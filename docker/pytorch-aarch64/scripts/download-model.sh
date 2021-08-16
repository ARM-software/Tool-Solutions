#!/bin/bash
set -euo pipefail

# This script is  based on the upstream MLCommon's instructions to download models.
# https://github.com/mlperf/inference/tree/master/vision/classification_and_detection

cd inference/vision/classification_and_detection
# ResNet50
wget https://zenodo.org/record/4588417/files/resnet50-19c8e357.pth
# SSD-ResNet34
wget https://zenodo.org/record/3236545/files/resnet34-ssd1200.pytorch
