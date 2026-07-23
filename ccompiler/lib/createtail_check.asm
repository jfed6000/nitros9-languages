********************************************************************
* createtail_check - build-time validation harness for createtail
*
* createtail.asm holds CreateOk/CreateExists, which branch to SyscallErr
* (normally from lib/syscallerr.asm).  This harness stubs that tail,
* wraps the include in a throwaway module and assembles it, proving it
* stays valid and self-consistent.  The module it emits is not used by
* anything.
********************************************************************

                    nam       createtail_check
                    ttl       validation harness for the create tail

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $01

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckcrt/
                    fcb       edition

_start              use       createtail.asm

SyscallErr          rts                 stub errno tail

                    emod
eom                 equ       *

                    end
