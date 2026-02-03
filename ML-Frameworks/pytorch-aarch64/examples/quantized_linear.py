# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

import sys

import torch
import torch.nn as nn
from torchao.quantization.quant_api import (
    Int8DynamicActivationIntxWeightConfig,
    quantize_,
)
from torchao.quantization.granularity import PerAxis
from torchao.quantization.quant_primitives import MappingType

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

quantize_(
    model,
    Int8DynamicActivationIntxWeightConfig(
        weight_scale_dtype=torch.float32,
        weight_granularity=PerAxis(0),
        weight_mapping_type=MappingType.SYMMETRIC_NO_CLIPPING_ERR,
        weight_dtype=torch.int4,
        intx_packing_format="opaque_aten_kleidiai",
        version=2,
    ),
    filter_fn=lambda m, _: isinstance(m, torch.nn.Linear),
)

# Quantized
runtimes = []
with torch.no_grad():
    model(data)
    for _ in range(10):
        t0 = time.time()
        model(data)
        runtimes.append(time.time() - t0)

print('Quantized: %.4fms, FP32: %.4fms, Speedup: %.4f' % (np.min(runtimes)*1e3, np.min(fp32_runtimes)*1e3, np.min(fp32_runtimes)/np.min(runtimes)))