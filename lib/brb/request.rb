module BrB
  module Request

    def is_brb_request_blocking?(meth)
      if m = meth.to_s and m.rindex('_block') == (m.size - 6)
        return true
      end
      nil
    end

    # Execute a request on a distant object
    def new_brb_out_request(meth, *args)
      Thread.current[:brb_nb_out] ||= 0
      Thread.current[:brb_nb_out] += 1

      block = is_brb_request_blocking?(meth) ? Thread.current.to_s.to_sym : nil
      if block
        args << block 
        args << Thread.current[:brb_nb_out]
      end

      args.size > 0 ? brb_send([:s, meth, args]) : brb_send([:s, meth])

      # Block jusqu'au retour de la requete
      if block
        #TimeMonitor.instance.watch_thread!(@timeout_rcv_value || 45)
        begin
          r = recv(block, Thread.current[:brb_nb_out])
        rescue Exception => e
          #@object.log_error(e, "Error sending out request #{meth}(#{args.inspect})")
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
          #TimeMonitor.instance.watch_thread!(25)
          r = ((args.size > 0) ? @object.send(m, *args) : @object.send(m))
          brb_send([:r, r, thread, idrequest])
        rescue Exception => e
          brb_send([:r, e, thread, idrequest])
          tputs e.to_s
          tputs e.backtrace.join("\n")
          #raise e
        ensure
          #TimeMonitor.instance.remove_thread!
        end
      else

        begin
          (args.size > 0) ? @object.send(meth, *args) : @object.send(meth)
        rescue Exception => e
          tputs "#{e.to_s} => By calling #{meth} on #{@object.class} with args : #{args.inspect}"
          tputs e.backtrace.join("\n")
          raise e
        end

      end

    end

  end
end