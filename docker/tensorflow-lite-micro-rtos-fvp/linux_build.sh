#!/bin/bash

BASEDIR=$(dirname "$0")

wget -c https://git.mlplatform.org/ml/ethos-u/ethos-u.git/snapshot/ethos-u-21.02.tar.gz -O - | tar -xz
mv ethos-u-21.02 ethos-u

pushd $BASEDIR/ethos-u
python3 fetch_externals.py -c 21.02.json fetch
popd

NPROC=`grep -c ^processor /proc/cpuinfo`

pushd $BASEDIR/sw/corstone-300-person-detection
mkdir build
cd build
cmake ..
make -j $NPROC
popd

pushd $BASEDIR/sw/corstone-300-mobilenet-v2
mkdir build
cd build
cmake ..
make -j $NPROC
popd
