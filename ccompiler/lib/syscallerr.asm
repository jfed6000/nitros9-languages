* ====================================================================
* syscallerr.asm -- shared OS-9 syscall error/return tails.
*
* SyscallErr : store errno and return -1  (D = $FFFF).
* SyscallRet : on carry fall through to SyscallErr, else return 0.
* The low-level file wrappers end here.  Identical in all eight modules
* bar the errno cell name; each supplies "Errno equ <its cell>" and
* points its own tail names at SyscallErr / SyscallRet.
*
* Role:         internal: syscall error/return tails (store errno & return -1, or return status)
* ====================================================================

SyscallErr          clra                high errno byte zero
                    std       Errno,y   store errno
                    ldd       #$FFFF    return minus one
                    rts                 return error

SyscallRet          bcs       SyscallErr error sets errno
                    clra                clear high result
                    clrb                clear low result
                    rts                 return success
