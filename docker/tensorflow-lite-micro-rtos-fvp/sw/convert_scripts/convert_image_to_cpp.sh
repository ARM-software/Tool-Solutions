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

# Usage: takes image as input
# TODO: enable to convert directory of images?
usage() { 
    echo "Usage: $0 [-i <input-image>] [-o <output.cpp>]" 1>&2
    echo "   -i|--input     : pass the path to the image that you want to convert" 1>&2
    echo "   --width        : output image width, if you wish to resize" 1>&2
    echo "   --height       : output image height, if you wish to resize, if no value, the width will be used" 1>&2
    echo "   -g|--grayscale : output is grayscale, single channel" 1>&2
    echo "   -o|--output    : pass a output file path (default is <input-image>.cpp" 1>&2
    echo "   -h|--help      : will print this message" 1>&2
    exit 1 
}

GRAYSCALE=0

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_IMAGE_FILE="$2"; shift ;;
        -o|--output) OUTPUT_FILE="$2"; shift ;;
        --width) IMAGE_WIDTH="$2"; shift ;;
        --height) IMAGE_HEIGHT="$2"; shift ;;
        -g|--grayscale) GRAYSCALE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done


if [ -z "$INPUT_IMAGE_FILE" ];
then
    echo "Error: No input file defined."
    usage
fi

if [ -z "$OUTPUT_FILE" ];
then
    OUTPUT_FILE=${INPUT_IMAGE_FILE##*/}
    OUTPUT_FILE="${OUTPUT_FILE%.*}"
    OUTPUT_FILE=${OUTPUT_FILE//[^[:alnum:]]/_}.cpp
fi

# Dont resize if no width is defined
if [ -z "$IMAGE_WIDTH" ];
then
    RESIZE=0
fi
if [ -z "$IMAGE_HEIGHT" ];
then
    IMAGE_HEIGHT=$IMAGE_WIDTH
fi

# resize and convert image to ppm/pgm format
if [ "$GRAYSCALE" = 1 ]
then
    IMAGE_EXTENSION="pgm"
else
    IMAGE_EXTENSION="ppm"
fi


CONVERTED_IMAGE_FILE="${INPUT_IMAGE_FILE%.*}".$IMAGE_EXTENSION

if [ "$RESIZE" = 0 ];
then
    convert_command="convert $INPUT_IMAGE_FILE $CONVERTED_IMAGE_FILE"
else
    convert_command="convert -resize ${IMAGE_WIDTH}x${IMAGE_HEIGHT}! $INPUT_IMAGE_FILE $CONVERTED_IMAGE_FILE"
fi
echo "$convert_command"
if ! command $convert_command &> /dev/null
then
    echo "Error: $INPUT_IMAGE_FILE is not an image"
    exit 1;
fi

# create output dir if not exists
FILE_DIR=$(dirname $OUTPUT_FILE)
[ -d $FILE_DIR ] || mkdir -p $FILE_DIR

# write the header to the cpp-file
cat $BASEDIR/image_header.cpp.template > $OUTPUT_FILE

# write the iamge data to the cpp-file
if [ "$RESIZE" = 0 ];
then
    IMAGE_WIDTH="$(identify -format '%w' $INPUT_IMAGE_FILE)"
    IMAGE_HEIGHT="$(identify -format '%h' $INPUT_IMAGE_FILE)"
fi
if [ $GRAYSCALE = 1 ]
then 
    CHANNELS=1
else
    CHANNELS=3
fi

NUM_BYTES=$(($CHANNELS * $IMAGE_WIDTH * $IMAGE_HEIGHT))
xxd -i -s -$NUM_BYTES $CONVERTED_IMAGE_FILE >> $OUTPUT_FILE

# get the output variable name
x="grep -o -P '(?<=unsigned char ).*(?=\[\])' $OUTPUT_FILE"
GENERATED_IMAGE_NAME=$(eval "$x")

INPUT_FILE_NAME=${INPUT_IMAGE_FILE##*/}
IMAGE_VARIABLE_NAME="${INPUT_FILE_NAME%.*}"
IMAGE_VARIABLE_NAME=${IMAGE_VARIABLE_NAME//[^[:alnum:]]/_}

# use variable name in footer-methods
sed -i "s/$GENERATED_IMAGE_NAME/$IMAGE_VARIABLE_NAME/g" $OUTPUT_FILE
sed -i 's/unsigned char/const unsigned char/g' $OUTPUT_FILE
sed -i 's/\[\] = {/\[\] __attribute__\(\(section\("input_data_sec"\), aligned\(4\)\)\) = {/g' $OUTPUT_FILE

rm $CONVERTED_IMAGE_FILE

echo "Converted $INPUT_IMAGE_FILE to $OUTPUT_FILE"