* ====================================================================
* imul.asm -- shared 16x16 -> 32 multiply (runtime helper).
*
* The Microware C runtime's word multiply, factored out of the compiled
* compiler modules and pulled in with "use lib/imul.asm".  Structurally
* identical across every module (some spell it with pshs b,a / decimal
* offsets, all assemble to the same bytes).
*
* MulEntry is the public entry: it takes the 8x8 fast path when both
* operands fit in a byte, otherwise falls into MulFull for the full
* 16x16 multiply.  Self-contained: operands and the running accumulator
* live entirely on the stack, there are no data-global or external
* references, and every label (MulFull, MulAcc1, MulAcc2) is internal.
*
* Entry:  the two 16-bit operands sit in the caller's frame (d and
*         $02,s); returns the 32-bit product in x:d.
*
* Runtime:      compiler runtime: 16 x 16 -> 16 multiply (emitted for *)
* ====================================================================

MulEntry            tsta                is the first operand's high byte zero
                    bne       @MulFull  no, take the full multiply
                    tst       2,s       is the second operand's high byte zero
                    bne       @MulFull  no, take the full multiply
                    lda       3,s       both fit in eight bits: load one
                    mul                 eight-by-eight multiply
                    ldx       ,s        zero for the high result word
                    stx       2,s       store the zero high word
                    ldx       #0        the product high word is zero
                    std       ,s        store the product low word
                    puls      pc,d      return the 32-bit product
@MulFull             pshs      d         save the operands
                    ldd       #0        zero accumulator
                    pshs      d         push zero high word
                    pshs      d         push zero low word
                    lda       5,s       first low byte
                    ldb       9,s       second low byte
                    mul                 partial product
                    std       2,s       store it
                    lda       5,s       first low byte
                    ldb       8,s       second high byte
                    mul                 partial product
                    addd      1,s       add running total
                    std       1,s       store it
                    bcc       @MulAcc1  skip carry
                    inc       ,s        propagate the carry
@MulAcc1             lda       4,s       first high byte
                    ldb       9,s       second low byte
                    mul                 partial product
                    addd      1,s       add running total
                    std       1,s       store it
                    bcc       @MulAcc2  skip carry
                    inc       ,s        propagate the carry
@MulAcc2             lda       4,s       first high byte
                    ldb       8,s       second high byte
                    mul                 partial product
                    addd      ,s        add running total
                    std       ,s        store it
                    ldx       6,s       gather low result
                    stx       8,s       place low result
                    ldx       ,s        load high result
                    ldd       2,s       load low result
                    leas      8,s       drop the temporaries
                    rts                 return the product

