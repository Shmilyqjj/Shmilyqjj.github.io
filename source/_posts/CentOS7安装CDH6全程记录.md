---
title: CentOS7安装CDH6安装与排坑
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
  - CDH6+CentOS7
keywords: CDH6+CentOS7
description: CDH6+CentOS7安装过程与排坑
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-intro.jpg
abbrlink: 38328
date: 2019-10-29 10:50:40
---
# 前言  
一开始搭集群时，都是装Apache原生的Hadoop，Spark包，一个一个装，一个一个配，好麻烦，而且通过命令或REST监控还很不直观，直到我遇到了Cloudera Manager，这东西简直就是神器。  
[Cloudera Manager](https://www.cloudera.com/products/product-components/cloudera-manager.html)（简称CM），是Cloudera开发的一款大数据集群部署神器，而且它具有集群自动化安装、中心化管理、集群监控、报警等功能，通过它，可以轻松一键部署，大大方便了运维，也极大的提高集群管理的效率。  
一开始因为CentOS8出来了，想尝鲜，发现ClouderaManager没有el8的版本，所以暂时还不能用CentOS8来安装CM，请千万不要尝试使用CentOS8。  

CM的主要功能：
1. 管理：对集群进行管理，如添加、删除节点等操作
2. 监控：监控集群的健康情况，对设置的各种指标和系统运行情况进行全面监控
3. 诊断：对集群出现的问题进行诊断，会针对集群问题给出建议的方案
4. 集成：对hadoop生态的多种组件和框架进行整合，减少部署时间和工作量
5. 兼容：与各个生态圈的兼容性强

总结一下就是：方便搭建和运维，提供全面监控

## CDH架构
![alt CDH-01](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-01.jpg) 
CDH的组件：
 * Agent：在每台机器上安装，该代理程序负责启动和停止服务和角色的过程，拆包配置，触发装置和监控主机。
 * Management Service：负责执行各种监控，警报和报告功能角色等服务。
 * Database：存储配置和监视信息。通常情况下，多个逻辑数据库在一个或多个数据库服务器上运行。例如，Cloudera的管理服务器和监控角色使用不同的逻辑数据库。
 * Cloudera Repository：软件由Cloudera管理分布存储库。
 * Clients：是用于与服务器进行交互的接口

**CDH中都有哪些服务?** 
 
| 组件名称 | 用途 | 
| ---- | ---- | 
| Zookeeper | Apache ZooKeeper 是用于维护和同步配置数据的集中服务。 | 
| HDFS | HDFS是 Hadoop 应用程序使用的主要存储系统。 | 
| yarn | Apache Hadoop MapReduce 2.0 (MRv2) 或 YARN 是支持 MapReduce 应用程序的数据计算框架。依赖HDFS服务。 | 
| HBase | 支持随机读/写访问的Hadoop数据库(HBase是一个分布式、面向列的开源数据库，) | 
| Hive | 在大数据集合上的类SQL查询和表。Hive是基于Hadoop的一个数据仓库工具，可以将结构化的数据文件映射为一张数据库表，并提供简单的sql查询功能，可以将sql语句转换为MapReduce任务进行运行。 | 
| impala | Impala是一个新型查询系统，它提供SQL语义，能查询存储在Hadoop的HDFS和HBase中的PB级大数据。 | 
| solr | Solr是一个分布式服务，用于编制存储在 HDFS 中的数据的索引并搜索这些数据。 | 
| spark | Spark是强大的开源并行计算引擎，基于内存计算，速度更快；接口丰富，易于开发；集成SQL、Streaming、GraphX、MLlib，提供一栈式解决方案。 | 
| flume | 高可靠、可配置的数据流集合。 | 
| storm | Storm是一个分布式的、容错的实时计算系统。 | 
| kafka | Kafka是一种高吞吐量的分布式发布订阅消息系统。 | 
| Hue | 可视化Hadoop应用的用户接口框架和SDK。。 | 
| Sqoop | 以高度可扩展的方式跨关系数据库和HDFS移动数据 | 
| oozie | Oozie是一种框架，是用于hadoop平台的作业调度服务。 | 
| Avro | 数据序列化：丰富的数据结构，快速/紧凑的二进制格式和RPC。 | 
| Crunch | Java库，可以更轻松地编写，测试和运行MR管道。 | 
| DataFu | 用于进行大规模分析的有用统计UDF库。 | 
| Mahout | 用于群集，分类和协作过滤的库。 | 
| Parquet | 在Hadoop中提供压缩，高效的列式数据表示。 | 
| Pig | 提供使用高级语言批量分析大型数据集的框架。 | 
| MapReduce | 强大的并行数据处理框架。 | 
| Pig | 数据流语言和编译器 | 
| Sqoop | 利用集成到Hadoop的数据库和数据仓库 | 
| Sentry | 为Hadoop用户提供精细支持，基于角色的访问控制。 | 
| Kudu | 完成Hadoop的存储层，以实现对快速数据的快速分析。 |   


## 安装部署  
在虚拟机环境上部署Cloudera Manager，可能达不到预期的效果，但是基本的功能可以实现。  
我的电脑内存16GB勉强可以使用，如果电脑16GB以上的可以考虑折腾CDH，16GB以下的想都不要想...
### 环境
物理机i7-6700hq 16GB内存 1T HDD  
虚拟机四台 8个逻辑核心 内存分配分别是 5GB 3GB 2GB 2GB （可以说是榨干了物理机性能）  
建议如果没有i7-8th及以上CPU或没有32G+的电脑，就不要尝试了。还是直接装Apache版的好些。
VMWare 15  
SecureCRT 8.1.4  
FileZilla 3.40.0  
CentOS 7  
<font size="6" color="red">**以上是旧配置，后面再有更新均使用新的配置：**</font>
物理机i7-9750h 64GB内存 2T HDD+2T SSD
虚拟机四台 12个逻辑核心 内存分配分别是 20GB 14GB 14GB 10GB  
Hyper-V虚拟机
SecureCRT 8.5.3  
FileZilla 3.40.0  
CentOS 7  
能够同时运行所有服务。

### 一.基础配置  
**下载CentOS7:**  
[CentOS7 Minimal下载](http://mirrors.aliyun.com/centos/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso)

**虚拟机配置**  
* 使用VMWare
 采用NAT格式网卡,按如下配置  
 虚拟网卡设置（编辑-虚拟网络编辑器）  
 ![alt CDH-02](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-02.jpg)  
 点击NAT设置:  
 ![alt CDH-2.5](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-02.5.jpg) 
 点击DHCP设置:  
 ![alt CDH-03](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-03.jpg)  
 以后我们的虚拟机都使用NAT网卡  
 **安装CentOS7**  
 文件->新建虚拟机->选择自定义(高级)->下一步->下一步->**稍后安装操作系统**->选择Linux/CentOS7 64位->下一步->虚拟机名称CDH066->下一步  
 ->根据自己电脑设置核心数->下一步->虚拟机内存5120MB->网络类型选NAT->下一步...->磁盘分配80GB->下一步->下一步->自定义硬件->选择CentOS7的安装镜像,如图:  
 ![alt CDH-03.5](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-03.5.jpg)  
 关闭->完成->开启此虚拟机 
 开始安装  
 ![alt CDH-04](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-04.jpg)  
 安装Minimal版的CentOS，感觉很清爽！但是后续需要自己手动装一些依赖包，不过这样也好，可以避免安装过多无用的依赖。时区选择ShangHai。  

 此步骤时指定root密码123456  
 安装时指定一个管理员用户shmily 密码123456  
 ![alt CDH-05](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-05.jpg)  
 ![alt CDH-05.5](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-05.5.jpg)  

* 使用Hyper-V（推荐）
 在Hyper-V管理器中的虚拟交换机管理器新建内部网络，然后如果要指定IP，需要去电脑的网络设置IPV4，然后设置把Wifi网络共享给这个网卡。
 IPV4：192.168.x.1  (x均替换为你喜欢的值 1-254)
 网关255.255.255.255.0
 然后配置虚拟机ifcfg-eth0时
 IPADDR=192.168.x.101
 NETMASK=255.255.255.0
 DNS1=192.168.x.1
 DNS2=192.168.x.2
 ........
 我的设置如图：
 ![alt CDH-05.6](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-05.6.JPG)  
 ![alt CDH-05.7](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-05.7.JPG)  
 ![alt CDH-05.8](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-05.8.JPG)  
 ![alt CDH-05.9](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-05.9.JPG)  


安装完成后Reboot，按步骤进行如下配置  
```shell
 rm -rf * 

 vi /etc/sysconfig/network   
 NETWORKING=yes
 HOSTNAME=cdh066
 
 vi /etc/sysconfig/network-scripts/ifcfg-ens33  修改以下几项的值
 BOOTPROTO=static
 ONBOOT=yes
 NM_CONTROLLED=yes
 IPADDR=192.168.1.66
 GATEWAY=192.168.1.2
 DNS1=192.168.1.2
 
 vi /etc/sudoers  添加以下，必要的话可以加其他用户权限控制策略，这里我对root和shmily两个用户赋权
 root ALL=(ALL)  ALL 下面添加：
 shmily ALL=(ALL)  ALL
 
 systemctl start NetworkManger
 systemctl enable NetworkManger
 service NetworkManager status
 
 systemctl status firewalld.service    # 查看防火墙状态
 systemctl stop firewalld.service   # 关闭防火墙
 systemctl disable firewalld.service   # 关闭防火墙开机启动
 systemctl is-enabled firewalld.service  # 查看防火墙是否开机启动
 
 # 关闭selinux
 vi /etc/selinux/config 配置文件中的 SELINUX=disabled
 
 # 开启SSH服务，用于使用SecureCRT连接
 # 检查ssh服务是否开启（CentOS7默认开启）
 ps -e | grep sshd 

 # 修改Hostname
 vi /etc/hostname
 localhost.localdomain改为cdh066

 sudo hostnamectl set-hostname CDH067
 
 vi /etc/hosts  # 添加如下记录
 192.168.1.66 cdh066
 192.168.1.67 cdh067
 192.168.1.68 cdh068
 192.168.1.69 cdh069
 
 reboot   # 重启机器CDH066

 # 检查22端口是否开启 （CentOS87默认开启）
 yum install net-tools
 netstat -an | grep 22
```

SecureCRT连接测试SSH  
SecureCRT创建New Session -> SSH2 -> Hostname是CDH066 username是root  
发现还是会提示Hostname lookup failed: host not found
需要修改Windows的C:\Windows\System32\drivers\etc\hosts
添加如下并保存
192.168.1.66 cdh066
192.168.1.67 cdh067
192.168.1.68 cdh068
192.168.1.69 cdh069

重新用SecureCRT连接出现如下图:
![alt CDH-06](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-06.jpg)  
Accept & Save,输入密码并勾选Save password  
完成  
FileZilla也能连接了:  
![alt CDH-07](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-07.jpg)  

检查一下网络:  
ping 8.8.8.8  
能ping通即可进行下一步，如果ping不通，需要仔细检查网络配置文件:  
![alt CDH-08](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-08.jpg)  

安装python:  
CentOS7 Minimal默认带Python2.7.5版本，已经满足需求，为了开发方便，还是安装个ipython吧  
```shell
 yum -y install epel-release
 yum install python-pip
 pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip
 pip install -i https://pypi.tuna.tsinghua.edu.cn/simple requests  # 安装必要的库可以指定源 以安装requests库为例
 pip install -i https://pypi.tuna.tsinghua.edu.cn/simple ipython   # 安装ipython
```
完成后，命令行执行python即可运行python2.7.5，命令行执行ipython即可使用ipython  

安装一些必要的常用命令[必要]
yum install bind-utils  
yum -q install /usr/bin/iostat  
yum install vim wget iotop lsof 
yum install -y git  
yum install dstat   (全面的系统监控工具-推荐)  
yum install nload  

安装一些CDH所需的必要依赖[必要] 
```shell
 yum -y install chkconfig bind-utils psmisc libxslt zlib sqlite cyrus-sasl-plain cyrus-sasl-gssapi fuse portmap fuse-libs redhat-lsb httpd httpd-tools unzip ntp
 systemctl start httpd.service  # 启动httpd服务
 systemctl enable httpd.service # 设置httpd开机启动
 yum -y install httpd createrepo  # createrepo是安装CDH6集群必备
 
 vim /etc/rc.local  添加
 echo never > /sys/kernel/mm/transparent_hugepage/defrag
 echo never > /sys/kernel/mm/transparent_hugepage/enabled
 
 chmod +x /etc/rc.d/rc.local
```  

安装JDK1.8[千万不要自行更换版本]  
去Oracle官网下载1.8版本8u181的安装包[JDK 1.8历史版本下载](https://www.oracle.com/technetwork/java/javase/downloads/java-archive-javase8-2177648.html)  
如果安装最新版本，后续CDH安装服务会无法启动，遇到各种问题。  
要明确CDH6.3支持的JDK版本：  
![alt CDH-25](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-25.JPG)  

这里注意，JDK目录一定是/usr/java/jdk_1.8.x_xx，这样CM服务才能检测到JDK，否则服务无法启动  
```shell
 mkdir /opt/software
 # 通过FileZilla上传到CDH066节点的 <u>/opt/software</u>目录下  
 cd /opt/software
 mkdir /usr/java/
 tar -zxvf jdk-8u181-linux-x64.tar.gz -C /usr/java/
 cd ..
 vim /etc/profile 添加
#JAVA_HOME      
export JAVA_HOME=/usr/java/jdk1.8.0_181
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

 source /etc/profile
 java -version
```  

优化服务器配置
```shell
# swappiness
echo 10 > /proc/sys/vm/swappiness
# 关闭透明大页面压缩
echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
echo "vm.swappiness=0" >> /etc/sysctl.conf
```

还有一些其他的监控命令[Linux监控命令汇总](https://blog.csdn.net/qq_15766181/article/details/89928275)  

Mysql安装(CDH必备)  
首先查看Cloudera Manager官网要求的Mysql版本：[Database Requirements](https://docs.cloudera.com/documentation/enterprise/6/release-notes/topics/rg_database_requirements.html#cdh_cm_supported_db)  
参考CDH6.x兼容的版本，我们选择Mysql5.7版本  
注意:
mysql-server依赖mysql-client  
mysql-client依赖mysql-community-libs  
mysql-community-libs依赖mysql-community-common  
所以安装Server会默认安装其全部依赖  
在线安装：
```shell
 rpm -qa|grep mariadb
 rpm -e --nodeps mariadb-libs-5.5.64-1.el7.x86_64  # 卸载MariaDB 虽然CDH6支持了MariaDB，但还是推荐Mysql
 wget -i -c http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm  
 yum -y install mysql57-community-release-el7-10.noarch.rpm
 yum -y install mysql-community-server
```  

离线安装：
去[Mysql-Archives](https://downloads.mysql.com/archives/community/) 下载对应版本的rpm包
```shell
# 安装依赖包
rpm -ivh mysql-community-common-5.7.28-1.el7.x86_64.rpm
# 若安装失败 删除mariadb包
rpm -qa | grep mariadb
rpm -ve mariadb
# 安装libs
rpm -ivh mysql-community-libs-5.7.28-1.el7.x86_64.rpm 
# 安装客户端
rpm -ivh mysql-community-client-5.7.28-1.el7.x86_64.rpm 
# 安装服务端
rpm -ivh mysql-community-server-5.7.28-1.el7.x86_64.rpm 
# 启动
systemctl status mysqld 
# 开机自启
systemctl  enable mysqld
# 查找临时密码
grep 'temporary password' /var/log/mysqld.log
# 设置密码强度
set global validate_password_policy=LOW;
set global validate_password_length=6;
```

![alt CDH-08.6](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-08.6.jpg)  
如图安装完成，接着我们对其进行一些配置  
```shell
 systemctl start mysqld.service
 systemctl enable mysqld.service  # 设置开机启动
 systemctl status mysqld.service # 查看mysql运行状态
 grep 'temporary password' /var/log/mysqld.log  # 找到root初始密码，我的是cWgrI9:14%=_
 mysql -uroot -p           # 登陆mysql
 # 提示Enter Password
  cWgrI9:14%=_    
 set global validate_password_policy=LOW;    # 没有这项会提示Your password does not satisfy the current policy requirements  如果不是生产环境需要修改密码安全策略等级为LOW
 set global validate_password_length=6;   # 最低密码长度，因为测试所以设为了6 生产环境则不需要修改
 ALTER USER 'root'@'localhost' IDENTIFIED BY '123456'; # 修改数据库密码为123456

 CREATE USER 'mysql'@'%' IDENTIFIED BY '123456';  # root登陆然后创建用户及其密码（用户名mysql为例）
 GRANT ALL ON mysql.* TO 'mysql'@'%';  # 赋予mysql用户所有权限
 flush privileges; # 刷新配置 
 status;  # 通过这个命令发现Mysql目前不是UTF-8字符集
```  

配置utf-8字符集
vim /etc/my.cnf  添加如下配置  
注意顺序，client一定在mysqld属性的上方  
```conf
[client]
default-character-set=utf8
[mysqld]
init_connect='SET collation_connection = utf8_unicode_ci' 
init_connect='SET NAMES utf8' 
character-set-server=utf8 
collation-server=utf8_unicode_ci 
skip-character-set-client-handshake
```

根据[CDH官方推荐的Mysql参数配置](https://docs.cloudera.com/documentation/enterprise/6/latest/topics/cm_ig_mysql.html#cmig_topic_5_5),继续添加如下参数:  
如果生产环境，需要根据集群配置的实际情况来设定  
```shell
[mysqld]
transaction-isolation = READ-COMMITTED
symbolic-links = 0

key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
expire_logs_days = 10
max_binlog_size = 100M
log_bin=/var/lib/mysql/mysql_binary_log
server_id=1
binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit  = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 128M   
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M
sql_mode=STRICT_ALL_TABLES
```

重启Mysql服务  
systemctl restart mysqld.service

登录Mysql并查看是否修改成功
mysql -hlocalhost -P3306 -uroot  -p123456 
show variables like "%character%";  
show variables like "%collation%";
如图即为配置成功  
![alt CDH-09](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-09.jpg)  

创建CM的数据库并增加数据库所属用户的远程登陆权限：  
```shell
CREATE DATABASE scm DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE amon DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE rman DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hue DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE hive DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE sentry DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE nav DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE navms DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
CREATE DATABASE oozie DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;

GRANT ALL ON scm.* TO 'scm'@'%' IDENTIFIED BY '123456';
GRANT ALL ON amon.* TO 'amon'@'%' IDENTIFIED BY '123456';
GRANT ALL ON rman.* TO 'rman'@'%' IDENTIFIED BY '123456';
GRANT ALL ON hue.* TO 'hue'@'%' IDENTIFIED BY '123456';
GRANT ALL ON hive.* TO 'hive'@'%' IDENTIFIED BY '123456';
GRANT ALL ON sentry.* TO 'sentry'@'%' IDENTIFIED BY '123456';
GRANT ALL ON nav.* TO 'nav'@'%' IDENTIFIED BY '123456';
GRANT ALL ON navms.* TO 'navms'@'%' IDENTIFIED BY '123456';
GRANT ALL ON oozie.* TO 'oozie'@'%' IDENTIFIED BY '123456';

GRANT ALL ON scm.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON amon.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON rman.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON hue.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON hive.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON sentry.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON nav.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON navms.* TO 'root'@'%' IDENTIFIED BY '123456';
GRANT ALL ON oozie.* TO 'root'@'%' IDENTIFIED BY '123456';

set global validate_password_policy=LOW; 
set global validate_password_length=6; 
GRANT ALL ON root.* TO 'root'@'%' IDENTIFIED BY '123456';  # 让root用户可以在cdh066节点上登录
FLUSH PRIVILEGES;

```  
关于如何查看和修改用户的远程登录权限：  
select user,host from mysql.user;
![alt CDH-09.5](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-09.5.jpg)  
host字段为%的则是允许远程登录的用户，是localhost的只能本地登录  
所以想给远程某台机器开通远程访问某个用户的权限： update mysql.user set host='CDH066' where user='root';  
或者想给某个用户所有局域网内机器的访问权限： update mysql.user set host='%' where user='root';  
然后重启服务或者刷新配置就可以通过mysql -hCDH066 -uroot -p123456来登录了  
远程其他节点可以通过制定-h来访问非root用户的mysql  
![alt CDH-09.6](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-09.6.jpg) 

Mysql JDBC库配置：  
右键 链接另存为 进行下载  
**[下载mysql-connector-java-5.1.47-bin.jar](http://imgs.shmily-qjj.top/BlogImages/CDH/mysql-connector-java-5.1.47-bin.jar)**，将mysql-connector-java-5.1.47-bin.jar文件上传到CDH066节点上的/usr/share/java/目录下并重命名为mysql-connector-java.jar（如果/usr/share/java/目录不存在，需要手动创建）  

系统文件描述符限制修改
vi /etc/security/limits.conf
```text
* soft nofile 32728
* hard nofile 1029345
* soft nproc 65536
* hard nproc unlimited
* soft memlock unlimited
* hard memlock unlimited
```  
![alt CDH-10](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-10.jpg)  

好玩的screenfetch(可选，用来娱乐...)  
```bash
 cd /usr/local/src
 git clone https://github.com/KittyKatt/screenFetch.git
 cp screenFetch/screenfetch-dev /usr/local/bin/screenfetch
 chmod 777 /usr/local/bin/screenfetch
```
![alt CDH-11](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-11.jpg)  

更多安全与防火墙配置参考[安全与防火墙配置](https://blog.csdn.net/thinktik/article/details/81046318)  
有关linux用户和组的详细文章:[Linux用户和组](https://www.cnblogs.com/pengyunjing/p/8543026.html)  

开启ntpd时间同步：参考：[ntp本地服务器搭建](https://blog.csdn.net/zx8167107/article/details/78753134)
1.创建本地NTP时间服务器
```text
vim /etc/ntp.conf
注释掉：
#restrict default nomodify notrap nopeer noquery
#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
添加：
restrict default nomodify
restrict 192.168.1.0 mask 255.255.255.0 nomodify   显式的指出时间服务器所涉及的ip范围
server 127.127.1.0
fudge 127.127.1.0 stratum 10
```
2.配置NTP客户端（其他节点）
```text
注释掉：
#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
添加：
server cdh101  指明本地ntp服务器地址
```
3.分别启动ntpd服务
systemctl status ntpd
systemctl start ntpd
systemctl enable ntpd
ntpdate -u cdh101  手动同步一次
ntpq –p  查看ntpd服务状态

### 二.克隆虚拟机  
克隆CDH所需的另外三台虚拟机  
右键CDH066这台已关闭的虚拟机，右键->管理->克隆  
选择虚拟机中当前状态  下一步  
选择创建完整克隆  下一步  
虚拟机名称 CDH067  完成  
同样方法克隆 CDH068 CDH069  
克隆完成对机器进行设置:  
CDH067  3GB内存  
CDH068  2GB内存  
CDH069  2GB内存  

开启CDH067机器  
确保 /ect/hosts里已经添加了其他机器的ip和host
vim /etc/sysconfig/network-scripts/ifcfg-ens33  
删除UUID和HWADDR  
IPADDR重新分配为192.168.1.67  
修改后如图  
![alt CDH-12](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-12.jpg)  

vi /etc/sysconfig/network  
NETWORKING=yes  
HOSTNAME=CDH067  

vi /etc/hostname  
CDH066改为CDH067  
sudo hostnamectl set-hostname CDH067

重启 reboot  

同样方式修改CDH068,CDH069  

检查：  
1. ping8.8.8.8能通  
2. 使用SecureCRT可以正常连接到机器  
3. ifconfig 或 ip addr命令查看ip地址成功改过来了  
则配置成功  

### 三.配置免密登录[可选 非必须]  
在四台机器分别操作：  
ssh-keygen  并连续敲三下回车

在66机器上  
ssh-copy-id cdh066   建立 cdh066自身免密  
ssh-copy-id cdh067   建立 cdh066 -> cdh067单向免密  
ssh-copy-id cdh068   建立 cdh066 -> cdh068单向免密  
ssh-copy-id cdh069   建立 cdh066 -> cdh069单向免密  

在67机器上  
ssh-copy-id cdh066   建立 cdh067 -> cdh066单向免密  
ssh-copy-id cdh067   建立 cdh066自身免密  
ssh-copy-id cdh068   建立 cdh067 -> cdh068单向免密  
ssh-copy-id cdh069   建立 cdh067 -> cdh069单向免密  

在68机器上  
ssh-copy-id cdh066   建立 cdh068 -> cdh066单向免密  
ssh-copy-id cdh067   建立 cdh068 -> cdh067单向免密  
ssh-copy-id cdh068   建立 cdh068自身免密  
ssh-copy-id cdh069   建立 cdh068 -> cdh069单向免密  

在69机器上  
ssh-copy-id cdh066   建立 cdh069 -> cdh066单向免密  
ssh-copy-id cdh067   建立 cdh069 -> cdh067单向免密  
ssh-copy-id cdh068   建立 cdh069 -> cdh068单向免密  
ssh-copy-id cdh069   建立 cdh069自身免密  

测试都能免密登录:  
![alt CDH-13](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-13.jpg)  
至此免密登录配置完成  

### 四.CDH6安装   
下面的是下载地址，因为我之前手动安装了JDK1.8，所以可以不下载<u>oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm</u>这个包，其余的包全部下载下来  
[CDH6.3.1下载地址](https://archive.cloudera.com/cm6/6.3.1/redhat7/yum/RPMS/x86_64/)  
还需要一个asc文件，下载地址：[allkeys.asc](https://archive.cloudera.com/cm6/6.3.1/allkeys.asc),右键另存为即可  
**在cdh066节点上进行操作**  
mkdir /opt/software/cloudera-repos  
将下载的所有文件通过FileZilla上传到/opt/software/cloudera-repos目录，目录结构如下:  
├── allkeys.asc
├── cloudera-manager-daemons-6.3.1-1466458.el7.x86_64.rpm
├── cloudera-manager-agent-6.3.1-1466458.el7.x86_64.rpm
├── cloudera-manager-server-db-2-6.3.1-1466458.el7.x86_64.rpm
├── enterprise-debuginfo-6.3.1-1466458.el7.x86_64.rpm
└── cloudera-manager-server-6.3.1-1466458.el7.x86_64.rpm


CDH066节点执行如下命令  目的是建立本地存储库 搭建本地源  为了节省空间，也可以只在一台机器上搭建源
```shell
 cd /opt/software/cloudera-repos  
 createrepo .

 # 将cloudera-repos目录移动到httpd的html目录下 制作本地源
 cd ..
 mv cloudera-repos /var/www/html/
 
 cd /etc/yum.repos.d
 touch cloudera-manager.repo  
 vim cloudera-manager.repo  添加如下 baseurl地址对应自己的主机host 如 cdh067节点:http://cdh067/cloudera-repos/  
[cloudera-manager]
name=Cloudera Manager 6.3.1
baseurl=http://cdh066/cloudera-repos/   
gpgcheck=0
enabled=1
autorefresh=0
type=rpm-md
 
 yum clean all 
 yum makecache
```  
制作本地源后[http://cdh066/cloudera-repos/](http://cdh066/cloudera-repos/)这个链接可以访问到源的文件  
我们搭建的本地源，后面会用到  
![alt CDH-14](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-14.jpg)  

安装Cloudera Manager组件:  
```shell
# 在CDH066节点运行
 yum install cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server --skip-broken --nogpgcheck
```  
下载parcel包，：[Index of cdh6/6.3.1/parcels/](https://archive.cloudera.com/cdh6/6.3.1/parcels/)
该链接目前需要有License的Cloudera帐号才可以下载了。

```shell
cd /opt/cloudera/parcel-repo
sha1sum CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel | awk '{ print $1 }' > CDH-6.3.1-1.cdh6.3.1.p0.1470567-el7.parcel.sha
chown -R cloudera-scm:cloudera-scm /opt/cloudera/parcel-repo/*
``` 

初始化数据库
该步骤很重要，可以在第一次启动ClouderaManager前检测数据库连接是否有问题，是否会影响到CMServer初始化。
通过该脚本输出的日志可以定位到错误原因，并修改mysql中不合理的配置文件，修改系统环境配置错误的地方。
```shell
# （scm_prepare_database.sh 库类型 scm库名称 scm库连接的用户名 密码 -h服务端所在地址）
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm 123456 -hHOST  
```

systemctl start cloudera-scm-server.service    # 启动CM服务  
systemctl status cloudera-scm-server.service   # 查看启动状态
![alt CDH-15](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-15.jpg)  

等待几分钟后访问**http://cdh066:7180**，默认帐号密码都是**admin**  
![alt CDH-16](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-16.jpg)  

这里选择免费版本
![alt CDH-17](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-17.jpg)  

下面就是群集安装的步骤：  
主机名称填写cdh066,cdh067,cdh068,cdh069，然后点击搜索搜索
![alt CDH-18](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-18.JPG)  
这里搜到了67，68，69节点，但是66节点是灰色的，安装时，66节点不会被安装Agent，意味着后续安装的组件只能部署在67，68，69节点上运行，不过没有关系，可以在添加组件的步骤之前新开个页面将cdh066也加进去。  

这步使用我们搭建的本地源 **http://cdh066/cloudera-repos/**  如下设置  
![alt CDH-19](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-19.JPG)  
若继续按钮仍为灰色，可以点击更多选项，将所有外部源的链接全部删掉，增加本地parcel源地址，保存更改。

这步**不要勾选**
![alt CDH-20](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-20.JPG)  

填入root用户的密码  
![alt CDH-21](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-21.JPG)  

这步耐心等待，**不要手动刷新**  
![alt CDH-22](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-22.JPG)  

![alt CDH-22.25](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-22.25.JPG)  

这步勾选最后一项  
![alt CDH-22.3](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-22.3.JPG)  
企业安装时，最好先Inspect Hosts，验证节点是否有配置不当的地方，避免影响稳定性。针对Inspect Hosts的结果，可以一条一条优化集群配置。

开始安装服务 如图，选**自定义服务**  
根据集群环境和需求选择合适的服务和搭配。  
![alt CDH-22.4](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-22.4.JPG)  
![alt CDH-22.5](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-22.5.JPG)   

填上之前建的数据库，选的服务不同要求也不同  
![alt CDH-22.6](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-22.6.JPG)  

最后部署成功，启动服务：  
因为我虚拟机搭建，物理机本身配置就很差，有内存不足和请求延迟高的问题，所以，虽然服务都能正常打开，跑一两个小的计算任务也还能勉强承受，但CDH都会报警告，大多都是提示分配内存低了，请求延迟高了，内存不足等信息。  
![alt CDH-24](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-24.JPG)  
后续文章更新内容采用新电脑64GB内存i7-9750h物理机环境，能正常运行CDH服务：
![alt CDH-31](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-31.JPG)  

ClockOffset的报警：
集群全红，提示ClockOffset 未检测到ntpd服务。这个时候就需要配置NTP时间同步服务，重新参考之前NTP时钟同步的配置。

企业级部署时，需要在安装好各角色后，依次设置里面每个角色(包括CMServer)的dir、path等路径，将一些日志、dump路径等放在数据盘。

### 五.Flink集成  
集成官方Flink-1.9.0到CDH管理
下载相应的csd文件和parcels文件到本地：
[csd下载地址](https://archive.cloudera.com/csa/1.0.0.0/csd/)
[parcels下载地址](https://archive.cloudera.com/csa/1.0.0.0/parcels/)
下载后得到如下：
```text
FLINK-1.9.0-csa1.0.0.0-cdh6.3.0.jar
FLINK-1.9.0-csa1.0.0.0-cdh6.3.0-el7.parcel.sha
FLINK-1.9.0-csa1.0.0.0-cdh6.3.0-el7.parcel 
manifest.json
```
将FLINK-1.9.0-csa1.0.0.0-cdh6.3.0.jar放入/opt/cloudera/csd中
将FLINK-1.9.0-csa1.0.0.0-cdh6.3.0-el7.parcel和FLINK-1.9.0-csa1.0.0.0-cdh6.3.0-el7.parcel.sha放入/opt/cloudera/parcel-repo中
然后重启Cloudera Manager Server服务：sudo systemctl restart cloudera-scm-server
重启完成后进入页面，主机->Parcel->检查新Parcel->找到Flink->分配
![alt CDH-27](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-27.JPG)  
![alt CDH-26](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-26.JPG)  
完成分配后开始添加服务：
![alt CDH-28](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-28.JPG)  
![alt CDH-29](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-29.JPG)  
![alt CDH-30](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-30.JPG)  

Flink1.9.0版本比较老，对Hive的兼容不是很友好，可以参考：https://blog.csdn.net/qq_31454379/article/details/110440037 安装Flink官方1.12版本


### 六.功能扩展 
[自定义告警脚本](https://cloud.tencent.com/developer/article/1544865)

### 七.坑点总结  
1. 如果遇到HDFS无法启动的问题，可能是因为**/dfs/nn/**,**/dfs/dn/**,**/dfs/snn/**这些目录和里面的文件权限不够，请检查每个节点的这几个目录，保证nn,dn,snn文件夹权限为**drwx------ 3 hdfs hadoop**，即hdfs用户hadoop组，里面的current文件夹的权限为**drwxr-xr-x 3 hdfs hdfs**。  
2. 提示**Error: JAVA_HOME is not set and Java could not be found**  先确保JDK安装路径在/usr/java/jdkxxxxx，再确定JAVA版本是当前CDH支持的JAVA版本，过高过低都不会兼容，就报这个错误。  
3. The number of live datanodes 2 has reached the minimum number 0. Safe mode will be turned off automatically once the thresholds have been reached.   不多说，关闭安全模式 hdfs dfsadmin -safemode leave 注意，需要sudo到hdfs用户操作  如果sudo到hdfs失败，就vim /etc/passwd  将hdfs用户对应的/sbin/nologin改成/bin/bash 即可sudo到hdfs  
4. 启动ClouderaManagerServer报错
```text
INFO main:com.cloudera.server.cmf.bootstrap.EntityManagerFactoryBean: MYSQL database engine and table mapping: {InnoDB=[AUDITS, COMMANDS, CONFIGS, SCHEMA_VERSION]}
2020-03-25 16:27:22,021 WARN main:com.cloudera.server.cmf.bootstrap.EntityManagerFactoryBean: Failed to determine prior version. This is expected if you are starting Cloudera Manager for the first time. Please also ignore any error messages about missing tables. Moving ahead assuming no upgrade: org.hibernate.exception.SQLGrammarException: could not extract ResultSet
2020-03-25 16:27:22,031 INFO main:com.cloudera.enterprise.dbutil.DbUtil: Schema version table already exists.
2020-03-25 16:27:22,032 INFO main:com.cloudera.enterprise.dbutil.DbUtil: DB Schema version 1.
2020-03-25 16:27:22,039 WARN main:org.springframework.context.support.GenericApplicationContext: Exception encountered during context initialization - cancelling refresh attempt: org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'com.cloudera.server.cmf.TrialState': Cannot resolve reference to bean 'entityManagerFactoryBean' while setting constructor argument; nested exception is org.springframework.beans.factory.BeanCreationException: Error creating bean with name 'entityManagerFactoryBean': FactoryBean threw exception on object creation; nested exception is java.lang.RuntimeException: Unable to obtain CM release version.
2020-03-25 16:27:22,040 ERROR main:com.cloudera.server.cmf.Main: Server failed.
```
使用/opt/cloudera/cm/schema/scm_prepare_database.sh工具初始化scm数据库时报错：when @@GLOBAL.ENFORCE_GTID_CONSISTENCY = 1
原因是数据库启用了gtid_mode，my.cnf有如下配置
```text
gtid_mode = on
enforce_gtid_consistency = 1
binlog_gtid_simple_recovery = 1
```
解决：
①注释掉如上配置，重启mysql server，②删掉scm库并重建，③重启cloudera-scm-server 即可

5. 向CM添加host时，只有某几台主机可以被识别，其他主机，能显示出来但是灰色的，提示无法解析主机名称
解决：检查/etc/hosts 配置是否正确

### HDFS高可用
进入HDFS角色，操作->启用High Availability->选择两个NN、三个JN节点，下一步（注意需要格式化NN，重启HDFS相关所有正在运行的依赖服务，重新部署客户端配置）->完成
进入HUE 将“Web界面角色”改为httpfs
关闭Hive，备份HiveMetastore数据库的数据（以防万一），操作->更新Hive Metastore NameNodes->重启Hive服务


### 升级Python版本为3.8
```shell
cd /opt/software
wget https://www.python.org/ftp/python/3.8.5/Python-3.8.5.tgz
tar -zxvf Python-3.8.5.tgz
xsync或scp -r Python-3.8.5拷贝到其他节点，并对所有节点如下操作
cd Python-3.8.5
yum update -y
yum groupinstall -y 'Development Tools'
yum install -y gcc openssl-devel bzip2-devel libffi-devel
./configure prefix=/usr/local/python3
make && make install
ls -la /usr/bin/python*
vim /usr/bin/yum  #!/usr/bin/python 改为 #!/usr/bin/python2
vim /usr/libexec/urlgrabber-ext-down  #!/usr/bin/python 改为 #!/usr/bin/python2
mv /usr/bin/python /usr/bin/python_bak
ln -s /usr/local/python3/bin/python3.8 /usr/bin/python
ln -s /usr/local/python3/bin/python3.8 /usr/bin/python3
mv /usr/bin/pip /usr/bin/pip_bak
ln -s /usr/local/python3/bin/pip3.8 /usr/bin/pip3
python -V && pip3 -V
---------------后续操作----------------
/usr/local/python3/bin/python3.8 -m pip install --upgrade pip -i https://pypi.doubanio.com/simple
pip3 install pyspark -i https://pypi.doubanio.com/simple
spark-env增加export PYSPARK_PYTHON=/usr/local/python3/bin/python3.8
pip3 install koalas -i https://pypi.doubanio.com/simple
```

### HiveMetastoreServer异常解决
去HMS机器找/var/log/hive看到如下Error日志：
Failed to sync requested HMS notifications up to the event ID xxxxx
查看sentry 异常CounterWait源码发现传递的id比 currentid 大导致一直等待超时，超时时间为200s。
CDH可以启用Sentry同步ACL权限，启动后HDFS、Sentry、HMS三者间权限同步的消息处理，突然大批量的目录权限消息需要处理，后台线程处理不过来，消息积压就会报Failed to sync requested HMS notifications up to the event ID: xxxxx，该错误不会导致HMS不可用但会导致响应速度很慢。
解决：
1. sentry_hms_notification_id表插入最大的ID，重启Sentry忽略掉之前积压的消息
2. 设置Sentry参数sentry.notification.sync.timeout.ms（默认200s）参数调小超时时间，减小等待时间，积压不多的话可以让它自行消费处理掉

### CDH添加外部HDFS集群的nameservice
现在添加对外部HDFS集群nameservice-test的支持。
在配置项hdfs-site.xml 的 HDFS 客户端高级配置代码段（安全阀）中添加配置
```xml
<property>
    <name>dfs.nameservices</name>
    <value>nameservice-dev,nameservice-test</value>
</property>
<property>
    <name>dfs.ha.namenodes.nameservice-test</name>
    <value>nn1,nn2</value>
</property>
<property>
    <name>dfs.namenode.rpc-address.nameservice-test.nn1</name>
    <value>test1:8020</value>
</property>
<property>
    <name>dfs.namenode.rpc-address.nameservice-test.nn2</name>
    <value>test2:8020</value>
</property>
<property>
    <name>dfs.client.failover.proxy.provider.nameservice-test</name>
    <value>org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider</value>
</property>
```

### impala-shell脚本报错
升级Python版本后，Impala-shell报语法错误
原python命令是python2.7，现python命令是python3.8，而/opt/cloudera/parcels/CDH-6.3.1-1.cdh6.3.1.p0.1470567/bin/impala-shell脚本没考虑环境变量，直接用python命令执行，故出现语法兼容性问题。
解决：vim /opt/cloudera/parcels/CDH-6.3.1-1.cdh6.3.1.p0.1470567/bin/impala-shell
将最后一行exec python...替换为exec python2.7
```python
PYTHONPATH="${EGG_PATH}${SHELL_HOME}/gen-py:${SHELL_HOME}/lib:${PYTHONPATH}" \
  exec python2.7 ${SHELL_HOME}/impala_shell.py "$@"
```

### beeline连接Impala
1.拷贝ImpalaJDBC41.jar到/opt/cloudera/parcels/CDH-6.3.1-1.cdh6.3.1.p0.1470567/lib/hive/auxlib
2.beeline -d "com.cloudera.impala.jdbc41.Driver" -u "jdbc:impala://one_impalad_ip:21050"
3.如果报warn：Error: [Simba][JDBC](11975) Unsupported transaction isolation level: 4. (state=HY000,code=11975) 则加beeline参数--isolation=default 


### CDH升级JDK版本
主机-> 选择一台 -> 配置 -> Java 主目录 -> 填上新的jdk路径
每台节点设置/etc/profile中JAVA_HOME和PATH为新jdk路径（或者修改cloudera-scm-server\cloudera-scm-agent启动脚本上添加export JAVA_HOME=xxx）
停止服务
重启CMServer
重启各节点CM Agent
在页面重启CMService
启动服务

### 部署与CDH6组件版本兼容的开源版Spark 2.x
CDH不是自带Spark吗，为什么要使用开源版？因为CDH Spark阉割了很多Spark的功能，不支持spark-sql入口和spark-thriftserver入口，还有一些其他功能，可以参考:[]()
使用Spark2.3.x：下载或编译获得spark2.3.2-bin-hadoop2.6官方tarball可以直接兼容当前CDH个版本。其源码中hive依赖版本为1.2.1.spark2，hadoop版本为2.6.5，作为兼容hive、hadoop的客户端。
使用Spark2.4.x: 下载或编译获得spark2.4.8-bin-hadoop2.7官方tarball，不可直接兼容，需要替换jar包：
```shell
echo "export SPARK_HOME=/opt/spark/spark-2.4.8-bin-hadoop2.7" >> /etc/profile;source /etc/profile
rm -f $SPARK_HOME:/jars/hadoop-yarn*
cp /opt/cloudera/parcels/CDH/jars/hadoop-yarn* $SPARK_HOME:/jars/
cp /opt/cloudera/parcels/CDH/jars/hive-shims-scheduler-2.1.1-cdh6.3.2.jar $SPARK_HOME:/jars/
```
spark-env.sh
```text
JAVA_HOME=/usr/local/jdk1.8.0_181/
HADOOP_CONF_DIR=/etc/hadoop/conf
export SPARK_DIST_CLASSPATH=$(/opt/cloudera/parcels/CDH/bin/hadoop classpath)
export SPARK_LOCAL_DIRS=/data/spark_tmp_data
```
spark-defaults.conf
```text
spark.kryoserializer.buffer.max=512m
spark.serializer=org.apache.spark.serializer.KryoSerializer
spark.eventLog.enabled=false
spark.eventLog.dir=file:///data/spark_tmp_data
spark.driver.extraLibraryPath=/hadoop/cloudera/parcels/CDH/lib/hadoop/lib/native
spark.executor.extraLibraryPath=/hadoop/cloudera/parcels/CDH/lib/hadoop/lib/native
spark.yarn.am.extraLibraryPath=/hadoop/cloudera/parcels/CDH/lib/hadoop/lib/native
spark.executorEnv.JAVA_HOME=/usr/local/jdk1.8.0_181/
spark.yarn.appMasterEnv.JAVA_HOME=/usr/local/jdk1.8.0_181/
spark.local.dir=/data/spark_tmp_data
```
ln -s /etc/hadoop/conf/core-site.xml $SPARK_HOME:/conf/core-site.xml
ln -s /etc/hadoop/conf/hdfs-site.xml $SPARK_HOME:/conf/hdfs-site.xml
ln -s /etc/hadoop/conf/mapred-site.xml $SPARK_HOME:/conf/mapred-site.xml
ln -s /etc/hadoop/conf/yarn-site.xml $SPARK_HOME:/conf/yarn-site.xml
ln -s /etc/hive/conf/hive-site.xml $SPARK_HOME:/conf/hive-site.xml
如果在Kerberos集群启用ThriftServer，在hive-site.xml添加或修改如下参数
```text
  <property>
    <name>hive.metastore.sasl.enabled</name>
    <value>true</value>
  </property>
  <!-- 以下三项填写HMS所在服务器的地址和HiveServer2服务的keytab，HS2服务的keytab文件到HS2节点找最新/var/run/cloudera-scm-agent/process/ 里面的hive.keytab -->
  <property>
    <name>hive.metastore.kerberos.principal</name>
    <value>hive/cdh02@SMYOA.COM</value>
  </property>
  <property>
    <name>hive.server2.authentication.kerberos.principal</name>
    <value>hive/cdh02@SMYOA.COM</value>
  </property>
  <property>
    <name>hive.server2.authentication.kerberos.keytab</name>
    <value>/hadoop/bigdata/kerberos/keytab/hiveserver2_cdh02.keytab</value>
  </property>
  <property>
    <name>hive.server2.authentication</name>
    <value>NONE</value>
  </property>
```
提交任务：
```shell
cd $SPARK_HOME
bin/spark-sql --master yarn
sbin/start-thriftserver.sh --hiveconf hive.server2.thrift.port=10002 --queue thrift  --master yarn --executor-memory 8g --executor-cores 5 --num-executors 20  
[启用Kerberos] sbin/start-thriftserver.sh --hiveconf hive.server2.thrift.port=10002 --queue thrift  --master yarn --executor-memory 8g --executor-cores 5 --num-executors 20  --hiveconf hive.server2.authentication.kerberos.keytab /hadoop/bigdata/kerberos/keytab/hiveserver2_cdh02.keytab
```

### CDH集群修改IP
将原来的192.168.1.x网段修改为10.2.5.x网段
在Hyper-V创建新的虚拟网卡 模拟网卡地址变更
![alt CDH-32](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-32.JPG)  
![alt](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-33.JPG)  
打开控制面板->查看网络连接->找到Cluster 设置IP和DNS
![alt](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-34.JPG)  
设置外网共享 让虚拟机可以连接外部网络
![alt](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-35.JPG)
重新回到上一步设置IP和DNS
![alt](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-34.JPG)  
修改虚拟机设置网络设置
![alt](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-36.JPG)
停止所有cloudera服务
```shell
systemctl stop cloudera-scm-server;systemctl stop cloudera-scm-agent;systemctl stop supervisord
```
修改各节点ip和hosts（以CDH101为例）
```shell
# 修改网卡配置
vim /etc/sysconfig/network-scripts/ifcfg-eth0  内容如下
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
# IPV6INIT=yes
# IPV6_AUTOCONF=yes
# IPV6_DEFROUTE=yes
# IPV6_FAILURE_FATAL=no
# IPV6_ADDR_GEN_MODE=stable-privacy
NAME=eth0
UUID=b6de3f15-8829-44bc-8743-d3cab3cfb62f
DEVICE=eth0
ONBOOT=yes
# IPV6_PRIVACY=no
NM_CONTROLLED=yes
IPADDR=10.2.5.101
NETMASK=255.0.0.0
GATEWAY=10.2.5.2
# DNS1=10.2.5.1
DNS2=10.2.5.2
# 修改hosts
vim /etc/hosts 内容如下
10.2.5.101 cdh101
10.2.5.102 cdh102
10.2.5.103 cdh103
10.2.5.104 cdh104
```
修改CM库的hosts表中IP_ADDRESS字段为新IP
```sql
update scm.HOSTS set IP_ADDRESS = '10.2.5.101' where IP_ADDRESS = '192.168.1.101';
update scm.HOSTS set IP_ADDRESS = '10.2.5.102' where IP_ADDRESS = '192.168.1.102';
update scm.HOSTS set IP_ADDRESS = '10.2.5.103' where IP_ADDRESS = '192.168.1.103';
update scm.HOSTS set IP_ADDRESS = '10.2.5.104' where IP_ADDRESS = '192.168.1.104';
```
修改/etc/hosts下对应的ip映射 
修改Agent配置文件中server_host字段vim /etc/cloudera-scm-agent/config.ini 值为cmserver的hostname
然后poweroff关机
修改虚拟机网卡，替换为DNS为10.2.5.2的新的虚拟网卡
![alt](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-37.JPG)
启动节点，在页面重启ClouderaManagerService、部署各个组件的客户端配置即可


### 升级与CDH6组件版本兼容的开源版Spark 3.x
编译https://blog.csdn.net/Young2018/article/details/108856622
部署https://www.pianshen.com/article/46531976066/



## Cloudera Manager使用
![alt CDH-usage-01](http://imgs.shmily-qjj.top/BlogImages/CDH/CDH-usage-01.JPG)  



## CDH卸载
https://mp.weixin.qq.com/s?__biz=MzI4OTY3MTUyNg==&mid=2247484118&idx=1&sn=e7109978013a286fe1f172f99459c45a&chksm=ec2ad2dfdb5d5bc96fcaeb6ce2ed42a025e1d95ab251372fb4769c29434f0d84fb66bbfec1d2&scene=21#wechat_redirect
