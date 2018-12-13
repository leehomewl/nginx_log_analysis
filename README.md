# nginx_log_analysis
    nginx_log_analysis是一个Nginx日志实时分析系统，目前已经在折800旗下的全部Nginx代理上运行，每天负责数十亿日志的实时分析。

介绍  
    nginx_log_analysis是基于Ngx_Lua模块开发，由网络传输到InfluxDB数据库，可以部署在Nginx和OpenResty上，它有如下的功能：  
1 支持Nginx集群日志集中存储  
2 支持正则表达式的URI日志分析  
3 支持upstream_time合并，可以正确统计到每条请求在后端的总时长  
4 支持URI的 PV统计  
5 支持URI平均响应时间计算，  
6 支持URI P99,P90,P85的数据报表  
7 数据存放InfluxDB，InfluxDB提供强大的函数查询，可以支持URI各种数据的汇总和自定义分析 

安装方式：
  详见wiki：https://github.com/leehomewl/nginx_log_analysis/wiki
 
特性说明：
  URI的管理特别引人了MySQL，作用如下：
  很多业务的URI是包括了正则表达式的，比如 a.com/123.html ,a.com/234.html 等，
  它们在计算中属于同一个类型，都应该是属于a.com/[0-9]+\.html,正则URI的数据如果不能归类在一起计算，
  将会失去计算的意义，并且会影响整体数据的汇总的报表，我们用MySQL存放每个URI的属性，
  数据存储中提供了精确匹配URI计算，正则匹配，目录匹配，
  MySQL存放的数据结构如下：
  Mysql的表nginx_var_information存放的是URI有关的属性
  uri_type是存放URI是精确匹配（precise）还是正则匹配（regex），或者是目录匹配（wildcard）
  host是请求的host，即域名
  uri是请求在进行分析和统计时使用的uri  
  ![image](https://github.com/leehomewl/nginx_log_analysis/blob/master/img/mysql-table.png)
  
  InfluxDB数据存放如下,我只查询了部分日志的变量，更多变量使用者可以在InfluxDB中查询：  
  InfluxDB中特殊字段说明（其他的字段都是Nginx的变量名，很容易区分）：
  InfluxDB字段url， 它是 host+uri组合的，如果你在config.lua中激活了MySQL，则用户的请求uri符合MySQL中的规则就会被Mysql中的格式替代，从而进行统计和分析，
  但如果在MySQl中找不到此URI，就会使用null来表示。因为如果遇到攻击，采用的是随机uri，会导致Influxdb的索引性能问题，并且只通过Mysql的数据来认领，
  我们在测试环境做uri的审核功能，如果某个uri不在mysql中出现过，我们就认为这是个新的uri，需要审核后上线，审核中就可以完成各项监控配置，
  比如响应时间监控，请求字节大小控制，cookie控制等提升uri的管理能力。
  InfluxDB字段uri， 它是用户原生的uri，
  
  ![image](https://github.com/leehomewl/nginx_log_analysis/blob/master/img/Influxdb-table.png)
  
