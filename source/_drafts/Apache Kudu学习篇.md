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
date: 2020-07-04 12:26:08
---
# Apache Kudu  

## 前言
  离线大数据分析处理固然是大数据整个业务流程中必不可少的部分，但它已经很难满足当前的业务需求，数据时效性也越来越受到从业者及业务部门的重视，所以Flink，Storm等实时计算框架以及HBase存储开始被广泛使用，但仍然面临一个问题，在既需要随机读写又需要OLAP批量数据分析的场景下，还没有比较好的解决方案，Kudu应运而生，它的定位介于HDFS和HBase之间，是一个**既支持随机读写又支持OLAP分析的存储引擎**。本篇博客主要研究一下Kudu，对其应用场景，架构原理及基本使用做一个总结，方便后续回看。
## Kudu介绍  
### 适用场景
* Apache Kudu专为快速变化的数据进行快速分析的场景设计的
* 要求数据实时性高（如实时决策，实时更新）的场景
* 数据操作需要支持事物ACID特性
* 同时高效运行顺序读写和随机读写任务的场景
* 支持分布式高性能，高可用，可横向扩展的场景
* Kudu作为持久层与Impala紧密集成的场景
* 解决HBase大批量数据SQL分析性能不佳的场景

### 特点及缺点
1. 特点
  * 基于列式存储
  * 快速顺序读写
  * 类似HBase使用的[LSM树]()以支持高效随机读写
  * 查询性能和耗时较稳定
  * 不依赖Zookeeper
  * 有表结构，需要定义Schema，需要定义唯一键
  * 支持增删列,行级ACID
  * 查询时先查询内存再查询磁盘
  * 自己存储数据，不依赖HDFS
2. 缺点
  * 暂不支持二级索引
  * 不支持BloomFilter优化join
  
  
  
  
## Kudu架构原理



### Raft算法介绍

### LSM树



## Kudu使用  

``` java

```

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


