********************************************************************
* setstat - I$SetStt wrapper taking X and U parameters
*
* Shared C runtime setstat helper.  Loads the X and U parameters from
* the stack, issues the set-status call, and returns through SyscallRet
* (from lib/syscallerr.asm).
*
* Each module pulls this in with "use lib/setstat.asm".
*
* Convention:   setstat helper: A=path, B=status code, X=arg3, U=arg4
********************************************************************

SetStatXU           pshs      u         save the caller u register
                    ldx       8,s       load the x parameter
                    ldu       10,s      load the u parameter
                    os9       I$SetStt  set file status
                    puls      u         restore the caller u register
                    lbra      SyscallRet return the status
