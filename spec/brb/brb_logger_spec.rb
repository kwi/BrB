require 'spec_helper'

class CustomLogger
  attr_accessor :level, :history
  def initialize
    @history = []
  end
  def info(msg)
    @history << msg
  end
  alias :error :info
  alias :warn :info
  alias :debug :info
end

describe :brb_logger do
  before(:each) do
    @original_logger = BrB.logger
  end
  
  after(:each) do
    BrB.logger = @original_logger
  end
  
  it 'should be assigned a default logger' do
    BrB.logger.should_not be_nil
    BrB.logger.class.should == Logger
  end
  
  it 'should be possible to use a custom logger' do
    BrB.logger = CustomLogger.new
    BrB.logger.info('foo')
    BrB.logger.history.last.should == 'foo'
  end
end