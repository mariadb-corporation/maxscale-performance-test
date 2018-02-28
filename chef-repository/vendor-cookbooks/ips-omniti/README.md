ips-omniti Cookbook
============

The ips-omniti cookbook configures the machine to talk to the OmniTI
IPS package archives.

Requirements
------------
* Chef 11 or higher
* Ruby 1.9 (preferably from the Chef full-stack installer)
* IPS cookbook

Recipes
-------
`default` - Uses the ips_publisher resource from the IPS cookbook to
configure IPS.

Usage
-----
include_recipe 'ips-omniti::default'

License & Authors
-----------------
- Author:: Sean OMeara (<someara@getchef.com>)

```text
Copyright:: 2008-2013 Chef Software, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
