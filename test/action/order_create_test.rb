# coding: utf-8
require "test_setup"

describe OrderCreate do

  before do
    $redis.flushdb
    $db.flush!
  end

  # todo: test transactions

  describe "bid" do
    before do
      $db.insert(:accounts, account_id: 42, eur: 100000, eur_used: 300)
      @bid = OrderCreate.new(type: "bid", account_id: 42, eur_limit: 9800, btc: 500)
    end

    it "ensure the account has sufficient unused EUR balance" do
      $db.update(:accounts, "set eur_used = eur where account_id = 42")
      assert_raises(RuntimeError) { @bid.execute }
    end

    it "should increase account.eur_used by total order amount" do
      @bid.execute
      result = $db.exec("select eur_used from accounts where account_id = 42").first
      assert_equal 300 + 9800 * 5, result["eur_used"]
    end

    it "should insert the order into the database" do
      order_id = @bid.execute
      result = $db.exec("select * from orders where order_id = #{order_id}").first
      assert_equal "bid", result["type"]
      assert_equal 42, result["account_id"]
      assert_equal 9800, result["eur_limit"]
      assert_equal 500, result["btc"]
      assert_equal 500, result["btc_open"]
    end

    it "should insert the order details into redis" do
      order_id = @bid.execute
      result = MessagePack.unpack($redis.hget("orders", order_id))
      assert_equal Hash("account_id" => 42, "eur_limit" => 9800, "btc_open" => 500), result
    end

    it "should add the order to bid side of order book" do
      order_id = @bid.execute
      score = $redis.zscore("bids", order_id)
      assert_equal -9800, score.to_i
    end
  end

  describe "ask" do
    before do
      $db.insert(:accounts, account_id: 42, btc: 2000, btc_used: 300)
      @ask = OrderCreate.new(type: "ask", account_id: 42, eur_limit: 9800, btc: 500)
    end

    it "ensure the account has sufficient unused BTC balance" do
      $db.update(:accounts, "set btc_used = btc where account_id = 42")
      assert_raises(RuntimeError) { @ask.execute }
    end

    it "should increase account.btc_used by btc amount" do
      @ask.execute
      result = $db.exec("select btc_used from accounts where account_id = 42").first
      assert_equal 300 + 500, result["btc_used"]
    end

    it "should insert the order into the database" do
      order_id = @ask.execute
      result = $db.exec("select * from orders where order_id = #{order_id}").first
      assert_equal "ask", result["type"]
      assert_equal 42, result["account_id"]
      assert_equal 9800, result["eur_limit"]
      assert_equal 500, result["btc"]
      assert_equal 500, result["btc_open"]
    end

    it "should insert the order details into redis" do
      order_id = @ask.execute
      result = MessagePack.unpack($redis.hget("orders", order_id))
      assert_equal Hash("account_id" => 42, "eur_limit" => 9800, "btc_open" => 500), result
    end

    it "should add the order to ask side of order book" do
      order_id = @ask.execute
      score = $redis.zscore("asks", order_id)
      assert_equal 9800, score.to_i
    end
  end

end
