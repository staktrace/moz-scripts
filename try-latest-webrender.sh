#!/usr/bin/env bash

set -eu
set -o pipefail

MOZILLA_SRC=$HOME/zspace/test-mozilla-wr
WEBRENDER_SRC=$HOME/zspace/test-webrender
MYSELF=$(readlink -f $0)
AWKSCRIPT=$(dirname $MYSELF)/latest-webrender.awk
TMPDIR=$HOME/tmp

echo "Running try-latest-webrender.sh at $(date)"

pushd $MOZILLA_SRC

hg pull -u graphics

pushd $WEBRENDER_SRC
git pull
CSET=$(git log -1 | grep commit)
popd

pushd gfx/
rm -rf webrender webrender_traits
cp -R $WEBRENDER_SRC/webrender .
cp -R $WEBRENDER_SRC/webrender_traits .

WR_VERSION=$(cat webrender/Cargo.toml | awk '/^version/ { print $0; exit }')
WRT_VERSION=$(cat webrender_traits/Cargo.toml | awk '/^version/ { print $0; exit }')
awk -f $AWKSCRIPT -v wr_version="${WR_VERSION}" -v wrt_version="${WRT_VERSION}" webrender_bindings/Cargo.toml > $TMPDIR/webrender-bindings-toml
mv $TMPDIR/webrender-bindings-toml webrender_bindings/Cargo.toml
popd

pushd toolkit/library/rust
cargo update -p webrender_bindings --aggressive
popd
pushd toolkit/library/gtest/rust
cargo update -p webrender_bindings --aggressive
popd

hg addremove
hg qnew -m "Update webrender to $CSET" wr-update

./mach vendor rust
hg addremove
hg qnew -m "Re-vendor rust dependencies" wr-revendor

hg qnew -m "try: -b do -p macosx64-qr,linux-qr,linux64-qr,win32-qr,win64-qr -u all[linux64-qr] -t none" wr-try
hg push -f try -r tip

hg qpop -a
hg qser | grep "wr-" | xargs hg qrm

popd
