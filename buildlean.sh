#!/bin/sh

# This script is designed to compliment .bash_profile code to automate the build process by adding a typical shell command such as:
# function buildKernel { cd /Volumes/android/android-tzb_ics4.0.1/kernel/leanKernel-tbolt-ics; echo "Config Name? "; ls config; read config; ./buildlean.sh 1 $config 1; }
# This script is designed by Twisted Playground for use on MacOSX 10.7 but can be modified for other distributions of Mac and Linux

HANDLE=TwistedZero
BUILDDIR=/Volumes/android/android-tzb_ics4.0.1
CCACHEBIN=prebuilt/darwin-x86/ccache/ccache
KERNELSPEC=leanKernel-tbolt-ics
USERLOCAL=/Users/$HANDLE
DROPBOX=/Users/$HANDLE/Dropbox/IceCreamSammy
DEVICEREPO=github-aosp_source/android_device_htc_mecha
GITHUB=TwistedUmbrella/android_device_htc_mecha.git

CPU_JOB_NUM=16
TOOLCHAIN_PREFIX=arm-none-eabi-

export USE_CCACHE=1
export CCACHE_DIR=$USERLOCAL/.ccache/kernel
../../$CCACHEBIN -M 40G
make clean -j$CPU_JOB_NUM
rm -R $CCACHE_DIR/*

if [ $2 ]; then
cp -R config/${2} .config
fi

sed -i s/CONFIG_LOCALVERSION=\"-"$HANDLE"-.*\"/CONFIG_LOCALVERSION=\"-"$HANDLE"-AOSP\"/ .config

if [ $1 -eq 2 ]; then
sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=n/" .config
zipfile=$HANDLE"_leanKernel_AOSP.zip"
else
sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=y/" .config
zipfile=$HANDLE"_leanKernel_184Mhz_AOSP.zip"
fi

export USE_CCACHE=1
export CCACHE_DIR=$USERLOCAL/.ccache/kernel
../../$CCACHEBIN -M 40G
make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TOOLCHAIN_PREFIX
rm -R $CCACHE_DIR/*

# make nsio module here for now
cd nsio*
make
cd ..

find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

cp .config arch/arm/configs/lean_aosp_defconfig

if [ ! $3 ]; then

echo "adding to build"

if [ ! -e ../../../$DEVICEREPO/kernel ]; then
mkdir ../../../$DEVICEREPO/kernel
fi
if [ ! -e ../../../$DEVICEREPO/kernel/lib ]; then
mkdir ../../../$DEVICEREPO/kernel/lib
fi
if [ ! -e ../../../$DEVICEREPO/kernel/lib/modules ]; then
mkdir ../../../$DEVICEREPO/kernel/lib/modules
fi

cp -R drivers/net/wireless/bcm4329/bcm4329.ko ../../../$DEVICEREPO/kernel/lib/modules
cp -R drivers/net/tun.ko ../../../$DEVICEREPO/kernel/lib/modules
cp -R drivers/staging/zram/zram.ko ../../../$DEVICEREPO/kernel/lib/modules
cp -R lib/lzo/lzo_decompress.ko ../../../$DEVICEREPO/kernel/lib/modules
cp -R lib/lzo/lzo_compress.ko ../../../$DEVICEREPO/kernel/lib/modules
if [ ! -e nsio*/*.ko ]; then
cp -R nsio*/*.ko ../../../$DEVICEREPO/kernel/lib/modules
fi
cp -R fs/cifs/cifs.ko ../../../$DEVICEREPO/kernel/lib/modules
cp -R arch/arm/boot/zImage ../../../$DEVICEREPO/kernel/kernel

if [ -e ../../../$DEVICEREPO/kernel/kernel ]; then
cd ../../../$DEVICEREPO
git commit -a -m "Automated Kernel Update"
git push git@github.com:$GITHUB HEAD:ics
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