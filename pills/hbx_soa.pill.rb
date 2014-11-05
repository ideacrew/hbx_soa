BUS_DIRECTORY = File.join(File.dirname(__FILE__), "..")
LOG_DIRECTORY = File.join(BUS_DIRECTORY, "log")
PID_DIRECTORY = File.join(BUS_DIRECTORY, "pids")

BLUEPILL_LOG = File.join(LOG_DIRECTORY, "hbx_soa.log")

def unset_list
  ev_list = [ 
    "RBENV_DIR",
    "GEM_PATH",
    "RBENV_PATH",
    "RBENV_GEMSET_ALREADY",
    "GEM_HOME",
    "RBENV_GEMSETS",
    "RBENV_HOOK_PATH",
    "RBENV_SHELL",
    "RBENV_VERSION"
  ]
  ev_list.map { |evv| "unset " + evv }.join(" && ")
end

def start_command_for(worker_name, worker_command)
    "#{worker_command}"
    # "cd #{BUS_DIRECTORY} && export RBENV_GEMSETS=`cat #{BUS_DIRECTORY}/.rbenv-gemsets` && echo `env` > #{LOG_DIRECTORY}/#{worker_name}_envs.log && #{worker_command}"
end

def define_worker(app, worker_name, directory, worker_command, watch_kids = false)
  app.process(worker_name) do |process|
    # puts ENV.inspect
    process.start_command = start_command_for(worker_name, worker_command)
    process.stop_command = "/bin/kill -9 {{PID}}"
    process.start_grace_time 10.seconds
    process.pid_file = File.join(PID_DIRECTORY, "#{worker_name}.pid")
    process.daemonize = true
    process.working_dir = directory
    process.stdout = process.stderr = File.join(LOG_DIRECTORY, "#{worker_name}.log")
    if watch_kids
      process.monitor_children do |child_process|
        child_process.stop_command = "/bin/kill -9 {{PID}}"
#        child_process.checks :flapping, :times => 5, :within => 5.seconds
      end
    end
  end
end

Bluepill.application("hbx_enterprise", :log_file => BLUEPILL_LOG) do |app|
  app.uid = "nginx"
  app.gid = "nginx"
end
