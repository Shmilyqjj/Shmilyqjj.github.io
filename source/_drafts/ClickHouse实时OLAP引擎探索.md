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
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Phoenix/ClickHouse-cover.jpg
date: 2021-12-10 16:10:00
---

# ClickHouse实时OLAP引擎探索  
## ClickHouse简介

### 适用场景与优势

### ClickHouse的不足

### ClickHouse架构原理 

## ClickHouse使用
### 表引擎
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
```
使用JDBC连接ClickHouse代码[**ClickHouseJDBC**](https://github.com/Shmilyqjj/Shmily/blob/master/ClickHouse/src/main/java/ClickHouseJDBC.groovy)

**副本**的目的在于保障数据的高可用性，即使一台CH节点宕机，也可以从其他服务器获得相同的数据。副本可以提高数据的可用性，降低丢失风险，但每台服务器必须容纳全部数据，数据的横向扩容没有解决。
**分片**用来解决数据水平切分的问题，通过分片把一份完整的数据进行切分，不同的分片分布到不同的节点上，然后通过Distributed表引擎把数据拼接起来一起使用。同一分片内的数据可以有多个副本。
CH分布式是表级别的分布式，实际使用中，大部分表做了高可用，但没有使用分片，避免降低查询性能以及操作集群的复杂性。


## ClickHouse最佳实践与优化








## 参考
[ClickHouse中文文档](https://clickhouse.com/docs/zh/)
