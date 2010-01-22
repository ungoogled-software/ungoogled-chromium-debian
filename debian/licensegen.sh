#!/bin/sh

cat debian/copyright.dep5-head > debian/copyright
echo >> debian/copyright
echo "generating main copyright dep-5 format ..."
sh -c "cd build-tree/; ../debian/licensecheck.pl -a src/" >> debian/copyright
echo "generating problem report (see README.copyright ..."
sh -c "cd build-tree/; ../debian/licensecheck.pl src/" >> debian/copyright.problems

echo "appending license details ..."
for i in debian/licenses/LICENSE.*; do
	echo >> debian/copyright
	cat "$i" >> debian/copyright
done

