********************************************************************
* flushbuffer_check - build-time validation harness for flushbuffer.asm
*
* flushbuffer.asm references four helpers each carrying module supplies
* (FileTell/SeekFile/WriteLnPath/WritePath).  This harness stubs them,
* wraps the include in a throwaway module and assembles it, proving the
* include stays valid.  The module it emits is not used by anything.
********************************************************************

                    nam       flushbuffer_check
                    ttl       validation harness for the buffered flush

                    use       ../defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       1

                    mod       eom,name,tylg,atrv,_start,size

                    org       0
                    rmb       16        stand-in data area
size                equ       .

name                fcs       /ckflsh/
                    fcb       edition

_start              use       flushbuffer.asm
FileTell            rts                 stub file-position helper
lseek               rts                 stub seek helper
writeln             rts                 stub line-write helper
write               rts                 stub raw-write helper

                    emod
eom                 equ       *

                    end
