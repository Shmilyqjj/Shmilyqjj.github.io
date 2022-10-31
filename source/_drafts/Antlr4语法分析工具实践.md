---
title: Antlr4语法分析工具实践
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
  - 编译原理
  - 语法分析
  - SQLParser
keywords: Kafka
description: Antlr4语法分析工具实践
photos: >-
  https://blog-images-1257889704.cos.ap-chengdu.myqcloud.com/BlogImages/Kafka/Kafka-Cover.jpg
abbrlink: s02c711a
date: 2020-11-19 10:50:00
---
# Antlr介绍  
ANTLR全称Another Tool for Language Recognition。Antlr是用Java语言开发的,它提供了一个通过语法描述来自动构造自定义语言的识别器（recognizer），编译器（parser）和解释器（translator）的框架，它被广泛的使用在编译语言，工具和框架中，很多开源项目使用Antlr作为代码解析工具，如Hive、Spark、Presto。



【Antlr4 入门】https://www.cnblogs.com/clonen/p/9083359.html


[ANTLR 实战 SQL 词法/语法分析]https://www.it610.com/article/1289186466957697024.htm

[antlr4 使用原理](https://zhmin.github.io/2019/04/26/antlr4-tutorial/)

[ANTLR官方网址](http://www.antlr.org/)

[ANTLR 官方 Github](https://github.com/antlr/antlr4)

[java词法分析_Presto SQL Parser源码分析](https://blog.csdn.net/weixin_39637203/article/details/110724221)


[IDEA配置antlr4环境和使用](https://blog.csdn.net/qq_36616602/article/details/85858133)
[在IDEA中使用ANTLR4教程](https://blog.csdn.net/sherrywong1220/article/details/53697737)



## 相关知识储备
Antlr 使用上下文无关文法描述语言, 它允许我们定义识别字符流的词法规则和用于解释Token流的语法分析规则。然后，ANTLR将根据用户提供的语法文件自动生成相应的词法/语法分析器。用户可以利用他们将输入的文本进行编译，并转换成其他形式.



Interpreter：解释执行
Translator：翻译程序，由一种语言翻译为另一种语言
Parser / syntax analyzers:根据语法等识别程序
Syntax:句法
Grammar:语法
Separate stages 分割语句
根据单词读入语句，然后和字典中的单词做对比。
Lexical analysis / simply tokenizing ：分词
Lexer:词法分析程序

## Antlr实践
[大量语法文件例子](https://github.com/antlr/grammars-v4)

### Antlr4环境配置
Linux端配置环境
```
mkdir -p /opt/modules/antlr4
cd /opt/modules/antlr4
wget https://www.antlr.org/download/antlr-4.7-complete.jar
vim /etc/profile
CLASSPATH=$CLASSPATH:/opt/modules/antlr4/antlr-4.7-complete.jar
alias antlr4='java -Xmx500M -cp "/opt/modules/antlr4/antlr-4.7-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
alias grun='java org.antlr.v4.runtime.misc.TestRig'
source /etc/profile
```
Windows端配置环境
```
创建目录%ANTLR_HOME%进入
下载https://www.antlr.org/download/antlr-4.7-complete.jar
目录下创建antlr4.bat 内容：java org.antlr.v4.Tool %*
目录下创建grun.bat 内容：java org.antlr.v4.gui.TestRig %*
CLASSPATH添加;%ANTLR_HOME%\antlr-4.7-complete.jar
PATH添加%ANTLR_HOME%
```
IDEA配置：Plugins中下载ANTLR v4 grammar plugin
注：为什么下载4.7版本而不是用4.8+ 因为目前的现有语法本都是基于4.8前的版本，4.8版本对语法本写法做了改动，已有开源的语法本不能正常使用。
### 使用Antlr4解析SQL  





## 参考资料  


