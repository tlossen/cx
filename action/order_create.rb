# coding: utf-8
class OrderCreate < Action

  params :type, :account_id, :eur_limit, :btc

  def execute
    case type
      when "bid" then create_bid
      when "ask" then create_ask
      else raise("invalid type: #{type}")
    end
  end

private

  def create_bid
    $db.transaction do
      updated = $db.update(:accounts,
        "set eur_used = eur_used + #{eur_total}
        where account_id = #{account_id}
          and eur_used + #{eur_total} <= eur"
      )
      raise("insufficient EUR balance available") unless updated == 1
      order_id = $db.insert(:orders,
        type:       "'bid'",
        account_id: account_id,
        eur_limit:  eur_limit,
        btc:        btc,
        btc_open:   btc
      )
      # todo: make redis commands atomic
      $redis.hset("orders", order_id, MessagePack.pack(
        account_id: account_id,
        eur_limit:  eur_limit,
        btc_open:   btc
      ))
      $redis.zadd("bids", "-#{eur_limit}.#{reverse_priority(order_id)}", order_id)
      order_id
    end
  end

  def create_ask
    $db.transaction do
      updated = $db.update(:accounts,
        "set btc_used = btc_used + #{btc}
        where account_id = #{account_id}
          and btc_used + #{btc} <= btc"
      )
      raise("insufficient BTC balance available") unless updated == 1
      order_id = $db.insert(:orders,
        type:       "'ask'",
        account_id: account_id,
        eur_limit:  eur_limit,
        btc:        btc,
        btc_open:   btc
      )
      $redis.hset("orders", order_id, MessagePack.pack(
        account_id: account_id,
        eur_limit:  eur_limit,
        btc_open:   btc
      ))
      $redis.zadd("asks", "#{eur_limit}.#{priority(order_id)}", order_id)
      order_id
    end
  end

  def priority(order_id)
    order_id.to_s.rjust(10, "0")
  end

  def reverse_priority(order_id)
    (2**32 - order_id).to_s.rjust(10, "0")
  end

  def eur_total
    @eur_total ||= multiply(eur_limit, btc)
  end

end