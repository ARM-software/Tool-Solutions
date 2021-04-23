#----------------------------------------------------------------------------
#  Copyright (c) 2021 Arm Limited. All rights reserved.
#  SPDX-License-Identifier: Apache-2.0
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#----------------------------------------------------------------------------

# If the path to a directory or source file has been defined,
# get the type here (FILEPATH or PATH):
if (DEFINED ${use_case}_FILE_PATH)
    get_path_type(${${use_case}_FILE_PATH} PATH_TYPE)
    # Set the default type if path is not a dir or file path (or undefined)
    if (NOT ${PATH_TYPE} STREQUAL PATH AND NOT ${PATH_TYPE} STREQUAL FILEPATH)
        message(FATAL_ERROR "Invalid ${use_case}_FILE_PATH. It should be a dir or file path.")
    endif()
else()
    # Default is a directory path
    set(PATH_TYPE PATH)
endif()

message(STATUS "${use_case}_FILE_PATH is of type: ${PATH_TYPE}")

USER_OPTION(${use_case}_FILE_PATH "Directory with custom image files to use, or path to a single image, in the evaluation application"
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/${use_case}/samples/
    ${PATH_TYPE})

USER_OPTION(${use_case}_IMAGE_SIZE "Square image size in pixels. Images will be resized to this size."
    96
    STRING)

USER_OPTION(${use_case}_LABELS_TXT_FILE "Labels' txt file for the chosen model"
    ${CMAKE_CURRENT_SOURCE_DIR}/resources/${use_case}/labels/labels_person_detection.txt
    FILEPATH)

# Generate input files
generate_images_code("${${use_case}_FILE_PATH}"
                     ${SRC_GEN_DIR}
                     ${INC_GEN_DIR}
                     "${${use_case}_IMAGE_SIZE}"
                     1)

# Generate labels file
set(${use_case}_LABELS_CPP_FILE Labels)
generate_labels_code(
    INPUT           "${${use_case}_LABELS_TXT_FILE}"
    DESTINATION_SRC ${SRC_GEN_DIR}
    DESTINATION_HDR ${INC_GEN_DIR}
    OUTPUT_FILENAME "${${use_case}_LABELS_CPP_FILE}"
)

USER_OPTION(${use_case}_ACTIVATION_BUF_SZ "Activation buffer size for the chosen model"
    0x00200000
    STRING)

# If there is no tflite file pointed to
# we can't build this usecase (not available in the model zoo.)
# upload model with use_case example?
if (NOT DEFINED ${use_case}_MODEL_TFLITE_PATH)
    set(DEFAULT_MODEL_PATH  ${CMAKE_CURRENT_SOURCE_DIR}/resources/${use_case}/models/person_detection.tflite)
else()
    set(DEFAULT_MODEL_PATH  "N/A")
endif()

USER_OPTION(${use_case}_MODEL_TFLITE_PATH "NN models file to be used in the evaluation application. Model files must be in tflite format."
    ${DEFAULT_MODEL_PATH}
    FILEPATH
    )

# Generate model file
generate_tflite_code(
    MODEL_PATH ${${use_case}_MODEL_TFLITE_PATH}
    DESTINATION ${SRC_GEN_DIR}
    )
