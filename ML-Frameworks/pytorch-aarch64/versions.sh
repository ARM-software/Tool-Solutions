#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# For information on how to update the versions below, read the README.md.

# get-source.sh deps
PYTORCH_HASH=01949e998f4ecac6f0e3661285bbd12ce1467779   # 2.15.0.dev20261001 from viable/strict, Oct 1th, 2026
IDEEP_HASH=3d5a3a466de3952f4aa56632c23660243da1802d     # From ideep_pytorch, Sep 27th, 2026
ONEDNN_HASH=3618ea62a9f1ccd98bacb2c683296c08c1e87b96    # From main, Sep 27th, 2026
KLEIDIAI_HASH=f68e4feebff1599632cdd900d1acf3ba9808aece  # v1.31.0 from main, Sep 25th, 2026

# build-wheel.sh deps
OPENBLAS_VERSION="v0.3.34"  # Juy 17th, 2026

# Dockerfile deps
TORCHVISION_NIGHTLY="0.30.0.dev20260927"
TORCHAO_NIGHTLY="0.19.0.dev20260928"
