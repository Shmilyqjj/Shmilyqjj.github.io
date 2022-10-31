---
title: 使用Koalas优化Pandas大数据分析场景
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
  - 数据分析
keywords: Koalas Pandas
description: 零学习成本加速Pandas大数据分析
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Spark/Koalas/Koalas-cover.png
date: 2020-09-08 20:05:00
---
# Koalas
&emsp;&emsp;"Koalas: pandas API on Apache Spark"这是**[Koalas官网](https://koalas.readthedocs.io/en/latest/)**上的第一句话，意思很明确，Koalas是构建在Spark之上的PandasAPI，通过Koalas我们可以使用Pandas的API并利用Spark做底层计算。当易用的PandasAPI遇见大数据友好的Spark，你是否更想了解Koalas了呢？这篇文章来记录一些Koalas相关原理，安装和使用等...

## Koalas介绍
&emsp;&emsp;首先，Pandas 不能很好地在大数据规模中应用，因为它专为单个机器可以处理的小型数据集而设计，另一方面，Apache Spark 已成为大数据处理的佼佼者。而由Spark的老东家Databricks开发的Koalas结合了以上两者的优点，可以让数据科学家在大数据分析场景下继续使用PandasAPI，而其底层计算引擎完全替换为了Spark分布式计算，可以让数据科学家在无学习成本的情况下轻松应对大数据分析场景，并且提高分析任务的执行效率和资源利用率。

## 安装
安装前请查看版本依赖关系：[Dependencies](https://koalas.readthedocs.io/en/latest/getting_started/install.html#dependencies)
```shell
pip install koalas -i https://pypi.douban.com/simple/
```
![alt Koalas-01](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Spark/Koalas/Koalas-01.png)   
Lastly, if your PyArrow version is 0.15+ and your PySpark version is lower than 3.0, it is best for you to set ARROW_PRE_0_15_IPC_FORMAT environment variable to 1 manually.
![alt Koalas-02](https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Spark/Koalas/Koalas-02.jpg)   

## 使用Koalas
导入Koalas，Pandas和PySpark，三者可结合使用，所以将三者同时导入
```python
import pandas as pd
import numpy as np
import databricks.koalas as ks
from pyspark.sql import SparkSession
```

### 使用
```python
import databricks.koalas as ks
import pandas as pd
# 将创建pandas df
pdf = pd.DataFrame({'x':range(3), 'y':['a','b','b'], 'z':['a','b','b']})
# 将Pandas df转为Koalas df
df = ks.from_pandas(pdf)
# 与使用PandasAPI相同的方法使用Koalas df
df.columns = ['x', 'y', 'z1']
df['x2'] = df.x * df.x
...
# 与PySpark df相互转换
sdf = df.to_spark()
df = sdf.to_koalas()
```
在将pandas的dataframe转换为kolas的dataframe时，会触发初始化SparkSession的操作，会初始化Spark对象，后续在Koalas df上的操作底层都会在Spark计算。
因为可能会有Koalas与PySpark混合使用的场景，避免重复创建SparkSession，可以通过**spark = SparkSession.builder.getOrCreate()**来获取当前已创建的Spark对象。

```python
# 创建Series
s = ks.Series([1, 3, 5, np.nan, 6, 8])  
# 创建dataframe
kdf = ks.DataFrame(
    {'a': [1, 2, 3, 4, 5, 6],
     'b': [100, 200, 300, 400, 500, 600],
     'c': ["one", "two", "three", "four", "five", "six"]},
    index=[10, 20, 30, 40, 50, 60])
# 创建Koalas df
kdf = ks.from_pandas(pd.DataFrame(np.random.randn(6, 4), index=dates, columns=list('ABCD')))
# 数据查看
kdf.head(3)
kdf.dtypes
kdf.index 
kdf.columns
# 转为np数组
kdf.to_numpy()
# 行列转换
kdf.T
#  按索引排序
kdf.sort_index(ascending=False)
# 按值排序
kdf.sort_values(by='B')
# 缺失值处理

```


## 小结  


## 参考 
[Koalas Github](https://github.com/databricks/koalas)
[Koalas HomePage](https://koalas.readthedocs.io/en/latest/)