---
title: Python笔记(二)——常用re函数与语句总结
date: 2019-05-06 10:56:29
tags:
- Python
- regex
categories: Programming
comment: true
toc: true
---

## 摘要

整理了调用Python `re`包时的常用操作和命令. <!--more-->

这里主要按照使用情景, 对操作和命令进行分类, 这样也顺带梳理不同情境下可能用到的正则表达式. 目前更新到模式组方法的比较.

## 基本函数

下表列出了常用的re函数, 其中变量类型仅为自己常用的情况, 具体见[re文档](https://docs.python.org/3/library/re.html)(Python 3).

| 函数           | 参数                        | 功能                                                   |
| :------------- | :-------------------------- | :----------------------------------------------------- |
| `re.compile`   | `pat`(s)                    | 返回一个与正则表达式`pat`对应的regular expression对象. |
| `re.match`     | `pat`(s), `string`(s)       | 对`string`从头匹配`pat`, 返回Match对象                 |
| `re.fullmatch` | 同`re.match`                | 对整个`string`匹配`pat`, 返回Match对象                 |
| `re.search`    | 同`re.match`                | 在`string`中搜索匹配模式`pat`的子字符串, 返回Match对象 |
| `re.sub`       | `pat`(s), `repl`(s), `s`(s) | 将`s`中匹配`pat`的字符串**全部**替换为`repl`           |

一些注意点

- 我们可能习惯在命令行下使用通配符`*`, 但是在正则表达式下`*`的作用是匹配任意次.
- `re.match("^"+pat+"$", s)`匹配整条字符串, 因此与`re.fullmatch(pat, s)`等价

## 一次匹配字符串

用`re.match`和`re.fullmatch`进行匹配

### 匹配名为`V_x.y`的文件夹

其中`x`为数字0或1 `y`为长度大于等于1的数字

```python
>>> dname = "V_0.98"
>>> re.fullmatch(r"V_[01]\.[0-9]+", dname)
<re.Match object; span=(0, 6), match='V_0.98'>
```

### 匹配一条K点路径

匹配一条类似`GM-X-L-M`格式的K点路径, 要求每一个特殊K点由1到2个大写字母组成.

```python
>>> re.match(r'^([A-Z]{1,2}-)+[A-Z]{1,2}$', 'GM-X-L-GM-L')
<re.Match object; span=(0, 11), match='GM-X-L-GM-L'>
```

简单解读:

- `[A-Z]{1,2}`对大写字母匹配1次或2次
- `()+`: 对括号内(组)模式匹配1次或多次

## compile函数

利用`re.compile`产生模式对应的regular expression对象. regular expression对象拥有与`re`函数同名的方法, 之后所有有关该模式的匹配都通过该对象进行.

例如匹配邮件中用户名

```python
>>> PAT_USERNAME = re.compile(r'\w+')
>>> PAT_USERNAME.match('bob@163.com')
<re.Match object; span=(0, 3), match='bob'>
>>> PAT_USERNAME.match('chris@163.com')
<re.Match object; span=(0, 5), match='chris'>
```

这个例子可能还不怎么明显, 但当模式非常复杂时, regular expression对象代替字符串模式要方便很多, 也更易读.

## 利用group和groups获得匹配内容

使用regex时, 我们有时需要获得具体的匹配内容, 这可以通过在模式中加入`()`以定义组(group)这一方式实现.

在上面匹配`V_x.y`的例子中, 如果我们要获得后面的具体数字

```python
# obtain and print the ratio of volume from the name of directory
>>> dname = "V_0.98"
>>> matched = re.fullmatch(r"V_([01]\.[0-9]+)", dname)
>>> matched.group()
'V_0.98'
>>> matched.group(1)
'0.98'
>>> matched.group(0, 1)
('V_0.98', '0.98')
>>> matched.group(2)
IndexError: no such group
>>> matched.groups()
('0.98',)
```

这里比较了Match对象的两种方法`group`和`groups`. 总结一下

- 如果没有参数或参数为`0`, `group`返回的是整条匹配的子字符串.
- 如果参数不为`0`, 则返回第n个组(括号)中匹配的字符串.
- 参数个数等于1时, 返回一个字符串; 大于1时返回一个字符串元组.
- 如果参数大于被匹配模式中包含的组数, 抛出`IndexError`.
- `groups`返回所有组的匹配结果, 总是一个字符串元组.

## 利用group标记的替换

对于包含多个参数的输入

```text
param1 | param2 | param3 # this is comment
```

注释以"#"开头, 是可选的, 参数之间用`|`隔开. 例如, 一条包含两个参数的字符串及其对应的匹配模式

```python
s = "2.0  |  1.E-15   # pwm, stctol"
pat = r"^([\w \.-]+)\|([\w \.-]+)(#[\w \(\),\.-]*)?$"
```

可利用group进行灵活有效的替换. 比如说, 现在只将第一个参数替换为5.0, 则

```python
>>> re.sub(pat, r"5.0 | \2 \3", s)
'5.0 |   1.E-15          # pwm, stctol'
```

其中标记`\2`表示第二个组所匹配的子字符串, 以此类推. 这种方法的好处是只需要知道被匹配参数在文件中的位置(行号, 行内参数的总数以及所要参数的序号)就可以方便地替换, 不需要依赖`split`和其他判断函数.

具体来说, 对于参数个数可变的情形, 利用函数动态地产生匹配模式和替换格式

```python
def get_pattern(n):
    '''Generate n parameters pattern'''
    s = [r"([\w \.-]+)", ] * n
    return r'^' + r'\|'.join(s) + r'(#[\w \(\),\.-]*)?$'

def get_substr(n, i, value):
    '''Return the sub string of n-parameter line with i+1-th parameter as value'''
    sublist = ["\\"+str(i+1) for i in range(n)]
    sublist[i] = str(value)
    return ' | '.join(sublist) + ' \\' + str(n+1)
```

还是用前面的两个参数的行(`s`)作为例子, 替换参数的位置记录在字典`params`里, 要替换的参数值记录在字典`new_value`中

```python
s = "2.0  |  1.E-15   # pwm, stctol"
params = {"pwm": (2, 0), "stctol": (2, 1)}
new_value = {"pwm": 5.0, "stctol": 1.0e-20}

for k, nv in new_value.items():
    n, i = params.get(k, (None, None))
    if n is not None:
        pat = get_pattern(n)
        sub = get_substr(n, i, nv)
        s = re.sub(pat, sub, s)
print(s)
# result: "5.0  | 1e-20 # pwm, stctol"
```
