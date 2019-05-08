---
title: 在Hexo博文中嵌入视频
date: 2019-05-01 16:18:19
tags:
- Hexo
- Youtube
- bilibili
categories: Software
---

## 摘要

总结了如何用HTML源码在博文中嵌入youtube和bilibili视频, 并通过定义样式表, 统一且响应式的控制视频画面尺寸.

<!--more-->

## Youtube视频

在浏览器中进入想分享的视频, 点击分享, 选择第一个“嵌入”按钮, 就可以得到嵌入博文中所需要的代码, 例如

```html
<iframe width="560" height="315" src="https://www.youtube.com/embed/arj7oStGLkU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
```

## bilibili视频

类似油管视频, 将鼠标移到B站视频下方分享按钮, 就会出来一段嵌入代码

```html
<iframe src="//player.bilibili.com/player.html?aid=16091118&cid=26251892&page=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>
```

## 统一尺寸控制

在Freemind主题下`source/css/style.css`中, 加入以下选择器

```css
.auto-resizable-iframe {
  /*max-width: 540px;*/
  max-width: 100%;
  margin: 0px auto;
}
.auto-resizable-iframe > div {
  position: relative;
  padding-bottom: 75%;
  height: 0px;
}
.auto-resizable-iframe iframe {
  position: absolute;
  top: 0px;
  left: 0px;
  width: 100%;
  height: 100%;
}
```

然后将前面`iframe`放入两层`div`元素里, 最外层元素的类设为`auto-resizable-iframe`, 删除`iframe`中的宽度长度控制, 即

```html
<div class="auto-resizable-iframe">
  <div>
    <iframe src="https://www.youtube.com/embed/arj7oStGLkU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
  </div>
</div>
```

效果如下(Youtube视频)

<div class="auto-resizable-iframe">
  <div>
    <iframe src="https://www.youtube.com/embed/arj7oStGLkU" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
  </div>
</div>

两层div使得画面尺寸是响应式的. 比起直接黏贴iframe稍微麻烦一些, 但是好看的多.

## 存在问题

本来想在这篇博文里也把上面的B站视频嵌入的, 但是插入B站视频的iframe后本地server查看, 发现两个视频都是TED. 问题原因不是很清楚. 所以暂时一篇博文只能插入一个视频了 :(

## 参考

[How To Embed Youtube Videos Within Hexo Blogs](http://www.tangycode.com/How-To-Embed-Youtube-Videos-Within-Hexo-Blogs/)

[在Hexo博客中插入bilibili视频的方式](https://anywaywillgo.github.io/post/writing/hexo/embed-bilibili-video-in-hexo/)
