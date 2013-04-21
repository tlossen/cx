# coding: utf-8
require "redis"
require "msgpack"


MATCH = <<-LUA
  local bid_id = redis.call('zrange', 'bids', 0, 0)[1]
  local bid = cmsgpack.unpack(redis.call('hget', 'orders', bid_id))

  local ask_id = redis.call('zrange', 'asks', 0, 0)[1]
  local ask = cmsgpack.unpack(redis.call('hget', 'orders', ask_id))

  if bid.eur_limit >= ask.eur_limit then

    local trade = { ask_id = ask_id, bid_id = bid_id }
    trade.rate = (bid.eur_limit + ask.eur_limit) / 2
    trade.btc = math.min(bid.btc_open, ask.btc_open)

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

def create_bid(eur_limit, btc)
  order_id = rand(1_000_000)
  $redis.hset "orders", order_id, MessagePack.pack(:eur_limit => eur_limit, :btc_open => btc)
  $redis.zadd "bids", "-#{eur_limit}.#{9_999_999_999 - Time.now.to_i}", order_id
end

def create_ask(eur_limit, btc)
  order_id = rand(1_000_000)
  $redis.hset "orders", order_id, MessagePack.pack(:eur_limit => eur_limit, :btc_open => btc)
  $redis.zadd "asks", "#{eur_limit}.#{Time.now.to_i}", order_id
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

create_bid(9700, 500)
create_bid(9770, 500)
create_ask(9970, 1000)
create_ask(9750, 300)
show_state

puts "[trade] #{MessagePack.unpack($redis.eval(MATCH))}"
show_state
