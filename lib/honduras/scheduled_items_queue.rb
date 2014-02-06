require 'json'

module Honduras
  module ScheduledItemsQueue
    DELAYED_TASKS_KEY = 'delayed_tasks'

    class << self
      def enqueue(timestamp, klass, *args)
        queue = Resque.queue_from_class(klass)

        item = {timestamp: timestamp, class: klass.to_s, queue: queue, args: args}

        send_to_queue(item)
      end

      def fetch_all(&block)
        items = redis.lrange(DELAYED_TASKS_KEY, 0, -1).map{|i| JSON.parse(i)}
        block[items]
        redis.ltrim(DELAYED_TASKS_KEY, items.count, -1) unless items.empty?
      end

      private

      def redis
        Resque.redis
      end

      def send_to_queue(item)
        redis.rpush(DELAYED_TASKS_KEY, item.to_json)
      end
    end
  end
end
