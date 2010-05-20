require 'spec_helper'

describe :brb_massive_usage do
  before(:all) do
    @brb = BrB::Service
    @brb.stop_service
    @brb_test = BrBTest.new
    open_service(@brb_test)
    @clients = []
    20.times do
      @clients << connect_to_the_service(self, @brb.uri) do |type, tunnel|
      end
    end
  end
  
  def random_client
    @clients[rand(@clients.size)]
  end
  
  # Start the service
  it "should the service be started" do
     @clients.each do |cl|
       cl.should_not be_nil
       cl.active?.should be_true
       cl.uri.should == @brb.uri
     end
  end
  
  it "should works with massive simple messaging" do
     nb_call_before = @brb_test.nb_call || 0
     nb_call_to_do = 500
  
     @clients.each do |cl|
       nb_call_to_do.times do
         cl.noarg
       end
     end
  
     sleep 5
     # Wait a little in order to be sure all the stack is processed
     @brb_test.last_call.should == :noarg
     @brb_test.nb_call.should == (nb_call_to_do * @clients.size) + nb_call_before
   end

  it "should works with massive callbacks" do
    block_called = 0
    nb_callbacks = 1000
    nb_callbacks.times do |i|
      random_client.return_same_value(i) do |callback_return_value|
        callback_return_value.should == i
        block_called += 1
      end
    end

    sleep 2
    # Wait a little in order to be sure the method is called
    @brb_test.last_call.should == :return_same_value
    block_called.should == nb_callbacks
  end
  
  it "should works with massive simple messaging including blocking messaging and callbacks" do
    nb_call_before = @brb_test.nb_call || 0
    nb_call_to_do = 500
    nb_call_blocking_to_do = 50
  
    t = Thread.new do
      @clients.each do |cl|
        nb_call_blocking_to_do.times do
          val = Time.now.to_f
          cl.return_same_value_block(val).should == val
        end
      end      
    end
    
    block_called = 0
    nb_callbacks = 1000
    nb_callbacks.times do |i|
      random_client.return_same_value(i) do |callback_return_value|
        callback_return_value.should == i
        block_called += 1
      end
    end
  
  
    @clients.each do |cl|
      nb_call_to_do.times do
        cl.noarg
      end
    end
  
    sleep 5
    block_called.should == nb_callbacks
    t.join
    # Wait a little in order to be sure all the stack is processed
    @brb_test.nb_call.should == nb_callbacks + (nb_call_to_do * @clients.size + nb_call_blocking_to_do * @clients.size) + nb_call_before
  end

  # Finally, stop the service
  it "should stop the service after usage" do
    @brb.stop_service
    @brb.uri.should be_nil
  end
end
