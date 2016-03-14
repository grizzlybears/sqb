SHELL:=/bin/bash
BuildRoot:=$(shell pwd)

ifeq ($(Release),1)
	DebugOpt= 
else
	DebugOpt= -ggdb
endif


#ifneq (,$(findstring  Red,$(shell gcc --version | head -n1))) 
#	# on rh famaly, trace can be 'dtrace'   , same as rhqemu
#	#
#	TraceQemuOpt= --enable-trace-backend=dtrace
#else
#	TraceQemuOpt= --enable-trace-backend=simple
#endif


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

SpiceProtocolPc=$(BuildRoot)/share/pkgconfig/spice-protocol.pc

QemuSrc=$(BuildRoot)/qemu
QemuExe=$(QemuSrc)/x86_64-softmmu/qemu-system-x86_64
QemuMakefile=$(QemuSrc)/config-host.mak
QemuPackDir=$(BuildRoot)/qemu-kvm-build

UsbLib=$(BuildRoot)/lib/libusb-1.0.a
UsbSrc=$(BuildRoot)/libusbx
UsbMakefile=$(UsbSrc)/Makefile
UsbPc=$(BuildRoot)/lib/pkgconfig/libusb-1.0.pc

UsbRedirLib=$(BuildRoot)/lib/libusbredirparser.a
UsbRedirSrc=$(BuildRoot)/usbredir
UsbRedirMakefile=$(UsbRedirSrc)/Makefile
UsbRedirPc=$(BuildRoot)/lib/pkgconfig/libusbredirparser-0.5.pc

none:
	@echo "Usage:"
	@echo "    To build qemu          -->  make [Release=1]  qemu"
	@echo "    To build spice then qemu with spice    -->  make [Release=1]  spiceqemu"
	@echo "    To test qemu without install -->  Firt run 'make buildqemu' once,  then './test_run_qemu.sh' as u like"

.PHONY: clean  hard_clean remove_output

all:qemu

buildqemu:$(QemuExe)
	mkdir -p $(QemuPackDir)
	make -C $(QemuSrc) install DESTDIR="$(QemuPackDir)"

qemu:$(QemuExe)

$(QemuExe):  $(QemuMakefile)
	make -C $(QemuSrc)

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

MyPkgDir=$(BuildRoot)/lib/pkgconfig:$(BuildRoot)/lib64/pkgconfig:$(BuildRoot)/share/pkgconfig

StaticSpiceLdFlags=-lrt -lglib-2.0 -pthread -lpixman-1 -lcelt051 -lm -lssl -lcrypto -Wl,-z,relro -ldl -lz -lgssapi_krb5 -lkrb5 -lcom_err -lk5crypto -lsasl2 -ljpeg

StaticGnuTlsFlags=$(shell PKG_CONFIG_PATH=$(MyPkgDir)  pkg-config --libs --static gnutls nettle) -lhogweed

#
#  assume u have source-made  gnunettle and gnutls at
#EXTRA_PKG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig

$(QemuMakefile):$(UsbPc) $(UsbRedirPc) $(SpiceProtocolPc) $(SpiceServerLib)  
	cd $(QemuSrc); \
	echo "gnutls: $(StaticGnuTlsFlags)"; \
	PKG_CONFIG_PATH="$(MyPkgDir):$(EXTRA_PKG_PATH)" \
	./configure \
	--target-list="x86_64-softmmu" \
	--prefix=$(OurPrefix) --localstatedir=$(OurPrefix)/var --sysconfdir=$(OurPrefix)/etc \
	--audio-drv-list='pa,alsa,oss'  \
	--disable-strip \
	--extra-cflags="$(RhQemuCFlags) -DVdiVer=$(VdiVer) " \
	--extra-ldflags="$(RhQemuLdFlags) $(StaticSpiceLdFlags) $(StaticGnuTlsFlags) -ludev" \
	--disable-xen \
	--block-drv-rw-whitelist=qcow2,raw,file,host_device,host_cdrom,qed,gluster,rbd \
	--block-drv-ro-whitelist=vmdk,vhdx,vpc \
	--disable-debug-tcg \
	--disable-sparse \
	--disable-werror \
	--disable-sdl --disable-gtk \
	--disable-curses  \
	--disable-libssh2 --disable-curl \
        --enable-gnutls \
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


spiceserver:$(SpiceServerLib)

$(SpiceServerLib):$(SpiceServerMakefile) 
	$(MAKE) -C $(SpiceServerSrc) install

$(SpiceServerMakefile):  $(SpiceProtocolHeader) $(SpiceServerSrc)/configure
	cd $(SpiceServerSrc); \
	PKG_CONFIG_PATH="$(BuildRoot)/share/pkgconfig" \
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

$(UsbPc):$(UsbMakefile)
	$(MAKE) -C $(UsbSrc) install

$(UsbLib):$(UsbMakefile)
	$(MAKE) -C $(UsbSrc) install

$(UsbMakefile):$(UsbSrc)/configure
	cd $(UsbSrc); \
    CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure --prefix="$(BuildRoot)" --enable-shared=no

$(UsbSrc)/configure:
	cd $(UsbSrc); \
	NOCONFIGURE=1 ./autogen.sh

$(UsbRedirPc):$(UsbRedirMakefile)
	$(MAKE) -C $(UsbRedirSrc) install

$(UsbRedirLib):$(UsbRedirMakefile)
	$(MAKE) -C $(UsbRedirSrc) install

$(UsbRedirMakefile):$(UsbRedirSrc)/configure $(UsbPc) 
	cd $(UsbRedirSrc); \
	PKG_CONFIG_PATH="$(BuildRoot)/lib/pkgconfig" \
    CFLAGS="-fPIC" CXXFLAGS="-fPIC" ./configure --prefix="$(BuildRoot)" --enable-shared=no

$(UsbRedirSrc)/configure:
	cd $(UsbRedirSrc); \
	NOCONFIGURE=1 ./autogen.sh


clean:clean_spice clean_qemu remove_output

clean_spice:
	$(MAKE) -C $(SpiceServerSrc) clean ; exit 0
	rm -f $(SpiceServerMakefile) $(SpiceServerLib)

clean_qemu:
	$(MAKE) -C $(QemuSrc) clean ; exit 0
	rm -f $(QemuMakefile)

remove_output:
	rm -fr bin include lib share sbin man $(QemuPackDir) 

hard_clean:remove_output 
	cd spice; git clean -xdf
	cd spice/spice-common; git clean -xdf
	cd spice-protocol;git clean -xdf
	cd qemu; git clean -xdf
	cd libusbx; git clean -xdf
	cd usbredir; git clean -xdf

