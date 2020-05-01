CMSIS_HOME=<Path_to_CMSIS_5 directory>
CC=armclang
ASM=armasm
LNK=armlink
INC=-I${CMSIS_HOME}/CMSIS/RTOS2/Include -I${CMSIS_HOME}/CMSIS/RTOS2/RTX/Include -I${CMSIS_HOME}/CMSIS/RTOS2/RTX/Source -I${CMSIS_HOME}/Device/ARM/ARMCM33/Include -I${CMSIS_HOME}/CMSIS/Core/Include -I./app/ -I./RTE/CMSIS  -I./RTE/_Simulation/ 
CFLAGS=--target=arm-arm-none-eabi -g -O0 -xc -std=c11 -D_RTE_ -march=armv8-m.main -mcpu=cortex-m33+nodsp+nofp16 -mfpu=none -mfloat-abi=soft -mthumb -DARMCM33
CFLAGS+=${INC}
ASMFLAGS=--target=arm-arm-none-eabi -g -D_RTE_ -march=armv8-m.main -mcpu=cortex-m33+nodsp+nofp16 -mfpu=none -mfloat-abi=soft -mthumb -DARMCM33
LDFLAGS=--scatter ./RTE/Device/AEMv8M_mainline.sct --entry=Reset_Handler
SRC=$(wildcard ${CMSIS_HOME}/CMSIS/RTOS2/RTX/Source/*.c) \
    $(wildcard ${CMSIS_HOME}/CMSIS/RTOS2/Source/os_systick.c) \
    $(wildcard ./RTE/CMSIS/*.c) \
    $(wildcard ./RTE/Device/*.c) \
    $(wildcard ./app/*.c)
SRC_S=$(wildcard ./RTE/Device/*.S)

OBJ=$(SRC:.c=.o)
OBJ_S=$(SRC_S:.S=.o)

%.o: %.S 
	$(CC) -o $@ $(ASMFLAGS) -c $<

test.axf: $(OBJ) $(OBJ_S)
	$(LNK) -o $@ $(LDFLAGS) $^

clean:
	find ${CMSIS_HOME} -name "*.o" -exec rm -rf {} \;
	find ./ -name "*.o" -exec rm -rf {} \;
	#rm test.axf
