require 'crypto'

##
# Outputs the encrypted version of the provided string using the provided key
##

if ARGV.size != 2
  puts "Usage: ./password_encrypter.rb <key> <password string>"
  puts "\n Example: ./password_encrypter.rb mylongishkey abcd1234"
else
  data = Crypto.encrypt(ARGV[0], ARGV[1])
  puts Crypto.encode(data)
end

