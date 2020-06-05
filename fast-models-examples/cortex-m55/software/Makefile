#
# Copyright (c) 2020 Arm Limited. All rights reserved.
#

APP=hello

TARGET_APP=$(APP).axf
TARGET_DIS=$(APP).dis

AS=armasm
CC=armclang
FE=fromelf
LD=armlink

# scatter comes from the hardware system
LINKFILE = scatter.scat

# generic flags for all systems added here
# try Omax to see impact of LTO
#CFLAGS= -g -Omax $(CPU_CFLAGS)
CFLAGS= -g -O3 $(CPU_CFLAGS)

# enable lto when using Omax
#LDFLAGS = --lto $(CPU_LDFLAGS)
LDFLAGS = $(CPU_LDFLAGS)

ASFLAGS = $(CPU_ASFLAGS)

# Select build rules based on Windows or Unix
ifdef windir
RM=if exist $(1) del /q $(1)
SHELL=$(windir)\system32\cmd.exe
else
RM=rm -f $(1)
endif

all: $(TARGET_APP) $(TARGET_DIS) 

clean:
	$(call RM,*.o)
	$(call RM,$(TARGET_DIS))
	$(call RM,$(TARGET_APP))

$(APP).o: $(APP).c
	$(CC) -c $(CFLAGS) $(DEFINES) $<

OBJ_FILES =  $(APP).o 
    
# add hardware specific CPU_CFLAGS and CPU_LDFLAGS from system
# include different source and object files that are CPU specific
include makefile.inc

    
$(TARGET_APP): $(OBJ_FILES) $(LINKFILE)
	$(LD) --scatter=$(LINKFILE) $(OBJ_FILES) $(LDFLAGS) -o $@

$(TARGET_DIS): $(TARGET_APP)
	$(FE) -c $(TARGET_APP) > $(TARGET_DIS)


