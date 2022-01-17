rem x64 Native Tools Command Prompt
@echo off
rem 
rem build.bat - Build the SystemC Peripheral example.
rem 
rem Copyright 2012-2020 ARM Limited.
rem All rights reserved.
rem 

rem Use Visual Studio x64 Native Tools Command Prompt


rem VS2019
nmake /nologo /f nMakefile rel_vs142_64

rem VS2017
rem nmake /nologo /f nMakefile rel_vs141_64

rem VS2015 (legacy)
rem nmake /nologo /f nMakefile rel_vs14_64

