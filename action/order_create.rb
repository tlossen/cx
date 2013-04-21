# coding: utf-8
class OrderCreate < Action

  params :account_id, :type, :eur_limit, :btc

  def execute
    case type
      when 'bid' then execute_bid
      when 'ask' then execute_ask
      else raise("invalid type: #{type}")
    end
  end

  def execute_bid
    transaction do
      $db.query "update accounts set eur_used = eur_used + #{eur_total}
        where account_id = #{account_id} and eur_used + #{eur_total} <= eur"
      raise("insufficient EUR balance available") unless $db.affected_rows == 1
      $db.query "insert into orders (type, eur_limit, btc, btc_open)
        values ('bid', #{eur_limit}, #{btc}, #{btc})"
      order_id = $db.last_id
    end
    $redis.hset "orders", order_id, MessagePack.pack(:eur_limit => eur_limit, :btc_open => btc)
    $redis.zadd "bids", "-#{eur_limit}.#{9_999_999_999 - Time.now.to_i}", order_id
  end

  def execute_ask
    transaction do
      updated = $db.query "update accounts set btc_used = btc_used + #{btc}
        where account_id = #{account_id} and btc_used + #{btc} <= btc"
      raise("insufficient BTC balance available") unless $db.affected_rows == 1
      $db.query "insert into orders (type, eur_limit, btc, btc_open)
        values ('ask', #{eur_limit}, #{btc}, #{btc})"
      order_id = $db.last_id
    end
    $redis.hset "orders", order_id, MessagePack.pack(:eur_limit => eur_limit, :btc_open => btc)
    $redis.zadd "asks", "#{eur_limit}.#{Time.now.to_i}", order_id
  end

private

  def eur_total
    @eur_total ||= multiply(eur_limit, btc)
  end

end