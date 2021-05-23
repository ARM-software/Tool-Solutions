#!/bin/bash

#
# Copyright (c) 2018-2019 Arm Limited. All rights reserved.
#

#
# Script to build all of the required software for the Arm NN examples
#

function IsPackageInstalled() {
    dpkg -s "$1" > /dev/null 2>&1
}

usage() { 
    echo "Usage: $0 [-a <armv7a|arm64-v8a>] [-o <0|1> -b BUILDDIR -x <0|1>]" 1>&2
    echo "   default arch is arm64-v8a " 1>&2
    echo "   -o option will enable or disable OpenCL when cross compiling" 1>&2
    echo "      native compile will enable OpenCL if /dev/mali is found and -o is not used" 1>&2
    echo "   -b pass a the path of the directory where things will be built (omit trailing /)" 1>&2
    echo "   -x option will enable or disable ONNX (disabled by default)" 1>&2
    exit 1 
}

BUILDDIR=$HOME
# Simple command line arguments
while getopts ":a:o:b:x:h" opt; do
    case "${opt}" in
        a)
            Arch=${OPTARG}
            [ $Arch = "armv7a" -o $Arch = "arm64-v8a" ] || usage
            ;;
        o)
            OpenCL=${OPTARG}
            ;;
        b)
            BUILDDIR=${OPTARG}
            ;;
        x)
            ONNX=${OPTARG}
            ;;
        h)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# check if cross compile from x64
if [ `uname -m` = "x86_64" ]; then
    CrossCompile="True"
else
    CrossCompile="False"
fi

# save history to logfile
exec > >(tee -i logfile)
exec 2>&1

# Start from build directory but check if it exists first
if [[ ! -d $BUILDDIR ]]; then
	echo -e "\nDirectory $BUILDDIR does not exist. Aborting!\n"
	exit 1
fi

echo "Building Arm NN stack in $BUILDDIR/armnn-devenv"
cd $BUILDDIR

# if nothing, found make a new diectory
[ -d armnn-devenv ] || mkdir armnn-devenv


# check for previous installation, HiKey 960 is done as a mount point so don't 
# delete all from top level, drop down 1 level
while [ -d armnn-devenv/pkg ]; do
    read -p "Do you wish to remove the existing armnn-devenv build environment? " yn
    case $yn in
        [Yy]*) rm -rf armnn-devenv/pkg armnn-devenv/ComputeLibrary armnn-devenv/armnn armnn-devenv/gator ; break ;;
        [Nn]*) echo "Exiting " ; exit;;
        *) echo "Please answer yes or no.";;
    esac
done

cd armnn-devenv 

# packages to install 
packages="git wget curl autoconf autogen automake libtool scons make cmake gcc g++ unzip bzip2"
for package in $packages; do
    if ! IsPackageInstalled $package; then
        sudo apt-get install -y $package
    fi
done

# extra packages when cross compiling
if [ $CrossCompile = "True" ]; then
    echo "Cross-compiling enabled"
    if [ "$Arch" = "armv7a" ]; then
        cross_packages="g++-arm-linux-gnueabihf"
    else
        cross_packages="g++-aarch64-linux-gnu"
    fi
    for cross_package in $cross_packages; do
        if ! IsPackageInstalled $cross_package; then
            sudo apt-get install -y $cross_package
        fi
    done
else
    echo "Cross-compiling disabled"
fi

# number of CPUs and memory size for make -j
NPROC=`grep -c ^processor /proc/cpuinfo`
MEM=`awk '/MemTotal/ {print $2}' /proc/meminfo`

# check for Mali device node
[ -z "$OpenCL" ] && [ -c /dev/mali? ] && OpenCL=1 || OpenCL=0 
if [ $OpenCL = 1 ]; then
  echo "OpenCL enabled"
else
  echo "OpenCL disabled"
fi

if [ "$ONNX" = "1" ]; then
  echo "ONNX enabled"
else
  echo "ONNX disabled"
fi

# check for Armv8 or Armv7
# don't override command line and default to aarch64
[ -z "$Arch" ] && Arch=`uname -m`

if [ $Arch = "armv7l" ]; then
    Arch=armv7a
    PREFIX=arm-linux-gnueabihf-
else
    Arch=arm64-v8a
    PREFIX=aarch64-linux-gnu-
fi
echo "Target architecture: ${Arch}"
echo

# Boost

mkdir -p pkg/boost 
echo "building boost"
pushd pkg/boost

wget https://boostorg.jfrog.io/artifactory/main/release/1.64.0/source/boost_1_64_0.tar.gz
tar xf boost_1_64_0.tar.gz
cd boost_1_64_0
./bootstrap.sh --prefix=$BUILDDIR/armnn-devenv/pkg/boost/install

Toolset=""
if [ $CrossCompile = "True" ]; then
    cp tools/build/example/user-config.jam project-config.jam
    sed -i "/# using gcc ;/c using gcc : arm : $PREFIX\g++ ;" project-config.jam
    Toolset="toolset=gcc-arm"
fi

./b2 install link=static cxxflags=-fPIC $Toolset --with-filesystem --with-test --with-log --with-program_options --prefix=$BUILDDIR/armnn-devenv/pkg/boost/install

popd

# Flatbuffers 
mkdir -p pkg/flatbuffers 
echo "building flatbuffers"

pushd pkg/flatbuffers

wget -O flatbuffers-1.12.0.zip https://github.com/google/flatbuffers/archive/v1.12.0.zip
unzip -d . flatbuffers-1.12.0.zip
cd flatbuffers-1.12.0
mkdir build
cd build
cmake .. -DCMAKE_CXX_FLAGS=-fPIC
make -j $NPROC
sudo make install

popd

# SWIG
mkdir -p pkg/swig
echo "building swig"
pushd pkg/swig
 
wget http://prdownloads.sourceforge.net/swig/swig-4.0.2.tar.gz
tar xzvf swig-4.0.2.tar.gz
cd swig-4.0.2/
./configure 
make -j $NPROC
sudo make install

popd

# gator
echo "building gator"
git clone https://github.com/ARM-software/gator.git

if [ $CrossCompile = "True" ]; then
    make CROSS_COMPILE=$PREFIX -C gator/daemon -j $NPROC
else
    make -C gator/daemon -j $NPROC
fi
cp gator/daemon/gatord $BUILDDIR/

# Arm Compute Library 
echo "building Arm CL"
git clone https://github.com/ARM-software/ComputeLibrary.git

pushd ComputeLibrary

# check gcc version in case adjustments are needed based on compiler
VER=`gcc -dumpversion | awk 'BEGIN{FS="."} {print $1}'`
echo "gcc version is $VER"

scons arch=$Arch neon=1 opencl=$OpenCL embed_kernels=$OpenCL Werror=0 \
  extra_cxx_flags="-fPIC" benchmark_tests=0 examples=0 validation_tests=0 \
  os=linux gator_dir="$BUILDDIR/armnn-devenv/gator" -j $NPROC

popd

# TensorFlow and Google protobuf
echo "building TensorFlow and Google protobuf"
pushd pkg
mkdir install
git clone --branch v3.12.0 https://github.com/google/protobuf.git
git clone --branch v2.3.1 https://github.com/tensorflow/tensorflow.git
cd tensorflow
cd ../

# build Protobuf
cd protobuf
./autogen.sh


# Extra protobuf build for host machine when cross compiling
if [ $CrossCompile = "True" ]; then
    mkdir host-build ; cd host-build
    ../configure --prefix=$BUILDDIR/armnn-devenv/pkg/host
    make -j NPROC
    make install
    make clean
    cd ..
fi

mkdir build ; cd build
if [ $CrossCompile = "True" ]; then
    ../configure --prefix=$BUILDDIR/armnn-devenv/pkg/install --host=arm-linux CC=$PREFIX\gcc CXX=$PREFIX\g++ --with-protoc=$BUILDDIR/armnn-devenv/pkg/host/bin/protoc
else
    ../configure --prefix=$BUILDDIR/armnn-devenv/pkg/install 
fi

make -j $NPROC
make install 

popd

OnnxOptions=""
# ONNX support
if [ "${ONNX}" = "1" ]; then
    echo "building ONNX"
    pushd pkg

    export ONNX_ML=1 #To clone ONNX with its ML extension
    git clone --recursive https://github.com/onnx/onnx.git
    unset ONNX_ML

    cd onnx
    # need specific version of ONNX: https://developer.arm.com/solutions/machine-learning-on-arm/developer-material/how-to-guides/configuring-the-arm-nn-sdk-build-environment-for-onnx/generate-the-onnx-protobuf-source-files
    git checkout f612532843bd8e24efeab2815e45b436479cc9ab

    export LD_LIBRARY_PATH=$BUILDDIR/armnn-devenv/pkg/install/lib:$LD_LIBRARY_PATH

    if [ $CrossCompile = "True" ]; then
        $BUILDDIR/armnn-devenv/pkg/host/bin/protoc onnx/onnx.proto --proto_path=. --proto_path=$BUILDDIR/armnn-devenv/pkg/host/include --cpp_out $BUILDDIR/armnn-devenv/pkg/onnx
    else
        $BUILDDIR/armnn-devenv/pkg/install/bin/protoc onnx/onnx.proto --proto_path=. --proto_path=$BUILDDIR/armnn-devenv/pkg/install/include --cpp_out $BUILDDIR/armnn-devenv/pkg/onnx
    fi

    popd

    OnnxOptions="-DBUILD_ONNX_PARSER=1 \
	         -DONNX_GENERATED_SOURCES=$BUILDDIR/armnn-devenv/pkg/onnx "
fi

# Arm NN
echo "building Arm NN"
git clone https://github.com/ARM-software/armnn.git

pushd pkg/tensorflow/

if [ $CrossCompile = "True" ]; then
    $BUILDDIR/armnn-devenv/armnn/scripts/generate_tensorflow_protobuf.sh $BUILDDIR/armnn-devenv/pkg/tensorflow-protobuf $BUILDDIR/armnn-devenv/pkg/host
else
    $BUILDDIR/armnn-devenv/armnn/scripts/generate_tensorflow_protobuf.sh $BUILDDIR/armnn-devenv/pkg/tensorflow-protobuf $BUILDDIR/armnn-devenv/pkg/install
fi

popd

pushd armnn
mkdir build ; cd build

CrossOptions=""
if [ $CrossCompile = "True" ]; then
    CrossOptions="-DCMAKE_LINKER=aarch64-linux-gnu-ld \
                  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
                  -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ "
fi

cmake ..  \
$CrossOptions  \
$OnnxOptions \
-DCMAKE_C_COMPILER_FLAGS=-fPIC \
-DARMCOMPUTE_ROOT=$BUILDDIR/armnn-devenv/ComputeLibrary/ \
-DARMCOMPUTE_BUILD_DIR=$BUILDDIR/armnn-devenv/ComputeLibrary/build \
-DBOOST_ROOT=$BUILDDIR/armnn-devenv/pkg/boost/install/ \
-DTF=$BUILDDIR/armnn-devenv/pkg/tensorflow/tensorflow/lite \
-DTF_GENERATED_SOURCES=$BUILDDIR/armnn-devenv/pkg/tensorflow-protobuf/  \
-DBUILD_TF_LITE_PARSER=1 \
-DTF_LITE_GENERATED_PATH=$BUILDDIR/armnn-devenv/pkg/tensorflow/tensorflow/lite/schema \
-DTF_LITE_SCHEMA_INCLUDE_PATH=$BUILDDIR/armnn-devenv/pkg/tensorflow/tensorflow/lite/schema \
-DBUILD_ARMNN_TFLITE_DELEGATE=0 \
-DPROTOBUF_ROOT=$BUILDDIR/armnn-devenv/pkg/install   \
-DPROTOBUF_INCLUDE_DIRS=$BUILDDIR/armnn-devenv/pkg/install/include   \
-DPROFILING_BACKEND_STREAMLINE=1 \
-DGATOR_ROOT=$BUILDDIR/armnn-devenv/gator \
-DARMCOMPUTENEON=1  \
-DARMCOMPUTECL=$OpenCL \
-DPROTOBUF_LIBRARY_DEBUG=$BUILDDIR/armnn-devenv/pkg/install/lib/libprotobuf.so \
-DPROTOBUF_LIBRARY_RELEASE=$BUILDDIR/armnn-devenv/pkg/install/lib/libprotobuf.so \
-DCMAKE_CXX_FLAGS="-Wno-error=sign-conversion" \
-DCMAKE_BUILD_TYPE=Debug

if [ $Arch = "armv7l" ] || [ $MEM -lt 2000000 ]; then
    # avoid running out of memory on smaller systems 
    make
else
    make -j $NPROC
fi

cd ..
echo "done, everything in $BUILDDIR/armnn-devenv"

export SWIG_EXECUTABLE=/usr/local/bin/swig
export ARMNN_INCLUDE=$BUILDDIR/armnn-devenv/armnn/include/
export ARMNN_LIB=$BUILDDIR/armnn-devenv/armnn/build/

cd python/pyarmnn

python3 swig_generate.py -v
python3 setup.py build_ext --inplace
python3 setup.py sdist
python3 setup.py bdist

popd
cd ..

