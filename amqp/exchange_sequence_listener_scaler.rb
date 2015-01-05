options = {
  "pid_file" => File.expand_path(File.join(HbxSoa::App.root, "..", "pids", "exchange_sequence_listener.pid")),
  "amqp_uri" => ExchangeInformation.amqp_uri,
  "queue_name" => Listeners::ExchangeSequenceListener.queue_name,
  "max_workers" => 5,
  "min_workers" => 1,
  "request_duration" => 1,
  "max_duration" => 4
}

puts options["pid_file"].inspect

Scaley::RabbitRunner.new(options).run
