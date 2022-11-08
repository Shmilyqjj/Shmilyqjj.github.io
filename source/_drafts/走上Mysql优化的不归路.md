---
title: Mysql性能优化之基础优化
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
  - Mysql
keywords: Mysql优化
description: Mysql基准测试，服务器性能，Schema与数据类型的优化
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/CategoryImages/technology/tech06.jpg
abbrlink: 26078
date: 2019-11-15 21:39:39
---
# 前言  

## 什么是xxxx（中标题）  
## 小标题1  

## 小标题2  

### 

大量sleep进程怎么解决：
每个mysql连接都消耗资源，而且mysql的连接数是有上限的，如果连接数达到上限，会报错too many connections，所以完成相应操作后应该关闭进程释放连接  
为什么会出现大量sleep进程：多个程序同时操作同一mysql server，而mysql默认进程超时时间是28800（8小时）
优化方案：
编辑 /etc/my.cnf,在mysqld 下新加timeout参数，设置为120秒，如下：
[mysqld]
wait_timeout=120
interactive_timeout=120
要同时设置interactive_timeout和wait_timeout才会生效。
重启一下mysql 生效 即可！


其他SQL优化技巧：
select a,b from tb where col = 'xxx'如果明确知道只能返回一条结果，则加limit 1，这样查询到一半找到了这条，mysql主动停止游标移动，不会再读后面的数据。
