<!--
SPDX-FileCopyrightText: Copyright 2021-2023, 2025, 2026 Arm Limited and affiliates.

SPDX-License-Identifier: Apache-2.0
-->

# Python Examples

This folder contains number of scripts that demonstrate how to run inference with various machine learning models.

## Vision

### Image Classification

The script [classify_image.py](classify_image.py) demonstrates how to run inference using the ResNet-50 model trained on the ImageNet data set.

To run inference on an image call:

```
python classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
```

Where the `-m` flag sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image to classify.

The file [resnet_v1-50.yml](resnet_v1-50.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html), information about the model:

- `name`: Name to use to save the model after downloading it
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model.
In addition to the model, pass the `arguments` record required to build the graph for inference of the trained model:
- `input_shape`: Input shape used for inference in the format NHWC
- `input`: Name of the input tensor in the trained model
- `output`: Name of the output tensor in the trained model.

By default, the model will be optimized for inference before the classification task is performed. This optimization takes a couple of minutes to complete. Set the flag `-u` to disable this optimization.

### Object Detection

The script [detect_objects.py](detect_objects.py) demonstrates how to run inference using SSD-ResNet-34 model trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference on example image call:

```bash
# wokeignore:rule=master
python detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where `-m` sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image in which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

The file [ssd_resnet34.yml](ssd_resnet34.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the model:
- `name`: Name of the model used for inference
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model
- `threshold`: If confidence is below this threshold, then object will not be reported as detected
In addition to the model, pass the `arguments` record required to build the graph for inference of the trained model:
- `input`: Name of the input tensor in the trained model
- `output`: Name of the output tensor in the trained model
Finally, there is additional information in `image_preprocess` that is used to preprocess image before doing inference:
- `input_shape`: Height and width of the image
- `transpose`: Set to true if expected image input is channel first
- `mean`: Mean values per channel for normalizing image
- `std`: Standard deviation values per channel for normalizing image

By default, the model will be optimized for inference before the object detection is performed. This optimization takes a couple of minutes to complete. Set the flag `-u` to disable this optimization.
