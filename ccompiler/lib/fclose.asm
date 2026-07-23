********************************************************************
* fclose - close a stream, flushing it first if it was writing
*
* Shared C runtime fclose.  A null or already-closed stream returns -1;
* otherwise a writing stream is flushed (FlushStream) and the path is
* closed (ClosePath from lib/closepath.asm), the stream flags cleared and
* the flush result returned.  FILE fields come from stdio.d.
*
* Each module supplies its flush helper as FlushStream (aliased where it
* is named differently).
*
* C prototype:  int   fclose(FILE *fp)
********************************************************************

fclose              pshs      u         save frame pointer
                    ldu       $04,s     load the FILE pointer
                    leas      -2,s      reserve a result slot
                    cmpu      #$0000    is the pointer null
                    beq       @CloseNotOpen treat null as not open
                    ldd       _flag,u   load the flags
                    bne       @DoCloseStream proceed if the stream is open
@CloseNotOpen        ldd       #$FFFF    return not-open error
                    puls      pc,u,x    return
@DoCloseStream       ldd       _flag,u   load the flags
                    clra                clear high byte
                    andb      #$02      mask the write-mode bit
                    beq       @SkipFlush skip flush if not writing
                    pshs      u         push the FILE pointer
                    bsr       FlushStream flush the stream
                    leas      2,s       drop the argument
                    bra       @AfterFlush go close the path
@SkipFlush           clra                clear high byte
                    clrb                no flush result
@AfterFlush          std       ,s        save the result
                    ldd       _fd,u     load the path number
                    pshs      d         push the path number
                    lbsr      close     close the path
                    leas      2,s       drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    std       _flag,u   clear the stream flags
                    ldd       ,s        load the flush result
                    puls      pc,u,x    return the result

