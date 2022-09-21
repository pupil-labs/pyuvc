#!/bin/bash -xe

# Build libusb master
git clone --branch fix-1199 https://github.com/pupil-labs/libusb.git /tmp/libusb
pushd /tmp/libusb
./bootstrap.sh
./configure
make -j
make install
popd

BUILD_DIR=libuvc-source/build

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
pushd $BUILD_DIR
cmake ..
cmake --build .
cmake --install .
pushd