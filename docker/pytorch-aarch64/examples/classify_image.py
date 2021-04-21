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

from PIL import Image

import torch
import torchvision.models as models
from torchvision import transforms

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

def load_model(model_descriptor):
    '''
    Downloads the model from given URL and builds model
    that can be used for inference
    :param model_descriptor: Dictionary describing model to build
    :returns: Function to be used for inference
    '''

    model_url = model_descriptor['model'][0]['source']
    model_name = model_descriptor['model'][0]['name']
    model_class = model_descriptor['model'][0]['class']

    # Check whether the URL is valid
    try:
        requests.get(model_url)
    except requests.ConnectionError as _:
        return None

    # Download the model
    urllib.request.urlretrieve(
        model_url,
        model_name,
        DownloadProgressBar('Downloading: ' + model_name + '...'))

    # Check if the model has been downloaded
    if not os.path.isfile(model_name):
        return None

    class_ = getattr(models, model_class)
    model = class_()
    state_dict = torch.load(model_name)
    model.load_state_dict(state_dict)
    model.eval()

    return model

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

def get_and_preprocess_image(image_url):
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

    input_image = Image.open(image_file)
    preprocess = transforms.Compose([
        transforms.Resize(256),
        transforms.CenterCrop(224),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
    ])
    input_tensor = preprocess(input_image)
    processed_image = input_tensor.unsqueeze(0)

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
    parser.add_argument("-r",
                        "--tries",
                        type=int,
                        default=5,
                        help="Number of inference runs")

    args = vars(parser.parse_args())

    # check whether path to the model descriptor exists
    if not os.path.isfile(args['model']):
        sys.exit("File %s does not exists!" % args['model'])
    model_descriptor = open(args['model'])
    model_descriptor = yaml.load(model_descriptor, Loader=yaml.FullLoader)

    # check whether the URL given for image exists
    try:
        requests.get(args['image'])
    except requests.ConnectionError as _:
        sys.exit("Image URL %s is not available!" % args['image'])

    # Load model used for inference
    infer_func = load_model(
        model_descriptor)
    if infer_func is None:
        sys.exit("Failed to download the model")

    # Obtain labels
    labels = load_labels(
        model_descriptor['model'][0]['labels'])

    # Preprocess the image
    image = get_and_preprocess_image(
        args['image'])

    inference_times = []
    for _ in range(args['tries']):
        start = time.time_ns()
        with torch.no_grad():
            output = infer_func(image)
        end = time.time_ns()

        inference_time = np.round((end - start) / 1e6, 2)
        inference_times.append(inference_time)

    print('---------------------------------')
    print('Inference time: %d ms' % np.min(inference_time))
    print('---------------------------------')

    probabilities = torch.nn.functional.softmax(output[0], dim=0)
    _, top5_catid = torch.topk(probabilities, 5)
    print('---------------------------------')
    print('Top prediction is: ' + labels[top5_catid[0]])
    print('---------------------------------')

    print('---------- Top 5 labels ---------')
    print(labels[top5_catid])
    print('---------------------------------')

if __name__ == "__main__":
    main()
