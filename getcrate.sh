#!/usr/bin/env bash
USAGE="$0 <crate> <version>"
CRATE=${1?$USAGE}
VERSION=${2?$USAGE}
curl --location https://crates.io/api/v1/crates/${CRATE}/${VERSION}/download > $CRATE.tgz
