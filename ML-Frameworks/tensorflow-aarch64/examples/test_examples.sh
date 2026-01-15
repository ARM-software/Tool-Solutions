#!/bin/bash -e

# SPDX-FileCopyrightText: Copyright 2025 Arm Limited and affiliates.
#
# SPDX-License-Identifier: Apache-2.0

# Runs examples from README.md by looking for lines that start with python, this
# doesn't catch everything but it's a good first approximation.
# Filters out example "python answer_questions.py -t <context> -q <question>"  as well.
# Store all examples in an array of strings (rather than all in a single string)
# so that the `for` loop iterates over lines (examples) rather than words. See
# https://unix.stackexchange.com/questions/412638 for more information
readarray -t examples < <( grep -E '^python' README.md | grep -v '<context>')
for example in "${examples[@]}"; do
    echo "Running: $example"
    bash -c "$example"
    echo ""
done
