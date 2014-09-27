require 'rufus-scheduler'
require 'yaml'
require 'honduras'

namespace :resque do
  task :scheduler, :schedule_file, :log_level do |_, args|
    log_level = args.log_level || Logger::INFO
    log = Logger.new(STDOUT)
    log.log_level = log_level
    Honduras::ResqueScheduler.log = log

    log.info{"Loading resque schedule from #{args.schedule_file}"}
    schedule = YAML.load_file(args.schedule_file)
    scheduler = Rufus::Scheduler.start_new

    Honduras::ResqueScheduler.start(scheduler, schedule)

    scheduler.every('5s') do
      Resque.enqueue_delayed_tasks
    end

    scheduler.join
  end
end
