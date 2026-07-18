* ====================================================================
* cstart.asm -- shared Microware C runtime startup.
*
* The runtime the Microware C compiler links ahead of every program: it
* clears the direct page, copies the initialised-data and non-DP data
* images into place, clears the bss, relocates the compiled pointer
* tables, tokenises the command line into an argv[] vector, sets up the
* stack bounds, then calls the program's main() and exit().
*
* Structurally identical across the C-compiled compiler modules.  Three
* per-module values are supplied by the including module:
*   RTBASE  -- base offset of the runtime-globals block in the data area
*   DATAEND -- end of static data / heap start / stack limit
*   HDRADV  -- advance from the data base to where the non-DP data starts
* and these module symbols must be defined elsewhere in the module:
*   WorkBlockImage (init/relocation tables), main, exit, _exit.
* Runtime globals are addressed as RTBASE+delta:
*   +$00 argv base    +$02 argv[] slots   +$3C argc    +$3D argc byte
*   +$3E entry SP     +$40 param pointer   +$4A memory top / heap
*   +$4C stack low-water reservation
*
* Public entry points: _start (module exec entry), stkcheck (per-frame
* stack check, d = negative reservation request), copybytes.
* ====================================================================

* copybytes - block move (y = source, u = destination, x = count)
copybytes           lda       ,y+       get a byte
                    sta       ,u+       put a byte
                    leax      -$01,x    decrement the count
                    bne       copybytes and round again
                    rts                 return from the block move

_start              pshs      y         save the top of memory
                    pshs      u         save the data base address
                    clra                set up to clear
                    clrb                256 direct-page bytes
cs.ZeroDataLoop     sta       ,u+       clear a direct-page byte
                    decb                count the byte down
                    bne       cs.ZeroDataLoop loop until the page is cleared
                    ldx       ,s        get the data base address again
                    leau      ,x        point u at the data base
                    leax      DATAEND,x get the end of the bss area
                    pshs      x         save the end-of-data pointer
                    leay      WorkBlockImage,pcr point y at the dp-data count word
                    ldx       ,y++      get the count of dp data to move
                    beq       cs.AfterFirstInit skip the copy when empty
                    bsr       copybytes move the dp data into position
                    ldu       $02,s     get the data base again
cs.AfterFirstInit   leau      >HDRADV,u point to where non-dp data starts
                    ldx       ,y++      get the count of non-dp data to move
                    beq       cs.PadLoop skip the copy when empty
                    bsr       copybytes move the non-dp data into position
                    clra                prepare a zero fill byte
* clear the bss area - it starts where the transferred data finished
cs.PadLoop          cmpu      ,s        reached the end of data?
                    beq       cs.RelocateData yes, done clearing the bss
cs.PadStore         sta       ,u+       clear a bss byte
                    bra       cs.PadLoop continue clearing the bss

* replace the compiled pointer references: first the data-to-text refs,
* then the data-to-data refs
cs.RelocateData     ldu       $02,s     point back at the data base
                    ldd       ,y++      get the text-reference count
                    beq       cs.CheckSecondReloc skip when no text references
                    leax      >$0000,pcr point x at the module (text) base
                    lbsr      cs.RelocatePointers patch the text references
cs.CheckSecondReloc ldd       ,y++      get the data-reference count
                    beq       cs.InitComplete skip when no data references
                    leax      ,u        u already points at the data base
                    lbsr      cs.RelocatePointers patch the data references
cs.InitComplete     leas      $04,s     drop the saved pointers
                    puls      x         restore the end-of-data pointer
                    stx       RTBASE+$40,u save it as the parameter pointer
* process the params: insert a null at the end of each argument and fill
* the argv[] vector with pointers to them.  the program-name address is
* stored first (an extra name slot is reserved for it).
                    sty       RTBASE,u  save the argument-vector base
                    ldd       #$0001    there is always at least one arg
                    std       RTBASE+$3C,u set the argument count to one
                    leay      RTBASE+$02,u point y at the second argv slot
                    leax      ,s        point x at the raw parameters
                    lda       ,x+       prime the first character
cs.ParseArgLoop     ldb       RTBASE+$3D,u load the current argument count
                    cmpb      #$1d      about to overflow the vector?
                    beq       cs.ArgsParsed stop when the vector is full
cs.SkipSepLoop      cmpa      #$0d      end of the command line?
                    beq       cs.ArgsParsed finish at carriage return
                    cmpa      #$20      a space separator?
                    beq       cs.NextSepChar skip it
                    cmpa      #$2C      a comma separator?
                    bne       cs.CheckQuote no, a word has started
cs.NextSepChar      lda       ,x+       get the next character
                    bra       cs.SkipSepLoop keep skipping separators

cs.CheckQuote       cmpa      #$22      a double-quoted string?
                    beq       cs.StartQuoted yes
                    cmpa      #$27      a single-quoted string?
                    bne       cs.StartWord no, an ordinary word
cs.StartQuoted      stx       ,y++      record the token start in argv
                    inc       RTBASE+$3D,u bump the argument count
                    pshs      a         save the quote delimiter
cs.QuoteScanLoop    lda       ,x+       scan a character inside the quotes
                    cmpa      #$0d      end of line inside the quote?
                    beq       cs.QuoteEnd stop at the line end
                    cmpa      ,s        the matching close quote?
                    bne       cs.QuoteScanLoop keep scanning quoted text
cs.QuoteEnd         puls      b         discard the saved delimiter
                    clr       -$01,x    terminate the token with a null
                    cmpa      #$0d      was it the end of the line?
                    beq       cs.ArgsParsed finish if the line ended
                    lda       ,x+       get the character after the quote
                    bra       cs.ParseArgLoop process the next token

cs.StartWord        leax      -$01,x    back up to the token start
                    stx       ,y++      record the token start in argv
                    leax      $01,x     step past the first character
                    inc       RTBASE+$3D,u bump the argument count
cs.WordScanLoop     cmpa      #$0d      end of the line?
                    beq       cs.WordEnd end the word
                    cmpa      #$20      a space?
                    beq       cs.WordEnd end the word
                    cmpa      #$2C      a comma?
                    beq       cs.WordEnd end the word
                    lda       ,x+       scan the next word character
                    bra       cs.WordScanLoop keep scanning the word

cs.WordEnd          clr       -$01,x    terminate the word with a null
                    bra       cs.ParseArgLoop process the next token

* put argv and argc on the stack, then call the program's main()
cs.ArgsParsed       leax      RTBASE,u  get the address of the argv vector
                    pshs      x         push argv first
                    ldd       RTBASE+$3C,u get the argument count
                    pshs      d         push argc
                    leay      ,u        c programs expect data & bss offset from y
                    bsr       cs.stkinit set up the stack-tracking globals
                    lbsr      main      call the program
                    clr       ,-s       push a zero exit status
                    clr       ,-s       and a dummy return address
                    lbsr      exit      exit the program (no return)

* set the initial stack bounds, then fall into the per-frame check
cs.stkinit          leax      DATAEND,y get the initial memory top
                    stx       RTBASE+$4A,y it is the current memory top
                    sts       RTBASE+$3E,y record the entry stack pointer
                    sts       RTBASE+$4C,y seed the stack low-water mark
                    ldd       #$FF82    give ourselves 126 bytes of headroom
* stkcheck - on entry d holds the negative of a stack reservation request
stkcheck            leax      d,s       compute the requested stack top
                    cmpx      RTBASE+$4C,y already below the reservation?
                    bcc       cs.StackOk yes, nothing to do
                    cmpx      RTBASE+$4A,y below the memory top?
                    bcs       cs.StackOverflow no, cannot satisfy it
                    stx       RTBASE+$4C,y reserve the new low-water mark
cs.StackOk          rts                 return from the stack check

cs.MsgStackOverflow fcc       /**** STACK OVERFLOW ****/
                    fcb       $0d       carriage-return terminator
cs.StackOverflow    leax      cs.MsgStackOverflow,pcr point at the error string
                    ldb       #$CF      E$MemFul (memory full) exit code
                    pshs      b         stack the error number
                    lda       #$02      standard error output
                    ldy       #$0064    more than the message length
                    os9       I$WritLn  write the message
                    clr       ,-s       clear the high byte of the status
                    lbsr      _exit     abort (no return)
* stacksize() - stack bytes in use = entry SP - low-water mark
                    ldd       RTBASE+$3E,y load the entry stack pointer
                    subd      RTBASE+$4C,y subtract the low-water mark
                    rts                 return the stack size in use
* freemem() - free bytes = low-water mark - memory top
                    ldd       RTBASE+$4C,y load the stack low-water mark
                    subd      RTBASE+$4A,y subtract the memory top
                    rts                 return the free memory size

* patch/RelocatePointers - add the relocation base to each stored pointer.
* entry: y -> list of offsets, u -> data base, x -> text or data base,
*        d = count of offsets.  exit: u unchanged, y past the last entry.
cs.RelocatePointers pshs      x         save the base
                    leax      d,y       index half way up the list
                    leax      d,x       to the top of the list
                    pshs      x         save it as the place to stop
cs.RelocLoop        ldd       ,y++      get an offset
                    leax      d,u       point at the location to fix
                    ldd       ,x        get the relative reference
                    addd      $02,s     add in the base
                    std       ,x        store the absolute reference
                    cmpy      ,s        reached the top of the list?
                    bne       cs.RelocLoop no, round again
                    leas      $04,s     drop the saved values
                    rts                 return from relocation
