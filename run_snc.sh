#!/bin/bash -xv

# Reference: https://github.com/crc-org/snc
#            https://github.com/openshift/installer/blob/master/docs/dev/libvirt/README.md#one-time-setup

echo 3 | sudo tee /proc/sys/vm/drop_caches

# Before running ./snc.sh, you need to create a pull secret file, and set a couple of environment variables to override the default behavior.
# Select the OKD 4 release that you want to build from: https://origin-release.apps.ci.l2s4.p1.openshiftapps.com
# For example, to build release: 4.5.0-0.okd-2020-08-12-020541
#
# --

# Create a pull secret file
# Get pull secret from the following and set it to /tmp/pull_secret.json
# https://console.redhat.com/openshift/create/local

cat << EOF > /tmp/pull_secret.json
<COPY AND PASTE SECRET FROM ABOVE URL>
EOF

# Set environment for OKD build
export OKD_VERSION=4.10.0-0.okd-2022-07-09-073606
export OKD_VERSION=4.10.0-0.okd-2022-06-10-131327
export OKD_VERSION=4.12.0-0.okd-2023-01-21-055900
export OPENSHIFT_PULL_SECRET_PATH="/tmp/pull_secret.json"

cd ~/snc || exit 1
./snc.sh
#./createdisk.sh crc-tmp-install-data
