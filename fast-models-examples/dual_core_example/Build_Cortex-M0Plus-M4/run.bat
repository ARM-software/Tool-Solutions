@echo off
rem 
rem run.bat - Run the Dual Core M0+/M4 example.
rem 
rem Copyright 2020 ARM Limited.
rem All rights reserved.
rem 

set axf0="..\Software\startup_Cortex-M0+_AC6_sharedmem\startup_Cortex-M0+_AC6.axf"
set axf4="..\Software\startup_Cortex-M4_AC6_sharedmem\startup_Cortex-M4_AC6.axf"

if not exist %axf0% (
    echo ERROR: %axf0%: application not found
    echo Build the Cortex-M0+ application in the software folder before running this example
    goto end
)

if not exist %axf4% (
    echo ERROR: %axf4%: application not found
    echo Build the Cortex-M4 application in the software folder before running this example
    goto end
)


.\EVS_Cortex-M0Plus-M4.exe -a Cortex_M4.Core=%axf4% -a Cortex_M0Plus.Core=%axf0% --stat --cyclelimit 10000000

:end
pause

