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
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/Kafka/Kafka-Cover.jpg
abbrlink: s02c711a
date: 2020-11-19 10:50:00
---
# Antlr介绍  
ANTLR全称Another Tool for Language Recognition。Antlr是用Java语言开发的,它提供了一个通过语法描述来自动构造自定义语言的识别器（recognizer），编译器（parser）和解释器（translator）的框架，它被广泛的使用在编译语言，工具和框架中，很多开源项目使用Antlr作为代码解析工具，如Hive、Spark、Presto。





[ANTLR官方网址](http://www.antlr.org/)

[ANTLR 官方 Github](https://github.com/antlr/antlr4)





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
alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.5-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
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

### 使用Antlr4解析SQL  



## 原理（中标题） 

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
[Kafka史上最详细原理总结](https://blog.csdn.net/u013573133/article/details/48142677)
[Apache Kafka](http://kafka.apache.org/)

