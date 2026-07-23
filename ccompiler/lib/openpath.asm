********************************************************************
* openpath - open an existing file by pathname
*
* Shared C runtime open wrapper.  Called with a pathname pointer and
* open mode on the stack; returns the OS-9 path number, or drops into
* SyscallErr (from lib/syscallerr.asm) on failure.
*
* Each module pulls this in with "use lib/openpath.asm" and points its
* own call name at OpenSysPath via an equ alias.  The canonical label is
* deliberately distinct: OpenFile and OpenPath both name unrelated
* higher-level routines in some modules.
*
* C prototype:  int   open(char *path, int mode);   returns path number
********************************************************************

open                ldx       $02,s     load pathname pointer
                    lda       $05,s     load open mode
                    os9       I$Open    open the file
                    lbcs      SyscallErr return error
                    tfr       a,b       path number to result
                    clra                clear high byte
                    rts                 return path number
