#
# Author:: Sean OMeara (<someara@getchef.com>)
# Provuder:: ips_publisher
#
# Copyright 2013, Chef Software, Inc.
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
  execute "pkg set-publisher -g #{new_resource.url} #{new_resource.publisher}" do
    not_if "pkg publisher #{new_resource.publisher}"
    notifies :run, 'execute[pkg refresh --full]'
  end

  execute 'pkg refresh --full' do
    action :nothing
    ignore_failure true
  end
end

action :delete do
  execute "pkg unset-publisher #{new_resource.publisher}" do
    only_if "pkg publisher #{new_resource.publisher}"
  end
end
