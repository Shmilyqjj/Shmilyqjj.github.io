---
title: 《鸟哥的Linux私房菜》读书笔记
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
  - Kafka
keywords: Kafka
description: 每天与Linux打交道，要熟悉呦！
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kafka/Kafka-Cover.jpg
abbrlink: c8fda62b
date: 2020-08-15 12:19:00
---
# 前言
  《鸟哥的Linux私房菜》是一本非常经典的Linux学习书籍，在业界比较有地位，而每天的工作都要与它打交道，无论是服务部署运行，还是性能优化都与Linux息息相关，这就需要对Linux有深入的了解，才能更快地定位问题并从底层解决问题。当然写这篇也是为了汲取书中精华，并方便后面回看，同时也希望能给大家带来帮助。
## 序章
序章主要讲计算机各个组件组成及操作系统相关概念。
```
1.计算机由输入单元、输出单元、CPU控制单元、算数逻辑单元和主存储器。CPU控制数据流进、流出内存，CPU要处理的资料完全来自内存所以内存不足性能下降
2.CPU分精简指令集RISC和复杂指令集CISC。ARM就是精简指令集，X86（32位，一次读32位信息）和X86_64（一次读64位信息）则为复杂指令集
3.1byte=8bits 文件容量采用二进制1GBytes=1024*1024*1024Bytes，CPU速度采用十进制1GHZ=1000*1000*1000HZ。硬盘比标称容量小也是类似原因
4.超线程(Hyper-Threading),CPU指令周期短，运算核心经常空闲，CPU将缓存器分两部分，程序可以分别使用这两部分缓存器，则同时可以有两个程序竞争一个CPU运算单元，相当于两个核心，充分利用CPU性能，减少空闲浪费。、
5.磁盘就是在以盘中心为同心圆切出一个个小区块（称为扇区），磁头会在扇区上做读写操作。
6.磁盘转一圈，在外圈会有更多扇区，转一圈读取的数据量比内圈多，所以磁盘写数据都从外向内写。
7.文字也是用二进制来存储的，通过字码对照表识别，常用的英文编码表为ASCII表。英文数字或符号都占用1bytes，也就是2的8次方=256种变化。为了解决非英语国家文字识别问题制定了Unicode编码系统，也就是UTF-8。
8.操作系统也是一组程序，这组程序重点在于管理计算机的所有活动以及驱动系统中所有硬件。实现这些功能都是需要核心(Kernel)的支持。
9.核心开机就被加载到内存且是受保护的。
10.为了保护核心，且让开发者能方便地开发软件，操作系统会给开发者提供开发接口，这就是系统呼叫层。
11.操作系统的Kernel参考硬件规格写成，所以同一个操作系统不能在不同的硬件架构下运行。操作系统只是在管理硬件资源。
```
  
## 第一章 Linux是什么及如何学习
```
1.Linux是操作系统，包含核心和系统呼叫两层，应用程序不属于操作系统。Linux具有可移植性。
2.从Unix开始，系统所有的程序和装置都是文件。
3.GNU计划：建立一个自由，开放的Unix系统。掀起了自由软件开源软件浪潮。gcc编译C的编译程序：GNU C Compiler。为了避免GNU自由软件没人利用成为专利软件，成立了GPL通用公共许可证。

```


## 原理（中标题） 

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
[Kafka史上最详细原理总结](https://blog.csdn.net/u013573133/article/details/48142677)
[Apache Kafka](http://kafka.apache.org/)

