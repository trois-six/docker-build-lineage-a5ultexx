#!/bin/bash

set -eu

# Set-Up ccache
ccache -M 50G

# Initialize the LineageOS source repository
if [ ! -d android/lineage ]; then
	mkdir -p android/lineage
	cd android/lineage
	repo init -u https://github.com/LineageOS/android.git -b lineage-15.1
else
	cd android/lineage
fi

# Configure the device-specific repositories
#Device tree: https://github.com/DeadSquirrel01/android_device_samsung_a5ultexx Branch: lineage-15.1
#Device Config: https://github.com/DeadSquirrel01/android_device_samsung_a5-common Branch: lineage-15.1
#Kernel: https://github.com/DeadSquirrel01/android_kernel_samsung_msm8916 Branch: lineage-15.1
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/roomservice.xml << __EOF__
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="DeadSquirrel01/proprietary_vendor_samsung" path="vendor/samsung" remote="github" revision="lineage-15.1" />
  <project name="LineageOS/android_hardware_samsung" path="hardware/samsung" remote="github" revision="lineage-15.1" />
  <project name="LineageOS/android_packages_resources_devicesettings" path="packages/resources/devicesettings" remote="github" revision="lineage-15.1" />
  <project path="device/qcom/common" name="lineageos/android_device_qcom_common" remote="github" revision="lineage-15.1" />
  <project path="device/samsung/a5-common" name="DeadSquirrel01/android_device_samsung_a5-common" remote="github" revision="lineage-15.1" />
  <project path="device/samsung/a5ultexx" name="DeadSquirrel01/android_device_samsung_a5ultexx" remote="github" revision="lineage-15.1" />
  <project path="device/samsung/qcom-common" name="lineageos/android_device_samsung_qcom-common" remote="github" revision="lineage-15.1" />
  <project path="external/sony/boringssl-compat" name="lineageos/android_external_sony_boringssl-compat" remote="github" revision="lineage-15.1" />
  <project path="external/stlport" name="lineageos/android_external_stlport" remote="github" revision="lineage-15.1" />
  <project path="kernel/samsung/msm8916" name="DeadSquirrel01/android_kernel_samsung_msm8916" remote="github" revision="lineage-15.1" />
  <project path="vendor/samsung" name="DeadSquirrel01/proprietary_vendor_samsung" remote="github" revision="lineage-15.1" />
</manifest>
__EOF__

# Clean patched dirs that have repopicks
cd frameworks/av
git reset --hard HEAD@{0}
cd ../../hardware/samsung
git reset --hard HEAD@{0}
cd ../../vendor/lineage
git reset --hard HEAD@{0}
cd ../..

# Download the source code
repo sync --force-sync ${MAKEFLAGS:-}

# Some needed commits haven't been pushed to lineage repos, yet. Let's repopick them, then
# Script can be found here http://msm8916.com/~vincent/repopicks.sh
curl -qs https://msm8916.com/~vincent/repopicks.sh -o repopicks.sh && chmod u+x repopicks.sh
./repopicks.sh

# Temporary remove disable AudioFX build: it crashes ad cause reboots in 8.1. Will be re-enabled later when gets stable
perl -i -ne 'print unless /^    AudioFX/; ' vendor/lineage/config/common.mk
BASE_PATCH="0001-fw-base-Enable-home-button-wake.patch" # patch to wake device with home button
CAMERA_PATCH="0001-Revert-Camera-Remove-dead-legacy-code.patch" # We have legacy camera
cp device/samsung/a5-common/patches/$FBASE_PATCH frameworks/base/
cp device/samsung/a5-common/patches/$CAMERA_PATCH frameworks/av/

# Apply patch
(cd frameworks/base && patch -N -p1 < $FBASE_PATCH) # Also ignores patching if patch is already applied
(cd frameworks/av && patch -N -p1 < $CAMERA_PATCH)
rm frameworks/base/$FBASE_PATCH
rm frameworks/av/$CAMERA_PATCH

# Fix build error in hardware/samsung
sed -i 's=void rilEventAddWakeup_helper=//void rilEventAddWakeup_helper=g' hardware/samsung/ril/include/libril/ril_ex.h

# Cleanup from previous build
rm -rf out

# Configure jack
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx32G"

# Start building
. build/envsetup.sh
breakfast a5ultexx

# Extract proprietary blobs
#./extract-files.sh

# Start the build
croot
brunch a5ultexx
