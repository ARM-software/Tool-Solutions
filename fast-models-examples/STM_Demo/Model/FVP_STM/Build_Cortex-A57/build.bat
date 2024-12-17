@echo off

rem brief  Build a CADI system using simgen
rem
rem Copyright ARM Limited 2020 All Rights Reserved.

"%MAXCORE_HOME%\bin\simgen" --num-comps-file 50 --gen-sysgen --warnings-as-errors  -p "FVP_STM_Cortex-A57.sgproj" -b %*

rem eof build.bat
