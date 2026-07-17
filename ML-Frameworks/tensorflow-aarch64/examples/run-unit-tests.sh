#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

python tensorflow/tensorflow/python/module/module_test.py
python tensorflow/tensorflow/python/kernel_tests/nn_ops/conv_ops_test.py
