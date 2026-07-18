* ====================================================================
* shift.asm -- shared multi-bit shift runtime (>> and <<).
*
* The Microware C runtime's word shift-by-count helpers, factored out of
* the compiled compiler modules.  Structurally identical across every
* module (some spell shift-left "lsl", the 6809 synonym of "asl"), so it
* is pulled in with "use lib/shift.asm" at the point each module's shift
* routine sits.
*
* Three entry points share one ShiftDone tail.  The value being shifted
* lives in the caller's frame at $02,s (high word) / $03,s (low byte);
* B holds the shift count.  On return d = the shifted result.
*   AsrEntry  arithmetic shift right (signed   >>) -- sign-propagating
*   LsrEntry  logical    shift right (unsigned >>) -- zero-filling
*   AslEntry  shift left            (         <<)
*
* Self-contained: no parameters, no external references; every branch
* target (AsrLoop/LsrLoop/AslLoop/ShiftTail) is internal.  A module that
* does not call one of the entries still carries it -- the runtime object
* is linked whole -- so the unused entry is simply never reached there.
* ====================================================================

AsrEntry            tstb                is the shift count zero
                    beq       ShiftTail nothing to shift
AsrLoop             asr       $02,s     arithmetic shift right high byte
                    ror       $03,s     rotate low byte
                    decb                decrement the count
                    bne       AsrLoop   loop for the count
                    bra       ShiftTail go return the result

LsrEntry            tstb                is the shift count zero
                    beq       ShiftTail nothing to shift
LsrLoop             lsr       $02,s     logical shift right high byte
                    ror       $03,s     rotate low byte
                    decb                decrement the count
                    bne       LsrLoop   loop for the count
ShiftTail           ldd       $02,s     load the shifted result
                    pshs      d         save it
                    ldd       $02,s     load result again
                    std       $04,s     place it
                    ldd       ,s        load return value
                    leas      $04,s     drop the temporary
                    rts                 return

AslEntry            tstb                is the shift count zero
                    beq       ShiftTail nothing to shift
AslLoop             asl       $03,s     shift left low byte
                    rol       $02,s     rotate high byte
                    decb                decrement the count
                    bne       AslLoop   loop for the count
                    bra       ShiftTail go return the result
