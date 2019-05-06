---
title: 解决运行VASP时set_indpw_full错误
comment: true
toc: true
date: 2019-03-20 13:50:59
tags:
- VASP
- Bugfix
- MPI
categories: Software
---

## 摘要

通过恰当设置KPAR和NPAR, 解决VASP杂化泛函计算中出现的“set_indpw_full”错误.

<!--more-->

## 问题描述

用ACFDT-RPA计算Ne的EOS曲线, 在进行+8%体积的非自洽HF计算一步时, 标准输出中打印错误

```plain
internal error in SET_INDPW_FULL: insufficient memory
```

## 解决过程

谷歌该错误,  在[第一条vasp forum链接](https://cms.mpi.univie.ac.at/vasp-forum/viewtopic.php?t=17510)的最后, 楼主给出了解决方法:

1. 恰当设置KPAR和NPAR, 使得$\rm KPAR\times NPAR$等于总的核数.
2. 关闭对称性, ISYM=0.

我试着加上了KPAR=4, 因为总核数为16, NPAR=4, 不再报该错误, 计算顺利完成. 考虑到链接里的错误来自HSE计算, 因此这有可能是进行大体系的VASP杂化泛函计算时容易出现的错误.
