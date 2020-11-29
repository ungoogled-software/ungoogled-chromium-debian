#!/bin/bash -eu

_debian_dir=$(dirname $(dirname $(readlink -f $0)))
_root_dir=$(dirname "$_debian_dir")
_ungoogled_repo=$_root_dir/ungoogled-chromium

printf '%s-%s.%s%s' $(cat $_ungoogled_repo/chromium_version.txt) $(cat $_ungoogled_repo/revision.txt) $(cat $_debian_dir/distro_release.txt) $(cat $_root_dir/revision.txt)
