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

### Statically Quantized Convolution

The script [static_quantize_conv.py](static_quantize_conv.py) demostrates Pytorch static quantization using the Post-Training Quantisation (PTQ) method with FX Graph Mode that automatically quantizes modules.

To run inference on an image call:

```
python static_quantize_conv.py
```

This example outputs the execution time of an F32 single convolution model and the output of the same model, but then statically quantized. It also prints the Mean Square Error (MSE) between the results of the F32 model and the int8 model. With this example, we demonstrate that although the difference in performance can be pretty big, the difference between the L2 error result can be relatively small.

### Object detection

The script [detect_objects.py](detect_object.py) demonstrates how to run inference using different models. Currently supported models are the SSD-ResNet-34 and RetinaNet (also known as ResNext50).

The SSD-ResNet-34 model is trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

RetinaNet is trained on the OpenImages dataset. It is a one-stage object detection model that is based on the ResNet-50 backbone network.

To run inference with SSD-ResNet-34 on example image call:

```
python detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

And similarly for RetinaNet:

```
python detect_objects.py -m ./retinanet.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where `-m` sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image in which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

The files [ssd_resnet34.yml](ssd_resnet34.yml) and [retinanet.yml](retinanet.yml) provide, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the models:
- `name`: Name of the model used for inference
- `script`: Script to download the Python model class and put it in the `PYTHONPATH`
- `class`: Name of the Python model class to import
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

The script `answer_questions.py` demonstrates how to build a simple question answering system using the pre-trained DistilBERT model (default) or BERT LARGE model (using the `--bert-large` flag). The script can answer questions from the [Stanford Question Answering Dataset (SQuAD)](https://rajpurkar.github.io/SQuAD-explorer/), or can be provided with a user defined context and question.

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

We can also quantize some of the layers of the models using the `--quantize` flag, which can make the model run several times faster
```
python answer_questions.py --quantize
```
See the section on [dynamic quantization](#dynamic-quantization) for more information.

To remove the setup from the measured inference time, you can use the `--warmup` flag.
This will run the model twice, and report the time of the second run.


### Torchtext Article Reading

The script 'torchtext_example.py' shows the functionality of the 'torchtext' Pytorch library. The example reads an article and determines its genre out of 4 options: world, sports, business, or science & technology.

To run the script:

```
python torchtext_example.py axion.txt
```

The example reads an excerpt from an article from https://news.northeastern.edu/2021/08/09/holy-grail-discovery-in-solid-state-physics-could-usher-in-new-technologies/, and correctly determines that it is a science & technology article.

This script was built following the approach detailed in https://pytorch.org/tutorials/beginner/text_sentiment_ngrams_tutorial.html

## Dynamic quantization

Quantization reduces the precision of the inputs to your operators to speed up computation.
Typically this takes us from the default float data type (32 bits) to an integer (8 bits).
Currently dynamic quantization is supported (inputs are quantized at run time), and can be easily applied to a model using
```python
model = torch.ao.quantization.quantize_dynamic(
    model,
    {torch.nn.Linear},
    dtype=torch.qint8)
```
Note that currently only the linear layer can be quantized, although for many models this layer contributes the largest runtime, so the overall speedup can still be large.

`quantized_linear.py ` is a very simple example of the dynamic quantization of a single linear layer.
It takes the 3 dimensions of the linear layer, and returns the runtime of the unquantized and quantized models along with the ratio.
```
python quantized_linear.py 384 1024 768
```
By running this you can see how the ratio unquantized/quantized time varies with number of threads and the size of the layer.
| Threads\M=K=N | 256 | 512 | 1024 |
|---------------|-----|-----|------|
| 4             | 1.4 | 3.9 | 5.5  |
| 8             | 1.2 | 3.0 | 5.1  |
| 16            | 1.1 | 2.8 | 4.8  |

The speedup is more pronounced for large linear layers and lower numbers of threads.

To see the effect on a full model, you can run the `answer_questions.py` script from the earlier NLP example with the `--quantize` flag.
```
python answer_questions.py -id 56de16ca4396321400ee25c7 --quantize --bert-large
```
Again, the effect is most pronounced for fewer threads and larger layers/models (hence `--bert-large`), in such cases you can see up to ~3x speedup.

| Threads | BERT Large speedup |
|---------|--------------------|
| 4       | 2.9                |
| 8       | 2.4                |
| 16      | 1.7                |
Note that in the above data we used the `--warmup` flag to run the model once before timing.

## MLCommons :tm: benchmarks

### Vision

To run the image classification and object detection benchmarks, first download the datasets and models using the scripts provided in the `$HOME/examples/MLCommons` directory of the final image.

  * `download-dataset.sh` downloads the ImageNet min-validation dataset using CK to `${HOME}/CK-TOOLS/` and additionally downloads the openimages dataset. Select option 1: for the val-min ImageNet dataset.
  * `download-model.sh` downloads the ResNet50 and RetinaNet models.

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

To run RetinaNet on the openimages validation dataset for image classification, set `DATA_DIR` to the location of the downloaded dataset and `MODEL_DIR` to the location of the downloaded model.

```
export DATA_DIR=${HOME}/CK-TOOLS/openimages-val
export MODEL_DIR=${HOME}/examples/MLCommons/inference/vision/classification_and_detection
```

From `$HOME/examples/MLCommons/inference/vision/classification_and_detection` use the `run_local.sh` to start the benchmark.

```
./run_local.sh pytorch retinanet cpu
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
