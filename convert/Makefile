# convert/Makefile
# This makefile requires GNU Make.

# Version of and paths to pristine Debian Chromium source tree + tarball,
# obtainable by running "apt-get source chromium" on a Debian system
#
VERSION      = 118.0.5993.70
ORIG_SOURCE  = chromium-$(VERSION)
ORIG_TARBALL = chromium_$(VERSION).orig.tar.xz

# Uncomment this if you wish to modify $(ORIG_SOURCE), otherwise the
# conversion process will operate on a copy.
#
#INPLACE = 1

# Path to local ungoogled-chromium Git repo
# https://github.com/ungoogled-software/ungoogled-chromium
#
UNGOOGLED = $(PWD)/ungoogled-chromium
UNGOOGLED_PATCHES = $(UNGOOGLED)/patches

# Path to convert/ subdir of ungoogled-chromium-debian Git repo
# https://github.com/ungoogled-software/ungoogled-chromium-debian
# (where this makefile comes from)
#
DEBIAN_CONVERT = .

# Append this to the Debian package version string
#
ADD_VERSION_SUFFIX =

# Target distribution (e.g. bookworm, jammy)
# If unset, the distribution will be set to UNRELEASED.
#
DISTRIBUTION = jammy

# Uncomment this if you are converting the Debian stable release of
# Chromium. It sometimes requires (slightly) different settings.
#
#DEBIAN_STABLE = 1

# Package maintainer (i.e. you) contact info
#
export DEBFULLNAME ?= Emmanuel Goldstein
export DEBEMAIL    ?= cereal@example.com

# List of patches to drop from the patch series to avoid conflicts.
# This list should be as short as possible; run the check-patch-drop-list
# target to verify this.
#
PATCH_DROP_LIST =

# More comprehensive disabling in
# ungoogled-upstream/core/ungoogled-chromium/disable-privacy-sandbox.patch
#
PATCH_DROP_LIST += disable/privacy-sandbox.patch

# The edits in this patch are included in
# ungoogled-upstream/core/ungoogled-chromium/fix-building-with-prunned-binaries.patch
#
PATCH_DROP_LIST += disable/tests.patch

# One unapplied edit (inline_login_handler_impl.cc) and one conflicting
# edit (primary_account_manager.cc) vis-a-vis
# ungoogled-upstream/core/ungoogled-chromium/remove-unused-preferences-fields.patch
#
PATCH_DROP_LIST += disable/signin.patch

# Edit is included in
# ungoogled-upstream/extra/inox-patchset/0006-modify-default-prefs.patch
#
PATCH_DROP_LIST += disable/third-party-cookies.patch

# Copy of ungoogled-upstream/core/ungoogled-chromium/disable-web-environment-integrity.patch
#
PATCH_DROP_LIST += ungoogled/core/ungoogled-chromium/disable-web-environment-integrity.patch

# This patch is already applied as disable/google-api-warning.patch
#
PATCH_DROP_LIST += ungoogled-upstream/extra/debian/disable/google-api-warning.patch

ifdef DEBIAN_STABLE
# No additional patches to drop at this time
#PATCH_DROP_LIST +=
endif

# quilt(1) setup
#
QUILT = quilt --quiltrc /dev/null
export QUILT_DIFF_OPTS = -p
export QUILT_PATCHES = debian/patches
export QUILT_REFRESH_ARGS = -p ab --no-index --no-timestamps

TIME = env time -p

orig_changelog = $(ORIG_SOURCE)/debian/changelog
ifneq ($(wildcard $(orig_changelog)),)
debian_version := $(shell dpkg-parsechangelog --file $(orig_changelog) --show-field Version)
ifndef URGENCY
URGENCY := $(shell dpkg-parsechangelog --file $(orig_changelog) --show-field Urgency)
endif
endif

################

work := $(shell pwd)

ifdef INPLACE
ug_source = $(ORIG_SOURCE)
else
ug_source = ungoogled-chromium-src
endif

ug_tarball = ungoogled-chromium_$(VERSION).orig.tar.xz

# These are used to symbolically specify a dependency on a certain
# variant of Chromium source tree
#
orig_tree_dep = $(ORIG_SOURCE)/debian/source/format
ug_tree_dep   = $(ug_source)/debian/source/format

# Avoid weird locale-dependent sort orders
#
export LC_COLLATE = C

# A bit of tooling around quilt(1) to apply all patches and automatically
# refresh the ones which need it (unlike "quilt push -a --refresh", which
# refreshes everything unconditionally)
#
# https://savannah.nongnu.org/bugs/?63986
#
quilt_auto_refresh = \
	while :; do \
		(set -x; $(QUILT) push -a -f -q) | tee tmp.quilt.out; \
		! grep -q 'FAILED -- saving rejects' tmp.quilt.out || exit; \
		if tail -n 1 tmp.quilt.out | grep -q 'forced; needs refresh'; then \
			(set -x; $(QUILT) refresh) || exit; \
		else \
			tail -n 1 tmp.quilt.out | grep -q '^Now at patch' || exit; \
			break; \
		fi; \
	done \
	&& rm -f tmp.quilt.out

################

.PHONY: all
all: convert source-package

.PHONY: convert
convert: stage-5.stamp

.PHONY: source-package
source-package: stage-6.stamp

# Stage 1
#
# * Create a new ungoogled-chromium source tree
# * Copy in the ungoogled-chromium patches
# * Append the ungoogled-chromium patches to the patch series
#
stage-1.stamp: $(orig_tree_dep) series.add
	test ! -f stage-2.stamp
	@$(MAKE) check-git_warning
ifndef INPLACE
# Note: Can't speed this up using hardlinks, alas:
# https://savannah.nongnu.org/bugs/?63994
	rsync -a --delete-after $(ORIG_SOURCE)/ $(ug_source)
endif
	touch $(ug_source)/__UNGOOGLED_CHROMIUM_CONVERSION_INCOMPLETE__
	cp -a $(UNGOOGLED_PATCHES) $(ug_source)/debian/patches/ungoogled-upstream
	rm -f $(ug_source)/debian/patches/ungoogled/series
	cat series.add >>$(ug_source)/debian/patches/series
	touch $@

# Stage 2
#
# * Back out any/all applied patches in the source tree
# * Comment out the patches in PATCH_DROP_LIST from the series
# * Apply and refresh all patches (this should consist mainly of removing
#   u-c hunks that refer to files absent from the Debian tree)
#
# If any patches fail to apply due to file changes, then this rule
# will error out.
#
stage-2.stamp: stage-1.stamp $(new_tree_dep)
	test ! -f stage-3.stamp
	! grep '^#ungoogled#' $(ug_source)/debian/patches/series
	cd $(ug_source) && ($(QUILT) pop -a -f -q || test $$? -eq 2)
	for p in $(PATCH_DROP_LIST); do \
		echo "checking $$p"; \
		grep -Fqx "$$p" $(ug_source)/debian/patches/series || exit; \
	done
	for p in $(PATCH_DROP_LIST); do \
		perl -pi -e '$$a=$$_; chomp($$a); $$a eq "'"$$p"'" and s/^/#ungoogled#/' \
			$(ug_source)/debian/patches/series; \
	done
	cd $(ug_source) && $(quilt_auto_refresh)
	touch $@

stage_3_deps = \
	stage-2.stamp \
	$(new_tree_dep) \
	ungoogled-domain-substitution.sh \
	rules.add

# Stage 3
#
# * Add the domain-substitution script
# * Append ungoogled-chromium section to debian/rules
# * Hook the (un)patch targets into the "build-arch" and "clean" targets
# * Add a line to rename-via-copy the chromedriver binary, as it will
#   be installed in /usr/bin/ and thus cannot keep the original name
# * Update the package changelog
#
stage-3.stamp: $(stage_3_deps)
	test ! -f stage-4.stamp
	cp ungoogled-domain-substitution.sh $(ug_source)/debian/
	cat rules.add >>$(ug_source)/debian/rules

	perl -pi \
		-e '/^override_dh_auto_build-arch:/ and s/$$/ patch/;' \
		-e '/^override_dh_auto_clean:/ and s/$$/ unpatch/' \
		$(ug_source)/debian/rules

	perl -pi -e 'm,^\tcp (out/Release)/chrome_sandbox , and' \
		-e '$$_.="\tcp $$1/chromedriver $$1/ungoogled-chromedriver\n"' \
		$(ug_source)/debian/rules
	grep -q ungoogled-chromedriver $(ug_source)/debian/rules

	test -n '$(debian_version)'
	cd $(ug_source) && debchange \
		--no-conf \
		--package ungoogled-chromium \
		--newversion $(debian_version)$(ADD_VERSION_SUFFIX) \
		--force-bad-version \
		$(if $(DISTRIBUTION),--distribution $(DISTRIBUTION)) \
		$(if $(URGENCY),--urgency $(URGENCY)) \
		--no-auto-nmu \
		'New upstream Debian package release.'

	touch $@

stage_4_deps = \
	stage-3.stamp \
	$(new_tree_dep) \
	$(DEBIAN_CONVERT)/replace-name.pl \
	$(DEBIAN_CONVERT)/editcontrol.pl

# Stage 4
#
# * Modify the files under debian/ to refer to "ungoogled-chromium"
#   instead of "chromium" where appropriate. Note that we have to do
#   this selectively, or else things will break!
# * As a special case, due to being a binary installed in /usr/bin/,
#   "chromedriver" needs to become "ungoogled-chromedriver".
#
stage-4.stamp: $(stage_4_deps)
	test ! -f stage-5.stamp
	perl -pi $(DEBIAN_CONVERT)/replace-name.pl \
		$(ug_source)/debian/*.bug-control \
		$(ug_source)/debian/*.desktop \
		$(ug_source)/debian/*.dirs \
		$(ug_source)/debian/*.install \
		$(ug_source)/debian/*.links \
		$(ug_source)/debian/*.lintian-overrides \
		$(ug_source)/debian/*.manpages \
		$(ug_source)/debian/*.postinst \
		$(ug_source)/debian/*.prerm \
		$(ug_source)/debian/*.xml \
		$(ug_source)/debian/etc/master_preferences \
		$(ug_source)/debian/rules \
		$(ug_source)/debian/scripts/*

	perl -pi -e 's/\b(chromedriver)\b/ungoogled-$$1/' \
		$(ug_source)/debian/chromium-driver.install

	$(DEBIAN_CONVERT)/editcontrol.pl -i \
		-e '$$field =~ /^(Source|Package|Breaks|Depends|Recommends|Replaces|Suggests)$$/ and s/\b(chromium)\b/ungoogled-$$1/g;' \
		-e '$$field eq "Uploaders" and undef $$_;' \
		$(ug_source)/debian/control

	if ! grep '^Maintainer:' $(ug_source)/debian/control | grep -Fq '<$(DEBEMAIL)>'; \
	then \
		$(DEBIAN_CONVERT)/editcontrol.pl -i \
			-e 'if ($$field eq "Maintainer") { set_field("XSBC-Original-Maintainer", $$_); $$_="__UGC_MAINTAINER__"; }' \
			$(ug_source)/debian/control || exit; \
		sed -i 's#__UGC_MAINTAINER__#$(DEBFULLNAME) <$(DEBEMAIL)>#' \
			$(ug_source)/debian/control; \
		sed -i 's/^Xsbc-/XSBC-/' $(ug_source)/debian/control; \
	fi

# Check for any double-replacement snafus
	! grep -ri --exclude-dir=patches ungoogled.ungoogled \
		$(ug_source)/debian

	touch $@

# Stage 5
#
# * Rename all files under debian/ beginning with "chromium" to
#   "ungoogled-chromium", using the file-map script
# * The ungoogled-chromium source conversion is complete
#
stage-5.stamp: stage-4.stamp $(new_tree_dep) debian-file-map.sh
	test ! -f stage-6.stamp
	op1=: op2='mv -fv' \
	debian_a=$(ug_source)/debian \
	debian_b=$(ug_source)/debian \
	sh -e debian-file-map.sh
	rm -f $(ug_source)/__UNGOOGLED_CHROMIUM_CONVERSION_INCOMPLETE__
	touch $@

# Stage 6
#
# * Build the Debian source package
#
stage-6.stamp: stage-5.stamp $(new_tree_dep) $(ug_tarball)
	dpkg-source --abort-on-upstream-changes --build $(ug_source)
	touch $@
	ls -Ll ungoogled-chromium_$(VERSION)*

################

# Addendum to debian/patches/series
#
series.add: $(UNGOOGLED_PATCHES)/series
	(printf '\n#\n# ungoogled-chromium addendum\n#\n\n'; \
	 perl -pe '/^\w/ and s,^,ungoogled-upstream/,' $< \
	) >$@

# Addendum to debian/rules
#
rules.add: $(UNGOOGLED)/flags.gn
	(printf '\n#\n# ungoogled-chromium addendum\n#\n\n'; \
	 perl -p -e 's/"/\\"/g; $$p = ($$.==1) ? "defines+=" : " "x9;' \
		-e 's/(.*)/$$p$$1 \\/' \
		$(UNGOOGLED)/flags.gn; \
	 printf '\npatch:\n'; \
	 printf '\ttest -f   ungoogled-domain-substitution.orig.tar \\\n'; \
	 printf '\t|| debian/ungoogled-domain-substitution.sh\n\n'; \
	 printf 'unpatch:\n'; \
	 printf '\ttest ! -f ungoogled-domain-substitution.orig.tar \\\n'; \
	 printf '\t|| tar xf ungoogled-domain-substitution.orig.tar\n'; \
	 printf '\trm -f     ungoogled-domain-substitution.orig.tar\n' \
	) >$@

# Script that maps files from the original debian/ subdirectory to the
# new one, taking renames into account. The script can be run with the
# following variables set:
#
#   op1 = operation to perform on files which DO NOT change name
#   op2 = operation to perform on files which DO change name
#   debian_a = path to first debian/ subdirectory
#   debian_b = path to second debian/ subdirectory
#
debian-file-map.sh: $(orig_tree_dep)
	(cd $(ORIG_SOURCE) && find debian -type f) \
	| grep -v '^debian/patches/' \
	| sort \
	| perl -n \
		-e 'chomp; s/^/\$$/; $$src=$$_;' \
		-e 's,/(chromium),/ungoogled-$$1,;' \
		-e '$$n = $$_ eq $$src ? "1" : "2";' \
		-e '$$src =~ s/^(.debian)/$${1}_a/;' \
		-e 's/^(.debian)/$${1}_b/;' \
		-e 'print "\$$op$$n\t$$src\t$$_\n"' \
	>$@

# ungoogled-chromium uses the exact same .orig.tar file as chromium,
# so just symlink it
#
$(ug_tarball): $(ORIG_TARBALL)
	ln -s $(ORIG_TARBALL) $(ug_tarball)

.PHONY: ug-tarball
ug-tarball: $(ug_tarball)

################

## Domain substitution

# Script to apply the domain substitutions during the Debian package build
# (invoked from the debian/rules "patch" target)
#
ungoogled-domain-substitution.sh: $(UNGOOGLED)/domain_regex.list domain_substitution.list
	rm -f $@.new
	$(UNGOOGLED)/utils/make_domsub_script.py \
		--regex $(UNGOOGLED)/domain_regex.list \
		--files domain_substitution.list \
		--output $@.new
	perl -pi -e 's/^(backup)=/$$1=ungoogled-/' $@.new
	chmod 755 $@.new
	mv -f $@.new $@

# List of files that, after all the patches have been applied, still
# contain Google-related domain names that need to be neutered.
#
domain_substitution.list: $(UNGOOGLED)/domain_regex.list stage-2.stamp $(new_tree_dep)
	$(UNGOOGLED)/devutils/update_lists.py \
		--pruning pruning.list \
		--domain-substitution $@ \
		--domain-regex $(UNGOOGLED)/domain_regex.list \
		--domain-exclude-prefix .pc/ \
		--domain-exclude-prefix debian/ \
		--no-error-unused \
		--tree $(ug_source)

# Create a tar file containing all the source files modified by the
# domain substitution process.
#
domain_substitution.files.tar: domain_substitution.list stage-2.stamp $(new_tree_dep)
	tar cf - -C $(ug_source) \
		--verbatim-files-from \
		--files-from=$(work)/domain_substitution.list \
		>$@

# Alternate rule to generate a patch containing the domain substitutions
#
# NOTE: The generated patch is huge (over 30 MB!) and hard to review.
# It is better to use the script if at all possible.
#
ungoogled-domain-substitution.patch: domain_substitution.files.tar domain_substitution.list
	mkdir tmp.src.a tmp.src.b
	cd tmp.src.a && tar xf ../domain_substitution.files.tar
	cd tmp.src.b && tar xf ../domain_substitution.files.tar

	$(UNGOOGLED)/utils/domain_substitution.py \
		apply \
		--regex $(UNGOOGLED)/domain_regex.list \
		--files domain_substitution.list \
		tmp.src.b

	! diff -ru tmp.src.a tmp.src.b >tmp.patch
	rm -rf tmp.src.?
	tail -n +2 tmp.patch \
	| perl -pe 'if(/^(---|\+\+\+) /){s/ tmp\.src\./ /;s/\t.*//}' \
	>$@
	rm -f tmp.patch

################

## Checks

# Check that the Git repo containing $(UNGOOGLED_PATCHES) is checked out
# to a commit matching $(VERSION). This ensures that we are using the
# specific revision of the patches intended for the version of Chromium
# being converted here.
#
.PHONY: check-git check-git_warning
check-git check-git_warning: $(UNGOOGLED_PATCHES)/series
	@cd $(UNGOOGLED_PATCHES) && git show -s >/dev/null 2>&1 || exit 0; \
	ucver=`git cat-file --textconv HEAD:chromium_version.txt`; \
	echo; \
	echo 'target Chromium source version: $(VERSION)'; \
	echo "    ungoogled-chromium patches: $$ucver"; \
	echo; \
	if [ '$(VERSION)' = "$$ucver" ]; then echo '==== $@ OK ===='; exit 0; fi; \
	case $@ in \
		*_warning) \
		echo 'Warning: The patches are not matched to this version of Chromium. The conversion process may fail.' | fmt; \
		echo \
		;; \
		*) \
		echo 'Please checkout the appropriate Git tag in the ungoogled-chromium repo containing $(UNGOOGLED_PATCHES)/ .' | fmt; \
		echo; \
		exit 1 \
		;; \
	esac

# Check that every patch listed in PATCH_DROP_LIST needs to be dropped
# in order for the ungoogled-chromium patch series to apply cleanly.
# That is, verify that PATCH_DROP_LIST is minimal, so that we don't drop
# any patches unnecessarily.
#
# (All this does is attempt to apply the combined patch series multiple
# times, each time enabling one of the dropped patches, and verifying
# that the expected conflicts result.)
#
.PHONY: check-patch-drop-list
check-patch-drop-list: stage-2.stamp
	! find $(ug_source) -type f -name \*.rej | grep .
	: >tmp.check-pdl.out
	cd $(ug_source)/debian/patches && cp -p series series.orig
	for p in $(PATCH_DROP_LIST); do \
		(cd $(ug_source) && set -x && $(QUILT) pop -a -f -q); \
		echo "==== checking $$p drop ===="; \
		(cd $(ug_source)/debian/patches && cp -fp series.orig series); \
		perl -pi -e '$$a=$$_; $$a =~ s/^#ungoogled#|\n$$//g; $$a eq "'"$$p"'" and $$_="$$a\n"' \
			$(ug_source)/debian/patches/series; \
		if (cd $(ug_source) && set -x && $(QUILT) push -a -f -q); then \
			echo "==== $$p drop NOT NEEDED ===="; \
			echo "$$p: remove from PATCH_DROP_LIST" >>tmp.check-pdl.out; \
		else \
			echo "==== $$p drop OK ===="; \
		fi; \
	done
	cd $(ug_source)/debian/patches && mv -f series.orig series
	find $(ug_source) -type f -name \*.rej -delete
	cd $(ug_source) && $(QUILT) pop  -a -f -q
	cd $(ug_source) && $(QUILT) push -a -f -q
	@echo; ! grep . tmp.check-pdl.out
	rm -f tmp.check-pdl.out
	@echo '==== $@ OK ===='

check_domsub_deps = \
	domain_substitution.list \
	domain_substitution.files.tar \
	ungoogled-domain-substitution.sh \
	$(UNGOOGLED)/utils/domain_substitution.py

# Check that the modifications made by domain_substitution.py and those
# made by the script created by make_domsub_script.py are identical.
#
.PHONY: check-domsub
check-domsub: $(check_domsub_deps)
	mkdir tmp.src.a tmp.src.b
	cd tmp.src.a && tar xf ../domain_substitution.files.tar
	cd tmp.src.b && tar xf ../domain_substitution.files.tar

	$(TIME) $(UNGOOGLED)/utils/domain_substitution.py \
		apply \
		--regex $(UNGOOGLED)/domain_regex.list \
		--files domain_substitution.list \
		tmp.src.a

	cd tmp.src.b && $(TIME) ../ungoogled-domain-substitution.sh
	rm tmp.src.b/ungoogled-domain-substitution.orig.tar

	diff -ru tmp.src.a tmp.src.b
	rm -rf tmp.src.?
	@echo '==== $@ OK ===='

.PHONY: check
check: check-git check-patch-drop-list check-domsub

# Compare the GN flags used by Debian versus those specified by
# ungoogled-chromium. Each output line is in one of two (tab-separated)
# columns: column 1 has flags that are unique to Debian, column 2 has
# flags that are unique to ungoogled-chromium. Flags that occur
# identically in both projects are not shown.
#
.PHONY: compare-flags
compare-flags: $(ORIG_SOURCE)/debian/rules $(UNGOOGLED)/flags.gn
	printf 'getflags:\n\tfor d in $$(defines); do echo "$$$$d"; done\n\ninclude %s\n' $< >tmp.getflags.mk
	$(MAKE) --silent -f tmp.getflags.mk >tmp.flags-debian.txt
	rm -f tmp.getflags.mk
	sort -u tmp.flags-debian.txt >tmp.flags-debian-s.txt
	sort -u $(UNGOOGLED)/flags.gn >tmp.flags-ungoogled-s.txt
	echo; comm -3 tmp.flags-debian-s.txt tmp.flags-ungoogled-s.txt; echo
	rm -f tmp.flags*.txt

################

.PHONY: unpatch
unpatch:
	cd $(ug_source) && $(QUILT) pop -a -f -q
	rm -rf $(ug_source)/.pc

.PHONY: clean
clean:
	rm -f stage-?.stamp
	rm -f check-domsub.diff
	rm -f debian-file-map.sh
	rm -f domain_substitution.list pruning.list
	rm -f domain_substitution.files.tar
	rm -f rules.add series.add
	rm -f ungoogled-domain-substitution.patch
	rm -f ungoogled-domain-substitution.sh
ifndef KEEP_TREE
	rm -rf ungoogled-chromium-src
endif
# dpkg-source(1) temporary dir
	rm -rf ungoogled-chromium-src.orig.*
	rm -rf tmp.*

.PHONY: clean-more
clean-more: clean
	rm -f ungoogled-chromium_$(VERSION).orig.tar.xz
	rm -f ungoogled-chromium_$(VERSION)-*.debian.tar.xz
	rm -f ungoogled-chromium_$(VERSION)-*.dsc

.DELETE_ON_ERROR:

# end convert/Makefile
