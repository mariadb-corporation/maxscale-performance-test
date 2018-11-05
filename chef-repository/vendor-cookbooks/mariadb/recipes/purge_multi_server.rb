execute 'Stop all running mariadb servers' do
  command '/usr/bin/mysqld_multi --defaults-file=/etc/mysql/multiple_servers.cnf stop'
  ignore_failure true
end

execute 'Wait for servers to stop' do
  command 'sleep 15'
end

1.upto(4) do |server|
  execute "Kill server backend #{server} with the kill command if needed" do
    ignore_failure true
    command <<COMMAND
pid_file=/var/run/mysqld/mysqld#{server}.pid
if [ -f ${pid_file} ]; then
  cat ${pid_file} | xargs kill -s kill
fi
COMMAND
  end
end

execute 'Wait for kill to complete' do
  command 'sleep 3'
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
