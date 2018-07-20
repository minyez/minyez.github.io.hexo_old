#!/usr/bin/env bash
generate() {
    hexo clean;
    hexo g;
}

# static as default
if [[ $# == 0 ]]; then
    generate
    hexo s -p 4002
# depoly with one argument d
elif [[ $# == 1 ]] && [[ $1 == 'd' ]]; then
    generate
    hexo d
fi
