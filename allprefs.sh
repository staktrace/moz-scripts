#!/usr/bin/env bash

# See https://wiki.mozilla.org/Platform/Platform-specific_build_defines
# for where this all comes from

USAGE="Usage: $0 <firefox|win|mac|osx|linux|mobile|fennec|b2g|all> [-D DEFINE1=VAL1 [-D DEFINE2=VAL2 [...]]]"
TARGET=${1?$USAGE}
PREFS=

if [ "$TARGET" == "firefox" ]; then
   TARGET="browser/app/profile/firefox.js"
   PREFS="-D AB_CD"
elif [ "$TARGET" == "win" ]; then
   TARGET="browser/app/profile/firefox.js"
   PREFS="-D XP_WIN -D AB_CD"
elif [ "$TARGET" == "mac" -o "$TARGET" == "osx" ]; then
   TARGET="browser/app/profile/firefox.js"
   PREFS="-D XP_DARWIN -D XP_MACOSX -D XP_UNIX -D AB_CD"
elif [ "$TARGET" == "linux" ]; then
   TARGET="browser/app/profile/firefox.js"
   PREFS="-D XP_UNIX -D XP_LINUX -D MOZ_WIDGET_GTK -D AB_CD"
elif [ "$TARGET" == "mobile" -o "$TARGET" == "fennec" ]; then
   TARGET="mobile/android/app/mobile.js"
   PREFS="-D XP_UNIX -D XP_LINUX -D ANDROID -D MOZ_WIDGET_ANDROID -D ANDROID_PACKAGE_NAME"
elif [ "$TARGET" == "b2g" ]; then
   TARGET="b2g/app/b2g.js"
   PREFS="-D XP_UNIX -D XP_LINUX -D ANDROID -D MOZ_B2G -D MOZ_WIDGET_GONK -D MOZ_B2G_VERSION -D MOZ_B2G_OS_NAME"
elif [ "$TARGET" == "all" ]; then
    shift;
    for i in firefox win mac linux mobile b2g; do
        $0 $i $* | sed -e "s/^/[$i] /"
    done
    exit 0;
else
    echo $USAGE > /dev/stderr
    exit 1;
fi

if [ ! -f "$TARGET" ]; then
    echo "Could not find $TARGET, are you in the root m-c dir?" > /dev/stderr
    exit 1;
fi

shift

echo "// Using preprocessor options: $PREFS $*"
echo .

(echo "var gPrefs = new Array(); pref = sticky_pref = function(a, b) { gPrefs[a] = b }" &&
 python python/mozbuild/mozbuild/preprocessor.py $PREFS $* modules/libpref/init/all.js &&
 python python/mozbuild/mozbuild/preprocessor.py $PREFS $* $TARGET &&
 echo "for (var x in gPrefs) { print(x + ' => ' + gPrefs[x]); }") | js.$(uname) -
