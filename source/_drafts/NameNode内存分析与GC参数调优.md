---
title: NameNode内存分析与GC参数调优
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
  - HDFS
  - NameNode
  - JVM调优
  - CMS
  - G1
keywords: 内存分析
description: 如何评估NN内存需求以及针对NN的GC调优策略
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/Kafka/Kafka-Cover.jpg
date: 2020-03-23 16:19:00
---
# NameNode内存分析与GC参数调优

 Namenode内存分析 https://ericsahit.github.io/2016/12/25/Namenode%E5%86%85%E5%AD%98%E5%88%86%E6%9E%90/

## NameNode使用内存分析    
CMS调优：https://blog.csdn.net/flysqrlboy/article/details/88679457

吞吐量(throughput)，响应时间(latency)，和内存用量，三者只能取其二
CMS+ParNew调优响应时间优先：https://blog.csdn.net/qq_32641659/article/details/88030753



NN GC调优：https://blog.csdn.net/shadyxu/article/details/94593336



CMS对比G1：https://blog.csdn.net/zhou2s_101216/article/details/79219953

### 小标题1  

### 小标题2  


## 调参策略
NameNode默认采用ParNew+CMS的GC收集器，

CMS的垃圾收集
1、initial-mark 初始标记(CMS的第一个STW阶段)，标记GC Root直接引用的对象，GC Root直接引用的对象不多，所以很快。

2、concurrent-mark 并发标记阶段，由第一阶段标记过的对象出发，所有可达的对象都在本阶段标记。

3、concurrent-preclean 并发预清理阶段，也是一个并发执行的阶段。在本阶段，会查找前一阶段执行过程中,从新生代晋升或新分配或被更新的对象。通过并发地重新扫描这些对象，预清理阶段可以减少下一个stop-the-world 重新标记阶段的工作量。

4、concurrent-abortable-preclean 并发可中止的预清理阶段。这个阶段其实跟上一个阶段做的东西一样，也是为了减少下一个STW重新标记阶段的工作量。增加这一阶段是为了让我们可以控制这个阶段的结束时机，比如扫描多长时间(默认5秒)或者Eden区使用占比达到期望比例(默认50%)就结束本阶段。

5、remark 重标记阶段(CMS的第二个STW阶段)，暂停所有用户线程，从GC Root开始重新扫描整堆，标记存活的对象。需要注意的是，虽然CMS只回收老年代的垃圾对象，但是这个阶段依然需要扫描新生代，因为很多GC Root都在新生代，而这些GC Root指向的对象又在老年代，这称为“跨代引用”。

6、concurrent-sweep ，并发清理。


[HDFS使用QJM(Quorum Journal Manager)实现的高可用性以及备份机制]https://blog.csdn.net/zhanyuanlin/article/details/77816600



G1
https://docs.cloudera.com/HDPDocuments/HDP2/HDP-2.6.2/bk_hdfs-administration/content/ch_g1gc_garbage_collector_tech_preview.html

-XX:+UseG1GC -XX:MaxGCPauseMillis=4000 -XX:ParallelGCThreads=23

根据自己环境（CPU内存）来调，

NN hdp2.6.0慢排查https://zhuanlan.zhihu.com/p/127022985

* 字体
*斜体文本*
_斜体文本_
**粗体文本**
__粗体文本__
***粗斜体文本***
___粗斜体文本___
<u>带下划线文本</u>

字颜色大小
<font size="3" color="red">This is some text!</font>
<font size="2" color="blue">This is some text!</font>
<font face="verdana" color="green"  size="3">This is some text!</font>


## 改用G1收集器

## 参考资料  


