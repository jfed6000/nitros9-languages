********************************************************************
* divide_check - build-time validation harness for divide.asm
*
* divide.asm is a source include pulled into each dividing module with
* "use lib/divide.asm".  It has one external reference -- the divide by
* zero path branches to DivSignal, the module's own signal raiser -- so
* this harness supplies a stand-in DivSignal, wraps the include in a
* throwaway module and assembles it, proving divide.asm stays valid.
* The module it emits is not used by any compiler component.
********************************************************************

                    nam       divide_check
                    ttl       validation harness for the shared divide

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckdiv/
                    fcb       edition

_start              use       divide.asm
SendSignal          rts                 stand-in divide by zero raiser

                    emod
eom                 equ       *

                    end
