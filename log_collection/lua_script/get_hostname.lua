local utils = require "utils"
local lua_data = ngx.shared.lua_data;
local hostname = utils.hostname()
lua_data:set("hostname", hostname)
--ngx.log(ngx.ERR,'The hostname is  :' ,lua_data:get("hostname"))

