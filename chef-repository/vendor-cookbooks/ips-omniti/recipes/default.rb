#
# Author:: Sean OMeara (<someara@getchef.com>)
# Recipe:: ips-omniti::default
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

directory '/opt/omni/etc' do
  recursive true
end

ips_publisher 'OmniTI Managed Services' do
  publisher 'ms.omniti.com'
  url 'http://pkg.omniti.com/omniti-ms/'
  action :create
end

if node['platform_version'].to_i <= 151006
  package 'incorporation/jeos/omnios-userland' do
    version '11,5.11-0.151006'
  end

  package 'pkg' do
    version '0.5.11,5.11-0.151006'
  end

  package 'web/ca-bundle' do
    version '5.11,5.11-0.151006'
  end
end
