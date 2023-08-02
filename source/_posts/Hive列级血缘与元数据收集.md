---
title: Hive列级血缘与元数据收集
author: 佳境
avatar: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/Resources/img/custom/avatar.jpg
authorLink: shmily-qjj.top
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true
tags:
  - 数仓
  - 表级血缘
  - 数据治理
keywords: 血缘
description: Hive列级血缘与元数据实时收集
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/CategoryImages/technology/tech05.jpg
date: 2023-08-02 12:16:00
---

# Hive列级血缘与元数据收集 

## 背景
大数据离线计算里不开Hive,而数据字典与数据血缘在数据治理中是最基本和必要的。数据字典和数据血缘可以大幅提升数据分析效率，方便分析人员快速了解业务。本文主要基于**Hive 3.x**实现列级血缘与元数据收集。

## 列级血缘收集
**思路**：使用Hive Hook机制零侵入实现列级血缘的收集。参考Hive源码中**org.apache.hadoop.hive.ql.hooks.LineageLogger**类，对其进行改造，即可实现列级别血缘关系的收集。

**Hook实现代码**：[**ColumnLevelLineageHook.java**](https://github.com/Shmilyqjj/ColumnLevelLineageListener/blob/master/hive-lineages-collector/src/main/java/top/qjj/shmily/lineage/ColumnLevelLineageHook.java)

**Hook部署**：打jar包，放入$HIVE_HOME/auxlib/下，修改hive-site.xml如下  
```xml
  <property>
    <name>hive.exec.post.hooks</name>
    <value>org.apache.hadoop.hive.ql.hooks.LineageLogger,top.qjj.shmily.lineage.ColumnLevelLineageHook</value>
  </property>
  <property>
    <name>column.lineage.enabled</name>
    <value>true</value>
  </property>
```

**注意事项**：hive.exec.post.hooks配置项需带有Hive原生Hook类org.apache.hadoop.hive.ql.hooks.LineageLogger，否则无法获取到列级别的血缘关系，原因见**org/apache/hadoop/hive/ql/optimizer/Optimizer.java:78**
![alt](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Hive/MetadataAndLineage/HiveLineage-1.png)  
只有指定了org.apache.hadoop.hive.ql.hooks.LineageLogger，才会添加Generator来生成列级血缘，否则默认针对其他Hook不收集列级别血缘。

## 元数据实时收集
**思路**：使用Hive Metastore Listener零侵入实现实时收集Hive元数据变更，参考源码中**org.apache.hive.hcatalog.listener.DbNotificationListener**或**org.apache.hive.hcatalog.listener.NotificationListener**类实现。

**Listener实现代码**：[**MetadataListener.java**](https://github.com/Shmilyqjj/ColumnLevelLineageListener/blob/master/hive-metadata-collector/src/main/java/top/qjj/shmily/metadata/MetadataListener.java)

**Listener部署**：打jar包，放入$HIVE_HOME/lib下，修改hive-site.xml如下
```xml
  <property>
    <name>hive.metastore.event.listeners</name>
    <value>top.qjj.shmily.metadata.MetadataListener</value>
  </property>
  <property>
    <name>metadata.listener.service.name</name>
    <value>hive_local</value>
  </property>
  <property>
    <name>metadata.listener.meta.server.rest</name>
    <value>http://host:port/metadata/receive</value>
  </property>
```

**注意事项**：
1. metadata.listener.service.name可以指定你的集群名称，用于区分多集群，影响输出结果中database\table的fqn(唯一标识)
2. metadata.listener.meta.server.rest指定元数据上报地址
3. 可以开启lastAccessTime属性统计，通过如下Hive原生参数
```xml
  <property>
   <name>hive.security.authorization.sqlstd.confwhitelist.append</name>
   <!-- <value>hive\.exec\.pre\.hooks</value> -->
   <value>hive\.*</value>
  </property>
  <property>
   <name>hive.exec.pre.hooks</name>
   <value>org.apache.hadoop.hive.ql.hooks.UpdateInputAccessTimeHook$PreExec</value>
  </property>
```  
4. 可以开启表统计信息，参数为hive.stats.autogather=true，会额外收集到如下信息
```text
  last_modified_by        xxxxx           
  last_modified_time      1690965029          
  numFiles                11                  
  numRows                 10                  
  rawDataSize             34                  
  totalSize               2433                
  transient_lastDdlTime   1690965096
```  
不建议在全局参数设置该参数，会影响写入性能，但可以针对部分表单独设置  
```sql
ALTER TABLE table_name SET TBLPROPERTIES ('hive.stats.autogather'='true');
```
