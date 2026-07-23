********************************************************************
* fcloseflush_check - build-time validation harness for fclose/fflush
*
* fclose.asm and fflush.asm call the per-module helpers FlushStream,
* ClosePath, GetBuf and FlushBuf.  This harness stubs those, wraps the
* two includes in a throwaway module and assembles them with the FILE
* offsets from stdio.d, proving they stay valid and self-consistent.
* The module it emits is not used by anything.
********************************************************************

                    nam       fcloseflush_check
                    ttl       validation harness for fclose and fflush

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckfcf/
                    fcb       edition

_start              use       fclose.asm
                    use       fflush.asm

FlushStream         rts                 stub flush-stream helper
close               rts                 stub close-path helper
GetBuf              rts                 stub buffer-allocate helper
FlushBuf            rts                 stub buffer-flush helper

                    emod
eom                 equ       *

                    end
