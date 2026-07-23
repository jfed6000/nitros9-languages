********************************************************************
* closepath - close an open path
*
* Shared C runtime close wrapper.  Called with a path number on the
* stack; returns through SyscallRet (from lib/syscallerr.asm), which
* yields zero on success or the errno result on failure.
*
* Each module pulls this in with "use lib/closepath.asm" and points its
* own call name at ClosePath via an equ alias.
*
* C prototype:  int   close(int path)
********************************************************************

close               lda       $03,s     load path number
                    os9       I$Close   close the file
                    lbra      SyscallRet return result
