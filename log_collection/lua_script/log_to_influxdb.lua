local ngx = require "ngx"
local logger = require "resty.logger.socket"
local random = require "resty.random"
local ut = require "log_collection.lua_script.module.utils"
local init_config = require "log_collection.config.config"
local sdt = require "log_collection.config.sdt"
local log_lru_cache = require "log_collection.lua_script.module.log_lru_cache"
local get_ngx_var = require "log_collection.lua_script.module.get_ngx_var"
local get_ngx_diy_var = require "log_collection.lua_script.module.get_ngx_diy_var"
local escape_var = require "log_collection.lua_script.module.escape_var"

local host = ngx.var.host or ''
local uri =  ngx.var.uri  or ''
local host_uri = host .. uri


local upstream_time = get_ngx_diy_var.get_upstream_time()
local upstream_name,upstream_addr,cache_ttl = get_ngx_diy_var.get_ups_name()
local mysql_host_uri,crash_sign,find_lru_res =  get_ngx_diy_var.find_uri(host,uri,host_uri)

escape_var.escape_uri(init_config.escape_list)



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
local tags = get_ngx_var.concat_tags(init_config.tags,mysql_host_uri,host,upstream_name)
local fields = get_ngx_var.concat_fields(init_config.fields,upstream_time,uri,crash_info,find_lru_res,crash_sign,host,cache_ttl)
local msg_measurement =  init_config.influxdb_table .. ","
local msg = msg_measurement .. tags  .. " " .. fields ..  " "  .. time_now .."\n"

local bytes, err = logger.log(msg)
if err then
    ngx.log(ngx.ERR, "failed to log message: ", err)
    return
end

return
