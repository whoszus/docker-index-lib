-- 文件服务器状态检测 
local cjson =require "cjson"
local server_verison = "t.2.0.1"
function getdiskuse(str)
   local handle = io.popen("df -h | grep home |awk -F ' ' '{print $5}'")
   local result = handle:read("*a")
   handle:close()

   return  result
end

function getdiskspace()
    -- body
    local handle = io.popen("df -h | grep home |awk -F ' ' '{print $4}'")
    local result = handle:read("*a")
    return result
end

ngx.say(cjson.encode({code=200, msg='healthy',diskstatus= {home_space_used=getdiskuse(),home_space_left= getdiskspace()}}))
                