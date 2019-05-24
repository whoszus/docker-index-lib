local upload = require "resty.upload"
local cjson = require "cjson"
local lfs = require"lfs"
local chunk_size = 4096
local form = upload:new(chunk_size)
local conf = {fileHome='/home/tinker/temp/upload/',version=1007,allow_exts={'mpeg','mov','pdf','doc','zip','swf','jar','xls','docx','xlsx','pptx','avi','mp4','tiff','3gp','wmv','apk','exe','tar'}}
local file
local file_name
local file_name_arry = {}
local orign_name_array ={}
local resposeData={code=500,msg='upload fail',desc='上传失败',server_verison= conf.version,file_orign_name= orign_name_array,diskstatus={diskuse=getdiskuse(),diskspace= getdiskspace()}}

if not form then
    resposeData.desc='请选择'
    ngx.say(cjson.encode(resposeData));
end


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
	local handle = io.popen("df -h | grep home |awk -F ' ' '{print $5}'")
	local result = handle:read("*a")
	handle:close()
    return result

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
                local dir = conf.fileHome..os.date('%Y')..os.date('%m')..os.date('%d')..'/'   
                local status = os.execute('mkdir -p '..dir)
                if not status then
                    ngx.say(cjson.encode({code=501, msg='创建目录失败'}))
                    return
                end  
                
                -- 如果文件扩展名命中-- 使用文件原来的名字
                if in_array(extension, conf.allow_exts) then
                	local file,err=io.open(dir..filename)
                	if file == nil then 
                		ngx.log(ngx.ERR,"ERR....filename: "..filename)
						file_name = dir..getFileRealName(filename)
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
                        file_name = string.gsub(file_name, conf.fileHome, '')
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
                --  todo  修改返回值 
                resposeData.code=200;
                ngx.say(cjson.encode(resposeData));
                ngx.log(ngx.DEBUG,'file_name' .. file_name)
            else
                ngx.say(cjson.encode({code=509, msg='form name do not existed',desc='',server_verison= conf.version,file_orign_name= orign_name_array,diskstatus= {diskuse= getdiskuse(),diskspace= getdiskspace()}}))
        end
        break
        else
            
        end
    end
