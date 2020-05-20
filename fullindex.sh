#!/bin/bash
cd "$(dirname "$0")"
source 'ci-library.sh'
deploy_enabled && mkdir artifacts
git_config user.email 'ci@msys2.org'
git_config user.name  'MSYS2 Continuous Integration'
git remote add upstream 'https://github.com/r-windows/rtools-extra'
git fetch --quiet upstream

# List all files and download them from bintray
cd artifacts
PKGS=($(curl "https://bintray.com/api/v1/packages/${BINTRAY_TARGET}/${BINTRAY_REPOSITORY}/${BINTRAY_PACKAGE}/versions/latest/files" | grep -oh '"name"[^, ]*.pkg\.tar\.xz' | sort -u | cut -b 9-1000))
for FILE in "${PKGS[@]}"; do
    echo "Downloading ${FILE}"
    curl -OL "http://dl.bintray.com/${BINTRAY_TARGET}/${BINTRAY_REPOSITORY}/${FILE}"
done
cd ..

# Deploy
deploy_enabled && cd artifacts || success 'All packages built successfully'
execute 'Generating pacman repository' create_pacman_repository "${PACMAN_REPOSITORY:-ci-build}"
execute 'Generating build references'  create_build_references  "${PACMAN_REPOSITORY:-ci-build}"
execute 'SHA-256 checksums' sha256sum *

# Remove packages so they don't get reuploaded
rm -f *pkg.tar.xz
success 'Index regenerated successfully'
