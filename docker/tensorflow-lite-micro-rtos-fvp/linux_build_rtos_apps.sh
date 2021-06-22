#!/bin/bash

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Usage: takes compiler as input
usage() { 
    echo -e "\e[1;33mUsage: $0 [-c <gcc|armclang>]\e[m" 1>&2
    echo -e "\e[1;34m   -c|--compiler\e[m  : The compiler to use to build the applications, gcc|armclang (default: armclang)" 1>&2
    exit 1 
}

COMPILER=${COMPILER:-'armclang'}
mkdir -p ${BASEDIR}/dependencies/logs

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

git clone -b 21.05 https://git.mlplatform.org/ml/ethos-u/ethos-u.git ${BASEDIR}/dependencies/ethos-u
pushd ${BASEDIR}/dependencies/ethos-u
python3 fetch_externals.py -c 21.05.json fetch
mkdir -p core_software/tensorflow/tensorflow/lite/micro/tools/make/downloads/gcc_embedded
popd

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

BUILDDIR=build${DOCKER}

pushd ${BASEDIR}/dependencies/ethos-u
    mkdir -p ${BUILDDIR}
    cd ${BUILDDIR}
    rm CMakeCache.txt
    rm -rf target/core_software/tensorflow
    cmake -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} -DCMAKE_INSTALL_PREFIX=. ../core_platform/targets/corstone-300 \
        | tee ${BASEDIR}/dependencies/logs/rtos_cmake_$(date '+%Y-%m-%d-%H').log
    make -j \
        | tee ${BASEDIR}/dependencies/logs/rtos_make_$(date '+%Y-%m-%d-%H').log
    make install \
        | tee ${BASEDIR}/dependencies/logs/rtos_make_install_$(date '+%Y-%m-%d-%H').log
popd
