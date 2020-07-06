---
title: Apache Kudu学习篇
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
  - 实时OLAP
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
* 解决HBase大批量数据SQL分析性能不佳的场景
* 跨大量历史数据的查询分析场景（Time-series场景）

### 特点及缺点  
1. **特点**
  * 基于列式存储
  * 快速顺序读写
  * 使用 [LSM树](https://shmily-qjj.top/5f26355/#LSM树) 以支持高效随机读写
  * 查询性能和耗时较稳定
  * 不依赖Zookeeper
  * 有表结构，需要定义Schema，需要定义唯一键，支持SQL分析
  * 支持增删列,行级ACID
  * 查询时先查询内存再查询磁盘
  * 数据存储在Linux文件系统，不依赖HDFS存储
2. **缺点**  
  * 暂不支持除PK外的二级索引和唯一性限制
  * 不支持BloomFilter优化join 
  * 不能通过Alter来drop PK
  * 每表最多不能有300列

## Kudu架构原理
&emsp;&emsp;Kudu有很多概念，有分布式文件系统（如HDFS），有一致性算法（类似Zookeeper），有Table（如Hive表），有Tablet（类似Hive表分区），有列式存储（如Parquet），有顺序和随机读取（如HBase），所以看起来kudu像一个轻量级的，结合了HDFS+Zookeeper+Hive+Parquet+HBase等组件功能并在性能上进行平衡的组件。
### Raft算法介绍
&emsp;&emsp;为了更好地理解Kudu，需要简单了解一下Raft算法。Raft是一个一致性算法，在分布式系统中一致性算法就是让多个节点在网络不稳定甚至部分节点宕机的情况下能对某个事件达成一致。
&emsp;&emsp;Raft算法的基本原理：先选举出Leader，Leader完全负责副本的管理，Leader接收客户端请求并转发给Follower节点，Leader也会不断发送心跳给Follower节点来证明存活，如果Follower未收到Leader心跳，则Follower节点状态变为Candidate状态并开始选举新的Leader。
&emsp;&emsp;详细了解：[一文搞懂Raft算法](https://www.cnblogs.com/xybaby/p/10124083.html)  
&emsp;&emsp;**Raft算法在Kudu中的应用：**Raft负责在多个Tablet副本中选出Leader和Follower，Leader Tablet负责发送写入数据给Follower Tablet，大多数副本都完成了写操作则会向客户端确认。给定一组需要写N个副本（一般为3或5）的Tablet，可以接受(N-1)/2个写入错误。
### LSM树
<font size="3" color="blue">**LSM树（Log-Structured Merge Tree）**</font>
&emsp;&emsp;Kudu与HBase在写的过程中都采用了LSM树的结构，LSM树的主要思想就是随机写转换为顺序写来提高写性能，随机读写需要磁盘的机械臂不断寻道，延迟较高，而转换为顺序写后机械臂不会频繁寻址，性能较好。  
&emsp;&emsp;LSM树原理是把一棵大的树拆分成N棵小树，小树存在于内存中，随着更新和写入操作，小树存放数据达到一定大小后会写入磁盘，小树到了磁盘中，定期与磁盘中的大树做合并。  
&emsp;&emsp;大家都知道HBase的MemStore，Kudu在写入方面的设计与之类似，Kudu先将对数据的修改保留在内存中，达到一定大小后将这些修改操作批量写入磁盘。但读取的时候稍微麻烦些，需要合并磁盘中历史数据和内存中最近修改操作。所以写入性能大大提升，而读取时要先去内存读取，如果没命中，则会去磁盘读多个文件。

### Kudu一些概念  
![alt Kudu-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-03.png)   

**Table：**具有Schema和全局有序主键的表。一张表有多个Tablet，多个Tablet包含表的全部数据。
**Tablet：**是Kudu数据实现分布式存储的关键，Kudu的表Table被水平分割为多段，称为Tablet，类似于HBase的Region，每个Tablet存储一段连续范围的数据（会记录开始Key和结束Key），且两个Tablet间不会有重复范围的数据。一个Tablet会复制（逻辑复制而非物理复制）多个副本在多台TServer上，其中一个副本为Leader Tablet，其他则为Follower Tablet。Leader Tablet响应写请求，任何Tablet副本可以响应读请求，副本中的内容不是实际的数据，而是操作该副本上的数据时对应的更改信息。
**TabletServer：**简称TServer，负责数据存储Tablet和提供数据读写服务。一个TServer可以是某些Tablet的Leader，也可以是某些Tablet的Follower，一个Tablet可以被多个TServer服务（多对多关系）。TServer会定期（默认1s）向Master发送心跳。
**Catalog Table：**目录表，用户不可直接读取或写入，由Master维护，存储两类元数据：表元数据（Schema信息，位置和状态）和Tablet元数据（所有TServer的列表、每个TServer包含哪些Tablet副本、Tablet的开始Key和结束Key）。Catalog Table存储在Master节点，随着Master启动而被加载到内存。
**Master：**负责集群管理和元数据管理。具体：跟踪所有Tablets、TServer、Catalog Table和其他相关的元数据。协调客户端做元数据操作，比如创建一个新表，客户端向Master发起请求，Master将新表的元数据写入Catalog Table并协调TServer创建Tablet。Master高可用，同一时刻只有一个Master工作，如果该Master出现问题，也是通过Raft来做选举，一般配置3或5个Master，半数以上Master存活服务都可正常运行。
**逻辑复制：**Insert和Update操作会走网络IO，但Delete操作不会，压缩数据也不会走网络。

### 存储与读写
**Kudu的存储结构：**
![alt Kudu-04](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-04.jpg)  
&emsp;&emsp;如图，Table分为若干Tablet；Tablet包含Metadata和RowSet，RowSet包含一个MemRowSet及若干个DiskRowSet，DiskRowSet中包含一个BloomFile、Ad_hoc Index、BaseData、DeltaMem及若干个RedoFile和UndoFile（UndoFile一般情况下只有一个）。
&emsp;&emsp;**MemRowSet：**插入新数据及更新已在MemRowSet中的数据，数据结构是B-树，按行存储一个MemRowSet写满后会将数据刷到磁盘形成若干个DiskRowSet。每次到达32M生成一个DiskRowSet，DiskRowSet按列存储，类似Parquet。
&emsp;&emsp;**DiskRowSet：**用于老数据的变更（Mutation），后台定期对DiskRowSet做Compaction，以删除没用的数据及合并历史数据，减少查询过程中的IO开销。DiskRowSets可以理解为HBase的HFile。这里每个Column被存储在一个相邻的数据区域，这个数据区域被分为多个小的Page，每个Column Page都可以使用一些Encoding以及Compression算法。
&emsp;&emsp;**BloomFile：**根据一个DiskRowSet中的Key生成一个Bloom Filter，用于快速模糊定位某个key是否在DiskRowSet中存在。
&emsp;&emsp;**AdhocIndex：**存放主键的索引，用于定位Key在DiskRowSet中的具体哪个偏移位置。
&emsp;&emsp;**BaseData：**MemRowSet达到一定大小后Flush下来的数据，按列存储，主键有序。
&emsp;&emsp;**UndoFile：**是基于BaseData之前时间的历史数据，数据被修改前的历史值，通过在BaseData上Apply UndoFile中的记录，可以获得历史数据（事务回滚）。
&emsp;&emsp;**RedoFile：**是基于BaseData之后时间的变更数据，数据被修改后的值，通过在BaseData上apply RedoFile中的记录，可获得较新的数据（事务提交）。UndoFile和RedoFile与关系型数据库中的Undo日子和Redo日志类似。
&emsp;&emsp;**DeltaMem：**用于DiskRowSet中数据的变更，先写到内存中，写满后Flush到磁盘形成RedoFile。

&emsp;&emsp;Kudu中文件会不断合并，有两种合并：
Minor Compaction：多个DeltaFile进行合并生成一个大的DeltaFile。默认是1000个DeltaFile进行合并一次。
Major Compaction：DeltaFile文件的大小和Base data的文件的比例为0.1的时候，会进行合并操作，生成Undo data。


### 分区方式  
Kudu的分区即为Tablet，分区模式有两种：
* 基于Hash分区

* 基于Range分区

## Kudu使用  


``` java

```

## Kudu优化
1. 使用SSD会显著提高Kudu性能。

## Kudu异常处理
[Apache Kudu Troubleshooting](https://kudu.apache.org/docs/troubleshooting.html)

## 总结

* 字体
*斜体文本*
_斜体文本_
**粗体文本**
__粗体文本__
***粗斜体文本***
___粗斜体文本___
<u>带下划线文本</u>


## 部署


## 参考资料
1.《Kudu:构建高性能实时数据分析存储系统》
2.[Apache Kudu - Fast Analytics on Fast Data](https://kudu.apache.org/docs/)
3.[Kudu专注于大规模数据快速读写，同时进行快速分析的利器](https://www.cnblogs.com/dajiangtai/p/12461999.html)
4.[Kudu基础入门](https://www.cnblogs.com/starzy/p/10573508.html)

