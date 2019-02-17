local _M = {}
--下面的配置文件是用来添加连续查询，连续查询的语句建议使用 [[  ]]  来加入，请看下面的实例就明白了，
--里面包含的双引号主要是influxdb的配置格式，请熟悉influxdb使用方式

local init_config = require "log_collection.config.config"
local database = init_config.influx_config["database"]
local influxdb_table = init_config.influxdb_table


_M.continuous_query = {
    string.format([[CREATE CONTINUOUS QUERY "tp99" ON %s BEGIN  SELECT PERCENTILE(upstream_time,99) as tptime  INTO %s."cq_data_expires".tp99_nginx FROM %s group by  time(1m),url  END]],database,database,influxdb_table),
    string.format([[CREATE CONTINUOUS QUERY "tp90" ON %s BEGIN  SELECT PERCENTILE(upstream_time,90) as tptime  INTO %s."cq_data_expires".tp90_nginx FROM %s group by  time(1m),url  END]],database,database,influxdb_table),
    string.format([[CREATE CONTINUOUS QUERY "tp85" ON %s BEGIN  SELECT PERCENTILE(upstream_time,85) as tptime  INTO %s."cq_data_expires".tp85_nginx FROM %s group by  time(1m),url  END]],database,database,influxdb_table),
    string.format([[CREATE CONTINUOUS QUERY "ave" ON %s BEGIN  select mean(upstream_time) as ave_mean INTO %s."cq_data_expires".ave_nginx FROM %s group by  time(2m),url END]],database,database,influxdb_table),
    string.format([[CREATE CONTINUOUS QUERY "pv" ON %s BEGIN  select count(uri) as pv_count INTO %s."cq_data_expires".pv_nginx FROM %s group by  time(1m),url END]],database,database,influxdb_table),
    string.format([[CREATE CONTINUOUS QUERY "uri_status_group" ON %s BEGIN  select count(uri) as status_count INTO %s."cq_data_expires".usg_nginx FROM %s  group by  time(1m),url,status  END]],database,database,influxdb_table),
}


return  _M
