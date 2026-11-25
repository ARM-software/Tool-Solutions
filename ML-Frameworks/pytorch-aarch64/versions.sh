#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# For information on how to update the versions below, read the README.md.

# get-source.sh deps
PYTORCH_HASH=68f0e54fd5ad3d7ceba57b36a5c2ebbacd3d6756   # 2.16.0.dev20261116 from viable/strict, Nov 16th, 2026
IDEEP_HASH=788fed8c794f1e934b1c2330b69de3fed3905bec     # From ideep_pytorch, Oct 30th, 2026
ONEDNN_HASH=9c7a3b6d6cf4e4068a16a30f65e4c5f7b0539c78    # From main, Nov 24th, 2026
KLEIDIAI_HASH=2b0c108eb6a19e12e1e57cb84a2ce1773aa8b3ae  # v1.34.0 from main, Nov 24th, 2026

# build-wheel.sh deps
OPENBLAS_VERSION="v0.3.34"  # Jul 17th, 2026

# Dockerfile deps
TORCHVISION_NIGHTLY="0.30.0.dev20261007"
TORCHAO_NIGHTLY="0.19.0.dev20261124"
