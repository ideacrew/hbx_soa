class ExchangeInformation

  class MissingKeyError < StandardError
    def initialize(key)
      super("Missing required key: #{key}") 
    end
  end

  include Singleton

  REQUIRED_KEYS = [
    'amqp_uri',
    'environment',
    'hbx_id',
    'event_exchange',
    'event_publish_exchange',
    'request_exchange',
    'invalid_argument_queue',
    'processing_failure_queue',
    'email_username',
    'email_password',
    'smtp_host',
    'smtp_port',
    'email_from_address',
    'email_domain'
  ]

  attr_reader :config

  def initialize
    @config = YAML.load(ERB.new(File.read(File.join(HbxSoa::App.root,'..','config', 'exchange.yml'))).result)
    ensure_configuration_values(@config)
  end

  def ensure_configuration_values(conf)
    REQUIRED_KEYS.each do |k|
      if @config[k].blank?
        raise MissingKeyError.new(k)
      end
    end
  end

  def self.define_key(key)
    define_method(key.to_sym) do
      config[key.to_s]
    end
    self.instance_eval(<<-RUBYCODE)
      def self.#{key.to_s}
        self.instance.#{key.to_s}
      end
    RUBYCODE
  end

  REQUIRED_KEYS.each do |k|
    define_key k
  end
end
