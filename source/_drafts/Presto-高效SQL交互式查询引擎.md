---
title: Presto-高效SQL交互式查询引擎
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
  - 交互式分析
  - SQL引擎
keywords: SQL实时交互式查询
description: Presto提供高效的交互式SQL查询服务
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-Cover.jpg
date: 2021-03-02 13:46:00
---
# Presto-高效SQL交互式查询引擎  
## Presto简介  
&emsp;&emsp;Presto是Facebook开源的分布式SQL查询引擎，适用于交互式分析查询的场景（OLAP），数据量支持GB到PB字节。类似的工具有**[Impala](https://shmily-qjj.top/1ae37d82/)**、**ClickHouse**等...
  
## Presto优缺点
优点：
* 架构清晰，可不依赖任何外部系统独立运行。
* Presto自身提供了对集群的监控。
* 基于纯内存计算，不需要写磁盘，效率高
* 自身更加轻量级资源调度，线程级别的Task，效率高
* 轮询查询结果并立刻返回结果，效率高
* 多种数据源支持，支持多个数据源不同表的联邦查询分析
* MPP架构的优势-扩展性，节点独立，无锁资源竞争，无IO冲突，无共享数据
* 简单的数据结构，列式存储，逻辑行，大部分数据都可以轻易的转化成Presto所需要的这种数据结构。
* 丰富的接口，可完美对接外部存储系统，以及添加自定义的函数。


缺点：
* 无容错能力，无重试机制
* 不支持数据类型隐式转换
* 与Hive相比存在不小的语法差异、函数和UDF差异以及运算结果差异(如1/2在Hive结果为0.5在Presto结果为0)
* Hive views are not supported.需要创建Presto视图
* 因为纯内存计算，不适合多个大表Join
* Coordinator单点问题（常见方案：ip漂移、Nginx代理动态获取等）

## Presto原理
<font size="3" color="red">推荐在学习Presto原理前先看看我之前关于Impala的文章：[《Impala-基于内存的高效SQL交互查询引擎》](https://shmily-qjj.top/1ae37d82/)</font>

### Presto架构和进程
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-01.png)
&emsp;&emsp;Presto与Impala的架构极其相似，都是采用Master-Slave模型以及MPP架构,而且Presto的工作进程也与ImpalaDaemon的角色基本相同，Presto有三种工作进程：Coordinator,Worker和DiscoveryServer：
* <font size="3" color="red">Coordinator</font>：即Master，负责管理Meta元数据，Worker节点，SQL的解析和调度，生成Stage和Task分发给Workers，负责合并结果集并返回给客户端。相当于结合了Impalad的Coordinator角色和Planner角色的功能，区别是每个Impalad节点都可以是Coordinator，而Presto只能有一个Coordinator，多个协调者进程会导致脑裂，查询任务会死锁。
* <font size="3" color="red">Worker</font>：负责计算和读写数据。相当于Impalad的Executor角色的功能。
* <font size="3" color="red">DiscoveryServer</font>：通常内嵌于Coordinator节点，也可以独立出来部署，功能类似ZK，类似Impala中的ImpalaStateStore，用于监控节点心跳，一般DS和Coordinator在同一节点。Worker启动会向DS进程注册，Coordinator可以从DS获取到所有正常提供服务的Worker。

### Presto数据模型
Presto使用Catalog、Schema和Table这3层结构来管理数据：
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-06.png)
* Catalog：每个数据源都有一个名字，一个Catalog可包含多个Schema。通过show catalogs命令查看Presto已连接的所有数据源
* Schema：相当于一个数据库实例，一个Schema(数据库)中有多个Table表，通过show schemas from hive命令查看hive数据源所有库
* Table：相当于一张表，通过show tables from catalog_name.schema_name来查看库下有哪些表。定位一张表：数据源的类别.数据库.数据表

Presto有两种存储单元：Page和Block
+ Page：多行数据的集合，包含多个列的数据，这里的多行数据是逻辑行，实际是以列式存储。
+ Block：一列数据，根据不同类型的数据，通常采取不同的编码方式。（Kudu也有类似的思想）
  * array类型的Block：应用于固定长度的类型如int、long、double，由两部分组成
    + boolean valueIsNull[]表示每一行是否有值。
    + T values[] 每一行的具体值。
  * 可变长度的Block：String类型，由三部分组成：
    + Slice：所有行数据拼接起来的字符串
    + int offsets[]：每行数据的起始偏移位置(每一行的长度等于下一行的起始偏移量减去当前行的起始偏移量)
    + boolean valueIsNull[]：是否空值，如果无值，偏移量与上一行相等
  * 固定长度的string类型的block：所有行的数据拼接成一长串Slice，每一行的长度固定
  * 字典类型的Block：可以嵌套任意类型的Block，由两部分组成：
    + 字典
    + int ids[] 数据的编号，查找时先找到id，再从字典中拿到真实值

### Presto插件
了解了Presto的数据模型后，就可以利用插件来对接自己的系统。Presto提供了一套Connector接口，支持从自定义存储中读取元数据，以及列式存储数据。
* ConnectorMetadata:管理表的元数据，表的元数据，partition等信息。在处理请求时，需要获取元信息，以便确认读取的数据的位置。Presto会传入filter条件，以便减少读取的数据的范围。元信息可以从磁盘上读取，也可以缓存在内存中。
* ConnectorSplit:一个IO Task处理的数据的集合，是调度的单元。一个split可以对应一个partition，或多个partition。
* SplitManager:根据表的meta，构造split。
* SlsPageSource:根据split的信息以及要读取的列信息，从磁盘上读取0个或多个page，供计算引擎计算。

基于Presto的插件我们可以开发这些功能：
* 对接自己的存储系统。
* 添加自定义数据类型。
* 添加自定义处理函数。
* 自定义权限控制。
* 自定义资源控制。
* 添加query事件处理逻辑。

目前Presto已经支持很多类型的Connector，具体可见官方文档：[Presto-Connectors](https://prestodb.io/docs/current/connector.html)

### Presto内存管理机制
&emsp;&emsp;Presto作为基于内存的计算引擎，对内存的分配很精细。Presto采用逻辑的内存池，来管理不同类型的内存需求。Presto把机器的内存划分成三个内存池，分别是System Pool,Reserved Pool,General Pool。
* System Pool：保留给系统使用的内存，默认是Xmx的40%
* General Pool：大部分Query使用这个内存池中的内存，因为大部分Query消耗内存并不高
* Reserved Pool：用于给消耗内存最大的一个Query使用，这个内存池默认占10%的总内存，也表示一个Query在一台机器上最大的内存使用量

&emsp;&emsp;为什么Presto会使用内存池机制？
首先，System Pool为了系统正常运行以及数据传输时系统缓存消耗；在资源不充足时，一个消耗内存较大的Query开始运行，因为没足够空间所以会挂起等待执行，等一些消耗内存小的Query执行完，又有新的Query请求，内存一直不充足，如果没有Reserved Pool，这个消耗内存大的Query就会一直被挂起直到失败。为了防止这种情况，预留出Reserved Pool内存池供大Query执行。Presto每秒钟挑出来一个内存占用最大的query，允许它在所有机器上都能使用Reserved pool，避免一直没有可用内存供大Query使用。

&emsp;&emsp;如果大Query不在某些节点使用Reserved Pool就会浪费那台节点的预留内存，所以为什么不是单台机器中挑出占用内存最大的Task来使用Reserved Pool？
这样设计会死锁，假设一个大Query的一个Task在某台机器可用Reserved Pool很快执行完，而另外一台机器的Task还是挂起状态，这个Query也会一直处于挂起状态，效率降低。

&emsp;&emsp;Presto内存管理分为两部分：Query内存管理和机器内存管理，是由Coordinator负责的
Query内存管理：Query会划分为多个Task，每个Task会有一个线程循环获取Task状态包括内存使用情况，Query内存管理就是汇总这些Task的内存使用情况。
机器内存管理：Coordinator有一个线程定时轮询每台机器的内存状态

### Presto执行计划
Presto与Spark、Hive一样，都是使用Antlr进行语法解析，一条SQL经过如下步骤最终生成在每个节点执行的LocalExecutionPlan逻辑计划。
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-02.png)

样例：
```sql
select c1.rank, count(*) from dim.city c1 join dim.city c2 on c1.id = c2.id where c1.id > 10 group by c1.rank limit 10;
```
生成的逻辑计划：
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-04.jpg)

物理执行计划：逻辑计划的每一个SubPlan都会提交到一个或者多个Worker节点上执行，一个SubPlan也可以理解为一个Stage，SubPlan有几个重要的属性planDistribution、outputPartitioning、partitionBy属性。
* planDistribution有三种类型
  + Source：数据源，会根据数据源大小确定分配多少个节点
  + Fixed：分配到固定个数的节点执行（Config配置中的query.initial-hash-partitions参数配置，默认是8）
  + None：这个SubPlan只分配到一个节点执行
* outputPartitioning有两种类型，表示这个SubPlan的输出是否按照**partitionBy属性**的key值对数据进行Shuffle。
  + Hash：发生Shuffle
  + None：不进行Shuffle

在下面的执行计划中，SubPlan1和SubPlan0 PlanDistribution=Source，这两个SubPlan都是提供数据源的节点，SubPlan1所有节点的读取数据都会发向SubPlan0的每一个节点；SubPlan2分配8个节点执行最终的聚合操作；SubPlan3只负责输出最后计算完成的数据。只有SubPlan0的OutputPartitioning=HASH（存在JoinNode计划），所以SubPlan2接收到的数据是按照rank字段Partition后的数据
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-05.png)

SQL提交并解析为SubPlan后的执行流程：
比如一条SQL最终生成4个SubPlan（0-3），其中0，1并行执行Join或聚合操作，其余串行执行，每个SubPlan都会分发到多个工作节点执行。
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Presto/Presto-03.png)
1. Coordinator通过HTTP协议调用Worker节点的/v1/task接口将执行计划分配给所有Worker节点（图中蓝色箭头）
2. SubPlan1的每个节点读取一个Split的数据并过滤后将数据分发给每个SubPlan0节点进行Join或聚合操作
3. SubPlan1的每个节点计算完成后按GroupBy Key的Hash值将数据分发到不同的SubPlan2节点
4. 所有SubPlan2节点计算完成后将数据分发到SubPlan3节点
5. SubPlan3节点计算完成后通知Coordinator结束查询，并将数据发送给Coordinator

总结一条SQL在Presto执行的完整流程：
1. 客户端通过HTTP协议发送一个查询语句给Presto集群的Coordinator
2. Coordinator接收到客户端传来的查询语句，对该语句进行解析、生成查询执行计划，并根据查询执行计划依次生成SqlQueryExecution -> SqlStageExecution -> HttpRemoteTask
3. Coordinator将每个Task分发到所需要处理的数据所在的Worker上进行分析
4. 执行Source Stage的Task，这些Task通过Connector从数据源中读取所需要的数据
5. 处于下游Stage中用的Task会读取上游Stage产生的输出结果，并在该Stage的每个Task所在的Worker内存中进行后续的计算和处理
6. Coordinator从分发的Task之后，一直持续不断的从最后的Stage中的Task获得计算结果，并将结果写入到缓存中，直到所所有的计算结束
7. Client从提交查询后，就一直监听Coordinator中的本次查询结果集，立即输出。直到所有的结果都返回，本次查询结束

## 部署与使用
### Presto集群部署
下载Presto
使用[GUID生成工具](https://www.toolbaba.cn/d/dev_guid)生成所需机器数量相等的GUID，用于配置node.properties
```shell
cd $PRESTO_HOME
mkdir etc
# node.properties配置节点信息(每个节点不同)
vim etc/node.properties
node.environment=cdh    一个Presto集群有相同的env名称，我这里起名叫cdh
node.id=AB1C6EAC-8CF6-B397-EFD3-77C8AB041CD5  刚刚生成的GUID，每个节点都要不同的GUID
node.data-dir=/var/presto/data   存放数据的目录
# JVM配置(每个节点相同)
vim etc/jvm.config
-server
-Xmx4G
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+UseGCOverheadLimit
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
# Presto配置 Coordinator节点 非生产集群单个节点即为Coordinator又为Worker可设node-scheduler.include-coordinator=true
vim etc/config.properties(每个节点不同)
coordinator=true  是否为Coordinator
node-scheduler.include-coordinator=false  是否在Coordinator节点执行计算（会影响性能，不建议true）
http-server.http.port=8080  请求发送的HTTP端口
query.max-memory=4GB  单条Query占用集群内存的最大值
query.max-memory-per-node=1GB  单条Query单个节点占用内存的最大值
query.max-total-memory-per-node=2GB  单条Quey单个节点占用的执行内存和系统内存(readers, writers, and network buffers, etc.)总和的最大值
discovery-server.enabled=true  整合Coordinator和DiscoveryServer为一个进程，使用同一个端口
discovery.uri=http://cdh101:8080
# Presto配置 Worker节点
vim etc/config.properties
coordinator=false
http-server.http.port=8080
query.max-memory=4GB
query.max-memory-per-node=1GB
query.max-total-memory-per-node=2GB
discovery.uri=http://cdh101:8080  指定集群中已有的DS服务HTTP地址
# 日志等级设置(每个节点相同)
vim etc/log.properties
com.facebook.presto=INFO
# 配置支持Hive数据源 (每个节点相同)(其他数据源可参考https://prestodb.io/docs/current/connector)
mkdir etc/catalog
vim etc/catalog/hive.properties
connector.name=hive-hadoop2
hive.metastore.uri=thrift://cdh101:9083
hive.config.resources=/etc/hadoop/conf/core-site.xml,/etc/hadoop/conf/hdfs-site.xml 
# ###############################################
ln -s /var/presto/data/var/log log  将日志链接到安装目录
在各个节点后台启动Presto：bin/launcher start
也可以在前台运行,查看具体的日志：bin/launcher run
停止服务进程命令：bin/laucher stop
启动脚本编写
  #!/bin/bash
  # 需要root用户免密
  # 使用 sh presto-server.sh start
  PRESTO_HOME=/opt/modules/presto-server-0.248
  OP=$1
  if [ "$OP" == "start" ] || [ "$OP" == "stop" ]; then
    echo "Begin to $OP Presto Coordinator and Workers."
    for((host=101; host<=104; host++)); do
            echo --- "$OP" presto server on cdh$host ---
            ssh -l root cdh$host $PRESTO_HOME/bin/launcher "$OP"
    done
  else
    echo "Usage: ./presto-server.sh [start|stop]"
    exit 1
  fi
# ###############################################
根据自己的版本下载presto客户端：https://repo1.maven.org/maven2/com/facebook/presto/presto-cli/0.248/presto-cli-0.248-executable.jar
chmod a+x presto-cli-0.248-executable.jar
mv presto-cli-0.248-executable.jar presto
ln -s /opt/modules/presto-server-0.248/presto /usr/bin/presto
进入Presto客户端(指定数据源hive，指定库名default) presto --server cdh101:8080 --catalog hive --schema default
# ###############################################
# 配置MySQL数据源
vim etc/catalog/mysql.properties
connector.name=mysql
connection-url=jdbc:mysql://cdh102:3306
connection-user=root
connection-password=123456
```

Presto语法：
```sql
SHOW SCHEMAS FROM hive;  查看hive数据源的所有库 （FROM可以用IN替换)
SHOW TABLES FROM hive.default;  查看hive数据源下default库下的所有表
CREATE SCHEMA hive.web WITH (location = 'hdfs:///user/hive/warehouse/web/')  # 建库
-- 建表
CREATE TABLE hive.web.page_views (
  view_time timestamp,
  user_id bigint,
  page_url varchar,
  ds date,
  country varchar
)
WITH (
  format = 'Parquet',
  partitioned_by = ARRAY['ds', 'country'],
  bucketed_by = ARRAY['user_id'],
  bucket_count = 50
);
-- 查看表
desc hive.web.page_views;
```




Presto的接入方式：presto-cli，pyhive，jdbc等



先解释下各参数的含义：


Presto 采用 Connector 对接第三方数据源，一个 Connector 便能提供一种新的 catalog



## 最佳实践
https://www.cnblogs.com/GO-NO-1/p/12143879.html     
如果一个Query超过30分钟就Kill掉吧，没准一直在GC，无法完成这个任务，还浪费了资源

## 总结
1. 当前基于Spark或Hive的交互查询任务迁移Presto需要很大的工作量
2. 

## 参考


字颜色大小
<font size="3" color="red">This is some text!</font>
<font size="2" color="blue">This is some text!</font>
<font face="verdana" color="green"  size="3">This is some text!</font>


## 参考资料  
[Presto官网](https://prestodb.io/)
[深入理解Presto](https://zhuanlan.zhihu.com/p/101366898)
[Presto实现原理和美团的使用实践](https://tech.meituan.com/2014/06/16/presto.html)

