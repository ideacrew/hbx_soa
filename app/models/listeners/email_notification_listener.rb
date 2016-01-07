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
      format = properties.headers['format']
      body = payload
      body_opts = case format
      when "html"
        { :html_body => body }
      else
        { :body => body }
      end
      Pony.mail({
        :to => recipient,
        :subject => subject,
        :via => :smtp,
        :via_options => {
          :to => recipient,
          :from => ExchangeInformation.email_from_address,
          :address => ExchangeInformation.smtp_host,
          :user_name => ExchangeInformation.email_username,
          :password => ExchangeInformation.email_password,
          :domain => ExchangeInformation.email_domain,
          :authentication => :plain,
          :port => "587"
        }
      }.merge(body_opts).merge({
         :from => "redmine@dchbx.org"
      }))
      channel.acknowledge(delivery_info.delivery_tag, false)
    end

    def self.run
      conn = Bunny.new(ExchangeInformation.amqp_uri, :heartbeat => 10)
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
