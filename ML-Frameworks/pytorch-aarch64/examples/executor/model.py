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
Class that wraps around TensorFlow session and execute frozen model
"""

import os
import runpy
import time
import sys
from urllib.parse import urlparse
import urllib.request
import warnings
import zipfile

import numpy as np
from tqdm import tqdm

import torch
import torchvision.models as torch_models


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

    def __init__(self):
        self._model = None

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

    def load(self, model_file, model_descriptor):
        """
        Downloads the model from given URL and builds frozen function
        that can be used for inference
        :param model_file: File describing model to build
        :param model_descriptor: Parsed yaml file describing model to build
        :returns: Function to be used for inference
        """

        if self._model is not None:
            return True

        # downloading the model, only done if it exists
        model_name = self._download_model(model_descriptor)

        if "class" in model_descriptor["model"]:
            model_class = model_descriptor["model"]["class"]
            if model_class == "retinanet_resnext50_32x4d_fpn":
                # The RetinaNet model is loaded from a different module
                class_ = getattr(torch_models.detection, model_class)
                self._model = class_()
                state_dict = torch.load(model_name, map_location="cpu")["model"]
            else:
                # Loading a given state dict into the provided class
                class_ = getattr(torch_models, model_class)
                self._model = class_()
                state_dict = torch.load(model_name, map_location="cpu")
            self._model.load_state_dict(state_dict)

        elif "script" in model_descriptor["model"]:
            warnings.filterwarnings("ignore")
            script_path = os.path.join(
                "/".join(model_file.split("/")[:-1]),
                model_descriptor["model"]["script"],
            )
            # the script for preparing files to run
            runpy.run_path(script_path, run_name="__main__")
            self._model = torch.load(model_name, map_location="cpu", weights_only=False)

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
