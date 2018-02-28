include_recipe 'ips::grant_sudo_to_root'

directory '/data'

ips_repo 'test-repo-created' do
  path '/data/test-repo-created'
  action :create
  default_publisher 'fancy-software'
end

ips_repo 'test-repo-enabled1' do
  path '/data/test-repo-enabled1'
  action :enable_depot
  port 10000
  default_publisher 'fancy-software'
end

ips_repo 'test-repo-enabled2' do
  path '/data/test-repo-enabled2'
  action :enable_depot
  port 10002
  readonly false
  default_publisher 'fancy-software'
end

# Enable, then disable, this one
ips_repo 'test-repo-disabled' do
  path '/data/test-repo-disabled'
  action [:enable_depot, :disable_depot]
  port 10001
  default_publisher 'fancy-software'
end

# Create, then delete, this one
ips_repo 'test-repo-deleted' do
  path '/data/test-repo-deleted'
  action [:create, :delete]
  default_publisher 'fancy-software'
end


