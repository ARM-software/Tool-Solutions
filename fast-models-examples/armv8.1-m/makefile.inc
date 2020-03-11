
CPU_CFLAGS   = -mcpu=cortex-m55 --target=arm-arm-none-eabi -mthumb -munaligned-access -mcmse 
CPU_LDFLAGS += --entry=ResetHandler

startup.o: startup.c
	$(CC) -O3 -c $(CPU_CFLAGS)  -Wno-extra $<

OBJ_FILES += startup.o 

