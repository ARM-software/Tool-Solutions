# Settings for IPSS platforms.
ifeq ($(TARGET),$(filter $(TARGET),ipss model))
  TARGET_ARCH := cortex-m33+nodsp

  ifneq ($(filter armclang,$(ALL_TAGS)),)
    CXX_TOOL  := armclang
    CC_TOOL   := armclang
    AR_TOOL   := armar
    LD        := armlink
  else
    $(error "Currently only support armclang (TAGS=armclang).")
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

  ifeq ($(TARGET_ARCH), cortex-m55)
    CORE=M55
    THIRD_PARTY_CC_HDRS += \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/core_armv81mml.h \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/mpu_armv8.h
    LDFLAGS+=--cpu=8.1-M.Main.dsp -Omax --entry=__start
    TARGET_SPECIFIC_FLAGS=
    FLOAT=hard
  else ifeq ($(TARGET_ARCH), cortex-m33+nodsp)
    CORE=M33
    NO_DSP=.no_dsp
    THIRD_PARTY_CC_HDRS += \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/core_cm33.h \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/mpu_armv8.h
    LDFLAGS+=--cpu=Cortex-M33.no_dsp.no_fp -Omax
    TARGET_SPECIFIC_FLAGS=
  else ifeq ($(TARGET_ARCH), cortex-m0)
    CORE=M0
    THIRD_PARTY_CC_HDRS += \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/core_cm0.h
    LDFLAGS+=--cpu=Cortex-M0 -Omax
    TARGET_SPECIFIC_FLAGS=
  else ifeq ($(TARGET_ARCH), cortex-m3)
    CORE=M3
    THIRD_PARTY_CC_HDRS += \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/core_cm3.h \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/mpu_armv7.h
    LDFLAGS+=--cpu=Cortex-M3 -Omax
    TARGET_SPECIFIC_FLAGS=
  else ifeq ($(TARGET_ARCH), cortex-m4)
    CORE=M4
    THIRD_PARTY_CC_HDRS += \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/core_cm4.h \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/mpu_armv7.h
    LDFLAGS+=--cpu=Cortex-M4.no_fp -Omax
    TARGET_SPECIFIC_FLAGS=
  else ifeq ($(TARGET_ARCH), cortex-m7)
    CORE=M7
    THIRD_PARTY_CC_HDRS += \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/core_cm7.h \
        $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/mpu_armv7.h
    LDFLAGS+=--cpu=Cortex-M7.no_fp -Omax
    TARGET_SPECIFIC_FLAGS=
  endif

  PLATFORM_FLAGS = \
    -mthumb \
    --target=arm-arm-none-eabi \
    -mfloat-abi=$(FLOAT) \
    -c \
    -fno-rtti \
    -funsigned-char \
    -mlittle-endian \
    -fno-function-sections \
    -MD \
    -DCPU_$(CORE)=1 \
    -mcpu=$(TARGET_ARCH) \
    $(TARGET_SPECIFIC_FLAGS) \
    $(OPTIMIZATION)

  INCLUDES += \
    -I$(MAKEFILE_DIR)/targets/ipss \
    -I$(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/ \
    -I$(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/ \
    -I$(MAKEFILE_DIR)/downloads/cmsis/CMSIS/NN/Include/

  GENERATED_PROJECT_INCLUDES += \
    -I$(MAKEFILE_DIR)/targets/ipss \
    -I$(MAKEFILE_DIR)/downloads/ \
    -I$(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/ \
    -I$(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/ \
    -I$(MAKEFILE_DIR)/downloads/cmsis/CMSIS/NN/Include/

  THIRD_PARTY_CC_SRCS += \
    $(MAKEFILE_DIR)/targets/ipss/flatbuffer_version_dummy.cc \
    $(MAKEFILE_DIR)/targets/ipss/uart_stdout.c \
    $(MAKEFILE_DIR)/targets/ipss/retarget.c \
    $(MAKEFILE_DIR)/targets/ipss/boot.cc

  THIRD_PARTY_CC_HDRS += \
    $(MAKEFILE_DIR)/targets/ipss/uart_stdout.h \
    $(MAKEFILE_DIR)/targets/ipss/app.scatter \
    $(MAKEFILE_DIR)/targets/ipss/cmsis.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/cmsis_compiler.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/cmsis_armclang.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/Core/Include/cmsis_version.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/NN/Include/arm_nnfunctions.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/NN/Include/arm_nnsupportfunctions.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/NN/Include/arm_nn_tables.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/NN/Include/arm_nn_types.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/arm_common_tables.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/arm_const_structs.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/arm_helium_utils.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/arm_math.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/arm_mve_tables.h \
    $(MAKEFILE_DIR)/downloads/cmsis/CMSIS/DSP/Include/arm_vec_math.h
    

  CXXFLAGS += $(PLATFORM_FLAGS)
  CCFLAGS += $(PLATFORM_FLAGS)
  LDFLAGS += --map --list=mem.map

  LDFLAGS += --scatter "$(MAKEFILE_DIR)/targets/ipss/app.scatter"

  BUILD_TYPE := micro

endif
