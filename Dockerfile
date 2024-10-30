# SPDX-FileCopyrightText: 2023 Rivos Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Note that only debian:unstable work for Debian.
ARG distro=ubuntu
ARG flavor=noble

FROM ${distro}:${flavor}

ARG distro
ARG flavor
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
    ccache \
    cpio \
    curl \
    diffstat \
    flex \
    g++-riscv64-linux-gnu \
    guestfish \
    libguestfs-tools \
    linux-image-generic \
    gawk \
    gcc-riscv64-linux-gnu \
    gdb \
    gettext \
    git \
    git-lfs \
    gperf \
    groff \
    keyutils \
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

RUN if [ "$distro" = "ubuntu" ]; then \
      echo "deb [arch=amd64] http://apt.llvm.org/${flavor}/ llvm-toolchain-${flavor} main" >> /etc/apt/sources.list.d/llvm.list; \
    else \
      echo "deb [arch=amd64] http://apt.llvm.org/${flavor}/ llvm-toolchain main" >> /etc/apt/sources.list.d/llvm.list; \
    fi

RUN cat /etc/apt/sources.list.d/llvm.list
RUN wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | tee /etc/apt/trusted.gpg.d/apt.llvm.org.asc

RUN apt update
RUN apt-get install --yes clang llvm lld

RUN cd $(mktemp -d) && git clone https://git.kernel.org/pub/scm/devel/pahole/pahole.git && \
    cd pahole && mkdir build && cd build && cmake -D__LIB=lib .. && make install

RUN dpkg --add-architecture riscv64
RUN if [ "$distro" = "ubuntu" ]; then sed -i 's/^deb/deb [arch=amd64]/' /etc/apt/sources.list; fi
RUN if [ "$distro" = "ubuntu" ]; then \
      echo "\n\
deb [arch=riscv64] http://ports.ubuntu.com/ubuntu-ports ${flavor} main restricted multiverse universe\n\
deb [arch=riscv64] http://ports.ubuntu.com/ubuntu-ports ${flavor}-updates main\n\
deb [arch=riscv64] http://ports.ubuntu.com/ubuntu-ports ${flavor}-security main\n"\
    >> /etc/apt/sources.list; \
    fi

RUN if [ "$distro" = "ubuntu" ]; then sed -i -E "s/(^URIs.*)/\1\nArchitectures: amd64/" /etc/apt/sources.list.d/ubuntu.sources; fi

RUN cat /etc/apt/sources.list.d/${distro}.sources
RUN if [ "$distro" = "ubuntu" ]; then cat /etc/apt/sources.list; fi

RUN apt-get update

# Cross-build deps
RUN apt-get install --yes --no-install-recommends \
    libasound2-dev:riscv64 \
    libaudit-dev:riscv64 \
    libc6-dev-riscv64-cross \
    libc6-dev:riscv64 \
    libcap-dev:riscv64 \
    libcap-ng-dev:riscv64 \
    libcrypt-dev:riscv64 \
    libdw-dev:riscv64 \
    libelf-dev:riscv64 \
    libfuse-dev:riscv64 \
    libhugetlbfs-dev:riscv64 \
    liblzma-dev:riscv64 \
    libmnl-dev:riscv64 \
    libnuma-dev:riscv64 \
    libpcre2-dev:riscv64 \
    libpng-dev:riscv64 \
    libpopt-dev:riscv64 \
    libselinux1-dev:riscv64 \
    libsepol-dev:riscv64 \
    libslang2-dev:riscv64 \
    libssl-dev:riscv64 \
    libtraceevent-dev:riscv64 \
    liburing-dev:riscv64 \
    libzstd-dev:riscv64 \
    linux-libc-dev:riscv64 \
    zlib1g-dev:riscv64

# The workspace volume is for bind-mounted source trees.
VOLUME /workspace
WORKDIR /workspace
