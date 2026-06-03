# SPDX-FileCopyrightText: Copyright 2021, 2023, 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
This example demonstrates how to load an image classification model and run
inference on a single image
"""

import sys

from utils import vision_parser
from utils import image
from utils import label
from utils import common

from executor import model


def main():
    """
    Main function
    """

    args = vision_parser.parse_arguments()

    # Parsing the model descriptor
    model_descriptor = common.parse_model_file(args["model"])

    # Load model used for inference, 'threads' stands for the intra-node parallelism
    # and 'inter_threads' stands for inter-node parallelism
    classification_model = model.Model(
        args["unoptimized"], args["intra_threads"], args["inter_threads"]
    )
    if not classification_model.load(model_descriptor):
        sys.exit("Failed to set up the model")

    # Preprocess the image
    image_to_classify = image.preprocess_image(
        args["image"], model_descriptor
    )

    # Predict
    predictions = classification_model.run(image_to_classify, args["runs"])

    # Label predictions
    label.classify_predictions(model_descriptor, predictions)


if __name__ == "__main__":
    main()
