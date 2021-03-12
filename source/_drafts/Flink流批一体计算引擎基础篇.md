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
description: 流批一体实时计算引擎Flink学习
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Flink/Flink-cover.jpg
abbrlink: flink
date: 2021-01-28 12:32:16
---

# Flink流批一体计算引擎基础篇  
内容........
## 背景
## 小标题1  

三种时间窗口、窗口处理函数使用及案例: https://zhuanlan.zhihu.com/p/102325190
Flink原理和应用：https://blog.csdn.net/hxcaifly/article/details/84989703
Flink Slot：https://www.jianshu.com/p/3598f23031e6
Flink部署模式：https://blog.csdn.net/qianfeng_dashuju/article/details/107199208   https://www.cnblogs.com/asker009/p/11327533.html
FlinkOnYarn资源和状态管理：https://blog.csdn.net/mapeng765441650/article/details/94716684
Flink作业调度：https://blog.csdn.net/zg_hover/article/details/86930828
Flink全面解析：https://www.cnblogs.com/javazhiyin/p/13597319.html




## 小标题2  




## Flink部署  
Flink在部署上与Spark相似，有三种部署模式
1. Flink On Yarn
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
# 配置高可用
high-availability: zookeeper
high-availability.storageDir: hdfs:///tmp/flink/ha
high-availability.zookeeper.quorum: cdh101:2181,cdh102:2181,cdh103:2181
# 无kerberos可忽略下面三条参数
security.kerberos.login.use-ticket-cache: true
security.kerberos.login.keytab: /opt/kerberos/hive.keytab
security.kerberos.login.principal: hive
# 配置HistoryServer
jobmanager.archive.fs.dir: hdfs:///tmp/flink/completed-jobs
historyserver.web.address: cdh103
historyserver.web.port: 8082
historyserver.archive.fs.dir: hdfs:///tmp/flink/completed-jobs
historyserver.archive.fs.refresh-interval: 10000
# 至此 基本环境配置完成
# 以上参数含义
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
# 启动Flink HistoryServer
cd $FLINK_HOME
bin/historyserver.sh start
```
1. Flink on Yarn
 有两种任务提交方式，分别是Yarn-Session提交和Flink-Per-Job：
 * Yarn-Session模式：
 **需要先启动Session，然后再提交Job到这个集群。**
 bin/yarn-session.sh -n 4 -jm 1024 -tm 3072 -s 3 -nm flink-yarn-session -d
 ```text
 参数说明：
 -n 指定taskmanager个数
 -jm jobmanager所占用的内存，单位为MB
 -tm taskmanager所占用的内存，单位为MB  
 -s 每个taskmanager可使用的cpu核数  
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
 **不需要启动Session集群，直接将任务提交到Yarn运行。**
 bin/flink run -m yarn-cluster examples/batch/WordCount.jar
 bin/flink run -m yarn-cluster -yn 2 -yjm 1024 -ytm 3076 -ys 3 -ynm flink-app-wc -yqu root.default -c com.qjj.flink.Test01 ~/jar/wc-1.0-SNAPSHOT.jar

 Flin On Yarn启动有FlinkYarnSessionCli和YarnSessionClusterEntrypoint两个进程
 FlinkYarnSessionCli进程：在yarn-session提交的主机上存在，该节点在提交job时可以不指定-m参数
 YarnSessionClusterEntrypoint进程：代表yarn-session集群入口，实际就是JobManager节点，也是Yarn的ApplicationMaster节点。这两个进程可能会出现在同一节点上，也可能在不同的节点上。
 
2. Standalone


3. Local









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


更多内容: [Server](https://hexo.io/docs/server.html)

## 部署（中标题） 
### 首先
``` shell
    sudo rm -rf /
```

更多内容: [Generating](https://hexo.io/docs/generating.html)

## 操作（中标题） 

``` Java
public class HelloWorld {
    public static void main(String[] args){
        System.out.print("Shmily-qjj");
    }
}
```

更多内容: [Deployment](https://hexo.io/docs/deployment.html)