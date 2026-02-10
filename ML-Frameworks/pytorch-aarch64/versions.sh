#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# get-source.sh deps
PYTORCH_HASH=77da53a7356e033e3fc1e03fdd960fc4ad117882   # 2.11.0.dev20260129 from viable/strict, Jan 29th
IDEEP_HASH=bbb9ffb9e0c401ca058b7f35a6ebe7d0e08ffd34     # From ideep_pytorch, Jan 30th
ONEDNN_HASH=804f364c04ad8a763d534abaabc99bf99c2754e0    # From main, Jan 30th
TORCH_AO_HASH=30fcb156945ecacd515775414d37c09bfe60727e  # From main, Jan 30th
KLEIDIAI_HASH=5addaad73ebbb02e7dde6c50fff3bdb2ae8c407f  # v1.20.0 from main, Jan 30th

# build-wheel.sh deps
ACL_VERSION="v52.8.0"
OPENBLAS_VERSION="v0.3.30"

# Dockerfile deps
TORCHVISION_NIGHTLY="0.25.0.dev20260130"
