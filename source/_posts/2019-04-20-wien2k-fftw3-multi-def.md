---
title: 解决编译WIEN2k时FFTW3 multiple definition错误
comment: true
date: 2019-04-20 13:50:59
tags:
- WIEN2k
- Bugfix
- Intel
- FFTW
- Compilation
categories: Software
---

## 摘要

通过使用Intel FFTW3 wrapper, 解决了自编FFTW下编译WIEN2k v14.2时出现的多次定义"fftw_destroy_plan"错误

<!--more-->

## 问题描述

尝试用Intel 2018.0和对应编译的FFTW3库编译WIEN2k v14.2. 用`siteconfig_lapw`, 在编译`SRC_lapw0`中的并行程序`lapw0_mpi`时, 报错

```
libfftw3.a (apiplan.o): In function `fftw_destroy_plan’:
apiplan.c:(.text+0x430): multiple definition of `fftw_destroy_plan’
mkl/lib/intel64/libmkl_intel_lp64.a(fftw_destroy_panl.o):fftw_destroy_plan.c(.text+0x0): first defined here
make[1]: *** [Makefile:99: lapw0_mpi] Error 1
```

最终编译信息里提示`tetra`, `joint`, `telnes3`报错, 错误为`Internal compiler error`.



## 解决过程

因为是FFTW3和MKL的冲突, 所以考虑放弃自己编译的FFTW3, 用Intel自带的FFTW3 wrapper. 在编译好静态库`libfftw3xf_intel.a`后, 把`include`改为`mkl/interfaces/fftw`, 把`-lfftw3`改为该静态库的绝对路径, 删掉`lfftw3_mpi`

作上述修改后用`siteconfig_lapw`重新编译`lapw0`, 出现`fft_modules`报错, 提示未定义MPI FFTW3变量的引用. 参考Intel的官方文档, 发现对MPI FFTW3有关变量的包装器定义在`fftw3x_cdtf`中, 需要编译这个lib. 链接时用它取代原来`lfftw3_mpi`的位置 

改完后再重新编译, 这一次报错`libfftw3x_cdft`链接错误: `Undefined reference to DftiSetValueDM`. 参考该 [Intel forum链接](https://software.intel.com/en-us/forums/intel-math-kernel-library/topic/284696) , 在静态链接时把`libmkl_cdft_core.a`放入链接的group中. 编译通过! 这时把RP_LIBS中的`libfftw3xf.a`去掉, 也可以正常编译. 