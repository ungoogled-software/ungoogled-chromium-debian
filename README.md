# ungoogled-chromium-debian

This is a Debian packaging of [ungoogled-chromium-portablelinux](//github.com/ungoogled-software/ungoogled-chromium-portablelinux). It also enables system-dependent GN flags that require no code changes like VA-API, and a few minor "Debianization" patches.

## Downloads

[Download binaries from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

## Building

TODO: Copy any other necessary info from other branches

Tested on Debian 10 (buster). It will not work on newer Debian versions right now because `python-xcbgen` is not available on them (only `python3-xcbgen`).

1. Add the [the LLVM APT repo](//apt.llvm.org/) for **LLVM 11**.
    * Note that the APT URLs for development (aka nightly snapshot) LLVM versions *do not contain* the LLVM version in them.
2. Run the following commands:

```sh
git pull --recurse-submodules https://github.com/ungoogled-software/ungoogled-chromium-debian.git
git switch unportable
./debian/scripts/setup debian
./debian/scripts/setup local-src
mk-build-deps  # To install dependencies
dpkg-buildpackage -b -uc
```

## Developing

TODO: Modify instructions from other branches

## License

See [LICENSE](LICENSE)

---

# ungoogled-chromium-portablelinux

Portable Linux (i.e. a generic Linux version) packaging for [ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

Portable Linux builds can run on **any Linux distribution** (that regular Chromium supports).

## Downloads

[Download binaries from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

**Source Code**: It is recommended to use a tag via `git checkout` (see building instructions below). You may also use `master`, but it is for development and may not be stable.

## Installing the binaries

1. Unpack the downloaded `tar` archive to any location, such as `/opt`:
    ```sh
    # tar -xvf ungoogled-chromium_xxxxxxx.tar.xz -C /opt
    ```
2. Follow the instructions in `/opt/ungoogled-chromium_xxxxxxx/README`

## Building

These instructions will build packages compatible with any Linux distribution that Chromium supports. They are portable and have minimal dependencies on system libraries (just as in regular Chromium).

### Hardware requirements

* For 64-bit systems, at least 8 GB of RAM is highly recommended (per the document in the Chromium source tree under `docs/linux_build_instructions.md`).
    * To reduce RAM consumption, set the GN flag `jumbo_file_merge_limit` with a lower value (documented in the Chromium source code under `docs/jumbo.md`). `50` is a normal setting, while `8` will conserve more RAM.
* At least 8 GB of filesystem space. 16 GB should be safe.

### Software requirements

TODO: Document all libraries and tools needed to build. For now, see the build dependencies for Debian systems.

* Python 3 (tested on 3.5) for ungoogled-chromium's utilities
* Python 2 (tested on 2.7) for building GN and running other build-time scripts
* [Ninja](//ninja-build.org/) for running the build command
* One of the following LLVM toolchain versions, in descending order of preference (which must include Clang and LLD):
    1. A build of the LLVM revision used by Google to build Chromium. This is specified in the Chromium source tree under `tools/clang/scripts/update.py` in the constant `CLANG_REVISION`. (For more info about how Google manages its prebuilt LLVM toolchain, see the file in the Chromium source tree `docs/updating_clang.md`)
    2. The latest *stable* LLVM version (not development/trunk!)
    3. A nightly snapshot LLVM build, available from [the LLVM apt repo](//apt.llvm.org). For best results, the branch version should match the current stable LLVM version (e.g. if the current stable is 8.0.1, use branch version 8)

    **However, make sure to note the following**:

    * Any other LLVM version may outright fail, or [cause unexpected behavior](//github.com/Eloston/ungoogled-chromium/issues/586).
    * on Debian-based systems, installing LLVM from the distro's repo and from `apt.llvm.org` may cause conflicts. To ensure correctness, make sure to only have one or the other installed. For example, [Clang could use the wrong linker](https://github.com/ungoogled-software/ungoogled-chromium-portablelinux/issues/21).
* Node.js

For Debian-based systems:

1. Add the [the LLVM APT repo](//apt.llvm.org/) for the appropriate LLVM version (e.g. the latest stable).
    * Note that the APT URLs for development (aka nightly snapshot) LLVM versions *do not contain* the LLVM version in them.
2. Install LLVM (version 10 shown) and other build dependencies: `# apt install clang-10 lld-10 llvm-10-dev python python3 ninja-build nodejs`

### Build a tar archive

First clone the repository and choose the right tag or branch

```sh
git clone --recurse-submodules https://github.com/ungoogled-software/ungoogled-chromium-portablelinux.git
cd ungoogled-chromium-portablelinux
# Replace TAG_OR_BRANCH_HERE with a tag or branch name
git checkout --recurse-submodules TAG_OR_BRANCH_HERE
```

Then run a normal build

```sh
# Use "export ..." for AR, NM, CC, CXX, or others to specify the compiler to use
# It defaults to LLVM tools. See build.sh for more details
./build.sh
./package.sh
```

Or run a build inside a docker container

```sh
./docker-build.sh
```

A compressed tar archive will appear under `build`

**NOTE**: If the build fails, you must take additional steps before re-running the build:

* If the build fails while downloading the Chromium source code (during `build.sh`), it can be fixed by removing `build/download_cache` and re-running the build instructions.
* If the build fails at any other point after downloading, it can be fixed by removing `build/src` and re-running the build instructions. This will clear out all the code used by the build, and any files generated by the build.

### Building an AppImage

Software requirements:

* desktop-file-utils
* libglib2.0-dev
* binutils

First, follow the instructions in [Build a tar archive](#build-a-tar-archive).

Then, run the following:

```
./package.appimage.sh
```

An `.AppImage` file will appear under `AppImages/out`

## Developer info

### Updating patches

```sh
./devutils/update_patches.sh merge
source devutils/set_quilt_vars.sh

# Setup Chromium source
mkdir -p build/{src,download_cache}
./ungoogled-chromium/utils/downloads.py retrieve -i ungoogled-chromium/downloads.ini -c build/download_cache
./ungoogled-chromium/utils/downloads.py unpack -i ungoogled-chromium/downloads.ini -c build/download_cache build/src

cd build/src
# Use quilt to refresh patches. See ungoogled-chromium's docs/developing.md section "Updating patches" for more details
quilt pop -a

cd ../../
# Remove all patches introduced by ungoogled-chromium
./devutils/update_patches.sh unmerge
# Ensure patches/series is formatted correctly, e.g. blank lines

# Sanity checking for consistency in series file
./devutils/check_patch_files.sh

# Use git to add changes and commit
```

## License

See [LICENSE](LICENSE)
