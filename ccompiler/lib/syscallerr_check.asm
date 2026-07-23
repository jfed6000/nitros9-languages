********************************************************************
* syscallerr_check - build-time validation harness for syscallerr.asm
*
* syscallerr.asm stores to Errno,y (the module's errno cell); this
* harness declares a stub Errno in a throwaway module's data area and
* assembles the include, proving it stays valid.
********************************************************************

                    nam       syscallerr_check
                    ttl       validation harness for the syscall tails

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $01

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
Errno               rmb       2         stub errno cell
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /cksys/
                    fcb       edition

_start              use       syscallerr.asm

                    emod
eom                 equ       *

                    end
