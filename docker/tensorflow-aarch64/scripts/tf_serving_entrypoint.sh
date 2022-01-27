#!/usr/bin/env bash

# *******************************************************************************
# Copyright 2022 Arm Limited and affiliates.
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

# This script provides the entrypoint to serve a TF model supplied from outside
# Docker process.
#
# To run a simple test model...
#   1. Checkout TF serving:
#      `git clone https://github.com/tensorflow/serving`
#   2. Locate demo model to use:
#      TESTDATA="$(pwd)/serving/tensorflow_serving/servables/tensorflow/testdata"
#   3. Start TensorFlow Serving container:
#      - The REST API port (8501) needs to be open.
#      - This example uses the 'half_plus_two' model.
#      - The saved model is mounted inside the Docker image in the models
#         directory inside the default user's home:
#      ```
#      docker run -t --rm -p 8501:8501 \
#       -v "$TESTDATA/saved_model_half_plus_two_cpu:/home/ubuntu/models/half_plus_two" \
#       -e MODEL_NAME=half_plus_two tensorflow-serving-v2acl &
#      ```
#   4. Query the model using the predict API
#      ```
#      curl -d '{"instances": [1.0, 2.0, 5.0]}' \
#        -X POST http://localhost:8501/v1/models/half_plus_two:predict`
#      ```
#      This example should return: `{ "predictions": [2.5, 3.0, 4.5] }`

./tensorflow_model_server \
  --port=8500 \ # gRPC port
  --rest_api_port=8501 \ # REST API port
  --model_name=${MODEL_NAME} \ # MODEL_NAME supplied via `docker run`
  --model_base_path=${MODEL_BASE_PATH}/${MODEL_NAME} \ # Location of model mounted within the container
  "$@"
