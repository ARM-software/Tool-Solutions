# SPDX-FileCopyrightText: Copyright 2021, 2023, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Helper methods that are common between utility functions
"""

import yaml


RESNET50_NAME = "resnet50_v1.pb"
SSD_RESNET34_NAME = "resnet34_tf.22.5.nhwc.pb"


def parse_model_file(model_file):
    """
    Parses YAML configuration file to dictionary
    :param model_file: Path to model descriptor to parse
    """

    with open(model_file) as model_file_handle:
        model_descriptor = yaml.load(model_file_handle, Loader=yaml.FullLoader)

    return model_descriptor
