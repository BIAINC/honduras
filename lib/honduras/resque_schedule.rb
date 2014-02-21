module Honduras
  module ResqueSchedule

    def self.log
      @log ||= Logger.new(STDOUT)
    end

    def self.log=(log)
      @log = log
    end

    def self.start(rufus_scheduler, schedule)
      schedule.each do |_, item|
        cron = item.delete('cron')
        queue = item.delete('queue')
        klass = item['class']
        item["args"] = Array(item["args"])

        rufus_scheduler.cron(cron) do
          log.info "Queueing #{item} into #{queue}"
          Resque.push(queue, item)
        end
        log.info "Scheduled #{klass} into #{queue}"
      end
    end
  end
end
