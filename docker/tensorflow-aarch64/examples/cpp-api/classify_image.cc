/*******************************************************************************
 * Copyright 2021 Arm Ltd. and affiliates.
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

#include "common.hpp"

int main(int argc, char **argv) {

  // Paths for the model, image and labels files
  string arg_model_path = "models/resnet50";
  string arg_image_path = "images/guineapig.jpeg";
  string arg_label_path = "labels/imagenet-labels.txt";

  // Load model in SavedModel format
  tf::SessionOptions session_options;
  tf::RunOptions run_options;
  tf::SavedModelBundle bundle; // i.e. a loaded SavedModel in a Session

  auto status_load_model = tf::LoadSavedModel(
      session_options, run_options, arg_model_path, {"serve"}, &bundle);

  if (!status_load_model.ok()) {
    LOG(ERROR) << status_load_model.ToString();
    exit(EXIT_FAILURE);
  }

  // Load image and preprocess
  std::vector<tf::Tensor> processed_image_tensors;
  tf::Status status_read_image = utils::read_image_into_tensor(
      arg_image_path, 224, 224, &processed_image_tensors);

  if (!status_read_image.ok()) {
    LOG(ERROR) << status_read_image.ToString();
    exit(EXIT_FAILURE);
  }

  const tf::Tensor &input_tensor = processed_image_tensors[0];

  // Create new Tensorflow session and prepare the run configuration
  tf::Scope root = tf::Scope::NewRootScope();
  tf::ClientSession session(root);

  const string input_node = "serving_default_input_1";
  std::vector<string> output_nodes = {{"StatefulPartitionedCall:0"}};

  std::vector<std::pair<string, tf::Tensor>> input_feed = {
      {input_node, input_tensor}};
  std::vector<tf::Tensor> predictions;

  // inputs: pair of input node and input values to be fed to the graph
  // output_nodes: nodes to evaluate
  // predictions: tensors resulted from evaluation the output_nodes
  tf::Status session_run_status =
      bundle.GetSession()->Run(input_feed, output_nodes, {}, &predictions);

  if (!session_run_status.ok()) {
    LOG(ERROR) << session_run_status.ToString();
    exit(EXIT_FAILURE);
  }

  // Read labels
  std::vector<string> labels = utils::get_labels(arg_label_path);

  // Unpack the outputs and print top 3 labels
  int count_labels = 3;
  tf::Tensor indices_tensor;
  tf::Tensor scores_tensor;

  utils::get_top_labels(predictions, count_labels, &indices_tensor,
                        &scores_tensor);

  auto scores = scores_tensor.flat<float>();
  auto indices = indices_tensor.flat<tf::int32>();
  for (int pos = 0; pos < count_labels; ++pos) {
    const int label_index = indices(pos);
    const float score = scores(pos);
    utils::print_prediction(score, label_index + 1, labels[label_index + 1]);
  }

  return 0;
}
