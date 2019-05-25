#!/usr/bin/env bash
generate() {
    hexo clean;
    hexo g;
    hexo g;
}

yml=themes/freemind/_config.yml

# static server as default for debugging
if [[ $# == 0 ]]; then
    # change wordcount to false
    awk '{if($1=="site:")print "  "$1 " false";else print $0}' $yml > ${yml}.tmp
    awk '{if($1=="post:")print "  "$1 " false";else print $0}' $yml > ${yml}.tmp
    mv ${yml}.tmp $yml
    generate
    hexo s -p 4002
# deploy to gitpages with one argument d
elif [[ $# == 1 ]] && [[ $1 == 'd' ]]; then
    # change wordcount to true
    awk '{if($1=="site:")print "  "$1 " true";else print $0}' $yml > ${yml}.tmp
    awk '{if($1=="post:")print "  "$1 " true";else print $0}' $yml > ${yml}.tmp
    mv ${yml}.tmp $yml
    generate
    hexo d
fi
