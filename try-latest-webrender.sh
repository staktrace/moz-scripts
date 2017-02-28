#!/usr/bin/env bash

set -eu
set -o pipefail

# The test-mozilla-wr repo must have an unapplied mq patch called wr-try which
# is created as follows:
#   hg qnew -m "try: -b do -p macosx64-qr,linux-qr,linux64-qr,win32-qr,win64-qr -u all[linux64-qr] -t none" wr-try
# Any additional patches that you wish to have applied in the try push must be
# above this patch in the patch stack (so that `hg qgoto wr-try` applies them).
MOZILLA_SRC=$HOME/zspace/test-mozilla-wr
WEBRENDER_SRC=$HOME/zspace/test-webrender
MYSELF=$(readlink -f $0)
AWKSCRIPT=$(dirname $MYSELF)/latest-webrender.awk
TMPDIR=$HOME/tmp
PUSH_TO_TRY=${PUSH_TO_TRY:-1}
WR_CSET=${WR_CSET:-master}

echo "Running try-latest-webrender.sh at $(date)"

pushd $MOZILLA_SRC
hg qrm wr-update wr-revendor

hg pull -u graphics

pushd $WEBRENDER_SRC
git pull
git checkout $WR_CSET
CSET=$(git log -1 | grep commit | head -n 1)
popd

pushd gfx/
rm -rf webrender webrender_traits
cp -R $WEBRENDER_SRC/webrender .
cp -R $WEBRENDER_SRC/webrender_traits .

pushd $WEBRENDER_SRC
git checkout master
popd

WR_VERSION=$(cat webrender/Cargo.toml | awk '/^version/ { print $0; exit }')
WRT_VERSION=$(cat webrender_traits/Cargo.toml | awk '/^version/ { print $0; exit }')
awk -f $AWKSCRIPT -v wr_version="${WR_VERSION}" -v wrt_version="${WRT_VERSION}" webrender_bindings/Cargo.toml > $TMPDIR/webrender-bindings-toml
mv $TMPDIR/webrender-bindings-toml webrender_bindings/Cargo.toml
popd

pushd toolkit/library/rust
cargo update -p webrender_traits
popd
pushd toolkit/library/gtest/rust
cargo update -p webrender_traits
popd

hg addremove
hg qnew -m "Update webrender to $CSET" wr-update

./mach vendor rust
hg addremove
hg qnew -m "Re-vendor rust dependencies" wr-revendor

if [ "$PUSH_TO_TRY" -eq 1 ]; then
    hg qgoto wr-try
    hg push -f try -r tip
fi

hg qpop -a

popd
