local ut = require "utils"
local ngx = require "ngx"
local init_config = require "config"
local sdt = require "sdt"
local logger = require "resty.logger.socket"
local random = require "resty.random"
local log_lru_cache = require "log_lru_cache"


local host = ngx.var.host or ''
local uri =  ngx.var.uri  or ''
local host_uri = host .. uri


local get_ups_name = function()
    local upstream_name
    local back_upstream_addr
    local cache_ttl = 'null'
    local sent_http_cache_server  = ngx.var.sent_http_cache_server
    if  not  sent_http_cache_server  then
        upstream_name = ngx.var.sent_http_upstream_name or 'null'
        back_upstream_addr = upstream_addr or 'null'
    else
        local cache_data = ut.split(sent_http_cache_server, ":")
        upstream_name = cache_data[1] or 'null'
        back_upstream_addr = cache_data[2] .. ":" .. cache_data[3]  or  'null'
        cache_ttl = cache_data[4] or  'null'
    end
    return upstream_name,back_upstream_addr,cache_ttl
end



local get_upstream_time = function()
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


local escape_uri = function(list)
    for k,v in  pairs(list) do
        if v == 'http_user_agent' and http_user_agent ~= '' then
            http_user_agent = ngx.escape_uri(http_user_agent)
        elseif v == 'http_referer' and http_referer  ~= ''  then
            http_referer = ngx.escape_uri(http_referer)
	elseif v == 'args' and args  ~= ''  then
            args = ngx.escape_uri(args)
        elseif v == 'uri' and uri  ~= '' then
            uri = ngx.escape_uri(uri)
	elseif v == 'host' and host  ~= '' then
            host = ngx.escape_uri(host)
        end
    end
end


local find_uri = function()
    local jk_uri
    local crash_sign

    if init_config.mysql_config["active"] then
        local value, flags = log_lru_cache.get_cache_eq(host_uri)
        if (value)  then
            crash_sign = value
            jk_uri = host_uri
        else
            jk_uri,crash_sign = log_lru_cache.get_cache_match(uri,host,'$')
            if not jk_uri  then
               jk_uri,crash_sign = log_lru_cache.get_cache_match(uri,host)
            end
        end
        jk_uri = jk_uri or 'null'
    else 
        jk_uri = jk_uri or host_uri
    end
    return jk_uri,crash_sign
    
end

local upstream_time = get_upstream_time()
local upstream_name,upstream_addr,cache_ttl = get_ups_name()
local url,crash_sign = find_uri()

local find_lru_res = 0 
if not jk_uri  then 
     find_lru_res  = 1
end

escape_uri(init_config.escape_list)

local random_num = random.number(100000000, 999999999)
local time_now = tostring(ngx.time() ) .. random_num
if not logger.initted() then
    local ok, err = logger.init(
         init_config.influx_config
    )
    if not ok then
        ngx.log(ngx.ERR, "failed to initialize the logger: ",err)
        return
    end
end

local get_ngx_var = require "get_ngx_var"
local tags = get_ngx_var.concat_tags(init_config.tags,url,host,upstream_name)
local fields = get_ngx_var.concat_fields(init_config.fields,upstream_time,uri,crash_info,find_lru_res)
local msg_measurement =  init_config.influxdb_table .. ","
local msg = msg_measurement .. tags  .. " " .. fields ..  " "  .. time_now .."\n"

local bytes, err = logger.log(msg)
if err then
    ngx.log(ngx.ERR, "failed to log message: ", err)
    return
end

return
