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
  string arg_model_path = "models/inception_v3_2016_08_28_frozen.pb";
  string arg_image_path = "images/guineapig.jpeg";
  string arg_label_path = "labels/imagenet_slim_labels.txt";

  // Read model into graph
  tf::GraphDef graph_def;
  tf::Status status;
  status = ReadBinaryProto(tf::Env::Default(), arg_model_path, &graph_def);
  if (!status.ok()) {
    LOG(ERROR) << status.ToString();
    exit(EXIT_FAILURE);
  }

  // Create session and attach graph
  tf::SessionOptions session_options;
  tf::Session *session;

  status = NewSession(session_options, &session);
  if (!status.ok()) {
    LOG(ERROR) << status.ToString();
    exit(EXIT_FAILURE);
  }
  status = session->Create(graph_def);
  if (!status.ok()) {
    LOG(ERROR) << status.ToString();
    exit(EXIT_FAILURE);
  }
  // utils::print_graph_nodes(graph_def);

  // Load image and preprocess
  std::vector<tf::Tensor> resized_tensors;
  tf::Status read_tensor_status =
      utils::read_image_into_tensor(arg_image_path, 299, 299, &resized_tensors);
  if (!read_tensor_status.ok()) {
    LOG(ERROR) << read_tensor_status;
    exit(EXIT_FAILURE);
  }
  const tf::Tensor &input_tensor = resized_tensors[0];

  // Run graph
  const string input_node = "input";
  std::vector<string> output_nodes = {{
      "InceptionV3/Predictions/Reshape_1", // only node we want to evaluate
  }};

  std::vector<std::pair<string, tf::Tensor>> inputs = {
      {input_node, input_tensor}};
  std::vector<tf::Tensor> predictions;

  // inputs: pair of input node and input values to be fed to the graph
  // output_nodes: nodes to evaluate
  // predictions: tensors resulted from evaluation the output_nodes
  tf::Status s = session->Run(inputs, output_nodes, {}, &predictions);
  if (!s.ok()) {
    LOG(ERROR) << s.ToString().c_str();
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
    utils::print_prediction(score, label_index, labels[label_index]);
  }

  return 0;
}
