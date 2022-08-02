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
 $ javap -p -v Hello   # -p打印私有字段和方法  -v尽量多打印一些信息

 当在java代码中添加一些注释信息后，.class的MD5不一样了。因为javac可以指定输出一些额外内容到.class
 javac -g:lines 强制生成LineNumberTable | javac -g:vars 强制生成LocalVariableTable | javac -g 生成所有debug信息
 当然如果使用IDEA，可以使用jclasslib Bytecode viewerb插件（插件商店搜索即可）
```
JVM的程序运行是在栈上完成的，运行main方法自动分配一个栈帧，退出方法体时候再弹出相应栈帧。从javap得到的结果看，大多数字节码指令是不断操作栈帧。
整个过程：**Java 文件->编译器->字节码->JVM->机器码**
整个过程：**Hello.java -> Hello.class -> Java类加载器(JVM中) -> 执行引擎(JVM中) -> 通过操作系统接口解释执行+JIT**

如下有两段代码：我们可以通过字节码文件判断它们的执行结果
```java
 public class A{  # 第一段
    static int a = 0;
    static {
        a = 1;
        b = 1;
    }
    static int b = 0;
    public static void main(String[] args) {
        System.out.println(a);
        System.out.println(b);
    }
 }
//执行结果：1 0
//字节码如下：
       0: iconst_0
       1: putstatic     #3                  // Field a:I
       4: iconst_1
       5: putstatic     #3                  // Field a:I
       8: iconst_1
       9: putstatic     #5                  // Field b:I
      12: iconst_0
      13: putstatic     #5                  // Field b:I
      16: return
--------------------------------------------------------------------------------------------------
 public class A{  # 第二段
    static int a = 0;
    static {
        a = 1;
        b = 1;
    }
    static int b;
    public static void main(String[] args) {
        System.out.println(a);
        System.out.println(b);
    }
 }
//执行结果：1 1
//字节码如下：
       0: iconst_0
       1: putstatic     #3                  // Field a:I
       4: iconst_1
       5: putstatic     #3                  // Field a:I
       8: iconst_1
       9: putstatic     #5                  // Field b:I
      12: return
```
其他信息：
stack=1, locals=0, args_size=0中
stack表示该方法最大操作数栈深度为4，JVM根据这个分配栈帧中操作栈深度，
locals变量存储了局部变量的存储空间，单位是Slot(槽)，
args_size指方法参数个数
其他字节码指令表可参照：https://docs.oracle.com/javase/specs/jvms/se8/html/jvms-6.html



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
* 元空间：存放类名与字段(类的元数据)，运行时常量池，JIT优化。
    先对比一下JDK8和以前版本的方法区
    ![alt JVM-03](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-03.png)  
    Perm区(永久代)在JDK8废除，用元空间来取代。**好处：元空间的出现解决了类和类加载器元数据过多导致的OOM问题，它是非堆区，使用操作系统内存，不会出现方法区内存溢出，省去了GC扫描压缩的开销，每个加载器有专门的存储空间；坏处：无限制使用操作系统内存会导致操作系统崩溃，所以一般要加-XX:MaxMetaspaceSize参数来控制大小。元空间不支持压缩，有内存碎片问题。**
    **方法区**：包含在元空间中。方法区存储：**类信息、静态（static）变量，常量（final），编译后的代码等数据**。是线程共享的。
    元空间内存管理由元空间虚拟机完成。
* 程序计数器：**[JVM中唯一不会OOM的区域]**在多线程切换的情况下，Java通过程序计数器来记录字节码执行到什么地方，这样能保证切换回来时能够从原来的地方继续执行。（相当于字节码的行号指示器）。程序计数器实现了**异常处理，跳转，循环分支**的功能。因为每个线程都有其独立的程序计数器，所以是线程私有的。
    

### JVM类加载机制
类加载过程：**加载->验证->准备->解析->初始化**  大多数情况按这个流程加载。
**加载**：将类的同名.class文件加载到方法区
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

### JVM的GC
![alt JVM-06](https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-web@master/cdn_sources/Blog_Images/JAVA/JVM/JVM-06.png)  
**GC Roots**：可达性分析法，是GC实现的一种方法(另一种是引用计数法)，GC Roots是一组活跃的引用，程序在接下来的运行中能直接或间接引用或能被引用的对象。从GC Roots不断向下追溯遍历，会产生Reference Chain引用链。GC Roots遍历过程是找出所有活对象，并把其余空间认定为无用，而不是找到死对象。如果一个对象连续两次遍历过程中跟GC Roots没有任何直接或间接引用，则会被GC掉。
GC Roots包括：
* 活动线程相关的各种引用
* 类的静态变量的引用
* JNI引用
* GC Roots是引用不是对象
**引用级别（引用链的表现）**：
* 强引用：[有用且必须]内存不足直到抛OOM，这种强引用的对象也不会被回收。 - 容易造成内存泄露(比如一个User类没有字段info，用HashMap<User,String>存，用完User但因为被HashMap使用而未能回收，就造成内存泄露)
* 软引用：[有用非必须]维护一些可有可无的对象，内存足够的时候不会被回收，内存不足会回收。如果回收了软引用对象后内存还不够则抛出OOM。
* 弱引用：[可能有用非必须]引用的对象相比软引用，要更加无用一些，生命周期更短。GC时无论内存是否充足都会回收弱引用关联的对象。不过由于垃圾回收器是一个优先级较低的线程，所以并不一定能迅速发现弱引用对象。
* 虚引用：[无用]形同虚设的引用，任何时候都可被回收。  

**WeakReference与SoftReference的区别?**
虽然WeakReference与SoftReference都有利于提高GC和内存的效率，但是WeakReference一旦失去最后一个强引用，就会被GC回收，而软引用虽然不能阻止被回收，但是可以拖延到JVM内存不足的时候再被回收。

**为何要有多种不同引用级别?**
_利用软引用和弱引用解决OOM问题_：用一个HashMap来保存图片的路径和相应图片对象关联的软引用之间的映射关系，在内存不足时，JVM会自动回收这些缓存图片对象所占用的空间，从而有效地避免了OOM的问题.
_通过软引用实现Java对象的高速缓存_:比如我们创建了Person类，如果每次需要查询一个人的信息,哪怕是几秒中之前刚刚查询过的，都要重新构建一个实例，这将引起大量Person对象的消耗,并且由于这些对象的生命周期相对较短,会引起多次GC影响性能。此时,通过软引用和HashMap的结合可以构建高速缓存,提高性能。

```java
 //强引用
 Shmily shmily = new Shmily();

//软引用  
 SoftReference<Shmily> softReference = new SoftReference<Shmily>(new Shmily());
 Shmily shmily = softReference.get();

 //弱引用  
 WeakReference<Shmily> weakReference = new WeakReference<Shmily>(new Shmily());
 Shmily shmily = weakReference.get();

 //虚引用 虚引用的使用必须和引用队列（Reference Queue）联合使用 
 ReferenceQueue referenceQueue = new ReferenceQueue();
 PhantomReference<Shmily> phantomReference = new PhantomReference<Shmily>(new Shmily(), referenceQueue);
 Shmily shmily = phantomReference.get();

 //所有以上对象出了强引用之外，一旦被回收，get方法返回null。
 //以上创建软引用，弱引用的对象softReference和weakReference还都属于强引用，用完也需要回收避免内存溢出，方法如下：
 ReferenceQueue referenceQueue = new ReferenceQueue();
 PhantomReference<Shmily> phantomReference = new PhantomReference<Shmily>(softReference, referenceQueue);
```

**可能发生OOM的内存区域**：除了程序计数器，都有可能。但主要是发生在堆上。
**OOM发生原因**：
* 内存不足需要扩容。
* 错误的引用方式，没有及时切断GC Roots的引用，导致内存泄漏。(典型)
* 没有进行数据范围检查，比如全量查询了某个数据库。
* 无限制无节制使用MemoryOverHead

**JVM的垃圾回收算法**
**GC的标记过程**：从GC Roots遍历所有可达的活跃对象并标记。
**GC触发条件**：1.老年代不足 2.调用了System.gc()  3.通过MinorGC进入老年代的对象大小总和大于老年代的大小（担保失败）  4.Eden区不够存放新创建的对象
**GC算法：**
* 标记清除算法：标记-标记已用对象，清除-清除未被标记的对象。
   + 缺点：产生内存碎片
   + 场景：适合在收集频率低的老年代使用
* 复制算法：内存空间分等大两块，一块满了，未被标记的对象复制到另一块。
   + 优点：解决了内存碎片问题，效率最高
   + 缺点：会有一半的内存空间浪费
   + 场景：适合收集频率高且追求收集效率的年轻代使用
* 标记整理算法：移动所有存活的对象，且按内存地址顺序依次排列，然后将末端内存全部回收。
   + 优点：解决了内存碎片问题，同时解决标记复制算法的内存空间浪费问题
   + 缺点：效率低于复制算法和标记清除算法   
   + 场景：适合在收集频率低的老年代使用
* 分代收集算法: JVM采用**分代收集算法**，对不同的区域采用不用的收集算法。
   分代收集算法是融合上述3种基础的算法思想，而产生的针对不同情况所采用不同算法的一套组合。根据对象存活周期的不同将内存划分为几块。一般是把 Java 堆分为新生代和老年代，这样就可以根据各个年代的特点采用最适当的收集算法。在新生代中，每次垃圾收集时都发现有大批对象是待回收的，只有少量存活，那就选用复制算法，只需要付出少量存活对象的复制成本就可以完成收集。而老年代中因为对象存活率高，就使用标记-清除或标记-整理算法来进行回收。

**GC种类：**
* MinorGC 发生在年轻代的GC
触发条件：Eden区不够存放新创建的对象
* MajorGC 发生在老年代的GC 与FullGC区别是只清理老年代而不清理年轻代
触发条件：①
* FullGC  全堆垃圾回收（如元空间引起的年轻代和老年代回收）
触发条件：①调用System.gc ②老年代空间不足(可能无足够连续空间) ③担保机制失败(Eden大对象无法存入老年代，因为检测到老年代无足够连续内存空间) ④Minor GC后进入老年代的平均大小大于老年代可用内存
* Mixed GC[G1收集器特有] 收集整个YoungGeneration和部分OldGeneration
   
Java的大部分对象生命周期都不长，它们位于年轻代(Young Generation)，而生命周期较长的位于老年代(Old Generation)。
<font size="3" color="red">**年轻代的GC**：年轻代使用复制算法</font>，因为年轻代大部分对象生命周期短，如果发生GC只会有少量对象存活，复制这部分对象是高效的。
年轻代分为**Eden:From Survivor:To Survivor = 8:1:1**三个空间。对象首先在Eden区，如果**Eden区满了就会触发MinorGC**。
<u>单数次MinorGC:在MinorGC后，存活的对象进入Form Survivor区。双数次MinorGC，Eden和From Survivor区一起清理，存活对象被复制到To区，并清空From区。</u>
从上面可以得知每次GC都有一个Survivor区空闲，由于Eden:From Survivor:To Survivor = 8:1:1，年轻代GC复制算法只浪费了10%的内存空间，同时做到了高效，无碎片和节约空间。
扩展：TLAB(Thread Local Allocation Buffer)，是JVM给每个线程单独开辟的区域，用来加速对象分配。在Eden区分多个TLAB，TLAB通常比较小，对象优先分配在TLAB上，对象较大才会在Eden区分配。TLAB是一种优化，类似于逃逸分析的对象在栈上分配的优化。

<font size="3" color="red">**老年代的GC**：老年代一般使用**标记整理和标记清除算法**</font>。因为老年代很多对象存活率高，占用较大，不方便复制。
**对象怎么进入老年代**：
1. **达到一定年龄**
每次发生MinorGC，对象年龄加1，达到阈值(最大值是15可通过‐XX:+MaxTenuringThreshold调)，进入老年代。
2. **分配担保机制**
因为Survivor区只占年轻代10%的空间，发生MinorGC时无法保证每次Eden+其中一个Survivor存活的对象大小都小于另一个Survivor区空间，通过分配担保机制，另一个Survivor区放不下的对象直接进入老年代。JVM每次MinorGC前会检查老年代最大可用连续内存空间是否大于新生代对象的总空间，如果是的话确保MinorGC是安全的。
3. **大对象直接进入老年代**
超过一定大小的对象直接进入老年代。(通过-XX:PretenureSizeThreshold设置，默认0表示都要先走年轻代)
4. **动态年龄判定**
为了使内存分配更灵活，JVM不一定要求对象年龄达到MaxTenuringThreshold(15)才晋升为老年代，若Survivor区相同年龄对象总大小大于Survivor区空间的一半，则大于等于这个年龄的对象将会在MinorGC时移到老年代。

<font size="3" color="red">**JVM常见垃圾回收器**：</font>
如果垃圾收集算法是JVM垃圾回收的方法论，那垃圾回收器就是上述算法的实现。
* 年轻代垃圾回收器
    1. Serial垃圾回收器
    单线程的垃圾回收器，垃圾回收时暂停一切用户线程，使用复制算法。
    优点：简单轻量级，使用资源少。
    场景：用于客户端应用，因为客户端应用不会频繁创建对象。
    2. ParNew垃圾回收器
    Serial回收器的多线程版本，多条GC线程并行回收，垃圾回收时仍暂停一切用户线程
    优点：多CPU环境下收集效率高些，GC停顿时间缩短。
    场景：多CPU场景下使用，ParNew适合交互多计算少的场景。
    3. Parallel Scavenge垃圾回收器
    多线程回收器
    场景：多CPU下使用，追求CPU吞吐量，适用于交互少计算多的场景。
* 老年代垃圾回收器
    1. Serial Old垃圾回收器
    与年轻代的Serial垃圾回收器对应，也是单线程，使用标记-整理算法。
    优点：简单轻量级，使用资源少。
    场景：也适用于客户端应用
    2. Parallel Old垃圾回收器
    Parallel Scavenge垃圾回收器的老年代版本。
    场景：多CPU下使用，追求CPU吞吐量，适用于交互少计算多的场景。
    3.CMS垃圾回收器
    以最短GC时间为目标，用户线程与GC线程可并发执行，垃圾回收过程用户不会感到明显卡顿。
    长期来看G1、ZGC等更高级的垃圾回收器是趋势。
* CMS垃圾回收器
    全称：Mostly Concurrent Mark and Sweep Garbage Collector（主要并发­标记­清除­垃圾收集器）
    CMS在年轻代使用复制算法，在老年代使用标记-清除算法。它把耗时的GC操作通过多线程并发执行的。
    优点：避免老年代GC出现长时间卡顿
    缺点：对老年代的回收没整理阶段，产生内存碎片随时间推移增多时必须要FullGC才能清理。可能会导致大对象创建失败。
    场景：不希望GC停顿时间长且CPU资源较充足
    回收过程：1.初始标记阶段：只标记GC Roots直接关联的对象和年轻代中的引用，不向下追溯，缩短了标记时GC暂停时间。2.并发标记阶段，并发地追溯可达对象，持续时间较长但跟用户线程并行执行。3.并发预清理，这个过程会清理dirty状态的老年代对象。4.可选的预清理。5.最终标记，会GC暂停。6.并发清理，用户线程重新激活，删除不可达对象。
    关于CMS的碎片整理问题：两个参数
        UseCMSCompactAtFullCollection（默认开启）：FullGC时压缩，整理内存碎片，会造成较长时间停顿。
        CMSFullGCsBeforeCompaction：每隔几次FullGC后执行一次带压缩的FullGC。
    总结CMS中有哪些会造成STW(GC停顿)的操作：  <font size="3" color="red">STW = stop the world.</font>
        初始标记阶段-较短停顿
        最终标记阶段-较短停顿
        老年代的回收-较长停顿
        Full GC阶段-较长停顿
* G1垃圾回收器
    全称：Garbage First（尽可能多地收集垃圾以减少FullGC）
    目前比较好的收集器，关注低延迟，用于替代CMS的功能更强大的新型收集器。
    引入了分区概念，弱化了分带概念
    优点：避免老年代GC出现长时间卡顿，同时与CMS相比解决了CMS产生碎片的缺陷。
    缺点：
    场景：不希望GC停顿时间长且CPU资源较充足
    回收过程：
    关于CMS的碎片整理问题：两个参数
        
    总结G1中有哪些会造成STW(GC停顿)的操作：  <font size="3" color="red">STW = stop the world.</font>
        
**GC小技巧**
1. GC日志查看
    加-XX:+PrintGCDetails参数 查看GC日志，有关GC日志的解析后续我会单写一个博客。
    使用Sun公司的gchisto，gcviewer离线分析工具
    使用JDK自带的JConsole
    使用jstat -gcutil pid命令
    使用JvisualVM工具





```text
查看当前Java版本垃圾回收信息
$ java -XX:+PrintCommandLineFlags -version  
    -XX:InitialHeapSize=266248768 -XX:MaxHeapSize=4259980288 -XX:+PrintCommandLineFlags -XX:+UseCompressedClassPointers -XX:+UseCompressedOops -XX:-UseLargePagesIndividualAllocation -XX:+UseParallelGC
    java version "1.8.0_191"
    Java(TM) SE Runtime Environment (build 1.8.0_191-b12)
    Java HotSpot(TM) 64-Bit Server VM (build 25.191-b12, mixed mode)

设置应用的垃圾回收器：
-XX:+UseSerialGC 年轻代和老年代都用串行收集器
-XX:+UseParNewGC 年轻代使用 ParNew，老年代使用 Serial Old [JDK9被抛弃]
-XX:+UseParallelGC 年轻代使用 ParallerGC，老年代使用 Serial Old
-XX:+UseParallelOldGC 新生代和老年代都使用并行收集器
-XX:+UseConcMarkSweepGC，表示年轻代使用 ParNew，老年代的用 CMS
-XX:+UseG1GC 使用 G1垃圾回收器
-XX:+UseZGC 使用 ZGC 垃圾回收器
```





常量池分静态常量池和运行时常量池，静态常量池在 .class 中，运行时常量池在方法区中。
字符串池在JDK 1.7 之后被分离到堆区。
String str = new String("Hello world") 创建了 2 个对象，一个驻留在字符串池，一个分配在 Java 堆，str 指向堆上的实例。
String.intern() 能在运行时向字符串池添加常量。
为什么String为final：1.为了实现字符串池：创建字符串常量时，JVM会检测字符串常量池，如果已存在，直接返回常量池中的实例的引用，如果不存在就实例化并放入字符串常量池。因为String为Final类型，我们可以十分肯定字符串常量池不存在两个相同的字符串。2.为了线程安全：因为它不可变，本身就是线程安全的3.节约内存4.HashMap的key往往用String是因为String不可变，在被创建时HashCode就被缓存了不需要重新计算。

GC是怎么判断对象是被标记的？
通过枚举根节点的方式，通过jvm提供的一种oopMap的数据结构，简单来说就是不要再通过去遍历内存里的东西，而是通过OOPMap的数据结构去记录该记录的信息,比如说它可以不用去遍历整个栈，而是扫描栈上面引用的信息并记录下来。
总结:通过OOPMap把栈上代表引用的位置全部记录下来，避免全栈扫描，加快枚举根节点的速度，除此之外还有一个极为重要的作用，可以帮HotSpot实现准确式GC【这边的准确关键就是类型，可以根据给定位置的某块数据知道它的准确类型，HotSpot是通过oopMap外部记录下这些信息，存成映射表一样的东西】。

CMS收集器是否会扫描年轻代？
会，在初始标记的时候会扫描新生代。虽然cms是老年代收集器，但是我们知道年轻代的对象是可以晋升为老年代的，为了空间分配担保，还是有必要去扫描年轻代。



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
[拉勾网](https://kaiwu.lagou.com/course/courseInfo.htm?courseId=31#/content?courseId=31)
[MetaSpace整体介绍](https://www.cnblogs.com/duanxz/p/3520829.html)
[深入理解JMM和GC](https://www.jianshu.com/p/76959115d486)
