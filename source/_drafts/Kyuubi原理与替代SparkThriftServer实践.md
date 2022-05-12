---
title: Kyuubi原理与替代SparkThriftServer实践-基于CDH6
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
  - Kyuubi
  - Spark
keywords: Kyuubi
description: Kyuubi统一分析引擎代替ThriftServer提供稳定高效、支持多租户、权限管理、动态资源的分析服务。
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Kyuubi/Kyuubi-cover.jpg
date: 2022-04-29 16:39:12
---
# Kyuubi原理与替代SparkThriftServer实践-基于CDH6
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Kyuubi/Kyuubi-00.png)

## 前言
Spark ThriftServer原生不支持多租户、权限管理、且稳定性一般，即使我们在源码基础上做了很多权限管控、SQL日志审计、数据脱敏以及性能优化，但由于它自身的稳定性和单点问题，仍然会经常造成调度、分析任务的失败。常见的一些问题有：
1. Driver端单点故障导致整个调度失败
2. 单个大Query占用大量并行度，导致后续任务缓慢或持续等待
3. 单个Job发生数据倾斜时，会拖慢该Job的Task所在的Executor，影响其他Job
4. 定期重启以避免Kerberos凭据过期
5. 通过源码二次开发才能实现的用户权限管理、多租户管理
6. 资源申请和释放粒度较粗，导致资源利用浪费或不充分
7. 对不同负载任务启动多个Thrift实例，才能实现粗粒度的资源隔离，实例越多，维护起来越繁琐
针对以上痛点，网易贡献了Kyuubi这个项目，非常适合替换掉原有的SparkThriftServer服务，解决以上痛点的同时，还支持了异构计算引擎(Flink、Trino等)。当前(2022.5)该项目还在Apache孵化器进行孵化，在我看来是个比较有前景的项目。

## Kyuubi是什么
网易数帆开源的一款支持多租户资源隔离、细粒度的行级、列级权限管理、支持高可用和负载均衡的统一分析引擎，可以通过SQL、Scala完成ETL、数据处理跑批、分析等多种任务负载。
Kyuubi的愿景是建立在Apache Spark和Data Lake技术之上，理想的统一数据湖管理平台。支持纯SQL方式处理数据，实现在同统一平台上使用一份数据副本和一个SQL接口，完成ETL、分析、BI......等工作。

## Kyuubi对比SparkThriftServer的优势  
1. 支持资源隔离（STS只能提交到一个Yarn Queue）
2. 支持多客户端并发和授权
3. 支持数据和元数据的访问权限控制，保证数据安全（STS是单用户的）
4. 用户级别的SparkApplication实例申请
5. 支持多个计算引擎，如Flink、Presto等
6. 两级弹性资源管理（Kyuubi的资源弹性管理+Spark应用自身动态资源管理）
7. 可自动扩展的查询并发能力（单个STS并发查询能力有限、并发高时就会出现资源紧张，资源抢占，任务等待、卡死...）

## Kyuubi原理
### Kyuubi架构图
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Kyuubi/Kyuubi-01.png)
在Kyuubi中，客户端的连接是作为**KyuubiSession**来维护的。
Kyuubi Session的创建可以分为轻量级和重量级两种情况。大多数会话创建都是轻量级、用户无感知的。唯一的重量级情况是用户的共享域中没有实例化或缓存的SparkContext，这种情况通常发生在用户第一次连接或长时间未连接时。这种一次性创建会话的成本，在多数AdHoc场景下也能接受。

Kyuubi维护SparkContext的方式是松散耦合的，这些SparkContext既可以是本地Client模式创建的，也可以是Yarn、K8S集群上的Cluster模式创建的。高可用模式下，SparkContext也可以由其他机器上的Kyuubi实例创建并共享出来。

Kyuubi可以创建和托管多个SparkContexts实例，它们有自己的生命周期，一定条件下会被自动创建和回收，如果一段时间没有任务负载，资源会全部释放。SparkContext的状态不受Kyuubi进程故障转移的影响。

### Kyuubi HA
Kyuubi基于ZK实现高可用和负载均衡：
![alt](https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Kyuubi/Kyuubi-02.png)


## 部署Kyuubi On CDH6.3.2
### Spark 3.2.2 On CDH6.3.2编译与部署
**源码准备**
```shell
# Windows下进入wsl环境（Windows的Linux子系统）
wsl
# 下载Spark源码
git clone https://github.com/apache/spark.git
# 切换到spark3.2分支并创建新分支branch-3.2-cdh6.3.2
cd spark
git checkout branch-3.2
git checkout -b branch-3.2-cdh6.3.2
```
**pom修改**
```xml
<!-- 增加Cloudera源 -->
<repository>
    <id>cloudera</id>
    <url>https://repository.cloudera.com/artifactory/cloudera-repos/</url>
    <name>Cloudera Repositories</name>
    <snapshots>
      <enabled>true</enabled>
    </snapshots>
</repository>
<pluginRepository>
    <id>cloudera</id>
    <name>Cloudera Repositories</name>
    <url>https://repository.cloudera.com/artifactory/cloudera-repos/</url>
</pluginRepository>
<!-- 增加hadoop3 profile -->
<profile>
    <id>hadoop-3.0</id>
    <properties>
      <hadoop.version>3.0.0-cdh6.3.2</hadoop.version>
    </properties>
</profile>
```
**编译**
```shell
# 转换/r/n为unix系统可正常运行的/n  (CRLF转LF)
sudo apt install dos2unix
dos2unix ./dev/*.sh 
dos2unix ./build/*
# 编译 看能否编译通过：
mvn -Pyarn -Dhadoop.version=3.0.0-cdh6.3.2  -Phadoop-3.0 -Phive-thriftserver -DskipTests clean package --settings "/mnt/d/Applications/apache-maven-3.6.3/conf/settings.xml" -Dmaven.repo.local="/mnt/e/Maven/Repository"
# 编译&打包 将源码编译为binary包 生成spark-3.2.2-SNAPSHOT-bin-hadoop-3.0.0-cdh6.3.2.tgz安装包：
./dev/make-distribution.sh --name hadoop-3.0.0-cdh6.3.2 --tgz -Phadoop-3.0 -Pyarn -Phive-thriftserver -DskipTests --settings "/mnt/d/Applications/apache-maven-3.6.3/conf/settings.xml" -Dmaven.repo.local="/mnt/e/Maven/Repository"
```
**部署**
```shell
tar -zxvf spark-3.2.2-SNAPSHOT-bin-hadoop-3.0.0-cdh6.3.2.tgz -C ../../
mv spark-3.2.2-SNAPSHOT-bin-hadoop-3.0.0-cdh6.3.2 spark-3.2.2-bin-hadoop-3.0.0-cdh6.3.2
cd spark-3.2.2-bin-hadoop-3.0.0-cdh6.3.2
cd conf 
cp spark-defaults.conf.template spark-defaults.conf
cp spark-env.sh.template spark-env.sh
# 修改spark-defaults.conf (参数生效优先级: SparkConf > spark-submit Flags > spark-defaults.conf)
vim spark-defaults.conf
  ## Java设置
  spark.executorEnv.JAVA_HOME=/usr/java/jdk1.8.0_181
  spark.yarn.appMasterEnv.JAVA_HOME=/usr/java/jdk1.8.0_181
  ## 开启eventLog用于重构历史已完成任务的WebUI    
  spark.eventLog.enabled=true
  spark.eventLog.dir=hdfs:///user/spark/applicationHistory
  spark.eventLog.compress=true
  spark.driver.log.dfsDir=/user/spark/driverLogs  （持久化driver日志的路径）
  spark.driver.log.persistToDfs.enabled=true   （持久化driver日志）
  spark.history.fs.cleaner.enabled=true  (定期自动清理日志目录，默认一天清理一次，清理7天前的日志文件)
  spark.history.fs.logDirectory=hdfs:///user/spark/applicationHistory
  spark.history.ui.port=18080   （访问Spark应用历史记录http://historyServerHost:18080/）
  spark.history.retainedApplications=30   （缓存中保存的应用历史记录个数，超过会将旧的删除，读更早的日志去磁盘读会慢些）
  spark.yarn.historyServer.address=http://cdh101:18080   （Yarn Application页面Tracking URL链接可以直接进入HistoryServer查看日志）
  spark.yarn.historyServer.allowTracking=true  （Yarn Application页面Tracking URL链接可以直接进入HistoryServer查看日志）
  ## local.dir设置为数据盘，避免使用系统分区
  spark.local.dir=/tmp/spark_temp_data
  ## 优化设置
  spark.kryoserializer.buffer.max=512m
  spark.serializer=org.apache.spark.serializer.KryoSerializer
  spark.authenticate=false   （关闭数据块传输服务SASL加密认证）
  spark.io.encryption.enabled=false   （关闭I/O加密）
  spark.network.crypto.enabled=false  （关闭基于AES算法的RPC加密）
  spark.shuffle.service.enabled=true  （启用外部ShuffleService提高Shuffle稳定性）
  spark.shuffle.service.port=7337  （这个外部ShuffleService由YarnNodeManager提供，默认端口7337）
  spark.shuffle.useOldFetchProtocol=true  （兼容旧的Shuffle协议避免报错）
  spark.sql.cbo.enabled=true  (启用CBO基于代价的优化-代替RBO基于规则的优化-Optimizer)
  spark.sql.cbo.starSchemaDetection=true  （星型模型探测，判断列是否是表的主键）
  spark.sql.datetime.java8API.enabled=false
  spark.sql.sources.partitionOverwriteMode=dynamic 
  spark.sql.orc.mergeSchema=true  （ORC格式Schema加载时从所有数据文件收集）
  spark.sql.parquet.mergeSchema=false (根据情况设置，我们集群大多数都是parquet，从所有文件收集Schema会影响性能，所以从随机一个Parquet文件收集Schema)
  spark.sql.parquet.writeLegacyFormat=true  （兼容旧集群）
  spark.sql.autoBroadcastJoinThreshold=1048576  （当前仅支持运行了ANALYZE TABLE <tableName> COMPUTE STATISTICS noscan的Hive Metastore表，以及直接在数据文件上计算统计信息的基于文件的数据源表）
  spark.sql.adaptive.enabled=true   （Spark AQE[adaptive query execution]启用，AQE的优势：执行计划可动态调整、调整的依据是中间结果的精确统计信息）
  spark.sql.adaptive.forceApply=false
  spark.sql.adaptive.logLevel=info
  spark.sql.adaptive.advisoryPartitionSizeInBytes=256m  （倾斜数据分区拆分，小数据分区合并优化时，建议的分区大小，与spark.sql.adaptive.shuffle.targetPostShuffleInputSize含义相同）
  spark.sql.adaptive.coalescePartitions.enabled=true  （是否开启合并小数据分区默认开启，调优策略之一）
  spark.sql.adaptive.coalescePartitions.minPartitionSize=1m  （合并后最小的分区大小）
  spark.sql.adaptive.coalescePartitions.initialPartitionNum=1024  （合并前的初始分区数）
  spark.sql.adaptive.fetchShuffleBlocksInBatch=true  （是否批量拉取blocks,而不是一个个的去取，给同一个map任务一次性批量拉取blocks可以减少io 提高性能）
  spark.sql.adaptive.localShuffleReader.enabled=true （不需要Shuffle操作时，使用LocalShuffleReader，例如将SortMergeJoin转为BrocastJoin）
  spark.sql.adaptive.skewJoin.enabled=true   （Spark会通过拆分的方式自动处理Join过程中有数据倾斜的分区）
  spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes=128m
  spark.sql.adaptive.skewJoin.skewedPartitionFactor=5  （判断倾斜的条件：分区大小大于所有分区大小中位数的5倍，且大于spark.sql.adaptive.skewJoin.skewedPartitionThresholdInBytes的值）
  ## 默认应用资源设置
  spark.driver.memory=2G
  spark.executor.cores=4
  spark.executor.memory=4G
  spark.executor.memoryOverhead=2G
  spark.memory.offHeap.enabled=true
  spark.memory.offHeap.size=2G
  ## 动态资源设置  具体逻辑见ExecutorAllocationManager这个类
  spark.dynamicAllocation.enabled=true
  spark.dynamicAllocation.executorIdleTimeout=60 （executor闲置时间，如果某executor空闲超过60s，则remove此executor）
  spark.dynamicAllocation.minExecutors=0
  spark.dynamicAllocation.schedulerBacklogTimeout=5s  （如果有pending task并且等待了5s，则申请增加executor）
  spark.dynamicAllocation.cachedExecutorIdleTimeout=600 （cache闲置时间，超过此时间，可释放cache所在的executor）
  ## 其他设置
  spark.driver.extraLibraryPath=/opt/cloudera/parcels/CDH/lib/hadoop/lib/native
  spark.executor.extraLibraryPath=/opt/cloudera/parcels/CDH/lib/hadoop/lib/native
  spark.yarn.am.extraLibraryPath=/opt/cloudera/parcels/CDH/lib/hadoop/lib/native
  spark.ui.enabled=true
  spark.ui.killEnabled=true
  spark.master=yarn
  spark.sql.hive.metastore.version=2.1.1
  spark.sql.hive.metastore.jars=/opt/cloudera/parcels/CDH/lib/hive/lib/*
# 修改spark-env.sh
vim spark-env.sh
  export JAVA_HOME=/usr/java/jdk1.8.0_181
  HADOOP_CONF_DIR=/etc/hadoop/conf
  export SPARK_DIST_CLASSPATH=$(/opt/cloudera/parcels/CDH/bin/hadoop classpath)
  export SPARK_LOCAL_DIRS=/tmp/spark_temp_data
# 软连接hive和hdfs、yarn配置：
ln -s /etc/hadoop/conf/core-site.xml core-site.xml
ln -s /etc/hbase/conf/hbase-site.xml hbase-site.xml
ln -s /etc/hadoop/conf/hdfs-site.xml hdfs-site.xml
ln -s /etc/hive/conf/hive-site.xml hive-site.xml
ln -s /etc/hadoop/conf/mapred-site.xml mapred-site.xml
ln -s /etc/hadoop/conf/yarn-site.xml yarn-site.xml
# 将CRLF转LF以保证运行正常
cd spark-3.2.2-bin-hadoop-3.0.0-cdh6.3.2
sudo yum -y install dos2unix
dos2unix bin/*
dos2unix sbin/*
dos2unix conf/*
dos2unix python/*
# 运行SparkHistoryServer (注意该进程会产生日志，为避免占用系统分区空间，尽量将$SPARK_HOME/logs软连接到数据盘)
sbin/start-history-server.sh
# 运行SparkSQL on Yarn
bin/spark-sql --master yarn 
```
**至此Spark3.2.2 On CDH6.3.2编译部署完毕**

### Kyuubi On Spark3基础部署
更多配置参考：[Kyuubi-Deployment-Settings](https://kyuubi.apache.org/docs/latest/deployment/settings.html)
**安装与配置Kyuubi**
```shell
wget https://www.apache.org/dyn/closer.lua/incubator/kyuubi/kyuubi-1.5.1-incubating/apache-kyuubi-1.5.1-incubating-bin.tgz
tar -zxvf apache-kyuubi-1.5.1-incubating-bin.tgz -C /opt/modules/
# 设置环境变量 vim /etc/profile
# KYUUBI_HOME
export KYUUBI_HOME=/opt/modules/apache-kyuubi-1.5.1-incubating-bin
# 配置文件修改
cd apache-kyuubi-1.5.1-incubating-bin
cd conf
cp kyuubi-env.sh.template  kyuubi-env.sh;cp kyuubi-defaults.conf.template kyuubi-defaults.conf;cp log4j2.properties.template log4j2.properties
# 修改kyuubi-env.sh
vim kyuubi-env.sh
  export JAVA_HOME=/usr/java/jdk1.8.0_181
  export SPARK_HOME=/opt/modules/spark-3.2.2-bin-hadoop-3.0.0-cdh6.3.2
  export HADOOP_CONF_DIR=/etc/hive/conf
  export KYUUBI_JAVA_OPTS="-Xmx4g -XX:+UnlockDiagnosticVMOptions -XX:ParGCCardsPerStrideChunk=4096 -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:+CMSConcurrentMTEnabled -XX:CMSInitiatingOccupancyFraction=70 -XX:+UseCMSInitiatingOccupancyOnly -XX:+CMSClassUnloadingEnabled -XX:+CMSParallelRemarkEnabled -XX:+UseCondCardMark -XX:MaxDirectMemorySize=1024m  -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=./logs -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintTenuringDistribution -Xloggc:./logs/kyuubi-server-gc-%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=5M -XX:NewRatio=3 -XX:MetaspaceSize=512m"
# 修改kyuubi-defaults.conf
vim kyuubi-defaults.conf
  spark.master=yarn
  kyuubi.ha.zookeeper.acl.enabled=true
  kyuubi.ha.zookeeper.quorum=cdh101:2181,cdh102:2181,cdh103:2181
```
**启动与连接Kyuubi**
```shell
# 启动Kyuubi Server
bin/kyuubi start
# 使用hive用户 连接Kyuubi
beeline -u jdbc:hive2://10.2.5.101:10009 -n hive
show databases  # 该命令直接触发Spark引擎初始化
```
**至此Kyuubi基础配置完成**
Kyuubi申请到Spark引擎后，默认空闲30min后自动回收。

### Kyuubi生产环境的高级配置
在上面基础配置的基础上增加生产环境所需的高级配置，包括安全性配置，用户的配置，授权配置等。
```shell
# Kerberos认证
kyuubi.kinit.keytab=/hadoop/bigdata/kerberos/keytab/hive.keytab
kyuubi.kinit.principal=hive/xxx@XXX.COM
```

### 问题与异常处理
1. 执行spark sql后一直卡住，后台报错User: root is not allowed to impersonate anonymous
```log
Error: org.apache.kyuubi.KyuubiSQLException: Timeout(180000 ms) to launched SPARK_SQL engine with /opt/modules/spark-3.2.2-bin-hadoop-3.0.0-cdh6.3.2/bin/spark-submit \
        --class org.apache.kyuubi.engine.spark.SparkSQLEngine \
        --conf spark.kyuubi.ha.zookeeper.quorum=cdh101:2181,cdh102:2181,cdh103:2181 \
        --conf spark.kyuubi.client.ip=10.2.5.101 \
        --conf spark.hive.query.redaction.rules=/etc/alternatives/hive-conf/redaction-rules.json \
        --conf spark.kyuubi.engine.submit.time=1651991699800 \
        --conf spark.app.name=kyuubi_USER_SPARK_SQL_anonymous_default_a0c93d16-2718-4791-8205-97fbc35e652a \
        --conf spark.kyuubi.ha.zookeeper.acl.enabled=true \
        --conf spark.kyuubi.ha.engine.ref.id=a0c93d16-2718-4791-8205-97fbc35e652a \
        --conf spark.kyuubi.ha.zookeeper.auth.type=NONE \
        --conf spark.master=yarn \
        --conf spark.yarn.tags=KYUUBI \
        --conf spark.kyuubi.ha.zookeeper.namespace=/kyuubi_1.5.1-incubating_USER_SPARK_SQL/anonymous/default \
        --conf spark.hive.exec.query.redactor.hooks=org.cloudera.hadoop.hive.ql.hooks.QueryRedactor \
        --proxy-user anonymous /opt/modules/apache-kyuubi-1.5.1-incubating-bin/externals/engines/spark/kyuubi-spark-sql-engine_2.12-1.5.1-incubating.jar. (state=,code=0)
......
22/05/08 14:37:17 INFO retry.RetryInvocationHandler: org.apache.hadoop.security.authorize.AuthorizationException: User: root is not allowed to impersonate anonymous, while invoking ApplicationClientProtocolPBClientImpl.getClusterMetrics over null after 5 failover attempts. Trying to failover after sleeping for 37639ms.
```
解决：避免使用root用户启动Kyuubi Server。可使用hive、hdfs用户启动。


## 参考
[Apache Kyuubi Documents](https://kyuubi.apache.org/docs/latest/index.html)
[Apache Kyuubi Deployment Settings](https://kyuubi.apache.org/docs/latest/deployment/settings.html)
[Apache Spark Configuration](https://spark.apache.org/docs/latest/configuration.html)
[spark-history-server-configuration-options](https://spark.apache.org/docs/latest/monitoring.html#spark-history-server-configuration-options)
[SparkSQL的自适应执行](https://blog.csdn.net/u013411339/article/details/107075125/)
[Migration Guide: SQL, Datasets and DataFrame](https://spark.apache.org/docs/latest/sql-migration-guide.html#upgrading-from-spark-sql-24-to-30)

