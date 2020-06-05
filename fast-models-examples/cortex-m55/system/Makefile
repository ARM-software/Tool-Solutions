#
# Makefile
#
# Copyright 2019 ARM Limited.
# All rights reserved.
#

PROJECT_PATH ?= .

# Common rules
include Makefile.common

# Specify objects and target(s) to build
SRCS = main.cpp trickbox.cpp
TARGET = Cortex-M55.x

# Determine others...
GENDIR = ./$(CONFIG)/gen
BUILDDIR = ./$(CONFIG)
WRAPPERLIB = scx-m55-$(CONFIG)
EVSLIB = m55-$(CONFIG)
# CXXFLAGS += -I../../../../_common/models -I$(GENDIR) -Wno-deprecated -Wno-maybe-uninitialized -Wno-unused-variable
CXXFLAGS += -I$(GENDIR) -Wno-deprecated -Wno-maybe-uninitialized -Wno-unused-variable
LDFLAGS += -L$(BUILDDIR) -l$(WRAPPERLIB) -lcomponents -lpvbus \
		 $(PVLIB_HOME)/lib/Linux$(BITNESS_IN_NAME)_GCC-$(GCC_VER)/libarmctmodel.a \
		 -lscx -lfmruntime -lIrisSupport -lsystemc -latomic -l$(EVSLIB) -ldl -lrt \
		 -Wl,-rpath,'$$ORIGIN'

# Determine commands
# SIMGEN_CMD = $(MAXCORE_HOME)/bin/simgen -p $(PROJECT_PATH)/m55.sgproj \
			 --num-build-cpus $(J) --configuration $(CONFIG) \
                         --license-mapping $(ELMAP) \
			 $(SIMGENFLAGS)
SIMGEN_CMD = $(MAXCORE_HOME)/bin/simgen -p $(PROJECT_PATH)/m55.sgproj \
			 --num-build-cpus $(J) --configuration $(CONFIG) \
                         $(SIMGENFLAGS)
CXX_CMD = $(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDFLAGS)

.SUFFIXES:

.PHONY: dbg_gcc49_64 rel_gcc49_64
.PHONY: dbg_gcc64_64 rel_gcc64_64
.PHONY: dbg_gcc73_64 rel_gcc73_64

.PHONY: dbg_gcc49_64_clean rel_gcc49_64_clean
.PHONY: dbg_gcc64_64_clean rel_gcc64_64_clean
.PHONY: dbg_gcc73_64_clean rel_gcc73_64_clean

dbg_gcc49_64 rel_gcc49_64 dbg_gcc64_64 rel_gcc64_64 dbg_gcc73_64 rel_gcc73_64:
	$(SIMGEN_CMD) -b
	cp $(BUILDDIR)/lib$(EVSLIB).so ./
	$(CXX_CMD)

dbg_gcc49_64_clean rel_gcc49_64_clean dbg_gcc64_64_clean rel_gcc64_64_clean dbg_gcc73_64_clean rel_gcc73_64_clean:
	-$(SIMGEN_CMD) --clean
	-rm -f $(TARGET)
	-rm -rf $(CONFIG)
	-rm -f ./lib$(EVSLIB).so


