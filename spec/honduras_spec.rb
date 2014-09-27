require 'spec_helper'

describe Honduras do
  let(:scheduler) { mock_scheduler }
  let(:queue) { Honduras::ScheduledItemsQueue }

  before(:each) do
    Resque.stub(:rufus_scheduler).and_return(scheduler)
  end

  def mock_scheduler
    s = double('scheduler')
    s.stub(:at)
    s.stub(:cron)
    s
  end

  context "Resque extension" do
    subject { Resque }

    it {should respond_to(:enqueue_in)}
    it {should respond_to(:enqueue_at)}
    it {should respond_to(:enqueue_delayed_tasks)}
  end

  context 'queueing' do
    it 'should enqueue with a delay' do
      actual_time = Time.now
      Time.should_receive(:now).exactly(1).times.and_return(actual_time)
      queue.should_receive(:enqueue).with(actual_time + 10, TestTask, :foo, :bar)

      Resque.enqueue_in(10, TestTask, :foo, :bar)
    end

    it 'should enqueue at specific time' do
      scheduled_time = Time.now + 180
      queue.should_receive(:enqueue).with(scheduled_time, TestTask, :foo)

      Resque.enqueue_at(scheduled_time, TestTask, :foo)
    end
  end

  context '::enqueue_delayed_tasks' do
    let(:core_task) { {"class" => 'test_class'} }
    let(:scheduled_task) { {"class" => "test_class", "queue" => resque_queue, "timestamp" => timestamp}}
    let(:resque_queue) { SecureRandom.uuid.to_s }
    let(:timestamp) { Time.now + rand(-10..10) }

    before(:each) do
      queue.stub(:fetch_all).and_yield([scheduled_task])
      Resque.stub(:push)
      Resque.delayed_tasks_storage.stub(:add).and_return(SecureRandom.uuid)
      Resque.delayed_tasks_storage.stub(:fetch).and_yield(scheduled_task)
      scheduler.stub(:at).and_yield
    end

    it 'should schedule a task' do
      scheduler.should_receive(:at).once.with(timestamp)

      Resque.enqueue_delayed_tasks
    end

    it 'should enqueue Resque task' do
      scheduler.stub(:at).and_yield
      Resque.should_receive(:push).with(resque_queue, core_task)

      Resque.enqueue_delayed_tasks
    end

    it 'should store tasks in the delayed tasks storage' do
      Resque.delayed_tasks_storage.should_receive(:add).with(scheduled_task)

      Resque.enqueue_delayed_tasks
    end

    it 'should fetch task from the delayed tasks storage' do
      Resque.delayed_tasks_storage.should_receive(:fetch).exactly(1).times.and_yield(scheduled_task)

      Resque.enqueue_delayed_tasks
    end
  end
end