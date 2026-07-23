********************************************************************
* pathops_check - build-time validation harness for the path wrappers
*
* openpath/closepath/deletepath.asm are small syscall wrappers that
* branch to SyscallErr/SyscallRet (normally from lib/syscallerr.asm).
* This harness stubs those two tails, wraps the three includes in a
* throwaway module and assembles them, proving they stay valid and
* self-consistent.  The module it emits is not used by anything.
********************************************************************

                    nam       pathops_check
                    ttl       validation harness for the path wrappers

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckpth/
                    fcb       edition

_start              use       openpath.asm
                    use       closepath.asm
                    use       deletepath.asm

SyscallErr          rts                 stub errno tail
SyscallRet          rts                 stub return tail

                    emod
eom                 equ       *

                    end
