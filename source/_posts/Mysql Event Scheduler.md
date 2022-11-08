---
title: Mysql Event Scheduler
author: 佳境
avatar: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/Resources/img/custom/avatar.jpg
authorLink: shmily-qjj.top
authorAbout: 你自以为的极限，只是别人的起点
authorDesc: 你自以为的极限，只是别人的起点
categories:
  - 技术
comments: true
tags:
  - Mysql
keywords: 事件调度器
description: Mysql事件调度器
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Mysql/MYSQL-event-scheduler-intro.jpg
abbrlink: 3c26421b
date: 2019-11-15 21:25:04
---
# Mysql事件调度器  
工作的时候遇到一张表需要每天Truncate，就想到了Mysql的Event Scheduler，但是又忘了它的语法了，所以这里来复习一下。  
## 什么是Event Scheduler  
事件调度器，可以作为定时调度器，类似于Crontab，可以取代部分操作系统任务调度器的定时任务工作。Mysql在5.1版本后新增了事件调度器，它可以支持秒级调度，很实用方便。  
时间调度器也可以看作是一个触发器，是针对某个表进行操作的，时间调度器执行采用了单独一个线程，可通过***SHOW PROCESSLIST***命令查看 

  
## Event Scheduler语法
```sql
CREATE
    [DEFINER = { user | CURRENT_USER }]
    EVENT
    [IF NOT EXISTS]
    event_name
    ON SCHEDULE schedule
    [ON COMPLETION [NOT] PRESERVE]
    [ENABLE | DISABLE | DISABLE ON SLAVE]
    [COMMENT 'string']
    DO event_body;

schedule:
    AT timestamp [+ INTERVAL interval] ...
  | EVERY interval
    [STARTS timestamp [+ INTERVAL interval] ...]
    [ENDS timestamp [+ INTERVAL interval] ...]

interval:
    quantity {YEAR | QUARTER | MONTH | DAY | HOUR | MINUTE |
              WEEK | SECOND | YEAR_MONTH | DAY_HOUR | DAY_MINUTE |
              DAY_SECOND | HOUR_MINUTE | HOUR_SECOND | MINUTE_SECOND}
```  
语法说明：
- DEFINER：指定可执行该定时器的MySQL账号，user的格式是’user_name’@’host_name’，CURRENT_USER或CURRENT_USER()，单引号是需要在语句中输入的。如果不指定，默认是DEFINER = CURRENT_USER。
- event_name：事件名称，最大64个字符，不区分大小写，MyEvent和myevent是一样的，命名规则和其他MySQL对象是一样的。
- ON SCHEDULE schedule：ON SCHEDULE指定事件何时执行，执行的频率和执行的时间段，有AT和EVERY两种形式。
- [ON COMPLETION [NOT] PRESERVE]：可选，preserve是保持的意思，这里是说这个定时器第一次执行完成以后是否还需要保持，如果是NOT PRESERVE，该定时器只执行一次，完成后自动删除事件；没有NOT，该定时器会多次执行，可以理解为这个定时器是持久性的。默认是NOT PRESERVE。
- [ENABLE | DISABLE | DISABLE ON SLAVE]：可选，是否启用该事件，ENABLE-启用，DISABLE-禁用，可使用alter event语句修改该状态。DISABLE ON SLAVE是指在主备复制的数据库服务器中，在备机上也创建该定时器，但是不执行。
- COMMENT: 注释，必须用单引号括住。
- DO event_body：事件要执行的SQL语句，可以是一个SQL，也可以是使用BEGIN和END的复合语句，和存储过程相同。

## ON SCHEDULE时间类型
两种时间类型***AT timestamp***和***Every interval***  
### AT timestamp  
用于只执行一次的事件。执行的时间由timestamp指定，timestamp必须包含完整的日期和时间，即年月日时分秒都要有。可以使用DATETIME或TIMESTAMP类型，或者可以转换成时间的值，例如“2018-01-21 00:00:00”。如果指定是时间是过去的时间，该事件不会执行，并生成警告。  

```sql
mysql> create table test(id int,name varchar(255));
Query OK, 0 rows affected (0.01 sec)

mysql> select NOW();
+---------------------+
| NOW()               |
+---------------------+
| 2019-11-16 11:30:59 |
+---------------------+
1 row in set (0.00 sec)

mysql> create event insert_test ON SCHEDULE AT '2019-11-16 11:30:59' DO show tables;
Query OK, 0 rows affected, 1 warning (0.00 sec)

mysql> show warnings\G;
*************************** 1. row ***************************
  Level: Note
   Code: 1588
Message: Event execution time is in the past and ON COMPLETION NOT PRESERVE is set. The event was dropped immediately after creation.
1 row in set (0.00 sec)

ERROR: 
No query specified

mysql> create event insert_test ON SCHEDULE AT '2019-11-16 11:34:59' DO show tables; 
Query OK, 0 rows affected (0.01 sec)

mysql> create event insert_test ON SCHEDULE AT '2019-11-16 11:37:59' DO insert into test(id,name) values (1,'qjj'); 
Query OK, 0 rows affected (0.00 sec)
```  
时间过后我发现我的test表里仍然没数据
```sql
mysql> show variables like "event_scheduler";
+-----------------+-------+
| Variable_name   | Value |
+-----------------+-------+
| event_scheduler | OFF    |
+-----------------+-------+
1 row in set (0.00 sec)
```
原因是我没开启event_scheduler  
vim /etc/my.cnf 在[mysqld]这一栏下添加***event_scheduler = ON***来永久启用event_scheduler  
重启mysql服务***systemctl restart mysqld.service***

```sql
mysql> select NOW();
+---------------------+
| NOW()               |
+---------------------+
| 2019-11-16 11:40:37 |
+---------------------+
1 row in set (0.00 sec)

mysql> create event insert_test ON SCHEDULE AT '2019-11-16 11:41:37' DO insert into test(id,name) values (1,'qjj');       
Query OK, 0 rows affected (0.00 sec)

mysql> select * from test;                                                               +------+------+
| id   | name |
+------+------+
|    1 | qjj  |
+------+------+
1 row in set (0.00 sec)

mysql> show events;
Empty set (0.00 sec)

# 一小时后执行 命令示例 
mysql> CREATE EVENT update_test ON SCHEDULE AT CURRENT_TIMESTAMP + INTERVAL 1 HOUR DO UPDATE test SET id = 2;   
Query OK, 0 rows affected (0.00 sec)
```  
上述结果说明:必须先开启event_scheduler之后event才会生效，AT timestamp的方式只会在指定时间点执行一次，然后这个event就会被销毁，如果指定的时间是过去的是时间点，则这个event会有警告，且不执行也不保留event。
    
### Every interval
让事件定期执行，每多久执行一次  
ON SCHEDULE后面时间写法的几个栗子：  
EVERY 6 WEEK 每六周  
EVERY 20 second 每20秒  
EVERY 3 MONTH STARTS CURRENT_TIMESTAMP + INTERVAL 1 WEEK 一周以后开始，每隔三个月  
EVERY 2 WEEK STARTS CURRENT_TIMESTAMP + INTERVAL ‘6:15’ HOUR_MINUTE 6小时15分钟以后开始，每隔两周执行  
EVERY 1 DAY STARTS CURRENT_TIMESTAMP + INTERVAL 5 MINUTE ENDS CURRENT_TIMESTAMP + INTERVAL 2 WEEK  5分钟以后开始，每隔一天执行，两周后结束  

举个栗子  
```sql
mysql> create event daily_truncate_test
    -> ON SCHEDULE
    -> EVERY 1 DAY
    -> COMMENT '每天执行一次清空test表数据'
    -> DO
    -> truncate test;
Query OK, 0 rows affected (0.00 sec)

mysql> mysql> show events;
+------+---------------------+-------------+-----------+-----------+---------------------+----------------+----------------+---------------------+------+---------+------------+----------------------+----------------------+--------------------+
| Db   | Name                | Definer     | Time zone | Type      | Execute at          | Interval value | Interval field | Starts              | Ends | Status  | Originator | character_set_client | collation_connection | Database Collation |
+------+---------------------+-------------+-----------+-----------+---------------------+----------------+----------------+---------------------+------+---------+------------+----------------------+----------------------+--------------------+
| test | daily_truncate_test | root@CDH066 | SYSTEM    | RECURRING | NULL                | 1              | DAY            | 2019-11-16 12:10:36 | NULL | ENABLED |          1 | utf8                 | utf8_unicode_ci      | utf8_unicode_ci    |
| test | update_test         | root@CDH066 | SYSTEM    | ONE TIME  | 2019-11-16 12:58:52 | NULL           | NULL           | NULL                | NULL | ENABLED |          1 | utf8                 | utf8_unicode_ci      | utf8_unicode_ci    |
+------+---------------------+-------------+-----------+-----------+---------------------+----------------+----------------+---------------------+------+---------+------------+----------------------+----------------------+--------------------+
2 rows in set (0.00 sec)

mysql> SHOW PROCESSLIST;
+----+-----------------+--------------+------+---------+------+-----------------------------+------------------+
| Id | User            | Host         | db   | Command | Time | State                       | Info             |
+----+-----------------+--------------+------+---------+------+-----------------------------+------------------+
|  1 | event_scheduler | localhost    | NULL | Daemon  |  721 | Waiting for next activation | NULL             |
|  7 | root            | CDH066:34902 | test | Query   |    0 | starting                    | SHOW PROCESSLIST |
+----+-----------------+--------------+------+---------+------+-----------------------------+------------------+
2 rows in set (0.00 sec)


# 示例2 指定每天具体时间点的event事件
CREATE EVENT truncate_with_time
ON SCHEDULE EVERY 1 day STARTS date_add(concat(current_date(), ' 00:00:00'), interval 0 second)
ON COMPLETION PRESERVE ENABLE
COMMENT
DO
TRUNCATE test;
```

## 操作和查看事件  
```sql
show events;  # 查看事件及其状态
ALTER EVENT daily_truncate_test DISABLE;  # 禁用指定事件
ALTER EVENT daily_truncate_test ENABLE;   # 启用指定事件
ALTER EVENT daily_truncate_test RENAME TO daily_truncate;   # 重命名事件
ALTER EVENT test.daily_truncate_test RENAME TO qjj_test.daily_truncate_test;    # 事件是数据库层面的，可以把事件从一个数据库移动到另一个数据库(另一个数据库要有对应的表)  
DROP EVENT daily_truncate;   # 删除事件
```

## 总结  
Mysql作为最热门的关系型数据库之一，有很多东西值得我们去探索，好记性不如烂笔头，写了博客，对事件调度器的理解更加深刻了。

