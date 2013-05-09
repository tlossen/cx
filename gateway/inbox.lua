-- timestamp must be within 10s
local msec = ngx.var.msec
local timestamp = ngx.var.http_x_time or ngx.exit(400)
if string.sub(msec, 1, 9) ~= string.sub(timestamp, 1, 9) then
  ngx.exit(400)
end

-- hashcash
local request_body = ngx.var.request_body or ngx.exit(400)
local request_body_hash = sha2.sha256hex(request_body)
local auth_token = ngx.var.http_x_auth or ""
local nons = ngx.var.http_x_nons or ngx.exit(400)
local cash = ngx.var.http_x_cash or ngx.exit(400)
local hash = ngx.var.remote_addr .. timestamp .. auth_token .. request_body_hash .. nons
if not sha2.sha256hex(hash) == cash then
  ngx.exit(400)
end

-- connect to redis
local redis = require("redis"):new()
local ok, err = redis:connect("127.0.0.1", 6379)
if not ok then
  ngx.exit(500)
end

-- verify auth_token
-- {"get":"auth_token"} requests need no auth_token verification
if request_body_hash ~= "b755a32a4e580fea87fe192110098f0350829a41fc3bb135ecfd7eda50aaf85c" then
  local expires, err = redis:hget("auth_tokens", auth_token)
  if expires == ngx.null then
    ngx.exit(401)
  end
  if tonumber(expires) < tonumber(msec) then
    redis:hdel("auth_tokens", auth_token)
    ngx.exit(401)
  end
end

-- verify json
local cjson = require("cjson.safe")
cjson.decode_max_depth(2)
local value, err = cjson.decode(request_body)
if not value then
  ngx.exit(400)
end

-- lpush valid requests into queue
local ok, err = redis:lpush("inbox", request_body)
if not ok then
  ngx.exit(500)
else
  ngx.exit(202)
end
