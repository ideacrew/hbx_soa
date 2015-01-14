module Listeners
  class EventLoggingListener < ::Amqp::Client
    def on_message(delivery_info, properties, payload)
      ex = channel.fanout(ExchangeInformation.event_publish_exchange, {:durable => true})
      if old_event_format?(delivery_info)
        publishing_hash = fix_message_properties(delivery_info, properties)
        ex.publish(payload, publishing_hash)
      end
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def old_event_format?(delivery_info)
      rk = delivery_info.routing_key
      rk_start = rk.split(".").first
      !proper_logging_patterns.include?(rk_start)
    end

    def fix_message_properties(delivery_info, properties)
      new_routing_key = "info.events." + delivery_info.routing_key
      properties.to_hash.merge(:routing_key => new_routing_key)
    end

    def proper_logging_patterns
      [
        "emergency",
        "alert",
        "critical",
        "error",
        "warning",
        "notice",
        "info",
        "debug"
      ]
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.event_logger"
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      q = ch.queue(queue_name, :durable => true)

      self.new(ch, q).subscribe(:block => true, :manual_ack => true)
    end
  end
end
