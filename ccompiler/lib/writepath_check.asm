********************************************************************
* writepath_check - build-time validation harness for writepath.asm
*
* writepath.asm branches to SyscallErr (the module's errno tail) on a
* failed write; this harness stubs it, wraps the include in a throwaway
* module and assembles it, proving the include stays valid.
********************************************************************

                    nam       writepath_check
                    ttl       validation harness for the write wrappers

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $01

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckwrt/
                    fcb       edition

_start              use       writepath.asm
SyscallErr          rts                 stub errno tail

                    emod
eom                 equ       *

                    end
