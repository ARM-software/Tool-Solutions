#!/bin/bash

# =========================================
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the License); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# =========================================
#
# this script is created and maintained by 
# Tobias Andersson (Arm K.K)
# email: tobias.andersson@arm.com
#
# It is released As Is
# You are free to use and modify without restrictions.
#
# =========================================

# Templates are in this directory
BASEDIR=$(dirname "$0")

# Usage: takes model as input
usage() { 
    echo "Usage: $0 [-i <model.tflite>] [-o <output.cpp>]" 1>&2
    echo "   -i|--input     pass the path to the model that you want to convert" 1>&2
    echo "   -o|--output    pass a output file path (default is <model.tflite>.cpp" 1>&2
    echo "   -h|--help      option will print this message" 1>&2
    exit 1 
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) TFLITE_MODEL_FILE="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

if [ -z "$TFLITE_MODEL_FILE" ];
then
    echo "Error: No input file defined."
    usage
fi

if [ -z "$OUTPUT_FILE" ];
then
    OUTPUT_FILE=${TFLITE_MODEL_FILE##*/}
    OUTPUT_FILE="${OUTPUT_FILE%.*}"
    OUTPUT_FILE=${OUTPUT_FILE//[^[:alnum:]]/_}.cpp
fi

# write the header to the cpp-file
cat $BASEDIR/model_header.cpp.template > $OUTPUT_FILE

# write the tflite-model data to the cpp-file
xxd -i $TFLITE_MODEL_FILE >> $OUTPUT_FILE

# write the footer to the cpp-file
cat $BASEDIR/model_footer.cpp.template >> $OUTPUT_FILE

# get the output variable name
x="grep -o -P '(?<=unsigned char ).*(?=\[\])' $OUTPUT_FILE"
GENERATED_MODEL_NAME=$(eval "$x")

INPUT_FILE_NAME=${TFLITE_MODEL_FILE##*/}
MODEL_NAME=${INPUT_FILE_NAME//[^[:alnum:]]/_}

# use variable name in footer-methods
sed -i "s/$GENERATED_MODEL_NAME/$MODEL_NAME/g" $OUTPUT_FILE
sed -i 's/unsigned char/const unsigned char/g' $OUTPUT_FILE
sed -i "s/\[\[model_name\]\]/$MODEL_NAME/g" $OUTPUT_FILE
sed -i 's/\[\] = {/\[\] __attribute__\(\(section\("network_model_sec"\), aligned\(16\)\)\) = {/g' $OUTPUT_FILE

