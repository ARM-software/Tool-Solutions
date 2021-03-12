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
    echo "Usage: $0 [-i <input-dir>] [-o <output_dir>]" 1>&2
    echo "   -i|--input     : pass the path to the directory with images that you want to convert" 1>&2
    echo "   --width        : output image width, if you wish to resize (default 224)" 1>&2
    echo "   --height       : output image height, if you wish to resize, if no value, the width will be used" 1>&2
    echo "   -g|--grayscale : output is grayscale, single channel" 1>&2
    echo "   -o|--output    : pass a output dir (default is <input-dir>/out" 1>&2
    echo "   -h|--help      : will print this message" 1>&2
    exit 1 
}

GRAYSCALE=0
IMAGE_WIDTH=224

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--input) INPUT_IMAGE_DIR="$2"; shift ;;
        -o|--output) OUTPUT_DIR="$2"; shift ;;
        --width) IMAGE_WIDTH="$2"; shift ;;
        --height) IMAGE_HEIGHT="$2"; shift ;;
        -g|--grayscale) GRAYSCALE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done


if [ -z "$INPUT_IMAGE_DIR" ];
then
    echo "Error: No input file defined."
    usage
fi

if [ -z "$OUTPUT_DIR" ];
then
    OUTPUT_DIR=${INPUT_IMAGE_DIR}/out
fi

if [ -z "$IMAGE_HEIGHT" ];
then
    IMAGE_HEIGHT=$IMAGE_WIDTH
fi

[ -d $OUTPUT_DIR ] || mkdir -p $OUTPUT_DIR

cat $BASEDIR/images_header.hpp.template > $OUTPUT_DIR/images.hpp
cat $BASEDIR/images_header.cpp.template > $OUTPUT_DIR/images.cpp

NUM_IMAGES=0

for FILE in $INPUT_IMAGE_DIR/*; 
do 
    OUTPUT_FILE=${FILE##*/}
    OUTPUT_FILE="${OUTPUT_FILE%.*}"
    OUTPUT_FILE=${OUTPUT_FILE//[^[:alnum:]]/_}
    convert_command="$BASEDIR/convert_image_to_cpp.sh -i $FILE -o $OUTPUT_DIR/${OUTPUT_FILE}.cpp -g $GRAYSCALE --width $IMAGE_WIDTH --height $IMAGE_HEIGHT" ;

    if command $convert_command &> /dev/null
    then
        echo "extern const unsigned char ${OUTPUT_FILE}[IMAGE_DATA_SIZE];" >> $OUTPUT_DIR/images.hpp
        
        sed -i "/^.*image_names\[\].*/a \ \ \ \ \"$OUTPUT_FILE\"," $OUTPUT_DIR/images.cpp
        sed -i "/^.*image_pointers\[\].*/a \ \ \ \ $OUTPUT_FILE," $OUTPUT_DIR/images.cpp
        
        NUM_IMAGES=$(($NUM_IMAGES + 1))
        echo "Converted image $FILE"
    fi
done

cat $BASEDIR/images_footer.hpp.template >> $OUTPUT_DIR/images.hpp

if [ $GRAYSCALE = 1 ]
then 
    CHANNELS=1
else
    CHANNELS=3
fi

NUM_BYTES=$(($CHANNELS * $IMAGE_WIDTH * $IMAGE_HEIGHT))
sed -i "s/\[\[NUM_BYTES\]\]/$NUM_BYTES/g" $OUTPUT_DIR/images.hpp
sed -i "s/\[\[NUM_IMAGES\]\]/$NUM_IMAGES/g" $OUTPUT_DIR/images.hpp

echo "Converted images in $INPUT_IMAGE_DIR to $OUTPUT_DIR"

exit 0;