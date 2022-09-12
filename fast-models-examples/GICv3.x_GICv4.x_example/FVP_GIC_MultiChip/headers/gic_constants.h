#ifndef GIC_CONSTANTS_H
#define GIC_CONSTANTS_H


#define ITS_CMD_SIZE_IN_LONG_WORDS 4
#define ITS_CMD_SIZE_IN_BYTES ITS_CMD_SIZE_IN_LONG_WORDS*8

// ITS command identifier
#define ITS_CMD_MOVI    0x01
#define ITS_CMD_INT     0x03
#define ITS_CMD_CLEAR   0x04
#define ITS_CMD_SYNC    0x05
#define ITS_CMD_MAPD    0x08
#define ITS_CMD_MAPC    0x09
#define ITS_CMD_MAPTI   0x0A
#define ITS_CMD_MAPI    0x0B
#define ITS_CMD_INV     0x0C
#define ITS_CMD_INVALL  0x0D
#define ITS_CMD_MOVALL  0x0E
#define ITS_CMD_DISCARD 0x0F
#define ITS_CMD_VMOVI   0x21
#define ITS_CMD_VMOVP   0x22
#define ITS_CMD_VSGI    0x23 // Only for GICv4.1
#define ITS_CMD_VSYNC   0x25
#define ITS_CMD_VMAPP   0x29
#define ITS_CMD_VMAPTI  0x2A
#define ITS_CMD_VMAPI   0x2B
#define ITS_CMD_VINVALL 0x2D
#define ITS_CMD_INVDB   0x2E // Only for GICv4.1

#endif
