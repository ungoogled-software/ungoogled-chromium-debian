#!/bin/bash -eu

DEBIAN_ROOT=$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))
UNGOOGLED_REPO=$DEBIAN_ROOT/ungoogled-upstream/ungoogled-chromium

$UNGOOGLED_REPO/devutils/check_patch_files.py -p $DEBIAN_ROOT/patches
