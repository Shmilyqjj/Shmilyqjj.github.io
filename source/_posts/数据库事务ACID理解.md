---
title: 数据库事务ACID理解
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
  - 数据库
keywords: 事务ACID与隔离级别
description: 事务的ACID，加深一下印象
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/Mysql/MYSQL-ACID-Cover.jpg
abbrlink: 1f7eb1b3
date: 2019-12-28 20:22:00
---
# Intro  
对于事务ACID，知道大概的意思，但总觉得对这个概念还有点模糊，所以写一篇博客加深一下印象。  

## 数据库的事务  
一个事务中可能有多个操作，当所有操作都成功了的情况下这个事务才会被提交，如果其中一个操作失败，整个事务都将回滚(Rollback)到事务开始前的状态，好像这个事务从未执行过。  
简单来说就是:要么什么都不做，要么做全套（All or Nothing）  
  
## ACID  
ACID是指数据库事务正确执行的四个基本特征的缩写  
![alt MYSQL-ACID-01](http://imgs.shmily-qjj.top/BlogImages/Mysql/MYSQL-ACID-01.png)  
通过上图可以大概了解ACID的基本特征，下面做详细介绍

### 原子性（Atomicity）  
事务中包含的操作集合，<font size="3" color="red">**要么全部操作执行完成，要么全部都不执行**</font>。即当事务执行过程中，发生了某些异常情况，如系统崩溃、执行出错，则需要对已执行的操作进行回滚，清除所有执行痕迹。  
例子：A向B转账100，这个事务包括两步(A失去100，B得到100)，原子性保证这两步都成功或者都失败。

### 一致性（Consistency）  
事务执行前和事务执行后，数据库的<font size="3" color="red">**完整性约束不被破坏**</font>。即事务的执行是从一个有效状态转移到另一个有效状态。  
例子：A向B转账100，这个事务包括两步(A失去100，B得到100)，A和B所在的表收入和支出存在外键约束，若A支出增加而B收入未增加，则违反了一致性约束。  

### 隔离性（Isolation）  
数据库允许多个并发事务同时对数据进行读写和修改的能力，如果一个事务要访问的数据正在被另外一个事务修改，只要另外一个事务未提交，它所访问的数据就不受未提交事务的影响。  
隔离性可以<font size="3" color="red">**防止多个事务并发执行时由于交叉执行而导致数据的不一致**</font>。  
多个事务并发执行时，彼此之间不应该存在相互影响。隔离程度不是绝对的，每个数据库都提供有自己的隔离级别，每个数据库的默认隔离级别也不尽相同。  
例子：A向B转账100，交易还未完成时，B查询不到100元入账。

### 持久性（Durability）  
事务正常执行完毕后，<font size="3" color="red">**对数据库的修改是永久性的，即便系统故障也不会丢失**</font>。即事务的修改操作已经记录到了存储介质中。  
例子：A向B转账100，A永久失去了100元而B永久得到100元，不能赖账。

### 总结ACID  
* 原子性：<u>事务操作的整体性。</u>  
* 一致性：<u>事务操作下数据的正确性。</u>  
* 隔离性：<u>事务并发操作下数据的正确性。</u>  
* 持久性：<u>事务对数据修改的可靠性。</u>  

## 事务隔离级别  
上面说过“每个数据库都提供有自己的隔离级别，每个数据库的默认隔离级别也不尽相同”，事物隔离级别分为四种，下面一一介绍。  
首先简述**共享锁（S）**和**排它锁（X）**，方便后续理解：<u>多个共享锁(S)可以同时获取，但是排它锁(X)会阻塞其它所有锁</u>

1. 未提交读(Read Uncommitted)  
指一个事务读取到了另外一个事务未提交的数据。即事务的修改阶段未加排他锁，对其他事务可见。  
例如事务T1可能读取到只是事务T2中某一步的修改状态，即存在**脏读**的现象。  
<u>**脏读**</u>：事务读取到的数据可能是不正确、不合理或者处于非法状态的数据，例如在事务T1读取后，事务T2可能又对数据做了修改，或者事务T2中某些操作违反了一致性约束，做了回滚操作，该情况下事务T1读取到的数据称之为脏数据，该行为称之为**脏读**。  
2. 提交读(Read Committed)  
一个事务过程中只能读取到其他事务对数据的提交后修改，即事务的修改阶段加了排它锁，直到事务结束才释放，执行读命令那一刻加了共享锁，读完即释放，以此维持事务修改阶段对其他事务的不可见。  
例如事务T2读取到的只能是事务T2提交完成后的状态。该隔离级别避免了脏读现象，但正是由于**事务T1可能读取到的是事务T2修改完成后的数据**，以致出现了**不可重复读**现象。  
<u>**不可重复读**</u>：对于同一个事务的前后两次读取操作，读取到的内容不同。例如在事务T1读取操作后，事务T2可能对数据做了修改，事务T2修改完成提交后，事务T1又做了读取操作，因为内容已被修改，导致读取到的内容与上一次不同，即存在**不可重复读**现象。
3. 可重复读(Repeatable Reads)  
一个事务过程中不允许其他事务对数据进行修改。即事务的读取过程加了共享锁，事务的修改过程加了排它锁，并一直维持锁定状态直到事务结束。  
因为事务的读取或修改都需要维持整个阶段的锁定状态，所以避免了脏读和不可重复读现象。但是因为只对**现有的记录**上进行了锁定，并未维持间隙锁/范围锁，导致某些数据记录的插入未受阻拦**（结果多了一行）**，即存在**幻读**现象。  
<u>**幻读**</u>：事务中前后相同的查询语句，返回的结果集不同。例如在事务T1查询表记录后，事务T2向表中增加了一条记录，当事务T1再次执行相同的查询时，返回的结果集可能不同，即存在幻读现象。  
4. 可串行化(Serializable)  
一个事务过程中不允许其他事务对指定范围数据进行修改。即事务过程中若指定了操作集合的范围，**在可重复读的锁基础上增加了对操作集合的范围锁**，通过增加范围锁避免了幻读现象。  

**四种隔离级别设置:**  

| 级别 | 说明 |
| :----: | :----:|
| Serializable | 可避免脏读、不可重复读、虚读情况的发生 |
| Repeatable read | 可避免脏读、不可重复读情况的发生 |
| Read committed | 可避免脏读情况发生 |
| Read uncommitted | 最低级别，以上情况均无法保证 |  

锁的使用是为了在并发环境中保持每个业务流处理结果的正确性，这样的概念在计算机领域中很普遍，但是都必须要基于一个前提，或者称之为约定：**在执行操作前，首先尝试去获取锁，获取成功则可以执行，若获取失败，则不执行或等待重复获取**。因为无论任何类型的操作，有没有锁都不影响程序本身的执行流程，但只有遵从这个约定才能体现出其价值。就像红绿灯并不影响车辆本身的行驶能力，只有声明所有个体皆遵守相同的规则，所以一切才变得有序。  
在数据库的并发环境下，**隔离程度越高，也就意味着并发程度越低，所以各个数据库中一般设置的都是一个折中的隔离级别**。

**基于Mysql测试隔离级别**  
```sql
SELECT @@global.tx_isolation;  # 查看全局事物隔离级别
SELECT @@session.tx_isolation;  # 查看会话事物隔离级别
SELECT @@tx_isolation;    # 查看当前事务隔离级别
  
SET SESSION TRANSACTION ISOLATION LEVEL read uncommitted;  # 可避免脏读、不可重复读、虚读情况的发生
SET SESSION TRANSACTION ISOLATION LEVEL read committed;  # 可避免脏读情况发生
SET SESSION TRANSACTION ISOLATION LEVEL repeatable read;  # 可避免脏读、不可重复读情况的发生
SET SESSION TRANSACTION ISOLATION LEVEL serializable;  # 可避免脏读、不可重复读、幻读情况的发生

start transaction;

--建表
drop table AMOUNT;
CREATE TABLE `AMOUNT` (
`id`  varchar(10) NULL,
`money`  numeric NULL
)
;
--插入数据
insert into amount(id,money) values('A', 800);
insert into amount(id,money) values('B', 200);
insert into amount(id,money) values('C', 1000);
--测试可重复读，插入数据
insert into amount(id,money) values('D', 1000);

--设置事务
SET SESSION TRANSACTION ISOLATION LEVEL read uncommitted;  
SELECT @@tx_isolation;  
--开启事务
start transaction;

--脏读演示，读到其他事务未提交的数据
--案列1，事务一：A向B转200，事务二：查看B金额变化，事务一回滚事务
update amount set money = money - 200 where id = 'A';
update amount set money = money + 200 where id = 'B';

--不可重复读演示，读到了其他事务提交的数据
--案列2，事务一：B向A转200，事务二：B向C转200转100
SET SESSION TRANSACTION ISOLATION LEVEL read committed;  

--开启事务
start transaction;
--两个事务都查一下数据(转账之前需要，查一下金额是否够满足转账)
select * from amount;
--事务一：B向A转200
update amount set money = money - 200 where id = 'B';
update amount set money = money + 200 where id = 'A';

commit;
--事务二：B向C转200转100
update amount set money = money - 100 where id = 'B';
update amount set money = money + 100 where id = 'C';
commit;
--从事务二的角度来看，读到了事务一提交事务的数据，导致金额出现负数

--幻读演示
--案列3，事务一：B向A转200，事务二：B向C转200转100
SET SESSION TRANSACTION ISOLATION LEVEL repeatable read;  

--开启事务
start transaction;
--两个事务都查一下数据(转账之前需要，查一下金额是否够满足转账)
select * from amount;
--事务一：B向A转200
update amount set money = money - 200 where id = 'B';
update amount set money = money + 200 where id = 'A';

commit;
--事务二：B向C转200转100
update amount set money = money - 100 where id = 'B';
update amount set money = money + 100 where id = 'C';
commit;
--从事务二的角度来看，读到了事务一提交事务的数据，导致金额出现负数
```



## 参考资料   
[事务的ACID](https://www.cnblogs.com/fanBlog/p/11081777.html)  
[事务ACID理解](https://blog.csdn.net/dengjili/article/details/82468576)  
[事务ACID属性与隔离级别](https://www.jianshu.com/p/f3605aacf7cf)