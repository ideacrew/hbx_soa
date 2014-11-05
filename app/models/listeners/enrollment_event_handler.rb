module Listeners
  class EnrollmentEventHandler < Amqp::Client
    def on_message(delivery_info, properties, payload)
      
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.enrollment_event_handler"
    end
  end
end
