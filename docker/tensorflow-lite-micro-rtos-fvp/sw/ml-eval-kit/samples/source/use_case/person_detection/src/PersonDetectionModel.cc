/*
 * Copyright (c) 2021 Arm Limited. All rights reserved.
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
 */
#include "PersonDetectionModel.hpp"

#include "hal.h"

const tflite::MicroOpResolver& arm::app::PersonDetectionModel::GetOpResolver()
{
    return this->_m_opResolver;
}

bool arm::app::PersonDetectionModel::EnlistOperations()
{
    this->_m_opResolver.AddAveragePool2D();
    this->_m_opResolver.AddConv2D();
    this->_m_opResolver.AddDepthwiseConv2D();

#if defined(ARM_NPU)
    if (kTfLiteOk == this->_m_opResolver.AddEthosU()) {
        info("Added %s support to op resolver\n",
            tflite::GetString_ETHOSU());
    } else {
        printf_err("Failed to add Arm NPU support to op resolver.");
        return false;
    }
#endif /* ARM_NPU */
    return true;
}

extern uint8_t* GetModelPointer();
const uint8_t* arm::app::PersonDetectionModel::ModelPointer()
{
    return GetModelPointer();
}

extern size_t GetModelLen();
size_t arm::app::PersonDetectionModel::ModelSize()
{
    return GetModelLen();
}