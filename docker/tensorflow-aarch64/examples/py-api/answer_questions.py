# *******************************************************************************
# Copyright 2021-2022 Arm Limited and affiliates.
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
import numpy as np
from transformers import DistilBertTokenizer, TFDistilBertForQuestionAnswering

from utils import nlp_parser
from utils import nlp


def main():
    """
    Main function
    """

    # Parse cmd line arguments
    args = nlp_parser.parse_arguments()

    source = ""
    subject = ""
    context = ""
    question = ""
    answer = ""
    squadid = ""

    if args:
        if "text" in args:
            if args["text"]:
                source = args["text"]
        if "subject" in args:
            if args["subject"]:
                subject = args["subject"]
        if "context" in args:
            if args["context"]:
                context = args["context"]
        if "question" in args:
            if args["question"]:
                question = args["question"]
                clean_question = nlp.clean(question)
        if "answer" in args:
            if args["answer"]:
                answer = args["answer"]
        if "squadid" in args:
            if args["squadid"]:
                squadid = args["squadid"]
    else:
        sys.exit("Parser didn't return args correctly")

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
                squad_data["clean_question"] == clean_question
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

    # DistilBERT question answering using pre-trained model.
    token = DistilBertTokenizer.from_pretrained(
        "distilbert-base-uncased", return_token_type_ids=True
    )

    model = TFDistilBertForQuestionAnswering.from_pretrained(
        "distilbert-base-uncased-distilled-squad"
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
    model_output = model(
        np.array([input_ids]), attention_mask=np.array([attention_mask])
    )
    start_scores = model_output.start_logits
    end_scores = model_output.end_logits

    answer_ids = input_ids[np.argmax(start_scores): np.argmax(end_scores) + 1]
    answer_tokens = token.convert_ids_to_tokens(
        answer_ids, skip_special_tokens=True
    )
    answer_tokens_to_string = token.convert_tokens_to_string(answer_tokens)

    # Display results
    print("\nDistilBERT question answering example.")
    print("======================================")
    print("Reading from: ", subject, source)
    print("\nContext: ", context)
    print("--")
    print("Question: ", question)
    print("Answer: ", answer_tokens_to_string)
    print("Reference Answers: ", answer)


if __name__ == "__main__":
    main()
