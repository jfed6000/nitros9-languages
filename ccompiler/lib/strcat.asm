* ====================================================================
* strcat.asm -- shared string-concatenate runtime (strcat).
*
* The Microware C runtime's strcat, factored out of the compiler
* modules that carry an identical copy (cc1, c.prep, c_asm, c.link).
* Pulled in with "use lib/strcat.asm" where each module's copy sits.
*
* StrCat(dst, src): scans dst to its NUL, then appends the string at
* src, returning dst.  dst/src come from the caller frame at $06,s; a
* 2-byte cursor lives in the local frame.
*
* Self-contained: no parameters, no external references; both branch
* targets (StrCatScan/StrCatLoop) are internal.  The entry is uncalled
* in every module that carries it (dead runtime code that the linked
* object retains), so there are no call sites to repoint.
*
* C prototype:  char *strcat(char *dst, char *src);   returns dst
* ====================================================================

strcat              pshs      u         save frame pointer
                    ldu       $06,s     source string
                    leas      -2,s       cursor local
                    ldd       $06,s     destination pointer
                    std       ,s        init cursor
@StrCatScan          ldx       ,s        scan destination
                    leax      $01,x     advance cursor
                    stx       ,s        store cursor
                    ldb       -$01,x    destination byte
                    bne       @StrCatScan find end of destination
                    ldd       ,s        cursor
                    addd      #$FFFF    back up onto nul
                    std       ,s        store cursor
@StrCatLoop          ldb       ,u+       next source byte
                    ldx       ,s        destination cursor
                    leax      $01,x     advance cursor
                    stx       ,s        store cursor
                    stb       -$01,x    append byte
                    bne       @StrCatLoop until nul appended
                    ldd       $06,s     return destination
                    puls      pc,u,x    return to caller

