#!/bin/bash -eu

_debian_dir=$(dirname $(dirname $(readlink -f $0)))
_ungoogled_repo=$_debian_dir/ungoogled-upstream/ungoogled-chromium

printf '%s-%s.focal%s' $(cat $_ungoogled_repo/chromium_version.txt) $(cat $_ungoogled_repo/revision.txt) $(cat $_debian_dir/distro_revision.txt)
