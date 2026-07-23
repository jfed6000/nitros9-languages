********************************************************************
* deletepath - delete a file by pathname
*
* Shared C runtime delete wrapper.  Called with a pathname pointer on
* the stack; returns through SyscallRet (from lib/syscallerr.asm).
*
* Each module pulls this in with "use lib/deletepath.asm"; modules that
* call it point their own name at DeletePath via an equ alias (some
* carry the routine as unreferenced runtime and need no alias).
*
* C prototype:  int  unlink(char *path)
********************************************************************

unlink              ldx       $02,s     load pathname pointer
                    os9       I$Delete  delete the file
                    lbra      SyscallRet return result
