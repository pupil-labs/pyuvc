#!/bin/bash -xe

# Build libturbojpeg
pushd /tmp
curl -L -o libjpeg-turbo.tar.gz https://sourceforge.net/projects/libjpeg-turbo/files/1.5.1/libjpeg-turbo-1.5.1.tar.gz/download
tar xvzf libjpeg-turbo.tar.gz
pushd libjpeg-turbo-1.5.1
./configure --prefix=/usr/local
make -j
make install
popd
popd

$(dirname "$0")/build-deps-unix.sh