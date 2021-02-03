ifneq ($(filter cmsis-nn,$(ALL_TAGS)),)
    # Enable u-arch specfic behaviours
    ifneq (,$(filter $(TARGET_ARCH), x86_64))
        # CMSIS-NN optimizations not supported
    endif

    ifneq (,$(filter $(TARGET_ARCH), cortex-m55))
      CCFLAGS += -DARM_MATH_MVEI
      CXXFLAGS += -DARM_MATH_MVEI
    endif

    # You can use the tensorflow defined CMSIS if you do not define CMSIS_PATH
    ifeq ($(CMSIS_PATH),) 
      # Setup CMSIS-NN lib and add required header files to microlite lib INCLUDE
      THIRD_PARTY_DOWNLOADS += \
      $(eval $(call add_third_party_download,$(CMSIS_URL),$(CMSIS_MD5),cmsis,))

      CMSIS_PATH = $(MAKEFILE_DIR)/downloads/cmsis/
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
                -I$(CMSIS_PATH)/CMSIS/DSP/Include \
		-I$(CMSIS_PATH)/../

    GENERATED_PROJECT_INCLUDES += -I$(CMSIS_PATH)/CMSIS/Core/Include \
                                  -I$(CMSIS_PATH)/CMSIS/NN/Include \
                                  -I$(CMSIS_PATH)/CMSIS/DSP/Include \
                                  -I$(CMSIS_PATH)/../ 
endif
