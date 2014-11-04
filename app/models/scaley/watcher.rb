module Scaley
  class Watcher
    def initialize(enforcer, counter, sample_frequency = 10)
      @enforcer = enforcer
      @counter = counter
      @sample_frequency = sample_frequency
    end

    def mark_for_quit
      @outbound.write("Q")
    end

    def run
      @inbound, @outbound = IO.pipe
      Signal.trap('INT') { mark_for_quit }
      Signal.trap('TERM') { mark_for_quit }
      Signal.trap('QUIT') { mark_for_quit }
      loop do
        fds = IO.select([@inbound],nil,nil,@sample_frequency)
        unless fds.nil?
          data_read = fds.first.first.read(1)
          if data_read == "Q"
            raise StopIteration.new
          end
        end
        do_enforcement
      end
      @inbound.close
      @outbound.close
    end

    def do_enforcement
      @enforcer.enforce(@counter)
    end
  end
end
