#!/usr/bin/env bash

adb shell am start -n org.mozilla.fennec_$USER/.App -d "$1" -a android.intent.action.VIEW
