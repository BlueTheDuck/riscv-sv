#!/bin/env bash

sudo sh -c "mkdir -p /opt/riscv && chown $USER /opt/riscv"

docker build -t rv32i:20250522 .
CONTAINER_ID=$(docker run -d rv32i:20250522)
docker cp ${CONTAINER_ID}:/opt/riscv /opt/
docker rm -f ${CONTAINER_ID}
echo "Toolchain built and copied to /opt/riscv"
echo "Run 'docker rmi rv32i:20250522' to remove the image if no longer needed."
