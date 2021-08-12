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

图遍历语言:
* [Gremlin](http://orientdb.com/docs/3.0.x/gremlin/Gremlin.html)

#  主流图数据库对比
[主流图数据库Neo4J、ArangoDB、OrientDB综合对比-架构分析](https://www.cnblogs.com/jpfss/p/11412176.html)
<!-- 看不到我看不到我 -->

## OrientDB
### 特性
&emsp;&emsp;OrientDB使用Java语言实现，运行在JVM上。
* 支持多种数据模型包括K-V，BLOB，Document和Graph(包括CLASS、Vertex顶点、Edge边缘)。
* 支持多种数据类型：[数据类型列表](https://www.w3cschool.cn/orientdb/orientdb_data_types.html)
* 支持多Master备份，每个节点都是Master，都包含完整数据，其中一个Master中数据发生变更数据会同步其他Master。
* 支持大部分标准的SQL，同时在标准的SQL之上扩展了部分功能以方便图的操作
* 定义数据结构的Class符合OOP面向对象理念，支持继承和多态。

### 基本概念
Classes:用于定义数据结构模型，类比关系型数据库中的Table，类比文档数据库中的Document，每个类都有自己的集群（数据文件），非抽象类至少有一个集群，一个类可以有多个集群，类支持继承，创建新类时OrientDB将创建与该类同名的新的持久性群集，默认OrientDB为每个类创建的群集与主机具有的内核（超线程数）一样多。例子：类Person，OrientDB将创建集群person，person_1，person_2...
Record:OrientDB中最小的加载和存储单位，分四种类型(Document,RecordBytes,Vertex,Edge)
Document:OrientDB中最灵活的Record形式，可通过create class来定义，Document支持schema-less,schemal-full,schema-mixed，即可以在定义数据结构的时候指定属性及约定条件，也可以不指定
Vertex:在Graph数据结构下的结点(顶点)，每个Vertex也是一个Document
Edge:在Graph数据结构下连接两个Vertex的边，它是有向性的
Clusters:用于存储Record。每个数据库最多有32767个Cluster。每个Class都必须至少有一个对应的Cluster。默认情况下OrientDB会自动为每个Class创建与当前cpu核数相同的Cluster，其中有一个默认的Cluster
ClusterSelection:当新增加一条Reocrd时OrientDB会根据ClusterSection为这条记录选择一个Cluster。ClusterSelection有四种类型(detault、round-robin、balanced、local)
RecordID:即@rid，每个record都有一个RecordID，格式：#<cluster-id>:<cluster-position>，cluster-id是指所属群集，正数为持久记录，负数为临时记录,rid代表集群中记录的绝对位置
VersionID:即@version，每次更新都会自动+1，乐观事务中，OrientDB会检查这个版本，避免提交发生冲突
Relationships:类似于关系型数据库的Join，但OrientDB不用Join，而是每个Record中定义的关系类型属性来维护关系，这个关系属性实际存储的是RecordID

<!-- ### 优点 -->

<!-- ### 缺点 -->

## OrientDB原理
![alt OrientDB-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/OrientDB/OrientDB-01.png)  

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
```OrientDB
创建库
CREATE DATABASE PLOCAL:/opt/orientdb/databses/demo 创建写入文件系统以存储数据的数据库
CREATE DATABASE memory:demo   创建存储在内存的数据库
CREATE DATABASE remote:localhost/demo 存储通过远程网络连接打开，多个客户端共享的数据库
连接数据库
CONNECT PLOCAL:/opt/orientdb/databses/demo admin admin
断开数据库
DISCONNECT
创建CLASS
CREATE CLASS hivetable  普通CLASS
CREATE CLASS hivetable_v EXTENDS V;  顶点CLASS
CREATE CLASS hivetable_source_e EXTENDS E;  边CLASS
创建属性
CREATE PROPERTY hivetable_v.db_name String   创建顶点的属性
CREATE PROPERTY hivetable_v.table_name String 
CREATE PROPERTY hivetable_v.last_references_datetime datetime
CREATE PROPERTY hivetable_v.refer_num INTEGER
CREATE PROPERTY hivetable_v.creator String
CREATE PROPERTY hivetable_v.create_datetime datetime
CREATE PROPERTY hivetable_v.update_datetime datetime
CREATE PROPERTY hivetable_source_e.link_num INTEGER  创建边的属性
CREATE PROPERTY hivetable_source_e.create_datetime datetime
CREATE PROPERTY hivetable_source_e.update_datetime datetime
写入数据到CLASS
INSERT INTO hivetable VALUES ('xx','xx'...)
CREATE VERTEX hivetable CONTENT {"db_name" : "default", "table_name" : "qjj","last_references_datetime":"2020-12-02",........}
新增VERTEX顶点
CREATE VERTEX V 
CREATE VERTEX V SET name="user01",sex="M",age="25";
CREATE VERTEX V SET name="user02",sex="F",age="23";
新增hivetable_v类型的顶点
CREATE VERTEX hivetable_v SET db_name="test",table_name="source_table",last_references_datetime="2020-09-21 10:20:20",refer_num=1,creator="qjj",create_datetime="2020-09-20 10:15:15",update_datetime="2020-09-20 11:10:15";
CREATE VERTEX hivetable_v SET db_name="test",table_name="target_table",last_references_datetime="2020-09-21 10:20:25",refer_num=1,creator="qjj",create_datetime="2020-09-25 10:15:15",update_datetime="2020-09-25 11:10:15";
删除VERTEX顶点
DELETE VERTEX V WHERE name="user01";
删除hivetable_v类型的顶点
DELETE VERTEX hivetable_v where table_name = 'source_table';
新增Edge边
CREATE EDGE E FROM #1:1 TO #1:2 SET name="friend";
新增hivetable_source_e类型的边连接两个hivetable_v类型的顶点
CREATE EDGE hivetable_source_e FROM (select from hivetable_v where db_name='test' and table_name="target_table") TO (select from hivetable_v where db_name='test' and table_name="source_table");
删除Edge边
DELETE EDGE E WHERE name="friend";
DELETE EDGE hivetable_source_e WHERE in = "#11:10" AND out = "#12:10";
DELETE EDGE hivetable_source_e WHERE in IN (select from hivetable_v where db_name='test' and table_name="target_table") AND out IN (select from hivetable_v where db_name='test' and table_name="source_table");
创建新的顶点类型
CREATE CLASS V1 EXTENDS V
移动顶点
MOVE VERTEX #13:1 TO CLASS:V1
创建新的边类型
CREATE CLASS E1 EXTENDS E
应用新的边类型到两个结点
CREATE EDGE E1 FROM #10:3 TO #11:4
获取当前时间
SELECT SYSDATE()
查询一个CLASS
SELECT FROM class_name
SELECT * FROM class_name
SELECT * FROM class_name where name = "qjj"
SELECT FROM CLUSTER_NAME:class_name   指定cluster，有点类似于查Hive分区表，通过缩小查询结果集来优化查询效率
更新CLASS
UPDATE class_name SET name = "qjj",update_time = SYSDATE() WHERE in IN (SELECT FROM class_name WHERE name = "abc")  (通过条件更新，用IN代替=)
UPDATE class_name SET name = "qjj",update_time = SYSDATE() WHERE in = #43:0     (通过RecordID更新)
UPDATE class_name INCREMENT age = 1 where @rid = '#21:10'; 在原有数据上更新 要确保原有数据存在
UPDATE hivetable_source_e INCREMENT link_num = 1 where in IN (select from hivetable_v where db_name='test' and table_name="source_table") and out IN (select from hivetable_v where db_name='test' and table_name="target_table");  更新边属性link_num自增1(OrientDB 2.x)
UPDATE hivetable_source_e SET link_num = link_num + 1 where in = #377:0 and out = #378:0  (OrientDB 3.x支持，除了+还支持-*/%>><<>>><<<&|^||)
删除CLASS
DROP CLASS hivetable
查询顶点所有入边
select inE() from hivetable_v
查询顶点的所有出边
select outE() from hivetable_v
查询顶点的所有入点
select in() from hivetable_v
查询顶点的所有出点
select out() from hivetable_v
查询所有入边入点出边出点的详细信息包含属性信息
select expand(inE()) from hivetable_v
select expand(outE()) from hivetable_v
select expand(in()) from hivetable_v
select expand(out()) from hivetable_v
查询所有与点#378:0相关的点
SELECT both() FROM #378:0
查询所有与点#378:0相关的边
SELECT bothE() FROM #378:0
查询所有与边#387:0相关的点
SELECT bothV() FROM #387:0
查询边#387:0的in、out点
SELECT inV() FROM #387:0
SELECT outV() FROM #387:0
```
以上只是基础用法，更多高级用法以及SQL支持语法见:[OrientDB SQL Reference](http://www.orientdb.org/docs/3.0.x/sql/)

### 图遍历SQL之TRAVERSE语法
TRAVERSE主要用于对图进行遍历。基于深度搜索算法或者广度搜索算法对图进行有限制的盲目搜索。它返回一个符合遍历条件的子图。具体使用可以参考：**[OrientDB图遍历SQL之TRAVERSE](https://cloud.tencent.com/developer/article/1528017)**

### 图遍历SQL之Match语法
Match语法基于OrientDB3.x版本，具体使用可以参考：**[OrientDB图遍历SQL之MATCH](https://cloud.tencent.com/developer/article/1528023)**
后续完善

### 经典案例实践
通过案例熟悉图数据库中顶点和边如何设计,也方便理解点、边、属性、类等相关概念。
**案例1：人际关系网**
```sql
-- 小朱25岁，出生在教师家庭并且有个姐姐小田，他现在奋斗在帝都。 
CREATE VERTEX V SET name="小朱",sex="男",age="25";
CREATE VERTEX V SET name="小田",sex="女",age="27";
CREATE EDGE E FROM #9:0 TO #10:0 SET name="sisiter";
CREATE EDGE E FROM #10:0 TO #9:0 SET name="brother";
Select from V where name in ['小朱',"小田"];  -- select 在 Graph 页面查询会自动渲染出关系结果
-- 小朱还有一个可爱的女盆友叫小刘
CREATE VERTEX V SET name="小刘",sex="女",age="23";
CREATE EDGE E FROM #9:0 TO #11:0 SET name="lover";
CREATE EDGE E FROM #11:0 TO #9:0 SET name="lover";
-- 小朱目前工作在企业ABC，他有一堆同事小马、小龚、小微...
CREATE VERTEX V SET name="ABC";
CREATE VERTEX V SET name="小马",sex="男",age="29",company="ABC";
CREATE VERTEX V SET name="小龚",sex="男",age="28",company="ABC";
CREATE VERTEX V SET name="小微",sex="女",age="24",company="ABC";
UPDATE V SET company = 'ABC' WHERE name='小朱'
CREATE EDGE E FROM (select from V where company='ABC') TO (select from V where name ='ABC') SET name="employee";
-- 小朱目前跟不同同事合作完成了如下项目：PROJECT-1,PROJECT-2,PROJECT-3…..
CREATE VERTEX V SET name="PROJECT-1",type='JAVA',starttime='2016/01/01';
CREATE VERTEX V SET name="PROJECT-2",type='JAVA',starttime='2016/01/01';
CREATE VERTEX V SET name="PROJECT-3",type='JAVA',starttime='2016/01/01';
CREATE EDGE E FROM (select from V where name in ['小朱','小马','小微']) TO (select from v where name='PROJECT-1') SET name="work";
CREATE EDGE E FROM (select from V where name in ['小朱','小马','小微','小龚']) TO (select from v where name='PROJECT-2') SET name="work";
CREATE EDGE E FROM (select from V where name in ['小朱','小马','小龚']) TO (select from v where name='PROJECT-3') SET name="work";
-- 以上描述中，所有点和边缘均直接继承了祖先V、E对象，不能方便的通过语句进行筛选，不推荐直接创建V、E记录。
-- 所以用CLASS改造上面的场景==>用不同的关系对象表示
-- 上面场景产生了这些点和边：V{Company,Preson,Project}，E{Lover,sisiter,brother,employee,work}
-- 改进：
CREATE CLASS Company EXTENDS V;
CREATE CLASS Project EXTENDS V;
CREATE CLASS Preson EXTENDS V;
CREATE CLASS Lover EXTENDS E;
CREATE CLASS Sisiter EXTENDS E;
CREATE CLASS Brother EXTENDS E;
CREATE CLASS Employee EXTENDS E;
CREATE CLASS Work EXTENDS E;
CREATE VERTEX Preson SET name="小朱",sex="男",age="25",company="Lianjia";
CREATE VERTEX Preson SET name="小刘",sex="女",age="23";
CREATE VERTEX Preson SET name="小田",sex="女",age="27";
CREATE VERTEX Company SET name="Lianjia";
CREATE VERTEX Preson SET name="小马",sex="男",age="29",company="Lianjia";
CREATE VERTEX Preson SET name="小龚",sex="男",age="28",company="Lianjia";
CREATE VERTEX Preson SET name="小微",sex="女",age="24",company="Lianjia";
CREATE VERTEX Project SET name="PROJECT-1",type='JAVA',starttime='2016/01/01';
CREATE VERTEX Project SET name="PROJECT-2",type='JAVA',starttime='2016/01/01';
CREATE VERTEX Project SET name="PROJECT-3",type='JAVA',starttime='2016/01/01';
-- 创建情侣关系
CREATE EDGE Lover FROM (select from Preson where name='小朱') TO (select from Preson where name='小刘');
CREATE EDGE Lover FROM (select from Preson where name='小刘') TO (select from Preson where name='小朱');
-- 创建姐弟关系
CREATE EDGE Sisiter FROM (select from Preson where name='小朱') TO (select from Preson where name='小田');
CREATE EDGE Brother FROM (select from Preson where name='小田') TO (select from Preson where name='小朱');
-- 创建雇佣关系
CREATE EDGE Employee FROM (select from Preson where company='Lianjia') TO (select from Company where name ='Lianjia');
-- 创建项目关系
CREATE EDGE Work FROM (select from Preson where name in ['小朱','小马','小微']) TO (select from Project where name='PROJECT-1');
CREATE EDGE Work FROM (select from Preson where name in ['小朱','小马','小微','小龚']) TO (select from Project where name='PROJECT-2');
CREATE EDGE Work FROM (select from Preson where name in ['小朱','小马','小龚']) TO (select from Project where name='PROJECT-3');
```

**案例2：Hive表血缘关系**
```sql
-- CLASS设计：
CREATE CLASS hivetable_source_e EXTENDS E;
CREATE CLASS hivetable_v EXTENDS V;
-- PROPERTY设计：
  -- 点的属性设计：
 CREATE PROPERTY hivetable_v.db_name String 
 CREATE PROPERTY hivetable_v.table_name String 
 CREATE PROPERTY hivetable_v.last_references_datetime datetime
 CREATE PROPERTY hivetable_v.refer_num INTEGER
 CREATE PROPERTY hivetable_v.creator String
 CREATE PROPERTY hivetable_v.create_datetime datetime
 CREATE PROPERTY hivetable_v.update_datetime datetime
  -- 边的属性设计：
 CREATE PROPERTY hivetable_source_e.link_num INTEGER
 CREATE PROPERTY hivetable_source_e.create_datetime datetime
 CREATE PROPERTY hivetable_source_e.update_datetime datetime
-- INDEX设计:
CREATE INDEX hivetable_v.db_table ON hivetable_v (db_name,table_name) UNIQUE
-- VERTEX设计：
CREATE VERTEX hivetable_v SET db_name="test_db",table_name="source_table",last_references_datetime="2020-09-21 10:20:20",refer_num=1,creator="qjj",create_datetime="2020-09-20 10:15:15",update_datetime="2020-09-20 11:10:15";
CREATE VERTEX hivetable_v SET db_name="test_db",table_name="target_table",last_references_datetime="2020-09-21 10:20:20",refer_num=1,creator="qjj",create_datetime="2020-09-20 10:15:15",update_datetime="2020-09-20 11:10:15";
-- EDGE设计：
CREATE EDGE hivetable_source_e FROM (select from hivetable_v where db_name='test_db' and table_name="target_table") TO (select from hivetable_v where db_name='test_db' and table_name="source_table");
-- 更新边连接次数：(用in代替=；=不能查出结果)
UPDATE hivetable_source_e INCREMENT link_num = 1 where in IN (select from hivetable_v where db_name='test_db' and table_name="target_table") and out IN (select from hivetable_v where db_name='test_db' and table_name="source_table");
```

**案例3：商场销售场景下的图数据库应用实践**
[商场销售场景下的图数据库应用实践](https://blog.csdn.net/clj198606061111/article/details/82314459)

### OrientDB索引
SB-Tree Index：从其他索引类型中获得的特性的良好组合，持久的，支持事务，支持范围查询，默认索引
Hash Index：类似HashMap，消耗资源少，查询速度快，持久的，支持事务，不支持范围查询
Auto Sharding Index：提供一个DHT实现；不支持范围查询
Lucene Full Text Index：全文索引，不能索引其他类型，持久的，支持事务，支持范围查询
Lucene Spatial Index：空间索引，不能索引其他类型，持久的，支持事物，支持范围查询
OridenDB索引使用参考了官方文档**[OrientDB-Indexes](http://www.orientdb.org/docs/3.0.x/indexing/Indexes.html)**

### 优化数据库
OrientDB支持轻量级边，这意味着数据实体之间的直接关系。 简单来说，它是一个场到场的关系。 OrientDB提供了不同的方法来优化数据库。 它支持将规则边转换为轻量边。
OPTMIZE DATABASE [-lwedges] [-noverbose]   # 其中lwedges将规则边转换为轻量边，noverbose禁用输出

### WebUI
OrientDB的WebUI可以运行查询数据、将点边依赖关系图形化显示、管理点边属性Schema、管理权限、管理函数和管理库表等功能。

### 性能调优与压测
官方给出的调优方案：[Performance-Tuning](http://www.orientdb.org/docs/3.0.x/tuning/Performance-Tuning.html)
参考调优方案：[OrientDB性能调优](https://www.w3cschool.cn/orientdb/orientdb_performance_tuning.html)
官方给出的压测方案：[Stress-Test-Tool](http://www.orientdb.org/docs/3.0.x/misc/Stress-Test-Tool.html)

## 参考
[OrientDB Manual 3.0.x](http://www.orientdb.org/docs/3.0.x/)
[越来越火的图数据库究竟是什么](https://www.cnblogs.com/mantoudev/p/10414495.html)
[聊聊何为图数据库和图数据库的小知识](https://zhuanlan.zhihu.com/p/79484631)
[图数据库OrientDB-基础篇](https://blog.csdn.net/jinnee/article/details/70224512)
[图数据库orientDB（1-2）例子](https://www.cnblogs.com/lexiaofei/p/6672778.html)
[OrientDB 教程](https://www.w3cschool.cn/orientdb/)
