#!/bin/bash
# Ubuntu 20.04 base
set -e
set -x

# Install dependencies
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses5-dev lib32readline-dev lib32z1-dev liblz4-tool libncurses5 libncurses5-dev libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev
sudo apt-get install -y default-jdk
sudo apt-get install -y python2
sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1  # Android git repo hooks are python2-only

# Install repo
mkdir -p ~/bin
cat >> ~/.profile <<EOF
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi
EOF
source ~/.profile
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Git config
git config --global user.email "phyks@phyks.me"
git config --global user.name "Phyks (Lucas Verney)"

# Use ccache
cat >> ~/.bashrc <<EOF
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
EOF
source ~/.bashrc
ccache -M 50G
ccache -o compression=true

# Prevent repo prompt about using colors
git config --global color.ui false

# Clone Lineage 17.1 or /e/ codebase (takes roughly 1h!)
mkdir -p ~/android/lineage
cd ~/android/lineage
if [[ "${BUILD_FLAVOR}" == "lineage" ]]; then
    repo init -q -u https://github.com/LineageOS/android.git -b lineage-17.1
elif [[ "$BUILD_FLAVOR" == "e" ]]; then
    repo init -q -u https://gitlab.e.foundation/e/os/android.git -b v1-q
else
    echo "Unknown build flavor! Exiting."
    exit 1
fi
repo sync
source build/envsetup.sh

# Get h870-specific repos
mkdir -p ~/android/lineage/.repo/local_manifests/
cat > ~/android/lineage/.repo/local_manifests/roomservice.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <project name="LG-G6-DEV/android_device_lge_h870" path="device/lge/h870" remote="github" revision="lineage-17.0" />
  <project name="LG-G6-DEV/android_device_lge_msm8996-common" path="device/lge/msm8996-common" remote="github" revision="stagingAU" />
  <project name="LG-G6-DEV/android_kernel_lge_msm8996" path="kernel/lge/msm8996" remote="github" revision="Optimizing" />
  <project name="LG-G6-DEV/proprietary_vendor_lge" path="vendor/lge" remote="github" revision="new_audio" />
</manifest>
EOF
repo sync

# Some h870 cherry picks
croot
cd frameworks/base/
git remote add fixes https://github.com/BernardoBas/android_frameworks_base.git
git fetch fixes
# Phantom camera fixes
git cherry-pick a904a84ad485d8768c7a523ec380696d573c9a9e 5a02ae0abfb2a341055aecbb46fb6ce3b24070cf
# Sunrise/Sunset hardoded if location is not available
git cherry-pick 2c9baf509fef40586cc07a8b3aed91bb3cc741b3
croot
cd device/lge/msm8996-common/
git remote add brightness https://github.com/BernardoBas/android_device_lge_msm8996-common.git
git fetch brightness
# MIC LEVEL -- TODO
git cherry-pick 9123565f56262e73dc6d613a0efc4bfb5867f5e6
# ROUNDED CORNERS  -- TODO
git cherry-pick 5c490db56b5d2431bc21a35f865511a3ea86ca4a


# If you want micro-g on Lineage, uncomment this part
# Note: micro-g is already built-in with /e/
# if [[ "${BUILD_FLAVOR}" == "lineage" ]]; then
#    croot
#    cd frameworks/base
#    curl https://raw.githubusercontent.com/lineageos4microg/docker-lineage-cicd/master/src/signature_spoofing_patches/android_frameworks_base-Q.patch > android_frameworks_base-Q.patch
#    patch -p1 -i android_frameworks_base-Q.patch
# fi

if [[ "${BUILD_FLAVOR}" == "e" ]]; then
    # Remove some apps built with /e/, comment if you want to keep them
    croot
    # Remove MagicEarth (non-free)
    rm -r prebuilts/prebuiltapks/MagicEarth
    # Remove DemoApp
    rm -r prebuilts/prebuiltapks/DemoApp
    # Remove DroidGuard
    rm -r prebuilts/prebuiltapks/DroidGuard
    # Remove eDrive
    rm -r prebuilts/prebuiltapks/eDrive
    # Remove ESmsSync
    rm -r prebuilts/prebuiltapks/ESmsSync
    # Remove Notes
    rm -r prebuilts/prebuiltapks/Notes
    # Remove Camera
    rm -r prebuilts/prebuiltapks/Camera
    # Remove Browser
    rm -r prebuilts/prebuiltapks/Browser
    # Remove Weather
    rm -r prebuilts/prebuiltapks/Weather
    # Remove Tasks
    rm -r prebuilts/prebuiltapks/Tasks
    # Remove PdfViewer
    rm -r prebuilts/prebuiltapks/PdfViewer
    # Remove BrowserWebView
    rm -r prebuilts/prebuiltapks/BrowserWebView
    # Remove eSpeakTTS
    rm -r prebuilts/prebuiltapks/eSpeakTTS
    # Remove LibreOfficeViewer
    rm -r prebuilts/prebuiltapks/LibreOfficeViewer
    # Remove OpenWeatherMapWeatherProvider
    rm -r prebuilts/prebuiltapks/OpenWeatherMapWeatherProvider
    # TODO
fi

# Build Lineage or /e/ (takes 2 to 3 hours!)
croot
make clean
date | tee -a build.log && brunch h870 | tee -a build.log && date | tee -a build.log && touch ~/BUILD_DONE
