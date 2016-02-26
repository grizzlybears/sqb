SHELL:=/bin/bash
BuildRoot:=$(shell pwd)

ifeq ($(Release),1)
	DebugOpt= 
else
	DebugOpt= -ggdb
endif


ifneq (,$(findstring  Red,$(shell gcc --version | head -n1))) 
	# on rh famaly, trace default to 'dtrace'   , same as rhqemu
	TraceQemuOpt= --enable-trace-backend=dtrace
else
	TraceQemuOpt= --enable-trace-backend=simple
endif


SpiceStatSrc=$(BuildRoot)/spice-stat
SpiceStatMakefile=$(SpiceStatSrc)/Makefile
SpiceStatExe=$(SpiceStatSrc)/spicestat

SpiceServerLib=$(BuildRoot)/lib/libspice-server.a
SpiceServerSrc=$(BuildRoot)/spice
SpiceServerMakefile=$(SpiceServerSrc)/Makefile

SpiceProtocolDir=$(BuildRoot)/include/spice-1
SpiceProtocolHeader=$(SpiceProtocolDir)/spice/protocol.h
SpiceProtocolSrc=$(BuildRoot)/spice-protocol
SpiceProtocolMakefile=$(SpiceProtocolSrc)/Makefile 

SpiceProtocolPc=$(BuildRoot)/lib/pkgconfig/spice-protocol.pc

QemuSrc=$(BuildRoot)/qemu
QemuExe=$(QemuSrc)/x86_64-softmmu/qemu-system-x86_64
QemuMakefile=$(QemuSrc)/config-host.mak
QemuPackDir=$(BuildRoot)/qemu-kvm-build

none:
	@echo "Usage:"
	@echo "    To prepare qemu build env on centos  -->  make prepare_rh "
	@echo "    To prepare build env on Fedora      -->  make prepare_fc "
	@echo "    To build qemu          -->  make [Release=1]  qemu"
	@echo "    To build spice then qemu with spice    -->  make [Release=1]  spiceqemu"
	@echo "    To test qemu without install -->  Firt run 'make buildqemu' once,  then './testqemu.bash' as u like"

.PHONY: prepare_rh prepare_fc clean clean_spice remove_output

all:qemu

buildqemu:$(QemuExe)
	mkdir -p $(QemuPackDir)
	make -C $(QemuSrc) install DESTDIR="$(QemuPackDir)"

qemu:$(QemuExe)

spiceqemu: ${SpiceServerMakefile} ${QemuMakefile}
	make -C ${SpiceServerSrc} install
	rm -f ${QemuExe}
	make -C ${QemuSrc}

spicestat:$(SpiceStatExe)
	
$(SpiceStatExe): $(SpiceStatMakefile)
	make -C $(SpiceStatSrc)

$(SpiceStatMakefile):
	cd $(SpiceStatSrc); \
        PKG_CONFIG_PATH="$(BuildRoot)/lib/pkgconfig" CFLAGS="-fPIC" CXXFLAGS="-fPIC" \
        ./configure

test:
	./testqemu.bash


installqemu:$(QemuExe)
	sudo make -C $(QemuSrc) install


$(QemuExe):  $(QemuMakefile)
	make -C $(QemuSrc)

config_qemu: $(QemuMakefile)

## Here is qemu configure options from  qemu-kvm-0.12.1.2-2.415.el6_5.14.src.rpm 
## For your ref :)
##../configure \
##	--target-list=x86_64-softmmu \
##	--prefix=/usr 
##	--localstatedir=/var 
##	--sysconfdir=/etc 
##	--audio-drv-list=pa,alsa --audio-card-list=ac97,es1370 --enable-mixemu 
##	--disable-strip 
##	'--extra-ldflags=-Wl,--build-id -pie -Wl,-z,relro -Wl,-z,now' 
##	'--extra-cflags=-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -fPIE -DPIE' 
##	--disable-xen 
##	--block-drv-rw-whitelist=qcow2,raw,file,host_device,host_cdrom,qed,gluster,rbd 
##	--block-drv-ro-whitelist=vmdk,vhdx,vpc 
##	--disable-debug-tcg 
##	--disable-sparse 
##	--enable-werror 
##	--disable-sdl 
##  --disable-curses --disable-check-utests 
##  --disable-curl 
##	--enable-vnc-tls --enable-vnc-sasl 
##	--disable-brlapi --disable-bluez 
##	--enable-docs 
##	--disable-vde 
##	--enable-linux-aio 
##	--enable-kvm --enable-kvm-cap-pit --enable-kvm-cap-device-assignment
##	--enable-spice  --enable-usb-redir 
##	--trace-backend=dtrace 
##	--enable-smartcard --disable-smartcard-nss 
##	--enable-glusterfs 
##	--disable-rhev-features

RhQemuCFlags= -O2 -ggdb -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64 -mtune=generic -fPIE -DPIE
RhQemuLdFlags= -Wl,--build-id -pie -Wl,-z,relro -Wl,-z,now

ifeq (,$(OurPrefix))
  OurPrefix=/opt/sqb
endif

StaticSpiceLdFlags=-lrt -lglib-2.0 -pthread -lpixman-1 -lcelt051 -lm -lssl -lcrypto -Wl,-z,relro -ldl -lz -lgssapi_krb5 -lkrb5 -lcom_err -lk5crypto -lsasl2 -ljpeg

$(QemuMakefile):$(SpiceProtocolPc) $(SpiceServerLib)  
	cd $(QemuSrc); \
	PKG_CONFIG_PATH="$(BuildRoot)/lib/pkgconfig" \
	./configure \
	--target-list="x86_64-softmmu" \
	--prefix=$(OurPrefix) --localstatedir=$(OurPrefix)/var --sysconfdir=$(OurPrefix)/etc \
	--audio-drv-list='pa,alsa,oss'  \
	--disable-strip \
	--extra-cflags="$(RhQemuCFlags) -DVdiVer=$(VdiVer) " \
	--extra-ldflags="$(RhQemuLdFlags) $(StaticSpiceLdFlags) -ludev" \
	--disable-xen \
	--block-drv-rw-whitelist=qcow2,raw,file,host_device,host_cdrom,qed,gluster,rbd \
	--block-drv-ro-whitelist=vmdk,vhdx,vpc \
	--disable-debug-tcg \
	--disable-sparse \
	--disable-werror \
	--disable-sdl --disable-gtk \
	--disable-curses  \
	--disable-libssh2 --disable-curl \
	--enable-vnc --enable-vnc-sasl --enable-vnc-tls \
	--disable-brlapi --disable-bluez \
	--enable-docs \
	--disable-vde \
	--enable-linux-aio \
	--enable-kvm  \
	--enable-spice --enable-usb-redir --enable-libusb \
	$(TraceQemuOpt) \
	--disable-smartcard-nss  \
	--disable-glusterfs \
	--enable-vhost-net \
	--disable-guest-agent \
	--disable-slirp --disable-user \
	--disable-seccomp --disable-libiscsi --disable-virtfs --disable-libnfs

prepare_rh:
	sudo yum install -y gcc gcc-c++  gdb gdb-doc binutils binutils-devel make automake autoconf  libtool nasm nasm-doc pyparsing  tunctl
	sudo yum install -y openssl-devel gnutls-devel nss-devel  cyrus-sasl-devel libssh-devel  valgrind-devel libcurl-devel
	sudo yum install -y libpng-devel freetype-devel libogg-devel libXrandr-devel SDL-devel libXfixes-devel alsa-lib-devel pulseaudio-libs-devel 
	sudo yum install -y libxml2-devel neon libcap-ng-devel numactl-devel libaio-devel
	sudo yum install -y lvm2 yajl-devel polkit libnl3-devel iscsi-initiator-utils parted-devel libudev-devel libpciaccess-devel device-mapper-multipath
	sudo yum install -y celt051-devel pixman-devel libjpeg-turbo-devel 
	sudo yum install -y texi2html texinfo   # for qemu --enable-doc
	sudo yum install -y xz wget qemu-image # for downloading cloud base image


prepare_fc: prepare_rh
	sudo yum install -y spice-gtk-tools # to  open VM spice console
	# These are for building spice-gtk
	# sudo yum install -y gtk3-devel gobject-introspection-devel libgudev1-devel vala vala-tools gtk-doc perl-Text-CSV libcacard-devel libcacard-tools 

spiceserver:$(SpiceServerLib)

$(SpiceServerLib):$(SpiceServerMakefile) 
	$(MAKE) -C $(SpiceServerSrc) install

$(SpiceServerMakefile):  $(SpiceProtocolHeader) $(SpiceServerSrc)/configure
	cd $(SpiceServerSrc); \
	SPICE_PROTOCOL_CFLAGS="-I $(SpiceProtocolDir)" \
	CFLAGS="-fPIC $(DebugOpt) $(PgOpt)" CXXFLAGS="-fPIC $(DebugOpt) $(PgOpt) " LIBS="-lpthread" \
	./configure --prefix="$(BuildRoot)" \
	    --enable-shared=no \
		--enable-client=no \
		--enable-smartcard=no \
		--enable-automated-tests=no \
		--enable-werror=no	

$(SpiceServerSrc)/configure:
	cd $(SpiceServerSrc); \
    NOCONFIGURE=1 ./autogen.sh 

$(SpiceProtocolHeader):$(SpiceProtocolMakefile)
	$(MAKE) -C $(SpiceProtocolSrc) install

$(SpiceProtocolPc):$(SpiceProtocolHeader)

$(SpiceProtocolMakefile): $(SpiceProtocolSrc)/configure 
	cd $(SpiceProtocolSrc); \
	./configure --prefix="$(BuildRoot)" 

$(SpiceProtocolSrc)/configure:
	cd $(SpiceProtocolSrc); \
    NOCONFIGURE=1 ./autogen.sh 

clean:clean_spice clean_qemu clean_libvirt remove_output clean_spicy

clean_spice:
	$(MAKE) -C $(SpiceServerSrc) clean ; exit 0
	rm -f $(SpiceServerMakefile) $(SpiceServerLib)

clean_qemu:
	$(MAKE) -C $(QemuSrc) clean ; exit 0
	rm -f $(QemuMakefile)

remove_output:
	rm -fr bin include lib share sbin man $(QemuPackDir) 


