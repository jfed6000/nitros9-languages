* ====================================================================
* memcpy.asm -- shared memory-copy runtime (memcpy).
* Only c_asm carries this copy; moved to the shared library so the
* program module stays lean.  MemCpy(dst,src,n): copies n bytes.
* Self-contained: no parameters, no external references (kept in the
* c_asm disassembly style: uppercase registers, decimal operands).
*
* C prototype:  char *memcpy(char *dst, char *src, int n)
* ====================================================================

memcpy              pshs      U         save the caller u register
                    ldu       4,S       load destination pointer
                    bra       @MemCpyTest enter copy loop
@MemCpyLoop          ldx       6,S       load source pointer
                    leax      1,X       advance it
                    stx       6,S       store it back
                    ldb       -1,X      load source byte
                    stb       ,U+       store to destination
@MemCpyTest          ldd       8,S       load remaining count
                    addd      #-1       decrement it
                    std       8,S       store count
                    subd      #-1       test for zero
                    bgt       @MemCpyLoop loop while bytes remain
                    puls      PC,U      return

