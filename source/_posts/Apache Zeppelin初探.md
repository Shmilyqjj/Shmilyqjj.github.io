---
title: Apache Zeppelin初探
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
  - Zeppelin
keywords: Zeppelin
description: 高性能，高可用的分布式K-V存储平台
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Zeppelin/Zeppelin-cover.jpg
date: 2020-02-11 10:16:00
---
# Apache Zeppelin  
![alt Zeppelin-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Zeppelin/Zeppelin-01.png)  
![alt Zeppelin-02](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Zeppelin/Zeppelin-02.png)  
## 什么是Zeppelin  
Apache Zeppelin是一个高性能，高可用，高可靠的分布式Key-Value存储与**可视化平台**，它是集数据摄取，数据分析，数据可视化与协作于一身的notebook形式的基于Web的工具，支持多种解释器(Interpreter),能广泛支持多种大数据查询引擎和计算引擎(如Spark，Flink，Presto，Kylin...)，多种存储系统(如JDBC数据源，HBase，Elasticsearch，Hive，Neo4j，Alluxio，Ignite...),以及多种脚本语言(如python,scala,R,shell...)和markdown。
  
## Zeppelin优势  
1. **为数据分析与可视化提供便利**[在Zeppelin中以笔记本（notebook）的形式组织和管理交互式数据探索任务，一个笔记本（note）可以包括多个段（paragraph）。段是进行数据分析的最小单位，即在段中可以完成数据分析代码的编写以及结果的可视化查看]
2. **为多人协作提供便利**[可以共享你的notebook，使他人也能看到你的数据分析笔记和结果]
3. **提供权限管理**[可以管理notebook的权限以及执行者是否对已有数据有修改权限]
4. **支持多种查询计算引擎**[兼容多种主流大数据查询，计算引擎，使得数据分析更加方便，数据分析人员可以对底层无感知]
5. **为临时获取某些数据提供便利**[有需要临时获取一些数据的需求，通过配置Interpreter即可]
6. **配置与部署简单**[已完全支持的组件只需简单填写解释器参数即可使用，支持安装第三方解释器]
7. **支持简单任务调度**[Linux Crontab调度器功能]

## Zeppelin适用场景  
1. 多个部门需要在大数据平台取数据做分析的场景
2. 需要多种查询引擎做数据分析的场景
3. 需要对多种数据源进行数据可视化的场景
4. 需要多人协作的场景
5. 数据平台与数据分析分离，对数据分析人员无感知的场景

## Zeppelin原理  
[官方Docs](http://zeppelin.apache.org/docs)


详细深入了解: [Apache Zeppelin官网](http://zeppelin.apache.org/)