* ====================================================================
* strncmp.asm -- shared counted string-compare runtime (strncmp).
* Only c.link carries this copy; moved to the shared library so the
* program module stays lean.  StrNCmp(a,b,n): compares up to n bytes.
* Self-contained: no parameters, no external references.
*
* C prototype:  int   strncmp(char *s1, char *s2, int n)
* ====================================================================

strncmp             pshs      u         save the caller u register
                    ldu       4,s       first string
                    bra       @StrNCmpLoop start comparing
@StrNCmpNext         ldx       6,s       second string pointer
                    leax      1,x       advance it
                    stx       6,s       store pointer
                    ldb       -1,x      second string byte
                    bne       @StrNCmpAdv continue while nonzero
                    clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u      equal within count
@StrNCmpAdv          leau      1,u       advance first string
@StrNCmpLoop         ldd       8,s       remaining count
                    addd      #$FFFF    minus one
                    std       8,s       decrement count
                    subd      #$FFFF    restore value
                    ble       @StrNCmpCheck count exhausted
                    ldb       ,u        first string byte
                    sex                 sign extend to word
                    pshs      d         save it
                    ldb       [8,s]     second string byte
                    sex                 sign extend to word
                    cmpd      ,s++      compare bytes
                    beq       @StrNCmpNext equal keep scanning
@StrNCmpCheck        ldd       8,s       remaining count
                    bge       @StrNCmpDiff count not exhausted
                    clra                clear high byte
                    clrb                clear low byte
                    bra       @StrNCmpRet equal within count
@StrNCmpDiff         ldb       [6,s]     sign extend to word
                    sex                 save it
                    pshs      d         first string byte
                    ldb       ,u        sign extend to word
                    sex                 return difference
                    subd      ,s++
@StrNCmpRet          puls      pc,u      return to caller

