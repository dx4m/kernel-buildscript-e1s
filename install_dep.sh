#!/bin/bash

# SPDX-License-Identifier: GPL-3.0
#
# Kernel build script for Samsung Galaxy S24 (Exynos)

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function install_package() {
    for pkg in "$@"; do
		if ! dpkg -l | grep -q "^ii  $pkg "; then
			echo "Installing $pkg..."
			if ! apt-get install -y "$pkg"; then
				echo -e "[❌] ${RED}Installation failed: $pkg${NC}" >&2
				exit 1
			else
				echo -e "[✅] ${GREEN}Install success: $pkg${NC}";
			fi
		fi
	done
}

if [ "$(id -u)" -ne 0 ]; then
	echo -e "[❌] ${RED}This script needs to run as root."
	echo -e "Try sudo $0 $@ --OR-- sudo !!${NC}"
	exit 1
fi

apt-get update && apt-get upgrade -y
install_package git-core gnupg flex bison build-essential zip curl zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3 repo


