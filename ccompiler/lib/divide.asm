* ====================================================================
* divide.asm -- shared signed/unsigned integer divide runtime.
*
* The Microware C runtime's divide worker, factored out of the compiled
* compiler modules.  Structurally identical across every module that
* performs division (c.pass1, c.pass2, c.comp, c.opt, c_asm, c.link), so
* it is pulled in with "use lib/divide.asm" at the point each module's
* divide worker sits (immediately before the shift runtime).
*
* Two entry points share the normalize-and-restore bit loop:
*   UDivEntry  unsigned divide
*   SDivEntry  signed divide (records the result sign, works on the
*              absolute values, then re-applies the sign)
* The module's setup routine points DivideRoutinePointer at the wanted
* entry and calls it; the divisor arrives in d, the dividend in the
* caller frame, and it returns quotient in d / remainder in x.
*
* Each module repoints its divide call sites to UDivEntry / SDivEntry.
* One external reference: the divide-by-zero path loads error 45 and
* branches to SendSignal, the module's own signal raiser.  Four modules
* already name that routine SendSignal; c.opt and c.link name it
* RaiseSignal / RaiseError, so those two add a single "SendSignal equ
* <name>" alias.  Nothing else is needed and the bytes stay identical.
*
* Runtime:      compiler runtime: unsigned & signed 16-bit divide (emitted for / and %)
* ====================================================================

UDivEntry           subd      #0        test dividend value
                    beq       @DivZeroErr zero dividend is error
                    pshs      d         save dividend
                    leas      -2,s       reserve remainder space
                    clr       ,s        clear remainder
                    clr       1,s       clear remainder
                    bra       @DivNorm  enter normalization
@DivZeroErr          puls      d         restore dividend
                    std       ,s        place operand
                    ldd       #45       division error code
                    lbra      SendSignal raise division error
SDivEntry           subd      #0        test dividend value
                    beq       @DivZeroErr zero dividend is error
                    pshs      d         save dividend
                    leas      -2,s       reserve remainder space
                    clr       ,s        clear remainder
                    clr       1,s       clear remainder
                    tsta                test dividend sign
                    bpl       @DivDivisorSign dividend already positive
                    nega                negate dividend
                    negb                negate dividend
                    sbca      #0        negate dividend
                    inc       1,s       mark result sign flip
                    std       2,s       store absolute dividend
@DivDivisorSign      ldd       6,s       load divisor
                    bpl       @DivNorm  divisor already positive
                    nega                negate divisor
                    negb                negate divisor
                    sbca      #0        negate divisor
                    com       1,s       flip result sign
                    std       6,s       store absolute divisor
@DivNorm             lda       #1        init shift counter
@DivNormLoop         inca                count normalization shifts
                    asl       3,s       shift divisor left
                    rol       2,s       shift divisor left
                    bpl       @DivNormLoop until top bit set
                    sta       ,s        save shift count
                    ldd       6,s       load dividend
                    clr       6,s       clear quotient
                    clr       7,s       clear quotient
@DivTrialLoop          subd      2,s       trial subtract divisor
                    bcc       @DivBitSet subtract succeeded
                    addd      2,s       restore dividend
                    andcc     #$FE      clear quotient bit
                    bra       @DivBitShift finish this iteration
@DivBitSet           orcc      #$01      set quotient bit
@DivBitShift         rol       7,s       shift bit into quotient
                    rol       6,s       shift bit into quotient
                    lsr       2,s       shift divisor right
                    ror       3,s       shift divisor right
                    dec       ,s        decrement shift count
                    bne       @DivTrialLoop loop over all bits
                    std       2,s       store remainder
                    tst       1,s       test result sign flag
                    beq       @DivFinish quotient stays positive
                    ldd       6,s       load quotient
                    nega                negate quotient
                    negb                negate quotient
                    sbca      #0        negate quotient
                    std       6,s       store negated quotient
@DivFinish           ldx       4,s       save remainder pointer
                    ldd       6,s       load quotient
                    std       4,s       place quotient for return
                    stx       6,s       place remainder
                    ldx       2,s       load remainder
                    ldd       4,s       load quotient result
                    leas      6,s        clean local stack
                    rts                 return to caller

