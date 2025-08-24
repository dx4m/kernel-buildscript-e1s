#!/bin/bash

# SPDX-License-Identifier: GPL-3.0
#
# Kernel build script for Samsung Galaxy S24 (Exynos)

sudo apt-get update
sudo apt-get install git-core gnupg flex bison build-essential zip curl zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3 -y
sudo apt-get install repo -y

