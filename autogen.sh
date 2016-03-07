#!/bin/bash -e

git submodule sync
git submodule update  --init spice qemu spice-protocol libusbx usbredir

pushd .
echo "###########################################################"
echo "####  goto autogen spice-protocol:                     ####"
echo "###########################################################"
cd spice-protocol 
NOCONFIGURE=1 ./autogen.sh
popd


pushd .
echo "###########################################################"
echo "####  goto autogen spice:                              ####"
echo "###########################################################"
cd spice
NOCONFIGURE=1 ./autogen.sh
popd

pushd .
echo "###########################################################"
echo "####  goto autogen libusb                              ####"
echo "###########################################################"
cd libusbx
NOCONFIGURE=1 ./autogen.sh
popd


pushd .
echo "###########################################################"
echo "####  download vm image from web                       ####"
echo "###########################################################"

cd vm_images/base

TheImage=Fedora-Cloud-Base-23-20151030.i386

## The offical location
ImageUrl=https://download.fedoraproject.org/pub/fedora/linux/releases/23/Cloud/i386/Images/${TheImage}.raw.xz
## mirror in RPC
ImageUrl=https://mirrors.ustc.edu.cn/fedora/linux/releases/23/Cloud/i386/Images/${TheImage}.raw.xz
wget $ImageUrl
unxz ${TheImage}.raw.xz
cd ..
qemu-img create -f qcow2 -b base/${TheImage}.raw f23.qcow2


