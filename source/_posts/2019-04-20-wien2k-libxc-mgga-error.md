---
title: 解决编译WIEN2k时找不到meta-GGA例程的问题
comment: true
date: 2019-04-20 14:05:10
tags:
- WIEN2k
- Bugfix
- LIBXC
- Intel
- Compilation
categories: Software
---

## 摘要

通过修改libxc.F, 解决编译WIEN2k v16.1时出现的未定义"xc_f03_mgga_x_tb09_set_params_"的错误

<!--more-->

## 问题描述

在{% post_link wien2k-fftw3-multi-def %}一文修正FFTW错误基础上, 利用Intel, Intel FFTW和LIBXC编译WIEN2k v16.1的`lapw0`时, 串行版本报错

```
ld: libxc.o: in function `libxc_':
libxc.F:(.text+0xcf7): undefined reference to `xc_f03_mgga_x_tb09_set_params_'
ld: libxc.F:(.text+0xd6b): undefined reference to `xc_f03_mgga_x_tb09_set_params_'
make[2]: *** [Makefile:83: lapw0] Error 1
make[2]: Leaving directory '/opt/software/wien2k/16.1/SRC_lapw0'
make[1]: *** [Makefile:72: seq] Error 2
make[1]: Leaving directory '/opt/software/wien2k/16.1/SRC_lapw0'
make: *** [Makefile:64: all] Error 2
```



## 解决方案

这个错误在[这封mail-list](https://www.mail-archive.com/wien@zeus.theochem.tuwien.ac.at/msg16924.html)里提到, 原因是由于LIBXC版本升级导致的一些参数改变. 用这个[libxc.F](libxc.F)替代`SRC_lapw0`中同名文件, 即可正确编译. 
