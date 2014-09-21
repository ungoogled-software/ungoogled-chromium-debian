# -*- mode: makefile; coding: utf-8 -*-
# Copyright © 2008, Fabien Tassin <fta@sofaraway.org>
# Description: A class to build scons packages
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
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

_cdbs_scripts_path ?= /usr/lib/cdbs
_cdbs_rules_pat    ?= /usr/share/cdbs/1/rules
_cdbs_class_path   ?= /usr/share/cdbs/1/class

ifndef _cdbs_class_scons
_cdbs_class_scons = 1

SCONS ?= scons

common-build-arch common-build-indep:: debian/stamp-scons-build
debian/stamp-scons-build:
	cd $(DEB_BUILDDIR) && $(DEB_SCONS_ENVVARS) $(SCONS) $(DEB_SCONS_ARGS)
	touch $@

### There's no install rule yet
#common-install-arch common-install-indep:: common-install-impl
#common-install-impl::
#	cd $(DEB_BUILDDIR) && $(DEB_SCONS_ENVVARS) DESTDIR=$(DEB_DESTDIR) $(SCONS) $(DEB_SCONS_INSTALL_ARGS) install

clean::
	cd $(DEB_BUILDDIR) && $(DEB_SCONS_ENVVARS) $(SCONS) $(DEB_SCONS_CLEAN_ARGS) --keep-going --clean || true
	rm -f debian/stamp-scons-build

endif
