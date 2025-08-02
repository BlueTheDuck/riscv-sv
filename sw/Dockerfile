FROM debian:bookworm-slim AS build

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get upgrade -y \
    && apt-get -y install apt-utils git ca-certificates 2>&1

RUN apt-get install -y \
    autoconf automake autotools-dev curl \
    python3 python3-pip python3-tomli \
    libmpc-dev libmpfr-dev libgmp-dev gawk \
    build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build cmake libglib2.0-dev libslirp-dev

RUN git clone --branch 2025.05.22 https://github.com/riscv-collab/riscv-gnu-toolchain.git /opt/riscv-gnu-toolchain/ 

WORKDIR /opt/riscv-gnu-toolchain/

# Pre-initialize submodules so that Docker caches them
RUN git submodule update --init --recursive --jobs $(nproc) -- \
      binutils \
      gcc \
      gdb \
      glibc \
      newlib

RUN ./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32 --with-languages=c,c++
RUN make -j$(nproc)
# Uncomment to build gcc for Linux userspace
# RUN make linux -j$(nproc)
RUN find /opt/riscv -type f -executable -exec strip --strip-all '{}' 2>/dev/null \;
