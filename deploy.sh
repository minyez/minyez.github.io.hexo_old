#!/usr/bin/env bash
function generate () {
    hexo clean
    hexo g
    #hexo g
}

# use to hide draft post in _posts dir when deploying
drafts="" # container of drafts
draftsDir="drafts"
postsDir="source/_posts"
cwd=$(pwd)

# static server as default for debugging
if [[ $# == 0 ]]; then
    generate
    hexo s -p 4002
# deploy to gitpages with one argument d
elif [[ $# == 1 ]] && [[ $1 == 'd' ]]; then
    cd "$postsDir" || exit 1
    echo "transfer draft posts tp _draft..."
    for i in ./*.md
    do
        s=$(head -5 "$i" | grep -q '^draft: true'; echo $?)
        if (( s == 0 )); then
            echo "- $i"
            drafts="$drafts $i"
            mv "$i" "$cwd/$draftsDir/"
        fi
    done

    cd ../../
    generate
    hexo d

    echo "transfer draft posts back..."
    for i in $drafts
    do
        echo "+ $i"
        mv "$draftsDir/$i" "$postsDir/"
    done
    echo "done"
fi
