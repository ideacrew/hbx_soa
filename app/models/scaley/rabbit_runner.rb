module Scaley
  class RabbitRunner
    def initialize(conf = {}) 
      @configuration = ::Scaley::Configuration.new(conf)
      @counter = ::Scaley::RabbitCounter.new(
        @configuration.amqp_uri,
        @configuration.queue_name
      )
      @enforcer = ::Scaley::Enforcer.new(@configuration)
    end

    def run
      @watcher = ::Scaley::Watcher.new(@enforcer, @counter)
      @watcher.run
    end
  end
end
