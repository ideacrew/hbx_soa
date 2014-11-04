module Scaley
  class RabbitCounter
    def initialize(amqp_uri, queue_name)
      @bunny = Bunny.new(amqp_uri)
      @bunny.start
      @channel = @bunny.create_channel
      @queue = @channel.queue(queue_name, :durable => true)
    end

    def statistics
      status_hash = @queue.status
      {
        :backlog => status_hash[:message_count],
        :workers => status_hash[:consumer_count]
      }
    end
  end
end
