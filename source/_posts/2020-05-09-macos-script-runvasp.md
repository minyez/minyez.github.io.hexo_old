---
title: 解决macOS上脚本中运行VASP时动态库未载入问题
comment: true
toc: true
date: 2020-05-09 15:30:23
updated: 2020-06-29 15:30:23
tags:
- macOS
- VASP
categories: Software
---

{% alert success %}
解决macOS上脚本中运行程序遇到dyld: Library not loaded报错.
{% endalert %}
<!-- more -->

## 背景

疫情在家工mo作yu期间, 准备在自己macOS上用VASP做点小的测试. 因为懒得重复输入命令, 于是写了一个最基本的shell脚本

```bash
#!/usr/bin/env bash
module load vasp/5.4.4-common-intel-2018.0.1
mpirun -np 4 vasp_std
```

第一步载入的是事先写好的VASP相关环境变量. 执行, 结果报错

```bash
dyld: Library not loaded: @rpath/libmkl_intel_lp64.dylib
  Referenced from: /Users/stevezhang/software/sci/vasp/vasp.5.4.4-intel-2018.0.1/common/bin/vasp_std
  Reason: image not found
```

也即`libmkl_intel_lp64.dylib`没有加到`DYLD_LIBRARY_PATH`中. 可比较奇怪的是, 在命令行里echo `DYLD_LIBRARY_PATH`, 返回的是预期结果.

## 探索与解决

写一个非常简单的脚本，检查脚本执行过程中的环境变量.

```bash
#!/usr/bin/env bash
echo $DYLD_LIBRARY_PATH
echo $LIBRARY_PATH
echo $PATH

module load intel/2018.1
module load mpich/3.2.1-intel-2018.0.1

echo $DYLD_LIBRARY_PATH
echo $LIBRARY_PATH
echo $PATH
```

运行前线载入`intel/2018.1`模块. 运行脚本发现:

- 在module load前后, `LIBRARY_PATH`和`PATH`同echo的预期结果相同.
- 在module load前, `DYLD_LIBRARY_PATH`是空的.
- 在load后, 只有未在zshrc里载入的MPICH里定义的库路径被加入到`DYLD_LIBRARY_PATH`中.

搜索后找到几个帖子描述类似问题:

<https://stackoverflow.com/questions/35568122/why-isnt-dyld-library-path-being-propagated-here>
<https://apple.stackexchange.com/questions/212945/unable-to-set-dyld-fallback-library-path-in-shell-on-osx-10-11-1>

问题原因是，从El Captian开始, macOS引入了系统完整性保护(system integrity protection, SIP), 在调用系统提供的解释器时，所有`DYLD_`环境变量会被重设. 在使用module管理环境时, 因为intel模块事先被载入过, 因此脚本里面载入intel模块的行为会被module无视, 因此只有MPICH中的变量加入到`DYLD_LIBRARY_PATH`中.

一种解决办法是, 在最开始的shell脚本里面手动设置`DYLD_LIBRARY_PATH`, 缺点是不容易复用bashrc或zshrc里的内容. 更方便的做法是在shell脚本里load完所有module后reload一下，

```bash
#!/usr/bin/env bash
module load vasp/5.4.4-common-intel-2018.0.1
module reload

mpirun -np 4 vasp_std # success
```

另一种可能的办法是[关闭SIP](https://blog.csdn.net/qq285744011/article/details/82219340), 不过因为reload完全解决了我的需求, 所以就没有尝试这种稍微麻烦些的办法.
