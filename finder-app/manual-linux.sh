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

	# Add your kernel build steps here

	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make mrproper
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make defconfig
	ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} make -j7
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

# Create necessary base directories

mkdir rootfs
cd rootfs
mkdir bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "${OUTDIR}"
if [ ! -d "${OUTDIR}/busybox" ]
then
	git clone git://busybox.net/busybox.git
	cd busybox
	git checkout ${BUSYBOX_VERSION}
	
	# Configure busybox
	
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} distclean
	make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} defconfig
else
	cd busybox
fi

# Make and install busybox

make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make CONFIG_PREFIX="${OUTDIR}/rootfs" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} install
cd "${OUTDIR}/rootfs"

echo "Library dependencies"
${CROSS_COMPILE}readelf -a ./bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ./bin/busybox | grep "Shared library"

echo "Copying dependency files"
TOOLCHAINPATH=$(dirname `which "${CROSS_COMPILE}gcc"`)
TOOLCHAINDIR=$(dirname $TOOLCHAINPATH)
echo $TOOLCHAINDIR
cp "${TOOLCHAINDIR}/aarch64-none-linux-gnu/libc/lib/ld-linux-aarch64.so.1" ./lib/
cp "${TOOLCHAINDIR}/aarch64-none-linux-gnu/libc/lib64/libm.so.6" ./lib64/
cp "${TOOLCHAINDIR}/aarch64-none-linux-gnu/libc/lib64/libresolv.so.2" ./lib64/
cp "${TOOLCHAINDIR}/aarch64-none-linux-gnu/libc/lib64/libc.so.6" ./lib64/
echo "Done Copying dependency files"

# Make device nodes

sudo mknod -m 666 ./dev/null c 1 3
sudo mknod -m 666 ./dev/console c 5 1

# Clean and build the writer utility

cd "${FINDER_APP_DIR}"
make clean
CROSS_COMPILE="$CROSS_COMPILE" make

# Copy the finder related scripts and executables to the /home directory
# on the target rootfs

cp -a autorun-qemu.sh "${OUTDIR}/rootfs/home/"
cp -a writer "${OUTDIR}/rootfs/home/"
cp -a finder.sh "${OUTDIR}/rootfs/home/"
cp -a finder-test.sh "${OUTDIR}/rootfs/home/"
mkdir -p "${OUTDIR}/rootfs/home/conf/"
cp conf/assignment.txt "${OUTDIR}/rootfs/home/conf/"
cp conf/username.txt "${OUTDIR}/rootfs/home/conf/"
mkdir -p "${OUTDIR}/rootfs/conf/"
cp conf/assignment.txt "${OUTDIR}/rootfs/conf/"
cp conf/username.txt "${OUTDIR}/rootfs/conf/"

# Chown the root directory

sudo chown -R root:root "${OUTDIR}/rootfs"

# Create initramfs.cpio.gz

cd "${OUTDIR}/rootfs"

find . | cpio -H newc -ov --owner root:root > "${OUTDIR}/initramfs.cpio"

cd "${OUTDIR}"
gzip -f initramfs.cpio 
