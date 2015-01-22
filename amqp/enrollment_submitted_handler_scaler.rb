options = {
  "pid_file" => File.expand_path(File.join(HbxSoa::App.root, "..", "pids", "enrollment_submitted_handler.pid")),
  "amqp_uri" => ExchangeInformation.amqp_uri,
  "queue_name" => Listeners::EnrollmentSubmittedHandler.queue_name,
  "max_workers" => 5,
  "min_workers" => 1,
  "request_duration" => 10,
  "max_duration" => 120
}

puts options["pid_file"].inspect

Scaley::RabbitRunner.new(options).run
