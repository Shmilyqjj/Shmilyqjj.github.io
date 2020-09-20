---
title: 图数据库之OrientDB
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
  - 图数据库
keywords: OrientDB
description: 图数据库之OrientDB
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/OrientDB/OrientDB-cover.jpg
date: 2020-09-21 10:16:00
---
# 图数据库简介  
&emsp;&emsp;图数据库是一种NoSQL数据库，使用图形理论存储实体间关系，常见例子是社会网络中人与人的关系。图数据库能更好地反映实体间多对多的关系(关系网络)。与传统关系型数据库相比，如果关系网络数据使用关系型数据库存储，会带来更多存储开销，更复杂的查询逻辑，更多的服务器负载和更高的查询延迟，图数据库的多层次多样性复杂关系查询、海量关系数据存储和查询弥补了这些不足。
&emsp;&emsp;目前图数据库一些常见的应用场景：公司关系、社交关系、风控领域、金融与资金关系网络、知识图谱、基于图模型训练、基于社交关系网络的社交推荐(拼多多的商品推荐，抖音的视频推荐，头条的内容推荐)、识别团伙作案等等。

# 图数据库通用概念  
https://zhuanlan.zhihu.com/p/79484631

## OrientDB特点

https://blog.csdn.net/jinnee/article/details/70224512
https://www.w3cschool.cn/orientdb/orientdb_basic_concepts.html
https://blog.csdn.net/clj198606061111/article/details/82314459
http://www.orientdb.org/docs/3.0.x/

### 优点

### 缺点

## OrientDB原理

## OrientDB使用  

### OrientBD安装
```
tar -zxvf /opt/software/orientdb-3.1.2.tar.gz  -C /opt/modules/
cd /opt/modules/orientdb-3.1.2/
vim /etc/profile  添加ORIENTDB_HOME和ORIENTDB_PATH source /etc/profile
vim /opt/modules/orientdb-3.1.2/bin/orientdb.sh 修改ORIENTDB_DIR为/opt/modules/orientdb-3.1.2/ 修改ORIENTDB_USER为root
sudo cp $ORIENTDB_HOME/bin/orientdb.sh /etc/init.d/orientdb
vim /usr/bin/orientdb  编写#!/bin/bash 换行 source /etc/profile 换行 sh $ORIENTDB_HOME/bin/console.sh  然后chmod 744 /usr/bin/orientdb
service orientdb start   （关闭是service orientdb stop）
service orientdb status
chkconfig orientdb on
ps -ef | grep orientdb可以看到已启动
连接console: orientdb
进入WebUI界面:http://host:2480/studio/index.html#/  账户admin密码admin
```  

### 控制台命令

### WebUI使用

### 连接工具类
```java

```

## 参考

