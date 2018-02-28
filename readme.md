# MaxScale Performance Test

The repository contains a utility that allows to setup environment for performance testing and execute the required tests. Currently environment consists out of two virtual machines one having two instances of mariadb running and another one includes the maxscale alongside with the sysbench utility.

The virtual machines can be either setup by the [MDBCI](https://github.com/mariadb-corporation/mdbci) tool or created manually. For both cases the tool will setup them according to their roles. Currently only Ubuntu 16.04 is supported.

## Known arguments

Currently the tool supports the following arguments:

- `backend-box` allows to specify the virtual boxes that will be created by the MDBCI. The supported are `ubuntu_xenial_libvirt` and `ubuntu_xenial_aws`. By default VMs are created locally with `ubuntu_xenial_libvirt` machines.
- `memory-size` allows to specify memory size for libvirt VM managed by the MDBCI. By default it is 2048.
- `mdbci-path` sets up the path to the MDBCI tool. By default it is `~/mdbci`.
- `mdbci-vm-path` sets up the path to the MDBCI VM configuration directory. By default it is `~/vms`
- `keep-servers` sets the tool to keep VMs created with MDBCI intact after performing the configuration and testing. By default is `false`.
- `server-config` allows to specify configuration of existing servers to configure them and not to use MDBCI to create machines.
- `verbose` options allows to provide more data to the standard output.
- `already-configured` option allows to skip configuration of virtual machines if they are already configured.
- `test` specifies the test application that should be run after the machines are brought up. Network configuration is passed to the application via environment variables.

If you want to use AWS to run tests, then use the following command:

```
./bin/performance_test --backend-box=ubuntu_xenial_aws --test tests/sample-test.rb
```

If you want to use existing virtual machines, then use the following command:

```
./bin/performance_test --server-config=~/vms/some_machine_network_config --test tests/sample-test.rb
```

If you want to just launch test application for the already created and configured virtual machines use the following command:

```
./bin/performance_test --server-config=~/vms/some_machine_network_config --alreay-configured=true --test tests/sample-test.rb
```

## Installation procedure

In order to use the tool you must install the following components:

- [MDBCI](https://github.com/mariadb-corporation/mdbci) tool if you want to create virtual machines.
- Ruby interpreter 2.3 or higher.
- Ruby gems `iniparse`, `net-ssh`, `net-scp`

If your host machine running Ubuntu 16.04 or higher, then you can install ruby interpreter and required gems using the command:

```
sudo apt install ruby ruby-net-ssh ruby-net-scp ruby-iniparse
```

## Chef cookbooks

The tool uses the [chef](https://www.chef.io/chef/) to configure machines into a desired state. The configuration is done in `chef-solo` mode, no installation of the chef on the host system is required. The installation of the [Chef Development Kit](https://downloads.chef.io/chefdk) is only required for the development of the cookbooks and their vendoring.

Repository also includes the dependent cookbooks to reduce the burden of running and configuring the tool. The support script `chef-repository/vendor-cookbooks.rb` performs vendoring of all cookbooks residing in the `chef-repository/cookbook` directory. It should be run every time any cookbook is changed.

## Known issues

* The mariadb configuration can be performed only once. If it is performed several times, then mariadb_multi can not start the application.
* The result of running MDBCI appears only after the tool has finished it job.
