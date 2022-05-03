# *******************************************************************************
# Copyright 2021-2022 Arm Limited and affiliates.
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
Utility functions to label predictions
"""

import os
import sys
import urllib.request
import json

import numpy as np

import torch

from . import common


def classify_predictions(model_file, predictions):
    """
    Gets the label file and prints out top prediction and top 5 predictions
    :param model_file: Path to file describing where to get labels
    :param predictions: Result from running inference
    """

    model_descriptor = common.parse_model_file(model_file)
    labels_loc = model_descriptor["model"][0]["labels"]
    labels_file = labels_loc

    # get labels file
    if labels_loc.startswith('http'):
        labels_file = labels_loc.split("/")[-1]  # filename

        if not os.path.isfile(labels_file):
            # Download the labels if required
            urllib.request.urlretrieve(labels_loc, labels_file)

    if not os.path.isfile(labels_file):
        sys.exit("Labels file %s does not exist!" % labels_file)

    class_idx = json.load(open(labels_file))
    labels = np.asarray([class_idx[str(k)][1] for k in range(len(class_idx))])

    probabilities = torch.nn.functional.softmax(predictions[0], dim=0)
    _, top5_catid = torch.topk(probabilities, 5)
    print("---------------------------------")
    print("Top prediction is: " + labels[top5_catid[0]])
    print("---------------------------------")

    print("---------- Top 5 labels ---------")
    print(labels[top5_catid])
    print("---------------------------------")


def detected_objects(model_file, predictions):
    """
    Labels objects that are detected whose confidence is above given threshold
    :param model_file: Path to file describing where to get labels and what threshold to use
    :param predictions: Results from running inference
    """
    model_descriptor = common.parse_model_file(model_file)
    labels_loc = model_descriptor["model"][0]["labels"]
    labels_file = labels_loc

    # Get labels file
    if labels_loc.startswith('http'):
        labels_file = labels_loc.split("/")[-1]  # filename
        if not os.path.isfile(labels_file):
            # Download the labels if required
            urllib.request.urlretrieve(labels_loc, labels_file)

    if not os.path.isfile(labels_file):
        sys.exit("Labels file %s does not exist!" % labels_file)

    labels = []
    with open(labels_file) as labels_f:
        for line in labels_f.readlines():
            labels.append(line.strip())

    objects = []
    _, classes, scores = predictions
    classes = np.flip(classes[0].numpy(), 0)
    threshold = model_descriptor["model"][0]["threshold"]
    print("---------------------------------")
    for idx, score in enumerate(np.flip(scores[0].numpy(), 0)):
        # if score is less then threshold then
        # we ignore all objects that are below it
        if score < threshold:
            break

        print(
            "Detected %s with confidence %.2f%%"
            % (labels[int(classes[idx]) - 1], score * 100)
        )
        objects.append(labels[int(classes[idx]) - 1])
    print("---------------------------------")

    return objects
