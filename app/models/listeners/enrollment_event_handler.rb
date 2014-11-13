module Listeners
  class EnrollmentEventHandler < Amqp::Client
    def validate(delivery_info, properties, payload)
      if properties.headers["enrollment_group_uri"].blank?
        add_error("No enrollment_group_uri")
      end
    end

    def on_message(delivery_info, properties, payload)
      enrollment_group_uri = properties.headers['enrollment_group_uri']
      eg_id = Maybe.new(enrollment_group_uri).split(":").split("#").last.value
      enrollment_props = {
        :routing_key => "enrollment.get_by_id",
        :headers => {
          :enrollment_group_id => eg_id
        }
      }
      di, prop, enrollment = request(enrollment_props, "", 30)
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.enrollment_event_handler"
    end
  end
end
