# Define a BrB::Protocol using event machine
require 'eventmachine'

module BrB
  class EventMachine

    class << self

    private
      # If EM::run has not been called yet, start the EM reactor in another thread.
      def ensure_em_is_started!
        if !EM::reactor_running?
          # Launch event machine reactor
          q = Queue.new
          Thread.new do
            EM::run do
              q << true # Set to the calling thread that the reactor is running
              #EM::set_quantum(20)
              #EventMachine::epoll
            end
          end
          # Wait for event machine running :
          q.pop
        end

      end

    public
      def open(uri, klass, opts = {})
        host, port = parse_uri(uri)
        begin
          ensure_em_is_started!
      
          q = Queue.new
          EM.schedule do
            q << EM::connect(host, port, klass, opts.merge(:uri => "brb://#{host}:#{port}"))
          end
          
          # Wait for socket connection with the q.pop
          return q.pop

        rescue Exception => e
          puts e.backtrace.join("\n")
          raise "#{e} - #{uri}"
        end
      end

      def open_server(uri, klass, opts = {})
        host, port = parse_uri(uri)
        max = 80 # Nb try before giving up
        begin
          uri = "brb://#{host}:#{port}"
          ensure_em_is_started!

          # Schedule server creation for thread safety
          q = Queue.new
          EM.schedule do
            q << EM::start_server(host, port, klass, opts.merge(:uri => uri))
          end

          # Wait for server creation with the q.pop
          return uri, q.pop

        rescue Exception => e
          max -= 1
          port += 1
          retry if max > 0
          puts e.backtrace.join("\n")
          raise "#{e} - BrB Tcp Event machine Can not bind on #{host}:#{port}"
        end

      end
    end
  end
  
  class Protocol < EventMachine

    class << self

      def parse_uri(uri)
        if /^brb:\/\/(.+):([0-9]+)$/ =~ uri 
          [$1, $2.to_i]
        else
          raise "Bad tcp BrB url: '#{uri}'"
        end
      end

    end
  end
end

