#!/bin/bash

PWD=`pwd`
QEMU="$PWD/qemu/x86_64-softmmu/qemu-system-x86_64 -enable-kvm -L $PWD/qemu-kvm-build/opt/sqb/share/qemu -nodefconfig -nodefaults"
SpicePort="6600"
VncPort="0"
VncWsPort="5700"
Nic1Mac="52:54:00:cd:62:1a"
VmName=F23

Spicy="spicy"


MachineSpec=" -smp 2,sockets=1,cores=2,threads=1 -m 1024"

HdImage="$PWD/vm_images/f23.qcow2"

HdOpt=" -drive if=virtio,cache.direct=on,aio=native,file=$HdImage"


SpiceOpt=" -spice port=${SpicePort},addr=0.0.0.0,disable-ticketing,seamless-migration=on"

# vnc web socket requires  "gnutls >= 2.9.10", which is not available natively on CentOS 6.
# so we turn it off for now.
VncOpt=" -vnc 0.0.0.0:$VncPort,websocket=$VncWsPort"
#VncOpt=" -vnc 0.0.0.0:$VncPort"
#

DisplayOpt="$SpiceOpt $VncOpt"

UsbOpt=" -usb -readconfig $PWD/qemu/docs/ich9-ehci-uhci.cfg "  # enable the USB driver & create both  usb1.1 and usb2.0 bus
#
Redir1=" -chardev spicevmc,id=charredir0,name=usbredir -device usb-redir,chardev=charredir0,id=redir0"
Redir2=" -chardev spicevmc,id=charredir1,name=usbredir -device usb-redir,chardev=charredir1,id=redir1"

RedirOpt=" ${Redir1} ${Redir2} ${Redir3} ${Redir4}  ${Redir5} $UsbPass1"

  # create both 
InputOpt=" -device usb-tablet,id=input0,bus=ehci.0 "   # specify 'bus=echi.0' to attach the device to usb2.0 bus

#VgaOpt=" -device qxl-vga,id=video0,ram_size=67108864,vram_size=67108864"
VgaOpt=" -device VGA,id=video0,vgamem_mb=64"


#AudioOpt=" -soundhw ac97"
AudioOpt=" -device intel-hda,id=sound0 -device hda-duplex,id=sound0-codec0,bus=sound0.0,cad=0"


#
# better nic options , more similar to libvirt
# to hot-plug more nic, just
#     netdev_add tap,id=nicX,script=$PWD/qemu-ifup2,downscript=$PWD/qemu-ifdown2
#     device_add virtio-net-pci,netdev=nicX,mac=XXXXXXXX  
Nic1=" -netdev  tap,id=nic1,script=$PWD/qemu-ifup,downscript=$PWD/qemu-ifdown -device virtio-net-pci,netdev=nic1,mac=$Nic1Mac"
NetOptNone=" -net none"

#probe if we can use the 'default network' of libvirt.
if ip link show virbr0
then
    NetOpt=" $Nic1"
else
    NetOpt=" $NetOptNone"
fi

# linux guests    use '-rtc base=utc,'
# while windows guests need '-rtc=localtime'
OtherOpt=" -balloon none -no-hpet -rtc base=utc,driftfix=none -global kvm-pit.lost_tick_policy=discard  -msg timestamp=on"

#TraceOpt=" -trace events=$PWD/dig_into/qemu_trace_qxl"


MonOpt=" -chardev socket,id=charmonitor,path=$PWD/dig_into/qmon_$VmName,server,nowait -mon chardev=charmonitor,id=monitor,mode=readline"
QmpOpt=" -chardev socket,id=charqmp,path=$PWD/dig_into/qmp_$VmName,server,nowait -mon chardev=charqmp,id=qmp,mode=control"
#sudo -S  SPICE_DEBUG_LEVEL=4   $QEMU $HdOpt $DisplayOpt 


# Ref: http://spice-space.org/page/Whiteboard/AgentProtocol
#  -device virtio-serial-pci,id=virtio-serial0,max_ports=16,bus=pci.0,addr=0x5 -chardev spicevmc,name=vdagent,id=vdagent
#  -device virtserialport,nr=1,bus=virtio-serial0.0,chardev=vdagent,name=com.redhat.spice.0

VirtioSerialOpt=" -device virtio-serial-pci,id=virtio-serial0,bus=pci.0,addr=0x5"


# SPICE_DEBUG_LEVEL=  最大是4
echo "we need 'sudo' to run qemu with kvm and tap nic"
sudo echo "let's go"
#sudo  SPICE_DEBUG_LEVEL=2  LD_PRELOAD=libkeepalive.so KEEPIDLE=60 KEEPINTVL=60 KEEPCNT=5 \

cmd_line=" $QEMU $MachineSpec $HdOpt  \
 $VirtioSerialOpt $DisplayOpt $VgaOpt $AudioOpt \
 $UsbOpt $RedirOpt $InputOpt $NetOpt $OtherOpt $TraceOpt $MonOpt $QmpOpt"

lib_path=/usr/local/lib:/usr/local/lib64:$LD_LIBRARY_PATH

#echo $cmd_line
sudo  SPICE_DEBUG_LEVEL=2 LD_LIBRARY_PATH=$lib_path  $cmd_line &

sleep 1

sudo chmod a+w $PWD/dig_into/qmon_$VmName

$Spicy -h localhost -p ${SpicePort} &
