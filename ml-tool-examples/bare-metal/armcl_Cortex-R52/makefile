# Copyright (c) 2007-2018 Arm Limited (or its affiliates). All rights reserved.
# Use, modification and redistribution of this file is subject to your possession of a
# valid End User License Agreement for the Arm Product of which these examples are part of 
# and your compliance with all applicable terms and conditions of such licence agreement.
#
# This example is intended to be built with Linaro bare-metal GCC
#
# Environment variables for build options that the user might wish to change
#
# Variable     Example Value
# ----------   -------------
# APP_NAME     neon_convolution-Cortex-R52_GCC.axf
# OPT_LEVEL    0, 1, 2 or 3
# CODE_TYPE    arm or thumb

APP_NAME ?= neon_convolution
OPT_LEVEL ?= 0
CODE_TYPE ?= thumb

APP = $(APP_NAME)-Cortex-R52_GCC.axf

# Other switches the user should not normally need to change:
CPU = cortex-r52 # This isn't used yet 
DEBUG_FLAGS = -g

CC = arm-eabi-gcc
CXX= arm-eabi-g++

define EOL =

endef

ifeq ($(OS),Windows_NT)
SHELL=$(windir)\system32\cmd.exe
RM_FILES = $(foreach file,$(1),if exist $(file) del /q $(file)$(EOL))
RM_DIRS = $(foreach dir,$(1),if exist $(dir) rmdir /s /q $(dir)$(EOL))
else
RM_FILES = $(foreach file,$(1),rm -f $(file)$(EOL))
RM_DIRS = $(foreach dir,$(1),rm -rf $(dir)$(EOL))
endif

DEPEND_FLAGS = -MD
INCLUDES = -I ComputeLibrary  -I ComputeLibrary/include
DEFINES=-DNO_MULTI_THREADING  

CPPFLAGS = $(DEBUG_FLAGS) -O$(OPT_LEVEL) $(DEFINES) $(INCLUDES) $(DEPEND_FLAGS) -std=c++11
CFLAGS = $(DEBUG_FLAGS) -O$(OPT_LEVEL)
ASFLAGS = $(DEBUG_FLAGS)
LDFLAGS = -Tgcc.ld -Wl,--build-id=none,-Map=linkmap.txt --specs=rdimon.specs 
TARGET_ARCH = -march=armv8-r -mfloat-abi=hard -mfpu=neon -m$(CODE_TYPE)
TARGET_MACH = $(TARGET_ARCH)

APP_C_SRC := ComputeLibrary/utils/Utils.cpp ComputeLibrary/examples/$(APP_NAME).cpp
APP_ASM_SRC := $(wildcard *.S)
OBJ_FILES := $(APP_C_SRC:%.cpp=%.o) $(APP_ASM_SRC:%.S=%.o)
DEP_FILES := $(OBJ_FILES:%.o=%.d)
CL_LIBS_PATH = ComputeLibrary/build 
CL_LIBS = -larm_compute-static -larm_compute_core-static -larm_compute_graph-static 

.phony: all clean

all: $(APP)

$(APP): $(OBJ_FILES) gcc.ld
	$(CXX) $(TARGET_ARCH) $(LDFLAGS) -o $@ $(OBJ_FILES)  -L $(CL_LIBS_PATH) $(CL_LIBS)

clean:
	$(call RM_FILES,$(APP) $(OBJ_FILES) $(DEP_FILES) linkmap.txt)

# Make sure everything is rebuilt if this makefile is changed
$(OBJ_FILES) $(APP): makefile

-include $(DEP_FILES)

