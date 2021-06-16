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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either exprgess or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************
"""
This wrapper script downloads Python modules that are required to
in order to be able to deserialize saved PyTorch module
"""

import datetime
import os
import sys

import urllib.request

# List of files that need downloading
REPO = "https://raw.githubusercontent.com/mlcommons/inference"
COMMIT = "8b58587c93af2a5ee67722064f2540a2db15d42f"
FILES = [
    "vision/classification_and_detection/python/models/ssd_r34.py",
    "vision/classification_and_detection/python/models/base_model_r34.py",
]

# We need to replace calls to view with reshape with new PyTorch versions
PATCH = {"ssd_r34.py": [".view", ".reshape"]}

# Name of directory where the files should sit
FOLDER = "models"


def main():
    """
    Main entry method
    """
    current_time = datetime.datetime.now()
    current_time_str = current_time.strftime("%Y%m%dT%H%M%S")

    # folder where to download files
    folder = os.path.join(
        os.getcwd(), "ssd_resnet34_" + current_time_str, FOLDER
    )
    os.makedirs(folder, exist_ok=True)

    for python_file in FILES:
        basename = python_file.split("/")[-1]
        dest = os.path.join(folder, basename)
        url = os.path.join(REPO, COMMIT, python_file)
        urllib.request.urlretrieve(url, dest)

        # Check whether downloaded file needs to be patched
        if basename in PATCH:
            with open(dest, "r") as file:
                filedata = file.read()
                # Patch the file
                filedata = filedata.replace(
                    PATCH[basename][0], PATCH[basename][1]
                )
            with open(dest, "w") as file:
                file.write(filedata)

    # add folder to PYTHONPATH so that classes and methods
    # are callable
    models_folder = "/".join(folder.split("/")[:-1])
    sys.path.insert(1, models_folder)


if __name__ == "__main__":
    main()
