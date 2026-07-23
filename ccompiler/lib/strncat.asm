* ====================================================================
* strncat.asm -- shared counted string-concatenate runtime (strncat).
* Only c.link carries this copy; moved to the shared library so the
* program module stays lean.  StrNCat(dst,src,n): appends up to n.
* Self-contained: no parameters, no external references.
*
* C prototype:  char *strncat(char *dst, char *src, int n);   returns dst
* ====================================================================

strncat             pshs      u         save frame pointer
                    ldu       $06,s     source string
                    leas      -2,s       cursor local
                    ldd       $06,s     destination pointer
                    std       ,s        init cursor
@StrNCatScan         ldx       ,s        scan destination
                    leax      $01,x     advance cursor
                    stx       ,s        store cursor
                    ldb       -$01,x    destination byte
                    bne       @StrNCatScan find end of destination
                    ldd       ,s        cursor
                    addd      #$FFFF    back up onto nul
                    std       ,s        store cursor
@StrNCatLoop         ldd       $0a,s     remaining count
                    addd      #$FFFF    decrement count
                    std       $0a,s     save remaining byte count
                    subd      #$FFFF    test if count reached zero
                    ble       @PadZero  stop when count exhausted
                    ldb       ,u+       fetch next source byte
                    ldx       ,s        load destination pointer
                    leax      $01,x     advance destination pointer
                    stx       ,s        save destination pointer
                    stb       -$01,x    store byte at destination
                    bne       @StrNCatLoop continue while byte nonzero
@PadZero             ldd       $0a,s     reload remaining count
                    bge       @StrncpyDone skip padding if none left
                    clra                prepare zero byte
                    clrb                prepare zero byte
                    stb       [,s]      null-terminate destination
@StrncpyDone         ldd       $06,s     return original pointer
                    puls      pc,u,x    return to caller

