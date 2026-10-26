********************************************************************
* statwrap_check - build-time validation harness for the leaf wrappers
*
* getstat/setstat/access.asm branch to SyscallErr/SyscallRet (normally
* from lib/syscallerr.asm).  This harness stubs those tails, wraps the
* three includes in a throwaway module and assembles them, proving they
* stay valid and self-consistent.  The module it emits is not used by
* anything.
********************************************************************

                    nam       statwrap_check
                    ttl       validation harness for the leaf wrappers

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckstt/
                    fcb       edition

_start              use       getstat.asm
                    use       setstat.asm
                    use       access.asm

SyscallErr          rts                 stub errno tail
SyscallRet          rts                 stub return tail

                    emod
eom                 equ       *

                    end
