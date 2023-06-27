# ungoogled-chromium converter for Debian

These scripts will automatically convert a [Debian
Chromium](https://packages.debian.org/testing/chromium) source package into
an equivalent one for
[ungoogled-chromium](https://github.com/ungoogled-software/ungoogled-chromium).

The resulting source package can be compiled into binary `.deb` files, just
like the original. These ungoogled-chromium `.deb` files can be installed
on a system concurrently with the (regular) Chromium ones, as they should
not conflict.

(Note that regular Chromium and ungoogled-chromium cannot be *used*
concurrently, as they rely on the same user configuration.)


## Usage

1. Start with a Debian or Debian-derived system. Ensure that you have the
   necessary prerequisites installed:
   ```
   apt-get install devscripts quilt rsync
   ```

2. Prepare a workspace for the conversion. You can use either the
   `convert/` subdirectory for this, or an empty directory if you
   copy/symlink in the `Makefile` and set the `DEBIAN_CONVERT` variable
   therein to the appropriate location. You'll need at least 8 GB of
   free disk space.

3. Download a `chromium` source package from Debian. If you are on a Debian
   system, running `apt-get source chromium` will suffice. Otherwise, visit
   the Debian [source package
   page](https://packages.debian.org/source/testing/chromium), and download
   the three required files (`.dsc`, `.debian.tar.xz`, `.orig.tar.xz`)
   using the links near the bottom.

4. Clone the ungoogled-chromium [Git
   repo](https://github.com/ungoogled-software/ungoogled-chromium.git), and
   checkout the Git tag that matches the base version of Chromium that you
   downloaded from Debian. (It is important to use a revision of the
   ungoogled-chromium tree that matches the Chromium version.)

   For example, if the source version is `100.0.4896.88`, then you could
   get an appropriate set of patches with `git checkout 100.0.4896.88-1`.
   (The tags used by ungoogled-chromium usually end in `-1`, but if any
   problem is found, new tags ending in `-2`, `-3`, etc. will be created to
   supersede the initial one. Use `git tag --list` to check for these.)

   Note that Debian Chromium package versions can also have a numeric
   suffix like `-1`, but it has nothing to do with the numbering of
   ungoogled-chromium tags. Only the four-part version number of the
   `.orig.tar.xz` source tarball is shared between those two contexts.

5. If the source package is not already unpacked, then do so by running
   `dpkg-source -x chromium_${VERSION}.dsc`.

6. The conversion process is driven primarily by the `Makefile`. Edit the
   variables in the first section of the file to appropriate values.

7. Run `make`, and wait a few minutes for the process to complete.

8. If the process is successful, then you'll see three new
   ungoogled-chromium source-package files (`.dsc`, `.debian.tar.xz`,
   `.orig.tar.xz`) in the workspace. These can be built into binary `.deb`
   files using `dpkg-buildpackage(1)`.

9. If you would like to review the changes that were made by this process,
   the included `compare.sh` script can help in generating diffs between
   the original and converted trees. (Several files are renamed, and won't
   be correlated by a standard recursive diff.)

10. Run `make clean` to clean up intermediate files in the workspace.


## Pitfalls

A few things can go wrong in the conversion process:

* **ungoogled-chromium patches fail to apply.** This is usually due to an
  incompatibility with the Debian patches, either because the same Chromium
  file is being modified in different ways, or ungoogled-chromium adopted
  one of Debian's patches (or vice versa). It can often be resolved by
  adding one or more patches to `PATCH_DROP_LIST`. (Determining which
  patch(es) should be added is left as an exercise for the reader.)

* **`PATCH_DROP_LIST` contains patches not in patch series.** Typically the
  result of either ungoogled-chromium or Debian dropping a patch that is
  still listed in the variable. Just remove it.

* **Not enough disk space.** The Chromium source tree is quite large!
