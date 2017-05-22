require 'openssl'
require 'base64'

##
# Module to encrypt and decrypt text. Also has Base64 encoding/decoding to make 
# encrypted data easy to cut/paste and handle in general.
##

module Crypto
  # does the heavy lifting
  def self.cipher(mode, key, data)
    cipher = OpenSSL::Cipher::Cipher.new('bf-cbc').send(mode)
    cipher.key = Digest::SHA256.digest(key)
    cipher.update(data) << cipher.final
  end

  # Encrypts provided string with provided key
  def self.encrypt(key, data)
    cipher(:encrypt, key, data)
  end

  # Decrypts provided string with provided key
  def self.decrypt(key, data)
    cipher(:decrypt, key, data)
  end

  # Base64 encoding of provided data
  def self.encode(data)
    Base64.encode64(data)
  end

  # Base64 decoding of provided data
  def self.decode(data)
    Base64.decode64(data)
  end
 end

