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
import os
import argparse
import json
from pathlib import Path


def main(args):
    prompt = args.prompt

    torchchat_path = os.getcwd() + "/gen_ai_utils/torchchat/torchchat.py"

    command = [
        "python3", torchchat_path, "generate", args.model,
        "--quantize", str(args.quant_config),
        "--prompt", prompt,
        "--compile" if args.compile else "",
        "--compile-prefill" if args.compile else "",
        "--max-autotune", "--max-new-tokens", str(args.max_new_tokens)
    ]
    command = [arg for arg in command if arg]
    subprocess.run(command, env=os.environ)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Quantize and Run Benchmark LLM'
    )
    parser.add_argument('--quant-config', type=Path, default=Path.cwd() / "gen_ai_utils/quant_configs/aarch64_cpu_channelwise.json",
                        help='Path to json file for quantization config')
    parser.add_argument('--max-new-tokens', type=int,
                        default=64, help='New tokens to generate at decode.')
    parser.add_argument('--compile', action='store_true',
                        help='Whether to compile the model.')
    parser.add_argument('--model', type=str, default="llama2",
                        help='Torchchat supported model alias')
    parser.add_argument('--prompt', type=str, default="In a distant world where magic and technology coexist, "
                                                      "a mysterious artifact is discovered deep beneath an ancient city. "
                                                      "Legends say the artifact can bend time and space, but it comes with a price. "
                                                      "As various factions race to claim it, a young adventurer—either a reluctant,",
                        help='Input prompt.')

    args = parser.parse_args()

    main(args)
