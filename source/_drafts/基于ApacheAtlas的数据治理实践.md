---
title: 基于ApacheAtlas的数据治理实践
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
  - 大数据治理
  - Atlas
keywords: 基于ApacheAtlas的数据治理
description: ApacheAtlas数据治理相关实践总结
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Atlas/Atlas-Cover.jpg
date: 2020-10-31 21:12:00
---
# 前言  


## ApacheAtlas介绍  
  
## ApacheAtlas使用  
### 编译安装
Windows编译坑点太多，暂时不写了，下面是使用Linux编译Atlas-2.1.0步骤
到[ApacheAtlas-Downloads](http://atlas.apache.org/#/Downloads)下载最新（目前2.1.0的源码包）
或到[apache/atlas-Github](https://github.com/apache/atlas)下载master分支zip包
```shell
tar -zxvf apache-atlas-2.1.0-sources.tar.gz
cd apache-atlas-sources-2.1.0/
编译：
export MAVEN_OPTS="-Xms2g -Xmx6g"
mvn clean -DskipTests install
mvn clean package -DskipTests  -Pdist
遇到的问题1：
[ERROR] Failed to execute goal com.github.eirslett:frontend-maven-plugin:1.4:install-node-and-npm (install node and npm) on project atlas-dashboardv2: Could not download Node.js: Could not download https://nodejs.org/dist/v12.16.0/node-v12.16.0-linux-x64.tar.gz: Remote host closed connection during handshake: SSL peer shut down incorrectly -> [Help 1]
解决：手动下载node-v12.16.0-linux-x64.tar.gz然后放到指定位置/usr/share/maven/localRepo/com/github/eirslett/node/12.16.0/
遇到的问题2：
[INFO] Downloading https://nodejs.org/dist/v12.16.0/node-v12.16.0-linux-x64.tar.gz to /usr/share/maven/localRepo/com/github/eirslett/node/12.16.0/node-12.16.0-linux-x64.tar.gz
[INFO] No proxies configured
[INFO] No proxy was configured, downloading directly
一直卡住，没有下载 解决：
手动下载node-v12.16.0-linux-x64.tar.gz然后放到指定位置并重命名为/usr/share/maven/localRepo/com/github/eirslett/node/12.16.0/node-12.16.0-linux-x64.tar.gz
遇到的问题3：
[INFO] Downloading http://registry.npmjs.org/npm/-/npm-6.13.7.tgz to /usr/share/maven/localRepo/com/github/eirslett/npm/6.13.7/npm-6.13.7.tar.gz
[INFO] No proxies configured
[INFO] No proxy was configured, downloading directly
一直卡住，没有下载 解决：
手动下载npm-6.13.7.tgz然后放到指定位置并重命名为/usr/share/maven/localRepo/com/github/eirslett/npm/6.13.7/npm-6.13.7.tar.gz
遇到的问题4：
[INFO] Running 'npm install' in /opt/software/atlas-2.1.0/apache-atlas-sources-2.1.0/dashboardv2/target
这步卡太久原因是npm默认国外源
解决方案：/opt/software/atlas-2.1.0/apache-atlas-sources-2.1.0/dashboardv2/target/node/npm config set registry https://registry.npm.taobao.org
遇到的问题5：
Connect to repo.spring.io:443 [repo.spring.io/xx.xx.xx.xx]
网络原因，重新import即可
最终编译成功，生成的包在/opt/software/atlas-2.1.0/apache-atlas-sources-2.1.0/distro/target
```




修改HBase配置
cd $ATLAS_HOME/conf/hbase
cp hbase-site.xml.template hbase-site.xml
vim hbase-site.xml修改hbase.rootdir和hbase.zookeeper.property.dataDir为file:///xx/xx形式(本地存储)
修改Solr配置
cd $ATLAS_HOME/conf/hbase
vim solrconfig.xml 修改dataDir
修改zookeeper配置
cd $ATLAS_HOME/conf/zookeeper
cp zoo.cfg.template zoo.cfg
vim zoo.cfg修改dataDir和clientPort

## SparkAtlasConnector  
**[Spark-Atlas-Connector](https://github.com/hortonworks-spark/spark-atlas-connector)**简称SAC，是用于连接Spark和Atlas，帮助Atlas收集Spark任务血缘的组件，它通过SparkListener来监听Spark程序发生的所有操作，SparkListener返回一个EventQueue包含了Spark程序执行的各个阶段的事件，SAC从EventQueue中获取到关心的DDL、DML等事件并解析成血缘，在Atlas中建立SparkModel，并通过Kafka将血缘信息异步发送到Atlas。
编译过程：
```

```

原理：


## 总结 

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


## 参考资料  
[ApacheAtlas官网](http://atlas.apache.org/#/)
[]()

