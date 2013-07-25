#!/usr/bin/env bash

$PWD/run-gdb.sh attach $(adb shell b2g-ps | awk '/b2g/ { print $3 }')
