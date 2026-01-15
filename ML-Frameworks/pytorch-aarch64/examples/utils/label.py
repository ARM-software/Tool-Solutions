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

import torch

from . import common


def _get_labels_file(labels_loc):
    """
    Downloads the labels file if needed, and returns the filename
    :param labels_loc: Path or URL to labels file
    """
    labels_file = labels_loc

    # get labels file
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

    probabilities = torch.nn.functional.softmax(predictions[0], dim=0)
    _, top5_catid = torch.topk(probabilities, 5)
    print("---------------------------------")
    print("Top prediction is: " + labels[top5_catid[0]])
    print("---------------------------------")

    print("---------- Top 5 labels ---------")
    print(labels[top5_catid])
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
        common.RETINANET_NAME: _detect_objects_retinanet,
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
    classes = np.flip(classes[0].numpy(), 0)
    threshold = model_descriptor["model"]["threshold"]
    print("---------------------------------")
    for idx, score in enumerate(np.flip(scores[0].numpy(), 0)):
        # if score is less then threshold then
        # we ignore all objects that are below it
        if score < threshold:
            break

        detected_object = labels[int(classes[idx]) - 1]

        print(f'Detected {detected_object} with confidence {score:.2%}')
        objects.append(detected_object)
    print("---------------------------------")

    return objects


def _detect_objects_retinanet(model_descriptor, predictions):
    """
    Labels objects that are detected whose confidence is above given threshold from SSD-ResNet34
    :param model_descriptor: Parsed yaml file describing model and its labels and threshold
    :param predictions: Results from running inference
    :returns: List of label strings, in order of confidence
    """
    labels_file = _get_labels_file(model_descriptor["model"]["labels"])
    json_dict = json.load(open(labels_file))
    label_names = [item["name"] for item in json_dict["categories"]]

    # Unwrapping the single value predictions array
    [results] = predictions
    label_idxs = results['labels'].cpu()
    scores = results['scores'].cpu()

    threshold = model_descriptor["model"]["threshold"]

    objects = []

    print("---------------------------------")
    for label_idx, score in zip(label_idxs, scores):
        if score < threshold:
            break

        detected_object = label_names[label_idx]

        print(f'Detected {detected_object} with confidence {score:.2%}')
        objects.append(detected_object)
    print("---------------------------------")

    return objects
