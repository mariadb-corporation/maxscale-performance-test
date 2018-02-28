#!/usr/bin/env ruby

# This script vendors all the cookbooks into a special directory

def vendor_cookbooks
  root = File.absolute_path(File.dirname(__FILE__))
  cookbooks_path = "#{root}/cookbooks"
  Dir.foreach(cookbooks_path) do |cookbook|
    next if cookbook =~ /^\./
    puts "Vendoring '#{cookbook}' cookbook."
    Dir.chdir("#{cookbooks_path}/#{cookbook}")
    puts `berks vendor #{root}/vendor-cookbooks`
  end
  Dir.chdir root
end

vendor_cookbooks
