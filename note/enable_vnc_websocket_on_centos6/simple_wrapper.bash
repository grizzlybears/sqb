#!/bin/bash -e

rm -fr gnutls
rm -fr nettle


# http://gnutls.org/
tar xvf   gnutls-3.4.10.tar.xz


tar xzvf  nettle-3.2.tar.gz

mv  gnutls-3.4.10 gnutls
mv  nettle-3.2    nettle

ROOT=`readlink  -f ../..`

pushd .

cd nettle

CFLAGS='-fpic' ./configure --prefix=$ROOT --disable-shared
make 
make install

popd 


pushd .
cd gnutls

PKG_CONFIG_PATH=$ROOT/lib64/pkgconfig CFLAGS='-fpic' \
    ./configure --prefix=$ROOT \
    --with-included-libtasn1 --without-p11-kit --without-tpm \
    --disable-doc --enable-static=yes --enable-shared=no
make 
make install

popd 

