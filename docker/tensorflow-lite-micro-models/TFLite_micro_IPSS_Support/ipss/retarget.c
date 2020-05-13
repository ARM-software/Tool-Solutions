#include <stdio.h>
#include <string.h>
#include <time.h>
#include <rt_misc.h>
#include <rt_sys.h>

#include "uart_stdout.h"

//asm(".global __use_no_semihosting_swi");

/* Standard IO device handles. */
#define STDIN   0x8001
#define STDOUT  0x8002
#define STDERR  0x8003

/* Standard IO device name defines. */
const char __stdin_name[]  __attribute__((aligned(4))) = "STDIN";
const char __stdout_name[] __attribute__((aligned(4))) = "STDOUT";
const char __stderr_name[] __attribute__((aligned(4))) = "STDERR";

//struct __FILE { int handle; /* Add whatever you need here */ };
//FILE __stdout;
//FILE __stdin;

void exit(int code)
{
    stdout_putchar(4);
}

int fputc(int ch, FILE *f)
{
    (void)(f);
    return (stdout_putchar(ch));
}


void _ttywrch(int ch)
{
    stdout_putchar(ch);
}

/*--------------------------- _sys_open --------------------------------------*/

FILEHANDLE _sys_open (const char *name, int openmode)
{
    (void)(openmode);
    /* Register standard Input Output devices. */
    if (strcmp(name, "STDIN") == 0)
    {
        return (STDIN);
    }
    if (strcmp(name, "STDOUT") == 0)
    {
        return (STDOUT);
    }
    if (strcmp(name, "STDERR") == 0)
    {
        return (STDERR);
    }
    return (-1);
    //return (__sys_open (name, openmode));
}

/*--------------------------- _sys_close -------------------------------------*/

int _sys_close (FILEHANDLE fh)
{
    if (fh > 0x8000)
    {
        return (0);
    }
    return (-1);
    //return (__sys_close (fh));
}

/*--------------------------- _sys_write -------------------------------------*/

int _sys_write (FILEHANDLE fh, const unsigned char  *buf, unsigned int len, int mode)
{
    (void)(mode);
    if (fh == STDOUT)
    {
        /* Standard Output device. */
        for (; len; len--)
        {
	  stdout_putchar(*buf++);
        }
        return (0);
    }

    if (fh > 0x8000)
    {
        return (-1);
    }
    return (-1);
    //return (__sys_write (fh, buf, len));
}

/*--------------------------- _sys_read --------------------------------------*/

int _sys_read (FILEHANDLE fh, unsigned char *buf, unsigned int len, int mode)
{
    (void)(mode);
    if (fh == STDIN)
    {
        /* Standard Input device. */
        for (; len; len--)
        {
            //*buf++ = stdout_getchar();
        }
        return (0);
    }

    if (fh > 0x8000)
    {
        return (-1);
    }
    return (-1);
    //return (__sys_read (fh, buf, len));
}

/*--------------------------- _sys_istty -------------------------------------*/

int _sys_istty (FILEHANDLE fh)
{
    if (fh > 0x8000)
    {
        return (1);
    }
    return (0);
}

/*--------------------------- _sys_seek --------------------------------------*/

int _sys_seek (FILEHANDLE fh, long pos)
{
    (void)(pos);
    if (fh > 0x8000)
    {
        return (-1);
    }
    return (-1);
    //return (__sys_seek (fh, pos));
}

/*--------------------------- _sys_ensure ------------------------------------*/

int _sys_ensure (FILEHANDLE fh)
{
    if (fh > 0x8000)
    {
        return (-1);
    }
    return (-1);
    //return (__sys_ensure (fh));
}

/*--------------------------- _sys_flen --------------------------------------*/

long _sys_flen (FILEHANDLE fh)
{
    if (fh > 0x8000)
    {
        return (0);
    }
    return (-1);
    //return (__sys_flen (fh));
}

int _sys_tmpnam (char *name, int sig, unsigned maxlen)
{
    (void)(name);
    (void)(sig);
    (void)(maxlen);
    return (1);
}

char *_sys_command_string (char *cmd, int len)
{
    (void)(len);
    return (cmd);
}

void _sys_exit(int return_code)
{
    (void)(return_code);
label:
    goto label;  /* endless loop */
}

int system(const char * cmd)
{
    (void)(cmd);
    return (0);
}

time_t time(time_t * timer)
{
    time_t current;

    current = 0; // To Do !! No RTC implemented

    if (timer != NULL)
    {
        *timer = current;
    }

    return (current);
}
