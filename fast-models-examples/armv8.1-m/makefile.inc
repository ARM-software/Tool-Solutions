
CPU_CFLAGS   = -march=armv8.1-m.main+mve.fp+fp.dp --target=arm-arm-none-eabi -mthumb -munaligned-access -mcmse 
CPU_LDFLAGS += --entry=ResetHandler

startup.o: startup.c
	$(CC) -O3 -c $(CPU_CFLAGS)  -Wno-extra $<

OBJ_FILES += startup.o 

