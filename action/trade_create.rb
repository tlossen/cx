# coding: utf-8
class TradeCreate < Action

  def execute
    trade = unpack($redis.eval(DATA))
    if trade
      btc, bid_id, ask_id = trade.values_at(%w[btc bid_id ask_id])
      $db.transaction do
        $db.update(:orders,
          "set
            btc_open = btc_open - #{btc},
            active = btc_open > 0
          where
            order_id = #{bid_id}"
        )
        $db.update(:orders,
          "set
            btc_open = btc_open - #{btc},
            active = btc_open > 0
          where
            order_id = #{ask_id}"
        )
        trade_id = $db.insert(:trades, trade.merge(created_at: Time.stamp))
        # move this into the worker?
        $redis.lpush("trades", trade_id)
      end
    end
  end

end

__END__
local bid_id = redis.call('zrange', 'bids', 0, 0)[1]
local bid = cmsgpack.unpack(redis.call('hget', 'orders', bid_id))

local ask_id = redis.call('zrange', 'asks', 0, 0)[1]
local ask = cmsgpack.unpack(redis.call('hget', 'orders', ask_id))

if bid.eur_limit < ask.eur_limit then
  return nil
end

local trade = {
  bidder_id = bid.account_id,
  asker_id = ask.account_id,
  bid_id = bid_id,
  ask_id = ask_id,
  btc = math.min(bid.btc_open, ask.btc_open)
}

local last_rate = tonumber(redis.call('get', 'rate')) or 0
if last_rate >= bid.eur_limit then
  trade.eur_rate = bid.eur_limit
elseif last_rate <= ask.eur_limit then
  trade.eur_rate = ask.eur_limit
else
  trade.eur_rate = last_rate
end
redis.call('set', 'rate', trade.eur_rate)

bid.btc_open = bid.btc_open - trade.btc
if bid.btc_open == 0 then
  redis.call('hdel', 'orders', bid_id)
  redis.call('zremrangebyrank', 'bids', 0, 0)
else
  redis.call('hset', 'orders', bid_id, cmsgpack.pack(bid))
end

ask.btc_open = ask.btc_open - trade.btc
if ask.btc_open == 0 then
  redis.call('hdel', 'orders', ask_id)
  redis.call('zremrangebyrank', 'asks', 0, 0)
else
  redis.call('hset', 'orders', ask_id, cmsgpack.pack(ask))
end

return cmsgpack.pack(trade)
