#
# Cookbook:: freebsd
# Resource:: port_options
#
# Copyright:: 2012-2016, ZephirWorks
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
#

actions :create
default_action :create

attribute :name, kind_of: String, name_attribute: true
attribute :source, kind_of: String
attribute :options, kind_of: Hash
attribute :dir_path, kind_of: String
attribute :full_path, kind_of: String
attribute :default_options, kind_of: Hash, default: {}
attribute :current_options, kind_of: Hash, default: {}
attribute :file_writer, kind_of: String

def initialize(*args)
  super
  @dir_path = '/var/db/ports/' + name
  @full_path = @dir_path + '/options'
end
