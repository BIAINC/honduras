require "spec_helper"

describe Honduras::ResqueSchedule do
  context "interface" do
    subject { Honduras::ResqueSchedule }

    it {should respond_to(:start)}
  end

  context "functionality" do
    let(:schedule) { load_schedule }


  end
end
