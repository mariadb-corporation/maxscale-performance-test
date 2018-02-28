
# Looks like the OmniOS vagrant boxes were packaged without sudo for 
# the root user, which borks busser/serverspec

# This is crude, obviously
execute "echo 'root ALL=(ALL) NOPASSWD: ALL  # ips::grant_sudo_to_root' >> /etc/sudoers" do
  not_if "grep ips::grant_sudo_to_root /etc/sudoers"
end
