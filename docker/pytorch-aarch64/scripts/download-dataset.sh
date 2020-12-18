#!/bin/bash

# This script is based on the upstream MLCommon's instructions to download datasets.
# https://github.com/mlperf/inference/tree/master/vision/classification_and_detection

# Download coco dataset
ck install package --tags=object-detection,dataset,coco,2017,val,original
