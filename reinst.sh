#!/usr/bin/env bash

adb uninstall org.mozilla.fennec_$USER
adb install fennec*.apk
