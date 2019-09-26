---
title: Alluxio - 一个基于内存的分布式存储系统
author: 佳境
avatar: 'https://wx1.sinaimg.cn/large/006bYVyvgy1ftand2qurdj303c03cdfv.jpg'
authorLink: www.shmily-qjj.github.io
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true  
date: 2019-9-26 22:16:00
tags:
  - 大数据
  - Alluxio
keywords: Alluxio
description: Alluxio框架学习
photos: http://r.photo.store.qq.com/psb?/V10aWFGB3ChSVt/gTdB5VZVD3n1G9mwn*nGk.F3ramDY4MDnk44dJkecO0!/r/dL4AAAAAAAAA
---
![alt Alluxio-1](https://vi2.xiu123.cn/live/2019/09/24/22/1002v1569336488318656852_b.jpg)   
### 什么是Alluxio  
Alluxio 是世界上第一个虚拟的分布式存储系统，以内存速度统一了数据访问。 它为计算框架和存储系统构建了桥梁，使应用程序能够通过一个公共接口连接到许多存储系统。 Alluxio 以内存为中心的架构使得数据的访问速度能比现有方案快几个数量级。  

在大数据生态系统中，Alluxio 位于数据驱动框架或应用（如 Apache Spark、Presto、Tensorflow、Apache HBase、Apache Hive 或 Apache Flink）和各种持久化存储系统（如 Amazon S3、Google Cloud Storage、OpenStack Swift、GlusterFS、HDFS、IBM Cleversafe、EMC ECS、Ceph、NFS 和 Alibaba OSS）之间。 Alluxio 统一了存储在这些不同存储系统中的数据，为其上层数据驱动应用提供统一的客户端 API 和全局命名空间。


#### Alluxio优势
1. **内存速度 I/O**:Alluxio 能够用作分布式共享缓存服务，这样与 Alluxio 通信的计算应用程序可以透明地缓存频繁访问的数据（尤其是从远程位置），以提供内存级 I/O 吞吐率。
2. **简化云存储和对象存储接入**:与传统文件系统相比，云存储系统和对象存储系统使用不同的语义，这些语义对性能的影响也不同于传统文件系统。常见的文件系统操作（如列出目录和重命名）通常会导致显著的性能开销。当访问云存储中的数据时，应用程序没有节点级数据本地性或跨应用程序缓存。将 Alluxio 与云存储或对象存储一起部署可以缓解这些问题，因为这样将从 Alluxio 中检索读取数据，而不是从底层云存储或对象存储中检索读取。
3. **简化数据管理**:Alluxio 提供对多数据源的单点访问。除了连接不同类型的数据源之外，Alluxio 还允许用户同时连接到不同版本的同一存储系统，如多个版本的 HDFS，并且无需复杂的系统配置和管理。
4. **应用程序部署简易**:Alluxio 管理应用程序和文件或对象存储之间的通信，将应用程序的数据访问请求转换为底层存储接口的请求。Alluxio 与 Hadoop 兼容，现有的数据分析应用程序，如 Spark 和 MapReduce 程序，无需更改任何代码就能在 Alluxio 上运行。

#### Alluxio的一些特征:  
[超大规模工作负载](https://www.alluxio.io/blog/store-1-billion-files-in-alluxio-20/):支持超大规模工作负载并具有HA高可用性  
[灵活的API](https://www.alluxio.io/blog/store-1-billion-files-in-alluxio-20/) :使用HDFS、S3、Java、RESTful或POSIX为基础的API，集成计算框架Spark、Presto、Tensorflow、HIVE和更多的计算框架  
[智能数据缓存和分层](https://docs.alluxio.io/os/user/stable/en/advanced/Alluxio-Storage-Management.html) : 根据数据拓扑和负载，利用接近计算的存储介质来优化数据放置  
[内置](https://docs.alluxio.io/ee/user/stable/en/advanced/Policy-Driven-Data-Management.html) : 为持久性，跨存储数据迁移和分布式负载提供高度可定制的数据策略   
[存储系统接口](https://docs.alluxio.io/os/user/stable/en/ufs/S3.html) : 通过一系列接口集成HDFS，S3，Azure Blob Store，Google Cloud Store等存储系统  
[透明统一的命名空间](https://docs.alluxio.io/os/user/stable/en/advanced/Namespace-Management.html) : 多个存储系统安装到一个统一的名称空间中，以进行读写工作负载  
[安全性](https://docs.alluxio.io/os/user/stable/en/advanced/Security.html) : 通过内置审核、基于角色的访问控制、LDAP、活动目录和加密通信，提供数据保护  
[监控和管理](https://docs.alluxio.io/os/user/stable/en/basic/Web-Interface.html) : 提供了用户友好的Web界面和命令行工具，允许用户监控和管理集群  
[企业级高可用和跨区域性](https://docs.alluxio.io/os/user/stable/en/advanced/Tiered-Locality.html) : 跨区域和区域的自适应复制，以最大限度地提高性能和可用性  

### Alluxio原理  
![alt Alluxio-2](https://vi1.xiu123.cn/live/2019/09/26/23/1002v1569511241325155301_b.jpg)  

#### Alluxio的三个核心组件:
Master，负责管理文件和对象元数据
Worker，管理节点的本地空间，以及管理文件和对象块以及与下面的存储系统的接口
Client，允许分析和AI/ML应用程序与Alluxio连接和交互

Alluxio是基于内存的,抽象底层持久存储系统中的文件和对象，并为计算应用程序提供共享数据访问层。Alluxio可以应用于任何持久存储系统（如amazon s3、microsoft azure object store、apache hdfs或openstack swift）和计算框架（如apache spark、presto或hadoop mapreduce）之间,使计算框架能够通过一个公共接口连接到许多存储系统。







喜欢看源码的小伙伴可以戳这里哟->[Alluxio源码入口](https://github.com/Alluxio/alluxio)


### 安装和部署Alluxio  
[下载](https://www.alluxio.io/download/)Alluxio的压缩包并上传到NN所在集群  
``` bash
#解压并进入安装目录
tar -zxvf alluxio-2.0.1-bin.tar.gz -C /opt/module/
cd /opt/module/alluxio-2.0.1
cp conf/alluxio-site.properties.template conf/alluxio-site.properties

# 设置必要参数
vim conf/alluxio-site.properties
alluxio.master.hostname=192.168.1.101 # NameNode所在机器
# 具体配置参数https://docs.alluxio.io/os/user/stable/cn/reference/Properties-List.html
#这里列出Alluxio与Hadoop整合的参数:




```

More info: [Server](https://hexo.io/docs/server.html)

### Generate static files

``` bash
$ hexo generate
```

More info: [Generating](https://hexo.io/docs/generating.html)

### Deploy to remote sites

``` bash
$ hexo deploy
```

More info: [Deployment](https://hexo.io/docs/deployment.html)