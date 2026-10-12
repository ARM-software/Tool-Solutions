# SPDX-FileCopyrightText: Copyright 2021, 2023, 2025, 2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0
"""
Helper methods that are common between utility functions
"""

from pathlib import Path
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
import http.client
import tempfile
import time
import urllib.error
import urllib.request

import yaml


RESNET50_NAME = "resnet50_v1.pth"
RETINANET_NAME = "retinanet_model_10.pth"
SSD_RESNET34_NAME = "resnet34-ssd1200.pytorch"
USER_AGENT = (
    "Tool-Solutions/1.0 (https://github.com/ARM-software/Tool-Solutions)"
)


def _retry_delay(error, attempt):
    """Honour Retry-After, otherwise use exponential backoff."""
    value = error.headers.get("Retry-After") if isinstance(error, urllib.error.HTTPError) else None
    if value:
        try:
            return max(0, float(value))
        except ValueError:
            try:
                return max(0, (parsedate_to_datetime(value) - datetime.now(timezone.utc)).total_seconds())
            except (ValueError, TypeError):
                pass
    return min(60, 2 ** attempt)


def download_url(url, dest, *, reporthook=None, timeout=60, attempts=5):
    """
    Downloads a URL to a local file if needed.
    :param url: URL to download
    :param dest: Local output path
    :param reporthook: Optional urllib.urlretrieve-style progress hook
    :param timeout: Network timeout in seconds
    :param attempts: Maximum attempts for transient download failures
    :returns: Local output path
    """
    dest = Path(dest)
    if dest.is_file():
        return dest

    if attempts < 1:
        raise ValueError("attempts must be positive")
    dest.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(attempts):
        temporary = None
        try:
            request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(request, timeout=timeout) as response:
                total_size = int(response.headers.get("Content-Length", -1))
                block_size = 8192
                block_num = 0
                if reporthook:
                    reporthook(0, block_size, total_size)
                with tempfile.NamedTemporaryFile(dir=dest.parent, suffix=".part", delete=False) as output:
                    temporary = Path(output.name)
                    while block := response.read(block_size):
                        output.write(block)
                        block_num += 1
                        if reporthook:
                            reporthook(block_num, block_size, total_size)
            if total_size >= 0 and temporary.stat().st_size != total_size:
                raise urllib.error.ContentTooShortError(f"Incomplete download: {url}", None)
            temporary.replace(dest)
            return dest
        except (OSError, http.client.HTTPException) as error:
            if isinstance(error, urllib.error.HTTPError) and error.code not in (408, 429, 500, 502, 503, 504):
                raise
            if attempt + 1 == attempts:
                raise
            delay = _retry_delay(error, attempt)
            print(f"Download failed ({error}); retrying in {delay:.1f}s: {url}", flush=True)
            time.sleep(delay)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)


def parse_model_file(model_file):
    """
    Parses YAML configuration file to dictionary
    :param model_file: Path to model descriptor to parse
    """

    with open(model_file) as model_file_handle:
        model_descriptor = yaml.load(model_file_handle, Loader=yaml.FullLoader)

    return model_descriptor
