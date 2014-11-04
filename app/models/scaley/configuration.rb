module Scaley
  class Configuration
    INT_KEYS = [
      "min_workers",
      "max_workers",
      "request_duration",
      "max_duration"
    ]

    STRING_KEYS = [
      "pid_file",
      "queue_name",
      "amqp_uri"
    ]

    attr_accessor(*(INT_KEYS.map(&:to_sym)))
    attr_accessor(*(STRING_KEYS.map(&:to_sym)))

    def initialize(confs)
      @config = confs
      read_properties(@config)
    end

    def needed_workers(backlog_size)
      approx_workers_needed = (backlog_size.to_f * request_duration.to_f)/(max_duration.to_f)
      workers_needed = approx_workers_needed.to_i
      if workers_needed < min_workers
        return min_workers
      elsif workers_needed > max_workers
        return max_workers
      end
      workers_needed
    end

    def adjustment_for(current_workers, backlog_size)
      needed_workers(backlog_size) - current_workers
    end

    def read_properties(conf)
      INT_KEYS.each do |key|
        val = conf[key]
        raise("Configuration value missing: #{key}") if val.blank?
        raise("Invalid value: #{key}, #{val}") if val.to_i < 1
        self.send("#{key}=".to_sym, val.to_i)
      end
      STRING_KEYS.each do |key|
        val = conf[key]
        raise("Configuration value missing: #{key}") if val.blank?
        self.send("#{key}=".to_sym, val)
      end
    end
  end
end
