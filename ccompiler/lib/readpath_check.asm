********************************************************************
* readpath_check - build-time validation harness for the read wrappers
*
* readpath.asm holds ReadPath/ReadLnPath, which branch to SyscallErr
* (normally from lib/syscallerr.asm).  This harness stubs that tail,
* wraps the include in a throwaway module and assembles it, proving it
* stays valid and self-consistent.  The module it emits is not used by
* anything.
********************************************************************

                    nam       readpath_check
                    ttl       validation harness for the read wrappers

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckrd/
                    fcb       edition

_start              use       readpath.asm

SyscallErr          rts                 stub errno tail

                    emod
eom                 equ       *

                    end
