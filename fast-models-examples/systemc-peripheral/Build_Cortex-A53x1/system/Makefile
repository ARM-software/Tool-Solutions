#
# Makefile
#
# Copyright 2019-2022 ARM Limited.
# All rights reserved.
#

PROJECT_PATH ?= .
SYSTEMC_EXPORT_HOME ?= $(PVLIB_HOME)/examples/SystemCExport

# Common rules
include $(SYSTEMC_EXPORT_HOME)/Common/Makefile.common

# Specify objects and target(s) to build
SRCS = $(wildcard ../../SystemC_Source/*.cpp)
TARGET = systemc-peripheral-example.x

# Other targets
GENDIR = ./$(CONFIG)/gen
BUILDDIR = ./$(CONFIG)
WRAPPERLIB = scx-cpu_core-$(CONFIG)
EVSLIB = cpu_core-$(CONFIG)

CXXFLAGS += -I$(GENDIR) -Wno-deprecated -Wno-maybe-uninitialized -Wno-unused-variable

LDFLAGS += -L$(BUILDDIR) -l$(WRAPPERLIB) -l$(EVSLIB) -lcomponents -lpugixml -lpvbus \
	$(PVLIB_HOME)/lib/Linux$(BITNESS_IN_NAME)_GCC-$(GCC_VER)/libarmctmodel.a -lscx -lfmruntime -lIrisSupport -lsystemc -ldl -lrt \
	-Wl,-rpath,'$$ORIGIN'

# Determine commands
SIMGEN_CMD = $(MAXCORE_HOME)/bin/simgen -p \
	$(PROJECT_PATH)/systemc-peripheral-example.sgproj  --configuration \
	$(CONFIG) --num-build-cpus $(J) $(SIMGENFLAGS)

CXX_CMD = $(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDFLAGS) $(SYSTEMLIBS)

# Local rules
.SUFFIXES:

HOST_ARCH = $(shell uname -m)

ifeq ($(HOST_ARCH),x86_64)
.PHONY: dbg_gcc49_64 rel_gcc49_64
.PHONY: dbg_gcc64_64 rel_gcc64_64
.PHONY: dbg_gcc73_64 rel_gcc73_64
.PHONY: dbg_gcc93_64 rel_gcc93_64

.PHONY: dbg_gcc49_64_clean rel_gcc49_64_clean
.PHONY: dbg_gcc64_64_clean rel_gcc64_64_clean
.PHONY: dbg_gcc73_64_clean rel_gcc73_64_clean
.PHONY: dbg_gcc93_64_clean rel_gcc93_64_clean

dbg_gcc49_64 rel_gcc49_64 dbg_gcc64_64 rel_gcc64_64 dbg_gcc73_64 rel_gcc73_64 dbg_gcc93_64 rel_gcc93_64 :

else ifeq ($(HOST_ARCH),aarch64)
.PHONY: dbg_gcc63_64 rel_gcc63_64

.PHONY: dbg_gcc63_64_clean rel_gcc63_64_clean

dbg_gcc63_64 rel_gcc63_64 :

else
$(error $(HOST_ARCH): unknown host architecture)
endif
	$(SIMGEN_CMD) -b
	cp $(BUILDDIR)/lib$(EVSLIB).so ./
	$(CXX_CMD)


ifeq ($(HOST_ARCH),x86_64)
dbg_gcc49_64_clean rel_gcc49_64_clean dbg_gcc64_64_clean rel_gcc64_64_clean dbg_gcc73_64_clean rel_gcc73_64_clean \
	dbg_gcc93_64_clean rel_gcc93_64_clean :

else ifeq ($(HOST_ARCH),aarch64)
dbg_gcc63_64_clean rel_gcc63_64_clean :

else
$(error $(HOST_ARCH): unknown host architecture)
endif
	-$(SIMGEN_CMD) --clean
	-rm -f ./lib$(EVSLIB).so
	-rm -f $(TARGET)
