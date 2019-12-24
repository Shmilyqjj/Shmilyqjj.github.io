---
title: Hive3.x来了
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
  - Hive
keywords: Hive
description: Hive 3.x来了,学习一下新特性
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-cover.jpg
abbrlink: 7fbbfd34
date: 2019-12-22 15:18:25
---
# Hive3.x新特性  
## 新特性简述  
![alt Hive3.x-0](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Hive/Hive3.x-0.JPG)  
1. 执行引擎变更为**[TEZ](https://tez.apache.org/)**,不使用MR  
2. ACID大数据事务支持  
3. [LLAP](https://cwiki.apache.org/confluence/display/Hive/LLAP)用于妙极，毫秒级查询访问  
4. 基于[Apache Ranger](http://ranger.apache.org/)的统一权限管理  
5. 默认开启HDFS ACLs  
6. Beeline代替Hive Cli  
7. 不再支持内嵌Metastore  
8. Spark Catalog不与Hive Catalog集成，但可以互相访问  
9.批处理使用TEZ，实时查询使用LLAP  

## 应用  

## 架构原理
1. TEZ执行引擎  

## 优缺点  


更多内容: [Writing](https://hexo.io/docs/writing.html)
Hadoop统一授权管理框架[Apache Ranger](http://ranger.apache.org/)

 

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

* 列表
无序列表用* + -三种符号表示
    * 列表嵌套
    1. 有序列表第一项：
        - 第一项嵌套的第一个元素
        - 第一项嵌套的第二个元素
    2. 有序列表第二项：
        - 第二项嵌套的第一个元素
        - 第二项嵌套的第二个元素
            * 最多第三层嵌套
            + 最多第三层嵌套
            - 最多第三层嵌套


更多内容: [Server](https://hexo.io/docs/server.html)

## 部署（中标题） 
### 首先
``` shell
    sudo rm -rf /
```

更多内容: [Generating](https://hexo.io/docs/generating.html)

## 参考资料  

[Hive3新特性](https://www.jianshu.com/p/a1324fb4eb80)
[]()
[]()
[]()
[]()
[]()

``` Java
public class HelloWorld {
    public static void main(String[] args){
        System.out.print("Shmily-qjj");
    }
}
```

更多内容: [Deployment](https://hexo.io/docs/deployment.html)