********************************************************************
* access - test whether a file can be opened
*
* Shared C runtime access helper.  Opens the named file with the given
* mode and immediately closes it, returning through SyscallRet (from
* lib/syscallerr.asm); the open failure is reported as the result.
*
* Each module pulls this in with "use lib/access.asm"; modules that call
* it reference the access entry, the rest carry it as spare runtime.
*
* C prototype:  int   access(char *path, int mode)
********************************************************************

access              ldx       2,s       load the pathname
                    lda       5,s       load the access mode
                    os9       I$Open    open the file
                    bcs       @AccessDone failed to open
                    os9       I$Close   close it immediately
@AccessDone          lbra      SyscallRet return the status

