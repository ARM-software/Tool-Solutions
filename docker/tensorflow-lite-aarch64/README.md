# Build TensorFlow Lite 2.8 and ArmNN 22.02 for Arm AArch64

This folder contains scripts and patches to build a Docker image that contains [TensorFlow Lite](https://www.tensorflow.org/lite) and [ArmNN](https://developer.arm.com/ip-products/processors/machine-learning/arm-nn) for Arm AArch64 execution.

For more information, please see [this](https://gitlab.com/arm-hpc/packages/-/wikis/packages/tensorflow-lite) wiki page.

To build the image simply run:

``` ./build.sh ```

## Conversion to TensorFlow Lite format

If your model is in TensorFlow Protocol Buffers format, convert it to optimized TensorFlow Lite FlatBuffer format by following instructions and code from [here](https://gitlab.com/arm-hpc/packages/-/wikis/packages/tensorflow-lite#conversion-to-tensorflow-lite-format).

To quantize already trained model to INT8 please follow instructions and code from [here](https://gitlab.com/arm-hpc/packages/-/wikis/packages/tensorflow-lite#post-training-integer-quantization).

## Running the Docker image
To run the finished image:

```docker run --rm -it --init <image name> ```

where <image name> is the name of the finished image, for example 'pytorch'.

```docker run --rm -it --init tensorflow-lite-aarch64```


## Running inference

In the image in `$HOME/examples` directory there is a script `run_mobilenet.sh` that downloads MobileNetV1 model from [Zenodo](https://zenodo.org/record/2269307/files/mobilenet_v1_1.0_224.tgz) and runs it using ArmNN as a standalone binary and using `benchmark_model` binary from Tensorflow lite with ArmNN as delegate. The command to run MobileNetV1 with ArmNN as standalone using `ExecuteNetwork` that is available in the image in `/packages/armnn/build/tests' is:

```
/packages/armnn/build/tests/ExecuteNetwork -c CpuAcc -f tflite-binary -m mobilenet_v1_1.0_224.tflite -T parser -i input -o MobilenetV1/Predictions/Reshape_1 --number-of-threads 8 --iterations 10
```

Here ArmNN is executing model (`-m mobilnet_v1_1.0_224.tflite -f tflite-binary -T parser') with input (`-i input`) and output (`-o MobilenetV1/Predictions/Reshape_1`) ten times (`--iterations 10`) on 8 threads (`--number-of-threads 8`) using accelerated mode (`-c CpuAcc`).

Alternatively the same model can be executed using `benchmark_model` (located in `/packages/tflite_build/benchmark_model`) binary with ArmNN as delegate (located in `/packages/armnn/build/delegate/libarmnnDelegate.so`):

```
/packages/tflite_build/benchmark_model --graph=mobilenet_v1_1.0_224.tflite --external_delegate_path=/packages/armnn/build/delegate/libarmnnDelegate.so --external_delegate_options="backends:CpuAcc;number-of-threads:8" --num_runs=10 --warmup_runs=5
```

Here options to ArmNN are passed through `--external_delegate_options` flag.