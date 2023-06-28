#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

mkdir -p ${OUTDIR}
if [ ! -d "$OUTDIR" ]
then
	echo "The creation of "$OUTDIR" failed, exiting..."
        exit 1
fi

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
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make mrproper
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make defconfig
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j6
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make modules
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make dtbs
fi

echo "Adding the Image in outdir"
cp ${OUTDIR}/linux-stable/arch/arm64/boot/Image ${OUTDIR}

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
	sudo rm -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
cd "${OUTDIR}"
mkdir rootfs
cd rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir usr/bin usr/lib usr/sbin
mkdir var/log

cd "${OUTDIR}"
if [ ! -d "${OUTDIR}/busybox" ]
then
	git clone git://busybox.net/busybox.git
	cd busybox
	git checkout ${BUSYBOX_VERSION}
	# TODO:  Configure busybox
	make distclean
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make defconfig
else
	cd busybox
fi

# TODO: Make and install busybox
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j6
	CONFIG_PREFIX=${OUTDIR}/rootfs ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install

echo "Library dependencies"
${CROSS_COMPILE}readelf -a bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs

# TODO: Make device nodes

# TODO: Clean and build the writer utility

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs

# TODO: Chown the root directory

# TODO: Create initramfs.cpio.gz
