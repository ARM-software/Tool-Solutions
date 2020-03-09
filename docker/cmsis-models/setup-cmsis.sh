#!/bin/bash

git clone https://github.com/ARM-software/CMSIS_5.git
cp configPlatform.cmake CMSIS_5/CMSIS/DSP
cp -r Platforms/IPSS CMSIS_5/CMSIS/DSP/Platforms
cp cmake_M7F.sh CMSIS_5/CMSIS/DSP/Testing
cp cmake_M55.sh CMSIS_5/CMSIS/DSP/Testing
