# Python Examples

The `py-api` folder contains number of scripts that demonstrate how to run inference with various machine learning models.

## Vision

### Image Classification

The script [classify_image.py](py-api/classify_image.py) demonstrates how to run inference using the ResNet-50 model trained on the ImageNet data set.

To run inference on an image call:

```
python classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
```

Where the `-m` flag sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image to classify.

The file [resnet_v1-50.yml](py-api/resnet_v1-50.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html), information about the model:

- `name`: Name to use to save the model after downloading it
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model.
In addition to the model, pass the `arguments` record required to build the graph for inference of the trained model:
- `input_shape`: Input shape used for inference in the format NHWC
- `input`: Name of the input tensor in the trained model
- `output`: Name of the output tensor in the trained model.

By default, the model will be optimized for inference before the classification task is performed. This optimization takes a couple of minutes to complete. Set the flag `-u` to disable this optimization.

### Object Detection

The script [detect_objects.py](py-api/detect_object.py) demonstrates how to run inference using SSD-ResNet-34 model trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference on example image call:

```
python detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where `-m` sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image in which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

The file [ssd_resnet34.yml](py-api/ssd_resnet34.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the model:
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

## Natural Language Processing (NLP)

### Question answering

The script `answer_questions.py` demonstrates how to build a simple question answering system using the pre-trained DistilBERT model. The script can answer questions from the [Stanford Question Answering Dataset (SQuAD)](https://rajpurkar.github.io/SQuAD-explorer/), or can be provided with a user defined context and question.

To run the script on a random entry from the SQuAD dev-v2.0 dataset call:

```
python answer_questions.py
```

To pick a random question on a specific topic in the SQuAD dataset, use `-s` flag:

```
python answer_questions.py -s "Normans"
```

The routine `print_squad_questions` can be used to give a list of available subjects, see below.


To choose a specific entry from the SQuAD dataset use the `-id` flag to supply the ID of the question, for example:

```
python answer_questions.py -id 56de16ca4396321400ee25c7
```

will attempt to answer "When was the battle of Hastings?" based on one of the entries on the [Normans from the SQuAD dataset](https://rajpurkar.github.io/SQuAD-explorer/explore/v2.0/dev/Normans.html) (originally derived from Wikipedia). The expected answer is "In 1066".

In the `utils` folder, [nlp.py](py-api/utils/nlp.py) provides a some simple tools for obtaining and browsing the dataset. This also displays the ID of each question which can be supplied to `answer_questions.py`. Calling `print_squad_questions` will display a list of the various subjects contained in the dataset and supplying a `subject` argument will print the details of all the questions on that subject, for example, from within your Python environment:

```
from utils import nlp
nlp.print_squad_questions(subject="Normans")
```

will print all the SQuAD entries on Normans - the context, questions, reference answers and IDs.

It is also possible to supply a question, and context, to `answer_questions.py` directly at the command line using the flags `-t` and `-q`, for example:

```
python answer_questions.py -t <context> -q <question>
```

where `<context>` is the text file containing the text on which the `<question>` is based. If no text file is provided, `answer_questions.py` will search through the SQuAD dataset for the question and, if the question can be located, use the context associated with it.


## MLCommons :tm: benchmarks

### Vision

To run the image classification and object detection benchmarks, first download the datasets and models using the scripts provided in the `$HOME/examples/MLCommons` directory of the final image.

  * `download-dataset.sh` downloads the ImageNet min-validation and Coco 2017 datasets using CK to `${HOME}/CK-TOOLS/`. Select option 1: for the val-min ImageNet dataset.
  * `download-model.sh` downloads the ResNet50 and SSD-ResNet34 models. The SSD-ResNet34 model is converted to channels-last (NHWC) format as required by TensorFlow for CPU targets.

The environment variables `DATA_DIR` and `MODEL_DIR` will need to be set to the location of the downloaded dataset and model in each case.

#### Image classification

To run ResNet50 on ImageNet min-validation dataset for image classification, set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min
export MODEL_DIR=${HOME}/examples/MLCommons/inference/vision/classification_and_detection
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark.

```
./run_local.sh tf resnet50 cpu
```

_Note: you can use `ONEDNN_VERBOSE=1` to verify the build uses oneDNN when running the benchmarks._

##### Running with (optional) `run_cnn.py` wrapper script provided

The script `run_cnn.py` is located in `$HOME/examples/MLCommons/inference/vision/classification_and_detection`. To find out the usages and default settings:


```
./run_cnn.py --help
```

To run benchmarks in the multiprogrammed mode:

```
OMP_NUM_THREADS=$(nproc) ./run_cnn.py --processes $(nproc) --threads 1
```

To run benchmarks in the multithreaded mode:

```
OMP_NUM_THREADS=$(nproc) ./run_cnn.py --processes 1 --threads $(nproc)
```

To run benchmarks in the hybrid mode:

For example, run 8 processes each of which has 8 threads on a 64-core machine

```
OMP_NUM_THREADS=64 ./run_cnn.py --processes 8 --threads 8
```

Please refer to [MLCommons, Inference](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection) for further details.

#### Object detection

To run ResNet34-ssd with the COCO 2017 validation dataset for object detection, set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/dataset-coco-2017-val
export MODEL_DIR=${HOME}/examples/MLCommons/inference/vision/classification_and_detection
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark, `--count` can be used to control the number of inferences:

```
./run_local.sh tf ssd-resnet34 cpu --count 10 --data-format NHWC
```

_Note: you can use `ONEDNN_VERBOSE=1` to verify the build uses oneDNN when running the benchmarks._

Please refer to [MLCommons, Inference](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection) for further details.


### BERT

The BERT NLP benchmarks are not built by default, due to the size of the datasets downloaded during the build. From within the container, the benchmarks can be built as follows:

```
cd $HOME/examples/MLCommons/inference/language/bert
make setup
```

To run BERT for TensorFlow, use `run.py` located in `$HOME/examples/MLCommons/inference/languages/bert` as follows:

```
python run.py --backend=tf --scenario SingleStream
```

For details of additional options use `-h`:

```
python run.py -h
```

In order to reduce the runtime, for the purposes of confirming that it runs as expected, in `$HOME/examples/MLCommons/inference/language/bert/user.conf` add:

```
*.*.min_query_count = 1
*.*.performance_sample_count_override = 1
```
TensorFlow threading can be set using environment variables TF_INTRA_OP_PARALLELISM_THREADS and TF_INTER_OP_PARALLELISM_THREADS.

# C++ Examples

To build the C++ examples, simply run `make` from inside the `cpp-api` directory.
When executing the resulting binaries, the following flags are required:
* `-m` flag sets the configuration file that describes model in YAML format (see Python section above)
* `-i` sets the input image

_Note:_ unlike in the python examples, the model/labels/image paths are local relative paths. The examples expect these files to be downloaded before execution. By default, the makefile build will download the required models, labels and input images.

To run the examples:
* `./classify_image -m resnet50.yml -i images/guineapig.jpeg`
  * Resnet50 in `SavedModel` format (single image inference)
  * _input_: images/guineapig.jpeg | _labels:_ labels/imagenet-labels.txt
  * _output:_ Top 3 predictions with confidence and labels
* `./inception_inference -m inception.yml -i images/guineapig.jpeg`
  * Inception model in `FrozenModel.pb` format (single image inference)
  * _input:_ images/guineapig.jpes | _labels_: labels/imagenet_slim_labels.txt
  * _output:_ Top 3 predictions with confidence and labels
* `./detect_objects -m ssd_resnet50.yml -i images/cows.jpeg`
  * SSD-Resnet50 in `SavedModel` format (single image inference)
  * uses OpenCV to load _and_ post-process the image.
  * post-processing creates a new image `output_image.jpeg` where the detected objects are framed in red rectangles.
  * _input:_ images/cows.jpeg | _labels:_ labels/coco-labels.txt
  *  _output:_ All detected objects with confidence above 70% threshold


