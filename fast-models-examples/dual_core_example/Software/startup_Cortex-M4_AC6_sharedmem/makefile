# Copyright (c) 2009-2017 Arm Limited (or its affiliates). All rights reserved.
# Use, modification and redistribution of this file is subject to your possession of a
# valid End User License Agreement for the Arm Product of which these examples are part of 
# and your compliance with all applicable terms and conditions of such licence agreement.
#
# This makefile is intended to allow command-line users to build this project outside of Eclipse
# This makefile is NOT used by the Eclipse managed builder project (which creates its own makefiles)
#
# This makefile is intended for use with GNU make
# This example is intended to be built with Arm Compiler 6


TARGET=startup_Cortex-M4_AC6.axf

CC=armclang
LD=armlink
AR=armar
FE=fromelf

# Select build rules based on Windows or Unix
ifdef WINDIR
DONE=@if exist $(1) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(WINDIR)\system32\cmd.exe
else
ifdef windir
DONE=@if exist $(1) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(windir)\system32\cmd.exe
else
DONE=@if [ -f $(1) ]; then echo Build completed.; fi
RM=rm -f $(1)
endif
endif


all: $(TARGET)
	$(call DONE,$(TARGET))

rebuild: clean all

clean:
	$(call RM,*.o)
	$(call RM,$(TARGET))

# Change -mfpu=fpv4-sp-d16 -mfloat-abi=hard to -mfpu=none if the (optional) FPU is not present
CFLAGS=--target=arm-arm-none-eabi -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -O2 -g

$(TARGET): main.o scs.o exceptions.o timer.o sorts.o scatter.scat
	$(LD) main.o scs.o exceptions.o timer.o sorts.o --scatter=scatter.scat --keep="exceptions.o(vectors)" -o $(TARGET) --info=totals --info=unused

main.o: main.c scs.h timer.h
	$(CC) -c $(CFLAGS) main.c

scs.o: scs.c scs.h
	$(CC) -c $(CFLAGS) scs.c

exceptions.o: exceptions.c
	$(CC) -c $(CFLAGS) exceptions.c

timer.o: timer.c timer.h scs.h
	$(CC) -c $(CFLAGS) timer.c

sorts.o: sorts.c
	$(CC) -c $(CFLAGS) sorts.c
