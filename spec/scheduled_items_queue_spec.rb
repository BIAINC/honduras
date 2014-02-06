require "spec_helper"
require "json"

describe Honduras::ScheduledItemsQueue do
  context 'interface' do
    let(:subject) { Honduras::ScheduledItemsQueue }

    it { should respond_to(:enqueue) }
    it { should respond_to(:fetch_all) }
  end

  context 'functionality' do
    let(:queue) { Honduras::ScheduledItemsQueue}
    let(:redis) { mock_redis}
    let(:timestamp) { Time.now + rand(-10..10) }
    let(:test_class) { TestTask }
    let(:resque_queue) { Resque.queue_from_class(test_class) }
    let(:test_args) { [] }
    let(:normal_item) { {"timestamp" => timestamp.to_s, "class" => test_class.to_s, "queue" => resque_queue, "args" => test_args} }
    let(:serialized_item) { normal_item.to_json }

    before(:each) do
      Resque.stub(:redis).and_return(redis)
    end

    def mock_redis
      r = double('redis')
      r.stub(:lrange)
      r.stub(:ltrim)
      r.stub(:rpush)
      r
    end

    context "::enqueue" do
      it "should store data in redis" do
        redis.should_receive(:rpush).with(queue::DELAYED_TASKS_KEY, serialized_item)

        queue.enqueue(timestamp, test_class, *test_args)
      end
    end

    context "::fetch_all" do
      let(:expected_redis_items) { [serialized_item] }

      before(:each) do
        redis.stub(:lrange).and_return(expected_redis_items)
      end

      it "should obtain serialized items from Redis" do
        redis.should_receive(:lrange).with(queue::DELAYED_TASKS_KEY, 0, -1).and_return([serialized_item])

        queue.fetch_all{}
      end

      it "should pass deserialized items to thecode block" do
        expect{|b| queue.fetch_all(&b)}.to yield_with_args([normal_item])
      end

    end
  end
end
