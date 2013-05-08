#!/usr/bin/env ruby

require "redis"
require "json"

$redis = Redis.new

while response = $redis.brpop("inbox") do
  message = JSON.parse(response[1])
  p message
  case message["action"]
  when "get:user"
    $redis.publish(message["channel"], JSON.generate(event_type:"set:user", user: {name: "Joe Doe #{rand}"}))
  end
end
