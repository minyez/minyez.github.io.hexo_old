---
title: Pandoc学习笔记(二)——使用panflute编写过滤器
categories: Software
comment: True
date: 2019-01-05 22:08:03
tags:
- Pandoc
- Markdown
- Panflute
- AST
- Bootstrap
toc: True
---

## 前言

本文简单介绍了笔者学习通过panflute编写pandoc过滤器的过程, 实现了一个将`#anytag(date, mood)`转化为可用Bootstrap CSS渲染的HTML源码的过滤器.

<!-- more -->

在{% post_link pandoc-md-to-pdf %}一文里我尝试用HTML和LaTeX转化Markdown文本到PDF, 包括用CSS和LaTeX模板自定义PDF输出. 但有时我们需要在转化时对Markdown文本本身进行on-the-fly的修改. 这是仅仅修改样式无法完成的, 需要借助[pandoc过滤器](https://pandoc.org/filters.html)直接修改抽象语义树(abstract syntax tree, AST).

过滤器原则上需要用Haskell写. 对于不会写Haskell的开发人员, jgm老师提供了它的Python包装[pandocfilters](https://github.com/jgm/pandocfilters). 它的一个替代品是[panflute](http://scorreia.com/software/panflute/), 特点是提供了额外的帮助函数, 便于debug等等. 下面过滤器代码都是基于panflute的.

## 学习简单例子

### 强调转删除线

官网上一个将`*x*`强调文字换成`~~x~~`删除线文字

``` python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# filename: emph_so.py
"""
Replace Emph elements with Strikeout elements
"""
from panflute import Emph, Strikeout, run_filter

def action(elem, doc):
    if isinstance(elem, Emph):
        return Strikeout(*elem.content)

def main(doc=None):
    return run_filter(action, doc=doc)

if __name__ == '__main__':
    main()
```

运行

``` bash
$ pandoc sometext.md --filter emph_so.py -t gfm -o filtered.md 
```

下面的文字可作为测试

``` markdown
这里有一句*本来被强调的文字*. 处理后会和这一段~~被删除的文字~~一样.
```

### 删除注释

用的是Panflute GitHub repo里的例子[comments.py](https://github.com/sergiocorreia/panflute/blob/master/examples/panflute/comments.py). 注意原链接17行(这里19行)应该是`el.format`, 而不是`doc.format`. 

``` python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# filename: comments.py
"""
Pandoc filter that causes everything between
'<!-- BEGIN COMMENT -->' and '<!-- END COMMENT -->'
to be ignored.  The comment lines must appear on
lines by themselves, with blank lines surrounding
them.
"""

import panflute as pf
import re

def prepare(doc):
    doc.ignore = False

def comment(el, doc):
    is_relevant = (type(el) == pf.RawBlock) and (el.format == 'html')
    if is_relevant and re.search("<!-- BEGIN COMMENT -->", el.text):
        doc.ignore = True
    if doc.ignore:
        if is_relevant and re.search("<!-- END COMMENT -->", el.text):
            doc.ignore = False
        return []

if __name__ == "__main__":
    pf.toJSONFilter(comment, prepare=prepare)
```

以下文字可供测试：

``` markdown
<!-- BEGIN COMMENT -->

在这里的文字在经过comments.py过滤后会消失. 

<!-- END COMMENT -->
```

### 将所有标题上升一层

自己的原始Markdown笔记都是以h1开始, 这样在LaTeX转化时可以正常转为section. 但Hexo博文正文标题是h2开始的, 因此将原始Markdown笔记转化为Hexo博文中需要修改标题层级结构

```python
#!/usr/local/bin/python3
# -*- coding: utf-8 -*-
# filename: header-up.py
"""
Set headers to 1 level higher. 
Remove h6, and add '.' at the end if there was no '.'
"""

from panflute import Header, Para, run_filter, Block, Str

def action(el, doc):
    if isinstance(el, Header):
        if el.level < 6:
            el.level += 1
        else:
            _contents = el.content
            _lastcont = _contents[-1]
            if isinstance(_lastcont, Str):
                if not _lastcont.text.endswith('.'):
                    _lastcont.text += '.'
            return Para(*el.content)

def main(doc=None):
    return run_filter(action, doc=doc) 

if __name__ == '__main__':
    main()
```

这段代码还处理了h6的特殊情况. 下面的文字可以作为测试

``` markdown
# was a level-1 header

## was a level-2 header

### was a level-3 header

#### was a level-4 header

##### was a level-5 header

###### was a level-6 header
```

## 进阶尝试: 转换`<badge />`

基于上面[删除注释](#删除注释)的例子, 写了一个这样的一个例子, 目的是将`<badge id=id text=text />`形式的HTML文本转换为`<span class="badge badge-id">text</span>`, 后者可以被Bootstrap CSS渲染. 代码如下

``` python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# filename: badge_span.py
"""
Pandoc filter that turns the inline <xxx id=id text=text />
to <span class="xxx xxx-id">text</span>
xxx equals to 'badge, label' currently
text should have no space
"""
import re
import panflute as pf

def extract_id_text(raw_inline):
    '''return (id, string) tuple
    '''
    _ide = ''
    _str = ''
    iden = re.findall('(id=[\"\']?\w+[\"\']?[ ]*[/>]?)', raw_inline)
    text = re.findall('(text=[\"\']?\w+[\"\']?[ ]*[/>]?)', raw_inline)

    if len(iden) != 0:
        if iden[0] != '':
            _ide = iden[0][3:-1].strip()
    if len(text) != 0:
        if text[0] != '':
            _str = text[0][5:-1].strip()

    _ret = [_ide, _str]

    for i, token in enumerate(_ret):
        if token != '':
            if token.startswith(("\'", "\"")):
                _ret[i] = _ret[i][1:]
            if token.endswith(("\'", "\"")):
                _ret[i] = _ret[i][:-1]
    return tuple(_ret)
    

def rawinline_label_badge(el, doc):
    is_rawinline = isinstance(el, pf.RawInline) and (el.format == 'html')
    if is_rawinline:
        if re.match("<label", el.text) or re.match("<badge", el.text):
            __cls = re.findall('(<\w+)', el.text)
            __cls[0] = __cls[0][1:]
            identi, text = extract_id_text(el.text)
            if identi != '':
                __cls.append(__cls[0] + '-' + identi)
            return pf.Span(pf.Str(text), classes=__cls)
    return el


if __name__ == "__main__":
    pf.toJSONFilter(rawinline_label_badge)
```

由于转化基于`RawInline`对象, 所以单独为一行的badge或者label是无法正常转化的. 例如

``` markdown
右侧两个是可以的 <badge id="warn" text="badge-warn"> <badge id="info" text="badge-info">
```

下面有一个单独成行的`badge-danger`是在这个脚本下是渲染不出来的. 

``` markdown
<badge id="danger" text="单独成行的badge-danger">
```

## 过滤器调试

直接用`--filter`选项套用过滤器比较难调试. 可以用以下方法来调试, 其中pandoc输出格式必须作为过滤器的第一个变量声明. 

``` bash
pandoc -t json | ./filter.py latex | pandoc -f json -t latex
```

等价于

``` bash
pandoc --filter./filter.py -f json -t latex
```

也可以使用`convert_text`来检查自己对一段文字的AST的理解

``` python
>>> from panflute import *
>>> tag1 = 'Some #Tag(abc, cde)'
>>> convert_text(tag1)
[Para(Str(Some) Space Str(#Tag(abc,) Space Str(cde)))]
```

## 实际例子: 转化行内带`#`的标签

这个例子的目的是转化`#anytag(date, mood)`到HTML源码

```
<span class="badge badge-tag">#anytag(date, mood)</span>
```

之所以想做这个转化是因为在笔记软件里会用`#tag`做笔记分类, 想在转化时把这个tag转化成bootstrap的徽章, 这样在借助HTML转化时就能用BS渲染标签.

在上面过滤器调试的`tag1`例子里, 我们看到如果`date`和`mod`之间如果有空格时, 上面的tag会转化成两个`[Str Space Str]`. 这个时候就要用到前面`comments.py`中的`doc.ignore`来判断一个标签是否完成, 以及处理中间出现的空间. 

最后的代码如下

``` python
#!/usr/local/bin/python3
# -*- coding: utf-8 -*-
# filename: tag_span.py
"""
Pandoc filter that turns 
   "#XXX(...)" to '<span class="badge badge-warn">#XXX(...)</span>'
and
   "@XXX(...)" to <span class="badge badge-info">@XXX(...)</span>
letters, numbers, comas, underscore, hyphon and space are allowed in the parenthese
"""
import re
import panflute as pf

str_to_replace = ''

def prepare(doc):
    '''ignore represents whether in the tag/people environment
    '''
    doc.ignore = False

def convert_tag_people(el, doc):

    dict_tag_people = {"#": "warn", "@": "info"}

    global str_to_replace
    is_str = isinstance(el, pf.Str)
    if is_str:
        _text = el.text
        if not doc.ignore:
            # outside the tag/people, check if meet a tag/people
            if re.fullmatch("[#@][\w-]+\([\w,-]*\)", _text):
                # direct return the span if the string has both left parenthese and right parenthese
                str_to_replace = ''
                return pf.Span(pf.Str(_text), \
                        classes=["badge", "badge"+'-'+dict_tag_people[_text[0]]])
            if re.fullmatch("[#@][\w-]+", _text):
                # direct return span if the string has noparenthese
                str_to_replace = ''
                return pf.Span(pf.Str(_text), \
                        classes=["badge", "badge"+'-'+dict_tag_people[_text[0]]])
            if re.fullmatch("[#@][\w-]+\([\w,-]*", _text):
                # string with left parenthese in it, but with no right parenthese
                # initialize the str_to_replace
                str_to_replace = _text
                doc.ignore = True
                return []
        else:
            # inside the tag/people, check if the tag/people string ends.
            # Found right parenthese at the end, return the whole string
            if re.fullmatch("[^#@][\w,-]+\)", _text):
                doc.ignore = False
                str_to_replace += _text
                new_Str = pf.Str(str_to_replace)
                return pf.Span(new_Str, \
                        classes=["badge", "badge"+'-'+dict_tag_people[str_to_replace[0]]])

            # no right parenthese found, purge it to str_to_replace, return empty element
            str_to_replace += _text
            return []
    else:
        # Not a normal string. If within the tag/people and is a space, add space to str_to_replace
        # otherwise, just give it back to AST
        if doc.ignore:
            if isinstance(el, pf.Space):
                str_to_replace += ' '
            return []
    return el

if __name__ == "__main__":
    pf.toJSONFilter(convert_tag_people, prepare=prepare)
```

这个脚本里还对`@`开头做进行了同样处理, 在Agenda里它用来代表人名. 尝试转化下面的文字:

```
Tags: #todo , #todo() , #todo(today) , #todo(today, tomorrow)
People: @todo , @todo() , @todo(today) , @todo(today, tomorrow)
```

转化结果

``` markdown
Tags: <span class="badge badge-warn">\#todo</span> ,
<span class="badge badge-warn">\#todo()</span> ,
<span class="badge badge-warn">\#todo(today)</span> ,
<span class="badge badge-warn">\#todo(today, tomorrow)</span>

People: <span class="badge badge-info">@todo</span> ,
<span class="badge badge-info">@todo</span>() ,
<span class="badge badge-info">@todo</span>(today) ,
<span class="badge badge-info">@todo</span>(today, tomorrow)
```

可以看到以`#`为前缀的都正确转化了, 而以`@`前缀的, 含括号的字符串都没有正确转化. 

由于在`re.fullmatch`中`#`和`@`是同样处理的, 出现这种情形只有可能是在`pf.Span`转化字符串时对`#`和`@`做了区别对待. 为了验证, 我们看一下`convert_text`的结果

``` python
>>> md2 = "@todo(today, tomorrow)"
>>> convert_text(md2)
[Para(Cite(Str(@todo)) Str((today,) Space Str(tomorrow)))]
```

可见`Str`对象`@todo`是`Cite`对象的子对象, 跟括号所含字符串对应的`Str`完全分开了, 而我上面的代码没有考虑这个问题. 

## 总结

本文基于panflute编写了几个pandoc过滤器, 用途包括将原始Markdown标题结构转化为适用于Hexo博文的, 将`#tag`形式的标签转化为可用Bootstrap CSS渲染的HTML源码.