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

  // Parse commandline parameters
  if (argc != 5) {
    LOG(ERROR) << "Required arguments: -m <yaml_path> and -i <image_path>\n";
    exit(EXIT_FAILURE);
  }

  char *arg_m = NULL;
  char *arg_i = NULL;
  int c;

  opterr = 0;

  while ((c = getopt(argc, argv, "m:i:")) != -1)
    switch (c) {
    case 'm':
      arg_m = optarg;
      break;
    case 'i':
      arg_i = optarg;
      break;
    default:
      exit(EXIT_FAILURE);
    }

  // Parse YAML file
  YAML::Node config = YAML::LoadFile(arg_m);

  // Paths for the model, image and labels files
  std::string model_path = utils::get_yaml_model(config);
  std::string labels_path = utils::get_yaml_labels(config);

  // Expected input size
  int img_h = utils::get_yaml_img_h(config);
  int img_w = utils::get_yaml_img_w(config);

  // Input and output node names
  std::string input_node_ = utils::get_yaml_input(config);
  auto output_nodes_ = utils::get_yaml_output(config);

  // Read model into graph
  tf::GraphDef graph_def;
  tf::Status status;
  status = ReadBinaryProto(tf::Env::Default(), model_path, &graph_def);
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
      utils::read_image_into_tensor(arg_i, img_h, img_w, &resized_tensors);
  if (!read_tensor_status.ok()) {
    LOG(ERROR) << read_tensor_status;
    exit(EXIT_FAILURE);
  }
  const tf::Tensor &input_tensor = resized_tensors[0];

  // Run graph
  const string input_node = input_node_;
  std::vector<string> output_nodes = output_nodes_;

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
  std::vector<string> labels = utils::get_labels(labels_path);

  // Unpack the outputs and print top 5 labels
  int count_labels = 5;
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
