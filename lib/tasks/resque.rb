require 'rufus-scheduler'
require 'yaml'
require 'honduras'

namespace :resque do
  task :scheduler, :schedule_file do |_, args|
    puts "Loading resque schedule from #{args.schedule_file}"
    schedule = YAML.load_file(args.schedule_file)
    scheduler = Rufus::Scheduler.start_new

    Honduras::ResqueSchedule.start(scheduler, schedule)
    sleep
  end
end
