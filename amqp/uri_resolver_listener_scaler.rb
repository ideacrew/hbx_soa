options = {
  "pid_file" => File.expand_path(File.join(HbxSoa::App.root, "..", "pids", "uri_resolver_listener.pid")),
  "amqp_uri" => ExchangeInformation.amqp_uri,
  "queue_name" => Listeners::UriResolverListener.queue_name,
  "max_workers" => 10,
  "min_workers" => 3,
  "request_duration" => 1,
  "max_duration" => 3 
}

puts options["pid_file"].inspect

Scaley::RabbitRunner.new(options).run
