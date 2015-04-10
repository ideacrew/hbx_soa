module Listeners
  class EventLogShipper < ::Amqp::Client
    def on_message(delivery_info, properties, payload)
      publishing_hash = extract_gelf_hash(delivery_info, properties)
      ec = ExchangeInformation
      published_queue = channel.queue(
        "#{ec.hbx_id}.#{ec.environment}.q.graylog.events",
        { :durable => true }
      )
      published_queue.publish(JSON.dump(publishing_hash.merge("full_message" => payload)), {})
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def level_from_hash(level_name)
      levels = {
         "emergency" => 0,
         "alert" => 1,
         "critical" => 2,
         "error" => 3,
         "warning" => 4,
         "notice" => 5,
         "info" => 6,
         "debug" => 7
      }
      return(6) if !levels.has_key?(level_name.to_s.downcase)
      levels[level_name.to_s.downcase]
    end

    def extract_host(props)
      props_strings = properties.to_hash.stringify_keys
      return({}) if !props_strings.has_key?("host")
      { :host => props_strings["host"] }
    end

    def extract_gelf_hash(delivery_info, properties)
      headers = properties.headers || {}
#      raise delivery_info.routing_key.inspect
      routing_key_string = delivery_info.routing_key
      level_name, facility, *rest = routing_key_string.split(".")
      new_timestamp = extract_timestamp(properties)
      new_properties = { 
        :version => "1.1",
        :timestamp => new_timestamp,
        :facility => facility,
        :short_message => rest.join("."),
        :level => level_from_hash(level_name)
      }.merge(extract_host(properties))
      properties.to_hash.each_pair do |k,v|
        if ![:headers, "headers"].include?(k)
          new_properties["_#{k.to_s}"] = v
        end
      end
      headers.each_pair do |k,v|
        new_properties["_#{k.to_s}"] = v
      end
      new_properties
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.logging.all_events"
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
  end
end
