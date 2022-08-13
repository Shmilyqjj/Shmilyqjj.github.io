---
title: 浅谈group by与distinct去重
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
  - SQL
keywords: group by与distinct
description: group by与distinct去重
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/Mysql/MYSQL-groupby-distinct-intro.jpg
abbrlink: '96009187'
date: 2019-11-13 20:45:37
---
# 前言  
今天带我的老哥让我改一下报警模块，把一些联系方式等信息存在Mysql里，方便以后管理和维护，很简单的东西，为了减少Mysql并发压力，我想每次报警只查询一次数据库，但子查询返回的结果有重复记录，于是我写了个类似***SELECT col1,col2,col3,col4 FROM (select...) GROUP BY col1;***的语句来去重，可以正常执行不报错且达到了目的就直接使用了，也没深究。直到老哥看了代码说找我说老弟呀你这个逻辑，有点问题呀。。。  

按理说，GROUP BY都是要与聚合函数搭配使用的，所以确实是逻辑有问题，写代码规范很重要，规范的同时还要弄清楚原理，于是就有了这篇博客，详细说一下使用GROUP BY和DISTINCT去重...  

## DISTINCT去重  
DISTINCT可多字段去重，每个字段的值都完全相同的情况下使用DISTINCT去重  
DISTINCT也可以单个字段值去重 select(name),id from table;
```sql
mysql> select name,tel,wxid from person_info where wxid in ('SCALA');    
+--------+-------+-------+
| name   | tel   | wxid  |
+--------+-------+-------+
| scala  | 10010 | SCALA |
| scala1 | 10010 | SCALA |
+--------+-------+-------+
2 rows in set (0.00 sec)

mysql> select distinct name,tel,wxid from person_info where wxid in ('SCALA');
+--------+-------+-------+
| name   | tel   | wxid  |
+--------+-------+-------+
| scala  | 10010 | SCALA |
| scala1 | 10010 | SCALA |
+--------+-------+-------+
2 rows in set (0.00 sec)

mysql> select distinct tel from person_info where wxid in ('SCALA');          
+-------+
| tel   |
+-------+
| 10010 |
+-------+
1 row in set (0.00 sec)

mysql> select distinct name from person_info where wxid in ('SCALA');    
+--------+
| name   |
+--------+
| scala  |
| scala1 |
+--------+
2 rows in set (0.00 sec)

mysql> select distinct tel,wxid from person_info where wxid in ('SCALA');       
+-------+-------+
| tel   | wxid  |
+-------+-------+
| 10010 | SCALA |
+-------+-------+
1 row in set (0.00 sec)
```  
通过上面的实验可以看出，DISTINCT的去重效果是 如果取出的所有字段的值都完全相同则可以去重，如果取出的字段不完全相同，就无法去重。


## GROUP BY  
GROUP BY与聚合函数连用，主要用于分组聚合，但它也可以用来去重，与DISTINCT相反，它支持多个字段值不完全相同的情况下去重，但会舍弃一些值。  
假如A,B,C三个字段，A和B两个字段在多条记录中值都相同，但C不同，使用GROUP BY去重后只会得到一条记录，C的值只保留一个，其余记录C字段不同的值舍弃。  
```sql
mysql> select distinct name,tel,wxid from person_info where wxid in ('SCALA'); 
+--------+-------+-------+
| name   | tel   | wxid  |
+--------+-------+-------+
| scala  | 10010 | SCALA |
| scala1 | 10010 | SCALA |
| scala2 | 10010 | SCALA |
+--------+-------+-------+
3 rows in set (0.00 sec)

# GROUP BY的正确用法  分组聚合
mysql> select count(name),tel,wxid from person_info group by tel;                  +-------------+-------+--------+
| count(name) | tel   | wxid   |
+-------------+-------+--------+
|           1 | 10000 | SBT    |
|           3 | 10010 | SCALA  |
|           1 | 10086 | PYTHON |
|           1 | 110   | QJJ    |
|           1 | 114   | JAVA   |
|           1 | 119   | MAVEN  |
|           1 | 120   | JJQ    |
+-------------+-------+--------+
7 rows in set (0.00 sec)

# 报警模块不希望重复报警，所以只想获取一个电话号码   下面的语句逻辑有问题，不符合GROUP BY的使用规范，但是能执行
mysql> select name,tel,wxid from person_info where wxid in ('SCALA') group by tel;
+-------+-------+-------+
| name  | tel   | wxid  |
+-------+-------+-------+
| scala | 10010 | SCALA |
+-------+-------+-------+
1 row in set (0.00 sec)

# 改成符合使用规范的  
mysql> select max(name),tel,wxid from person_info where wxid in ('SCALA') group by tel;
+-----------+-------+-------+
| max(name) | tel   | wxid  |
+-----------+-------+-------+
| scala2    | 10010 | SCALA |
+-----------+-------+-------+
1 row in set (0.00 sec)
mysql> select min(name),tel,wxid from person_info where wxid in ('SCALA') group by tel;
+-----------+-------+-------+
| min(name) | tel   | wxid  |
+-----------+-------+-------+
| scala     | 10010 | SCALA |
+-----------+-------+-------+
1 row in set (0.00 sec)

# 
mysql> select name,tel,wxid from person_info where wxid in ('SCALA') group by tel,name;
+--------+-------+-------+
| name   | tel   | wxid  |
+--------+-------+-------+
| scala  | 10010 | SCALA |
| scala1 | 10010 | SCALA |
| scala2 | 10010 | SCALA |
+--------+-------+-------+
3 rows in set (0.00 sec)

mysql> select name,tel,wxid from person_info where wxid in ('SCALA') group by tel,tel;
+-------+-------+-------+
| name  | tel   | wxid  |
+-------+-------+-------+
| scala | 10010 | SCALA |
+-------+-------+-------+
1 row in set (0.00 sec)
```  
从上面实验可以得出的结论:
如果只需要tel和wxid两个字段，无所谓name的字段值，就可以用GROUP BY的方式去重，但是也要尽量写得规范。  
如果需要name字段的值，就不能用GROUP BY来去重了。  

## 问题情景重现  
报警有两种方式，一种是传人名，还有一种是传组名，人与组是多对多关系  
联系方式信息存为两张表，person_info和group_info,大致如下  
name 人名，tel是电话，wxid是微信，groupname是组名
```sql
mysql> show tables;
+----------------+
| Tables_in_test |
+----------------+
| group_info     |
| persion_info   |
+----------------+
2 rows in set (0.00 sec)

mysql> desc person_info;
+-------+--------------+------+-----+---------+-------+
| Field | Type         | Null | Key | Default | Extra |
+-------+--------------+------+-----+---------+-------+
| name  | varchar(255) | NO   | PRI | NULL    |       |
| tel   | varchar(255) | NO   |     | NULL    |       |
| wxid  | varchar(255) | NO   |     | NULL    |       |
+-------+--------------+------+-----+---------+-------+
3 rows in set (0.00 sec)

mysql> desc group_info;
+-----------+--------------+------+-----+---------+-------+
| Field     | Type         | Null | Key | Default | Extra |
+-----------+--------------+------+-----+---------+-------+
| name      | varchar(255) | NO   | PRI | NULL    |       |
| groupname | varchar(255) | NO   |     | NULL    |       |
+-----------+--------------+------+-----+---------+-------+
2 rows in set (0.00 sec)

mysql> select * from person_info;
+--------+-------+--------+
| name   | tel   | wxid   |
+--------+-------+--------+
| java   | 114   | JAVA   |
| jjq    | 120   | JJQ    |
| maven  | 119   | MAVEN  |
| python | 10086 | PYTHON |
| qjj    | 110   | QJJ    |
| sbt    | 10000 | SBT    |
| scala  | 10010 | SCALA  |
+--------+-------+--------+
7 rows in set (0.00 sec)

mysql> select * from group_info;
+--------+-------------+
| name   | groupname   |
+--------+-------------+
| java   | languages   |
| jjq    | person      |
| maven  | build-tools |
| python | languages   |
| qjj    | person      |
| sbt    | build-tools |
| scala  | languages   |
+--------+-------------+
7 rows in set (0.00 sec)
```  
报警接口传进来的参数可能是多个人名或者组名的组合列表，我想通过一次查询获取到所有报警人信息，于是我先写了内部子查询:
```sql
SELECT t2.name,t2.tel,t2.wxid,t1.groupname
FROM person_info t2
RIGHT JOIN group_info t1 ON t2.name = t1.name
WHERE groupname IN ('qjj','jjq','person')
UNION ALL
SELECT IFNULL(name,0),tel,wxid,'groupname'
FROM person_info
WHERE name IN ('qjj','jjq','person');

# 结果:
+------+------+------+-----------+
| name | tel  | wxid | groupname |
+------+------+------+-----------+
| jjq  | 120  | JJQ  | person    |
| qjj  | 110  | QJJ  | person    |
| jjq  | 120  | JJQ  | groupname |
| qjj  | 110  | QJJ  | groupname |
+------+------+------+-----------+
4 rows in set (0.00 sec)
```  

因为有重复的人名和重复的联系方式会重复报警，所以为了避免重复报警，我又加了外面的一层:
```sql
SELECT name,tel,wxid,max(groupname) FROM
(SELECT t2.name,t2.tel,t2.wxid,t1.groupname
FROM person_info t2
RIGHT JOIN group_info t1 ON t2.name = t1.name
WHERE groupname IN ('qjj','jjq','person')
UNION ALL
SELECT IFNULL(name,0),tel,wxid,'groupname'
FROM person_info
WHERE name IN ('qjj','jjq','person')) a
GROUP BY name;

# 结果:
+------+------+------+----------------+
| name | tel  | wxid | max(groupname) |
+------+------+------+----------------+
| jjq  | 120  | JJQ  | person         |
| qjj  | 110  | QJJ  | person         |
+------+------+------+----------------+
2 rows in set (0.01 sec)
```  
准确地拿到了name,tel,wxid，但是groupname字段呢，到底是哪个被舍弃了？不同情况下不一定。如果我们只要name,tel,wxid这三个字段，在groupname字段上加个max()好了，这样逻辑也说得通，也比较规范，如果要求精确拿到groupname字段的值，就不能使用group by去重。  

## 关于效率  
DISTINCT和GROUP BY同时适用的场景下，**不能说一定是谁的效率更高**
DISTINCT就是字段值对比的方式，要遍历整个表。GROUP BY类似于先建索引再查索引。
**小表DISTINCT去重效率高，大表GROUP BY去重效率高**

## 总结  
* 认清DISTINCT和GROUP BY的去重场景  
* 某些场景下DISTINCT与GROUP BY去重同时适用，但DISTINCT效率更高  
* 代码要规范且符合逻辑  
* 要对SQL每个语法的使用场景有明确的认识  
* 多总结问题  
