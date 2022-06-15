# Examples

This folder contains number of scripts that demonstrate how to run inference with various machine learning models.

## Vision

### Image classification

The script [classify_image.py](classify_image.py) demonstrates how to run inference using the ResNet-50 model trained on the ImageNet data set.

To run inference on an image call:

```
python classify_image.py -m ./resnet_v1-50.yml -i https://upload.wikimedia.org/wikipedia/commons/3/32/Weimaraner_wb.jpg
```

Where the `-m` flag sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image to classify.

The file [resnet_v1-50.yml](resnet_v1-50.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html), information about the model:

- `name`: Name to use to save the model after downloading it
- `class`: The name of class that implements model architecture in torchvision.models
- `source`: URL from where to download saved checkpoint
- `labels`: URL from where to download labels for the model.

### Object detection

The script [detect_objects.py](detect_object.py) demonstrates how to run inference using SSD-ResNet-34 model trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference on example image call:

```
python detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where `-m` sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image in which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

The file [ssd_resnet34.yml](ssd_resnet34.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the model:
- `name`: Name of the model used for inference
- `script`: Script to download the Python model class and put it in the `PYTHONPATH`
- `source`: URL from where to download the model
- `labels`: URL from where to download labels for the model
- `threshold`: If confidence is below this threshold, then object will not be reported as detected
There is also additional information in `image_preprocess` that is used to preprocess image before doing inference:
- `input_shape`: Input shape used for inference in format NCHW
- `mean`: Mean values per channel for normalizing image
- `std`: Standard deviation values per channel for normalizing image

_Note: in PyTorch, in order to load the model from saved checkpoint, it is also necessary to have the implementation of that model in Python. In the example configuration used here, the implementation of the model (`SSD_R34`) is defined [here](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection/python/models)._

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

In the `utils` folder, [nlp.py](utils/nlp.py) provides a some simple tools for obtaining and browsing the dataset. This also displays the ID of each question which can be supplied to `answer_questions.py`. Calling `print_squad_questions` will display a list of the various subjects contained in the dataset and supplying a `subject` argument will print the details of all the questions on that subject, for example, from within your Python environment:

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

### Torchtext Article Reading

The script 'torchtext_example.py' shows the functionality of the 'torchtext' Pytorch library. The example reads an article and determines its genre out of 4 options: world, sports, business, or science & technology.

To run the script:

```
python torchtext_example.py axion.txt
```

The example reads an excerpt from an article from https://news.northeastern.edu/2021/08/09/holy-grail-discovery-in-solid-state-physics-could-usher-in-new-technologies/, and correctly determines that it is a science & technology article.

This script was built following the approach detailed in https://pytorch.org/tutorials/beginner/text_sentiment_ngrams_tutorial.html

## MLCommons :tm: benchmarks

### Vision

To run the image classification and object detection benchmarks, first download the datasets and models using the scripts provided in the `$HOME/examples/MLCommons` directory of the final image.

  * `download-dataset.sh` downloads the ImageNet min-validation and Coco 2017 datasets using CK to `${HOME}/CK-TOOLS/`. Select option 1: for the val-min ImageNet dataset.
  * `download-model.sh` downloads the ResNet50 and SSD-ResNet34 models.

The environment variables `DATA_DIR` and `MODEL_DIR` will need to be set to the location of the downloaded dataset and model in each case.

#### Image classification

To run ResNet50 on ImageNet min-validation dataset for image classification, set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/dataset-imagenet-ilsvrc2012-val-min
export MODEL_DIR=${HOME}/examples/MLCommons/inference/vision/classification_and_detection
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark.

```
./run_local.sh pytorch resnet50 cpu
```

#### Object detection

To run ResNet34-ssd with the COCO 2017 validation dataset for object detection, set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/dataset-coco-2017-val
export MODEL_DIR=${HOME}/examples/MLCommons/inference/vision/classification_and_detection
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark:

```
./run_local.sh pytorch ssd-resnet34 cpu
```

_Note: you can use `ONEDNN_VERBOSE=1` to verify the build uses oneDNN when running the benchmarks._

Please refer to [MLCommons, Inference](https://github.com/mlcommons/inference/tree/master/vision/classification_and_detection) for further details.

### BERT

The BERT NLP benchmarks are not built by default, due to the size of the datasets downloaded during the build. From within the container, the benchmarks can be built as follows:

```
cd $HOME/examples/MLCommons/inference/language/bert
make setup
```

To run BERT for PyTorch, use `run.py`, located in `$HOME/examples/MLCommons/inference/languages/bert`, as follows:

```
python run.py --backend=pytorch --scenario SingleStream
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

### Speech Recognition

#### RNNT

The speech recognition RNNT benchmark ([original paper available here](https://arxiv.org/pdf/1811.06621.pdf)) generates character transcriptions from raw audio samples. The data and model parameters are not included in the Docker image by default due to their size (~1GB), but can be downloaded easily using the shell scripts described below.

Two shell scripts for model and data download, and running scenarios are generated for the built image using a patch file. These scripts can be found in `$HOME/examples/MLCommons/inference/speech_recognition/rnnt/` of the built image.

  * `download_dataset_model.sh` downloads the model and test dataset
  * `run.sh` runs the test, by default only the SingleStream scenario latency test

Further information on the scripts can be found in the README available in that directory. `run.sh -h` can be used to get more information on test configuration options.

For testing purposes, the runtime can be reduced by manually reducing the number of samples listed in the JSON file `$HOME/examples/MLCommons/inference/speech_recognition/rnnt/temp_work/local_data/dev-clean-wav.json` after it has been generated by the `download_dataset_model.sh` script.
