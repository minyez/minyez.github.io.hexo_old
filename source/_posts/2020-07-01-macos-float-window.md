---
title: 在macOS中置顶窗口
comment: true
toc: true
date: 2020-07-01 17:40:49
updated: 2020-07-01 23:07:09
tags: [macOS, MacForge, Afloatx, GTD]
categories: Software
---

{% alert success %}
使用MacForge和AfloatX插件, 在Mojave系统下允许窗口置顶.
{% endalert %}
<!--more-->

## 前言

macOS上一直困扰我的问题是没有简单的窗口置顶工具. 在PC下, 播放器之类的很多软件在任务栏上都有一个小图钉图标, 点一下就可以置顶. 但是macOS上竟然找不到自带这样功能的软件. 这归因于自Mac OS El Capitan以后苹果引入的系统完整性保护 (System Integrity Protection, SIP). 根据[维基百科](https://en.wikipedia.org/wiki/System_Integrity_Protection#Functions), SIP禁止用户对根目录下`/System`和`/usr`等特定文件夹的修改, 关闭代码注入和运行时进程附着, 禁止未签名的内核扩展. 由此看来, 将窗口置顶可能涉及向Finder运行时进行代码注入从而被SIP禁止, 因此按正常流程发布的app就不可能实现这个功能了. 但另一方面, 窗口置顶是否有可能通过由app发送置顶请求到Finder, Finder向用户一次性请求权限的方式来实现呢? 这就要看今后Apple对macOS的改进了.

可是对于Mojave来说恐怕等不到那个时候, 所以还是得自己想办法. [这篇文章](https://www.maketecheasier.com/mac-keeping-your-application-window-always-on-top/)提供了比较完整的思路, 主要是利用mySIMBL进行代码注入, 置顶功能由[Afloat](https://github.com/rwu823/afloat)提供. 有点遗憾的是, 这篇文章时间比较久远了, mySIMBL已经升级成了[MacForge](https://github.com/MacEnhance/MacForge), Afloat数年没有更新, 几乎被[AfloatX](https://github.com/jslegendre/AfloatX)取代. 不过基本思路没有变化, 就在这里简单记录一下流程.

## 流程记录

### Step 1 部分关闭SIP

这一部分在[MacForge Wiki页](https://github.com/MacEnhance/MacForge/wiki/Installation)上有充分的描述. 重启, 按住`CMD+R`进入recovery mode. 从左上角菜单栏打开终端, 输入以下部分关闭SIP的命令

```shell
csrutil enable --without fs --without nvram --without debug
```

`without`选项指定禁止的SIP功能. 对应内容可由直接输入`csrutil`来理解

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

`fs`指的是文件系统保护, `debug`指调试限制, `nvram`指非易失性存储器([Non-volatile random-access memory](https://en.wikipedia.org/wiki/Non-volatile_random-access_memory), NVRAM)保护. NVRAM是内存的一部分, 用于存储快速访问的设置, 包括[内核崩溃信息](https://support.apple.com/zh-cn/HT204063).

### Step 2 安装MacForge

解压GitHub中[最新发布的压缩包](https://github.com/w0lfschild/app_updates/raw/master/MacForge/MacForge.zip), 然后将`.app`移到应用程序中.

### Step 3 安装AfloatX

打开MacForge, 从Featured页面找到AfloatX, GET即可.

![ ](plugin.png)

### Step 4 置顶窗口

打开想要置顶的窗口, 右击对应app的Dock图标, 在AfloatX里选择`Float Window`, 窗口置顶就完成了. 关闭一次窗口重新打开, 就可以取消置顶.

![ ](float-taskpaper.png)

完工 (ง •̀_•́)ง 置顶GTD app窗口对于健忘+拖延的我来说就是救命恩人(bushi).
