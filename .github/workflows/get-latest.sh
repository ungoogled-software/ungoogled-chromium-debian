#!/bin/bash
# get-latest.sh
#
# Determine the latest version(s) of the "chromium" package in the Debian
# repositories, download the corresponding source package(s), and look for
# matching ungoogled-chromium Git release tags.
#

set -e

test -n "$DOWNLOAD_DIR"
test -n "$STATE_DIR"
test -n "$WORK_DIR"
test -d "$GITHUB_WORKSPACE"

debian_codename_list='bookworm sid'

package=chromium

obsolete_list=$WORK_DIR/obsolete.$package.txt

debian_incoming_url=https://incoming.debian.org/debian-buildd
debian_security_url=https://security.debian.org/debian-security

chdist_dir=$STATE_DIR/chdist-data
chdist="chdist --data-dir=$chdist_dir"
uc_git=$GITHUB_WORKSPACE/ungoogled-chromium

tab='	'

do_update=yes
do_download=yes
do_status=no

todo_flag=	# Note: "false" is interpreted by GitHub as true >_<

export LC_COLLATE=C

while [ -n "$1" ]
do
	case "$1" in
		--skip-update)   do_update=no   ;;
		--skip-download) do_download=no ;;
		--exit-status)   do_status=yes  ;;
		'') ;;
		-*) echo "$0: error: unrecognized option \"$1\"";   exit 1 ;;
		*)  echo "$0: error: unrecognized argument \"$1\""; exit 1 ;;
	esac
	shift
done

if [ ! -d $uc_git ]
then
	echo 'Error: ungoogled-chromium Git repository is not present'
	exit 1
fi

run()
{
	echo "+ $*"
	env "$@"
	echo ' '
}

check_debian_release()
{
	local deb_codename="debian-$1"

	# Latest version of the package in the APT repo
	# (for the specified release, e.g. "unstable" or "bullseye")
	local deb_version=$($chdist apt-get $deb_codename --print-uris source $package 2>/dev/null \
		| awk '/\.dsc /{print $2}' \
		| sed -r 's/^[^_]+_//; s/\.dsc$//')

	if [ -n "$deb_version" ]
	then
		echo "$deb_codename/$package: current package version $deb_version"
	else
		# Note that Debian's incoming repo doesn't always have
		# a given package available; this is not an error
		echo "$deb_codename/$package: no version available"
		echo ' '
		return
	fi

	# Upstream project version (remove the package-revision suffix)
	local ups_version="${deb_version%-*}"
	if [ -z "$ups_version" ]
	then
		echo "error: package version string is bogus"
		exit 1
	fi

	# Latest matching ungoogled-chromium tag
	local uc_tag=$(cd $uc_git && git tag --list --sort=-version:refname "$ups_version-*" | head -n1)

	if [ -n "$uc_tag" ]
	then
		echo "ungoogled-chromium: latest matching tag $uc_tag"
	else
		echo "ungoogled-chromium: no matching tag for $ups_version"
		echo ' '
		return
	fi

	local combo_line="$deb_codename$tab$deb_version$tab$uc_tag"

	# Have we built this combination before?
	if grep -Fqx "$combo_line" $STATE_DIR/done.$package.txt 2>/dev/null
	then
		echo "Already built DEB($deb_codename, $deb_version) + UC($uc_tag)"
		echo ' '
		return
	else
		echo "Will build DEB($deb_codename, $deb_version) + UC($uc_tag)"
	fi

	if [ $do_download = yes ]
	then
		echo ' '
		echo "$deb_codename/$package: downloading source package files"

		(cd $DOWNLOAD_DIR && run $chdist apt-get $deb_codename --quiet --only-source --download-only source $package)
	fi

	echo ' '

	echo "$combo_line" > $WORK_DIR/todo.$deb_codename.$package.txt
	todo_flag=true
}

find_obsolete_files()
{
	: > $obsolete_list

	local keep_count=$(wc -w <<<$debian_codename_list)
	local orig_file

	# We should not need to hang on to more orig source tarballs than
	# the number of codenames we are monitoring

	(cd $DOWNLOAD_DIR && ls -1t ${package}_*.orig.tar.* 2>/dev/null) \
	| tail -n +$((keep_count + 1)) \
	| while read orig_file
	do
		local prefix=${orig_file%.orig.tar.*}

		(cd $DOWNLOAD_DIR && ls -1 $orig_file $prefix-*.dsc $prefix-*.debian.tar.*) \
		>> $obsolete_list
	done
}

#
# First-time setup
#

mkdir -p $DOWNLOAD_DIR $STATE_DIR $chdist_dir
new_apt=no

for codename in $debian_codename_list
do
	deb_codename=debian-$codename
	test ! -d $chdist_dir/$deb_codename || continue
	echo "Initializing APT index for $deb_codename ..."

	case "$deb_codename" in
		debian-sid | debian-unstable)
		run $chdist create $deb_codename $debian_incoming_url buildd-$codename main
		;;

		*)
		run $chdist create $deb_codename $debian_security_url $codename-security main
		;;
	esac

	new_apt=yes
done

if [ $new_apt = yes ]
then
	# We only need deb-src lines, no binary packages
	find $chdist_dir -type f -name sources.list \
		-exec sed -i '/^deb /s/^/#/' {} +
fi

#
# Do version checks
#

for codename in $debian_codename_list
do
	deb_codename=debian-$codename

	if [ $do_update = yes ]
	then
		echo "Updating APT index for $deb_codename ..."
		run $chdist apt-get $deb_codename update --error-on=any
	fi

	check_debian_release $codename
done

find_obsolete_files

if [ -n "$GITHUB_OUTPUT" ]
then
	echo todo=$todo_flag >> $GITHUB_OUTPUT
fi

test $do_status = no || test $todo_flag = true || exit 1
exit 0

# end get-latest.sh
