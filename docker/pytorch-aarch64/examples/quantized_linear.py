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

import sys
import os

import torch
import torch.nn as nn

import time

import numpy as np

class Net(nn.Module):
    def __init__(self, K, N):
        super(Net, self).__init__()

        self.linear = torch.nn.Linear(K, N)

    def forward(self, x):
        x = self.linear(x)
        return x

M = int(sys.argv[1])
K = int(sys.argv[2])
N = int(sys.argv[3])

model = Net(K, N)
model = model.eval()

data = torch.randn(M, K)

# Not quantized
fp32_runtimes = []
with torch.no_grad():
    model(data)
    for _ in range(10):
        t0 = time.time()
        model(data)
        fp32_runtimes.append(time.time() - t0)

model = torch.ao.quantization.quantize_dynamic(
    model,
    {torch.nn.Linear},
    dtype=torch.qint8)

# Quantized
runtimes = []
with torch.no_grad():
    model(data)
    for _ in range(10):
        t0 = time.time()
        model(data)
        runtimes.append(time.time() - t0)

print('Quantized: %.4fms, FP32: %.4fms, Speedup: %.4f' % (np.min(runtimes)*1e3, np.min(fp32_runtimes)*1e3, np.min(fp32_runtimes)/np.min(runtimes)))