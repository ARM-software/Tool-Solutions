# *******************************************************************************
# Copyright 2024 Arm Limited and affiliates.
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
"""
This example showcases Pytorch static quantization using the Post-Training
Quantisation (PTQ) method with FX Graph Mode that automatically quantizes modules.
"""
import numpy as np

import torch
import torch.nn as nn
import torch.optim as optim
import torch.nn.init as init

import torch
from torch.ao.quantization import get_default_qconfig_mapping, default_symmetric_qnnpack_qconfig, get_default_qconfig
from torch.ao.quantization import QConfig, QConfigMapping
from torch.ao.quantization.quantize_fx import prepare_fx, convert_fx
from torch.ao.quantization.observer import MinMaxObserver, default_observer

from time import time

torch.manual_seed(42)

from torch.ao.quantization.backend_config import (
    BackendConfig,
    BackendPatternConfig,
    DTypeConfig,
    ObservationType,
)

weighted_int8_dtype_config = DTypeConfig(
    input_dtype=torch.qint8,
    output_dtype=torch.qint8,
    weight_dtype=torch.qint8,
    bias_dtype=torch.qint32)

# For quantizing convolution
conv2d_config = BackendPatternConfig(torch.nn.Conv2d) \
    .set_observation_type(ObservationType.OUTPUT_USE_DIFFERENT_OBSERVER_AS_INPUT) \
    .add_dtype_config(weighted_int8_dtype_config) \
    .set_root_module(torch.nn.Conv2d) \
    .set_qat_module(torch.ao.nn.qat.Conv2d) \
    .set_reference_quantized_module(torch.ao.nn.quantized.reference.Conv2d)

aarch64_backend_config = BackendConfig("aarch64") \
    .set_backend_pattern_config(conv2d_config)

# model to be quantized
class Net(nn.Module):
    def __init__(self):
        super(Net, self).__init__()

        self.conv1 = nn.Conv2d(3, 64, 7, 7)

        self._initialize_weights()

    def forward(self, x):
        x = self.conv1(x)
        return x

    def _initialize_weights(self):
        init.uniform_(self.conv1.weight)

model = Net()

my_qconfig = QConfigMapping().set_global(default_symmetric_qnnpack_qconfig)

# generate some fake data
data = torch.randn(8, 3, 896, 896)

# warm-up
model = model.eval()
model(data)

# run the model in f32
times = []
with torch.no_grad():
    for _ in range(100):
        start = time()
        x = model(data)
        times.append(time() - start)
print("F32 average time: %.4fms" %(np.average(times)*1e3))

# do fake quantization where the parameters are calculated but everything is still f32.
# That is why it is called "fake"
model_prepared = prepare_fx(model, my_qconfig, data, None, None, aarch64_backend_config)
# the prepared model uses HistogramObserver observer that derives the quantization parameters by creating a histogram
# of running minimums and maximums. More options here:
# https://glaringlee.github.io/quantization.html#:~:text=Observers%20for%20computing%20the%20quantization%20parameters

# calibrate using the data
model_prepared(data) # we need this to calculate the quantised parameters for the activations

# do the real quantization here based on the parameters, scale and zero point, calculated in the previous step
model_quantized = convert_fx(model_prepared, qconfig_mapping=my_qconfig, backend_config=aarch64_backend_config)
model_quantized.eval()

# run the model in qunatized mode (int8)
quantized_times = []
with torch.no_grad():
    for _ in range(100):
        start = time()
        y = model_quantized(data)
        quantized_times.append(time() - start)
print("Quantized average time: %.4fms" % (np.average(quantized_times)*1e3))

# comparing the results
print("L2 error between f32 and s8: %.4f" % (((x-y)**2).mean()))