#!/usr/bin/env bash

# Usage:
#  mkdir -p /c/slave/test
#  cd /c/slave/test
#  wget https://raw.githubusercontent.com/staktrace/moz-scripts/master/replicate-run.sh
#  edit as needed
#  run

LOG='https://archive.mozilla.org/pub/firefox/try-builds/kgupta@mozilla.com-bcda71946c858f3b5317fc82ce46c5241f64847c/try-win64/try_win10_64_test-reftest-e10s-bm109-tests1-windows-build2995.txt.gz'

# Scrape log for rev and URLs
wget -Otry_log "$LOG"
REV=$(head -n 5 try_log | awk '/revision:/ { print $2 }')
INSTALLER_URL=$(awk '/installer_url:/ { print $6 }' try_log)
PACKAGES_URL=$(awk '/test_packages_url:/ { print $6 }' try_log)

# Setup phase
wget -Oarchiver_client.py --no-check-certificate --tries=10 --waitretry=3 https://hg.mozilla.org/build/tools/raw-file/default/buildfarm/utils/archiver_client.py
python archiver_client.py mozharness --repo try --rev $REV --destination scripts --debug

# Fixup phase
pushd scripts/mozharness/base/
wget -O - 'https://bug1439744.bmoattachments.org/attachment.cgi?id=8952530' | patch
popd

# Hack up reftests to just run what we want and capture the right things
mkdir test-packages
pushd test-packages
wget -Otarget.test_packages.json "$PACKAGES_URL"
wget -Otarget.common.tests.zip "${PACKAGES_URL%/*}/target.common.tests.zip"
wget -Otarget.reftest.tests.zip "${PACKAGES_URL%/*}/target.reftest.tests.zip"
unzip target.reftest.tests.zip
echo "include reftest-sanity/reftest.list" > reftest/tests/layout/reftests/reftest.list
sed -e 's#\(^.*font-size-24.*$\)#wr-capture wr-capture-ref \1#' --in-place reftest/tests/layout/reftests/reftest-sanity/reftest.list
zip -f -r target.reftest.tests.zip reftest/
popd

# Run in a loop until we hit failures
while true; do
    /c/mozilla-build/python/python2.7.exe '-u' 'scripts/scripts/desktop_unittest.py' '--cfg' 'unittests/win_unittest.py' '--reftest-suite' 'reftest' '--e10s' '--blob-upload-branch' 'try' '--download-symbols' 'ondemand' '--no-read-buildbot-config' '--installer-url' "$INSTALLER_URL" '--test-packages-url' 'file:///c:/slave/test/test-packages/target.test_packages.json' 2>&1 | tee reftest.log
    grep "UNEXPECTED" reftest.log
    if [ $? -eq 0 ]; then
        break;
    fi
done

# Save capture info
zip -r captures.zip build/tests/reftest/wr-capture* reftest.log

# Get it off the loaner
# build/application/firefox/firefox.exe https://staktrace.com/util/paste.php
