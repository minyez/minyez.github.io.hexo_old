---
title: 在Hexo博文中嵌入Jupyter notebook
comment: true
toc: true
date: 2019-05-03 13:23:51
tags:
- Hexo
- Jupyter
categories: Softwares
---

## 摘要

尝试在Hexo博文中嵌入Jupyter notebook (`.ipynb`)以展示Python代码 (快速入门到光速入土).

<!--more-->

## 前提准备

首先安装`hexo-jupyter-notebook`和`co`两个npm包, 后者为前者的依赖

```shell
$ npm install hexo-jupyter-notebook --save
$ npm install co
```

像{% post_link embed-videos %}一文中的视频画面一样, 为了将嵌入帧尺寸做成响应式的, 修改`node_modules/hexo-jupyter-notebook/main.py`中的`template`变量, 加入`auto-resizable-iframe`容器

```python
    template = """
<div class="auto-resizable-iframe"><div>
<iframe id='ipynb' marginheight="0" frameborder="0" srcdoc="%s"  style="scrolling:no;">
</iframe></div></div>

<script>

$("#ipynb").load( function() {
console.log($("#ipynb").contents().find("body").find("#notebook"));
document.getElementById('ipynb').height=$("#ipynb").contents().find("#notebook").height()+100;
})
</script> 
    """ % restr.replace("\"", "'")
```

有这一部分后, 我就没有像参考链接里那样用jQuery来控制尺寸. 

再准备好要嵌入的ipynb文件, 准备工作就做好了. 我这里用的是之前练习matplotlib时写的`meshgrid_plot.ipynb`

## 嵌入ipynb

做好上述准备后, 进行下面三步操作

1. 在`_config.yml`中打开`post_asset_folder`
    ```yaml
    post_asset_folder: true
    ```
2. 在`source/assets`中新建`codes`文件夹, 将准备好的ipynb放入其中. 
3. Markdown文本中, 在要嵌入ipynb的位置加入

    ```markdown
    {% asset_jupyter /usr/local/bin/python3 ../../assets/codes/meshgrid_plot.ipynb %}
    ```

嵌入效果如图所示.

![](meshgrid_demo.png)

## 结论

成功利用`hexo-jupyter-notebook`包, 在Hexo博文中嵌入了Jupyter notebook. 然而自己对这个效果不是很满意, 主要是两个原因

1. 嵌入的ipynb代码有滚动条. 修改`iframe`的大小(试到3000px)或修改JS里`+100`为更大数值, 也不能解决.
2. 更关键的, `hexo s`渲染时间显著增加, 从600 ms左右增加到1.34 s. 且持续一段时间后系统明显卡顿, 调试变得更麻烦了.

遂最终放弃了嵌入ipynb的想法  \_(xз」∠)\_

## 参考

[Blogging Jupyter Notebooks (.ipynb) with Hexo on GitHub - Medium](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=2ahUKEwj5-v20yf7hAhUFRqwKHYyID48QFjAAegQIBRAB&url=https%3A%2F%2Fmedium.com%2F%40juanx002%2Fblogging-jupyter-notebooks-ipynb-with-hexo-on-github-7948b72636dc&usg=AOvVaw1xUf2rSePZCUw7anF7uVRu)