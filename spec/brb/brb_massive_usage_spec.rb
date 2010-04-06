# require File.dirname(__FILE__) + '/../spec_helper'
# 
# describe :brb_service do
#   before(:all) do
#     @brb = BrB::Service.instance
#     @brb.stop_service
#     @brb_test = BrBTest.new
#     open_service
#   end
#   
#   def open_service(host = 'localhost', port = 6200)
#     Thread.new do
#       EventMachine::run do
#         EventMachine::set_quantum(20)
#         # Create a Brb service and expose the object BrbTest
#         BrB::Service.instance.start_service(:object => @brb_test, :silent => true, :nb_worker => 5, :host => host, :port => port)
#       end
#     end
#   end
# 
#   # Start the service
#   it "should open a service on localhost:6200" do
#     @brb.uri.should_not be_nil
#   end
#   
#   # Finally, stop the service
#   it "should stop the service" do
#     @brb.stop_service
#     @brb.uri.should be_nil
#   end
#   
#   it "should start again the service after a stop" do
#     open_service
#     @brb.stop_service
#     open_service
#     @brb.uri.should_not be_nil
#   end
# end
# 
