#
# Makefile - DualDhrystone platform makefile.
#
# Copyright 2011-2012 ARM Limited.
# All rights reserved.
#

PROJECT_PATH ?= .

# Common rules
include $(PROJECT_PATH)/Makefile.common

# Specify objects and target(s) to build
SRCS = $(PROJECT_PATH)/../Source/mainM0PlusM4.cpp 
SRCS += $(PROJECT_PATH)/../Source/Mailbox.cpp
TARGET = EVS_Cortex-M0Plus-M4.x

# Determine others...
GENDIR = ./$(CONFIG)/gen
BUILDDIR = ./$(CONFIG)
WRAPPERLIB4 = scx-EVS_Cortex_M4-$(CONFIG)
EVSLIB4 = EVS_Cortex_M4-$(CONFIG)
WRAPPERLIB0Plus = scx-EVS_Cortex_M0Plus-$(CONFIG)
EVSLIB0Plus = EVS_Cortex_M0Plus-$(CONFIG)
CXXFLAGS += -I$(GENDIR) -I$(PROJECT_PATH)/../Source
LDFLAGS += -L$(BUILDDIR) -l$(WRAPPERLIB4) -l$(WRAPPERLIB0Plus) -lcomponents -lpvbus \
		 $(PVLIB_HOME)/lib/Linux$(BITNESS_IN_NAME)_GCC-$(GCC_VER)/libarmctmodel.a \
		 -lscx -lfmruntime -lIrisSupport -lsystemc -l$(EVSLIB4) -l$(EVSLIB0Plus) -ldl -lrt \
		 -Wl,-rpath,'$$ORIGIN'

# Determine commands
SIMGEN4_CMD = $(MAXCORE_HOME)/bin/simgen \
			 -p $(PROJECT_PATH)/../../dual_core_example/Build_Cortex-M4/EVS_Cortex-M4.sgproj \
			 --num-build-cpus $(J) --configuration $(CONFIG) \
			 $(SIMGENFLAGS)
SIMGEN0Plus_CMD = $(MAXCORE_HOME)/bin/simgen \
			 -p $(PROJECT_PATH)/../../dual_core_example/Build_Cortex-M0Plus/EVS_Cortex-M0Plus.sgproj \
			 --num-build-cpus $(J) --configuration $(CONFIG) \
			 $(SIMGENFLAGS)
CXX_CMD = $(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDFLAGS) $(SYSTEMLIBS)

# Local rules
.SUFFIXES:

.PHONY: rel_gcc73_64 rel_gcc73_64_clean rel_gcc64_64 rel_gcc64_64_clean rel_gcc49_64 rel_gcc49_64_clean

rel_gcc49_64 rel_gcc64_64 rel_gcc73_64:
	$(SIMGEN4_CMD) -b
	$(SIMGEN0Plus_CMD) -b
	cp $(BUILDDIR)/lib$(EVSLIB4).so ./
	cp $(BUILDDIR)/lib$(EVSLIB0Plus).so ./
	$(CXX_CMD)

rel_gcc49_64_clean rel_gcc64_64_clean rel_gcc73_64_clean:
	-$(SIMGEN4_CMD) --clean
	-$(SIMGEN0Plus_CMD) --clean
	-rm -f $(TARGET)
	-rm -f ./lib*.so
	-rm -rf $(CONFIG)
	-rm -f flex* EVS*
