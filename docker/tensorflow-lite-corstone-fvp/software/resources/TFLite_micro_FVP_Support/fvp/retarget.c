#include <stdio.h>
#include <rt_sys.h>
#include <stdint.h>
#include <string.h>
#include <uart.h>

#ifdef STANDALONE
#define USE_SERIAL_PORT
__asm(".global __use_no_semihosting");
#endif

/**
   Writes the character specified by c (converted to an unsigned char) to
   the output stream pointed to by stream, at the position indicated by the
   associated file position indicator (if defined), and advances the
   indicator appropriately. If the file position indicator is not defined,
   the character is appended to the output stream.
 
  \param[in] c       Character
  \param[in] stream  Stream handle
 
  \return    The character written. If a write error occurs, the error
             indicator is set and fputc returns EOF.
*/
__attribute__((weak))
/*int fputc (int c, FILE * stream) 
{
    if (stream == &__stdout) {
        return (uart_putc_polled(c));
    }

    return (-1);
    } */
int fputc(int ch, FILE *f)
{
    unsigned char tempch = ch;
    if (tempch == '\n') uart_putc_polled('\r');
    uart_putc_polled(tempch);
    return ch;
}

/* IO device file handles. */
#define FH_STDIN    0x8001
#define FH_STDOUT   0x8002
#define FH_STDERR   0x8003

const char __stdin_name[]  = ":STDIN";
const char __stdout_name[] = ":STDOUT";
const char __stderr_name[] = ":STDERR";

#define RETARGET_SYS        1
#define RTE_Compiler_IO_STDOUT  1
#define RTE_Compiler_IO_STDERR  1
/**
  Defined in rt_sys.h, this function opens a file.
 
  The _sys_open() function is required by fopen() and freopen(). These
  functions in turn are required if any file input/output function is to
  be used.
  The openmode parameter is a bitmap whose bits mostly correspond directly to
  the ISO mode specification. Target-dependent extensions are possible, but
  freopen() must also be extended.
 
  \param[in] name     File name
  \param[in] openmode Mode specification bitmap
 
  \return    The return value is ?1 if an error occurs.
*/
#ifdef RETARGET_SYS
__attribute__((weak))
FILEHANDLE _sys_open (const char *name, int openmode) {
#if (!defined(RTE_Compiler_IO_File))
  (void)openmode;
#endif
 
  if (name == NULL) {
    return (-1);
  }
 
  if (name[0] == ':') {
    if (strcmp(name, ":STDIN") == 0) {
      return (FH_STDIN);
    }
    if (strcmp(name, ":STDOUT") == 0) {
      return (FH_STDOUT);
    }
    if (strcmp(name, ":STDERR") == 0) {
      return (FH_STDERR);
    }
    return (-1);
  }
 
#ifdef RTE_Compiler_IO_File
#ifdef RTE_Compiler_IO_File_FS
  return (__sys_open(name, openmode));
#endif
#else
  return (-1);
#endif
}
#endif
 
 
/**
  Defined in rt_sys.h, this function closes a file previously opened
  with _sys_open().
  
  This function must be defined if any input/output function is to be used.
 
  \param[in] fh File handle
 
  \return    The return value is 0 if successful. A nonzero value indicates
             an error.
*/
#ifdef RETARGET_SYS
__attribute__((weak))
int _sys_close (FILEHANDLE fh) {
 
  switch (fh) {
    case FH_STDIN:
      return (0);
    case FH_STDOUT:
      return (0);
    case FH_STDERR:
      return (0);
  }
 
#ifdef RTE_Compiler_IO_File
#ifdef RTE_Compiler_IO_File_FS
  return (__sys_close(fh));
#endif
#else
  return (-1);
#endif
}
#endif
 
 
/**
  Defined in rt_sys.h, this function writes the contents of a buffer to a file
  previously opened with _sys_open().
 
  \note The mode parameter is here for historical reasons. It contains
        nothing useful and must be ignored.
 
  \param[in] fh   File handle
  \param[in] buf  Data buffer
  \param[in] len  Data length
  \param[in] mode Ignore this parameter
 
  \return    The return value is either:
             - a positive number representing the number of characters not
               written (so any nonzero return value denotes a failure of
               some sort)
             - a negative number indicating an error.
*/
#ifdef RETARGET_SYS
__attribute__((weak))
int _sys_write (FILEHANDLE fh, const uint8_t *buf, uint32_t len, int mode) {
#if (defined(RTE_Compiler_IO_STDOUT) || defined(RTE_Compiler_IO_STDERR))
  int ch;
#elif (!defined(RTE_Compiler_IO_File))
  (void)buf;
  (void)len;
#endif
  (void)mode;
 
  switch (fh) {
    case FH_STDIN:
      return (-1);
    case FH_STDOUT:
#ifdef RTE_Compiler_IO_STDOUT
      for (; len; len--) {
        ch = *buf++;
#if (STDOUT_CR_LF != 0)
        if (ch == '\n') uart_putc_polled('\r');
#endif
        uart_putc_polled(ch);
      }
#endif
      return (0);
    case FH_STDERR:
/*#ifdef RTE_Compiler_IO_STDERR
      for (; len; len--) {
        ch = *buf++;
#if (STDERR_CR_LF != 0)
        if (ch == '\n') stderr_putchar('\r');
#endif
        stderr_putchar(ch);
      }
      #endif */
      return (0);
  }
 
#ifdef RTE_Compiler_IO_File
#ifdef RTE_Compiler_IO_File_FS
  return (__sys_write(fh, buf, len));
#endif
#else
  return (-1);
#endif
}
#endif
 
 
/**
  Defined in rt_sys.h, this function reads the contents of a file into a buffer.
 
  Reading up to and including the last byte of data does not turn on the EOF
  indicator. The EOF indicator is only reached when an attempt is made to read
  beyond the last byte of data. The target-independent code is capable of
  handling:
    - the EOF indicator being returned in the same read as the remaining bytes
      of data that precede the EOF
    - the EOF indicator being returned on its own after the remaining bytes of
      data have been returned in a previous read.
 
  \note The mode parameter is here for historical reasons. It contains
        nothing useful and must be ignored.
 
  \param[in] fh   File handle
  \param[in] buf  Data buffer
  \param[in] len  Data length
  \param[in] mode Ignore this parameter
 
  \return     The return value is one of the following:
              - The number of bytes not read (that is, len - result number of
                bytes were read).
              - An error indication.
              - An EOF indicator. The EOF indication involves the setting of
                0x80000000 in the normal result.
*/
#ifdef RETARGET_SYS
__attribute__((weak))
int _sys_read (FILEHANDLE fh, uint8_t *buf, uint32_t len, int mode) {
#ifdef RTE_Compiler_IO_STDIN
  int ch;
#elif (!defined(RTE_Compiler_IO_File))
  (void)buf;
  (void)len;
#endif
  (void)mode;
 
  switch (fh) {
    case FH_STDIN:
#ifdef RTE_Compiler_IO_STDIN
      ch = stdin_getchar();
      if (ch < 0) {
        return ((int)(len | 0x80000000U));
      }
      *buf++ = (uint8_t)ch;
#if (STDIN_ECHO != 0)
      uart_putc_polled(ch);
#endif
      len--;
      return ((int)(len));
#else
      return ((int)(len | 0x80000000U));
#endif
    case FH_STDOUT:
      return (-1);
    case FH_STDERR:
      return (-1);
  }
 
#ifdef RTE_Compiler_IO_File
#ifdef RTE_Compiler_IO_File_FS
  return (__sys_read(fh, buf, len));
#endif
#else
  return (-1);
#endif
}
#endif
 
 

 
 
/**
  Defined in rt_sys.h, this function determines if a file handle identifies
  a terminal.
 
  When a file is connected to a terminal device, this function is used to
  provide unbuffered behavior by default (in the absence of a call to
  set(v)buf) and to prohibit seeking.
 
  \param[in] fh File handle
 
  \return    The return value is one of the following values:
             - 0:     There is no interactive device.
             - 1:     There is an interactive device.
             - other: An error occurred.
*/
#ifdef RETARGET_SYS
__attribute__((weak))
int _sys_istty (FILEHANDLE fh) {
 
  switch (fh) {
    case FH_STDIN:
      return (1);
    case FH_STDOUT:
      return (1);
    case FH_STDERR:
      return (1);
  }
 
  return (0);
}
#endif
 
 
/**
  Defined in rt_sys.h, this function puts the file pointer at offset pos from
  the beginning of the file.
 
  This function sets the current read or write position to the new location pos
  relative to the start of the current file fh.
 
  \param[in] fh  File handle
  \param[in] pos File pointer offset
 
  \return    The result is:
             - non-negative if no error occurs
             - negative if an error occurs
*/
#ifdef RETARGET_SYS
__attribute__((weak))
int _sys_seek (FILEHANDLE fh, long pos) {
#if (!defined(RTE_Compiler_IO_File))
  (void)pos;
#endif
 
  switch (fh) {
    case FH_STDIN:
      return (-1);
    case FH_STDOUT:
      return (-1);
    case FH_STDERR:
      return (-1);
  }
 
#ifdef RTE_Compiler_IO_File
#ifdef RTE_Compiler_IO_File_FS
  return (__sys_seek(fh, (uint32_t)pos));
#endif
#else
  return (-1);
#endif
}
#endif
 
 
/**
  Defined in rt_sys.h, this function returns the current length of a file.
 
  This function is used by _sys_seek() to convert an offset relative to the
  end of a file into an offset relative to the beginning of the file.
  You do not have to define _sys_flen() if you do not intend to use fseek().
  If you retarget at system _sys_*() level, you must supply _sys_flen(),
  even if the underlying system directly supports seeking relative to the
  end of a file.
 
  \param[in] fh File handle
 
  \return    This function returns the current length of the file fh,
             or a negative error indicator.
*/
#ifdef RETARGET_SYS
__attribute__((weak))
long _sys_flen (FILEHANDLE fh) {
 
  switch (fh) {
    case FH_STDIN:
      return (0);
    case FH_STDOUT:
      return (0);
    case FH_STDERR:
      return (0);
  }
 
#ifdef RTE_Compiler_IO_File
#ifdef RTE_Compiler_IO_File_FS
  return (__sys_flen(fh));
#endif
#else
  return (0);
#endif
}
#endif
 

void _sys_exit(int n)
{
    (void)n;
while(1);
}

void _ttywrch(int ch)
{
    unsigned char tempch = ch;
    if (tempch == '\n') uart_putc_polled('\r');
    uart_putc_polled(tempch);
}
 
