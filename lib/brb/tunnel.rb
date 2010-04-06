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
        #set_comm_inactivity_timeout(600)
        @active = true
        if @block
          EventMachine.defer do
            @block.call(:register, self)
          end
        end
      end
      
      def close_connection(after_writing = false)
        @active = false
        Error.create(:backtrace => (@object.server_status + "\nreport_connection_error_status:\n"+ @object.xray), :type => 'CloseConnection', :url => "#{@object.class}-#{@uri}")
        super
      end

      def unbind
        #puts "Unbind"
        @active = false
        Error.create(:backtrace => (@object.server_status + "\nreport_connection_error_status:\n"+ @object.xray), :type => 'UnbindEventMachine', :url => "#{@object.class}-#{@uri}")
        #puts "NB connec : #{EventMachine::connection_count}"
        if @block
          #puts "Call Unregister"
          EventMachine.defer do
            @block.call(:unregister, self)
          end
          #puts "Call Unregister > done"
          # Libere les threads qui blockait en attente d'une réponse
#          Thread.list.each do |t|
#            if @responses[t.to_s.to_sym] and t.stop?
#              puts "Libere le thread : #{t} du blockage | statuts:#{t.status} | stop:#{t.stop?} | alive:#{t.alive?}"
#              t.wakeup
#              puts "Libere le thread (Done) : #{t} du blockage | statuts:#{t.status} | stop:#{t.stop?} | alive:#{t.alive?}"
#            end
#          end
        end
        #puts "NB connec : #{EventMachine::connection_count}"
      end
      
      def stop_service
        #puts "NB connec : #{EventMachine::connection_count}"
        tputs ' [BrB] Stop Tunnel service'
        @active = false
        EM.schedule do
          close_connection
        end
        #puts "NB connec : #{EventMachine::connection_count}"
      end

      def method_missing(meth, *args)
        #t = Time.now.to_f
        #puts " Send req : #{meth}"
        #raise 'Tunnel is not active for a request' if !@active
        return nil if !@active
        r = new_brb_out_request(meth, *args)
        #tputs " - Time to send request : #{(Time.now.to_f - t).round(4)}ms"
        return r
      end
    end
  end

end