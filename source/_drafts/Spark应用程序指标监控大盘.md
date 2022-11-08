---
title: Spark应用程序指标监控大盘
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
  - 大数据
  - Spark
  - 监控
keywords: 监控大盘
description: 实现对线上Spark应用的实时指标监控
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Zeppelin/Zeppelin-cover.jpg
date: 2021-04-20 11:54:00
---
# Spark应用程序指标监控大盘


## 使用JVMProfiler+InfluxDB+Grafana实现
不仅仅是Spark应用程序，其他基于JVM的应用程序都可以采用这套监控方案，是一种比较通用的监控方案

[如何用Uber JVM Profiler等可视化工具监控Spark应用程序](https://blog.csdn.net/weixin_33933118/article/details/89133504)

### JVMProfiler
https://github.com/uber-common/jvm-profiler

### InfluxDB
https://docs.influxdata.com/influxdb/v1.8/

### Grafana

### Spark应用程序启动
/opt/modules/influxdb1/influxdb.yaml
influxdb:
  host: 192.168.1.102
  port: 8086
  database: spark_metrics
  username: root
  password: 12345678


```shell
# Client + FileOutputReporter
spark-shell --master yarn \
--conf spark.ui.port=9111  \
--conf spark.driver.extraJavaOptions=-javaagent:/opt/modules/influxdb2/jvm-profiler-1.0.0.jar=reporter=com.uber.profiling.reporters.FileOutputReporter,metricInterval=5000,ioProfiling=true,tag=spark,outputDir=/opt/modules/influxdb2/metrics_files

# client
spark-shell --master yarn \
--conf spark.ui.port=9111  \
--conf spark.driver.extraJavaOptions=-javaagent:/opt/modules/jvm-profiler/jvm-profiler-1.0.0.jar=reporter=com.uber.profiling.reporters.InfluxDBOutputReporter,configProvider=com.uber.profiling.YamlConfigProvider,configFile=/opt/modules/influxdb1/influxdb.yaml \
--conf spark.executor.extraJavaOptions=-javaagent:/opt/modules/jvm-profiler/jvm-profiler-1.0.0.jar=reporter=com.uber.profiling.reporters.InfluxDBOutputReporter,configProvider=com.uber.profiling.YamlConfigProvider,configFile=/opt/modules/influxdb1/influxdb.yaml
```

## 使用SparkMetrics+Graphitle实现
更加细粒度监控Spark的

http://www.hammerlab.org/2015/02/27/monitoring-spark-with-graphite-and-grafana/

### SparkMetrics
[Spark Metrics配置详解](https://blog.csdn.net/qq_36330643/article/details/78754896)
[Spark Monitoring and Instrumentation](http://spark.apache.org/docs/2.4.4/monitoring.html)

### Graphite
https://blog.csdn.net/hffyyg/article/details/87900613

![alt](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Zeppelin/Zeppelin-02.png)  
