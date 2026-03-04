#!/bin/bash -xe

# Build libusb master
pushd libusb-source
./bootstrap.sh
./configure --prefix=$HOME/.local
make -j
make install
popd

BUILD_DIR=libuvc-source/build

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
pushd $BUILD_DIR
cmake ..
cmake --build .
cmake -DCMAKE_INSTALL_PREFIX=$HOME/.local .
cmake --install .
pushd
