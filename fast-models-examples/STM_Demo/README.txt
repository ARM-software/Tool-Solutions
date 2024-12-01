This Package contain Demo on how to model STM and use test software to use this demo model. This model is not complete and for demo purpose only.

STM500 model is implemented in Model/FVP_STM/LISA/STM500.lisa

It supports two different trace sources to populate STM ATB data.
STM_PORT: Human readable syntax for data trace
STM_ATB_VALUE : Match ATB data from STM500 to match hardware packet

Model also supports port "master port<Value_64> ATB;", Any device can connect to the ATB port of STM500 model to get Packet.


Build Model
============
setenv PVLIB_HOME <Path to FastModel Install>
setenv SYSTEMC_HOME <PATH to SystemC>


cd Model/FVP_STM/Build_Cortex-A57
sh build.sh


Build Software
================

Configure your Arm DS environment to run Arm Compiler 6 from the command-line:
https://developer.arm.com/docs/101470/1900/configure-arm-development-studio/register-a-compiler-toolchain/configure-a-compiler-toolchain-for-the-arm-ds-command-prompt


cd SW_Test
sh build.sh


Run Model with Software Test
==============================
Option 1:
Without Trace plugin
Model/FVP_STM/Build_Cortex-A57/Linux64-Release-GCC-4.9/isim_system -a SW_Test/image.axf

Option 2:
With Trace PLugin GenericTrace.so to get STM_PORT trace

Model/FVP_STM/Build_Cortex-A57/Linux64-Release-GCC-4.9/isim_system -a SW_Test/image.axf --plugin $PVLIB_HOME/plugins/Linux64_GCC-4.9/GenericTrace.so -C TRACE.GenericTrace.trace-sources=STM_PORT

Option 3:
With Trace PLugin GenericTrace.so to get STM_ATB_VALUE trace


Model/FVP_STM/Build_Cortex-A57/Linux64-Release-GCC-4.9/isim_system -a SW_Test/image.axf --plugin $PVLIB_HOME/plugins/Linux64_GCC-4.9/GenericTrace.so -C TRACE.GenericTrace.trace-sources=STM_ATB_VALUE
