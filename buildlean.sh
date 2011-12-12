#!/bin/sh

CPU_JOB_NUM=16
TOOLCHAIN_PREFIX=arm-none-eabi-

export USE_CCACHE=1
export CCACHE_DIR=/Users/TwistedZero/.ccache
../../prebuilt/darwin-x86/ccache/ccache -M 40G
make clean -j$CPU_JOB_NUM

if [ $2 ]; then
cp -R config/${2} .config
fi

sed -i s/CONFIG_LOCALVERSION=\"-imoseyon-.*\"/CONFIG_LOCALVERSION=\"-imoseyon-${3}AOSP\"/ .config

if [ $1 -eq 2 ]; then
sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=n/" .config
zipfile="imoseyon_leanKernel_v${3}AOSP.zip"
else
sed -i "s/^.*UNLOCK_184.*$/CONFIG_UNLOCK_184MHZ=y/" .config
zipfile="imoseyon_leanKernel_184Mhz_v${3}AOSP.zip"
fi

export USE_CCACHE=1
export CCACHE_DIR=/Users/TwistedZero/.ccache
../../prebuilt/darwin-x86/ccache/ccache -M 40G
make -j$CPU_JOB_NUM ARCH=arm CROSS_COMPILE=$TOOLCHAIN_PREFIX

# make nsio module here for now
cd nsio*
make
cd ..

find . -name "*.ko" | xargs ${TOOLCHAIN_PREFIX}strip --strip-unneeded

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
cp .config arch/arm/configs/lean_aosp_defconfig

if [ ! $3 ]; then

echo "adding to build"

if [ ! -e ../../device/htc/mecha/kernel ]; then
mkdir ../../device/htc/mecha/kernel
fi
if [ ! -e ../../device/htc/mecha/kernel/lib ]; then
mkdir ../../device/htc/mecha/kernel/lib
fi
if [ ! -e ../../device/htc/mecha/kernel/lib/modules ]; then
mkdir ../../device/htc/mecha/kernel/lib/modules
fi

cp -R drivers/net/wireless/bcm4329/bcm4329.ko ../../device/htc/mecha/kernel/lib/modules
cp -R drivers/net/tun.ko ../../device/htc/mecha/kernel/lib/modules
cp -R drivers/staging/zram/zram.ko ../../device/htc/mecha/kernel/lib/modules
cp -R lib/lzo/lzo_decompress.ko ../../device/htc/mecha/kernel/lib/modules
cp -R lib/lzo/lzo_compress.ko ../../device/htc/mecha/kernel/lib/modules
if [ ! -e nsio*/*.ko ]; then
cp -R nsio*/*.ko ../../device/htc/mecha/kernel/lib/modules
fi
cp -R fs/cifs/cifs.ko ../../device/htc/mecha/kernel/lib/modules
cp -R arch/arm/boot/zImage ../../device/htc/mecha/kernel/kernel

else

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

fi
