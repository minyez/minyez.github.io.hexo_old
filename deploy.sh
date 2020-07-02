#!/usr/bin/env bash
generate() {
    hexo clean;
    hexo g;
    hexo g;
}

# use to hide draft post in _posts dir when deploying
drafts=""
draftsDir="source/_drafts"
postsDir="source/_posts"
cwd=`pwd`

# static server as default for debugging
if [[ $# == 0 ]]; then
    # change wordcount to false
    generate
    hexo s -p 4002
# deploy to gitpages with one argument d
elif [[ $# == 1 ]] && [[ $1 == 'd' ]]; then
    cd $postsDir
    echo "transfer draft posts tp _draft..."
    for i in $(ls *.md)
    do
        s=`head -5 $i | grep -q '^draft: true'; echo $?`
        if [ $s -eq 0 ]; then
            echo "- $i"
            drafts="$drafts $i"
            mv $i $cwd/$draftsDir/
        fi
    done

    cd ../../
    generate
    hexo d

    echo "transfer draft posts back..."
    for i in $drafts
    do
        echo "+ $i"
        mv $draftsDir/$i $postsDir/
    done
    echo "done"
fi
