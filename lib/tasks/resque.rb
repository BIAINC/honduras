require 'rufus-scheduler'
require 'yaml'
require 'honduras'

namespace :resque do
  task :scheduler, :schedule_file do |_, args|
    puts "Loading resque schedule from #{args.schedule_file}"
    schedule = YAML.load_file(args.schedule_file)
    scheduler = Rufus::Scheduler.start_new

    Honduras::ResqueSchedule.start(scheduler, schedule)

    scheduler.every('5s') do
      print '.'
      Resque.enqueue_delayed_tasks
    end

    scheduler.join
  end
end
