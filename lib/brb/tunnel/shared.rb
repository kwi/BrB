# encoding: utf-8

module BrB
  module Tunnel
    module Shared
      def tputs(s)
        puts s if !@silent
      end

      def make_proxy(r)
        if r.is_a?(Array)
          t = []
          r.each do |obj|
            t << if obj.is_a? Array
              make_proxy(obj)
            elsif !obj.is_a?(Symbol) and !obj.is_a?(String) and obj and !(Marshal::dump(obj) rescue nil)
              puts "  - > Make proxy for : #{obj.class}"
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
        #EventMachine.defer do
        #tputs " >> Send : #{[s.size].pack('N') + s}    | (#{([s.size].pack('N') + s).size})"
        #tputs " >> Send : #{s}    | (#{([s.size].pack('N') + s).size})"

        s = [s.size].pack('N') + s
        EM.schedule do
          send_data s
        end
        #tputs " >> Send done "
        #end
      end

      SizeOfPackedInt = [1].pack('N').size

      def load_request
        return nil if @buffer.size < SizeOfPackedInt
        len = @buffer.unpack('N').first + SizeOfPackedInt
        #puts " >> Wait for #{len}"
        if @buffer.size < len
          return nil#, (len - @buffer.size)
        end

        obj =  Marshal::load(@buffer[SizeOfPackedInt, len])
        @buffer.slice!(0,len)
        #tputs "Buffer after load: #{@buffer}    (#{@buffer.size})"
        #tputs "Buffer after load: dump: #{@buffer.dump}"
        return obj
      end

      def receive_data(data)
        #tputs "RCV: #{data} (#{data.class})"
        #tputs "RCV dump: #{data.dump} (#{data.size})"
        @buffer << data
        
        #tputs "RCV dump full buffer: #{@buffer} | #{data.dump} (#{@buffer.size})"
    
        while obj = load_request
          if obj[0] == :r
            # ICI, on a recu une réponse
            #tputs "Get response ! on key"
            #tputs obj.last
            @replock.lock
            @responses[obj[2]] ||= Queue.new
            @replock.unlock
            @responses[obj[2]] << [obj[1], obj[3]]
          else

            @queue << obj

            EventMachine.defer do
              #puts "-- Trat : #{obj.to_yaml}"
              treat_request(@queue.pop)
              #puts "-- Over"
            end
            
            #puts "  > Queue size : #{@queue.size} (buff size : #{@buffer.size})"
            
          end
        end
        #tputs "Leave receive"
      end

      def treat_request(obj)
        #puts "Treeeat : #{obj.to_yaml}"
        #puts obj.to_yaml
        #puts " > treat request #{obj[1]} : #{error?}"
        if obj.size == 2
          new_brb_in_request(obj[1])
        else
          new_brb_in_request(obj[1], *(obj.last))
        end
        #puts " > Done ! "
        
      end

      def recv(key, nb_out)
        begin
          @replock.lock
          r = @responses[key] ||= Queue.new
          @replock.unlock
          #puts " >> Wait response #{nb_out}"
          while rep = r.pop
            #puts " >>>>>> Get rep  #{rep[1]} #{rep.inspect}"
            if rep[1] == nb_out # On check ke c'est bien la réponse que l'on attend
              return rep[0]
            end
            Error.create(:backtrace => "Error in Brb receiving in thread #{Thread.current}. Try to get #{nb_out} request id, but get #{rep[1]}", :type => 'BrBRecvBadId', :url => "#{@object.class}-#{@uri}")
            if rep[1] > nb_out
              return nil
            end
          end
        rescue Exception => e
          if @close_after_timeout == true
            Error.create(:backtrace => "Error in Rcv in thread #{Thread.current}. Try to get #{nb_out} => Stop service #{e.class.to_s}\n\n#{e.backtrace.join("\n")}", :type => e.to_s, :url => "#{@object.class}-#{@uri}")
            stop_service
            sleep 1
            raise e
          else
            raise e
          end
        end
        #(@responses[key] ||= Queue.new).pop
      end
    end
  end
end