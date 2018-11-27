#
# Cookbook:: sysbench
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

package 'wget'
package 'curl'

execute 'download sysbench installation script' do
  command 'wget https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh -O /tmp/install-sysbench.sh'
end

execute 'add sysbench repo' do
  command 'bash /tmp/install-sysbench.sh'
end

package 'sysbench'
