#!/bin/bash
set -ex

BINUTILS_VER=2.45.1
GCC_VER=15.2.0

MLIBC_DIR="$(pwd)/mlibc"
SRC_DIR="$(pwd)/src"
SYSROOT_DIR="$(pwd)/sysroot"
TOOLCHAIN_DIR="$(pwd)/toolchain"
BUILD_DIR="$(pwd)/build"
CROSS_FILE="$(pwd)/cross_file"
PATH="${TOOLCHAIN_DIR}/usr/bin:${PATH}"

git submodule update --init --recursive

# create needed directories for compilation
mkdir -p src sysroot toolchain build/binutils build/gcc build/mlibc-headers build/mlibc

# get and patch binutils if needed
if [ ! -f "${SRC_DIR}/.binutils_patched" ]; then
	wget -O "${SRC_DIR}/binutils-${BINUTILS_VER}.tar.xz" https://ftpmirror.gnu.org/binutils/binutils-${BINUTILS_VER}.tar.xz
	tar  -C "${SRC_DIR}" -xf "${SRC_DIR}/binutils-${BINUTILS_VER}.tar.xz"
	rm "${SRC_DIR}/binutils-${BINUTILS_VER}.tar.xz"

	cat patches/binutils.patch | patch -d "${SRC_DIR}/binutils-${BINUTILS_VER}"
	touch "${SRC_DIR}/.binutils_patched"
fi

# get and patch gcc if needed
if [ ! -f "${SRC_DIR}/.gcc_patched" ]; then
	wget -O "${SRC_DIR}/gcc-${GCC_VER}.tar.xz" https://ftpmirror.gnu.org/gnu/gcc/gcc-${GCC_VER}/gcc-${GCC_VER}.tar.xz
	tar  -C "${SRC_DIR}" -xf "${SRC_DIR}/gcc-${GCC_VER}.tar.xz"
	rm "${SRC_DIR}/gcc-${GCC_VER}.tar.xz"

	cat patches/gcc.patch | patch -p1 -d "${SRC_DIR}/gcc-${GCC_VER}"
	touch "${SRC_DIR}/.gcc_patched"
fi

# prepare mlibc in the sysroot if needed
if [ ! -f "${BUILD_DIR}/.mlibc_headers_installed" ]; then
	pushd "${BUILD_DIR}/mlibc-headers"
	meson setup --cross-file ${CROSS_FILE} --prefix=/usr  -Dheaders_only=true "${MLIBC_DIR}"
	DESTDIR=${SYSROOT_DIR} ninja install
	popd
	touch "${BUILD_DIR}/.mlibc_headers_installed"
fi

# build binutils if needed
if [ ! -f "${BUILD_DIR}/.binutils_built" ]; then
	pushd "${BUILD_DIR}/binutils"
	"${SRC_DIR}/binutils-${BINUTILS_VER}/configure" --target=riscv64-demo --prefix=/usr --with-sysroot=${SYSROOT_DIR} --disable-werror --enable-default-execstack=no
	make -j $(nproc)
	make install DESTDIR="${TOOLCHAIN_DIR}"
	popd
	touch "${BUILD_DIR}/.binutils_built"
fi

# build gcc if needed
if [ ! -f "${BUILD_DIR}/.gcc_built" ]; then
	pushd "${BUILD_DIR}/gcc"
	CFLAGS_FOR_TARGET="-march=rv64gc -mabi=lp64d" CXXFLAGS_FOR_TARGET="-march=rv64gc -mabi=lp64d" "${SRC_DIR}/gcc-${GCC_VER}/configure" --target=riscv64-demo --prefix=/usr --with-sysroot=${SYSROOT_DIR} --enable-languages=c,c++ -enable-threads=posix --disable-multilib --enable-shared --enable-host-shared --with-pic
	make all-gcc all-target-libgcc -j $(nproc)
	make install-gcc install-target-libgcc DESTDIR="${TOOLCHAIN_DIR}"
	popd
	touch "${BUILD_DIR}/.gcc_built"
fi

# build mlibc if needed
if [ ! -f "${BUILD_DIR}/.mlibc_built" ]; then
	pushd "${BUILD_DIR}/mlibc"
	meson setup -Ddefault_library=static --cross-file ${CROSS_FILE} --prefix=/usr -Dno_headers=true "${MLIBC_DIR}"
	DESTDIR="${SYSROOT_DIR}" ninja install
	popd
	touch "${BUILD_DIR}/.mlibc_built"
fi

mkdir -p ../target/riscv64imac-unknown-none-elf
riscv64-demo-gcc -march=rv64gc -mabi=lp64d main.c -o ../target/riscv64imac-unknown-none-elf/user_test
