* ====================================================================
* strncpy.asm -- shared counted string-copy runtime (strncpy).
*
* The Microware C runtime's strncpy.  Only c.link currently carries a
* copy, but it belongs in the shared library like the other string
* helpers; pulled in with "use lib/strncpy.asm" where the routine sits.
*
* StrNCopy(dst, src, n): copies up to n bytes of the NUL-terminated
* string at src into dst, NUL-padding the remainder to n bytes, and
* returns dst.  dst/src = $06,s, count = $0a,s (src is loaded into u as
* the working source pointer); a 2-byte cursor lives on the stack.
* args and locals are addressed off s; u is not a frame pointer here.
*
* Self-contained: no parameters, no external references; every branch
* target (StrNCopyLoop/PadLoop/PadCheck) is internal.
*
* C prototype:  char *strncpy(char *dst, char *src, int n);   returns dst
* ====================================================================

strncpy             pshs      u         save the caller u register
                    ldu       6,s       source string
                    leas      -2,s       cursor local
                    ldd       6,s       destination pointer
                    std       ,s        init cursor
@StrNCopyLoop        ldd       10,s      remaining count
                    addd      #$FFFF    minus one
                    std       10,s      decrement count
                    subd      #$FFFF    restore value
                    ble       @PadCheck count exhausted
                    ldb       ,u+       source byte
                    ldx       ,s        destination cursor
                    leax      1,x       advance cursor
                    stx       ,s        store cursor
                    stb       -1,x      copy byte
                    bne       @StrNCopyLoop until nul or count
                    bra       @PadCheck go pad remainder
@PadLoop             clra                pad byte nul
                    clrb                clear low byte
                    ldx       ,s        destination cursor
                    leax      1,x       advance cursor
                    stx       ,s        store cursor
                    stb       -1,x      write pad byte
@PadCheck            ldd       10,s      remaining count
                    addd      #$FFFF    minus one
                    std       10,s      decrement count
                    subd      #$FFFF    restore value
                    bgt       @PadLoop  keep padding
                    ldd       6,s       return destination
                    puls      pc,u,x    return to caller

