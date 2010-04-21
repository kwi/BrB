require 'spec_helper'

describe :brb_service do
  before(:all) do
    @brb = BrB::Service
    @brb.stop_service
    @brb_test = BrBTest.new
    open_service(self)
  end
  
  # Start the service
  it "should open a service on localhost:6200" do
    @brb.uri.should_not be_nil
  end

  # Finally, stop the service
  it "should stop the service" do
    @brb.stop_service
    @brb.uri.should be_nil
  end

  it "should start again the service after a stop" do
    open_service(self)
    @brb.stop_service
    open_service(self)
    @brb.uri.should_not be_nil
  end
end

