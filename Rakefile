require 'digest/md5'

BLOB_FOLDER = File.expand_path("./blobs", File.dirname(__FILE__))
REQUIRED_FILES = {
  "mysql-5.6.13-linux-glibc2.5-x86_64.tar.gz" => {
    url: "http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.13-linux-glibc2.5-x86_64.tar.gz/from/http://cdn.mysql.com/",
    md5: "809b35f6ce30029cc576f4c31f0803b1"
  },
  "percona-xtrabackup-2.1.5-680-Linux-x86_64.tar.gz" => {
    url: "http://www.percona.com/downloads/XtraBackup/LATEST/binary/Linux/x86_64/percona-xtrabackup-2.1.5-680-Linux-x86_64.tar.gz",
    md5: "5f5f570e6ead4f18683e4ce0808b26ff"
  }
}

task :prepare do
  REQUIRED_FILES.each do |name, info|
    unless installation_file_exits?(name, info[:md5])
      puts "Downloading #{name} to #{BLOB_FOLDER}"
      %x{pushd #{BLOB_FOLDER}; rm -rf #{name}; wget "#{info[:url]}" -O "#{name}"; popd}
    end
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

def installation_file_exits?(file, md5)
  Dir.chdir(BLOB_FOLDER) do
    return true if (File.exists? file) && (Digest::MD5.file(file).hexdigest == md5)
  end
end

task :default => :prepare
