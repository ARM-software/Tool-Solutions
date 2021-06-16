# *******************************************************************************
# Copyright 2021 Arm Limited and affiliates.
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
import time
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

    def __init__(
        self, unoptimized: bool, intra_threads: int, inter_threads: int
    ) -> None:
        self._session = None
        self._inputs = None
        self._outputs = None

        self._unoptimized = unoptimized
        self._intra_threads = intra_threads
        self._inter_threads = inter_threads

    def load(self, model_file):
        """
        Downloads the model from given URL and builds frozen function
        that can be used for inference
        :param model_file: File describing model to build
        :returns: Function to be used for inference
        """

        with open(model_file) as model_file_handle:
            model_descriptor = yaml.load(
                model_file_handle, Loader=yaml.FullLoader
            )

        if self._session:
            # do not need to do anything as model has
            # already been downloaded
            return True

        self._inputs = [model_descriptor["arguments"][0]["input"] + ":0"]
        self._outputs = [
            output + ":0"
            for output in model_descriptor["arguments"][0]["output"].split(",")
        ]

        model_url = model_descriptor["model"][0]["source"]
        # check to see whether model url is zip file
        model_file = model_url.split("/")[-1]
        model_ext = os.path.splitext(model_file)[1]
        if model_ext == ".zip":
            model_name = model_file
        else:
            model_name = model_descriptor["model"][0]["name"]

        try:
            # Download the model
            urllib.request.urlretrieve(
                model_url,
                model_name,
                DownloadProgressBar("Downloading: " + model_name + "..."),
            )
        except:  # pylint: disable=bare-except
            return False

        # once it is downloaded and if it is archive then
        # find the model and extract it
        if model_ext == ".zip":
            with zipfile.ZipFile(model_name) as zf_h:
                for file in zf_h.namelist():
                    if file.endswith(model_descriptor["model"][0]["name"]):
                        zf_h.extract(file)
                        model_name = file
                        break

        infer_config = tf.compat.v1.ConfigProto()
        infer_config.intra_op_parallelism_threads = self._intra_threads
        infer_config.inter_op_parallelism_threads = self._inter_threads

        with tf.io.gfile.GFile(model_name, "rb") as graph_file:
            graph_def = tf.compat.v1.GraphDef()
            graph_def.ParseFromString(graph_file.read())

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

        return True

    def _infer(self, input_):
        """
        Runs inference for a model
        :param input_: Image input
        """
        return self._session.run(
            self._outputs, feed_dict={self._inputs[0]: input_}
        )

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
