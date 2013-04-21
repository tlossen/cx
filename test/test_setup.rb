require "minitest/unit"
require "minitest/spec"
require "mocha/setup"

require_relative "../boot.rb"

module MiniTest
  module Assertions

    def assert_difference(expr, delta, &block)
      old = eval(expr, block.binding)
      yield
      assert_equal old + delta, eval(expr, block.binding)
    end

  end
end
