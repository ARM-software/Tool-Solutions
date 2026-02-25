# SPDX-FileCopyrightText: Copyright 2021, 2022, 2024-2026 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# System packages
import argparse
import random
import sys
import time

# Installed packages
import torch
from transformers import AutoTokenizer, AutoModelForQuestionAnswering
from torchao.quantization.quant_api import (
    Int8DynamicActivationIntxWeightConfig,
    quantize_,
)
from torchao.quantization.granularity import PerAxis
from torchao.quantization.quant_primitives import MappingType

# Local modules
from utils import nlp


def get_best_span_from_scores(start_scores, end_scores, max_answer_len, top_k):
    best_score = -1e18
    (start_idx, end_idx) = (0, 0)
    topk_start_posns = torch.topk(start_scores[0], k=top_k).indices.tolist()
    topk_end_posns = torch.topk(end_scores[0], k=top_k).indices.tolist()
    for start in topk_start_posns:
        for end in topk_end_posns:
            if (end < start) or ((end + 1) - start > max_answer_len):
                continue
            score = start_scores[0][start].item() + end_scores[0][end].item()
            if score > best_score:
                (best_score, start_idx, end_idx) = (score, start, end)
    return (start_idx, end_idx)


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
    answer = ""
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
                print("Picking a question at random on the subject: ", subject)
                squad_records = squad_data.loc[squad_data["subject"] == subject]
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

    # Select model and tokenizer
    if args["bert_large"]:
        model_hf_path = "google-bert/bert-large-uncased-whole-word-masking-finetuned-squad"
        model_name = "BERT Large"
    else:
        model_hf_path = "distilbert-base-uncased-distilled-squad"
        model_name = "DistilBERT"
    token = AutoTokenizer.from_pretrained(model_hf_path, return_token_type_ids=True)
    model = AutoModelForQuestionAnswering.from_pretrained(model_hf_path)

    # Optional: quantize
    if args["quantize"]:
        quantize_(
            model,
            Int8DynamicActivationIntxWeightConfig(
                weight_scale_dtype=torch.float32,
                weight_granularity=PerAxis(0),
                weight_mapping_type=MappingType.SYMMETRIC_NO_CLIPPING_ERR,
                weight_dtype=torch.int4,
                intx_packing_format="opaque_aten_kleidiai",
                version=2,
            ),
            filter_fn=lambda m, _: isinstance(m, torch.nn.Linear),
        )

    # Encode context
    encoding = token.encode_plus(question, context, max_length=512, truncation=True)
    (input_ids, attention_mask) = (encoding["input_ids"], encoding["attention_mask"])

    # Warm-up
    if args["warmup"]:
        model(
            torch.tensor([input_ids]),
            attention_mask=torch.tensor([attention_mask]),
            return_dict=False,
        )

    # Process
    start_time = time.time()
    with torch.no_grad():
        start_scores, end_scores = model(
            torch.tensor([input_ids]),
            attention_mask=torch.tensor([attention_mask]),
            return_dict=False,
        )
    end_time = time.time()

    # Post-process scores to find most likely answer
    (start_idx, end_idx) = get_best_span_from_scores(
        start_scores, end_scores, max_answer_len=30, top_k=20)

    # Decode answer
    answer_ids = input_ids[start_idx:end_idx + 1]
    answer_tokens_to_string = token.decode(answer_ids, skip_special_tokens=True).strip()

    # Display results
    print(f"\n{model_name} question answering example.")
    print("======================================")
    print("Reading from: ", subject, source)
    max_context_to_print = 1000
    if len(context) <= max_context_to_print:
        print("\nContext: ", context)
    else:
        print(f"\nContext (limited to {max_context_to_print} chars):")
        print(context[:max_context_to_print])
        print("...")
    print("--")
    print("Question:", question)
    print("Answer:", answer_tokens_to_string)
    print("Reference Answer:", answer)
    print(f"Inference time: {end_time - start_time:.6f}s")


if __name__ == "__main__":
    main()
