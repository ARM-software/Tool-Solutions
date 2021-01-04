#!/bin/bash
#
# Copyright 2019 ARM Limited.
# All rights reserved.
#

# Script to build TFLite-micro Test applications for M55
set -e
set -u
set -o pipefail

VENV="/tmp/venv-$$"
OUTPUT_DIR="/tmp/output-$$"
mkdir -p "$OUTPUT_DIR"

cleanup() {
    rm -fr "$VENV"
    rm -fr "$OUTPUT_DIR"
}

trap cleanup 0

usage() {
    echo "Usage: $0 [-u --use-case] Select the use case to build to run on the Corstone-300 FVP. Valid options (${valid_use_case[*]})" 1>&2
    echo "          [-i --input-data] Select the input image to classify for the img_classification use-case. Valid options are (cat, dog, kimono, tiger). For micro_speech the input-data is a sample input audio file" 1>&2
    echo "          [-t --target] Select the target to run the selected use case on. Valid options are (m55+u55, m55)" 1>&2
    echo "          [-h --help] prints help message " 1>&2
    exit 1
}


# allow the script to be called from another location using an absolute path
mydir=$(dirname "$(realpath "$0")")

# Location of scripts
SCRIPTS=$mydir/scripts
CMSIS_DIR=$mydir/CMSIS_REPO/CMSIS_5/

declare -A valid_targets=(
    ["m55"]="Cortex-M55F"
    ["m55+u55"]="Cortex-M55F+Ethos-U55"
)

valid_use_case=("img_class" "micro_speech")
use_case=
input_data=
target=

#Process command line arguments
args=$(getopt -o i:t:u:hx -l input-data:,target:,use-case:,help -n "$(basename "$0")" -- "$@")
eval set -- "$args"
while [ $# -gt 0 ]; do
  if [ -n "${opt_prev:-}" ]; then
    eval "$opt_prev=\$1"
    opt_prev=
    shift 1
    continue
  elif [ -n "${opt_append:-}" ]; then
    eval "$opt_append=\"\${$opt_append:-} \$1\""
    opt_append=
    shift 1
    continue
  fi
  case $1 in

  -h | --help)
    usage
    exit 0
    ;;

  -i | --input-data)
    opt_prev=input_data
    ;;

  -t | --target)
    opt_prev=target

    ;;
  -u | --use-case)
    # Example of option with an following argument
    opt_prev=use_case
    ;;

  -x)
    set -x
    ;;

  --)
    shift
    break 2
    ;;
  esac
  shift 1
done

# Install dependencies if needed
./install_dependencies.sh


# Target validation
if [ -z "$target" ]; then
    printf "error: --target value needed. Valid options: %s.\n" "${!valid_targets[*]}" >&2
    exit 1
else
    if [ ! "${valid_targets[$target]+found}" ]; then
        printf "error: target %s not supported. Valid options: %s.\n" "$target" "${!valid_targets[*]}" >&2
        exit 1
    fi
fi

# Location of software programs
SW="$mydir/exe"
mkdir -p $SW

# Use case validation
if [ -z "$use_case" ]; then
    printf "error: --use-case argument needed. Valid options: %s.\n" "${valid_use_case[*]}" >&2
    exit 1
fi

# For now we hardcode use case dependent data
case $use_case in
    img_class)
        tflite_model="resources/img_class/models/mobilenet_softmax_v2_1.0_224_uint8.tflite"
        # This script converts all the images but we are interested in the cat
        gen_script="python resources/gen_scripts/gen_rgb_cpp.py \
 --image_folder_path resources/img_class/samples/ \
 --source_folder_path $OUTPUT_DIR \
 --header_folder_path $OUTPUT_DIR \
 --image_size 224 224"
        valid_input_data=("cat" "dog" "kimono" "tiger")
        if [ -z "$input_data" ] || [[ ! ${valid_input_data[*]} =~ $input_data ]]; then
            printf "error: --input-data value needed/wrong. Valid options: %s.\n" "${valid_input_data[*]}" >&2
            exit 1
        fi
        INPUT_DATA="$OUTPUT_DIR/${input_data}.cc" # It needs to be converted
        ;;

    micro_speech)
        tflite_model="resources/micro_speech/models/micro_speech.tflite"
        gen_script=""
        INPUT_DATA="resources/micro_speech/input/input_data.h"
        ;;
esac

model_fullname=$(basename $tflite_model)
model_basename="${model_fullname%.*}"
model_extension="${model_fullname##*.}"

# Create and activate the venv
python3.7 -m venv "$VENV"
# shellcheck source=/tmp/venv-PID/bin/activate
source "$VENV/bin/activate"

if [ "$target" == "m55+u55" ]; then
    # Install vela
    pip install ethos-u-vela==1.2.0

    # Run vela
    vela \
        --output-dir="$OUTPUT_DIR/" \
        --tensor-allocator=Greedy \
        --accelerator-config=ethos-u55-256 \
        $tflite_model
    INPUT_MODEL="$OUTPUT_DIR/${model_basename}_vela.$model_extension"
    MODEL_H="$OUTPUT_DIR/${model_basename}_vela.h"
else
    INPUT_MODEL="$tflite_model"
    MODEL_H="$OUTPUT_DIR/${model_basename}.h"
fi

# Convert the model to C array
xxd -i "$INPUT_MODEL" > "$MODEL_H"

# Add PROLOG and EPILOG to the model_vela.h
# shellcheck disable=SC1004
MODEL_PROLOG='#ifndef TENSORFLOW_LITE_MICRO_EXAMPLES_NETWORK_TESTER_NETWORK_MODEL_H_\
#define TENSORFLOW_LITE_MICRO_EXAMPLES_NETWORK_TESTER_NETWORK_MODEL_H_\
unsigned char network_model[] __attribute__((aligned (16), section("network_model_sec"))) = {'
MODEL_EPILOG='#endif'

# Replace the first line with MODEL_EPILOG
sed -i "1 s/.*/$MODEL_PROLOG/" "$MODEL_H"
sed -i "$ a $MODEL_EPILOG" "$MODEL_H"

if [ ! -z "$gen_script" ]; then
    # Install dependencies for gen scripts
    pip install -r resources/gen_scripts/requirements.txt

    # Call the gen_script to convert input data
    $gen_script

    # Replace the header and create input_data.h
    # shellcheck disable=SC1004
    DATA_PROLOG='#ifndef TENSORFLOW_LITE_MICRO_EXAMPLES_NETWORK_TESTER_INPUT_DATA_H_\
    #define TENSORFLOW_LITE_MICRO_EXAMPLES_NETWORK_TESTER_INPUT_DATA_H_\
    unsigned char input_data[] __attribute__((aligned (16), section("input_data_sec"))) = {'
    DATA_EPILOG='#endif'

    sed -i "/#include/,/IFM_BUF_ATTRIBUTE = {/c$DATA_PROLOG" "$INPUT_DATA"
    sed -i "$ a $DATA_EPILOG" "$INPUT_DATA"
fi

# Copy the network model and input data for the test you are running into TF repo
cp "$MODEL_H" tensorflow/tensorflow/lite/micro/examples/test_runner/network_model.h
cp "$INPUT_DATA" tensorflow/tensorflow/lite/micro/examples/test_runner/input_data.h

# Build the make files for the tflite-micro example selected
cd tensorflow/
make -f tensorflow/lite/micro/tools/make/Makefile clean

if [ "$target" == "m55+u55" ]; then
    export TAGS="armclang ethos-u cmsis-nn"
    export ETHOSU_DRIVER_PATH=../ethos-u-core-driver-20.11-rc1
    # shellcheck disable=SC2016
    export ETHOSU_DRIVER_LIBS='$(call recursive_find,../ethos-u-core-driver-20.11-rc1/build,lib*.a)'
    export NPU_LOG_LEVEL=1
else
    export TAGS="armclang cmsis-nn"
fi

make -j 16 -f tensorflow/lite/micro/tools/make/Makefile test_runner_test \
    TARGET=fvp \
    TARGET_ARCH=cortex-m55 \
    CMSIS_PATH="$CMSIS_DIR" \
    ARENA_SIZE=2000000 \
    NUM_INFERENCES=1 \
    NUM_BYTES_TO_PRINT=0 \
    COMPARE_OUTPUT_DATA=no

pushd tensorflow/lite/micro/tools/make/gen/fvp_cortex-m55/bin/

fromelf --bin --bincombined --output="$use_case"_test.bin test_runner_test
fromelf -c test_runner_test > "$use_case".dis

mkdir -p "$SW/$use_case"
cp -r test_runner_test "$SW/$use_case/$use_case.axf"
cp -r "$use_case".dis "$SW/$use_case/$use_case.dis"

popd
