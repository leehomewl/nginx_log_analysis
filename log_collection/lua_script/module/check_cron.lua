local check_cron = {}

local http = require "resty.http"
local init_config = require "log_collection.config.config"
local influxdb_cron = require "log_collection.config.influxdb_cron"
local ngx = require "ngx"


local find_cq_name = function(cq_sql)
    local prce_cq_name = [[CREATE\s+CONTINUOUS\s+QUERY\s+"?(\w+)"?\s+ON]];
    local m, err = ngx.re.match(cq_sql,prce_cq_name ,"ijo")
    local cq_name
    if m then
        cq_name = m[1]
    end
    return cq_name
end

local find_cq_sql = function(cq_sql,cq_sql_online)
    local regex = [=[[\s+"']]=]
    local regex_measurement = [=[(FROM)[^.]+\.[^.]+\.([^.]+GROUP)]=]

    local newstr_1, n, err  = ngx.re.gsub(cq_sql,regex, "")
    local newstr_2, n, err  = ngx.re.gsub(cq_sql_online,regex, "")

    local newstr_1, n, err  = ngx.re.gsub(string.upper(newstr_1),regex_measurement, "$1$2")
    local newstr_2, n, err  = ngx.re.gsub(string.upper(newstr_2),regex_measurement, "$1$2")

    if newstr_1 == newstr_2  then
        return true
    else
        return false
    end
end

local insert_cq_sql = function(cq_sql)
    local host_url  =  "http://" .. init_config.influx_config["host"] .. ":" ..  init_config.influx_config["HTTP_port"] .. "/query"
    local database = init_config.influx_config["database"]

    if cq_sql then
        ngx.sleep(1)
        local post_data = "db=" .. database  .. "&q=" .. cq_sql
        local hc = http:new()
        local res, err = hc:request_uri(host_url, {
            method = "POST", -- POST or GET
            headers = {["Content-Type"] = "application/x-www-form-urlencoded" },
            body = post_data
        })
        if res.status ~= 200 then
            ngx.log(ngx.ERR, cq_sql ," was failed to insert ，" .. err .. res.body)
            return
        end
    end
    return
end


local  init_drop_cq = function(cq_name_online)
    local host_url  =  "http://" .. init_config.influx_config["host"] .. ":" ..  init_config.influx_config["HTTP_port"] .. "/query"
    local database = init_config.influx_config["database"]
    local qury_post_data =  "db=" .. database .. "&q=DROP+CONTINUOUS+QUERY+" .. cq_name_online  .. "+ON+" .. database
    local hc = http:new()
    local res, err = hc:request_uri(host_url, {
        method = "POST", -- POST or GET
        headers = {["Content-Type"] = "application/x-www-form-urlencoded" },
                body = qury_post_data
    })
    if res.status ~= 200 then
        ngx.log(ngx.ERR, "drop failed : " .. err)
    else 
        ngx.log(ngx.ERR, cq_name_online ," was removed successfully!!!")
    end
    return
end



local  diff_sql =  function(cq_name,cq_sql)
    local cjson = require "cjson"
    local host_url  =  "http://" .. init_config.influx_config["host"] .. ":" ..  init_config.influx_config["HTTP_port"] .. "/query"
    local database = init_config.influx_config["database"]

    local qury_post_data =  "db=" .. database .. "&q=show continuous queries"

    local hc = http:new()
    local res, err = hc:request_uri(host_url, {
        method = "POST", -- POST or GET
        headers = {["Content-Type"] = "application/x-www-form-urlencoded" },
		body = qury_post_data
    })
    if not res then
        ngx.log(ngx.ERR, "failed to request: " .. err)
        return
    end
    local results  =  cjson.decode(res.body)
    local check_db 
    local find_res
    for i, series  in ipairs(results["results"]) do
        for j, values in ipairs(series["series"]) do
            if values["name"] == database  then
          	check_db = true
		if values["values"] then
                    for v, one_value in ipairs(values["values"]) do
                        for c, cq_sql_online in ipairs(one_value) do
                            local cq_name_online = find_cq_name(cq_sql_online)
                            if cq_name_online ==  cq_name then
                                find_res = true
                                local find_res =  find_cq_sql(cq_sql,cq_sql_online)
                                if not find_res then
                                    ngx.log(ngx.ERR,cq_name_online,' has been changed, Re registration')
                                    init_drop_cq(cq_name_online)
                                    insert_cq_sql(cq_sql)
                                    return true
                                else
                                    return false
                                end
                            end
                        end
                    end
                    if not find_res then 
                        ngx.log(ngx.ERR, '正在创建Influxdb连续查询功能。。。')
                        insert_cq_sql(cq_sql)
                    end 

   	       else
                   ngx.log(ngx.ERR, '正在创建Influxdb连续查询功能。。。')
                   insert_cq_sql(cq_sql)				    
               end
            end
        end
    end
    if not check_db then
        ngx.log(ngx.ERR, 'not found influxdb databases! Please create it')
    end
end


function check_cron.check_mask()
    local continuous_query_list = influxdb_cron.continuous_query
    for i, cq_sql in pairs(continuous_query_list) do
          local cq_name = find_cq_name(cq_sql)
          if cq_name then
              diff_sql(cq_name,cq_sql)  
          else 
              ngx.log(ngx.ERR,"SQL is err : ",cq_sql)
          end
    end
    return 
end


return check_cron

