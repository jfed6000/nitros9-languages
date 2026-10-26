********************************************************************
* string_check - build-time validation harness for the string includes
*
* strcpy/strcat/strlen/strcmp/strncpy.asm are self-contained includes
* (no parameters, no external references), each pulled into the compiler
* modules with "use lib/<name>.asm".  This harness wraps them all in a
* throwaway module and assembles them, proving they stay valid and
* self-consistent.  The module it emits is not used by anything.
********************************************************************

                    nam       string_check
                    ttl       validation harness for the shared strings

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckstr/
                    fcb       edition

_start              use       strcpy.asm
                    use       strcat.asm
                    use       strlen.asm
                    use       strcmp.asm
                    use       strncpy.asm
                    use       strncmp.asm
                    use       strncat.asm
                    use       memcpy.asm

                    emod
eom                 equ       *

                    end
