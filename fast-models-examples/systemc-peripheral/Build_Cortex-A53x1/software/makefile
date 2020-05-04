#
# Copyright (c) 2018 Arm Limited. All rights reserved.
#

TARGET_APP=hello-peripheral.axf
TARGET_DIS=hello-peripheral.dis

AR=armar
AS=armasm
CC=armclang
FE=fromelf
LD=armlink

ASMFLAGS = -x assembler-with-cpp
CFLAGS   = -march=armv8-a --target=aarch64-arm-none-eabi -O2 -g
LDFLAGS  = --entry=Start --cpu=8-A.64
DEFINES  = -DUART
LINKFILE = scatter.scat


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
    
main.o: main.c
	$(CC) -c $(CFLAGS) $(DEFINES) $<

serial.o: serial.c
	$(CC) -c $(CFLAGS) $(DEFINES) $<

startup.o: startup.s
	$(CC) -c $(CFLAGS) $(ASMFLAGS) $(DEFINES) $<  
    
ttb.o: ttb.s
	$(AS) --cpu=8-A.64 -g $<
    
OBJ_FILES =  main.o serial.o startup.o ttb.o



$(TARGET_APP): $(OBJ_FILES) $(LINKFILE)
	$(LD) --scatter=$(LINKFILE) $(OBJ_FILES) $(LDFLAGS) -o $@
    
$(TARGET_DIS): $(TARGET_APP)
	$(FE) -c $(TARGET_APP) > $(TARGET_DIS)
