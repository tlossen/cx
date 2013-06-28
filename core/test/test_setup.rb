require "minitest/unit"
require "minitest/spec"
require "minitest/autorun"
require "redgreen"
# require "mocha/setup"

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


class Database
  def flush!
    @db.query("delete from accounts")
    @db.query("delete from orders")
    @db.query("delete from trades")
    @db.query("delete from deltas")
  end
end