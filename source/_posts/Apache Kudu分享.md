---
title: Apache Kudu分享
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
  - 大数据
  - Kudu
  - 实时
keywords: 
  - Kudu 
description: Fast Analytics on Fast Data.
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-cover.png
abbrlink: 5f26355
date: 2020-07-05 12:26:08
---
# Apache Kudu  

## 前言
&emsp;&emsp;在Kudu出现前，由于传统存储系统的局限性，对于数据的快速输入和分析还没有一个完美的解决方案，要么以缓慢的数据输入为代价实现快速分析，要么以缓慢的分析为代价实现数据快速输入。随着快速输入和分析场景越来越多，传统存储层的局限性越来越明显，Kudu应运而生，它的定位介于HDFS和HBase之间，将低延迟随机访问，逐行插入、更新和快速分析扫描融合到一个存储层中，是一个**既支持随机读写又支持OLAP分析的存储引擎**。本篇文章研究一下Kudu，对其应用场景，架构原理及基本使用做一个总结。
## Kudu介绍  
  <font size="3" color="red">**在Kudu出现前，无法对实时变化的数据做快速分析：**</font>
  
  ![alt Kudu-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-01.png)   
  以上设计方案的缺陷：
  1.数据存储多份造成冗余，存储资源浪费。
  2.架构复杂，运维成本高，排查问题困难。
  而Kudu就融合了动态数据与静态数据的处理，同时支持随机读写和OLAP分析。
 
  <font size="3" color="red">**Kudu与HDFS,HBase的对比：**</font>
  ![alt Kudu-02](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-02.JPG)  

### 适用场景  
* 既有随机读写随机访问，又有批量扫描分析的场景
* 要求数据实时性高（如实时决策，实时更新）的场景
* 数据逐行插入、更新且支持事物ACID特性
* 同时高效运行顺序读写和随机读写任务的场景
* 支持分布式高性能，高可用，可横向扩展的场景
* Kudu作为持久层与Impala紧密集成的场景
* 解决HBase(Phoenix)大批量数据SQL分析性能不佳的场景
* 跨大量历史数据的查询分析场景（Time-series场景）

### 特点及缺点  
1. **特点**
  * 基于列式存储
  * 快速顺序读写
  * 使用 [LSM树](https://shmily-qjj.top/5f26355/#LSM树) 以支持高效随机读写
  * 查询性能和耗时较稳定
  * 不依赖Zookeeper
  * 有表结构，需要定义Schema，需要定义唯一键，支持SQL分析（依赖Impala，Spark等引擎）
  * 支持增删列,单行级ACID（不支持多行事务-不满足原子性）
  * 查询时先查询内存再查询磁盘
  * 数据存储在Linux文件系统，不依赖HDFS存储
2. **缺点**  
  * 暂不支持除PK外的二级索引和唯一性限制
  * 只支持单行事务，暂不支持事务回滚，未来可能支持
  * 不支持BloomFilter优化join 
  * 不支持数据回滚
  * 不能通过Alter来drop PK
  * 每表最多不能有300列
  * 数据类型少，不支持Map，Struct等复杂类型

### 与相似类型存储引擎对比
&emsp;&emsp;本文重点说Kudu，但我们也需要了解其他类似组件，了解它们各自擅长的地方，才能更好地做技术选型。这里简单对比一下Kudu，Hudi和DeltaLake这三种存储方案，因为它们都具有相似的特性，能解决类似的问题。  

| 特性 | Kudu | Hudi | Delta Lake |
| :----: | :----: | :----: | :----: |
| 行级别更新 | 支持 | 支持 | 支持 |
| schema修改 | 支持 |  支持 |  支持 |
| 批流共享 | 支持 | 支持 | 支持 |
| 可用索引 | 是  |  是 |  否  |
| 多并发写 | 支持  | 不支持 | 支持 |
| 版本回滚 | 不支持 |  支持 |  支持  |
| 实时性 | 高 | 近实时 | 差 |
| 使用HDFS | 不支持 | 支持 | 支持 |
| 空值处理 | 默认null | error | 默认null |
| 并发读写 | 支持 | 不支持并发写 | 支持 |
| 云存储 | 不支持 | 支持 | 支持 |
| 兼容性 | Spark，Impala，Presto | Spark，Presto，Hive，MR 较好 | 依赖Spark，有限支持Hive，Presto |

**选择建议：**考虑实时数仓方案以及SQL支持方面可选Kudu，数据湖方案及可回滚可选DeltaLake和Hudi，考虑兼容性高且应对读多写少读少写多都有很好的方案选Hudi，考虑并发写能力读多写少且与Spark紧密结合选DeltaLake。

## Kudu架构原理

### Raft算法介绍
&emsp;&emsp;为了更好地理解Kudu，需要简单了解一下Raft算法。Raft是一个一致性算法，在分布式系统中一致性算法就是让多个节点在网络不稳定甚至部分节点宕机的情况下能对某个事件达成一致。
&emsp;&emsp;Raft算法的基本原理：先选举出Leader，Leader完全负责副本的管理，Leader接收客户端请求并转发给Follower节点，Leader也会不断发送心跳给Follower节点来证明存活，如果Follower未收到Leader心跳，则Follower节点状态变为Candidate状态并开始选举新的Leader。
&emsp;&emsp;详细了解：[一文搞懂Raft算法](https://www.cnblogs.com/xybaby/p/10124083.html)  
&emsp;&emsp;**Raft算法在Kudu中的应用：**多个TMaster之间通过Raft 协议实现数据同步和高可用--Raft负责在多个Tablet副本中选出Leader和Follower，Leader Tablet负责发送写入数据给Follower Tablet，大多数副本都完成了写操作则会向客户端确认。给定一组需要写N个副本（一般为3或5）的Tablet，可以接受(N-1)/2个写入错误。
### LSM树
<font size="3" color="blue">**LSM树(Log-Structured Merge Tree)**</font>
&emsp;&emsp;Kudu与HBase在写的过程中都采用了LSM树的结构，LSM树的主要思想就是随机写转换为顺序写来提高写性能，随机读写需要磁盘的机械臂不断寻道，延迟较高，而转换为顺序写后机械臂不会频繁寻址，性能较好。  
&emsp;&emsp;LSM树原理是把一棵大的树拆分成N棵小树，小树存在于内存中，随着更新和写入操作，小树存放数据达到一定大小后会写入磁盘，小树到了磁盘中，定期与磁盘中的大树做合并。  
&emsp;&emsp;大家都知道HBase的MemStore，Kudu在写入方面的设计与之类似，Kudu先将对数据的修改保留在内存中，达到一定大小后将这些修改操作批量写入磁盘。但读取的时候稍微麻烦些，需要读取历史数据和内存中最近修改操作。所以写入性能大大提升，而读取时要先去内存读取，如果没命中，则会去磁盘读多个文件。

### Kudu一些概念  
![alt Kudu-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-03.png)   

**Table：**具有Schema和全局有序主键的表。一张表有多个Tablet，多个Tablet包含表的全部数据。
**Tablet：**是Kudu数据实现分布式存储的关键，Kudu的表Table被水平分割为多段，称为Tablet，类似于HBase的Region，每个Tablet存储一段连续范围的数据（会记录开始Key和结束Key），且两个Tablet间不会有重复范围的数据。一个Tablet会复制（逻辑复制而非物理复制，副本中的内容不是实际的数据，而是操作该副本上的数据时对应的更改信息）多个副本在多台TServer上，其中一个副本为Leader Tablet，其他则为Follower Tablet。Leader Tablet响应写请求，任何Tablet副本可以响应读请求。
**TabletServer：**简称TServer，负责数据存储Tablet和提供数据读写服务。一个TServer可以是某些Tablet的Leader，也可以是某些Tablet的Follower，一个Tablet可以被多个TServer服务（多对多关系）。TServer会定期（默认1s）向Master发送心跳。
**Catalog Table：**目录表，用户不可直接读取或写入，由Master维护，存储两类元数据：表元数据（Schema信息，位置和状态）和Tablet元数据（所有TServer的列表、每个TServer包含哪些Tablet副本、Tablet的开始Key和结束Key）。Catalog Table存储在Master节点，随着Master启动而被加载到内存。
**Master：**负责集群管理和元数据管理。具体：跟踪所有Tablets、TServer、Catalog Table和其他相关的元数据。协调客户端做元数据操作，比如创建一个新表，客户端向Master发起请求，Master将新表的元数据写入Catalog Table并协调TServer创建Tablet。Master高可用，同一时刻只有一个Master工作，如果该Master出现问题，也是通过Raft来做选举，一般配置3或5个Master，半数以上Master存活服务都可正常运行。
**逻辑复制：**Kudu基于Raft协议在集群中对每个Tablet都存储多个副本，副本中的内容不是实际的数据，而是操作该副本上的数据时对应的更改信息。Insert和Update操作会走网络IO，但Delete操作不会，压缩数据也不会走网络。

### 存储与读写
**Kudu的存储结构：**
![alt Kudu-04](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-04.jpg)  
&emsp;&emsp;如图，Table分为若干Tablet；Tablet包含Metadata和RowSet，RowSet包含一个MemRowSet及若干个DiskRowSet，DiskRowSet中包含一个BloomFile、Ad_hoc Index、BaseData、DeltaMem及若干个RedoFile和UndoFile（UndoFile一般情况下只有一个）。
&emsp;&emsp;**MemRowSet：**插入新数据及更新已在MemRowSet中的数据，数据结构是B+树，主键在非叶子节点，数据都在叶子节点。MemRowSet写满后会将数据刷到磁盘形成若干个DiskRowSet。每次达到32M生成一个DiskRowSet，DiskRowSet按列存储，类似Parquet。
&emsp;&emsp;**DiskRowSet：**用于老数据的变更（Mutation），后台会定期对DiskRowSet做Compaction，以删除没用的数据及合并历史数据，减少查询过程中的IO开销。DiskRowSets存储文件格式为CFile。这里每个Column被存储在一个相邻的数据区域，这个数据区域被分为多个小的Page，每个Column Page都可以使用一些Encoding以及Compression算法。
&emsp;&emsp;**BaseData：**DiskRowSet刷写完成的数据，CFile，按列存储，主键有序。BaseData不可变。
&emsp;&emsp;**BloomFile：**根据一个DiskRowSet中的Key生成一个BloomFilter，用于快速模糊定位某个key是否在DiskRowSet中存在。
&emsp;&emsp;**AdhocIndex：**存放主键的索引，用于定位Key在DiskRowSet中的具体哪个偏移位置。
&emsp;&emsp;**DeltaMemStore：**用于DiskRowSet中数据的变更，先写到内存中，写满后Flush到磁盘形成RedoFile。每份DiskRowSet都对应内存中一个DeltaMemStore，负责记录这个DiskRowSet上BaseData发生后续变更的数据。DeltaMemStore的组织方式与MemRowSet相同，也维护一个B+树，记录发生的数据变更。
&emsp;&emsp;**DeltaFile：**DeltaMemStore到一定大小会存储到磁盘形成DeltaFile，分为UndoFile和RedoFile。
&emsp;&emsp;**RedoFile：**重做文件，记录上一次Flush生成BaseData之后发生变更数据。DeltaMemStore写满之后，也会刷成CFile，不过与BaseData分开存储，名为RedoFile。UndoFile和RedoFile与关系型数据库中的Undo日子和Redo日志类似。
&emsp;&emsp;**UndoFile：**撤销文件，记录上一次Flush生成BaseData之前时间的历史数据，数据被修改前的历史值，可以根据时间戳回滚读到历史数据。UndoFile一般只有一份。


&emsp;&emsp;DeltaFile-主要是RedoFile会不断增加，不合并不Compaction肯定影响性能，所以就有了下面两种合并方式：
* Minor Compaction：多个DeltaFile进行合并生成一个大的DeltaFile。默认是1000个DeltaFile进行合并一次。
* Major Compaction：RedoFile文件的大小和BaseData的文件的比例为0.1的时候，会将RedoFile合并到BaseData，生成UndoData。

**Kudu写流程：**
![alt Kudu-05](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-05.jpg)  
1. Client向Master发起写请求，Master找到对应的Tablet元数据信息，检查请求数据是否符合表结构
2. 因为Kudu不允许有主键重复的记录，所以需要判断主键是否已经存在，先查询主键范围，如果不在范围内则准备写MemRowSet
3. 如果在主键范围内，先通过主键Key的布隆过滤器快速模糊查找，未命中则准备写MemRowSet
4. 如果BloomFilter命中，则查询索引，如果没命中索引则准备写MemRowSet，如果命中了主键索引就报错：主键重复
5. 写入MemRowSet前先被提交到Tablet的WAL预写日志，并根据Raft一致性算法取得Follower Tablets的同意，然后才会被写入到其中一个Tablet的内存中。插入的数据会被添加到tablet的MemRowSet中

**Kudu读流程：**
![alt Kudu-06](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-06.jpg)  
1. Client发送读请求，Master根据主键范围确定到包含所需数据的所有Tablet位置和信息。
2. Client找到所需Tablet所在TServer，TServer接受读请求。
3. 如果要读取的数据位于内存，先从内存（MemRowSet，DeltaMemStore）读取数据，根据读取请求包含的时间戳前提交的更新合并成最终数据。
4. 如果要读取的数据位于磁盘（DiskRowSet，DeltaFile），在DeltaFile的UndoFile、RedoFile中找目标数据相关的改动，根据读取请求包含的时间戳合并成最新数据并返回。

**Kudu更新流程：**
![alt Kudu-07](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-07.jpg)  
1. Client发送更新请求，Master获取表的相关信息，表的所有Tablet信息。
2. Kudu检查是否符合表结构。
3. 如果需要更新的数据在MemRowSet，B+树找到待更新数据所在叶子节点，然后将更新操作记录在所在行中一个Mutation链表中；Kudu采用了MVCC(多版本并发控制，实现读和写的并行)思想，将更改的数据以链表形式追加到叶子节点后面，避免在树上进行更新和删除操作。
4. 如果需要更新的数据在DiskRowSet，找到其所在的DiskRowSet，前面提到每个DiskRowSet都会在内存中有一个DeltaMemStore，将更新操作记录在DeltaMemStore，达到一定大小才会生成DeltaFile到磁盘。

### 分区方式  
Kudu的分区即为Tablet，分区模式有两种：
* **基于Hash分区(Hash Partitioning):**哈希分区通过哈希值将行分配到许多Buckets(存储桶)之一,一个Bucket对应一个Tablet当不需要有序访问时，哈希分区可以减轻热点和Tablet大小不均匀问题。
* **基于Range分区(Range Partitioning):**由PK范围划分组成，一个区间对应一个Tablet。范围分区可以根据存入数据的数据量，均衡的存储到各个机器上，防止机器出现负载不均衡现象。
* **多级分区(Multilevel Partitioning):**可以在单表上组合分区类型，保留两种分区类型的优点。  

### 一些细节
1. 为什么Kudu要比HBase、Cassandra扫描速度更快？
&emsp;&emsp;HBase、Cassandra都有列簇(CF)，并不是纯正的列存储，那么一个列簇中有几个列，但这几个列不能一起编码，压缩效果相对不好，而且在扫描其中一个列的数据时，必然会扫描同一列簇中的其他列。Kudu没有列簇的概念，它的不同列数据都在相邻的数据区域，可以在一起压缩，也可以对不同列使用不同压缩算法，压缩效果很好；而且需要哪列读哪列不会读其他列，读取时不需要进行Merge操作，根据BaseData和Delta数据得到最终数据。Kudu扫描性能可媲美Parquet。还有，Kudu的读取方式避免了很多字段的比较操作，CPU利用率高。
2. Kudu一个Tablet中存很多很多DiskRowSet，怎么才能快速判断Key在哪个DiskRowSet？
&emsp;&emsp;首先肯定不能遍历，O(n)的复杂度是很难受的。它使用二叉查找树，每个节点维护多个DiskRowSet的最大Key和最小Key，这样就可在O(logn)时间内定位Key所在DiskRowSet。

## Kudu使用  
实验环境：
四台机器CDH6.3.1集群，6核心12线程，内存分别为：20GB，14GB，14GB和10GB。
**OS:**CentOS7;**Impala:**3.2.0-cdh6.3.1;**Kudu:**1.10.0-cdh6.3.1(3Master+3TServer);**Hive:**2.1.1-cdh6.3.1;
![alt Kudu-08](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-08.jpg)  
依次启动HDFS、hive、Kudu、Impala。

### Kudu + Impala
&emsp;&emsp;Impala定位是一款实时查询引擎(低延时SQL交互查询)，快的原因：基于内存计算，无需MR，C++编写，兼容HiveQL和支持数据本地化。这与Kudu场景相吻合，Kudu官网也说Impala和Kudu可以无缝整合。
&emsp;&emsp;进入Impala配置，Kudu服务处勾选Kudu即可。

1. Impala创建Kudu内部表
```Impala
impala-shell -i cdh102:21000  -- Impala Daemon在cdh102机器

CREATE DATABASE IF NOT EXISTS impala_kudu;

-- 建内部表，Impala发生drop操作会删除Kudu上对应数据
CREATE TABLE impala_kudu.first_kudu_table(  
id INT,
name String,
PRIMARY KEY(id)
)
PARTITION BY HASH PARTITIONS 8
STORED AS KUDU
TBLPROPERTIES (
'kudu.master_addresses' = 'cdh102:7051,cdh103:7051,cdh104:7051'
);
-- 查看Kudu中已能看到刚创建的表
kudu table list cdh102:7051,cdh103:7051,cdh104:7051
-- 查看表以及tablets
kudu table list cdh102:7051,cdh103:7051,cdh104:7051 --list_tablets
```

2. 在Impala映射已经存在的Kudu表
```Impala


```

### Kudu + Spark


### Kudu + Hive

### Kudu APIs
``` Java

```

``` Python

```

## Kudu优化
1. 使用SSD会显著提高Kudu性能。（因为如果取多个字段，列式存储在传统磁盘上会多次寻址，而使用SSD不会有寻址问题）
2. https://blog.csdn.net/weixin_39478115/article/details/78469837?utm_medium=distribute.pc_relevant_t0.none-task-blog-BlogCommendFromMachineLearnPai2-1.edu_weight&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-BlogCommendFromMachineLearnPai2-1.edu_weight
3.memory_limit_hard_bytes
该参数是单个TServer能够使用的最大内存量。如果写入量很大而内存太小，会造成写入性能下降。如果集群资源充裕，可以将它设得比较大，比如设置为单台服务器内存总量的一半。
官方也提供了一个近似估计的方法，即：每1TB实际存储的数据约占用1.5GB内存，每个副本的MemRowSet和DeltaMemStore约占用128MB内存，（对多读少写的表而言）每列每CPU核心约占用256KB内存，另外再加上块缓存，最后在这些基础上留出约25%的余量。

block_cache_capacity_mb
Kudu中也设计了BlockCache，不管名称还是作用都与HBase中的对应角色相同。默认值512MB，经验值是设置1~4GB之间，我们设了4GB。

memory.soft_limit_in_bytes/memory.limit_in_bytes
这是Kudu进程组（即Linux cgroup）的内存软限制和硬限制。当系统内存不足时，会优先回收超过软限制的进程占用的内存，使之尽量低于阈值。当进程占用的内存超过了硬限制，会直接触发OOM导致Kudu进程被杀掉。我们设为-1，即不限制。

maintenance_manager_num_threads
单个TServer用于在后台执行Flush、Compaction等后台操作的线程数，默认是1。如果是采用普通硬盘作为存储的话，该值应与所采用的硬盘数相同。

max_create_tablets_per_ts
创建表时能够指定的最大分区数目（hash partition * range partition），默认为60。如果不能满足需求，可以调大。

follower_unavailable_considered_failed_sec
当Follower与Leader失去联系后，Leader将Follower判定为失败的窗口时间，默认值300s。

max_clock_sync_error_usec
NTP时间同步的最大允许误差，单位为微秒，默认值10s。如果Kudu频繁报时间不同步的错误，可以适当调大，比如15s。



## Kudu异常处理
[Apache Kudu Troubleshooting](https://kudu.apache.org/docs/troubleshooting.html)

## 总结
&emsp;&emsp;Kudu--Fast Analytics on Fast Data.一个Kudu实现了整个大数据技术栈中诸多组件的功能，有分布式文件系统（好比HDFS），有一致性算法（好比Zookeeper），有Table（好比Hive表），有Tablet（好比Hive分区），有列式存储（如Parquet），有顺序和随机读取（如HBase），所以看起来kudu像一个轻量级的，结合了HDFS+Zookeeper+Hive+Parquet+HBase等组件功能并在性能上进行平衡的组件。它轻松地解决了随机读写+快速分析的业务场景，解决了实时数仓的诸多难点，同时降低了存储成本和运维成本。在实时数仓和实时计算蓬勃发展的今天，你确定不学一下Kudu吗？


## 参考资料
1.《Kudu:构建高性能实时数据分析存储系统》
2.[Apache Kudu - Fast Analytics on Fast Data](https://kudu.apache.org/docs/)
3.[Kudu专注于大规模数据快速读写，同时进行快速分析的利器](https://www.cnblogs.com/dajiangtai/p/12461999.html)
4.[Kudu基础入门](https://www.cnblogs.com/starzy/p/10573508.html)
5.[Kudu、Hudi和Delta Lake的比较](https://www.cnblogs.com/kehanc/p/12153409.html)
6.[迟到的Kudu设计要点面面观](https://blog.csdn.net/nazeniwaresakini/article/details/104220206/)
7.[迟到的Kudu设计要点面面观-前篇](https://www.jianshu.com/p/5ffd8730aad8)