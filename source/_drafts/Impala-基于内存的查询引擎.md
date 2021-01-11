---
title: Impala-基于内存的查询引擎
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
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Impala/Impala-cover.jpg
date: 2021-01-11 20:18:30
---
# Impala基于内存的大数据查询引擎

## Impala简介  
&emsp;&emsp;000
&emsp;&emsp;**同类计算引擎对比**
| 分类 | 数据模型 | 优势 | 劣势 | 举例 |
| :----: | :----: | :----: | :----: | :----: |
| 键值数据库 | 哈希表 | 查找速度快 | 数据无结构化 | Redis |
| 列式数据存储 | 列式数据 | 查找快可扩展高压缩 | 功能相对受限 | HBase |
| 文档型数据库 | JSON | 表结构可变，无需预先定义 | 查询性能不高、缺乏统一的查询语法 | MongoDB |
| 图数据库 | 节点和关系组成的图 | 可利用图结构相关算法(最短路径、节点度关系查找等) | 可能需要对整个图做计算、不利于图数据分布存储 | Neo4j、JanusGraph、OrientDB |
https://www.cnblogs.com/jins-note/p/9513448.html


## Impala优缺点
https://www.cnblogs.com/sdhzdtwhm/p/9293935.html
## Impala原理

https://zhuanlan.zhihu.com/p/87020775
https://blog.csdn.net/wyz0516071128/article/details/81194712

## 参考
[OrientDB Manual 3.0.x](http://www.orientdb.org/docs/3.0.x/)
[越来越火的图数据库究竟是什么](https://www.cnblogs.com/mantoudev/p/10414495.html)
[聊聊何为图数据库和图数据库的小知识](https://zhuanlan.zhihu.com/p/79484631)
[图数据库OrientDB-基础篇](https://blog.csdn.net/jinnee/article/details/70224512)
[图数据库orientDB（1-2）例子](https://www.cnblogs.com/lexiaofei/p/6672778.html)
[OrientDB 教程](https://www.w3cschool.cn/orientdb/)
