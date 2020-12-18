#!/bin/bash

# This script is  based on the upstream MLCommon's instructions to download models.
# https://github.com/mlperf/inference/tree/master/vision/classification_and_detection

cd vision/classification_and_detection
# ssd-resnet34
wget https://zenodo.org/record/3236545/files/resnet34-ssd1200.pytorch
