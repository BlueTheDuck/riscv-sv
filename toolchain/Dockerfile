# syntax=docker/dockerfile:1-labs

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

RUN apt-get install -y sccache ccache distcc distcc-pump

WORKDIR /opt/riscv-gnu-toolchain/

ADD \
    --exclude=.git --exclude=.gitignore --exclude=.github \
    ./riscv-gnu-toolchain .

ADD config.cache .

ADD --chmod=755 entry.sh entry.sh

ENV PATH=/usr/lib/ccache:${PATH}

CMD ["/opt/riscv-gnu-toolchain/entry.sh"]
