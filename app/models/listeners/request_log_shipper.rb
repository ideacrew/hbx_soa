module Listeners
  class RequestLogShipper < ::Amqp::Client
    def on_message(delivery_info, properties, payload)
      publishing_hash = extract_gelf_hash(delivery_info, properties)
      ec = ExchangeInformation
      published_queue = channel.queue(
        "#{ec.hbx_id}.#{ec.environment}.q.graylog.events",
        { :durable => true }
      )
      utf8_payload = payload.nil? ? "" : payload.force_encoding("utf-8")
      published_queue.publish(JSON.dump(publishing_hash.merge("full_message" => utf8_payload)), {})
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def extract_host(props)
      props_strings = props.to_hash.stringify_keys
      return({}) if !props_strings.has_key?("host")
      { :host => props_strings["host"] }
    end

    def extract_gelf_hash(delivery_info, properties)
      headers = properties.headers || {}
      routing_key_string = delivery_info.routing_key
      new_timestamp = extract_time_value(properties.to_hash.dup)
      new_properties = { 
        :version => "1.1",
        :timestamp => new_timestamp.to_i,
        :facility => "request",
        :short_message => routing_key_string,
        :level => 6
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

    def extract_time_value(props)
      time_from_submitted = extract_start_time(props)
      time_from_timestamp = extract_timestamp_prop(props)
      if !time_from_submitted.nil?
        return time_from_submitted
      elsif !time_from_timestamp.nil?
        return time_from_timestamp
      end
      Time.now
    end

    def extract_timestamp_prop(props)
      if props.has_key?(:timestamp)
        return(Time.at(props[:timestamp].to_i) rescue nil)
      elsif props.has_key?("timestamp")
        return(Time.at(props["timestamp"].to_i) rescue nil)
      end
    end

    def extract_start_time(props)
      headers = props[:headers] || {}
      if headers.has_key?("submitted_timestamp")
        return(parse_submitted_at(headers["submitted_timestamp"]))
      elsif headers.has_key?(:submitted_timestamp)
        return(parse_submitted_at(headers[:submitted_timestamp]))
      end
      nil
    end

    def parse_submitted_at(val)
      if val.kind_of?(Time)
        return val
      end
      ActiveSupport::TimeZone.new("UTC").parse(val) rescue nil
    end

    def self.queue_name
      ec = ExchangeInformation
      "#{ec.hbx_id}.#{ec.environment}.q.logging.all_requests"
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
