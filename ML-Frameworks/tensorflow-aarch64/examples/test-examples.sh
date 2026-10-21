#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025, 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Runs the same runnable examples listed in the README.md. Whenever new examples are
# added to the README.md, they should be added here too.

python classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
# wokeignore:rule=master
python detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
