# MaxScale Performance Test

The repository contains a utility that allows to setup environment for performance testing and execute the test. Currently environment consists out of two virtual machines one having four instances of mariadb running and another one includes the maxscale alongside with the sysbench utility.

The virtual machines can be either setup by the [MDBCI](https://github.com/mariadb-corporation/mdbci) tool or created manually. MDBCI tool also provides information about repositories that are used during the configuration of virtual machines. For both cases the tool will setup them according to their roles. Currently only Ubuntu 16.04 is supported as the OS for mentioned VMs.

## Supported arguments

Currently the tool supports the following arguments:

- `backend-box` allows to specify the virtual boxes that will be created by the MDBCI. The supported are `ubuntu_xenial_libvirt` and `ubuntu_xenial_aws`. By default VMs are created locally with `ubuntu_xenial_libvirt` machines.
- `memory-size` allows to specify memory size for libvirt VM managed by the MDBCI. By default it is 2048.
- `mdbci-path` sets up the path to the MDBCI tool. By default it is `~/mdbci`.
- `mdbci-vm-path` sets up the path to the MDBCI VM configuration directory. By default it is `~/vms`
- `keep-servers` sets the tool to keep VMs created with MDBCI running after performing the configuration and testing. By default is `false`, therefore servers created with MDBCI will be destroied.
- `server-config` allows to specify configuration of existing servers to use them instead of automatically created ones. The format of the file coinsides with network file configuration format of MDBCI.
- `mariadb_version` allows to specify version of mariadb to install on the server. The repositories are read from MDBCI configuration.
- `db-server-1-config` name of the template SQL file that resides in `templates/db-config` directory that will be used for configuration of MariaDB server after the installation.
- `db-server-2-config`, `db-server-3-config`, `db-server-4-config` are the same as `db-server-1-config` but for other database servers.
- `maxscale-version` name of the repository on the server `http://max-tst-01.mariadb.com/ci-repository/` to install maxscale from. By default it is `maxscale-2.2.3-release`.
- `maxscale-config` name of the file maxscale configuration template that should be used during the test and resides in the `templates/maxscale-config` directory.
- `verbose` or `-v` option allows to provide more data to the standard output. This option should be used during development to catch any bugs.
- `already-configured` option allows to skip configuration of virtual machines if they are already configured.
- `local-test-app` specifies the test application that should be run on the local machine after the machines are brought up to test. Network configuration is passed to the application via environment variables. Path is either absolute or relative.
- `remote-test-app` specifies the test application that should be run on the remote machine to perfrom the test. No network configuration is passed to the script. Path is either absolute or relative.

## Using the application

In order to run the full example on the local machine using MDBCI you should execute the following command:

```
./bin/performance_test -v --remote-test-app tests/run_sysbench.sh --db-server-2-config slave-config.sql.erb --db-server-3-config slave-config.sql.erb --db-server-4-config slave-config.sql.erb --mariadb-version 10.2 --maxscale-config base.cnf.erb --maxscale-version maxscale-2.2.4-release
```

If you want to use AWS to run tests, then use the following command:

```
./bin/performance_test -v --backend-box ubuntu_xenial_aws --remote-test-app tests/run_sysbench.sh --db-server-2-config slave-config.sql.erb --db-server-3-config slave-config.sql.erb --db-server-4-config slave-config.sql.erb --mariadb-version 10.2 --maxscale-config base.cnf.erb --maxscale-version maxscale-2.2.4-release
```

If you want to use existing virtual machines, then use the following command:

```
./bin/performance_test --server-config=~/vms/some_machine_network_config --remote-test-app tests/run_sysbench.sh --db-server-2-config slave-config.sql.erb --db-server-3-config slave-config.sql.erb --db-server-4-config slave-config.sql.erb --mariadb-version 10.2 --maxscale-config base.cnf.erb --maxscale-version maxscale-2.2.4-release
```

If you want to just launch test application for the already created and configured virtual machines use the following command:

```
./bin/performance_test --server-config ~/vms/some_machine_network_config --alreay-configured true --remote-test-app tests/run_sysbench.sh
```

## Installation procedure

In order to use the tool you must install the following components:

- [MDBCI](https://github.com/mariadb-corporation/mdbci) tool if you want to create virtual machines. It is assumed that the tool resides in the home directory of the
- Ruby interpreter 2.3 or higher.
- Ruby gems `iniparse`, `net-ssh`, `net-scp`, `mysql2`

If your host machine running Ubuntu 16.04 or higher, then you can install ruby interpreter and required gems using the following commands:

```
sudo apt install ruby ruby-net-ssh ruby-net-scp ruby-mysql2
sudo gem install iniparse -v 1.4
```

## Chef cookbooks

The tool uses the [chef](https://www.chef.io/chef/) to configure machines into a desired state. The configuration is done in `chef-solo` mode, no installation of the chef on the host system is required. The installation of the [Chef Development Kit](https://downloads.chef.io/chefdk) is only required for the development of the cookbooks and their vendoring.

Repository also includes the dependent cookbooks to reduce the burden of running and configuring the tool. The support script `chef-repository/vendor-cookbooks.rb` performs vendoring of all cookbooks residing in the `chef-repository/cookbook` directory. It should be run every time any cookbook is changed.

## Known issues

* The mariadb configuration can be performed only once. If it is performed several times, then mariadb_multi can not start the application.
* The result of running MDBCI appears only after the tool has finished it job.
