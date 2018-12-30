# ungoogled-chromium-debian

This repository contains the files to build Debian packages of [ungoogled-chromium](//github.com/Eloston/ungoogled-chromium).

This branch contains the code to build packages for: **Debian 10 (buster)**

## Developer info

### First-time setup

1. Clone this repo
2. Add the remote for Debian as `upstream`:

```sh
git remote add upstream https://salsa.debian.org/chromium-team/chromium.git
```

### Updating this branch

These instructions will update `debian_buster`:

1. Start out by updating the primary branch: `git checkout debian_buster`
2. Pull latest changes for Debian buster (this is currently `master`): `git pull upstream master`
3. Merge changes into other branches as necessary

### Adding a new branch

To add either a primary or secondary branch:

1. Create a new branch that forks off an existing branch with code that is closest to the desired code.
2. Give the branch a name of the format `DISTRO_CODENAME`. For example, Ubuntu 18.10 (cosmic) should have a branch name `ubuntu_cosmic`.
3. Make the necessary changes and commit
4. Submit a Pull Request for your new branch to the branch it is based off of. In the Pull Request, specify the new branch name that should be created. (This is necessary because GitHub doesn't support the creation of branches via PRs)

### Contributing

Contribution guidelines are the same as ungoogled-chromium.

Submit PRs to this repository for every packaging type that should be updated.
