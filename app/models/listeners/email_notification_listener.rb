module Listeners
  class EmailNotificationListener < Amqp::Client
    def validate(delivery_info, properties, payload)
      headers = properties.headers || {}
      if properties.headers.nil?
        add_error("No headers!")
      end
      if headers["recipient"].blank?
        add_error("No recipient")
      end
      if headers["subject"].blank?
        add_error("No subject")
      end
    end

    def on_message(delivery_info, properties, payload)
      subject = properties.headers['subject']
      recipient = properties.headers['recipient']
      body = payload
      Pony.mail({
        :to => recipient,
        :from => "no-reply@shop.dchealthlink.com",
        :subject => subject,
        :body => body,
        :via => :smtp,
        :via_options => {
          :to => recipient,
          :from => "no-reply@shop.dchealthlink.com",
          :host => "smtp4.dc.gov",
          :port => "25"
        }
      })
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
      "#{ec.hbx_id}.#{ec.environment}.q.hbx_soa.email_notification_listener"
    end
  end
end
