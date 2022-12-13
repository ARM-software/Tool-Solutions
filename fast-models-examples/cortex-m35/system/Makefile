#
# Makefile
#
# Copyright 2019-2022 ARM Limited.
# All rights reserved.
#

PROJECT_PATH ?= .

# Common rules
include Makefile.common

# Specify objects and target(s) to build
SRCS = $(wildcard *.cpp)
TARGET = Cortex-M35-example.x

# Determine others...
GENDIR = $(CONFIG)/gen
BUILDDIR = $(CONFIG)
WRAPPERLIB = scx-m35-$(CONFIG)
EVSLIB = m35-$(CONFIG)
CXXFLAGS += -I$(GENDIR)c -I$(GENDIR) -Wno-deprecated -Wno-maybe-uninitialized -Wno-unused-variable
LDFLAGS += -L$(BUILDDIR) -l$(WRAPPERLIB) -lcomponents -lpvbus \
		 $(PVLIB_HOME)/lib/Linux$(BITNESS_IN_NAME)_GCC-$(GCC_VER)/libarmctmodel.a \
		 -lscx -lfmruntime -lIrisSupport -lsystemc -l$(EVSLIB) -ldl -lrt \
		 -Wl,-rpath,'$$ORIGIN'

CXX_VER := $(shell $(CXX) -dumpversion 2> /dev/null | \
                   sed -e "s/\([0-9]*\.[0-9]*\)\.[0-9]*/\1/")
CXX_VER_MAJOR := $(word 1, $(subst ., ,$(CXX_VER)))

ifeq ($(CXX_VER_MAJOR),7)
LDFLAGS += -latomic
endif

# Determine commands
SIMGEN_CMD = $(MAXCORE_HOME)/bin/simgen -p ./m35.sgproj \
			 --num-build-cpus $(J) --configuration $(CONFIG) \
			 $(SIMGENFLAGS)
CXX_CMD = $(CXX) $(CXXFLAGS) -o $(TARGET) $(SRCS) $(LDFLAGS)

.SUFFIXES:




.PHONY: dbg_gcc49_64 rel_gcc49_64
.PHONY: dbg_gcc53_64 rel_gcc53_64
.PHONY: dbg_gcc64_64 rel_gcc64_64
.PHONY: dbg_gcc73_64 rel_gcc73_64
.PHONY: dbg_gcc93_64 rel_gcc93_64

.PHONY: dbg_gcc49_64_clean rel_gcc49_64_clean
.PHONY: dbg_gcc53_64_clean rel_gcc53_64_clean
.PHONY: dbg_gcc64_64_clean rel_gcc64_64_clean
.PHONY: dbg_gcc73_64_clean rel_gcc73_64_clean
.PHONY: dbg_gcc93_64_clean rel_gcc93_64_clean

 dbg_gcc49_64 rel_gcc49_64 dbg_gcc53_64 rel_gcc53_64 dbg_gcc64_64 rel_gcc64_64 dbg_gcc73_64 rel_gcc73_64 dbg_gcc93_64 rel_gcc93_64:
	$(SIMGEN_CMD) -b
	cp $(BUILDDIR)/lib$(EVSLIB).so ./
	$(CXX_CMD)

 dbg_gcc49_64_clean rel_gcc49_64_clean dbg_gcc73_64_clean rel_gcc73_64_clean dbg_gcc64_64_clean rel_gcc64_64_clean dbg_gcc53_64_clean rel_gcc53_64_clean dbg_gcc93_64_clean rel_gcc93_64_clean:
	-$(SIMGEN_CMD) --clean
	-rm -f $(TARGET)
	-rm -rf $(CONFIG)
	-rm -f ./lib$(EVSLIB).so


