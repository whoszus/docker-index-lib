### dockerfile for files-server

FROM openresty-ubuntu:xenial

# install lua  modules;
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-upload
RUN /usr/local/openresty/luajit/bin/luarocks install lua-cjson
RUN /usr/local/openresty/luajit/bin/luarocks install luafilesystem

# nginx configuration; 
COPY nginx-entry.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx-plus.conf /etc/nginx/conf.d/default.conf

# lua project 
COPY upload-resty.lua /etc/nginx/conf.d/
COPY zip_files_handle.lua /etc/nginx/conf.d/

# startup.sh 

CMD ["openresty", "-g", "daemon off;"]


