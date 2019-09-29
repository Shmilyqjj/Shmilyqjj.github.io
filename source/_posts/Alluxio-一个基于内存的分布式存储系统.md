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
date: 2019-9-27 22:16:00
tags:
  - 大数据
  - Alluxio
keywords: Alluxio
description: Alluxio干货分享
photos: http://r.photo.store.qq.com/psb?/V10aWFGB3ChSVt/gTdB5VZVD3n1G9mwn*nGk.F3ramDY4MDnk44dJkecO0!/r/dL4AAAAAAAAA
---
![alt Alluxio-1](https://vi2.xiu123.cn/live/2019/09/24/22/1002v1569336488318656852_b.jpg)   
### 什么是Alluxio  
Alluxio 是世界上第一个虚拟的分布式存储系统，它为计算框架和存储系统构建了桥梁，使计算框架能够通过一个公共接口连接到多个独立的存储系统,使计算与存储隔离。 Alluxio 是内存为中心的架构，以内存速度统一了数据访问速度，使得数据的访问速度能比现有方案快几个数量级,为大数据软件栈带来了显著的性能提升  
![alt Alluxio-3](https://vi3.xiu123.cn/live/2019/09/27/23/1002v1569597084038268730_b.jpg)  
在大数据生态系统中，Alluxio 位于数据驱动框架或应用（如 Apache Spark、Presto、Tensorflow、Apache HBase、Apache Hive 或 Apache Flink）和各种持久化存储系统（如 Amazon S3、Google Cloud Storage、OpenStack Swift、GlusterFS、HDFS、IBM Cleversafe、EMC ECS、Ceph、NFS 和 Alibaba OSS）之间,Alluxio 统一了存储在这些不同存储系统中的数据,为其上层数据框架提供统一的客户端 API和全局命名空间  


#### Alluxio优势  
1. **内存速度 I/O**:Alluxio 能够用作分布式共享缓存服务，这样与 Alluxio 通信的计算应用程序可以透明地缓存频繁访问的数据（尤其是从远程位置）,以提供内存级 I/O 吞吐率。
2. **简化云存储和对象存储接入**:与传统文件系统相比,云存储系统和对象存储系统使用不同的语义,这些语义对性能的影响也不同于传统文件系统。常见的文件系统操作（如列出目录和重命名）通常会导致显著的性能开销。当访问云存储中的数据时，应用程序没有节点级数据本地性或跨应用程序缓存。将 Alluxio 与云存储或对象存储一起部署可以缓解这些问题,因为这样将从Alluxio中检索读取数据,而不是从底层云存储或对象存储中检索读取。
3. **简化数据管理**:Alluxio 提供对多数据源的单点访问,便捷地管理远程的存储系统,并向上层提供统一的命名空间。除了连接不同类型的数据源之外,Alluxio 还允许用户同时连接到不同版本的同一存储系统,如多个版本的 HDFS,并且无需复杂的系统配置和管理。
4. **应用程序部署简易**:Alluxio 管理应用程序和文件或对象存储之间的通信，将应用程序的数据访问请求转换为底层存储接口的请求。Alluxio 与 Hadoop 兼容,现有的数据分析应用程序,如Spark和MapReduce程序,无需更改任何代码就能在Alluxio上运行。
5. **分层存储特性**:综合使用了内存、SSD和磁盘多种存储资源。通过Alluxio提供的LRU、LFU等缓存策略可以保证热数据一直保留在内存中，冷数据则被持久化到level 2甚至level 3的存储设备上
6. **方便迁移可插拔**:Alluxio提供多种易用的API方便将整个系统迁移到Alluxio

#### Alluxio的特征:  
[超大规模工作负载](https://www.alluxio.io/blog/store-1-billion-files-in-alluxio-20/):支持超大规模工作负载并具有HA高可用性  
[灵活的API](https://docs.alluxio.io/os/user/stable/en/compute/Spark.html) :计算框架可使用HDFS、S3、Java、RESTful或POSIX为基础的API来访问Alluxio  
[智能数据缓存和分层](https://docs.alluxio.io/os/user/stable/en/advanced/Alluxio-Storage-Management.html) : 使用包括内存在内的本地存储，来充当分布式缓存,很大程度上改善I/O性能，且缓存对用户透明  
[数据管理](https://docs.alluxio.io/ee/user/stable/en/advanced/Policy-Driven-Data-Management.html) : 通过union UFS方便数据迁移  
[存储系统接口](https://docs.alluxio.io/os/user/stable/en/ufs/S3.html) : 通过一系列接口集成HDFS，S3，Azure Blob Store，Google Cloud Store等存储系统  
[全局命名空间管理](https://docs.alluxio.io/os/user/stable/en/advanced/Namespace-Management.html) : 多个存储系统安装到一个统一的名称空间中，不需要创建永久数据副本  
[安全性](https://docs.alluxio.io/os/user/stable/en/advanced/Security.html) : 通过内置审核、基于角色的访问控制、LDAP、活动目录和加密通信，提供数据保护  
[监控和管理](https://docs.alluxio.io/os/user/stable/en/basic/Web-Interface.html) : 提供了用户友好的Web界面和命令行工具，允许用户监控和管理集群  
[分层次的本地性](https://docs.alluxio.io/os/user/stable/en/advanced/Tiered-Locality.html) : 将更多的读写安排在本地,实现成本和性能的优化

#### Alluxio的应用场景  
1.计算应用需要反复访问远程云端或机房的数据  
2.计算应用需要同时从多个独立的独立存储系统读取数据  
3.多个独立的大数据应用（比如不同的Spark Job）需要高速有效的共享数据  
4.计算框架所在机器内存占用较高,GC频繁,或者任务失败率较高,Alluxio通过数据的OffHeap来缓解



### Alluxio原理  
![alt Alluxio-2](https://vi1.xiu123.cn/live/2019/09/26/23/1002v1569511241325155301_b.jpg)  
#### Alluxio的三个核心组件:
**Master:** 负责管理文件和对象元数据
**Worker:** 管理节点的本地空间，以及管理文件和对象块以及与下面的存储系统的接口
**Client:** 允许分析和AI/ML应用程序与Alluxio连接和交互  
Alluxio使用了**单Master**和**多Worker**的架构,<u>Master和Worker一起组成了Alluxio的服务端，它们是系统管理员维护和管理的组件</u>,Client通常是应用程序，如Spark或MapReduce作业，或者Alluxio的命令行用户。Alluxio用户一般只与Alluxio的Client组件进行交互。  









喜欢看源码的小伙伴可以戳这里哟->[Alluxio源码入口](https://github.com/Alluxio/alluxio)


### 安装和部署Alluxio  
1.[下载Alluxio压缩包](https://www.alluxio.io/download/)并上传到NN所在集群  
2.解压并进入安装目录  
``` bash
tar -zxvf alluxio-2.0.1-bin.tar.gz -C /opt/module/
cd /opt/module/alluxio-2.0.1
cp conf/alluxio-site.properties.template conf/alluxio-site.properties
```
3.设置必要参数
alluxio-env.sh
```bash
ALLUXIO_HOME=/opt/programs/alluxio-1.4.0
ALLUXIO_LOGS_DIR=/opt/programs/alluxio-1.4.0/logs
ALLUXIO_MASTER_HOSTNAME=hadoop1
ALLUXIO_RAM_FOLDER=/mnt/ramdisk
ALLUXIO_UNDERFS_ADDRESS=hdfs://dev-dalu:8020/alluxio
ALLUXIO_WORKER_MEMORY_SIZE=2048MB
JAVA_HOME=/opt/programs/jdk1.7.0_67
```


非高可用
```bash
vim conf/alluxio-site.properties

```
高可用
```bash
vim conf/alluxio-site.properties

```
其他可选参数:[Alluxio配置参数大全](https://docs.alluxio.io/os/user/stable/cn/reference/Properties-List.html)

4.分发
```bash
scp -r /opt/module/alluxio  root@10.2.5.64:/opt/module/alluxio
scp -r /opt/module/alluxio  root@10.2.5.65:/opt/module/alluxio
```

alluxio.master.hostname=192.168.1.101 

#这里列出Alluxio与Hadoop整合的参数:



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