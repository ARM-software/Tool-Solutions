# *******************************************************************************
# Copyright 2021-2023 Arm Limited and affiliates.
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
"""
Class that wraps around TensorFlow session and executes the frozen model
"""

import os
import sys
import time
from urllib.parse import urlparse
import urllib.request
import zipfile

import numpy as np
import yaml
from tqdm import tqdm

import tensorflow as tf
from tensorflow.python.tools.optimize_for_inference_lib import (
    optimize_for_inference,
)
from tensorflow.python.framework import dtypes


def _zip_file(zip_file, model_name, extract):
    with zipfile.ZipFile(zip_file) as zf_h:
        for file in zf_h.namelist():
            if file.endswith(model_name):
                if extract:
                    zf_h.extract(file)
                return file


class DownloadProgressBar:
    """
    Very simple helper class to show progress while downloading file
    """

    def __init__(self, msg):
        self.pbar = None
        self.msg = msg
        self.downloaded = None

    def update_bar(self, block_num, block_size, total_size):
        """
        Updates progress bar based on how much of the file was downloaded
        :param block_num: Number of blocks downloaded
        :param block_size: Size in bytes of single block
        :param total_size: Total size of the file in bytes
        :return: returns nothing
        """
        if not self.pbar:
            self.pbar = tqdm(
                desc=self.msg, unit="b", unit_scale=True, total=total_size
            )
            self.downloaded = 0

        downloaded = block_num * block_size
        if downloaded < total_size:
            self.pbar.update(downloaded - self.downloaded)
            self.downloaded = downloaded
        else:
            self.pbar.close()

    def __call__(self, block_num, block_size, total_size):
        self.update_bar(block_num, block_size, total_size)


class Model:
    """
    Wrap around TensorFlow session and run inference
    """

    def __init__(self, unoptimized: bool, intra_threads: int, inter_threads: int) -> None:
        self._session = None
        self._inputs = None
        self._outputs = None

        self._unoptimized = unoptimized
        self._intra_threads = intra_threads
        self._inter_threads = inter_threads
        self._frozen = True

    def _download_model(self, model_descriptor):
        model_url = model_descriptor["model"]["source"]
        # check if source starts with http
        if model_url is not None and not model_url.startswith('http'):
            return None

        # we need to download the model
        model_file = urlparse(model_url).path.split("/")[-1]
        is_zip = model_file.endswith(".zip")

        if is_zip:
            model_name = model_file
        else:
            model_name = model_descriptor["model"]["name"]

        # check to see whether the model exists in the
        # current directory and if it exists then we do
        # not need to download it
        if os.path.isfile(model_name):
            # it exists we do not need to download it
            if is_zip:
                model_name = _zip_file(model_file, model_descriptor["model"]["name"], False)
                if os.path.isfile(model_name):
                    return model_name
            else:
                return model_name

        # Download the model
        urllib.request.urlretrieve(
            model_url,
            model_name,
            DownloadProgressBar("Downloading: " + model_name + "..."),
        )

        # once it is downloaded and if it is archive then
        # find the model and extract it
        if is_zip:
            model_name = _zip_file(model_name, model_descriptor["model"]["name"], True)

        return model_name

    def _read_model(self, model_descriptor):
        # check to see whether name tag exists
        if "name" in model_descriptor["model"]:
            model_name = os.path.join(
                model_descriptor["model"]["source"],
                model_descriptor["model"]["name"])
            if not os.path.isfile(model_name):
                sys.exit('Failed to set up the mode: file %s does not exists' % model_name)

        # if the name tag is not provided then we are assuming
        # that the model is in SavedModel format
        self._frozen = False
        return model_descriptor["model"]["source"]

    def _load_frozen_model(self, model_name, model_descriptor):
        infer_config = tf.compat.v1.ConfigProto()
        infer_config.intra_op_parallelism_threads = self._intra_threads
        infer_config.inter_op_parallelism_threads = self._inter_threads

        with tf.io.gfile.GFile(model_name, "rb") as graph_file:
            graph_def = tf.compat.v1.GraphDef()
            graph_def.ParseFromString(graph_file.read())

        self._outputs = [
            output + ":0"
            for output in model_descriptor["arguments"]["output"].split(",")
        ]

        # by default Graph is optimized for the inference
        if not self._unoptimized:
            graph_def = optimize_for_inference(
                graph_def,
                [item.split(":")[0] for item in self._inputs],
                [item.split(":")[0] for item in self._outputs],
                dtypes.float32.as_datatype_enum,
                False,
            )

        graph = tf.compat.v1.import_graph_def(graph_def, name="")
        self._session = tf.compat.v1.Session(graph=graph, config=infer_config)

    def _load_saved_model(self, model_name, model_descriptor):
        self._session = tf.saved_model.load(model_name).signatures['serving_default']
        self._outputs = model_descriptor["arguments"]["output"].split(",")[0]

    def load(self, model_descriptor):
        """
        Downloads the model from given URL or reads it from disk  and builds
        a function from frozen model or from saved model that can be used
        for inference
        :param model_descriptor: Parsed yaml file describing model to build
        :returns: Boolean true if it builds function for inference otherwise false
        """

        if self._session:
            # this class has already loaded model and built
            # function to do inference
            return True

        # check if source starts with http, if it does then
        # then we need to download the model
        model_name = self._download_model(model_descriptor)
        if model_name is None:
            model_name = self._read_model(model_descriptor)
        # if we still haven't found a model return and inform that
        # we cannot load model neither by downloading from URL or
        # by reading from disk
        if model_name is None:
            return False

        # prepare inputs, outputs and load model
        self._inputs = [model_descriptor["arguments"]["input"] + ":0"]
        if self._frozen:
            self._load_frozen_model(model_name, model_descriptor)
        else:
            self._load_saved_model(model_name, model_descriptor)

        return True

    def _infer(self, input_):
        """
        Runs inference for a model
        :param input_: Image input
        """
        if self._frozen:
            return self._session.run(
                self._outputs, feed_dict={self._inputs[0]: input_}
            )
        else:
            return self._session(tf.constant([input_]))[self._outputs]

    def run(self, image, tries):
        """
        Runs inference number of times
        :param image: Input image
        :param tries: Number of times to run inference
        """
        inference_times = []
        for _ in range(tries):
            start = time.time_ns()
            predictions = self._infer(image)
            end = time.time_ns()

            inference_time = np.round((end - start) / 1e6, 2)
            inference_times.append(inference_time)

        print("---------------------------------")
        print("Inference time: %d ms" % np.min(inference_times))
        print("---------------------------------")

        return predictions
