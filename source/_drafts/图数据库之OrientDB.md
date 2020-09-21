---
title: 图数据库之OrientDB
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
  - 图数据库
keywords: OrientDB
description: 图数据库之OrientDB
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/OrientDB/OrientDB-cover.jpg
date: 2020-09-21 10:16:00
---
# 图数据库简介  
&emsp;&emsp;图数据库是一种NoSQL数据库，使用图形理论存储实体间关系，常见例子是社会网络中人与人的关系。图数据库能更好地反映实体间多对多的关系(关系网络)。与传统关系型数据库相比，如果关系网络数据使用关系型数据库存储，会带来更多存储开销，更复杂的查询逻辑，更多的服务器负载和更高的查询延迟，图数据库的多层次多样性复杂关系查询、海量关系数据存储和查询弥补了这些不足。
&emsp;&emsp;目前图数据库一些常见的应用场景：公司关系、社交关系、风控领域、金融与资金关系网络、知识图谱、基于图模型训练、基于社交关系网络的社交推荐(拼多多的商品推荐，抖音的视频推荐，头条的内容推荐)、识别团伙作案等等。
&emsp;&emsp;**不同类型NoSQL对比**
| 分类 | 数据模型 | 优势 | 劣势 | 举例 |
| :----: | :----: | :----: | :----: | :----: |
| 键值数据库 | 哈希表 | 查找速度快 | 数据无结构化 | Redis |
| 列式数据存储 | 列式数据 | 查找快可扩展高压缩 | 功能相对受限 | HBase |
| 文档型数据库 | JSON | 表结构可变，无需预先定义 | 查询性能不高、缺乏统一的查询语法 | MongoDB |
| 图数据库 | 节点和关系组成的图 | 可利用图结构相关算法(最短路径、节点度关系查找等) | 可能需要对整个图做计算、不利于图数据分布存储 | Neo4j、JanusGraph、OrientDB |

# 图数据库通用概念  
Graph(图):是一种基于图论的数据模型，将数据节点和节点间表示关系的边的集合相关联构成的图结构。
Vertex(顶点、节点):存储主要数据元素，通过关系连接到其他节点，可具有一个或多个属性，可具有一个或多个标签(描述其在图表中的作用)。
Edge(边缘、关系):连接两个节点，具有方向性的，代表节点间的关联关系，关系可以有一个或多个属性。
属性:节点指向另外一个文档的指针，记录数据的不同元素不同属性，便于集中检索。除了节点有属性外，关系上也可含有属性。属性可以被索引和约束，可以对多个属性创建复合索引。
Label(标签):用于将节点分组，一个节点可以有多个标签，可以对标签索引加速查找节点。

常见图算法：
* 基本算法： 深度优先遍历，广度优先遍历，A*搜索算法等
* 最短路径算法：Dijkstra，Bellman-Ford，Floyd-Warshall等
* 最小生成树： Prim，Kruskal等
* 图匹配： 匈牙利算法等
* 强连通分支算法与网络流：Ford-Fulkerson等
* 深度学习： GNN

Gremlin:一种图遍历语言

## OrientDB
### 特性
&emsp;&emsp;OrientDB使用Java语言实现，运行在JVM上。
* 支持多种数据模型包括K-V，Object，Document和Graph。
* 支持多Master备份，每个节点都是Master，都包含完整数据，其中一个Master中数据发生变更数据会同步其他Master。
* 支持大部分标准的SQL，同时在标准的SQL之上扩展了部分功能以方便图的操作
* 定义数据结构的Class符合OOP面向对象理念，支持继承和多态。

### 基本概念
Classes:用于定义数据结构模型，类比关系型数据库中的Table，类比文档数据库中的Document
Record:OrientDB中最小的加载和存储单位，分四种类型(Document,RecordBytes,Vertex,Edge)
Document:OrientDB中最灵活的Record形式，可通过create class来定义，Document支持schema-less,schemal-full,schema-mixed，即可以在定义数据结构的时候指定属性及约定条件，也可以不指定。
Vertex:在Graph数据结构下的结点(顶点)，每个Vertex也是一个Document。
Edge:在Graph数据结构下连接两个Vertex的边，它是有向性的。
Clusters:用于存储Record。每个数据库最多有32767个Cluster。每个Class都必须至少有一个对应的Cluster。默认情况下OrientDB会自动为每个Class创建与当前cpu核数相同的Cluster，其中有一个默认的Cluster。
ClusterSelection:当新增加一条Reocrd时OrientDB会根据ClusterSection为这条记录选择一个Cluster。ClusterSelection有四种类型(detault、round-robin、balanced、local)。
RecordID:每个record都有一个RecordID，格式：#<cluster-id>:<cluster-position>。
Relationships:类似于关系型数据库的Join，但OrientDB不用Join，而是每个Record中定义的关系类型属性来维护关系，这个关系属性实际存储的是RecordID。



https://www.w3cschool.cn/orientdb/orientdb_basic_concepts.html
https://blog.csdn.net/clj198606061111/article/details/82314459
http://www.orientdb.org/docs/3.0.x/

### 优点


### 缺点

## OrientDB原理

https://www.cnblogs.com/jpfss/p/11412176.html

SB-Tree Index：从其他索引类型中获得的特性的良好组合，默认索引
Hash Index：
Auto Sharding Index：提供一个DHT实现；不支持范围查询
Lucene Spatial Index：持久化，支持事物，范围查询

## OrientDB使用  

### OrientBD安装
```
tar -zxvf /opt/software/orientdb-3.1.2.tar.gz  -C /opt/modules/
cd /opt/modules/orientdb-3.1.2/
vim /etc/profile  添加ORIENTDB_HOME和ORIENTDB_PATH source /etc/profile
vim /opt/modules/orientdb-3.1.2/bin/orientdb.sh 修改ORIENTDB_DIR为/opt/modules/orientdb-3.1.2/ 修改ORIENTDB_USER为root
sudo cp $ORIENTDB_HOME/bin/orientdb.sh /etc/init.d/orientdb
vim /usr/bin/orientdb  编写#!/bin/bash 换行 source /etc/profile 换行 sh $ORIENTDB_HOME/bin/console.sh  然后chmod 744 /usr/bin/orientdb
service orientdb start   （关闭是service orientdb stop）
service orientdb status
chkconfig orientdb on
ps -ef | grep orientdb可以看到已启动
连接console: orientdb
进入WebUI界面:http://host:2480/studio/index.html#/  账户admin密码admin
```  

### 控制台命令


### WebUI使用




### 连接工具类
```java

```

## 参考
[越来越火的图数据库究竟是什么](https://www.cnblogs.com/mantoudev/p/10414495.html)
[聊聊何为图数据库和图数据库的小知识](https://zhuanlan.zhihu.com/p/79484631)
[图数据库OrientDB-基础篇](https://blog.csdn.net/jinnee/article/details/70224512)

