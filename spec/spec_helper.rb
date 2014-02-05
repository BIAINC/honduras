require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "honduras"
require 'uuid'
require_relative "test_task"
