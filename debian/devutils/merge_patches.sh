#!/bin/bash -eux

DEBIAN_ROOT=$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))
UNGOOGLED_REPO=$DEBIAN_ROOT/ungoogled-upstream/ungoogled-chromium

$UNGOOGLED_REPO/utils/patches.py merge -p $DEBIAN_ROOT/patches $UNGOOGLED_REPO/patches
