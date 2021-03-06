require 'spec_helper'

$last_unregistered = nil
$last_registered = nil

describe :brb_tunnel do
  before(:all) do
    @brb = BrB::Service
    @brb.stop_service
    @brb_test = BrBTest.new
    open_service(@brb_test)
    @client = connect_to_the_service(self, @brb.uri) do |type, tunnel|
      if type == :unregister
        $last_unregistered = tunnel
      elsif type == :register
        $last_registered = tunnel
      end
    end
  end
  
  # Start the service
  it "should the service be started" do
    @client.should_not be_nil
    @client.active?.should be_true
    @client.uri.should == @brb.uri
  end
  
  it "should have get the register message" do
    sleep 0.2 # Be sure to get the message
    $last_registered.class.should == @client.class
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
  
  it "should correctly return multiple values" do
    r1, r2 = @client.return_same_value_twice_block(:ret, :ret2)
    r1.should == :ret
    r2.should == :ret2
  end
  
  it "should dump to symbol undumpable value by using the proxy" do
    @client.return_same_value_block(Thread.current).class.should == Symbol
    @client.return_same_value_block(Thread.current).should == Thread.current.to_s.to_sym
  end

  it "should transmit with success exception when blocking" do
    e = nil
    begin
      @client.notavalidmeth_block
    rescue Exception => e
    end
    e.should be_a NameError
  end
  
  it "should use block as non blocking callback with return value" do
    block_called = nil
    @client.return_same_value(:arg) do |v|
      v.should == :arg
      block_called = true
    end
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_call.should == :return_same_value
    block_called.should == true
  end
  
  it "should correctly handle multiple values return with callbacks" do
    block_called = nil
    @client.return_same_value_twice(:ret, :ret2) do |r1, r2|
      r1.should == :ret
      r2.should == :ret2
      block_called = true
    end
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_call.should == :return_same_value_twice
    block_called.should == true
  end
  
  it "should correctly handle no block args return with callbacks" do
    block_called = nil
    @client.return_same_value_twice(:ret, :ret2) do
      block_called = true
    end
    sleep 0.2
    # Wait a little in order to be sure the method is called
    @brb_test.last_call.should == :return_same_value_twice
    block_called.should == true
  end
  
  it "should raise an exception when calling a blocking method with a callback" do
    e = nil
    begin
      @client.return_same_value_block(:arg) do |v|
      end
    rescue Exception => e
    end
    e.should_not be_nil
  end

  # Finally, stop the service
  it "should stop the service after usage" do
    @brb.stop_service
    @brb.uri.should be_nil
  end

  # Finally, stop the client tunnel
  it "should stop the tunnel after usage" do
    @client.stop_service
    @client.active?.should_not be_true
  end

  it "should have get the unregister message" do
    sleep 0.2 # Be sure to get the message
    $last_unregistered.class.should == @client.class
  end
end

