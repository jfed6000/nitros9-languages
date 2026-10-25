* ====================================================================
* strncat.asm -- shared counted string-concatenate runtime (strncat).
* Only c.link carries this copy; moved to the shared library so the
* program module stays lean.  StrNCat(dst,src,n): appends up to n.
* Self-contained: no parameters, no external references.
*
* C prototype:  char *strncat(char *dst, char *src, int n);   returns dst
* ====================================================================

strncat             pshs      u         save the caller u register
                    ldu       6,s       source string
                    leas      -2,s       cursor local
                    ldd       6,s       destination pointer
                    std       ,s        init cursor
@StrNCatScan         ldx       ,s        scan destination
                    leax      1,x       advance cursor
                    stx       ,s        store cursor
                    ldb       -1,x      destination byte
                    bne       @StrNCatScan find end of destination
                    ldd       ,s        cursor
                    addd      #$FFFF    back up onto nul
                    std       ,s        store cursor
@StrNCatLoop         ldd       10,s      remaining count
                    addd      #$FFFF    decrement count
                    std       10,s      save remaining byte count
                    subd      #$FFFF    test if count reached zero
                    ble       @PadZero  stop when count exhausted
                    ldb       ,u+       fetch next source byte
                    ldx       ,s        load destination pointer
                    leax      1,x       advance destination pointer
                    stx       ,s        save destination pointer
                    stb       -1,x      store byte at destination
                    bne       @StrNCatLoop continue while byte nonzero
@PadZero             ldd       10,s      reload remaining count
                    bge       @StrncpyDone skip padding if none left
                    clra                prepare zero byte
                    clrb                prepare zero byte
                    stb       [,s]      null-terminate destination
@StrncpyDone         ldd       6,s       return original pointer
                    puls      pc,u,x    return to caller

