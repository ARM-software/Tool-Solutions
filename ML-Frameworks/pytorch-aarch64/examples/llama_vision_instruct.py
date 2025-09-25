# *******************************************************************************
# Copyright 2025 Arm Limited and affiliates.
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

import argparse
import requests
import torch
from PIL import Image
from transformers import MllamaForConditionalGeneration, AutoProcessor, GenerationConfig, TextStreamer
import time
from torchao.quantization.quant_api import (
    Int8DynamicActivationIntxWeightConfig,
    quantize_,
)
from torchao.dtypes.uintx.packed_linear_int8_dynamic_activation_intx_weight_layout import (
    PackedLinearInt8DynamicActivationIntxWeightLayout,
    Target,
)
from torchao.quantization.granularity import PerGroup, PerAxis
from torchao.quantization.quant_primitives import MappingType
import numpy as np
import os

def main(args):

    model_id = "meta-llama/Llama-3.2-11B-Vision-Instruct"
    model = MllamaForConditionalGeneration.from_pretrained(
        model_id,
        torch_dtype=torch.bfloat16 if args.dtype == "bfloat16" else torch.float32,
    )

    if args.quantize:
        layout = PackedLinearInt8DynamicActivationIntxWeightLayout(target=Target.ATEN)
        quantize_(
            model,
            Int8DynamicActivationIntxWeightConfig(
                weight_scale_dtype=torch.float32,
                weight_granularity=PerAxis(0),  #PerAxis is also supported
                weight_mapping_type=MappingType.SYMMETRIC_NO_CLIPPING_ERR, # MappingType.SYMMETRIC can also be used but increases error
                layout=layout,
                weight_dtype=torch.int4,
                intx_packing_format="opaque_aten_kleidiai",
            ),
        )

    processor = AutoProcessor.from_pretrained(model_id)
    image = Image.open(requests.get(args.image_url, stream=True).raw)

    messages = [
        {"role": "user", "content": [
            {"type": "image"},
            {"type": "text", "text": args.prompt + os.linesep}
        ]}
    ]

    input_text = processor.apply_chat_template(messages, add_generation_prompt=True)
    inputs = processor(
        image,
        input_text,
        add_special_tokens=False,
        return_tensors="pt"
    ).to(model.device)


    prefill_generation_config = GenerationConfig(do_sample=False, max_new_tokens=1, min_new_tokens=1, temperature=None, top_p=None)
    e2e_generation_config = GenerationConfig(do_sample=False, max_new_tokens=args.num_new_tokens, min_new_tokens=args.num_new_tokens, temperature=None, top_p=None)

    print("=" * 100)
    if args.benchmark:
        WARMUP_ITERS = 1
        BENCHMARK_ITERS = 3

        # prefill
        for _ in range(WARMUP_ITERS):
            model.generate(**inputs, generation_config=prefill_generation_config)

        prefill_times = []
        for _ in range(BENCHMARK_ITERS):
            start_time = time.time()
            model.generate(**inputs, generation_config=prefill_generation_config)
            prefill_times.append(time.time() - start_time)

        mean_prefill_times = np.mean(prefill_times)
        print("Prefill Time: ", mean_prefill_times)

        # end to end generation
        for _ in range(WARMUP_ITERS):
            model.generate(**inputs, generation_config=e2e_generation_config)

        e2e_times = []
        for _ in range(BENCHMARK_ITERS):
            start_time = time.time()
            model.generate(**inputs, generation_config=e2e_generation_config)
            e2e_times.append(time.time() - start_time)

        mean_e2e_times = np.mean(e2e_times)
        print("End to End Time: ", mean_e2e_times)
        print("Decode Throughput: ", args.num_new_tokens / (mean_e2e_times - mean_prefill_times))

    print("Model output:")
    streamer = TextStreamer(processor, skip_special_tokens=True)
    model.generate(**inputs,  streamer=streamer, generation_config=e2e_generation_config)
    print("=" * 100)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Quantize and Run Benchmark LLM")
    parser.add_argument(
        "--num-new-tokens",
        type=int,
        default=32,
        help="The model will always generate this number of new tokens",
    )
    parser.add_argument(
        "--prompt",
        type=str,
        default="what is the animal in this image",
        help="Input prompt.",
    )
    parser.add_argument(
        "--image-url",
        type=str,
        default="https://huggingface.co/datasets/huggingface/documentation-images/resolve/0052a70beed5bf71b92610a43a52df6d286cd5f3/diffusers/rabbit.jpg",
        help="URL to image"
    )
    parser.add_argument(
        "--benchmark",
        action="store_true",
        help="Run a benchmark, with warmup and multiple iterations"
    )
    parser.add_argument(
        "--dtype",
        type=str,
        default="bfloat16",
        choices=["bfloat16", "float32"],
        help="Precision to run the model in (or the non-linear layers for quantized model)"
    )
    parser.add_argument(
        "--quantize",
        action="store_true",
        help="Quantize weights to int4 symmetric channelwise"
    )

    args = parser.parse_args()
    main(args)
