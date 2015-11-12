#!/bin/bash

#--------------------------------------------------------------------------------------------------------------------------------
echo "deb http://repo.aptly.info/ squeeze main" > /etc/apt/sources.list.d/aptly.list
apt-key adv --keyserver keys.gnupg.net --recv-keys E083A3782A194991
apt-get update

apt-get install whiptail bc dialog git-core aptly device-tree-compiler pv bc lzop zip binfmt-support bison build-essential ccache debootstrap flex gawk gcc-arm-linux-gnueabihf lvm2 qemu-user-static u-boot-tools uuid-dev zlib1g-dev unzip libusb-1.0-0-dev parted pkg-config expect gcc-arm-linux-gnueabi libncurses5-dev whiptail debian-keyring debian-archive-keyring ntpdate

#--------------------------------------------------------------------------------------------------------------------------------
