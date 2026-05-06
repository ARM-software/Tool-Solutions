#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# For information on how to update the versions below, read the README.md.

# get-source.sh deps
PYTORCH_HASH=004acb4e35805062a643ee1588cdae584b2b2957   # 2.13.0.dev20260504 from viable/strict, May 4th, 2026
IDEEP_HASH=6469a610baaa94ba15de1902fd1afb25316171d2     # From ideep_pytorch, Apr 23rd, 2026
ONEDNN_HASH=8fa20dc93a75c094f618f3f8c206775731d63301    # From main, May 5th, 2026
KLEIDIAI_HASH=7a7da265d21f42053d453ef664814c5b5cad8cd3  # v1.24.0 from main, May 4th, 2026

# build-wheel.sh deps
ACL_VERSION="v53.0.0"   # Apr 10th
OPENBLAS_VERSION="v0.3.33"  # Apr 23rd

# Dockerfile deps
TORCHVISION_NIGHTLY="0.27.0.dev20260505"
TORCHAO_NIGHTLY="0.18.0.dev20260505"
