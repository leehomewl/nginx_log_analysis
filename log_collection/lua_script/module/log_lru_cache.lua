local _Lcache = {}

local lrucache = require "resty.lrucache"
local ut = require "log_collection.lua_script.module.utils"
local init_config = require "log_collection.config.config"
local cjson = require "cjson"

-- 注意目录写入的权限
local dump_list = init_config.dump_list 
--缓存key的有效期,单位秒
local ttl = init_config.cache_ttl
--最大缓存的key的数量
local max_cache_key = init_config.max_cache_key


local log_uri, err = lrucache.new(max_cache_key)
if not log_uri then
    return error("failed to create the cache: " .. (err or "unknown"))
end

local log_uri_regex, err = lrucache.new(2000)
if not log_uri_regex then
    return error("failed to create the cache: " .. (err or "unknown"))
end

local log_uri_wildcard, err = lrucache.new(2000)
if not log_uri_wildcard then
    return error("failed to create the cache: " .. (err or "unknown"))
end

function _Lcache.get_cache_eq(url)
    return log_uri:get(url)
end


local find_uri = function(host,uri,url_list,uri_end)
    local jk_uri 
    for key, value_uri in pairs(url_list) do
        local m, err  = ngx.re.find(uri ,  value_uri[1] .. uri_end ,"jo")
        if m then
            jk_uri =  host .. value_uri[1]
        end
    end
    return jk_uri
end

local to_table = function(host,uri,uri_type,catch_disaster,uri_regex,uri_wildcard)
    if uri_type == "precise" then
        log_uri:set(host .. uri,catch_disaster,ttl)
    elseif uri_type == "regex" then
        if uri_regex[host] then
            table.insert(uri_regex[host],{uri,catch_disaster})
        else
            uri_regex[host] = {}
            table.insert(uri_regex[host],{uri,catch_disaster})
        end
    elseif  uri_type == "wildcard" then
        if uri_wildcard[host] then
            table.insert(uri_wildcard[host],{uri,catch_disaster})
        else
            uri_wildcard[host] = {}
            table.insert(uri_wildcard[host],{uri,catch_disaster})
        end
    end
    return 
end

function _Lcache.get_cache_match(uri,host,uri_end)
    local list 
    local res 
   -- local uri_end = uri_end
    if uri_end then
        list = log_uri_regex:get(host)
    else 
        list = log_uri_wildcard:get(host)
    end
    if list then
        for key, value_uri in pairs(list) do
            local m, err  = ngx.re.find(uri , value_uri[1] ,"jo")
            if m then
                return  host .. value_uri[1],value_uri[2]
            end
         end
    end
    return res 
end


--local test_t, err = lrucache.new(1000)
--if not test_t then
--    return error("failed to create the cache: " .. (err or "unknown"))
--end

function _Lcache.init_set_cache()
    local uri_regex = {}
    local uri_wildcard = {}
    local file =  io.open(dump_list, "r")
    if not file then
       return
    end
    for line in file:lines() do
         local res = ut.split(line,"\t")
         to_table(res[1],res[2],res[3],res[4],uri_regex,uri_wildcard)
    end
    file:close()
    for k in pairs(uri_regex) do
        log_uri_regex:set(k,uri_regex[k],ttl)
    end
    for k in pairs(uri_wildcard) do
        log_uri_wildcard:set(k,uri_wildcard[k],ttl)
    end

end


function _Lcache.set_cache()

 --   local init_config = require "config"
    local sdt = require "log_collection.config.sdt"
    local ngx = require "ngx"
    local mysql = require "resty.mysql"
    ngx.sleep(3)
    local db, err = mysql:new()
    local sql

    if sdt.online == false  then
       sql = 'select uri_type,host,uri from nginx_var_information;'
    elseif sdt.online == true then 
       sql = 'select uri_type,host,uri,catch_disaster from nginx_var_information;'
    else
        ngx.log(ngx.ERR, "config.sdt.lua 中online请设置为false或者true")
    end


    if not db then
       ngx.log(ngx.ERR,"failed to instantiate mysql: ", err)
       return
    end
    db:set_timeout(3000) --sec 
    local ok, err, errcode, sqlstate = db:connect(init_config.mysql_config) 
    if not ok then
        ngx.log(ngx.ERR,"failed to connect MySQL: ", err, ": ", errcode, " ", sqlstate)
        return
    end
    local   res, err, errcode, sqlstate =
        db:query(sql)
    if not res then
        ngx.log(ngx.ERR,"bad result: ", err, ": ", errcode, ": ", sqlstate, ".")
        return
    end

    local ok, err = db:set_keepalive(1000, 10)
    if not ok then
        ngx.say("failed to set keepalive: ", err)
        return
    end
    local pid = ngx.worker.id()
    local file
    if 0 == pid then
        file =  io.open(dump_list, "w")	
    end
    local uri_regex = {}	 
    local uri_wildcard = {}	 
    for i, one  in ipairs(res) do
        local uri_type =  one['uri_type']
        local uri = one['uri']
        local host = one['host']
        local catch_disaster = one['catch_disaster'] or 0 
        to_table(host,uri,uri_type,catch_disaster,uri_regex,uri_wildcard)
        if 0 == pid then
            file:write(host .. "\t" .. uri .. "\t" .. uri_type .. "\t" .. catch_disaster .. "\n")
        end
    end
    if 0 == pid then
        file:close()
    end	
    for k in pairs(uri_regex) do
        log_uri_regex:set(k,uri_regex[k],ttl) 
    end
    for k in pairs(uri_wildcard) do
        log_uri_wildcard:set(k,uri_wildcard[k],ttl) 
    end
    return 'ok'

end

return _Lcache

