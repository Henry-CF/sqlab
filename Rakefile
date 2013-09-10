require 'digest/md5'

INSTALLATION_FILE="mysql-5.6.13-linux-glibc2.5-x86_64.tar.gz"
BLOB_FOLDER = File.expand_path("./blobs", File.dirname(__FILE__))
DOWNLOAD_URL = "http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.13-linux-glibc2.5-x86_64.tar.gz/from/http://cdn.mysql.com/"
MD5SUM="809b35f6ce30029cc576f4c31f0803b1"

task :prepare do
  unless installation_file_exits?
    %x{pushd #{BLOB_FOLDER}; wget #{URL} -o #{INSTALLATION_FILE}; popd}
  end

  res = %x{vagrant plugin list}
  if !$?.success?
    fail "Vagrant is not installed."
  elsif !res =~ /vagrant-proxyconf/
    puts "Installing vagrant-proxyconf plugin"
    %x{vagrant plugin install vagrant-proxyconf}
  end
  puts "Done!"
end

def installation_file_exits?
  Dir.chdir(BLOB_FOLDER) do
    return unless File.exists? INSTALLATION_FILE
    file_md5 = Digest::MD5.file(INSTALLATION_FILE).hexdigest
    return true if file_md5 == MD5SUM
  end
end

task :default => :prepare
