---
title: ElasticSearch学习笔记
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
  - ElasticSearch
  - Kibana
keywords: ElasticSearch
description: 记录ElasticSearch学习笔记，好记性不如烂笔头。
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/ElasticSearch/ElasticSearch-cover.jpg
date: 2022-06-18 12:19:00
---
# ElasticSearch学习笔记

## ES简介与知识准备 
生活中的数据总体分为两种：结构化数据、非结构化数据
结构化数据：由二维表结构来逻辑表达和实现的数据，严格地遵循数据格式与长度规范，主要通过关系型数据库进行存储和管理。
非结构化数据： 又可称为全文数据，不定长或无固定格式，不适于由数据库二维表来表现，包括所有格式的办公文档、XML、HTML、Word 文档，邮件，各类报表、图片和咅频、视频信息等。XML、HTML也可细分为半结构化数据。

对于结构化数据，可以通过二维表(MySQL、Oracle)的方式存储和搜索，可以建立索引。
对于非结构化数据，数据搜索主要有两种方式：**顺序扫描、全文检索**。（顺序扫描：按文字顺序查找特定的关键字，速度慢；全文检索：将非结构化数据中的部分信息提取出来重新组织，使其有一定结构，然后进行检索，速度较快）
这部分从非结构化数据中提取出的然后重新组织的信息，我们称之为**索引**。全文检索主要的开销是创建索引的过程，但后续检索速度很快。

ES与Lucene：
**Lucene**是为软件开发人员提供的全文检索工具包，但它不是一个完整的全文检索引擎，所以有了ES以及Solr、二者都是基于Lucene的较成熟的全文检索引擎。
无论Solr还是ES底层都是依赖于Lucene，而Lucene能实现全文搜索主要是因为它实现了**倒排索引**的查询结构。

倒排索引：
通过分词器将每个文档的内容域拆分成单独的词（我们称它为词条或 Term），创建一个包含所有不重复词条的排序列表，然后列出每个词条出现在哪个文档。
这种结构由文档中所有不重复词的列表构成，对于其中每个词都有一个文档列表与之关联。
这种由属性值来确定记录的位置的结构就是倒排索引。
```text
Java is the best programming language.
PHP is the best programming language.
Javascript is the best programming language.
```
倒排索引图示(倒排索引主要由**词典**和**倒排文件**组成，词典和倒排文件是分两部分存储，词典在内存中而倒排文件存储在磁盘上)
![alt](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/ElasticSearch/ElasticSearch-1.png)
词条（Term）：索引里面最小的存储和查询单元，对于英文来说是一个单词，对于中文来说一般指分词后的一个词。
词典（Term Dictionary）：或字典，是词条Term的集合。搜索引擎的通常索引单位是单词，单词词典是由文档集合中出现过的所有单词构成的字符串集合，单词词典内每条索引项记载单词本身的一些信息以及指向“倒排列表”的指针。
倒排表（Post list）：一个文档通常由多个词组成，倒排表记录的是某个词在哪些文档里出现过以及出现的位置。每条记录称为一个倒排项（Posting）。倒排表记录的不单是文档编号，还存储了词频等信息。
倒排文件（Inverted File）：所有单词的倒排列表往往顺序地存储在磁盘的某个文件里，这个文件被称之为倒排文件，倒排文件是存储倒排索引的物理文件。

**ElasticSearch**
使用Java编写的开源分布式可扩展的文档实时储存分析搜索引擎，支持海量结构化和非结构化数据。

## ES+Kibana部署  
单机测试环境部署
```
1.安装ElasticSearch
  rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
  vim /etc/yum.repos.d/elasticsearch.repo
  [elasticsearch]
  name=Elasticsearch repository for 8.x packages
  baseurl=https://artifacts.elastic.co/packages/8.x/yum
  gpgcheck=1
  gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
  enabled=0
  autorefresh=1
  type=rpm-md
  sudo yum install --enablerepo=elasticsearch elasticsearch
  修改配置文件elasticsearch.yml
  vim /etc/elasticsearch/elasticsearch.yml
  node.name: node-1
  node.attr.rack: r1
  path.data: /data/elasticsearch/data
  path.logs: /data/elasticsearch/logs
  network.host: 10.2.5.100
  http.port: 9200
  # Enable security features
  xpack.security.enabled: true
  xpack.security.enrollment.enabled: true
  # Enable encryption for HTTP API client connections, such as Kibana, Logstash, and Agents
  xpack.security.http.ssl:
    enabled: false
    keystore.path: certs/http.p12
  # Enable encryption and mutual authentication between cluster nodes
  xpack.security.transport.ssl:
    enabled: true
    verification_mode: certificate
    keystore.path: certs/transport.p12
    truststore.path: certs/transport.p12
  # Create a new cluster with the current node only
  # Additional nodes can still join the cluster later
  cluster.initial_master_nodes: ["node1.shmily-qjj.top"]
  # Allow HTTP API connections from anywhere
  # Connections are encrypted and require user authentication
  http.host: 0.0.0.0
  http.cors.enabled: true
  http.cors.allow-origin: "*"
  http.cors.allow-headers: Authorization,X-Requested-With,Content-Length,Content-Type
  启动
  systemctl enable elasticsearch
  systemctl start elasticsearch
  systemctl status elasticsearch
  设置环境变量:
  export ES_HOME=/usr/share/elasticsearch
  export PATH=$PATH:$ES_HOME/bin
  source /etc/profile
  修改密码：
  elasticsearch-reset-password --username elastic -i
  访问:
  http://10.2.5.100:9200/ 输入帐号密码 elastic/123456
2.安装Kibana
  rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
  vim /etc/yum.repos.d/kibana.repo
  [kibana-8.x]
  name=Kibana repository for 8.x packages
  baseurl=https://artifacts.elastic.co/packages/8.x/yum
  gpgcheck=1
  gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
  enabled=1
  autorefresh=1
  type=rpm-md
  sudo yum install kibana
  准备一个kibana用户(用户名不能是elastic) kibana_system/123456
  curl -u elastic:123456 -XPUT 'http://10.2.5.100:9200/_security/user/kibana_system/_password' -H 'Content-Type: application/json' -d '{ "password" : "123456" }'
  修改如下部分配置：
  vim /etc/kibana/kibana.yml
  server.host: "0.0.0.0"
  server.publicBaseUrl: "http://10.2.5.100:5601"
  elasticsearch.hosts: ["http://10.2.5.100:9200"]
  elasticsearch.username: "kibana_system"
  elasticsearch.password: "123456"
  logging:
    appenders:
      file:
        type: file
        fileName: /data/kibana/kibana.log
        layout:
          type: json
  启动kibana:
  systemctl enable kibana
  systemctl restart kibana
  systemctl status kibana
  访问kibana:
  http://10.2.5.100:5601/ 输入帐号密码 elastic/123456
```
至此单机模式部署完毕，可供测试和学习使用

## ES使用

### 创建索引

### 增

### 删


### 改


### 查


### 运维相关
```shell
1.检查集群运行状况 （status分为green、yellow、red，green代表一切正常所有分片和副本都正常；yellow表示预警状态，所有主分片正常，但存在不正常的副本，高可用性收到影响；red表示集群存在严重问题，存在不可用的分片，可以查询但结果不准确，异常分片的写入会报错，数据丢失）
curl -u elastic:123456 10.2.5.100:9200/_cluster/health | jq
```

## ES原理
### ES分片Shards
ES支持PB级全文搜索，数据量巨大时为了实现良好的水平扩展能力，ES将数据水平拆分到不同数据块上，拆出来的一个块为一个分片。
ES创建索引时指定了分片数量，一旦分片数量确定则不能修改。
```text
创建索引时指定分片数和副本数
PUT /indexName  
{  
   "settings" : {  
      "number_of_shards" : 5,  
      "number_of_replicas" : 1  
   }  
}  
```
数据分片是为了提高可容纳数据容量，易于水平扩展。

### ES副本Replicas
为了保证数据高可靠性，ES每个分片都可以有0到多个副本。当主分片异常时，副本可以提供数据查询能力。
主分片和副本分片不会在同一节点上。副本数最大值为N-1(N为节点数)。

ES写操作是并发的，必须在主分片上完成写入操作后才会同步到相关副本分片。 
为了避免并发写过程产生数据冲突，ES通过乐观锁的方式控制，每个文档都有_version字段，版本号，当文档被修改时版本号递增。
ES所有副本分片都报告写入成功后，才会向协调节点报告成功，协调节点才会反馈客户端写成功。

数据副本是为了提高集群稳定性和查询并发。副本越多，写入操作消耗越大，但数据可靠性越高，集群可用性越高。（每个分片就相当于一个Lucene索引文件。）

### ES写数据
写索引是只能写在主分片上，然后同步到副本分片。
数据写到哪个分片是通过公式**hash(Routing) % number_of_primary_shards = shard**
Routing是一个可变值，默认是文档_id，也可以自定义。
number_of_primary_shards是主分片的数量。
0 <= shard <= number_of_primary_shards - 1
分片数量在创建索引时就确定并且无法修改，就是以为如果能修改，则根据这个shard分配算法就无法再找到数据所在的shard了。
在一个写请求被发送到某个节点后，该节点即为协调节点，协调节点会根据路由公式计算出需要写到哪个分片上，再将请求转发到该分片的主分片节点上。
具体流程：1.客户端向A节点请求写入数据 2.A节点作为协调节点，通过路由公式计算出应当写入哪个分片，并将请求转发到分片所在节点 3.分片所在节点接受请求并将数据写入到磁盘 4.并发将数据写入分片的其他副本，乐观锁控制数据冲突 5.一旦所有副本节点返回成功，则主分片所在节点向协调节点报告写入成功 6.协调节点向客户端返回写入成功

### ES映射[Mapping](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping.html)
Mapping用于定义ES对索引中字段存储类型、分词方式等信息。类似于Schema，描述了文档可能具有的属性、字段和字段的类型。（字段类型可以不指定，让ES动态推测，也可以在创建索引时指定具体数据类型。）
**动态映射(Dynamic Mapping)**：根据数据格式自动识别的Mapping
**静态映射(Explicit Mapping)(显式映射)**：创建索引时具体定义字段类型的Mapping
比如指定了Keyword类型的字段和指定了Text类型的字段：
Keyword用于索引**结构化内容**的字段，例如电子邮件地址，主机名，状态代码，邮政编码或标签。它们通常用于过滤，排序，和聚合。**Keyword字段只能按其确切值进行搜索**。
Text用于索引**全文值**的字段，例如电子邮件正文或产品说明。这些字段是被分词的，它们通过分词器传递 ，以在被索引之前将字符串转换为单个术语的列表。

创建索引时的模板
```text
PUT /indexName   
{  
   "settings" : {  
      "number_of_shards" : 5,  
      "number_of_replicas" : 1  
   }  
  "mappings": {  
    "_doc": {   
      "properties": {   
        "title":    { "type": "text"  },   
        "name":     { "type": "text"  },   
        "age":      { "type": "integer" },    
        "created":  {  
          "type":   "date",   
          "format": "strict_date_optional_time||epoch_millis"  
        }  
      }  
    }  
  }  
}  
```


### ES集群
ES集群不需要第三方协调服务，ES自身内部实现了集群管理和自动发现协调功能，ES集群中每个节点指定相同的cluster.name即可加入集群。每个节点不同的是node.name，如果不设置则名称随机。

ES基于内部Zen Discovery模块实现节点发现，它提供单播和基于文件的发现，并且可以扩展为通过插件支持云环境和其他形式的发现。

ES节点分两种角色：node.master和node.data
数据节点负责增删改查、聚合统计等操作，对性能配置要求比较高，
主节点负责创建索、删除索引、跟踪哪些节点是群集的一部分，并决定哪些分片分配给相关的节点、追踪集群中节点的状态等，稳定的主节点对集群的健康是非常重要的。
一个节点既可以是候选主节点也可以是数据节点，但数据节点资源消耗大，可能影响主节点的功能，所以还是建议主节点和数据节点分开部署。
集群中任何节点都可以作为协调节点，以接收用户请求。

### ES存储原理



字颜色大小
<font size="3" color="red">This is some text!</font>
<font size="2" color="blue">This is some text!</font>
<font face="verdana" color="green"  size="3">This is some text!</font>

## 参考
[2 万字详解，吃透 ES！](https://mp.weixin.qq.com/s/m7TZ6ljpNtc1b6yAnrT5TA)



