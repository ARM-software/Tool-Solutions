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
#include "armnnTfParser/ITfParser.hpp"

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
    armnnTfParser::ITfParserPtr parser = armnnTfParser::ITfParser::Create();
    armnn::INetworkPtr network = parser->CreateNetworkFromBinaryFile("model/convol_mnist_tf.pb",
                                                                   { {"input_tensor", {nrOfImages, 784, 1, 1}} },
                                                                   { "fc2/output_tensor" });

    // Find the binding points for the input and output nodes
    armnnTfParser::BindingPointInfo inputBindingInfo = parser->GetNetworkInputBindingInfo("input_tensor");
    armnnTfParser::BindingPointInfo outputBindingInfo = parser->GetNetworkOutputBindingInfo("fc2/output_tensor");

    // Create ArmNN runtime
    armnn::IRuntime::CreationOptions options; // default options
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

    // Load multiple images from the data directory
    std::string dataDir = "data/";

    auto input = new float[nrOfImages][g_kMnistImageByteSize];
    auto output = new float[nrOfImages][10];
    auto labels = new int[nrOfImages];

    for (int i = 0; i < nrOfImages; ++i)
    {
      std::unique_ptr<MnistImage> imgInfo = loadMnistImage(dataDir, i);
      if (imgInfo == nullptr)
          return 1;

      std::memcpy(input[i], imgInfo->image, sizeof(imgInfo->image));
      labels[i] = imgInfo->label;
    }

    // Execute network
    armnn::InputTensors inputTensor = MakeInputTensors(inputBindingInfo, &input[0]);
    armnn::OutputTensors outputTensor = MakeOutputTensors(outputBindingInfo, &output[0]);

    armnn::Status ret = runtime->EnqueueWorkload(networkIdentifier, inputTensor, outputTensor);

    // Check output and compute correct predictions
    int nrOfCorrectPredictions = 0;
    for (int i = 0; i < nrOfImages; ++i)
    {
      float max = output[i][0];
      int label = 0;

      for (int j = 0; j < 10; ++j)
      {
        // Translate 1-hot output to find integer label
        if (output[i][j] > max)
        {
          max = output[i][j];
          label = j;
        }
      }
      if (label == labels[i]) nrOfCorrectPredictions++;
      std::cout << "#" << i+1 << " | Predicted: " << label << " Actual: " << labels[i] << std::endl;
    }
    std::cout << "Prediction accuracy: " << (float)nrOfCorrectPredictions/nrOfImages*100 << "%";
    std::cout << std::endl;

    delete[] input;
    delete[] output;
    delete[] labels;
 
    return 0;
}
