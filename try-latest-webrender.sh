#!/usr/bin/env bash

set -eu
set -o pipefail

# This script updates webrender in a mozilla-central repo. It requires the
# companion awk script `latest-webrender.awk` to be in the same folder as
# itself.
#
# The default mode of operation applies the update and does two try pushes, one
# for builds and linux tests; the other for windows tests. For most people this
# is not what you want. But it's what I want, so that's why it's the default.
#
# The mode of operation that is most generally useful is running it with
# PUSH_TO_TRY=0 and SKIP_WIN=1 in the environment, i.e.:
#    SKIP_WIN=1 PUSH_TO_TRY=0 ./try-latest-webrender.sh
# The rest of this documentation refers to this more useful mode of operation.
#
# WARNING: this script may result in dataloss if you run it on repos with
# uncommitted changes, so don't do that. Commit your stuff first!
#
# Requirements:
# 1. You should have two unapplied mq patches in your repo, called "wr-toml-fixup"
#    and "wr-try". You can create these patches like so:
#      hg qnew wr-toml-fixup && hg qnew wr-try && hg qpop -a
#    Note that the order of these patches is important, wr-toml-fixup should be
#    ahead of wr-try in the queue.
#    These patches are markers that allow to inject other custom manual-fixup
#    patches at various points in the update process. Any Cargo.toml fixes need
#    need to go in patches that apply before wr-toml-fixup, and anything else
#    should go between wr-toml-fixup and wr-try.
# 2. Set the environment variables:
#    MOZILLA_SRC -> this should point to your mozilla-central checkout
#    WEBRENDER_SRC -> this should point to your webrender git clone
#    PUSH_TO_TRY -> set this to 0 to skip the try push which otherwise happens
#                   by default.
#    SKIP_WIN -> set this to 1 to skip the windows try push which otherwise
#                happens by default. Note that if this is 0 you need an additional
#                this requires a wr-try-win patch at the end of your queue.
# 3. Set optional environment variables:
#    WR_CSET -> set to a git revision in the WR repo that you want to use as the
#               version to copy. Defaults to master if not set.
#    HG_REV -> set to a hg revision in m-c that you want to use as the base.
#              Defaults to central if not set.
#    AUTOLAND -> set to a hg revision in autoland that you want to use as the
#                base. The default is to not use autoland. This will override
#                HG_REV if set.
#    TMPDIR -> set to a temporary directory. Some temp working files are created
#              into this dir. Defaults to $HOME/tmp

# These should definitely be set
MOZILLA_SRC=${MOZILLA_SRC:-$HOME/zspace/test-mozilla-wr}
WEBRENDER_SRC=${WEBRENDER_SRC:-$HOME/zspace/test-webrender}

# For most general usefulness you will want to override these:
PUSH_TO_TRY=${PUSH_TO_TRY:-1}
SKIP_WIN=${SKIP_WIN:-0}

# These are optional but handy
HG_REV=${HG_REV:-central}
WR_CSET=${WR_CSET:-master}
AUTOLAND=${AUTOLAND:-0}
TMPDIR=${TMPDIR:-$HOME/tmp}
EXTRA_CRATES=${EXTRA_CRATES:-}

mkdir -p $TMPDIR || true

# Useful for cron
echo "Running $0 at $(date)"

# Abort if any mq patches are applied (usually because the last attempt failed)
pushd $MOZILLA_SRC
APPLIED=$(hg qapplied | wc -l)
if [ "$APPLIED" -ne 0 ]; then
    echo "Unclean state, aborting..."
    exit 1
fi

# Delete generated patches from the last time this ran. This may emit a
# warning if the patches don't exist; ignore the warning
hg qrm wr-update-code || true
hg qrm wr-update-lockfile || true
hg qrm wr-revendor || true
hg qrm wr-regen-bindings || true

# Update to desired base rev
hg pull -u m-c
if [ "$AUTOLAND" != "0" ]; then
    echo "Updating to autoland rev $AUTOLAND..."
    hg pull autoland
    hg update "$AUTOLAND"
else
    hg update "$HG_REV"
fi

# Update webrender repo to desired copy rev
pushd $WEBRENDER_SRC
git checkout master
git pull
git checkout $WR_CSET
CSET=$(git log -1 | grep commit | head -n 1)
popd

# Copy over th emain folders
pushd gfx/
rm -rf webrender webrender_traits webrender_api wrench
cp -R $WEBRENDER_SRC/webrender .
if [ -d $WEBRENDER_SRC/webrender_traits ]; then
    TRAITS=traits
elif [ -d $WEBRENDER_SRC/webrender_api ]; then
    TRAITS=api
fi
cp -R $WEBRENDER_SRC/webrender_$TRAITS .
cp -R $WEBRENDER_SRC/wrench .
rm -rf wrench/reftests wrench/benchmarks wrench/script
NUMDIRS=$(find wrench -maxdepth 1 -type d | wc -l)
if [ $NUMDIRS -ne 3 ]; then
    echo "Error: wrench/ has an unexpected number of subfolders!"
    exit 1
fi

# Do magic to update the webrender_bindings/Cargo.toml file with updated
# version numbers for webrender, webrender_api, euclid, app_units, log, etc.
MYSELF=$(readlink -f $0)
AWKSCRIPT=$(dirname $MYSELF)/latest-webrender.awk
WR_VERSION=$(cat webrender/Cargo.toml | awk '/^version/ { print $0; exit }')
WRT_VERSION=$(cat webrender_${TRAITS}/Cargo.toml | awk '/^version/ { print $0; exit }')
RAYON_VERSION=$(cat webrender/Cargo.toml | awk '/^rayon/ { print $0; exit }')
TP_VERSION=$(cat webrender/Cargo.toml | awk '/^thread_profiler/ { print $0; exit }')
EUCLID_VERSION=$(cat webrender_${TRAITS}/Cargo.toml | awk '/^euclid/ { print $0; exit }')
AU_VERSION=$(cat webrender_${TRAITS}/Cargo.toml | awk '/^app_units/ { print $0; exit }')
GLEAM_VERSION=$(cat webrender/Cargo.toml | awk '/^gleam/ { print $0; exit }')
LOG_VERSION=$(cat webrender/Cargo.toml | awk '/^log/ { print $0; exit }')
DWROTE_VERSION=$(cat webrender_${TRAITS}/Cargo.toml | awk '/^dwrote/ { print $0; exit }')
CF_VERSION=$(cat webrender_${TRAITS}/Cargo.toml | awk '/^core-foundation/ { print $0; exit }')
CG_VERSION=$(cat webrender_${TRAITS}/Cargo.toml | awk '/^core-graphics/ { print $0; exit }')
sed -e "s/webrender_traits/webrender_${TRAITS}/g" webrender_bindings/Cargo.toml | awk -f $AWKSCRIPT \
    -v wr_version="${WR_VERSION}" \
    -v wrt_version="${WRT_VERSION}" \
    -v rayon_version="${RAYON_VERSION}" \
    -v tp_version="${TP_VERSION}" \
    -v euclid_version="${EUCLID_VERSION}" \
    -v au_version="${AU_VERSION}" \
    -v gleam_version="${GLEAM_VERSION}" \
    -v log_version="${LOG_VERSION}" \
    -v dwrote_version="${DWROTE_VERSION}" \
    -v cf_version="${CF_VERSION}" \
    -v cg_version="${CG_VERSION}" \
    > $TMPDIR/webrender-bindings-toml
mv $TMPDIR/webrender-bindings-toml webrender_bindings/Cargo.toml
echo $CSET | sed -e "s/commit //" > webrender_bindings/revision.txt
popd

# Save update to mq patch wr-update-code
hg addremove
if [ "$WR_CSET" == "master" ]; then
    hg qnew -m "Update webrender to $CSET" wr-update-code
else
    hg qnew -m "Update webrender to $WR_CSET ($CSET)" wr-update-code
fi

# Advance to wr-toml-fixup, applying any other patches in the queue that are
# in front of it.
hg qgoto wr-toml-fixup

# Run cargo update
# This might fail because of versioning reasons, so we try to detect that
# and run cargo update again with the crates that need bumping. It tries this
# up to 5 times before giving up
for ((i = 0; i < 5; i++)); do
    cargo update -p webrender_${TRAITS} -p webrender ${EXTRA_CRATES} >$TMPDIR/update_output 2>&1 || true
    cat $TMPDIR/update_output
    ADDCRATE=$(cat ${TMPDIR}/update_output | awk '/failed to select a version/ { print $8 }' | tr -d '`')
    if [ -n "$ADDCRATE" ]; then
        echo "Adding crate $ADDCRATE to EXTRA_CRATES"
        export EXTRA_CRATES="$EXTRA_CRATES -p $ADDCRATE"
    else
        break
    fi
done

# Save update to mq patch wr-update-lockfile
hg addremove
hg qnew -m "Update Cargo lockfiles" wr-update-lockfile

# Re-vendor third-party libraries, save to mq patch wr-revendor
./mach vendor rust # --build-peers-said-large-imports-were-ok
hg addremove
hg qnew -m "Re-vendor rust dependencies" wr-revendor

# Regenerate bindings, save to mq patch wr-regen-bindings
rustup run nightly cbindgen toolkit/library/rust --lockfile Cargo.lock --crate webrender_bindings -o gfx/webrender_bindings/webrender_ffi_generated.h
hg qnew -m "Re-generate FFI header" wr-regen-bindings

# Advance to wr-try, applying any other patches in the queue that are in front
# of it. Do try pushes as needed.
hg qgoto wr-try
if [ "$PUSH_TO_TRY" -eq 1 ]; then
    mach try syntax -b do -p macosx64,linux,linux64,win64,linux64-base-toolchains -u all[linux64-qr,windows10-64-qr] -t all[linux64-qr,windows10-64-qr] || echo "Push failure (linux64)"
    if [ "$SKIP_WIN" -eq 0 ]; then
        hg qgoto wr-try-win
        mach try syntax -b do -p win64 -u 'reftest-e10s[Windows 10],reftest-e10s-1[Windows 10],reftest-e10s-2[Windows 10]' -t none --no-retry || echo "Push failure (windows)"
    fi
    hg qpop -a
else
    echo "Skipping push to try because PUSH_TO_TRY != 1"
fi

popd
