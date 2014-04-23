require 'spec_helper'

describe Honduras::TasksStorage do
  let(:redis) {mock_redis}
  let(:key) {"test"}
  let(:storage) {Honduras::TasksStorage.new(redis, key)}

  def mock_redis
    double("redis")
  end

  def mock_task
    double("task")
  end

  context "#redis" do
    it "should return redis passed into constructor" do
      Honduras::TasksStorage.new(redis, key).redis.should eql(redis)
    end
  end

  context "#key" do
    it "should return key passed into constructor" do
      Honduras::TasksStorage.new(redis, key).key.should eql(key)
    end
  end

  context "#add" do
    let(:task) {mock_task}

    before(:each) do
      redis.stub(:hset)
    end

    it "should save task in redis" do
      redis.should_receive(:hset).once.with(key, kind_of(String), kind_of(String))

      storage.add(task)
    end

    it "should assign an id to task" do
      task_id = SecureRandom.uuid
      SecureRandom.should_receive(:uuid).once.and_return(task_id)

      storage.add(task).should eql(task_id)
    end

    it "should save task as JSON" do
      json = SecureRandom.uuid
      task.should_receive(:to_json).once.and_return(json)

      redis.should_receive(:hset).once do |_, _, actual_json|
        actual_json.should eql(json)
      end

      storage.add(task)
    end
  end

  context "#fetch" do
    let(:task_id) {SecureRandom.uuid}
    let(:task) {mock_task}
    let(:raw_task) {SecureRandom.uuid}

    before(:each) do
      JSON.stub(:parse).and_return(task)
      redis.stub(:hget).with(key, task_id).and_return(raw_task)
      redis.stub(:hdel)
    end

    it "should get task from redis" do
      redis.should_receive(:hget).once.with(key, task_id).and_return(raw_task)

      storage.fetch(task_id){}
    end

    it "should yield task to the code block" do
      expect{|b| storage.fetch(task_id, &b)}.to yield_with_args(task)
    end

    it "should delete task from redis after yielding it" do
      storage.fetch(task_id) do
        redis.should_receive(:hdel).once.with(key, task_id)
      end
    end

    it "should not delete task if the code block throws" do
      redis.should_not_receive(:hdel)
      expect do
        storage.fetch(task_id) {raise 'Test'}
      end.to raise_error('Test')
    end
  end

  context "each_task" do
    let(:task1_id) {SecureRandom.uuid}
    let(:task2_id) {SecureRandom.uuid}
    let(:saved_data){{task1_id => "task_1", task2_id => "task_2"}}
    let(:tasks){[mock_task, mock_task]}

    before(:each) do
      redis.stub(:hgetall).and_return(saved_data)
      redis.stub(:hdel)
      JSON.stub(:parse).and_return(*tasks)
    end

    it "should read all tasks from redis" do
      redis.should_receive(:hgetall).once.and_return(saved_data)

      storage.each_task{}
    end

    it "should yield each task" do
      expect{|b| storage.each_task(&b)}.to yield_successive_args(*tasks)
    end

    it "should remove from redis" do
      redis.should_receive(:hdel).once.with(key, [task1_id, task2_id])

      storage.each_task(true){}
    end

    it "should not remove from redis" do
      redis.should_not_receive(:hdel)

      storage.each_task{}
    end

    it "should not delete from redis on no cached data" do
      redis.stub(:hgetall).and_return({})
      redis.should_not_receive(:hdel)

      storage.each_task(true){}
    end

    it "should not remove from redis on exception" do
      redis.should_not_receive(:hdel)

      expect{storage.each_task(true){raise "Test"}}.to raise_error("Test")
    end
  end
end
