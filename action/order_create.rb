class OrderCreate < Action

  params :account_id, :type, :eur_limit, :btc

  def execute
    case type
    when 'bid': execute_bid
    when 'ask': execute_ask
    else
      raise("invalid type: #{type}")
    end
  end

  def execute_bid
    transaction do
      result = $db.query "update accounts set eur_used = eur_used + #{eur_total}
        where account_id = #{account_id} and eur_used + #{eur_total} <= eur"
      raise("insufficient EUR balance available") unless result == 1
      $db.query "insert into orders (type, eur_limit, btc, btc_open)
        values ('bid', #{eur_limit}, #{btc}, #{btc})"
    end
    # todo: update order book in redis
  end

  def execute_ask
    transaction do
      result = $db.query "update accounts set btc_used = btc_used + #{btc}
        where account_id = #{account_id} and btc_used + #{btc} <= btc"
      raise("insufficient BTC balance available") unless result == 1
      $db.query "insert into orders (type, eur_limit, btc, btc_open)
        values ('ask', #{eur_limit}, #{btc}, #{btc})"
    end
    # todo: update order book in redis
  end

private

  def eur_total
    @eur_total ||= multiply(eur_limit, btc)
  end

end