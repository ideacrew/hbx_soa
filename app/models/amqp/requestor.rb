require 'timeout'
require 'thread'

module Amqp
  class Requestor
    attr_reader :channel

    def initialize(chan)
      @channel = chan
    end

    def request(properties, payload, timeout = 15)
      temp_queue = channel.queue("", :exclusive => true)
      request_exchange = channel.direct(ExchangeInformation.request_exchange, :durable => true)
      request_exchange.publish(payload, properties.merge({ :reply_to => temp_queue.name, :persistent => true }))
      delivery_info, properties, payload = [nil, nil, nil]
      begin
        Timeout::timeout(timeout) do
          temp_queue.subscribe({:manual_ack => true, :block => true}) do |di, prop, pay|
            delivery_info, properties, payload = [di, prop, pay]
            channel.acknowledge(di.delivery_tag, false)
            throw :terminate, "success"
          end
        end
      ensure
        temp_queue.delete
      end
      [delivery_info, properties, payload]
    end

    def self.default
      conn = Bunny.new(ExchangeInformation.amqp_uri)
      conn.start
      ch = conn.create_channel
      ch.prefetch(1)
      self.new(ch)
    end
  end
end
