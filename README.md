<!--
SPDX-FileCopyrightText: 2023 Rivos Inc.

SPDX-License-Identifier: Apache-2.0
-->

# RISC-V cross-build environment

riscv-cross-builder contains Dockerfiles to generate a container image
that is an x86-64 RISC-V cross-compiler environment suitable to build
a RISC-V kernel image, the corresponding userland things, like
kselftest.

Typically use this in conjunction with the
https://github.com/bjoto/riscv-rootfs-utils.

One would use the container to build, and the then rootfs-utils to
populate/run the RISC-V machine.

Create the Docker container:
```
docker buildx build --progress=plain --build-arg flavor=oracular -t cross-builder .
# or
docker buildx build --progress=plain -t cross-builder .
# or
docker buildx build --progress=plain --build-arg distro=debian --build-arg flavor=unstable -t cross-builder .
```
You now have a container named "cross-builder".

Run the container, pointing to your Linux kernel source tree,
e.g. `/src/linux`:
```
docker run -it --volume "/src/linux":/workspace --volume "/path/to/ccache":/ccache cross-builder /bin/bash
```

In the container, build the kernel, e.g. and the kselftest using:
```
time make ARCH=riscv CROSS_COMPILE="ccache riscv64-linux-gnu-" PAHOLE=~/src/pahole/build/pahole -j $(($(nproc)-1)) defconfig
time make ARCH=riscv CROSS_COMPILE="ccache riscv64-linux-gnu-" PAHOLE=~/src/pahole/build/pahole -j $(($(nproc)-1))
```

