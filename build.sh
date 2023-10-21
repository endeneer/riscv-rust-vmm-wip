#!/bin/sh
set -e

# DIR_PREFIX="$(realpath "$(dirname $(readlink -f "$0"))"/../../..)"
DIR_PREFIX=/home/user/git/worktree/personal/kvm-ioctls-riscv

export ARCH=riscv
export CROSS_COMPILE=riscv64-linux-gnu-
export CC=${CROSS_COMPILE}gcc

BUILDROOT_DIR="$DIR_PREFIX/buildroot"
BUILDROOT_DEFCONFIG="kvm_ioctls_riscv_defconfig"
# BUILDROOT_DEFCONFIG="starfive_dubhe_test_defconfig"
BUILDROOT_TARGET_DIR="$BUILDROOT_DIR/output/target"
BUILDROOT_IMAGES_DIR="$BUILDROOT_DIR/output/images"
BUILDROOT_ROOTFS_CPIO="$BUILDROOT_IMAGES_DIR/rootfs.cpio"
BUILDROOT_TEST_DIR="$BUILDROOT_TARGET_DIR/test"
BUILDROOT_LINUX_DIR=$DIR_PREFIX/buildroot/output/build/linux-custom

# DTC_DIR="$DIR_PREFIX/dtc"
# KVMTOOL_DIR="$DIR_PREFIX/kvmtool"
KVM_BINDINGS_DIR="$DIR_PREFIX/kvm-bindings"
KVM_IOCTLS_DIR="$DIR_PREFIX/kvm-ioctls"
LINUX_LOADER_DIR="$DIR_PREFIX/linux-loader"
RISCV_RUST_VMM_EXAMPLE_DIR="$DIR_PREFIX/riscv-rust-vmm-example"

LINUX_DIR="$DIR_PREFIX/linux"
LINUX_DEFCONFIG="kvm_ioctls_riscv_defconfig"
LINUX_IMAGE="$BUILDROOT_IMAGES_DIR/Image"
LINUX_VMLINUX="$BUILDROOT_LINUX_DIR/vmlinux"

LINUX_TEST_DIR="$BUILDROOT_DIR/test"

OPENSBI_DIR="$DIR_PREFIX/opensbi"
OPENSBI_FW_JUMP_ELF="$OPENSBI_DIR/build/platform/generic/firmware/fw_jump.elf"

mkdir -p "$BUILDROOT_TEST_DIR"

# cd "$DTC_DIR"
# make clean
# make -j libfdt
# cd "$KVMTOOL_DIR"
# make LIBFDT_DIR=${DIR_PREFIX}/dtc/libfdt clean
# make LIBFDT_DIR="${DIR_PREFIX}/dtc/libfdt" cscope
# make -j LIBFDT_DIR="${DIR_PREFIX}/dtc/libfdt" lkvm-static
# mkdir -p "$BUILDROOT_TARGET_DIR/bin"
# cp "$KVMTOOL_DIR/lkvm-static" "$BUILDROOT_TARGET_DIR/bin/lkvm"
# mkdir -p "$BUILDROOT_TARGET_DIR/test/kvmtool"
# rsync -av --delete \
# 	--include='*.c' --include='*.h' --include='*.S' \
# 	--include='*/' \
# 	--exclude="*" \
# 	"$KVMTOOL_DIR" "$BUILDROOT_TARGET_DIR/test/kvmtool"

cd "$KVM_BINDINGS_DIR"
cargo build --target=riscv64gc-unknown-linux-gnu
cargo test --no-run --target=riscv64gc-unknown-linux-gnu
find "$(pwd)" -name "*.rs" > cscope.files
cscope -bkq -i cscope.files -f cscope.out

cd "$KVM_IOCTLS_DIR"
cargo build --target=riscv64gc-unknown-linux-gnu
cargo test --no-run --target=riscv64gc-unknown-linux-gnu
find "$(pwd)" -name "*.rs" > cscope.files
cscope -bkq -i cscope.files -f cscope.out

cd "$LINUX_LOADER_DIR"
cargo build --target=riscv64gc-unknown-linux-gnu
cargo test --no-run --target=riscv64gc-unknown-linux-gnu
find "$(pwd)" -name "*.rs" > cscope.files
cscope -bkq -i cscope.files -f cscope.out
mkdir -p "$BUILDROOT_TEST_DIR/linux_loader"
cp target/riscv64gc-unknown-linux-gnu/debug/deps/linux_loader-64f33f2362904e37 "$BUILDROOT_TEST_DIR/linux_loader"

cd "$RISCV_RUST_VMM_EXAMPLE_DIR"
# ./bindgen.sh
find "$(pwd)" -name "*.rs" > cscope.files
cscope -bkq -i cscope.files -f cscope.out
cargo build --target=riscv64gc-unknown-linux-gnu
cargo test --no-run --target=riscv64gc-unknown-linux-gnu
cp target/riscv64gc-unknown-linux-gnu/debug/riscv-rust-vmm-example "$BUILDROOT_TEST_DIR"
# cp target/riscv64gc-unknown-linux-gnu/debug/deps "$BUILDROOT_TEST_DIR"

cd "$LINUX_DIR"
# make $LINUX_DEFCONFIG
# make COMPILED_SOURCE=1 cscope

cd "$BUILDROOT_DIR"
make "$BUILDROOT_DEFCONFIG"
make linux-reconfigure
# cp $LINUX_IMAGE $BUILDROOT_TEST_DIR
make

cd "$OPENSBI_DIR"
make distclean
make cscope
# make -j PLATFORM=generic FW_OPTIONS=0 FW_PAYLOAD_PATH=$LINUX_IMAGE FW_JUMP_FDT_ADDR=0xa0000000
make -j PLATFORM=generic FW_OPTIONS=0 FW_JUMP_FDT_ADDR=0xa0000000

echo "QEMU"
qemu-system-riscv64 \
	-M virt -nographic \
	-smp 4 -cpu rv64,h=true,v=true \
	-m 4G \
	-bios $OPENSBI_FW_JUMP_ELF \
	-kernel $LINUX_IMAGE \
	-append "root=/dev/ram rw console=ttyS0 earlycon=sbi nokaslr" \
	-initrd $BUILDROOT_ROOTFS_CPIO \
	-object rng-random,filename=/dev/urandom,id=rng0 \
	-device virtio-rng-device,rng=rng0 \
	-device virtio-net-device,netdev=usernet \
	-netdev user,id=usernet,hostfwd=tcp::1234-:1234
	# -netdev user,id=usernet,hostfwd=tcp::22222-:22222,net=192.168.76.0/24,dhcpstart=192.168.76.9
	# -device virtio-net-device,netdev=usernet \
	# -netdev user,id=usernet,hostfwd=tcp:127.0.0.1:22222-:22222,hostfwd=tcp::20080-:80,hostfwd=tcp::28080-:8080 \
	# -device virtio-net-device,netdev=net0 -netdev user,id=net0,hostfwd=tcp::22222-:22222
	# -device virtio-net-device,netdev=net0 -netdev user,id=net0,hostfwd=tcp::22222-:22222
	# -device virtio-net-device,netdev=usernet -netdev user,id=usernet,hostfwd=tcp::45455-:45455
	# -monitor telnet::45454,server,nowait \
	# -net user,hostfwd=tcp::45455-:45455
	# -device e1000,netdev=net0 \
	# -netdev user,id=net0,hostfwd=tcp::45455-:45455
	# -device virtio-net-device,netdev=usernet \
	# -netdev user,id=usernet,hostfwd=tcp::45455-:45455
