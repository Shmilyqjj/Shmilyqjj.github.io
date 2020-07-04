---
title: Apache Kudu学习篇
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
  - Kudu
keywords: Kudu
description: Fast Analytics on Fast Data.
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kudu/Kudu-cover.png
abbrlink: a138bbfb
date: 2020-07-04 12:26:08
---

# Apache Kudu  

## 前言
  离线大数据分析处理固然是大数据整个业务流程中必不可少的部分，但它已经很难满足当前的业务需求，数据时效性也越来越受到从业者及业务部门的重视，所以Flink，Storm等实时计算框架以及HBase存储开始被广泛使用，但仍然面临一个问题，在既需要随机读写又需要OLAP批量数据分析的场景下，还没有比较好的解决方案，Kudu应运而生，它的定位介于Hadoop和HBase之间，是一个既支持随机读写又支持OLAP分析的存储引擎。本篇博客主要研究一下Kudu，对其应用场景，架构原理及基本使用做一个总结，方便后续回看。
## Kudu介绍  
  

### 适用场景

## Kudu架构原理

## Kudu使用  

``` java

```

## 总结


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



## 部署


