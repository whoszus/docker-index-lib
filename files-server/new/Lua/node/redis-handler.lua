local redis_util = require "redis-util"

local redis, err  = redis_util:new();


local ok, err = redis:set("dog", "an animal")
if not ok then
    ngx.say("failed to set dog: ", err)
    return
end
ngx.say(redis:get("dog"))
