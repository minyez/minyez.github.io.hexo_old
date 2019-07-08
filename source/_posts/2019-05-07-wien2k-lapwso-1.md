---
title: 在WIEN2k中进行LAPWSO计算(一)
date: 2019-05-07 17:00:00
tags:
- WIEN2k
- SOC
- DFT
- Tutorial
categories: Software
comment: true
toc: true
---

## 摘要

介绍了WIEN2k中自旋非极化下通过LAPWSO考虑自旋轨道耦合(SOC)效应的第一性原理计算的流程. 以Si和Au为例子, 简单分析了SOC对能带结构的影响.

<!--more-->

## WIEN2k中实现的SOC

WIEN2k中价层轨道的SOC贡献是通过LAPWSO程序考虑的. 它基于一种所谓的二次变分[^1]的方法, 通过读取LAPW1计算的本征态的波函数与能量, 计算微扰$\hat{H}_{\rm SO}$的矩阵元并对角化, 得到包含SOC的波函数与能量. LAPWSO可以包含在SCF循环里, 也可以非自洽地运行.

[^1]: [Second variation](http://www.encyclopediaofmath.org/index.php?title=Second_variation&oldid=31231). Encyclopedia of Mathematics.

## 实际例子

### diamond Si

以diamond Si (10.405822 au)为例, RMT取1.8. 初始化命令

```bash
init_lapw -b -numk 64
```

体系共8个价电子. 先看不加SOC的结果. 执行

```bash
run_lapw -ec 0.0000001
```

仔细检查energy文件. 在第1个和第7个k点, 由能带4和5分别为价带和导带, 得到带隙为0.780 eV, 涉及k矢跃迁为000($\Gamma$)-100(X).

```plain
...
 0.000000000000E+00 0.000000000000E+00 0.000000000000E+00         1   291    15  1.0
           1 -0.476709975533258
           2  0.382390732021062
           3  0.382390732021068
           4  0.382390732021068
           5  0.567940696174970
           6  0.567940696174970
           7  0.567940696174976
           8  0.594331247119800
...
 1.000000000000E+00 0.000000000000E+00 0.000000000000E+00         7   294    20  3.0
           1 -0.183034494762965
           2 -0.183034494762950
           3  0.180029340741516
           4  0.180029340741516
           5  0.439692381439167
           6  0.439692381439175
           7   1.09817099212224
           8   1.09817099212225
...
```

关于能带的组成, 考虑$\Gamma$点上能带组分, 由TB分析可知, 上面8个能级从低到高依次是Si的$\sigma_{3s}$, $\{\sigma/\pi\}_{3p}$, $\{\sigma/\pi\}_{3p}^\ast$和$\sigma_{3s}^\ast$. 在一条k点路径上的组分变化可以从下面这张VASP计算的投影能带图看出[^2].

![Si投影能带图. 红色为s成分, 蓝色为p成分](Si_X-L-G-X.png)

[^2]: 因为用[mykit](https://github.com/minyez/mykit)制作的图, 目前只支持到VASP :(

上面这些都是对于无SOC的计算结果的分析. 下面利用LAPWSO微扰地考虑SOC. 首先用`save_lapw`保存上面的计算结果, 然后运行`initso`命令以初始化`lapwso`所需的主要输入文件`Si.inso`

```bash
save_lapw -d scf-no-soc
initso
```

`initso`是交互式命令, 会询问下面几个设置

1. 指定Direction of moment
2. 指定某些原子不考虑SOC
3. 修改考虑SOC的能带的最高能量(EMAX)
4. 是否在`case.in1`中添加RLO
5. 选择自旋极化方式. 因为在自旋极化情况下考虑SOC时, 体系的对称性有可能小于无SOC的情形. 如果选择`y`, `symmetso`程序将被执行, 确定考虑SOC后体系的对称性并修改`struct`文件.

暂时不深究几个问题的含义, 一路回车通关. 结束后执行

```bash
run_lapw -ec 0.0000001 -so
```

开始运行包含LAPWSO在内的SCF循环.

包含SOC的哈密顿量对角化后得到的本征值保存在`case.energyso`中. 与非极化计算的`case.energy`文件不同的是, SOC下不再有简单的自旋简并, 因此原则上各k点的能带数量是无SOC时的两倍. 还是看第1和第7个k点的能量

```plain
...
 0.000000000000E+00 0.000000000000E+00 0.000000000000E+00         1   291    30  1.0
...
           1 -0.476709708261459
           2 -0.476709708261458
           3  0.380103284844223
           4  0.380103284844224
           5  0.383531827460128
           6  0.383531827460128
           7  0.383531827479756
           8  0.383531827479756
           9  0.566261029915788
          10  0.566261029915788
          11  0.568777497161570
          12  0.568777497161571
          13  0.568777497196808
          14  0.568777497196810
          15  0.594331439770928
          16  0.594331439770930
...
 0.100000000000E+01 0.000000000000E+00 0.000000000000E+00         7   294    28  3.0
           1 -0.183035347355239
           2 -0.183035347355239
           3 -0.183035347355239
           4 -0.183035347355237
           5  0.180025326616621
           6  0.180025326616621
           7  0.180025326616631
           8  0.180025326616633
           9  0.439692350006189
          10  0.439692350006189
          11  0.439692350006200
          12  0.439692350006200
          13   1.09815900469418
          14   1.09815900469418
          15   1.09815900469536
          16   1.09815900469536
...
```

此时的价带和导带变成了8和9, 带隙为0.764 eV. 此外, $\Gamma$点上原来三重简并的3p成键与反键轨道均裂分为两组简并轨道, 能量较高的为四重简并, 较低的为二重简并. 考虑SOC后的带隙相比未考虑的情形只减小了0.016 eV, 反映出在Si等轻元素中相对论效应较弱的事实.

### FCC Au

以FCC Au (7.67 au)为例, 参考Novak老师的关于spin-orbit coupling笔记中的计算[^3]. RMT值取2.6, GMAX取16. 初始化命令

```bash
init_lapw -b -numk 5000 -rkmax 9
sed -i 's/ 12.00/ 16.00/g' Au.in2 # change GMAX
```

共17个价电子. 按和Si中相同的步骤, 分别进行无SOC和在LAPWSO下考虑SOC的计算. 直接对比$\Gamma$点上的能量. 先看无SOC的结果

```plain
 0.000000000000E+00 0.000000000000E+00 0.000000000000E+00         1    77    13  1.0
           1  -3.48417834812053
           2  -3.48417834812053
           3  -3.48417834812053
           4 -4.633683657763327E-002
           5  0.341371911764138
           6  0.341371911764145
           7  0.341371911764145
           8  0.456634603361144
           9  0.456634603361151
          10   1.75774908584153
          11   2.06272605171851
          12   2.06272605171851
          13   2.06272605171851
```

VASP的投影能带如下图所示. 从成分上看, 占据态分别是$5p$(1-3), $6s$(4), $t_{2g}$(5-7), $e_g$(8-9).

![Au投影能带图. 红蓝黄绿色分别为spdf成分.](Au_X-L-G-X.png)

再看考虑SOC后的结果`energyso`. 由于轨道增加一倍, 下面的18个轨道都是占据态[^4]. 很明显的, 原来的$t_{2g}$和$e_g$进一步裂分成了三组轨道, 能量从低到高的简并度分别为4, 2和4, 它们在群表示上的记号分别为$\Gamma_8, \Gamma_7$和$\Gamma'_8$.

[^3]: Prof. P. Novak, [Notes about spin-orbit](http://susi.theochem.tuwien.ac.at/reg_user/textbooks/novak_lecture_on_spinorbit.pdf), p12. 内容基于WIEN97.
[^4]: 可以通过增大`inso`中的`EMAX`来获取更多的SOC态的本征值

```plain
 0.000000000000E+00 0.000000000000E+00 0.000000000000E+00         1    77    18  1.0
           1  -4.20742280553107
           2  -4.20742280553106
           3  -3.14951843978248
           4  -3.14951843978248
           5  -3.14951842668932
           6  -3.14951842668932
           7 -4.585036452752571E-002
           8 -4.585036452752490E-002
           9  0.294994273106371
          10  0.294994273106371
          11  0.294994274995205
          12  0.294994274995205
          13  0.381494069224123
          14  0.381494069224123
          15  0.473340026931149
          16  0.473340026931150
          17  0.473340027624113
          18  0.473340027624115
```

考虑和不考虑SOC的$E_F$分别为0.705和0.699 Ry. 同Novak老师的能带位置结果(下表括号内数字)进行比较, 发现结果惊人一致(Novak老师的结果可还是用WIEN97算的啊).

| $E-E_F$ (mRy) |    No SOC    | SOC by LAPWSO |
| :-----------: | :----------: | :-----------: |
|  $\Gamma_8$   | -358  (-357) |  -410 (-410)  |
|  $\Gamma_7$   | -358  (-357) |  -324 (-323)  |
|  $\Gamma'_8$  | -242  (-241) |  -232 (-230)  |

## TODO

- [ ] 二次变分的原理.
- [ ] 对`initso`设置内容的阐明, direction of moment和RLO.
- [ ] 自旋极化计算.