#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# For information on how to update the versions below, read the README.md.

# get-source.sh deps
PYTORCH_HASH=e89c5aa724af75b3d439f7237d8815de19f284a3   # 2.14.0.dev20260707 from viable/strict, July 7th, 2026
IDEEP_HASH=78d0ba267580381a4efa7344d97091499d978de4     # From ideep_pytorch, July 2th, 2026
ONEDNN_HASH=47b2bf4f4df49310a7b81e848d85a0c6ac737a22    # From main, July 14th, 2026
KLEIDIAI_HASH=13cd35993d8439143aff1e756a862d366acded0d  # v1.29.0 from main, July 22th, 2026

# build-wheel.sh deps
OPENBLAS_VERSION="v0.3.33"  # Apr 23rd

# Dockerfile deps
TORCHVISION_NIGHTLY="0.29.0.dev20260726"
TORCHAO_NIGHTLY="0.18.0.dev20260726"
