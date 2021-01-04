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
set(CMAKE_C_COMPILER "armclang")
set(CMAKE_CXX_COMPILER "armclang")
set(CMAKE_SYSTEM_PROCESSOR "cortex-m33+nodsp" CACHE STRING "Select Cortex-M architure. (cortex-m0, cortex-m3, cortex-m33, cortex-m4, cortex-m55, cortex-m7, etc)")

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
set(__CPU_LINK_TARGET ${CMAKE_SYSTEM_PROCESSOR})
if("nodsp" IN_LIST __CPU_FEATURES)
    string(APPEND __CPU_LINK_TARGET ".no_dsp")
endif()
if("nofp" IN_LIST __CPU_FEATURES)
    string(APPEND __CPU_LINK_TARGET ".no_fp")
endif()

if(CMAKE_SYSTEM_PROCESSOR STREQUAL "cortex-m55")
    set(__CPU_LINK_TARGET 8.1-M.Main.dsp)
endif()

add_link_options(--cpu=${__CPU_LINK_TARGET})
add_link_options(--lto --info common,debug,sizes,totals,veneers,unused --symbols --diag_suppress=L6439W)

#
# Compile options
#

add_compile_options(-Wall -Wextra
                    -Wsign-compare -Wunused -Wswitch-default -Wformat -Wdouble-promotion -Wredundant-decls -Wshadow -Wcast-align -Wnull-dereference
                    -Wno-format-extra-args -Wno-unused-function -Wno-unused-label -Wno-missing-field-initializers -Wno-return-type)
add_compile_options(-fno-unwind-tables -fno-rtti -fno-exceptions)
add_compile_options(-mthumb)
add_compile_options("$<$<CONFIG:DEBUG>:-gdwarf-3>")
