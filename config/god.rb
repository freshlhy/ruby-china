RAILS_ROOT = File.expand_path('../', __dir__)

God.watch do |w|
  w.name     = "sidekiq"
  w.interval = 30.seconds
  w.log      = "#{RAILS_ROOT}/log/#{w.name}.god.log"
  w.dir      = RAILS_ROOT
  w.pid_file = "#{RAILS_ROOT}/tmp/pids/#{w.name}.pid"
  w.start    = "nohup bundle exec sidekiq -e production -C #{RAILS_ROOT}/config/sidekiq.yml -P #{RAILS_ROOT}/tmp/pids/sidekiq.pid >> #{RAILS_ROOT}/log/sidekiq.log 2>&1 &"
  w.stop     = "kill -9 `cat #{RAILS_ROOT}/tmp/pids/sidekiq.pid`"
  
  # determine the state on startup
  w.transition(:init, { true => :up, false => :start }) do |on|
    on.condition(:process_running) do |c|
      c.running = true
    end
  end

  # determine when process has finished starting
  w.transition([:start, :restart], :up) do |on|
    on.condition(:process_running) do |c|
      c.running = true
      c.interval = 5.seconds
    end

    # failsafe
    on.condition(:tries) do |c|
      c.times = 5
      c.transition = :start
      c.interval = 5.seconds
    end
  end

  # start if process is not running
  w.transition(:up, :start) do |on|
    on.condition(:process_running) do |c|
      c.running = false
    end
  end
end