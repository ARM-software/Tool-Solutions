ifneq ($(filter cmsis-nn,$(ALL_TAGS)),)
    # Enable u-arch specfic behaviours
    ifneq (,$(filter $(TARGET_ARCH), x86_64))
        # CMSIS-NN optimizations not supported
    endif

    ifneq (,$(filter $(TARGET_ARCH), cortex-m55))
      CCFLAGS += -DARM_MATH_MVEI
      CXXFLAGS += -DARM_MATH_MVEI
    endif

    # Include CMSIS-NN files
    THIRD_PARTY_CC_SRCS += \
      $(call recursive_find,$(CMSIS_PATH)/CMSIS/NN/Source,*.c)

    THIRD_PARTY_CC_HDRS += \
      $(call recursive_find,$(CMSIS_PATH)/CMSIS/NN/Include,*.h)
    THIRD_PARTY_CC_HDRS += \
      $(call recursive_find,$(CMSIS_PATH)/CMSIS/DSP/Include,*.h)
    THIRD_PARTY_CC_HDRS += \
      $(call recursive_find,$(CMSIS_PATH)/CMSIS/Core/Include,*.h)

    INCLUDES += -I$(CMSIS_PATH)/CMSIS/Core/Include \
                -I$(CMSIS_PATH)/CMSIS/NN/Include \
                -I$(CMSIS_PATH)/CMSIS/DSP/Include

GENERATED_PROJECT_INCLUDES += -I$(CMSIS_PATH)/CMSIS/Core/Include \
                                  -I$(CMSIS_PATH)/CMSIS/NN/Include \
                                  -I$(CMSIS_PATH)/CMSIS/DSP/Include
endif
