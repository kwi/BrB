require "logger"

module BrB
  class << self
    
    # returns the default logger instance
    def default_logger
      Logger.new(STDOUT)
    end
    
    # set a custom logger instance
    def logger=(custom_logger)
      @@logger = custom_logger
    end
    
    # returns the logger instance
    def logger
      # use default logger if no custom logger is set
      @@logger = default_logger unless defined? @@logger
      
      # this overwrites the original method with a static definition
      eval %Q{
        def logger
          @@logger
        end
      }
      @@logger
    end
  end
  
  # alias to BrB.logger
  def logger
    BrB.logger
  end
end