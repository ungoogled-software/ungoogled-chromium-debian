#!/bin/bash -eu

_debian_dir=$(dirname $(dirname $(readlink -f $0)))
_ungoogled_repo=$_debian_dir/ungoogled-upstream/ungoogled-chromium

printf '%s-%s.%s%s' $(< $_ungoogled_repo/chromium_version.txt) $(< $_ungoogled_repo/revision.txt) $(< $_debian_dir/distro_release.txt) $(< $_debian_dir/distro_revision.txt)
