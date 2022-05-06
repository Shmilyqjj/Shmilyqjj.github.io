---
title: Flink流批一体计算引擎基础篇
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
  - 实时计算
  - Flink
  - 流批一体
keywords: Apache Flink
description: 流批一体实时计算引擎Flink学习笔记
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-cover.jpg
abbrlink: flink
date: 2022-01-28 12:32:16
---

# Flink流批一体计算引擎基础篇  
Apache Flink is a framework and distributed processing engine for stateful computations over unbounded and bounded data streams. Flink has been designed to run in all common cluster environments, perform computations at in-memory speed and at any scale.
关键字: 分布式处理引擎、有状态的、可以处理有界\无界数据

## Flink特点及使用场景
### Flink特点
1.高吞吐、低延迟、可伸缩性高、极致的流式处理性能。（本地状态存取大幅降低网络IO提高性能）
2.Flink支持Stateful有状态计算，有状态是指数据流过计算引擎会不断把状态（中间结果）记录下来，比如计算PV\UV记录页面点击总数或用户访问总数这样的状态。（与之对应的是无状态，无状态计算就是数据来一条过滤一条，不在计算引擎保留任何信息）
3.支持灵活的窗口计算
4.7*24小时高可用：一致性Checkpoint、高效Checkpoint，支持Savepoint，本地状态存取及远程状态备份，本地状态支持Failover，本身提供了运维监控接口(WEBUI\Metric)
5.支持事件时间EventTime
6.支持两种数据集合BoundedStream(有界流)、UnBoundedStream(无界流)
7.精确一次Exactly-Once容错保证
8.基于JVM实现独立内存管理

### Flink应用场景
事件驱动型应用
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-01.png)  
数据分析应用
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-02.png)  
数据管道应用
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-03.png)  

应用案例：
1.实时智能推荐 -- 基于用户行为实时计算，对模型实时更新，对用户指标实时预测，进行实时推荐、广告投放
2.复杂事件处理(Flink CEP) -- 车载传感器、机械故障实时监测、物联网IOT
3.实时反欺诈监测 -- 实时完成对欺诈行为指标的判断并对交易进行实时拦截
4.实时数仓与实时ETL -- 流式数据实时清洗、归并、结构化处理，为离线数仓进行补充和优化，业务分析实时化
5.流数据分析 -- 实时计算各类数据指标，实时调整在线系统相关策略，实现精细化运营，提升产品质量和体验
6.实时报表分析 -- 双十一实时交易额、实时大屏，助力快速提取数据更多价值
7.实时监控系统 -- 对应用指标收集与分析，实现对系统的实时监控告警


## Flink原理与基础
### Flink三个重要的时间概念
Flink提供不同时间种类处理支持。
Event Time：事件真正发生的时间
Processing Time：数据进入Flink的时间，Flink收到数据的时间
Ingestion Time：数据摄入时间


### Flink API
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-04.png)  
Flink根据处理数据集类型不同分为支持流计算的DataStreamAPI，和支持批计算的DataSetAPI。Flink应用程序由用户自定义算子转换而来的流式Dataflows所组成。这些流式Dataflows形成了有向图，以一个或多个源（source）开始，并以一个或多个汇（sink）结束。
**灵活程度表达能力依次降低、抽象能力依次提高：SQL/TableAPI -> DataStreamAPI(streams\windows) -> ProcessFunction(event\state\time)**
* SQL API
  类似SparkSQL，使用SQL进行逻辑处理，聚焦业务逻辑，避免受限于复杂的编程接口。
* Table API
  类似Spark Dataframe，Flink将内存中的Datastream、Dataset数据集在原有基础上增加Schema信息，将数据抽象成表结构，然后通过Table API提供的接口方法(GroupByKey\Join等)进行处理。Table API转化为Datastream和Dataset数据处理过程中应用了大量优化规则，Table可以与Datastream\Dataset互相转换。
* Datastream\Dataset API
  类似Spark RDD弹性分布式数据集，提供了map、filter、aggregations、window等方法，支持Java、Scala、Python等多种开发语言。
* Stateful Stream Process API
  Flink中处理有状态流的最底层接口，用户可以通过Stateful Stream Process API操作状态、时间等底层数据，灵活性强，学习成本高，可以实现复杂逻辑。一般用于Flink二次开发以及深度封装。

Scala、Java、Python三种语言均可以开发Flink Application
使用Flink提供的Quickstart Shell来创建Flink项目模板：
```shell
curl https://flink.apache.org/q/quickstart-SNAPSHOT.sh | bash -s 1.13.6
mvn clean package  
```
Flink DataStream转换：
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-14.png)  
其中keyBy是最常用的算子，作用是将整个流按照不同的key分散，并行执行计算。如果不执行keyBy分组，所有数据得到一个大的AllWindowedStream，执行keyBy后，数据窗口分散为多个小的WindowedStream，同时keyBy后，每个节点分到不同的key的状态，将大的状态拆分为小的状态，每个节点都维持自己的状态，不需要关心其他节点的状态。KeyBy使用的前提是假设key数远大于并发度，假设流只有一个key，最终仍然是单个并行度跑。

Flink数据类型支持：
Flink是强数据类型的，Scala中也是通过隐式转换达到强类型的。强数据类型的DataStream方便Flink引擎提高不同数据类型序列化、反序列化效率。
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-15.png)  

![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-05.png)  

Flink命令行
```shell
cd $FLINK_HOME
# Flink 任务提交 
bin/flink run examples/streaming/TopSpeedWindowing.jar [args]
# Flink任务列表查看
[root@node1 ~]# flink list
Waiting for response...
------------------ Running/Restarting Jobs -------------------
05.05.2022 20:17:44 : c55d09b0f6dcd06b5630c17da14dae96 : CarTopSpeedWindowingExample (RUNNING)
--------------------------------------------------------------
No scheduled jobs.
# Flink停止某个任务 
## 分为stop和cancel  
## stop是优雅地退出，一个job能被stop，是其所有source都是stoppable的，即实现了StoppableFunction接口
[root@node1 ~]# flink stop c55d09b0f6dcd06b5630c17da14dae96
Suspending job "c55d09b0f6dcd06b5630c17da14dae96" with a savepoint.
Savepoint completed. Path: file:/tmp/flink-tmp/savepoints/savepoint-c55d09-70d0bdadd368
## cancel是强制退出 加-s可以指定一个savepoint目录 cancel会立刻调用算子的cancel方法尽快取消它们，如果算子调用cancel后没停止，Flink会开始中断算子线程的执行直到所有算子停止。
[root@node1 flink-1.13.6]# bin/flink cancel -m 127.0.0.1:8081 -s /tmp/flink-tmp/savepoints/17fc85c10edc883dd34d15a3b12f432f 17fc85c10edc883dd34d15a3b12f432f
DEPRECATION WARNING: Cancelling a job with savepoint is deprecated. Use "stop" instead.
Cancelling job 17fc85c10edc883dd34d15a3b12f432f with savepoint to /tmp/flink-tmp/savepoints/17fc85c10edc883dd34d15a3b12f432f.
Cancelled job 17fc85c10edc883dd34d15a3b12f432f. Savepoint stored in file:/tmp/flink-tmp/savepoints/17fc85c10edc883dd34d15a3b12f432f/savepoint-17fc85-04cf00276efc.
# Flink手动触发Savepoint
bin/flink savepoint -m 172.0.0.1:8081 3584bb94ea0c7cfcc5fbfc24ea5205cb /tmp/flink-tmp/savepoints/3584bb94ea0c7cfcc5fbfc24ea5205cb
# Flink从Savepoint启动任务  (JM日志可看到关键词Starting job xxx from savepoint xxx)
bin/flink run -d -s /tmp/flink-tmp/savepoints/17fc85c10edc883dd34d15a3b12f432f/savepoint-17fc85-04cf00276efc examples/streaming/TopSpeedWindowing.jar
# Flink 查看执行计划  将结果json复制到https://flink.apache.org/visualizer/ 可查看逻辑计划DAG图（与实际运行时WebUI上的物理计划不同）
bin/flink info examples/streaming/TopSpeedWindowing.jar
```

Flink RestAPI
可以用于监控任务状态以及提交任务，常用于任务状态监控。API参考如下文档：
**[Flink REST API Doc](https://nightlies.apache.org/flink/flink-docs-release-1.15/docs/ops/rest_api/)**




### Flink有状态计算的挑战
1. 状态容错
 * 如何确保精确一次Exactly-Once容错保证
 如果计算结果不是Exactly-Once，则产生的结果是不可靠的，没参考价值。
 保证精确一次：数据流处理的位置x-> state @ x -> 对当前计算位置状态做快照
 保证端到端精确一次： sources中的每个事件都仅精确一次对sinks生效，必须满足①Sources是可重放的、②Sinks必须是事务性或幂等的

 * 如何确保分散场景下多个拥有本地状态的算子产生一个全局一致性快照(Global Consistent Snapshot)，如何在不中断运算的前提下产生快照
 全局一致性快照->每个算子的state通过**checkpoint**存储到一个共享的FileSystem
 ![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-06.png)
 **Checkpoint**：Flink本地状态存取要保证容灾，支持Failover故障恢复，Checkpoint操作由JobManager定期触发，将本地状态归档到远程持久化存储，出问题时可以从远程检查点恢复。
 **Checkpoint Barrier(检查点屏障)**：异步barrier快照（asynchronous barrier snapshotting），实现了持续产生全局一致性快照且不中断计算。执行检查点屏障的动作可以理解为随着数据从算子一步一步计算下去，将数据offset、算子计算状态等信息不断填入一个表格数据结构，这个表格即为全局一致性快照，可以用来容错，节点Fail时就可以从checkpoint去恢复。
 ![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-07.png)
 当checkpoint coordinator（job manager 的一部分）指示task manager开始checkpoint时，它会让所有sources记录它们的偏移量，并将编号的checkpoint barriers插入到它们的流中。这些barriers流经job graph，标注每个checkpoint前后的流部分。Checkpoint n将包含每个算子的state，这些state是对应的 operator消费了在checkpoint barrier n之前的所有事件，并且不包含在此（checkpoint barrier n）后的任何事件后而生成的状态。
 当job graph中的每个operator接收到barriers时，它就会记录下其状态。拥有两个输入流的算子（例如 CoProcessFunction）会执行barrier对齐（barrier alignment）以便当前快照能够包含消费两个输入流barrier之前（但不超过）的所有events而产生的状态。
 **Copy-On-Write**: Flink的State Backends利用写时复制（copy-on-write）机制允许当异步生成旧版本的状态快照时，能够不受影响当前的流处理。只有当快照被持久保存后，这些旧版本的状态才会被当做垃圾回收。


2. 状态维护
Flink计算时可能会有大量的状态(中间结果)，一般情况下状态都保存在Memory中，如果状态特别大，则需要一个可靠的状态后端。
**State Backends**的作用就是用来维护State的。一个State Backend主要负责两件事：Local State Management(本地状态管理)和Remote State Checkpointing（远程状态备份）
 * Local State Management 本地状态管理
 ___MemoryStateBackend___：适合比较小的状态，状态管理方式是使用TaskManager的JVM Heap，直接将 State 以对象的形式存储到JVM的堆上面，状态读写时都是操作JavaObject代价不大，但在checkpoint由本地状态转而产生全局一致性快照时就需要序列化了，远程备份时MemoryStateBackend会将State备份到JobManager的堆内存上，这种方式是非常不安全的，且受限于JobManager的内存大小。
 ___RocksDBStateBackend___：适合比较大的状态，状态管理方式是RocksDB数据库作为状态读写的后端，可以节约TaskManager内存(相对Memory后端)，适合对延迟不是特别敏感的应用，每次读写都经过序列化\反序列化，远程备份的方式是在checkponit时数据已经序列化好，直接传输到底层FileSystem，代价小些。
 ___FsStateBackend___：状态管理方式是将State存储到TaskManager的JVM堆上，远程备份的方式是将State写入到远程的文件系统如HDFS中。
 * Remote State Checkpointing 远程状态备份(Checkpoint)
 Flink程序是分布式运行的，而State都是存储到各个节点本地的，一旦TaskManager节点出现问题，就会导致State的丢失。
 State Backends提供了State Checkpointing的功能，将TaskManager本地的State的备份到远程的存储介质上，可以是分布式的存储系统或者数据库。不同的 State Backend备份的方式不同，会有效率高低的区别。
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-08.png)
**总结**：MemoryStateBackend和FsStateBackend都是在内存中进行状态管理，所以可以获取较低的读写延迟，但会受限于TaskManager的内存大小，且只能做全量快照；而RocksDBStateBackend直接将State存储到RocksDB数据库中，所以不受JobManager的内存限制，但会有读写延迟，同时RocksDBStateBackend支持增量快照，这是其他两个都不支持的特性。一般来说，如果不是对延迟有极高的要求，或有大量变化缓慢状态的应用程序中，RocksDBStateBackend是更好的选择。
```code
getRuntimeContext().getState(xxx) 会创建一个本地状态后端
state.value()\state.update(xxx)  本地状态的读写
```

3. 状态保存、迁移与恢复
驱动关键业务服务的流应用是经常需要维护的。比如需要修复系统漏洞，改进功能，或开发新功能。然而升级一个有状态的流应用并不是简单的事情，因为在我们为了升级一个改进后版本而简单停止当前流应用并重启时，我们还不能丢失掉当前流应用的所处于的状态信息。
Savepoint就是解决这个难题的功能。
**Savepoint**：可以理解成一个手动触发保存的Checkpoint；区别是checkpoint是周期性自动触发、Savepoint是手动触发;Checkpoint是在作业failover时自动使用无需用户指定、Savepoint一般用于程序版本更新、Bug修复、ABTest等场景，需要用户手动指定；Checkpoint是增量的，每次耗时短数据量小、Savepoint是全量的，每次时间长数据量大。
流式Flink程序停服维护前进行Savepoint，维护两个小时后重启程序，可以Restore从Savepoint恢复执行程序。因为Savepoint保存着程序退出时Kafka Offset，所以恢复时，会从退出时的Offset继续消费，并利用Event-Time机制赶上最新数据（如果是用ProcessingTime机制，则停机时间段的事件处理结果都在当前的处理时间的窗口，数据不准确，所以这也是Flink支持事件时间的好处）。
Savepoint特点：
便于升级应用服务版本、方便集群服务移植、方便Flink版本升级、增加应用并行服务的扩展性、便于A/B测试及假设分析场景对比结果、暂停和恢复服务、归档服务

4. EventTime处理
Flink提供不同时间种类处理支持，EventTime为事件真实发生的时间，是从事件发生的源头产生的时间。
Flink引入了watermark 的概念，用以衡量事件时间进展。Watermark也是一种平衡处理延时和完整性的灵活机制。
Watermark是Flink中的特殊事件。一个带有时间戳t的watermark会让引擎判定不会再接收任何 时间戳<t 的事件。
Flink通过Watermarks让计算引擎知道当前这个Window的所有数据是否都已经进来了，是否可以计算完成并开始计算下一个Window。
比如10点钟的EventTime，Watermark设置为5分钟，则Watermark在EventTime基础上Delay五分钟，Watermark为9点55，等到10:05分的时候才判断10点的数据都已经进来了。
迟到数据处理：当以带有Watermark的事件时间模式处理数据流时，在计算完成之后仍会有相关数据到达。这样的事件被称为迟到事件。Flink提供了多种处理迟到数据的选项，例如将这些数据重定向到旁路输出（side output）或者更新之前完成计算的结果。

### 资源与并行度
* 分散式计算(并行Dataflows)
 stream与batch一样，也会partitioning，将同一个key放到同一个流分区去运算(keyBy)，累计起来的状态也在key所在的分区内。
 Flink 算子之间可以通过一对一（直传）模式或重新分发模式传输数据
 ![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-09.png)
  + 一对一模式
  （例如上图中的 Source 和 map() 算子之间）可以保留元素的分区和顺序信息。这意味着 map() 算子的 subtask[1] 输入的数据以及其顺序与 Source 算子的 subtask[1] 输出的数据和顺序完全相同，即同一分区的数据只会进入到下游算子的同一分区。
  + 重新分发模式（例如上图中的 map() 和 keyBy/window 之间，以及 keyBy/window 和 Sink 之间）
  重新分发模式会更改数据所在的流分区。当你在程序中选择使用不同的转换算子，每个转换算子也会将数据发送到不同的目标子任务。例如这几种 transformation和其对应分发数据的模式：keyBy（通过散列键重新分区）、broadcast（广播）或rebalance（随机重新分发）。在重新分发数据的过程中，元素只有在每对输出和输入子任务之间才能保留其之间的顺序信息（例如，keyBy/window的subtask[2]接收到的map()的subtask[1]中的元素都是有序的）。因此，上图所示的 keyBy/window和Sink算子之间数据的重新分发时，不同键（key）的聚合结果到达 Sink 的顺序是不确定的。
* Flink资源划分
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-10.png)
Task是Flink中资源调度的最小单位，相当于Thread
Flink程序分为三个角色：**Client**、**JobManager**、**TaskManager**
**Client**:Flink Program，提交Flink作业的命令行工具，将用户的代码经过Optimizer/GraphBuilder编译成Dataflow Graph，与JobManager构建Akka连接，提交Job(Dataflow)，通过和JobManager交互，获取任务状态。
**JobManager**:接收客户端请求，负责协调Task的分布式执行，包括调度Task，资源管理，Checkpoint管理及触发，Job Failover时协调Task从检查点恢复，Task心跳监控和状态管理。
**TaskManager**:负责计算的节点，从JobManager接收到Dataflow Graph，并执行Dataflow Graph中的Tasks，TaskManager上有多个TaskSlot(线程)，用于执行某个SubTask的容器(槽)。TaskManager还负责对资源的管理，包括Memory管理、Network管理、Actor管理。
如下图，Flink Task由不同算子组成：
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-12.png)
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-11.png)
Flink是多线程的，多个任务Task之间通过Taskslot共享系统资源。有多少TaskSlot(Thread)就可以跑多少个SubTask，TaskSlot是SubTask的容器，可以运行各种SubTask，既可以是map、也可以是keyBy+Window还可以是sink等等。

## Flink部署  
Flink的部署模式：Standalone、Yarn(session/per-job)、Mesos、K8s
**Flink On Yarn模式部署：**
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Flink/Flink-13.png)
推荐Flink On Yarn模式，有以下好处：
 1. 资源按需使用，集群资源利用率高
 2. 任务有优先级，按优先级作业
 3. 基于Yarn的调度可以自动化处理各个角色的Failover自动拉起（JM和TM都由YarnNodeManager监控，JM挂会被YarnRM重新调度到其他机器，TM挂时JM收到信息会重新向YarnRM申请资源以重新启动TM）
```shell
# 准备HDFS目录
hadoop fs -mkdir -p /tmp/flink/completed-jobs
hadoop fs -chmod 1777 /tmp/flink/completed-jobs
hadoop fs -chmod 1777 /tmp/flink
hadoop fs -mkdir -p /tmp/flink/ha
hadoop fs -chmod 1777 /tmp/flink/ha
# 准备系统环境变量
/etc/profile 添加
export FLINK_HOME=/opt/modules/flink/flink-1.12.1
export PATH=$PATH:$FLINK_HOME/bin
export HADOOP_CONF_DIR="/etc/alternatives/hadoop-conf"
export HADOOP_HOME="/opt/cloudera/parcels/CDH/lib/hadoop"
export HBASE_CONF_DIR="/etc/hbase/conf"
export HADOOP_CLASSPATH=`hadoop classpath`
source /etc/profile
# 对yarn配置做一定修改
yarn.resourcemanager.am.max-attempts Yarn集群应用的重试次数上限 默认2改为100 
# 修改flink-conf.yaml
cd $FLINK_HOME
vim conf/flink-conf.yaml 修改如下参数
# 配置Java环境 保证每个NodeManager节点JDK路径正确
env.java.home: /usr/java/jdk1.8.0_181
containerized.master.env.JAVA_HOME: /usr/java/jdk1.8.0_181
containerized.taskmanager.env.JAVA_HOME: /usr/java/jdk1.8.0_181
# 配置Flink yarn-session资源  根据机器资源情况调节
jobmanager.rpc.address: cdh103
jobmanager.rpc.port: 6123
jobmanager.heap.size: 1024m
taskmanager.heap.size: 2048m
taskmanager.numberOfTaskSlots: 3
parallelism.default: 1
# 配置高可用（Flink中的HA一般指JobManager的HA）
high-availability: zookeeper
high-availability.storageDir: hdfs:///tmp/flink/ha
high-availability.zookeeper.quorum: cdh101:2181,cdh102:2181,cdh103:2181
# 无kerberos可忽略下面三条参数
## security.kerberos.login.use-ticket-cache: true
## security.kerberos.login.keytab: /opt/kerberos/hive.keytab
## security.kerberos.login.principal: hive
# 配置HistoryServer
jobmanager.archive.fs.dir: hdfs:///tmp/flink/completed-jobs
historyserver.web.address: cdh103
historyserver.web.port: 8082
historyserver.archive.fs.dir: hdfs:///tmp/flink/completed-jobs
historyserver.archive.fs.refresh-interval: 10000
# 优化参数
yarn.application-attempts: 10 Flink Job级别的JobManager重启次数限制
# 至此 基本环境配置完成
```
以上参数含义
```text
jobmanager.rpc.address JobManager所在节点
jobmanager.rpc.port JobManager端口
jobmanager.heap.size   每个TaskManager可用内存
taskmanager.heap.size 每个JobManager可用堆内存
taskmanager.numberOfTaskSlots  每个TaskManager并行度，每个TaskManager分配Slot个数，设置Flink程序具有的并发能力
parallelism.default  Job运行的默认TaskManager并行度Slot，不能高于TaskManager并行度即Slot数  例：运行程序默认的并行度为1，9个TaskSlot只用了1个，有8个空闲，同时提交9个任务才会将Slot用完，否则浪费
jobmanager.archive.fs.dir：flink job运行完成后的日志存放目录
historyserver.archive.fs.dir：flink history进程的hdfs监控目录
historyserver.web.address：flink history进程所在的主机
historyserver.web.port：flink history进程的占用端口
historyserver.archive.fs.refresh-interval：刷新受监视目录的时间间隔（以毫秒为单位）
注意jobmanager.archive.fs.dir要和historyserver.archive.fs.dir值一样
```

启动Flink HistoryServer 
HistoryServer用于了解Flink过去完成任务的状态，以及有状态作业的恢复（保存了最后一次的Checkpoint地址）
```shell
cd $FLINK_HOME
bin/historyserver.sh start
```

提交Flink任务
Flink on Yarn有两种任务提交方式，分别是Yarn-Session提交和Flink-Per-Job
```
* Yarn-Session模式：
 需要先启动Session，然后再提交Job到这个集群。
 bin/yarn-session.sh -n 4 -jm 1024 -tm 3072 -s 3 -nm flink-yarn-session -d
```text
参数说明：
-n 指定taskmanager个数
-jm jobmanager所占用的内存，单位为MB
-tm taskmanager所占用的内存，单位为MB  
-s 每个taskmanager可使用的cpu核数  Slot数，Slot数对资源的隔离仅仅是对内存进行隔离，策略是均分，比如TaskManager内存4G有两个Slot则每个Slot有2可用内存
-nm 指定Application的名称
-d 后台启动
```
提交Job
bin/flink run -m cdh104:4055 examples/batch/WordCount.jar  (启动session后的JobManager Web Interface地址)
 
 ```text
 1.启动Session后，yarn首先会分配一个Container,用于启动APPlicationMaster和JobManager，所占用内存为-jm指定的内存大小，cpu为1核
 2.没有启动Job之前，Jobmanager不会启动TaskManager，Jobmanager会根据Job的并行度，即所占用的Slots，来动态的分配TaskManager  
 3.提交任务到APPlicationMaster
 4.任务运行完成，TaskManager资源释放
 ```
 
 * Flink-Per-Job模式(推荐)：
 不需要启动Session集群，直接将任务提交到Yarn运行。
 bin/flink run -m yarn-cluster examples/batch/WordCount.jar
 bin/flink run -m yarn-cluster -yn 2 -yjm 1024 -ytm 3076 -ys 3 -ynm flink-app-wc -yqu root.default -c com.qjj.flink.Test01 ~/jar/wc-1.0-SNAPSHOT.jar
注意：
```text
 Flin On Yarn启动有FlinkYarnSessionCli和YarnSessionClusterEntrypoint两个进程
 FlinkYarnSessionCli进程：在yarn-session提交的主机上存在，该节点在提交job时可以不指定-m参数
 YarnSessionClusterEntrypoint进程：代表yarn-session集群入口，实际就是JobManager节点，也是Yarn的ApplicationMaster节点。这两个进程可能会出现在同一节点上，也可能在不同的节点上。
```

**Flink Standalone模式部署：**
```shell
# 解压tar包
cd $FLINK_HOME
# vim conf/flink-conf.yaml  修改taskmanager.numberOfTaskSlots等参数
# vim conf/workers 修改为如下 表示本地启动三个TaskManager
localhost
localhost
localhost
# 执行启动Standalone集群
bin/start-cluster.sh
# 访问WebUI: localhost:8081
# jps查看进程
17122 Jps   
15572 TaskManagerRunner   （TaskManager进程）
15272 StandaloneSessionClusterEntrypoint （JobManager进程）
16216 TaskManagerRunner
15885 TaskManagerRunner
# 执行关闭Standalone集群
bin/stop-cluster.sh
# 配置高可用HA：在多个节点配置多个JobManager，并配置zk来通过zk实现高可用
# vim conf/flink-conf.yaml 
指定high-availability: zookeeper 并添加zk地址（high-availability.zookeeper.quorum: zk1:2181,zk2:2181,zk3:2181）
指定high-availability.storageDir: hdfs:///flink/ha/
注意HA模式下jobmanager.rpc.address和jobmanager.rpc.port配置无效，具体地址是通过争抢zk的锁获得
# vim conf/masters 添加多个JobManager节点host
```

 Flink日志配置
 ```text
 -rw-r--r-- 1 shmily 1001  2946 Feb  3 21:23 log4j-cli.properties  （Flink命令行的日志配置 如Flink run）
-rw-r--r-- 1 shmily 1001  3070 Feb  3 21:23 log4j-console.properties 
-rw-r--r-- 1 shmily 1001  2723 Feb  3 21:23 log4j.properties （所有JobManager和TaskManager的日志配置）
-rw-r--r-- 1 shmily 1001  2070 Feb  3 21:23 log4j-session.properties  （YarnSession启动时日志配置）
-rw-r--r-- 1 shmily 1001  2740 Feb  3 21:23 logback-console.xml
-rw-r--r-- 1 shmily 1001  1550 Sep  9  2020 logback-session.xml
-rw-r--r-- 1 shmily 1001  2331 Feb  3 21:23 logback.xml
-rw-r--r-- 1 shmily 1001  1434 Jul 20  2018 zoo.cfg  （Flink自带ZookeeperServer的配置）
# Flink既支持log4j又支持logback，log4j-console.properties对应logback-console.xml以此类推
# 如果决定用logback就删掉对应log4j配置文件即可，如果用log4j，不用删logback因为log4j优先级更高
 ```




















## 小标题2  


三种时间窗口、窗口处理函数使用及案例: https://zhuanlan.zhihu.com/p/102325190
Flink原理和应用：https://blog.csdn.net/hxcaifly/article/details/84989703
Flink Slot：https://www.jianshu.com/p/3598f23031e6
Flink部署模式：https://blog.csdn.net/qianfeng_dashuju/article/details/107199208   https://www.cnblogs.com/asker009/p/11327533.html
FlinkOnYarn资源和状态管理：https://blog.csdn.net/mapeng765441650/article/details/94716684
Flink作业调度：https://blog.csdn.net/zg_hover/article/details/86930828
Flink全面解析：https://www.cnblogs.com/javazhiyin/p/13597319.html



* 字体
*斜体文本*
_斜体文本_
**粗体文本**
__粗体文本__
***粗斜体文本***
___粗斜体文本___
<u>带下划线文本</u>

* 脚注
[^要注明的文本]: xxxxxxxxx

* 列表
无序列表用* + -三种符号表示
    * 列表嵌套
    1. 有序列表第一项：
        - 第一项嵌套的第一个元素
        - 第一项嵌套的第二个元素
    2. 有序列表第二项：
        - 第二项嵌套的第一个元素
        - 第二项嵌套的第二个元素
            * 最多第三层嵌套
            + 最多第三层嵌套
            - 最多第三层嵌套






## 参考
《Flink原理、实战与性能优化》
[Flink官方文档](https://flink.apache.org/)

