ips Cookbook
============

The IPS cookbook exposes a pair of resources that are used with the
Image Package System, a packaging system used on Oracle Solaris, 
Illumos, SmartOS, OmniOS, and others.

The IPS cookbook exposes the `ips_publisher` resource that allows a
user to set IP publisher sources on systems that support IPS.
This usually means Oracle Solaris, and Illumos systems like OmniOS.

Requirements
------------
* Chef 11 or higher
* Ruby 1.9 (preferably from the Chef full-stack installer)

Resources/Providers
-------------------
### ips_publisher
The ips_publisher resource manages package sources that are available 
to the system for package installation.  This is like managing 
/etc/yum.repo.d . It manages `pkg set-publisher` commands, and will 
repair publisher settings when needed.

#### Example
# add the OmniTI Managed Services repository

    ips_publisher 'OmniTI Managed Services' do
      publisher 'ms.omniti.com'
      url 'http://pkg.omniti.com/omniti-ms/'
      action :create
    end

#### Actions
- `:create` - creates a publisher
- `:delete` - deletes a publisher

#### Parameters
* `publisher` -  Must be a string value for the publisher, as consumed
  by the `pkg set-publisher` and `pkg unset-publisher` commands.
  
* `url` -  Must be a string value for the URL, as consumed by the `pkg
  set-publisher` and `pkg unset-publisher` commands.   

### ips_repo
The ips_repo resource manages a IPS package repository, which contains 
packages and can serve them either locally or via HTTP.  It manages the 
pkgrepo command, and the pkg/server SMF service (known as svc.depotd)

#### Actions
- `:create` - create a repo on the filesystem
- `:enable_depot` - expose a repo via HTTP.  Implies :create.
- `:disable_depot` - stop serving over HTTP, but leave repo on filesystem.
- `:delete` - Eradicate the repo from the filesystem.  Implies :disable_depot.

#### Parameters
* `path` - Required, filesystem path to use for repo.  If you want this 
   on ZFS, you should set that up prior to this.
* `default_publisher` - Required, publisher name to assign when 
   packages are written to the repo.
* `readonly` - Default true.  If false, anyone can publish a package to the repo.
   If using depot, consider authentication using nginx or similar. 
* `port` - Default 10000.  What port to run the depot instance on, if 
   :enable_depot is the action.

Usage
-----
Consume as a normal Chef resource after putting `depends 'ips'` in a cookbooks metadata.rb

Recipes
-----
No user recipes are included.  Two test recipes are included which are used in Test Kitchen testing.

License & Authors
-----------------
- Author:: Sean OMeara (<someara@getchef.com>)
- Author:: Clinton Wolfe (<clinton@omniti.com>)

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
