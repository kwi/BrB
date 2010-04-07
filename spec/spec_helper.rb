require 'rubygems'
require 'spec'

Thread.abort_on_exception = true

require File.dirname(__FILE__) + '/../init.rb'

def open_service(object, host = 'localhost', port = 6200)
  if !EM::reactor_running?
    # Launch event machine reactor
    Thread.new do
      EM::run do
        EM::set_quantum(20)
      end
    end
    sleep 0.05
  end
  r = nil
  EM.schedule do
    r = BrB::Service.instance.start_service(:object => object, :silent => true, :host => host, :port => port)
  end
  sleep 0.1
  return r
end

def connect_to_the_service(object_exposed, uri, &block)
  r = nil
  EM.schedule do
    r = BrB::Tunnel.create(object_exposed, uri, :silent => true, &block)
  end
  sleep 0.1
  return r
end

class BrBTest
  attr_reader :last_call
  attr_reader :last_args
  attr_reader :nb_call
  
  def increment_nb_call(call_name, *args)
    @last_call = call_name
    @last_args = args
    @nb_call ||= 0
    @nb_call += 1
  end
  
  def very_long(ar)
    increment_nb_call(:very_long, ar)
  end

  def fourargs(arg1, arg2, arg3, arg4)
    increment_nb_call(:fourargs, arg1, arg2, arg3, arg4)
  end

  def noarg
    increment_nb_call(:noarg)
  end

  def one_arg_with_return(ar)
    increment_nb_call(:one_arg_with_return)
    return ar
  end
  
  def return_same_value(val)
    increment_nb_call(:return_same_value)
    return val
  end
end