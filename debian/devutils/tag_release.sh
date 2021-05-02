#!/bin/sh
set -e

BASE="$(git rev-parse --show-toplevel 2> /dev/null)"
DEBIAN="${BASE}/debian"

if test -z "${BASE}"
then
    echo "BASE directory could not be determined. Aborting."
    exit 1
fi

BRANCH="$(git branch | sed -n '/^* /s;* ;;p')"
TAG="$("${DEBIAN}/devutils/print_tag_version.sh")"

git tag "${TAG}"
git push --atomic origin "${BRANCH}" "${TAG}"
