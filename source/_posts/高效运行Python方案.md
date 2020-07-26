---
title: 高效运行Python方案
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
  - xx技术/xx框架
keywords: xx技术
description: xxxx介绍
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Python/FastPython-cover.jpg
abbrlink: 2ed52290
date: 2020-07-26 11:16:00
---
# 高效运行Python  
&emsp;&emsp;Python以其简洁的语法，丰富的三方库，强大的功能而受到越来越多人的欢迎，但没有十全十美的编程语言，Python的运行效率一直被人们诟病。在一些场景下，我们希望Python也能够高效率运行，充分利用系统资源，所以这篇文章记录一些加快Python程序运行效率的方法，让我们的Python不再低效！

## 加速已有代码
&emsp;&emsp;这部分介绍的方案主要针对已有Python代码在不想做太大改动的情况下的优化方案。
### 使用numba加速  
**[numba官方网站](http://numba.pydata.org/)**

**优点：**
1. 无学习成本，只加一行代码（高级用法和调优除外）
2. 动态编译，直接翻译机器码，不走Python虚拟机，性能达到C语言水平
3. 支持GPU加速
4. 兼容常用的科学计算库

**局限：**
1. 我测试时有些场景会报WARN，需要调一下参数，也可能环境原因
2. 对部分第三方库有兼容性问题

**测试：**
```shell
pip install numba
```
![alt FastPython-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Python/FastPython-01.png)

**扩展：**
```python
from numba import jit
@jit  在方法前加装饰器-常用做法，object模式：默认nopython模式，但如果遇到不兼容的第三方库会退化成python模式，保证能运行但不能提速。
@jit(nopython=True,fastmath=True) 牺牲一点数学精度来提高速度（默认精度高）
@jit(nopython=True,parallel=True) 自动进行并行计算
```
![alt FastPython-02](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Python/FastPython-02.png)
原理：numba加速Python代码的原理是使用jit即时编译直接将Python代码翻译成机器码（上图左侧流程），避免了编译成Python字节码pyc再走Python虚拟机（上图右侧流程），直接提高了运行效率。

**结论：**
从上面的测试结果可以看到有将近300倍的效率提升，能大幅加速Python脚本的执行效率，对大量数据友好，对循环友好。我测试即使在低端处理器环境运行，也能有100+倍的性能提升。这个方案提速效果相当明显，而且对原有代码和环境改动很小，推荐哦！

### 使用modin加速pandas
**[modin官方网站](https://modin.readthedocs.io/en/latest/)**

**优点：**
1. 无学习成本，只改一行代码
2. 可以分布式跑，基于ray
3. 支持GPU加速

**局限性：**
1. 目前支持[93%的Pandas API](https://modin.readthedocs.io/en/latest/supported_apis/dataframe_supported.html)
2. 分布式运行功能为为实验性功能
3. 随着运行核心数增加，会占用更多内存
4. 安装时可能会更改原有pandas版本，需留意
5. 需要安装[ray](https://github.com/ray-project/ray)或[dask](https://dask.org/)依赖包，还有一些其他依赖包

**测试：**

```python
def pandas_test():
    import pandas as pd
    from time import time
    df = pd.DataFrame(zip(range(1000000),range(1000000,2000000)),columns=['a','b'])
    start = time()
    df['c'] = df.apply(lambda x: x.a+x.b ,axis=1)
    df['d'] = df.apply(lambda x: 1 if x.a%2==0 else 0, axis=1)
    print('pandas_df.apply Time: {:5.2f}s'.format(time() - start))
    start = time()
    group_df = df[['d','a']].groupby('d',as_index=False).agg({"a":['sum','max','min','mean']})
    print('pandas_df.groupby Time: {:5.2f}s'.format(time() - start))
    # start = time()
    # data = pd.read_csv('test_modin.csv')
    # print('pandas_df.read_csv Time: {:5.2f}s'.format(time() - start))


def modin_pandas_test():
    import modin.pandas as pd
    from time import time
    df = pd.DataFrame(zip(range(1000000),range(1000000,2000000)),columns=['a','b'])
    start = time()
    df['c'] = df.apply(lambda x:x.a+x.b ,axis=1)
    df['d'] = df.apply(lambda x:1 if x.a%2==0 else 0, axis=1)
    print('modin_pandas_df.apply Time: {:5.2f}s'.format(time() - start))
    start = time()
    group_df = df[['d','a']].groupby('d',as_index=False).agg({"a":['sum','max','min','mean']})
    print('modin_pandas_df.groupby Time: {:5.2f}s'.format(time() - start))
    # start = time()
    # data = pd.read_csv('test_modin.csv')
    # print('modin_pandas_df.read_csv Time: {:5.2f}s'.format(time() - start))


if __name__ == '__main__':
    pandas_test()
    modin_pandas_test()
```
![alt FastPython-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Python/FastPython-03.jpg)
![alt FastPython-04](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Python/FastPython-04.jpg)
单机跑Apply API速度大概快了3.5倍多。分布式还没测试。

**结论：**
使用modin模块的pandas代替普通的pandas，本质是将单机单核跑的任务负载分散到多核心甚至多机器来加速运算。基本可以满足使用pandas的业务需求场景，而且核心数越多，机器数越多，运行效率提升越高，但相应需要更大的内存。适合对大量数据操作的场景。
此外，pandas官网给出了一些优化效率的建议，参考：[Enhancing performance](https://pandas.pydata.org/pandas-docs/stable/user_guide/enhancingperf.html)

## 编写高效代码
&emsp;&emsp;除了上面已经提到的方案，在我们平时编码时也要注意编码效率，这部分主要介绍编写Python代码时一些提高运行效率的方法、技巧和工具。

### 使用PySpark
**优点：**
1. 使用Pyspark的dataframe进行数据操作数据分析简单高效，有较低的学习成本。
2. 只需要一行代码即可实现pyspark dataframe和pandas dataframe互相转换。
3. Pyspark dataframe可以直接registerTempTable，然后可以很容易地使用pyspark.sql对这个表做sql分析。
4. 分布式运行，分析效率效率高，对大量数据很友好。
5. 功能强大，支持udf。

**局限：**
1. 写代码要注意，避免小文件，减少driverResultSet（注意尽量避免让driver单点运算全部数据）
2. 需要更多内存做计算

**使用：**

```python
# 例如以前的pandas分析作业，可以移植到pyspark
# ①pandas dataframe转pyspark dataframe：
df = spark.createDataFrame(pandas_dataframe)
# ②pyspark dataframe转pandas dataframe:
pandas_dataframe = spark_dataframe.toPandas()
# ③代码中将spark dataframe注册成临时表（随sparkSession销毁，不占空间）
df.registerTempTable(‘tmp’)
# ④对数据做SQL分析
df = spark.sql(“””select * from tmp limit 10”””)  结果为新的dataframe
# ⑤结果输出
df.show() / df.writeInsertInto(table_name) / df.write.option(‘header’,True),csv(file) 
# …… 很多种输出方式，也可以继续转回pandas dataframe做后续操作
```
[PySpark使用文档](http://spark.apache.org/docs/2.4.4/api/python/index.html)

**结论：**
在数据量特别大的情况下，分布式计算是首选，所以对于大规模数据分析，目前PySpark是比较推荐的方式。

### 使用多线程


### 使用Cython

**优点：**
1.	Python代码可通过[一定工具转Cython代码](https://github.com/ArvinMei/py2so)
2.	性能达到C语言水平

**局限：**
1.	需要修改转换工具
2.	高级用法学习成本高

**使用：**
学习Cython：[cython-book](https://github.com/philberty/cython-book)
```shell
pip install cython
```
