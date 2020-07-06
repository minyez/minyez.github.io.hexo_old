---
title: GPAW笔记(五)——重启GW
comment: true
toc: false
date: 2019-09-12 19:07:28
updated: 2019-09-12 19:07:28
tags:
- GPAW
- GW
categories: Software
---

{% alert success %}
记录如何修改GPAW源码以允许开启ecut外推(`ecut_extrapolation=True`)的GW计算重启.
{% endalert %}
<!-- more -->

在超算上进行大体系计算时, 经常会遇到的问题是计算因为超过了单个任务所需时间而被迫停止. 对于较大体系或者较严格参数的GW计算, 遇到这种问题的可能性很高. 一般SCF计算可以通过读写波函数来重启, 但GW计算重启起来稍微麻烦一些, 也有不同的策略, 比如单独输出介电矩阵元.

在GPAW中, 重启GW计算可以通过指定`restartfile`参数来实现. 对于一个可能超时的计算, 在计算初始就指定`restartfile`, 那么在计算停止后以同样命令重新执行脚本, GPAW就会从停止的地方继续计算.

GPAW的GW重启机制是将已经计算好的来自`nQ`个q点的自能和自能梯度以及N存到`restartfile`里, 中断后读取之, 再从`nQ+1`个q点开始屏蔽库仑作用和自能的计算.

在1.5.2版本下, 从`gpaw.response.g0w0`的源码L1330看一下`restartfile`所存字典的结构

```python
data = {
    'last_q': nQ,
    'sigma_eskn': np.zeros((necut, nspins, nkpts, nbandsgw)),
    'nsigma_eskn': np.zeros((necut, nspins, nkpts, nbandsgw)),
    'ecut_e': np.zeros(necut),
    #...
}
```

其中`necut`是指定的介电矩阵截断的个数, 在`ecut_extrapolation=True`时等于3, 否则为1. 屏蔽库仑作用计算采用q点外循环和ecut内循环, 因此对于`necut`大于1的情况, 如果计算恰好在某个中间的ecut处停止, 那么该q点后面的ecut的计算就会被跳过.

因此若要在`necut`大于1的情况, 也即做ecut外推的情况下正确重启GW计算, 需要修改源码. 自己的做法是在字典里增加一个`last_ecut`的关键词, 定义

```python
'last_ecut': nQ * len(self.ecut_e) + iecut
```

并在load时读取到`last_ecut`属性. 实际上`last_ecut`同时对q点和ecut进行记数. iecut则作为`save_restart_file`的额外参数传入. 相应修改跳过判定条件

```python
for iq, q_c in enumerate(self.qd.ibzk_kc):
    if iq <= self.last_q - 1:
        continue
    # ...
    for ie, ecut in enumerate(self,ecut_e):
        if ie <= self.last_ecut - iq * len(self.ecut_e):
            continue
        # ...
        if self.restartfile is not None:
            self.save_restart_file(iq,ie)
```

这样就能正确重启包含ecut外推的G0W0计算了. 尽管如此, 因为外面还有一层自洽GW迭代步数的循环, 这样的修改对自恰GW可能还是有问题, 不过对我自己已经足够了.
