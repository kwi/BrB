require File.dirname(__FILE__) + '/../spec_helper'

describe :brb_service do
  before(:all) do
    @brb = BrB::Service.instance
    @brb.stop_service
    @brb_test = BrBTest.new
    open_service(@brb_test)
    @client = connect_to_the_service(self, @brb.uri) do |type, tunnel|
    end
  end
  
  def open_service(object, host = 'localhost', port = 6200)
    Thread.new do
      EventMachine::run do
        EventMachine::set_quantum(20)
        # Create a Brb service and expose the object BrbTest
        BrB::Service.instance.start_service(:object => object, :silent => true, :nb_worker => 5, :host => host, :port => port)
      end
    end
  end

  def connect_to_the_service(object_exposed, uri, &block)
    BrB::Tunnel.create(object_exposed, uri, :silent => true, &block)
  end

  # Start the service
  it "should the service be started" do
    @client.should_not be_nil
    @client.uri.should == @brb.uri
  end
  
  it "should correctly call simple distant method without args and without return" do
    @client.noarg
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_call.should == :noarg
  end
  
  it "should correctly call simple distant method without args and without return multipe times" do
    nb_call_before = @brb_test.nb_call
    nb_call_to_do = 50
    
    nb_call_to_do.times do
      @client.noarg
    end
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_call.should == :noarg
    @brb_test.nb_call.should == nb_call_to_do + nb_call_before
  end
  
  it "should correctly call distant method with one argument" do
    @client.very_long(:hello)
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_args.should == [:hello]
  end
  
  it "should correctly call distant method with multiple arguments" do
    args = [:one, :two, 3, "four"]
    @client.fourargs(*args)
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_args.should == args
  end

  it "should correctly return arguments symbol value" do
    @client.one_arg_with_return_block(:hello).should == :hello
  end

  it "should correctly return arguments string value" do
    @client.one_arg_with_return_block('hello').should == 'hello'
  end
  
  it "should correctly return arguments Fixnum value" do
    @client.one_arg_with_return_block(42).should == 42
  end
  
  it "should correctly return arguments Float value" do
    @client.one_arg_with_return_block(42.42).should == 42.42
  end
  
  it "should correctly return arguments Table value" do
    @client.one_arg_with_return_block([:one, :two, 3, "four"]).should == [:one, :two, 3, "four"]
  end
  
  it "should correctly return arguments Hash value" do
    h = {:yoyo => :titi, "salut" => 45}
    @client.one_arg_with_return_block(h).should == h
  end
  
  it "should do nothing for unknow method when no blocking" do
    e = nil
    begin
      @client.notavalidmeth
    rescue Exception => e
    end
    e.should be_nil
  end
  
  it "should transmit with success exception when blocking" do
    e = nil
    begin
      @client.notavalidmeth_block
    rescue Exception => e
      
    end
    e.should be_a NameError
  end

  # Finally, stop the service
  it "should stop the service after usage" do
    @brb.stop_service
    @brb.uri.should be_nil
  end
end

