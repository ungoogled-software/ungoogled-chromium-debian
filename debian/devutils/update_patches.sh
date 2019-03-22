#!/bin/bash -eux

DEBIAN_ROOT=$(dirname $(dirname $(readlink -f ${BASH_SOURCE[0]})))
UNGOOGLED_REPO=$DEBIAN_ROOT/ungoogled-upstream/ungoogled-chromium

_command=$1

$UNGOOGLED_REPO/devutils/update_platform_patches.py $_command $DEBIAN_ROOT/patches
