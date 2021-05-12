# Examples

This folder contains number of scripts that demonstrate how to run inference with various machine learning models.

## Image classification

The script [classify_image.py](classify_image.py) demonstrates how to run inference using ResNet-50 model trained on ImageNet data set.

To run inference on an image call:

```
python3 classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
```

Where flag `-m` is configuration file (see below) that describes model and `-i` is URL of the image that you want to classify.

File [resnet_v1-50.yml](resnet_v1-50.yml) describes in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about model. A `model` record contains:

- `name`: Name to use to save the model after downloading it
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model
In addition to the model, pass the `arguments` record required to build the graph for inference of the trained model:
- `input_shape`: Input shape used for inference in the format NHWC
- `input`: Name of the input tensor in the trained model
- `output`: Name of the output tensor in the trained model

To optimize the model for inference set the flag `-o`. The optimization takes couple of minutes to complete.

## Object detection

The script [detect_objects.py](detect_object.py) demonstrates how to run inference using SSD-ResNet-34 model trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference on example image call:

```
python3 detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where the flag `-m` is used to specify the configuration file (see below) that describes model and `-i` is the URL of the image on which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

File [ssd_resnet34.yml](ssd_resnet34.yml) describes in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about model. A `model` record contains:
- `name`: Name of the model used for inference
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model
- `threshold`: If confidence is below this threshold then object will not be reported as detected
In addition to the model, pass the `arguments` record required to build the graph for inference of the trained model:
- `input`: Name of the input tensor in the trained model
- `output`: Name of the output tensor in the trained model
Finally, there is additional information in `image_preprocess` that is used to preprocess image before doing inference:
- `input_shape`: Height and width of the image
- `transpose`: Set to true if expected image input is channel first
- `mean`: Mean values per channel for normalizing image
- `std`: Standard deviation values per channel for normalizing image

To optimize the model for inference set the flag `-o`. The optimization takes couple of minutes to complete.

## MLCommons :tm: benchmark

To run ResNet50 on ImageNet min-validation dataset for image classification, download the dataset and model using the scripts provided in the `$HOME/examples/MLCommons` directory of the final image.

  * `download-dataset.sh` downloads the ImageNet min-validation dataset using CK to `${HOME}/CK-TOOLS/`
  * `download-models.sh` downloads the resnet50 model.

Set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min
export MODEL_DIR=$(pwd)
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark.

``` ./run_local.sh tf resnet50 cpu ```

_Note: you can use `DNNL_VERBOSE=1` to verify the build uses oneDNN when running the benchmarks._

### Running with (optional) `run_cnn.py` wrapper script provided

The script `run_cnn.py` is located in `$HOME/examples/MLCommons/inference/vision/classification_and_detection`. To find out the usages and default settings:

```./run_cnn.py --help ```

To run benchmarks in the multiprogrammed mode:

```DATA_DIR=$abc MODEL_DIR=$def OMP_NUM_THREADS=$ghi ./run_cnn.py --processes $(nproc) --threads 1 ```

To run benchmarks in the multithreaded mode:

```DATA_DIR=$abc MODEL_DIR=$def OMP_NUM_THREADS=$ghi ./run_cnn.py --processes 1 --threads $(nproc) ```

To run benchmarks in the hybrid mode:

For example, run 8 processes each of which has 8 threads on a 64-core machine

```DATA_DIR=$abc MODEL_DIR=$def OMP_NUM_THREADS=$ghi ./run_cnn.py --processes 8 --threads 8 ```

Please refer to [ML Commons, Inference](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection) for further details.
