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

# Use the fast memory to support both 11.12.57 and 11.13.x release
# of the FVP
# The size is defined to force the .bss.NoInit to be placed in DDR
target_compile_definitions(
    ethosu55-person-detection PRIVATE ETHOSU_FAST_MEMORY_SIZE=0xa0000)

install(TARGETS ethosu55-person-detection
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
