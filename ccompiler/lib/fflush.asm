********************************************************************
* fflush - flush a writable stream's buffer
*
* Shared C runtime fflush.  A null or non-writable stream returns -1;
* otherwise the buffer is allocated if needed (GetBuf) and written out
* (FlushBuf).  FILE fields come from stdio.d.
*
* Each module supplies its buffer helpers as GetBuf and FlushBuf (aliased
* where they are named differently).
*
* C prototype:  int   fflush(FILE *fp)
********************************************************************

fflush              pshs      u         save the caller u register
                    ldu       4,s       load the stream pointer
                    beq       IoErr     fail if null stream
                    ldd       _flag,u   load the flags
                    clra                keep the low byte
                    andb      #$22      isolate write and error bits
                    cmpd      #2        check the stream is writable
                    beq       @FflushWrite flush if writable
IoErr               ldd       #$FFFF    return the error code
                    puls      pc,u      restore and return
@FflushWrite         ldd       _flag,u   load the flags
                    anda      #$80      isolate the high flag bit
                    clrb                clear the low byte
                    std       -2,s      save the test result
                    bne       @FflushTail skip alloc if already set
                    pshs      u         pass the stream
                    lbsr      GetBuf    allocate the buffer if needed
                    leas      2,s       drop the argument
@FflushTail          pshs      u         pass the stream
                    bsr       FlushBuf  perform the buffer flush
                    puls      pc,u,x    restore and return

