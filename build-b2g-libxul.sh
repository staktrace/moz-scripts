#!/usr/bin/env bash

if [ ! -d "objdir-gecko" ]; then
    echo "Error: no objdir-gecko found!" > /dev/stderr
    exit 1
fi

(make -C objdir-gecko/toolkit/library libs \
    && make -C objdir-gecko package
) 2>&1 | tee objdir-gecko/build.log
RET=${PIPESTATUS[0]}

exit $RET
