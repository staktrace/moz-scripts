#!/usr/bin/env bash

rsync -rl ../out/target/product/mako/system .
rsync -rl ../out/target/product/mako/data .
cp ../out/target/product/mako/boot.img .
mkdir -p META-INF/com/google/android/
cp ../tools/update-tools/bin/gonk/update-binary META-INF/com/google/android/
cat ../rom-scripts/updater-script.head >META-INF/com/google/android/updater-script
find . -type l |
   xargs ls -l |
   awk '{ print "symlink(\"" $11 "\", \"" $9 "\");" }' |
   sed -e 's#"./#"/#' >>META-INF/com/google/android/updater-script
cat ../rom-scripts/updater-script.tail >>META-INF/com/google/android/updater-script
zip -r9 b2g.zip *
java -jar ../prebuilts/sdk/tools/lib/signapk.jar \
            ../build/target/product/security/testkey.x509.pem \
            ../build/target/product/security/testkey.pk8 \
             b2g.zip signed_b2g.zip

echo "Ready to push signed_b2g.zip to sdcard and install using MultiROM"
