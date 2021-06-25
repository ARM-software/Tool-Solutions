#!/bin/sh

tflite_convert --output_file=model/convol_mnist.tflite --graph_def_file=model/convol_mnist_tf.pb --input_array=input_tensor --input_shapes=$1,28,28,1 --output_arrays=fc2/output_tensor
