# SPDX-FileCopyrightText: Copyright 2021, 2022, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
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
        help="URL or filename of image to process",
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

    # Check the image exists
    if args["image"].startswith('http'):
        try:
            requests.get(args["image"])
        except requests.ConnectionError as _:
            assert False, "Image URL is not available!"
    else:
        try:
            os.path.isfile(args["image"])
        except:
            assert False, "Image not found"

    return args
