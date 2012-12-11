#!/usr/bin/env bash

adb shell am start -a android.intent.action.VIEW -n org.mozilla.$1/.App -d "}"
