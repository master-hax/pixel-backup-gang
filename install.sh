#!/bin/sh -eu

################################################################################
# Description: install the latest version of pixel-backup-gang to the local directory
# Author: Vivek Revankar <vivek@master-hax.com>
# Usage: sh -c "$(curl -fSs https://raw.githubusercontent.com/master-hax/pixel-backup-gang/master/install.sh)"
################################################################################

pbg_tarball_version="0.0.6"
pbg_tarball_filename="pixel-backup-gang-$pbg_tarball_version.tar.gz"
pbg_tarball_url="https://github.com/master-hax/pixel-backup-gang/releases/download/$pbg_tarball_version/$pbg_tarball_filename"
echo "install.sh: downloading version $pbg_tarball_version from github"
curl -fL $pbg_tarball_url --output $pbg_tarball_filename || { echo 'failed to download release archive' ; exit 1; }
echo "install.sh: unpacking the release archive (requires root)" || { echo 'failed to unpack release archive' ; exit 1; }
su --command "tar -xvf $pbg_tarball_filename" || { echo 'failed to inflate release archive' ; exit 1; }
echo "install.sh: making the release executable (requires root)"
su --command "chmod +x ./pixel-backup-gang/*.sh" || { echo 'failed to make scripts executable' ; exit 1; }
echo "install.sh: pixel backup gang successfully installed to $(realpath ./pixel-backup-gang)"
