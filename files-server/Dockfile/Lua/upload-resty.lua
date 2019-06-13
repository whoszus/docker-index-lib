local upload = require "resty.upload"
local cjson = require "cjson"
-- local lfs = require "lfs"
local tkg = require "tkg"
local chunk_size = 4096
local form = upload:new(chunk_size)
local conf = {fileHome='/home/tinker/temp/upload/',version=1007,allow_exts={'mpeg','mov','pdf','doc','zip','swf','jar','xls','docx','xlsx','pptx','avi','mp4','tiff','3gp','wmv','apk','exe','tar'}}



local function getFileSecondPath()
    local file_path  = tkg.getParam(form,"file_path")
    local 
    if file_path ~= nil then 
        return file_path
    end
    return os.date('%Y')..os.date('%m')..os.date('%d')..'/';
end




local function uploadHandle()
    -- ngx.log(ngx.ERR,"测试tkg~~")
    -- ngx.log(ngx.ERR,tkg)
    local resposeData={code=500,msg='upload fail',desc='上传失败',server_verison= conf.version,file_orign_name= orign_name_array,diskstatus={diskuse=tkg.getdiskuse(),diskspace= tkg.getdiskspace()}}
    local file
    local file_name
    local file_name_arry = {}
    local orign_name_array ={}

    if not form then
        resposeData.desc='图片不存在'
    end
    
    -- test code 
    -- local typ, res, err = form:read()
    -- ngx.say(cjson.encode(tkg.loadFormInput(form,"file_path")))
    -- testcode end 

    
    while true do
       
        form:set_timeout(1000)
        local typ, res, err = form:read() 
        if not typ then
            ngx.say(cjson.encode({code=503, msg='failed to read',desc='读取form失败!'}))
            ngx.log(ngx.DEBUG,cjson.encode({typ, res}));
            return
        end
        -- local form_args = tkg.post_form_data(from,err)
        
        if typ == "header" then
            if res[1] == "Content-Disposition" then
                filename = tkg.getFilename(res[2])
                if filename then
                    local extension = tkg.get_extension(filename)
                    if not extension then
                        -- todo 修改为标准格式；
                        ngx.say(cjson.encode({code=501, msg='无法获取文件后缀', desc=res}))
                        return 
                    end

                    -- 创建文件路径
                    local dir = conf.fileHome..getFileSecondPath()  
                    local status = os.execute('mkdir -p '..dir)
                    if not status then
                        -- TODO 修改为标准格式
                        ngx.say(cjson.encode({code=501, msg='创建目录失败'}))
                        return
                    end  
                    
                    -- 如果文件扩展名命中-- 使用文件原来的名字
                    if tkg.in_array(extension, conf.allow_exts) then
                        local file,err=io.open(dir..filename)
                        if file == nil then 
                            ngx.log(ngx.ERR,"ERR....filename: "..filename)
                            file_name = dir..tkg.getFileRealName(filename)
                            else
                            -- 文件名重复处理 时间戳_文件名
                            file.close()
                            file_name = dir..os.time().."_"..tkg.getFileRealName(filename)
                            end
                    else
                        local file_id = tkg.uuid2()
                        file_name = dir..file_id.."."..extension
                    end
                    
                    -- 处理文件名返回处理
                    if file_name then
                        file = io.open(file_name, "w+")
                        if not file then
                            -- TODO 修改为标准格式
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
                file = nil
            end
        elseif typ == "eof" then
            if file_name then 
                --todo  修改返回值 
                resposeData.code=200;
                ngx.say(cjson.encode(resposeData));
                ngx.log(ngx.DEBUG,'file_name' .. file_name)
            else
                ngx.say(cjson.encode({code=509, msg='form name do not existed',desc='',server_verison= conf.version,file_orign_name= orign_name_array,diskstatus= {diskuse= tkg.getdiskuse(),diskspace= tkg.getdiskspace()}}))
            end
            -- 跳出while
            break
        else
        end
    end
end
-- ngx.say(cjson.encode(_M:uploadHandle()))
uploadHandle()
