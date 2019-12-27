---
title: Hive3.x来了
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
  - Hive
keywords: Hive
description: Hive 3.x来了,学习一下新特性
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-cover.jpg
abbrlink: 7fbbfd34
date: 2019-12-22 15:18:25
---
# Hive3.x新特性  
## 新特性简述  
![alt Hive3.x-0](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-0.JPG)  
1. 执行引擎变更为**[TEZ](https://tez.apache.org/)**,不使用MR  
2. 成熟的ACID大数据事务支持  
3. [LLAP](https://cwiki.apache.org/confluence/display/Hive/LLAP)用于妙极，毫秒级查询访问  
4. 基于[Apache Ranger](http://ranger.apache.org/)的统一权限管理  
5. 默认开启HDFS ACLs
6. Beeline代替Hive Cli，降低启动开销  
7. 不再支持内嵌Metastore  
8. Spark Catalog不与Hive Catalog集成，但可以互相访问  
9.批处理使用TEZ，实时查询使用LLAP  

## 应用  

## 架构原理
1. TEZ执行引擎  
**[Apache TEZ](https://tez.apache.org/)**是一个针对Hadoop数据处理应用程序的分布式计算框架，直接运行在Yarn上，是支持DAG作业的开源计算框架。Tez产生的主要原因是绕开MapReduce所施加的限制，逐步取代MR，提供更高的性能和灵活性。  
Apache TEZ的核心思想是将Map和Reduce拆分成若干子过程，即Map被拆分成Input、Processor、Sort、Merge和Output， Reduce被拆分成Input、Shuffle、Sort、Merge、Processor和Output等，分解后可以灵活组合成一个大的DAG作业。  
Apache TEZ兼容MR任务，不需要代码层面的改动。  
![alt Hive3.x-1](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-1.png)  ![alt Hive3.x-2](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-2.png)   

上图是Hive On MR和Hive On Tez执行任务流程对比图，解释：  

| Hive On MR| Hive On Tez |
| :----: | :----: |
| 计算需要多个MR任务而且中间结果都要落盘 | 只有一个作业，只写一次HDFS |  
| 没有资源重用 | 资源复用 |  
| 处理完释放资源 | Applications Manager资源池启动若干Container，处理完不释放直接分配给未运行任务 |  

2. LLAP  
LLAP(Live Long and Process)实时长期处理，由一个守护进程和一个基于DAG的框架组成，LLAP不是执行引擎(MR/Tez),它用来保证Hive的可伸缩性和多功能性，增强现有的执行引擎。  
LLAP的守护进程长期存在且与DataNode直接交互，缓存，预读取，某些查询处理和访问控制功能包含在这个守护程序中用于直接处理小的查询，而计算与IO较大的繁重任务会提交Yarn执行。守护程序不是必须的，没有它Hive仍能正常工作。对LLAP节点的请求都包含元数据信息和数据位置，所以LLAP节点无状态。    
可以使用Hive on Tez use LLAP来加速OLAP场景(OnLine Analytical Processing联机分析处理)
LLAP为了避免JVM内存设置的限制，使用堆外内存缓存数据以及处理GROUP BY/JOIN等操作，而守护程序仅使用少量内存。  

![alt Hive3.x-3](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-3.png)  
如图LLAP执行示例，TEZ作为执行引擎，初始阶段数据被推到LLAP，LLAP直接与DataNode交互。而在Reduce阶段，大的Shuffle数据在不同的Container容器中进行，多个查询和应用能同时访问LLAP。  







## 优缺点  

1.优点：  
```text
原子性（Atomicity）
原子性是指事务是一个不可分割的工作单位，事务中的操作要么都发生，要么都不发生。

一致性（Consistency）
事务前后数据的完整性必须保持一致。

隔离性（Isolation）
事务的隔离性是多个用户并发访问数据库时，数据库为每一个用户开启的事务，不能被其他事务的操作数据所干扰，多个并发事务之间要相互隔离。

持久性（Durability）
持久性是指一个事务一旦被提交，它对数据库中数据的改变就是永久性的，接下来即使数据库发生故障也不应该对其有任何影响
```  


 
https://link.zhihu.com/?target=https%3A//hortonworks.com/tutorial/interactive-sql-on-hadoop-with-hive-llap/
https://link.zhihu.com/?target=https%3A//dzone.com/articles/3x-faster-interactive-query-with-apache-hive-llap
https://link.zhihu.com/?target=https%3A//community.hortonworks.com/articles/149486/llap-sizing-and-setup.html
Hadoop统一授权管理框架[Apache Ranger](http://ranger.apache.org/)

 

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

## 参考资料  

[Hive3新特性](https://www.jianshu.com/p/a1324fb4eb80)
[Apache Tez 了解](https://www.cnblogs.com/rongfengliang/p/6991020.html)
[]()
[]()
[]()
[]()

``` Java
public class HelloWorld {
    public static void main(String[] args){
        System.out.print("Shmily-qjj");
    }
}
```

更多内容: [Deployment](https://hexo.io/docs/deployment.html)