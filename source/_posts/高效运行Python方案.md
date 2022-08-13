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
  - Python
keywords: Python效率
description: 提高Python运行效率的方案集锦
photos: >-
  http://imgs.shmily-qjj.top/BlogImages/Python/FastPython-cover.jpg
abbrlink: 2ed52290
date: 2020-07-26 11:16:00
---
# 高效运行Python  
&emsp;&emsp;Python以其简洁的语法，丰富的三方库，强大的功能而受到越来越多人的欢迎，但没有十全十美的编程语言，Python的运行效率一直被人们诟病。在一些场景下，我们希望Python也能够高效率运行，充分利用系统资源，所以这篇文章记录一些加快Python程序运行效率的方法，让我们的Python更高效！

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
![alt FastPython-01](http://imgs.shmily-qjj.top/BlogImages/Python/FastPython-01.png)

**扩展：**
```python
from numba import jit
@jit  在方法前加装饰器-常用做法，object模式：默认nopython模式，但如果遇到不兼容的第三方库会退化成python模式，保证能运行但不能提速。
@jit(nopython=True,fastmath=True) 牺牲一点数学精度来提高速度（默认精度高）
@jit(nopython=True,parallel=True) 自动进行并行计算
```
![alt FastPython-02](http://imgs.shmily-qjj.top/BlogImages/Python/FastPython-02.png)
原理：numba加速Python代码的原理是使用jit即时编译直接将Python代码翻译成机器码（上图左侧流程），避免了编译成Python字节码pyc再走Python虚拟机（上图右侧流程），直接提高了运行效率。

**结论：**
从上面的测试结果可以看到有将近300倍的效率提升，能大幅加速Python脚本的执行效率，对大量数据友好，对循环友好。我测试即使在低端处理器环境运行，也能有100+倍的性能提升。这个方案提速效果相当明显，而且对原有代码和环境改动很小，推荐哦！

### 使用modin加速pandas
**[modin官方网站](https://modin.readthedocs.io/en/latest/)**
pandas是很常用的数据分析库，功能强大，但它有个缺点就是对大数据的支持并不好，不适合大规模数据。
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
![alt FastPython-03](http://imgs.shmily-qjj.top/BlogImages/Python/FastPython-03.jpg)
![alt FastPython-04](http://imgs.shmily-qjj.top/BlogImages/Python/FastPython-04.jpg)
单机跑Apply API速度大概快了3.5倍多。分布式还没测试。

**结论：**
使用modin模块的pandas代替普通的pandas，本质是将单机单核跑的任务负载分散到多核心甚至多机器来加速运算。基本可以满足使用pandas的业务需求场景，而且核心数越多，机器数越多，运行效率提升越高，但相应需要更大的内存。适合对大量数据操作的场景。
此外，pandas官网给出了一些优化效率的建议，参考：[Enhancing performance](https://pandas.pydata.org/pandas-docs/stable/user_guide/enhancingperf.html)

### 使用pandarallel加速pandas
**[pandarallel官方网站](https://github.com/nalepae/pandarallel)**
**优点：**
1. 无学习成本，只添加1-2行代码
2. 充分利用CPU

**局限性：**
1. 理论上只提速物理核心数倍的效率。
2. 有使用成本（实现新进程，通过共享内存发送数据等等），因此只有计算量足够高时，才更有效。

**使用：**[pandarallel-example](https://github.com/nalepae/pandarallel/blob/master/docs/examples.ipynb)

**结论：**
对于非常少量的数据，不值得使用。对大量数据，可以尝试该方案，不会像modin一样依赖pandas版本，可以在原有pandas版本上操作。

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
**[PySpark使用文档](http://spark.apache.org/docs/2.4.4/api/python/index.html)**

**结论：**
在数据量特别大的情况下，分布式计算是首选，所以对于大规模数据分析，目前PySpark是比较推荐的方式。

### 使用Dask
**[Dask官方网站](https://dask.org/)**
**优点：**
1. 高效处理大量数据
2. 支持分布式
**局限：**
1. 只有来自pandas的某些功能才能移植到Dask上执行
2. 仅在不适合主存储器的数据集上，才建议使用Dask

**示例：**

```python
# 低速：
import numpy as np
import pandas as pd
df = pd.Dataframe(np.random.randint(0, 6, size=(100000000, 5)), columns = list('abcde')
df.groupby('a').mean()

# 高速：
import dask.dataframe as dd
df_dask = dd.from_pandas(df, npartitions=50)
df_dask.groupby('a').mean().compute()
```

**[详细了解Dask](https://blog.csdn.net/jack_jmsking/article/details/91433854)**

### 使用多线程
**优点：**能提高IO密集型Python程序效率。因为在一个线程因IO阻塞等待时，CPU切换到其他线程，CPU利用率高。
**局限：**由于GIL(Global Interpreter Lock)机制限制Python解释器任何时刻都只能执行一个线程，在计算密集型Python程序并不能提高执行效率，反而可能因线程切换降低效率。
**使用：**

```python
# 用法1
import threading
import time


class myThread(threading.Thread):
    def __init__(self,threadID,name,counter):
        threading.Thread.__init__(self)
        self.threadId = threadID
        self.name = name
        self.counter = counter


    def run(self):
        # 线程创建执行run函数
        while self.counter < 8:
            time.sleep(2)
            self.counter += 1
            print(self.threadId,self.name,self.counter,time.ctime(time.time()))
        print("Thread Stop")


thread1 = myThread(1, "Thread-1", 1)
thread2 = myThread(2, "Thread-2", 2)
thread1.start()
thread2.start()


# 用法2
import threading
from queue import Queue
import time
def testThread(num):
	print(num)

if __name__ == '__main__':
	for i in range(5):
		t = threading.Thread(target=testThread, arg=(i, ))
		t.start()
```

**GIL：**GIL是CPython解释器引入的锁，GIL在解释器层面阻止了真正的并行运行。解释器在执行任何线程之前，必须等待当前正在运行的线程释放GIL，事实上，解释器会强迫想要运行的线程必须拿到GIL才能访问解释器的任何资源，例如栈或Python对象等，这也正是GIL的目的，为了阻止不同的线程并发访问Python对象。这样GIL可以保护解释器的内存，让垃圾回收工作正常，不会出现运行死锁。但事实上，这却造成了程序员无法通过并行执行多线程来提高程序的性能。如果我们去掉GIL，就可以实现真正的并行。GIL并没有影响多处理器并行的线程，只是限制了一个解释器只能有一个线程在运行。
**结论：**IO包括磁盘IO和网络IO，所以可以在磁盘IO密集型Python任务或网络延迟是瓶颈的Python任务中使用Python多线程。

### 使用多进程
**优点：**可以提高计算密集型Python程序执行效率。会用到多个CPU核心。绕过GIL机制，充分利用CPU。核心原理是以子进程的形式，平行的运行多个python解释器，从而令python程序可以利用多核CPU来提升执行速度。由于子进程与主解释器相分离，所以他们的全局解释器锁也是相互独立的。每个子进程都能够完整使用一个CPU内核。

**局限：**
1. 进程间进行数据的交互会产生额外的I/O开销。
2. 整个内存空间被复制到每个子进程中，这样对于比较复杂的程序造成的额外开销也很大。

**使用：**

```python
# 用法1
import multiprocessing


def method(num):
    print(num)


if __name__ == '__main__':
    for i in range(100):
        p = multiprocessing.Process(target=method, args=(i,))
        p.start()


# 用法2
from multiprocessing.pool import ThreadPool
# 可以提供指定数量的进程供用户调用，当有新的请求提交到Pool中时，如果池还没有满，就会创建一个新的进程来执行请求。
# 如果池满，请求就会告知先等待，直到池中有进程结束，才会创建新的进程来执行这些请求。

def my_print(item):
    print(item[0]+item[1])


pool_size = 10  # 进程池大小
items = [(1,2),(2,3),(3,4),(4,5)]

pool = ThreadPool(pool_size)  # 创建一个进程池
pool.map(my_print, items)  # 往进程池中填进程
pool.close()  # 关闭进程池，不再接受进程
pool.join()  # 等待子进程结束以后再继续往下运行，通常用于进程间的同步 等待进程池中进程全部执行完


# 共享内存-共享变量
import multiprocessing
from ctypes import c_char_p
import time
int_val = multiprocessing.Value('i', 0)   # int类型共享变量
s = (c_char_p, 'str')  # str类型共享变量


def method(num):
    for i in range(10):
        time.sleep(0.1)
        with int_val.get_lock():  # 仍然需要使用 get_lock 方法来获取锁对象
            int_val.value += num
        print(int_val.value)


if __name__ == '__main__':
    for i in range(100):
        p = multiprocessing.Process(target=method, args=(i,))
        p.start()
```
**结论：**如果Python程序瓶颈在CPU数量或是CPU密集型，都可采用多进程。

### 使用Cython

**优点：**
1. Python代码可通过[一定工具转Cython代码](https://github.com/ArvinMei/py2so)
2. 性能达到C语言水平

**局限：**
1. 需要修改转换工具
2. 高级用法学习成本高

**使用：**
学习Cython：[cython-book](https://github.com/philberty/cython-book)
```shell
pip install cython
```

### 使用concurrent.futures
**介绍：**对threading和multiprocessing进一步封装的包，方便实现线程池和进程池。
**使用：**

```python
# 线程池
import time
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, Executor

start = time.time()
pool = ThreadPoolExecutor(max_workers=2)
results = list(pool.map(gcd, numbers))
end = time.time()
print 'Took %.3f seconds.' % (end - start)

# 进程池
import time
from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, Executor

start = time.time()
pool = ProcessPoolExecutor(max_workers=2)
results = list(pool.map(gcd, numbers))
end = time.time()
print 'Took %.3f seconds.' % (end - start)
```
**扩展：**

```text
在两个CPU核心的机器上运行多进程程序，比其他两个版本都快。
这是因为，ProcessPoolExecutor类会利用multiprocessing模块所提供的底层机制，完成下列操作：
1. 把numbers列表中的每一项输入数据都传给map。
2. 用pickle模块对数据进行序列化，将其变成二进制形式。
3. 通过本地套接字，将序列化之后的数据从煮解释器所在的进程，发送到子解释器所在的进程。
4. 在子进程中，用pickle对二进制数据进行反序列化，将其还原成python对象。
5. 引入包含gcd函数的python模块。
6. 各个子进程并行的对各自的输入数据进行计算。
7. 对运行的结果进行序列化操作，将其转变成字节。
8. 将这些字节通过socket复制到主进程之中。
9. 主进程对这些字节执行反序列化操作，将其还原成python对象
10.最后，把每个子进程所求出的计算结果合并到一份列表之中，并返回给调用者。
multiprocessing开销比较大，原因就在于：主进程和子进程之间通信，必须进行序列化和反序列化的操作。
```
详细参考：**[python concurrent.futures](https://www.cnblogs.com/kangoroo/p/7628092.html)**

### 常见代码优化
1. 在set中查找比在list查找快
```python
list_data = list(data)
set_data = set(data)
# 低速：
789 in list_data
# 高速：
789 in set_data
```

2. 用dict而非两个list进行匹配查找
```python
# 已知list_a,list_b
# 低速：
list_b[list_a.index(123)]
# 高速：
dict(zip(list_a,list_b)).get(123,None)
```

3. 优先用for循环，比while略快
4. 在循环体中避免重复计算

5. 用循环机制代替递归函数  
```python
# 低速：
def fib():
    return (1 if n in (1,2) else fib(n-1)+fib(n-2))
# 高速：
def fib(n):
    if n in (1,2):
        return 1
    a, b = 1, 1
    for i in range(2,n):
        a,b = b, a+b
    return b
```

6. 使用缓存机制加速递归函数
```python
# 低速：
def fib():
    return (1 if n in (1,2) else fib(n-1)+fib(n-2))
# 高速：
from functools import lru_cache
@lru_cache(100)
def fib():
    return (1 if n in (1,2) else fib(n-1)+fib(n-2))
```

7. 使用collections.Counter加速计数
```python
import time
data = [x**2 % 1989 for x in range(2000000)]
# 低速
st = time.time()
values_count = {}
for i in data:
    i_cnt = values_count.get(i, 0)
    values_count[i] = i_cnt + 1
print(values_count.get(4, 0))
print("time: %s" % (time.time() - st))
# 高速
st = time.time()
from collections import Counter
values_count = Counter(data)
print(values_count.get(4, 0))
print("time: %s" % (time.time() - st))
```

8. 使用collections.ChainMap加速字典合并
```python
# 低速
dict_a = {i: i + 1 for i in range(1, 1000000, 2)}
dict_b = {i: i * 2 + 1 for i in range(1, 1000000, 3)}
dict_c = {i: i * 3 + 1 for i in range(1, 1000000, 5)}
dict_d = {i: i * 4 + 1 for i in range(1, 1000000, 7)}
result = dict_a.copy()
result.update(dict_b)
result.update(dict_c)
result.update(dict_d)
print(result.get(9999))
# 高速
from collections import ChainMap
chain = ChainMap(dict_a, dict_b, dict_c, dict_d)
print(chain.get(9999))
```

9. 使用map代替推导式进行加速
```python
a = [x**2 for x in range(1, 1000000, 3)]  # 低速
a = map(lambda x: x**2, range(1, 1000000, 3)) # 高速
```

10. 使用filter代替推导式进行加速
```python
a = [x for x in range(1, 1000000, 3) if x % 7 == 0]  # 低速
a = filter(lambda x: x % 7 == 0, range(1, 1000000, 3)) # 高速
```

11. numpy向量化加速-使用np.array代替list集合
```python
a = range(1, 1000000, 3)
b = range(1, 1000000, -3)
c = [3 * a[i] - 2 * b[i] for i in range(0, len(a)] # 低速
import numpy as np
array_a = np.arange(1, 1000000, 3)
array_b = np.arange(1, 1000000, -3)
array_c = 3 * array_a - 2 * array_b # 高速
```

12. 使用np.ufunc代替math.func
```python
# 低速
import math 
a = range(1, 1000000, 3)
b = [math.log(x) for x in a]
# 高速
import numpy as np
array_a = np.arange(1, 1000000, 3)
array_b = np.log(array_a)
```

13. pandas df.to_excel效率低于df.to_csv

## 查看Python性能日志
### 使用profiler
python中的profiler可以帮助我们测量程序执行过程中详细的时间和空间复杂度。使用时通过-o参数传入可选输出文件以保留性能日志。

```shell
python -m cProfile [-o output_file] my_python_file.py
```
![alt FastPython-05](http://imgs.shmily-qjj.top/BlogImages/Python/FastPython-05.JPG)

### 使用profile
导入profile监控python程序整体执行耗时。

```python
import profile
profile.run('main()')
```

### 使用line_profiler
监控方法耗时。
```python
# pip install line_profiler
def a():
    pass
def main():
    a()
from line_profiler import LineProfiler
lp = LineProfiler(a,main)
lp.run('main()')
lp.print_stats()
```

### 在ipython中获取代码耗时
```ipython
%time code  获取执行code这一行代码的耗时
%%time 获取耗时
%%timeit -n 10  获取执行10次的平均耗时
%prun method()  获取执行method方法的耗时详情，输出与profiler一样
```



