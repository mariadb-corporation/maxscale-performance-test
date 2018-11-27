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

maxscale_rules = %w[3306 4006 4008 4009 4016 5306 4442 6444 6303].map do |port|
  "--protocol tcp --dport #{port} --jump ACCEPT"
end
iptables_ng_rule 'allow-maxscale-incoming-connections' do
  rule maxscale_rules
end
