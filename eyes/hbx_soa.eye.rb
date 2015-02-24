BUS_DIRECTORY = File.join(File.dirname(__FILE__), "..")
LOG_DIRECTORY = File.join(BUS_DIRECTORY, "log")
PID_DIRECTORY = File.join(BUS_DIRECTORY, "pids")

BLUEPILL_LOG = File.join(LOG_DIRECTORY, "eye_hbx_soa.log")

Eye.config do
  logger BLUEPILL_LOG

  mail :host => "smtp4.dc.gov", :port => 25, :from_mail => "no-reply@dchbx.info"
  contact :tevans, :mail, 'trey.evans@dc.gov'
  contact :dthomas, :mail, 'dan.thomas@dc.gov'
end

def start_command_for(worker_command)
      "bundle exec padrino r #{worker_command} -e production"
end

def define_worker(worker_name, directory, worker_command, watch_kids = false)
  process(worker_name) do
    start_command start_command_for(worker_command)
    stop_on_delete true
    stop_signals [:TERM, 10.seconds, :KILL]
    start_timeout 5.seconds
    pid_file File.join(PID_DIRECTORY, "#{worker_name}.pid")
    daemonize true
    working_dir directory
    stdall File.join(LOG_DIRECTORY, "#{worker_name}.log")
    if watch_kids
      monitor_children do
        stop_command "/bin/kill -9 {PID}"
        check :memory, :every => 30, :below => 200.megabytes, :times => [3,5]
      end
    end
  end
end

Eye.application 'eye_hbx_soa' do
    notify :tevans, :info
    notify :dthomas, :info

  define_worker("exchange_sequence_listener", BUS_DIRECTORY, "amqp/exchange_sequence_listener.rb", true)
  define_worker("exchange_sequence_listener_scaler", BUS_DIRECTORY, "amqp/exchange_sequence_listener_scaler.rb", false)
  define_worker("uri_resolver_listener", BUS_DIRECTORY, "amqp/uri_resolver_listener.rb", true)
  define_worker("uri_resolver_listener_scaler", BUS_DIRECTORY, "amqp/uri_resolver_listener_scaler.rb", false)
  define_worker("event_logging_listener", BUS_DIRECTORY, "amqp/event_logging_listener.rb", true)
  define_worker("enrollment_submitted_handler", BUS_DIRECTORY, "amqp/enrollment_submitted_handler.rb", true)
  define_worker("enrollment_submitted_handler_scaler", BUS_DIRECTORY, "amqp/enrollment_submitted_handler_scaler.rb", false)

  process("unicorn") do
    working_dir BUS_DIRECTORY
    pid_file "pids/unicorn.pid"
    start_command "bundle exec unicorn -c #{BUS_DIRECTORY}/config/unicorn.rb -E production -D"
    stdall "log/unicorn.log"

    # stop signals:
    #     # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]
    #
    #             # soft restart
    #    restart_command "kill -USR2 {PID}"
    #
    # check :cpu, :every => 30, :below => 80, :times => 3
    # check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    #
    start_timeout 100.seconds
    restart_grace 30.seconds
    #
    monitor_children do
      stop_command "kill -QUIT {PID}"
      check :cpu, :every => 30, :below => 80, :times => 3
      check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    end
  end
end
