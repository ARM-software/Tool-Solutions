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

The script [detect_objects.py](detect_object.py) demonstrates how to run object detection using SSD-ResNet-34.

The SSD-ResNet-34 model is trained from the Common Object in Context (COCO) image dataset. This is a multiscale SSD (Single Shot Detection) model based on the ResNet-34 backbone network that performs object detection.

To run inference with SSD-ResNet-34 on example image call:
```
python detect_objects.py -m ./ssd_resnet34.yml -i https://raw.githubusercontent.com/zhreshold/mxnet-ssd/master/data/demo/street.jpg
```

Where `-m` sets the configuration file (see below) that describes the model, and `-i` sets the URL, or filename, of the image in which you want to detect objects. The output of the script will list what object the model detected and with what confidence. It will also draw bounding boxes around those objects in a new image.

[ssd_resnet34.yml](ssd_resnet34.yml) provides, in [YAML format](https://docs.ansible.com/ansible/latest/reference_appendices/YAMLSyntax.html) information about the model:
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

## General optimization guidelines

### Weight prepacking
Linear layers calling ACL matmuls reorder weights during runtime by default. These reorders can be eliminated by calling `pack_linear_weights` as shown in `pack_linear_weights.py`. This improves the performance of any models calling a linear layer multiple times.

### General flags
There are several flags which typically improve the performance of PyTorch.

`DNNL_DEFAULT_FPMATH_MODE`: setting the environment variable `DNNL_DEFAULT_FPMATH_MODE` to `BF16` or `ANY` will instruct ACL to dispatch fp32 workloads to bfloat16 kernels where hardware support permits. _Note: this may introduce a drop in accuracy._

You can use `tcmalloc` to handle memory allocation in PyTorch, which often leads to better performance
`LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libtcmalloc.so.4`

You can control the number of threads with `OMP_NUM_THREADS`, smaller models may perform better with fewer threads.

### Compiled mode flags

* `TORCHINDUCTOR_CPP_WRAPPER=1`  - Reduces Python overhead within the graph for torch.compile
* `TORCHINDUCTOR_FREEZING=1`     - Freezing will attempt to inline weights as constants in optimization

e.g.
```
LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libtcmalloc.so.4  TORCHINDUCTOR_CPP_WRAPPER=1  TORCHINDUCTOR_FREEZING=1  OMP_NUM_THREADS=16  python <your_model_script>.py
```

### Eager mode flags

* `IDEEP_CACHE_MATMUL_REORDERS=1`   - Caches reordered weight tensors. This increases performance but also increases memory usage. `LRU_CACHE_CAPACITY` should be set to a meaningful amount for this cache to be effective.
* `LRU_CACHE_CAPACITY=<cache size>` - Number of objects to cache in the LRU cache

e.g.
```
LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libtcmalloc.so.4  IDEEP_CACHE_MATMUL_REORDERS=1 LRU_CACHE_CAPACITY=256 DNNL_DEFAULT_FPMATH_MODE=BF16 python <your_model_script>.py
```
