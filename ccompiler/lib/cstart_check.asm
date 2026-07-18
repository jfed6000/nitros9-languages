********************************************************************
* cstart_check - build-time validation harness for cstart.asm
*
* cstart.asm is a source include: each compiler module pulls it in with
* "use lib/cstart.asm" and supplies the three parameters, the four
* imported symbols and the OS-9 defs.  It therefore cannot assemble on
* its own.  This harness supplies representative stand-ins and includes
* it, so "make" in this directory proves cstart.asm still assembles
* cleanly (a syntax and interface check).  The module it emits is a
* throwaway and is not used by any compiler component.
********************************************************************

                    nam       cstart_check
                    ttl       validation harness for the shared C startup

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $01

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       2400      stand-in data area
size                equ       .

name                fcs       /ckstart/
                    fcb       edition

* representative per-module cstart parameters
RTBASE              equ       $01BF     runtime-globals block base in the data area
DATAEND             equ       $05E1     end of static data / heap start / stack limit
HDRADV              equ       $002D     advance to where the non-DP data starts

                    use       cstart.asm

* imported symbols the startup references (stubbed for the check)
main                rts
exit                rts
_exit               rts
WorkBlockImage      fdb       0,0,0

                    emod
eom                 equ       *

                    end
