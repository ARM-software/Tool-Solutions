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
Helper methods for pre- and post-processing of images
"""

import urllib.request
import os
import sys

import numpy as np

from PIL import Image

import torch
from torchvision import transforms

import cv2

from . import common


def _download_image(image_url):
    """
    Download image to file
    :param image_url: URL from where to download image
    :returns: File name of downloaded image
    """
    image_file = image_url.split("/")[-1]  # last part of URL
    # Download the image
    urllib.request.urlretrieve(image_url, image_file)

    if not os.path.isfile(image_file):
        sys.exit("Image %s does not exists!" % image_file)

    return image_file


def preprocess_image_for_classification(image_url):
    """
    Preprocess image for classification to do for inference on models
    that were trained using ImageNet
    :param image_url: Path to the image
    :param model_file: File describing model to build
    :returns: Preprocessed image for image classification
    """
    image_file = _download_image(image_url)

    input_image = Image.open(image_file)
    preprocess = transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(
                mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
            ),
        ]
    )
    input_tensor = preprocess(input_image)
    processed_image = input_tensor.unsqueeze(0)

    return processed_image


def preprocess_image_for_detection(image_url, model_file):
    """
    Preprocess image for object detection for SSD-ResNet34 model
    :param image_url: URL from where to download image
    :param model_file: File describing model
    :returns: Preprocess image for object detection
    """

    image_file = _download_image(image_url)
    model_descriptor = common.parse_model_file(model_file)

    input_image = cv2.imread(image_file)

    dimensions = model_descriptor["image_preprocess"][0]["input_shape"][2:4]
    numpy_image = cv2.resize(
        input_image, tuple(dimensions), interpolation=cv2.INTER_LINEAR
    )

    # normalise image
    mean = np.array(
        model_descriptor["image_preprocess"][0]["mean"], dtype=np.float32
    )
    std = np.array(
        model_descriptor["image_preprocess"][0]["std"], dtype=np.float32
    )
    numpy_image = numpy_image / 255.0 - mean
    numpy_image = numpy_image / std

    # the expected input is CHW, instead of HWC
    numpy_image = numpy_image.transpose([2, 0, 1])

    # create batch of 1
    image_batch = np.expand_dims(numpy_image, axis=0)

    return torch.tensor(image_batch).float().to("cpu"), image_file


def postprocess_image_for_detection(
    model_file, image_file, predictions, labels
):
    """
    Draw bounding boxes around objects that were detected
    :param model_file: File describing model
    :param image_file: Path to image
    :param predictions: Detected objects
    :param labels: Object labels
    :returns: Post processed image with boxes around detected objects
    """

    model_descriptor = common.parse_model_file(model_file)
    threshold = model_descriptor["model"][0]["threshold"]

    image = cv2.imread(image_file)
    height, width, _ = image.shape

    boxes, _, scores = predictions
    boxes = np.flip(boxes[0].numpy(), 0)

    for idx, score in enumerate(np.flip(scores[0].numpy(), 0)):
        if score < threshold:
            break

        # ymin, xmin, ymax, xmax = boxes[idx]
        xmin, ymin, xmax, ymax = boxes[idx]

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
        label_size, _ = cv2.getTextSize(
            labels[idx], font, font_scale, font_thickness
        )
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
