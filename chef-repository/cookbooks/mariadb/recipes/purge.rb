include_recipe "mariadb::uninstall"

execute "Configuration cleaning" do
  command "rm -fr /etc/mysql/"
end
execute "Data removing" do
  command "rm -fr /usr/share/mysql/ /usr/lib/mysql/ /usr/lib64/mysql/ /var/lib/mysql/ /var/log/mysql"
end
