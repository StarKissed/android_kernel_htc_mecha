#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

PROPER=`echo $2 | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`

HANDLE=TwistedZero
KERNELSPEC=/Volumes/android/leanKernel-tbolt-ics
ANDROIDREPO=/Volumes/android/Twisted-Playground
DROIDGITHUB=TwistedUmbrella/Twisted-Playground.git
MECHAREPO=/Volumes/android/github-aosp_source/android_device_htc_mecha
MECHAGITHUB=ThePlayground/android_device_htc_mecha.git
ICSREPO=/Volumes/android/github-aosp_source/android_system_core
SPDTWKR=/Volumes/android/Twisted-Playground/ScriptFusion
MSMREPO=/Volumes/android/github-aosp_source/android_device_htc_msm7x30-common
zipfile=$HANDLE"_leanKernel_184Mhz_AOSP.zip"

CPU_JOB_NUM=16
TOOLCHAIN_PREFIX=arm-none-eabi-

echo "Config Name? "
ls config
read configfile
cp -R config/$configfile .config

make clean -j$CPU_JOB_NUM

make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TOOLCHAIN_PREFIX

# make nsio module here for now
cd nsio*
make
cd ..

find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

cp .config arch/arm/configs/lean_aosp_defconfig

if [ -e arch/arm/boot/zImage ]; then

if [ "$1" == "1" ]; then

echo "adding to build"

cp -R arch/arm/boot/zImage $MECHAREPO/kernel/kernel
rm -r $MECHAREPO/kernel/lib/modules/*
for j in $(find . -name "*.ko"); do
cp -R "${j}" $MECHAREPO/kernel/lib/modules
done

cd $MECHAREPO
git commit -a -m "Automated Kernel Update - ${PROPER}"
git push git@github.com:$MECHAGITHUB HEAD:ics -f

else

cp -R $ICSREPO/rootdir/init.rc $KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R $ICSREPO/rootdir/ueventd.rc $KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R $SPDTWKR/speedtweak.sh $KERNELSPEC/mkboot.aosp/boot.img-ramdisk/sbin
cp -R $MECHAREPO/kernel/init.mecha.rc $KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R $MECHAREPO/kernel/ueventd.mecha.rc $KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R $MSMREPO/kernel/init.msm7x30.usb.rc $KERNELSPEC/mkboot.aosp/boot.img-ramdisk

if [ ! -e zip.aosp/system/lib ]; then
mkdir zip.aosp/system/lib
fi
if [ ! -e zip.aosp/system/lib/modules ]; then
mkdir zip.aosp/system/lib/modules
else
rm -r zip.aosp/system/lib/modules
mkdir zip.aosp/system/lib/modules
fi

for j in $(find . -name "*.ko"); do
cp -R "${j}" zip.aosp/system/lib/modules
done
cp -R arch/arm/boot/zImage mkboot.aosp

cd mkboot.aosp
echo "making boot image"
./img.sh

echo "making zip file"
cp -R boot.img ../zip.aosp
cd ../zip.aosp
rm *.zip
zip -r $zipfile *
cp -R $KERNELSPEC/zip.aosp/$zipfile $ANDROIDREPO/Kernel/$zipfile
cd $ANDROIDREPO
git checkout gh-pages
git commit -a -m "Automated Patch Kernel Build - ${PROPER}"
git push git@github.com:$DROIDGITHUB HEAD:ics -f

fi

fi

cd $KERNELSPEC
