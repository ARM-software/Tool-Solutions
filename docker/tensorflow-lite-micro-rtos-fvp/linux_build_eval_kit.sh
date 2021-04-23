#!/bin/bash

# Build use case with armclang
# only armclang supported at this point

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
pushd ${BASEDIR}

# Usage: takes use_case as input
usage() { 
    echo "Usage: $0 [-u <use_case>]" 1>&2
    echo "   -u|--use_case  : The use case to build (default: img_class)" 1>&2
    popd
    exit 1 
}

USE_CASE="img_class;person_detection"
NPROC=`grep -c ^processor /proc/cpuinfo`

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -u|--use_case) USE_CASE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# download repo to dependencies dir
mkdir -p ${BASEDIR}/dependencies

# Only clone ml-embedded-evaluation-kit if it doesn't exist already
if [ ! -d ${BASEDIR}/dependencies/ml-embedded-evaluation-kit ];
then
    pushd ${BASEDIR}/dependencies
    echo "Cloning ml-embedded-evaluation-kit repository"
    git clone -b 21.03 --recursive https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git 
    popd
else
    echo "Skipping cloning of ml-embedded-evaluation-kit, already exists"
fi

# add patch to convert grayscale images
echo "Apply grayscale patch to the eval kit"
pushd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/
patch -p1 --forward -b -r /dev/null < ${BASEDIR}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch
popd

# Copy source to ml-embedded-eval-kit add
echo "Copying user samples to ml-embedded-evaluation-kit"
cp -r ${BASEDIR}/sw/ml-eval-kit/samples/* ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/


if [ -z ${ARMLMD_LICENSE_FILE} ]; 
then 
    echo "ARMLMD_LICENSE_FILE is unset"
    echo "Please configure the Arm license before proceeding"
    popd
    exit;
fi

# download models and compile with vela
# TODO: list?
# starting with only mobilenet and person detection
pushd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit
# this will first download the models
# or we could download manually? is that better?
# ok, let's do that!

MOBILENET_MODEL=models/mobilenet_v2_1.0_224_quantized.tflite
MOBILENET_MODEL_VELA=output/mobilenet_v2_1.0_224_quantized_vela.tflite
PERSON_DETECTION_MODEL=resources/person_detection/models/person_detection.tflite
PERSON_DETECTION_MODEL_VELA=output/person_detection_vela.tflite

MODEL_ZOO_MOBILENET_URL=https://github.com/ARM-software/ML-zoo/raw/68b5fbc77ed28e67b2efc915997ea4477c1d9d5b/models/image_classification/mobilenet_v2_1.0_224/tflite_uint8/mobilenet_v2_1.0_224_quantized_1_default_1.tflite

# TODO: If it fails, exit and give a good error message
# Don't download if already exists.
# create download dir for models
mkdir -p models
echo "Downloading tflite file from model zoo, if not already present"
[ -f "${MOBILENET_MODEL}" ] || wget -O "${MOBILENET_MODEL}" ${MODEL_ZOO_MOBILENET_URL}

# TODO: first we must make sure we can use vela.
# So automatically install vela, or check that we can access and give 
# error if we can't?  also don't do if we already have the optimized model
echo "optimizing mobilenet model with vela"
[ -f "${MOBILENET_MODEL_VELA}" ] || vela ${MOBILENET_MODEL} \
    --accelerator-config=ethos-u55-128 \
    --block-config-limit=0 \
    --config scripts/vela/vela.ini \
    --memory-mode Shared_Sram \
    --system-config Ethos_U55_High_End_Embedded

echo "optimizing person detection model with vela"
[ -f "${PERSON_DETECTION_MODEL_VELA}" ] || vela ${PERSON_DETECTION_MODEL} \
    --accelerator-config=ethos-u55-128 \
    --block-config-limit=0 \
    --config scripts/vela/vela.ini \
    --memory-mode Shared_Sram \
    --system-config Ethos_U55_High_End_Embedded

# create build dir
echo "Creating build directory for ml-embedded-evaluation-kit"
mkdir -p ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/build_auto
cd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/build_auto

cmake \
    -DTARGET_PLATFORM=mps3 \
    -DTARGET_SUBSYSTEM=sse-300 \
    -DCMAKE_TOOLCHAIN_FILE=scripts/cmake/bare-metal-toolchain.cmake \
    -DUSE_CASE_BUILD=${USE_CASE} \
    -Dimg_class_MODEL_TFLITE_PATH=${MOBILENET_MODEL_VELA} \
    -Dperson_detection_MODEL_TFLITE_PATH=${PERSON_DETECTION_MODEL_VELA} \
    -Dimg_class_FILE_PATH=resources/img_class/samples \
    -Dperson_detection_FILE_PATH=resources/person_detection/samples \
    ..

make -j8

popd
