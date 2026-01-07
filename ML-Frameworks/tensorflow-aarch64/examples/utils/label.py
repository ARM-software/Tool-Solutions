# SPDX-FileCopyrightText: Copyright 2021-2023, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Utility functions to label predictions
"""

import os
import sys
import urllib.request
import json

import numpy as np

from . import common


def _get_labels_file(labels_loc):
    """
    Downloads the labels file if needed, and returns the filename
    :param labels_loc: Path or URL to labels file
    """
    labels_file = labels_loc

    # Get labels file
    if labels_loc.startswith('http'):
        labels_file = labels_loc.split("/")[-1]  # filename

        if not os.path.isfile(labels_file):
            # Download the labels if required
            urllib.request.urlretrieve(labels_loc, labels_file)

    if not os.path.isfile(labels_file):
        sys.exit("Labels file %s does not exist!" % labels_file)

    return labels_file


def classify_predictions(model_descriptor, predictions):
    """
    Gets the label file and prints out top prediction and top 5 predictions
    :param model_descriptor: Parsed yaml file describing model and its labels
    :param predictions: Result from running inference
    """
    labels_file = _get_labels_file(model_descriptor["model"]["labels"])

    class_idx = json.load(open(labels_file))
    labels = np.asarray([class_idx[str(k)][1] for k in range(len(class_idx))])

    idx = np.argmax(predictions)

    print("---------------------------------")
    print("Top prediction is: " + labels[idx - 1])
    print("---------------------------------")

    sort_idx = np.flip(np.squeeze(np.argsort(predictions))) - 1
    print("---------- Top 5 labels ---------")
    print(labels[sort_idx[:5]])
    print("---------------------------------")


def detected_objects(model_descriptor, predictions):
    """
    Labels objects that are detected whose confidence is above given threshold
    :param model_descriptor: Parsed yaml file describing model and its labels and threshold
    :param predictions: Results from running inference
    :returns: List of label strings, in order of confidence
    """
    model_name = model_descriptor["model"]["name"]

    # Getting the appropriate detected_object function for the model
    detected_func = {
        common.SSD_RESNET34_NAME: _detect_objects_ssd_resnet34
    }[model_name]

    return detected_func(model_descriptor, predictions)


def _detect_objects_ssd_resnet34(model_descriptor, predictions):
    """
    Labels objects that are detected whose confidence is above given threshold from SSD-ResNet34
    :param model_descriptor: Parsed yaml file describing model and its labels and threshold
    :param predictions: Results from running inference
    :returns: List of label strings, in order of confidence
    """
    labels_file = _get_labels_file(model_descriptor["model"]["labels"])

    labels = []
    with open(labels_file) as labels_f:
        for line in labels_f.readlines():
            labels.append(line.strip())

    objects = []
    _, classes, scores = predictions
    threshold = model_descriptor["model"]["threshold"]
    print("---------------------------------")
    for idx, score in enumerate(scores[0]):
        # if score is less then threshold then
        # we ignore all objects that are below it
        if score < threshold:
            break

        detected_object = labels[int(classes[0][idx]) - 1]

        print(f'Detected {detected_object} with confidence {score:.2%}')
        objects.append(detected_object)
    print("---------------------------------")

    return objects
