#!/usr/bin/env ruby
 
require 'net/http'
 
check_url ='http://blog.dataloop.io/2013/10/26/notes-from-monitorama-eu/'
html_content = Net::HTTP.get(URI.parse(check_url))
 
if html_content.match('Monitorama')
 puts "Up"
 Process.exit(0)
else
 puts "Down"
 Process.exit(2)
end