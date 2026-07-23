********************************************************************
* readpath - read raw bytes or a line from an open path
*
* Shared C runtime read wrappers.  Both take a path number, buffer
* pointer and byte count on the stack and return the count actually
* read; a clean end of file returns zero, any other error drops into
* SyscallErr (from lib/syscallerr.asm).  ReadLnPath shares ReadPath's
* result handling.
*
* Each module pulls this in with "use lib/readpath.asm" and points its
* own call names at ReadPath/ReadLnPath via equ aliases.
*
* C prototype:  int   read(int path, char *buf, int n)
*               int   readln(int path, char *buf, int n)
********************************************************************

read                pshs      y         save y
                    ldx       6,s       load buffer pointer
                    lda       5,s       load path number
                    ldy       8,s       load byte count
                    pshs      y         save count on stack
                    os9       I$Read    read from file
@ReadResult          bcc       @ReadOk  return count on success
                    cmpb      #E$EOF    end of file error
                    bne       @ReadErr  other error
                    clra                clear high result
                    clrb                clear low result
                    puls      pc,y,x    return zero at end of file
@ReadErr             puls      y,x       clean stack
                    lbra      SyscallErr return error
@ReadOk              tfr       y,d       returned count to result
                    puls      pc,y,x    return byte count
readln              pshs      y         save y
                    lda       5,s       load path number
                    ldx       6,s       load buffer pointer
                    ldy       8,s       load byte count
                    pshs      y         save count on stack
                    os9       I$ReadLn  read line from file
                    bra       @ReadResult share read result handling

