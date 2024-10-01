#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.15.163
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
#nproc=8

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    # Clean the previous build if necessary
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} mrproper 
    
    # Set the default configuration for ARM64 Architecture
    make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig 
    
    # Build the kernel image
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} all 
    
    make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} dtbs
    
    # Build the kernel modules (optional, but skipping due to space constraints)
    #make -j8 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules
    
    # Install the kernel modules (skipping as instructed
    #make -j8 ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} modules_install
    
    # Copy the Image to the output directory
    #mkdir ${OUTDIR}/Image
    #cp linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image
fi

echo "Adding the Image in outdir"
# Copy the Image to the output directory
#mkdir ${OUTDIR}/Image
cp linux-stable/arch/${ARCH}/boot/Image ${OUTDIR}/Image

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir ${OUTDIR}/rootfs
cd ${OUTDIR}/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var

mkdir -p usr/bin usr/lib usr/sbin

mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} distclean
    #make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
    cd busybox
fi

# TODO: Make and install busybox
make -j$(nproc) ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}

make -j$(nproc) CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

cd ${OUTDIR}/rootfs

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${OUTDIR}/rootfs/bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

cp -a ${SYSROOT}/lib/ld-linux-aarch64.so.1 	${OUTDIR}/rootfs/lib/
cp -a ${SYSROOT}/lib64/libc.so.6 		${OUTDIR}/rootfs/lib64/
cp -a ${SYSROOT}/lib64/libm.so.6 		${OUTDIR}/rootfs/lib64/
cp -a ${SYSROOT}/lib64/libresolv.so.2 		${OUTDIR}/rootfs/lib64

# TODO: Make device nodes
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/null c 1 3
sudo mknod -m 666 ${OUTDIR}/rootfs/dev/console c 5 1

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
make CROSS_COMPILE=${CROSS_COMPILE} clean
make CROSS_COMPILE=${CROSS_COMPILE} all

# Copy the writer binary to the target rootfs
cp ${FINDER_APP_DIR}/writer ${OUTDIR}/rootfs/home

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cp ${FINDER_APP_DIR}/finder.sh 			${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/username.txt 		${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/conf/assignment.txt 	${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/finder-test.sh 		${OUTDIR}/rootfs/home/
cp ${FINDER_APP_DIR}/autorun-qemu.sh 		${OUTDIR}/rootfs/home/

# Modify the finder-test.sj to reference the assignment.txt file in /home
#sed -i 's|\.\./conf/assignment.txt|home/assignment.txt|' ${OUTDIR}/rootfs/home/finder-test.sh

# TODO: Chown the root directory
sudo chown -R root:root ${OUTDIR}/rootfs

# TODO: Create initramfs.cpio.gz
cd ${OUTDIR}/rootfs
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio

# Compress File
cd ${OUTDIR}
rm -f initramfs.cpio.gz
gzip -f initramfs.cpio


