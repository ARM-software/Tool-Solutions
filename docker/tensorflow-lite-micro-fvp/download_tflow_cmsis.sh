#!/bin/bash

#CMSIS-repo location
CMSIS_DIR=./CMSIS_REPO
#TensorFlow Lite Micro location
TFLM_ROOT=$PWD/tensorflow/tensorflow/lite/micro


#Clone the tensorflow git repo if you haven't already
if [ ! -d "tensorflow" ]
then
    git clone -b v2.4.1 https://github.com/tensorflow/tensorflow.git
else
    echo "Tensorflow repo already cloned"
fi


#Clone CMSIS repo if you haven't already
if [ ! -d "./CMSIS_REPO/CMSIS_5" ]
then
    mkdir $CMSIS_DIR
    pushd $CMSIS_DIR
    git clone https://github.com/ARM-software/CMSIS_5.git
    popd
else
    echo "CMSIS repo already cloned"
fi


#Copy the files to the right locations
cp -r $PWD/TFLite_micro_FVP_Support/helper_functions.inc $PWD/tensorflow/tensorflow/lite/micro/tools/make/
cp -r $PWD/TFLite_micro_FVP_Support/armclang $PWD/tensorflow/tensorflow/lite/micro/tools/make/templates
cp -r $PWD/TFLite_micro_FVP_Support/fvp* $PWD/tensorflow/tensorflow/lite/micro/tools/make/targets/
cp -r $PWD/TFLite_micro_FVP_Support/cmsis.inc $PWD/tensorflow/tensorflow/lite/micro/tools/make/ext_libs/

#Remove -Wl, --fatal-warnings for Arm Compiler
sed -i -E 's#-Werror # #' ${TFLM_ROOT}/tools/make/Makefile
sed -i -E 's#-Wl,--fatal-warnings # #' ${TFLM_ROOT}/tools/make/Makefile
sed -i -E 's/-Wl,--gc-sections//g' ${TFLM_ROOT}/tools/make/Makefile

