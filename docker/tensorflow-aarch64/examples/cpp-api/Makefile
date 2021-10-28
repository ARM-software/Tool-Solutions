# ******************************************************************************
# Copyright 2021 Arm Ltd. and affiliates.
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
# ******************************************************************************

ssd_resnet50_url = http://download.tensorflow.org/models/object_detection/tf2/20200711/ssd_resnet50_v1_fpn_640x640_coco17_tpu-8.tar.gz
resnet50_url = https://tfhub.dev/tensorflow/resnet_50/classification/1\?tf-hub-format\=compressed
inception_url = https://storage.googleapis.com/download.tensorflow.org/models/inception_v3_2016_08_28_frozen.pb.tar.gz

cows_img_url = https://images.reference.com/amg-cms-reference-images/media/habitat-cow_9291b3a902721a26.jpg?width=740&height=420&fit=crop&format=pjpg
guineapig_img_url = https://upload.wikimedia.org/wikipedia/commons/6/6a/Guinea_Pigs.jpg

coco_labels_url = https://raw.githubusercontent.com/amikelive/coco-labels/master/coco-labels-paper.txt
imagenet_labels_url = https://storage.googleapis.com/download.tensorflow.org/data/ImageNetLabels.txt

TF_INCLUDE_DIR = /home/ubuntu/python3-venv/tensorflow/include
TF_LIB_DIR     = /home/ubuntu/python3-venv/tensorflow/lib
CV_INCLUDE_DIR = /opt/opencv/install/include/opencv4
CV_LIB_DIR     = /opt/opencv/install/lib
YAML_INCLUDE_DIR = /opt/yaml-cpp/include
YAML_LIB_DIR     = /opt/yaml-cpp/build

CC=g++
CFLAGS=-std=c++14 -Wno-deprecated-declarations
LDFLAGS=-Wl,-rpath,$(TF_LIB_DIR):$(CV_LIB_DIR)

all : detect_objects classify_image inception_inference

detect_objects: models images labels
	$(CC) $(CFLAGS) $(LDFLAGS) detect_objects.cc common.hpp \
	  $(YAML_LIB_DIR)/libyaml-cpp.a -o detect_objects \
	  -I $(TF_INCLUDE_DIR) -L $(TF_LIB_DIR) \
	  -I $(CV_INCLUDE_DIR) -L $(CV_LIB_DIR) \
	  -I $(YAML_INCLUDE_DIR) \
	  -ltensorflow_cc -ltensorflow_framework \
	  -lopencv_core -lopencv_imgcodecs -lopencv_imgproc

classify_image: models images labels
	$(CC) $(CFLAGS) $(LDFLAGS) classify_image.cc common.hpp \
	  $(YAML_LIB_DIR)/libyaml-cpp.a -o classify_image \
	  -I $(TF_INCLUDE_DIR) -L $(TF_LIB_DIR) \
	  -I $(YAML_INCLUDE_DIR) \
	  -ltensorflow_cc -ltensorflow_framework

inception_inference: models images labels
	$(CC) $(CFLAGS) $(LDFLAGS) inception_inference.cc common.hpp \
	  $(YAML_LIB_DIR)/libyaml-cpp.a -o inception_inference \
	  -I $(TF_INCLUDE_DIR) -L $(TF_LIB_DIR) \
	  -I $(YAML_INCLUDE_DIR) \
	  -ltensorflow_cc -ltensorflow_framework

models:
	mkdir -p models && mkdir -p models/resnet50
	wget -O "ssd_resnet50.tar.gz" $(ssd_resnet50_url) && \
	    tar -xzvf "ssd_resnet50.tar.gz" -C models/ && \
	    rm "ssd_resnet50.tar.gz"
	wget -O "resnet50.tar.gz" $(resnet50_url) && \
	    tar -xzvf "resnet50.tar.gz" -C models/resnet50 && \
	    rm "resnet50.tar.gz"
	wget -O "inception.tar.gz" $(inception_url) && \
	    tar -xzvf inception.tar.gz -C models/ && \
	    rm "inception.tar.gz"

images:
	mkdir -p images
	wget -O "images/cows.jpeg" $(cows_img_url)
	wget -O "images/guineapig.jpeg" $(guineapig_img_url)

labels:
	mkdir -p labels
	wget -O "labels/coco-labels.txt" $(coco_labels_url)
	wget -O "labels/imagenet-labels.txt" $(imagenet_labels_url)

clean:
	rm -rf classify_image detect_objects inception_inference \
	       images models labels output_image.jpg
