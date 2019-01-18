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
SRCS = $(wildcard ./SystemC-src/*.cpp)
TARGET = systemc-peripheral-example.x

# Determine others...
GENDIR = ./$(CONFIG)/gen
BUILDDIR = ./$(CONFIG)
WRAPPERLIB = scx-a53x1-$(CONFIG)
EVSLIB = a53x1-$(CONFIG)
CXXFLAGS += -ISystemC-src -I$(GENDIR) -Wno-deprecated -Wno-maybe-uninitialized -Wno-unused-variable
LDFLAGS += -L$(BUILDDIR) -l$(WRAPPERLIB) -lcomponents -lpvbus \
		 $(PVLIB_HOME)/lib/Linux$(BITNESS_IN_NAME)_GCC-$(GCC_VER)/libarmctmodel.a \
		 -lscx -lfmruntime -lIrisSupport -lsystemc -l$(EVSLIB) -ldl -lrt \
		 -Wl,-rpath,'$$ORIGIN'

# Determine commands
SIMGEN_CMD = $(MAXCORE_HOME)/bin/simgen -p $(PROJECT_PATH)/systemc-peripheral-example.sgproj \
			 --num-build-cpus $(J) --configuration $(CONFIG) \
			 $(SIMGENFLAGS)
CXX_CMD = $(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDFLAGS)

.SUFFIXES:




.PHONY: dbg_gcc49_64 rel_gcc49_64
.PHONY: dbg_gcc54_64 rel_gcc54_64
.PHONY: dbg_gcc64_64 rel_gcc64_64


.PHONY: dbg_gcc49_64_clean rel_gcc49_64_clean
.PHONY: dbg_gcc54_64_clean rel_gcc54_64_clean
.PHONY: dbg_gcc64_64_clean rel_gcc64_64_clean

 dbg_gcc49_64 rel_gcc49_64 dbg_gcc54_64 rel_gcc54_64 dbg_gcc64_64 rel_gcc64_64:
	$(SIMGEN_CMD) -b
	cp $(BUILDDIR)/lib$(EVSLIB).so ./
	$(CXX_CMD)

 dbg_gcc49_64_clean rel_gcc49_64_clean dbg_gcc54_64_clean rel_gcc54_64_clean dbg_gcc64_64_clean rel_gcc64_64_clean:
	-$(SIMGEN_CMD) --clean
	-rm -f $(TARGET)
	-rm -rf $(CONFIG)
	-rm -f ./lib$(EVSLIB).so


