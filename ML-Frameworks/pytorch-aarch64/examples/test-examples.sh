#!/bin/bash -e

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

# Runs examples from README.md by looking for lines that start with python, this
# doesn't catch everything but it's a good first approximation.
# Store all examples in an array of strings (rather than all in a single string)
# so that the `for` loop iterates over lines (examples) rather than words. See
# https://unix.stackexchange.com/questions/412638 for more information
readarray -t examples < <( grep -E '^python' README.md )
for example in "${examples[@]}"; do
    echo "Running: $example"
    bash -c "$example"
    echo ""
done
