# SPDX-FileCopyrightText: Copyright 2021-2023, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Helper methods for pre- and post-processing of images
"""

import urllib.request
import os
import sys

import numpy as np

import cv2
import tensorflow as tf

from . import common

# Install user agent to comply with Wikipedia policy
opener = urllib.request.build_opener()
opener.addheaders = [
    (
        "User-agent",
        "Tool-Solutions/1.0 (https://github.com/ARM-software/Tool-Solutions)",
    )
]
urllib.request.install_opener(opener)


def _download_image(image_loc):
    """
    Download image to file
    :param image_loc: URL or path for the image
    :returns: File name of downloaded image
    """
    image_file = image_loc

    if image_loc.startswith("http"):
        image_file = image_loc.split("/")[-1]  # filename

        if not os.path.isfile(image_file):
            # Download the image if required
            urllib.request.urlretrieve(
                image_loc,
                image_file,
            )

    if not os.path.isfile(image_file):
        sys.exit("Image %s does not exist!" % image_file)

    return image_file


def preprocess_image(image_url, model_descriptor):
    """
    Preprocess image for different models
    :param image_url: URL from where to download image
    :param model_descriptor: Parsed yaml file describing model
    :returns: Preprocessed image for the given model
    """
    model_name = model_descriptor["model"]["name"]

    # Getting the appropriate preprocess function for the model
    preprocess_func = {
        common.RESNET50_NAME: _preprocess_image_for_classification,
        common.SSD_RESNET34_NAME: _preprocess_image_for_ssd_resnet34_detection,
    }[model_name]

    return preprocess_func(image_url, model_descriptor)


def _preprocess_image_for_classification(image_url, model_descriptor):
    """
    Preprocess image for classification to do for inference on models
    that were trained using ImageNet
    :param image_url: Path to the image
    :param model_descriptor: Parsed yaml file describing model
    :returns: Preprocessed image for image classification
    """
    image_file = _download_image(image_url)

    input_shape = model_descriptor["arguments"]["input_shape"]
    transpose = False
    if "transpose" in model_descriptor["arguments"]:
        transpose = True
    if len(input_shape) == 4 and not transpose:
        dimensions = input_shape[1:3]
    elif len(input_shape) == 4 and transpose:
        dimensions = input_shape[2:4]
    elif len(input_shape) == 3 and not transpose:
        dimensions = input_shape[0:2]
    elif len(input_shape) == 3 and transpose:
        dimensions = input_shape[1:3]

    orig_image = tf.keras.preprocessing.image.load_img(
        image_file, target_size=dimensions
    )
    numpy_image = tf.keras.preprocessing.image.img_to_array(orig_image)
    if transpose:
        # if transpose is set to true then expected input is CHW, instead of HWC
        numpy_image = numpy_image.transpose([2, 0, 1])

    if len(input_shape) == 4:
        numpy_image = np.expand_dims(numpy_image, axis=0)
    processed_image = tf.keras.applications.imagenet_utils.preprocess_input(
        numpy_image, mode="caffe"
    )

    return processed_image


def _preprocess_image_for_ssd_resnet34_detection(image_url, model_descriptor):
    """
    Preprocess image for object detection for SSD-ResNet34 model
    :param image_url: URL from where to download image
    :param model_descriptor: Parsed yaml file describing model
    :returns: Preprocess image for object detection
    """
    image_file = _download_image(image_url)

    orig_image = tf.keras.preprocessing.image.load_img(image_file)
    numpy_image = tf.keras.preprocessing.image.img_to_array(orig_image)
    # scale image to expected dimensions for the input of model
    dimensions = model_descriptor["image_preprocess"]["input_shape"]
    numpy_image = cv2.resize(
        numpy_image, tuple(dimensions), interpolation=cv2.INTER_LINEAR
    )

    # normalise image
    mean = np.array(model_descriptor["image_preprocess"]["mean"], dtype=np.float32)
    std = np.array(model_descriptor["image_preprocess"]["std"], dtype=np.float32)
    numpy_image = numpy_image / 255.0 - mean
    numpy_image = numpy_image / std

    if model_descriptor["image_preprocess"]["transpose"]:
        # if transpose is set to true then expected input is CHW, instead of HWC
        numpy_image = numpy_image.transpose([2, 0, 1])

    # create batch of 1
    image_batch = np.expand_dims(numpy_image, axis=0)

    return image_batch, image_file


def postprocess_image(model_descriptor, image_file, predictions, labels):
    """
    Draw bounding boxes around objects that were detected for different models
    :param model_descriptor: Parsed yaml file describing model
    :param image_file: Path to image
    :param predictions: Detected objects
    :param labels: Object labels
    """
    model_name = model_descriptor["model"]["name"]

    # Getting the appropriate postprocess function for the model
    postprocess_func = {
        common.SSD_RESNET34_NAME: _postprocess_image_for_coco_detection,
    }[model_name]

    return postprocess_func(model_descriptor, image_file, predictions, labels)


def _postprocess_image_for_coco_detection(
    model_descriptor, image_file, predictions, labels
):
    """
    Draw bounding boxes around objects that were detected
    :param model_descriptor: Parsed yaml file describing model
    :param image_file: Path to image
    :param predictions: Detected objects
    :param labels: Object labels
    """
    threshold = model_descriptor["model"]["threshold"]

    image = cv2.imread(image_file)
    height, width, _ = image.shape

    boxes, _, scores = predictions
    for idx, score in enumerate(scores[0]):
        if score < threshold:
            break

        ymin, xmin, ymax, xmax = boxes[0][idx]

        left = int(xmin * width)
        right = int(xmax * width)
        top = int(ymin * height)
        bottom = int(ymax * height)

        # we are putting green rectangle around the object
        cv2.rectangle(image, (left, top), (right, bottom), (0, 255, 0), 1)
        # write label with green background
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 1
        font_thickness = 2
        label_size, _ = cv2.getTextSize(labels[idx], font, font_scale, font_thickness)
        label_width, label_height = label_size
        cv2.rectangle(
            image,
            (left, top),
            (left + label_width, top - label_height),
            (0, 255, 0),
            -1,
        )
        cv2.putText(
            image,
            labels[idx],
            (left, top),
            font,
            font_scale,
            (0, 0, 0),
            font_thickness,
        )

    basename, ext = os.path.splitext(image_file)
    image_file_boxes = basename + "_boxes" + ext
    cv2.imwrite(image_file_boxes, image)

    print("Image with bounding boxes written to %s" % image_file_boxes)
