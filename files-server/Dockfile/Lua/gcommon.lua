gcommon = {}

-- 是否在队列中
-- 返回位置
function gcommon.in_array(v, tab)
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


-- 生成 uuid
function gcommon.uuid2()
     local template ="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
     d = io.open("/dev/urandom", "r"):read(4)
     math.randomseed(os.time() + d:byte(1) + (d:byte(2) * 256) + (d:byte(3) * 65536) + (d:byte(4) * 4294967296))
     return string.gsub(template, "x", function (c)
      local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
      return string.format("%x", v)
      end)
end

-- 获取文件名
function gcommon.getFilename(str)  
    local filename = ngx.re.match(str,'(.+)filename="(.+)"(.*)')  
    if filename then   
        return filename[2]  
    end  
end


function gcommon.getFileRealName(str)
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

-- 或缺后缀
function gcommon.get_extension(str)
    return str:match(".+%.(%w+)$")
end

-- 磁盘用量
function gcommon.getdiskuse(str)
	local handle = io.popen("df -h | grep home |awk -F ' ' '{print $5}'")
	local result = handle:read("*a")
	handle:close()
    return result

end

-- 磁盘剩余空间
function gcommon.getdiskspace()
    -- body
    local handle = io.popen("df -h | grep home |awk -F ' ' '{print $4}'")
    local result = handle:read("*a")
    return result
end