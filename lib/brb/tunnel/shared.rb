# encoding: utf-8

module BrB
  module Tunnel
    module Shared
      def make_proxy(r)
        if r.is_a?(Array)
          t = []
          r.each do |obj|
            t << if obj.is_a? Array
              make_proxy(obj)
            elsif !obj.is_a?(Symbol) and !obj.is_a?(String) and obj and !(Marshal::dump(obj) rescue nil)
              #BrB.logger.debug "  - > Make proxy for : #{obj.class}"
              obj.to_s.to_sym
            else
              obj
            end
          end
          return t
        else
          return r.to_s
        end
      end

      def brb_send(r)
        return nil if !@active
        s = Marshal::dump(r) rescue Marshal::dump(make_proxy(r))

        s = [s.size].pack('N') + s
        EM.schedule do
          send_data s
        end
      end

      SizeOfPackedInt = [1].pack('N').size

      def load_request
        return nil if @buffer.size < SizeOfPackedInt
        len = @buffer.unpack('N').first + SizeOfPackedInt
        if @buffer.size < len
          return nil
        end

        obj =  Marshal::load(@buffer[SizeOfPackedInt, len])
        @buffer.slice!(0,len)
        return obj
      end

      def receive_data(data)
        @buffer << data
        
        while obj = load_request
          if obj[0] == BrB::Request::ReturnCode

            # Return if we have a callback handling the return :
            next if treat_callback_return(obj[1], obj[2], obj[3])

            # No callback, so blocking thread is waiting :
            @replock.lock
            @responses[obj[2]] ||= Queue.new
            @replock.unlock
            @responses[obj[2]] << [obj[1], obj[3]]
          else
            @queue << obj

            EM.defer do
              treat_request(@queue.pop)
            end
            
          end
        end
      end

      def treat_request(obj)
        if obj.size == 2
          new_brb_in_request(obj[1])
        else
          new_brb_in_request(obj[1], *(obj.last))
        end
      end

      # Declare a new callback to call for a given request
      # Thread safe code
      def declare_callback(key, nb_out, &block)
        @callbacks_mutex.lock

        @callbacks[key] ||= {}
        @callbacks[key][nb_out] = block

      ensure
        @callbacks_mutex.unlock
      end
      
      # Return associated callback if present
      # And if present, delete the associate callback from the table
      # Thread safe code
      def get_callback(key, nb_out)
        @callbacks_mutex.lock
        
        if @callbacks[key] and b = @callbacks[key].delete(nb_out)
          return b
        end

      ensure
        @callbacks_mutex.unlock
      end
      
      # Call a callback if present, return true if exists
      # Non blocking action, use EM.defer
      def treat_callback_return(ret, key, nb_out)

        if b = get_callback(key, nb_out)
          EM.defer do
            # With arity, handle multiple block arguments or no arguments
            b.arity == 1 ? b.call(ret) : (b.arity == 0 ? b.call : b.call(*ret)) 
          end

          # A callback has been found and called, return true
          return true
        end
        
        # No callback, do nothing
        return nil
      end

      # Blocking method that wait on the @responses table an answer
      def recv(key, nb_out)
        begin
          @replock.lock
          r = @responses[key] ||= Queue.new
          @replock.unlock
          while rep = r.pop
            if rep[1] == nb_out # On check ke c'est bien la réponse que l'on attend
              
              # Call the callback
              if block_given?
                yield(rep[0])
              end

              return rep[0]
            end
            if rep[1] > nb_out
              return nil
            end
          end
        rescue Exception => e
          if @close_after_timeout == true
            stop_service
            sleep 1
            raise e
          else
            raise e
          end
        end
      end
    end
  end
end