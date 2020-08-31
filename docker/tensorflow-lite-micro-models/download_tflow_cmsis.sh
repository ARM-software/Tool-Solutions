#!/bin/bash

#CMSIS-repo location
CMSIS_DIR=./CMSIS_REPO/cmsis
#TensorFlow Lite Micro location
TFLM_ROOT=$PWD/tensorflow/tensorflow/lite/micro

#Clone the tensorflow git repo if you haven't already
if [ ! -d "tensorflow" ]
then
    git clone https://github.com/tensorflow/tensorflow.git
else
    echo "Tensorflow repo already cloned"
fi


#Clone CMSIS repo if you haven't already
if [ ! -d $CMSIS_DIR ]
then
    git clone https://github.com/ARM-software/CMSIS_5.git $CMSIS_DIR
else
    echo "CMSIS repo already cloned"
fi



#Copy the files to the right locations
cp -r $PWD/TFLite_micro_IPSS_Support/helper_functions.inc ${TFLM_ROOT}/tools/make/
cp -r $PWD/TFLite_micro_IPSS_Support/armclang ${TFLM_ROOT}/tools/make/templates
cp -r $PWD/TFLite_micro_IPSS_Support/ipss* ${TFLM_ROOT}/tools/make/targets/
cp -r $PWD/TFLite_micro_IPSS_Support/cmsis.inc ${TFLM_ROOT}/tools/make/ext_libs/

# Removing -Werror from armclang option, making the build fail
sed -i -E 's#-Werror # #' ${TFLM_ROOT}/tools/make/Makefile

# A fix for fully_connected.cc, making the tests fail. 
# A line was removed in tensorflow commit 88461053262f02bbc15887daa172c02db7419780
sed -i '/fc_params.input_offset = -data.input_zero_point;/\,/fc_params.output_offset = data.output_zero_point;/c\
    fc_params.input_offset = -data.input_zero_point;\
    fc_params.filter_offset = -data.filter_zero_point;\
    fc_params.output_offset = data.output_zero_point;' \
    ${TFLM_ROOT}/kernels/cmsis-nn/fully_connected.cc
