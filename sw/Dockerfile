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

RUN git clone --branch 2025.01.20 https://github.com/riscv-collab/riscv-gnu-toolchain.git /opt/riscv-gnu-toolchain/ 
ADD fix_submodules.patch /opt/riscv-gnu-toolchain/

WORKDIR /opt/riscv-gnu-toolchain/

RUN git apply ./fix_submodules.patch

RUN ./configure --prefix=/opt/riscv --with-arch=rv32gc --with-abi=ilp32d --enable-multilib --with-languages=c,c++
RUN make -j$(nproc)
RUN make install
RUN find /opt/riscv -type f -executable -exec strip --strip-all '{}' 2>/dev/null \;

FROM debian:bookworm-slim AS runtime
COPY --from=build /opt/riscv/ /opt/riscv/

RUN addgroup riscv && useradd -m -g riscv -u 1000 riscv
ENV PATH /opt/riscv/bin:${PATH}
WORKDIR /opt/workdir/

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get upgrade -y \
    && apt-get -y install apt-utils git 2>&1
RUN apt-get install -y libexpat1 libgmp10 libmpc3 libmpfr6 zlib1g
# RUN apt-get autoremove -y \
#     && apt-get clean -y \
#     && rm -rf /var/lib/apt/lists/*
ENV DEBIAN_FRONTEND=dialog \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8
