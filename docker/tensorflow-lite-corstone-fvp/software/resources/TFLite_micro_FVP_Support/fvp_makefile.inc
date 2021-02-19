# Settings for FVP platforms.
ifeq ($(TARGET),$(filter $(TARGET),fvp model))
  TARGET_ARCH := cortex-m33+nodsp

  ifneq ($(filter armclang,$(ALL_TAGS)),)
    CXX_TOOL  := armclang
    CC_TOOL   := armclang
    AR_TOOL   := armar
    LD        := armlink
  else ifneq ($(filter gcc,$(ALL_TAGS)),)
    CXX_TOOL  := arm-none-eabi-gcc
    CC_TOOL   := arm-none-eabi-gcc
    AR_TOOL   := arm-none-eabi-gcc-ar
    LD        := arm-none-eabi-ld
  else
    $(error "Currently only supports armclang and gcc(WIP)")
  endif

  ifeq ($(CMSIS_PATH),)
    CMSIS_PATH = $(MAKEFILE_DIR)/downloads/cmsis/
  endif

  ifeq ($(OPTIMIZATION),)
    ifneq ($(MAKECMDGOALS), microlite)
      OPTIMIZATION := -O3
    else
      OPTIMIZATION := -O3
    endif
  endif

  $(eval $(call add_third_party_download,$(CMSIS_URL),$(CMSIS_MD5),cmsis,))

  FLOAT := soft
  SCATTER := $(MAKEFILE_DIR)/targets/fvp/app.scatter

  ifneq ($(filter ethos-u,$(ALL_TAGS)),)
    TARGET_SPECIFIC_FLAGS += -DETHOSU
  endif

  ifeq ($(TARGET_ARCH),$(filter $(TARGET_ARCH),cortex-m55 yamin))
    ifeq ($(TARGET_ARCH), cortex-m55)
        CORE=M55
    else
        CORE=YAMIN
    endif
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm55.h \
        $(CMSIS_PATH)/CMSIS/Core/Include/mpu_armv8.h
    ifeq ($(TARGET), fvp)
      ifneq ($(filter ethos-u,$(ALL_TAGS)),)
          SCATTER := $(MAKEFILE_DIR)/targets/fvp/m55_npu.scatter
      else
          SCATTER := $(MAKEFILE_DIR)/targets/fvp/m55_app.scatter
      endif
    endif
    LDFLAGS+=-Wl,--cpu=cortex-m55,-Omax
    TARGET_SPECIFIC_FLAGS += -D__DSP_PRESENT=1 -D__FPU_PRESENT=1
    FLOAT=hard
  else ifeq ($(TARGET_ARCH), cortex-m33+nodsp)
    CORE=M33
    NO_DSP=.no_dsp
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm33.h \
        $(CMSIS_PATH)/CMSIS/Core/Include/mpu_armv8.h
    LDFLAGS+=-Wl,--cpu=Cortex-M33.no_dsp.no_fp,-Omax
    TARGET_SPECIFIC_FLAGS +=
  else ifeq ($(TARGET_ARCH), cortex-m33)
    CORE=M33
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm33.h \
        $(CMSIS_PATH)/CMSIS/Core/Include/mpu_armv8.h
    LDFLAGS+=-Wl,--cpu=Cortex-M33,-Omax
    TARGET_SPECIFIC_FLAGS+=-D__DSP_PRESENT=1 -D__FPU_PRESENT=1 -D__VTOR_PRESENT=1 -D__FPU_USED=1
    FLOAT=hard
  else ifeq ($(TARGET_ARCH), cortex-m0)
    CORE=M0
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm0.h
    LDFLAGS+=-Wl,--cpu=Cortex-M0,-Omax
    TARGET_SPECIFIC_FLAGS+=
  else ifeq ($(TARGET_ARCH), cortex-m3)
    CORE=M3
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm3.h \
        $(CMSIS_PATH)/CMSIS/Core/Include/mpu_armv7.h
    LDFLAGS+=-Wl,--cpu=Cortex-M3,-Omax
    TARGET_SPECIFIC_FLAGS+=
  else ifeq ($(TARGET_ARCH), cortex-m4)
    CORE=M4
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm4.h \
        $(CMSIS_PATH)/CMSIS/Core/Include/mpu_armv7.h
    LDFLAGS+=-Wl,--cpu=Cortex-M4.no_fp,-Omax
    TARGET_SPECIFIC_FLAGS+=
  else ifeq ($(TARGET_ARCH), cortex-m7)
    CORE=M7
    THIRD_PARTY_CC_HDRS += \
        $(CMSIS_PATH)/CMSIS/Core/Include/core_cm7.h \
        $(CMSIS_PATH)/CMSIS/Core/Include/mpu_armv7.h
    LDFLAGS+=-Wl,--cpu=Cortex-M7.no_fp,-Omax
    TARGET_SPECIFIC_FLAGS+=
  endif

  FVP_FLAGS_COMMON = \
    -mthumb \
    -mfloat-abi=$(FLOAT) \
    -funsigned-char \
    -mlittle-endian \
    -fno-function-sections \
    -MD \
    -DCPU_$(CORE)=1 \
    -DSTANDALONE=1 \
    $(TARGET_SPECIFIC_FLAGS) \
    -DPROFILING=1 \
    $(OPTIMIZATION)

  FVP_FLAGS_CXX = \
      -fno-rtti

  FVP_FLAGS_ARMC = \
      --target=arm-arm-none-eabi \
      -mcpu=$(TARGET_ARCH)

  ifeq ($(TARGET_ARCH), cortex-m55)
  # Micro architecure support is not available yet.
    FVP_FLAGS_GCC = \
        -march=armv8.1-m.main+mve.fp+fp.dp \
        -flax-vector-conversions
  else
    FVP_FLAGS_GCC = \
        -mcpu=$(TARGET_ARCH)
  endif

  ifeq ($(NPU_LOG_LEVEL), 1)
    PLATFORM_FLAGS += -DLOG_ENABLED
  endif

  INCLUDES += \
    -I$(MAKEFILE_DIR)/targets/fvp \
    -I$(CMSIS_PATH)/CMSIS/Core/Include/ \
    -I$(CMSIS_PATH)/CMSIS/DSP/Include

  ifneq ($(filter ethos-u,$(ALL_TAGS)),)
    INCLUDES += -I$(ETHOSU_INTERNAL_DRIVER_PATH)/timing-adapter/include
    INCLUDES += -I$(ETHOSU_DRIVER_PATH)/ethosu_pmu/include
    INCLUDES += -I$(ETHOSU_DRIVER_PATH)/include
  endif

  GENERATED_PROJECT_INCLUDES += \
    -I$(MAKEFILE_DIR)/targets/fvp \
    -I$(CMSIS_PATH)/CMSIS/Core/Include \
    -I$(CMSIS_PATH)/CMSIS/DSP/Include

  THIRD_PARTY_CC_SRCS += \
    $(MAKEFILE_DIR)/targets/fvp/flatbuffer_version_dummy.cc \
    $(MAKEFILE_DIR)/targets/fvp/boot.cc \
    $(MAKEFILE_DIR)/targets/fvp/uart.c \
    $(MAKEFILE_DIR)/targets/fvp/retarget.c

  THIRD_PARTY_CC_HDRS += \
    $(MAKEFILE_DIR)/targets/fvp/uart.h \
    $(MAKEFILE_DIR)/targets/fvp/cmsis.h \
    $(CMSIS_PATH)/CMSIS/Core/Include/cmsis_compiler.h \
    $(CMSIS_PATH)/CMSIS/Core/Include/cmsis_armclang.h \
    $(CMSIS_PATH)/CMSIS/Core/Include/cmsis_version.h \
    $(SCATTER)

  # Common + C/C++ flags
  CXXFLAGS += $(FVP_FLAGS_COMMON) $(FVP_FLAGS_CXX)
  CCFLAGS += $(FVP_FLAGS_COMMON)

  # Toolchain specfic flags
  ifeq ($(filter armclang,$(ALL_TAGS)),armclang)
    CXXFLAGS += $(FVP_FLAGS_ARMC)
    CCFLAGS += $(FVP_FLAGS_ARMC)
  else ifeq ($(filter gcc,$(ALL_TAGS)),gcc)
    CXXFLAGS += $(FVP_FLAGS_GCC)
    CCFLAGS += $(FVP_FLAGS_GCC)
  endif

  # CCFLAGS := $(filter-out -std=c11,$(CCFLAGS))

  LDFLAGS += -Wl,--map,--verbose,--list=mem.map,--scatter=$(SCATTER),--entry=__start

  # suppress "L6439W Multiply defined Global Symbol" due to flatbuffer_version_string
  LDFLAGS += -Wl,--diag_suppress=L6439W

  # suppress "L6314W: No section matches pattern" to allow empty section mapping
  # as input and model placement is controlled by application
  LDFLAGS += -Wl,--diag_suppress=L6314W

  # no addtional libraries are needed when building with armclang
  MICROLITE_LIBS =

  BUILD_TYPE := micro

endif
