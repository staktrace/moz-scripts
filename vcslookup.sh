#!/usr/bin/env bash

ssh people "grep $1 gecko-mapfile"
if [ $? -ne 0 ]; then
    echo "Re-pulling mapfile..." > /dev/stderr
    ssh people "rm gecko-mapfile && wget --quiet http://people.mozilla.org/~pmoore/vcs2vcs/gecko-dev/gecko-mapfile && grep $1 gecko-mapfile"
fi
