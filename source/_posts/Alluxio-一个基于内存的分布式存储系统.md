---
title: Alluxio - 一个基于内存的分布式存储系统
author: 佳境
avatar: 'https://wx1.sinaimg.cn/large/006bYVyvgy1ftand2qurdj303c03cdfv.jpg'
authorLink: Shmilyqjj.github.io
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories: 技术
comments: true  
date: 2019-9-27 22:16:00
tags:
  - 大数据
  - Alluxio
keywords: Alluxio
description: Alluxio干货分享
photos: https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Category_Images/technology/tech05.jpg
---
![alt Alluxio-1](https://vi2.xiu123.cn/live/2019/09/24/22/1002v1569336488318656852_b.jpg)   
### 什么是Alluxio  
Alluxio 是世界上第一个虚拟的分布式存储系统，它为计算框架和存储系统构建了桥梁，使计算框架能够通过一个公共接口连接到多个独立的存储系统,使计算与存储隔离。 Alluxio 是内存为中心的架构，以内存速度统一了数据访问速度，使得数据的访问速度能比现有方案快几个数量级,为大数据软件栈带来了显著的性能提升  
![alt Alluxio-3](https://vi3.xiu123.cn/live/2019/09/27/23/1002v1569597084038268730_b.jpg)  
在大数据生态系统中，Alluxio 位于数据驱动框架或应用（如 Apache Spark、Presto、Tensorflow、Apache HBase、Apache Hive 或 Apache Flink）和各种持久化存储系统（如 Amazon S3、Google Cloud Storage、OpenStack Swift、GlusterFS、HDFS、IBM Cleversafe、EMC ECS、Ceph、NFS 和 Alibaba OSS）之间,Alluxio 统一了存储在这些不同存储系统中的数据,为其上层数据框架提供统一的客户端API和全局命名空间  


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
Alluxio使用了**单Master**和**多Worker**的架构,<u>Master和Worker一起组成了Alluxio的服务端，它们是系统管理员维护和管理的组件</u>,Client通常是应用程序，如Spark或MapReduce作业，或者Alluxio的命令行用户。Alluxio用户一般只与Alluxio的Client组件进行交互。  
- - -
![alt Alluxio-8](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Alluxio/Alluxio-8.png)
**Master:** 负责管理整个集群的全局元数据并响应Client对文件系统的请求。在Alluxio文件系统内部，每一个文件被划分为一个或多个数据块(block)，并以数据块为单位存储在Worker中。Master节点负责管理文件系统的元数据(如文件系统的inode树、文件到数据块的映射)、数据块的元数据(如block到Worker的位置映射)，以及Worker元数据(如集群当中每个Worker的状态)。所有Worker定期向Master发送心跳消息汇报自己状态，以维持参与服务的资格。Master通常不主动与其他组件通信，只通过RPC服务被动响应请求，同时Master还负责实时记录文件系统的日志(Journal)，以保证集群重启之后可以准确恢复文件系统的状态。高可用的Alluxio集群的Master会分为Primary Master和Secondary Master，正常情况下前者状态为Active后者状态为StandBy，Secondary Master需要将文件系统日志写入持久化存储，从而实现在多Master间共享日志，实现Master主从切换时可以恢复对外服务的Master的状态信息。Alluxio集群中可以有多个Secondary Master，每个Secondary Master定期压缩文件系统日志并生成Checkpoint以便快速恢复，并在切换成Primary Master时重播前Primary Master写入的日志。Secondary Master不处理来自任何Alluxio组件的任何请求。  
- - -
![alt Alluxio-9](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Alluxio/Alluxio-9.png)
**Worker:** Alluxio Master只负责响应Client对文件系统元数据的操作，而具体文件数据传输的任务由Worker负责，如图，每个Worker负责管理分配给Alluxio的本地存储资源(如RAM,SSD,HDD),记录所有被管理的数据块的元数据，并根据Client对数据块的读写请求做出响应。
* * *
**Client:** 允许分析和AI/ML应用程序与Alluxio连接和交互  



#### Alluxio工作机制
一个完整的Alluxio集群部署在逻辑上包括master、worker、client及底层存储(UFS)。master和worker进程通常由集群管理员维护和管理，它们通过RPC通信相互协作，从而构成了Alluxio服务端。而应用程序则通过Alluxio Client来和Alluxio服务交互，读写数据或操作文件、目录。一般Alluxio Client需要被放置于使用Alluxio服务的应用进程内部或classpath上。  
![alt Alluxio-7](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Alluxio/Alluxio-7.png)  









喜欢看源码的小伙伴可以戳这里哟->[Alluxio源码入口](https://github.com/Alluxio/alluxio)


### 安装和部署Alluxio  
1.[下载Alluxio压缩包](https://www.alluxio.io/download/)并上传到NN所在集群  
2.解压并进入安装目录  
``` bash
 tar -zxvf alluxio-2.0.1-bin.tar.gz -C /opt/module/
 cd /opt/module/alluxio-2.0.1
 cp conf/alluxio-site.properties.template conf/alluxio-site.properties
 cp conf/alluxio-env.sh.template conf/alluxio-env.sh
```
3.设置必要参数
**conf/alluxio-env.sh**  
```bash
 vim conf/alluxio-env.sh
 ALLUXIO_HOME=/opt/module/alluxio-2.0.1
 ALLUXIO_LOGS_DIR=/opt/module/alluxio-2.1.0/logs
 ALLUXIO_MASTER_HOSTNAME=hadoop101 
 ALLUXIO_RAM_FOLDER=/mnt/ramdisk
 ALLUXIO_UNDERFS_ADDRESS=hdfs://hadoop101:9000/alluxio # 底层存储系统的位置
 ALLUXIO_WORKER_MEMORY_SIZE=2048MB
 JAVA_HOME=/opt/module/jdk1.8.0_161
```

**conf/alluxio-site.properties**
**普通集群参数配置**
```bash
 vim conf/alluxio-site.properties
 # Common properties
 alluxio.master.hostname=hadoop101
 alluxio.master.mount.table.root.ufs=hdfs://192.168.1.101:9000/alluxio
 alluxio.underfs.hdfs.configuration=/opt/module/hadoop-2.7.2/etc/hadoop/core-site.xml:/opt/module/hadoop-2.7.2/etc/hadoop/hdfs-site.xml
 # Worker properties
 alluxio.worker.memory.size=512MB
 alluxio.worker.tieredstore.levels=1
 alluxio.worker.tieredstore.level0.alias=MEM
 alluxio.worker.tieredstore.level0.dirs.path=/mnt/ramdisk

 vim conf/masters 
 hadoop101

 vim conf/workers
 hadoop102
 hadoop103

 #测试部署是否成功
 bin/alluxio runTests  # 如果出现Passed the test则说明部署成功
 bin/alluxio-stop.sh all  # 关闭集群

 # 打开Alluxio服务
 bin/alluxio-start.sh master  
 alluxio-start.sh workers NoMount
 访问Master节点的WEB UI: hadoop101:19999
 访问Worker节点的WEB UI: hadoop102:30000
```  
出现类似以下界面即为部署成功
![alt Alluxio-4](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Alluxio/Alluxio-4.jpg)  
此时可以通过命令**alluxio fsdamin report**来查看集群状态
![alt Alluxio-6](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Alluxio/Alluxio-6.jpg)  

**高可用集群参数配置**  
高可用(HA)通过支持同时运行多个master来保证服务的高可用性，多个master中有一个master被选为primary master作为所有worker和client的通信首选，其余master为备选状态(StandBy)，它们通过和primary master共享日志来维护同样的文件系统元数据，并在primary master失效时迅速接替其工作(master主从切换过程中，客户端可能会出现短暂的延迟或瞬态错误)  
搭建高可用集群前的准备:  
①确保Zookeeper服务已经运行  
②一个单独安装的可靠的共享日志存储系统(可用HDFS或S3等系统)
首先在**Master**节点上设置:
```bash
 vim conf/alluxio-site.properties
 # Common properties
 alluxio.master.hostname=hadoop101  # 另一台master hadoop102    # 该项为本机外部可见地址(对Alluxio集群中其他节点可见的接口地址而非localhost等)
 alluxio.underfs.hdfs.configuration=/opt/module/cdh-hadoop-2.7.2/etc/hadoop/core-site.xml:/opt/module/cdh-hadoop-2.7.2/etc/hadoop/hdfs-site.xml
 # Worker properties
 alluxio.worker.memory.size=512MB
 alluxio.worker.tieredstore.levels=1
 alluxio.worker.tieredstore.level0.alias=MEM
 alluxio.worker.tieredstore.level0.dirs.path=/mnt/ramdisk
 # HA properties
 alluxio.zookeeper.enabled=true
 alluxio.zookeeper.address=hadoop101:2181,hadoop102:2181,hadoop103:2181
 alluxio.master.journal.folder=hdfs://192.168.1.101:9000/alluxio/master-logs  # 指定正确的共享日志存储

 vim masters   # 务必在masters中列出所有master的地址
 hadoop101
 hadoop102
```  
在**Worker**节点上设置:
```bash
 # HA properties
 alluxio.zookeeper.enabled=true
 alluxio.zookeeper.address=hadoop101:2181,hadoop102:2181,hadoop103:2181
 alluxio.worker.memory.size=512MB
 alluxio.worker.tieredstore.levels=1
 alluxio.worker.tieredstore.level0.alias=MEM
 alluxio.worker.tieredstore.level0.dirs.path=/mnt/ramdisk

 # Worker无需设置alluxio.master.hostname和alluxio.master.journal.folder
 # Client节点只需设置alluxio.zookeeper.enabled和alluxio.zookeeper.address即可

 # 测试部署是否成功
 bin/alluxio-start.sh all  
 alluxio fsadmin report   
 alluxio runTests    # 如果出现Passed the test则说明部署成功

 # 测试高可用模式的自动故障处理: (假设此时hadoop101位primary master)
 ssh hadoop101
 jps | grep AlluxioMaster
 kill -9 <AlluxioMaster PID>
 alluxio fs leader  # 显示新的primary Master(可能需要等待一小段时间选举)
```

4.分发
```bash
scp -r /opt/module/alluxio/conf  root@hadoop102:/opt/module/alluxio
scp -r /opt/module/alluxio/conf  root@hadoop103:/opt/module/alluxio
```  

至此，Alluxio服务部署完毕,一些关于优化和细节的参数在**Alluxio原理**部分中涉及到,也可查阅[Alluxio配置参数大全](https://docs.alluxio.io/os/user/stable/cn/reference/Properties-List.html)  

### Alluxio常用命令  
以下是常用的Alluxio Shell操作命令,就当是个速查表吧!  
``` bash
#文件基本操作
 alluxio fs cat <path/file>  # 打开文件
 alluxio fs ls [-d|-f|-p|-R|-h|--sort=option|-r] <path>  #查看目录
 alluxio fs copyFromLocal [--thread <num>] [--buffersize <bytes>] <src> <remoteDst> # 从本地上传文件到Alluxio
 alluxio fs copyToLocal [--buffersize <bytes>]  <src> <localDst>   #从Alluxio载文件到本地
 alluxio fs count <path>  # 统计Alluxio目录的文件数,文件夹数和总大小
 alluxio fs du [-h|-s|--memory] <path>  # 文件大小
 alluxio fs cp [-R] [--buffersize <bytes>] <src> <dst>   #复制文件
 alluxio fs mv <src> <dst>   # 移动文件
 alluxio fs rm [-R] [-U] [--alluxioOnly] <path>    # 删除文件
 alluxio fs mkdir <path1> [path2] ... [pathn]  # 创建文件夹
 alluxio fs touch <path>  #创建一个空文件
 alluxio fs setTtl [--action delete|free] <path> <time to live>  # 设置一个文件的TTL时间
 alluxio fs unsetTtl <path>  # 删除文件的TTL值
 alluxio fs checksum <Alluxio path>  # 得到文件的MD5值
 alluxio fs stat <path>  # 显示文件路径信息
 alluxio fs tail <path>  # 显示文件最后1KB的内容
 alluxio fs location <path>  # 输出包含某个文件数据的主机,使用location命令可以调试数据局部性
 alluxio fs help <command> # 查看命令介绍和用法
 alluxio fs distributedMv <src> <dst> # 并行移动文件或目录
 alluxio fs distributedCp <src> <dst> # 并行复制文件或目录
 alluxio fs distributedLoad [--replication <num>] <path>  # 在alluxio空间中加载文件或目录，使其驻留在内存中

#与底层存储的交互操作
 alluxio fs load [--local] <path>  # load命令可为数据分析编排数据,加快数据分析的效率,load命令将底层文件系统中的数据载入到Alluxio中,如果运行该命令的机器上正在运行一个Alluxio worker,那么数据将移动到该worker上,否则数据会被随机移动到一个worker上。 如果该文件已经存在在Alluxio中,设置了--local选项,并且有本地worker,则数据将移动到该worker上。否则该命令不进行任何操作。如果该命令的目标是一个文件夹,那么其子文件和子文件夹会被递归载入。
 alluxio fs persist [-p|--parallelism <#>] [-t|--timeout <milliseconds>] [-w|--wait <milliseconds>] <path> [<path> ...]  # 持久化Alluxio中的数据到底层存储
 alluxio fs checkConsistency [-r] [-t|--threads <threads>] <Alluxio path>  # 检查Alluxio与底层存储系统的元数据一致性(确定文件在底层存储还是在under storage system.)
 alluxio fs free -f <>   # 已经持久化到底层存储,但内存中还保留着的文件可以通过free从内存中释放,未被持久化的文件不能被free
 alluxio fs mount [--readonly] [--shared] [--option <key=val>] <alluxioPath> <ufsURI>]    # 将底层文件系统的"ufsURI"路径挂载到Alluxio命名空间中的"alluxioPath"路径下，"path"路径事先不能存在并由该命令生成。 没有任何数据或者元数据从底层文件系统加载。当挂载完成后，对该挂载路径下的操作会同时作用于底层文件系统的挂载点。
 alluxio fs unmount <alluxioPath>  # 取消挂载
 alluxio fs updateMount [--readonly] [--shared] [--option <key=val>] <alluxioPath>  # 保留元数据的同时更改挂载点设置
 alluxio fs pin <path> media1 media2 media3 ... 如果管理员对作业运行流程十分清楚，那么可以使用pin命令手动提高性能。pin命令对Alluxio中的文件或文件夹进行标记。该命令只针对元数据进行操作，不会导致任何数据被加载到Alluxio中。如果一个文件在Alluxio中被标记了，该文件的任何数据块都不会从Alluxio worker中被剔除。如果存在过多的被锁定的文件，Alluxio worker将会剩余少量存储空间，从而导致无法对其他文件进行缓存。
 alluxio fs unpin <path>   # 将Alluxio中的文件或文件夹解除标记。该命令仅作用于元数据，不会剔除或者删除任何数据块。一旦文件被解除锁定，Alluxio worker可以剔除该文件的数据块。
 alluxio fs startSync <path>  # 启动指定路径的自动同步进程
 alluxio fs stopSync <path>   # 关闭指定路径的自动同步进程
 alluxio fs setReplication [-R] [--max <num> | --min <num>] <path>  # 设置给定路径或文件的最大/最小副本数 (-1表示不限制最大副本数) -R递归

#权限相关操作及管理员命令
 alluxio fs chgrp [-R] <group> <path>  # 换组
 alluxio fs chmod [-R] <mode> <path>   # 更改读写执行等权限                        
 alluxio fs chown [-R] <owner>[:<group>] <path>  # 所有者
 alluxio fsadmin backup [directory] [--local]	# 备份Alluxio的元数据到备份目录
 alluxio fsadmin doctor [category]	# 显示错误和警告
 alluxio fsadmin report [category] [category args]	# 报告运行集群的信息
 alluxio fsadmin ufs --mode <noAccess/readOnly/readWrite> "ufsPath"	# 更新挂载的底层存储系统的属性

#集群相关信息
 alluxio fs masterInfo # 获得master节点的信息
 alluxio fs leader     # 打印当前Alluxio的leader master节点主机名。
 alluxio fs getCapacityBytes  # 获取Alluxio总容量
 alluxio fs getSyncPathList  # 获取同步路径列表
 alluxio fs getUsedBytes  # 获取已用空间大小
 alluxio fs getfacl <path> #  显示访问控制列表(ACLs)
 alluxio fs setfacl [-d] [-R] [--set | -m | -x <acl_entries> <path>] | [-b | -k <path>] # 设置访问控制列表(ACLs)
```  
**上面的命令不能帮到你? 那就戳这里**:  
[Alluxio命令使用示例](https://docs.alluxio.io/os/user/stable/cn/basic/Command-Line-Interface.html)  
[管理员命令使用示例](https://docs.alluxio.io/os/user/stable/cn/operation/Admin-CLI.html)


### Alluxio WEB UI介绍及使用  
![alt Alluxio-5](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Alluxio/Alluxio-5.png)
Alluxio master提供了Web界面以便用户管理  
Alluxio master Web界面的默认端口是19999:访问 http://MASTER IP:19999 即可查看  
Alluxio worker Web界面的默认端口是30000:访问 http://WORKER IP:30000 即可查看  

**WEB UI官网介绍的很明确:**[Alluxio Web界面](https://docs.alluxio.io/os/user/stable/cn/basic/Web-Interface.html)




``` bash
$ hexo deploy
```  

加速不明显?
Alluxio通过使用分布式的内存存储以及分层存储,和时间或空间的本地化来实现性能加速。如果数据集没有任何本地化, 性能加速效果并不明显。