require "spec_helper"
require 'yaml'

describe Honduras::ResqueSchedule do
  context "interface" do
    subject { Honduras::ResqueSchedule }

    it {should respond_to(:start)}
  end

  context "functionality" do
    let(:scheduler) { mock_scheduler }
    let(:schedule) { load_schedule }

    before(:each) do
      Resque.stub(:push)
    end

    def mock_scheduler
      s = double('scheduler')
      s.stub(:at).and_yield
      s.stub(:cron).and_yield
      s
    end

    def load_schedule
      schedule_path = "./spec/schedule.yml"
      YAML.load_file(schedule_path)
    end

    it "should have 3 items in the schedule" do
      # Sanity check
      schedule.size.should eql(3)
    end

    it "should schedule every task" do
      expected_times = schedule.values.map{|i| i['cron']}
      scheduler.should_receive(:cron).with(expected_times[0]).with(expected_times[1]).with(expected_times[2])

      Honduras::ResqueSchedule.start(scheduler, schedule)
    end

    it "should enqueue all scheduled tasks" do
      expected_queues = schedule.values.map{|i| i['queue']}
      expected_items = schedule.values.map do |item|
        item = item.clone
        item.delete('cron')
        item.delete('queue')
        item
      end

      Resque.should_receive(:push).with(expected_queues[0], expected_items[0]).with(expected_queues[1], expected_items[1]).with(expected_queues[2], expected_items[2])

      Honduras::ResqueSchedule.start(scheduler, schedule)
    end
  end
end
