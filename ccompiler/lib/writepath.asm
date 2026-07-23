* ====================================================================
* writepath.asm -- shared low-level write syscall wrappers.
*
* WritePath(path,buf,n)  -> I$Write   (raw write)
* WriteLnPath(path,buf,n)-> I$WritLn  (line write)
* Both return the byte count, or branch to SyscallErr on failure.
* Shared byte-identical across all eight compiler modules; each
* supplies its own entry names and error-tail (SyscallErr) via equ.
*
* C prototype:  int   write(int path, char *buf, int n)
*               int   writeln(int path, char *buf, int n)
* ====================================================================

write               pshs      y         save y
                    ldy       8,s       load byte count
                    beq       @WriteOk  nothing to write
                    lda       5,s       load path number
                    ldx       6,s       load buffer pointer
                    os9       I$Write   write to file
@WriteResult         bcc       @WriteOk return count on success
                    puls      y         clean stack
                    lbra      SyscallErr return error
@WriteOk             tfr       y,d       count to result
                    puls      pc,y      return byte count
writeln             pshs      y         save y
                    ldy       8,s       load byte count
                    beq       @WriteOk  nothing to write
                    lda       5,s       load path number
                    ldx       6,s       load buffer pointer
                    os9       I$WritLn  write line to file
                    bra       @WriteResult share write result handling

