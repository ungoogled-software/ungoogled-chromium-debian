#!/bin/sh

. debian/devutils/print_dist.inc

sed \
    -e "s|@BUILD_DIST@|$(print_dist)|" \
    -e "/@PRINT_DIST@/c\\$(sed '$!s|$|\\|' debian/devutils/print_dist.inc)"
