//
// Copyright © 2018 Arm Ltd. All rights reserved.
// See LICENSE file in the project root for full license information.
//

#include <iostream>
#include <string>
#include <fstream>
#include <vector>
#include <memory>
#include <array>
#include <algorithm>
#include <cstring>
#include "armnn/ArmNN.hpp"
#include "armnn/Exceptions.hpp"
#include "armnn/Tensor.hpp"
#include "armnn/INetwork.hpp"
#include "armnnTfLiteParser/ITfLiteParser.hpp"

#include "mnist_loader.hpp"

#define MAX_IMAGES 3000 

// Helper function to make input tensors
armnn::InputTensors MakeInputTensors(const std::pair<armnn::LayerBindingId,
    armnn::TensorInfo>& input,
    const void* inputTensorData)
{
    return { { input.first, armnn::ConstTensor(input.second, inputTensorData) } };
}

// Helper function to make output tensors
armnn::OutputTensors MakeOutputTensors(const std::pair<armnn::LayerBindingId,
    armnn::TensorInfo>& output,
    void* outputTensorData)
{
    return { { output.first, armnn::Tensor(output.second, outputTensorData) } };
}

int main(int argc, char** argv)
{
    // Default input size is one image
    unsigned int nrOfImages = 1;

    // Optimisation mode 0 = CPU Reference (unoptimised)
    // Optimisation mode 1 = CPU Accelerator
    // Optimisation mode 2 = GPU Accelerator
    unsigned int optimisationMode = 1;

    // Check program arguments
    if (argc != 3)
    {
      std::cout << "Invalid arguments. Exactly 2 arguments required." << std::endl;
      std::cout << "Example: ./mnist_tf 1 10" << std::endl;
      std::cout << "Optimisation modes: 0 for CpuRef, 1 for CpuAcc, 2 for GpuAcc" << std::endl;
      std::cout << "Input size: 1 to 2000 (number of images to predict)" << std::endl;
      return 1;
    }

    // Parse input size option
    nrOfImages = std::stoi(argv[2]);
    if (!(nrOfImages > 0 && nrOfImages <= MAX_IMAGES))
    {
      std::cout << "Error: Maximum number of images is " << MAX_IMAGES << std::endl;
      return 1;
    }

    // Parse optimisation mode option
    optimisationMode = std::stoi(argv[1]);
    if (!(optimisationMode == 0 || optimisationMode == 1 || optimisationMode == 2))
    {
      std::cout << "Invalid optimisation mode." << std::endl;
      return 1;
    }

    // Import the TensorFlow model. Note: use CreateNetworkFromBinaryFile for .pb files.
    armnnTfLiteParser::ITfLiteParserPtr parser = armnnTfLiteParser::ITfLiteParser::Create();
    armnn::INetworkPtr network = parser->CreateNetworkFromBinaryFile("model/simple_mnist.tflite")

    // Create ArmNN runtime
    armnn::IRuntime::CreationOptions options; // default options
    options.m_ProfilingOptions.m_EnableProfiling = true;
    options.m_ProfilingOptions.m_TimelineEnabled = true;
    armnn::IRuntimePtr runtime = armnn::IRuntime::Create(options);

    // Optimize the network for a specific runtime compute device, e.g. CpuAcc, GpuAcc
    std::cout << "Optimisation mode: ";
    armnn::Compute device;
    switch(optimisationMode)
    {
      case 0: device = armnn::Compute::CpuRef; std::cout << "CpuRef" << std::endl; break;
      case 1: device = armnn::Compute::CpuAcc; std::cout << "CpuAcc" << std::endl; break;
      case 2: device = armnn::Compute::GpuAcc; std::cout << "GpuAcc" << std::endl; break;
    }

    armnn::IOptimizedNetworkPtr optNet = Optimize(*network, {device}, runtime->GetDeviceSpec());

    // Load the optimized network onto the runtime device
    armnn::NetworkId networkIdentifier;
    runtime->LoadNetwork(networkIdentifier, std::move(optNet));


    // Find the binding points for the input and output nodes
    std::vector<std::string> inputNames = parser->GetSubgraphInputTensorNames(0);
    auto inputBindingInfo = parser->GetNetworkInputBindingInfo(0, inputNames[0]);

    std::vector<std::string> outputNames = parser->GetSubgraphOutputTensorNames(0);
    auto outputBindingInfo = parser->GetNetworkOutputBindingInfo(0, outputNames[0]);

    // Load multiple images from the data directory
    std::string dataDir = "data/";

    auto labels = new int[nrOfImages];

    int nrOfCorrectPredictions = 0;
    for (int i = 0; i < nrOfImages; ++i)
    {
        auto input = new float[g_kMnistImageByteSize];
        auto output = new float[10];
        std::unique_ptr<MnistImage> imgInfo = loadMnistImage(dataDir, i);
        if (imgInfo == nullptr)
            return 1;

        std::memcpy(input, imgInfo->image, sizeof(imgInfo->image));
        labels[i] = imgInfo->label;
        //Execute network
        armnn::InputTensors inputTensor = MakeInputTensors(inputBindingInfo, &input[0]);
        armnn::OutputTensors outputTensor = MakeOutputTensors(outputBindingInfo, &output[0]);

        armnn::Status ret = runtime->EnqueueWorkload(networkIdentifier, inputTensor, outputTensor);

        float max = output[0];
        int label = 0;

        for (int j = 0; j < 10; ++j)
        {
            //Translate 1-hot output to find integer label
            if (output[j] > max)
            {
                max = output[j];
                label = j;
            }
        }
        if (label == labels[i]) nrOfCorrectPredictions++;
        std::cout << "#" << i + 1 << " | Predicted: " << label << " Actual: " << labels[i] << std::endl;

        delete[] input;
        delete[] output;
    }
    std::cout << "Prediction accuracy: " << (float)nrOfCorrectPredictions / nrOfImages * 100 << "%";
    std::cout << std::endl;

    delete[] labels;

    return 0;
}
