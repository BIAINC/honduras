module Honduras
  module ResqueScheduler
    extend self

    def log
      @log ||= Logger.new(STDOUT)
    end

    def log=(log)
      @log = log
    end

    def delayed_tasks
      @delayed_tasks ||= TasksStorage.new(Resque.redis.redis, Honduras::DELAYED_TASKS_KEY)
    end

    def start(rufus_scheduler, schedule)
      schedule_delayed_tasks(rufus_scheduler)
      schedule_cron_tasks(rufus_scheduler, schedule)
    end

    private

    def schedule_delayed_tasks(rufus_scheduler)
      delayed_tasks.each_task(true) do |task|
        queue = task.delete('queue')
        timestamp = task.delete('timestamp')

        rufus_scheduler.at(timestamp) do
          log.info{"Queueing delayed task #{task} into #{queue}"}
          Resque.push(queue, task)
        end

        log.info{"Scheduled delayed task #{task['queue']} into #{queue}"}
      end
    end

    def schedule_cron_tasks(rufus_scheduler, schedule)
      schedule.each do |_, item|
        cron = item.delete('cron')
        queue = item.delete('queue')
        klass = item['class']
        item["args"] = Array(item["args"])

        rufus_scheduler.cron(cron) do
          log.info{"Queueing #{item} into #{queue}"}
          Resque.push(queue, item)
        end
        log.info{"Scheduled #{klass} into #{queue}"}
      end
    end
  end
end
