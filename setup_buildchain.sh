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
	repo init -u https://android.googlesource.com/kernel/manifest -b common-android15-6.6
	repo sync
	cd ..
	echo "[✅] Done."
}

function getSamsungKernel() {
	echo "[💠] Getting Samsung kernel for S24 (Exynos) from github"
	mkdir $KERNELBUILD && cd $KERNELBUILD
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


if [ ! -d $KERNELBUILD ]; then
	getSamsungKernel
fi

if [ ! -d $PREBUILTS ]; then
	if [ ! -d $BUILDCHAIN ]; then
		getAOSPBuildtools
	fi
	
	movePrebuilts
	removeAOSPBuildchain
fi
