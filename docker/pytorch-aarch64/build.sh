#!/bin/bash

# *******************************************************************************
# Copyright 2024 Arm Limited and affiliates.
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

set -eux -o pipefail

# Bail out if sources are already there
if ! [[ $* == *--force* ]] && ([ -d pytorch ] || [ -d builder ] || [ -d ComputeLibrary ]) ; then
    echo "You appear to have sources already (pytorch/builder/ComputeLibrary), rerun with --force to overrite sources or run ./build-wheel.sh if you want to build your existing sources."
    exit 1
fi

./get-source.sh

./build-wheel.sh
