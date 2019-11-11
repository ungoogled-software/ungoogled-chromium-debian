# ungoogled-chromium-debian

This repository contains files to build Debian packages of [ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

This branch contains the code to build packages for: **Debian 10 (buster)**

## Downloads

**Binaries** (i.e. `.deb` packages): [Get them from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

If your distro is not listed, you may have a look at the [community-maintained list of packages compatible on other distros](https://github.com/ungoogled-software/ungoogled-chromium-debian/wiki/Compatible-Packages). However, please note that this compatibility is not guarenteed; it may break at any time.

**Source Code**: Use the tags labeled with `buster` via `git checkout` (see building instructions). The branches are for development and may not be stable.

## Installing

**NOTE**: The packages are essentially identical in structure to Debian's `chromium` packages. **As a result, they cannot be installed simultaneously with the distro-provided Chromium package.**

At minimum, you will need to install the `ungoogled-chromium` and `ungoogled-chromium-common` packages. For example:

```sh
# dpkg -i ungoogled-chromium_*.deb ungoogled-chromium-common_*.deb
```

The other packages are as follows:

* `*-driver`: [ChomeDriver](http://chromedriver.chromium.org/)
* `*-l10n`: Localization package for the browser UI.
* `*-sandbox`: [`SUID` Sandbox](https://chromium.googlesource.com/chromium/src/+/lkgr/docs/linux_suid_sandbox.md). This is only necessary if you do not have user namespaces enabled (i.e. kernel parameter `kernel.unprivileged_userns_clone`)
* `*-shell`: Contains `content_shell`. Mainly for browser development/testing; search [the Chromium docs](https://chromium.googlesource.com/chromium/src/+/lkgr/docs/) for more details.
* `*-dbgsym*`: Debug symbols for the associated package.

## Building

```sh
# Install essential requirements
sudo apt install git python3 packaging-dev

# Setup build tree under build/
mkdir -p build/src
git clone --recurse-submodules https://github.com/ungoogled-software/ungoogled-chromium-debian.git
# Replace TAG_OR_BRANCH_HERE with the tag or branch you want to build
git checkout --recurse-submodules TAG_OR_BRANCH_HERE

# NOTE: If you are reading this on GitHub, make sure to read the version corresponding
# to your checkout of this repo (replace TAG_OR_BRANCH_HERE with the tag or branch you want to build):
# https://github.com/ungoogled-software/ungoogled-chromium-debian/blob/TAG_OR_BRANCH_HERE/README.md
#
# Or, just read the README in your local repo.

cp -r ungoogled-chromium-debian/debian build/src/
cd build/src

# Final setup steps for debian/ directory
./debian/rules setup-debian

# Add packages for LLVM 8
# One way to do this is to install from buster-backports:
# 1. Add this line to your /etc/apt/sources.list: deb http://deb.debian.org/debian/ buster-backports main
# 2. Run "apt update"
#
# Another way is to use the APT repo from apt.llvm.org
# 1. Add this line to your /etc/apt/sources.list: deb http://apt.llvm.org/buster/ llvm-toolchain-buster-8 main
# 2. Follow the instructions on https://apt.llvm.org for adding the signing key
# 3. Run "apt update"
#
# You do not need to install LLVM packages yourself, since the next step will do it for you.

# Install remaining requirements to build Chromium
sudo mk-build-deps -i debian/control
rm ungoogled-chromium-build-deps_*.deb

# Download and unpack Chromium sources (this will take some time)
./debian/rules setup-local-src

# Start building
dpkg-buildpackage -b -uc
```

### Restarting the build

If the build aborts during the last command, it can be restarted with this command:

```sh
dpkg-buildpackage -b -uc -nc
```

If it still fails, then try this command (this will clear any intermediate build outputs):

```sh
dpkg-buildpackage -b -uc
```

If all else fails, delete the entire build tree and start again.

### Building via source package

*Build via a Debian source package (i.e. `.dsc`, `.orig.tar.xz`, and `.debian.tar.xz`). This is useful for online build services like Launchpad and openSUSE Build Service.*

First, install base requirements: `# apt install packaging-dev python3`

Then, run the following as a regular user:

```sh
# TODO: Re-use instructions from above
debian/rules get-orig-source
debuild -S -sa
```

(`PACKAGE_TYPE_HERE` is the same as above)

Source package files will appear under `build/`

## Developer info

This section contains information for those contributing to ungoogled-chromium-debian.

### First-time setup

1. Clone this repo
2. Add the remote for Debian as `upstream`:

```sh
git remote add upstream https://salsa.debian.org/chromium-team/chromium.git
```

### Pull new changes from Debian

These instructions will pull in changes from Debian's `chromium` package into `debian_buster`:

```sh
git checkout --recurse-submodules debian_buster
git pull upstream master
# Complete the git merge
# Update patches via instructions below
```

### Pull new changes from ungoogled-chromium

There are two options, which depend on the use case.

1. Update to tag (where `TAG_HERE` is the tag name):

```sh
pushd debian/ungoogled-upstream/ungoogled-chromium/
git fetch
git checkout TAG_HERE
popd
# Commit the submodule changes
# Update patches via instructions below
```

2. Update to HEAD of `master` branch:

```sh
git submodule update --remote
# Commit the submodule changes
# Update patches via instructions below
```

### Updating patches

```sh
./debian/devutils/update_patches.sh merge
source debian/devutils/set_quilt_vars.sh

# Setup Chromium source
mkdir -p build/{src,download_cache}
./debian/ungoogled-upstream/ungoogled-chromium/utils/downloads.py retrieve -i debian/ungoogled-upstream/ungoogled-chromium/downloads.ini -c build/download_cache
./debian/ungoogled-upstream/ungoogled-chromium/utils/downloads.py unpack -i debian/ungoogled-upstream/ungoogled-chromium/downloads.ini -c build/download_cache build/src

cd build/src
# Use quilt to refresh patches. See ungoogled-chromium's docs/developing.md section "Updating patches" for more details
quilt pop -a

# Remove all patches introduced by ungoogled-chromium
./debian/devutils/update_patches.sh unmerge
# Ensure debian/patches/series is formatted correctly, e.g. blank lines

# Sanity checking for consistency in series file
./debian/devutils/check_patch_files.sh

# Remove entries from debian/copyright that are used in patches
./debian/devutils/fix_copyright_excludes.py

# Use git to add changes and commit
```

### Fixing patches when ninja aborts

```sh
# Make sure you are in the build sandbox
cd build/src
./debian/scripts/revert_domainsubstitution
# Debian already applied patches via quilt. Use quilt to modify patches
# Once you are done, copy the patches from build/src/debian/patches
# to this repo's debian/patches
./debian/scripts/apply_domainsubstitution
dpkg-buildpackage -b -uc -nc
```

### Adding a new branch

To add either a primary or secondary branch:

1. Create a new branch that forks off an existing branch with code that is closest to the desired code.
2. Give the branch a name of the format `DISTRO_CODENAME`. For example, Ubuntu 18.10 (cosmic) should have a branch name `ubuntu_cosmic`.
3. Make the necessary changes and commit
4. Submit a Pull Request for your new branch to the branch it is based off of. In the Pull Request, specify the new branch name that should be created. (This is necessary because GitHub doesn't support the creation of branches via PRs)

### Tagging a new version

1. Update the commit or tag version of the ungoogled-chromium repository in `debian/ungoogled-upstream/version.txt` as necessary.
2. Increment the revision in `debian/distro_revision.txt`. However, if the upstream version was changed in Step 1, reset the revision to `1`.
3. Use `git tag` to add a new tag with the name generated from `debian/devutils/print_tag_version.sh`
	* e.g. `git tag -s $(./debian/devutils/print_tag_version.sh)`
	* NOTE: This requires that `debian/ungoogled-upstream/ungoogled-chromium` contains the ungoogled-chromium repo files.

### Notes on updating older branches

If you're going to backport a branch for a newer distro version onto an older distro branch, you will need to either:

1. Try to use the older system library: Change `debian/control` to use an older version and get patches for Chromium to work with the older system library.
2. Use the bundled system library instead:
  1. If you are merging a newer distro's branch into an older distro's branch, and the older distro's branch removed the system library, git may automatically strip out most, if not all, the code to use the system library.
  2. For libraries like ICU or VA-API, there may be commits in the history that added or removed the library (try a search on the commit history). You can try cherry-picking them, or using them as a reference.
  3. Remove the dependency in `debian/control`
  4. Determine the library's name under Chromium's `third_party/` directory. We will refer to this name as `$LIB_NAME` below. Note that there are multiple `third_party` directories; the most common one is at the root of the Chromium source tree. Another one you may see is `base/third_party`. The following instructions still apply regardless of which `third_party` directory you use.
  5. Add `$LIB_NAME` to the `keepers` tuple in `debian/scripts/unbundle`. Also, check for any special removal logic, such as calls to functions `strip` and `remove_file`.
  6. Remove any filepaths including `third_party/$LIB_NAME` in `debian/clean`.
  7. Some libraries may produce additional build outputs (e.g. switching back to bundled ICU). In this scenario, you will need to add the build outputs into the relevant package's `.install` file. See `debian/control` for what the different packages are.
  8. Check for any special rules in `debian/rules` dealing with your library under `third_party/$LIB_NAME`
  9. Remove any entries involving `third_party/$LIB_NAME` from the `Files-Excluded` section of `debian/copyright`
  10. Remove any patches from `debian/patches/` relating to your library.

### Contributing

Contribution guidelines are the same as ungoogled-chromium.

Submit PRs to this repository for every packaging type that should be updated.

## Differences between Debian's Chromium

There are a few differences with Debian's Chromium:

* Modified default CLI flags and preferences; see `debian/etc/default-flags` and `debian/etc/master_preferences`
* Uses LLVM toolchain instead of GCC
* Add flag for VA-API acceleration (`chrome://flags/#disable-accelerated-video-decode`)
* Use GTK3 (Chromium's default) instead of GTK2
* Enable more FFMpeg codecs by default
