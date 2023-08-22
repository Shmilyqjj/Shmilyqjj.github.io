---
title: 《鸟哥的Linux私房菜》读书笔记
author: 佳境
avatar: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Linux/Linux-ng-cover.jpg
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
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Linux/Linux-ng-cover.jpg
abbrlink: c8fda62b
date: 2020-08-22 12:19:00
---
# 前言
&emsp;&emsp;**《鸟哥的Linux私房菜》**是一本非常经典的Linux学习书籍，作为数据平台开发从业者，每天的工作都要与它打交道，无论是服务部署运行，性能优化还是问题排查都与Linux息息相关，这就需要对Linux有深入的了解，才能更快地定位问题并从底层解决问题。好记性不如烂笔头，写这篇也是为了汲取书中精华，做一个读书笔记，方便后面回看加深印象，同时也希望能给大家带来帮助。
&emsp;&emsp;Tips:我尽量挑选必要的部分做笔记，一些过于基础的东西就不记啦，当然有些需要明确且重要的基础知识还是会记录的。点代码框上的TEXT可全屏放大看呦！
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
5.机械硬盘由磁盘盘，机械臂读取头和马达组成，数据写在磁盘盘上，磁盘盘又分Sector扇区和Track磁道。(通过fdisk -l命令可以看到Sector数量)
6.早期磁盘第一个扇区记录整个磁盘的重要信息，称为MasterBootRecord(MBR)。现在的磁盘格式GUIDpartitionTable(GPT)。MBR和GPT为两种分区表格式。
7.MBR分区表只有64bytes只能容纳4个分区记录，通过延伸分区利用额外扇区记录更多分区信息来实现分更多分区。延伸分区名称/dev/sda1，/dev/sda2...windows识别磁盘顺序也是按磁柱(同一个磁道)的顺序排为C，D，E，F...
8.对于MBR，磁盘分区可以提高读写性能，因为如果在C盘，只会找那个分区的磁柱范围，数据集中，检索速度提高。
9.GPT分区没有主，延伸，逻辑分区概念，每个分区都是独立存在的。
10.开机管理程序grub不认识GPT，grub2才认识GPT。
11.是否能读写GPT磁盘与开机检测程序有关，开机检测程序分BIOS和UEFI。因为操作系统也是软件，怎么打开OS这个大软件呢，就要靠BIOS或UEFI。
12.UEFI和BIOS都是在主板上的程序，开机首先运行它。UEFI是C语言编写，比汇编的BIOS更容易开发。
13.UEFI的SecureBoot要关闭才能启动Linux。
14.安装Linux分区，初级分法只需要分/和swap两个区即可。建议加一个分区用于备用。对于多用户的情况，可以将/home独立在一个分区上并加大容量。一些服务器数据或log会存在于/var，可以独立出来并加大容量。
15.fdisk命令可以查看磁盘以及添加、删除、转换磁盘分区等操作
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
4.显示隐藏文件ls -al或ls -a或ll -a或ls -a -l    常用:ls -l -trh按修改时间逆序友好输出
5.控制台有乱码，先locale查看目前支持的语系，两条命令LANG="en_US.UTF-8"和export LC_ALL="en_US.UTF-8"解决本次登陆出现的乱码问题
6.基础指令学习：
  date +%Y/%m/%d  年月日
  date +%H:%M:%S  时分秒
  date +%s        时间戳
  date "+%Y-%m-%d %H:%M:%S"
  cal                 日历
  cal [month] [year]  某年某月的日历
  bc 计算器用于加减乘除指余 quit离开计算器
7.CTRL+C关闭正在运行的指令  CTRL+D有EOF(END OF FILE)和End of Input的意思
8.SHIFT+PAGE UP/PAGE DOWN 翻页
9.man command获取命令的帮助信息- 命令的介绍和使用  空格和PAGEDOWN下翻页 PAGEUP上翻页  man可以用/和n搜索（像vim一样）
10.man命令不仅局限于看命令的介绍和使用，还可以看linux系统文件的说明，还有其他很多类型，具体看man man
11.man命令的配置文件/ect/man_db.conf数据文件/usr/share/man/
12.info命令与man差不多，也是用来查询命令用法和文件格式，但信息拆分多个节点显示。默认数据路径在/usr/share/info。N下一个P上一个U上一层节点。
13.LInux说明文档路径/usr/share/doc
14.动态查看当前网络连接状态信息netstat -a
15.查看当前谁在线who或w
16.Linux关机前sync命令是必要的。Linux为了加快读取速度，默认已经加载到内存中的数据不会写回磁盘，我们的改动不会持久化，所以关机前多执行几次sync将数据同步到磁盘。
17.虽然目前shutdown/reboot/halt都在关机前执行sync，但手动sync更放心。非root帐号sync只同步自己的数据，root帐号sync同步全局数据。
18.shutdown很多功能，可以用man shutdown多了解。功能如定时关机。
19.重启：sync;sync;sync;reboot
```

## 第五章 LInux的文件权限与目录配置
```
1.每个用户都可以有多个群组支持
2.使用者User、群组Group和其他人Others可以想象成王大毛、王大毛家和张三，个人有自己的权限，家庭成员有共有的权限，外人也有自己的权限。
3.无论任何用户和群组设置任何权限，root用户都可以访问和修改。[root是万能的天神]
4.所有用户及其家路径和登陆信息权限信息都在/etc/passwd，所有组名及其包含的用户都记录在/ect/group，所有用户加密密码都在/etc/shadow
5.ls -l输出的信息从左到右：
    -rw-r--r--   1 root root  5041  5月 31 18:48 rootfs-pkgs.txt
     权限   连接数  用户 组  大小bytes   最后修改时间   文件名
6.权限中各个字符表示
    * 第一个：d目录 -文件 l链接  b块设备文件  c字符设备  p命名管道文件  s套接字文件
    * 第2.3.4/5.6.7/8.9.10：三个一组 r可读  w可写 x可执行   三组分别三用户 组 其他人
7.连接数：Linux文件权限属性都记录在i-node，连接数表示有多少个不同的文件名连接到同一个i-node
8.drwxr-xr-- 其他用户虽然有读权限，但没执行权限，则不能进入该目录（x权限决定是否能进入目录）
9.chgrp改变群组 chown改变所有者 chmod改变权限  chown root:root -R /xx/xx改变xx目录及里面所有文件的用户为root组为root
10.chmod [u\g\o\a] [+-=] [r\w\x] /path/file  u用户 g群组 o其他人 a全部 +增加权限 -去除权限  =设定权限   例：chomd u=rwx,go=rx /path/a  例：chmod a+w /path/a
11.Linux下文件是否可执行只与x权限有关，与扩展名无关
12.对于文件的w权限，只是写入、修改、增加等权限，并不是指有删除权限，
     例子1：
     -rw-r--r-- 1 root   root     0  8月 21 21:43 aaa  
     [shmily@shmily ~]$ rm aaa
     rm：是否删除有写保护的普通空文件 'aaa'？y
     例子2：
     -rwxrwxrwx 1 root   root     0  8月 21 21:45 bbb 
     [shmily@shmily root]$ rm aaa
     rm: cannot remove ‘aaa’: Permission denied
     注意：
     aaa虽然是其他用户，只有r权限，不能编辑和执行，但由于aaa在shmily的家目录，shmily对自己家目录有完全的rwx权限，所以可删。
     bbb虽然是777权限，但因为在root的家目录，shmily用户对root目录没有任何权限，所以不能删除root目录下的bbb文件
     -rwxrwxrwx权限：该文件任何人都可以读取修改编辑和执行，但不一定能删除
13.对于文件夹的w权限，有w则可以删除更新新建其下任何文件 开放目录给其他用户浏览时给r和x权限，w权限不可轻易给
14.b代表块设备文件 ll /dev/sda可看.块设备就是存储数据的接口设备，如硬盘，ssd
15.c字符设备 ll /dev/tty可看到 一般是输入设备如键盘鼠标等
16.s套接字文件，资料接口文件sockets，常在/run和/tmp看到
17.p命名管道文件，数据传送文件FIFO Pipe
18./usr与软件安装执行有关，/var与系统运作过程有关
19.根目录的意义与内容
    /bin -> usr/bin 存放一些可以被root和其他用户使用的命令如cat chmod mv cp date mkdir bash等
    /boot 主要存放开机使用到的文件包括Linux Kernel、EFI、grub等（Kernel文件是vmlinuz）
    /dev 任何装置和接口设备都是文件形式存在这个目录
    /etc 系统主要的配置文件 其他用户可查看，只有root用户可修改
    /lib 依赖函数库存放路径 一些/bin /sbin下的指令依赖
    /media 存放可移除装置
    /mnt 挂载路径
    /opt 第三方软件存放位置
    /run 存放运行时相关文件 df命令可以看到/run是tmpfs，也就是/run基于内存和交换空间的，速度快
    /sbin 存放开机过程需要的包括了开机、修复、还原系统所需命令(包括fdisk、fsck、ifconfig、mkfs) /sbin -> /usr/sbin
    /srv service的缩写，一些网络服务WWW\FTP等需要读取的数据目录。
    /tmp 一般用户或正在执行程序存放临时文件的目录，任何人都可存取
    /home 家目录 等同于~ 里面存放多个用户的用户目录  ~代表当前用户家目录 ~shmily用户shmily的家目录 -代表前一个工作目录(cd -)
    /lib64 存放于/lib不同的二进制函数库
    /root root的家目录
    /lost+found ext2/3/4才有 存放系统错误时产生的片段
    /proc 本身是一个虚拟文件系统，存在内存中，存放当前系统核心、进程、装置状态及网络状态等信息
    /sys 也是一个虚拟文件系统，记录核心和硬件相关信息，包括已加载的核心模块和核心侦测到的硬件装置信息
20./usr usr(Unix Software Resource) 这个目录很重要
    /usr/bin 即/bin
    /usr/lib 即/lib
    /usr/local root用户安装的软件或同一软件不同版本可安装在这
    /usr/sbin 即/sbin
    /usr/share 只读数据文件和共享文件
    /usr/games 游戏相关数据
    /usr/include c/c++头文件header和include存放位置
    /usr/libexec 不被普通用户使用的执行脚本或命令
    /usr/lib64 即/lib64
    /usr/src 放置源码
21./var 主要存放常常变动的文件
    /var/cache 存放程序运行时暂存文件
    /var/lib 程序执行时存放数据文件的目录，各个程序所需数据在下面都有单独目录如/var/lib/mysql
    /var/lock 锁文件 某些程序同时只能被一个用户调用
    /var/log 重要 登陆日志和程序日志
    /var/mail 同/var/spool/mail 存放邮件
    /var/run 同/run
    /var/spool 存放一些队列数据即排队等待其他程序使用的数据，类似于中间件消费，被使用后则删除消息。系统收到新信息放在/var/spool/mail如果没被查看则到/var/spool/mqueue，crontab调度产生的信息放在/var/spool/cron
22.经常看到./xxx.sh执行脚本./代表本目录，当前目录
23.uname -r查看系统内核版本 uname -a显示uname的所有信息
24.groupadd guest添加一个guest组，useradd -G guest guest创建guest用户支持guest组，useradd -g guest guest1创建guest1并将它加入guest组，id guest查看guest用户属性
25.Linux非root用户home目录指定与迁移（home目录很多场景放在系统盘，但系统盘空间有限，用户多了容易把系统盘打满，所以需要指定或迁移用户目录到数据盘避免影响系统正常运行）：
    ①创建qjj用户，指定家目录到data盘 useradd qjj -d /data/home/qjj 此时可观察到qjj用户的家目录权限为750且ll -a看到默认会多三个文件：.bash_logout .bash_profile和.bashrc
    ②迁移qjj用户家目录 mkdir -p -m 1777 /data/home;mv /home/qjj /data/home/  vim /etc/passwd改用户家目录地址  （短暂的时间不可用）
```

## 第六章 Linux文件与目录管理
```
1.pwd -P在link目录下显示真实路径而非链接路径  pwd全称：print working directory打印当前工作目录
2.mkdir -m 766 dir 创建目录并直接指定权限，而非a=rwx-umask  umask是预设权限，在命令行输入umask可看到0022默认值，新建目录默认a=rwx-umask=777-022=755
3.ls命令支持各种其他参数比如按时间排序，按大小排序，显示隐藏文件，带完整时间，排序结果倒序列出inode号等，具体man ls或ls --help查看
4.cp命令常用的参数
   -d 若原文件是链接则复制链接而非文件本身，不加-d则拷贝文件本身
   -r 递归复制
   -i 如果已存在目标，覆盖前询问
   -p 复制时连同文件属性一起复制，而非使用默认属性
   --preserve=all 除了-p权限外还SELinux属性，链接，xattr属性也复制了，如果复制多个目标，最后目标路径必须为目录
   -a 等价于 -dr --preserve=all
   -s 复制为符号链接
   -l 复制为硬链接而非文件本身
   cp到当前目录  cp /xx/xx/a.txt .
5.rm命令常用参数
   -f 忽略一切错误，强制，不弹出错误
   -i 互动模式，询问是否删除
   -r 递归删除
6.创建-开头的文件并删除 touch ./-aaa-  rm ./-aaa-或touch -- -aaa-  rm -- -aaa-
7.mv命令常用参数 mv -f强制  -i询问  -u源目录比目标目录文件新才会覆盖更新
8.basename和dirname命令：basename取得最后的文件名，dirname取得文件所在目录名 所以文件的绝对路径即echo $(dirname $FILE)/$(basename $FILE)
9.文件内容查阅[重要] 查日志必备
   cat从第一行开始显示 -n打印行号 -b打印非空行行号 -E打印出换行符 -T显示Tab -v列出看不到的特殊字符 -A等于-vET显示特殊字符
   tac从最后一行开始显示，显示最后一行到第一行
   nl显示时顺便输出行号 -ba等于cat -n，-bt等于cat -b，-n ln行号显示最左边
   more一页一页显示文件内容 空格向下翻页，Enter向下一行，/搜索，:f显示文件名和行数，q离开，b向前翻页
   less与more相似但可以往前翻页 PAGEDOWN或空格向下翻页，PAGEUP向上翻页，/或?搜索n正向搜索N反向搜索，g去第一行G去最后一行，q离开
   head只看头几行-n 20看头20行，-n -20除了后20行都看
   tail只看尾几行-n 20看后20行，-f持续侦测变动，取11-20行：head -20 /xx/a.log | tail -n 10,取11-20行且输出行号cat -n /xx/a.log | head -n 20 | tail -n 10
   od以二进制方式读文件 od -t指定输出类型（a默认，c用ASCII，d[size]十进制，f[size]浮点数，o[size]八进制,x[size]十六进制，-oCc八进制列出值和ASCII对照表）
10. Linux文件mtime文件内容变更时间(非属性权限变更)  ctime权限被修改的时间  atime内容被读取访问的时间(如cat后)  查看方式date;ll aaa;ll aaa --time=atime;ll aaa --time=ctime默认输出mtime，然后依次输出atime和ctime
11.touch -a/c/d/m/t 可以修改文件的时间
12.文件预设权限umask 创建一个文件或目录的默认权限与之有关 查看: umask或umask -S  设置umask:umask 002全局umask设置在/etc/bashrc 注:0022第一个0就是特殊权限用的
13.Linux隐藏权限   可通过chattr设定，通过lsattr查看  [ext2/3/4才有完整支持chattr]
    chattr [+-=] [ASacdisu] pathOrFile
    A 存取不会更新atime 降低IO负载
    S 一般更新存储文件是异步的，加这个属性会同步写
    a 只有root才能设定的属性 作用：这个文件只能增加数据，不能删除和修改
    c 自动压缩这个文件，使用时自动解压--对大文件和不常用log很有用
    d 避免dump程序备份这个文件
    i 让一个文件不能更新删除写入和链接 只有root能设置
    s 删除时彻底删除，完全救不回来
    u 与s相反，如果被删除，数据内容还留在磁盘，可以恢复
    示例(锁住一个文件不让修改删除和链接)：chattr +i /etc/ntp.conf ; lsattr /etc/ntp.conf 
14.文件特殊权限SUID、SGID、SBIT
    -rwsr-xr-x 1 root root 63640  7月 16 04:15 /usr/bin/passwd
    drwxrwxrwt  21 root root  1040  8月 25 21:16 /tmp
    drwsr-sr-x 2 shmily shmily     40  7月19日 16:23  qjj
    SUID：(S或s,可执行为s,不可执行为S) /usr/bin/passwd中s在拥有者x位置，表示SUID权限 用户执行该binary程序过程中暂时拥有该程序所有者的权限  场景：用户通过passwd改自己密码，但不能直接访问读写/etc/shadow;再如Hadoop Yarn的可执行文件container-executor(权限6050)  注:权限仅对二进制文件有效，对目录和非二进制文件无效
    SGID：(S或s,可执行为s,不可执行为S) 对目录设定，在该目录建立的文件的组名都与这个目录组名相同
    比如执行chmod a-x qjj后qjj权限变为(drwSr-Sr-- 2 shmily shmily     40  7月19日 16:23  qjj)
    SBIT：粘贴位 /tmp多个t，表示SBIT权限  场景：所有人都可在这个目录下写文件但只有自己和root能删，别人没权限删你，你也没权限删别人的文件
    设定：4代表SUID，2代表SGID，1代表SBIT    例：chmod 1777 xx设置SBIT  例：chmod u+s设置SUID g+s设置SGID o+t设置SBIT
    (-rwsrwsrwt 7777;-rwsrwsrwx 6777;-rwSrwSrw- 6666;-rwSrw-rw- 4666;-rw-rwSrw- 2666;-rwxrwxrwt 1777;-rw-rw-rwT 1666;-rw-rw-rw- 0666;---x--x--x 0111;---S--S--- 6000;---S------ 4000;------S--- 2000)
    UID\GID：
    查看UID\GID  命令id [username]或者cat /etc/passwd
    修改foo用户的uid # usermod -u 2005 foo
    修改foo组的gid   # groupmod -g 3000 foo

    NFS挂载A节点的目录到B节点，在B节点这个目录的用户和组的位置显示UID和GID，此时的UID和GID对应的是A节点目录的用户和组在A节点的UID\GID的值，且UID、GID在B节点没有id相匹配的用户和组。如果A节点目录hive:hive对应UID、GID分别为1008 586，而B节点1008是用户aaa的UID，586是组sqoop的GID，则挂载目录在B节点权限显示为aaa:sqoop。
15.file命令可查看文件类型  file file_name
16.搜索:which寻找PATH中相关指令位置；找文件先用whereis和locate检查，找不到再用find
   whereis -l指定到哪个目录查询 -b只找binary文件 -m找说明文件 -s只找source -u找其他类型 （用whereis有些文件找不到因为它只搜索/bin /sbin /usr/share/man等几个指定目录位置，所以有些文件找不到） whereis -l查看它都查哪些路径
   locate -i忽略大小写 -c只输出数量 -l n只输出n行 -S输出locate记录的数据库文件地址文件夹文件数信息 该命令将元数据信息存放在/var/lib/mlocate/mlocate.db然后定期更新，所以查询快，但有时不准需要更新数据库，可用updatedb命令，更新时会读/etc/updatedb.conf中的设定去磁盘找并更新数据库 
   find [PATH] [OPT] [Action]命令：
      可加时间常数，以-mtime为例：
         -mtime  n：找 n 天之前的那天发生修改的文件 
         -mtime +n：列出n天前(不含第n天)发生修改的文件
         -mtime -n：列出n天内(不含第n天)发生修改的文件
         -newer file：列出比这个已存在的file还新的文件
         -user name：找属于用户name的文件  --group name：找属于name组的文件
         -nouser：找拥有者不在/etc/passwd的文件  -nogroup：找不存在于/etc/group记录的组的文件
         -uid n：找UID相关，UID在/etc/passwd记录  -gid n：找GID相关，GID在/etc/group记录
         -name filename：过滤文件名并查找
         -size +50k找比50k大的文件  -size -10k找比10k小的文件
         -type [fbcdlsp] 只找xx类型的文件：f普通文件，b装置文件，c装置文件，d目录，l链接，sSocket，p管道
         -perm 0600：找0600权限的文件  -perm +4000找SUID权限文件
         -exec command：执行一条指令来处理搜索结果
      常用示例：
        find /opt -mtime 0   24小时内发生修改的文件（0替换为3就是3天前的那天24小时内）
        find /opt -mtime -3  3天内发生修改的文件
        find .|xargs grep -ri "xxx"  查看目录下包含xxx关键字的所有行
        find .|xargs grep -ri "xxx" -l  查看目录下包含xxx关键字的所有文件
        grep -ri "keyword" *  查看当前目录下含有关键字的文件
        find . -name "*.sql" | xargs grep "keyword"  查看目录下包含keyword关键字的所有sql后缀文件
        find /hadoop/bigdata/ -type f -name "*.sh" -o -name "*.py"  | xargs grep -ri "keyword" | grep -v grep  查看目录下包含keyword关键字的所有sh后缀和py后缀文件
        find /tmp/ -type d -name "spark-*" -mtime +60  查看/tmp/目录下60天前的类型为目录且名称以spark-开头的目录
        find /opt -user shmily -name *.conf  找opt目录下shmily用户的conf后缀文件
        find /opt -user shmily -name *.conf -exec ls -lh {} \;  找opt目录下shmily用户的conf后缀文件并执行ll列出完整信息
        find ~ -type l -a -name 下载 -exec ls -l {} \;  找家目录下类型为链接的且名称为“下载”的文件并ll显示（-a表示and）
        find ~ -perm 4777 -o -name aaa 找权限为4777的或名称为aaa的文件或目录（-o表示or）
        find ~ -type f -a ! -user shmily -exec ls -lh {} \;  找类型为文件的且所有者非shmily的文件并执行ll -h输出信息（！表示非）
        find . -name '*.jar' -exec jar -tvf {} \; | grep gson  查看当前目录下引用gson的jar  （依赖apt install unzip openjdk-8-jdk）
        rm -f $(find . -type f -name "core.*" -mtime +100)  删除当前目录下修改时间为100天以前的前缀为core.文件
        rm -f $(find . -type f -name "*.txt" -o -name "*.csv" -mtime +100) 删除当前目录下修改时间为100天以前的后缀为txt或csv的文件
        find /path/path -type f -name "*.txt" -o -name "*.csv" -mtime +99 | xargs rm  删除/path/path目录下修改时间为100天以前的后缀为txt或csv的文件
17.进入目录需要x权限，在目录下ls需要r权限，读取文件需要对其路径上的目录有x权限对文件有r权限，修改文件需要对其路径上的目录有x权限对文件有rw权限
18.在目录下创建一个文件需要的权限：对该目录有wx权限
```

## 第七章 Linux磁盘与文件系统管理
```
1.
```

## 第八章
```
```

## 第九章
```
```

## 第十章
```
```

## 第十一章
```
```

## 第十二章
```
```

## 第十三章
```
```

## 第十四章
```
```

## 第十五章
```
```

## 第十六章
```
```

## 第十七章
```
```

## 第十八章
```
```

## 第十九章
```
```

## 第二十章
```
```

## 第二十一章
```
```

## 第二十二章
```
```

## 第二十三章
```
```

## 第二十四章
```
```

## 日常操作总结
1. Linux节点间延迟与带宽测试
```
在两台节点yum -y install qperf
在节点A执行qperf命令
在节点B执行：
qperf xx.xx.xx.xx(A的ip) tcp_bw tcp_lat conf
得到tcp_bw为得到的bw为TCP数据包网络带宽
latency为TCP网络延迟
conf是两台节点的CPU、OS内核版本
我们可以透过改变消息的大小（msg_size），比如从1个字节到64K，每次倍增的方式，来观察带宽和延迟的
qperf xx.xx.xx.xx -oo msg_size:1:64k:*2 tcp_bw tcp_lat conf
除了tcp_bw tcp_lat，还有udp_bw,udp_lat可测试UDP带宽，还支持其他几种协议，具体可查看qperf --help tests
```

2. 程序后台运行及日志输出
nohup sh xx.sh & 不间断(nohup)后台(&)运行,标准输出1默认写入nohup.out
nohup sh xx.sh > /dev/null 2>&1 &  不间断(nohup)后台(&)运行,标准输出stdout($1)和异常输出stderr(2)信息都永久丢失(> /dev/null)
nohup sh xx.sh > /data/logs/log_$(date +%Y-%m-%d) 2>&1 &  不间断(nohup)后台(&)运行,标准输出($1)和异常输出(2)信息都写入指定路径以日期命名的日志文件
0 表示stdin标准输入，用户键盘输入的内容
1 表示stdout标准输出，输出到显示屏的内容
2 表示stderr标准错误，报错内容
还有一种方法通过screen命令在一个screen窗口中前台运行，即使shell退出，但screen仍然存在，持续运行
创建一个名为qjj的screen窗口: screen -S qjj
前台执行某个命令
Ctrl+A+D保持会话退出
查看已有的screen：screen -ls
恢复到qjj这个screen：screen -r qjj
```shell
-A 　将所有的视窗都调整为目前终端机的大小。
-d 　将指定的screen作业离线。
-h 　指定视窗的缓冲区行数。
-m 　即使目前已在作业中的screen作业，仍强制建立新的screen作业。
-r 　恢复离线的screen作业。
-R 　先试图恢复离线的作业。若找不到离线的作业，即建立新的screen作业。
-s 　指定建立新视窗时，所要执行的shell。
-S 　指定screen作业的名称。
-v 　显示版本信息。
-x 　恢复之前离线的screen作业。
-ls或--list 　显示目前所有的screen作业。
-wipe 　检查目前所有的screen作业，并删除已经无法使用的screen作业。
```
日志重定向到文件
sh xxx.sh >> xxx.log 2>&1  标准错误输出重定向到标准输出


1. 文本批量替换
sed -i 's/\r//g' *.sh  替换文件中所有/r/n中的/r为空
sed -i s/sourceWord/targetWord/g $(find /hadoop/ -type f -name "*.sh" -o -name "*.py"  | xargs grep -rl "keywords")  批量替换/hadoop目录下所有包含keyword关键字的shell和python脚本中内容sourceWord替换为targetWord
sed "s/xxxxx/12345/g" test.txt > test1.txt 将test.txt中的内容xxxxx批量替换为12345并将替换后的内容生成新文件test1.txt(原test.txt内容不变)
sed 's/$/ \necho $(date) /g' test > test1   test文件里每行下面加一行echo $(date) 并将结果写入test1文件

4. nc使用
安装yum install nmap-ncat.x86_64
生产消息：nc -lk 8888
查看消息：nc -v host port
传文件：
服务器端(接收文件端)命令：nc -l ip地址 端口号 > 接收的文件名
客户端(发送文件端)命令：nc ip地址 端口号 < 发送的文件名

5. 目录下文件按大小\时间排序
大文件GB级别以上的文件按大小排序du -sh /path/* | grep G | sort -rnk1
按大小排序并显示ll | sort -rnk5

6. 统计磁盘使用情况
汇总目录的总大小 du -sh /tmp/xx
查看当前目录下文件和目录大小du -sh *
查看当前目录下文件和目录大小包括隐藏文件du -sh * .[^.]*
有时我们发现系统的关键目录占用空间都不大，都在可以接受的范围，但磁盘容量还是被大量占用，无法释放。是因为du命令只能检测目录下未删除的文件，而目录下可能存在已删除的文件但该文件一直被某一未关闭的进程写入，所以虽然文件表面上被删除了，但不会释放空间，会一直占用磁盘空间。
当进程打开了某个文件时，只要该进程保持打开该文件，即使将其删除，它依然存在于磁盘中。这意味着，进程并不知道文件已经被删除，它仍然可以向打开该文件时提供给它的文件描述符进行读取和写入。除了该进程之外，这个文件是不可见的，因为已经删除了其相应的目录索引节点。
此时可通过以下方式排查：
  lsof命令列出打开的文件(list open files)
  lsof | grep deleted 列出被进程占用但已被删除的文件，可以看到占用大小，对占用磁盘大的进程进行关闭或重启即可释放空间
一个快速检测系统盘关键目录及磁盘占用的脚本：
```shell
#!/bin/bash
declare -A dic path_threshold_dict=(\
[/home]="2048" \
[/tmp]="2048" \
[/root]="1536" \
[/var]="1536" \
[/usr]="10240" \
)
echo "Filesystem    Size  Used Avail Use% Mounted on"
df -h | grep / | awk 'NR==1'
if [ $(whoami) != "root" ]; then
  echo "Please use root to run this script."
  exit 1
fi
function size_check(){
  # arg1 is path,arg2 is size threshold(GB)
  size=$(du -sm $1 | awk '{print $1}')
  if [ $size -gt $2 ]; then
    echo "目录'$1'大于$2 MB ，检查该目录下占用空间前10的大目录"
    du --max-depth=8 $1 -h | sort -h -r | head -10
  else
    echo "目录'$1'占用空间为$size MB，未超过检测阈值 $2 MB."
  fi
}
for i in ${!path_threshold_dict[*]}
do
  echo "----------------------------------------"
  size_check $i ${path_threshold_dict[$i]}
done
echo "----------------------------------------"
# Check disk space occupied by unclosed processes.
echo 'These files were deleted but disk space was not freed.'
lsof | grep deleted
```
lsof其他常见命令：
lsof /etc/passwd //那个进程在占用/etc/passwd
lsof /dev/hda6 //那个进程在占用hda6
lsof /dev/cdrom //那个进程在占用光驱
lsof -c sendmail //查看sendmail进程的文件使用情况
lsof -p 30297 //显示那些文件被pid为30297的进程打开
lsof -D /tmp 显示所有在/tmp文件夹中打开的instance和文件的进程。但是symbol文件并不在列
lsof -u1000 //查看uid是100的用户的进程的文件使用情况
lsof -utony //查看用户tony的进程的文件使用情况
lsof -i //显示所有打开的端口
lsof -i:80 //显示所有打开80端口的进程
lsof -i -U //显示所有打开的端口和UNIX domain文件

7. ssh到远程节点执行命令
已免密无需密码：ssh -l root 192.168.1.101 "source /etc/profile;echo 1 >> /path/to/remote/logs 2>&1"
未免密需要密码：
yum install sshpass
sshpass -p "password" ssh root@192.168.1.101 'echo 1'

8. 上传下载文件lrzsz
yum -y install lrzsz
rz 上传
sz xxx下载

9. ramfs与tmpfs使用
Ramfs: 创建一个最大大小为8G的RAMFS
mkdir -p /ramfs
mount -t ramfs none /ramfs -o maxsize=8388608
实际测试超过8G也会存，可能导致系统内存占满崩溃
所以挂载tmpfs--据说速度比ramfs还快，限制大小有用，能使用SWAP空间
mkdir -p /tmpfs
mount tmpfs /tmpfs -t tmpfs -o size=8192m

10. 禁用swap
立刻禁用swap
sudo swapoff -a  
永久禁用swap
sudo vim /etc/fstab
将swap分区用#注释掉
一般不建议禁用swap，避免操作系统内存被打满时没有swap缓冲导致系统OOM，崩溃。

12. 数组
```shell
# 初始化一个数组arr包含五个元素 aaa bbb ccc ddd eee
arr=(aaa bbb ccc ddd eee)
# 遍历arr
for elem in "${arr[@]}";do
  echo "elem is $elem"
done
# 利用下标遍历arr
for((i=0;i<${#arr[@]};i++)) do
    echo "elem$i is ${arr[i]}"
done
# 将命令的结果初始化为数组
TABLES=($(impala-shell -i 192.168.1.101 -d default -q "show tables" -B | awk '{print $1}'))
files=($(ls -l . | awk '{print $9}'))
```

13. 日志检索
```shell
# 按时间切分日志  
## 取2022-03-22 13:20~2022-03-22 15:59分的日志  注意 所取日志中如果没有筛选范围的上界但有下界，可能筛选不到日志
sed -n '/2022-03-22 13:20/,/2022-03-22 15:59/p' hbase-cmf-hbase2-REGIONSERVER.out.1 > rs.hbase01.log  
## 取2022-03-22 14:06~2022-03-22 15:59分的日志
sed -n '/2022-03-22 14:06/,/2022-03-22 15:59/p' hbase-cmf-hbase2-REGIONSERVER.log.out >> rs.hbase01.log
```

14. strace调试分析工具
strace是个功能强大的Linux调试分析诊断工具，可用于跟踪程序执行时进程系统调用(system call)和所接收的信号，尤其是针对源码不可读或源码无法再编译的程序。在Linux系统中，用户进程不能直接访问计算机硬件设备。当进程需要访问硬件设备(如读取磁盘文件或接收网络数据等)时，必须由用户态模式切换至内核态模式，通过系统调用访问硬件设备。strace可跟踪进程产生的系统调用，包括参数、返回值和执行所消耗的时间。若strace没有任何输出，并不代表此时进程发生阻塞；也可能程序进程正在执行某些不需要与系统其它部分发生通信的事情。strace从内核接收信息。
strace command  执行名称为command的命令或程序并跟踪系统调用
strace -p PID 跟踪PID进程系统调用情况
strace -c -p PID 统计PID进程系统调用次数与用时，按CTRL+C结束统计

15. 计算加减乘除
```shell
整数混合运算
echo $(expr 3 * 2 + 2 / 2 + 1)
echo $[(1+1+1+1)*3/2]
浮点数运算 结果限制小数点后四位 计算10.3除以3.3
echo $(echo "scale=4;10.3/3.3"|bc)
```

16. 时间相关命令
```shell
date +%s  时间戳
echo $(date "+%Y-%m-%d %H-%M-%S")  时间输出YYYY-MM-DD HH:MM:SS格式
echo $(date "+%Y-%m-%d %H-%M-%S" --date="-1 day")  昨日此刻
DATE_DIFF=$(expr $(expr $(date +%s) - $(date -d '2022-03-29' +%s)) / 86400)   距2022-03-29已过多少天
```

17. 内存管理相关命令
```shell
free -h 查看系统内存使用情况
ps -p 340113 -o rss,vsz  查看PID的实际使用物理常驻内存(RSS)和使用的虚拟内存(vsz) 
echo N > /proc/sys/vm/drop_caches  释放内存(N=1/2/3) 该操作会清理缓存，建议先sync（sync 命令将所有未写的系统缓冲区写到磁盘中，包含已修改的 i-node、已延迟的块 I/O 和读写映射文件）
```

18. 压缩包创建与解压
```shell
# tar压缩包创建
tar -zcvf xxx.tar.gz /tmp/data
# tar压缩包创建，排除某个文件
tar -zcvf xxx.tar.gz /tmp/data --exclude=xx.sql
# tar压缩包创建,包含目录下的隐藏文件 (默认/tmp/data/*是不包括.开头的隐藏文件的)
tar -zcvf xxx.tar.gz /tmp/data/* /tmp/data/.[!.]* 
# tar压缩包解压
tar -zxvf xxx.tar.gz -C /tmp/data
# -c 产生.tar打包文件 -v显示详细信息 -f指定压缩后的文件名 -z打包同时压缩 -x解包.tar文件
# zip压缩包创建
zip xxx.zip /tmp/data/*.log
zip xxx.zip file1 file2 ... fileN
# zip压缩包解压
unzip xxx.zip
```

19. 文件对比
```shell
diff 对比文件差异 (格式不太好看)
diff system-auth-ac /etc/pam.d/system-auth-ac
diff 对比文件差异-左右格式(格式友好)
diff -y system-auth-ac /etc/pam.d/system-auth-ac
```

20. 使用命令直接向crontab中加入或删除调度
```shell
# 注意提前备份好crontab -l原来的内容,避免意外情况
# 一条命令向crontab中加入新调度 */10 * * * * sh /usr/local/complat/trino/bin/trino-auto-restart.sh
(crontab -l ; echo "*/10 * * * * sh /usr/local/complat/trino/bin/trino-auto-restart.sh") | crontab -
# 一条命令删除crontab中的trino-auto-restart.sh调度
(crontab -l | grep -v trino-auto-restart) | crontab -
```

21. 磁盘挂载
```shell
临时:
mkdir /data
chmod 1777 /data
mount /dev/sda1 /data
永久:
vim /etc/fstab添加  (df -T查看文件系统类型ext4\btrfs......)
/dev/sda1 /data btrfs defaults 0 0
```

22. 进程优先级设置
每个进程都有一个介于-20到19之间的NI(nice)值(这个值越小，表示进程”优先级”越高，而值越大“优先级”越低)。默认情况下，进程的NI值为0
```shell
sudo renice [优先级] PID
例:
sudo renice -20 pid  提到最高优先级
sudo renice -20  $(ps -ef | grep kwin | grep -v grep | awk '{print $2}')
sudo renice -20  $(ps -ef | grep latte-dock | grep -v grep | awk '{print $2}')
```

## 总结  
字颜色大小
<font size="3" color="red">This is some text!</font>
<font size="2" color="blue">This is some text!</font>
<font face="verdana" color="green"  size="3">This is some text!</font>



## 参考资料  
《鸟哥的Linux私房菜》

