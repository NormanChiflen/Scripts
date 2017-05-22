require 'xmlrpc/client'
require 'logger'

# Description:
#
# A useful helper for running Confluence XML-RPC from Ruby. Takes care of
# adding the token to each method call (so you can call server.getSpaces()
# instead of server.getSpaces(token)). Also takes care of re-logging in
# if your login times out.
#
# Usage:
#
# server = Confluence::RPC.new("http://confluence.atlassian.com")
# server.login("user", "password")
# puts server.getSpaces()
#
# Version: $Id: //e3/tools/ImplicitIntegration/live/confluence_rpc.rb#4 $
#
module Confluence

  class RPC
    attr_accessor :log

    def initialize(server_url, proxy = "confluence1")
      @log = AUTO_INTEGRATOR_LOGGER
      server_url += "/rpc/xmlrpc" unless server_url[-11..-1] == "/rpc/xmlrpc"
      @server_url = server_url
      server = XMLRPC::Client.new2(server_url)
      @conf = server.proxy(proxy)
      @token = "12345"
    end

    def log_and_print(text)
      puts text
      if AUTO_INTEGRATOR_LOG_ENABLED
          if text.downcase.include?"fail"
            @log.error "Confluence RPC: " + text.gsub("\n", "|")
          else
            @log.info "Confluence RPC: " + text.gsub("\n", "|")
          end
      end
    end
    
    def login(username, password)
      log_and_print "Logging in as '#{username}'."
      @user = username
      @pass = password
      do_login()
    end
    
    def method_missing(method_name, *args)
      log_and_print "Calling #{method_name}(#{args.inspect})."
      begin
        @conf.send(method_name, *([@token] + args))
      rescue XMLRPC::FaultException => e
        log_and_print "Failure: #{e}: #{e.message}"
        if (e.faultString.include?("InvalidSessionException"))
          do_login
          retry
        else
          raise RemoteException, e.respond_to?(:message) ? e.message : e
        end
      rescue
        log_and_print "Failure: #{$!}"
        raise $!
      end
    end
    
    private
    
    def do_login()
      begin
        @token = @conf.login(@user, @pass)
      rescue XMLRPC::FaultException => e
        log_and_print "Failure: #{e}: #{e.faultString}"
        raise RemoteAuthenticationException, e
      end
    end
  end
  
  
  class RemoteException < Exception
    def initialize(msg = nil, type = nil)
      if msg.kind_of? XMLRPC::FaultException
        msg.faultString =~ /^.*?:\s(.*?):\s(.*)/
        msg = $2
        type = $1
      end
    
      super(msg)
      @type = type
    end
  end
  
  class RemoteAuthenticationException < RemoteException
  end
end
