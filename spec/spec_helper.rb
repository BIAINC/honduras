require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "honduras"
require 'securerandom'
require_relative "test_task"
