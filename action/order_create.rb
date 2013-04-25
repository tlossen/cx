# coding: utf-8
class OrderCreate < Action

  params :account_id, :type, :eur_limit, :btc

  def execute
    case type
      when "bid" then create_bid
      when "ask" then create_ask
      else raise("invalid type: #{type}")
    end
  end

  def create_bid
    $db.transaction do
      updated = $db.update(:accounts,
        "set
          eur_used = eur_used + #{eur_total}
        where
          account_id = #{account_id}
          and eur_used + #{eur_total} <= eur"
      )
      raise("insufficient EUR balance available") unless updated == 1
      order_id = $db.insert(:orders,
        account_id: account_id,
        type: "bid",
        eur_limit: eur_limit,
        btc: btc,
        btc_open: btc
      )
    end
    priority = (2**32 - order_id).to_s.rjust(10, "0")
    $redis.hset("orders", order_id, MessagePack.pack(
      account_id: account_id,
      eur_limit:  eur_limit,
      btc_open:   btc
    ))
    $redis.zadd("bids", "-#{eur_limit}.#{priority}", order_id)
  end

  def create_ask
    transaction do
      updated = $db.update(:accounts,
        "set
          btc_used = btc_used + #{btc}
        where
          account_id = #{account_id}
          and btc_used + #{btc} <= btc"
      )
      raise("insufficient BTC balance available") unless updated == 1
      order_id = $db.insert(:orders,
        account_id: account_id,
        type: "ask",
        eur_limit: eur_limit,
        btc: btc,
        btc_open: btc
      )
    end
    priority = order_id.to_s.rjust(10, "0")
    $redis.hset("orders", order_id, MessagePack.pack(
      account_id: account_id,
      eur_limit:  eur_limit,
      btc_open:   btc
    ))
    $redis.zadd("asks", "#{eur_limit}.#{priority}", order_id)
  end

private

  def eur_total
    @eur_total ||= multiply(eur_limit, btc)
  end

end