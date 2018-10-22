# frozen_string_literal: true

require 'rubocop/rake_task'

RuboCop::RakeTask.new(:rubocop) do |task|
  task.patterns = %w[bin/** Gemfile lib/**/.rb Rakefile]
end

task :run do
  sh <<-COMMAND.gsub(/\n/, ' ')
    ./bin/performance_test -v --remote-test-app tests/run_sysbench.sh
    --db-server-2-config slave-config.sql.erb --db-server-3-config slave-config.sql.erb
    --db-server-4-config slave-config.sql.erb --mariadb-version 10.2
    --maxscale-config base.cnf.erb --maxscale-version maxscale-2.2.4-release
  COMMAND
end
