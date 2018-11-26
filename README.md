# ungoogled-chromium-debian

This repository contains Debian packaging and patches modified for ungoogled-chromium. Its purpose is to ease merging of updates from Debian's `chromium` package and managing updates between all Debian-based packaging.

**This repository alone cannot build ungoogled-chromium**. These files supplement those in the ungoogled-chromium repo. If you want to build Debian packages, consult the [ungoogled-chromium repo](//github.com/Eloston/ungoogled-chromium).

## Developer info

### First-time setup

1. Install [GitPython](https://pypi.org/project/GitPython/) (`python3-git` in Debian-based systems) version 2.1.8 or newer.
1. Clone this repo
2. Add the remote for Debian as `upstream`:

```sh
git remote add upstream https://salsa.debian.org/chromium-team/chromium.git
```

### Guidelines for making changes

* Any changes to `debian` directory files should be made in this repo and "pushed" (via `sync_debian_repo.py`) to ungoogled-chromium
* Any changes to patches should be made in ungoogled-chromium and "pulled" (via `sync_debian_repo.py`) into this one.
* Submit a Pull Request to the repository that was modified first. Then, submit another Pull Request for the second repository after the first Pull Request has been merged.

### Updating branches

There are two kinds of branches in this repository: primary branches, and secondary branches.

* A primary branch is a branch that is used as a base for secondary branches; Therefore, it does not contain `packaging_parent`. It also depends on the upstream branch with the latest changes; e.g. `ungoogled_debian_buster` depends on `upstream/master`.
* A secondary branch is a branch that has a `packaging_parent` file at the root of the branch's file tree. It may also have one or more additional dependencies on an upstream branch, e.g. `upstream/stretch` for `ungoogled_debian_stretch`.

#### Updating a primary branch

These instructions will update `ungoogled_debian_buster`.

1. Start out by updating the primary branch: `git checkout ungoogled_debian_buster`
2. From ungoogled-chromium repo: `./devutils/sync_debian_repo.py push debian_buster path/to/ungoogled-chromium-debian`
3. Commit the new changes 
4. Pull latest changes for Debian buster (this is currently `master`): `git pull upstream master`
5. Merge changes into other branches as necessary (see [Updating a secondary branch](#updating-a-secondary-branch))
6. From ungoogled-chromium repo: `./devutils/sync_debian_repo.py pull path/to/ungoogled-chromium-debian`

#### Updating a secondary branch

These instructions will update `ungoogled_debian_stretch`.

1. `git checkout ungoogled_debian_stretch`
2. From ungoogled-chromium repo: `./devutils/sync_debian_repo.py push debian_stretch path/to/ungoogled-chromium-debian`
3. Commit the changes
4. `git merge ungoogled_debian_buster`
5. `git pull upstream stretch`

### Adding a new branch

To add either a primary or secondary branch:

1. Create a new branch that forks off an existing branch with code that is closest to the desired code.
2. Give the branch a name of the format `ungoogled_DISTRO_CODENAME`. For example, Ubuntu 18.10 (cosmic) should have a branch name `ungoogled_ubuntu_cosmic`.
3. Make the necessary changes and commit
4. Submit a Pull Request for your new branch to the branch it is based off of. In the Pull Request, specify the new branch name that should be created. (This is necessary because GitHub doesn't support the creation of branches via PRs)
4. Once the PR above is merged, run the following from the ungoogled-chromium repo: `./devutils/sync_debian_repo.py pull path/to/ungoogled-chromium-debian`
5. Submit a PR for the changes made in `ungoogled-chromium`.

## Branch info

Current branches and their dependencies:

* `ungoogled_debian_buster`: `upstream/master`
* `ungoogled_debian_stretch`: `ungoogled_debian_buster`, `upstream/stretch`
* `ungoogled_debian_minimal`: `ungoogled_debian_buster`
* `ungoogled_ubuntu_bionic`: `ungoogled_debian_buster`

All branches with the `ungoogled_` prefix correspond to a:

* packaging type without the prefix
* subdirectory of `patches/` without the prefix

### Contributing

Contribution guidelines are the same as ungoogled-chromium.

Submit PRs to this repository for every packaging type that should be updated.
