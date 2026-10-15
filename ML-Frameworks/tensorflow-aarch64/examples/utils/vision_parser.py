# SPDX-FileCopyrightText: Copyright 2021, 2022, 2025, 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Parse arguments from the command line
"""

import argparse
import os


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
        "-t",
        "--intra_threads",
        type=int,
        help="Number of intra-op threads to use",
        default=16,
        required=False,
    )
    parser.add_argument(
        "--inter_threads",
        type=int,
        help="Number of inter-op threads to use",
        default=2,
        required=False,
    )
    parser.add_argument(
        "-r",
        "--runs",
        type=int,
        help="Number of inference runs",
        default=5,
        required=False,
    )
    parser.add_argument(
        "-u",
        "--unoptimized",
        help="Skip optimize_for_inference step for the model",
        default=False,
        action="store_true",
    )

    args = vars(parser.parse_args())

    assert (
        args["runs"] > 0
    ), "Number of inference runs must be greater then zero"
    assert (
        args["intra_threads"] > 0
    ), "Number of intra-threads must be greater then zero"
    assert (
        args["inter_threads"] > 0
    ), "Number of inter-threads must be greater then zero"

    # Check whether path to the model descriptor exists
    assert os.path.isfile(
        args["model"]
    ), "File describing model does not exists"

    # Remote images are checked by the downloader, which retries transient failures.
    if not args["image"].startswith('http'):
        assert os.path.isfile(args["image"]), "Image not found"

    return args
