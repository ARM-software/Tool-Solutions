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

The script [detect_objects.py](detect_object.py) demonstrates how to run inference using SSD-ResNet-34 model trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference on example image call:

```
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
