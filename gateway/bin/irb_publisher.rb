#!/usr/bin/env ruby

require "pry"
require "socket"
require "json"

def publish(channel = "firehose", event_id = nil, event_type = nil, data)
  content = JSON.generate(data)
  socket = UNIXSocket.new("/tmp/cx_gateway_publish.sock")
  socket.write([
    "POST /publish HTTP/1.0",
    "Content-Length: #{content.size}",
    "X-Channel: #{channel}",
    event_id ? "Event-ID: #{event_id}" : nil,
    event_type ? "Event-Type: #{event_type}" : nil,
    "",
    content
  ].compact.join("\r\n"))
  socket.close
end

binding.pry
