#!/bin/bash -eu

DEBIAN_ROOT=$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))
ROOT_ROOT=$(dirname "$DEBIAN_ROOT")
UNGOOGLED_REPO=$ROOT_ROOT/ungoogled-chromium

$UNGOOGLED_REPO/devutils/check_patch_files.py -p $DEBIAN_ROOT/patches
