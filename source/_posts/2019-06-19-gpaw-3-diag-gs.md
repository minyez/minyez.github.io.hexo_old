---
title: GPAW笔记(三)——求解器对全哈密顿量对角化的影响
comment: true
toc: true
date: 2019-06-19 20:43:08
updated: 2019-06-19 20:43:08
tags:
- GPAW
- DFT
- Band structure
categories: Software
---

{% alert success %}
本文比较了GPAW中不同求解器和不同密度收敛条件下对角化哈密顿量得到的本征值. 结果显示, 为了在较大的平面波截断下全对角化得到正确的Kohn-Sham能级, SCF需要使用CG求解器, 并取较严格的密度收敛标准.
{% endalert %}
<!--more-->

## 背景

GW, RPA和BSE等多体微扰计算需要大量的未占据态, 因此在进行这些计算前通常需要对当前基组下构造的哈密顿量进行全对角化以得到所有本征对. 在GPAW中, 这一步为

```python
GPAW.diagonalize_full_hamiltonian(nbands=None, ecut=None)
```

`nbands`和`ecut`都设为None时对角化得到的能带数量由平面波截断决定. GPAW这一方法继承自`gpaw.paw.PAW`, 实际执行对角化命令的是其中的`PWWaveFunctions`对象.

问题出现在用600 eV截断的平面波基组计算单层MoS2的GW时. 在默认能带数的PBE基态计算下, GPAW给出MoS2能谱对应于半导体, 费米能级约为-1 eV, 但对角化后的能谱对应的却是一个金属, 费米能级在-200 eV左右. 我想这种情况可能跟对角化的算法和基态收敛情况有关, 于是进行了下面的简单测试.

测试的GPAW版本是1.5.2, Python为采用Anaconda3/2019.3发行版. C扩展用Intel 2019编译, 数学库为MKL. 使用`mx2`函数构造MoS2模型

```python
from ase.build import mx2
from gpaw import GPAW, PW, FermiDirac

mos2 = mx2(formula='MoS2', kind='2H', a=3.184, thickness=3.127,
           size=(1, 1, 1), vacuum=10)
mos2.pbc = (1, 1, 1)
```

## 比较不同求解器

GPAW提供了五种求解器, CG, Davidson, RMM-DIIS, DirectLCAO, DirectPW. 这里主要讨论前三种. 简单测试DirectPW发现, 它计算的MoS2的$\Gamma$点带隙为1.7 eV, 要小于其他求解器和VASP的计算值2.7 eV. 初始化时求解器参数均使用GPAW的默认设置.

测试命令如下

```python
Ecut_kx_pairs = [(300, 6), (300, 9), (400, 12), (400, 18), (600, 6), (600, 18)]
egs = ["cg", "dav", "rmm-diis"]

for Ecut, kx in Ecut_kx_pairs:
    for eg in egs:
        suffix = f"Ecut_{Ecut}_kx_{kx}_{es}"
        calc = GPAW(mode=PW(Ecut), xc="PBE", eigensolver=es
                    kpts={'size': (kx, kx, 1), 'gamma': True},
                    occupations=FermiDirac(0.01), parallel={'domain': 1},
                    txt=f'MoS2_gs_{suffix}.txt')
        mos2.set_calculator(calc)
        mos2.get_potential_energy()
        calc.write(f'MoS2_gs_{suffix}.gpw')
        calc.diagonalize_full_hamiltonian()
        calc.write(f'MoS2_fulldiag_{suffix}.gpw')
```

CG使用4核并行, Davidson和RMM-DIIS使用16核并行. 测试结果如下表, 后三列中的值是分别用对角化和基态迭代计算得到的前20个能级的本征能量差, 定义为

$$
\Delta_{20} \equiv \sum_k\sum^{n<20}_{n=0}{|\epsilon^{diag}_{nk}-\epsilon^{gs}_{nk}|}.
$$

第三列是对角化得到的能带总数. 当取平面波截断到600 eV时, 使用Davidson和RMM-DIIS时的本征能量差非常大. 10次方误差来源是指标为0的能带的能量.

| Ecut | kx   | $N_{pw}$ |   CG    |   Dav   | RMM-DIIS |
| :--- | :--- | :------- | :-----: | :-----: | :------: |
| 300  | 6    | 2368     | 8.2E-01 | 2.6E+00 | 1.6E+01  |
| 300  | 9    | 2368     | 8.2E-01 | 1.0E+00 | 1.9E+01  |
| 400  | 12   | 3655     | 2.7E-01 | 1.6E+00 | 2.5E+01  |
| 400  | 18   | 3655     | 4.5E-02 | 2.0E+00 | 5.2E+01  |
| 600  | 6    | 6666     | 4.7E+00 | 5.6E+09 |          |
| 600  | 18   | 6666     | 3.5E+00 | 6.2E+10 | 6.2E+10  |

下图是设置三种不同的求解器时, 在600 eV截断下全对角化得到的所有k点上的本征值谱, 横坐标是能带指标. 当GPAW采用Davidson和RMM-DIIS时, 全对角化后部分k点上的能量系统偏低200 eV. 使用CG时怎没有这样的问题.

![600 eV平面波截断时对角化所得本征值](diag_eigensolver.png)

这里基本可以得到结论, 当需要在较大基组下对角化哈密顿量时, 基态计算采用CG求解器是比较保险的做法. 这里有一个了令人疑惑的地方是, 源码中`PWWaveFunctions`对象的对角化方法利用的是C扩展中的Scalapack功能, 与求解器应该没有直接的联系, 但结果看来求解器确实会影响对角化结果.

## CG下比较不同密度收敛限

下面测试密度收敛限对对角化所得的本征值的影响. 这里Ecut仍然取较大的600 eV, 求解器使用CG. 通过改变GPAW初始化时的`convergence`参数, 调整密度收敛限, 如

```python
calc = GPAW(mode=PW(Ecut), xc="PBE", eigensolver=es,
            convergence={'density': 1E-6})
```

测试结果如下表. 可以看出, 采用1E-08作为SCF收敛限时, 本征值收敛到非常小的阈值内, 同时SCF和对角化得到的低能能态在能量上完全一致. 另外, 如果不用CG而仍然用Davidson或者RMM-DIIS, 增大密度收敛限$\Delta_{20}$相比上一节没有改善.

| kx   | Convergence (Log10) | $\sum_{nk}{\epsilon_{nk}}$ (w.r.t default) | $\Delta_{20}$ |
| :--- | :------------------ | :----------------------------------------: | :-----------: |
| 6    | -4.61 (default)     |                     0                      |    4.7E+00    |
| 6    | -6                  |                   4.9383                   |    2.7E-04    |
| 6    | -8                  |                   5.0000                   |    4.0E-09    |
| 18   | -4.61 (default)     |                     0                      |    3.5E+00    |
| 18   | -6                  |                   9.4296                   |    1.5E-06    |
| 18   | -8                  |                   10.018                   |    1.5E-08    |

<!-- 它们在VASP里也有IALGO和ALGO的相似对应, 分别是58 (Conjugate, All), 38 (Normal)和48 (Very_fast). -->
