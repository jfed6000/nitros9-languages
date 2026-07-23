* ====================================================================
* flushbuffer.asm -- shared buffered-stream flush runtime.
*
* FlushBuffer(FILE*): flushes a buffered stdio stream -- repositions
* on a read stream, writes out a dirty write buffer (text via
* WriteLnPath, binary via WritePath), then resets the buffer.  All
* stream state comes through the U pointer argument (no Y-globals).
*
* External references (each carrying module supplies them): FileTell,
* LseekPath (lib/seek.asm), WriteLnPath, WritePath.  Shared across
* cc1/c.pass1/c.pass2/c.comp/c.link.
*
* Role:         internal: flush a buffered stdio stream -- FlushBuffer(FILE *fp)
* ====================================================================

FlushBuffer         pshs      u         save frame register
                    ldu       $04,s     load stream argument
                    leas      -4,s       reserve locals
                    ldd       $06,u     stream flags
                    anda      #$01      test read-direction flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    bne       @FlushWriteCount skip seek if writing
                    ldd       ,u        current position
                    cmpd      $04,u     buffer fully consumed
                    beq       @FlushWriteCount no reposition needed
                    clra                offset high zero
                    clrb                clear low byte
                    pshs      d         push offset high
                    pshs      u         push stream
                    lbsr      FileTell  compute true file position
                    leas      2,s        drop argument
                    ldd       $02,x     low word position
                    pshs      d         push low word
                    ldd       ,x        high word position
                    pshs      d         push high word
                    ldd       $08,u     path number
                    pshs      d         push path number
                    lbsr      lseek     lseek to true position
                    leas      8,s        drop arguments
@FlushWriteCount     ldd       ,u        current position
                    subd      $02,u     minus buffer base
                    std       $02,s     save byte count
                    lbeq      @FlushReset nothing to flush
                    ldd       $06,u     stream flags
                    anda      #$01      test read-direction flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    lbeq      @FlushReset reset only if reading
                    ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$40      test text-translation flag
                    beq       @FlushRaw raw write if binary
                    ldd       $02,u     buffer base pointer
                    bra       @FlushTextStep skip to store pointer
@FlushTextLoop       ldd       $02,s     remaining byte count
                    pshs      d         push count
                    ldd       ,u        current source pointer
                    pshs      d         push source
                    ldd       $08,u     path number
                    pshs      d         push path number
                    lbsr      writeln   text write to path
                    leas      6,s        drop arguments
                    std       ,s        save bytes written
                    cmpd      #$FFFF    write error
                    bne       @WriteLoopNext continue if written
                    leax      $04,s     restore stack for error
                    bra       @FlushErrFix go handle error
@WriteLoopNext       ldd       $02,s     remaining count
                    subd      ,s        minus bytes written
                    std       $02,s     update remaining
                    ldd       ,u        current pointer
                    addd      ,s        advance by bytes written
@FlushTextStep       std       ,u        store pointer
                    ldd       $02,s     remaining count
                    bne       @FlushTextLoop loop while bytes remain
                    bra       @FlushReset buffer flushed
@FlushRaw            ldd       $02,s     byte count
                    pshs      d         push count
                    ldd       $02,u     buffer base pointer
                    pshs      d         push source
                    ldd       $08,u     path number
                    pshs      d         push path number
                    lbsr      write     raw write to path
                    leas      6,s        drop arguments
                    cmpd      $02,s     wrote all bytes
                    beq       @FlushReset flushed successfully
                    bra       @FlushError write short or error
@FlushErrFix         leas      -$04,x    restore stack after thunk
@FlushError          ldd       $06,u     stream flags
                    orb       #$20      set error flag
                    std       $06,u     store flags
                    ldd       $04,u     buffer end pointer
                    std       ,u        reset current to end
                    ldd       #$FFFF    return -1
                    bra       FlushRet  go to exit
@FlushReset          ldd       $06,u     stream flags
                    ora       #$01      mark buffer positioned
                    std       $06,u     store flags
                    ldd       $02,u     buffer base pointer
                    std       ,u        reset current to base
                    addd      $0b,u     plus buffer size
                    std       $04,u     set buffer end
                    clra                return zero
                    clrb                clear low byte
FlushRet            leas      4,s        drop locals
                    puls      pc,u      return

