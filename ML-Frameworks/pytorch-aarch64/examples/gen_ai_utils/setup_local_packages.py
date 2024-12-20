# *******************************************************************************
# Copyright 2021-2024 Arm Limited and affiliates.
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

import subprocess
import sys
import os


def install_packages(packages, target_path):
    for package in packages:
        try:
            print(f"Installing {package}...")
            subprocess.check_call(['sudo', sys.executable, "-m", "pip", "install",
                                   f"--target={target_path}", package])
            print(f"Successfully installed {package}")
        except subprocess.CalledProcessError as e:
            print(f"Failed to install {package}. Error: {e}")


if __name__ == "__main__":
    # Check if correct number of arguments are provided
    if len(sys.argv) < 3:
        print("Usage: python script.py <target_path> <package1> <package2> ...")
        sys.exit(1)

    # Get target path and packages from command line arguments
    target_path = sys.argv[1]
    packages = sys.argv[2:]

    install_packages(packages, target_path)
