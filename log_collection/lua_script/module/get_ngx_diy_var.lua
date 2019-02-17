local _M = {}

local ngx = require "ngx"
local ut = require "log_collection.lua_script.module.utils"
local init_config = require "log_collection.config.config"
local log_lru_cache = require "log_collection.lua_script.module.log_lru_cache"



_M.get_ups_name = function()
    local upstream_name
    local back_upstream_addr
    local cache_ttl = 'null'
    -- 如果配置了缓存系统，可以在缓存系统返回数据时，返回一个后端应用服务的地址信息，内容存放在c_cache_server响应头里面

    local sent_http_z_cache_server  = ngx.var.sent_http_z_cache_server
    if  not  sent_http_z_cache_server  then
        upstream_name = ngx.var.sent_http_upstream_name or 'null'
        back_upstream_addr = upstream_addr or 'null'
    else
        local cache_data = ut.split(sent_http_z_cache_server, ":")
        upstream_name = cache_data[1] or 'null'
        back_upstream_addr = cache_data[2] .. ":" .. cache_data[3]  or  'null'
        cache_ttl = cache_data[4] or  'null'
    end
    return upstream_name,back_upstream_addr,cache_ttl
end

_M.get_upstream_time = function()
    local upstream_response_time = ngx.var.upstream_response_time
    local upstream_time = tonumber(upstream_response_time)

    if not upstream_time   then
        upstream_time = 0
        if upstream_response_time then
            local ups_time_all, err = ut.split(upstream_response_time, ",")
            for key, ups_time in pairs(ups_time_all) do
                ups_time = tonumber(ups_time) or 0
                upstream_time = upstream_time + ups_time
            end
        end
    end
        return upstream_time
end

_M.get_args_key_name = function()
    local args_key_list = {}
    local args = ngx.req.get_uri_args()
    for key, val in pairs(args) do
        table.insert(args_key_list,key)
    end
    local args_key_names = table.concat(args_key_list,"|")
    return  args_key_names
end





_M.find_uri = function(host,uri,host_uri)
    local url
    local crash_sign
    local find_lru_res = 0
    if init_config.mysql_config["active"] then
        local value, flags = log_lru_cache.get_cache_eq(host_uri)
        if (value)  then
            crash_sign = value
            url = host_uri
        else
            url,crash_sign = log_lru_cache.get_cache_match(uri,host,'prce')
            if not url  then
               url,crash_sign = log_lru_cache.get_cache_match(uri,host)
            end
        end
        url = url or 'null'
        if url == 'null' then 
           find_lru_res = 1
        end
    else
        url = url or host_uri
    end
    return url,crash_sign,find_lru_res

end


return _M
