require 'resque'

require_relative "honduras/version"
require_relative "honduras/scheduled_items_queue"
require_relative "honduras/resque_schedule"

module Honduras
  attr_accessor(:rufus_scheduler)

  def enqueue_in(seconds, klass, *args)
    ScheduledItemsQueue.enqueue(Time.now + seconds, klass, *args)
  end

  def enqueue_at(timestamp, klass, *args)
    ScheduledItemsQueue.enqueue(timestamp, klass, *args)
  end

  def enqueue_delayed_tasks
    ScheduledItemsQueue.fetch_all do |tasks|
      tasks.each do |task|
        enqueue_delayed_task(task)
      end
    end
  end

  private

  def enqueue_delayed_task(task)
    timestamp = task.delete('timestamp')
    queue = task.delete('queue')

    rufus_scheduler.at(timestamp) { Resque.push(queue, task) }
  end
end

Resque.extend(Honduras)
