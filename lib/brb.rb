require File.join(File.dirname(__FILE__), 'brb', 'exception.rb')
require File.join(File.dirname(__FILE__), 'brb', 'event_machine.rb')
require File.join(File.dirname(__FILE__), 'brb', 'tunnel.rb')
require 'Singleton'

#
# Brb Main class used to do basic distributed ruby, Simple but fast
# Use two distinct canal, one for the command reception, and the other one for send return value
#
module BrB
  class Service
    attr_reader :silent
    attr_reader :uri

    include Singleton

    # Start a server hosted on the object given,
    # If an uri is given, automatcilay connect to the distant brb object
    def start_service(opts = {}, &block)
      return if @em_signature
      
      @silent = opts[:silent]

      addr = "brb://#{opts[:host] || 'localhost'}:#{opts[:port] || 6200}"

      tputs " [BrB] Start service on #{addr} ..."
      @uri, @em_signature = BrBProtocol.open_server(addr, BrB::Tunnel::Handler, opts.merge(:block => block))
      tputs " [BrB] Service started on #{@uri}"
    end

private
    def tputs(s)
      puts s if !@silent
    end

public
    # Stop the Brb Service
    def stop_service
      return if !@em_signature
      
      tputs ' [BrB] Stop service'
      EM::stop_server(@em_signature)
      @em_signature = nil
      @uri = nil
    end

  end
end