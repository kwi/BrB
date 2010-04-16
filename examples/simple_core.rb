require 'lib/brb'

class ExposedCoreObject
  
  def simple_api_method
    puts "#{Thread.current} > In simple api method, now sleeping"
    sleep 1
    puts "#{Thread.current} > Done sleeping in simple api method, return"
    return 'OK'
  end
  
  def simple_long_api_method
    puts "#{Thread.current} > In simple long api method, now sleeping"
    sleep 10
    puts "#{Thread.current} > Done sleeping in long api method, return"
    return 'OK LONG'
  end
  
end

Thread.abort_on_exception = true

port = 5555
host = 'localhost'

EM::run do
  EM::set_quantum(20)

  puts " > Starting the core on brb://#{host}:#{port}"
  BrB::Service.instance.start_service(:object => ExposedCoreObject.new, :silent => false, :host => host, :port => port)
end
