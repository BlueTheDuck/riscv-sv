#!/bin/env bash

TAG="2025.08.28"

sudo sh -c "mkdir -p /opt/riscv && chown $USER /opt/riscv"

if [ ! -d "./riscv-gnu-toolchain" ]; then
    git clone --branch ${TAG} https://github.com/riscv-collab/riscv-gnu-toolchain.git ./riscv-gnu-toolchain
else
    git -C riscv-gnu-toolchain reset --hard
    git -C riscv-gnu-toolchain checkout ${TAG}
fi

git -C riscv-gnu-toolchain submodule update --init --recursive --jobs $(nproc) -- \
    binutils \
    gcc \
    gdb \
    glibc \
    newlib

echo Building dev environment

docker build -t rv32:${TAG} .

echo Running build

CONTAINER_ID=$(docker run -d rv32:${TAG})
# wait until container finishes
docker wait ${CONTAINER_ID}

echo Copying toolchain to host

docker cp ${CONTAINER_ID}:/opt/riscv/ $(pwd)/opt/
docker rm -f ${CONTAINER_ID}
echo "Toolchain built and copied to /opt/riscv"
echo "Run 'docker rmi rv32:${TAG}' to remove the image if no longer needed."
