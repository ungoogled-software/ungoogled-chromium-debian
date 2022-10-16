#!/bin/bash -eux

# Simple build script for Portable Linux
# NOTE: This script will delete all build intermediates every time it runs. Proceed with caution.

_root_dir=$(dirname $(readlink -f $0))
_download_cache="$_root_dir/build/download_cache"
_src_dir="$_root_dir/build/src"
_main_repo="$_root_dir/ungoogled-chromium"

rm -rf "$_src_dir" || true
rm -f "$_root_dir/build/domsubcache.tar.gz" || true
mkdir -p "$_src_dir/out/Default"
mkdir -p "$_download_cache"

"$_main_repo/utils/downloads.py" retrieve -i "$_main_repo/downloads.ini" -c "$_download_cache"
"$_main_repo/utils/downloads.py" unpack -i "$_main_repo/downloads.ini" -c "$_download_cache" "$_src_dir"
"$_main_repo/utils/prune_binaries.py" "$_src_dir" "$_main_repo/pruning.list"
"$_main_repo/utils/patches.py" apply "$_src_dir" "$_main_repo/patches" "$_root_dir/patches"
"$_main_repo/utils/domain_substitution.py" apply -r "$_main_repo/domain_regex.list" -f "$_main_repo/domain_substitution.list" -c "$_root_dir/build/domsubcache.tar.gz" "$_src_dir"
cp "$_main_repo/flags.gn" "$_src_dir/out/Default/args.gn"
cat "$_root_dir/flags.portable.gn" >> "$_src_dir/out/Default/args.gn"

# Set commands or paths to LLVM-provided tools outside the script via 'export ...'
# or before these lines
export LLVM_VERSION=${LLVM_VERSION:=15}
export AR=${AR:=llvm-ar-${LLVM_VERSION}}
export NM=${NM:=llvm-nm-${LLVM_VERSION}}
export CC=${CC:=clang-${LLVM_VERSION}}
export CXX=${CXX:=clang++-${LLVM_VERSION}}
export LLVM_BIN=${LLVM_BIN:=/usr/lib/llvm-${LLVM_VERSION}/bin}
# You may also set CFLAGS, CPPFLAGS, CXXFLAGS, and LDFLAGS
# See build/toolchain/linux/unbundle/ in the Chromium source for more details.
#
# Hack to allow clang to find the default cfi_ignorelist.txt and LLVM tools
# -B<prefix> defined here: https://clang.llvm.org/docs/ClangCommandLineReference.html
_llvm_resource_dir=$("$CC" --print-resource-dir)
export CXXFLAGS+="-resource-dir=${_llvm_resource_dir} -B${LLVM_BIN}"
export CPPFLAGS+="-resource-dir=${_llvm_resource_dir} -B${LLVM_BIN}"
export CFLAGS+="-resource-dir=${_llvm_resource_dir} -B${LLVM_BIN}"

cd "$_src_dir"

./tools/gn/bootstrap/bootstrap.py -o out/Default/gn --skip-generate-buildfiles
./out/Default/gn gen out/Default --fail-on-unused-args
ninja -C out/Default chrome chrome_sandbox chromedriver
