local _M = {}

--如果有多台Nginx需要存储日志，请将其中一台Nginx的机器hostname配置到此处，它是用来检查和更新influxdb的定时任务的，只需要一台即可
--如果只有一台，请配置这一台的hostname
--必填项
_M.hostname_crond = ""

_M.influx_config = {
    --Influxdb的IP地址
    host = "",
    -- Influxdb的数据库
    database = "",
    -- Influxdb的udp端口
    port = 8089, 
    --数据传输模式是udp
    sock_type = "udp",
   --influxdb的HTTP API端口，默认是8086，如果你修改了Influxdb中[http]的配置的HTTP启动端口，请也修改这里
    HTTP_port = 8086, 
    
    --------------------------------------------------------------------------------------
    --下面的参数是lua-resty-logger-socket模块中的优化参数，大家可以自行添加或者使用默认
    flush_limit = 4096,  --2k 
    drop_limit = 3145728, -- 3MB
    periodic_flush = 1,
    -------------------------------------------------------------------------------------
}

_M.mysql_config = {
    -- active 等于true，表示URI的规则存放在MySQl,日志分析时会优先使用MySQL中存在的规则，
    -- active 等于false，表示禁用MySQL配置，此时监控平台的分析URI将会是当前的精确URI，
    -- 如果你有URI需要合并成一个正则表达式的（比如 www.test.com/[0-9a-z]+.html），强烈建议你使用MySQL，
    -- 这样可以提升计算的准确性，利于数据分析和汇总
    -- 如果后期你需要使用更多此系统的功能，也强烈建议你使用MySQL存储URI的信息，
    host = "",
    port = ,
    database = "",
    user = "",
    password = "",
    active = true,
    charset = "utf8",
    max_packet_size = 2048 * 2048
}

-- Influxdb中表的索引字段，适合数据变化不频繁的字段，比如状态码等，暂时不建议修改，如果对Influxdb比较熟悉的用户可以适当添加
-- Nginx的日志中会将下列变量存放到Influxdb的索引字段中
_M.tags = {
    "status",
    --当没有使用Mysql存储URI规则的情况下，下面的url等于下面_M.fields 中的uri 
    "url",
    "host",
    "upstream_name",
}

-- Influxdb中表的数据字段，可以支持自定义变量和Nginx所有可以获取的变量，具体操作请查看wiki
-- Nginx的日志中会将下列变量存放到Influxdb的字段数据中（没有索引属性）
_M.fields = {
    "server_ip_port",
    "find_lru_res",
    "upstream_time",
    "upstream_status",
    "upstream_addr",
    "http_user_agent",
    "uri",
    "args",
    "http_referer",
    "remote_addr",
    "request_length",
    "scheme",
    "request_method",
    "time_local",
    "request_time",
}


-- 是否对传输到Influxdb的Nginx变量进行URI编码，如果你的这个变量中包含双引号，空格，逗号 中的任意一种，请使用URI编译，避免写入influxdb失败
-- nginx变量请使用小写, 目前此工具支持URI编码的变量有 uri,host,http_referer,http_user_agent,args
-- 可以先使用下面的默认值，如果传输中Influxdb有报错，在添加新的，比较一般情况下uri,host，args不太容易包含上述特殊字符
_M.escape_list = {"http_referer","http_user_agent"} 

-- Ngx_Lua临时存放数据的路径，注意目录写入的权限,当mysql_config中active = true ，此配置才有意义
_M.dump_list = "/tmp/dump_url_list"

-- Ngx_Lua缓存存放key的最大数量，根据MySQL存放的URL的数量进行设置，建议大于MySQL中URI的数量50%，避免日后添加缓存key时，缓存空间不够，当mysql_config中active = true ，此配置才有意义
_M.max_cache_key = 10000

-- Ngx_Lua缓存key的有效期,单位秒,当mysql_config中active = true ，此配置才有意义
_M.cache_ttl = 1200

--缓存数据更新的时间，update_cache_time必须小于cache_ttl,当mysql_config中active = true ，此配置才有意义
_M.update_cache_time = 120

--Influxdb的表名，Nginx的日志就存放在这个表中
_M.influxdb_table = "nginx"      

--设置为true ，表示会使用本工具默认已经创建的Influxdb连续查询的指令，如果你想自定义，而不使用默认的连续查询，请设置为false,当设置为false后，用户可以在自己去创建连续查询功能
--自定义连续查询也可以由此工具管理，请查看本目录下的influxdb_cron.lua文件，它支持自定义的添加和删除
_M.influxdb_cq_init = true 

return _M
