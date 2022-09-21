# ARMv8 Startup Example Makefile
#
# Copyright (C) ARM Limited, 2013. All rights reserved.
#
# This makefile is intended for use with GNU make
# This example is intended to be built with ARM Compiler 6

ASFLAGS= -gdwarf-3 -c --target=aarch64-arm-none-eabi
CFLAGS=  -gdwarf-3 -c --target=aarch64-arm-none-eabi -I"./headers" -O1

CC=armclang
AS=armclang
LD=armlink

GIC?=	GICV3

ifeq "$(GIC)" "GICV4"
	CFLAGS += -DGICV4=TRUE
endif

ifeq "$(DEBUG)" "TRUE"
    CFLAGS += -DDEBUG
endif

# Select build rules based on Windows or Unix
ifdef WINDIR
DONE=@if exist $(1) if exist $(2) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(WINDIR)\system32\cmd.exe
else
ifdef windir
DONE=@if exist $(1) if exist $(2) echo Build completed.
RM=if exist $(1) del /q $(1)
SHELL=$(windir)\system32\cmd.exe
else
DONE=@if [ -f $(1) ]; then if [ -f $(2) ]; then echo Build completed.; fi; fi
RM=rm -f $(1)
endif
endif

all: image_basic.axf image_lpi.axf image_gicv31.axf
	$(call DONE,$(EXECUTABLE))

gicv4: image_vlpi.axf image_vsgi.axf

rebuild: clean all

clean:
	$(call RM,*.o)
	$(call RM,image_basic.axf)
	$(call RM,image_lpi.axf)
	$(call RM,image_gicv31.axf)
	$(call RM,image_vlpi.axf)
	$(call RM,image_vsgi.axf)

main_basic.o: ./src/main_basic.c
	$(CC) ${CFLAGS} ./src/main_basic.c

main_gicv31.o: ./src/main_gicv31.c
	$(CC) ${CFLAGS} ./src/main_gicv31.c

main_lpi.o: ./src/main_lpi.c
	$(CC) ${CFLAGS} ./src/main_lpi.c

main_vlpi.o: ./src/main_vlpi.c
	$(CC) ${CFLAGS} ./src/main_vlpi.c

main_vsgi.o: ./src/main_vsgi.c
	$(CC) ${CFLAGS} ./src/main_vsgi.c

gicv3_basic.o: ./src/gicv3_basic.c
	$(CC) ${CFLAGS} ./src/gicv3_basic.c

gicv3_lpis.o: ./src/gicv3_lpis.c
	$(CC) ${CFLAGS} ./src/gicv3_lpis.c

gicv4_virt.o: ./src/gicv4_virt.c
	$(CC) ${CFLAGS} ./src/gicv4_virt.c

system_counter.o: ./src/system_counter.c
	$(CC) ${CFLAGS} ./src/system_counter.c

sp804_timer.o: ./src/sp804_timer.c
	$(CC) ${CFLAGS} ./src/sp804_timer.c

startup.o: ./src/startup.s
	$(AS) ${ASFLAGS} ./src/startup.s

startup_virt.o: ./src/startup_virt.s
	$(AS) ${ASFLAGS} ./src/startup_virt.s

secondary_virt.o: ./src/secondary_virt.s
	$(AS) ${ASFLAGS} ./src/secondary_virt.s

el3_vectors.o: ./src/el3_vectors.s
	$(AS) ${ASFLAGS} ./src/el3_vectors.s

generic_timer.o: ./src/generic_timer.s
	$(AS) ${ASFLAGS} ./src/generic_timer.s

gicv3_cpuif.o: ./src/gicv3_cpuif.S
	$(AS) ${ASFLAGS} ./src/gicv3_cpuif.S

image_basic.axf: main_basic.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter.txt main_basic.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o -o image_basic.axf --entry=start64

image_gicv31.axf: main_gicv31.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter.txt main_gicv31.o startup.o gicv3_basic.o gicv3_cpuif.o el3_vectors.o -o image_gicv31.axf --entry=start64

image_lpi.axf: main_lpi.o generic_timer.o system_counter.o startup.o gicv3_basic.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter.txt main_lpi.o  generic_timer.o system_counter.o               startup.o gicv3_basic.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o -o image_lpi.axf --entry=start64

image_vlpi.axf: main_vlpi.o generic_timer.o system_counter.o startup_virt.o secondary_virt.o gicv3_basic.o gicv4_virt.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter_virt.txt main_vlpi.o generic_timer.o system_counter.o startup_virt.o secondary_virt.o gicv3_basic.o gicv3_lpis.o gicv4_virt.o gicv3_cpuif.o el3_vectors.o -o image_vlpi.axf --entry=start64

image_vsgi.axf: main_vsgi.o generic_timer.o system_counter.o startup_virt.o secondary_virt.o gicv3_basic.o gicv4_virt.o gicv3_lpis.o gicv3_cpuif.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter_virt.txt main_vsgi.o generic_timer.o system_counter.o startup_virt.o secondary_virt.o gicv3_basic.o gicv3_lpis.o gicv4_virt.o gicv3_cpuif.o el3_vectors.o -o image_vsgi.axf --entry=start64
