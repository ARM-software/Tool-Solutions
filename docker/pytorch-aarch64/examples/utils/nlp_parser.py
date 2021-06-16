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
        "-s",
        "--subject",
        type=str,
        help="Pick a SQuAD question on the given subject at random",
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
        help="Question to ask about the user-provided text. Note: SQuAD id is ignored if set.",
        required=False,
    )

    args = vars(parser.parse_args())

    return args
