#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# For information on how to update the versions below, read the README.md.

# get-source.sh deps
PYTORCH_HASH=434b8cfdfac8ef7c741385561e340781ad76512f   # 2.12.0.dev20260227 from viable/strict, Feb 27th
IDEEP_HASH=bbb9ffb9e0c401ca058b7f35a6ebe7d0e08ffd34     # From ideep_pytorch, Jan 16th
ONEDNN_HASH=a83f8b4c7ca45fb339f3ecdf82895bc496941808    # From main, Feb 27th
TORCH_AO_HASH=9bdc0ca87c1134b7c1dedaa9512233b726f22955  # From main, Feb 27th
KLEIDIAI_HASH=98a6df72bdbb566bc7d8ba13d71991bcd94a8393  # v1.22.0 from main, Feb 19th

# build-wheel.sh deps
ACL_VERSION="v52.8.0"
OPENBLAS_VERSION="v0.3.31"

# Dockerfile deps
TORCHVISION_NIGHTLY="0.25.0.dev20260130"
