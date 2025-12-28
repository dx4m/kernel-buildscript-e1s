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

KERNELSU_BRANCH="main"

YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#Runner variable
ENABLE_RUNNER=false
CLEANUP_RUNNER=false
GETKSUVERSION=false
GETTAGVERSION=false
GETKERNELVERSION=false
DISABLESUSFS=false
ENABLESUKI=true
ENABLEKSU=false
CLEAN_KERNEL=false
SAMSUNG_PATCH_LEVEL=false
HYMOFS_PATCH=false
DISABLE_LKM=false

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
	git clone https://github.com/dx4m/android-kernel-samsung-e1s.git -b $1 common
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

function getKernelSU() {
        echo "[💠] Getting KernelSU"
        cd $KERNEL_DIR
        curl -LSs "https://raw.githubusercontent.com/tiann/KernelSU/main/kernel/setup.sh" | bash -s main
		
		if [ "$DISABLE_LKM" = false ]; then
			sed -i 's/#ifdef MODULE/#ifndef MODULE/g' KernelSU/kernel/supercalls.c
		fi
		
        cd $CURRENT_DIR
		
        echo "[✅] Done."
}

function getSuSFS(){
	echo "[💠] Getting SuSFS"
	cd $KERNEL_DIR/../
        git clone --depth=1 https://gitlab.com/simonpunk/susfs4ksu.git -b gki-android14-6.1 susfs4ksu
        cd $CURRENT_DIR
        cp $KERNEL_DIR/../susfs4ksu/kernel_patches/50_add_susfs_in_gki-android14-6.1.patch $KERNEL_DIR/
		if [ "$ENABLEKSU" = true ]; then
			cp $KERNEL_DIR/../susfs4ksu/kernel_patches/KernelSU/10_enable_susfs_for_ksu.patch $KERNEL_DIR/KernelSU/
		fi
        cp -r $KERNEL_DIR/../susfs4ksu/kernel_patches/fs/* $KERNEL_DIR/fs/
        cp -r $KERNEL_DIR/../susfs4ksu/kernel_patches/include/linux/* $KERNEL_DIR/include/linux/

        cd $KERNEL_DIR
		echo "[💠] Patching Kernel"
        patch -p1 --fuzz=3 < 50_add_susfs_in_gki-android14-6.1.patch
		
		if [ "$ENABLEKSU" = true ]; then
			grep -q '<linux/stat.h>' include/linux/susfs.h || sed -i '/#include <linux\/susfs_def.h>/a #include <linux/stat.h>' include/linux/susfs.h
			cd KernelSU/
			echo "[💠] Patching KernelSU"
			patch -p1 --fuzz=3 < 10_enable_susfs_for_ksu.patch
		fi
		
        cd $CURRENT_DIR
        echo "[✅] Done."
}

function getHymoFS(){
	echo "[💠] Getting HymoFS"
	
	cd $KERNEL_DIR
	if [ "$DISABLESUSFS" = true ]; then
		curl -LSs https://raw.githubusercontent.com/Anatdx/HymoFS/refs/heads/android14_6.1/patch/hymofs.patch > hymofs.patch
	else
		curl -LSs https://raw.githubusercontent.com/Anatdx/HymoFS/refs/heads/android14_6.1/patch/hymofs_with_susfs.patch > hymofs.patch
	fi
	echo "[💠] Patching Kernel for HymoFS"
	patch -p1 --fuzz=3 < hymofs.patch
	
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
		--getKSUVer)
            GETKSUVERSION=true
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
		--enableSuSFS)
            DISABLESUSFS=false
            shift
            ;;
		--disableSuki)
            ENABLESUKI=false
            shift
            ;;
		--enableSuki)
            ENABLESUKI=true
			ENABLEKSU=false
            shift
            ;;
		--disableKSU)
			ENABLEKSU=false
            shift
            ;;
		--enableKSU)
            ENABLEKSU=true
			ENABLESUKI=false
            shift
            ;;
		--disableFakeLKM)
			DISABLE_LKM=true;
			shift
			;;
		--disableHymoFS)
            HYMOFS_PATCH=false
            shift
            ;;
		--enableHymoFS)
            HYMOFS_PATCH=true
            shift
            ;;
		--cleanKernel)
            CLEAN_KERNEL=true
            shift
            ;;
		-b)
			shift
            KERNELSU_BRANCH="$1"
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

if [ "$GETKSUVERSION" = true ]; then
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

if [ "$DISABLE_LKM" = false ] && [ "$ENABLEKSU" = true ]; then
	echo -e "${YELLOW}WARNING: Since KernelSU v3.0.0, GKI mode was deprecated. It works but you get a annoying warning in the manager, which you can't get rid of.${NC}"
	echo -e "${YELLOW}So we suppress KSU to be LKM mode which is fake obviously.${NC}"
	echo -e "${YELLOW}When you don't want this add the \"--disableFakeLKM\" flag to the setup_buildchain.sh${NC}"
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
	
	getSamsungKernel $KERNELSU_BRANCH
	
	if [ "$ENABLESUKI" = true ]; then
		getSukiSU
	fi
	
	if [ "$ENABLEKSU" = true ]; then
		getKernelSU
	fi
	
	if [ "$DISABLESUSFS" = false ]; then
		getSuSFS
	fi
	
	if [ "$HYMOFS_PATCH" = true ]; then
		getHymoFS
	fi
	
	if [ ! -d $PREBUILTS ]; then
		if [ ! -d $BUILDCHAIN ]; then
			getAOSPBuildtools
		fi
	
		copyPrebuilts
	fi
	
else
	if [ ! -d $KERNELBUILD/common ]; then
		getSamsungKernel $KERNELSU_BRANCH
		if [ "$ENABLESUKI" = true ]; then
			getSukiSU
		fi
		
		if [ "$ENABLEKSU" = true ]; then
			getKernelSU
		fi
	
		if [ "$DISABLESUSFS" = false ]; then
			getSuSFS
		fi
		
		if [ "$HYMOFS_PATCH" = true ]; then
			getHymoFS
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
