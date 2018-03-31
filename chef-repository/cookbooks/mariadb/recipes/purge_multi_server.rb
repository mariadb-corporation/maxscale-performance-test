execute 'Stop all running mariadb servers' do
  command '/usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf stop'
  ignore_failure true
end

execute 'Wait for servers to start' do
  command 'sleep 15'
end

# Remove all data files for multiple servers
directory '/data/mysql' do
  action :delete
  recursive true
end

# Remove configuration file
file '/etc/mysql/multiple_servers.cnf' do
  action :delete
end

# We need to remove all cached data, so it won't interfere with the next installation
include_recipe 'mariadb::purge'
