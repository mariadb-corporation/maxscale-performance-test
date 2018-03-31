include_recipe "mariadb::uninstall"

case node[:platform_family]
when 'debian'
  node['mariadb']['debian-packages'].each do |name|
    package name do
      action :purge
    end
  end
end

# Automatically remove packages that are no longer needed for dependencies
execute 'apt-get autoremove' do
  command 'apt-get -y autoremove'
  environment(
    'DEBIAN_FRONTEND' => 'noninteractive'
  )
  action :nothing
  only_if { apt_installed? }
end

execute 'Reload systemd configuration' do
  command 'systemctl daemon-reload'
end

directories = %w(/usr/share/mysql /usr/lib/mysql /usr/lib64/mysql /var/lib/mysql /var/log/mysql)
directories.each do |directory_name|
  directory directory_name do
    action :delete
    recursive true
  end
end
