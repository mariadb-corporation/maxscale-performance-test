include_recipe 'mariadb::configure_multi_firewall'
include_recipe 'mariadb::install_community'

# Create mysql directory that is destroyed during the purge
directory '/etc/mysql' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Create configuration file
template '/etc/mysql/multiple_servers.cnf' do
  source 'multiple_servers.cnf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Create log and run directories
directory '/var/run/mysqld/' do
  user 'mysql'
  group 'mysql'
  action :create
end

directory '/var/log/mysql' do
  user 'mysql'
  group 'mysql'
  action :create
end

# Create data directory
directory '/data/mysql' do
  action :create
  owner 'mysql'
  group 'mysql'
  recursive true
end

# Create databases for all the servers
1.upto(node['mariadb']['servers']) do |server|
  execute "Create databases for #{server} mysql server" do
    command "mysql_install_db --defaults-file=/etc/mysql/multiple_servers.cnf --user=mysql --datadir=/data/mysql/mysql#{server}"
  end
end

# Start the multi-node service manually
execute 'Start multiple mariadb servers' do
  command '/usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf start'
end

execute 'Wait for servers to start' do
  command 'sleep 15'
end

# Transfer database configuration file to the server
cookbook_file '/tmp/configure_database.sql' do
  source 'configure_database.sql'
end

# Apply configuration to all the mysql instances
1.upto(node['mariadb']['servers']) do |server|
  execute "Configure #{server} mysql server" do
    command "mysql --socket=/var/run/mysqld/mysqld#{server}.sock < /tmp/configure_database.sql"
  end
end
