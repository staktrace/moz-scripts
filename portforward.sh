#!/usr/bin/env bash

APP=${1?""}

adb forward tcp:6000 localfilesystem:/data/data/org.mozilla.fennec$APP/firefox-debugger-socket
