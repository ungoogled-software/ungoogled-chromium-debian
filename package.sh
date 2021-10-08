#!/bin/bash

set -eux

_root_dir=$(dirname $(readlink -f $0))
_chromium_version=$(cat $_root_dir/ungoogled-chromium/chromium_version.txt)
_ungoogled_revision=$(cat $_root_dir/ungoogled-chromium/revision.txt)
_package_revision=$(cat $_root_dir/revision.txt)
_tarprefix=ungoogled-chromium_$_chromium_version-$_ungoogled_revision.${_package_revision}_linux
# Assume source tree is outside this script's directory
_archive_output="$_root_dir/build/$_tarprefix.tar.xz"

"$_root_dir/ungoogled-chromium/utils/filescfg.py" \
	-c "$_root_dir/build/src/chrome/tools/build/linux/FILES.cfg" \
	--build-outputs "$_root_dir/build/src/out/Default" \
	archive \
	-o "$_archive_output" \
	-i "$_root_dir/tar_includes/README"

# NOTE: Forcing use_system_minigbm=false in flags.portable.gn, which is the case on ChromeOS
# Therefore, we are including files according to build/src/chrome/tools/build/chromeos/FILES.cfg
