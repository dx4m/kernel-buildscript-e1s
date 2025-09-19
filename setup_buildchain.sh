#!/bin/bash

# SPDX-License-Identifier: GPL-3.0
#
# Kernel build script for Samsung S24 (Exynos)

BUILDCHAIN="buildchain"
KERNELBUILD="kernelbuild"

TOOLS="${KERNELBUILD}/tools"
SYSTEM="${KERNELBUILD}/system"
BIONIC="${KERNELBUILD}/bionic"
PREBUILTS="${KERNELBUILD}/prebuilts"
EXTERNAL="${KERNELBUILD}/external"
BUILD="${KERNELBUILD}/build"

KERNEL_DIR="${KERNELBUILD}/common"
DEFCONFIG_DIR="${KERNEL_DIR}/arch/arm64/configs/e1s_defconfig"
CURRENT_DIR="$(pwd)"

function getAOSPBuildtools() {
	echo "[💠] Getting the buildchain"
	mkdir $BUILDCHAIN && cd $BUILDCHAIN
	repo init --depth=1 -u https://android.googlesource.com/kernel/manifest -b common-android15-6.6
	repo sync
	cd ..
	echo "[✅] Done."
}

function getSamsungKernel() {
	echo "[💠] Getting Samsung kernel for S24 (Exynos) from github"
	cd $KERNELBUILD
	git clone http://github.com/dx4m/android-kernel-samsung-e1s.git -b main common
	cd ..
	echo "[✅] Done."
}

function movePrebuilts() {
	echo "[💠] Moving buildchain from AOSP Buildchain to ${KERNELBUILD} folder"
	mv $BUILDCHAIN/tools $TOOLS
	mv $BUILDCHAIN/prebuilts $PREBUILTS
	mv $BUILDCHAIN/external $EXTERNAL
	mv $BUILDCHAIN/build $BUILD
	echo "[✅] Done."
}

function removeAOSPBuildchain() {
	echo "[💠] Remove AOSP Buildchain"
	
	rm -rf $BUILDCHAIN
	
	echo "[✅] Done."
}

function getSukiSU() {
	echo "[💠] Getting SukiSU with SUSFS"
	cd $KERNEL_DIR
	curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s susfs-main
	cd ..
	git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-6.1 susfs4ksu
	cd $CURRENT_DIR
	cp $KERNEL_DIR/../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch $KERNEL_DIR/
	cp -r $KERNEL_DIR/../susfs4ksu/kernel_patches/fs/* $KERNEL_DIR/fs/
	cp -r $KERNEL_DIR/../susfs4ksu/kernel_patches/include/linux/* $KERNEL_DIR/include/linux/
	cp $CURRENT_DIR/namespace.patch $KERNEL_DIR/fs/namespace.patch

	cd $KERNEL_DIR
	patch -p1 < 50_add_susfs_in_gki-android14-6.1.patch
	cd fs/
	patch -p2 < namespace.patch
	cd $CURRENT_DIR
	echo "[✅] Done. Ignore the first patch error from namespace, we patch it with the second patch"
}

if [ ! -d $KERNELBUILD ]; then
	mkdir $KERNELBUILD
fi

if [ ! -d $KERNELBUILD/common ]; then
	getSamsungKernel
	getSukiSU
fi

if [ ! -d $PREBUILTS ]; then
	if [ ! -d $BUILDCHAIN ]; then
		getAOSPBuildtools
	fi
	
	movePrebuilts
	removeAOSPBuildchain
fi
