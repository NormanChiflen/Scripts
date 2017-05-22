#!/usr/bin/ruby
require 'open-uri'

PATHS = [
  'http://www.expedia.com',
  'http://www.expedia.com/Hotels',
  'http://www.expedia.com/Flights',
  'http://www.expedia.com/Vacation-Packages',
  'http://www.expedia.com/Flights-Search?trip=roundtrip&leg1=from:New%20York,%20NY%20(NYC-All%20Airports),to:San%20Francisco,%20CA,%20United%20States%20(SFO-San%20Francisco%20Intl.),departure:02%2F05%2F2013TANYT&leg2=from:San%20Francisco,%20CA,%20United%20States%20(SFO-San%20Francisco%20Intl.),to:New%20York,%20NY%20(NYC-All%20Airports),departure:02%2F21%2F2013TANYT&passengers=children:0,adults:1,seniors:0,infantinlap:Y&options=cabinclass:coach,nopenalty:N,sortby:price&mode=search',
  'http://www.expedia.com/Hotel-Search?storedCheckoutField=&storedCheckinField=&lang=1033#destination=San+Francisco+%28and+vicinity%29%2C+California%2C+United+States+of+America&startDate=02%2F05%2F2013&endDate=02%2F21%2F2013&adults=1&star=0&lodging=all',
  'http://www.expedia.com/San-Francisco-Hotels-Sheraton-Fishermans-Wharf.h24625.Hotel-Information?chkin=2/5/2013&chkout=2/21/2013&pmicid=TA_2545877&rm1=a1&',
  'http://www.expedia.com/Chicago-Hotels.d178248.Travel-Guide-Hotels',
  'http://www.expedia.co.uk',
  'http://www.expedia.co.uk/Flights',
  'http://www.expedia.co.uk/Hotels',
  'http://www.expedia.co.uk/Holidays',
  'http://www.expedia.co.uk/Flights-Search?trip=roundtrip&leg1=from:London,%20England,%20UK%20(LHR-Heathrow),to:Tokyo,%20Japan%20(TYO-All%20Airports),departure:06%2F02%2F2013TANYT&leg2=from:Tokyo,%20Japan%20(TYO-All%20Airports),to:London,%20England,%20UK%20(LHR-Heathrow),departure:14%2F02%2F2013TANYT&passengers=children:0,adults:2,seniors:0,infantinlap:Y&options=cabinclass:economy,nopenalty:N,sortby:price&mode=search',
  'http://www.expedia.fr',
  'http://www.expedia.de',
  'http://www.expedia.ca',
  'http://www.expedia.co.jp']

minify_paths = []   
  
PATHS.each do |path|
  # Get the http://www.expedia.com/ or its equivalent from each path:
  domain_prefix = path.match(/^(https?:\/\/[^\/]+)(\/.*)?$/)[1]
  
  output = open(path) {|io| io.read}
  
  # regex: capture everything that starts and ends with the same type of quote and includes "/minify/" 
  output.scan(/(["'])([^"']*\/minify\/[^"']+)\1/) do |group1, group2|
    # pre-pend the domain-prefix so that we can run curl on each minify url
    min_path = group2
    min_path = domain_prefix + min_path unless min_path.start_with?'http://'
    
    # add it to the list if it doesn't already exist
    unless minify_paths.include?(min_path)
      minify_paths << min_path 
    end
  end
end


minify_paths.each do |path|
  output = open(path) {|io| io.read}
  
  served_in_matches = output.scan(/\/\*\!?  served in \d+ ms  \*\//)
  if served_in_matches.length != 1
    filename = path.match(/^https?:\/\/[^\/]+\/(minify\/[^?]*)/)[1].tr("/", "_")
    puts "FAILURE: #{path}: No match on 'served in'.  Output saved to file #{filename}"
    File.open(filename, 'w') { |file| file.write(output) }
  else
    puts "SUCCESS: #{path}"
  end
end
  
  

  
  
  