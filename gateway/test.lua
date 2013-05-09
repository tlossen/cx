-- local msec = ngx.var.msec
-- 
-- local redis = require("redis"):new()
-- local ok, err = redis:connect("127.0.0.1", 6379)
-- if not ok then
--   ngx.exit(500)
-- end
-- 
-- local auth_token = ngx.var.arg_auth_token or ""
-- local value, err = redis:hget("auth_tokens", auth_token or "")
-- if value == ngx.null then
--   ngx.exit(401)
-- end
-- local msecs = tonumber(msec)
-- local expires_at = tonumber(value)
-- if expires_at < msecs then
--   redis:hdel("auth_tokens", auth_token)
--   ngx.say(ok)
--   ngx.say(err)
--   ngx.exit(401)
-- end
-- 
-- ngx.exit(202)

-- if string.sub(ngx.var.msec, 1, 9) == string.sub(ngx.var.arg_time, 1, 9) then
--   ngx.say("within 10s")
-- else
--   ngx.exit(400)
-- end

local cjson = require("cjson.safe")
cjson.decode_max_depth(10)
local json = cjson.decode(ngx.var.request_body)

ngx.say(json)

ngx.say("ok")