require 'rubygems'
require 'spec'

#Thread.abort_on_exception = true

require File.dirname(__FILE__) + '/../init.rb'

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
end