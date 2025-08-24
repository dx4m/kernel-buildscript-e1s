# Kernel Build Script for the Samsung Galaxy S24 (Exynos)

This repository contains a simple build script and environment setup for compiling the **Samsung Galaxy S24 (Exynos)** kernel based on the AOSP toolchain and Samsung kernel sources.

## Intro

- Automated setup of the Android build toolchain (prebuilts, clang, kernel build tools, etc.)
- Support for custom build arguments (e.g. `--enable-kernelsu`)
- `--disable-samsung-protection` is enabled by default, otherwise your device won't boot.

## Different branches
This is the main branch. With this you can build the kernel without any ksu or susfs functions.
To build with sukisu and susfs use the suki-susfs branch or use the main branch and clone your flavor of ksu into the kernel.
Please follow the ksu build guides and build your kernel on the main branch with:
```bash
./build_kernel.sh --enable-kernelsu
```

On the suki-susfs branch the `--enable-kernelsu` is not needed because it's enabled by default.

## Requirements

- Linux environment (tested on WSL2 + Ubuntu)
- Install dependencies:
  ```bash
  sudo apt-get update
  sudo apt-get install git make bc bison flex libssl-dev wget curl lzop git-core gnupg flex bison build-essential zip zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig python3 repo -y
  ```
- Sufficient disk space (~100GB+ recommended)

## Usage

1. Clone the repository:
   ```bash
   git clone https://github.com/dx4m/kernel-buildscript-e1s.git
   cd kernel-buildscript-e1s
   chmod +x *.sh
   ```

2. Install dependencies:
   ```bash
   ./install_dep.sh
   ```
   
   and then you need to setup your identity
   ```bash
   git config --global user.email "your@email.com"
   git config --global user.name "Your Name"
   ```

3. Setup the toolchain (downloads AOSP prebuilts):
   
   ```bash
   ./setup_buildchain.sh
   ```

4. Build the kernel:
   ```bash
   ./build_kernel.sh
   ```

   - Additional flags are supported, e.g.:
     ```bash
     ./build_kernel.sh --enable-kernelsu
     ```
   - Make sure you have KernelSU in your kernel sources. Please follow the build guide of your prefered KernelSU repo

5. The compiled kernel output will be placed in:
   ```
   out/arch/arm64/boot/
   ```
   and a flashable boot.img will be generated.

## License

This project is licensed under the **GNU General Public License v3.0** (GPL-3.0).  
See the [LICENSE](LICENSE) file for details.

## Credits
Special thanks to:
- [Samsung](https://opensource.samsung.com/) for releasing the [kernel sources](https://opensource.samsung.com/uploadSearch?searchValue=sm-s921b)
- [Lucius](https://github.com/Luciiuss) for his buildscript and [kernel](https://github.com/Luciiuss/sm-a566b) for the Galaxy A56.

## Resources
- [AOSP Kernel Sources](https://android.googlesource.com/kernel/manifest/)
- [Samsung Kernel Source](https://github.com/dx4m/android-kernel-samsung-e1s)
- [Kernel Buildscript](https://github.com/dx4m/kernel_buildscript_gts10fewifi) for the Galaxy Tab S10 FE where this bases on
- [susfs4ksu](https://gitlab.com/simonpunk/susfs4ksu)

## KSU flavors
- [KernelSU](https://github.com/tiann/KernelSU)
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [SukiSU Ultra](https://github.com/sukisu-ultra/sukisu-ultra)
