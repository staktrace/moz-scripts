#!/usr/bin/env bash

if [ "$PWD" != "/Users/kats/zspace/mozilla" ]; then
    echo "Not in right directory!" > /dev/stderr
    exit 1;
fi
hg qtop | grep "^try-"
if [ $? -ne 0 ]; then
    echo "No try command at top of queue!" > /dev/stderr
    exit 2;
fi
hg push -f try -r tip
