#
# Copyright (c) 2019-2020 Arm Limited. All rights reserved.
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

if (__TOOLCHAIN_LOADED)
    return()
endif()
set(__TOOLCHAIN_LOADED TRUE)

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_C_COMPILER "arm-none-eabi-gcc")
set(CMAKE_CXX_COMPILER "arm-none-eabi-g++")
set(CMAKE_SYSTEM_PROCESSOR "cortex-m33+nodsp" CACHE STRING "Select Cortex-M architure. (cortex-m0, cortex-m3, cortex-m33, cortex-m4, cortex-m55, cortex-m7, etc)")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_C_STANDARD 99)
set(CMAKE_CXX_STANDARD 11)

# The system processor could for example be set to cortex-m33+nodsp+nofp.
set(__CPU_COMPILE_TARGET ${CMAKE_SYSTEM_PROCESSOR})
string(REPLACE "+" ";" __CPU_FEATURES ${__CPU_COMPILE_TARGET})
list(POP_FRONT __CPU_FEATURES CMAKE_SYSTEM_PROCESSOR)

string(FIND ${__CPU_COMPILE_TARGET} "+" __OFFSET)
if(__OFFSET GREATER_EQUAL 0)
    string(SUBSTRING ${__CPU_COMPILE_TARGET} ${__OFFSET} -1 CPU_FEATURES)
endif()

# Add -mcpu to the compile options to override the -mcpu the CMake toolchain adds
add_compile_options(-mcpu=${__CPU_COMPILE_TARGET})

# Link target
add_link_options(-mcpu=${__CPU_COMPILE_TARGET})
add_link_options(-Xlinker -Map=output.map)

#
# Compile options
#
set(cxx_flags "-fno-unwind-tables;-fno-rtti;-fno-exceptions")

add_compile_options("-Wall;-Wextra;-Wsign-compare;-Wunused;-Wswitch-default;-Wformat;\
-Wdouble-promotion;-Wredundant-decls;-Wshadow;-Wcast-align;-Wnull-dereference;\
-Wno-format-extra-args;-Wno-unused-function;-Wno-unused-label;\
-Wno-missing-field-initializers;-Wno-return-type"
    "$<$<COMPILE_LANGUAGE:CXX>:${cxx_flags}>"
)
