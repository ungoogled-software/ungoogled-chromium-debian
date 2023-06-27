#!/bin/bash
#
# This script helps to review the differences between the original
# (Debian) chromium and ungoogled-chromium source package trees, with
# renamed files properly taken into account (unlike what "diff -ru"
# would do). If an ungoogled-chromium project tree is also provided,
# this script will additionally show any changes made to the patches.
#
# Note that this only looks at the files in the debian/ subdirectory,
# because everything else comes from the original upstream source tarball
# and should be exactly the same (provided no patches have been applied).
#

case "$#" in
	2)
	UG_PROJECT=
	ORIG_CHROMIUM="$1"
	UG_CHROMIUM="$2"
	;;

	3)
	UG_PROJECT="$1"
	ORIG_CHROMIUM="$2"
	UG_CHROMIUM="$3"
	;;

	*)
	name=$(basename $0)
	cat <<END
usage: $name ORIG_CHROMIUM UG_CHROMIUM
       $name UG_PROJECT ORIG_CHROMIUM UG_CHROMIUM

ORIG_CHROMIUM = path to original (Debian) chromium source tree
UG_CHROMIUM   = path to ungoogled-chromium source tree
UG_PROJECT    = path to ungoogled-chromium project source tree

Set DIFF_OPTS to pass options to diff(1).
END
	exit 1
	;;
esac

cat <<END
Chromium package source comparison
 original: $ORIG_CHROMIUM
ungoogled: $UG_CHROMIUM

END

export LC_COLLATE=C

(cd "$UG_CHROMIUM" && find debian -type f) \
| sort \
| perl -n \
	-e 'chomp; $dest=$_;' \
	-e '!m,^debian/patches/, and s,/ungoogled-(chromium),/$1,;' \
	-e 'print "$_\t$dest\n"' \
| while read orig_file ug_file
  do
	a="$ORIG_CHROMIUM/$orig_file"
	b="$UG_CHROMIUM/$ug_file"

	if [ -f "$a" ]
	then

		diff -u \
			--label "(original)/$orig_file" \
			--label "(ungoogled)/$ug_file" \
			$DIFF_OPTS \
			"$a" "$b"
	else
		echo "File added: (ungoogled)/$ug_file"
	fi
  done

if [ -d "$UG_PROJECT" ]
then

	cat <<END

===========================================================================

ungoogled-chromium patches comparison:
original: $UG_PROJECT/patches
 package: $UG_CHROMIUM/debian/patches/ungoogled-upstream

END

	(cd "$UG_PROJECT/patches" && find . -type f -printf '%P\n') \
	| sort \
	| while read patch
	  do
		a="$UG_PROJECT/patches/$patch" \
		b="$UG_CHROMIUM/debian/patches/ungoogled-upstream/$patch"

		if [ -f "$b" ]
		then
			diff -u \
				--label "(original)/$patch" \
				--label "(package)/$patch" \
				$DIFF_OPTS \
				"$a" "$b"
		else
			echo "File removed: (package)/$patch"
		fi
	  done
fi

# EOF
