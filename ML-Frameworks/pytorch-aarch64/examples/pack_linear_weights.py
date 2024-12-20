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
Example of the prepacking functionality introduced in this PR:
https://github.com/pytorch/pytorch/pull/139387

By prepacking the weights for linear layers, performance on aarch64
is improved by skipping unnecessary weight reorders during inference.
"""

import torch

M = 128
K = 256
N = 512

class Foo(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.linear = torch.nn.Linear(N, K, dtype=torch.float32, bias=bias)

    def forward(self, x):
        return self.linear(x)

model = Foo()

# Pack the linear weights
packed_model = torch.nn.utils.pack_linear.pack_linear_weights(model)
inputs = (
    torch.randint(0, 128, (M, N), dtype=torch.float32)
)

# Run packed model
packed_model(inputs)

# With autocast
with torch.autocast(device_type="cpu", dtype=torch.bfloat16):
    autocast_packed_model = torch.nn.utils.pack_linear.pack_linear_weights(model)
    autocast_packed_model(inputs)