#!/usr/bin/env bash
generate() {
    hexo clean;
    hexo g;
    hexo g;
}

# static server as default for debugging
if [[ $# == 0 ]]; then
    # change wordcount to false
    generate
    hexo s -p 4002
# deploy to gitpages with one argument d
elif [[ $# == 1 ]] && [[ $1 == 'd' ]]; then
    # change wordcount to true
    generate
    hexo d
fi
