include_recipe 'iptables-ng::install'

iptables_ng_chain 'INPUT' do
  policy 'DROP [0:0]'
end

iptables_ng_rule 'allow-loopback-connections' do
  rule '-i lo --jump ACCEPT'
end

iptables_ng_rule 'allow-related-connections' do
  rule ['--match state --state ESTABLISHED --jump ACCEPT',
        '--match state --state RELATED --jump ACCEPT']
end

iptables_ng_rule 'drop-invalid-packets' do
  rule '-m state --state INVALID --jump DROP'
end

iptables_ng_rule 'allow-incoming-ssh-connections' do
  rule '--protocol tcp --dport 22 --match state --state NEW --jump ACCEPT'
end

port_numbers = (1..node['mariadb']['servers']).map { |port| 3300 + port }
mariadb_rules = port_numbers.map do |port|
  "--protocol tcp --dport #{port} --jump ACCEPT"
end

iptables_ng_rule 'allow-access-to-mariadb-incoming-ports' do
  rule mariadb_rules
end

iptables_ng_rule 'test' do
  rule '--protocol udp --dport 5555 --jump ACCEPT'
end
