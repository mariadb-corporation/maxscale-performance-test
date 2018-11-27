include_recipe "mariadb-maxscale::configure_firewall"
include_recipe "mariadb-maxscale::maxscale_repos"
include_recipe "ntp::default"

# Turn off SElinux
if node[:platform] == "centos" and node["platform_version"].to_f >= 6.0
  # TODO: centos7 don't have selinux
  bash 'Turn off SElinux on CentOS >= 6.0' do
  code <<-EOF
    selinuxenabled && flag=enabled || flag=disabled
    if [[ $flag == 'enabled' ]];
    then
      /usr/sbin/setenforce 0
    else
      echo "SElinux already disabled!"
    fi
  EOF
  end

  cookbook_file 'selinux.config' do
    path "/etc/selinux/config"
    action :create
  end
end  # Turn off SElinux

# Set timezone to Europe/Paris
case node[:platform_family]
when "debian", "ubuntu", "rhel", "fedora", "centos", "suse", "opensuse"
  execute "Set timezone to Europe/Paris" do
    command "rm -f /etc/localtime && ln -s /usr/share/Europe/Paris /etc/localtime"
  end
end # iptables rules

# Install bind-utils/dnsutils for nslookup
case node[:platform_family]
when "rhel", "centos"
  execute "install bind-utils" do
    command "yum -y install bind-utils"
  end
when "debian", "ubuntu"
  execute "install dnsutils" do
    command "DEBIAN_FRONTEND=noninteractive apt-get -y install dnsutils"
  end
when "suse", "opensuse"
  execute "install bind-utils" do
    command "zypper install -y bind-utils"
  end
end

# Install packages
case node[:platform_family]
when "suse"
  execute "install" do
    command "zypper -n install maxscale"
  end
when "debian"
  package 'maxscale'
when "windows"
  windows_package "maxscale" do
    source "#{Chef::Config[:file_cache_path]}/maxscale.msi"
    installer_type :msi
    action :install
  end
else
  package 'maxscale'
end
