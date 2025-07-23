#!/bin/bash -e

# *******************************************************************************
# Copyright 2025 Arm Limited and affiliates.
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

LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libtcmalloc.so.4 DNNL_DEFAULT_FPMATH_MODE=BF16 /
    python pytorch/test/test_mkldnn.py
LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libtcmalloc.so.4 DNNL_DEFAULT_FPMATH_MODE=BF16 /
    python pytorch/test/test_transformers.py
