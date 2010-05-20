# Future BrB custom exceptions will come here
class BrBException < Exception
end

class BrBCallbackWithBlockingMethodException < BrBException
  def initialize
    super('Out request can not be blocking and have a callback at the same time !')
  end
end
