#!/bin/bash -xe

BUILD_DIR=libuvc-source/build

rm -rf $BUILD_DIR
mkdir $BUILD_DIR
pushd $BUILD_DIR
cmake ..
cmake --build .
cmake --install .
pushd