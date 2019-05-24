local redis_util = require "redis-util"

local redis, err  = redis_util:new();
local request_uri = ngx.var.request_uri;

ngx.say(request_uri);
