---
title: 系统学习JVM
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
  - Java
keywords: JVM
description: 系统学习一下JVM，很重要
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-cover.jpg
abbrlink: 508b5c7
date: 2020-03-21 12:19:00
---
# 系统学习JVM  
Java跨平台，一次编译到处运行，垃圾回收等特性离不开JVM，学习JVM的原理可以让我们在工作中更快速定位问题。写这篇的目的就是避免零零散散地学习JVM，那样效率很低，也方便以后回顾和复习。

## 字节码
学习之前先要学会简单分析字节码。
用户Java代码与JVM交互沟通的桥梁。代码编译为.class字节码给JVM运行。
```bash
 $ javac Hello.java
 $ javap -c Hello.class  # javap可查看字节码的操作数
```
JVM的程序运行是在栈上完成的，运行main方法自动分配一个栈帧，退出方法体时候再弹出相应栈帧。从javap得到的结果看，大多数字节码指令是不断操作栈帧。
整个过程：**Java 文件->编译器->字节码->JVM->机器码**
整个过程：**Hello.java -> Hello.class -> Java类加载器(JVM中) -> 执行引擎(JVM中) -> 通过操作系统接口解释执行+JIT**

## JVM
### 定义
JVM（JAVA虚拟机）是一个规范，定义了.class文件的结构，加载机制，数据存储，运行时栈等内容。
JDK8以后Java是编译与解释混合执行模式。
JDK8以后JVM的技术实现是HotSpot(包含一个解释器和两个编译器)。
两个编译器：可以动态编译，含server模式和client模式。
    client模式是一种轻量级编译器，也叫C1编译器，占用内存小，启动快，但是执行效率没有server模式高，默认状态下不进行动态编译，适用于桌面应用程序。
    server模式是一种重量级编译器，也叫C2编译器，启动慢，占用内存大，执行效率高，默认是开启动态编译的，适合服务器应用。
```text
 -XX:RewriteFrequentPairs   用于开启动态编译。
 -Xint:禁用JIT编译，UYZNGSUYZNGS即禁用两个编译器，纯解释执行。
 -Xcomp:纯编译执行，如果方法无法编译，则回退到解释执行模式解释无法编译的代码。
```

### 内存管理
* JVM内存区域如何划分？
![alt JVM-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-01.png)  
Java内存布局一直在调整，Java8开始彻底移除了持久代，使用MetaSpace(元空间)来代替。 => -XX:PermSize和-XX:MaxPermSize失效

Java的运行时数据区可以分成**堆、元空间(含方法区)、虚拟机栈、本地方法栈和程序计数器**

* 堆：存放绝大多数Java对象，是JVM中最大的一块内存，随着频繁创建对象，堆空间占用越来越大，需要不定期的GC。（JVM主要GC区域：堆和元空间）。是线程共享的。
   **对象是否被分配在堆中取决于对象的基本类型和Java类中存在的位置**：
    + 基本数据类型（byte,short,int,long,float,double,char）如果在方法体内声明则在栈上(栈帧的局部变量表)直接分配，其他情况在堆上分配。
    + int[]这样的数组类型不属于基本数据类型，在堆上分配。
* 栈：分虚拟机栈和本地方法栈。
    ![alt JVM-02](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-02.png)  
    + 虚拟机栈：Java中**每个方法被调用时都会创建一个栈帧，执行完后再出栈，所有栈帧都出栈后线程结束**。每一个方法对应一个栈帧，每一个线程对应一个栈。栈帧中包括：**局部变量表，操作数，动态链接，返回地址**，这些不是线程共享的。
    + 本地方法栈：与虚拟机栈相似，但它主要包含Native对象。本地方法栈有一个叫returnAddress的数据类型。
* 元空间：先对比一下JDK8和以前版本的方法区
    ![alt JVM-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-03.png)  
    Perm区(永久代)在JDK8废除，用元空间来取代。**好处：非堆区，使用操作系统内存，不会出现方法区内存溢出；坏处：无限制使用操作系统内存会导致操作系统崩溃。所以一般要加-XX:MaxMetaspaceSize参数来控制大小。**
    **方法区**：包含在元空间中。方法区存储：**类信息、静态（static）变量，常量（final），编译后的代码等数据**。是线程共享的。
* 程序计数器：在多线程切换的情况下，Java通过程序计数器来记录字节码执行到什么地方，这样能保证切换回来时能够从原来的地方继续执行。（相当于字节码的行号指示器）。程序计数器实现了**异常处理，跳转，循环分支**的功能。因为每个线程都有其独立的程序计数器，所以是线程私有的。




JAVA8元空间？为什么要元空间？为什么替代永久代？








## 小标题1  

## 小标题2  


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
## 一些常用Java命令


## 参考资料  
[Kafka史上最详细原理总结](https://blog.csdn.net/u013573133/article/details/48142677)
[Apache Kafka](http://kafka.apache.org/)

