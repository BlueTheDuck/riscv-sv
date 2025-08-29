#!/bin/bash

./configure --prefix=/opt/riscv --with-arch=rv32 --with-abi=ilp32 --with-languages=c,c++

# DISTCC_HOSTS='localhost 192.168.0.7'
# make -j16 CC=distcc
make -j$(nproc)
# Uncomment to build gcc for Linux userspace
make linux -j$(nproc)
find /opt/riscv -type f -executable -exec strip --strip-all '{}' 2>/dev/null \;
