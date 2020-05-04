;
; Copyright (c) 2018 Arm Limited. All rights reserved.
;

        AREA    TTB, CODE

;===================================================================
; Cortex-A53 L2 PAGE TABLE generation

;===================================================================

        EXPORT TT0_L2
        EXPORT TT_S1_FAULT
        EXPORT TT_RAM
        EXPORT TT_DEVICE

TT_S1_FAULT              EQU    0x0
TT_RAM                   EQU    0x0000000000000705    ; Index = 1, AF=1
TT_DEVICE            EQU    0x0000000000000409
        GBLA    page
	
TT0_L2
page    SETA    0
        WHILE   page < 0xC0
        DCD     TT_RAM + (page :SHL: 21)
        DCD 0
        DCD     TT_RAM + ((page+1) :SHL: 21)
        DCD 0
        DCD     TT_RAM + ((page+2) :SHL: 21)
        DCD 0
        DCD     TT_RAM + ((page+3) :SHL: 21)
        DCD 0
        
page    SETA    page + 4
        WEND
        WHILE   page < 0x170
        DCD     TT_DEVICE + (page :SHL: 21)
        DCD 0x00600000
        DCD     TT_DEVICE + ((page+1) :SHL: 21)
        DCD 0x00600000
        DCD     TT_DEVICE + ((page+2) :SHL: 21)
        DCD 0x00600000
        DCD     TT_DEVICE + ((page+3) :SHL: 21)
        DCD 0x00600000
        
page    SETA    page + 4      
        WEND
        WHILE   page < 0x800
        DCD     TT_RAM + (page :SHL: 21)
        DCD 0
        DCD     TT_RAM + ((page+1) :SHL: 21)
        DCD 0
        DCD     TT_RAM + ((page+2) :SHL: 21)
        DCD 0
        DCD     TT_RAM + ((page+3) :SHL: 21)
        DCD 0
        
page    SETA    page + 4
        WEND
	
        END
        
