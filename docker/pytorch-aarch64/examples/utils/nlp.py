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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************

import sys
import os
import json
import urllib.request
import pandas


def import_squad_data():
    """
    Downloads the SQuAD dev-v2 dataset and organises it into a more
    convenient pandas dataframe.
    See https://rajpurkar.github.io/SQuAD-explorer/
    for more details on SQuAD.
    """

    squad_url = (
        "https://rajpurkar.github.io/SQuAD-explorer/dataset/dev-v2.0.json"
    )
    squad_file = squad_url.split("/")[-1]  # last part of URL

    urllib.request.urlretrieve(squad_url, squad_file)

    if not os.path.isfile(squad_file):
        sys.exit("Dataset %s does not exist!" % squad_file)

    with open(squad_file) as squad_file_handle:
        squad_data = json.load(squad_file_handle)["data"]

        title_list = []
        ident_list = []
        context_list = []
        question_list = []
        impossible_list = []
        answer_start_list = []
        answer_text_list = []

        # 'data' contains title and paragraph list
        for it_art in squad_data:
            title = it_art["title"]

            # 'paragraphs' contains context (the copy) and Q&A sets
            for it_par in it_art["paragraphs"]:
                context = it_par["context"]

                # 'qas' contains questions and reference answers
                for it_que in it_par["qas"]:
                    question = it_que["question"]
                    impossible = it_que["is_impossible"]
                    ident = it_que["id"]

                    # 'answers' contains the answer text and location in 'context'
                    for it_ans in it_que["answers"]:
                        answer_start = it_ans["answer_start"]
                        text = it_ans["text"]

                        # set an empty answer for an impossible question
                        if impossible:
                            text = ""

                        # add details of this answer to the list
                        title_list.append(title)
                        ident_list.append(ident)
                        context_list.append(context)
                        question_list.append(question)
                        impossible_list.append(impossible)
                        answer_start_list.append(answer_start)
                        answer_text_list.append(text)

        squad_data_final = pandas.DataFrame(
            {
                "id": ident_list,
                "subject": title_list,
                "context": context_list,
                "question": question_list,
                "impossible": impossible_list,
                "answer_start": answer_start_list,
                "answer": answer_text_list,
            }
        )

    return squad_data_final.drop_duplicates(keep="first")


def print_squad_questions(subject=None):
    """
    Prints all the SQuAD entries for a given subject.
    """

    squad_data = import_squad_data()

    if subject:
        if subject == "all":
            squad_records = squad_data
        else:
            squad_records = squad_data.loc[squad_data["subject"] == subject]
            if squad_records.empty:
                print("Subject not found in SQuAD dev-v2.0 dataset.")
                return
    else:
        print(squad_data["subject"].unique())
        print(
            "Please specify a subject from the list above, or choose 'all', e.g. print_squad_questions(nlp.import_squad_data(), subject='Normans'"
        )
        return

    for index, row in squad_records.iterrows():
        print("\n=============================")
        print("Id: ", row["id"])
        print("Reading from: ", row["subject"])
        print("\nContext: ", row["context"])
        print("--")
        print("Question: ", row["question"])
        print("Answer: ", row["answer"])
