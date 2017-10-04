#!/bin/bash

# Set-Up ccache
ccache -M 50G

# Initialize the LineageOS source repository
if [ ! -d android/lineage ]; then
	mkdir -p android/lineage
	cd android/lineage
	repo init -u https://github.com/LineageOS/android.git -b cm-14.1
else
	cd android/lineage
fi

# Configure the device-specific repositories
#Device tree: https://github.com/DeadSquirrel01/android_device_samsung_a5ultexx Branch: cm-14.1
#Device Config: https://github.com/DeadSquirrel01/android_device_samsung_a5-common Branch: cm-14.1
#Kernel: https://github.com/DeadSquirrel01/android_kernel_samsung_msm8916 Branch: cm-14.1
mkdir -p .repo/local_manifests
cat > .repo/local_manifests/roomservice.xml << __EOF__
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project path="device/samsung/a5ultexx" name="DeadSquirrel01/android_device_samsung_a5ultexx" remote="github" revision="cm-14.1" />
  <project path="device/samsung/a5-common" name="DeadSquirrel01/android_device_samsung_a5-common" remote="github" revision="cm-14.1" />
  <project path="device/samsung/qcom-common" name="lineageos/android_device_samsung_qcom-common" remote="github" revision="cm-14.1" />
  <project path="device/qcom/common" name="lineageos/android_device_qcom_common" remote="github" revision="cm-14.1" />
  <project path="external/stlport" name="lineageos/android_external_stlport" remote="github" revision="cm-14.1" />
  <project path="external/sony/boringssl-compat" name="lineageos/android_external_sony_boringssl-compat" remote="github" revision="cm-14.1" />
  <project path="kernel/samsung/msm8916" name="DeadSquirrel01/android_kernel_samsung_msm8916" remote="github" revision="cm-14.1" />
  <project path="vendor/samsung" name="DeadSquirrel01/proprietary_vendor_samsung" remote="github" revision="cm-14.1" />
</manifest>
__EOF__

# Download the source code
repo sync ${MAKEFLAGS}

# Prepare the device-specific code
. build/envsetup.sh
breakfast a5ultexx

# Configure jack
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx32G"

# Extract proprietary blobs
#./extract-files.sh

# Start the build
croot
brunch a5ultexx
