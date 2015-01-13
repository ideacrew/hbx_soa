module Listeners
  class EventLoggingListener
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.event_logger"
    end
  end
end
