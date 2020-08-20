    
# Requires a recent armclang on the PATH, e.g.:
#     eval `setup_wh_comp 'ARMCC:TestableTools:0.0::trunk:regime=rel|checking=none'`

# Configure your Arm DS environment to run Arm Compiler 6 from the command-line:

#https://developer.arm.com/docs/101470/1900/configure-arm-development-studio/register-a-compiler-toolchain/configure-a-compiler-toolchain-for-the-arm-ds-command-prompt


armclang -c -g --target=aarch64-arm-none-eabi $CFLAGS hello_world.c
armclang -c -g --target=aarch64-arm-none-eabi $CFLAGS startup.s
armclang -c -g --target=aarch64-arm-none-eabi $CFLAGS pl011_uart.c
armclang -c -g --target=aarch64-arm-none-eabi $CFLAGS stm.c
armlink --scatter=scatter.txt --entry=start64 $CFLAGS hello_world.o startup.o pl011_uart.o stm.o -o image.axf
fromelf --text -c image.axf --output=disasm.txt
