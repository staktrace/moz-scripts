#!/usr/bin/env bash

set -eu
set -o pipefail

# The test-mozilla-wr repo must have an unapplied mq patch called wr-try which
# is created as follows:
#   hg qnew -m "try: -b do -p macosx64,linux,linux64,win32,linux64-base-toolchains -u all[linux64-qr] -t none" wr-try
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
APPLIED=$(hg qapplied | wc -l)
if [ "$APPLIED" -ne 0 ]; then
    echo "Unclean state, aborting..."
    exit 1
fi
hg qrm wr-update-code || true
hg qrm wr-update-lockfile || true
hg qrm wr-revendor || true
hg qrm wr-regen-bindings || true

hg pull -u m-c

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
EUCLID_VERSION=$(cat webrender_traits/Cargo.toml | awk '/^euclid/ { print $0; exit }')
AU_VERSION=$(cat webrender_traits/Cargo.toml | awk '/^app_units/ { print $0; exit }')
awk -f $AWKSCRIPT -v wr_version="${WR_VERSION}" -v wrt_version="${WRT_VERSION}" -v euclid_version="${EUCLID_VERSION}" au_version="${AU_VERSION}" webrender_bindings/Cargo.toml > $TMPDIR/webrender-bindings-toml
mv $TMPDIR/webrender-bindings-toml webrender_bindings/Cargo.toml
popd

hg addremove
hg qnew -m "Update webrender to $CSET" wr-update-code

hg qgoto wr-toml-fixup

pushd toolkit/library/rust
cargo update -p webrender_traits -p webrender
popd
pushd toolkit/library/gtest/rust
cargo update -p webrender_traits -p webrender
popd

hg addremove
hg qnew -m "Update Cargo lockfiles" wr-update-lockfile

./mach vendor rust
hg addremove
hg qnew -m "Re-vendor rust dependencies" wr-revendor

cbindgen gfx/webrender_bindings/ -o gfx/webrender_bindings/webrender_ffi_generated.h
hg qnew -m "Re-generate FFI header" wr-regen-bindings

hg qgoto wr-try

if [ "$PUSH_TO_TRY" -eq 1 ]; then
    hg push -f try -r tip || echo "Push failure (linux64)"
    hg qgoto wr-try-win
    hg push -f try -r tip || echo "Push failure (windows)"
    hg qpop -a
else
    echo "Skipping push to try because PUSH_TO_TRY != 1"
fi

popd
