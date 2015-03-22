module Listeners
  class EnrollmentEventHandler < Amqp::Client
    def validate(delivery_info, properties, payload)
      if properties.headers["enrollment_group_uri"].blank?
        add_error("No enrollment_group_uri")
      end
    end

    def on_message(delivery_info, properties, payload)
      enrollment_group_uri = properties.headers['enrollment_group_uri']
      eg_id = Maybe.new(enrollment_group_uri).split(":").last.split("#").last.value
      enrollment_props = {
        :routing_key => "enrollment.get_by_id",
        :headers => {
          :enrollment_group_id => eg_id
        }
      }
      di, prop, enrollment = request(enrollment_props, "", 10)
      handle_enrollment_response(prop, enrollment, properties.headers.to_hash.dup)
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def create_enrollment(enrollment_payload, original_headers, qr_uri)
       request_props = {
         :routing_key => "enrollment.create",
         :headers => {
           :qualifying_reason_uri => qr_uri
         }
       }

       di, prop, payload = request(request_props, enrollment_payload, 30)
       return_code = prop.headers["return_status"]
       case return_code
       when "200"
       else
        channel.direct(ExchangeInformation.request_exchange, {:durable => true}).publish(
          payload,
          {
            :routing_key => "enrollment.error",
            :headers => original_headers.merge({:return_status => return_code})
          }
        )
      end
    end

    def handle_enrollment_response(props, payload, original_headers)
      qr_uri = props.headers["qualifying_reason_uri"]
      return_code = props.headers["return_status"]
      case return_code
      when "200"
        create_enrollment(payload, original_headers, qr_uri)
      else
        channel.direct(ExchangeInformation.request_exchange, {:durable => true}).publish(
          payload,
          {
            :routing_key => "enrollment.error",
            :headers => original_headers.merge({:return_status => return_code})
          }
        )
      end
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
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.enrollment_event_handler"
    end
  end
end
