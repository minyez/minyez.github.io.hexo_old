---
title: 在 macOS 中置顶窗口
comment: true
toc: true
date: 2020-07-01 17:40:49
updated: 2020-07-01 23:07:09
tags: [macOS, MacForge, Afloatx, GTD]
categories: Software
---

{% alert success %}
使用 MacForge 和 AfloatX 插件, 在 Mojave 系统下允许窗口置顶.
{% endalert %}
<!--more-->

## 前言

macOS 上一直困扰我的问题是没有简单的窗口置顶工具. 在 PC 下, 播放器之类的很多软件在任务栏上都有一个小图钉图标, 点一下就可以置顶. 但是 macOS 上竟然找不到自带这样功能的软件. 这归因于自 Mac OS El Capitan 以后苹果引入的系统完整性保护 (System Integrity Protection, SIP). 根据[维基百科](https://en.wikipedia.org/wiki/System_Integrity_Protection#Functions), SIP 禁止用户对根目录下 `/System` 和 `/usr` 等特定文件夹的修改, 关闭代码注入和运行时进程附着, 禁止未签名的内核扩展. 由此看来, 将窗口置顶可能涉及向Finder运行时进行代码注入从而被 SIP 禁止, 因此按正常流程发布的 app 就不可能实现这个功能了. 但另一方面, 窗口置顶是否有可能通过由 app 发送置顶请求到 Finder, Finder 向用户一次性请求权限的方式来实现呢? 这就要看今后 Apple 的 macOS 更新了.

可是对于 Mojave 来说恐怕等不到那个时候, 所以还是得自己想办法. [这篇文章](https://www.maketecheasier.com/mac-keeping-your-application-window-always-on-top/)提供了比较完整的思路, 主要是利用 mySIMBL 进行代码注入, 置顶功能由 [Afloat](https://github.com/rwu823/afloat) 提供. 有点遗憾的是, 这篇文章时间比较久远了, mySIMBL 已经升级成了 [MacForge](https://github.com/MacEnhance/MacForge), Afloat 数年没有更新, 几乎被 [AfloatX](https://github.com/jslegendre/AfloatX) 取代. 不过基本思路没有变化, 就在这里简单记录一下流程.

## 流程记录

### Step 1 部分关闭SIP

这一部分在 [MacForge Wiki 页](https://github.com/MacEnhance/MacForge/wiki/Installation)上有充分的描述. 重启, 按住 `CMD+R` 进入 recovery mode. 从左上角菜单栏打开终端, 输入以下部分关闭 SIP 的命令

```shell
csrutil enable --without fs --without nvram --without debug
```

`without` 选项指定禁止的 SIP 功能. 对应内容可由直接输入 `csrutil` 来理解

```plain
$ csrutil
System Integrity Protection status: enabled (Custom Configuration).
Configuration:
    Apple Internal: disabled
    Kext Signing: enabled
    Filesystem Protections: disabled
    Debugging Restrictions: disabled
    DTrace Restrictions: enabled
    NVRAM Protections: disabled
    BaseSystem Verification: enabled

This is an unsupported configuration, likely to break in the future and leave your machine in an unknown state.
```

`fs` 指文件系统保护, `debug` 指调试限制, `nvram` 指非易失性存储器 ([Non-volatile random-access memory](https://en.wikipedia.org/wiki/Non-volatile_random-access_memory), NVRAM) 保护. NVRAM 是内存的一部分, 用于存储快速访问的设置, 包括[内核崩溃信息](https://support.apple.com/zh-cn/HT204063).

### Step 2 安装MacForge

解压 GitHub 中[最新发布的压缩包](https://github.com/w0lfschild/app_updates/raw/master/MacForge/MacForge.zip), 然后将 `.app` 移到应用程序中.

### Step 3 安装AfloatX

打开 MacForge, 从 Featured 页面找到 AfloatX, GET 即可.

![ ](plugin.png)

### Step 4 置顶窗口

打开想要置顶的窗口, 右击对应 app 的 Dock 图标, 在 AfloatX 里选择 `Float Window`, 窗口置顶就完成了. 关闭一次窗口重新打开, 就可以取消置顶.

![ ](float-taskpaper.png)

完工 (ง •̀_•́)ง 置顶 GTD app 窗口对于健忘+拖延的我来说就是救命恩人 (bushi).
