require "sha2"

-- timestamp must be within 10s
local timestamp = ngx.var.arg_timestamp or ngx.exit(400)
if string.sub(ngx.var.msec, 1, 9) == string.sub(timestamp, 1, 9) then
  ngx.say("within 10s")
else
  ngx.exit(400)
end

-- hashcash
local private_channel_token = ngx.var.arg_private_channel_token or ""
local nons = ngx.var.arg_nons or ngx.exit(400)
local cash = ngx.var.arg_cash or ngx.exit(400)
local hash = ngx.var.remote_addr .. timestamp .. private_channel_token .. nons
if not sha2.sha256hex(hash) == cash then
  ngx.exit(400)
end

-- verify private_channel_token if given
if private_channel_token ~= "" then
  local redis = require("redis"):new()
  local ok, err = redis:connect("127.0.0.1", 6379)
  if not ok then
    ngx.exit(500)
  end
  local ok, err = redis:sismember("private_channel_tokens", private_channel_token)
  if ok ~= 1 then
    ngx.exit(400)
  end
end

-- return channels
return "firehose/" .. private_channel_token
