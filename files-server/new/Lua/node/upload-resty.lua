local upload = require "resty.upload"
local cjson = require "cjson"
local redis_util = require "redis-util"
-- local socket  = require("sock")

local redis, err  = redis_util:new();
local localIp


local chunk_size = 4096
local form = upload:new(chunk_size)
local conf = {max_size=1024000, allow_exts={'mpeg','mov','pdf','doc','zip','swf','jar','xls','docx','xlsx','pptx','avi','mp4','tiff','3gp','wmv','apk','exe','tar'}}
local file
local file_name
local file_name_arry = {}
local orign_name_array ={}
local today  = os.date('%Y')..os.date('%m')..os.date('%d')
local dest_file_path = '/home/tinker/temp/upload/'


if not form then
    ngx.say(cjson.encode({code=501, msg='form is null',desc='表单内容为空！'}))
end

--判断某个值是否在数组中
local function in_array(v, tab)
    local i = false
    local temp = string.lower(v)
    for _, val in ipairs(tab) do
        if val == temp then
            i = true
            break
        end
    end
    return i
end

local function getLocalIP()
    -- local command  = "/sbin/ifconfig -a | grep inet | egrep -v '(127.0.0.1|inet6)'  | awk     '{print $2}' | tr -d "addrs" | grep -v '\.0\.'|awk 'NR==1{print}'" 
    local hostName = socket.dns.gethostname()
    local ip, resolved = socket.dns.toip(hostName)
    for k,v in ipairs(resolved,ip) do 
        ngx.log(ngx.ERR,v)
    end 
    return  resolved[1];
end

local function getLocalIpByOS( ... )
	if localIp then 
		return localIp 
	end 
	 
	local command =  "/sbin/ifconfig -a | grep inet | egrep -v '(127.0.0.1|inet6)'  | awk     '{print $2}' | tr -d \"addrs\" | grep -v '\\.0\\.'|awk 'NR==1{print}'"
	-- body
	local handle = io.popen(command)
	local result = handle:read("*a")
	handle:close()
	localIp = result -- set local server ip cache ,this cache will dispear with the nginx lua code cache, reduce frequency io operate
	return result


end


local function  file_redis_save(key,field_table)
    if not key or not field_table then
        ngx.log(ngx.ERR,"param empty")
        return
    end
  	-- local hostName = ngx.var.hostname;

    local localServerIP = getLocalIpByOS();

    -- redis:sadd(set_name,unpack(file_name_table)) --https://github.com/openresty/lua-resty-redis/issues/112
    -- key: today  field: file_name ,value : server ip addr or localIp 
    for k,field in ipairs(field_table) do 
    	ngx.log(ngx.ERR,"key"..key.."!!!!!.....field"..field.."!!!!!!!......value:"..localServerIP)
        redis:hset(key,field,localServerIP) -- save to redis by for loop 
    end
end


local function uuid2()
     local template ="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
     d = io.open("/dev/urandom", "r"):read(4)
     math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
     return string.gsub(template, "x", function (c)
      local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
      return string.format("%x", v)
      end)
end

local function get_filename(str)  
    local filename = ngx.re.match(str,'(.+)filename="(.+)"(.*)')  
    if filename then   
        return filename[2]  
    end  
end

local function getFileRealName(str)
	--return str:match(".+/(.+)$")
	-- real_name
	if(string.find(str,"/")) then  
		if(str) then
			local name = string.gsub(str,"\\","/");
			return name:match(".+/(.+)$");
		else
			return "default-file-name";
		end
	else
		return  str
	end

end

local function get_extension(str)
    return str:match(".+%.(%w+)$")
end

local function getdiskuse(str)
     -- df -h | grep root |awk -F ' ' '{print $5}' | cut -d '%' -f 1
    -- use = os.execute("df -h | grep home |awk -F ' ' '{print $5}'  | cut -d '%' -f 1 ")
    -- if not use  or use == 0 then 
    --     use =  os.execute("df -h | grep root |awk -F ' ' '{print $5}' ")
    -- end
	local handle = io.popen("df -h | grep home |awk -F ' ' '{print $5}'")
	local result = handle:read("*a")
	handle:close()
    return  result

end

local function getdiskspace()
    -- body
    local handle = io.popen("df -h | grep home |awk -F ' ' '{print $4}'")
    local result = handle:read("*a")
    return result
end

form:set_timeout(1000)

while true do
    local typ, res, err = form:read() 
    -- ngx.say("read: ", cjson.encode({typ, res}))
    if not typ then
         ngx.say(cjson.encode({code=503, msg='failed to read',desc='读取form失败!'}))
         ngx.log(ngx.DEBUG,cjson.encode({typ, res}));
         return
    end
    -- ngx.log(ngx.ERR,cjson.encode({typ, res}));
    if typ == "header" then
        if res[1] == "Content-Disposition" then
            filename = get_filename(res[2])
            if filename then
                local extension = get_extension(filename)
                -- getLocalIP();
                if not extension then
                    ngx.say(cjson.encode({code=501, msg='未获取文件后缀', desc=res}))
                    return 
                end

                -- 创建文件路径
                local dir = dest_file_path..today.."/" 
                file,err = io.open(dir)
                if not file then 

                    local status = os.execute('mkdir -p '..dir)

                    if status ~= 0 then
                        ngx.say(cjson.encode({code=501, msg='创建目录失败'}))
                        return
                    end  
                end 
                
                -- 如果文件扩展名命中-- 使用文件原来的名字
                if in_array(extension, conf.allow_exts) then
                	local file,err=io.open(dir..filename)
                	if file == nil then 
                		ngx.log(ngx.ERR,"filename~~"..filename)
                		ngx.log(ngx.ERR,"getFileRealName~~"..getFileRealName(filename))
						file_name = dir..getFileRealName(filename)

 	                   --file_name = dir..getFileRealName(filename)
 	                 else
 	                 	-- 文件名重复处理 时间戳_文件名
 	                 	file.close()
 	                 	file_name = dir..os.time().."_"..getFileRealName(filename)
 	                 end
              	else
              		local file_id = uuid2()
              		file_name = dir..file_id.."."..extension
                end
                
                -- 处理文件名返回处理
                if file_name then
                    file = io.open(file_name, "w+")
                    if not file then
                        ngx.say(cjson.encode({code=500, msg='failed to write file',imgurl=''}))
                        return
                    else
                        file_name = string.gsub(file_name, dest_file_path, '')
                        table.insert(file_name_arry,file_name);
                        table.insert(orign_name_array,filename);
                    end
                end
            end
        end
        elseif typ == "body" then
            if file then
                file:write(res)            
        end
        elseif typ == "part_end" then
            if file then
                file:close()
                ngx.log(ngx.DEBUG,'close files end ')
                file = nil
        end
        elseif typ == "eof" then
            if file_name then 
                file_redis_save(today,file_name_arry) --文件路径记录到redis中
                ngx.say(cjson.encode({code=200, msg='上传成功！',desc= file_name_arry, server_verison= server_verison, file_orign_name= orign_name_array,diskstatus= {diskuse=getdiskuse(),diskspace= getdiskspace()}}))
                ngx.log(ngx.DEBUG,'file_name' .. file_name)
            else
                ngx.say(cjson.encode({code=509, msg='form name do not existed',desc='',server_verison= server_verison,file_orign_name= orign_name_array,diskstatus= {diskuse= getdiskuse(),diskspace= getdiskspace()}}))
        end
        break
        else
            
        end
    end
