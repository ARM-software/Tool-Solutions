//
// Copyright © 2018 Arm Ltd. All rights reserved.
// See LICENSE file in the project root for full license information.
//

#pragma once

#include <sstream>
#include <string>

constexpr int g_kMnistImageByteSize = 28 * 28;

// Helper struct for loading MNIST data
struct MnistImage
{
    unsigned int label;
    float image[g_kMnistImageByteSize];
};

// Load a single MNIST image from a simple text file
std::unique_ptr<MnistImage> loadMnistImage(std::string dataFile)
{
    std::vector<unsigned char> I(g_kMnistImageByteSize);
    float x;
    unsigned int label = 0;
    int i = 0;

    std::ifstream myfile (dataFile);

    std::unique_ptr<MnistImage> ret(new MnistImage);
    ret->label = label;

    for (std::string fline; std::getline(myfile, fline); i++ )
    {
        std::istringstream in(fline); 
        in >> x;
        ret->image[i] = x;
    }

    return ret;
}
