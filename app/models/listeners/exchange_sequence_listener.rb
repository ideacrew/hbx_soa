module Listeners
  class ExchangeSequenceListener < Amqp::Client
    def validate(delivery_info, properties, payload)
      if properties.headers["sequence_name"].blank?
        add_error("No sequence name")
      end
      if properties.reply_to.blank?
        add_error("No reply to!")
      end
    end

    def send_response(reply_to, status, body)
      response_properties = {
        :routing_key => reply_to,
        :headers => {
          :return_status => status
        }
      }
      channel.default_exchange.publish(body, response_properties)
    end

    def on_message(delivery_info, properties, payload)
      count_header = properties.headers['count']
      the_count = count_header.blank? ? 1 : count_header.to_i
      sequence_name = properties.headers['sequence_name']
      reply_to = properties.reply_to
      result = ExchangeSequence.generate_identifiers(sequence_name, the_count)
      if result.nil?
        send_response(reply_to, "404", "")
      else
        send_response(reply_to, "200", JSON.dump(result.last))
      end
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      q = ch.queue(queue_name, :durable => true)

      self.new(ch, q).subscribe(:block => true, :manual_ack => true)
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.exchange_sequence_listener"
    end
  end
end
