********************************************************************
* imul_check - build-time validation harness for imul.asm
*
* imul.asm is a source include: each compiler module pulls it in with
* "use lib/imul.asm" where its multiply routine reaches the full-width
* path.  Unlike cstart it takes no parameters and references no external
* symbols, so this harness only has to wrap it in a throwaway module and
* assemble it, proving imul.asm stays syntactically valid.  The module it
* emits is not used by any compiler component.
********************************************************************

                    nam       imul_check
                    ttl       validation harness for the shared multiply

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $01

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckimul/
                    fcb       edition

_start              use       imul.asm

                    emod
eom                 equ       *

                    end
