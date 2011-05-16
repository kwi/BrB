#
# Brb Main class used to do basic distributed ruby, Simple but fast
# Use two distinct canal, one for the command reception, and the other one for send return value
#
module BrB
  class Service
    @@uri = nil
    @@em_signature = nil
    @@verbose = false
    
    class << self

    public

      # Start a server hosted on the object given,
      # If an uri is given, automatcilay connect to the distant brb object
      def start_service(opts = {}, &block)
        return if @@em_signature
  
        @@verbose = opts[:verbose]
        BrB.logger.level = @@verbose ? Logger::INFO : Logger::WARN

        addr = opts[:uri] || "brb://#{opts[:host] || 'localhost'}:#{opts[:port] || 6200}"

        BrB.logger.info " [BrB] Start service on #{addr} ..."
        @@uri, @@em_signature = BrB::Protocol::open_server(addr, BrB::Tunnel::Handler, opts.merge(:block => block))
        BrB.logger.info " [BrB] Service started on #{@@uri}"
      end

      def uri
        @@uri
      end

      # Stop the Brb Service
      def stop_service
        return if !@@em_signature or !EM::reactor_running?
      
        BrB.logger.info " [BrB] Stop service on #{@@uri}"
        sign = @@em_signature
        q = Queue.new # Creation of a Queue for waiting server to stop
        EM::schedule do
          q << EM::stop_server(sign)
        end
        q.pop
        @@em_signature = nil
        @@uri = nil
      end
      
      # Deprecated old method
      def instance
        BrB.logger.warn "DEPRECATION WARNING: BrB::Service::instance is deprecated => Just use BrB::Service"
        self
      end
    end
  end
end