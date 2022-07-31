---
title: Linux Bind服务配置DNS解析
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
  - DNS
  - Bind
  - Linux
keywords: DNS
description: DNS解析服务配置
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/Linux/DNS/DNS-cover.jpg
abbrlink: 39a9ed67
date: 2022-06-01 20:12:10
---
# Linux服务器配置DNS解析服务Bind

## BIND简介
BIND是现在使用最为广泛的DNS服务器软件（Berkeley Internet Name Domain）,支持先今绝大多数的操作系统（Linux，UNIX，Mac，Windows）。BIND服务的名称称之为named。DNS默认使用UDP、TCP协议，使用端口为53（domain），953（mdc，远程控制使用）。

## DNS服务端配置
1. 安装bind
准备两台DNS服务器 kdc1(10.2.5.3) kdc2(10.2.5.4) 安装
```shell
yum -y install bind bind-utils
rpm -qa | grep bind
```
2. 配置bind
 配置文件分别位于两个位置
 /etc/named.conf　BIND服务主配置文件
 /var/named/　　　zone文件（域的dns信息）
 先修改主DNS Server上的配置文件/etc/named.conf
 cp /etc/named.conf /etc/named.conf.template
 vim /etc/named.conf
 ```conf
options {
        listen-on port 53 { 127.0.0.1;10.2.5.3; };
        listen-on-v6 {none;};
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query-cache {any;};
        allow-query  { 10.2.5.0/8; };
        forward only;
        forwarders {10.2.5.2;8.8.8.8;};

        recursion yes;
        allow-recursion { any;};

        dnssec-enable no;
        dnssec-validation no;
        recursive-clients 1000000;
        tcp-clients 10000;
        send-cookie no;
        require-server-cookie no;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "." IN {
        type hint;
        file "named.ca";
};
zone "shmily-qjj.top" IN {
        type master;
        file "shmily-qjj.top.zone";
        notify yes;
        also-notify { 10.2.5.4; };
        allow-update { none; };
};
zone "10.in-addr.arpa" IN {
        type master;
        file "ptr.shmily-qjj.top.zone";
        notify yes;
        also-notify { 10.2.5.4; };
        allow-update { none; };
};
#include "/etc/named.rfc1912.zones";
#include "/etc/named.root.key";
```
 主DNS Server上添加解析ZONE文件
 正向解析文件 vim /var/named/shmily-qjj.top.zone 
 ```zone
$TTL    1D
@               IN SOA  dns1.shmily-qjj.top.    admin.shmily-qjj.top. (
                                        2022060101
                                        3H
                                        15M
                                        1W
                                        1D )
@       IN  NS  dns1.shmily-qjj.top.
@       IN  NS  dns2.shmily-qjj.top.  
dns1  IN  A  10.2.5.3
dns2  IN  A  10.2.5.4
;kdc ldap
kdc1.shmily-qjj.top IN A 10.2.5.3
kdc2.shmily-qjj.top IN A 10.2.5.4
;cdh
cdh101 IN A 10.2.5.101
cdh102 IN A 10.2.5.102
cdh103 IN A 10.2.5.103
cdh104 IN A 10.2.5.104
;other nodes
node1.shmily-qjj.top IN A 10.2.5.100
```  

反向解析文件 vim /var/named/ptr.shmily-qjj.top.zone  
```zone
$TTL    1D
@               IN SOA  dns1.shmily-qjj.top.    admin.shmily-qjj.top. (
                                        2022060101
                                        3H
                                        15M
                                        1W
                                        1D )
@       IN  NS  dns1.shmily-qjj.top.
@       IN  NS  dns2.shmily-qjj.top.
;kdc ldap
3.5.2 IN PTR kdc1.shmily-qjj.top
4.5.2 IN PTR kdc2.shmily-qjj.top
;cdh
101.5.2 IN PTR cdh101
102.5.2 IN PTR cdh102
103.5.2 IN PTR cdh103
104.5.2 IN PTR cdh104
;;other nodes
100.5.2 IN PTR node1.shmily-qjj.top
```  

修改备DNS Server上的配置文件/etc/named.conf
```conf
options {
        listen-on port 53 { 127.0.0.1;10.2.5.4; };
        listen-on-v6 {none;};
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query-cache {any;};
        allow-query  { 10.2.5.0/8; };
        forward only;
        forwarders {10.2.5.2;8.8.8.8;};

        recursion yes;
        allow-recursion { any;};

        dnssec-enable no;
        dnssec-validation no;
        recursive-clients 1000000;
        tcp-clients 10000;
        send-cookie no;
        require-server-cookie no;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
zone "." IN {
        type hint;
        file "named.ca";
};
zone "shmily-qjj.top" IN {
        type slave;
        file "slaves/shmily-qjj.top.zone";
        notify no;
        masters { 10.2.5.3; };
};
zone "10.in-addr.arpa" IN {
        type slave;
        file "slaves/ptr.shmily-qjj.top.zone";
        notify no;
        masters { 10.2.5.3; };
};
#include "/etc/named.rfc1912.zones";
#include "/etc/named.root.key";
```

两台节点分别启动的DNS服务
```shell
systemctl enable named
systemctl start named
systemctl status named
```

3. rndc同步  
 rndc（Remote Name Domain Controllerr）是一个远程管理bind的工具，通过这个工具可以在本地或者远程了解当前服务器的运行状况，也可以对服务器进行关闭、重载、刷新缓存、增加删除zone等操作。 
 使用rndc可以在不停止DNS服务器工作的情况进行数据的更新，使修改后的配置文件生效。在实际情况下，DNS服务器是非常繁忙的，任何短时间的停顿都会给用户的使用带来影响。因此，使用rndc工具可以使DNS服务器更好地为用户提供服务。在使用rndc管理bind前需要使用rndc生成一对密钥文件，一半保存于rndc的配置文件中，另一半保存于bind主配置文件中。rndc的配置文件为/etc/rndc.conf，在CentOS或者RHEL中，rndc的密钥保存在/etc/rndc.key文件中。rndc默认监听在953号端口（TCP），其实在bind9中rndc默认就是可以使用，不需要配置密钥文件。
 rndc与DNS服务器实行连接时，需要通过数字证书进行认证，而不是传统的用户名/密码方式。在当前版本下，rndc和named都只支持HMAC-MD5认证算法，在通信两端使用预共享密钥。在当前版本的rndc 和 named中，唯一支持的认证算法是HMAC-MD5，在连接的两端使用共享密钥。它为命令请求和名字服务器的响应提供 TSIG类型的认证。所有经由通道发送的命令都必须被一个服务器所知道的 key_id 签名。为了生成双方都认可的密钥，可以使用rndc-confgen命令产生密钥和相应的配置，再把这些配置分别放入named.conf和rndc的配置文件rndc.conf中。
 修改主节点ZONE配置文件（需要修改ZONE文件的编号）
 **注意：修改了ZONE编号，即使配置没发生变化，配置仍然会同步到备用DNS；未修改ZONE编号，即使配置发生变化，也不会同步到备用DNS**
 vim /var/named/shmily-qjj.top.zone
 ![alt](http://imgs.shmily-qjj.top/BlogImages/Linux/DNS/DNS-1.jpg)  
 执行rndc reload 提示server reload successful证明成功

 验证备节点解析
 将/etc/resolv.conf中nameserver指向备节点10.2.5.4
 ![alt](http://imgs.shmily-qjj.top/BlogImages/Linux/DNS/DNS-2.jpg)  
 查看备节点目录修改时间
 ![alt](http://imgs.shmily-qjj.top/BlogImages/Linux/DNS/DNS-3.jpg)  

## DNS客户端节点配置
客户端配置
vim /etc/resolv.conf
```conf
search shmily-qjj.top
nameserver 10.2.5.3
nameserver 10.2.5.4
```

验证：
注释掉/etc/hosts下的ip地址映射
安装bind-utils
yum install bind-utils
正向解析验证
nslookup kdc1.shmily-qjj.top
nslookup kdc2.shmily-qjj.top
nslookup node1.shmily-qjj.top
ping kdc1.shmily-qjj.top -c 3
ping kdc2.shmily-qjj.top -c 1
ping node1.shmily-qjj.top -c 1
![alt](http://imgs.shmily-qjj.top/BlogImages/Linux/DNS/DNS-4.jpg)  

反向解析验证
nslookup 10.2.5.3
nslookup 10.2.5.100
![alt](http://imgs.shmily-qjj.top/BlogImages/Linux/DNS/DNS-5.jpg)  


## 参考
[bind配置工具rndc使用](https://www.jianshu.com/p/f08cf7cebf3f)


