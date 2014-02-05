class TestTask
  @queue = 'test_queue'

  def self.perform(*args)
    # Do nothing.
  end
end
