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

#include <opencv2/imgcodecs.hpp>
#include <opencv2/imgproc.hpp>

#include "common.hpp"

int main(int argc, char **argv) {

  string arg_model_path =
      "models/ssd_resnet50_v1_fpn_640x640_coco17_tpu-8/saved_model";
  string arg_image_path = "images/cows.jpeg";
  string arg_label_path = "labels/coco-labels.txt";

  // Load model in SavedModel format
  tf::SessionOptions session_options;
  tf::RunOptions run_options;
  tf::SavedModelBundle bundle; // i.e. a loaded SavedModel in a Session

  auto status = tf::LoadSavedModel(session_options, run_options, arg_model_path,
                                   {"serve"}, &bundle);

  if (!status.ok()) {
    LOG(ERROR) << status.ToString();
    exit(EXIT_FAILURE);
  }

  // Load image using OpenCV
  cv::Mat image = cv::imread(arg_image_path);
  if (!image.data) {
    LOG(ERROR) << "ERROR: cannot load image";
    exit(EXIT_FAILURE);
  }

  // Image dimensions
  int height = image.rows;
  int width = image.cols;
  int channels = image.channels();

  // Create input tensor
  tf::Tensor input_tensor(tf::DT_UINT8,
                          tf::TensorShape({1, height, width, channels}));

  // A trick to fill in the tensor data with the image loaded via OpenCV
  // Get pointer to input tensor's data
  uint8_t *image_data = input_tensor.flat<uint8_t>().data();
  // Attach data pointer to a new cv::Mat placeholder
  cv::Mat input_image(height, width, CV_8UC3, image_data);
  // Use the placeholder as a destination for image conversion
  image.convertTo(input_image, CV_8U);

  // Create new Tensorflow session and prepare the run configuration
  tf::Scope root = tf::Scope::NewRootScope();
  tf::ClientSession session(root);

  const string input_node = "serving_default_input_tensor:0";
  std::vector<string> output_nodes = {{
      "StatefulPartitionedCall:0", // detection_anchor_indices
      "StatefulPartitionedCall:1", // detection_boxes
      "StatefulPartitionedCall:2", // detection_classes
      "StatefulPartitionedCall:3", // detection_multiclass_scores
      "StatefulPartitionedCall:4", // detection_scores
      "StatefulPartitionedCall:5"  // num_detections
  }};

  std::vector<std::pair<string, tf::Tensor>> input_feed = {
      {input_node, input_tensor}};
  std::vector<tf::Tensor> predictions;

  // inputs: pair of input node and input values to be fed to the graph
  // output_nodes: nodes to evaluate
  // predictions: tensors resulted from evaluation the output_nodes
  tf::Status s =
      bundle.GetSession()->Run(input_feed, output_nodes, {}, &predictions);

  if (!s.ok()) {
    LOG(ERROR) << s.ToString();
    exit(EXIT_FAILURE);
  }

  // Post-processing and read labels
  std::vector<string> labels = utils::get_labels(arg_label_path);

  // Unpack the outputs
  auto predicted_boxes = predictions[1].tensor<float, 3>();
  auto predicted_scores = predictions[4].tensor<float, 2>();
  auto predicted_labels = predictions[2].tensor<float, 2>();

  std::vector<std::vector<float>> out_pred_boxes;
  std::vector<float> out_pred_scores;
  std::vector<int> out_pred_labels;

  const float confidence_threshold = 0.7;
  for (int i = 0; i < 100; i++) {
    std::vector<float> coords;
    for (int j = 0; j < 4; j++) {
      coords.push_back(predicted_boxes(0, i, j));
    }
    out_pred_boxes.push_back(coords);
    out_pred_scores.push_back(predicted_scores(0, i));
    out_pred_labels.push_back(predicted_labels(0, i));
  }

  // For each detected object
  for (int i = 0; i < out_pred_boxes.size(); i++) {
    auto box = out_pred_boxes[i];
    auto score = out_pred_scores[i];
    auto label = out_pred_labels[i];

    if (score < confidence_threshold) {
      LOG(INFO) << "DONE: confidence dropped below threshold of "
                << confidence_threshold * 100 << "%";
      break;
    }

    LOG(INFO) << "OBJECT DETECTED #" << i + 1 << ": " << labels[label - 1]
              << " (label " << label << "), "
              << "confidence " << score * 100 << "%";

    // Draw red rectangle around the object
    int ymin = (int)(box[0] * height);
    int xmin = (int)(box[1] * width);
    int h = (int)(box[2] * height) - ymin;
    int w = (int)(box[3] * width) - xmin;
    cv::Rect rect = cv::Rect(xmin, ymin, w, h);
    cv::rectangle(image, rect, cv::Scalar(0, 0, 255), 2);
  }

  cv::imwrite("./output_image.jpg", image);

  return 0;
}
