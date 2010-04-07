require 'eventmachine'

# Define a BrBProtocol using event machine
class BrBEventMachine

  def self.parse_uri(uri)
    if /^brb:\/\/(.+):([0-9]+)$/ =~ uri 
      [$1, $2.to_i]
    else
      raise "Bad tcp BrB url: '#{uri}'"
    end
  end

  def self.open(uri, klass, opts = {})
    host, port = parse_uri(uri)
    begin
      socket = EventMachine::connect host, port, klass, opts.merge(:uri => "brb://#{host}:#{port}")

    rescue Exception => e
      puts e.backtrace.join("\n")
      raise "#{e} - #{uri}"
    end
    return socket
  end

  def self.open_server(uri, klass, opts = {})
    host, port = parse_uri(uri)
    max = 80
    begin
      #EventMachine::epoll
      uri = "brb://#{host}:#{port}"
      return uri, EventMachine::start_server(host, port, klass, opts.merge(:uri => uri))
    rescue Exception => e
      max -= 1
      port += 1
      retry if max > 0
      puts e.backtrace.join("\n")
      raise "#{e} - BrB Tcp Event machine Can not bind on #{host}:#{port}"
    end
  end
end

class BrBProtocol < BrBEventMachine
end