---
title: ClickHouse实时OLAP引擎探索
author: 佳境
avatar: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/img/custom/avatar.jpg
authorLink: shmily-qjj.top
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true
tags:
  - OLAP
  - ClickHouse
keywords: ClickHouse
description: 高效率MPP架构分布式OLAP实时分析引擎
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/ClickHouse/ClickHouse-cover.jpeg
date: 2021-12-10 16:10:00
---

# ClickHouse实时OLAP引擎探索  
## ClickHouse简介
### 适用场景
适用场景：
1.读多写少
2.数据大批写入，每个批次>1000rows
3.列式读取，每次读取访问少量列
4.业务数据制作成大宽表，包含大量列
5.并发查询量较少的场景
6.单个查询运行时数据吞吐量高
7.避免大表关联
8.查询结果数据量明显小于源数据，数据被过滤或聚合后能够被盛放在单台服务器的内存中
9.丰富的表引擎支持多种数据分析场景
10.支持数据分片
11.向量化执行引擎

### ClickHouse的不足
1.并发查询能力一般，ClickHouseServer会耗费大量资源执行单条SQL
2.不要求事务性，事务能力差
3.支持但不擅长按行删除数据

### ClickHouse架构原理 


## ClickHouse使用
### SQL
```sql
-- CRUD
-- 建库
CREATE DATABASE [IF NOT EXISTS] db_name [ON CLUSTER cluster] [ENGINE = engine(...)]
-- 建表
CREATE TABLE [IF NOT EXISTS] [db.]table_name [ON CLUSTER cluster]
(
    name1 [type1] [DEFAULT|MATERIALIZED|ALIAS expr1] [compression_codec] [TTL expr1],
    name2 [type2] [DEFAULT|MATERIALIZED|ALIAS expr2] [compression_codec] [TTL expr2],
    ...
) ENGINE = engine
```

```sql
-- 对DateTime64类型求min,max
select toDateTime(min(toUInt64(time))),toDateTime(max(toUInt64(time))) from db.table;
-- 根据条件删除数据（异步）
alter table db.table delete where col=111;
-- 根据条件删除分布式表的本地表的数据（异步）（不推荐）
alter table db.table on cluster cluster_name delete where col=111;
-- 删除分布式表的分区 分区是两个字段组成 一级分区值为19087，二级分区值为0
ALTER TABLE db.table_local ON CLUSTER cluster_name DROP PARTITION (19087,0);
```


### 数据导入
1. Parquet文件导入

| Parquet data type (INSERT) | ClickHouse data type | Parquet data type (SELECT) |
|----|----|----|
| UINT8,BOOL | UInt8 | UINT8 |
| INT8 | Int8 | INT8 |
| UINT16 | UInt16 | UINT16 |
| INT16 | Int16 | INT16 |
| UINT32 | UInt32 | UINT32 |
| INT32 | Int32 | INT32 |
| UINT64 | UInt64 | UINT64 |
| INT64 | Int64 | INT64 |
| FLOAT,HALF_FLOAT | Float32 | FLOAT |
| DOUBLE | Float64 | DOUBLE |
| DATE32 | Date | UINT16 |
| DATE64,TIMESTAMP | DateTime | UINT32 |
| STRING,BINARY | String | STRING |
| DECIMAL | Decimal | DECIMAL |
| — | FixedString | STRING |
| DATE32, TIME32, FIXED_SIZE_BINARY, JSON, UUID, ENUM | 不支持 | 不支持 |
```shell
cat xxx.parquet | clickhouse-client --port 9009 --query="INSERT INTO default.table_name FORMAT Parquet"
clickhouse-client -h 192.168.1.102 --port 9009 --query="INSERT INTO default.table_name FORMAT Parquet" < xxx.parquet
```
若数据存在空值，需要建表时在数据类型上加Nullable()，也就是String -> Nullable(String)，否则会报如下错误
```error
Code: 349. DB::Exception: Cannot convert NULL value to non-Nullable type: while converting column `p_operate_time` from type Nullable(Int64) to type Int64: While executing ParquetBlockInputFormat: data for INSERT was parsed from stdin: (in query: INSERT INTO default.event_ros_p1_imported FORMAT Parquet). (CANNOT_INSERT_NULL_IN_ORDINARY_COLUMN)
```
导入Parquet文件时，单个文件越大，字段数越多，消耗峰值内存越多，速度越慢。建议Parquet文件大小不要过大，字段不要过多，否则可能会报如下错误：
```error
Received exception from server (version 21.12.3):
Code: 241. DB::Exception: Received from ch_server:9030. DB::Exception: Memory limit (for query) exceeded: would use 46.57 GiB (attempt to allocate chunk of 9437184 bytes), maximum: 46.57 GiB. (MEMORY_LIMIT_EXCEEDED)
(query: INSERT INTO default.event_ros_p1 FORMAT Parquet)
```
解决办法是缩小单个Parquet文件的大小，或者尽量减少列数，若列数和文件大小不可控，可以增加如下参数，提高ClickHouse客户端使用的瞬时峰值内存，使得文件可以成功导入(此处设置为90G但实际导入时客户端仅仅使用到几个G左右的内存，若90G不够可以继续加到110G，不会对机器产生影响)。导入文件的过程是事务的，如果该Parquet文件导入过程中失败，则数据不会导入进去。
```shell
clickhouse-client --port 9030 --input_format_allow_errors_num 5 --max_memory_usage=90000000000 --query="INSERT INTO default.table_name FORMAT Parquet" < xxx.parquet
```
导入Parquet文件时报如下错误，可能需要检查parquet文件是否已损坏，通过md5sum进行校验是否损坏。
```error
Code: 36. DB::Exception: Invalid: Parquet magic bytes not found in footer. Either the file is corrupted or this is not a parquet file.: While executing ParquetBlockInputFormat: data for INSERT was parsed from stdin: (in query: INSERT INTO default.event_ros_p3 FORMAT Parquet). (BAD_ARGUMENTS)
```
表已有数据量较大时，再导入Parquet文件可能会有如下报错：
```error
Code: 32. DB::Exception: Attempt to read after eof: while receiving packet from xxx.xx.xxx.xx:9010: (in query: INSERT INTO db_name.table_name FORMAT Parquet). (ATTEMPT_TO_READ_AFTER_EOF)
# 再次执行会报：
Code: 210. DB::NetException: Connection refused (xxx.xx.xxx.xx:9010). (NETWORK_ERROR)
```
解决:降低写入的并行度，若允许数据不按顺序导入，可以加--max_insert_threads=32参数（ClickHouse默认是单线程导入文件，默认值为0）
```shell
clickhouse-client -h xxx.xx.xxx.xx --port 9010 --input_format_allow_errors_num 5 --max_memory_usage=90000000000 --max_insert_threads=32 --query="INSERT INTO db_name.table_name  FORMAT Parquet" < /data3/xxx-xxx.parquet
```
如果ClickHouse表的Schema发生变化，导致与Parquet文件中的Schema不一致就会发生报错，无法导入
```error
Code: 8. DB::Exception: Column 'p_test1' is not presented in input data.: While executing ParquetBlockInputFormat: data for INSERT was parsed from stdin: (in query: INSERT INTO db.table FORMAT Parquet). (THERE_IS_NO_COLUMN)
```
解决：INSERT INTO db.table(col1,col2,...,colN) FORMAT Parquet 指定Parquet已有的字段插入即可

注意：Parquet中的时间字段精确到毫秒，但导入ClickHouse的DateTime64(3)类型字段时毫秒的精度会丢失，全部变为000。且因时区问题，Parquet时间数据导入ClickHouse的DateTime64(3)类型后，时间默认会+8小时。

2. Hive、Impala数据导入 
Hive数据可以通过[SeaTunnel](https://interestinglab.github.io/seatunnel-docs/#/zh-cn/v2/) 程序导入。编写配置文件即可抽取到ClickHouse。
Impala数据导入可以先创建一张Impala的Parquet格式临时表，创建前设置set PARQUET_FILE_SIZE=128m;参数，避免Parquet文件过大，再将parquet文件load到本地并导入ClickHouse。

3. Kudu数据导入
可以使用SeaTunnel开源工具将Kudu数据导入ClickHouse，可以参考我的另一篇博客：[SeaTunnel开源数据同步平台](https://shmily-qjj.top/84534d72/)


### 数据导出
1. 导出数据到Parquet文件
```shell
clickhouse-client --query="SELECT * FROM tsv_demo FORMAT Parquet" > parquet_demo.parquet
```

### 表引擎
ClickHouse支持多种使用场景，拥有多种表引擎以适应不同的使用场景，表引擎的作用：
1.决定表存储在哪里以及以何种方式存储
2.支持哪些查询以及如何支持
3.并发数据访问
4.索引的使用
5.是否可以执行多线程请求
6.数据复制相关能力

* HDFS表引擎
直接使用ClickHouse作为HDFS的客户端管理HDFS上的数据。
Parquet(HDFS)与ClickHouse数据类型对应关系:

| Parquet(Insert) | ClickHouse | Parquet(SELECT) |
| ---- | ---- | ---- |
| UINT8,BOOL | UInt8 | UINT8 |
| INT8 | Int8 | INT8 |
| UINT16 | UInt16 | UINT16 |
| INT16 | Int16 | INT16 |
| UINT32 | UInt32 | UINT32 |
| INT32 | Int32 | INT32 |
| UINT64 | UInt64 | UINT64 |
| INT64 | Int64 | INT64 |
| FLOAT,HALF_FLOAT | Float32 | FLOAT |
| DOUBLE | Float64 | DOUBLE |
| DATE32 | Date | UINT16 |
| DATE64,TIMESTAMP | DateTime | UINT32 |
| STRING,BINARY | String | STRING |
| — | FixedString | STRING |
| DECIMAL | Decimal | DECIMAL |
使用HDFS表引擎读取一个Parquet文件
```sql
-- 读取HDFS上的单个Parquet文件作为一张表  
create table hdfs_table (name String,age int) engine = HDFS('hdfs://192.168.1.102:8020/user/hive/warehouse/test_parquet/000000_0','Parquet');
select * from hdfs_table;
```
使用HDFS表引擎读取Hive分区表
```sql
-- 读取HDFS上的正则匹配到的文件作为一张表  
create table hdfs_partitioned_table (id int,name String) engine = HDFS('hdfs://192.168.1.102:8020/user/hive/warehouse/parquet_partitioned_table1/dt=2016*/*','Parquet');
select * from hdfs_partitioned_table limit 1000;
```
Kerberos认证问题及配置：
如果HDFS端是要求Kerberos认证的，需要配置如下参数，查询该HDFS引擎表会报如下错误
```error
Code: 210. DB::Exception: Received from ch_host:9900. DB::Exception: Unable to connect to HDFS: SIMPLE authentication is not enabled.  Available:[TOKEN, KERBEROS]. (NETWORK_ERROR)
```
所以在配置里指定HDFS的Principal和Keytab来认证Kerberos，认证的用户需要具有HDFS读权限
```config
<hdfs>
  <hadoop_kerberos_keytab>/hadoop/bigdata/kerberos/ch.keytab</hadoop_kerberos_keytab>
  <hadoop_kerberos_principal>hive@HIVETEST.COM</hadoop_kerberos_principal>
  <hadoop_security_authentication>kerberos</hadoop_security_authentication>
</hdfs>
```
重启Server再次重试，如果报如下错误
```error
Received exception from server (version 21.12.2):
Code: 36. DB::Exception: Received from ch_host:9900. DB::Exception: kinit failure: kinit -R -t "/hadoop/bigdata/kerberos/ch.keytab" -k hive@HIVETEST.COM|| kinit -t "/hadoop/bigdata/kerberos/ch.keytab" -k hive@HIVETEST.COM. (BAD_ARGUMENTS)
```
此时要注意认证程序是用clickhouse-server进程启动的用户去执行的，默认是clickhouse用户，该用户没有/hadoop/bigdata/kerberos/ch.keytab的访问权限所以报这个错误。解决
```shell
chown clickhouse:clickhouse /hadoop/bigdata/kerberos/ch.keytab
chmod 660 /hadoop/bigdata/kerberos/ch.keytab
```

* Memory引擎
Memory引擎,数据存储在内存中，Server重启后数据会丢失
```sql
create table test(
    id Int32,
    name String
) engine=Memory;
```

## ClickHouse安装部署
### 单机ClickHouse安装
```shell
# 检查是否支持SSE4.2指令集 否则无法使用CH
grep -q sse4_2 /proc/cpuinfo && echo "SSE 4.2 supported" || echo "SSE 4.2 not supported" 
# 安装
sudo yum install yum-utils
sudo rpm --import https://repo.clickhouse.com/CLICKHOUSE-KEY.GPG
sudo yum-config-manager --add-repo https://repo.clickhouse.com/rpm/stable/x86_64
sudo yum install clickhouse-server clickhouse-client
# 修改配置文件 
sudo cp /etc/clickhouse-server/config.xml /etc/clickhouse-server/config_bak.xml 
# sudo vi /etc/clickhouse-server/config.xml 开放远程访问权限(默认关闭)
<listen_host>::</listen_host>
<!-- <listen_host>::1</listen_host> -->
<!-- <listen_host>127.0.0.1</listen_host> -->
# 防止端口冲突
<tcp_port>9000</tcp_port>改为<tcp_port>9009</tcp_port>
<interserver_http_port>9000</interserver_http_port>改为<interserver_http_port>9008</interserver_http_port>
# sudo vi /etc/metrika.xml 远程访问权限
<yandex>
<networks>
<ip>::/0</ip>
</networks>
</yandex>
# sudo vim /etc/clickhouse-server/users.xml 找到networks节点，确保该节点下的ip节点值为::/0
# 启动 默认使用/etc/clickhouse-server/config.xml配置文件在后台启动
systemctl start clickhouse-server
systemctl status clickhouse-server
# 客户端连接
clickhouse-client -h cdh101 --port 9009 -u default --password '' -m -n
# JDBC连接 jdbc:clickhouse://cdh101:8123/default
# 设置default用户密码
echo -n "admin" | openssl dgst -sha256得到明文admin的sha256密文
sudo vim /etc/clickhouse-server/users.xml 找到user节点->default(用户名)节点
<!-- <password></password> -->
<password_sha256_hex>8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918</password_sha256_hex>
# 使用密码登陆
clickhouse-client -h cdh101 --port 9009 -u default --password admin -m -n
```

### 分布式ClickHouse安装
```shell
# 检查是否支持SSE4.2指令集 否则无法使用CH
grep -q sse4_2 /proc/cpuinfo && echo "SSE 4.2 supported" || echo "SSE 4.2 not supported" 
# 安装
sudo yum install yum-utils
sudo rpm --import https://repo.clickhouse.com/CLICKHOUSE-KEY.GPG
sudo yum-config-manager --add-repo https://repo.clickhouse.com/rpm/stable/x86_64
sudo yum install clickhouse-server clickhouse-client
# 修改配置文件 
sudo cp /etc/clickhouse-server/config.xml /etc/clickhouse-server/config_bak.xml 
<listen_host>::</listen_host>去掉注释
<tcp_port>9000</tcp_port>改为<tcp_port>9009</tcp_port>
<interserver_http_port>9000</interserver_http_port>改为<interserver_http_port>9008</interserver_http_port>
<remote_servers></remote_servers>标签及内容整段都注释掉并增加如下内容
    <remote_servers incl="clickhouse_remote_servers"/>
    <zookeeper incl="zookeeper-servers" optional="true"/>
    <macros incl="macros" optional="true"/>
    <include_from>/etc/clickhouse-server/metrika.xml</include_from>
-----------------------------------------------------------------------------------------
# sudo vim /etc/clickhouse-server/users.xml 找到networks节点，确保该节点下的ip节点值为::/0
# 设置default用户密码
echo -n "admin" | openssl dgst -sha256得到明文admin的sha256密文
sudo vim /etc/clickhouse-server/users.xml 找到user节点->default(用户名)节点
<!-- <password></password> -->
<password_sha256_hex>8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918</password_sha256_hex>
```
三节点配置示例---三分片一副本 
sudo vim /etc/clickhouse-server/metrika.xml
```xml
<?xml version="1.0"?>
<yandex>
 <clickhouse_remote_servers>
  <cluster_3shards_1replicas>
   <shard>
    <!-- 数据自动同步 -->
    <internal_replication>true</internal_replication>
    <replica>
     <host>cdh102</host>
     <port>9009</port>
     <user>default</user>
     <password>admin</password>
    </replica>
   </shard>
   <shard>
    <internal_replication>true</internal_replication>
    <replica>
     <host>cdh103</host>
     <port>9009</port>
     <user>default</user>
     <password>admin</password>
    </replica>
   </shard>
   <shard>
    <internal_replication>true</internal_replication>
    <replica>
     <host>cdh104</host>
     <port>9009</port>
     <user>default</user>
     <password>admin</password>
    </replica>
   </shard>
  </cluster_3shards_1replicas>
 </clickhouse_remote_servers>
 <!--zookeeper相关配置-->
 <zookeeper-servers>
  <node index="1">
   <host>cdh101</host>
   <port>2181</port>
  </node>
  <node index="2">
   <host>cdh102</host>
   <port>2181</port>
  </node>
  <node index="3">
   <host>cdh103</host>
   <port>2181</port>
  </node>
 </zookeeper-servers>
 <macros>
  <shard>1</shard>  <!-- 当前节点分片号，其他节点需要修改 -->
  <replica>cdh102</replica>  <!-- 当前节点域名IP，其他节点需要修改 -->
 </macros>
 <networks>
  <ip>::/0</ip>
 </networks>
 <clickhouse_compression>
  <case>
   <min_part_size>10000000000</min_part_size>
   <min_part_size_ratio>0.01</min_part_size_ratio>
   <method>lz4</method>
  </case>
 </clickhouse_compression>
</yandex>
```
分别登陆各节点验证
```shell
clickhouse-client -h cdh102 --port 9009 -u default --password admin -m -n
clickhouse-client -h cdh103 --port 9009 -u default --password admin -m -n
clickhouse-client -h cdh104 --port 9009 -u default --password admin -m -n
select cluster,shard_num,replica_num,host_name,host_address,port,is_local,user from system.clusters;
┌─cluster───────────────────┬─shard_num─┬─replica_num─┬─host_name─┬─host_address──┬─port─┬─is_local─┬─user────┐
│ cluster_3shards_1replicas │         1 │           1 │ cdh102    │ 192.168.1.102 │ 9009 │        1 │ default │
│ cluster_3shards_1replicas │         2 │           1 │ cdh103    │ 192.168.1.103 │ 9009 │        0 │ default │
│ cluster_3shards_1replicas │         3 │           1 │ cdh104    │ 192.168.1.104 │ 9009 │        0 │ default │
└───────────────────────────┴───────────┴─────────────┴───────────┴───────────────┴──────┴──────────┴─────────┘
```

测试分布式表引擎
```sql
-- 分布式引擎本身不存储数据, 但可以在多个服务器上进行分布式查询。
-- https://clickhouse.com/docs/zh/engines/table-engines/special/distributed/
--新建分布式表
CREATE TABLE IF NOT EXISTS distribute_table ON CLUSTER cluster_3shards_1replicas
(
  id Int32,
  name String
)
ENGINE = Distributed(cluster_3shards_1replicas,default,local_table,id); 
参数含义
Distributed（集群名称，库名，本地表名，分片键） 
-- 分片键用于分片的key值，在数据写入的过程中，分布式表会根据分片key的规则，将数据分布到各个节点的本地表。必须是整型数字，可以用hiveHash函数转换，也可以用rand()。
--各节点新建本地表
CREATE TABLE IF NOT EXISTS local_table
(
  id Int32, 
  name String
)ENGINE = MergeTree() 
PARTITION BY id 
PRIMARY KEY id
ORDER BY id;
--插数据
INSERT INTO distribute_table VALUES(1,'test1'),(2,'test2'),(3,'test3'),(4,'test4'),(5,'test5'),(6,'test6');
-- 各个节点执行可查看数据分布
select * from local_table; 
-- 查询全部数据
select * from distribute_table; 
-- 删除分布式表
drop table shard01_db.local_table on cluster cluster_name;   -- 删除副本01的表
drop table shard02_db.local_table on cluster cluster_name;   -- 删除副本02的表
drop table default.distribute_table on cluster cluster_name; -- 删除分布式表
-- 清空分布式表数据
truncate table shard01_db.local_table on cluster cluster_name; -- 清空副本01的表的数据
truncate table shard02_db.local_table on cluster cluster_name; -- 清空副本02的表的数据
```
使用JDBC连接ClickHouse代码[**ClickHouseJDBC**](https://github.com/Shmilyqjj/Shmily/blob/master/ClickHouse/src/main/java/ClickHouseJDBC.groovy)

**副本**的目的在于保障数据的高可用性，即使一台CH节点宕机，也可以从其他服务器获得相同的数据。副本可以提高数据的可用性，降低丢失风险，但每台服务器必须容纳全部数据，数据的横向扩容没有解决。
**分片**用来解决数据水平切分的问题，通过分片把一份完整的数据进行切分，不同的分片分布到不同的节点上，然后通过Distributed表引擎把数据拼接起来一起使用。同一分片内的数据可以有多个副本。
CH分布式是表级别的分布式，实际使用中，大部分表做了高可用，但没有使用分片，避免降低查询性能以及操作集群的复杂性。

## ClickHouse最佳实践与优化
### 配置优化
```json

```

## ClickHouse集群运维
### SQL
```sql
查看存储磁盘配置：
SELECT
name,path,formatReadableSize(free_space) AS free,
formatReadableSize(total_space) AS total,
formatReadableSize(keep_free_space) AS reserved
FROM system.disks;
查看压缩率：
select
    sum(rows) as "总行数",
    formatReadableSize(sum(data_uncompressed_bytes)) as "原始大小",
    formatReadableSize(sum(data_compressed_bytes)) as "压缩大小",
    round(sum(data_compressed_bytes) / sum(data_uncompressed_bytes) * 100, 0) "压缩率"
from system.parts;
表存储情况查询：
SELECT table,disk_name,path
 FROM system.parts
 where database = 'default' and table = 'table_name';
SELECT sum(rows) / 2,formatReadableSize(sum(bytes_on_disk)) AS size
 FROM system.parts
 where database = 'default' and table = 'table_name';
```

### Config
查看本机压缩算法：
metrika.xml 文件的<method></method>  标签， 默认lz4；



## ClickHouse异常处理
1. 删分布式表后立刻重建表(表名相同字段不同)报错
```error
There was an error on [xxx.xx.xxx.xx:9030]: Code: 122. DB::Exception: Table columns structure in ZooKeeper is different from local table structure.
```
原因：ClickHouse删表操作后，ZK中的信息会立刻更新，但Clickhouse还有缓存，导致建表失败
解决：隔一段时间再创建表

2. 建表语句有重名字段
```error
There was an error on [xxx.xx.xxx.xx:9030]: Code: 44. DB::Exception: Cannot add column p__lib: column with this name already exists. (ILLEGAL_COLUMN) 
```
解决：排查重名字段，去掉即可

 


## 参考
[ClickHouse中文文档](https://clickhouse.com/docs/zh/)
[clickhouse输入输出格式之Parquet](https://blog.csdn.net/lyq7269/article/details/114982515)
[ClickHouse快速入门](https://zhuanlan.zhihu.com/p/240767797)
