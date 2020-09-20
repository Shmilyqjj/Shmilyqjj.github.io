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
https://blog.csdn.net/jinnee/article/details/70224512
https://www.w3cschool.cn/orientdb/orientdb_basic_concepts.html
https://blog.csdn.net/clj198606061111/article/details/82314459

# 图数据库通用概念  


## OrientDB特点

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

