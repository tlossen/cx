# coding: utf-8
class OrderCancel < Action

  params :account_id, :order_id

  DELETE_ORDER = <<-LUA
    local order_id = ARGV[1]
    local order = redis.call('hget', 'orders', order_id)
    if order then
      redis.call('zrem', 'bids', order_id)
      redis.call('zrem', 'asks', order_id)
      redis.call('hdel', 'orders', order_id)
    end
    return order
  LUA

  def execute
    order = unpack($redis.eval(DELETE_ORDER, [], [order_id]))
    if order
      btc_open = order["btc_open"]
      $db.transaction do
        $db.update(:orders, "set active = false where order_id = #{order_id}")
        $db.update(:accounts, "set btc_used = btc_used - #{btc_open} where account_id = #{account_id}")
      end
    end
  end

end