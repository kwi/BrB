require 'lib/srv/brb/brb'

class BrBTest
  def initialize(uri)
    @uri = uri.blank? ? nil : uri
  end
  
  def very_long(ar)
    puts 'in very long'
  end
  def salut(arg1, arg2, arg3, arg4)
    puts "in salut"
    puts arg1
    puts arg2
    puts arg3
    puts arg4
  end
  def noarg
    puts "No arg !"
  end
  def yo(ar)
    puts 'yo'
    #sleep 0.2
    return 'retour de yo !!!'
  end

  def test_brb(brb)
    sleep 1
    puts "Start test"

    brb.noarg
    brb.salut('coucou', 'var2', 'var3', 'var4')
    brb.yo('coucou')
    15.times do
      puts brb.yo_block('coucou block')
    end

    
    10.times do
      Thread.new do
        150.times do
          puts brb.yo_block('Test yo block dans un thread')
        end
      end
    end

    #brb.very_long('coucou d' * 65000)

    1.times do
      brb.very_long('coucou block' * 15000)
      brb.very_long('coucou d' * 35000)
      brb.very_long('coucou d' * 65000)
      brb.very_long('coucou d' * 100000)
    end
    
    5.times do
      puts "FINAL TEST"
    end
    
    700.times do
      puts brb.yo('coucou block')
      puts brb.yo_block('coucou block')
    end
    

    15.times do
      puts 'TEST is over'
    end
  end

  # Lance le test
  def go
    Thread.abort_on_exception = true

    #EventMachine::epoll
    EventMachine::run do
      EventMachine::set_quantum(10)

      if @uri
        BrB::Service.instance.start_service(:object => self)
        brb = BrB::Tunnel.create(self, @uri)
        sleep 5
        test_brb(brb)
      else
        BrB::Service.instance.start_service(:object => self) do |type, obj|
          puts "New tunnel connected : #{type}"
          sleep 5
          test_brb(obj)
        end
      end
  
      puts " NOw make request !"
    end

    BrB::Service.instance.stop_service
  end
end