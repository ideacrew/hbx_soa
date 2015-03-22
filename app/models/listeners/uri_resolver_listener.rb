module Listeners
  class UriResolverListener < Amqp::Client
    def validate(delivery_info, properties, payload)
      if properties.headers["reference_uri"].blank?
        add_error("No reference to resolve!")
      end
      if properties.reply_to.blank?
        add_error("No reply to!")
      end
    end

    def send_response(reply_to, reference_uri, uri = nil)
      response_properties = {
        :routing_key => reply_to,
        :headers => {
          :reference_uri => reference_uri,
          :return_status => (uri.blank? ? "404" : "200"),
          :uri => uri.to_s
        }
      }
      channel.default_exchange.publish("", response_properties)
    end

    def on_message(delivery_info, properties, payload)
      reference = properties.headers['reference_uri']
      reply_to = properties.reply_to
      uri = UriReference.resolve_uri(reference)
      send_response(reply_to, reference, uri)
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      q = ch.queue(queue_name, :durable => true)

      self.new(ch, q).subscribe(:block => true, :manual_ack => true)
      conn.close
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.uri_resolver"
    end
  end
end
