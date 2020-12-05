# ungoogled-chromium-debian

This is a Debian packaging of [ungoogled-chromium-portablelinux](//github.com/ungoogled-software/ungoogled-chromium-portablelinux). It also enables system-dependent GN flags that require no code changes like VA-API, and a few minor "Debianization" patches.

## Downloads

[Download binaries from the Contributor Binaries website](//ungoogled-software.github.io/ungoogled-chromium-binaries/).

## Installing

**NOTE**: The packages are essentially identical in structure to Debian's `chromium` packages. **As a result, they cannot be installed simultaneously with the distro-provided Chromium package.**

At minimum, you will need to install the `ungoogled-chromium` and `ungoogled-chromium-common` packages:

```sh
# dpkg -i ungoogled-chromium_*.deb ungoogled-chromium-common_*.deb
```

The other packages are as follows:

* `*-driver`: [ChomeDriver](http://chromedriver.chromium.org/)
* `*-l10n`: Localization package for the browser UI.
* `*-sandbox`: [`SUID` Sandbox](https://chromium.googlesource.com/chromium/src/+/lkgr/docs/linux_suid_sandbox.md). This is only necessary if you do not have user namespaces enabled (i.e. kernel parameter `kernel.unprivileged_userns_clone`)
* `*-dbgsym*`: Debug symbols for the associated package.

## Building

Tested on Debian 10 (buster). It will not work on newer Debian versions right now because `python-xcbgen` is not available on them (only `python3-xcbgen`).

1. Add the [the LLVM APT repo](//apt.llvm.org/) for **LLVM 11**.
    * Note that the APT URLs for development (aka nightly snapshot) LLVM versions *do not contain* the LLVM version in them.
2. Run the following commands:

```sh
# Install essential requirements
sudo apt install git python3 packaging-dev equivs

# Clone the repository and switch to unportable variant
git clone https://github.com/ungoogled-software/ungoogled-chromium-debian.git
git switch unportable
git submodule update --init

# NOTE: If you are reading this on GitHub, make sure to read the version corresponding
# to your checkout of this repo (replace TAG_OR_BRANCH_HERE with the tag or branch you want to build):
# https://github.com/ungoogled-software/ungoogled-chromium-debian/blob/TAG_OR_BRANCH_HERE/README.md
#
# Or, just read the README in your local repo.

# (Optional) Replace TAG_HERE with the tag you want to build
# Example of a tag: 79.0.3945.88-1.sid1
# If you omit this step, you will build the latest changes in unportable.
git -C ungoogled-chromium-debian checkout --recurse-submodules TAG_HERE

# Setup build tree under build/
mkdir -p build/src
cp -r ungoogled-chromium-debian/debian build/src/
cd build/src

# Replace UPLOADER_HERE with your uploader string (optional)
# Example of an uploader string: John Doe <johndoe@example.com>
echo 'UPLOADER_HERE' > debian/uploader.txt

# Final setup steps for debian/ directory
./debian/scripts/setup debian

# Install remaining requirements to build Chromium
sudo mk-build-deps -i -r

# Download and unpack Chromium sources (this will take some time)
./debian/scripts/setup local-src

# Start building
dpkg-buildpackage -b -uc
```

## Developing

TODO: Modify instructions from other branches

1. (First-time only) Add Portable Linux remote: `git remote add portablelinux https://github.com/ungoogled-software/ungoogled-chromium-portablelinux.git`
2. Merge new changes from upstream: `git pull --recurse-submodules --no-ff portablelinux master`
3. Refresh existing patches:
	a. `./debian/scripts/setup local-src`
	b. `source debian/devutils/set_quilt_vars.sh`
	c. `cd build/src`
	d. TODO: Clarify quilt commands to run here
4. TODO

## License

See [LICENSE](LICENSE)
