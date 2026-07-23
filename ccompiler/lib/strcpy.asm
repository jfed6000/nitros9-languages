* ====================================================================
* strcpy.asm -- shared string-copy runtime (strcpy).
*
* The Microware C runtime's strcpy, factored out of the compiler
* modules that carry an identical copy (cc1, c.prep, c.opt, c_asm,
* c.link).  Pulled in with "use lib/strcpy.asm" where each module's
* copy sits.
*
* StrCopy(dst, src): copies the NUL-terminated string at src to dst,
* returning dst.  dst = $06,s, src = $06,s reloaded after the frame is
* built; a 2-byte destination cursor lives in the local frame.
*
* Self-contained: no parameters, no external references; the only
* branch target (StrCopyLoop) is internal.  c_asm spells the entry
* StrCpy and repoints its call sites to StrCopy.
*
* C prototype:  char *strcpy(char *dst, char *src);   returns dst
* ====================================================================

strcpy              pshs      u         save frame pointer
                    ldu       $06,s     source string
                    leas      -2,s       destination cursor local
                    ldd       $06,s     destination pointer
                    std       ,s        init cursor
@StrCopyLoop         ldb       ,u+       next source byte
                    ldx       ,s        destination cursor
                    leax      $01,x     advance cursor
                    stx       ,s        store cursor
                    stb       -$01,x    copy byte
                    bne       @StrCopyLoop until nul copied
                    ldd       $06,s     return destination
                    puls      pc,u,x    return to caller

