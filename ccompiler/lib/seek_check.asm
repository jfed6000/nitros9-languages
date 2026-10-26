********************************************************************
* seek_check - build-time validation harness for lib/seek.asm
*
* seek.asm reaches Errno and the long-value staging cells HighResultWord
* / LowResultWord, which each real module supplies.  This harness gives
* them stand-in storage, wraps the include in a throwaway module and
* assembles it, proving it stays valid and self-consistent.  The module
* it emits is not used by anything.
********************************************************************

                    nam       seek_check
                    ttl       validation harness for lib/seek.asm

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
Errno               rmb       2         stand-in errno cell
LowResultWord       rmb       2         stand-in long-value low cell
HighResultWord      rmb       2         stand-in long-value high cell
size                equ       .

name                fcs       /ckseek/
                    fcb       edition

_start              use       seek.asm

                    emod
eom                 equ       *

                    end
