#!/bin/bash

#-------------------------------------------------------------------------------

set -e
set -x

#-------------------------------------------------------------------------------

BASE=$(cd `dirname $0` && pwd)
SOURCES="${BASE}/sources"

BUILD="${BASE}/build"
mkdir -p ${BUILD}

#-------------------------------------------------------------------------------

if [ ! -f /etc/apt/sources.list.d/aptly.list ]; then
	
	echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list
	apt-key adv --keyserver keys.gnupg.net --recv-keys E083A3782A194991
	apt-get update
	
	apt-get install aptly bc binfmt-support bison build-essential ccache debhelper debian-archive-keyring debian-keyring debootstrap device-tree-compiler devscripts dialog expect fakeroot flex gawk gcc-arm-linux-gnueabi gcc-arm-linux-gnueabihf git-core libncurses5-dev libnl-3-dev libnl-genl-3-dev libssl-dev libusb-1.0-0-dev lvm2 lzop ntpdate parted pkg-config pv qemu-user-static u-boot-tools unzip uuid-dev whiptail zip zlib1g-dev
	
fi

#-------------------------------------------------------------------------------

cd ${SOURCES}/sunxi-tools

if [ ! -f ${BUILD}/fex2bin ] || [ ! -f ${BUILD}/bin2fex ]; then
	
	make -j1 -s clean #>/dev/null 2>&1
	make -j5 -s fex2bin #>/dev/null 2>&1
	make -j5 -s bin2fex #>/dev/null 2>&1
	
	cp -f bin2fex ${BUILD}/fex2bin
	cp -f bin2fex ${BUILD}/bin2fex
	
fi

#if [ ! -f ${BUILD}/arm-fex2bin ] || [ ! -f ${BUILD}/arm-bin2fex ] || [ ! -f ${BUILD}/arm-nand-part ]; then
if [ ! -f ${BUILD}/arm-fex2bin ] || [ ! -f ${BUILD}/arm-bin2fex ]; then
	
	make -j1 -s clean #>/dev/null 2>&1
	make -j5 fex2bin CC=arm-linux-gnueabi-gcc #>/dev/null 2>&1
	make -j5 bin2fex CC=arm-linux-gnueabi-gcc #>/dev/null 2>&1
	#make -j5 nand-part CC=arm-linux-gnueabi-gcc #>/dev/null 2>&1
	
	cp -f bin2fex ${BUILD}/arm-fex2bin
	cp -f bin2fex ${BUILD}/arm-bin2fex
	#cp -f nand-part ${BUILD}/arm-nand-part
	
fi

#-------------------------------------------------------------------------------

cd ${SOURCES}/u-boot

if [ ! -f ${BUILD}/u-boot-sunxi-with-spl.bin ] || [ ! -f ${BUILD}/u-boot.bin ] || [ ! -f ${BUILD}/sunxi-spl.bin ]; then
	
	make -j1 -s ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean #>/dev/null 2>&1
	make -j5 Bananapro_defconfig CROSS_COMPILE=arm-linux-gnueabihf- #>/dev/null 2>&1
	
	[ -f .config ] && sed -i 's/CONFIG_LOCALVERSION=""/CONFIG_LOCALVERSION="-armbian"/g' .config
	[ -f .config ] && sed -i 's/CONFIG_LOCALVERSION_AUTO=.*/# CONFIG_LOCALVERSION_AUTO is not set/g' .config
	touch .scmversion
	if [ "$(cat .config | grep CONFIG_ARMV7_BOOT_SEC_DEFAULT=y)" == "" ]; then
		echo "CONFIG_ARMV7_BOOT_SEC_DEFAULT=y" >> .config
		echo "CONFIG_OLD_SUNXI_KERNEL_COMPAT=y" >> .config
	fi
	
	make -j5 CROSS_COMPILE=arm-linux-gnueabihf- #>/dev/null 2>&1
	
	cp -f u-boot-sunxi-with-spl.bin ${BUILD}/u-boot-sunxi-with-spl.bin
	cp -f u-boot.bin ${BUILD}/u-boot.bin
	cp -f spl/sunxi-spl.bin ${BUILD}/sunxi-spl.bin
	
fi

#-------------------------------------------------------------------------------

#mkdir -p $SOURCES/$LINUXSOURCE/drivers/video/fbtft
#mount --bind $SOURCES/$MISC4_DIR $SOURCES/$LINUXSOURCE/drivers/video/fbtft

#-------------------------------------------------------------------------------

cd ${SOURCES}/linux-sunxi-dev

if [ ! -f ${BUILD}/zImage ]; then
	
	make -j1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean
	
	cp ../../linux-sun7i.config .config
	sed -i 's/CONFIG_GMAC_CLK_SYS=y/CONFIG_GMAC_CLK_SYS=y\nCONFIG_GMAC_FOR_BANANAPI=y/g' .config
	export LOCALVERSION="-sun7i"
	
	make -j5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- oldconfig
	make -j5 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all zImage
	
	cp -f arch/arm/boot/zImage ${BUILD}/zImage
	
fi

if [ ! -f ${BUILD}/linux-firmware-image_*_armhf.deb ] || [ ! -f ${BUILD}/linux-headers-*-sun7i_*_armhf.deb ] || [ ! -f ${BUILD}/linux-image-*-sun7i_*_armhf.deb ] || [ ! -f ${BUILD}/linux-libc-dev_*_armhf.deb ]; then
	
	make -j1 deb-pkg KDEB_PKGVERSION="2.0" LOCALVERSION="-sun7i" KBUILD_DEBARCH=armhf ARCH=arm DEBFULLNAME="Simon Pascal Baur" DEBEMAIL="sbausis@gmx.net" CROSS_COMPILE=arm-linux-gnueabihf-
	
	mv -f ${SOURCES}/linux-firmware-image_*_armhf.deb ${BUILD}/
	mv -f ${SOURCES}/linux-headers-*-sun7i_*_armhf.deb ${BUILD}/
	mv -f ${SOURCES}/linux-image-*-sun7i_*_armhf.deb ${BUILD}/
	mv -f ${SOURCES}/linux-libc-dev_*_armhf.deb ${BUILD}/
	
fi

#-------------------------------------------------------------------------------

cd ${SOURCES}/rt8192cu

if [ ! -f ${BUILD}/8192cu.ko ]; then
	
	make -j1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- clean #>/dev/null 2>&1
	make -j1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KSRC=${SOURCES}/linux-sunxi-dev/ #>/dev/null 2>&1
	
	cp -f 8192cu.ko ${BUILD}/8192cu.ko
	
fi

#-------------------------------------------------------------------------------

cd ${SOURCES}/sunxi-display-changer

if [ ! -f ${BUILD}/a10disp ]; then
	
	make clean #>/dev/null 2>&1

	cp -f ../linux-sunxi-dev/include/video/sunxi_disp_ioctl.h sunxi_disp_ioctl.h

	make -j1 ARCH=arm CC=arm-linux-gnueabihf-gcc KSRC=${SOURCES}/linux-sunxi-dev/ #>/dev/null 2>&1
	
	cp -f a10disp ${BUILD}/a10disp
fi

#-------------------------------------------------------------------------------

if [ ! -d ${SOURCES}/usb-redirector-linux-arm-eabi ]; then
	
	wget -O - -q http://www.incentivespro.com/usb-redirector-linux-arm-eabi.tar.gz | tar -xz -C ${SOURCES}
	
fi

cd  ${SOURCES}/usb-redirector-linux-arm-eabi

if [ ! -f ${BUILD}/tusbd.ko ]; then
	
	(cd ${SOURCES}/usb-redirector-linux-arm-eabi/files/modules/src/tusbd
	
	sed -e "s/f_dentry/f_path.dentry/g" -i usbdcdev.c
	
	make -j1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- KERNELDIR=${SOURCES}/linux-sunxi-dev/
	
	cp -f tusbd.ko ${BUILD}/tusbd.ko)
	
fi

if [ ! -f ${BUILD}/usbclnt ] || [ ! -f ${BUILD}/usbsrv ] || [ ! -f ${BUILD}/usbsrvd ] || [ ! -f ${BUILD}/usbsrvd-cl ] || [ ! -f ${BUILD}/usbsrvd-srv ]; then
	
	cp -f files/usbclnt ${BUILD}/usbclnt
	cp -f files/usbsrv ${BUILD}/usbsrv
	cp -f files/usbsrvd ${BUILD}/usbsrvd
	cp -f files/usbsrvd-cl ${BUILD}/usbsrvd-cl
	cp -f files/usbsrvd-srv ${BUILD}/usbsrvd-srv
	
fi

#-------------------------------------------------------------------------------

cd ${SOURCES}/hostapd-ap6210

if [ ! -f ${BUILD}/hostapd ] || [ ! -f ${BUILD}/hostapd_cli ]; then
	
	make -j1 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
	
	cp hostapd/hostapd ${BUILD}/hostapd
	cp hostapd/hostapd_cli ${BUILD}/hostapd_cli
	
fi

#-------------------------------------------------------------------------------

exit 0
