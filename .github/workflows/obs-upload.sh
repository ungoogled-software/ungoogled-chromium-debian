#!/bin/sh
set -e

for i in git curl xmlstarlet
do
    if test -z "$(which "$i" || true)"
    then
        echo "The $i binary could not be found. Aborting."
        exit 1
    fi
done

BASE="$(git rev-parse --show-toplevel 2> /dev/null)"
DEBIAN="${BASE}/debian"
UNGOOGLED_CHROMIUM="${DEBIAN}/ungoogled-upstream/ungoogled-chromium"

if test -z "${BASE}"
then
    echo "BASE directory could not be determined. Aborting."
    exit 1
fi

for i in OBS_API_USERNAME OBS_API_PASSWORD
do
    if test -z "$(eval echo \$${i})"
    then
        echo "$i is not in the environment. Aborting."
        exit 1
    fi
done

PROJECT="${OBS_API_PROJECT:-home:${OBS_API_USERNAME}}"

dsc_sha1()
{
    local FILE="${1}"
    local FILENAME="${FILE##*/}"

    if test ! -f "$FILE"
    then
        echo "$FILE must exist and be a regular file. Aborting."
        exit 1
    fi

    echo " $(sha1sum "${FILE}" | cut -f 1 -d ' ') $(stat -c '%s' "${FILE}") ${FILENAME}"
}

dsc_sha256()
{
    local FILE="${1}"
    local FILENAME="${FILE##*/}"

    if test ! -f "$FILE"
    then
        echo "$FILE must exist and be a regular file. Aborting."
        exit 1
    fi

    echo " $(sha256sum "${FILE}" | cut -f 1 -d ' ') $(stat -c '%s' "${FILE}") ${FILENAME}"
}

dsc_md5()
{
    local FILE="${1}"
    local FILENAME="${FILE##*/}"

    if test ! -f "$FILE"
    then
        echo "$FILE must exist and be a regular file. Aborting."
        exit 1
    fi

    echo " $(md5sum "${FILE}" | cut -f 1 -d ' ') $(stat -c '%s' "${FILE}") ${FILENAME}"
}

curl()
{
    for i in `seq 1 5`
    do
        command curl -sS -K - "${@}" << EOF
user="${OBS_API_USERNAME}:${OBS_API_PASSWORD}"
EOF
        test "${?}" -eq 0 && return 0
        sleep 30s
    done
    return 1
}

git_get_tag()
{
    local TAG
    local TYPE

    TAG="$(git describe --tags --exact-match 2> /dev/null || true)"

    if test -z "${TAG}"
    then
        TAG="$(git describe --tags)"
        TYPE='development'
    else
        TYPE='production'
    fi

    echo "${TYPE}:${TAG}"
}

generate_obs()
{
    local ROOT="${1}"
    local CHROMIUM_VERSION="${2}"
    local OBS_DEPENDS="${3}"
    local TAG="${4#*:}"
    local TYPE="${4%:*}"

    cat > "${ROOT}/_service" << EOF
<services>
    <service name="obs_scm">
        <param name="scm">git</param>
        <param name="url">https://github.com/ungoogled-software/ungoogled-chromium-debian.git</param>
        <param name="submodules">enable</param>
        <param name="subdir">debian</param>
        <param name="filename">ungoogled-chromium-debian</param>
        <param name="version">${TAG}</param>
        <param name="revision">${TAG}</param>
    </service>
    <service name="download_url">
        <param name="protocol">https</param>
        <param name="host">commondatastorage.googleapis.com</param>
        <param name="path">chromium-browser-official/chromium-${CHROMIUM_VERSION}.tar.xz</param>
    </service>
    <service name="download_url">
        <param name="protocol">https</param>
        <param name="host">commondatastorage.googleapis.com</param>
        <param name="path">chromium-browser-official/chromium-${CHROMIUM_VERSION}.tar.xz.hashes</param>
    </service>
    <service name="recompress">
        <param name="compression">xz</param>
        <param name="file">*.obscpio</param>
    </service>
</services>
EOF

    cat > "${ROOT}/build.script" << 'EOF'
export LANG=C.UTF-8

xz -d < ../SOURCES/ungoogled-chromium-debian-*.obscpio.xz | cpio -i -d
mv ungoogled-chromium-debian-* debian

mkdir ../download_cache
ln -s ../SOURCES/chromium-*.tar.xz ../download_cache
ln -s ../SOURCES/chromium-*.tar.xz.hashes ../download_cache

debian/scripts/setup debian
debian/scripts/setup local-src

dpkg-buildpackage -b -uc
EOF

    tar -c -T/dev/null | xz -9 > "${ROOT}/ungoogled-chromium_1.0.orig.tar.xz"
    tar -c -T/dev/null | xz -9 > "${ROOT}/ungoogled-chromium_1.0.debian.tar.xz"

    mkdir "${ROOT}/tmp"
    cp -r "${DEBIAN}" "${ROOT}/tmp"
    tar -c -T/dev/null | xz -9 > "${ROOT}/ungoogled-chromium_${CHROMIUM_VERSION}.orig.tar.xz"
    (cd "${ROOT}/tmp"; debian/scripts/setup debian; rm debian/patches/series; dpkg-source -b .)
    sed -e '/^Checksums-/,$d' -e '/^Version:/cVersion: 1.0' -e "s/^Build-Depends:.*/&${OBS_DEPENDS}/" "${ROOT}"/ungoogled-chromium_*.dsc > "${ROOT}/ungoogled-chromium.dsc"
    cat >> "${ROOT}/ungoogled-chromium.dsc" << EOF
Checksums-Sha1:
$(dsc_sha1 "${ROOT}/ungoogled-chromium_1.0.orig.tar.xz")
$(dsc_sha1 "${ROOT}/ungoogled-chromium_1.0.debian.tar.xz")
Checksums-Sha256:
$(dsc_sha256 "${ROOT}/ungoogled-chromium_1.0.orig.tar.xz")
$(dsc_sha256 "${ROOT}/ungoogled-chromium_1.0.debian.tar.xz")
Files:
$(dsc_md5 "${ROOT}/ungoogled-chromium_1.0.orig.tar.xz")
$(dsc_md5 "${ROOT}/ungoogled-chromium_1.0.debian.tar.xz")
EOF
    rm -rf "${ROOT}/tmp" "${ROOT}"/*"${CHROMIUM_VERSION}"*
}

upload_obs()
{
    local ROOT="${1}"
    local TAG="${2#*:}"
    local TYPE="${2%:*}"
    local DISTRO_RELEASE="${3}"
    local REPOSITORY
    local PACKAGE="ungoogled-chromium-${DISTRO_RELEASE}"
    local FILE
    local FILENAME

    case "${TYPE}" in
    
        production)
            REPOSITORY="${PROJECT}"
            ;;

        development)
            REPOSITORY="${PROJECT}:testing"
            ;;

    esac

    curl "https://api.opensuse.org/source/${REPOSITORY}/${PACKAGE}" -F 'cmd=deleteuploadrev'

    curl "https://api.opensuse.org/source/${REPOSITORY}/${PACKAGE}" > "${ROOT}/directory.xml"

    xmlstarlet sel -t -v '//entry/@name' < "${ROOT}/directory.xml" | while read FILENAME
    do
        curl "https://api.opensuse.org/source/${REPOSITORY}/${PACKAGE}/${FILENAME}?rev=upload" -X DELETE
    done

    rm -f "${ROOT}/directory.xml"

    for FILE in "${ROOT}"/*
    do
        FILENAME="${FILE##*/}"
        curl "https://api.opensuse.org/source/${REPOSITORY}/${PACKAGE}/${FILENAME}?rev=upload" -T "${FILE}"
    done

    curl "https://api.opensuse.org/source/${REPOSITORY}/${PACKAGE}" -F 'cmd=commit'
}

TMP="$(mktemp -d)"
CHROMIUM_VERSION="$(cat "${UNGOOGLED_CHROMIUM}/chromium_version.txt")"
OBS_DEPENDS="$(cat "${DEBIAN}/obs_depends.txt")"
GIT_TAG="$(git_get_tag)"
DISTRO_RELEASE="$(cat "${DEBIAN}/distro_release.txt")"

trap 'rm -rf "${TMP}"' EXIT INT
generate_obs "${TMP}" "${CHROMIUM_VERSION}" "${OBS_DEPENDS}" "${GIT_TAG}"
upload_obs "${TMP}" "${GIT_TAG}" "${DISTRO_RELEASE}"
