---
title: CentOS8安装CDH6安装与排坑
author: 佳境
avatar: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/img/custom/avatar.jpg
authorLink: /
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true
tags:
  - 大数据
  - CDH6+CentOS8
keywords: CDH6+CentOS8
description: CDH6+CentOS8安装过程与排坑
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-intro.jpg
abbrlink: 38328
date: 2019-10-29 10:50:40
---
# 前言  
一开始搭集群时，都是装Apache原生的Hadoop，Spark包，一个一个装，一个一个配，好麻烦，而且通过命令或REST监控还很不直观，直到我遇到了Cloudera Manager，这东西简直就是神器。  
[Cloudera Manager](https://www.cloudera.com/products/product-components/cloudera-manager.html)（简称CM），是Cloudera开发的一款大数据集群部署神器，而且它具有集群自动化安装、中心化管理、集群监控、报警等功能，通过它，可以轻松一键部署，大大方便了运维，也极大的提高集群管理的效率。  

CM的主要功能：
1. 管理：对集群进行管理，如添加、删除节点等操作
2. 监控：监控集群的健康情况，对设置的各种指标和系统运行情况进行全面监控
3. 诊断：对集群出现的问题进行诊断，会针对集群问题给出建议的方案
4. 集成：对hadoop生态的多种组件和框架进行整合，减少部署时间和工作量
5. 兼容：与各个生态圈的兼容性强

注意：如果按我的步骤操作，一定没有错，如果更换了版本或自定义了一些东西，可能会出问题！

## CDH架构
![alt CDH-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-01.jpg) 
CDH的组件：
 * Agent：在每台机器上安装，该代理程序负责启动和停止服务和角色的过程，拆包配置，触发装置和监控主机。
 * Management Service：负责执行各种监控，警报和报告功能角色等服务。
 * Database：存储配置和监视信息。通常情况下，多个逻辑数据库在一个或多个数据库服务器上运行。例如，Cloudera的管理服务器和监控角色使用不同的逻辑数据库。
 * Cloudera Repository：软件由Cloudera管理分布存储库。
 * Clients：是用于与服务器进行交互的接口



## 小标题1  

## 小标题2  


更多内容: [Writing](https://hexo.io/docs/writing.html)

## 原理（中标题） 

``` python
import re
lists = []
s = re.match(r".*\((.*)\).*",lists).group(1)
```
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