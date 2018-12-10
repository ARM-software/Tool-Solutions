## MNIST Demo Application

Simple TensorFlow neural network trained on the task of [MNIST](http://yann.lecun.com/exdb/mnist/).
Uses Arm NN to optimise inference on Arm Cortex-A CPU or Arm Mali GPU.

NOTE: This application is heavily based on the ML-Examples on the [ARM-software GitHub repo](https://github.com/ARM-software/ML-examples/tree/master/armnn-mnist).

This is the example code used in Arm's [Deploying a TensorFlow MNIST model on Arm NN](https://developer.arm.com/technologies/machine-learning-on-arm/developer-material/how-to-guides/) tutorial - a more detailed description can be found there.

The application mnist_tf.cpp reads from a TensorFlow model.
Models are stored in the model/ directory in two formats: protobuf binary and protobuf text.
Data is stored in directory data/ in a simple format designed for storing vectors and n-d matrices. It contains the test set only.

## Arm NN MNIST
Use Arm NN to deploy a Tensorflow MNIST network on an Arm Cortex-A CPU or Arm Mali GPU.

## Dependencies

You will need the Arm NN SDK, available from the [Arm NN SDK site](https://developer.arm.com/products/processors/machine-learning/arm-nn). TensorFlow support will require version 18.02.1 or above.

## Usage

Edit the Makefile and change ARMNN_LIB and ARMNN_INC to point to the library and include directories of your Arm NN installation:

    ARMNN_LIB = ${HOME}/armnn-devenv/armnn/build
    ARMNN_INC = ${HOME}/armnn-devenv/armnn/include

You can then build and run the examples with:
```bash
# Go into the repository
cd mnist-demo
make test
```

This builds and runs two different TensorFlow models from model/ and performs a hardcoded number of inferences on the MNIST data set in data/.

The purpose of these examples is to demonstrate how to use Arm NN to load and execute TensorFlow models in a C++ application.

For information about how to profile with Arm Streamline refer to the file mnist-demo.pdf
