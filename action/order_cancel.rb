# coding: utf-8
class OrderCancel < Action

  params :account_id, :order_id

  DELETE_ORDER = <<-LUA
    local order_id = ARGV[1]
    local order = redis.call('hget', 'orders', order_id)
    redis.call('zrem', 'bids', order_id)
    redis.call('zrem', 'asks', order_id)
    redis.call('hdel', 'orders', order_id)
    return order
  LUA

  def execute
    order = MessagePack.unpack($redis.eval(DELETE_ORDER, [], [order_id]))
    $db.transaction do
      $db.update("orders",
        "set active = false
        where order_id = #{order_id}"
      )
      $db.update("accounts",
        "set btc_used = btc_used - #{order['btc_open']}
        where account_id = #{account_id}"
      )
    end
  end

end