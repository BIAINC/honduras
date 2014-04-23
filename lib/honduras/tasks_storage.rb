require 'securerandom'
require 'json'

module Honduras
  class TasksStorage

    attr_reader(:redis)
    attr_reader(:key)

    def initialize(redis, key)
      @redis = redis
      @key = key
    end

    def add(task)
      task_id = SecureRandom.uuid
      redis.hset(key, task_id, task.to_json)
      task_id
    end

    def fetch(task_id, &block)
      raw_task = redis.hget(key, task_id)
      block.call(JSON.parse(raw_task))
      redis.hdel(key, task_id)
    end

    def each_task(delete_at_end = false, &block)
      data = redis.hgetall(key)
      data.each do |_, raw_task|
        block.call(JSON.parse(raw_task))
      end
      redis.hdel(key, data.keys) if delete_at_end && !data.empty?
    end
  end
end
