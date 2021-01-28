---
title: Emacs 笔记 (三) —— Org-mode 导出到 LaTeX 与 Beamer
tags:
  - Org-mode
  - Emacs
  - LaTeX
  - Beamer
categories: Software
comment: true
toc: true
date: 2020-10-01 19:50
---

{% alert success %}
简单介绍了将 org 文件导出为 LaTeX 普通文档或 Beamer 演示所需要的基本准备, 包括 org 文档格式和相关 Lisp 变量的自定义.
{% endalert %}

<!-- more -->

## 前言

前面两篇博文谈及 Emacs 和 Org-mode 的基本操作。经过了快三个月的练习，现在对两者也算是熟悉了一些. 目前 Emacs+Org 已经成为我整理文献，分析数据和撰写研究报告的主力工具. 其中对我最重要的一个功能就是 org 文本向 LaTeX 和 Beamer 的导出. 通过编写导出模板，可以使用同一个 org 文件，不改动正文就可以同时导出 LaTeX 和 Beamer 格式的 tex 文档，再进行编译.

本文是对我自己的 LaTeX 导出配置的一个整理和回顾。对 `config` 文件全文感兴趣的朋友可以移步我的 [dotfiles 项目](https://github.com/minyez/dotfiles/blob/master/doom.d/config.el). 欢迎提出改进意见.

## LaTeX 导出的最小工作实例

```plain
#+TITLE: MWE of LaTeX export
#+LATEX_CLASS: article
#+LATEX_COMPILER: xelatex
#+LATEX_HEADER: \usepackage[dvipsnames]{xcolor}

This is a \colortext{Blue}{minimal} working example for \LaTeX export of org file

这是 org 文件导出为 \LaTeX 文档的最小工作实例.
```

快捷键 `C-c C-e l l` 即可导出 `.tex` 后缀的同名文件, 其中就是转换好的 LaTeX 代码. `C-c C-e l o` 可以在导出后立刻编译, 清理临时文件, 随后打开编译好的 pdf. 这里有四点需要说明:

第一, 导出的核心是头部参数 `LATEX_CLASS`。前者需要在变量 `org-latex-classes` (一个 list) 中预先定义. 它的默认值是

```Lisp
(
  ("article"
   "\\documentclass[11pt]{article}"
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
  ("report"
   "\\documentclass[11pt]{report}"
   ("\\part{%s}" . "\\part*{%s}")
   ("\\chapter{%s}" . "\\chapter*{%s}")
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}"))
  ("book" "\\documentclass[11pt]{book}"
   ("\\part {%s}" . "\\part*{%s}")
   ("\\chapter {%s}" . "\\chapter*{%s}")
   ("\\section {%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))
)
```

列表中每个元素也是一个列表, 各自对应一个预定义的 LaTeX 类. 每个类需要这样几个要素

- 类名称 (字符串)
- 对应的 LaTeX 文档类 (字符串)
- 各标题层级的转换规则 (不定数量的 cons cell)

类名称是 `LATEX_CLASS` 可以取的值. 可以看到默认值里定义了三个 LaTeX 类, 分别对应于 article, report, book 三个实际的 LaTeX 文档类. 定义文档类的 `documentclass` 语句, 再转换时会被添加到 tex 文件的最开头. 原则上写在这一行的所有内容都会被添加到 tex 的开头, 即序言部分. 因此我们可以对这一字符串做更复杂的自定义来满足自己的需求. 这一点后面会再提到. 后面的每个 cons cell 是 Org 各层级有序号和无序号标题转换的规则. 第一个对应一级标题, 第二个对应二级标题, 以此类推. 比如在 book 类中, 一级标题会被转换为 `part`, 三级无序标题会被转换为 `section*`. 可以在 `config.el` 自定义 LaTeX类. 例如添加如下代码即可增加一个 `beamer` 类

```lisp
(add-to-list 'org-latex-classes
  '("beamer"
    "\\documentclass[ignorenonframetext,presentation]{beamer}"
    ("\\section{%s}" . "\\section*{%s}")
    ("\\subsection{%s}" . "\\subsection*{%s}"))
)
```

它对应于 LaTeX 中的 `beamer` 文档类.

第二, `LATEX_COMPILER` 指明使用何种编译器来编译转换的 tex 文件. Org 提供了一条默认的编译 tex 文件的命令, 写在变量 `org-latex-pdf-process` 中. 默认是一个包含按次序执行的 latex 指令的列表, 因为在编译 tex 时由于交叉引用等原因, 编译器通常需要与 biber 等附加程序一起对源文档多次编译. 我们可以将其修改为使用 `latexmk` 等比较智能的编译器, 比如

```shell
latexmk -latexoption="-interaction=nonstopmode -shell-escape" -pdf -pdflatex=%latex -bibtex -f %f
```

这里的 `%latex` 对应于 `LATEX_COMPILER` 的值, `%f` 对应于所产生的 tex 文档的相对路径.

第三, 在转换为 tex 时, Org 原文中的 `\LaTeX`, `\colortext` 命令将不作任何转换, 原样导出. Org 会自动识别 `\`, `\begin{}..\end{}` 这样具有 LaTeX 特征的语句, 并在导出为 LaTeX 时保留它. 如果想编写专属 LaTeX 导出的内容, 可以使用 `@@latex: xxx@@` 的形式, 此时 `xxx` 只会在 tex 中出现, 而不会出现在 Markdown, HTML 等其他格式的导出中.

第四, `LATEX_HEADER` 允许包含任何序言区命令, 在默认情况下会添加到序言区末尾. 可添加任意行 `LATEX_HEADER`, 以便对特定文档进行序言区的定制. 如果一些序言是所有 LaTeX 导出公用的, 可以考虑添加到类声明当中. 如果是一个 package, 则可以加入到 `org-latex-packages-alist` 或 `org-latex-default-packages-alist`.

## Beamer 导出的最小工作实例

```plain
#+TITLE: MWE of Beamer Export
#+AUTHOR: minyez
#+OPTIONS: H:3
#+BEAMER_THEME: CambridgeUS
#+LATEX_CLASS_OPTION: [presentation]
#+LATEX_COMPILER: pdflatex
#+LATEX_HEADER: \usepackage{physics}
#+BEAMER_HEADER: \institute[Bed, Home]{Bedroom \\ My House}

* This is a section
** Subsection A
*** Frame one
\begin{equation}
\braket{\phi_i}{\phi_j} = \delta_{ij}
\end{equation}
*** Frame two
Not an empty frame
* This is another section
** Subsection B
non-frame text here
```

这里, `LATEX_COMPILER` 和前面 LaTeX 导出中的作用相同. OPTIONS 中用 `H:3` 指定三级标题转化为 Beamer 帧. 比如这里的 "Frame one" 和 "Frame two" 都会被转化为帧. slides 主题用 `BEAMER_THEME` 指定. 其他自定义命令用 `BEAMER_HEADER` 指定, 它们将被添加到 `LATEX_HEADER` 之后. 与 LaTeX 导出不同, `LATEX_CLASS` 不是必须的, 导出时默认使用 `beamer` 类, 但可用 `LATEX_CLASS_OPTION` 为 Beamer 文档类的 `\documentclass` 添加选项.

## 自定义 LaTeX 导出类

我们可以在 `org-latex-classes` 中定义比单独 `\documentclass` 更为复杂的序言. 事实上, Org 在导出时会检查 header 中的 `[DEFAULT-PACKAGES]`, `[PACKAGES]`, `[EXTRA]` 占位符. 如果没有这些占位符, 也未找到对应的 `[NO-*]`, 那么导出时会用 `org-latex-default-packages-alist`, `org-latex-packages-alist` 列表和文档的 `LATEX_HEADER` 语句展开对应的占位符. 如果找到了任意一个, 则会在该位置展开. 例如, 定义一个新的 `colorarticle` 类

```lisp
(add-to-list 'org-latex-classes
  '("colorarticle"
   "\\documentclass[11pt,4paper]{article}
[PACKAGES]
\\usepackage[dvipsnames,svgnames*]{xcolors}
[EXTRA]
\\definecolor{bg}{rgb}{0.95,0.95,0.95}
\\definecolors{AliceBlue}
[NO-DEFAULT-PACKAGES]"
   ("\\section{%s}" . "\\section*{%s}")
   ("\\subsection{%s}" . "\\subsection*{%s}")
   ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
   ("\\paragraph{%s}" . "\\paragraph*{%s}")
   ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))
)
```

这里会在 xcolors 前导入 `org-latex-packages-alist` 中定义的包, 在之后导入文档中 `LATEX_HEADER`, 但不会导入 `org-latex-default-packages-alist`. 以这种方式引入宏包的目的是方便在不同类中引入一些常用的宏包, 简化自定义类的编写.

之所以提供 `org-latex-packages-alist` 和 `org-latex-default-packages-alist` 两个参数, 可能是考虑到有的包适合在序言最开始包括 (如 `amsmath`, `xcolor` 等). 而有的包必须放在最后以避免可能的包冲突. (如 `hyperref`, `cleveref`). 笔者一般是把前者放在序言头部, 后者放在结尾.

### 宏包列表

默认宏包列表 `org-latex-default-packages-alist` 和宏包列表 `org-latex-packages-alist` 具有类似的结构. 先看默认宏包 (为简洁起见, 这里只包含一部分)

```lisp
(setq org-latex-default-packages-alist
  '(
    ("" "amsmath" t) ; include first to avoid iint and iiint error
    ("" "amssymb" t)
    ("" "wasysym" t) ; include last to avoid iint and iint error
    ("AUTO" "inputenc"  t ("pdflatex"))
    ("T1"   "fontenc"   t ("pdflatex"))
    (""     "CJKutf8"   t ("pdflatex"))
    (""     "xeCJK"     nil ("xelatex", "xetex"))
    (""     "fontspec"  nil ("xelatex", "xetex", "lualatex", "luatex"))
    (""     "graphicx"  t)
    (""     "xcolor"  t)
    ("newfloat,cache=true"   "minted"   nil)
  )
)
```

列表中每一个元素是一个列表, 最多包含四个参数

1. 宏包的选项 (字符串)
2. 宏包名称 (字符串)
3. 编译 tex 片断预览时是否导入 (布尔值)
4. 编译器 (即 `LATEX_COMPILER`) 依赖 (列表), 只在用该编译器时导出. 留空则表示无论何编译器均导出.

`org-latex-packages-alist` 是类似的

```lisp
(setq org-latex-packages-alist
  '(; hyperref and cleverf should be the last packages to load
    (""     "hyperref"  nil)
    (""     "cleveref"   nil)
  )
)
```

考虑到不同文档中需要 hyperref 包的选项 (链接颜色, 边框等) 不同, 因此比较灵活的办法是留空 alist 变量中 hyperref 的选项, 通过在 LaTeX 类定义的头部中指定 `PassOptionsToPackages` 来传递选项.

### 代码块风格控制

通常有两种方式来控制 LaTeX 文档中代码块的表现, listings 或 minted. 由于 minted 适用的语言更多, 风格也更为灵活, 笔者选择其作为代码块渲染

```lisp
(setq org-latex-listings 'minted)
```

并使用 `org-latex-minted-options` 控制 minted 环境的选项

```lisp
(setq org-latex-minted-options
      '(
        ("bgcolor" "bg")
        ("breaklines" "true")
        ("autogobble" "true")
        ("fontsize" "\\small")
       )
)
```

## 结合 watchman 模拟异步编译

在 Emacs 内编译 tex 虽然方便, 但是对于编译较大的文档, 或者交叉引用需要多次编译时, 编译动作需要较长的时间. 默认情况下, 编译是在 Emacs 进程内执行的, 这会导致我们在编译时无法进行其他操作, 造成时间的浪费. 在 Linux 下, 可以用 `watchman-make` 监控 `org-directory` 下 tex 文件的情况, 一旦有变化就执行 `make`. [watchman-make](https://facebook.github.io/watchman/docs/watchman-make.html) 是 Facebook 开源项目 [watchman](https://facebook.github.io/watchman/) 的一个组件, 用 Python 编写. 一件需要注意的事情是, 用 Homebrew 安装的 `watchman`, 在使用时会遇到 [name 'basestring' is not defined](https://github.com/facebook/watchman/issues/631) 错误. 简单的修复办法是, 找到它报错的一行把 `basestring` 改成 `str`, 然后就能正常使用了.

Org-mode 在内部支持异步导出和编译, 但是需要额外编辑异步导出的模板 `async-init.el`. 笔者稍微调试了一下这个文件, 但并未成功. 在导出元素比较丰富的 org 文档时, 转换本身可能就比较慢, 需要用异步的方式来提高效率. 目前需要还不是很明显, 等以后有机会研究, 届时再作更新.

## 总结

本文给出了笔者对 org 文档 LaTeX 导出的基本功能的探索, 对于普通文档的导出应当是够用了. 然而值得推敲和探索的还有很多, 比如异步导出模板, 利用 `LATEX_CLASS` 实现普通文档和 Beamer 演示导出之间的敏捷切换, 多行多列表格, 以及利用表格和 gnuplot 源代码在 org 文档内直接作图, 等等. 希望之后还有时间精力能把这些分享出来.

<!-- 在 `org-latex-classes` 里准备好 `beamer` 类. 同时, 定义另外一个普通的文档类, 例如名为 `beamerarticle` 的 article 文档类,
并将 `beamerarticle` 包添加到 class 的序言区 (或 `LATEX_HEADER`) 内.-->
