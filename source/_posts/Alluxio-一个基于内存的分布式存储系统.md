---
title: Alluxio - 一个基于内存的分布式存储系统
author: 佳境
avatar: 'https://wx1.sinaimg.cn/large/006bYVyvgy1ftand2qurdj303c03cdfv.jpg'
authorLink: www.shmily-qjj.github.io
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true  
date: 2019-9-26 22:16:00
tags:
  - 大数据
  - Alluxio
keywords: Alluxio
description: Alluxio调研-随手记
photos: http://r.photo.store.qq.com/psb?/V10aWFGB3ChSVt/gTdB5VZVD3n1G9mwn*nGk.F3ramDY4MDnk44dJkecO0!/r/dL4AAAAAAAAA
---
### Alluxio数据编排
![alt](https://vi2.xiu123.cn/live/2019/09/24/22/1002v1569336488318656852_b.jpg)   
### 什么是Alluxio


More info: [Writing](https://hexo.io/docs/writing.html)

### Run server

Alluxio调研

Alluxio基于三个核心组件：
	Master，负责管理文件和对象元数据
	Worker，管理节点的本地空间，以及管理文件和对象块以及与下面的存储系统的接口
	Client，允许分析和AI / ML应用程序与Alluxio连接


``` bash
$ hexo server
```

More info: [Server](https://hexo.io/docs/server.html)

### Generate static files

``` bash
$ hexo generate
```

More info: [Generating](https://hexo.io/docs/generating.html)

### Deploy to remote sites

``` bash
$ hexo deploy
```

More info: [Deployment](https://hexo.io/docs/deployment.html)