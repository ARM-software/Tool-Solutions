#!/bin/bash

#CMSIS-repo location
CMSIS_DIR=./CMSIS_REPO/cmsis
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
sed -i -E 's#-Wl,--fatal-warnings # #' ${TFLM_ROOT}/tools/make/Makefile
sed -i -E 's/-Wl,--gc-sections//g' ${TFLM_ROOT}/tools/make/Makefile

 


