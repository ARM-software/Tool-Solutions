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

#include <fstream>
#include <string>
#include <vector>

#include "yaml-cpp/yaml.h"

#include "tensorflow/cc/client/client_session.h"
#include "tensorflow/cc/ops/const_op.h"
#include "tensorflow/cc/ops/image_ops.h"
#include "tensorflow/cc/ops/standard_ops.h"
#include "tensorflow/cc/saved_model/loader.h"

namespace tf = tensorflow;
using tensorflow::string;

namespace utils {

// Load the labels in a given file into a standard vector
std::vector<std::string> get_labels(std::string filename) {
  std::ifstream file(filename);
  std::vector<std::string> labels;
  if (file.is_open()) {
    std::string line;
    while (std::getline(file, line)) {
      labels.push_back(line);
    }
    file.close();
  } else {
    fprintf(stderr, ">>> ERROR: cannot read labels file.\n");
  }
  return labels;
}

// Print graph nodes
void print_graph_nodes(tf::GraphDef &graph_def) {
  int node_count = graph_def.node_size();
  for (int i = 0; i < node_count; i++) {
    auto n = graph_def.node(i);
    std::cout << ">>> Name : " << n.name() << std::endl;
  }
}

// Print prediction
void print_prediction(float score, int label_index, std::string label_name) {
  printf(">> Prediction confidence %6.3f - %s (label %d)\n", score * 100,
         label_name.c_str(), label_index);
}

// Get the image from disk as a float array of numbers, resized and normalized
tf::Status read_image_into_tensor(const std::string &filename, tf::int32 img_w,
                                  tf::int32 img_h,
                                  std::vector<tf::Tensor> *out_tensors) {

  string output_name = "normalized";
  tf::Scope root = tf::Scope::NewRootScope();
  auto file_reader =
      tf::ops::ReadFile(root.WithOpName("file_reader"), filename);

  const int wanted_channels = 3;
  tf::Output image_reader =
      tf::ops::DecodeJpeg(root.WithOpName("file_decoder"), file_reader,
                          tf::ops::DecodeJpeg::Channels(wanted_channels));

  auto float_caster = tf::ops::Cast(root.WithOpName("float_caster"),
                                    image_reader, tf::DT_FLOAT);
  auto image_expander =
      tf::ops::ExpandDims(root.WithOpName("expand_dims"), float_caster, 0);

  float input_mean = 0;
  float input_std = 255;

  // Resize to graph expectation
  auto resized = tf::ops::ResizeBilinear(
      root, image_expander,
      tf::ops::Const(root.WithOpName("size"), {img_w, img_h}));
  // Normalize pixel value: subtract the mean and divide by the scale
  tf::ops::Div(root.WithOpName(output_name),
               tf::ops::Sub(root, resized, {input_mean}), {input_std});

  // Run the graph we just constructed and return the outputs
  tf::GraphDef graph;
  TF_RETURN_IF_ERROR(root.ToGraphDef(&graph));

  std::unique_ptr<tf::Session> session(tf::NewSession(tf::SessionOptions()));
  TF_RETURN_IF_ERROR(session->Create(graph));
  TF_RETURN_IF_ERROR(session->Run({}, {output_name}, {}, out_tensors));
  return tf::Status::OK();
}

// Get the top predictions: score and label
tf::Status get_top_labels(const std::vector<tf::Tensor> &outputs, int count,
                          tf::Tensor *indices, tf::Tensor *scores) {

  auto root = tf::Scope::NewRootScope();

  std::string output_name = "top_k";
  tf::ops::TopK(root.WithOpName(output_name), outputs[0], count);

  tf::GraphDef graph;
  root.ToGraphDef(&graph);

  std::unique_ptr<tf::Session> session(tf::NewSession(tf::SessionOptions()));
  session->Create(graph);

  // :0 to specify scores
  // :1 to specify indices
  std::vector<tf::Tensor> out_tensors;
  auto status = session->Run({}, {output_name + ":0", output_name + ":1"}, {},
                             &out_tensors);
  *scores = out_tensors[0];
  *indices = out_tensors[1];
  return tf::Status::OK();
}

// Returns the relative model path as a string
std::string get_yaml_model(YAML::Node config) {
  return config["model"][0]["source"].as<std::string>();
}

// Returns the relative labels path as a string
std::string get_yaml_labels(YAML::Node config) {
  return config["model"][0]["labels"].as<std::string>();
}

// Returns the image width
int get_yaml_img_w(YAML::Node config) {
  return config["arguments"][0]["input_shape"][1].as<int>();
}

// Returns the image height
int get_yaml_img_h(YAML::Node config) {
  return config["arguments"][0]["input_shape"][2].as<int>();
}

// Returns the input node name
std::string get_yaml_input(YAML::Node config) {
  return config["arguments"][0]["input"].as<std::string>();
}

// Returns the output node names in a vector of strings
std::vector<std::string> get_yaml_output(YAML::Node config) {
  auto output = config["arguments"][0]["output"];
  std::vector<string> output_nodes_;
  for (int i = 0; i < output.size(); i++)
    output_nodes_.push_back(output[i].as<string>());

  return output_nodes_;
}

// Returns the confidence threshold as a float
float get_yaml_threshold(YAML::Node config) {
  return config["model"][0]["threshold"].as<float>();
}

} // namespace utils
