local cron_check = require "log_collection.lua_script.module.check_cron"
local ngx = require "ngx"
local init_config = require "log_collection.config.config"
local log_lru_cache = require "log_collection.lua_script.module.log_lru_cache"

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

if  init_config.mysql_config["active"]  then
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
end


local cron_add_to_lc = require "staic_dt.lua_script.cron_add_to_lc"
cron_add_to_lc.set_dt_cache()




--如果你有其他的定时任务要执行，请在下面配置即可，不会产生冲突
