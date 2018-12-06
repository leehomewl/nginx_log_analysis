local cron_check = require "check_cron"
local ngx = require "ngx"
local init_config = require "config"
local log_lru_cache = require "log_lru_cache"

if 0 == ngx.worker.id() then
    local lua_data = ngx.shared.lua_data;
    local hostname = lua_data:get("hostname")
    if hostname == init_config.hostname_crond and init_config.influxdb_cq_init then
        local ok, err = ngx.timer.every(120, cron_check.check_mask)
        if not ok then
            ngx.log(ngx.ERR, "failed to create timer: ", err)
            return
        end
    end
end


if  not init_config.mysql_config["active"]  then
    return
end

local ok, err = ngx.timer.at(0, log_lru_cache.init_set_cache)
if not ok then
    ngx.log(ngx.ERR, "failed to create the timer: ", err)
    return
end

local ok, err = ngx.timer.every(init_config.update_cache_time, log_lru_cache.set_cache)
if not ok then
    ngx.log(ngx.ERR, "failed to create timer: ", err)
    return
end
