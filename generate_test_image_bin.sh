#!/bin/bash
set -e

ARCH=riscv

DIR_PREFIX=/home/user/git/worktree/personal/kvm-ioctls-riscv
# LINUX_DIR="$DIR_PREFIX/linux"
BUILDROOT_DIR="$DIR_PREFIX/buildroot"
BUILDROOT_IMAGES_DIR="$BUILDROOT_DIR/output/images"
LINUX_LOADER_DIR="$DIR_PREFIX/linux-loader"

cd "$BUILDROOT_IMAGES_DIR"
head -c 4096 Image > test_image.bin
mkdir -p "$LINUX_LOADER_DIR"/src/loader/"$ARCH"/pe
mv test_image.bin "$LINUX_LOADER_DIR"/src/loader/"$ARCH"/pe
hexdump -C "$LINUX_LOADER_DIR"/src/loader/"$ARCH"/pe/test_image.bin
