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
Alluxio 是世界上第一个虚拟的分布式存储系统，以内存速度统一了数据访问。 它为计算框架和存储系统构建了桥梁，使应用程序能够通过一个公共接口连接到许多存储系统。 Alluxio 以内存为中心的架构使得数据的访问速度能比现有方案快几个数量级,为大数据软件栈带来了显著的性能提升  

在大数据生态系统中，Alluxio 位于数据驱动框架或应用（如 Apache Spark、Presto、Tensorflow、Apache HBase、Apache Hive 或 Apache Flink）和各种持久化存储系统（如 Amazon S3、Google Cloud Storage、OpenStack Swift、GlusterFS、HDFS、IBM Cleversafe、EMC ECS、Ceph、NFS 和 Alibaba OSS）之间。 Alluxio 统一了存储在这些不同存储系统中的数据，为其上层数据框架提供统一的客户端 API 和全局命名空间。

Alluxio改善了传统的数据湖安全隐患高,数据管理难度大,永久数据副本代价高,数据创建和分析之间的延迟,资源密集等问题,Alluxio可以看作是一个虚拟且高速的数据湖,Alluxio可以按需快速本地访问重要和频繁使用的数据，不需要维护一个永久的副本。缓存的只是数据块，而不是整个文件。企业可以通过将更多的数据迁移到商用存储中来减少存储开销。  

Alluxio与Hadoop兼容,现有的数据分析应用，如Spark和MapReduce程序，可以不修改代码直接在Alluxio上运行。  

#### Alluxio优势
1. **内存速度 I/O**:Alluxio 能够用作分布式共享缓存服务，这样与 Alluxio 通信的计算应用程序可以透明地缓存频繁访问的数据（尤其是从远程位置），以提供内存级 I/O 吞吐率。
2. **简化云存储和对象存储接入**:与传统文件系统相比，云存储系统和对象存储系统使用不同的语义，这些语义对性能的影响也不同于传统文件系统。常见的文件系统操作（如列出目录和重命名）通常会导致显著的性能开销。当访问云存储中的数据时，应用程序没有节点级数据本地性或跨应用程序缓存。将 Alluxio 与云存储或对象存储一起部署可以缓解这些问题，因为这样将从 Alluxio 中检索读取数据，而不是从底层云存储或对象存储中检索读取。
3. **简化数据管理**:Alluxio 提供对多数据源的单点访问。除了连接不同类型的数据源之外，Alluxio 还允许用户同时连接到不同版本的同一存储系统，如多个版本的 HDFS，并且无需复杂的系统配置和管理。
4. **应用程序部署简易**:Alluxio 管理应用程序和文件或对象存储之间的通信，将应用程序的数据访问请求转换为底层存储接口的请求。Alluxio 与 Hadoop 兼容，现有的数据分析应用程序，如 Spark 和 MapReduce 程序，无需更改任何代码就能在 Alluxio 上运行。

#### Alluxio的一些特征:  
[超大规模工作负载](https://www.alluxio.io/blog/store-1-billion-files-in-alluxio-20/):支持超大规模工作负载并具有HA高可用性  
[灵活的API](https://www.alluxio.io/blog/store-1-billion-files-in-alluxio-20/) :使用HDFS、S3、Java、RESTful或POSIX为基础的API，集成计算框架Spark、Presto、Tensorflow、HIVE和更多的计算框架  
[智能数据缓存和分层](https://docs.alluxio.io/os/user/stable/en/advanced/Alluxio-Storage-Management.html) : 使用包括内存在内的本地存储，来充当分布式缓冲缓存区,这个在用户应用程序和各种底层存储之间的快速数据层可以很大程度上改善I/O性能。
[内置](https://docs.alluxio.io/ee/user/stable/en/advanced/Policy-Driven-Data-Management.html) : 为持久性，跨存储数据迁移和分布式负载提供高度可定制的数据策略   
[存储系统接口](https://docs.alluxio.io/os/user/stable/en/ufs/S3.html) : 通过一系列接口集成HDFS，S3，Azure Blob Store，Google Cloud Store等存储系统  
[透明统一的命名空间](https://docs.alluxio.io/os/user/stable/en/advanced/Namespace-Management.html) : 多个存储系统安装到一个统一的名称空间中，不需要创建永久数据副本 
[安全性](https://docs.alluxio.io/os/user/stable/en/advanced/Security.html) : 通过内置审核、基于角色的访问控制、LDAP、活动目录和加密通信，提供数据保护  
[监控和管理](https://docs.alluxio.io/os/user/stable/en/basic/Web-Interface.html) : 提供了用户友好的Web界面和命令行工具，允许用户监控和管理集群  
[企业级高可用和跨区域性](https://docs.alluxio.io/os/user/stable/en/advanced/Tiered-Locality.html) : 跨区域和区域的自适应复制，以最大限度地提高性能和可用性  

__觉得上面特征太啰嗦?下面我们挑重点!敲黑板!!!:__ 
[全局命名空间管理](https://docs.alluxio.io/os/user/stable/en/advanced/Namespace-Management.html)：Alluxio 能够对多个独立存储系统提供单点访问，无论这些存储系统的物理位置在何处。这提供了所有数据源的统一视图和应用程序的标准接口。  
[智能缓存](https://docs.alluxio.io/os/user/stable/en/advanced/Alluxio-Storage-Management.html)智能缓存：Alluxio 集群能够充当底层存储系统中数据的读写缓存。可配置自动优化数据放置策略，以实现跨内存和磁盘（SSD/HDD）的性能和可靠性。缓存对用户是透明的，使用缓冲来保持与持久存储的一致性。  
[服务器端 API 转换](https://docs.alluxio.io/os/user/stable/en/ufs/S3.html)：Alluxio 能够透明地从标准客户端接口转换到任何存储接口。Alluxio 负责管理应用程序和文件或对象存储之间的通信，从而消除了对复杂系统进行配置和管理的需求。文件数据可以看起来像对象数据，反之亦然。  
### Alluxio原理  
![alt Alluxio-2](https://vi1.xiu123.cn/live/2019/09/26/23/1002v1569511241325155301_b.jpg)  
#### Alluxio的三个核心组件:
**Master:** 负责管理文件和对象元数据
**Worker:** 管理节点的本地空间，以及管理文件和对象块以及与下面的存储系统的接口
**Client:** 允许分析和AI/ML应用程序与Alluxio连接和交互  
Alluxio使用了**单Master**和**多Worker**的架构,<u>Master和Worker一起组成了Alluxio的服务端，它们是系统管理员维护和管理的组件</u>,Client通常是应用程序，如Spark或MapReduce作业，或者Alluxio的命令行用户。Alluxio用户一般只与Alluxio的Client组件进行交互。  









喜欢看源码的小伙伴可以戳这里哟->[Alluxio源码入口](https://github.com/Alluxio/alluxio)


### 安装和部署Alluxio  
[下载Alluxio压缩包](https://www.alluxio.io/download/)并上传到NN所在集群  
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