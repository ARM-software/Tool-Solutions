# *******************************************************************************
# Copyright 2021-2023, 2025 Arm Limited and affiliates.
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


def download_image(image_loc):
    """
    Download image to file
    :param image_loc: URL or path for the image
    :returns: File name of downloaded image
    """
    image_file = image_loc

    if image_loc.startswith("http"):
        image_file = image_loc.split("/")[-1]  # filename

        if not os.path.isfile(image_file):
            # download the image if required
            opener = urllib.request.build_opener()
            opener.addheaders = [
                (
                    "User-agent",
                    "Tool-Solutions/1.0 (https://github.com/ARM-software/Tool-Solutions)",
                )
            ]
            urllib.request.install_opener(opener)
            urllib.request.urlretrieve(image_loc, image_file)

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

    # getting the appropriate preprocess function for the model
    preprocess_func = {
        common.RESNET50_NAME: _preprocess_image_for_classification,
        common.RETINANET_NAME: _preprocess_image_for_detection,
        common.SSD_RESNET34_NAME: _preprocess_image_for_detection,
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
    image_file = download_image(image_url)

    input_image = Image.open(image_file)
    preprocess = transforms.Compose(
        [
            transforms.Resize(256),
            transforms.CenterCrop(224),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ]
    )
    input_tensor = preprocess(input_image)
    processed_image = input_tensor.unsqueeze(0)

    return processed_image


def _preprocess_image_for_detection(image_url, model_descriptor):
    """
    Preprocess image for object detection
    :param image_url: URL from where to download image
    :param model_descriptor: Parsed yaml file describing model
    :returns: Preprocess image for object detection
    """
    image_file = download_image(image_url)

    input_image = cv2.imread(image_file)

    dimensions = model_descriptor["image_preprocess"]["input_shape"][2:4]
    numpy_image = cv2.resize(
        input_image, tuple(dimensions), interpolation=cv2.INTER_LINEAR
    )

    # normalise image
    numpy_image = numpy_image / 255.0
    if model_descriptor["model"]["name"] == common.SSD_RESNET34_NAME:
        # ssd_resnet34 needs to normalised around 0
        mean = np.array(model_descriptor["image_preprocess"]["mean"], dtype=np.float32)
        std = np.array(model_descriptor["image_preprocess"]["std"], dtype=np.float32)
        numpy_image = (numpy_image - mean) / std

    # the expected input is CHW, instead of HWC
    numpy_image = numpy_image.transpose([2, 0, 1])

    # create batch of 1
    image_batch = np.expand_dims(numpy_image, axis=0)

    return torch.tensor(image_batch).float().to("cpu"), image_file


def postprocess_image(model_descriptor, image_file, predictions, labels):
    """
    Draw bounding boxes around objects that were detected for different models
    :param model_descriptor: Parsed yaml file describing model
    :param image_file: Path to image
    :param predictions: Detected objects
    :param labels: Object labels
    """
    model_name = model_descriptor["model"]["name"]

    # getting the appropriate postprocess function for the model
    postprocess_func = {
        common.RETINANET_NAME: _postprocess_image_for_openimages_detection,
        common.SSD_RESNET34_NAME: _postprocess_image_for_coco_detection,
    }[model_name]

    return postprocess_func(model_descriptor, image_file, predictions, labels)


def _draw_box(image, label, left, right, top, bottom):
    """
    Draws a box and label of a detected object on a given image
    :param image: OpenCV image to draw the box on
    :param label: String to draw next to the box
    :param left: Left box coordinate
    :param right: Right box coordinate
    :param top: Top box coordinate
    :param bottom: Bottom box coordinate
    """
    # we are putting green rectangle around the object
    cv2.rectangle(image, (left, top), (right, bottom), (0, 255, 0), 1)
    # write label with green background
    font = cv2.FONT_HERSHEY_SIMPLEX
    font_scale = 1
    font_thickness = 2
    label_size, _ = cv2.getTextSize(label, font, font_scale, font_thickness)
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
        label,
        (left, top),
        font,
        font_scale,
        (0, 0, 0),
        font_thickness,
    )


def _write_boxes_file(image_file, image):
    """
    Writes the output image file with boxes drawn on it
    :param image_file: Name of the given image file
    :param image: OpenCV image with boxes drawn on
    """
    basename, ext = os.path.splitext(image_file)
    image_file_boxes = basename + "_boxes" + ext
    cv2.imwrite(image_file_boxes, image)

    print("Image with bounding boxes written to %s" % image_file_boxes)


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
    boxes = np.flip(boxes[0].numpy(), 0)

    for idx, score in enumerate(np.flip(scores[0].numpy(), 0)):
        if score < threshold:
            break

        xmin, ymin, xmax, ymax = boxes[idx]

        left = int(xmin * width)
        right = int(xmax * width)
        top = int(ymin * height)
        bottom = int(ymax * height)

        _draw_box(image, labels[idx], left, right, top, bottom)

    _write_boxes_file(image_file, image)


def _postprocess_image_for_openimages_detection(
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

    # unwrapping the single value predictions array
    [results] = predictions
    boxes = results["boxes"].cpu()
    scores = results["scores"].cpu()

    label_idx = 0
    for box, score in zip(boxes, scores):
        if score < threshold:
            break

        # resizing the box values from the 800x800 image to the original
        # resolution.
        resize = lambda x, orig: int((x / 800) * orig)
        left = resize(box[0], width)
        top = resize(box[1], height)
        right = resize(box[2], width)
        bottom = resize(box[3], height)

        _draw_box(image, labels[label_idx], left, right, top, bottom)

        label_idx += 1

    _write_boxes_file(image_file, image)
