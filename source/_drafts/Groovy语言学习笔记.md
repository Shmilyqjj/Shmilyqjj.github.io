---
title: Groovy语言学习笔记
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
  - Phoenix
keywords: Phoenix
description: 基于HBase的SQL查询引擎
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/BlogImages-0@master/cdn_sources/Blog_Images/Groovy/Groovy-cover.jpg
date: 2021-08-18 11:26:08
---

# Groovy语言学习笔记  


## Groovy简介
Groovy是用于Java虚拟机的一种敏捷的动态语言，它是一种成熟的面向对象编程语言，既可以用于面向对象编程，又可以用作纯粹的脚本语言。使用该种语言不必编写过多的代码，同时又具有闭包和动态语言中的其他特性。
Groovy是JVM的一个替代语言（替代是指可以用 Groovy 在Java平台上进行 Java 编程），使用方式基本与使用 Java代码的方式相同，该语言特别适合与Spring的动态语言支持一起使用，设计时充分考虑了Java集成，这使 Groovy 与 Java 代码的互操作很容易。（注意：不是指Groovy替代java，而是指Groovy和java很好的结合编程。


## Groovy特点
1、构建在强大的Java语言之上 并 添加了从Python，Ruby和Smalltalk等语言中学到的 诸多特征，例如动态类型转换、闭包和元编程（metaprogramming）支持。

2、为Java开发者提供了 现代最流行的编程语言特性，而且学习成本很低（几乎为零）。

3、支持DSL（Domain Specific Languages领域定义语言）和其它简洁的语法，让代码变得易于阅读和维护。

4、受检查类型异常(Checked Exception)也可以不用捕获。

5、Groovy拥有处理原生类型，面向对象以及一个Ant DSL，使得创建Shell Scripts变得非常简单。

6、在开发Web，GUI，数据库或控制台程序时 通过 减少框架性代码 大大提高了开发者的效率。

7、支持单元测试和模拟（对象），可以 简化测试。

8、无缝集成 所有已经存在的 Java对象和类库。

9、直接编译成Java字节码，这样可以在任何使用Java的地方 使用Groovy。

10、支持函数式编程，不需要main函数。

11、一些新的运算符。

12、默认导入常用的包。

13、断言不支持jvm的-ea参数进行开关。

14、支持对对象进行布尔求值。

15、类不支持default作用域，且默认作用域为public。

16、groovy中基本类型也是对象，可以直接调用对象的方法。 

类
Groovy类和java类一样，完全可以用标准java bean的语法定义一个Groovy类。但作为另一种语言，可以使用更Groovy的方式定义类，这样的好处是，可以少写一半以上的javabean代码。

（1）不需public修饰符

如前面所言，Groovy的默认访问修饰符就是public，如果Groovy类成员需要public修饰，则根本不用写它。

（2）不需要类型说明

同样前面也说过，Groovy也不关心变量和方法参数的具体类型。

（3）不需要getter/setter方法

在很多ide（如eclipse）早就可以为程序员自动产生getter/setter方法了，在Groovy中，不需要getter/setter方法--所有类成员（如果是默认的public）根本不用通过getter/setter方法引用它们（当然，如果一定要通过getter/setter方法访问成员属性，Groovy也提供了它们）。

（4）不需要构造函数

不再需要程序员声明任何构造函数，因为实际上只需要两个构造函数（1个不带参数的默认构造函数，1个只带一个map参数的构造函数--由于是map类型，通过这个参数可以构造对象时任意初始化它的成员变量）。

（5）不需要return

Groovy中，方法不需要return来返回值。

（6）不需要（）

Groovy中方法调用可以省略（）（构造函数除外）。

总结特点：动态类型、支持闭包、Groovy和Java语言的主要区别是：完成同样的任务所需的Groovy代码比Java代码更少

## Groovy基本语法
### 关键字
as	assert	break	case
catch	class	const	continue
def	default	do	else
enum	extends	false	Finally
for	goto	if	implements
import	in	instanceof	interface
new	pull	package	return
super	switch	this	throw
throws	trait	true	try while

### 数据类型
Groovy提供多种内置数据类型。以下是在Groovy中定义的数据类型的列表：
byte -这是用来表示字节值。例如2。
short -这是用来表示一个短整型。例如10。
int -这是用来表示整数。例如1234。
long -这是用来表示一个长整型。例如10000090。
float -这是用来表示32位浮点数。例如12.34。
double -这是用来表示64位浮点数，这些数字是有时可能需要的更长的十进制数表示。例如12.3456565。
char -这定义了单个字符文字。例如“A”。
Boolean -这表示一个布尔值，可以是true或false。
String -这些是以字符串的形式表示的文本。

数字类：
类型除了基本类型，还允许以下对象类型（有时称为包装器类型）：
java.lang.Byte
java.lang.Short
java.lang.Integer
java.lang.Long
java.lang.Float
java.lang.Double

此外，以下类可用于支持高精度计算：
java.math.BigInteger	不可变的任意精度的有符号整数数字
java.math.BigDecimal	不可变的任意精度的有符号十进制数

### 变量定义
```groovy
  // init objects
  def xml = new MarkupBuilder()
  // define variables
  def student_name
  String x = "QJJ"
  def _Name = "qjj"
  int X = 6
```

### 运算符
算术运算符 + - * / % ++ --
关系运算符 == != < <= > >=
逻辑运算符 && || !
位运算符 & | ^ ~
赋值运算符 += -= *= /= (%)=
范围运算符 def range = 0..5 range.get(2)可以获取范围内一个对象

### 循环
```groovy
 // while
  int count = 0
  while(count<5) {
    count++;
  }
  //for
  for(int i = 0;i < 5; i++) {
    if(i == 2){
      continue
    }
    if(1){
      break
    }
  }
  //for in
  int[] array = [0,1,2,3];
  for(int i in array) {
    println(i);
  } 
  //for in map
  def map = ["a":1,"b":2,"c":3]
  for(j in map) {
      println(j)
  }
```

### 条件
```groovy
// if else
if(i==0){
  println(0)
}else if(i==1){
  println(1)
}else{
  println(i)
}
// switch
switch(expression) { 
   case expression #1: 
   statement #1 
   ... 
   case expression #2: 
   statement #2 
   ... 
   case expression #N: 
   statement #N 
   ... 
   default:
   statement #Default 
   ... 
} 
```

### 方法
```groovy
def method(){  //最简单的方法定义

}
static int sum(int a, int b){  //带返回值
  return a+b
}
static void sum(int a, int b=1){  //默认参数
  println(a+b) 
}
```

### 文件IO


## 原理（中标题） 

