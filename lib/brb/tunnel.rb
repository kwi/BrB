# encoding: utf-8
require 'eventmachine'
require File.join(File.dirname(__FILE__), 'request.rb')
require File.join(File.dirname(__FILE__), 'tunnel', 'shared.rb')

module BrB
  module Tunnel

    def self.create(object, uri = nil, silent = nil, &block)
      BrBProtocol.open(uri, BrB::Tunnel::Handler, :object => object, :silent => silent, :block => block)
    end

    # Brb interface Handler for Tunnel over Event machine
    class Handler < EventMachine::Connection
      attr_reader :uri

      include BrB::Request
      include BrB::Tunnel::Shared

      def initialize(opts = {})
        super
        @object = opts[:object]
        @silent = opts[:silent]
        @timeout_rcv_value = opts[:timeout] || 30
        @close_after_timeout = opts[:close_after_timeout] || false
        @uri = opts[:uri]
        @closed = nil
        @replock = Mutex.new
        @responses = {}
        @block = opts[:block]
        @mu = Mutex.new
        
        @queue = Queue.new
        @buffer = ''
      end

      def post_init
        @active = true
        if @block
          EventMachine.defer do
            @block.call(:register, self)
          end
        end
      end
      
      def close_connection(after_writing = false)
        @active = false
        super
      end

      def unbind
        @active = false
        if @block
          EventMachine.defer do
            @block.call(:unregister, self)
          end
        end
      end
      
      def stop_service
        tputs ' [BrB] Stop Tunnel service'
        @active = false
        EM.schedule do
          close_connection
        end
      end

      def active?
        @active
      end

      def method_missing(meth, *args)
        return nil if !@active
        new_brb_out_request(meth, *args)
      end
    end
  end

end