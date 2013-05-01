-- hashcash check
-- authentication check
-- csrf token check?

local redis = require "redis"
local r = redis:new()

ok, err = r:connect("127.0.0.1", 6379)
if not ok then
  ngx.exit(444)
else
  ngx.say("ok from lua and redis")
end

-- lpush valid requests into queue
ngx.say(ngx.var.action)

return
