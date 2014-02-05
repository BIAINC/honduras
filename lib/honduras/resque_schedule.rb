module Honduras
  module ResqueSchedule
    def self.start(rufus_scheduler, schedule)
      schedule.each do |_, item|
        cron = item.delete('cron')
        queue = item.delete('queue')

        rufus_scheduler.cron(cron) do
          Resque.push(queue, item)
        end
      end
    end
  end
end
