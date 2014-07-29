#!/usr/bin/env bash
PREFS_JS=$(adb shell echo -n "/data/b2g/mozilla/*.default")/prefs.js
echo "Pulling preferences: $PREFS_JS"
adb pull $PREFS_JS
echo 'user_pref("devtools.debugger.forbid-certified-apps", false);' >> prefs.js
echo "Pushing and restarting"
adb shell stop b2g
adb push prefs.js $PREFS_JS
adb shell start b2g
