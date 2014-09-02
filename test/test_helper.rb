
begin
  require 'minitest/test'
rescue LoadError
  require 'minitest/autorun'
  module Minitest
    class Test < MiniTest::Unit::TestCase
    end
  end
end

if ENV['COVERAGE'] == 'test'
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
    add_filter "/specs/"
  end
end

# Previous content of test helper now starts here

