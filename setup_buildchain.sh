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
CURRENT_DIR="$(pwd)"

#Runner variable
ENABLE_RUNNER=false
CLEANUP_RUNNER=false
GETSUKIVERSION=false
GETTAGVERSION=false
GETKERNELVERSION=false
DISABLESUSFS=false
DISABLESUKI=false
CLEAN_KERNEL=false
SAMSUNG_PATCH_LEVEL=false

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

function copyPrebuilts() {
	echo "[💠] Copying buildchain from AOSP Buildchain to ${KERNELBUILD} folder"
	cp -r $BUILDCHAIN/tools $TOOLS
	cp -r $BUILDCHAIN/prebuilts $PREBUILTS
	cp -r $BUILDCHAIN/external $EXTERNAL
	cp -r $BUILDCHAIN/build $BUILD
	echo "[✅] Done."
}

function rmPrebuilts() {
	echo "[💠] Removing buildchain from ${KERNELBUILD} folder"
	rm -rf $TOOLS
	rm -rf $PREBUILTS
	rm -rf $EXTERNAL
	rm -rf $BUILD
	echo "[✅] Done."
}

function removeAOSPBuildchain() {
	echo "[💠] Remove AOSP Buildchain"
	
	rm -rf $BUILDCHAIN
	
	echo "[✅] Done."
}

function getSukiSU() {
        echo "[💠] Getting SukiSU Ultra"
        cd $KERNEL_DIR
        curl -LSs "https://raw.githubusercontent.com/SukiSU-Ultra/SukiSU-Ultra/main/kernel/setup.sh" | bash -s builtin
        cd $CURRENT_DIR
        echo "[✅] Done."
}

function getSuSFS(){
	echo "[💠] Getting SuSFS"
	cd $KERNEL_DIR/../
        git clone https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-6.1 susfs4ksu
        cd $CURRENT_DIR
        cp $KERNEL_DIR/../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch $KERNEL_DIR/
        cp -r $KERNEL_DIR/../susfs4ksu/kernel_patches/fs/* $KERNEL_DIR/fs/
        cp -r $KERNEL_DIR/../susfs4ksu/kernel_patches/include/linux/* $KERNEL_DIR/include/linux/

        cd $KERNEL_DIR
        patch -p1 --fuzz=3 < 50_add_susfs_in_gki-android14-6.1.patch
        cd $CURRENT_DIR
        echo "[✅] Done."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --runner)
            ENABLE_RUNNER=true
            shift
            ;;
		--cleanup)
            CLEANUP_RUNNER=true
            shift
            ;;
		--getSukiVer)
            GETSUKIVERSION=true
            shift
            ;;
		--getTagVer)
            GETTAGVERSION=true
            shift
            ;;
		--getKernelVer)
            GETKERNELVERSION=true
            shift
            ;;
		--getSamsungPatchLevel)
            SAMSUNG_PATCH_LEVEL=true
            shift
            ;;
		--disableSuSFS)
            DISABLESUSFS=true
            shift
            ;;
		--disableSuki)
            DISABLESUKI=true
            shift
            ;;
		--cleanKernel)
            CLEAN_KERNEL=true
            shift
            ;;
        *)
            OTHER_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "$SAMSUNG_PATCH_LEVEL" = true ]; then
	if [ ! -d $KERNEL_DIR ]; then
		exit 1
	fi
	
	cd $KERNEL_DIR
	echo "$(make sampatchlevel)"
	cd $CURRENT_DIR
	exit 0
fi

if [ "$GETKERNELVERSION" = true ]; then
	if [ ! -d $KERNEL_DIR ]; then
		exit 1
	fi
	
	cd $KERNEL_DIR
	echo "$(make kernelversion)-g$(git rev-parse --short HEAD)"
	cd $CURRENT_DIR
	exit 0
fi

if [ "$GETTAGVERSION" = true ]; then
	if [ ! -d $KERNEL_DIR/KernelSU ]; then
		exit 1
	fi
	
	cd $KERNEL_DIR/KernelSU
	echo "$(git tag --sort=-v:refname | head -n1)-$(git rev-parse --short HEAD)"
	cd $CURRENT_DIR
	exit 0
fi

if [ "$GETSUKIVERSION" = true ]; then
	if [ ! -d $KERNEL_DIR/KernelSU ]; then
		exit 1
	fi
	
	cd $KERNEL_DIR/KernelSU
	echo "$(git tag --sort=-v:refname | head -n1)-$(git rev-parse --short HEAD)@$(git branch --show-current)"
	cd $CURRENT_DIR
	exit 0
fi

if [ "$CLEANUP_RUNNER" = true ]; then
	rmPrebuilts
	exit 0
fi

if [ "$CLEAN_KERNEL" = true ]; then
	if [ -d $KERNELBUILD/common ]; then
		rm -rf $KERNELBUILD/common
	fi
fi

if [ ! -d $KERNELBUILD ]; then
	mkdir $KERNELBUILD
fi

if [ "$ENABLE_RUNNER" = true ]; then
	if [ -d $KERNELBUILD/common ]; then
		rm -rf $KERNELBUILD/common
	fi
	
	if [ -d $KERNELBUILD/susfs4ksu ]; then
		rm -rf $KERNELBUILD/susfs4ksu
	fi
	
	getSamsungKernel
	
	if [ "$DISABLESUKI" = false ]; then
		getSukiSU
	fi
	
	if [ "$DISABLESUSFS" = false]; then
		getSuSFS
	fi
	
	if [ ! -d $PREBUILTS ]; then
		if [ ! -d $BUILDCHAIN ]; then
			getAOSPBuildtools
		fi
	
		copyPrebuilts
	fi
	
else
	if [ ! -d $KERNELBUILD/common ]; then
		getSamsungKernel
		if [ "$DISABLESUKI" = false ]; then
			getSukiSU
		fi
	
		if [ "$DISABLESUSFS" = false ]; then
			getSuSFS
		fi
	fi

	if [ ! -d $PREBUILTS ]; then
		if [ ! -d $BUILDCHAIN ]; then
			getAOSPBuildtools
		fi
	
		movePrebuilts
		removeAOSPBuildchain
	fi
fi
