# coding: utf-8
require "redis"
require "msgpack"


MATCH = <<-LUA
  local bid_id = redis.call('zrange', 'bids', 0, 0)[1]
  local bid = cmsgpack.unpack(redis.call('hget', 'orders', bid_id))

  local ask_id = redis.call('zrange', 'asks', 0, 0)[1]
  local ask = cmsgpack.unpack(redis.call('hget', 'orders', ask_id))

  if bid.eur_limit >= ask.eur_limit then

    local trade = {
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
  end
LUA

DELETE_ORDER = <<-LUA
  local order_id = ARGV[1]
  local order = redis.call('hget', 'orders', order_id)
  redis.call('zrem', 'bids', order_id)
  redis.call('zrem', 'asks', order_id)
  redis.call('hdel', 'orders', order_id)
  return order
LUA

def create_bid(eur_limit, btc)
  order_id = rand(1_000_000)
  $redis.hset "orders", order_id, MessagePack.pack(:eur_limit => eur_limit, :btc_open => btc)
  $redis.zadd "bids", "-#{eur_limit}.#{9_999_999_999 - Time.now.to_i}", order_id
  order_id
end

def create_ask(eur_limit, btc)
  order_id = rand(1_000_000)
  $redis.hset "orders", order_id, MessagePack.pack(:eur_limit => eur_limit, :btc_open => btc)
  $redis.zadd "asks", "#{eur_limit}.#{Time.now.to_i}", order_id
  order_id
end

def show_state
  puts "-----" * 10
  $redis.hgetall("orders").each do |key, value|
    puts "[orders] #{key}: #{MessagePack.unpack(value)}"
  end
  $redis.zrevrange("asks", 0, -1, :withscores => true).each do |value, score|
    puts "[asks] #{score}: #{value}"
  end
  $redis.zrange("bids", 0, -1, :withscores => true).each do |value, score|
    puts "[bids] #{score}: #{value}"
  end
  puts "-----" * 10
end

$redis = Redis.new
$redis.flushdb

bid1 = create_bid(9700, 500)
create_bid(9770, 500)
create_ask(9970, 1000)
create_ask(9750, 300)
show_state

puts "[trade] #{MessagePack.unpack($redis.eval(MATCH))}"
show_state

puts "[delete] #{MessagePack.unpack($redis.eval(DELETE_ORDER, [], [bid1]))}"
show_state
