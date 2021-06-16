# *******************************************************************************
# Copyright 2021 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************
"""
Parse arguments from the command line
"""

import argparse
import os

import requests


def parse_arguments():
    """
    Takes arguments from the command line and checks whether
    they have been parsed correctly
    """
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-m",
        "--model",
        type=str,
        help="Path to YAML file describing model to run",
        required=True,
    )
    parser.add_argument(
        "-i",
        "--image",
        type=str,
        help="URL to image that will be processed",
        required=True,
    )
    parser.add_argument(
        "-r",
        "--runs",
        type=int,
        help="Number of inference runs",
        default=5,
        required=False,
    )

    args = vars(parser.parse_args())

    assert (
        args["runs"] > 0
    ), "Number of inference runs must be greater then zero"

    # Check whether path to the model descriptor exists
    assert os.path.isfile(
        args["model"]
    ), "File describing model does not exists"

    # Check whether the URL given for image exists
    try:
        requests.get(args["image"])
    except requests.ConnectionError as _:
        assert False, "Image URL is not available!"

    return args
