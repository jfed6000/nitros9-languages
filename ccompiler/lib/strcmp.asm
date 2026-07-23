* ====================================================================
* strcmp.asm -- shared string-compare runtime (strcmp).
*
* The Microware C runtime's strcmp, factored out of the compiler
* modules that carry an identical copy (cc1, c.pass2, c.link).  Pulled
* in with "use lib/strcmp.asm" where each module's copy sits.
*
* StrCmp(a, b): compares the NUL-terminated strings (a = $04,s, b via
* $06,s), returning the signed byte difference, zero when equal.
*
* Self-contained: no parameters, no external references; every branch
* target (StrCmpNext/StrCmpAdv/StrCmpLoop) is internal.  The entry is
* uncalled in cc1 and c.pass2 (dead runtime code the object retains),
* so only c.link's call sites reference it and no repointing is needed.
*
* C prototype:  int   strcmp(char *s1, char *s2)
* ====================================================================

strcmp              pshs      u         save the caller u register
                    ldu       4,s       first string
                    bra       @StrCmpLoop start comparing
@StrCmpNext          ldx       6,s       second string pointer
                    leax      1,x       advance it
                    stx       6,s       store pointer
                    ldb       -1,x      second string byte
                    bne       @StrCmpAdv continue while nonzero
                    clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u      strings equal
@StrCmpAdv           leau      1,u       advance first string
@StrCmpLoop          ldb       ,u        first string byte
                    sex                 sign extend to word
                    pshs      d         save it
                    ldb       [8,s]     second string byte
                    sex                 sign extend to word
                    cmpd      ,s++      compare bytes
                    beq       @StrCmpNext equal keep scanning
                    ldb       [6,s]     second string byte
                    sex                 sign extend to word
                    pshs      d         save it
                    ldb       ,u        first string byte
                    sex                 sign extend to word
                    subd      ,s++      return difference
                    puls      pc,u      return to caller

