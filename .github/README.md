# ungoogled-chromium-debian (unmaintained)

The debian packaging is currently maintained but version will behind the current ungoogled-chromium version.

---

This repository contains files to build Debian packages of
[ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

These are the new unified packaging files which are designed to be built
directly from the git repository and serve as a single set of packaging
files for all Debian or Ubuntu releases newer than and including the
currently oldest supported release, `Jammy`.

Even so we will only be supporting a subset of the available distributions.
These are currently:
- Debian Sid
- Ubuntu Jammy
- Ubuntu Lunar

All releases shall be supported on a best-effort basis. `x86_64` is the only
architecture we can be reliably test so any other architectures will only be
buildable at best. Older releases may be dropped at any time if they are too
difficult to continue to support due to how bleeding edge Chromium tends to
be.

## Getting OBS packages

We now defer to here:
[OBS Setup Instructions](https://software.opensuse.org//download.html?project=home%3Aungoogled_chromium&package=ungoogled-chromium)

## Building a binary package

```sh
# Install initial packages
sudo apt install -y devscripts equivs

# Clone repository and switch to it (optional if are already in it)
git clone https://github.com/ungoogled-software/ungoogled-chromium-debian.git
cd ungoogled-chromium-debian

# Initiate the submodules (optional if they are already initiated)
git submodule update --init --recursive

# Prepare the local source
debian/rules setup

# Install missing packages
sudo mk-build-deps -i debian/control
rm ungoogled-chromium-build-deps_*

# Build the package
dpkg-buildpackage -b -uc
```
