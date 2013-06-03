# encoding: utf-8
require 'eventmachine'
require File.join(File.dirname(__FILE__), 'request.rb')
require File.join(File.dirname(__FILE__), 'tunnel', 'shared.rb')

module BrB
  module Tunnel

    # Create a BrB Tunnel by connecting to a distant BrB service
    # Pass a block if you want to get register and unregister events
    # The first parameter object is the object you want to expose in the BrB tunnel
    def self.create(object, uri = nil, opts = {}, &block)
      BrB::Protocol.open(uri, BrB::Tunnel::Handler, opts.merge(:object => object, :block => block))
    end

    # Brb interface Handler for Tunnel over Event machine
    class Handler < ::EventMachine::Connection
      attr_reader :uri
      attr_reader :ip_address, :port

      include BrB::Request
      include BrB::Tunnel::Shared

      def initialize(opts = {})
        super
        @object = opts[:object]
        @verbose = opts[:verbose]
        BrB.logger.level = @verbose ? Logger::INFO : Logger::WARN
        @timeout_rcv_value = opts[:timeout] || 30 # Currently not implemented due to the lack of performance of ruby Timeout
        @close_after_timeout = opts[:close_after_timeout] || false
        @uri = opts[:uri]
        @replock = Mutex.new
        @responses = {}
        @block = opts[:block]
        
        @queue = Queue.new
        @buffer = ''
        
        # Callbacks handling :
        @callbacks = {}
        @callbacks_mutex = Mutex.new
      end

      # EventMachine Callback, called after connection has been initialized
      def post_init
        begin
          @port, @ip_address = Socket.unpack_sockaddr_in(get_peername) 
        rescue Exception => e
          @port = ""
          @ip_address = ""
          puts e.message
          puts e.backtrace.inspect
        end
        
        
        BrB.logger.info " [BrB] Tunnel initialized on #{@uri}"
        @active = true
        if @block
          EM.defer do
            @block.call(:register, self)
          end
        end
      end

      def close_connection(after_writing = false)
        @active = false
        super
      end

      # EventMachine unbind event
      # The connection has been closed
      def unbind
        BrB.logger.info ' [BrB] Tunnel service closed'
        @active = false
        if @block
          EM.defer do
            @block.call(:unregister, self)
          end
        end
      end
      
      # Stop the service
      def stop_service
        BrB.logger.info ' [BrB] Stopping Tunnel service...'
        @active = false
        EM.schedule do
          close_connection
        end
      end

      # Return true if the tunnel is currently active
      def active?
        @active
      end

      # When no method is found on tunnel interface, create an brb out request
      def method_missing(meth, *args, &block)
        return nil if !@active
        new_brb_out_request(meth, *args, &block)
      end
    end
  end

end
