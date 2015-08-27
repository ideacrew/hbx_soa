options = {
  "pid_file" => File.expand_path(File.join(HbxSoa::App.root, "..", "pids", "exchange_sequence_listener.pid")),
  "amqp_uri" => ExchangeInformation.amqp_uri,
  "queue_name" => Listeners::ExchangeSequenceListener.queue_name,
  "max_workers" => 40,
  "min_workers" => 20,
  "request_duration" => 10,
  "max_duration" => 5 
}

puts options["pid_file"].inspect

Scaley::RabbitRunner.new(options).run
