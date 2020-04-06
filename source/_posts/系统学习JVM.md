---
title: 系统学习JVM
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
  - Java
keywords: JVM
description: 系统学习一下JVM，很重要
photos: >-
  https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-cover.jpg
abbrlink: 508b5c7
date: 2020-03-21 12:19:00
---
# 系统学习JVM  
Java跨平台，一次编译到处运行，垃圾回收等特性离不开JVM，学习JVM的原理可以让我们在工作中更快速定位问题。写这篇的目的就是避免零零散散地学习JVM，那样效率很低，也方便以后回顾和复习。

## 字节码
学习之前先要学会简单分析字节码。
用户Java代码与JVM交互沟通的桥梁。代码编译为.class字节码给JVM运行。
```bash
 $ javac Hello.java
 $ javap -c Hello.class  # javap可查看字节码的操作数
```
JVM的程序运行是在栈上完成的，运行main方法自动分配一个栈帧，退出方法体时候再弹出相应栈帧。从javap得到的结果看，大多数字节码指令是不断操作栈帧。
整个过程：**Java 文件->编译器->字节码->JVM->机器码**
整个过程：**Hello.java -> Hello.class -> Java类加载器(JVM中) -> 执行引擎(JVM中) -> 通过操作系统接口解释执行+JIT**

## JVM
### 定义
JVM（JAVA虚拟机）是一个规范，定义了.class文件的结构，加载机制，数据存储，运行时栈等内容。
JDK8以后Java是编译与解释混合执行模式。
JDK8以后JVM的技术实现是HotSpot(包含一个解释器和两个编译器)。
两个编译器：可以动态编译，含server模式和client模式。
    client模式是一种轻量级编译器，也叫C1编译器，占用内存小，启动快，但是执行效率没有server模式高，默认状态下不进行动态编译，适用于桌面应用程序。
    server模式是一种重量级编译器，也叫C2编译器，启动慢，占用内存大，执行效率高，默认是开启动态编译的，适合服务器应用。
```text
 -XX:RewriteFrequentPairs   用于开启动态编译。
 -Xint:禁用JIT编译，UYZNGSUYZNGS即禁用两个编译器，纯解释执行。
 -Xcomp:纯编译执行，如果方法无法编译，则回退到解释执行模式解释无法编译的代码。
```

### 内存管理
* JVM内存区域如何划分？
![alt JVM-01](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-01.png)  
Java内存布局一直在调整，Java8开始彻底移除了持久代，使用MetaSpace(元空间)来代替。 => -XX:PermSize和-XX:MaxPermSize失效

Java的运行时数据区可以分成**堆、元空间(含方法区)、虚拟机栈、本地方法栈和程序计数器**

* 堆：存放绝大多数Java对象，是JVM中最大的一块内存，随着频繁创建对象，堆空间占用越来越大，需要不定期的GC。（JVM主要GC区域：堆和元空间）。是线程共享的。
   **对象是否被分配在堆中取决于对象的基本类型和Java类中存在的位置**：
    + 基本数据类型（byte,short,int,long,float,double,char）如果在方法体内声明则在栈上(栈帧的局部变量表)直接分配，其他情况在堆上分配。
    + int[]这样的数组类型不属于基本数据类型，在堆上分配。
* 栈：分虚拟机栈和本地方法栈。
    ![alt JVM-02](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-02.png)  
    + 虚拟机栈：Java中**每个方法被调用时都会创建一个栈帧，执行完后再出栈，所有栈帧都出栈后线程结束**。每一个方法对应一个栈帧，每一个线程对应一个栈。栈帧中包括：**局部变量表，操作数，动态链接，返回地址**，这些不是线程共享的。
    + 本地方法栈：与虚拟机栈相似，但它主要包含Native对象。本地方法栈有一个叫returnAddress的数据类型。
* 元空间：先对比一下JDK8和以前版本的方法区
    ![alt JVM-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-03.png)  
    Perm区(永久代)在JDK8废除，用元空间来取代。**好处：非堆区，使用操作系统内存，不会出现方法区内存溢出；坏处：无限制使用操作系统内存会导致操作系统崩溃。所以一般要加-XX:MaxMetaspaceSize参数来控制大小。**
    **方法区**：包含在元空间中。方法区存储：**类信息、静态（static）变量，常量（final），编译后的代码等数据**。是线程共享的。
* 程序计数器：在多线程切换的情况下，Java通过程序计数器来记录字节码执行到什么地方，这样能保证切换回来时能够从原来的地方继续执行。（相当于字节码的行号指示器）。程序计数器实现了**异常处理，跳转，循环分支**的功能。因为每个线程都有其独立的程序计数器，所以是线程私有的。
    

### JVM类加载机制
类加载过程：**加载->验证->准备->解析->初始化**  大多数情况按这个流程加载。
**加载**：将.class文件加载到方法区
**验证**：检查.class是否合规。如果.class不合规，抛异常。如果任何.class都能加载就不安全了。
**准备**：为一些类变量分配内存，并初始化为默认值。此时，实例对象还没有分配内存，所以这些动作是在方法区上进行的。
```java
 类加载的准备阶段会给类变量分配内存和初始化默认值。所以下面这段，我们不手动给a赋值也能编译通过。
 public class test_java {
    static int a;
    public static void main(String[] args) {
        System.out.println(a);  // output:0
    }
 }
 类变量有两个阶段可以被赋值，一是类加载准备阶段，二是初始化阶段。而局部变量只有一次初始化，如果没赋初值，不能使用，下面代码编译不通过。
 public class test_java {
    public static void main(String[] args) {
        int a;
        System.out.println(a);
    }
 }
```
**解析**：保证引用的完整性。做了：类或接口解析，类方法解析，接口方法解析，字段解析。
```text
这个阶段相关的报错信息：
java.lang.NoSuchFieldError  根据继承关系从上往下没找到相关字段时报错
java.lang.IllegalAccessError  不具备访问权限时报错
java.lang.NoSuchMethodError  找不到相关方法时报错
```
**初始化**：初始化成员变量，这一步才开始执行字节码。
```java
public class A {
    static{
        System.out.println(1);
    }
    public A(){
        System.out.println("A");
    }

    public static void main(String[] args) {
        A ab = new B();
        ab = new B();
    }
}

class B extends A{
    static {
        System.out.println("2");
    }
    public B(){
        System.out.println("B");
    }

//执行结果: 1 2 A B A B   原因:初始化子类先调用父类无参构造，static在类加载的准备阶段执行一次，不重复执行。
//static只会执行一次，对应cint方法
//对象初始化调用构造方法，每次新建对象都会执行，对应init方法
```

如果你自己写一个java.lang包，改写了String类，编译后发现没起作用。JRE不能被轻易篡改，否则可能会有安全问题。这就是类加载机制在起作用。
**类加载机制流程**：
![alt JVM-04](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-04.png)  

**双亲委派机制**：当某个类加载器需要加载某个.class文件时，它首先把这个任务委托给他的上级类加载器，递归这个操作，如果上级的类加载器没有加载，才会去真正加载这个类。
比如Object类，毫无疑问会交给最上层的类加载器加载，保证只有一个被加载的Object类。如果没有双亲委派机制，会有多个Object类，很混乱。
类加载器运行有先后顺序的，下面是类加载器的种类：
![alt JVM-05](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-05.png)  
* BootstrapClassLoader（启动类加载器）：c++编写，加载java核心库 java.*,构造ExtClassLoader和AppClassLoader。由于引导类加载器涉及到虚拟机本地实现细节，开发者无法直接获取到启动类加载器的引用，所以不允许直接通过引用进行操作
* ExtentionClassLoader （标准扩展类加载器）：java编写，加载扩展库，如classpath中的jre(lib/ext下jar包和.class)，javax.*和java.ext.dirs指定位置中的类，开发者可以直接使用标准扩展类加载器。
* AppClassLoader（系统类加载器）：java编写，加载程序所在的目录，classpath位置下其他所有jar和.class。我们写的代码最先尝试使用这个进行加载，再通过双亲委派机制递归委托上级类加载器。
* CustomClassLoader（用户自定义类加载器）：java编写,用户自定义的类加载器,可加载指定路径的class文件。支持自定义扩展功能。

**双亲委派机制作用**：
1、防止一个.class被重复加载，一个一个去上面问，加载过了就不加载了。保证数据安全。
2、保证核心.class不被篡改，即使篡改也不会加载，即使加载也不会是同一个.class对象。（不同的类加载器加载同一个.class得到的是不同的对象）。保证.class执行没问题。

* 可以覆盖HashMap类的实现吗？
可以，用到Java的endorsed技术，我们可以把自己的HashMap类打成jar放在-Djava.endorsed.dirs指定的目录，类名和包名应该与jdk原生的一致。这个目录下的jar会被优先加载，比rt.jar优先级更高。

* 哪些地方打破了Java的类加载机制?
举例子：
1.tomcat使用war包发布应用，由WebAppClassLoader类加载器优先加载，它加载自己目录的.class但不传递给父类加载器，但它可以通过SharedClassLoader实现共享和分离。
2.Java的SPI机制，例子：Mysql的JDBC。使用JDBC Driver前使用Class.forName("com.mysql.jdbc.driver)，但如果删除这行代码也能正确加载到驱动类，因为使用ServiceLoader来动态装载。

* 如何加载远程.class文件，怎么加密.class文件？
通过实现一个新的自定义类加载器。


















JAVA8元空间？为什么要元空间？为什么替代永久代？


常量池分静态常量池和运行时常量池，静态常量池在 .class 中，运行时常量池在方法区中。
字符串池在JDK 1.7 之后被分离到堆区。
String str = new String("Hello world") 创建了 2 个对象，一个驻留在字符串池，一个分配在 Java 堆，str 指向堆上的实例。
String.intern() 能在运行时向字符串池添加常量。




## 小标题1  

## 小标题2  


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
## 一些常用Java命令


## 参考资料  
[Java双亲委派机制及其作用](https://www.jianshu.com/p/1e4011617650)
[Apache Kafka](http://kafka.apache.org/)

