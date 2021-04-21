# Examples

This folder contains number of scripts that demonstrate how to run inference with various machine learning models.

## Image classification

The script [classify_image.py](classify_image.py) demonstrates how to run inference using ResNet-50 model trained on ImageNet data set.

To run inference on an image call:

```
python3 classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
```

Where flag `-m` is configuration file (see blow) that describes model and `-i` is URL of the image that you want to classify.

File [resnet_v1-50.yml](resnet_v1-50.yml) describes in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about model. A `model` record contains:
- `name`: Name to use to save the model after downloading it
- `class`: The name of class that implements model architecture in torchvision.models
- `source`: URL from where to download saved checkpoint
- `labels`: URL from where to download labels for the model

## MLCommons benchmark

Please refer to (https://github.com/mlperf/inference/tree/master/vision/classification_and_detection) for instructions to download datasets and models.

To run ResNet34-ssd with the COCO 2017 validation dataset for object detection, download the dataset and model using the scripts provided in the `$HOME/examples/MLCommons` directory of the final image.
  * `download-dataset.sh` downloads the Coco 2017 dataset using CK to `${HOME}/CK-TOOLS/`
  * `download-models.sh` downloads the resnet34-ssd model.

Set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

  ``` > export DATA_DIR=${HOME}/CK-TOOLS/dataset-coco-2017-val ```

  ``` > export MODEL_DIR=$(pwd) ```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark.
  ``` > ./run_local.sh pytorch ssd-resnet34 cpu ```

_Note: use DNNL_VERBOSE=1 to verify the build uses oneDNN when running the benchmarks._

Please refer to (https://github.com/mlperf/inference/tree/master/vision/classification_and_detection) for further details.
