#!/usr/bin/env sh
# USAGE: ./get-fedora-coreos
# USAGE: ./get-fedora-coreos stream dest
#
set -Eeou pipefail

STREAM=${1:-"stable"}
DEST_DIR=${2:-"/assets"}
DEST="${DEST_DIR}/fedora-coreos"
VERSION=$(curl -sL "https://builds.coreos.fedoraproject.org/streams/${STREAM}.json" | jq -r '.architectures.x86_64.artifacts.metal.release')
BASE_URL="https://builds.coreos.fedoraproject.org/prod/streams/${STREAM}/builds/${VERSION}/x86_64"

# check stream/version exist based on the header response
if ! curl -sfI "${BASE_URL}/fedora-coreos-${VERSION}-metal.x86_64.raw.xz"; then
    echo "Stream or Version not found"
    exit 1
fi

if [ ! -d "${DEST}" ]; then
    echo "Creating directory ${DEST}"
    mkdir -p "${DEST}"
else
    echo "Deleting images older than 30 days from ${DEST}"
    find "${DEST}" -type f -mtime +30 -delete 
fi

echo "Downloading Fedora CoreOS ${STREAM} ${VERSION} images to ${DEST}"
cd "${DEST}"

# GPG signature
FILE="fedora.gpg"; echo "${FILE}"
if [ ! -f "${FILE}" ]; then
    curl -# -LO "https://getfedora.org/static/${FILE}"
fi

# PXE kernel
FILE="fedora-coreos-${VERSION}-live-kernel-x86_64"; echo "${FILE}"
while [ ! -f "${FILE}" ]; do
    curl -# -LO "${BASE_URL}/${FILE}"
    curl -# -LO "${BASE_URL}/${FILE}.sig"

    if ! gpgv --quiet --keyring ./fedora.gpg ${FILE}.sig ${FILE}; then
        echo "${FILE} has bad signature, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi

    CHECKSUM=$(curl -sL "https://builds.coreos.fedoraproject.org/streams/${STREAM}.json" | jq -r '.architectures.x86_64.artifacts.metal.formats.pxe.kernel.sha256')
    if ! echo "${CHECKSUM}  ${FILE}" | sha256sum -c -; then
        echo "${FILE} has bad checksum, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi
done

# PXE initramfs
FILE="fedora-coreos-${VERSION}-live-initramfs.x86_64.img"; echo "${FILE}"
while [ ! -f "${FILE}" ]; do
    curl -# -LO "${BASE_URL}/${FILE}"
    curl -# -LO "${BASE_URL}/${FILE}.sig"

    if ! gpgv --quiet --keyring ./fedora.gpg ${FILE}.sig ${FILE}; then
        echo "${FILE} has bad signature, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi

    CHECKSUM=$(curl -sL "https://builds.coreos.fedoraproject.org/streams/${STREAM}.json" | jq -r '.architectures.x86_64.artifacts.metal.formats.pxe.initramfs.sha256')
    if ! echo "${CHECKSUM}  ${FILE}" | sha256sum -c -; then
        echo "${FILE} has bad checksum, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi
done

# PXE rootfs
FILE="fedora-coreos-${VERSION}-live-rootfs.x86_64.img"; echo "${FILE}"
while [ ! -f "${FILE}" ]; do
    curl -# -LO "${BASE_URL}/${FILE}"
    curl -# -LO "${BASE_URL}/${FILE}.sig"

    if ! gpgv --quiet --keyring ./fedora.gpg ${FILE}.sig ${FILE}; then
        echo "${FILE} has bad signature, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi

    CHECKSUM=$(curl -sL "https://builds.coreos.fedoraproject.org/streams/${STREAM}.json" | jq -r '.architectures.x86_64.artifacts.metal.formats.pxe.rootfs.sha256')
    if ! echo "${CHECKSUM}  ${FILE}" | sha256sum -c -; then
        echo "${FILE} has bad checksum, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi
done

# Install image
FILE="fedora-coreos-${VERSION}-metal.x86_64.raw.xz"; echo "${FILE}"
while [ ! -f "${FILE}" ]; do
    curl -# -LO "${BASE_URL}/${FILE}"
    curl -# -LO "${BASE_URL}/${FILE}.sig"

    if ! gpgv --quiet --keyring ./fedora.gpg ${FILE}.sig ${FILE}; then
        echo "${FILE} has bad signature, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi

    CHECKSUM=$(curl -sL "https://builds.coreos.fedoraproject.org/streams/${STREAM}.json" | jq -r '.architectures.x86_64.artifacts.metal.formats."raw.xz".disk.sha256')
    if ! echo "${CHECKSUM}  ${FILE}" | sha256sum -c -; then
        echo "${FILE} has bad checksum, deleting file..."
        rm -f "${FILE}.sig" "${FILE}"
    fi
done

# success
exit 0