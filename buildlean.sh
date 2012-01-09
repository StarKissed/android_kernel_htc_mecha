#!/bin/sh

# Copyright (C) 2011 Twisted Playground

# This script is designed to compliment .bash_profile code to automate the build process by adding a typical shell command such as:
# function function buildKernel { cd /Volumes/android/android-tzb_ics4.0.1/kernel/leanKernel-tbolt-ics; echo "Ace, Mecha, Release?"; read device; ./buildlean.sh 1 $device; }
# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

PROPER=`echo $1 | sed 's/\([a-z]\)\([a-zA-Z0-9]*\)/\u\1\2/g'`

HANDLE=TwistedZero
BUILDDIR=/Volumes/android/android-tzb_ics4.0.1
KERNELSPEC=leanKernel-tbolt-ics
DROPBOX=/Users/$HANDLE/Dropbox/IceCreamSammy
MECHAREPO=github-aosp_source/android_device_htc_mecha
MECHAGITHUB=TwistedUmbrella/android_device_htc_mecha.git
ACEREPO=github-aosp_source/android_device_htc_ace
ACEGITHUB=TwistedUmbrella/android_device_htc_ace.git
MSMREPO=github-aosp_source/android_device_htc_msm7x30-common

CPU_JOB_NUM=16
TOOLCHAIN_PREFIX=arm-none-eabi-

echo "Config Name? ";
ls config
read configfile
cp -R config/$configfile .config

cp -R ../../../$ACEREPO/kernel/init.spade.rc $BUILDDIR/kernel/$KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R ../../../$ACEREPO/kernel/ueventd.spade.rc $BUILDDIR/kernel/$KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R ../../../$MECHAREPO/kernel/init.mecha.rc $BUILDDIR/kernel/$KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R ../../../$MECHAREPO/kernel/ueventd.mecha.rc $BUILDDIR/kernel/$KERNELSPEC/mkboot.aosp/boot.img-ramdisk
cp -R ../../../$MSMREPO/kernel/init.msm7x30.usb.rc $BUILDDIR/kernel/$KERNELSPEC/mkboot.aosp/boot.img-ramdisk

make clean -j$CPU_JOB_NUM

sed -i s/CONFIG_LOCALVERSION=\"-"$HANDLE"-.*\"/CONFIG_LOCALVERSION=\"-"$HANDLE"-AOSP\"/ .config

if [ $1 -eq 2 ]; then
sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=n/" .config
zipfile=$HANDLE"_leanKernel_AOSP.zip"
else
sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=y/" .config
zipfile=$HANDLE"_leanKernel_184Mhz_AOSP.zip"
fi

make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TOOLCHAIN_PREFIX

# make nsio module here for now
cd nsio*
make
cd ..

find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

cp .config arch/arm/configs/lean_aosp_defconfig

if [ "$2" == "mecha" ]; then

echo "adding to build"

if [ ! -e ../../../$MECHAREPO/kernel ]; then
mkdir ../../../$MECHAREPO/kernel
fi
if [ ! -e ../../../$MECHAREPO/kernel/lib ]; then
mkdir ../../../$MECHAREPO/kernel/lib
fi
if [ ! -e ../../../$MECHAREPO/kernel/lib/modules ]; then
mkdir ../../../$MECHAREPO/kernel/lib/modules
fi

cp -R drivers/net/wireless/bcm4329/bcm4329.ko ../../../$MECHAREPO/kernel/lib/modules
cp -R drivers/net/tun.ko ../../../$MECHAREPO/kernel/lib/modules
cp -R drivers/staging/zram/zram.ko ../../../$MECHAREPO/kernel/lib/modules
cp -R lib/lzo/lzo_decompress.ko ../../../$MECHAREPO/kernel/lib/modules
cp -R lib/lzo/lzo_compress.ko ../../../$MECHAREPO/kernel/lib/modules
if [ ! -e nsio*/*.ko ]; then
cp -R nsio*/*.ko ../../../$MECHAREPO/kernel/lib/modules
fi
cp -R fs/cifs/cifs.ko ../../../$MECHAREPO/kernel/lib/modules
cp -R arch/arm/boot/zImage ../../../$MECHAREPO/kernel/kernel

if [ -e ../../../$MECHAREPO/kernel/kernel ]; then
cd ../../../$MECHAREPO
git commit -a -m "Automated Kernel Update - ${PROPER}"
git push git@github.com:$MECHAGITHUB HEAD:ics
fi

elif [ "$2" == "ace" ]; then

echo "adding to build"

if [ ! -e ../../../$ACEREPO/kernel ]; then
mkdir ../../../$ACEREPO/kernel
fi
if [ ! -e ../../../$ACEREPO/kernel/lib ]; then
mkdir ../../../$ACEREPO/kernel/lib
fi
if [ ! -e ../../../$ACEREPO/kernel/lib/modules ]; then
mkdir ../../../$ACEREPO/kernel/lib/modules
fi

cp -R drivers/net/wireless/bcm4329/bcm4329.ko ../../../$ACEREPO/kernel/lib/modules
cp -R drivers/net/tun.ko ../../../$ACEREPO/kernel/lib/modules
cp -R drivers/staging/zram/zram.ko ../../../$ACEREPO/kernel/lib/modules
cp -R lib/lzo/lzo_decompress.ko ../../../$ACEREPO/kernel/lib/modules
cp -R lib/lzo/lzo_compress.ko ../../../$MECHAREPO/kernel/lib/modules
if [ ! -e nsio*/*.ko ]; then
cp -R nsio*/*.ko ../../../$ACEREPO/kernel/lib/modules
fi
cp -R fs/cifs/cifs.ko ../../../$ACEREPO/kernel/lib/modules
cp -R arch/arm/boot/zImage ../../../$ACEREPO/kernel/kernel

if [ -e ../../../$ACEREPO/kernel/kernel ]; then
cd ../../../$ACEREPO
git commit -a -m "Automated Kernel Update - ${PROPER}"
git push git@github.com:$ACEGITHUB HEAD:ics
fi

else

if [ ! -e zip.aosp ]; then
mkdir zip.aosp
fi
if [ ! -e zip.aosp/system ]; then
mkdir zip.aosp/system
fi
if [ ! -e zip.aosp/system/lib ]; then
mkdir zip.aosp/system/lib
fi
if [ ! -e zip.aosp/system/lib/modules ]; then
mkdir zip.aosp/system/lib/modules
else
rm -r zip.aosp/system/lib/modules
mkdir zip.aosp/system/lib/modules
fi
cp drivers/net/wireless/bcm4329/bcm4329.ko zip.aosp/system/lib/modules
cp drivers/net/tun.ko zip.aosp/system/lib/modules
cp drivers/staging/zram/zram.ko zip.aosp/system/lib/modules
cp lib/lzo/lzo_decompress.ko zip.aosp/system/lib/modules
cp lib/lzo/lzo_compress.ko zip.aosp/system/lib/modules
if [ ! -e nsio*/*.ko ]; then
cp nsio*/*.ko zip.aosp/system/lib/modules
fi
cp fs/cifs/cifs.ko zip.aosp/system/lib/modules
cp arch/arm/boot/zImage mkboot.aosp/

cd mkboot.aosp
echo "making boot image"
./img.sh

echo "making zip file"
cp boot.img ../zip.aosp
cd ../zip.aosp
rm *.zip
zip -r $zipfile *
rm /tmp/*.zip
cp *.zip /tmp
cp -R $BUILDDIR/kernel/$KERNELSPEC/zip.aosp/$zipfile $DROPBOX/$zipfile

fi