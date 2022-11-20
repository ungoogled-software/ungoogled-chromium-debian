# ungoogled-chromium-debian (unmaintained)

The debian packaging is currently not maintained.

---

This repository contains files to build Debian packages of
[ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

These are the new unified packaging files which are designed to be built
directly from the git repository and serve as a single set of packaging
files for all Debian or Ubuntu releases newer than the currently oldest
supported release, `Focal`.

Even so we will only be supporting a subset of the available distributions.
These are currently:
- Debian Bullseye
- Debian Sid
- Ubuntu Focal

The only guarantee we will make for support longevity is as follows:
- Debian stable releases will be supported at least until the next stable release is available.
- Ubuntu LTS releases will be supported at least until the next LTS release is available.
- Ubuntu regular releases will be supported until their normal EOL with Ubuntu upstream.

The actual time we decide to drop support for a release after these windows
have elapsed will depend on what we have to gain from doing so. Examples of
reasons we may drop a release include: upgrading to a newer toolchain and
reintroduction of system libraries.

## Getting OBS packages

Use the following instructions to setup your system for our OBS repositories. Make sure to use the one for the correct distribution release for your installation.
- Debian Bullseye
  ```sh
  # echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Bullseye/ /' | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list > /dev/null
  # curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Bullseye/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg > /dev/null
  # sudo apt update
  # sudo apt install -y ungoogled-chromium
  ```
- Debian Sid
  ```sh
  # echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/ /' | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list > /dev/null
  # curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Debian_Sid/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg > /dev/null
  # sudo apt update
  # sudo apt install -y ungoogled-chromium
  ```
- Ubuntu Focal
  ```sh
  # echo 'deb http://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/ /' | sudo tee /etc/apt/sources.list.d/home-ungoogled_chromium.list > /dev/null
  # curl -s 'https://download.opensuse.org/repositories/home:/ungoogled_chromium/Ubuntu_Focal/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home-ungoogled_chromium.gpg > /dev/null
  # sudo apt update
  # sudo apt install -y ungoogled-chromium
  ```

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
