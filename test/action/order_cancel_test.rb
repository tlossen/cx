# coding: utf-8
require "test_setup"

describe OrderCancel do

  before do
    $redis.flushdb
    $db.flush!
  end

  describe "execute" do
    before do
      $db.insert(:accounts, account_id: 42, eur: 100000, eur_used: 300)
      @order_id = OrderCreate.new(type: "bid", account_id: 42, eur_limit: 9800, btc: 500).execute
      @action = OrderCancel.new(account_id: 42, order_id: @order_id)
    end

    it "should ensure the order exists in database" do
      $db.exec("delete from orders where order_id = #{@order_id}")
      assert_raises(RuntimeError) { @action.execute }
    end

    it "should ensure the order belongs to the given account" do
      $db.exec("update orders set account_id = 11 where order_id = #{@order_id}")
      assert_raises(RuntimeError) { @action.execute }
    end

    it "should ensure the order is active" do
      $db.exec("update orders set active = false where order_id = #{@order_id}")
      assert_raises(RuntimeError) { @action.execute }
    end
  end

end
