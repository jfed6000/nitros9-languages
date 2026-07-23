* ====================================================================
* strlen.asm -- shared string-length runtime (strlen).
*
* The Microware C runtime's strlen, factored out of the compiler
* modules that carry an identical copy (c.opt, c.link).  Pulled in with
* "use lib/strlen.asm" where each module's copy sits.  StrLen is reached
* through a returned &StrLen pointer, so the reference stays in the
* module and resolves to the entry here.
*
* StrLen(s): returns the length of the NUL-terminated string at $04,s.
* Self-contained: no parameters, no external references (StrLenScan is
* internal).  The two-instruction entry is the original, disassembled
* prologue (byte-exact); its odd mnemonics are preserved verbatim.
*
* C prototype:  int   strlen(char *s)
* ====================================================================

strlen              neg       $0034     misframed prologue
                    nega                misframed prologue
                    ldu       4,s       string argument
@StrLenScan         ldb       ,u+       scan for terminator
                    bne       @StrLenScan until nul
                    tfr       u,d       end pointer
                    subd      4,s       minus start
                    addd      #$FFFF    exclude the nul
                    puls      pc,u      return length

