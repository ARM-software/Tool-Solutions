/*
 * Copyright (c) 2020 Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/****************************************************************************
 * Includes
 ****************************************************************************/

// FreeRTOS
#include "FreeRTOS.h"
#include "queue.h"
#include "task.h"

// Ethos-U
#include "ethosu_driver.h"
#include "inference_process.hpp"

// model and input
#include "model.hpp"
#include "images.hpp"

// System includes
#include <stdio.h>

using namespace std;
using namespace InferenceProcess;

/****************************************************************************
 * InferenceJob
 ****************************************************************************/

#ifndef TENSOR_ARENA_SIZE
#define TENSOR_ARENA_SIZE 0xa0000
#endif

__attribute__((section(".bss.NoInit"), aligned(16))) uint8_t inferenceProcessTensorArena[TENSOR_ARENA_SIZE];


namespace {

struct xInferenceJob : public InferenceJob {
    QueueHandle_t queue;
    bool status;

    xInferenceJob();
    xInferenceJob(const string &name,
                  const DataPtr &networkModel,
                  const vector<DataPtr> &input,
                  const vector<DataPtr> &output,
                  const vector<DataPtr> &expectedOutput,
                  size_t numBytesToPrint,
                  const vector<uint8_t> &pmuEventConfig,
                  const uint32_t pmuCycleCounterEnable,
                  QueueHandle_t queue);
};

xInferenceJob::xInferenceJob() : InferenceJob(), queue(nullptr), status(false) {}

xInferenceJob::xInferenceJob(const std::string &_name,
                             const DataPtr &_networkModel,
                             const std::vector<DataPtr> &_input,
                             const std::vector<DataPtr> &_output,
                             const std::vector<DataPtr> &_expectedOutput,
                             size_t _numBytesToPrint,
                             const vector<uint8_t> &_pmuEventConfig,
                             const uint32_t _pmuCycleCounterEnable,
                             QueueHandle_t _queue) :
    InferenceJob(_name,
                 _networkModel,
                 _input,
                 _output,
                 _expectedOutput,
                 _numBytesToPrint,
                 _pmuEventConfig,
                 _pmuCycleCounterEnable),
    queue(_queue), status(false) {}

} // namespace

/****************************************************************************
 * Functions
 ****************************************************************************/

namespace {

uint8_t inferenceResult[3];

void printResults(const char* name)
{
    float no_person_confidence = (float)(inferenceResult[2] / 255.0f);
    float person_confidence = (float)(inferenceResult[1] / 255.0f);

    printf("\n#-----------------------------\n");
    printf ("Input image name: \"%s\"\n", name);
    printf("  No Person Confidence = %f | Person Confidence = %f\n",
        (double)no_person_confidence, (double)person_confidence);

    if(no_person_confidence >= person_confidence)
    {
        printf("  Detected NO PERSON in the input image \n  Confidence = %f\n",
            (double)no_person_confidence);
    }
    else
    {
        printf("  Detected A PERSON in the input image\n  Confidence = %f\n",
            (double)person_confidence);
    }
    printf("#-----------------------------\n\n");
}

void inferenceProcessTask(void *pvParameters) {
    QueueHandle_t queue = reinterpret_cast<QueueHandle_t>(pvParameters);

    class InferenceProcess inferenceProcess(inferenceProcessTensorArena, TENSOR_ARENA_SIZE);

    while (true) {
        xInferenceJob *job;

        // Wait for inference job
        xQueueReceive(queue, &job, portMAX_DELAY);
        printf("Received inference job. job=%p, name=%s\n", job, job->name.c_str());

        bool status = inferenceProcess.runJob(*job);
        job->status = status;

        // Return inference job response
        xQueueSend(job->queue, &job, portMAX_DELAY);
    }

    vTaskDelete(NULL);
}

void inferenceJobTask(void *pvParameters) {
    QueueHandle_t inferenceProcessQueue = reinterpret_cast<QueueHandle_t>(pvParameters);

    // Create queue for response messages
    QueueHandle_t senderQueue = xQueueCreate(10, sizeof(xInferenceJob *));

    // Inference job
    DataPtr networkModel((uint8_t*)get_model_pointer(), get_model_len());
    
    for(int i = 0; i < NUMBER_OF_IMAGES; i ++)
    {
        xInferenceJob job;
        xInferenceJob *j = &job;
        job.name         = get_image_name(i);
        job.networkModel = networkModel;
        job.output.push_back(DataPtr(inferenceResult, sizeof(inferenceResult)));
        job.input.push_back(DataPtr((uint8_t*)get_image_pointer(i), get_image_len(i)));
        job.queue = senderQueue;

        // Send job
        printf("Sending inference job\n");
        xQueueSend(inferenceProcessQueue, &j, portMAX_DELAY);

        // Wait for response
        xQueueReceive(senderQueue, &j, portMAX_DELAY);
        printf("Received inference job response. status=%u\n", j->status);
        
        printResults(get_image_name(i));
    }

    exit(0);
}

} // namespace

/* Keep the queue ouf of the stack sinde freertos resets it when the scheduler starts.*/
QueueHandle_t inferenceProcessQueue;

int main() {
    // Inference process
    inferenceProcessQueue = xQueueCreate(10, sizeof(xInferenceJob *));
    xTaskCreate(inferenceProcessTask, "inferenceProcess", 2 * 1024, inferenceProcessQueue, 1, nullptr);

    // Inference job task
    xTaskCreate(inferenceJobTask, "inferenceJob", 2 * 1024, inferenceProcessQueue, 2, nullptr);

    // Run the scheduler
    vTaskStartScheduler();

    return 0;
}
