case node[:platform_family]
when "debian"
  node['mariadb']['debian-packages'].each do |name|
    package name do
      action :remove
    end
  end
  file '/etc/apt/sources.list.d/mariadb.list' do
    action :delete
  end
  apt_update 'update'

  # Automatically remove packages that are no longer needed for dependencies
  execute 'apt-get autoremove' do
    command 'apt-get -y autoremove'
    environment(
      'DEBIAN_FRONTEND' => 'noninteractive'
    )
  end
when "rhel", "fedora", "suse"
  package "MariaDB-common" do
    action :remove
  end
  execute "Remove repo" do
    command "rm -fr /etc/yum.repos.d/mariadb.repo /etc/zypp/repos.d/mariadb.repo*"
  end
end
