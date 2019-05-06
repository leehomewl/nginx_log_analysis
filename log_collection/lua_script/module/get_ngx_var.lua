local _G = {}

local ngx = require "ngx"
local sdt = require "log_collection.config.sdt"
local get_ngx_diy_var = require "log_collection.lua_script.module.get_ngx_diy_var"

--influxdb tags，索引在这个函数进行添加
_G.concat_tags = function(tags,mysql_host_uri,host,upstream_name)
    local status = tonumber(ngx.var.status) or 00
    local tags_list = {}
    for i, v in pairs(tags) do
        if v == "status"  then
            tags_list[i] =  v .. '=' .. status
        elseif v == "mysql_host_uri"  then
            tags_list[i] =  v .. '=' .. mysql_host_uri
        elseif v == "host"  then
            tags_list[i] =  v .. '=' .. host
        --elseif v == "get_args_key_name"  then
          --  local get_args_key_name = get_ngx_diy_var.get_args_key_name()
           -- tags_list[i] =  v .. '="' .. get_args_key_name  .. '"'
        elseif v == "upstream_name"  then
            tags_list[i] =  v .. '=' .. upstream_name
        end
    end
    local res = table.concat(tags_list,",")
    return res
end

--influxdb field，在这个函数进行添加
_G.concat_fields = function(fields,upstream_time,uri,crash_info,find_lru_res,crash_sign,host,cache_ttl)
    local upstream_status = ngx.var.upstream_status or ''
    local upstream_addr = ngx.var.upstream_addr or ''
    local http_user_agent =  ngx.var.http_user_agent or ''
    local args = ngx.var.args or ''
    local http_referer = ngx.var.http_referer or ''
    local remote_addr = ngx.var.remote_addr or ''
    local crash_info = ngx.var.zb_info or ''
    local request_length = ngx.var.request_length or ''
    local server_addr = ngx.var.server_addr or ''
    local server_port = ngx.var.server_port or ''
    local server_ip_port = server_addr .. ":" .. server_port
    local scheme = ngx.var.scheme or ''
    local request_method =  ngx.var.request_method or ''
    local time_local = ngx.var.time_iso8601 or ''
    local body_bytes_sent = ngx.var.body_bytes_sent or ''
    local request_time = ngx.var.request_time or '0'
    local upstream_cache_status = ngx.var.upstream_cache_status or ''

    local fields_list = {}
    for i, v in pairs(fields) do
        if v == "upstream_time"  then
            fields_list[i] =  v .. '=' .. upstream_time 
        elseif v == "upstream_status" then
            fields_list[i] =  v .. '="' .. upstream_status .. '"'
        elseif v == "upstream_addr" then
            fields_list[i] =  v .. '="' .. upstream_addr .. '"'
        elseif v == "http_user_agent" then
            fields_list[i] =  v .. '="' .. http_user_agent .. '"'
        elseif v == "uri" then
            fields_list[i] =  v .. '="' .. uri .. '"'
        elseif v == "args" then
            fields_list[i] =  v .. '="' .. args .. '"'
        elseif v == "http_referer" then
            fields_list[i] =  v .. '="' .. http_referer .. '"'
        elseif v == "remote_addr" then
            fields_list[i] =  v .. '="' .. remote_addr .. '"'
        elseif v == "crash_info" then
            fields_list[i] =  v .. '="' .. crash_info .. '"'
        elseif v == "request_length" then
            fields_list[i] =  v .. '=' .. request_length
        elseif v == "server_ip_port" then
            fields_list[i] =  v .. '="' .. server_ip_port .. '"'
        elseif v == "scheme" then
            fields_list[i] =  v .. '="' .. scheme .. '"'
        elseif v == "request_method" then
            fields_list[i] =  v .. '="' .. request_method .. '"'
        elseif v == "time_local" then
            fields_list[i] =  v .. '="' .. time_local .. '"'
        elseif v == "find_lru_res" then
            fields_list[i] =  v .. '="' .. find_lru_res .. '"'
        elseif v == "body_bytes_sent" then
            fields_list[i] =  v .. '=' .. body_bytes_sent 
        elseif v == "request_time" then
            fields_list[i] =  v .. '=' .. request_time 
        elseif v == "upstream_cache_status" then
            fields_list[i] =  v .. '="' .. upstream_cache_status .. '"'
        elseif v == "cache_ttl" then
            fields_list[i] =  v .. '="' .. cache_ttl .. '"'
        else
            fields_list[i] =  v .. '="' .. 'null' .. '"'
            ngx.log(ngx.ERR,v,"is not support into influxdb, we not found it")
        end
    end
    local org_url = ''
    if sdt.online  and tonumber(crash_sign) == 1 then
        org_url = host .. ngx.var.request_uri
        local org_url_data =  'org_url' .. '="' .. org_url .. '"'
        table.insert(fields_list,org_url_data)
    end

    local res = table.concat(fields_list,",")
    return res
end
return _G
