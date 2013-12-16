#!/usr/bin/env bash

$PWD/run-gdb.sh attach $(adb shell b2g-ps | awk "/$1/ { print \$3 }")
