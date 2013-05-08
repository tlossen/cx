#!/usr/bin/env ruby

require "socket"
require "redis"

trap(:INT) { puts; exit }

redis = Redis.new
begin
  redis.psubscribe("*") do |on|

    on.pmessage do |pattern, channel, data|
      event_type = data =~ /"event_type":"([^"]+)"/ && $1
      puts "Event-Type: #{event_type}\n" +
           "#{channel}: #{data}"
      # TODO: make persistent socket (keepalive?)
      socket = UNIXSocket.new("/tmp/cx_gateway_publish.sock")
      socket.write([
        "POST /publish HTTP/1.0",
        "Content-Length: #{data.size}",
        "X-Channel: #{channel}",
        "Event-Type: #{event_type}",
        "",
        data
      ].compact.join("\r\n"))
      socket.close
    end

  end
rescue Redis::BaseConnectionError => error
  puts "#{error}, retrying in 1s"
  sleep 1
  retry
end
