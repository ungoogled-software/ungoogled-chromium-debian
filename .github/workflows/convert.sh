#!/bin/bash
# convert.sh
#
# Perform the conversion from Chromium to ungoogled-chromium
#

set -e

test -n "$DOWNLOAD_DIR"
test -n "$OUTPUT_DIR"
test -n "$STATE_DIR"
test -n "$WORK_DIR"
test -d "$GITHUB_WORKSPACE"

uc_git=$GITHUB_WORKSPACE/ungoogled-chromium

wrap=

tab='	'

run()
{
	echo "+ $*"
	env "$@"
	echo ' '
}

do_conversion()
{
	local codename="$1" deb_version="$2" uc_tag="$3"
	local conv_dir=$WORK_DIR/convert/$codename

	echo "Using ungoogled-chromium Git tag $uc_tag ..."
	(cd $uc_git && run git switch --detach $uc_tag)

	rm -rf   $conv_dir
	mkdir -p $conv_dir

	echo 'Unpacking source package ...'
	run dpkg-source \
		--no-copy \
		--require-valid-signature \
		--skip-patches \
		--extract \
		$DOWNLOAD_DIR/chromium_$deb_version.dsc \
		$conv_dir/chromium-src

	local uc_rev="${uc_tag##*-}"
	local ucd_convert=$GITHUB_WORKSPACE/convert

	local ups_version="${deb_version%-*}"

	# NOTE: Nested output groups are not yet supported
	# https://github.com/actions/toolkit/issues/1001
	#echo '::group::Ungoogling Chromium'

	(cd $conv_dir && run $wrap make -f $ucd_convert/Makefile \
		convert ug-tarball clean \
		VERSION=$ups_version \
		ORIG_SOURCE=chromium-src \
		ORIG_TARBALL=$DOWNLOAD_DIR/chromium_$ups_version.orig.tar.xz \
		UNGOOGLED=$uc_git \
		DEBIAN_CONVERT=$ucd_convert \
		ADD_VERSION_SUFFIX=.$uc_rev \
		DISTRIBUTION= \
		INPLACE=1
	)

	#echo '::endgroup::'

	echo 'Building new source package ...'
	(cd $conv_dir && run time -p dpkg-source --no-preparation --no-generate-diff --build chromium-src 2>&1)

	local uc_version=$deb_version.$uc_rev

	local files=
	  files="$codename/ungoogled-chromium_$uc_version.dsc"
	files+=" $codename/ungoogled-chromium_$uc_version.debian.tar.xz"
	ofiles=" $codename/ungoogled-chromium_$ups_version.orig.tar.xz"

	mkdir -p $OUTPUT_DIR/$codename

	(cd $conv_dir/..
	 ls -LUl $files $ofiles
	 echo ' '; echo 'SHA-256 sums:'
	 sha256sum $files $ofiles
	 cp -np $files $OUTPUT_DIR/$codename/
	)

	# Note: Do NOT save the .orig tarball as an artifact!
	# It's enormous, and we do not modify it.

	rm -rf $conv_dir
}

for todo in $WORK_DIR/todo.*.chromium.txt
do
	test -f "$todo" || continue
	IFS="$tab" read codename deb_version uc_tag < $todo

	echo "::group::Build DEB($codename, $deb_version) + UC($uc_tag)"

	do_conversion "$codename" "$deb_version" "$uc_tag"

	echo '::endgroup::'

	case "$codename" in
		debian-sid | debian-unstable)
		# do Ubuntu conversions here if desired
		;;
	esac

	cat $todo >> $STATE_DIR/done.chromium.txt
	rm -f $todo
	echo ' '
done

# end convert.sh
