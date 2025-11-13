# *******************************************************************************
# Copyright 2021-2025 Arm Limited and affiliates.
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

import sys
import random
import torch
from transformers import AutoTokenizer, AutoModelForQuestionAnswering
from torchao.quantization.quant_api import (
    Int8DynamicActivationIntxWeightConfig,
    quantize_,
)
from torchao.dtypes.uintx.packed_linear_int8_dynamic_activation_intx_weight_layout import (
    PackedLinearInt8DynamicActivationIntxWeightLayout,
    Target,
)
from torchao.quantization.granularity import PerAxis
from torchao.quantization.quant_primitives import MappingType

from utils import nlp

import time

import argparse

def main():
    """
    Main function
    """

    parser = argparse.ArgumentParser()
    parser.add_argument("-id", "--squadid",
        help="ID of SQuAD record to use. A record will be picked at random if unset")
    parser.add_argument("-s", "--subject",
        help="Pick a SQuAD question on the given subject at random")
    parser.add_argument("-t", "--text",
        help="Filename of a user-specified text file to answer questions on. Note: SQuAD id is ignored if set.")
    parser.add_argument("-q", "--question",
        help="Question to ask about the user-provided text. Note: SQuAD id is ignored if set.")
    parser.add_argument("--bert-large", action='store_true',
        help="Use BERT large instead of DistilBERT")
    parser.add_argument("--quantize", action='store_true',
        help="Quantize the model to int4 using dynamic quantization")
    parser.add_argument("--warmup", action='store_true',
        help="Run warmup")

    args = vars(parser.parse_args())

    source = args.get("text","")
    subject = args.get("subject","")
    context = ""
    question = args.get("question","")
    answer = args.get("answer","")
    squadid = args.get("squadid","")

    # Setup the question, either from a specified SQuAD record
    # or from cmd line arguments.
    # If no question details are provided, a random
    # SQuAD example will be chosen.
    if question:
        if source:
            with open(source, "r") as text_file_handle:
                context = text_file_handle.read()
        else:
            print("No text provided, searching SQuAD dev-2.0 dataset")
            squad_data = nlp.import_squad_data()
            squad_records = squad_data.loc[
                squad_data["clean_question"] == nlp.clean(question)
            ]
            if squad_records.empty:
                sys.exit(
                    "Question not found in SQuAD data, please provide context using `--text`."
                )
            subject = squad_records["subject"].iloc[0]
            context = squad_records["context"].iloc[0]
            question = squad_records["question"].iloc[0]
            answer = squad_records["answer"]
    else:
        squad_data = nlp.import_squad_data()

        if squadid:
            source = args["squadid"]
            squad_records = squad_data.loc[squad_data["id"] == source]
            i_record = 0
        else:
            if subject:
                print(
                    "Picking a question at random on the subject: ",
                    subject,
                )
                squad_records = squad_data.loc[
                    squad_data["subject"] == subject
                ]
            else:
                print(
                    "No SQuAD ID or question provided, picking one at random!"
                )
                squad_records = squad_data

            n_records = len(squad_records.index)
            i_record = random.randint(0, max(0, n_records - 1))

        if squad_records.empty:
            sys.exit(
                "No questions found in SQuAD data, please provide valid ID or subject."
            )

        n_records = len(squad_records.index)
        i_record = random.randint(0, n_records - 1)
        source = squad_records["id"].iloc[i_record]
        subject = squad_records["subject"].iloc[i_record]
        context = squad_records["context"].iloc[i_record]
        question = squad_records["question"].iloc[i_record]
        answer = squad_records["answer"].iloc[i_record]

    if args["bert_large"]:
        model_hf_path = "google-bert/bert-large-uncased-whole-word-masking-finetuned-squad"
        model_name = "BERT Large"
    else:
        model_hf_path = "distilbert-base-uncased-distilled-squad"
        model_name = "DistilBERT"

    token = AutoTokenizer.from_pretrained(model_hf_path, return_token_type_ids=True)
    model = AutoModelForQuestionAnswering.from_pretrained(model_hf_path)

    if args["quantize"]:
        layout = PackedLinearInt8DynamicActivationIntxWeightLayout(target=Target.ATEN)
        quantize_(
            model,
            Int8DynamicActivationIntxWeightConfig(
                weight_scale_dtype=torch.float32,
                weight_granularity=PerAxis(0),
                weight_mapping_type=MappingType.SYMMETRIC_NO_CLIPPING_ERR,
                layout=layout,
                weight_dtype=torch.int4,
                intx_packing_format="opaque_aten_kleidiai",
                version=2,
            ),
            filter_fn=lambda m, _: isinstance(m, torch.nn.Linear),
        )

    encoding = token.encode_plus(
        question,
        context,
        max_length=512, truncation=True
    )

    input_ids, attention_mask = (
        encoding["input_ids"],
        encoding["attention_mask"],
    )

    if args["warmup"]:
        model(
            torch.tensor([input_ids]),
            attention_mask=torch.tensor([attention_mask]),
            return_dict=False,
        )

    start_time = time.time()
    start_scores, end_scores = model(
        torch.tensor([input_ids]),
        attention_mask=torch.tensor([attention_mask]),
        return_dict=False,
    )
    end_time = time.time()

    answer_ids = input_ids[
        torch.argmax(start_scores) : torch.argmax(end_scores) + 1
    ]
    answer_tokens = token.convert_ids_to_tokens(
        answer_ids, skip_special_tokens=True
    )
    answer_tokens_to_string = token.convert_tokens_to_string(answer_tokens)

    # Display results
    print(f"\n{model_name} question answering example.")
    print("======================================")
    print("Reading from: ", subject, source)
    print("\nContext: ", context)
    print(f"Inference time: {end_time - start_time}s")
    print("--")
    print("Question: ", question)
    print("Answer: ", answer_tokens_to_string)
    print("Reference Answer: ", answer)


if __name__ == "__main__":
    main()
