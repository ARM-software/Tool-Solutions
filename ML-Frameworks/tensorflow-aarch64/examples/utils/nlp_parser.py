# SPDX-FileCopyrightText: Copyright 2021, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Parse arguments from the command line for NLP examples.
"""

import argparse


def parse_arguments():
    """
    Takes arguments from the command line and checks whether
    they have been parsed correctly
    """
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-id",
        "--squadid",
        type=str,
        help="ID of SQuAD record to use. A record will be picked at random if unset",
        required=False,
    )
    parser.add_argument(
        "-t",
        "--text",
        type=str,
        help="Filename of a user-specified text file to answer questions on. Note: SQuAD id is ignored if set.",
        required=False,
    )
    parser.add_argument(
        "-q",
        "--question",
        type=str,
        help="Question to ask about the user-provided text, or by default, the appropriate SQuAD context. Note: SQuAD id is ignored if set.",
        required=False,
    )
    parser.add_argument(
        "-s",
        "--subject",
        type=str,
        help="Subject to specify which SQuAD context to use for question answering. Note: SQuAD id is ignored if set.",
        required=False,
    )

    args = vars(parser.parse_args())

    return args
