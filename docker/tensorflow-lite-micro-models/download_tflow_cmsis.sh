#!/bin/bash

#CMSIS-repo location
CMSIS_DIR=./CMSIS_REPO
TFLM_ROOT=$PWD/tensorflow/tensorflow/lite/micro

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
cp -r $PWD/TFLite_micro_IPSS_Support/helper_functions.inc ${TFLM_ROOT}/tools/make/
cp -r $PWD/TFLite_micro_IPSS_Support/armclang ${TFLM_ROOT}/tools/make/templates
cp -r $PWD/TFLite_micro_IPSS_Support/ipss* ${TFLM_ROOT}/tools/make/targets/
cp -r $PWD/TFLite_micro_IPSS_Support/cmsis.inc ${TFLM_ROOT}/tools/make/ext_libs/


# Fix double-promotion warning in mul.cc
sed -i -E 's#input1->params.scale \* input2->params.scale \/ output->params.scale;#static_cast<double>\(input1->params.scale\) \*\
        static_cast<double>\(input2->params.scale\) \/\
        static_cast<double>\(output->params.scale\);#' \
        ${TFLM_ROOT}/kernels/cmsis-nn/mul.cc

# Fix missing-field-initializers warning in mul.cc
sed -i -E 's#return \{mul::Init, nullptr \/\* Free \*\/, mul::Prepare, mul::Eval\};#return \{mul::Init,\
        nullptr \/\* Free \*\/,\
        mul::Prepare,\
        mul::Eval, \
        \/\*profiling_string=\*\/nullptr,\
        \/\*builtin_code=\*\/0,\
        \/\*custom_name=\*\/nullptr,\
        \/\*version=\*\/0};#' \
        ${TFLM_ROOT}/kernels/cmsis-nn/mul.cc

