********************************************************************
* createheada_check - build-time validation harness for createheada
*
* createheada.asm is a create-file prologue that falls through into the
* shared tail (createtail.asm).  This harness assembles the two together
* with a stubbed SyscallErr, proving the prologue stays valid and its
* fall-through and CreateExists reference resolve.  The module it emits
* is not used by anything.
********************************************************************

                    nam       createheada_check
                    ttl       validation harness for the create head A

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckcra/
                    fcb       edition

_start              use       createheada.asm
                    use       createtail.asm

SyscallErr          rts                 stub errno tail

                    emod
eom                 equ       *

                    end
