require 'json'

module Honduras
  module ScheduledItemsQueue
    extend Enumerable

    DELAYED_TASKS_KEY = 'resque:delayed_tasks'

    class << self
      def enqueue(timestamp, klass, *args)
        queue = Resque.queue_from_class(klass)

        item = {timestamp: timestamp, class: klass.to_s, queue: queue, args: args}

        send_to_queue(item)
      end

      def fetch(count = :all, &block)
        last = count == :all ? -1 : count - 1

        items = redis.lrange(DELAYED_TASKS_KEY, 0, last).map{|i| JSON.parse(i)}
        block[items]
        redis.ltrim(DELAYED_TASKS_KEY, items.size, - 1) unless items.empty?
      end

      def each(&block)
        enum = Enumerator.new do |enum|
          first = 0
          page_size = 100

          loop do
            page_results = redis.lrange(DELAYED_TASKS_KEY, first, first + page_size - 1)
            page_results.each{|res| enum << JSON.parse(res)}
            first += page_results.size
            break unless page_results.size == page_size
          end
        end

        block.nil? ? enum : enum.each(&block)
      end

      private

      def redis
        Resque.redis.redis
      end

      def send_to_queue(item)
        redis.rpush(DELAYED_TASKS_KEY, item.to_json)
      end
    end
  end
end
