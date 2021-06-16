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
This example demonstrates how to load an image classification model and run
inference on a single image
"""

import sys

from utils import vision_parser
from utils import image
from utils import label

from executor import model


def main():
    """
    Main function
    """

    args = vision_parser.parse_arguments()

    # Load model used for inference
    classification_model = model.Model()
    if not classification_model.load(args["model"]):
        sys.exit("Failed to set up the model")

    # Preprocess the image
    image_to_classify = image.preprocess_image_for_classification(
        args["image"]
    )

    # Predict
    predictions = classification_model.run(image_to_classify, args["runs"])

    # Label predictions
    label.classify_predictions(args["model"], predictions)


if __name__ == "__main__":
    main()
