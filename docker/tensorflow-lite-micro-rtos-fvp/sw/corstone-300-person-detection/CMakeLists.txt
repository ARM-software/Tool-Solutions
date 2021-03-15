#
# Copyright (c) 2021 Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the License); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an AS IS BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#############################################################################
# Default parameters
#############################################################################

set(TARGET_CPU "cortex-m55")

if (NOT CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/../../ethos-u/core_platform/cmake/toolchain/armclang.cmake")
endif()

set(ETHOSU_COMMAND_DEFAULT ${CMAKE_CURRENT_SOURCE_DIR}/../../ethos-u/core_platform/scripts/run_ctest.py -t corstone-300)

#############################################################################
# Project
#############################################################################

cmake_minimum_required(VERSION 3.15.6)

project(corstone-300-person-detection VERSION 0.0.1)

#############################################################################
# Corstone-300
#############################################################################

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../../ethos-u/core_platform/targets/corstone-300" corstone-300)


###############################################################################
# Applications
###############################################################################

# Exclude this app if freertos target does not exist
if (NOT TARGET freertos_kernel)
    message("Skipping FreeRTOS application")
    return()
endif()

FILE(GLOB CPP_SOURCES *.cpp)

ethosu_add_executable(ethosu55-person-detection PRIVATE
    SOURCES 
        ${CPP_SOURCES}
    LIBRARIES 
        freertos_kernel
    )
add_dependencies(ethosu55-person-detection cmsis_startup)
add_dependencies(ethosu55-person-detection ethosu_core_driver)

# Use the fast memory to support both 11.12.57 and 11.13.x release
# of the FVP
# The size is defined to force the .bss.NoInit to be placed in DDR
target_compile_definitions(
    ethosu55-person-detection PRIVATE 
    ETHOSU_FAST_MEMORY_SIZE=0xa0000)
