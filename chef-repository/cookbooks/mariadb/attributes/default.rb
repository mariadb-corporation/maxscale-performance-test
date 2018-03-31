# attributes/default.rb

# mariadb version
default["mariadb"]["version"] = "10.2"

# mariadb repo ubuntu/debian/mint
default["mariadb"]["repo"] = "http://mirror.netinch.com/pub/mariadb/repo/10.2/ubuntu/ xenial main"

# mariadb repo key for rhel/fedora/centos/suse
#default["mariadb"]["repo_key"] = "http://mirror.mephi.ru/mariadb/yum"
default["mariadb"]["repo_key"] = " http://yum.mariadb.org/"

# path for server.cnf file
default["mariadb"]["cnf_template"] = "server1.cnf"

# number of multi servers to setup
default['mariadb']['servers'] = 4

# Names of pagkages that should be uninstall or purged when
# uninstalling corresponding
default['mariadb']['debian-packages'] = %w(mariadb-server mariadb-client mariadb-common mysql-common)
