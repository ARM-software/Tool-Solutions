# SPDX-FileCopyrightText: Copyright 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

import torch
import sys
import os
import tempfile
import argparse
import time

from torchao.quantization.quant_api import (
    Int8DynamicActivationIntxWeightConfig,
    quantize_,
)
from torchao.quantization.granularity import PerGroup, PerAxis
from torchao.quantization.quant_primitives import MappingType

from transformers import AutoModelForCausalLM, AutoConfig, AutoTokenizer, TextStreamer

torch.set_grad_enabled(False)


def load_model_components(model_folder_path):
    try:
        if os.path.exists(model_folder_path) and os.path.isdir(model_folder_path):
            try:
                print("Attempting to load model components from local directory.")
                config = AutoConfig.from_pretrained(
                    model_folder_path, local_files_only=True
                )
                tokenizer = AutoTokenizer.from_pretrained(
                    model_folder_path, local_files_only=True
                )
                model = AutoModelForCausalLM.from_pretrained(
                    model_folder_path, local_files_only=True
                )
                print("Model components loaded successfully from local directory.")
                return config, tokenizer, model
            except Exception as local_error:
                print(f"Failed to load locally: {local_error}")

        with tempfile.TemporaryDirectory() as temp_dir:
            original_directory = os.getcwd()
            os.chdir(temp_dir)
            try:
                print("Loading model components from Hugging Face Model Hub.")
                config = AutoConfig.from_pretrained(model_folder_path)
                tokenizer = AutoTokenizer.from_pretrained(model_folder_path)
                model = AutoModelForCausalLM.from_pretrained(model_folder_path)
                print(
                    "Model components loaded successfully from Hugging Face Model Hub."
                )
                return config, tokenizer, model
            except Exception as hub_error:
                print(
                    f"An error occurred while loading from Hugging Face Model Hub: {hub_error}.\nPlease run huggingface_cli login."
                )
                return None, None, None
            finally:
                os.chdir(original_directory)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None, None, None


def get_quantized_model(args):
    model_name = f"{args.model}"
    print("Running model ", model_name)
    config, tokenizer, model = load_model_components(args.model)
    if model is None:
        print("[ERROR] Model loading failed. Exiting.")
        sys.exit(1)

    print("Quantizing model to 4 bit ..")

    # Set granularity and mapping type based on quant-scheme
    if args.quant_scheme == "symmetric_channelwise":
        granularity = PerAxis(axis=0)
        mapping_type = MappingType.SYMMETRIC
    elif args.quant_scheme == "symmetric_groupwise":
        granularity = PerGroup(args.groupsize)
        mapping_type = MappingType.SYMMETRIC_NO_CLIPPING_ERR
    else:
        raise ValueError(f"Unsupported quant scheme: {args.quant_scheme}")

    quant_config = Int8DynamicActivationIntxWeightConfig(
        weight_scale_dtype=torch.float32,
        weight_granularity=granularity,
        weight_mapping_type=mapping_type,
        weight_dtype=torch.int4,
        intx_packing_format="opaque_aten_kleidiai",
    )

    print("Quantization config:")

    quantize_(model, quant_config)
    model = model.eval()

    if args.compile:
        model.generation_config.cache_implementation = "static"
        model.forward = torch.compile(
            model.forward, backend="inductor", dynamic=True, fullgraph=True
        )

    return model, tokenizer, config


@torch.no_grad()
def eval_quantized_output(quantized_model, tokenizer, input_tensor, max_min_tokens):
    quantized_model.generate(
        input_tensor,
        do_sample=False,
        max_new_tokens=max_min_tokens,
        min_new_tokens=max_min_tokens,
    )
    quantized_model.generate(
        input_tensor, do_sample=False, max_new_tokens=1, min_new_tokens=1
    )

    start_time = time.time()
    quantized_model.generate(
        input_tensor, do_sample=False, max_new_tokens=1, min_new_tokens=1
    )
    end_time = time.time()
    prefill_time = end_time - start_time

    start_time = time.time()
    outputs = quantized_model.generate(
        input_tensor, do_sample=False, max_new_tokens=max_min_tokens
    )
    end_time = time.time()
    generation_time = end_time - start_time

    decode_time = generation_time - prefill_time
    encoded_length = input_tensor.shape[1]

    generated_text_full = tokenizer.decode(outputs[0], skip_special_tokens=False)
    decoded_tokens = tokenizer.encode(generated_text_full, return_tensors="pt")
    decoded_length = decoded_tokens.shape[1] - encoded_length

    prefill_tokens_per_second = encoded_length / prefill_time
    decode_tokens_per_second = decoded_length / decode_time
    streamer = TextStreamer(tokenizer, skip_special_tokens=True)

    print("=" * 100)
    quantized_model.generate(
        input_tensor, streamer=streamer, do_sample=False, max_new_tokens=max_min_tokens
    )
    print("=" * 100)
    print(f"Prefill Tokens: {encoded_length}")
    print(f"Prefill time: {prefill_time:.2f} seconds")
    print(f"E2E Generation time: {generation_time:.2f} seconds")
    print(f"Decoded Tokens: {decoded_length}")
    print(f"Decode time: {decode_time:.2f} seconds")
    print(f"Prefill Tokens per second: {prefill_tokens_per_second:.2f}")
    print(f"Decode Tokens per second: {decode_tokens_per_second:.2f}")


def main(args):
    name_string = f"{args.model}"
    quantized_model_, tokenizer_, config_ = get_quantized_model(args)
    input_tensor = tokenizer_.encode(args.prompt, return_tensors="pt")
    eval_quantized_output(
        quantized_model_, tokenizer_, input_tensor, args.max_new_tokens
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Quantize and Run Benchmark LLM")
    parser.add_argument(
        "--quant-scheme",
        type=str,
        choices=["symmetric_channelwise", "symmetric_groupwise"],
        default="symmetric_groupwise",
        help="Quantization scheme to use (affects granularity)",
    )
    parser.add_argument(
        "--groupsize",
        type=int,
        default=32,
        help="Group size for PerGroup quantization (only used in symmetric_groupwise)",
    )
    parser.add_argument(
        "--max-new-tokens",
        type=int,
        default=64,
        help="New tokens to generate at decode.",
    )
    parser.add_argument(
        "--compile", action="store_true", help="Whether to compile the model."
    )
    parser.add_argument(
        "--model",
        type=str,
        default="TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        help="Hugging Face model ID or Cloned model repository with model files",
    )
    parser.add_argument(
        "--prompt",
        type=str,
        default="In a distant world where magic and technology coexist, "
        "a mysterious artifact is discovered deep beneath an ancient city. "
        "Legends say the artifact can bend time and space, but it comes with a price. "
        "As various factions race to claim it, a young adventurer—either a reluctant,",
        help="Input prompt.",
    )
    args = parser.parse_args()

    main(args)
