#!/bin/sh
set -e

RT_DIR="$PWD"
DB_DIR="$RT_DIR/debian"
UC_DIR="$DB_DIR/submodules/ungoogled-chromium"

for i in OBS_API_USERNAME OBS_API_PASSWORD
do
    if test -z "$(eval echo \$$i)"
    then
        echo "$i is not in the environment. Aborting."
        exit 1
    fi
done

PROJECT="${OBS_API_PROJECT:-home:$OBS_API_USERNAME}"

case "$GITHUB_EVENT_NAME" in
    workflow_dispatch) REPOSITORY="$PROJECT:testing" ;;
    push) REPOSITORY="$PROJECT" ;;
    *) echo "Not running as part of a GitHub workflow. Aborting."; exit 1 ;;
esac

curl()
{
    for i in `seq 1 5`
    do
        {
            command curl -sS -K - "$@" << EOF
user="$OBS_API_USERNAME:$OBS_API_PASSWORD"
EOF
        } && return 0 || sleep 30s
    done
    return 1
}

debian/rules changelog control

read UC_VERSION < $UC_DIR/chromium_version.txt
AUTHOR=`grep 'AUTHOR *:=' $DB_DIR/rules | cut -f 2 -d '=' | sed -r 's;^ *| *$;;g'`
NODE_VERSION=`grep 'NODE_VERSION *:=' $DB_DIR/rules | cut -f 2 -d '=' | sed -r 's;^ *| *$;;g'`

cat > _service << EOF
<services>
    <service name="download_url">
        <param name="url">https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$UC_VERSION.tar.xz</param>
    </service>
    <service name="download_url">
        <param name="url">https://commondatastorage.googleapis.com/chromium-browser-official/chromium-$UC_VERSION.tar.xz.hashes</param>
    </service>
    <service name="download_url">
        <param name="url">https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-x64.tar.xz</param>
    </service>
    <service name="download_url">
        <param name="url">https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-armv7l.tar.xz</param>
    </service>
    <service name="download_url">
        <param name="url">https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-linux-arm64.tar.xz</param>
    </service>
    <service name="download_url">
        <param name="url">https://nodejs.org/dist/$NODE_VERSION/SHASUMS256.txt</param>
        <param name="filename">node-$NODE_VERSION.sha256sum</param>
    </service>
</services>
EOF

tar -c -T/dev/null | xz -9 > ungoogled-chromium_$UC_VERSION.orig.tar.xz
tar -c -T/dev/null | xz -9 > ungoogled-chromium_$UC_VERSION.debian.tar.xz
tar -c --exclude-vcs --exclude='download_cache/*' -C $RT_DIR debian/ | xz -9 > ungoogled-chromium.tar.xz

cat > ungoogled-chromium.dsc << EOF
Format: 3.0 (quilt)
Source: ungoogled-chromium
Binary: ungoogled-chromium
Architecture: any
Version: $UC_VERSION
Maintainer: $AUTHOR
Homepage: https://github.com/Eloston/ungoogled-chromium
Standards-Version: 4.5.0
Build-Depends: $(sed -n '/^Build-Depends:/,/^$/p' < $DB_DIR/control | tr -d '\n' | cut -f 2 -d : | sed -r 's;^ *| *$;;g')
Package-List:
 ungoogled-chromium deb web optional arch=any
Checksums-Sha1:
 $(sha1sum < ungoogled-chromium_$UC_VERSION.orig.tar.xz | cut -f 1 -d ' ') $(stat -c '%s' ungoogled-chromium_$UC_VERSION.orig.tar.xz) ungoogled-chromium_$UC_VERSION.orig.tar.xz
 $(sha1sum < ungoogled-chromium_$UC_VERSION.debian.tar.xz | cut -f 1 -d ' ') $(stat -c '%s' ungoogled-chromium_$UC_VERSION.debian.tar.xz) ungoogled-chromium_$UC_VERSION.debian.tar.xz
Checksums-Sha256:
 $(sha256sum < ungoogled-chromium_$UC_VERSION.orig.tar.xz | cut -f 1 -d ' ') $(stat -c '%s' ungoogled-chromium_$UC_VERSION.orig.tar.xz) ungoogled-chromium_$UC_VERSION.orig.tar.xz
 $(sha256sum < ungoogled-chromium_$UC_VERSION.debian.tar.xz | cut -f 1 -d ' ') $(stat -c '%s' ungoogled-chromium_$UC_VERSION.debian.tar.xz) ungoogled-chromium_$UC_VERSION.debian.tar.xz
Files:
 $(md5sum < ungoogled-chromium_$UC_VERSION.orig.tar.xz | cut -f 1 -d ' ') $(stat -c '%s' ungoogled-chromium_$UC_VERSION.orig.tar.xz) ungoogled-chromium_$UC_VERSION.orig.tar.xz
 $(md5sum < ungoogled-chromium_$UC_VERSION.debian.tar.xz | cut -f 1 -d ' ') $(stat -c '%s' ungoogled-chromium_$UC_VERSION.debian.tar.xz) ungoogled-chromium_$UC_VERSION.debian.tar.xz
EOF

cat > build.script << EOF
export LANG=C.UTF-8

JOBS="\${DEB_BUILD_OPTIONS#*=}"
case "\$(uname -m)" in
aarch64) DEB_BUILD_OPTIONS="parallel=\$(("\$JOBS" / 2))" ;;
esac
JOBS=

tar -x -f ../SOURCES/ungoogled-chromium.tar.xz
mkdir -p debian/download_cache
ln -s ../../../SOURCES/chromium-$UC_VERSION.tar.xz debian/download_cache/chromium-$UC_VERSION.tar.xz
ln -s ../../../SOURCES/chromium-$UC_VERSION.tar.xz.hashes debian/download_cache/chromium-$UC_VERSION.tar.xz.hashes
ln -s ../../../SOURCES/node-$NODE_VERSION-linux-x64.tar.xz debian/download_cache/node-$NODE_VERSION-linux-x64.tar.xz
ln -s ../../../SOURCES/node-$NODE_VERSION-linux-armv7l.tar.xz debian/download_cache/node-$NODE_VERSION-linux-armv7l.tar.xz
ln -s ../../../SOURCES/node-$NODE_VERSION-linux-arm64.tar.xz debian/download_cache/node-$NODE_VERSION-linux-arm64.tar.xz
ln -s ../../../SOURCES/node-$NODE_VERSION.sha256sum debian/download_cache/node-$NODE_VERSION.sha256sum

debian/rules setup

dpkg-buildpackage -b -uc
EOF

PACKAGE="ungoogled-chromium-debian"

curl "https://api.opensuse.org/source/$REPOSITORY/$PACKAGE" -F 'cmd=deleteuploadrev'

curl "https://api.opensuse.org/source/$REPOSITORY/$PACKAGE" > directory.xml

xmlstarlet sel -t -v '//entry/@name' < directory.xml | while read FILENAME
do
    curl "https://api.opensuse.org/source/$REPOSITORY/$PACKAGE/$FILENAME?rev=upload" -X DELETE
done

for FILENAME in _service ungoogled-chromium_$UC_VERSION.orig.tar.xz ungoogled-chromium_$UC_VERSION.debian.tar.xz ungoogled-chromium.tar.xz ungoogled-chromium.dsc build.script
do
    curl "https://api.opensuse.org/source/$REPOSITORY/$PACKAGE/$FILENAME?rev=upload" -T "$FILENAME"
done

curl "https://api.opensuse.org/source/$REPOSITORY/$PACKAGE" -F 'cmd=commit'

rm -f _service ungoogled-chromium_$UC_VERSION.orig.tar.xz ungoogled-chromium_$UC_VERSION.debian.tar.xz ungoogled-chromium.tar.xz ungoogled-chromium.dsc build.script directory.xml
