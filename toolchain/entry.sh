#!/bin/bash

./configure -C --prefix=/opt/riscv \
    --with-arch=rv32i --with-abi=ilp32 --with-languages=c,c++\
    --enable-strip

# DISTCC_HOSTS='localhost 192.168.0.7'
# make -j16 CC=distcc
make -j$(nproc)
# Uncomment to build gcc for Linux userspace
# make linux -j$(nproc)
find /opt/riscv/bin -type f -exec sh -c "file '{}' | grep -qo ELF" \; -and -print0 | xargs -0 strip --strip-all