#!/usr/bin/env bash

wdk=`pwd`
cd $wdk

# Freemind
npm install hexo-deployer-git --save
npm install hexo-generator-sitemap --save
npm install hexo-generator-feed --save
npm install hexo-generator-search --save
npm install hexo-tag-bootstrap --save
npm install hexo-reference --save
npm install hexo-filter-sub --save
# Use MathJax
npm install hexo-renderer-mathjax --save
# prism highlight
# npm insatll hexo-prism-plugin --save
# rtl support
npm install hexo-tag-rtl --save
# word count
npm install hexo-wordcount --save
npm install -g browsersync
npm install hexo-browsersync --save

# clone theme
cd themes/
git clone git@github.com:minyez/hexo-theme-freemind.git freemind
cd ..

# change the default markdown renderering of escape 
# in node_modules/marked/lib/marked.js
cd node_modules/marked/lib/
sed -i 's/escape: \/^\\\\(\[\\\\`\*{}\\\[\\\]()#+\\-\.!_>\])\/,/escape: \/^\\\\(\[`\*\\\[\\\]()#+\\-\.!_>\])\/,/g' marked.js
cd ../../..
