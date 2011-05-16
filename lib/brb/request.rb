module BrB
  module Request
    
    MessageRequestCode  = :s
    CallbackRequestCode = :c
    ReturnCode          = :r

    def is_brb_request_blocking?(meth)
      if m = meth.to_s and m.rindex('_block') == (m.size - 6)
        return true
      end
      nil
    end

    # Execute a request on a distant object
    def new_brb_out_request(meth, *args, &blck)
      Thread.current[:brb_nb_out] ||= 0
      Thread.current[:brb_nb_out] += 1

      raise BrBCallbackWithBlockingMethodException.new if is_brb_request_blocking?(meth) and block_given?

      block = (is_brb_request_blocking?(meth) or block_given?) ? Thread.current.to_s.to_sym : nil
      if block
        args << block 
        args << Thread.current[:brb_nb_out]
      end
      
      if block_given?
        # Simulate a method with _block in order to make BrB send the answer
        meth = "#{meth}_block".to_sym
      end

      args.size > 0 ? brb_send([MessageRequestCode, meth, args]) : brb_send([MessageRequestCode, meth])

      if block_given?
        # Declare the callback
        declare_callback(block, Thread.current[:brb_nb_out], &blck)

      elsif block # Block until the request return

        #TimeMonitor.instance.watch_thread!(@timeout_rcv_value || 45)
        begin
          r = recv(block, Thread.current[:brb_nb_out], &blck)
        rescue Exception => e
          raise e
        ensure
          #TimeMonitor.instance.remove_thread!
        end
        if r.kind_of? Exception
          raise r
        end
        return r
      end

      nil
    end

    # Execute a request on the local object
    def new_brb_in_request(meth, *args)

      if is_brb_request_blocking?(meth)

        m = meth.to_s
        m = m[0, m.size - 6].to_sym

        idrequest = args.pop
        thread = args.pop
        begin
          r = ((args.size > 0) ? @object.send(m, *args) : @object.send(m))
          brb_send([ReturnCode, r, thread, idrequest])
        rescue Exception => e
          brb_send([ReturnCode, e, thread, idrequest])
          BrB.logger.error e.to_s
          BrB.logger.error e.backtrace.join("\n")
          #raise e
        end
      else

        begin
          (args.size > 0) ? @object.send(meth, *args) : @object.send(meth)
        rescue Exception => e
          BrB.logger.error "#{e.to_s} => By calling #{meth} on #{@object.class} with args : #{args.inspect}"
          BrB.logger.error e.backtrace.join("\n")
          raise e
        end

      end

    end

  end
end