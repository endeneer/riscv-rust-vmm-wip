#!/bin/bash
set -e

# cargo install bindgen-cli --vers 0.64.0

ARCH=riscv

DIR_PREFIX=/home/user/git/worktree/personal/kvm-ioctls-riscv
KVM_BINDINGS_DIR="$DIR_PREFIX/kvm-bindings"
LINUX_DIR="$DIR_PREFIX/linux"

mkdir -p "$KVM_BINDINGS_DIR/src/$ARCH"

cd "$LINUX_DIR"
make clean
rm -rf "$LINUX_DIR/${ARCH}_headers"
make headers_install ARCH=$ARCH INSTALL_HDR_PATH="$ARCH"_headers
cd "$LINUX_DIR/${ARCH}_headers"
bindgen include/linux/kvm.h -o bindings.rs  \
     --impl-debug --with-derive-default  \
     --with-derive-partialeq  --impl-partialeq \
     -- -Iinclude

cp "$LINUX_DIR/${ARCH}_headers/bindings.rs" "$KVM_BINDINGS_DIR/src/$ARCH"
# cp "$KVM_BINDINGS_DIR/src/arm64/mod.rs" "$KVM_BINDINGS_DIR/src/$ARCH"
