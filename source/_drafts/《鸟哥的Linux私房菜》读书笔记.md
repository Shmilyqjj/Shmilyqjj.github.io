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
4.同时启动两个进程在一个CPU上要比一个一个执行更耗时一些因为切换消耗CPU时间。
5.程序执行时有一个最大CPU时间，若超过这个时间会被推出，等待下次轮到CPU时间片。
6.POSIX(Portable Operating System Interface)，规范核心与应用程序之间的接口。Linux开发依照POSIX标准，而POSIX标准针对Unix的，所以Linux就兼容Unix软件了。Linux也被称为类Unix。
7.不同发行版采用Linux内核基本一致且都依赖LinuxStandardBase(LSB)标准和目录架构的FileSystemHierarchyStandard(FHS)标准。所以基本上只有架构严谨度和包管理方式不同。
8.X Window System是Linux上的一个套件，用于桌面显示，即使崩了，Linux系统也能正常使用。
9.Linux自带文档以及应用文档路径：/usr/share/doc/xx
```

## 第二章 主机规划与磁盘分区
```
1.在Linux系统中，每个装置都被当成一个文件夹，比如SATA接口硬盘为/dev/sda /dev/sdb...
2.几乎所有的硬件装置文件都存放在/dev这个目录
3.磁盘有sda，sdb，sdc等等，还有vda，vdb（虚拟磁盘）等
4.Linux内核侦测磁盘顺序？如果有5个插槽，硬盘A插在SATA1，B插在SATA4，USB盘C，按侦测顺序，硬盘A为/dev/sda，硬盘B为/dev/sdb，USB盘开机才被加载为/dev/sdc
5.机械硬盘由磁盘盘，机械臂读取头和马达组成，数据写在磁盘盘上，磁盘盘又分Sector扇区和Track磁道。
6.早期磁盘第一个扇区记录整个磁盘的重要信息，称为MasterBootRecord(MBR)。现在的磁盘格式GUIDpartitionTable(GPT)。MBR和GPT为两种分区表格式。
7.MBR分区表只有64bytes只能容纳4个分区记录，通过延伸分区利用额外扇区记录更多分区信息来实现分更多分区。延伸分区名称/dev/sda1，/dev/sda2...windows识别磁盘顺序也是按磁柱(同一个磁道)的顺序排为C，D，E，F...
8.对于MBR，磁盘分区可以提高读写性能，因为如果在C盘，只会找那个分区的磁柱范围，数据集中，检索速度提高。
9.GPT分区没有主，延伸，逻辑分区概念，每个分区都是独立存在的。
10.开机管理程序grub不认识GPT，grub2才认识GPT。
11.是否能读写GPT磁盘与开机检测程序有关，开机检测程序分BIOS和UEFI。因为操作系统也是软件，怎么打开OS这个大软件呢，就要靠BIOS或UEFI。
12.UEFI和BIOS都是在主板上的程序，开机首先运行它。UEFI是C语言编写，比汇编的BIOS更容易开发。
13.UEFI的SecureBoot要关闭才能启动Linux。
14.安装Linux分区，初级分法只需要分/和swap两个区即可。建议加一个分区用于备用。对于多用户的情况，可以将/home独立在一个分区上并加大容量。一些服务器数据或log会存在于/var，可以独立出来并加大容量。
```

## 第三章 安装CentOS7
```
1.Linux下使用dd刻录iso镜像：dd if=xxx.iso of=/dev/sdc
2.Linux常见文件系统格式，ext4，xfs，vfat等，xfs性能较ext4好。vfat同时支持win和linux。
3.LVM是 Logical Volume Manager(逻辑卷管理)的简写,它是Linux环境下对磁盘分区进行管理的一种机制。
4.直接使用fdisk分区挂载的话，随着时间的推移，数据量越来越大，硬盘空间越来越小，要想扩充容量的话，就必须挂载新硬盘然后做数据迁移，这就必然导致前台业务的停止，不符合企业需求，因此完美的解决方法应该是在零停机前提下可以自如对文件系统的大小进行调整，可以方便实现文件系统跨越不同磁盘和分区。Linux提供的逻辑盘卷管理（LVM，Logical Volume Manager）机制就是一个完美的解决方案。
5.LVM逻辑分区管理通过将底层物理硬盘抽象封装起来，以逻辑卷的形式表现给上层系统，逻辑卷的大小可以动态调整，而且不会丢失现有数据。新加入的硬盘也不会改变现有上层的逻辑卷，大大提高了磁盘管理的灵活性。
6.LVM支持快照功能和调整分区大小的功能。 
6.Swap交换内存是利用磁盘充当内存，当物理内存不够时，使用Swap存一些在内存中不被CPU常用的内容。
7.以前建议Swap是物理内存的两倍，不过现在RAM都比较大了，Swap几个G就够了，不要太大。如果用到了Swap，那证明物理内存还是需要加。
8.CentOS7下，安装完成后有/root/anaconda-ks.cfg文件，安装的依赖，root密码等都保存在里面，这个文件可以修改成自动安装脚本，用来安装相同规格参数的系统。使用KickStart。
9.安装Linux时一般会用到的内核参数acpi=off acpi_osi=! acpi_osi="Windows 2009" pci=noacpi等等
10.chroot命令，在根目录下执行，修改根目录为一个新文件夹
11.df -T可以看到linux目前使用的文件系统。CentOS7默认为xfs文件系统
```

## 第四章 首次登入与在线求助
```
1.文件、文件夹名只要以小数点开头即为隐藏文件，ls看不到需要ls -a
2.Linux分为6个操作接口环境tty1-tty6 切换方式CTRL+ALT+[F1~F6] 切换到文字接口后按CTRL+ALT+F1切换回图形界面
3.一行命令太长可以用"\"切到下一行继续输入
4.显示隐藏文件ls -al或ls -a或ll -a或ls -a -l
5.控制台有乱码，先locale查看目前支持的语系，两条命令LANG="en_US.UTF-8"和export LC_ALL="en_US.UTF-8"解决本次登陆出现的乱码问题
6.基础指令学习：
  date +%Y/%m/%d  年月日
  date +%H:%M:%S  时分秒
  date +%s        时间戳
  cal                 日历
  cal [month] [year]  某年某月的日历
  bc 计算器用于加减乘除指余 quit离开计算器
7.CTRL+C关闭正在运行的指令  CTRL+D有EOF(END OF FILE)和End of Input的意思
8.SHIFT+PAGE UP/PAGE DOWN 翻页
9.man command获取命令的帮助信息- 命令的介绍和使用  空格和PAGEDOWN下翻页 PAGEUP上翻页  man可以用/和n搜索（像vim一样）
10.man命令不仅局限于看命令的介绍和使用，还可以看linux系统文件的说明，还有其他很多类型，具体看man man
11.man命令的配置文件/ect/man_db.conf数据文件/usr/share/man/
12.
该4.3.3
```








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

