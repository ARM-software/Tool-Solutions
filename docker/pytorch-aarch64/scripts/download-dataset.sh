#!/bin/bash
set -euo pipefail

# This script is based on the upstream MLCommon's instructions to download datasets.
# https://github.com/mlperf/inference/tree/master/vision/classification_and_detection

# Download ImageNet's validation set
# These will be installed to ${HOME}/CK_TOOLS/
# Select option 1: val-min data set. Issue when downloading the complete val data set using ck-env [https://github.com/ctuning/ck-env/issues/101]

ck install package --tags=image-classification,dataset,imagenet,aux
ck install package --tags=image-classification,dataset,imagenet,val

# Copy the labels into the image location
cp ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-aux/val.txt ${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min/val_map.txt

# Download coco dataset
ck install package --tags=object-detection,dataset,coco,2017,val,original
