# *****************************************************************************$
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
# *****************************************************************************$

# This script was built following the approach detailed in:
# https://pytorch.org/tutorials/beginner/text_sentiment_ngrams_tutorial.html

import torch
from torch import nn
from torch.utils.data import DataLoader
from torch.utils.data.dataset import random_split
from torchtext.vocab import build_vocab_from_iterator
from torchtext.datasets import AG_NEWS
from torchtext.data.utils import get_tokenizer
from torchtext.data.functional import to_map_style_dataset
from TextClassificationModel import TextClassificationModel
from pathlib import Path
import time
import sys


# Hyperparameters
EPOCHS = 10  # epoch
LR = 5  # learning rate
BATCH_SIZE = 64  # batch size for training


# Yields a list of tokens from iterator of input data
def yield_tokens(data_iter, tokenizer):
    for _, text in data_iter:
        yield tokenizer(text)


# Trains the model
def train(dataloader, model, optimizer, criterion, epoch):
    model.train()
    total_acc, total_count = 0, 0
    log_interval = 500
    start_time = time.time()

    for idx, (label, text, offsets) in enumerate(dataloader):
        optimizer.zero_grad()
        predicted_label = model(text, offsets)
        loss = criterion(predicted_label, label)
        loss.backward()
        torch.nn.utils.clip_grad_norm_(model.parameters(), 0.1)
        optimizer.step()
        total_acc += (predicted_label.argmax(1) == label).sum().item()
        total_count += label.size(0)
        if idx % log_interval == 0 and idx > 0:
            elapsed = time.time() - start_time
            print('| epoch {:3d} | {:5d}/{:5d} batches '
                '| accuracy {:8.3f}'.format(epoch, idx, len(dataloader),
                                            total_acc/total_count))
            total_acc, total_count = 0, 0
            start_time = time.time()


# Evaluates test accuracy of model
def evaluate(dataloader, model, criterion):
    model.eval()
    total_acc, total_count = 0, 0

    with torch.no_grad():
        for idx, (label, text, offsets) in enumerate(dataloader):
            predicted_label = model(text, offsets)
            loss = criterion(predicted_label, label)
            total_acc += (predicted_label.argmax(1) == label).sum().item()
            total_count += label.size(0)
    return total_acc/total_count


# Predicts article type of test article
def predict(text, text_pipeline, model):
    with torch.no_grad():
        text = torch.tensor(text_pipeline(text))
        output = model(text, torch.tensor([0]))
        return output.argmax(1).item() + 1


def main():

    num_args = len(sys.argv)

    # Checking if filename input is specified
    if num_args < 2:
        sys.exit("Please specify an input file")

    filename = str(sys.argv[1])
    p = Path(filename)

    # Checking if filepath is valid and/or file exists
    if not (p.exists()):
        sys.exit("File not found")

    # Prepare data processing pipelines
    tokenizer = get_tokenizer('basic_english')
    train_iter = AG_NEWS(split='train')

    vocab = build_vocab_from_iterator(yield_tokens(train_iter, tokenizer),
        specials=["<unk>"])
    vocab.set_default_index(vocab["<unk>"])

    text_pipeline = lambda x: vocab(tokenizer(x))
    label_pipeline = lambda x: int(x) - 1

    # Generate data batch and iterator
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    def collate_batch(batch):
        label_list, text_list, offsets = [], [], [0]
        for (_label, _text) in batch:
            label_list.append(label_pipeline(_label))
            processed_text = torch.tensor(text_pipeline(_text),
                dtype=torch.int64)
            text_list.append(processed_text)
            offsets.append(processed_text.size(0))
        label_list = torch.tensor(label_list, dtype=torch.int64)
        offsets = torch.tensor(offsets[:-1]).cumsum(dim=0)
        text_list = torch.cat(text_list)
        return label_list.to(device), text_list.to(device), offsets.to(device)

    # This variable needs to be initialized twice or else an IndexError occurs
    train_iter = AG_NEWS(split='train')
    dataloader = DataLoader(train_iter, batch_size=8, shuffle=False,
        collate_fn=collate_batch)

    # Build an instance
    num_class = len(set([label for (label, text) in train_iter]))
    vocab_size = len(vocab)
    emsize = 64
    model = TextClassificationModel(vocab_size, emsize, num_class).to(device)

    # Split the dataset and run the model
    criterion = torch.nn.CrossEntropyLoss()
    optimizer = torch.optim.SGD(model.parameters(), lr=LR)
    scheduler = torch.optim.lr_scheduler.StepLR(optimizer, 1.0, gamma=0.1)
    total_accu = None
    train_iter, test_iter = AG_NEWS()
    train_dataset = to_map_style_dataset(train_iter)
    test_dataset = to_map_style_dataset(test_iter)
    num_train = int(len(train_dataset) * 0.95)
    split_train_, split_valid_ = \
        random_split(train_dataset,
        [num_train, len(train_dataset) - num_train])

    train_dataloader = DataLoader(split_train_, batch_size=BATCH_SIZE,
                                shuffle=True, collate_fn=collate_batch)
    valid_dataloader = DataLoader(split_valid_, batch_size=BATCH_SIZE,
                                shuffle=True, collate_fn=collate_batch)
    test_dataloader = DataLoader(test_dataset, batch_size=BATCH_SIZE,
                                shuffle=True, collate_fn=collate_batch)

    # Run epochs
    for epoch in range(1, EPOCHS + 1):
        epoch_start_time = time.time()
        train(train_dataloader, model, optimizer, criterion, epoch)
        accu_val = evaluate(valid_dataloader, model, criterion)
        if total_accu is not None and total_accu > accu_val:
            scheduler.step()
        else:
            total_accu = accu_val
        print('-' * 59)
        print('| end of epoch {:3d} | time: {:5.2f}s | '
            'valid accuracy {:8.3f} '.format(epoch,
                                            time.time() - epoch_start_time,
                                            accu_val))
        print('-' * 59)

    print('Checking the results of test dataset.')
    accu_test = evaluate(test_dataloader, model, criterion)
    print('test accuracy {:8.3f}'.format(accu_test))

    # Run article prediction
    ag_news_label = {1: "World",
                    2: "Sports",
                    3: "Business",
                    4: "Sci/Tec"}

    with p.open() as readfile:
        ex_text_str = readfile.read()

    model = model.to("cpu")

    print("This is a %s news" % ag_news_label[predict(ex_text_str,
        text_pipeline, model)])


if __name__ == '__main__':
    main()

