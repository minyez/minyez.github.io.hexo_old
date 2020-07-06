---
title: Hexo笔记(二)——显示博文修改时间等
comment: true
toc: true
date: 2020-06-30 12:12:12
updated: 2020-07-01 12:29:31
tags: [Hexo, Freemind, JavaScript]
categories: Software
---

{% alert success %}
给Freemind主题增加显示博文修改时间的功能. 用hexo-browsersync实现server模式实时预览.
{% endalert %}
<!-- more -->

## 背景

在网上浏览博文的时候, 经常可以看到一些Hexo生成的站点文章有最后修改时间的属性, 所以一直以来都想给自己的博文增加这样的功能. 可惜拖着拖着到现在才想着实践. 原本想着只要在front matter上增加类似`update`属性, 然后修改ejs让它像`date`一样在边栏显示就可以了. 但是这样想的时候出现了一点问题, 因为直接从front matter提取的`update`是字符串, 没有`format`方法, 也不能传给`date()`函数. 在看了一些文章后才知道需要先将其转换为`moment`对象. 那么问题就变成了找到`date`是在哪里变成`moment`对象的即可. 另外还想实现的需求是: 如果front matter有`updated`属性, 则以`updated`为最后修改时间; 如果没有, 则获取文件的最后修改时间.

## 搜索date moment对象化代码

采用正则表达式, `find`和`grep`搜索js文件, 寻找`date`属性的`moment`实例化

```shell
$ find . -regex ".*\.js" | xargs grep -E "moment\(.*date)" --color -RnH
./node_modules/hexo/lib/plugins/helper/date.js:9:  if (!isMoment(date)) date = moment(isDate(date) ? date : new Date(date));
./node_modules/hexo/lib/hexo/post.js:40:  data.date = data.date ? moment(data.date) : moment();
```

可以看到`date`实例化在`post.js`的40行. 接下来在`post.js`中加入如下代码使data获得moment对象`updated`.

```javascript
if (data.updated) {
      data.updated = moment(data.updated);
  }
```

但这样还不能满足我们的要求, 即要求`updated`属性不存在时获取文件最后修改时间, 作为文章最后修改时间. 根据参考资料1, 为获取文件路径, 除了`post.js`中已经引入的`path`外, 需要引入`child_process`库来调用系统的date命令.

```javascript
const execSync = require('child_process').execSync;
```

于是修改上一步中的实例化if语句

```javascript
var lastMod = '';
if (data.updated) {
    data.updated = moment(data.updated);
}
else {
  // 对data.source进行判断, 否则在新建post时会报错
  if (data.source) {
    fp = pathFn.resolve(config.source_dir, data.source);
    lastMod = execSync(`date -r ${fp} "+%Y-%m-%d %H:%M:%S"`).toString().trim();
    data.updated = moment(lastMod);
  }
  else {
    data.updated = data.date;
  }
}
```

这样就使得每一个post对象获得了`updated`属性.

## 修改meta.ejs

得到`updated`属性后, 只要简单修改`layout/_partial/post`下的`meta.ejs`文件即可

```javascript
<!-- date -->
<% if (item.date) { %>
<div class="meta-widget">
<i class="fa fa-clock-o"></i>
<%= item.date.format(config.date_format) %> created
</div>
<% if (item.updated) { %>
 <% if (date(item.date) != date(item.updated)) { %>
    <div class="meta-widget">
    <i class="fa fa-pencil"></i>
    <%= item.updated.format(config.date_format) %> last modified
    </div>
    <% } %>
   <% } %>
<% } %>
```

这里额外要求只有当`date`和`updated`两者日期不同时, 才显示`updated`的时间. 效果如下图所示

![ ](update_time_result.png)

完工 (ง •̀_•́)ง

## Server模式实时预览

每次修改博文都要重新hexo generate再server挺麻烦的. 原来用的[hexo-livereload](https://github.com/hexojs/hexo-livereload)已被归档, 现在可以用[hexo-browsersync](https://github.com/hexojs/hexo-browsersync)

```shell
npm install -g browsersync
npm install hexo-browsersync --save
```

之后再运行server模式. 当md文件有改动时, localhost页面会自动更新.

## 相关文章

{% post_link Hexo-1 %}

## 参考资料

1. [hexo-filter-date-from-git/index.js](https://github.com/xcatliu/hexo-filter-date-from-git/blob/master/index.js)
2. [SO - Print a file's last modified date in Bash](https://stackoverflow.com/a/20807343)
3. [grep 递归指定文件遍历方法](https://blog.csdn.net/dengxu11/article/details/6947078?utm_source=blogxgwz0)
4. [Hexo利用browsersync进行自动刷新](https://blog.singee.me/2018/05/16/hexo/hexo-auto-refresh/)
