#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Source-of-truth versions and hashes for this repo

# For information on how to update the versions below, read the README.md.

# get-source.sh deps
PYTORCH_HASH=c230e6986c6aaee101e24ca14813c21add0b148f   # 2.13.0.dev20260528 from viable/strict, May 28th, 2026
IDEEP_HASH=e087b6e4b32a7ba684db82231d1558123968ac1d     # From ideep_pytorch, May 11th, 2026
ONEDNN_HASH=3004f0a1d9cf92c06eaaca57840aaa2149ebba85    # From main, May 27th, 2026
KLEIDIAI_HASH=5866364d3bc079d2d6cae5f0acf6d076594bc7a7  # v1.25.0 from main, May 28th, 2026

# build-wheel.sh deps
OPENBLAS_VERSION="v0.3.33"  # Apr 23rd

# Dockerfile deps
TORCHVISION_NIGHTLY="0.28.0.dev20260527"
TORCHAO_NIGHTLY="0.18.0.dev20260528"
