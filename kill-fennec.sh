#!/usr/bin/env bash

adb shell ps | grep fennec_$USER | awk '{print $2}' | xargs adb shell run-as org.mozilla.fennec_$USER kill
