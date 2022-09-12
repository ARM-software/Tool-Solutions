# ARMv8 Startup Example Makefile
#
# Copyright (C) ARM Limited, 2019. All rights reserved.
#
# This makefile is intended for use with GNU make
# This example is intended to be built with ARM Compiler 6

ASFLAGS= -gdwarf-3 -c --target=aarch64-arm-none-eabi
CFLAGS=  -gdwarf-3 -c --target=aarch64-arm-none-eabi -I"./headers"

# eval `setup_wh_comp 'ARMCC:TestableTools:0.0::trunk:regime=rel|checking=none'`
CC=armclang
CXX=armclang
AS=armclang
LD=armlink

GIC?=    GICV3

ifeq "$(GIC)" "GICV4"
    CFLAGS += -DGICV4
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

all: mc_config.axf mc_lpi_cmd.axf
	$(call DONE,$(EXECUTABLE))
    
gicv4: image_vlpis.axf image_vsgi.axf

rebuild: clean all

clean:
	$(call RM,*.o)
	$(call RM,mc_config.axf)
	$(call RM,mc_lpi_cmd.axf)
	$(call RM,image_vlpis.axf)
	$(call RM,image_vsgi.axf)

mc_config_test.o: ./src/mc_config_test.c
	$(CC) ${CFLAGS} ./src/mc_config_test.c

main_lpis.o: ./src/main_lpis.c
	$(CC) ${CFLAGS} ./src/main_lpis.c

main_vlpis.o: ./src/main_vlpis.c
	$(CC) ${CFLAGS} ./src/main_vlpis.c

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

multichip_basic.o: ./src/multichip_basic.c ./headers/multichip_basic.h
	$(CC) ${CFLAGS} ./src/multichip_basic.c

mc_lpi_cmd.o: ./src/mc_lpi_cmd.c
	$(CC) ${CFLAGS} ./src/mc_lpi_cmd.c

startup.o: ./src/startup.s
	$(AS) ${CFLAGS} ./src/startup.s

startup_vlpis.o: ./src/startup_vlpis.s
	$(AS) ${ASFLAGS} ./src/startup_vlpis.s

secondary_vlpis.o: ./src/secondary_vlpis.s
	$(AS) ${ASFLAGS} ./src/secondary_vlpis.s

el3_vectors.o: ./src/el3_vectors.s
	$(AS) ${ASFLAGS} ./src/el3_vectors.s

generic_timer.o: ./src/generic_timer.s
	$(AS) ${ASFLAGS} ./src/generic_timer.s

gicv3_cpuif.o: ./src/gicv3_cpuif.S
	$(AS) ${ASFLAGS} ./src/gicv3_cpuif.S

cpuid.o: ./src/cpuid.s
	$(AS) ${ASFLAGS} ./src/cpuid.s

image_vlpis.axf: main_vlpis.o generic_timer.o system_counter.o startup_vlpis.o secondary_vlpis.o gicv3_basic.o gicv4_virt.o gicv3_lpis.o gicv3_cpuif.o cpuid.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter_vlpis.txt main_vlpis.o generic_timer.o system_counter.o startup_vlpis.o secondary_vlpis.o gicv3_basic.o gicv3_lpis.o gicv4_virt.o gicv3_cpuif.o cpuid.o el3_vectors.o -o image_vlpis.axf --entry=start64

image_vsgi.axf: main_vsgi.o generic_timer.o system_counter.o startup_vlpis.o secondary_vlpis.o gicv3_basic.o gicv4_virt.o gicv3_lpis.o gicv3_cpuif.o cpuid.o el3_vectors.o scatter.txt
	$(LD) --scatter=scatter_vlpis.txt main_vsgi.o generic_timer.o system_counter.o startup_vlpis.o secondary_vlpis.o gicv3_basic.o gicv3_lpis.o gicv4_virt.o gicv3_cpuif.o cpuid.o el3_vectors.o -o image_vsgi.axf --entry=start64

# When you add a new multichip operation test, please add at the end of line by copying the template below
# Also, do not forget complie your c file containing main function
mc_config.axf: mc_config_test.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o gicv3_lpis.o gicv3_cpuif.o cpuid.o el3_vectors.o multichip_basic.o scatter.txt
	$(LD) --scatter=scatter.txt cpuid.o mc_config_test.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o gicv3_lpis.o gicv3_cpuif.o multichip_basic.o el3_vectors.o -o mc_config.axf --entry=start64

mc_lpi_cmd.axf: mc_lpi_cmd.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o  gicv3_cpuif.o cpuid.o el3_vectors.o multichip_basic.o scatter.txt
	$(LD) --scatter=scatter.txt multichip_basic.o gicv3_basic.o generic_timer.o system_counter.o sp804_timer.o startup.o  gicv3_lpis.o gicv3_cpuif.o cpuid.o el3_vectors.o mc_lpi_cmd.o -o mc_lpi_cmd.axf --entry=start64

# your_test.axf : your_main.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o gicv3_cpuif.o cpuid.o el3_vectors.o multichip_basic.o scatter.txt
#	$(LD) --scatter=scatter.txt cpuid.o your_main.o generic_timer.o system_counter.o sp804_timer.o startup.o gicv3_basic.o gicv3_cpuif.o multichip_basic.o el3_vectors.o -o $your_test.axf$ --entry=start64
