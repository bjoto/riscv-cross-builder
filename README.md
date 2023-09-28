<!--
SPDX-FileCopyrightText: 2023 Rivos Inc.

SPDX-License-Identifier: Apache-2.0
-->

# RISC-V cross-builder (RISC-V kselftest HOWTO)

riscv-cross-builder contains Dockerfiles to generate a container image
that is:

* An x86-64 RISC-V cross-compiler environment suitable to build a
  RISC-V kernel image, the corresponding kselftest.
* A RISC-V rootfs, that shares the same libraries as the
  cross-compiler environment. This rootfs is used to execute the
  kselftest.

Create the Docker container:
```
docker build -f Dockerfile.ubuntu . -t ubuntu-builder
```
You now have a container named "ubuntu-builder".

Run the container, pointing to your Linux kernel source tree,
e.g. `/src/linux`:
```
docker run --tty --interactive --volume "/src/linux":/workspace --volume "/path/to/ccache":/ccache ubuntu-builder:latest /bin/bash
```

In the container, build the kernel, and the kselftest using:
```
build-selftest
```

When the build is complete, the following artifacts reside in
`/src/linux`:
* `build` contains the kernel and the modules
* `lunar.tar` the rootfs with the kselfself bundled
* `kbuild` contains the kernel build intermediaries

Create an image:
```
sudo create_image.sh rv-linux.img ./build ./lunar.tar
```

The image is created. Boot the image, e.g.:
```
sudo qemu-system-riscv64 \
    -bios opensbi/build/platform/generic/firmware/fw_dynamic.bin \
    -nographic \
    -monitor telnet:127.0.0.1:55555,server,nowait \
    -machine virt \
    -smp 4 \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-device,rng=rng0 \
    -append "root=/dev/vda2 rw earlycon console=tty0 console=ttyS0 loglevel=8 panic=-1 oops=panic sysctl.vm.panic_on_oom=1" \
    -drive if=none,file=./rv-linux.img,format=raw,id=hd0 \
    -device virtio-blk-pci,drive=hd0 \
    -chardev stdio,id=char0,mux=on,signal=off,logfile=boot.log \
    -serial chardev:char0 \
    -kernel ./build/vmlinuz-6.4.0 \
    -netdev user,id=net0,host=10.0.2.10,hostfwd=tcp::10022-:22 \
    -device virtio-net-device,netdev=net0 \
    -m 16G \
    -object memory-backend-ram,id=mem0,size=16G \
    -numa node,nodeid=0,memdev=mem0
```

In the virtual machine, when it's logged in:
```
cd
mkdir -p src/kselftest
cd src/kselftest
tar xvf /kselftest.tar
for i in $(./run_kselftest.sh -l|awk -F: '{print $1}' |uniq |egrep -v 'bpf|lkdtm|net') net bpf; do echo "TEST $i"; ./run_kselftest.sh -o 9000 -c $i ; done
```

Note that the for-state simply runs all the components, but runs net
and bpf last, since they take the longest.

Another option, is to skip generating the image, and instead use 9p.

Just unpack the tar:
```
mkdir rootfs; cd rootfs; sudo tar --extract --xattrs --xattrs-include='*' -f path/to/lunar.tar
```

Boot it using the rootfs:
```
sudo qemu-system-riscv64 \
  -nographic \
  -machine virt \
  -smp 4 \
  -m 16G \
  -object rng-random,filename=/dev/urandom,id=rng0 \
  -device virtio-rng-device,rng=rng0 \
  -fsdev local,id=root,path=/path/to/rootfs/lunar/,security_model=none \
  -device virtio-9p-pci,fsdev=root,mount_tag=/dev/root \
  -append \"root=/dev/root rw rootfstype=9p rootflags=version=9p2000.L,trans=virtio,cache=mmap,access=any security=none\" \ "
  -serial mon:stdio \
  -kernel /path to kernel/Image \
  -netdev user,id=net0,host=10.0.2.10,hostfwd=tcp::10022-:22 \
  -device virtio-net-device,netdev=net0
```

When your machine is booted and logged in:
```
mkdir selftest
cd selftest
tar xvf /kselftest.tar
```

Finally, run the tests:
```
./run_kselftest.sh
```

```
./run_kselftest.sh -c bpf
```
