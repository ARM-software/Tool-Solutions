#!/bin/bash

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Usage: takes compiler as input
usage() { 
    echo "Usage: $0 [-c <gcc|armclang>]" 1>&2
    echo "   -c|--compiler  : The compiler to use to build the applications, gcc|armclang (default: armclang)" 1>&2
    exit 1 
}

COMPILER=${COMPILER:-'armclang'}
NPROC=`grep -c ^processor /proc/cpuinfo`

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--compiler) COMPILER="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

if [ ${COMPILER} = 'armclang' ];
then
    if [ -z ${ARMLMD_LICENSE_FILE} ]; 
    then 
        echo "ARMLMD_LICENSE_FILE is unset"
        echo "Please set ARMLMD_LICENSE_FILE to a valid License Server before proceeding"
        exit;
    fi
    TOOLCHAIN_FILE=${BASEDIR}/dependencies/ethos-u/core_platform/cmake/toolchain/armclang.cmake
elif [ ${COMPILER} = 'gcc' ]
then
    TOOLCHAIN_FILE=${BASEDIR}/dependencies/ethos-u/core_platform/cmake/toolchain/arm-none-eabi-gcc.cmake
else
    usage;
fi

# Only clone ethos-u if it doesn't exist already
if [ ! -d ${BASEDIR}/dependencies/ethos-u ];
then
    git clone -b 21.02 https://git.mlplatform.org/ml/ethos-u/ethos-u.git ${BASEDIR}/dependencies/ethos-u
    pushd ${BASEDIR}/dependencies/ethos-u
    python3 fetch_externals.py -c 21.02.json fetch
    popd
fi

# include samples (TODO:automatic detect sample names?)
echo "Apply grayscale patch to the eval kit"
pushd ${BASEDIR}/dependencies/ethos-u/core_platform
patch -p1 --forward -r /dev/null < ${BASEDIR}/sw/ethos-u/ethos_u_core_platform.patch
popd

# Copy source to ml-embedded-eval-kit add
echo "Copying user samples to ml-embedded-evaluation-kit"
cp -r ${BASEDIR}/sw/ethos-u/samples/* ${BASEDIR}/dependencies/ethos-u/core_platform/applications/

DOCKER=""

if grep "docker\|lxc" /proc/1/cgroup >/dev/null 2>&1 ;  
then
    DOCKER="-docker";
fi

BUILDDIR=build-${DOCKER}

pushd ${BASEDIR}/dependencies/ethos-u
    mkdir -p ${BUILDDIR}
    cd ${BUILDDIR}
    cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} -DCMAKE_INSTALL_PREFIX=. ../core_platform/targets/corstone-300
    make -j8
    make install
popd
