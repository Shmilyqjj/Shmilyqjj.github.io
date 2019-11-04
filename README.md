#My Blog

##佳境的小本本(Jiajing's Note)

##Welcome To [My Blog](c38kw0.coding-pages.com) !

我的[GitHub](https://github.com/Shmilyqjj)地址

我的[CloudMusic](http://music.163.com/artist?id=13610347)地址





###HEXO目录结构
```yml
|-- _config.yml     全局配置（网站名称作者主题部署等）
|-- package.json    框架参数（框架依赖拆件及其版本）
|-- scaffolds       脚手架（通用MarkDown模板，新建文章时，hexo根据这个目录的文件进行构建）
|-- source          网页资源（css,js,images,文章等）
   |-- _posts       博客文章（写文章的地方）
|-- themes          主题目录
|-- .gitignore      Git忽略文件或目录
|-- package.json    框架参数（框架依赖拆件及其版本）
```


* * *
#MarkDown语法字典
* 标题
# 一级标题(最大)
## 二级标题
### 三级标题
#### 四级标题
##### 五级标题
###### 六级标题

* 字体
*斜体文本*
_斜体文本_
**粗体文本**
__粗体文本__
***粗斜体文本***
___粗斜体文本___
<u>带下划线文本</u>

* 脚注
[^要注明的文本]: xxxxxxxxx

* 列表
无序列表用* + -三种符号表示
    * 列表嵌套
    1. 有序列表第一项：
        - 第一项嵌套的第一个元素
        - 第一项嵌套的第二个元素
        > 列表中可以使用区块
        > 列表中可以使用区块
    2. 有序列表第二项：
        - 第二项嵌套的第一个元素
        - 第二项嵌套的第二个元素
            * 最多第三层嵌套
            + 最多第三层嵌套
            - 最多第三层嵌套

* 区块引用
> 最外层
> > 第一层嵌套...
> > > 第二层嵌套...
> * list
> * list
> + list

* 代码块
`public static void main(String[] args)`
        System.out.println();
        //tab或者四个空格
```python
l = []
import copy
copy.copy(l)
```

```java
public static void main()
```

```scala
var qjj = 0;
//定义代码块并指定语言->显示高亮
```
* 链接
这是我的云音乐主页[CloudMusic](http://music.163.com/artist?id=13610347)
直接显示链接地址: <http://music.163.com/artist?id=13610347>
我的网易云主页高级链接[cm-1]
我的网易云主页高级链接[cm-2]

[cm-1]:http://music.163.com/artist?id=13610347
[cm-2]:http://music.163.com/artist?id=13610347

* 添加图片
![alt lalala](http://m.qpic.cn/psb?/V10aWFGB3ChSVt/4Onwe7wF*pBhD4*iWs0KetAXGTu6fMrAUJrxWkkB4fk!/b/dL8AAAAAAAAA&bo=hANYAgAAAAADB*8!&rf=viewer_4)
![alt hahaha](http://m.qpic.cn/psb?/V10aWFGB3ChSVt/4Onwe7wF*pBhD4*iWs0KetAXGTu6fMrAUJrxWkkB4fk!/b/dL8AAAAAAAAA&bo=hANYAgAAAAADB*8!&rf=viewer_4 "图片注释呀!鼠标放那会弹出注释!")
<img src="http://m.qpic.cn/psb?/V10aWFGB3ChSVt/4Onwe7wF*pBhD4*iWs0KetAXGTu6fMrAUJrxWkkB4fk!/b/dL8AAAAAAAAA&bo=hANYAgAAAAADB*8!&rf=viewer_4" width=30% title="可以使用html的标签,控制图片大小,title悬停显示文字">  

* 图片链接
[![Slack](https://slackin.alluxio.io/badge.svg)](https://www.alluxio.io/slack)
[![Release](https://img.shields.io/github/release/alluxio/alluxio/all.svg)](https://www.alluxio.io/download)
[![Docker Pulls](https://img.shields.io/docker/pulls/alluxio/alluxio.svg)](https://hub.docker.com/r/alluxio/alluxio)
[![Documentation](https://img.shields.io/badge/docs-reference-blue.svg)](https://www.alluxio.io/docs)
[![Twitter Follow](https://img.shields.io/twitter/follow/alluxio.svg?label=Follow&style=social)](https://twitter.com/intent/follow?screen_name=alluxio)
[![License](https://img.shields.io/github/license/alluxio/alluxio.svg)](https://github.com/Alluxio/alluxio/blob/master/LICENSE)


* 添加表格
`Markdown 制作表格使用 | 来分隔不同的单元格，使用 - 来分隔表头和其他行`
| 表头 | 表头 |
| ---- | ---- |
| 表格 | 表格 |
| 表格 | 表格 |
| 表格 | 表格 |



| 左对齐 | 右对齐 | 居中对齐 |
| :-----| ----: | :----: |
| 单元格 | 单元格 | 单元格 |
| 单元格 | 单元格 | 单元格 |

对于左右图片，可以使用单元格  ，如下

|   |   |
| ---- | ---- |
| <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-8.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=left alt="大宁郁金香公园"> | <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-9.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=right alt="大宁郁金香公园"> |
| <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-10.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=left alt="大宁郁金香公园"> | <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-7.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=right alt="大宁郁金香公园"> |
| <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-11.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=left alt="大宁郁金香公园"> | <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-12.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=right alt="大宁郁金香公园"> |
| <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-13.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=left alt="大宁郁金香公园"> | <img src="https://cdn.jsdelivr.net/gh/Shmilyqjj/Shmily-Web@master/cdn_sources/Blog_Images/QCon/QCon-14.jpg" width=100% style="border:solid 3px #CCFFFF" title="大宁郁金香公园" align=right alt="大宁郁金香公园"> |




* 对HTML的支持
`不在 Markdown 涵盖范围之内的标签，都可以直接在文档里面用 HTML 撰写`

```html
使用 <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>Del</kbd> 重启电脑
```
使用 <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>Del</kbd> 重启电脑

**文本加粗**
**\*正常显示\*号配合文本加粗体\**
```yml
以下支持反斜杠转义
\   反斜线
`   反引号
*   星号
_   下划线
{}  花括号
[]  方括号
()  小括号
#   井字号
+   加号
-   减号
.   英文句点
!   感叹号
```

* 数学公式  需要开启 mathjax: 0 0改为1
`当需要在编辑器中插入数学公式时，可以使用两个美元符 $$ 包裹 TeX 或 LaTeX 格式的数学公式来实现`

$$
\mathbf{V}_1 \times \mathbf{V}_2 =  \begin{vmatrix}
\mathbf{i} & \mathbf{j} & \mathbf{k} \\
\frac{\partial X}{\partial u} &  \frac{\partial Y}{\partial u} & 0 \\
\frac{\partial X}{\partial v} &  \frac{\partial Y}{\partial v} & 0 \\
\end{vmatrix}
$$tep1}{\style{visibility:hidden}{(x+1)(x+1)}}
$$

- - -














###Thanks:
[All Hexo Themes](https://hexo.io/themes/)

[Sakura](https://github.com/mashirozx/Sakura/) Hexo theme.

[hojun](https://sakura.hojun.cn) Modified into the theme.


