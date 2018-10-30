#!/usr/bin/env ruby

# This is the simple application that only prints the environment variables and exits

puts 'All known environment variables'
ENV.each do |key, value|
  puts "#{key} = #{value}"
end
