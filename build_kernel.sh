#!/bin/bash

# SPDX-License-Identifier: GPL-3.0
#
# Kernel build script for Samsung Galaxy S24 (Exynos)

CURRENT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
KERNELBUILD="${CURRENT_DIR}/kernelbuild"

TOOLS="${KERNELBUILD}/tools"
PREBUILTS="${KERNELBUILD}/prebuilts"
EXTERNAL="${KERNELBUILD}/external"
BUILD="${KERNELBUILD}/build"

KERNEL_DIR="${KERNELBUILD}/common"
OUTPUT_DIR="${CURRENT_DIR}/out"

DISABLE_SAMSUNG_PROTECTION=true
ENABLE_SUKI=true
ENABLE_KSU=false
MENUCONFIG=false
PRINTHELP=false
CLEAN=false
CONFIG=false
SETVERSION=""
LOCALVERSION=""

VERSION="-android14-11-dx4m"
TARGETSOC="s5e9945"

if [ ! -d $PREBUILTS ]; then
	echo "[❌] Missing prebuilts"
	exit 1
fi

if [ ! -d $KERNEL_DIR ]; then
	echo "[❌] Missing kernel"
	exit 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --disable-samsung-protection)
            DISABLE_SAMSUNG_PROTECTION=true
            shift
            ;;
        --disable-suki)
            ENABLE_SUKI=false
            shift
            ;;
		--enable-suki)
            ENABLE_SUKI=true
            shift
            ;;
		--enable-ksu)
            ENABLE_KSU=true
            shift
            ;;
		menuconfig)
            MENUCONFIG=true
            shift
            ;;
		config)
            CONFIG=true
            shift
            ;;
		clean)
            CLEAN=true
            shift
            ;;
		--help)
            PRINTHELP=true
            shift
            ;;
		--version)
			shift
			SETVERSION="$1"
			shift
			;;
        *)
            OTHER_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ "$PRINTHELP" = true ]; then
	echo "build_kernel.sh [COMMAND/OPTIONS]"
	echo "COMMANDS:"
	printf "\tmenuconfig (opens menuconfig)\n"
	printf "\tconfig (Builds the .config)\n"
	printf "\tclean (cleans the out dir)\n"
	echo "OPTIONS:"
	printf "\t--disable-samsung-protection (DEFAULT DISABLED)\n"
	printf "\t--disable-suki (Disables SukiSU Ultra in config. Follow SukiSU Ultra building guide)\n"
	printf "\t--help (Prints this message)\n"
	printf "\t--version [str] (Sets kernelversion to [str]. It overrides \"6.1.138$VERSION\")\n"
	exit 0
fi

if [ "$CLEAN" = true ]; then
	if [ ! -d $OUTPUT_DIR ]; then
		echo "[✅] Already clean."
		exit 0
	fi
	
	rm -rf $OUTPUT_DIR
	echo "[✅] Cleaned output."
	exit 0
fi

export PATH="${PREBUILTS}/build-tools/linux-x86/bin:${PATH}"
export PATH="${PREBUILTS}/build-tools/path/linux-x86:${PATH}"
export PATH="${PREBUILTS}/clang/host/linux-x86/clang-r510928/bin:${PATH}"
export PATH="${PREBUILTS}/kernel-build-tools/linux-x86/bin:${PATH}"

LLD_COMPILER_RT="-fuse-ld=lld --rtlib=compiler-rt"
SYSROOT_FLAGS="--sysroot=${PREBUILTS}/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8/sysroot"

CFLAGS="-I${PREBUILTS}/kernel-build-tools/linux-x86/include "
LDFLAGS="-L${PREBUILTS}/kernel-build-tools/linux-x86/lib64 ${LLD_COMPILER_RT}"

export LD_LIBRARY_PATH="${PREBUILTS}/kernel-build-tools/linux-x86/lib64"
export HOSTCFLAGS="${SYSROOT_FLAGS} ${CFLAGS}"
export HOSTLDFLAGS="${SYSROOT_FLAGS} ${LDFLAGS}"

TARGET_DEFCONFIG="${1:-e1s_defconfig}"
ARGS="CC=clang LD=ld.lld ARCH=arm64 LLVM=1 LLVM_IAS=1"

CONFIG_FILE="${OUTPUT_DIR}/.config"

if [ -f "${CONFIG_FILE}" ]; then
	TARGET_DEFCONFIG="oldconfig"
fi

if [ "$CONFIG" = true ]; then
	make -j"$(nproc)" \
     -C "${KERNEL_DIR}" \
     O="${OUTPUT_DIR}" \
     ${ARGS} \
     "${TARGET_DEFCONFIG}"
	exit 0
fi

if [ "$MENUCONFIG" = true ]; then
	make -j"$(nproc)" \
     -C "${KERNEL_DIR}" \
     O="${OUTPUT_DIR}" \
     ${ARGS} \
     "${TARGET_DEFCONFIG}" HOSTCFLAGS="${CFLAGS}" HOSTLDFLAGS="${LDFLAGS}" menuconfig
	 exit 0
else
	make -j"$(nproc)" \
     -C "${KERNEL_DIR}" \
     O="${OUTPUT_DIR}" \
     ${ARGS} \
     EXTRA_CFLAGS:=" -DCFG80211_SINGLE_NETDEV_MULTI_LINK_SUPPORT -DTARGET_SOC=${TARGETSOC}" \
     "${TARGET_DEFCONFIG}"
fi

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "[❌] .config not found at ${CONFIG_FILE}"
  exit 1
fi

if [ "$ENABLE_SUKI" = true ]; then
	if [ ! -d $KERNEL_DIR/KernelSU ]; then
		echo "[❗] Can't enable KernelSU in config. KernelSU doesn't exist."
		ENABLE_SUKI=false
	else
		DISABLE_SAMSUNG_PROTECTION=true
		"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
			-e CONFIG_KSU -e CONFIG_KPM -e CONFIG_KSU_MANUAL_SU \
			-e CONFIG_KSU_NONE_HOOK \
			-e CONFIG_KSU_SUSFS -e CONFIG_KSU_SUSFS_SUS_PATH -e CONFIG_KSU_SUSFS_SUS_MOUNT \
			-e CONFIG_KSU_SUSFS_SUS_KSTAT -e CONFIG_KSU_SUSFS_SPOOF_UNAME \
			-e CONFIG_KSU_SUSFS_ENABLE_LOG -e CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
			-e CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG -e CONFIG_KSU_SUSFS_OPEN_REDIRECT \
			-e CONFIG_KSU_SUSFS_SUS_MAP
	fi
fi

if [ "$ENABLE_KSU" = true ]; then
	if [ ! -d $KERNEL_DIR/KernelSU ]; then
		echo "[❗] Can't enable KernelSU in config. KernelSU doesn't exist."
		ENABLE_KSU=false
	else
		DISABLE_SAMSUNG_PROTECTION=true
		"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
			-e CONFIG_KSU -e CONFIG_KSU_KPROBES_HOOK \
			-e CONFIG_KSU_SUSFS -e CONFIG_KSU_SUSFS_SUS_PATH -e CONFIG_KSU_SUSFS_SUS_MOUNT \
			-e CONFIG_KSU_SUSFS_SUS_KSTAT -e CONFIG_KSU_SUSFS_SPOOF_UNAME \
			-e CONFIG_KSU_SUSFS_ENABLE_LOG -e CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
			-e CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG -e CONFIG_KSU_SUSFS_OPEN_REDIRECT \
			-e CONFIG_KSU_SUSFS_SUS_MAP
	fi
fi

# Disable Samsung Protection
if [ "$DISABLE_SAMSUNG_PROTECTION" = true ]; then
	
	"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
		-d UH -d RKP -d KDP -d SECURITY_DEFEX -d INTEGRITY -d FIVE \
		-d TRIM_UNUSED_KSYMS -d PROCA -d PROCA_GKI_10 -d PROCA_S_OS \
		-d PROCA_CERTIFICATES_XATTR -d PROCA_CERT_ENG -d PROCA_CERT_USER \
		-d GAF -d GAF_V6 -d FIVE_CERT_USER -d FIVE_DEFAULT_HASH \
		-e CONFIG_TMPFS_XATTR -e CONFIG_TMPFS_POSIX_ACL

fi

LOCALVERSION=$("${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" --state CONFIG_LOCALVERSION)

if [ -z "$LOCALVERSION" ]; then
	LOCALVERSION="${VERSION}"
fi

if [[ ! -z "$SETVERSION" ]]; then
	LOCALVERSION="${SETVERSION}"
fi

echo "LOCALVERSION: $LOCALVERSION"

# Change LOCALVERSION
"${KERNEL_DIR}/scripts/config" --file "${CONFIG_FILE}" \
  --set-str CONFIG_LOCALVERSION "$LOCALVERSION" -d CONFIG_LOCALVERSION_AUTO

# Fix Kernel Version to remove + (The + stands for dirty kernel -- because we patch it and the changes are not in a commit)
sed -i 's/echo "+"$/echo ""/' $KERNEL_DIR/scripts/setlocalversion

# Compile
KBUILD_BUILD_USER="build-user" KBUILD_BUILD_HOST="build-host" make -j"$(nproc)" \
     -C "${KERNEL_DIR}" \
     O="${OUTPUT_DIR}" \
     ${ARGS} \
     EXTRA_CFLAGS:=" -I$KERNEL_DIR/drivers/ufs/host/s5e9945/ -I$KERNEL_DIR/arch/arm64/kvm/hyp/include -DCFG80211_SINGLE_NETDEV_MULTI_LINK_SUPPORT -DTARGET_SOC=${TARGETSOC}"


# Restore fix from earlier
sed -i 's/echo ""$/echo "+"/' $KERNEL_DIR/scripts/setlocalversion

if [ -e $OUTPUT_DIR/arch/arm64/boot/Image ]; then
	echo "[✅] Kernel build finished."
	python3 $TOOLS/mkbootimg/mkbootimg.py --header_version 4 --kernel $OUTPUT_DIR/arch/arm64/boot/Image --cmdline '' --out $CURRENT_DIR/boot.img
	echo "[✅] Boot image generated at ${CURRENT_DIR}/boot.img"
	tar -cf $CURRENT_DIR/boot.img.tar boot.img
	echo "[✅] Odin flashable image at ${CURRENT_DIR}/boot.img.tar"
else
	echo "[❌] Kernel build failed."
fi
