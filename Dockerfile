# SPDX-FileCopyrightText: 2023 Rivos Inc.
#
# SPDX-License-Identifier: Apache-2.0

FROM debian:sid

ARG DEBIAN_FRONTEND=noninteractive

# Base packages to retrieve the other repositories/packages
RUN apt-get update && apt-get install --yes --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg

# Add additional packages here.
RUN apt-get update && apt-get install --yes --no-install-recommends \
    arch-test \
    autoconf \
    automake \
    autotools-dev \
    bash-completion \
    bc \
    binfmt-support \
    bison \
    bsdmainutils \
    build-essential \
    cpio \
    curl \
    diffstat \
    flex \
    g++-riscv64-linux-gnu \
    gawk \
    gcc-riscv64-linux-gnu \
    gdb \
    gettext \
    git \
    git-lfs \
    gperf \
    groff \
    less \
    libelf-dev \
    liburing-dev \
    lsb-release \
    mmdebstrap \
    ninja-build \
    patchutils \
    perl \
    pkg-config \
    psmisc \
    python-is-python3 \
    python3-venv \
    qemu-user-static \
    rsync \
    ruby \
    ssh \
    strace \
    texinfo \
    traceroute \
    unzip \
    vim \
    zlib1g-dev \
    lsb-release \
    wget \
    software-properties-common \
    gnupg \
    cmake \
    libdw-dev \
    libssl-dev \
    python3-docutils \
    kmod

RUN echo 'deb [arch=amd64] http://apt.llvm.org/unstable/ llvm-toolchain main' >> /etc/apt/sources.list.d/llvm.list

RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc

RUN apt update
RUN apt-get install --yes clang llvm

# Ick. BPF requires pahole "supernew" to work
RUN cd $(mktemp -d) && git clone https://git.kernel.org/pub/scm/devel/pahole/pahole.git && \
    cd pahole && mkdir build && cd build && cmake -D__LIB=lib .. && make install

RUN dpkg --add-architecture riscv64

RUN apt-get update

RUN apt-get install --yes --no-install-recommends \
    libasound2-dev:riscv64 \
    libc6-dev:riscv64 \
    libcap-dev:riscv64 \
    libcap-ng-dev:riscv64 \
    libelf-dev:riscv64 \
    libfuse-dev:riscv64 \
    libhugetlbfs-dev:riscv64 \
    libmnl-dev:riscv64 \
    libnuma-dev:riscv64 \
    libpopt-dev:riscv64 \
    libssl-dev:riscv64 \
    liburing-dev:riscv64

RUN mkdir /rootfs

RUN mmdebstrap --architectures=riscv64 --include="liburing2,libasound2,net-tools,socat,ethtool,iputils-ping,uuid-runtime,rsync,python3,libnuma1,libmnl0,libfuse2,libcap2,libcap-ng0,libhugetlbfs0,libssl3,jq,iptables,nftables,netsniff-ng,tcpdump,traceroute,tshark,fuse3,netcat-openbsd" sid /rootfs/sid.tar \
    --customize-hook='echo rv-selftester > "$1/etc/hostname"' \
    --customize-hook='echo 44f789c720e545ab8fb376b1526ba6ca > "$1/etc/machine-id"' \
    --customize-hook='mkdir -p "$1/etc/systemd/system/serial-getty@ttyS0.service.d"' \
    --customize-hook='printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty -o \"-p -f -- \\\\\\\\u\" --keep-baud --autologin root 115200,57600,38400,9600 - \$TERM\n" > "$1/etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf"'

RUN apt-get clean && rm -rf /var/lib/apt/lists/

COPY build-selftest /usr/local/bin

# The workspace volume is for bind-mounted source trees.
VOLUME /workspace
WORKDIR /workspace
