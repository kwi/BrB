require 'lib/brb'

port = 5555
host = 'localhost'

EM::run do
  EM::set_quantum(20)
  # Connecting to the core server, retrieving its interface object : core
  # We do not want to expose an object, so the first parameter is nil
  core = BrB::Tunnel.create(nil, "brb://#{host}:#{port}", :silent => false)

  # Create thread here, as you can not block the EventMachine::run block
  Thread.new do

    # Calling 10 times an non blocking method on the distant core server
    10.times do
      core.simple_api_method # Do not wait for response
    end
    
    # Calling 10 times again long treatment time distant methods
    10.times do
      core.simple_long_api_method # Do not wait for response
    end

    # Calling a blocking method with _block on the distant core server :
    puts " >> Calling 1s call, and wait for response..."
    r = core.simple_api_method_block
    puts " > Api response : #{r}"
    
    puts " >> Calling long call, and wait for response..."
    r = core.simple_long_api_method_block
    puts " > Api long response : #{r}"

    # Our job is over, close
    EM.stop
  end
end
