# ungoogled-chromium-debian

This repository contains Debian packaging and patches modified for ungoogled-chromium. Its purpose is to ease merging of updates from Debian's `chromium` package and managing updates between all Debian-based packaging.

**This repository alone cannot build ungoogled-chromium**. These files supplement those in the ungoogled-chromium repo. If you want to build Debian packages, consult the [ungoogled-chromium repo](//github.com/Eloston/ungoogled-chromium).

## Developer info

NOTE: Any changes to `debian` directory files should be made in this repo and pushed (via `sync_debian_repo.py`) to ungoogled-chromium. However, any changes to patches should be made in ungoogled-chromium and pulled (via `sync_debian_repo.py`) into this one.

### First-time setup

1. Install [GitPython](https://pypi.org/project/GitPython/) (`python3-git` in Debian-based systems) version 2.1.8 or newer.
1. Clone this repo
2. Add the remote for Debian as `upstream`:

```sh
git remote add upstream https://salsa.debian.org/chromium-team/chromium.git
```

### Updating instructions

1. Start out by updating the main branch: `git checkout ungoogled_debian_buster`
2. From ungoogled-chromium repo: `./devutils/sync_debian_repo.py push debian_buster path/to/ungoogled-chromium-debian`
3. Commit the new changes 
4. Pull latest changes for Debian buster (this is currently `master`): `git pull upstream master`
5. Merge changes into other branches as necessary (see [Updating a secondary branch](#updating-a-secondary-branch))
6. From ungoogled-chromium repo: `./devutils/sync_debian_repo.py pull path/to/ungoogled-chromium-debian`

#### Updating a secondary branch

To update `ungoogled_debian_stretch`:

1. `git checkout ungoogled_debian_stretch`
2. From ungoogled-chromium repo: `./devutils/sync_debian_repo.py push debian_stretch path/to/ungoogled-chromium-debian`
3. Commit the changes
4. `git merge ungoogled_debian_buster`
5. `git pull upstream stretch`

## Branch info

Current branches and their dependencies:

* `ungoogled_debian_buster`: `upstream/master`
* `ungoogled_debian_stretch`: `ungoogled_debian_buster`, `upstream/stretch`
* `ungoogled_debian_minimal`: `ungoogled_debian_buster`
* `ungoogled_ubuntu_bionic`: `ungoogled_debian_buster`
* `ungoogled_ubuntu_cosmic`: `ungoogled_debian_buster`

All branches with the `ungoogled_` prefix correspond to a:

* packaging type without the prefix
* subdirectory of `patches/` without the prefix

### Contributing

Contribution guidelines are the same as ungoogled-chromium.

Submit PRs to this repository for every packaging type that should be updated.
