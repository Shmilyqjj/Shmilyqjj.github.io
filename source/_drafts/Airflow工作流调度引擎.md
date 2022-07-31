---
title: Airflow工作流调度引擎
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
  - 任务调度
  - 工作流引擎
keywords: Airflow任务调度
description: 工作流调度与管理方案
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/Airflow/Airflow-Cover.jpg
date: 2021-04-11 12:16:00
---
# Airflow工作流调度引擎  

## Airflow介绍  

### 优势与缺点

### 应用场景

## Airflow架构与原理

### 系统架构

### Executor




  
## Airflow部署与使用
### 安装Airflow 2.0.1
1. 开始安装
```shell
# Python版本3.6-3.8;pip版本20.2.4;MySQL: 5.7或8;
pip install --upgrade pip==20.2.4 -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com
pip install mysqlclient -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com  [解决ModuleNotFoundError: No module named 'MySQLdb']
# 指定Airflow安装版本和Python版本（我安装2.0.1的Airflow，系统Python版本3.8）
# Airflow2.x的Python依赖管理更加人性化，引入了constraint约束文件来保存依赖关系，减少安装过程出现的异常
# 安装命令：
pip install "apache-airflow==2.0.1" --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-2.0.1/constraints-3.8.txt" -i http://pypi.douban.com/simple/ --trusted-host pypi.douban.com
```
2. 配置后端数据库并初始化启动
参考[setting-up-a-mysql-database](https://airflow.apache.org/docs/apache-airflow/stable/howto/set-up-database.html#setting-up-a-mysql-database)来设置Airflow的后端数据库为MySQL
参考[Running Airflow locally](https://airflow.apache.org/docs/apache-airflow/stable/start/local.html)进行Airflow基础配置和初始化启动
```text
 vim /etc/my.cnf  在mysqld那栏下添加explicit_defaults_for_timestamp=1参数，重启mysqld
 # mysql -hcdh103 -uroot -p123456 连接mysql并建立相关库和用户 airflow\123456
 CREATE DATABASE airflow_db CHARACTER SET utf8 COLLATE utf8_unicode_ci;
 CREATE USER 'airflow' IDENTIFIED BY '123456';
 GRANT ALL PRIVILEGES ON airflow_db.* TO 'airflow';
 # 创建Airflow快捷启动脚本 touch /usr/bin/airflow;chmod u+x /usr/bin/airflow 内容如下
   #!/bin/bash
   /usr/bin/python3 -m airflow $*
 # 修改/etc/profile  source /etc/profile
 #AIRFLOW_HOME
 export AIRFLOW_HOME=/opt/modules/airflow
 export PATH=$PATH:$AIRFLOW_HOME/bin
 # 先运行一下airflow webserver --port 8081 会在AIRFLOW_HOME生成配置文件，继续下面的修改
 # 修改配置文件 $AIRFLOW_HOME/airflow.cfg
 # 数据库链接规则：mysql+mysqldb://<user>:<password>@<host>[:<port>]/<dbname>
 default_timezone = Asia/Shanghai
 sql_alchemy_conn = mysql+mysqldb://airflow:123456@192.168.1.103:3306/airflow_db
 base_url = http://192.168.1.103:8081
 web_server_host = 192.168.1.103
 web_server_port = 8081
 # 初始化数据库 airflow db init
 # 创建用户 输入密码
 airflow users create \
     --username admin \
     --firstname qjj \
     --lastname qjj \
     --role Admin \
     --email 710552907@qq.com
 # 使用8081端口启动Web服务  通过网页访问http://192.168.1.103:8081
 airflow webserver
 # 后台启动airflow scheduler执行器
 airflow scheduler -D
```

3. 安装过程Trouble Shooting
```text
1.ModuleNotFoundError: No module named '_sqlite3'
首先yum -y install sqlite sqlite-devel
备份python依赖包以防万一pip freeze > requirements.txt
重新编译Python3：
  cd Python-3.8.5
  ./configure prefix=/usr/local/python3  （指定以前的安装路径）
  make && make install
命令行import sqlite3不报错即成功
2.启动webserver报Error: No module named airflow.www.gunicorn_config
首先确定pip list | grep gunicorn 版本是https://raw.githubusercontent.com/apache/airflow/constraints-2.0.1/constraints-3.8.txt指定好的
如果版本正确，可能的原因是sys.path里有多个gunicorn导致失败，如下操作，保证sys.path中只有一个gunicorn
mv /usr/bin/gunicorn /usr/bin/gunicorn_bak
ln -s  /usr/local/python3/bin/gunicorn /usr/bin/gunicorn
再重新启动webserver 成功
3.WARN：Could not import DAGs in example_kubernetes_executor_config.py: No module named 'kubernetes'
pip install kubernetes
```

4. 编写启动停止脚本 用法./airflow-service.sh [start|stop|restart|status] [webserver|scheduler|all]
```shell
#!/bin/bash
OP=$1
ROLE=$2
if [[ $(whoami) != root ]]; then echo "Please run this script with root user.";exit 2;fi
# Check params
if [ "$OP" != "start" -a "$OP" != "stop" -a "$OP" != "status" -a "$OP" != "restart" ]; then
  echo "Usage: ./airflow-service.sh [start|stop|restart|status] [webserver|scheduler|all]"
  exit 1
elif [ "$ROLE" != "webserver" -a "$ROLE" != "scheduler" -a "$ROLE" != "all" ]; then
  echo "Usage: ./airflow-service.sh [start|stop|restart|status] [webserver|scheduler|all]"
  exit 1
else
  echo "Airflow $ROLE $OP ..."
fi
# Check AIRFLOW_HOME
if [[ -n $AIRFLOW_HOME ]]; then
  # AIRFLOW_HOME is set.
  echo "Airflow home is $AIRFLOW_HOME."
else
  AIRFLOW_HOME=~/airflow
  echo "Airflow home is not set,use $AIRFLOW_HOME ."
fi
# Check Python3.8 Env
PYTHON_EXEC=$(which python3)
# Get PID
WEBSERVER_PID=$(echo -e "$(ps -ef | grep airflow-webserver | grep -v grep | awk '{print $2}')\n$(ps -ef | grep "airflow webserver" | grep -v grep | awk '{print $2}')")
SCHEDULER_PID=$(ps -ef | grep "airflow scheduler" | grep -v grep | awk '{print $2}')
# Do operations.
function start_role() {
  echo "Starting role $1 ..."
  if [ "$1" = "webserver" ]; then
    nohup $PYTHON_EXEC -m airflow webserver >> $AIRFLOW_HOME/airflow-webserver.log 2>&1 & 
  elif [ "$1" = "scheduler" ]; then
    $PYTHON_EXEC -m airflow scheduler -D   
  else
    echo "Wrong airflow role name."
  fi
}
function stop_role() {
  echo "Stopping role $1 ..."
  if [ "$1" = "webserver" ]; then
    if [ -z "$WEBSERVER_PID" ]; then
      echo "Airflow webserver is not running."
     else
      echo $WEBSERVER_PID | xargs kill -9
    fi
    rm -f $AIRFLOW_HOME/airflow-webserver.pid
  elif [ "$1" = "scheduler" ]; then
     if [ -z "$SCHEDULER_PID" ]; then
      echo "Airflow scheduler is not running."
     else
      echo $SCHEDULER_PID | xargs kill -9
     fi
     rm -f $AIRFLOW_HOME/airflow-scheduler.pid
  else
    echo "Wrong airflow role name."
  fi
}
function role_status_check() {
  echo "Checking $1 status..."
  if [ "$1" = "webserver" ]; then
    if [ -z "$(ps -ef | grep airflow-webserver | grep -v grep)" ]; then
      echo "Airflow webserver is not running."
    else
      ps -ef | grep "airflow webserver" | grep -v grep
      ps -ef | grep airflow-webserver | grep -v grep
    fi
  elif [ "$1" = "scheduler" ]; then
    if [ -z "$(ps -ef | grep "airflow scheduler" | grep -v grep)" ]; then
      echo "Airflow scheduler is not running."
    else
      ps -ef | grep "airflow scheduler" | grep -v grep
    fi
  else  
    echo "Wrong airflow role name."
  fi
}
if [ "$OP" == "start" ]; then
  if [ "$ROLE" == "all" ]; then
    start_role webserver
    start_role scheduler
    role_status_check webserver
    role_status_check scheduler
  else
    start_role $ROLE
    role_status_check $ROLE
  fi
elif [ "$OP" == "stop" ]; then
  if [ "$ROLE" == "all" ]; then
    stop_role webserver
    stop_role scheduler
  else
    stop_role $ROLE
  fi
elif [ "$OP" == "status" ]; then
  if [ "$ROLE" == "all" ]; then
    role_status_check webserver
    role_status_check scheduler
  else
    role_status_check $ROLE
  fi
elif [ "$OP" == "restart" ]; then
  if [ "$ROLE" == "all" ]; then
    stop_role webserver
    start_role webserver
    stop_role scheduler
    start_role scheduler
    sleep 6
    role_status_check webserver
    role_status_check scheduler
  else
    stop_role $ROLE
    start_role $ROLE
    sleep 6
    role_status_check $ROLE
  fi
else
  echo "Usage: ./airflow-service.sh [start|stop|restart|status] [webserver|scheduler|all]"
  exit 1
fi
```
通过以上配置，我们的Airflow可以正常运行了，但仅仅可以用于测试环境。
<font size="3" color="red">**以上是最基础的部署方式，使用的是默认的SequentialExecutor，它不能提供并行执行的功能，只能用于测试，而生产环境上一般都使用CeleryExecutor，下面我们开始切换Executor为CeleryExecutor**</font>

5. 准备工作-安装RabbitMQ



### 使用Airflow




可选与Airflow绑定的额外功能包 参考链接：
[extra-packages-ref](https://airflow.apache.org/docs/apache-airflow/stable/extra-packages-ref.html)
[packages-ref](https://airflow.apache.org/docs/apache-airflow-providers/packages-ref.html)


## 总结 

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
[Airflow官方文档](https://airflow.apache.org/docs/apache-airflow/stable/index.html)
[详细deploy-airflow](https://leeif.me/2019/deploy-airflow.html)

