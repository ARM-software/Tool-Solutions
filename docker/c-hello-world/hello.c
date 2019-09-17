#include <stdio.h>
#include <stdlib.h>

#ifndef ARCH
#define ARCH "Undefined"
#endif
 
int main() 
{
    printf("Hello, my architecture is %s\n", ARCH);
    exit(0);
}
