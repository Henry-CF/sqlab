INSTALLATION_FILE="mysql-5.6.13-linux-glibc2.5-x86_64.tar.gz"
FOLDER_NAME="mysql-5.6.13-linux-glibc2.5-x86_64"
INSTALL_FOLDER="/usr/local"

if Chef::Config[:solo]
  missing_attrs = %w{
    server_root_password server_repl_password
  }.select do |attr|
    node["mysql"][attr].nil?
  end.map { |attr| "node['mysql']['#{attr}']" }

  if !missing_attrs.empty?
    Chef::Application.fatal!([
        "You must set #{missing_attrs.join(', ')} in chef-solo mode.",
        "For more information, see https://github.com/opscode-cookbooks/mysql#chef-solo-note"
      ].join(' '))
  end
end

package "apparmor" do
  action :purge
end

%w{libaio1 build-essential vim libdbd-mysql-perl}.each do |p|
  package p do
    action :install
  end
end

bash "rename unwanted config file" do
  code <<-EOH
  mv /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
  EOH

  action :run
  not_if { ::File.exists?("/etc/mysql/my.cnf.bak") }
end

group "mysql" do
  action :create
end

user "mysql" do
  action :create
  gid "mysql"
  system true
end

directory "/var/log/mysql" do
  owner "mysql"
  group "mysql"
  mode 00644
  action :create
end

bash "Install mysql binary" do
  code <<-EOH
  set -x
  cd #{INSTALL_FOLDER}
  tar zxvf /tmp/blobs/#{INSTALLATION_FILE}
  ln -s #{FOLDER_NAME} mysql
  cd mysql
  chown -R mysql:mysql .
  scripts/mysql_install_db --user=mysql
  chown -R root .
  chown -R mysql data
  cp support-files/mysql.server /etc/init.d/mysql
  MY_LD_FILE=/etc/ld.so.conf.d/mysql.conf
  echo "#{INSTALL_FOLDER}/mysql/lib" >> $MY_LD_FILE
  /sbin/ldconfig
  EOH

  action :run
  not_if { ::File.exists?("/etc/init.d/mysql") }
end

template "/etc/my.cnf" do
  source "my.cnf.erb"
  owner "root"
  group node["mysql"]["root_group"]
  mode "0644"

  notifies :restart, "service[mysql]", :immediately
end

service "mysql" do
  action :restart
end

## setup slave
ruby_block "config-replication" do
  block do
    require "mysql2"

    if node['mysql']['master']
      Chef::Log.info("Skip for master node.")
    else
      master_ip = node["mysql"]["master_ip"]
      client = Mysql2::Client.new(
        :host => "localhost",
        :user_name => "root",
        :password => node["mysql"]["server_root_password"],
        :database => "mysql"
      )
      setup_master_cmd = %Q[
      CHANGE MASTER TO
        MASTER_HOST='#{master_ip}',
        MASTER_USER='repl',
        MASTER_PASSWORD='#{node.mysql.server_repl_password}',
      ]
      Chef::Log.info("Using #{master_ip} as master")
      Chef::Log.info("#{setup_master_cmd}")

      client.query("stop slave")
      client.query(setup_master_cmd)
      client.query("start slave")
    end
  end
  only_if "pgrep mysqld$"
  action :nothing
end

gem_package "mysql2" do
  action :nothing
  # weired options.. but works
  options "-- --with-mysql-config=#{INSTALL_FOLDER}/mysql/bin/mysql_config"
#  notifies :create, resources(:ruby_block => "config-replication"), :immediately
end

execute "assign-root-password" do
  command %Q["#{INSTALL_FOLDER}/mysql/bin/mysqladmin" -u root password '#{node['mysql']['server_root_password']}']
  action :run
  only_if %Q["#{INSTALL_FOLDER}/mysql/bin/mysql" -u root -e 'show databases;']
end

template "/tmp/init.sql" do
  source "init.sql.erb"
  owner "mysql"
  mode "0644"
end

execute "execute initial scripts" do
  command %Q["#{INSTALL_FOLDER}/mysql/bin/mysql" -u root --password='#{node['mysql']['server_root_password']}' < /tmp/init.sql]
  action :run
  notifies :install, resources(:gem_package => "mysql2"), :immediately
end

template "/tmp/config-replication.rb" do
  source "config-replication.rb.erb"
  mode "0755"
end

execute "config replication" do
  command %Q[/tmp/config-replication.rb; touch /usr/local/mysql/repl-configured]
  action :run
  not_if { ::File.exists?("/usr/loca/mysql/repl-configured") }
end

