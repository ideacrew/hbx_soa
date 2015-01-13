module Listeners
  class RequestLoggingListener
    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.request_logger"
    end
  end
end
