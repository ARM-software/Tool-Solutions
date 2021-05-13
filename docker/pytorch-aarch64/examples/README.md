# Examples

This folder contains number of scripts that demonstrate how to run inference with various machine learning models.

## Image classification

The script [classify_image.py](classify_image.py) demonstrates how to run inference using ResNet-50 model trained on ImageNet data set.

To run inference on an image call:

```
python3 classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
```

Where flag `-m` is configuration file (see blow) that describes model and `-i` is URL of the image that you want to classify.

File [resnet_v1-50.yml](resnet_v1-50.yml) describes in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the model. A `model` record contains:

- `name`: Name to use to save the model after downloading it
- `class`: The name of class that implements model architecture in torchvision.models
- `source`: URL from where to download saved checkpoint
- `labels`: URL from where to download labels for the model

## Object detection

The script [detect_objects.py](detect_object.py) demonstrates how to run inference using SSD-ResNet-34 model trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference on example image call:

```
python3 detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where flag `-m` is configuration file (see below) that describes the model, and `-i` is URL of the image in which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

File [ssd_resnet34.yml](ssd_resnet34.yml) describes in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the model. A `model` record contains:
- `name`: Name of the model used for inference
- `script`: Script to download the Python model class and put it in the `PYTHONPATH`
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model
- `threshold`: If confidence is below this threshold then object will not be reported as detected
There is also additional information in `image_preprocess` that is used to preprocess image before doing inference:
- `input_shape`: Input shape used for inference in format NCHW
- `mean`: Mean values per channel for normalizing image
- `std`: Standard deviation values per channel for normalizing image

_Note: in PyTorch, in order to load the model from saved checkpoint, it is also necessary to have the implementation of that model in Python. In the example configuration used here, the implementation of the model (`SSD_R34`) is defined [here](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection/python/models)._

## MLCommons :tm: benchmark

To run ResNet34-ssd with the COCO 2017 validation dataset for object detection, download the dataset and model using the scripts provided in the `$HOME/examples/MLCommons` directory of the final image.

  * `download-dataset.sh` downloads the Coco 2017 dataset using CK to `${HOME}/CK-TOOLS/`
  * `download-models.sh` downloads the resnet34-ssd model.

Set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/dataset-coco-2017-val
export MODEL_DIR=$(pwd)
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark:

```./run_local.sh pytorch ssd-resnet34 cpu ```

_Note: you can use `DNNL_VERBOSE=1` to verify the build uses oneDNN when running the benchmarks._

Please refer to [ML Commons, Inference](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection) for further details.
