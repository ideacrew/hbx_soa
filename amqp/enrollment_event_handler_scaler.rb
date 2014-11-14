options = {
  "pid_file" => File.expand_path(File.join(HbxSoa::App.root, "..", "pids", "enrollment_event_handler.pid")),
  "amqp_uri" => ExchangeInformation.amqp_uri,
  "queue_name" => Listeners::EnrollmentEventHandler.queue_name,
  "max_workers" => 4,
  "min_workers" => 1,
  "request_duration" => 10,
  "max_duration" => 120
}

puts options["pid_file"].inspect

Scaley::RabbitRunner.new(options).run
