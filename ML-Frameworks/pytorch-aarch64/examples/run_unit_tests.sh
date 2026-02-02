#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

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
