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

if [[ "${ONEDNN_DEFAULT_FPMATH_MODE:-}" == "BF16" ]]; then
    # Run bfloat16 tests but carefully ignore float16
    OMP_NUM_THREADS=16 python3 -m pytest -q pytorch/test/test_mkldnn.py -k 'bfloat16 or ((lower_precision or bf16) and not float16)'
else
    OMP_NUM_THREADS=16 python3 -m pytest -q pytorch/test/test_mkldnn.py
fi

if [[ "${ONEDNN_DEFAULT_FPMATH_MODE:-}" == "BF16" ]]; then
    # Run bfloat16 tests but carefully ignore float16
    OMP_NUM_THREADS=16 python3 -m pytest -q pytorch/test/test_transformers.py -k 'bfloat16 or ((lower_precision or bf16) and not float16)'
else
    OMP_NUM_THREADS=16 python3 -m pytest -q pytorch/test/test_transformers.py
fi
