/*
 * Copyright (c) 2020-2021 Arm Limited. All rights reserved.
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

#include "FreeRTOS.h"
#include "queue.h"
#include "semphr.h"
#include "task.h"

#include <inttypes.h>
#include <stdio.h>
#include <vector>

#include "inference_process.hpp"

// model and input
#include "images.hpp"
#include "model.hpp"

using namespace std;
using namespace InferenceProcess;

/****************************************************************************
 * Defines
 ****************************************************************************/

// Nr. of tasks to process inferences with. Task reserves driver & runs inference (Normally 1 per NPU, but not a must)
#define NUM_INFERENCE_TASKS 1
// Nr. of tasks to create jobs and recieve responses
#define NUM_JOB_TASKS 1
// Nr. of jobs to create per job task
#define NUM_JOBS_PER_TASK 1

// Tensor arena size
#ifdef TENSOR_ARENA_SIZE // If defined in model.h
#define TENSOR_ARENA_SIZE_PER_INFERENCE TENSOR_ARENA_SIZE
#else // If not defined, use maximum available
#define TENSOR_ARENA_SIZE_PER_INFERENCE 2000000 / NUM_INFERENCE_TASKS
#endif

/****************************************************************************
 * InferenceJob
 ****************************************************************************/

struct ProcessTaskParams {
    ProcessTaskParams() {}
    ProcessTaskParams(QueueHandle_t _queue, uint8_t *_tensorArena, size_t _arenaSize) :
        queueHandle(_queue), tensorArena(_tensorArena), arenaSize(_arenaSize) {}

    QueueHandle_t queueHandle;
    uint8_t *tensorArena;
    size_t arenaSize;
};

// Number of total completed jobs, needed to exit application correctly if NUM_JOB_TASKS > 1
static int totalCompletedJobs = 0;

// TensorArena static initialisation
static const size_t arenaSize = TENSOR_ARENA_SIZE_PER_INFERENCE;
__attribute__((section(".bss.tensor_arena"), aligned(16)))
uint8_t inferenceProcessTensorArena[NUM_INFERENCE_TASKS][arenaSize];

// Wrapper around InferenceProcess::InferenceJob. Adds responseQueue and status for FreeRTOS multi-tasking purposes.
struct xInferenceJob : public InferenceJob {
    QueueHandle_t responseQueue;
    bool status;

    xInferenceJob() : InferenceJob(), responseQueue(nullptr), status(false) {}
    xInferenceJob(const string &_name,
                  const DataPtr &_networkModel,
                  const vector<DataPtr> &_input,
                  const vector<DataPtr> &_output,
                  const vector<DataPtr> &_expectedOutput,
                  const size_t _numBytesToPrint,
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
        responseQueue(_queue), status(false) {}
};

/****************************************************************************
 * Mutex & Semaphore
 * Overrides weak-linked symbols in ethosu_driver.c to implement thread handling
 ****************************************************************************/

extern "C" {

void *ethosu_mutex_create(void) {
    return xSemaphoreCreateMutex();
}

void ethosu_mutex_lock(void *mutex) {
    SemaphoreHandle_t handle = reinterpret_cast<SemaphoreHandle_t>(mutex);
    xSemaphoreTake(handle, portMAX_DELAY);
}

void ethosu_mutex_unlock(void *mutex) {
    SemaphoreHandle_t handle = reinterpret_cast<SemaphoreHandle_t>(mutex);
    xSemaphoreGive(handle);
}

void *ethosu_semaphore_create(void) {
    return xSemaphoreCreateBinary();
}

void ethosu_semaphore_take(void *sem) {
    SemaphoreHandle_t handle = reinterpret_cast<SemaphoreHandle_t>(sem);
    xSemaphoreTake(handle, portMAX_DELAY);
}

void ethosu_semaphore_give(void *sem) {
    SemaphoreHandle_t handle = reinterpret_cast<SemaphoreHandle_t>(sem);
    xSemaphoreGive(handle);
}
}

/****************************************************************************
 * Functions
 ****************************************************************************/

uint8_t inferenceResult[NUM_JOBS_PER_TASK][3] __attribute__((section("output_data_sec"), aligned(4)));

void printResults(const char* name, uint32_t taskID)
{
    float no_person_confidence = (float)(inferenceResult[taskID][2] / 255.0f);
    float person_confidence = (float)(inferenceResult[taskID][1] / 255.0f);

    printf("\n");
    printf("#-------------------\n");
    printf ("\tInput image name: \"%s\"\n", name);
    printf("\tNo Person Confidence = %f | Person Confidence = %f\n",
        (double)no_person_confidence, (double)person_confidence);

    if(no_person_confidence >= person_confidence)
    {
        printf("\tDetected NO PERSON in the input image \n\tConfidence = %f\n",
            (double)no_person_confidence);
    }
    else
    {
        printf("\tDetected A PERSON in the input image\n\tConfidence = %f\n",
            (double)person_confidence);
    }
    printf("#-----------------------------\n\n");
}


//  inferenceProcessTask - Run jobs from queue with available driver
void inferenceProcessTask(void *pvParameters) {
    ProcessTaskParams params = *reinterpret_cast<ProcessTaskParams *>(pvParameters);

    class InferenceProcess inferenceProcess(params.tensorArena, params.arenaSize);

    for (;;) {
        xInferenceJob *xJob;

        xQueueReceive(params.queueHandle, &xJob, portMAX_DELAY);
        bool status  = inferenceProcess.runJob(*xJob);
        xJob->status = status;
        xQueueSend(xJob->responseQueue, &xJob, portMAX_DELAY);
    }
    vTaskDelete(nullptr);
}

//  inferenceSenderTask - Creates NUM_INFERNECE_JOBS jobs, queues them, and then listens for completion status
void inferenceSenderTask(void *pvParameters) {
    int ret = 0;

    QueueHandle_t inferenceProcessQueue = reinterpret_cast<QueueHandle_t>(pvParameters);
    // Create queue for response messages
    QueueHandle_t senderQueue = xQueueCreate(NUM_JOBS_PER_TASK, sizeof(xInferenceJob *));

    for (unsigned int i = 0; i < NUMBER_OF_IMAGES; i++) {
        xInferenceJob jobs[NUM_JOBS_PER_TASK];
        for (unsigned int n = 0; n < NUM_JOBS_PER_TASK; n++) {
            xInferenceJob *job = &jobs[n];
            job->name         = get_image_name(i);
            job->networkModel = DataPtr((uint8_t*)get_model_pointer(), get_model_len());
            job->input.push_back(DataPtr((uint8_t*)get_image_pointer(i), get_image_len(i)));
            job->output.push_back(DataPtr(inferenceResult[i], sizeof(inferenceResult[i])));
            job->responseQueue = senderQueue;

            // Send job
            printf("Sending inference job: job=%p, name=%s\n", job, job->name.c_str());
            xQueueSend(inferenceProcessQueue, &job, portMAX_DELAY);
        }

        // Listen for completion status
        do {
            xInferenceJob *pSendJob;
            xQueueReceive(senderQueue, &pSendJob, portMAX_DELAY);
            printf("inferenceSenderTask: received response for job: %s, status = %u\n",
                pSendJob->name.c_str(),
                pSendJob->status);

            printResults(get_image_name(i), totalCompletedJobs);

            totalCompletedJobs++;
            ret = (pSendJob->status);
            if (pSendJob->status != 0) {
                break;
            }
        } while (totalCompletedJobs < NUM_JOBS_PER_TASK * NUM_JOB_TASKS);
    }
    vQueueDelete(senderQueue);

    printf("FreeRTOS application returning %d.\n", ret);
    exit(ret);
}

/****************************************************************************
 * Application
 ****************************************************************************/

// Declare variables in global scope to avoid stack since FreeRTOS resets stack when the scheduler is started
static QueueHandle_t inferenceProcessQueue;
static ProcessTaskParams taskParams[NUM_INFERENCE_TASKS];

// FreeRTOS application. NOTE: Additional tasks may require increased heap size.
int main() {
    BaseType_t ret;
    inferenceProcessQueue = xQueueCreate(NUM_JOBS_PER_TASK, sizeof(xInferenceJob *));

    // inferenceSender tasks to create and queue the jobs
    for (int n = 0; n < NUM_JOB_TASKS; n++) {
        ret = xTaskCreate(inferenceSenderTask, "inferenceSenderTask", 2 * 1024, inferenceProcessQueue, 2, nullptr);
        if (ret != pdPASS) {
            printf("FreeRTOS: Failed to create 'inferenceSenderTask%i'\n", n);
            exit(1);
        }
    }

    // Create inferenceProcess tasks to process the queued jobs
    for (int n = 0; n < NUM_INFERENCE_TASKS; n++) {
        taskParams[n] = ProcessTaskParams(inferenceProcessQueue, inferenceProcessTensorArena[n], arenaSize);
        ret           = xTaskCreate(inferenceProcessTask, "inferenceProcessTask", 3 * 1024, &taskParams[n], 3, nullptr);
        if (ret != pdPASS) {
            printf("FreeRTOS: Failed to create 'inferenceProcessTask%i'\n", n);
            exit(1);
        }
    }

    // Start Scheduler
    vTaskStartScheduler();

    printf("FreeRTOS application failed to initialise \n");
    exit(1);

    return 0;
}
