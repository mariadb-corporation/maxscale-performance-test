
include_recipe 'ips::grant_sudo_to_root'

# You can get a list of well-known publishers here:
# http://omnios.omniti.com/wiki.php/Packaging

# Since presumably all images will have omnios publisher, 
# try removing it as a test for :delete
ips_publisher 'OmniOS main' do
  publisher 'omnios'
  url 'http://pkg.omniti.com/omnios/release'
  action :delete
end

# Add the OmniTI Perl modules repo as a test for :create
ips_publisher 'OmniTI Perl Modules' do
  publisher 'perl.omniti.com'
  url 'http://pkg.omniti.com/omniti-perl'
  action :create
end
