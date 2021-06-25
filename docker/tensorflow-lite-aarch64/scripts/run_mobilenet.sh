#!/bin/bash

echo 'Retrieving MobileNetV1...'
wget https://zenodo.org/record/2269307/files/mobilenet_v1_1.0_224.tgz
tar -xzf mobilenet_v1_1.0_224.tgz ./mobilenet_v1_1.0_224.tflite
rm -f mobilenet_v1_1.0_224.tgz

num_cpus=`grep -c ^processor /proc/cpuinfo`
if [ ${num_cpus} > 8 ];
then
    num_cpus=8;
fi

echo 'Executing MobileNetV1 ten times with ArmNN as standalone...'
taskset -c 0-$((num_cpus-1)) /packages/armnn/build/tests/ExecuteNetwork -c CpuAcc -f tflite-binary -m mobilenet_v1_1.0_224.tflite -T parser -i input -o MobilenetV1/Predictions/Reshape_1 --number-of-threads ${num_cpus} --iterations 10

echo 'Executing MobileNetV1 ten times with ArmNN as delegate...'
taskset -c 0-$((num_cpus-1)) /packages/tflite_build/benchmark_model --graph=mobilenet_v1_1.0_224.tflite --external_delegate_path=/packages/armnn/build/delegate/libarmnnDelegate.so --external_delegate_options="backends:CpuAcc;number-of-threads:${num_cpus}" --num_runs=10 --warmup_runs=5
