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
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-intro.jpg
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
![alt CDH-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-01.jpg) 
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
VMWare 15  
SecureCRT 8.1.4  
FileZilla 3.40.0  
CentOS 7  

### 一.基础配置  
**下载CentOS7:**  
[CentOS7 Minimal下载](http://mirrors.aliyun.com/centos/7.7.1908/isos/x86_64/CentOS-7-x86_64-Minimal-1908.iso)

**虚拟机配置**  
采用NAT格式网卡,按如下配置  
虚拟网卡设置（编辑-虚拟网络编辑器）  
![alt CDH-02](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-02.jpg)  
点击NAT设置:  
![alt CDH-2.5](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-02.5.jpg) 
点击DHCP设置:  
![alt CDH-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-03.jpg)  
以后我们的虚拟机都使用NAT网卡  
**安装CentOS7**  
文件->新建虚拟机->选择自定义(高级)->下一步->下一步->**稍后安装操作系统**->选择Linux/CentOS7 64位->下一步->虚拟机名称CDH066->下一步  
->根据自己电脑设置核心数->下一步->虚拟机内存5120MB->网络类型选NAT->下一步...->磁盘分配80GB->下一步->下一步->自定义硬件->选择CentOS7的安装镜像,如图:  
![alt CDH-03.5](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-03.5.jpg)  
关闭->完成->开启此虚拟机 
开始安装  
![alt CDH-04](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-04.jpg)  
安装Minimal版的CentOS，感觉很清爽！但是后续需要自己手动装一些依赖包，不过这样也好，可以避免安装过多无用的依赖。  

在这步安装时指定root密码123456  
安装时指定一个管理员用户shmily 密码123456  
![alt CDH-05](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-05.jpg)  
![alt CDH-05.5](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-05.5.jpg)  

安装完成后Reboot，按步骤进行如下配置  
```shell
 rm -rf * 

 vi /etc/sysconfig/network   
 NETWORKING=yes
 HOSTNAME=CDH066
 
 vi /etc/sysconfig/network-scripts/ifcfg-ens33  修改以下几项的值
 BOOTPROTO=static
 ONBOOT=yes
 NM_CONTROLLED=yes
 IPADDR=192.168.1.66
 GATEWAY=192.168.1.2
 DNS1=192.168.1.2
 
 vi /etc/sudoers  添加以下，必要的话可以加其他用户权限控制策略，这里我对root和shmily两个用户赋权
 root ALL=(ALL)  ALL
 shmily ALL=(ALL)  ALL
 
 service NetworkManager start
 systemctl start NetworkManger
 systemctl enable NetworkManger
 service NetworkManager start
 chkconfig NetworkManager on
 
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
 localhost.localdomain改为CDH066
 
 vi /etc/hosts  # 添加如下记录
 192.168.1.66 CDH066
 192.168.1.67 CDH067
 192.168.1.68 CDH068
 192.168.1.69 CDH069
 
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
192.168.1.66 CDH066
192.168.1.67 CDH067
192.168.1.68 CDH068
192.168.1.69 CDH069

重新用SecureCRT连接出现如下图:
![alt CDH-06](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-06.jpg)  
Accept & Save,输入密码并勾选Save password  
完成  
FileZilla也能连接了:  
![alt CDH-07](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-07.jpg)  

检查一下网络:  
ping 8.8.8.8  
能ping通即可进行下一步，如果ping不通，需要仔细检查网络配置文件:  
![alt CDH-08](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-08.jpg)  

安装python:  
CentOS7 Minimal默认带Python2.7.5版本，已经满足需求，所以，安装个ipython吧  
```shell
 yum -y install epel-release
 yum install python-pip
 pip install --upgrade pip
 pip install -i https://pypi.tuna.tsinghua.edu.cn/simple requests  # 安装必要的库可以指定源 以安装requests库为例
 pip install -i https://pypi.tuna.tsinghua.edu.cn/simple ipython   # 安装ipython
```
完成后，命令行执行python即可运行python2.7.5，命令行执行ipython即可使用ipython  

安装一些必要的常用命令[必要]
yum install bind-utils  
yum -q install /usr/bin/iostat  
yum install vim  
yum install wget  
yum install iotop  
yum install lsof  
yum install -y git  
yum install dstat(全面的系统监控工具-推荐)  
yum install nload  

安装一些CDH的必要依赖[必要] 
```shell
 yum -y install chkconfig bind-utils psmisc libxslt zlib sqlite cyrus-sasl-plain cyrus-sasl-gssapi fuse portmap fuse-libs redhat-lsb httpd httpd-tools unzip ntp
 systemctl start httpd.service  # 启动httpd服务
 systemctl enable httpd.service # 设置httpd开机启动
 yum -y install httpd createrepo  # createrepo是安装CDH6集群必备
 # 配置ntp时间同步服务
 ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
 ntpdate ntp1.aliyun.com  # 立即同步时间
 # 设置同步时间池
 sed -i 's/server 0.centos.pool.ntp.org iburst/server ntp1.aliyun.com/g' /etc/ntp.conf
 sed -i 's/server 1.centos.pool.ntp.org iburst/server ntp2.aliyun.com/g' /etc/ntp.conf
 sed -i 's/server 2.centos.pool.ntp.org iburst/server ntp3.aliyun.com/g' /etc/ntp.conf
 sed -i 's/server 3.centos.pool.ntp.org iburst/server ntp4.aliyun.com/g' /etc/ntp.conf
 service ntpd restart  # 重新启动 ntp 服务
 systemctl enable ntpd.service  # 设置开机自启
 ntpdc -c loopinfo  # 查看时间偏差
 ntpstat
```  

```shell

 
```


还有一些其他的监控命令[Linux监控命令汇总](https://blog.csdn.net/qq_15766181/article/details/89928275)  

JDK安装  
下载JDK包并通过FileZilla上传到/opt/software  
```shell
 tar -zxvf /opt/software/jdk-8u221-linux-x64.tar.gz -C /opt/module/
 
 vim /etc/profile
 #JAVA_HOME      
 export JAVA_HOME=/opt/module/jdk1.8.0_221
 export PATH=$JAVA_HOME/bin:$PATH
 export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
 
 source /etc/profile
```

安装mariadb  代替mysql5.7  
```shell
 yum install mariadb-server
 systemctl start mariadb  # 开启服务
 
 grep 'temporary password' /var/log/mysqld.log  # 找到root初始密码，我的是UlKbg8TGOD_=
 mysql -uroot -pUlKbg8TGOD_=  # 登陆mysql
 ALTER USER 'root'@'localhost' IDENTIFIED BY '123456'; # 修改数据库密码为123456
 systemctl enable mariadb  # 设置开机启动
 systemctl status mariadb # 重启后查看mariadb状态
  - mysql_secure_installation  # 安全配置
 	- Enter current password for root (enter for none): 输入密码回车
 	- Change the root password? [Y/n]    n回车
 	- Remove anonymous users? [Y/n] y回车  # 移除匿名用户
 	- Disallow root login remotely? [Y/n] y回车  # 禁止root远程登陆
 	- Remove test database and access to it? [Y/n]   y回车
 	- Reload privilege tables now? [Y/n] y火车  # 刷新配置立即生效
 
 mysql -hlocalhost -P3306 -uroot  -p123456 # 注意现在远程是不能访问root的
 # 如果想远程登录使用其他用户，则需要增加远程登陆权限：
 CREATE USER 'mysql'@'%' IDENTIFIED BY '123456';  # root登陆然后创建用户及其密码（用户名mysql为例）
 GRANT ALL ON my_db.* TO 'mysql'@'%';  # 赋予mysql用户所有权限
 flush privileges; # 刷新配置 
 Query OK, 0 rows affected (0.001 sec)
 mysql -umysql -p123456  # 用新用户登陆
 show databases;  # 查看新用户的数据库
 mysql -h192.168.1.66 -P3306 -umysql  -p123456  # 此时另一个局域网内机器可以访问除root用户外其他用户的数据库
 
 # 配置utf-8字符集
 vim /etc/my.cnf 添加
 [mysqld]
 init_connect='SET collation_connection = utf8_unicode_ci' 
 init_connect='SET NAMES utf8' 
 character-set-server=utf8 
 collation-server=utf8_unicode_ci 
 skip-character-set-client-handshake
 
 vim /etc/my.cnf.d/mysql-clients.cnf 
 在[mysql]下添加
 default-character-set=utf8
 
 vim /etc/my.cnf.d/client.cnf
 在[client]下添加
 default-character-set=utf8
 
 systemctl restart mariadb # 重启服务
 show variables like "%character%";  # 查看是否修改成功
 show variables like "%collation%";
```
查看字符集是否修改成功-如图则修改成功:  
![alt CDH-09](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-09.jpg)  

设置用户最大能打开文件数目、进程数和内存  
```shell
 vim /etc/security/limits.conf 插入以下:
 * soft nofile 32728
 * hard nofile 1029345
 * soft nproc 65536
 * hard nproc unlimited
 * soft memlock unlimited
 * hard memlock unlimited
```  
![alt CDH-10](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-10.jpg)  

好玩的screenfetch(可选，用来娱乐...)  
```bash
 cd /usr/local/src
 git clone https://github.com/KittyKatt/screenFetch.git
 cp screenFetch/screenfetch-dev /usr/local/bin/screenfetch
 chmod 777 /usr/local/bin/screenfetch
```
![alt CDH-11](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-11.jpg)  

我的配置暂时这样，更多安全与防火墙配置参考[安全与防火墙配置](https://blog.csdn.net/thinktik/article/details/81046318)  
有关linux用户和组的详细文章:[Linux用户和组](https://www.cnblogs.com/pengyunjing/p/8543026.html)  

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
vim /etc/sysconfig/network-scripts/ifcfg-ens33  
删除UUID和HWADDR  
IPADDR重新分配为192.168.1.67  
修改后如图  
![alt CDH-12](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-12.jpg)  

vi /etc/sysconfig/network  
NETWORKING=yes  
HOSTNAME=CDH067  

vi /etc/hostname  
CDH066改为CDH067  

重启 reboot  

同样方式修改CDH068,CDH069  

检查：  
1. ping8.8.8.8能通  
2. 使用SecureCRT可以正常连接到机器  
3. ifconfig 或 ip addr命令查看ip地址成功改过来了  
则配置成功  

### 三.配置免密登录  
在四台机器分别操作：  
ssh-keygen  并连续敲三下回车

在66机器上  
ssh-copy-id CDH066   建立 CDH066自身免密  
ssh-copy-id CDH067   建立 CDH066 -> CDH067单向免密  
ssh-copy-id CDH068   建立 CDH066 -> CDH068单向免密  
ssh-copy-id CDH069   建立 CDH066 -> CDH069单向免密  

在67机器上  
ssh-copy-id CDH066   建立 CDH067 -> CDH066单向免密  
ssh-copy-id CDH067   建立 CDH066自身免密  
ssh-copy-id CDH068   建立 CDH067 -> CDH068单向免密  
ssh-copy-id CDH069   建立 CDH067 -> CDH069单向免密  

在68机器上  
ssh-copy-id CDH066   建立 CDH068 -> CDH066单向免密  
ssh-copy-id CDH067   建立 CDH068 -> CDH067单向免密  
ssh-copy-id CDH068   建立 CDH068自身免密  
ssh-copy-id CDH069   建立 CDH068 -> CDH069单向免密  

在69机器上  
ssh-copy-id CDH066   建立 CDH069 -> CDH066单向免密  
ssh-copy-id CDH067   建立 CDH069 -> CDH067单向免密  
ssh-copy-id CDH068   建立 CDH069 -> CDH068单向免密  
ssh-copy-id CDH069   建立 CDH069自身免密  

测试都能免密登录:  
![alt CDH-13](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-13.jpg)  
至此免密登录配置完成  

### 四.CDH6安装   
下面的是下载地址，因为我之前手动安装了JDK1.8，所以可以不下载<u>oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm</u>这个包，其余的包全部下载下来  
[CDH6.3.1下载地址](https://archive.cloudera.com/cm6/6.3.1/redhat7/yum/RPMS/x86_64/)  
还需要一个asc文件，下载地址：[allkeys.asc](https://archive.cloudera.com/cm6/6.3.1/allkeys.asc),右键另存为即可  
**在CDH066节点上进行操作**  
mkdir /opt/software/cloudera-repos  
将下载的所有文件通过FileZilla上传到/opt/software/cloudera-repos目录，目录结构如下:  
├── allkeys.asc
├── cloudera-manager-daemons-6.3.1-1466458.el7.x86_64.rpm
├── cloudera-manager-agent-6.3.1-1466458.el7.x86_64.rpm
├── cloudera-manager-server-db-2-6.3.1-1466458.el7.x86_64.rpm
├── enterprise-debuginfo-6.3.1-1466458.el7.x86_64.rpm
└── cloudera-manager-server-6.3.1-1466458.el7.x86_64.rpm

scp -r /opt/software/cloudera-repos  root@CDH067:/opt/software/
scp -r /opt/software/cloudera-repos  root@CDH068:/opt/software/
scp -r /opt/software/cloudera-repos  root@CDH069:/opt/software/

各个节点执行如下命令
```shell
 cd /opt/software/cloudera-repos  
 createrepo .

 # 将cloudera-repos目录移动到httpd的html目录下 制作本地源
 cd..
 mv cloudera-repos /var/www/html/
 
 cd /etc/yum.repos.d
 touch cloudera-manager.repo  
 vim cloudera-manager.repo  添加如下:  
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
制作本地源后http://cdh066/cloudera-repos/这个链接可以访问到源的文件  
![alt CDH-14](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/CDH/CDH-14.jpg)  

安装Cloudera Manager组件:  
```shell
# 在CDH066节点运行
 yum install cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server --skip-broken --nogpgcheck
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

