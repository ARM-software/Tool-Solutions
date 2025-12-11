#!/bin/bash

# SPDX-FileCopyrightText: Copyright 2020-2023, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

# This script is  based on the upstream MLCommon's instructions to download models.
# https://github.com/mlperf/inference/tree/master/vision/classification_and_detection # wokeignore:rule=master

cd inference/vision/classification_and_detection

# ResNet50
wget https://zenodo.org/record/4588417/files/resnet50-19c8e357.pth

# RetinaNet
wget https://zenodo.org/record/6605272/files/retinanet_model_10.zip?download=1 -O retinanet_model_10.zip
unzip retinanet_model_10.zip
mv retinanet_model_10.pth resnext50_32x4d_fpn.pth
rm retinanet_model_10.zip
