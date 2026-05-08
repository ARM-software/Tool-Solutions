# SPDX-FileCopyrightText: Copyright 2021, 2023, 2025, 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Helper methods that are common between utility functions
"""

from pathlib import Path
import urllib.request

import yaml


RESNET50_NAME = "resnet50_v1.pth"
RETINANET_NAME = "retinanet_model_10.pth"
SSD_RESNET34_NAME = "resnet34-ssd1200.pytorch"
USER_AGENT = (
    "Tool-Solutions/1.0 (https://github.com/ARM-software/Tool-Solutions)"
)


def download_url(url, dest, *, reporthook=None, timeout=60):
    """
    Downloads a URL to a local file if needed.
    :param url: URL to download
    :param dest: Local output path
    :param reporthook: Optional urllib.urlretrieve-style progress hook
    :param timeout: Network timeout in seconds
    :returns: Local output path
    """
    dest = Path(dest)
    if dest.is_file():
        return dest

    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})

    with urllib.request.urlopen(request, timeout=timeout) as response:
        total_size = int(response.headers.get("Content-Length", -1))
        block_size = 8192
        block_num = 0
        with dest.open("wb") as dest_file:
            while True:
                block = response.read(block_size)
                if not block:
                    break
                dest_file.write(block)
                block_num += 1
                if reporthook:
                    reporthook(block_num, block_size, total_size)

    return dest


def parse_model_file(model_file):
    """
    Parses YAML configuration file to dictionary
    :param model_file: Path to model descriptor to parse
    """

    with open(model_file) as model_file_handle:
        model_descriptor = yaml.load(model_file_handle, Loader=yaml.FullLoader)

    return model_descriptor
