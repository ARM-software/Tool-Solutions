#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2021-2023 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************

echo 'Retrieving MobileNetV1...'
wget https://zenodo.org/record/2269307/files/mobilenet_v1_1.0_224.tgz
tar -xzf mobilenet_v1_1.0_224.tgz ./mobilenet_v1_1.0_224.tflite
rm -f mobilenet_v1_1.0_224.tgz

num_cpus=`nproc`
if [ $num_cpus -gt "8" ];
then
    num_cpus=8;
fi

echo 'Executing MobileNetV1 ten times with ArmNN as standalone...'
taskset -c 0-$((num_cpus-1)) /packages/armnn/build/tests/ExecuteNetwork -c CpuAcc -m mobilenet_v1_1.0_224.tflite -N -I 10 --number-of-threads ${num_cpus}

echo 'Executing MobileNetV1 ten times with ArmNN as delegate...'
taskset -c 0-$((num_cpus-1)) /packages/tflite_build/tools/benchmark/benchmark_model --graph=mobilenet_v1_1.0_224.tflite --external_delegate_path=/packages/armnn/build/delegate/libarmnnDelegate.so --external_delegate_options="backends:CpuAcc;number-of-threads:${num_cpus}" --num_runs=10 --warmup_runs=5
