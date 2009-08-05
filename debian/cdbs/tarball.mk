# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2003 Jeff Bailey <jbailey@debian.org>
# Description: A class for Tarball-based packages
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
# 02111-1307 USA.

####
# facilitates unpacking into a directory and setting DEB_SRCDIR and
# DEB_BUILDDIR appropriately.  Note that tarball.mk MUST come
# *FIRST* in the list of included rules.
####

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_path ?= /usr/share/cdbs/1/rules
_cdbs_class_path ?= /usr/share/cdbs/1/class

ifndef _cdbs_rules_tarball
_cdbs_rules_tarball = 1

include $(_cdbs_rules_path)/buildcore.mk$(_cdbs_makefile_suffix)

# The user developper may override this variable to choose which tarballs
# to unpack.

ifeq ($(DEB_TAR_SRCDIR),)
$(error DEB_TAR_SRCDIR must be specified)
endif

_cdbs_tarball_dir = build-tree

DEB_SRCDIR = $(_cdbs_tarball_dir)/$(DEB_TAR_SRCDIR)
DEB_BUILDDIR ?= $(DEB_SRCDIR)

# This is not my finest piece of work.
# Essentially, it's never right to unpack a tarball more than once
# so we have to emit stamps.  The stamps then have to be the rule
# we use.  Then we have to figure out what file we're working on
# based on the stamp name.  Also, tar-gzip archives can be either
# .tar.gz or .tgz.  tar-bzip archives can be either tar.bz or tar.bz2
# tar-lzma archives can be either tar.7z or tar.lzma

_cdbs_tarball_stamps = $(addprefix debian/stamp-,$(notdir $(DEB_TARBALL)))
_cdbs_tarball_stamp_base = $(basename $(_cdbs_tarball_stamps))

ifeq ($(DEB_VERBOSE_ALL),yes)
_cdbs_tar_verbose = -v
endif

pre-build:: $(_cdbs_tarball_stamps)
ifneq (, $(config_guess_tar))
	if test -e /usr/share/misc/config.guess ; then \
		for i in $(config_guess_tar) ; do \
			cp --remove-destination /usr/share/misc/config.guess \
			$(_cdbs_tarball_dir)/$$i ; \
		done ; \
	fi
endif
ifneq (, $(config_sub_tar))
	if test -e /usr/share/misc/config.sub ; then \
		for i in $(config_sub_tar) ; do \
			cp --remove-destination /usr/share/misc/config.sub \
			$(_cdbs_tarball_dir)/$$i ; \
		done ; \
	fi
endif
ifneq (, $(config_rpath_tar))
	if test -e /usr/share/gnulib/config/config.rpath ; then \
		for i in $(config_rpath_tar) ; do \
			cp --remove-destination /usr/share/gnulib/config/config.rpath \
			$(_cdbs_tarball_dir)/$$i ; \
		done ; \
	fi
endif

_cdbs_stampname_to_tarname = $(filter $(patsubst stamp-%,%,$(notdir $(1))) %/$(patsubst stamp-%,%,$(notdir $(1))),$(DEB_TARBALL))

$(addsuffix .tar,$(_cdbs_tarball_stamp_base)):
	tar -C $(_cdbs_tarball_dir) $(_cdbs_tar_verbose) -x -f $(call _cdbs_stampname_to_tarname,$@)
	touch $@

$(addsuffix .gz,$(_cdbs_tarball_stamp_base)) $(addsuffix .tgz,$(_cdbs_tarball_stamp_base)):
	tar -C $(_cdbs_tarball_dir) $(_cdbs_tar_verbose) -x -z -f $(call _cdbs_stampname_to_tarname,$@)
	touch $@

$(addsuffix .bz,$(_cdbs_tarball_stamp_base)) $(addsuffix .bz2,$(_cdbs_tarball_stamp_base)):
	tar -C $(_cdbs_tarball_dir) $(_cdbs_tar_verbose) -x -j -f $(call _cdbs_stampname_to_tarname,$@)
	touch $@

$(addsuffix .7z,$(_cdbs_tarball_stamp_base)) $(addsuffix .lzma,$(_cdbs_tarball_stamp_base)):
	# Hardy's tar doesn't support lzma
	# tar -C $(_cdbs_tarball_dir) $(_cdbs_tar_verbose) -x --lzma -f $(call _cdbs_stampname_to_tarname,$@)
	lzma -dkc $(call _cdbs_stampname_to_tarname,$@) | ( cd $(_cdbs_tarball_dir) ; tar xf - )
	touch $@

$(addsuffix .zip,$(_cdbs_tarball_stamp_base)):
	unzip $(call _cdbs_stampname_to_tarname,$@) -d $(_cdbs_tarball_dir)
	touch $@

cleanbuilddir::
	rm -rf $(_cdbs_tarball_dir)
	rm -f $(_cdbs_tarball_stamps)
	rm -f debian/stamp-patch-*
	rm -rf debian/patched

endif
