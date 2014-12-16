#!/usr/bin/env bash

for i in $(git branch -r | grep github); do
    git log -1 --since=-1month $i | grep Date > /dev/null
    if [ $? -eq 1 ]; then
        git push github +:${i##*/}
    fi
done
