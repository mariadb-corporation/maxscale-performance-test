name              'mariadb'
maintainer        'MariaDB, Inc.'
maintainer_email  'Andrey.Kuznetsov@mariadb.com'
license           'Apache 2.0'
description       'MariaDB coockbook'
version           '0.0.3'
recipe            'install_community', 'Installs community version of mariadb'
recipe            'uninstall', 'Uninstalls mariadb and clears repository configuration'
recipe            'purge', 'Uninstalls packages and manually removes all known directories'
recipe            'install_multi_server', 'Installs, runs and configures multi-server setup of mariadb on single node'
recipe            'purge_multi_server', 'Removes configuration of multiserver and calls purge script'
recipe            'setup_multi_server', 'Removes current version and makes fresh installation of multiple servers'

depends           'ntp'
depends           'packages'
depends           'iptables-ng'

supports          'redhat'
supports          'centos'
supports          'fedora'
supports          'debian'
supports          'ubuntu'
supports          'suse'