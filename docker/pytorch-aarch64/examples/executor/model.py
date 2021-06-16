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
Class that wraps around TensorFlow session and execute frozen model
"""

import os
import runpy
import time
import urllib.request
import warnings

import numpy as np
from tqdm import tqdm
import yaml

import torch
import torchvision.models as torch_models


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

    def __init__(self):
        self._model = None

    def load(self, model_file):
        """
        Downloads the model from given URL and builds frozen function
        that can be used for inference
        :param model_file: File describing model to build
        :returns: Function to be used for inference
        """

        if self._model is not None:
            return True

        with open(model_file) as model_file_handle:
            model_descriptor = yaml.load(
                model_file_handle, Loader=yaml.FullLoader
            )

        model_url = model_descriptor["model"][0]["source"]
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

        if "class" in model_descriptor["model"][0]:
            model_class = model_descriptor["model"][0]["class"]
            class_ = getattr(torch_models, model_class)
            self._model = class_()
            state_dict = torch.load(model_name)
            self._model.load_state_dict(state_dict)

            self._model.eval()

        elif "script" in model_descriptor["model"][0]:
            warnings.filterwarnings("ignore")
            script_path = os.path.join(
                "/".join(model_file.split("/")[:-1]),
                model_descriptor["model"][0]["script"],
            )
            # the script for preparing files to run
            runpy.run_path(script_path, run_name="__main__")
            self._model = torch.load(model_name, map_location="cpu")

        else:
            assert (
                False
            ), "Cannot load module as there is no Python code of model class"

        self._model.eval()

        return True

    def run(self, image, tries):
        """
        Runs inference multiple times
        :param image: Input image
        :param tries: Number of times to run inference
        """
        inference_times = []
        for _ in range(tries):
            start = time.time_ns()
            with torch.no_grad():
                predictions = self._model(image)
            end = time.time_ns()

            inference_time = np.round((end - start) / 1e6, 2)
            inference_times.append(inference_time)

        print("---------------------------------")
        print("Inference time: %d ms" % np.min(inference_times))
        print("---------------------------------")

        return predictions
