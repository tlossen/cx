--[[
-- hashcash check
-- hmac signature check
  local access_key = ngx.var.http_x_access_key
  local signature = ngx.var.http_x_signature

  local secret, err = r.hget("secrets", access_key)
  local string_to_sign = ngx.var.http_date .. ngx.var.request_body
  if signature ~= ngx.encode_base64(ngx.hmac_sha1(secret, string_to_sign)) then
    ngx.exit(401)
  end

-- protect against replays
  if ngx.time + 60 > ngx.parse_http_time(ngx.var.http_date) then
    ngx.exit(400)
  end

-- csrf token check?
]]

local redis = require "redis"
local r = redis:new()

local ok, err = r:connect("127.0.0.1", 6379)
if not ok then
  ngx.exit(444)
end

-- lpush valid requests into queue
local ok, err = r:lpush("inbox", ngx.var.request_body)
if not ok then
  ngx.exit(500)
else
  ngx.exit(202)
end
