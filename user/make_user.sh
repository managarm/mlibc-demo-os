#!/bin/sh
set -ex

MLIBC_DIR=$HOME/mlibc

OUT_DIR=target/riscv64imac-unknown-none-elf
mkdir -p $OUT_DIR

CRT_BEGIN=$(riscv64-linux-gnu-gcc -print-file-name=crtbegin.o)
CRT_END=$(riscv64-linux-gnu-gcc -print-file-name=crtend.o)

# Build + install mlibc.
# Note: do meson setup first.
DESTDIR=$MLIBC_DIR/install-headers ninja -C $MLIBC_DIR/build install

riscv64-linux-gnu-gcc \
    -static -nostdinc -nostdlib -g \
    -I $MLIBC_DIR/install-headers/usr/local/include \
    -L $MLIBC_DIR/build \
    $MLIBC_DIR/install-headers/usr/local/lib/crt1.o \
    user/user_test.c \
    ${CRT_BEGIN} \
    ${CRT_END} \
    $MLIBC_DIR/build/libc.a \
    -lgcc \
    -o $OUT_DIR/user_test
