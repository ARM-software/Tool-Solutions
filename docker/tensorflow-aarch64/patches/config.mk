# *******************************************************************************
# Copyright 2020 Arm Limited and affiliates.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *******************************************************************************


HOST_CC = /usr/bin/gcc-7
HOST_CFLAGS = -std=c99 -O2
HOST_CFLAGS += -Wall -Wno-unused-function

CC = /usr/bin/gcc-7
CFLAGS = -std=c99 -pipe -O3
CFLAGS += -Wall -Wno-missing-braces
CFLAGS += -Werror=implicit-function-declaration

HOST_CFLAGS += -g
CFLAGS += -g

CFLAGS += -frounding-math -fexcess-precision=standard -fno-stack-protector
CFLAGS += -ffp-contract=fast -fno-math-errno
