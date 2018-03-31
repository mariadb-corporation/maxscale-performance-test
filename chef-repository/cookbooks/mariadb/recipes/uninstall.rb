case node[:platform_family]
when "debian"
  %w(mariadb-server mariadb-client mariadb-common mysql-common).each do |name|
    package name do
      action :purge
    end
  end
  execute "Remove mariadb repository" do
    command "rm -fr /etc/apt/sources.list.d/mariadb.list"
  end
  execute "update" do
    command "apt-get update"
  end
when "rhel", "fedora", "suse"
  package "MariaDB-common" do
    action :remove
  end
  execute "Remove repo" do
    command "rm -fr /etc/yum.repos.d/mariadb.repo /etc/zypp/repos.d/mariadb.repo*"
  end
end
