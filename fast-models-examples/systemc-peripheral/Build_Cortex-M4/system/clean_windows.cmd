@echo off
rem 
rem clean.cmd - clean the SystemC Peripheral example.
rem 
rem Copyright 2012-2020 ARM Limited.
rem All rights reserved.
rem 

rem VS2019
nmake /nologo /f nMakefile rel_vs142_64_clean

rem VS2017
rem nmake /nologo /f nMakefile rel_vs141_64_clean

rem VS2015 (legacy)
rem nmake /nologo /f nMakefile rel_vs14_64_clean
