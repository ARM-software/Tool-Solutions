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
#include "UseCaseHandler.hpp"

#include "Classifier.hpp"
#include "InputFiles.hpp"
#include "PersonDetectionModel.hpp"
#include "UseCaseCommonUtils.hpp"
#include "hal.h"

using ImgClassClassifier = arm::app::Classifier;

namespace arm {
namespace app {

    /**
    * @brief           Helper function to load the current image into the input
    *                  tensor.
    * @param[in]       imIdx         Image index (from the pool of images available
    *                                to the application).
    * @param[out]      inputTensor   Pointer to the input tensor to be populated.
    * @return          true if tensor is loaded, false otherwise.
    **/
    static bool _LoadImageIntoTensor(uint32_t imIdx, TfLiteTensor* inputTensor);

    /**
     * @brief           Helper function to increment current image index.
     * @param[in,out]   ctx   Pointer to the application context object.
     **/
    static void _IncrementAppCtxImageIdx(ApplicationContext& ctx);

    /**
     * @brief           Helper function to set the image index.
     * @param[in,out]   ctx   Pointer to the application context object.
     * @param[in]       idx   Value to be set.
     * @return          true if index is set, false otherwise.
     **/
    static bool _SetAppCtxImageIdx(ApplicationContext& ctx, uint32_t idx);

    /**
     * @brief           Presents inference results using the data presentation
     *                  object.
     * @param[in]       platform    Reference to the hal platform object.
     * @param[in]       results     Vector of classification results to be displayed.
     * @param[in]       infTimeMs   Inference time in milliseconds, if available
     *                              otherwise, this can be passed in as 0.
     * @return          true if successful, false otherwise.
     **/
    static bool _PresentInferenceResult(hal_platform& platform,
                                        const std::vector<ClassificationResult>& results);

    /**
     * @brief           Helper function to convert a UINT8 image to INT8 format.
     * @param[in,out]   data            Pointer to the data start.
     * @param[in]       kMaxImageSize   Total number of pixels in the image.
     **/
    static void ConvertImgToInt8(void* data, size_t kMaxImageSize);

    /* Image inference classification handler. */
    bool ClassifyImageHandler(ApplicationContext& ctx, uint32_t imgIndex, bool runAll)
    {
        auto& platform = ctx.Get<hal_platform&>("platform");

        constexpr uint32_t dataPsnImgDownscaleFactor = 2;
        constexpr uint32_t dataPsnImgStartX = 10;
        constexpr uint32_t dataPsnImgStartY = 35;

        constexpr uint32_t dataPsnTxtInfStartX = 150;
        constexpr uint32_t dataPsnTxtInfStartY = 40;

        platform.data_psn->clear(COLOR_BLACK);

        auto& model = ctx.Get<Model&>("model");

        /* If the request has a valid size, set the image index. */
        if (imgIndex < NUMBER_OF_FILES) {
            if (!_SetAppCtxImageIdx(ctx, imgIndex)) {
                return false;
            }
        }
        if (!model.IsInited()) {
            printf_err("Model is not initialised! Terminating processing.\n");
            return false;
        }

        auto curImIdx = ctx.Get<uint32_t>("imgIndex");

        TfLiteTensor* outputTensor = model.GetOutputTensor(0);
        TfLiteTensor* inputTensor = model.GetInputTensor(0);

        if (!inputTensor->dims) {
            printf_err("Invalid input tensor dims\n");
            return false;
        } else if (inputTensor->dims->size < 3) {
            printf_err("Input tensor dimension should be >= 3\n");
            return false;
        }

        TfLiteIntArray* inputShape = model.GetInputShape(0);

        const uint32_t nCols = inputShape->data[arm::app::PersonDetectionModel::ms_inputColsIdx];
        const uint32_t nRows = inputShape->data[arm::app::PersonDetectionModel::ms_inputRowsIdx];
        const uint32_t nChannels = inputShape->data[arm::app::PersonDetectionModel::ms_inputChannelsIdx];

        std::vector<ClassificationResult> results;

        do {
            /* Strings for presentation/logging. */
            std::string str_inf{"Running inference... "};

            /* Copy over the data. */
            _LoadImageIntoTensor(ctx.Get<uint32_t>("imgIndex"), inputTensor);

            /* Display this image on the LCD. */
            platform.data_psn->present_data_image(
                (uint8_t*) inputTensor->data.data,
                nCols, nRows, nChannels,
                dataPsnImgStartX, dataPsnImgStartY, dataPsnImgDownscaleFactor);

            /* If the data is signed. */
            if (model.IsDataSigned()) {
                ConvertImgToInt8(inputTensor->data.data, inputTensor->bytes);
            }

            /* Display message on the LCD - inference running. */
            platform.data_psn->present_data_text(str_inf.c_str(), str_inf.size(),
                                    dataPsnTxtInfStartX, dataPsnTxtInfStartY, 0);

            /* Run inference over this image. */
            info("Running inference on image %u => %s\n", ctx.Get<uint32_t>("imgIndex"),
                get_filename(ctx.Get<uint32_t>("imgIndex")));

            RunInference(platform, model);

            /* Erase. */
            str_inf = std::string(str_inf.size(), ' ');
            platform.data_psn->present_data_text(str_inf.c_str(), str_inf.size(),
                                    dataPsnTxtInfStartX, dataPsnTxtInfStartY, 0);

            auto& classifier = ctx.Get<ImgClassClassifier&>("classifier");
            classifier.GetClassificationResults(outputTensor, results,
                                                ctx.Get<std::vector <std::string>&>("labels"),
                                                2);

            /* Add results to context for access outside handler. */
            ctx.Set<std::vector<ClassificationResult>>("results", results);

#if VERIFY_TEST_OUTPUT
            arm::app::DumpTensor(outputTensor);
#endif /* VERIFY_TEST_OUTPUT */

            if (!_PresentInferenceResult(platform, results)) {
                return false;
            }

            _IncrementAppCtxImageIdx(ctx);

        } while (runAll && ctx.Get<uint32_t>("imgIndex") != curImIdx);

        return true;
    }

    static bool _LoadImageIntoTensor(const uint32_t imIdx, TfLiteTensor* inputTensor)
    {
        const size_t copySz = inputTensor->bytes < IMAGE_DATA_SIZE ?
                              inputTensor->bytes : IMAGE_DATA_SIZE;
        const uint8_t* imgSrc = get_img_array(imIdx);
        if (nullptr == imgSrc) {
            printf_err("Failed to get image index %u (max: %u)\n", imIdx,
                       NUMBER_OF_FILES - 1);
            return false;
        }

        memcpy(inputTensor->data.data, imgSrc, copySz);
        debug("Image %u loaded\n", imIdx);
        return true;
    }

    static void _IncrementAppCtxImageIdx(ApplicationContext& ctx)
    {
        auto curImIdx = ctx.Get<uint32_t>("imgIndex");

        if (curImIdx + 1 >= NUMBER_OF_FILES) {
            ctx.Set<uint32_t>("imgIndex", 0);
            return;
        }
        ++curImIdx;
        ctx.Set<uint32_t>("imgIndex", curImIdx);
    }

    static bool _SetAppCtxImageIdx(ApplicationContext& ctx, const uint32_t idx)
    {
        if (idx >= NUMBER_OF_FILES) {
            printf_err("Invalid idx %u (expected less than %u)\n",
                       idx, NUMBER_OF_FILES);
            return false;
        }
        ctx.Set<uint32_t>("imgIndex", idx);
        return true;
    }

    static bool _PresentInferenceResult(hal_platform& platform,
                                        const std::vector<ClassificationResult>& results)
    {
        constexpr uint32_t dataPsnTxtStartX1 = 150;
        constexpr uint32_t dataPsnTxtStartY1 = 30;

        constexpr uint32_t dataPsnTxtStartX2 = 10;
        constexpr uint32_t dataPsnTxtStartY2 = 150;

        constexpr uint32_t dataPsnTxtYIncr = 16;  /* Row index increment. */

        platform.data_psn->set_text_color(COLOR_GREEN);

        /* Display each result. */
        uint32_t rowIdx1 = dataPsnTxtStartY1 + 2 * dataPsnTxtYIncr;
        uint32_t rowIdx2 = dataPsnTxtStartY2;

        for (uint32_t i = 0; i < results.size(); ++i) {
            std::string resultStr =
                std::to_string(i + 1) + ") " +
                std::to_string(results[i].m_labelIdx) +
                " (" + std::to_string(results[i].m_normalisedVal) + ")";

            platform.data_psn->present_data_text(
                                        resultStr.c_str(), resultStr.size(),
                                        dataPsnTxtStartX1, rowIdx1, 0);
            rowIdx1 += dataPsnTxtYIncr;

            resultStr = std::to_string(i + 1) + ") " + results[i].m_label;
            platform.data_psn->present_data_text(
                                        resultStr.c_str(), resultStr.size(),
                                        dataPsnTxtStartX2, rowIdx2, 0);
            rowIdx2 += dataPsnTxtYIncr;

            info("%u) %u (%f) -> %s\n", i, results[i].m_labelIdx,
                 results[i].m_normalisedVal, results[i].m_label.c_str());
        }

        return true;
    }

    static void ConvertImgToInt8(void* data, const size_t kMaxImageSize)
    {
        auto* tmp_req_data = (uint8_t*) data;
        auto* tmp_signed_req_data = (int8_t*) data;

        for (size_t i = 0; i < kMaxImageSize; i++) {
            tmp_signed_req_data[i] = (int8_t) (
                (int32_t) (tmp_req_data[i]) - 128);
        }
    }

} /* namespace app */
} /* namespace arm */
