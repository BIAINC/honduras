require 'resque'

require_relative "honduras/version"
require_relative "honduras/scheduled_items_queue"
require_relative "honduras/resque_scheduler"
require_relative "honduras/tasks_storage"

module Honduras
  DELAYED_TASKS_KEY = "honduras:delayed_tasks"

  attr_accessor(:rufus_scheduler)

  def enqueue_in(seconds, klass, *args)
    ScheduledItemsQueue.enqueue(Time.now + seconds, klass, *args)
  end

  def enqueue_at(timestamp, klass, *args)
    ScheduledItemsQueue.enqueue(timestamp, klass, *args)
  end

  def enqueue_delayed_tasks
    ScheduledItemsQueue.fetch(500) do |tasks|
      tasks.each do |task|
        schedule_delayed_task(task)
      end
    end
  end

  def delayed_tasks_storage
    @delayed_tasks_storage ||= TasksStorage.new(redis.redis, DELAYED_TASKS_KEY)
  end

  private

  def schedule_delayed_task(task)
    timestamp = task["timestamp"]
    task_id = delayed_tasks_storage.add(task)
    rufus_scheduler.at(timestamp) {enqueue_delayed_task(task_id)}
  end

  def enqueue_delayed_task(task_id)
    delayed_tasks_storage.fetch(task_id) do |task|
      queue = task.delete("queue")
      task.delete("timestamp")
      Resque.push(queue, task)
    end
  end
end

Resque.extend(Honduras)
