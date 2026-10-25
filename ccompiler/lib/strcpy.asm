* ====================================================================
* strcpy.asm -- shared string-copy runtime (strcpy).
*
* The Microware C runtime's strcpy, factored out of the compiler
* modules that carry an identical copy (cc1, c.prep, c.opt, c_asm,
* c.link).  Pulled in with "use lib/strcpy.asm" where each module's
* copy sits.
*
* StrCopy(dst, src): copies the NUL-terminated string at src to dst,
* returning dst.  src comes from $06,s (loaded into u as the working
* source pointer); dst is reread from $06,s after a 2-byte cursor slot
* is reserved on the stack.  args and locals are addressed off s; u is
* not a frame pointer here.
*
* Self-contained: no parameters, no external references; the only
* branch target (StrCopyLoop) is internal.  c_asm spells the entry
* StrCpy and repoints its call sites to StrCopy.
*
* C prototype:  char *strcpy(char *dst, char *src);   returns dst
* ====================================================================

strcpy              pshs      u         save the caller u register
                    ldu       6,s       source string
                    leas      -2,s       destination cursor local
                    ldd       6,s       destination pointer
                    std       ,s        init cursor
@StrCopyLoop         ldb       ,u+       next source byte
                    ldx       ,s        destination cursor
                    leax      1,x       advance cursor
                    stx       ,s        store cursor
                    stb       -1,x      copy byte
                    bne       @StrCopyLoop until nul copied
                    ldd       6,s       return destination
                    puls      pc,u,x    return to caller

