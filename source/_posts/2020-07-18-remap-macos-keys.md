---
title: 修改 macOS 上外设键盘的键位映射
comment: true
toc: true
date: 2020-07-18 16:05:58
tags: [macOS, keyboard]
categories: Software
---

{% alert success %}
用 `hidutil` 对 macOS 外设键盘改键，并设置开机自启.
{% endalert %}
<!-- more -->

## 前言

最近在用 Emacs 编写文本时遇到的一个问题就是频繁地缩回小拇指去按左 ctrl 很不方便。因此想着把大小写锁定键改成 ctrl. 在 macOS 上，修改内置键盘键位是比较容易的，`系统偏好` => `键盘` => `修饰键`, 就可以随便改。但这一修改不会应用到外接键盘上 (笔者用的是 Logi MX Keys). [搜索](https://mic-kul.com/2020/01/25/mx-keys-remap-right-alt/) 后发现可以用 `hidutil` 解决这个问题.

## 修改外设键盘映射

手册上，`hidutil` 被解释为用于管理人机接口设备 (Human Interface Device, HID) 事件系统的实用程序。我理解的 HID 就是键鼠，手柄，方向盘之类。修改键位需要用到它的 `property` 命令，通过脚本来说明可能更加直接。编写 `remap_keyboard.sh` 脚本

```bash
#!/usr/bin/env bash
hidutil property --matching '{"Product": "MX Keys"}' \
    --set '{"UserKeyMapping": [{"HIDKeyboardModifierMappingSrc":0x700000039,
                                "HIDKeyboardModifierMappingDst":0x7000000e0}]}'
```

选项的具体含义可通过 `hidutil property --help` 了解。这里做一些简单说明

- `--matching` 选项用来匹配需要修改的外设，值是一个字典。这里用的 Key 是产品名 `Product`. 如果不知道产品名，可以用 `hidutil list` 了解设备情况. RegistryID 等信息也能从这里看到.
- `--set` 用来设置属性值。相应的，提取属性是 `--get`.
- 改键对应的 Key 是 `UserKeyMapping`, 值是一个列表。列表中每一个元素是一个字典。这里用于映射修饰键的 Key 是 `HIDKeyboardModifierMappingSrc` 和 `HIDKeyboardModifierMappingDst`. 通俗的说，`Src` 是键盘上的键，`Dst` 是机器实际接收的按键，用 16 进制数表示。键位值是 `0x700000000` 加上对应的 Usage ID, 可以在 [Apple 文档](https://developer.apple.com/library/archive/technotes/tn2450/_index.html) 上查到. CapsLock 是 `39`, 左 Ctrl 是 `e0`.

写完后，加上权限运行即可

```bash
chmod +x remap_keyboard.sh
./remap_keyboard.sh
```

## 开机自启

系统重启后，映射会失效。所以需要把它写进开机自启动项里。可以用 Automator 的 App, 也可以用 `launchctl`. 参考 [SO 回答](https://stackoverflow.com/questions/6442364/running-script-upon-login-mac), 编写 plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
   <key>Label</key>
   <string>com.user.loginscript</string>
   <key>ProgramArguments</key>
   <array><string>/path/to/remap_keyboard.sh</string></array>
   <key>RunAtLoad</key>
   <true/>
</dict>
</plist>
```

命名为 `com.user.loginscript.plist`, 保存到 `~/Library/LaunchAgents` 下。然后用 `launchctl` 修改启动项

```shell
launchctl load ~/Library/LaunchAgents/com.user.loginscript.plist
```

重启测试似乎并没有成功 (\*/ω＼\*) 索性放到 bin 下，发现 capslock 恢复后就手动运行，倒也算是解决了吧.
