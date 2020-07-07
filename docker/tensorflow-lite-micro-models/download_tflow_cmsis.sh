#!/bin/bash

#CMSIS-repo location
CMSIS_DIR=./CMSIS_REPO

#Clone the tensorflow git repo if you haven't already
if [ ! -d "tensorflow" ]
then
    git clone https://github.com/tensorflow/tensorflow.git
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
cp -r $PWD/TFLite_micro_IPSS_Support/helper_functions.inc $PWD/tensorflow/tensorflow/lite/micro/tools/make/
cp -r $PWD/TFLite_micro_IPSS_Support/armclang $PWD/tensorflow/tensorflow/lite/micro/tools/make/templates
cp -r $PWD/TFLite_micro_IPSS_Support/ipss* $PWD/tensorflow/tensorflow/lite/micro/tools/make/targets/
cp -r $PWD/TFLite_micro_IPSS_Support/cmsis.inc $PWD/tensorflow/tensorflow/lite/micro/tools/make/ext_libs/


