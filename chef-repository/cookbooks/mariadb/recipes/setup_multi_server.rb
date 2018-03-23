include_recipe 'mariadb::install_community'

# Create configuration file
template '/etc/mysql/multiple_servers.cnf' do
  source 'multiple_servers.cnf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

# Open ports for these servers and save configuration
1.upto(node['mariadb']['servers']) do |server|
  port = 3300 + server
  execute "Openning port #{port} for MultipleServers" do
    command "iptables -I INPUT -p tcp -m tcp --dport #{port} -j ACCEPT"
    command "iptables -I INPUT -p tcp --dport #{port} -j ACCEPT -m state --state NEW"
  end
end

execute "Save MariaDB iptables rules" do
  command "iptables-save > /etc/iptables/rules.v4"
end

# Install systemd service that would start the multiple instances of the mariadb
systemd_unit 'mariadb-multi.service' do
  content <<-EOU.gsub(/^\s+/, '')
    [Unit]
    Description = Start several database instances
    After = network.target

    [Install]
    WantedBy = multi-user.target

    [Service]
    Type = oneshot
    User = root
    Group = root
    ExecStart = /usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf start
    ExecStop = /usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf stop
  EOU
  verify false
  action [:create, :reload, :enable]
end

# Enshure that system is not running
# service 'mariadb-multi' do
#   action :stop
# end

# Start the multi-node service manually
execute 'Start multiple mariadb servers' do
  command '/usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf stop'
end

execute 'Wait for servers to start' do
  command 'sleep 5'
end

# Remove all data files
directory '/data' do
  action :delete
  recursive true
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

# Stop the main database
execute 'Stop the main database' do
  command 'systemctl stop mysql'
end

# Start the multi-node service using systemd (it does not work)
# service 'mariadb-multi' do
#   action :start
# end

# Start the multi-node service manually
execute 'Start multiple mariadb servers' do
  command '/usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf start'
end

execute 'Wait for servers to start' do
  command 'sleep 5'
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
