#!/bin/bash

# Build use case with armclang
# only armclang supported at this point

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
pushd ${BASEDIR}

# Usage: takes use_case as input
usage() { 
    echo "Usage: $0 [-c <gcc|armclang> -u <use_case>]" 1>&2
    echo "   -c|--compiler  : The compiler to use to build the applications, gcc|armclang (default: armclang)" 1>&2
    echo "   -u|--use_case  : The use case to build (default: img_class)" 1>&2
    echo "   -d|--data_path  : Full path to a folder of custom images" 1>&2
    echo "   -m|--model     : Path to the model to use. Full path, or relative to ml-embedded-evaluation-kit root. " 1>&2
    echo "   -k|--kws_model : Path to the kws model for kws_asr use_case to use. This option is only uded for the kws_asr use case" 1>&2
    echo "            Default models exists for all use_cases except inference_runner" 1>&2
    echo "            Available use_cases: { img_class, person_detection, ad, asr, kws, kws_asr, inference_runner }" 1>&2
    echo "            Read more about the use cases in the ml-embedded-evaluation-kit documentation" 1>&2
    
    popd
    exit 1 
}

COMPILER=${COMPILER:-'armclang'}
USE_CASE='img_class'
MODEL=''
DATA_PATH=''
MODEL_kws=''

NPROC=`nproc`

mkdir -p ${BASEDIR}/dependencies/logs

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -c|--compiler) COMPILER="$2"; shift ;;
        -u|--use_case) USE_CASE="$2"; shift ;;
        -d|--data_path) DATA_PATH="$2"; shift ;;
        -m|--model) MODEL="$2"; shift ;;
        -k|--kws_model) MODEL_kws="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

if [ "${DATA_PATH}" == '' ];
then
    DATA_PATH="resources/${USE_CASE}/samples"
fi

# download repo to dependencies dir
mkdir -p ${BASEDIR}/dependencies

# Only clone ml-embedded-evaluation-kit if it doesn't exist already
if [ ! -d ${BASEDIR}/dependencies/ml-embedded-evaluation-kit ];
then
    pushd ${BASEDIR}/dependencies
        echo "Cloning ml-embedded-evaluation-kit repository"
        git clone -b 21.05 --recursive https://git.mlplatform.org/ml/ethos-u/ml-embedded-evaluation-kit.git
        mkdir -p ml-embedded-evaluation-kit/dependencies/tensorflow/tensorflow/lite/micro/tools/make/downloads/gcc_embedded
    popd
else
    echo "Skipping cloning of ml-embedded-evaluation-kit, already exists"
fi

if [ ! -d ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/dependencies/tensorflow/tensorflow ];
then
pushd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit 
    git submodule update --init --recursive
    mkdir -p dependencies/tensorflow/tensorflow/lite/micro/tools/make/downloads/gcc_embedded
popd
fi

# add patch to convert grayscale images
if [ "${USE_CASE}" = 'person_detection' ];
then
    echo "Apply grayscale patch to the eval kit"
    pushd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/
        patch -p1 --forward -b -r /dev/null < ${BASEDIR}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch
    popd
fi

# Copy source to ml-embedded-eval-kit add
echo "Copying user samples to ml-embedded-evaluation-kit"
cp -r ${BASEDIR}/sw/ml-eval-kit/samples/* ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/


if [ ! -d "${BASEDIR}/dependencies/ml-embedded-evaluation-kit/source/use_case/${USE_CASE}" ];
then
    echo "ERROR: Selected use case source was not found in ml-embedded-evaluation-kit source folder"
    usage;
fi


# download use_case default models
pushd ${BASEDIR}/dependencies
bash ${BASEDIR}/download_use_case_model.sh -u ${USE_CASE}    
popd

if [ "${MODEL}" = '' ];
then
    case ${USE_CASE} in
    'img_class')
        MODEL='../ML-zoo/models/image_classification/mobilenet_v2_1.0_224/tflite_uint8/mobilenet_v2_1.0_224_quantized_1_default_1.tflite'
        ;;
    'ad')
        MODEL='../ML-zoo/models/anomaly_detection/micronet_medium/tflite_int8/ad_medium_int8.tflite'
        ;;
    'asr')
        MODEL='../ML-zoo/models/speech_recognition/wav2letter/tflite_int8/wav2letter_int8.tflite'
        ;;
    'kws')
        MODEL='../ML-zoo/models/keyword_spotting/ds_cnn_large/tflite_clustered_int8/ds_cnn_clustered_int8.tflite'
        ;;
    'kws_asr')
        MODEL='../ML-zoo/models/speech_recognition/wav2letter/tflite_int8/wav2letter_int8.tflite'
        ;;
    'person_detection')
        MODEL='resources/person_detection/models/person_detection.tflite'
    esac
fi

if [ "${MODEL_kws}" = '' ] && [ "${USE_CASE}" = 'kws_asr' ];
then
    MODEL_kws='../ML-zoo/models/keyword_spotting/ds_cnn_large/tflite_clustered_int8/ds_cnn_clustered_int8.tflite'
fi


if [ "${COMPILER}" = 'armclang' ];
then
    if [ -z ${ARMLMD_LICENSE_FILE} ]; 
    then 
        echo "ARMLMD_LICENSE_FILE is unset"
        echo "Please configure the Arm license before proceeding"
        popd
        exit;
    fi
    TOOLCHAIN_FILE=${BASEDIR}/dependencies/ml-embedded-evaluation-kit/scripts/cmake/toolchains/bare-metal-armclang.cmake
elif [ ${COMPILER} = 'gcc' ]
then
    TOOLCHAIN_FILE=${BASEDIR}/dependencies/ml-embedded-evaluation-kit/scripts/cmake/toolchains/bare-metal-gcc.cmake
else
    usage;
fi

pushd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit

# TODO: first we must make sure we can use vela.
# So automatically install vela, or check that we can access and give 
# error if we can't?  also don't do if we already have the optimized model
mkdir -p output
echo "Optimizing ${USE_CASE} model with vela"
vela ${MODEL} \
    --accelerator-config=ethos-u55-128 \
    --block-config-limit=0 \
    --config scripts/vela/default_vela.ini \
    --memory-mode Shared_Sram \
    --system-config Ethos_U55_High_End_Embedded \
      | tee ${BASEDIR}/dependencies/logs/eval_kit_vela_log_${USE_CASE}_$(date '+%Y%m%d-%H:%M:%S').txt

MODEL_VELA=`echo "${MODEL}" | sed 's/.tflite/_vela.tflite/g'`
MODEL_VELA="output/`basename ${MODEL_VELA}`"

# kws_asr uses 2 models
if [ "${USE_CASE}" = 'kws_asr' ];
then
    echo "Optimizing ${USE_CASE} model with vela"
    vela ${MODEL_kws} \
        --accelerator-config=ethos-u55-128 \
        --block-config-limit=0 \
        --config scripts/vela/default_vela.ini \
        --memory-mode Shared_Sram \
        --system-config Ethos_U55_High_End_Embedded \
        | tee ${BASEDIR}/dependencies/logs/eval_kit_vela_log_${USE_CASE}_$(date '+%Y%m%d-%H:%M:%S').txt
        
    MODEL_kws_VELA=`echo "${MODEL_kws}" | sed 's/.tflite/_vela.tflite/g'`
    MODEL_kws_VELA="output/`basename ${MODEL_kws_VELA}`"
fi

# create build dir
echo "Creating build directory for ml-embedded-evaluation-kit"

DOCKER=""

if grep "docker\|lxc" /proc/1/cgroup >/dev/null 2>&1 ;  
then
    DOCKER="-docker";
fi

BUILDDIR=build${DOCKER}

mkdir -p ${BUILDDIR}
pushd ${BUILDDIR}
    # remove CMakeCache.txt, if user have build in other configuration.
    rm CMakeCache.txt
    rm -rf tensorflow

    USE_CASE_OPTIONS="-DUSE_CASE_BUILD=${USE_CASE} \
        -D${USE_CASE}_MODEL_TFLITE_PATH=${MODEL_VELA} \
        -D${USE_CASE}_FILE_PATH=${DATA_PATH}"
    
    # this use case uses two models.
    if [ ${USE_CASE} = 'kws_asr' ];
    then
        USE_CASE_OPTIONS="-DUSE_CASE_BUILD=${USE_CASE} \
            -D${USE_CASE}_MODEL_TFLITE_PATH_ASR=${MODEL_VELA} \
            -D${USE_CASE}_MODEL_TFLITE_PATH_KWS=${MODEL_kws_VELA} \
            -D${USE_CASE}_FILE_PATH=${DATA_PATH}"
    fi

    cmake \
        -DTARGET_PLATFORM=mps3 \
        -DTARGET_SUBSYSTEM=sse-300 \
        -DCMAKE_TOOLCHAIN_FILE=${TOOLCHAIN_FILE} \
        ${USE_CASE_OPTIONS} \
        .. \
            | tee ${BASEDIR}/dependencies/logs/eval_kit_cmake_$(date '+%Y%m%d-%H:%M:%S').log

    make -j${NPROC} \
        | tee ${BASEDIR}/dependencies/logs/eval_kit_make_$(date '+%Y%m%d-%H:%M:%S').log
popd

# revert patch to convert grayscale images
if [ "${USE_CASE}" == "person_detection" ];
then
    echo "Apply grayscale patch to the eval kit"
    pushd ${BASEDIR}/dependencies/ml-embedded-evaluation-kit/
        patch -p1 -R < ${BASEDIR}/sw/ml-eval-kit/ml-embedded-evaluation-kit-grayscale-support.patch
    popd
fi

popd
