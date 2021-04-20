# *******************************************************************************
# Copyright 2021  Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************
'''
This example demonstrates how to load an image classification model and run
inference on a single image
'''

import argparse
import json
import os.path
import sys
import time
import urllib.request
import yaml

import requests

from tqdm import tqdm
import numpy as np

import tensorflow as tf
from tensorflow.python.tools.optimize_for_inference_lib import optimize_for_inference
from tensorflow.python.framework import dtypes

class Model():
    '''
    Simple class that wraps around TensorFlow session that is used
    to run inference
    '''
    def __init__(self, optimized, threads):
        self._session = None
        self._inputs = None
        self._outputs = None

        self._optimized = optimized
        self._threads = threads

    def load(self, model_descriptor):
        '''
        Downloads the model from given URL and builds frozen function
        that can be used for inference
        :param model_descriptor: Dictionary describing model to builds
        :returns: Function to be used for inference
        '''

        if self._session is not None:
            # do not need to do anything as model has
            # already been downloaded
            return True

        self._inputs = [model_descriptor['arguments'][0]['input'] + ':0']
        self._outputs = [model_descriptor['arguments'][0]['output'] + ':0']

        model_url = model_descriptor['model'][0]['source']
        model_name = model_descriptor['model'][0]['name']

        try:
            # Download the model
            urllib.request.urlretrieve(
                model_url,
                model_name,
                DownloadProgressBar('Downloading: ' + model_name + '...'))
        except:
            return False

        infer_config = tf.compat.v1.ConfigProto()
        infer_config.intra_op_parallelism_threads = self._threads
        infer_config.inter_op_parallelism_threads = self._threads

        with tf.io.gfile.GFile(model_name, "rb") as graph_file:
            graph_def = tf.compat.v1.GraphDef()
            graph_def.ParseFromString(graph_file.read())

        if self._optimized:
            graph_def = optimize_for_inference(
                graph_def,
                [item.split(':')[0] for item in self._inputs],
                [item.split(':')[0] for item in self._outputs],
                dtypes.float32.as_datatype_enum,
                False)
        graph = tf.compat.v1.import_graph_def(graph_def, name='')
        self._session = tf.compat.v1.Session(
            graph=graph,
            config=infer_config)

        return True

    def infer(self, input_):
        '''
        Runs inference for a model
        :param input_: Image input
        '''
        return self._session.run(
            self._outputs,
            feed_dict={self._inputs[0]: input_})


class DownloadProgressBar():
    '''
    Simple class to show progress while downloading file
    '''
    def __init__(self, msg):
        self.pbar = None
        self.msg = msg
        self.downloaded = None

    def update_bar(self, block_num, block_size, total_size):
        '''
        Updates progress bar based on how much of the file was downloaded
        :param block_num: Number of blocks downloaded
        :param block_size: Size in bytes of single block
        :param total_size: Total size of the file in bytes
        :return: returns nothing
        '''
        if not self.pbar:
            self.pbar = tqdm(
                desc = self.msg,
                unit = "b",
                unit_scale = True,
                total = total_size)
            self.downloaded = 0

        downloaded = block_num * block_size
        if downloaded < total_size:
            self.pbar.update(downloaded - self.downloaded)
            self.downloaded = downloaded
        else:
            self.pbar.close()

    def __call__(self, block_num, block_size, total_size):
        self.update_bar(
            block_num,
            block_size,
            total_size)

def load_labels(labels_url):
    '''
    Creates array of labels in order to get them with index
    :param labels_url: URL from where to download labels
    :returns: Array of labels
    '''

    # Download labels
    urllib.request.urlretrieve(
        labels_url,
        'labels.json')

    class_idx = json.load(open('labels.json'))
    idx2label = [class_idx[str(k)][1] for k in range(len(class_idx))]

    return np.asarray(idx2label)

def get_and_preprocess_image(image_url, dimensions):
    '''
    Preprocess image for classification to do for inference on models
    that were trained using ImageNet
    :param image_url: Path to the image
    :param dimensions: Width and height to which to scale the image
    :returns: Preprocessed image for image classification
    '''

    image_file = image_url.split('/')[-1] # last part of URL
    # Download the image
    urllib.request.urlretrieve(
        image_url,
        image_file)

    if not os.path.isfile(image_file):
        sys.exit("Image %s does not exists!" % image_file)

    orig_image = tf.keras.preprocessing.image.load_img(
        image_file,
        target_size=dimensions)
    numpy_image = tf.keras.preprocessing.image.img_to_array(orig_image)
    image_batch = np.expand_dims(numpy_image, axis=0)
    processed_image = tf.keras.applications.imagenet_utils.preprocess_input(
        image_batch,
        mode='caffe')

    return processed_image

def main():
    '''
    Main function
    '''
    parser = argparse.ArgumentParser()

    parser.add_argument("-m",
                        "--model",
                        type=str,
                        help="Path to YAML file describing model to run",
                        required=True)
    parser.add_argument("-i",
                        "--image",
                        type=str,
                        help="URL to image that will be classified",
                        required=True)
    parser.add_argument("-t",
                        "--threads",
                        type=int,
                        help="Number of threads to use",
                        default=16,
                        required=False)
    parser.add_argument("-r",
                        "--tries",
                        type=int,
                        help="Number of inference runs",
                        default=5,
                        required=False)
    parser.add_argument("-o",
                        "--optimized",
                        default=False,
                        action="store_true")

    args = vars(parser.parse_args())

    assert args['tries'] > 0, "Number of inference runs must be greater then zero"

    # Check whether path to the model descriptor exists
    if not os.path.isfile(args['model']):
        sys.exit("File %s does not exists!" % args['model'])
    model_descriptor = open(args['model'])
    model_descriptor = yaml.load(model_descriptor, Loader=yaml.FullLoader)

    # Check whether the URL given for image exists
    try:
        requests.get(args['image'])
    except requests.ConnectionError as _:
        sys.exit("Image URL %s is not available!" % args['image'])

    # Load model used for inference
    model = Model(args['optimized'], args['threads'])
    if not model.load(model_descriptor):
        sys.exit("Failed to download the model")

    # Obtain labels
    labels = load_labels(
        model_descriptor['model'][0]['labels'])

    # Preprocess the image
    image = get_and_preprocess_image(
        args['image'],
        tuple(model_descriptor['arguments'][0]['input_shape'][1:3]))

    inference_times = []
    for _ in range(args['tries']):
        start = time.time_ns()
        predictions = model.infer(image)
        end = time.time_ns()

        inference_time = np.round((end - start) / 1e6, 2)
        inference_times.append(inference_time)

    print('---------------------------------')
    print('Inference time: %d ms' % np.min(inference_times))
    print('---------------------------------')

    idx = np.argmax(predictions)

    print('---------------------------------')
    print('Top prediction is: ' + labels[idx-1])
    print('---------------------------------')

    sort_idx = np.flip(np.squeeze(np.argsort(predictions))) - 1
    print('---------- Top 5 labels ---------')
    print(labels[sort_idx[:5]])
    print('---------------------------------')

if __name__ == "__main__":
    main()
