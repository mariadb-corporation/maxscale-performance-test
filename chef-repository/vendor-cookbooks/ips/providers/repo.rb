#
# Author:: Clinton Wolfe (<clinton@omniti.com>)
# Provider:: ips_repo
#
# Copyright 2015, OmniTI Computer Consulting, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Allow for Chef 10 support
use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do

  directory new_resource.path do
    recursive true
    mode '0700'
  end

  bash "pkgrepo create #{new_resource.path}" do
    not_if "pkgrepo info -s file://#{new_resource.path}"
    code <<-EOB
pkgrepo create #{new_resource.path} && \
pkgrepo set -s #{new_resource.path} publisher/prefix=#{new_resource.default_publisher} && \
pkgrepo set -s #{new_resource.path} repository/name=#{new_resource.name}
EOB
  end

end

action :delete do
  new_resource.run_action(:disable_depot)
  # TODO: any repo cleanup?

  directory new_resource.path do
    recursive true
    action :delete
  end
end

action :enable_depot do
  new_resource.run_action(:create)

  bash "create SMF pkg/server for #{new_resource.name}" do
    not_if "svcs pkg/server:#{new_resource.name}"
    # TODO: figure out how to deduplicate this code for setting/changing the properties.
    code <<-EOB
svccfg -s pkg/server add #{new_resource.name} && \
svccfg -s pkg/server:#{new_resource.name} addpg pkg application && \
svccfg -s pkg/server:#{new_resource.name} setprop pkg/inst_root = astring: "#{new_resource.path}" && \
svccfg -s pkg/server:#{new_resource.name} setprop pkg/port = count: #{new_resource.port} && \
svccfg -s pkg/server:#{new_resource.name} setprop pkg/readonly = #{new_resource.readonly} && \
svcadm refresh pkg/server:#{new_resource.name} && \
svcadm enable -s pkg/server:#{new_resource.name}
EOB
  end

  # Next three resources are just here to catch changes on individual properties
  bash "update file path for pkg/server:#{new_resource.name}" do
    not_if "svccfg -s pkg/server:#{new_resource.name} listprop pkg/inst_root | grep #{new_resource.path}"
    code <<-EOB
svccfg -s pkg/server:#{new_resource.name} setprop pkg/inst_root = astring: "#{new_resource.path}"
svcadm refresh pkg/server:#{new_resource.name}
svcadm enable -s pkg/server:#{new_resource.name}
EOB
  end

  bash "update port for pkg/server:#{new_resource.name}" do
    not_if "svccfg -s pkg/server:#{new_resource.name} listprop pkg/port | grep #{new_resource.port}"
    code <<-EOB
svccfg -s pkg/server:#{new_resource.name} setprop pkg/port = count: #{new_resource.port}
svcadm refresh pkg/server:#{new_resource.name}
svcadm enable -s pkg/server:#{new_resource.name}
EOB
  end

  bash "update readonly flag for pkg/server:#{new_resource.name}" do
    not_if "svccfg -s pkg/server:#{new_resource.name} listprop pkg/readonly | grep #{new_resource.readonly}"
    code <<-EOB
svccfg -s pkg/server:#{new_resource.name} setprop pkg/readonly = #{new_resource.readonly}
svcadm refresh pkg/server:#{new_resource.name}
svcadm enable -s pkg/server:#{new_resource.name}
EOB
  end
  
end

action :disable_depot do
  bash "delete SMF pkg/server for #{new_resource.name}" do
    only_if "svcs pkg/server:#{new_resource.name}"
    code <<-EOB
svcadm disable -s pkg/server:#{new_resource.name}
svccfg -s pkg/server delete #{new_resource.name}
EOB
  end

end
