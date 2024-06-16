#!/system/bin/sh -e

################################################################################
# Description: install the latest version of pixel-backup to the local directory
# Author: Vivek Revankar <vivek@master-hax.com>
# Usage: curl -fl https://raw.githubusercontent.com/master-hax/pixel-backup-gang/master/install.sh | sh
################################################################################

pbg_tarball_url="https://github.com/master-hax/pixel-backup-gang/releases/download/0.0.2/pixel-backup-gang-0.0.2.tar.gz"
pbg_tarball_filename="pixel-backup-gang-latest.tar.gz"
echo "install.sh: downloading the latest release"
curl -fL $pbg_tarball_url --output $pbg_tarball_filename
echo "install.sh: unpacking the release archive (requires root)"
/sbin/su --command "tar -xvf $pbg_tarball_filename"
echo "install.sh: make the release executable (requires root)"
/sbin/su --command "chmod +x ./pixel-backup-gang/*.sh"
echo "install.sh: pixel backup gang successfully installed to $(realpath ./pixel-backup-gang)"
