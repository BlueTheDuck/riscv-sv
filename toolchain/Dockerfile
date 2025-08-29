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

RUN apt-get install -y distcc

WORKDIR /opt/riscv-gnu-toolchain/

ADD ./riscv-gnu-toolchain .

ADD entry.sh entry.sh
RUN chmod +x entry.sh

ENTRYPOINT ["/opt/riscv-gnu-toolchain/entry.sh"]
