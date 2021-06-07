#!/bin/bash

BASEDIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
pushd ${BASEDIR}

# Usage: takes use_case as input
usage() { 
    echo "Usage: $0 [-u <use_case>]" 1>&2
    echo "   -u|--use_case  : The use case model to download (default: img_class)" 1>&2

    popd
    exit 1 
}

USE_CASE='img_class'

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

pushd ${BASEDIR}/dependencies

echo "Downloading model from Arm ML-zoo"
if [ ! -d 'ML-zoo' ]
then 
    git clone --depth 1 https://github.com/ARM-software/ML-zoo.git
fi

pushd ML-zoo

case ${USE_CASE} in
  'img_class')
    echo "Downloading img_class model"
    git lfs pull --include="models/image_classification/mobilenet_v2_1.0_224/tflite_uint8/mobilenet_v2_1.0_224_quantized_1_default_1.tflite"
    ;;
  'ad')
    echo "Downloading ad model"
    git lfs pull --include="models/anomaly_detection/micronet_medium/tflite_int8/ad_medium_int8.tflite"
    ;;
  'asr')
    echo "Downloading asr model"
    git lfs pull --include="models/speech_recognition/wav2letter/tflite_int8/wav2letter_int8.tflite"
    ;;
  'kws')
    echo "Downloading kws model"
    git lfs pull --include="models/keyword_spotting/ds_cnn_large/tflite_clustered_int8/ds_cnn_clustered_int8.tflite"
    ;;
  'kws_asr')
    echo "Downloading kws_asr models"
    git lfs pull --include="models/speech_recognition/wav2letter/tflite_int8/wav2letter_int8.tflite"
    git lfs pull --include="models/keyword_spotting/ds_cnn_large/tflite_clustered_int8/ds_cnn_clustered_int8.tflite"
    ;;
esac

popd

popd
