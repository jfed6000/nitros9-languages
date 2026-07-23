********************************************************************
* shift_check - build-time validation harness for shift.asm
*
* shift.asm is a source include pulled into each module with
* "use lib/shift.asm".  It takes no parameters and references no
* external symbols, so this harness only has to wrap it in a throwaway
* module and assemble it, proving shift.asm stays syntactically valid.
* The module it emits is not used by any compiler component.
********************************************************************

                    nam       shift_check
                    ttl       validation harness for the shared shifts

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckshft/
                    fcb       edition

_start              use       shift.asm

                    emod
eom                 equ       *

                    end
