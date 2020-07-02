---
title: Python笔记(四)——使用MathpixOCR API进行LaTeX公式识别
comment: true
toc: true
date: 2019-10-28 16:39:23
updated: 2020-06-30 09:36:41
tags:
- LaTeX
- MathpixOCR
categories: Software
---

{% alert success %}
编写MathpixOCR API的Python包装器和简单的Automator workflow, 模拟Mathpix Snip Tool的公式识别体验.
{% endalert %}
<!--more-->

## 前言

用LaTeX准备文献报告时一个比较头疼的问题是输入文献中包含复杂符号的长公式. [Mathpix Snip Tool](https://mathpix.com/) (MST)提供了方便的光学字符识别功能, 可以将包含公式的截图转化为LaTeX代码. 今年MST从完全免费的1.0版本升级到了2.0, 自此个人用户每月只能免费识别50次, 这对于苦逼PhD显然是不够用的.

好在作为MST底层的MathpixOCR服务, API每月可免费调用1000次, 所得结果和MST相同, 只是没有MST方便的截图和GUI功能. 归根结底, 我们想实现的无非是识别剪贴板中的公式图片, 转化图片到LaTeX代码并复制到剪贴板而已. 这可以通过将OCR与OS命令包装在一起来实现. 官方提供了简单的[例子](https://github.com/Mathpix/api-examples/tree/master/python)供我们学习OCR API的使用, 而OS API可以通过Python包和CLI命令调用. 这篇文章是学习包装器编写的记录.

最终脚本已上传到[GitHub仓库](https://github.com/minyez/mathpixocr_wrapper), 欢迎下载使用.

## API包装

### 获取API密钥

首先需要在Mathpix上注册用户并填写信用卡信息, 注册后获得`app_key`和`app_id`作为API密钥. 脚本采用了两种从外部获取密钥的方式, 一种是环境变量, 另一种是从同路径下JSON读取.

### 从系统剪贴板获取图片

使用pillow包中的`ImageGrab.grabclipboard`获取剪贴版中的图片, 并产生`Image`对象. 注意, 此后剪贴板中的临时文件会被删除, 无法再直接通过路径获得

```python
>>> from PIL import ImageGrab
>>> im = ImageGrab.grabclipboard()
>>> os.path.isfile(im.filename)
False
```

因此需要先把图片保存下来才能在后续继续使用

```python
im = ImageGrab.grabclipboard()
fn = ".temp_eq.png"
im.save(fn, "PNG")
```

### base64编码

OCR要求图片编码为base64. 编码转换可以参考官方例子

```python
import base64
def image_uri(fn):
  image_data = open(fn, "rb").read()
  return "data:image/jpg;base64," + base64.b64encode(image_data).decode()
```

`b64encode`使用Base64规则将一串类字节字符串进行编码, `decode`方法返回编码后的普通字符串.

```python
>>> ec = base64.b64encode(b"abcdefg")
>>> ec
b'YWJjZGVmZw=='
>>> ec.decode()
'YWJjZGVmZw=='
```

### 调用API

通过`requests`包与OCR API进行通信. 通信数据要求为JSON, 它至少需要包含`src`和`format`两个键. `src`值就是base64编码后的图片字符串, `format`值为一个列表, 成员为所想要转换的格式, 支持的转化格式包括下面几种.

| `format`值         | 转化格式                               |
| :----------------- | :------------------------------------- |
| `text`             | 普通文本                               |
| `wolfram`          | Mathematica                            |
| `latex_simplified` | 简化的latex代码, 括号不包含left或right |
| `latex_styled`     | left/right控制的latex代码              |

利用`json`包将字典转化成JSON字符串, 用`requests`发送API请求到`v3/latex`端点

```python
data = json.dump({"src": img_base64, "format": ["latex_simplified",]})
headers = {
  'Content-type': 'application/json',
  'app_key': your_app_key,
  'app_id': your_app_id,
  }
r = requests.post('https://api.mathpix.com/v3/latex',
                  data=data, headers=headers)
```

通信返回的`r.text`是一个JSON字符串. 如果OCR识别成功, 则它包含`latex_simplified`键, 对应值为识别号的简化LaTeX代码. 如果识别失败, 则包含`error`键, 给出具体错误信息. 更复杂的API调用参考[官方文档](https://docs.mathpix.com/).

{% alert info %}
`v3/latex`端点目前是旧端点. 官方推荐使用`v/3text`, 通信所需的JSON关键词有些许不同, 但变化不是很大, 读者可自行参考文档修改. (2020-06-29)
{% endalert %}

### 拷贝转化好的LaTeX到系统剪贴板

参考了[这个GIST](https://gist.github.com/luqmaan/d8bc61e746207bb12f11), 使用macOS上的`pbcopy`将字符串拷贝到系统剪贴板. 另一种办法是直接打印到标准输出, 然后用Automator服务中的功能拷贝到剪贴板.

### 附加功能

比如每月API调用统计以及历史记录, 都保存在JSON文件中. 实现说起来比较琐碎, 就不赘述了.

## Automator服务

把写好的包装器放到`~/bin`下, 编写简单的工作流`Mathpix Snip OCR API`

![ ](automator_workflow.png)

然后在系统设置-键盘-快捷键设置服务的快捷键

![ ](shortcut.png)

如此一来, `cmd+shift+4`将公式截屏到剪贴板后`cmd+shift+M`, 等待片刻即可从剪贴板黏贴转换好的公式. 大功告成!

## 参考资料

使用pillow包来获取剪贴板图片: [Mathpix收费了？快使用API吧，一个月免费识别1000次！](https://zhuanlan.zhihu.com/p/83678942)
