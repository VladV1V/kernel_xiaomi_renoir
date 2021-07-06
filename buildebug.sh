#!/bin/bash

# Resources
THREAD="-j$(nproc --all)"

export CLANG_PATH=/home/vlad/toolchains/proton-clang/bin/
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=/home/vlad/toolchains/proton-clang/bin/aarch64-linux-gnu- CC=clang CXX=clang++

DEFCONFIG="renoir_defconfig"

# Paths
KERNEL_DIR=`pwd`
ZIMAGE_DIR="$KERNEL_DIR/out/arch/arm64/boot/"

# Vars
export LOCALVERSION=-debug
export ARCH=arm64
export SUBARCH=$ARCH
export KBUILD_BUILD_USER=vlad

DATE_START=$(date +"%s")

echo
echo "-------------------"
echo "Making Kernel:"
echo "-------------------"
echo

make CC="ccache clang" CXX="ccache clang++" O=out $DEFCONFIG
make CC="ccache clang" CXX="ccache clang++" O=out $THREAD 2>&1 | tee kernel.log

echo
echo "-------------------"
echo "Build Completed in:"
echo "-------------------"
echo

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo
ls -a $ZIMAGE_DIR

cd $KERNEL_DIR
if grep -q "error: " kernel.log
then
	echo; echo; grep -n "error: " kernel.log; echo "\n\n"
	chown -R vlad *
	chgrp -R vlad *
	exit 0
elif grep -q "undefined reference to" kernel.log
then
	echo; echo; grep -n "undefined reference to" kernel.log; echo "\n\n"
	chown -R vlad *
	chgrp -R vlad *
	exit 0
elif grep -q "undefined symbol" kernel.log
then
	echo; echo; grep -n "undefined symbol" kernel.log; echo "\n\n"
	chown -R vlad *
	chgrp -R vlad *
	exit 0
elif grep -q "Error 2" kernel.log
then
	exit 0
else
TIME="$(date "+%Y%m%d-%H%M%S")"
mkdir -p tmp
cp -fp $ZIMAGE_DIR/Image tmp
cp -rp ./anykernel/* tmp
cd tmp
7za a -mx9 $TIME-tmp.zip *
cd ..
rm Noob*.zip
cp -fp tmp/$TIME-tmp.zip Noob-Kernel-Mi11Lite5G-$TIME.zip
rm -rf tmp
chown -R vlad *
chgrp -R vlad *
fi
