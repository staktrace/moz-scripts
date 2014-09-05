#!/usr/bin/env bash

adb forward tcp:6000 localfilesystem:/data/data/org.mozilla.fennec_kats/firefox-debugger-socket
