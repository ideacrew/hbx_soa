module Scaley
  class Enforcer

    def initialize(config)
      @configuration = config
      @pid = read_pid_file
    end

    def enforce(counter)
      info_hash = counter.statistics
      adjust_workers_for(info_hash[:workers], info_hash[:backlog])
    end

    def adjust_workers_for(current_workers, backlog_size)
      adjustment_needed = @configuration.adjustment_for(current_workers, backlog_size)
      return if adjustment_needed == 0
      adjust_workers_by(adjustment_needed)
    end

    def adjust_workers_by(amount)
      sig = (amount > 0) ? :TTIN : :TTOU
      amount.abs.times do
        Process.kill(sig, @pid)
        sleep(0.2)
      end
    end

    def read_pid_file
      File.read(@configuration.pid_file).to_i
    end

  end
end
