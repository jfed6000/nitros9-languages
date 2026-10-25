                    nam       c.pass1
                    ttl       program module

* Annotated 2026-07-14 (Claude Code):
*   - renamed disassembled labels to meaningful names
*   - added an inline comment to every instruction
*   - re-disassembled the "**** STACK OVERFLOW ****" banner that had
*     been decoded as instructions
*   - separated the direct-page globals from the startup code they had
*     been mis-resolved onto (disassembler assumed DP=$00); they are now
*     a direct-page equate block with the references repointed
*   - verified byte-identical to the original assembly (module CRC $D500EC)

                    use       defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       5

                    mod       eom,name,tylg,atrv,_start,size

                    * ------------------------------------------------------------------
                    * Data area (named rmb fields).  rmb reserves RAM without emitting
                    * bytes; OS-9 allocates <size> at load, cstart inits from WorkBlockImage.
                    * Names for ,y-referenced fields are derived from the code comments.
                    * ------------------------------------------------------------------
                    rmb       1
GlbVar0001          rmb       1
Dest                rmb       1
GlbVar0003          rmb       2
GlbVar0005          rmb       2
GlbVar0007          rmb       2
GlbVar0009          rmb       2
GlbVar000B          rmb       2
GlbVar000D          rmb       2
GlbVar000F          rmb       2
GlbVar0011          rmb       2
GlbVar0013          rmb       2
GlbVar0015          rmb       2
GlbVar0017          rmb       2
GlbVar0019          rmb       2
GlbVar001B          rmb       2
GlbVar001D          rmb       2
GlbVar001F          rmb       2
GlbVar0021          rmb       2
GlbVar0023          rmb       2
GlbVar0025          rmb       2
GlbLineNum          rmb       2
GlbErrCount         rmb       2
GlbVar002B          rmb       2
GlbNodeList         rmb       2
GlbVar002F          rmb       2
GlbVar0031          rmb       2
GlbVar0033          rmb       2
GlbVar0035          rmb       2
GlbVar0037          rmb       2
GlbVar0039          rmb       2
GlbVar003B          rmb       4
GlbVar003F          rmb       2
GlbVar0041          rmb       2
GlbFreeList         rmb       2
GlbVar0045          rmb       2
GlbVar0047          rmb       2
GlbVar0049          rmb       2
GlbVar004B          rmb       2
GlbVar004D          rmb       2
GlbVar004F          rmb       2
GlbVar0051          rmb       2
GlbVar0053          rmb       2
GlbVar0055          rmb       2
GlbVar0057          rmb       2
GlbVar0059          rmb       2
GlbVar005B          rmb       4
GlbVar005F          rmb       2
GlbVar0061          rmb       2
GlbVar0063          rmb       2
GlbVar0065          rmb       1
GlbVar0066          rmb       2
GlbVar0068          rmb       2
GlbVar006A          rmb       2
GlbVar006C          rmb       6
GlbVar0072          rmb       4
MsgBuf              rmb       11
Pow10               rmb       8
CtypeTab            rmb       128
ActionTable         rmb       128
IsBufferFull        rmb       2
DummyErrorSymbol    rmb       28
GlobalPointerArgument rmb       2
NameBuf             rmb       11
FileTab             rmb       13
StdoutStream        rmb       13
OutputStream        rmb       182
TableLimit          rmb       64
BreakPointer        rmb       2
NumberWorkArea      rmb       2
ResultLowWord       rmb       6
RegionPointer       rmb       2
RegionLimit         rmb       2
Errno               rmb       2
DefaultLabel        rmb       2
RecordContextField  rmb       2
RecordContextField2 rmb       2
OutputBuffer        rmb       10
TempDigitBuffer     rmb       10
NameBuffer          rmb       256
FilenameBuffer      rmb       30
SymbolTableB        rmb       256
SymbolTable         rmb       256
LineBuffer          rmb       256
PreviousLineBuffer  rmb       256
ResultSignFlag      rmb       1
DivideRoutinePointer rmb       2
UpdateFreeSpace     rmb       2
SignalHandler       rmb       2
HeapStart           rmb       1920     remaining data, bss and heap
size                equ       .

name                equ       *
                    fcs       /c.pass1/
                    fcb       edition

* --- shared C runtime startup (see lib/cstart.asm) ---
RTBASE              equ       TableLimit runtime-globals block base in the data area
DATAEND             equ       HeapStart end of static data / heap start / stack limit
HDRADV              equ       MsgBuf    advance to where the non-DP data starts
                    use       lib/cstart.asm

AllocNode           pshs      u         save the caller u register
                    ldu       4,s       load the parent node argument
                    leas      -6,s       allocate local slots
                    ldd       GlbFreeList load the free-list head
                    std       2,s       save it
                    beq       AllocFromHeap allocate from heap if empty
                    ldx       2,s       take a node from the free list
                    ldd       16,x      load the next free pointer
                    std       GlbFreeList unlink node from the free list
                    bra       InitNode  node obtained

AllocFromHeap       ldd       #18       request eighteen bytes
                    pshs      d         push the size
                    lbsr      AllocMem  allocate from the heap
                    leas      2,s        drop the size argument
                    std       2,s       save the new node pointer
InitNode            ldd       #18       copy length eighteen bytes
                    pshs      d         push the length
                    ldd       4,s       source template pointer
                    pshs      d         push the source
                    stu       8,s       stash the destination node
                    pshs      u         push the destination node
                    bsr       CopyBlock copy template into the node
                    leas      6,s        drop the copy arguments
                    ldd       #9        nine words to clear
                    std       ,s        seed the clear count
                    bra       ClearNodeTest enter the clear loop

ClearNodeLoop       clra                clear high half
                    clrb                clear low half
                    std       ,u++      clear a node word
ClearNodeTest       ldd       ,s        load the remaining count
                    addd      #$FFFF    decrement the counter
                    std       ,s        store the count back
                    subd      #$FFFF    test for zero
                    bne       ClearNodeLoop clear the next word
                    ldd       2,s       the new node pointer
                    ldx       4,s       the parent node
                    std       14,x      link node into the parent
                    lbra      Drop6Ret  return the new node

FreeNode            pshs      u         save the caller u register
                    ldu       4,s       load the node argument
                    leas      -2,s       allocate a local slot
                    ldd       14,u      load the child link
                    std       ,s        save it
                    ldd       #18       copy length eighteen bytes
                    pshs      d         push the length
                    pshs      u         push the source node
                    ldd       4,s       child pointer as destination
                    pshs      d         push the destination
                    bsr       CopyBlock copy the node contents
                    leas      6,s        drop the copy arguments
                    ldd       GlbFreeList current free-list head
                    ldx       ,s        the child pointer
                    std       16,x      chain node onto the free list
                    ldd       ,s        reload the node pointer
                    std       GlbFreeList push node onto the free list
                    lbra      DropArgRet return

CopyBlock           pshs      u         save the caller u register
                    ldu       4,s       source pointer
                    bra       CopyByteTest enter the copy loop

CopyByteLoop        ldb       ,u+       read a source byte
                    ldx       6,s       load the destination pointer
                    leax      1,x       advance the destination
                    stx       6,s       save the destination back
                    stb       -1,x      store the copied byte
CopyByteTest        ldd       8,s       load the remaining count
                    addd      #$FFFF    decrement the count
                    std       8,s       store the count back
                    subd      #$FFFF    test for zero
                    bne       CopyByteLoop copy the next byte
                    puls      pc,u      return from the copy

PrintFileName       pshs      u         save the caller u register
                    leax      FilenameBuffer,y   point at the file name buffer
                    pshs      x         push the file name argument
                    leax      FmtNameColon,pcr point at the format string
                    pshs      x         push the format
                    lbsr      Fprintf3Arg print the source file name
                    lbra      PopArgsRet return

ReportTokenErr      pshs      u         save the caller u register
                    ldd       4,s       load the token argument
                    pshs      d         push it
                    bsr       PrintErrLoc print the error location
                    leas      2,s        drop the argument
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    lbsr      FlushStream flush the output stream
                    lbra      ReportErrExit return

ReportMsgErr        pshs      u         save the caller u register
                    leax      MsgMultiDef,pcr point at the message string
                    pshs      x         push the message
                    bsr       PrintErrLoc print the error with the message
                    lbra      DropArgRet return

PrintErrLoc         pshs      u         save the caller u register
                    ldd       GlbVar003F load the current line number
                    pshs      d         push the line number
                    ldd       6,s       load the error argument
                    pshs      d         push it
                    leax      LineBuffer,y   point at the source line buffer
                    pshs      x         push the buffer
                    ldd       GlbVar0063 load the column position
                    bra       SpanReport compute and report the error

ReportFmtErr        pshs      u         save the caller u register
                    leas      -50,s      allocate the format buffer
                    leax      MsgCompilerErr,pcr point at the format string
                    pshs      x         push the format
                    leax      2,s       point at the work buffer
                    pshs      x         push the buffer
                    lbsr      StrCpy    format into the buffer
                    leas      4,s        drop the format arguments
                    ldd       56,s      load the first value
                    pshs      d         push it
                    leax      2,s       point at the work buffer
                    pshs      x         push the buffer
                    lbsr      strcat    append the formatted text
                    leas      4,s        drop the arguments
                    leax      ,s        point at the built string
                    pshs      x         push the string
                    ldd       56,s      load the second value
                    pshs      d         push it
                    bsr       PrintErrSpan report the error span
                    leas      4,s        drop the arguments
                    leas      50,s       release the format buffer
                    puls      pc,u      return

PrintErrSpan        pshs      u         save the caller u register
                    ldu       4,s       load the node argument
                    ldd       14,u      load the span start
                    pshs      d         push it
                    ldd       8,s       load the line argument
                    pshs      d         push it
                    leax      LineBuffer,y   point at the source line buffer
                    pshs      x         push the buffer
                    ldd       16,u      load the span end
SpanReport          subd      ,s++      compute the span length
                    pshs      d         push it
                    bsr       PrintDiagnostic print the diagnostic
                    lbra      Drop6Ret  return

PrintDiagnostic     pshs      u         save the caller u register
                    ldu       4,s       load the column count
                    lbsr      PrintFileName print the source file name
                    ldd       8,s       load the line argument
                    pshs      d         push it
                    leax      FmtLineNum,pcr point at the line format
                    pshs      x         push the format
                    lbsr      Fprintf3Arg print the line number
                    leas      4,s        drop the arguments
                    ldd       6,s       load the column argument
                    pshs      d         push it
                    leax      FmtBanner,pcr point at the column format
                    pshs      x         push the format
                    lbsr      Fprintf3Arg print the column number
                    leas      4,s        drop the arguments
                    ldd       8,s       load the error line number
                    cmpd      GlbLineNum matches the current line
                    bne       CheckPrevLine check the previous line
                    leax      LineBuffer,y   point at the current line buffer
                    pshs      x         push the buffer
                    lbsr      PrintStrLn print the offending source line
                    leas      2,s        drop the argument
                    leax      ,s        point at the stack slot
                    bra       CaretFromStack position the caret

CheckPrevLine       ldd       GlbLineNum load the current line number
                    addd      #$FFFF    previous line number
                    cmpd      8,s       error on the previous line
                    bne       BumpErrCount skip source echo otherwise
                    leax      PreviousLineBuffer,y   point at the previous line buffer
                    pshs      x         push the buffer
                    lbsr      PrintStrLn print the previous source line
                    leas      2,s        drop the argument
                    bra       CaretPadTest draw the caret

CaretFromStack      leas      ,x        restore the stack pointer
                    bra       CaretPadTest draw the caret

CaretPadLoop        ldd       #'        space character
                    pshs      d         push it
                    lbsr      PutCharOut print a space
                    leas      2,s        drop the argument
                    leau      -1,u      count down the columns
CaretPadTest        cmpu      #0        more columns to pad
                    bgt       CaretPadLoop pad up to the error column
                    leax      MsgCaret,pcr point at the caret string
                    pshs      x         push it
                    bsr       PrintStrLn print the caret marker
                    leas      2,s        drop the argument
BumpErrCount        ldd       GlbErrCount load the error count
                    addd      #1        increment it
                    std       GlbErrCount store the error count
                    cmpd      #_start   reached the error limit
                    ble       DiagDone  continue if under the limit
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    lbsr      FlushStream flush the output
                    leas      2,s        drop the argument
                    leax      MsgTooManyErrors,pcr point at the abort message
                    pshs      x         push it
                    bsr       PrintStrLn print the too-many-errors message
ReportErrExit       leas      2,s        drop the argument
                    lbsr      EmitDataInit abort compilation
DiagDone            puls      pc,u      return

Fprintf3Arg         pshs      u         save the caller u register
                    ldd       8,s       load the third argument
                    pshs      d         push it
                    ldd       8,s       load the second argument
                    pshs      d         push it
                    ldd       8,s       load the first argument
                    pshs      d         push it
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    lbsr      fprintf   formatted print
                    leas      8,s        drop the print arguments
                    puls      pc,u      return

PrintStrLn          pshs      u         save the caller u register
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    ldd       6,s       load the string pointer
                    pshs      d         push it
                    lbsr      FputStr   write the string
                    leas      4,s        drop the arguments
                    ldd       #13       carriage return
                    pshs      d         push it
                    bsr       PutCharOut print the newline
                    bra       DropArgRet return

PutCharOut          pshs      u         save the caller u register
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    ldb       7,s       load the character argument
                    sex                 sign-extend to a word
                    pshs      d         push it
                    lbsr      PutChar2  write the character
PopArgsRet          leas      4,s        drop the arguments
                    puls      pc,u      return

WalkTree            pshs      u         save the caller u register
                    ldu       4,s       load the tree node
                    stu       -2,s      test the node pointer
                    beq       RetU      return on a null node
                    ldd       10,u      load the left child
                    pshs      d         push it
                    bsr       WalkTree  recurse the left subtree
                    leas      2,s        drop the argument
                    ldd       12,u      load the right child
                    pshs      d         push it
                    lbsr      WalkTree  recurse the right subtree
                    leas      2,s        drop the argument
                    pshs      u         push the current node
                    bsr       LinkNode  link node into the list
DropArgRet          leas      2,s        drop the argument
RetU                puls      pc,u      return

LinkNode            pshs      u         save the caller u register
                    ldu       4,s       load the node argument
                    stu       -2,s      test the node pointer
                    beq       LinkDone  skip if null
                    ldd       GlbNodeList load the node list head
                    std       10,u      chain onto the list
                    stu       GlbNodeList push node onto the list
LinkDone            puls      pc,u      return

CopyStruct          pshs      u         save the caller u register
                    ldd       #22       copy length twenty-two bytes
                    pshs      d         push the length
                    ldd       8,s       source pointer
                    pshs      d         push the source
                    ldd       8,s       destination pointer
                    pshs      d         push the destination
                    lbsr      CopyBlock copy the structure
Drop6Ret            leas      6,s        drop the arguments
                    puls      pc,u      return

ClassifyType        pshs      u         save the caller u register
                    ldd       GlbVar005F load the current type
                    cmpd      #51       is it a basic type
                    bne       CheckType34 not a scalar type
                    ldx       GlbVar0061 load the type subclass
                    cmpx      #1        compare against subclass one
                    lbeq      RetOne    matched a scalar type
                    cmpx      #2        compare against subclass two
                    lbeq      RetOne    matched a scalar type
                    cmpx      #7        compare against subclass seven
                    lbeq      RetOne    matched a scalar type
                    cmpx      #10       compare against subclass ten
                    lbeq      RetOne    matched a scalar type
                    cmpx      #8        compare against subclass eight
                    lbeq      RetOne    matched a scalar type
                    cmpx      #4        compare against subclass four
                    lbeq      RetOne    matched a scalar type
                    cmpx      #3        compare against subclass three
                    lbeq      RetOne    matched a scalar type
                    cmpx      #6        compare against subclass six
                    lbeq      RetOne    matched a scalar type
                    cmpx      #5        compare against subclass five
                    lbeq      RetOne    matched a scalar type
                    lbra      RetZero   not a base type keyword, return zero

CheckType34         ldd       GlbVar005F load the current token kind
                    cmpd      #52       is it type kind 0x34
                    lbne      RetZero   no, return zero
                    ldx       GlbVar0061 token value is a pointer
                    ldd       8,x       fetch the type field
                    cmpd      #_start   compare against base type code
                    bra       Type34Match test the match

IsQualifierKw       pshs      u         save the caller u register
                    ldd       GlbVar005F current token kind
                    cmpd      #51       is it keyword kind 0x33
                    lbne      RetZero   no, return zero
                    ldx       GlbVar0061 token value
                    cmpx      #14       qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #13       qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #_start   qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #16       qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #15       qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #33       qualifier keyword code
Type34Match         lbeq      RetOne    matched, return one
                    lbra      RetZero   none matched, return zero

RemovePtrLevel      pshs      u         save the caller u register
                    ldd       4,s       load the type word argument
                    asra                shift high byte right
                    rorb                rotate into low byte
                    asra                shift right again
                    rorb                rotate into low byte
                    andb      #$F0      keep the indirection nibble
                    bra       CombineTypeBits combine with base type

AddPtrLevel         pshs      u         save the caller u register
                    ldd       4,s       load the type word argument
                    andb      #$F0      mask the indirection nibble
                    aslb                shift low byte left
                    rola                rotate into high byte
                    aslb                shift left again
                    rola                rotate into high byte
                    addd      #16       bump the indirection count
CombineTypeBits     pshs      d         save the new indirection bits
                    ldd       6,s       reload the original type word
                    clra                clear high byte
                    andb      #$0f      keep the base type nibble
                    addd      ,s++      merge base type with indirection
                    puls      pc,u      return the combined type

IsOpToken           pshs      u         save the caller u register
                    ldu       4,s       load the token code argument
                    cmpu      #76       below operator range
                    blt       RetZero   not an operator, return zero
                    cmpu      #99       above operator range
                    bgt       RetZero   not an operator, return zero
                    ldd       #1        it is an operator
                    bra       ExpectRet return one

GetNodeType         pshs      u         save the caller u register
                    ldu       4,s       load the node pointer argument
                    stu       -2,s      test for null
                    beq       RetZero   null, return zero
                    ldd       2,u       fetch the node type field
                    bra       ExpectRet return it

ExpectToken         pshs      u         save the caller u register
                    ldd       GlbVar005F load the current token
                    cmpd      4,s       does it match the expected token
                    bne       ExpectErr no, report the error
                    lbsr      ScanToken consume the token
RetZero             clra                result high byte zero
                    clrb                result low byte zero
ExpectRet           puls      pc,u      return

ExpectErr           ldu       #0        start at character table index zero
                    bra       FindCharCond enter the search loop

FindCharLoop        tfr       u,d       index into d
                    leax      CtypeTab,y token-to-character table base
                    leax      d,x       index into the table
                    ldb       ,x        fetch the char for this token
                    sex                 sign extend to d
                    cmpd      4,s       does it match the expected token
                    beq       CharFound found the character
                    leau      1,u       advance to next index
FindCharCond        cmpu      #128      end of the table
                    blt       FindCharLoop keep searching
CharFound           tfr       u,d       index into d
                    stb       >MsgBuf,y store char into the message buffer
                    leax      >MsgBuf,y point at the buffer
                    pshs      x         pass to print
                    lbsr      PrintErrLoc print expected-token error
                    leas      2,s        drop the argument
RetOne              ldd       #1        return one
                    puls      pc,u      return

SyncDeclarator      pshs      u         save the caller u register
                    bra       SyncCheck check the current token first

SyncLoop            lbsr      ScanToken advance to the next token
SyncCheck           ldd       GlbVar005F load the current token
                    cmpd      #'(       open paren
                    beq       SyncDone  stop, found declarator start
                    ldd       GlbVar005F reload current token
                    cmpd      #42       pointer star
                    beq       SyncDone  stop, found declarator start
                    ldd       GlbVar005F reload current token
                    cmpd      #$FFFF    end of file
                    bne       SyncLoop  keep skipping tokens
SyncDone            puls      pc,u      recovery complete, return

FmtNameColon        fcc       /%s : /
                    fcb       C$NULL
MsgMultiDef         fcc       /multiple definition/
                    fcb       C$NULL
MsgCompilerErr      fcc       /compiler error - /
                    fcb       C$NULL
FmtLineNum          fcc       /line %d  /
                    fcb       C$NULL
FmtBanner           fcc       /****  %s  ****/
                    fcb       C$CR,C$NULL
MsgCaret            fcb       $5E
                    fcb       C$NULL
MsgTooManyErrors    fcc       /too many errors - ABORT/
                    fcb       C$NULL
ParseExpr           pshs      u         save the caller u register
                    ldd       #$FFA2    stack space needed
                    lbsr      stkcheck  verify stack space
                    leas      -14,s      allocate locals
                    lbsr      ParsePrimary parse the left operand
                    std       12,s      save the operand node
                    lbne      CheckPrecLoop got operand, climb precedence
                    clra                no operand, result high zero
                    clrb                result low zero
                    lbra      ParseExprExit return

                    lbra      CheckPrecLoop unreachable fallthrough

ParseExprLoop       ldd       GlbVar005F operator token kind
                    std       10,s      save the operator kind
                    ldd       GlbVar0061 operator value
                    std       8,s       save the operator value
                    std       ,s        also as working precedence
                    ldd       GlbVar003F current line number
                    std       4,s       save the line
                    ldd       GlbVar0063 source position
                    std       2,s       save the position
                    lbsr      ScanToken consume the operator token
                    ldx       10,s      reload the operator
                    bra       CheckSpecialOp classify the operator

CheckOpPrec         ldd       10,s      operator kind
                    cmpd      #160      below assignment range
                    blt       BumpPrec  treat with normal precedence
                    ldd       10,s      reload operator kind
                    cmpd      #169      assignment operator range
                    ble       BuildBinNode right associative, keep value
BumpPrec            ldd       8,s       operator value
                    addd      #1        bump precedence for left associative
                    std       ,s        update working precedence
                    bra       BuildBinNode build the binary node

CheckSpecialOp      cmpx      #100      special operator check
                    beq       BuildBinNode keep operator value
                    cmpx      #120      special operator check
                    beq       BuildBinNode keep operator value
                    bra       CheckOpPrec otherwise check precedence

BuildBinNode        ldd       ,s        working precedence
                    pshs      d         pass as argument
                    lbsr      ParseExpr recurse for the right operand
                    leas      2,s        drop the argument
                    tfr       d,u       right operand node
                    stu       -2,s      test for null
                    lbeq      MissingRhsErr missing right operand
                    ldd       10,s      operator kind
                    cmpd      #'d       comma-like operator
                    lbne      MakeBinNode otherwise build normal node
                    ldd       #47       node kind
                    pshs      d         push kind
                    lbsr      ExpectToken expect matching token
                    std       ,s++      save and discard result
                    bne       FreeAndReturn on error, cleanup
                    ldd       GlbVar0063 source position
                    std       2,s       save position
                    ldd       GlbVar003F current line
                    std       4,s       save line
                    ldd       #3        node kind
                    pshs      d         push kind
                    lbsr      ParseExpr parse another operand
                    leas      2,s        drop the argument
                    std       6,s       save the operand
                    beq       MissingOperandErr missing operand error
                    ldd       2,s       position argument
                    pshs      d         push
                    ldd       6,s       operand argument
                    pshs      d         push
                    ldd       #3        node kind argument
                    pshs      d         push
                    ldd       12,s      left operand argument
                    pshs      d         push
                    pshs      u         right operand argument
                    ldd       #47       node kind argument
                    pshs      d         push
                    lbsr      NewExprNode build the ternary node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
                    bra       MakeBinNode continue

MissingOperandErr   leax      MsgThirdExprMissing,pcr error message text
                    pshs      x         push
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
FreeAndReturn       pshs      u         right operand
                    lbsr      WalkTree  free the operand tree
                    leas      2,s        drop the argument
                    leax      14,s      restore the frame
                    bra       ExprRestoreStack return path

MakeBinNode         ldd       2,s       position argument
                    pshs      d         push
                    ldd       6,s       operand value argument
                    pshs      d         push
                    ldd       12,s      left operand argument
                    pshs      d         push
                    pshs      u         right operand argument
                    ldd       20,s      line argument
                    pshs      d         push
                    ldd       20,s      operator kind argument
                    pshs      d         push
                    lbsr      NewExprNode build the binary node
                    leas      12,s       drop the arguments
                    std       12,s      save as the new left operand
                    bra       CheckPrecLoop climb precedence again

MissingRhsErr       leax      MsgOperandExpected,pcr missing operand message
                    pshs      x         push
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
CheckPrecLoop       lbsr      IsTypeToken look up next operator precedence
                    std       -2,s      test it
                    beq       ParseExprDone no operator, done
                    ldd       18,s      outer precedence
                    cmpd      GlbVar0061 versus this operator's precedence
                    lble      ParseExprLoop higher, keep building
                    bra       ParseExprDone else done

ExprRestoreStack    leas      -14,x     restore stack from saved frame
ParseExprDone       ldd       12,s      result node
ParseExprExit       leas      14,s       free the locals
                    puls      pc,u      return

ParsePrimary        pshs      u         save the caller u register
                    ldd       #$FFA4    stack space needed
                    lbsr      stkcheck  verify stack space
                    leas      -12,s      allocate locals
                    ldu       #0        null result node
                    ldx       GlbVar005F current token
                    lbra      ParsePrimaryDispatch dispatch on the token

MakeLeafNode        ldd       GlbVar0063 source position
                    pshs      d         push
                    ldd       GlbVar003F current line
                    pshs      d         push
                    ldd       GlbVar0061 token value
                    pshs      d         push
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    ldd       GlbVar005F token kind
                    pshs      d         push
                    lbsr      NewExprNode build the leaf node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
                    lbsr      ScanToken advance the token
                    lbra      LeftOperandCheck finish

ParseCastOrSizeof   lbsr      ScanToken advance past the marker
                    lbsr      ClassifyType is the next token a type keyword
                    std       -2,s      test it
                    beq       SizeofExpr not a type, sizeof expression
                    lbsr      ParseCast build the type node
                    tfr       d,u       type node
                    ldd       #'.       expect close paren
                    pshs      d         push
                    lbsr      ExpectToken expect it
                    leas      2,s        drop the argument
                    bsr       ParsePrimary parse the cast operand
                    std       10,u      attach the operand
                    lbne      LeftOperandCheck on error finish
                    pshs      u         cast node
                    lbsr      LinkNode  link the node
                    leas      2,s        drop the argument
                    ldu       #0        clear result
                    lbra      LeftOperandCheck finish

SizeofExpr          clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero argument
                    lbsr      ParseExpr parse the operand expression
                    leas      2,s        drop the argument
                    tfr       d,u       operand node
                    stu       -2,s      test it
                    bne       ExpectCloseParen got operand
                    bra       SizeofBuildNode build empty node

SizeofRestoreStack  leas      -12,x     restore stack from saved frame
SizeofBuildNode     lbsr      ExprMissingErr report missing operand
                    ldd       GlbVar0063 source position
                    pshs      d         push
                    ldd       GlbVar003F current line
                    pshs      d         push
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    ldd       #54       sizeof node kind
                    pshs      d         push
                    lbsr      NewExprNode build the sizeof node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
ExpectCloseParen    ldd       #'.       expect close paren
                    pshs      d         push
                    lbsr      ExpectToken expect it
                    lbra      PrimaryTail finish

ParseUnaryPrefix    ldd       GlbVar005F operator token
                    std       8,s       save the operator
                    ldd       GlbVar003F current line
                    std       6,s       save line
                    ldd       GlbVar0063 source position
                    std       4,s       save position
                    lbsr      ScanToken advance past the operator
                    lbsr      ParsePrimary parse the operand
                    std       10,s      save the operand
                    beq       UnaryOperandErr missing operand
                    ldd       4,s       position argument
                    pshs      d         push
                    ldd       8,s       operator argument
                    pshs      d         push
                    ldd       #14       prefix node kind
                    pshs      d         push
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    ldd       18,s      operand argument
                    pshs      d         push
                    ldd       18,s      operand argument
                    pshs      d         push
                    lbsr      NewExprNode build the unary node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
                    lbra      LeftOperandCheck finish

UnaryOperandErr     leax      MsgPrimaryExpected,pcr missing operand message
                    pshs      x         push
                    lbsr      PrintErrLoc print the error
                    lbra      PrimaryTail finish

ParseParenExpr      ldd       GlbVar003F current line
                    std       6,s       save line
                    ldd       GlbVar0063 source position
                    std       4,s       save position
                    lbsr      ScanToken advance past the token
                    ldd       GlbVar005F current token
                    cmpd      #45       type-cast marker
                    bne       ParenSubExpr no, parse a subexpression
                    lbsr      ScanToken advance
                    lbsr      ClassifyType is it a type keyword
                    std       -2,s      test it
                    beq       ParenExprNoType not a type
                    lbsr      ParseCast build the type node
                    std       10,s      save the type
                    bra       ParenExpectClose expect the close paren

ParenExprNoType     clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero argument
                    lbsr      ParseExpr parse the expression
                    leas      2,s        drop the argument
                    std       10,s      save the node
                    bne       ParenExpectClose got it
                    leax      12,s      restore frame pointer
                    lbra      SizeofRestoreStack handle the missing operand

ParenExpectClose    ldd       #'.       expect close paren
                    pshs      d         push
                    lbsr      ExpectToken expect it
                    leas      2,s        drop the argument
                    bra       ParenBuildNode build the node

ParenSubExpr        lbsr      ParsePrimary parse the operand
                    std       10,s      save the operand
ParenBuildNode      ldd       10,s      operand or type node
                    std       ,s        store working copy
                    ldd       4,s       position argument
                    pshs      d         push
                    ldd       8,s       line argument
                    pshs      d         push
                    leax      4,s       pointer to the node
                    pshs      x         push
                    lbsr      EmitExpr  compute the node result
                    std       ,s        store the result
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    ldd       #54       sizeof node kind
                    pshs      d         push
                    lbsr      NewExprNode build the node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
                    ldd       ,s        the node
                    pshs      d         push
                    lbsr      WalkTree  free the temporary tree
PrimaryTail         leas      2,s        drop the argument
                    bra       LeftOperandCheck finish

ParsePrimaryDispatch cmpx      #55       leaf token: constant
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #52       leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #74       leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #75       leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #54       leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #45       cast or sizeof marker
                    lbeq      ParseCastOrSizeof parse cast or sizeof
                    cmpx      #64       prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #67       prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #68       prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #66       prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #61       prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #60       prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #65       compare token against a type keyword
                    lbeq      ParseUnaryPrefix branch to that keyword handler
                    cmpx      #59       compare token 3B
                    lbeq      ParseParenExpr branch to its handler
LeftOperandCheck    cmpu      #0        test whether a left operand exists yet
                    bne       OpDispatchA have operand, dispatch operator
                    clra                result high byte zero
                    clrb                result low byte zero
                    lbra      BinParseDone return empty expression

OpDispatchA         ldx       GlbVar005F load current token type
                    lbra      OpTableA  dispatch on the operator token

BuildNodeTok2D      ldd       GlbVar0063 save current line number
                    std       4,s       stash line in frame
                    ldd       GlbVar003F save file/column global
                    std       6,s       stash it in frame
                    lbsr      ScanToken advance to next token
                    ldd       4,s       reload saved line
                    pshs      d         pass as node argument
                    ldd       8,s       load left operand pointer
                    pshs      d         pass left operand
                    ldd       #15       node type field
                    pshs      d         pass type field
                    lbsr      ParsePostfix parse the right-hand postfix operand
                    pshs      d         pass right operand
                    pshs      u         pass left node
                    ldd       #101      operator code for the node
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the binary tree node
                    leas      12,s       drop node arguments
                    tfr       d,u       new node becomes current
                    ldd       #46       following operator token
                    lbra      EmitOpAndLoop emit it and continue loop

BuildNodeTok2B      lbsr      ScanToken advance past the operator token
                    ldd       #2        lookup kind two
                    pshs      d         pass lookup kind
                    lbsr      ParseExpr look up the operand symbol
                    leas      2,s        drop argument
                    std       10,s      save returned pointer
                    bne       Tok2BNodeChain found, skip placeholder node
                    lbsr      ExprMissingErr report the missing operand error
                    ldd       GlbVar0063 current line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    ldd       #54       constant node kind
                    pshs      d         pass node kind
                    lbsr      NewExprNode build a placeholder constant node
                    leas      12,s       drop arguments
                    std       10,s      save as operand
Tok2BNodeChain      ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       #12       node type field
                    pshs      d         pass type field
                    ldd       16,s      left operand pointer
                    pshs      d         pass left operand
                    pshs      u         pass current node
                    ldd       #80       operator code
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the tree node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       #15       node type field
                    pshs      d         pass type field
                    clra                null operand high
                    clrb                null operand low
                    pshs      d         pass null operand
                    pshs      u         pass current node
                    ldd       #66       operator code
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the tree node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    ldd       #44       operator token to emit
EmitOpAndLoop       pshs      d         pass token
                    lbsr      ExpectToken emit the operator token
                    leas      2,s        drop argument
                    lbra      OpDispatchA loop for next operator

BuildNodeTok45      ldd       GlbVar005F current token type
                    std       8,s       save token type
                    ldd       GlbVar003F file/column global
                    std       6,s       save it in frame
                    ldd       GlbVar0063 line number
                    std       4,s       save it in frame
                    ldd       GlbVar0041 nesting counter
                    addd      #1        increment it
                    std       GlbVar0041 store back
                    lbsr      ScanToken advance to next token
                    ldd       GlbVar0041 reload nesting counter
                    addd      #$FFFF    decrement it back
                    std       GlbVar0041 store back
                    ldd       GlbVar005F new token type
                    cmpd      #52       is it a constant token
                    beq       Tok45FoldConst yes, fold the constant
                    lbsr      ErrIdentMissing parse a sub-expression operand
                    lbra      OpDispatchB continue with second dispatch

Tok45FoldConst      ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       GlbVar0061 operand value or size
                    pshs      d         pass it
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    ldd       GlbVar005F token type as node kind
                    pshs      d         pass node kind
                    lbsr      NewExprNode build the constant node
                    leas      12,s       drop arguments
                    std       10,s      save operand node
                    ldd       4,s       saved line/frame value
                    pshs      d         pass it
                    ldd       8,s       saved frame value
                    pshs      d         pass it
                    ldd       #15       node type field
                    pshs      d         pass type field
                    ldd       16,s      operand node
                    pshs      d         pass operand
                    pshs      u         pass current node
                    ldd       18,s      operator code from frame
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the binary node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    lbsr      ScanToken advance to next token
                    lbra      OpDispatchA loop for next operator

OpTableA            cmpx      #45       operator token 2D
                    lbeq      BuildNodeTok2D handle it
                    cmpx      #43       operator token 2B
                    lbeq      BuildNodeTok2B handle it
                    cmpx      #69       operator token 45
                    lbeq      BuildNodeTok45 handle it
                    cmpx      #70       operator token 46
                    lbeq      BuildNodeTok45 handle it
OpDispatchB         ldx       GlbVar005F reload current token type
                    bra       OpTableB  dispatch the second operator set

BuildNodeTok3C      ldd       #62       canonical operator code 3E
                    std       GlbVar005F override current token
                    leax      12,s      point at frame slot
                    bra       RelNodeAlloc go build the node

BuildNodeTok3D      ldd       #63       canonical operator code 3F
                    std       GlbVar005F override current token
                    bra       RelNodeBuild go build the node

RelNodeAlloc        leas      -12,x     reserve node argument space
RelNodeBuild        ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       #14       node type field
                    pshs      d         pass type field
                    clra                null operand high
                    clrb                null operand low
                    pshs      d         pass null operand
                    pshs      u         pass current node
                    ldd       GlbVar005F operator code
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the unary node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    lbsr      ScanToken advance to next token
                    bra       MergeResult merge result and return

OpTableB            cmpx      #60       operator token 3C
                    beq       BuildNodeTok3C handle it
                    cmpx      #61       operator token 3D
                    beq       BuildNodeTok3D handle it
MergeResult         tfr       u,d       move current node to return register
BinParseDone        leas      12,s       release locals
                    puls      pc,u      return to caller

ParsePostfix        pshs      u         save the caller u register
                    ldd       #$FFAE    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate a local
                    ldu       #0        null accumulator node
                    bra       PostfixLoop enter the postfix loop

PostfixLoop         ldd       GlbVar005F current token type
                    cmpd      #46       is it the postfix separator
                    beq       PostfixDone none, finish
                    ldd       #2        lookup kind two
                    pshs      d         pass kind
                    lbsr      ParseExpr look up member operand
                    leas      2,s        drop argument
                    std       ,s        save operand pointer
                    beq       PostfixCheckChain not found, skip node build
                    ldx       ,s        operand pointer
                    ldd       16,x      its type field
                    pshs      d         pass it
                    ldx       2,s       previous node pointer
                    ldd       14,x      its field
                    pshs      d         pass it
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    pshs      u         pass accumulator node
                    ldd       8,s       operand pointer
                    pshs      d         pass operand
                    ldd       #11       postfix node kind
                    pshs      d         pass node kind
                    lbsr      NewExprNode build the postfix node
                    leas      12,s       drop arguments
                    std       ,s        save the node
                    ldu       ,s        becomes accumulator
PostfixCheckChain   ldd       GlbVar005F current token type
                    cmpd      #48       chained postfix operator
                    bne       PostfixDone no, finish loop
                    lbsr      ScanToken advance to next token
                    bra       PostfixLoop loop for next postfix

PostfixDone         tfr       u,d       move accumulator to return register
                    bra       ConstOpExit go to shared epilogue

EvalConstOperand    pshs      u         save the caller u register
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate a local
                    ldd       6,s       argument value
                    pshs      d         pass it
                    lbsr      ParseExpr look up the operand
                    std       ,s        save operand pointer
                    lbsr      OptExprTree resolve or evaluate the node
                    leas      2,s        drop argument
                    tfr       d,u       result node pointer
                    stu       -2,s      save local copy
                    beq       NotConstErr null, emit error
                    ldd       6,u       node kind field
                    cmpd      #54       is it a constant node
                    bne       NotConstErr no, emit error
                    ldd       8,u       constant value
                    std       ,s        save the value
                    bra       FreeConstNode proceed to free node

NotConstErr         clra                zero value high
                    clrb                zero value low
                    std       ,s        store zero value
                    leax      MsgConstantRequired,pcr constant-required message
                    pshs      x         pass the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
FreeConstNode       stu       -2,s      reload node pointer
                    beq       ConstResult null, skip freeing
                    pshs      u         pass node pointer
                    lbsr      WalkTree  free the temporary node
                    leas      2,s        drop argument
ConstResult         ldd       ,s        load constant value to return
ConstOpExit         leas      2,s        release the local
                    puls      pc,u      return to caller

IsTypeToken         pshs      u         save the caller u register
                    ldd       #$FFC0    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    ldx       GlbVar005F current token type
                    bra       TypeTokTable dispatch the type test

TokAToType          ldd       #87       canonical type token
                    std       GlbVar005F rewrite current token
                    ldd       #8        type size
                    bra       SetTypeSize store the size

TokBToType          ldd       #82       canonical type token
                    std       GlbVar005F rewrite current token
                    ldd       #13       type size
                    bra       SetTypeSize store the size

TokCToType          ldd       #81       canonical type token
                    std       GlbVar005F rewrite current token
                    ldd       #12       type size
SetTypeSize         std       GlbVar0061 store type size global
TokIsType           ldd       #1        token is a type
                    puls      pc,u      return true

CheckTypeRange      ldd       GlbVar005F current token type
                    cmpd      #71       below the type range
                    blt       CheckTypeRange2 if so, check extended range
                    ldd       GlbVar005F current token type
                    cmpd      #95       within the first type range
                    ble       TypeYes   yes, it is a type
CheckTypeRange2     ldd       GlbVar005F current token type
                    cmpd      #160      below extended type range
                    lblt      ConstOpZero no, not a type
                    ldd       GlbVar005F current token type
                    cmpd      #169      above extended type range
                    lbgt      ConstOpZero no, not a type
TypeYes             ldd       #1        token is a type
                    lbra      ConstOpReturn return true

TypeTokTable        cmpx      #65       type keyword A
                    beq       TokAToType map it
                    cmpx      #66       type keyword B
                    beq       TokBToType map it
                    cmpx      #67       type keyword C
                    beq       TokCToType map it
                    cmpx      #48       already a type token
                    beq       TokIsType return true
                    cmpx      #120      already a type token
                    lbeq      TokIsType return true
                    cmpx      #100      already a type token
                    lbeq      TokIsType return true
                    cmpx      #47       not a type token
                    lbeq      ConstOpZero return false
                    bra       CheckTypeRange check the type code ranges

                    puls      pc,u      return (unreached)

FoldBinaryOp        pshs      u         save the caller u register
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    ldx       4,s       operator code to fold
                    lbra      FoldBinaryConst dispatch to the fold routine

FoldAdd             ldd       6,s       left operand
                    addd      8,s       add the right operand
                    puls      pc,u      return the sum

FoldSub             ldd       6,s       left operand
                    subd      8,s       subtract the right operand
                    puls      pc,u      return the difference

FoldMul             ldd       6,s       left operand
                    pshs      d         pass it
                    ldd       10,s      right operand
                    lbsr      MulEntry  multiply
                    puls      pc,u      return the product

FoldDiv             ldd       8,s       right operand is the divisor
                    beq       FoldDivZero zero divisor, division error
                    ldd       6,s       left operand
                    pshs      d         pass it
                    ldd       10,s      divisor
                    lbsr      SDivEntry divide
                    bra       FoldDivDone return the quotient

FoldMod             ldd       8,s       right operand is the divisor
                    beq       FoldDivZero zero divisor, division error
                    ldd       6,s       left operand
                    pshs      d         pass it
                    ldd       10,s      divisor
                    lbsr      SignedDivSetup take the modulo
FoldDivDone         puls      pc,u      return the result

FoldDivZero         lbsr      PrintNodeMsg report divide by zero
                    lbra      ConstOpZero return zero

FoldAnd             ldd       6,s       left operand
                    anda      8,s       and the high byte
                    andb      9,s       and the low byte
                    puls      pc,u      return the bitwise and

FoldOr              ldd       6,s       left operand
                    ora       8,s       or the high byte
                    orb       9,s       or the low byte
                    puls      pc,u      return the bitwise or

FoldXor             ldd       6,s       left operand
                    eora      8,s       xor the high byte
                    eorb      9,s       xor the low byte
                    puls      pc,u      return the bitwise xor

FoldShiftLeft       ldd       6,s       left operand
                    pshs      d         pass it
                    ldd       10,s      shift count
                    lbsr      AslEntry  shift left
                    puls      pc,u      return the shifted value

FoldShiftRight      ldd       6,s       left operand
                    pshs      d         pass it
                    ldd       10,s      shift count
                    lbsr      AsrEntry  shift right
                    puls      pc,u      return the shifted value

FoldEqual           ldd       6,s       left operand
                    cmpd      8,s       compare with right operand
                    lbne      ConstOpZero not equal, return zero
                    ldd       #1        equal, result true
                    lbra      ConstOpReturn return one

FoldNotEqual        ldd       6,s       left operand
                    cmpd      8,s       compare with right operand
                    lbeq      ConstOpZero equal, return zero
                    ldd       #1        unequal, result true
                    lbra      ConstOpReturn return one

FoldGreater         ldd       6,s       left operand
                    cmpd      8,s       compare with right operand
                    lble      ConstOpZero not greater, return zero
                    ldd       #1        greater, result true
                    lbra      ConstOpReturn return one

FoldLess            ldd       6,s       left operand
                    cmpd      8,s       compare with right operand
                    lbge      ConstOpZero not less, return zero
                    ldd       #1        less, result true
                    lbra      ConstOpReturn return one

FoldGreaterEq       ldd       6,s       left operand
                    cmpd      8,s       compare with right operand
                    lblt      ConstOpZero less, return zero
                    ldd       #1        not less, result true
                    lbra      ConstOpReturn return one

FoldLessEq          ldd       6,s       left operand
                    cmpd      8,s       compare with right operand
                    lbgt      ConstOpZero greater, return zero
                    ldd       #1        not greater, result true
                    lbra      ConstOpReturn return one

FoldNegate          ldd       6,s       operand
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        finish 16-bit negation
                    puls      pc,u      return the negation

FoldLogNot          ldd       6,s       operand
                    lbne      ConstOpZero nonzero, return zero
                    ldd       #1        zero, result true
                    lbra      ConstOpReturn return one

FoldBitNot          ldd       6,s       operand
                    coma                complement high byte
                    comb                complement low byte
                    puls      pc,u      return the complement

FoldLogAnd          ldd       6,s       left operand
                    lbeq      ConstOpZero zero, result false
                    ldd       8,s       right operand
                    lbeq      ConstOpZero zero, result false
                    ldd       #1        both nonzero, result true
                    lbra      ConstOpReturn return one

FoldLogOr           ldd       6,s       left operand
                    bne       FoldLogOrTrue nonzero, result true
                    ldd       8,s       right operand
                    lbeq      ConstOpZero both zero, result false
FoldLogOrTrue       ldd       #1        result true
                    lbra      ConstOpReturn return one

FoldUnsignedOp      leas      -4,s       allocate locals
                    ldd       12,s      left operand
                    std       2,s       save as local
                    ldd       10,s      load left operand value
                    std       ,s        store as comparison left side
                    ldx       8,s       load the relational operator code
                    bra       ConstCmpDispatch dispatch by relational operator

ConstCmpLE          ldd       ,s        load left operand
                    cmpd      2,s       compare against right operand
                    bhi       ConstCmpFalse if left higher then result is false
                    ldd       #1        result is true
                    bra       ConstCmpDone return the folded value

ConstCmpLT          ldd       ,s        load left operand
                    cmpd      2,s       compare against right operand
                    bcc       ConstCmpFalse if left greater or equal then false
                    ldd       #1        result is true
                    bra       ConstCmpDone return the folded value

ConstCmpGE          ldd       ,s        load left operand
                    cmpd      2,s       compare against right operand
                    bcs       ConstCmpFalse if left less then false
                    ldd       #1        result is true
                    bra       ConstCmpDone return the folded value

ConstCmpGT          ldd       ,s        load left operand
                    cmpd      2,s       compare against right operand
                    bls       ConstCmpFalse if left less or equal then false
                    ldd       #1        result is true
                    bra       ConstCmpDone return the folded value

ConstCmpFalse       clra                clear high byte of result
                    clrb                result is false
ConstCmpDone        leas      4,s        drop the operand scratch
                    puls      pc,u      return the folded value

ConstCmpDispatch    cmpx      #96       operator is less-or-equal
                    beq       ConstCmpLE handle less-or-equal
                    cmpx      #97       operator is less-than
                    beq       ConstCmpLT handle less-than
                    cmpx      #98       operator is greater-or-equal
                    beq       ConstCmpGE handle greater-or-equal
                    bra       ConstCmpGT otherwise handle greater-than

                    leas      4,s        drop operand scratch
ConstOpError        leax      MsgConstantOperator,pcr point at constant-operator message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop the argument
ConstOpZero         clra                clear high byte
                    clrb                return zero result
ConstOpReturn       puls      pc,u      return

FoldBinaryConst     cmpx      #80       operator code $0050
                    lbeq      FoldAdd   dispatch to its handler
                    cmpx      #81       operator code $0051
                    lbeq      FoldSub   dispatch to its handler
                    cmpx      #82       operator code $0052
                    lbeq      FoldMul   dispatch to its handler
                    cmpx      #83       operator code $0053
                    lbeq      FoldDiv   dispatch to its handler
                    cmpx      #84       operator code $0054
                    lbeq      FoldMod   dispatch to its handler
                    cmpx      #87       operator code $0057
                    lbeq      FoldAnd   dispatch to its handler
                    cmpx      #88       operator code $0058
                    lbeq      FoldOr    dispatch to its handler
                    cmpx      #89       operator code $0059
                    lbeq      FoldXor   dispatch to its handler
                    cmpx      #86       operator code $0056
                    lbeq      FoldShiftLeft dispatch to its handler
                    cmpx      #85       operator code $0055
                    lbeq      FoldShiftRight dispatch to its handler
                    cmpx      #90       operator code $005A
                    lbeq      FoldEqual dispatch to its handler
                    cmpx      #91       operator code $005B
                    lbeq      FoldNotEqual dispatch to its handler
                    cmpx      #95       operator code $005F
                    lbeq      FoldGreater dispatch to its handler
                    cmpx      #93       operator code $005D
                    lbeq      FoldLess  dispatch to its handler
                    cmpx      #94       operator code $005E
                    lbeq      FoldGreaterEq dispatch to its handler
                    cmpx      #92       operator code $005C
                    lbeq      FoldLessEq dispatch to its handler
                    cmpx      #67       operator code $0043
                    lbeq      FoldNegate dispatch to its handler
                    cmpx      #64       operator code $0040
                    lbeq      FoldLogNot dispatch to its handler
                    cmpx      #68       operator code $0044
                    lbeq      FoldBitNot dispatch to its handler
                    cmpx      #71       operator code $0047
                    lbeq      FoldLogAnd dispatch to its handler
                    cmpx      #72       operator code $0048
                    lbeq      FoldLogOr dispatch to its handler
                    cmpx      #96       relational operator $0060
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    cmpx      #97       relational operator $0061
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    cmpx      #98       relational operator $0062
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    cmpx      #99       relational operator $0063
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    lbra      ConstOpError unknown operator error

                    puls      pc,u      return

ParseCast           pshs      u         save the caller u register
                    ldd       #$FFA2    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    leas      -14,s      reserve local storage
                    ldd       GlbVar003F load the current token global
                    std       4,s       save it in a local
                    ldd       GlbVar0063 load the current type global
                    std       2,s       save it in a local
                    leax      ,s        point at local buffer
                    pshs      x         pass the pointer
                    leax      12,s      point at another local
                    pshs      x         pass the pointer
                    leax      16,s      point at the argument slot
                    pshs      x         pass the pointer
                    lbsr      ParseDeclSpec parse the type specifier
                    leas      6,s        drop the three pointers
                    std       8,s       save the parsed type
                    pshs      d         pass the type
                    leax      12,s      point at local
                    pshs      x         pass the pointer
                    leax      10,s      point at local
                    pshs      x         pass the pointer
                    lbsr      ParseTypeSpec parse the abstract declarator
                    leas      6,s        drop the arguments
                    std       8,s       save the declarator result
                    leax      >GlbVar0047,y  point at the type table entry
                    pshs      x         pass the pointer
                    lbsr      EndScopeCheck build the cast type
                    leas      2,s        drop the argument
                    ldd       6,s       load the returned status
                    beq       BuildCastNode no error so continue
                    leax      MsgNameInCast,pcr point at name-in-a-cast message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop the argument
BuildCastNode       ldd       2,s       load the saved type
                    pshs      d         push as node argument
                    ldd       6,s       load the declarator
                    pshs      d         push as node argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push a zero argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push a zero argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push a zero argument
                    ldd       #32       node kind is cast
                    pshs      d         push the node kind
                    bsr       NewExprNode allocate the cast node
                    leas      12,s       drop the six arguments
                    std       6,s       save the node pointer
                    ldd       8,s       load the parsed type
                    std       [6,s]     store it into the node
                    ldd       12,s      load a field
                    pshs      d         push as argument
                    ldd       12,s      load a field
                    pshs      d         push as argument
                    ldd       10,s      load a field
                    pshs      d         push as argument
                    lbsr      SetNodeTypeSize finalize the cast node
                    leas      6,s        drop the arguments
                    ldd       6,s       return the node pointer
                    leas      14,s       release the locals
                    puls      pc,u      return

NewExprNode         pshs      u         save the caller u register
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldd       GlbNodeList load the node free list head
                    beq       NewNodeAlloc if empty allocate fresh
                    ldu       GlbNodeList take the head node
                    ldd       10,u      load its next-free link
                    std       GlbNodeList unlink from the free list
                    bra       NewNodeFill go fill the node

NewNodeAlloc        ldd       #22       node size is 22 bytes
                    pshs      d         pass the size
                    lbsr      AllocMem  allocate memory
                    leas      2,s        drop the size argument
                    tfr       d,u       node pointer into U
NewNodeFill         ldd       4,s       load the first argument
                    std       6,u       store the node kind
                    ldd       6,s       load an argument
                    std       10,u      store the left child
                    ldd       8,s       load an argument
                    std       12,u      store the right child
                    ldd       10,s      load an argument
                    std       8,u       store the value field
                    ldd       12,s      load an argument
                    std       14,u      store a field
                    ldd       14,s      load an argument
                    std       16,u      store a field
                    clra                clear high byte
                    clrb                clear low byte
                    std       20,u      clear the last field
                    tfr       u,d       return the node pointer
                    puls      pc,u      return

ExprMissingErr      pshs      u         save the caller u register
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    leax      MsgExpressionMissing,pcr point at expression-missing message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    lbra      EmitExprDone return

EmitExpr            pshs      u         save the caller u register
                    ldd       #$FFB6    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       [4,s]     load the expression node
                    ldx       6,u       load its node type
                    bra       EmitExprDispatch dispatch on node type

EmitExprOpt         pshs      u         save the caller u register
                    lbsr      OptExprTree optimize the expression tree
                    leas      2,s        drop the argument
                    std       [4,s]     store the optimized node back
                    tfr       d,u       node pointer into U
                    leax      ,s        point at scratch
                    bra       EmitLeafRestore emit the node

EmitDeref           ldd       [8,u]     load the indirect target
                    std       ,u        overwrite the node value
                    pshs      u         pass the node
                    lbsr      ChkUndeclared resolve the indirection
                    leas      2,s        drop the argument
                    ldu       8,u       follow the pointer
                    bra       EmitLeaf  emit the node

EmitLeafRestore     leas      ,x        restore the stack pointer
EmitLeaf            ldd       4,u       load a node field
                    pshs      d         push as argument
                    ldd       2,u       load a node field
                    pshs      d         push as argument
                    ldd       ,u        load the node value
                    pshs      d         push as argument
                    lbsr      ComputeElemSize emit the operand
                    leas      6,s        drop the arguments
                    puls      pc,u      return

EmitExprField       pshs      u         save the caller u register
                    ldd       #12       field offset
                    addd      ,s++      add to the node pointer
                    pshs      d         push the field pointer
                    bsr       EmitExpr  recurse into the subexpression
EmitExprDone        leas      2,s        drop the argument
                    puls      pc,u      return

EmitExprDispatch    cmpx      #52       node type indirection
                    beq       EmitDeref handle indirection
                    cmpx      #32       node type leaf
                    beq       EmitLeaf  emit as leaf
                    cmpx      #69       node type field
                    beq       EmitExprField handle field
                    cmpx      #70       node type field
                    lbeq      EmitExprField handle field
                    lbra      EmitExprOpt otherwise optimize and emit

                    puls      pc,u      return

MsgThirdExprMissing fcc       /third expression missing/
                    fcb       C$NULL
MsgOperandExpected  fcc       /operand expected/
                    fcb       C$NULL
MsgPrimaryExpected  fcc       /primary expected/
                    fcb       C$NULL
MsgConstantRequired fcc       /constant required/
                    fcb       C$NULL
MsgConstantOperator fcc       /constant operator/
                    fcb       C$NULL
MsgNameInCast       fcc       /name in a cast/
                    fcb       C$NULL
MsgExpressionMissing fcc       /expression missing/
                    fcb       C$NULL
OptExprTree         pshs      u         save the caller u register
                    ldd       #$FFAE    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the expression node
                    leas      -12,s      reserve local storage
                    stu       -2,s      save the node pointer
                    lbeq      OptExprDone null node so return
                    ldd       10,u      load the left child
                    pshs      d         pass it
                    bsr       OptExprTree optimize the left subtree
                    leas      2,s        drop the argument
                    std       10,u      store the optimized left child
                    ldd       12,u      load the right child
                    pshs      d         pass it
                    lbsr      OptExprTree optimize the right subtree
                    leas      2,s        drop the argument
                    std       12,u      store the optimized right child
                    pshs      u         pass the node
                    lbsr      GenSymbolExpr get the operator descriptor
                    leas      2,s        drop the argument
                    tfr       d,u       descriptor into U
                    pshs      u         pass the node
                    lbsr      IsFoldableTag try constant folding
                    std       ,s++      save the fold result
                    beq       OptRebalance not folded so keep optimizing
                    leax      12,s      adjust stack for the result
                    lbra      OptAdjustLocals return the folded node

OptRebalance        pshs      u         pass the descriptor
                    lbsr      SimplifyExpr simplify the expression
                    leas      2,s        drop the argument
                    tfr       d,u       result into U
                    ldd       10,u      load the left child
                    std       10,s      save it
                    ldd       12,u      load the right child
                    std       8,s       save it
                    ldd       6,u       load the operator
                    std       4,s       save it
                    cmpd      #100      operator is index or deref
                    bne       OptCheckAddSub no so check associativity
                    ldx       10,s      load the left child node
                    ldd       6,x       load its operator
                    cmpd      #54       is it a constant
                    bne       OptCheckAddSub no so check associativity
                    ldx       10,s      reload the left child
                    ldd       8,x       load the child value
                    beq       OptSwapOperand zero so swap operands
                    ldx       8,s       load the right child
                    ldd       10,x      load an operand
                    std       2,s       save the operand
                    ldx       8,s       reload the right child
                    ldd       12,x      load an operand
                    bra       OptEmitPair emit the operand pair

OptSwapOperand      ldx       8,s       load the right child
                    ldd       12,x      load an operand
                    std       2,s       save the operand
                    ldx       8,s       reload the right child
                    ldd       10,x      load an operand
OptEmitPair         pshs      d         push the operand
                    lbsr      WalkTree  emit the operand
                    leas      2,s        drop the argument
                    ldd       8,s       load a node
                    pshs      d         pass it
                    lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    ldd       10,s      load a node
                    pshs      d         pass it
                    lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    pshs      u         push the result node
                    bra       OptFreeTail finish

OptCheckAddSub      ldd       4,s       load the operator
                    cmpd      #66       operator is add
                    bne       OptCheckSubAdd no so check subtract form
                    ldx       10,s      load the left child
                    ldd       6,x       load its operator
                    cmpd      #65       is left a subtract
                    beq       OptCombineNested yes so combine them
OptCheckSubAdd      ldd       4,s       load the operator
                    cmpd      #65       operator is subtract
                    bne       OptExprDone no so done
                    ldx       10,s      load the left child
                    ldd       6,x       load its operator
                    cmpd      #66       is left an add
                    bne       OptExprDone no so done
OptCombineNested    ldx       10,s      load the left child
                    ldd       10,x      load the nested operand
                    std       2,s       save it
                    ldd       ,u        load the node value
                    std       [2,s]     patch the nested node
                    ldd       2,u       load a node field
                    ldx       2,s       load the saved node pointer
                    std       2,x       copy the field across
                    pshs      u         pass the node
                    lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    ldd       10,s      load a node
                    pshs      d         pass it
OptFreeTail         lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    ldu       2,s       reload the result node
                    bra       OptExprDone done

OptAdjustLocals     leas      -12,x     restore reserved locals via X
OptExprDone         tfr       u,d       return the node pointer
                    leas      12,s       release the locals
                    puls      pc,u      return

SimplifyExpr        pshs      u         save the caller u register
                    ldd       #$FFA8    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the expression node
                    leas      -14,s      reserve local storage
                    stu       -2,s      save the node pointer
                    bne       SimplifyClassify non-null so proceed
                    clra                clear high byte
                    clrb                clear low byte
                    lbra      TeardownReturn return null result

SimplifyClassify    ldd       10,u      load the left child
                    std       12,s      save it
                    ldd       12,u      load the right child
                    std       10,s      save it
                    ldd       6,u       load the operator
                    std       6,s       save it
                    pshs      d         pass the operator
                    lbsr      IsOpToken classify the operator
                    std       ,s++      save the classification
                    bne       CheckConstOperands commutative so continue
                    ldd       6,s       load the operator
                    cmpd      #71       operator is a comparison
                    beq       CheckConstOperands treat as commutative
                    ldd       6,s       load the operator
                    cmpd      #72       operator is a comparison
                    lbne      LoadTagDispatch2 otherwise skip reordering
CheckConstOperands  ldx       12,s      load the left child
                    ldd       6,x       load its operator
                    cmpd      #54       is left a constant
                    bne       LeftNotConst no so flag zero
                    ldd       #1        flag left is constant
                    bra       CheckRightConst save the flag

LeftNotConst        clra                clear high byte
                    clrb                clear low byte
CheckRightConst     std       2,s       save the left-constant flag
                    pshs      d         push the flag
                    ldx       12,s      load the right child
                    ldd       6,x       load its operator
                    cmpd      #54       is right a constant
                    bne       RightNotConst no so flag zero
                    ldd       #1        flag right is constant
                    bra       BothConstFlags save the flag

RightNotConst       clra                clear high byte
                    clrb                clear low byte
BothConstFlags      std       2,s       save the right-constant flag
                    anda      ,s+       and with left flag high byte
                    andb      ,s+       and with left flag low byte
                    std       -2,s      save the both-constant flag
                    beq       TestLeftConst not both constant so continue
                    leax      14,s      both constant path
                    lbra      BuildStoreFromX fold the two constants

TestLeftConst       ldd       2,s       load the left-constant flag
                    beq       LoadTagAndDispatch left not constant so skip
                    ldx       6,s       load the operator class
                    bra       CheckPtrClassTags reorder the operands

SwapOperands        ldd       12,s      load the right child
                    std       8,s       stash it
                    ldd       10,s      load the left child
                    std       12,s      move it
                    std       10,u      update the node left child
                    ldd       8,s       reload the stashed child
                    std       10,s      restore it
                    std       12,u      update the node right child
                    ldd       #1        mark swapped
                    std       ,s        set the swapped flag
                    bra       LoadTagAndDispatch continue

CheckPtrClassTags   cmpx      #80       compare node tag to P pointer
                    beq       SwapOperands branch when pointer-class tag
                    cmpx      #82       compare tag to R register
                    lbeq      SwapOperands branch when register tag
                    cmpx      #87       compare tag to W
                    lbeq      SwapOperands branch when W tag
                    cmpx      #88       compare tag to X
                    lbeq      SwapOperands branch when X tag
                    cmpx      #89       compare tag to Y
                    lbeq      SwapOperands branch when Y tag
LoadTagAndDispatch  ldx       6,s       load the current node tag
                    lbra      DispatchByTagMain dispatch on the tag

FoldXYNode          ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU nothing to fold return node
                    ldx       10,s      load operand node pointer
                    ldd       8,x       load its value field
                    lbeq      EmitOperandPair fold when operand value zero
                    lbra      ReturnNodeU otherwise return the node

FoldPtrNode         ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       10,s      load operand node pointer
                    ldd       8,x       load its value field
                    lbeq      EmitOperandPair fold zero operand
                    ldx       12,s      load child node
                    ldx       6,x       load child node tag
                    lbra      DispatchChildTag dispatch on child tag

FoldArrayRef        ldx       12,s      load child node
                    ldx       10,x      load grandchild pointer
                    ldd       20,x      load its offset value
                    leax      20,x      point at that field
                    pshs      x,d       save pointer and value
                    ldx       14,s      load target node
                    ldd       8,x       load target value
                    addd      ,s++      add saved offset
                    std       [,s++]    store back through pointer
                    bra       EmitBinaryChildren emit the folded children

EmitPairFromX       leas      -14,x     restore frame from x
EmitBinaryChildren  ldd       12,s      load left child node
                    std       8,s       stash as first operand
                    pshs      u         push result node
                    lbsr      LinkNode  free the child node
                    leas      2,s        drop argument
                    ldd       10,s      load second operand
                    pshs      d         push it
                    lbsr      LinkNode  free the operand node
                    leas      2,s        drop argument
                    ldu       8,s       reload result node
                    lbra      ReturnNodeU return the node

FoldPtrConstAdd     ldx       12,s      load child node
                    ldx       12,x      load grandchild node
                    ldd       6,x       load its tag
                    cmpd      #54       compare to constant 6
                    lbne      ReturnNodeU not constant return node
                    ldx       12,s      reload child node
                    ldx       12,x      grandchild node
                    ldd       8,x       load constant value
                    leax      8,x       point at value field
                    pshs      x,d       save pointer and value
                    ldx       14,s      target node
                    ldd       8,x       its value
                    addd      ,s++      add constant offset
                    lbra      StoreThroughPtr store through pointer and fold

DispatchChildTag    cmpx      #65       child tag A array
                    lbeq      FoldArrayRef fold array reference
                    cmpx      #80       child tag P pointer
                    beq       FoldPtrConstAdd fold pointer add
                    lbra      ReturnNodeU otherwise return node

FoldNegate2         ldd       ,s        test left operand flag
                    beq       MakeConstNode handle no-operand case
                    ldx       10,s      operand node
                    ldd       8,x       load its value
                    nega                negate value high byte
                    negb                negate value low byte
                    sbca      #0        finish two's complement
                    ldx       10,s      reload operand node
                    std       8,x       store negated value
                    ldd       #80       tag P pointer
                    std       6,u       set result tag to pointer
                    pshs      u         push result node
                    lbsr      SimplifyExpr re-simplify the node
                    leas      2,s        drop argument
                    lbra      TeardownReturn return folded node

MakeConstNode       ldd       2,s       test right operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       12,s      load child node
                    ldd       8,x       load its value
                    lbne      ReturnNodeU nonzero return node
                    ldd       #67       tag C constant
                    std       6,u       set result tag
                    ldd       10,s      load operand
                    std       10,u      store into result
                    clra                zero high
                    clrb                zero low
                    std       12,u      clear child pointer
                    ldd       12,s      load child node
                    lbra      EmitOperandJoin emit and return

FoldWNode           ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       10,s      operand node
                    ldd       8,x       its value
                    beq       BuildIndirectNode fold zero to indirect
                    lbra      ReturnNodeU otherwise return node

FoldRNode           ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       10,s      operand node
                    ldx       8,x       load its value as pointer
                    bra       ClassifyRValue classify the rvalue

BuildIndirectNode   leax      14,s      point at frame node
                    lbra      BuildSixFromX build indirect node

FoldRegConst        ldx       12,s      load child node
                    ldd       6,x       load its tag
                    cmpd      #82       compare to R register
                    lbne      ReturnNodeU not register return node
                    ldx       12,s      reload child node
                    ldx       12,x      grandchild node
                    ldd       6,x       its tag
                    cmpd      #54       compare to constant 6
                    lbne      ReturnNodeU not constant return node
                    ldx       12,s      reload child node
                    ldx       12,x      grandchild node
                    ldd       8,x       load constant value
                    leax      8,x       point at value field
                    pshs      x,d       save pointer and value
                    ldx       14,s      target node
                    ldd       8,x       its value
                    lbsr      MulEntry  combine the two values
StoreThroughPtr     std       [,s++]    store result through pointer
                    bra       EmitOperandPair emit operand pair

ClassifyRValue      stx       -2,s      stash rvalue pointer
                    beq       BuildIndirectNode zero build indirect node
                    cmpx      #1        value equals one
                    beq       EmitOperandPair fold to operand pair
                    bra       FoldRegConst else try register-const fold

FoldSNode           ldd       ,s        test left operand flag
                    beq       CheckRightZero no operand case
                    ldx       10,s      operand node
                    ldd       8,x       its value
                    cmpd      #1        value equals one
                    bne       CheckRightZero not one other case
EmitOperandPair     leax      14,s      point at frame node
                    lbra      EmitPairFromX emit paired children

CheckRightZero      ldd       2,s       test right operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       12,s      child node
                    ldd       8,x       its value
                    lbne      ReturnNodeU nonzero return node
                    bra       InitSixNode build constant node

BuildSixFromX       leas      -14,x     restore frame from x
InitSixNode         ldd       #54       tag 6 integer constant
                    std       6,u       set result tag
                    clra                zero high
                    clrb                zero low
ClearNodeFields     std       8,u       clear value field
                    clra                zero high
                    clrb                zero low
                    std       12,u      clear child pointer
                    std       10,u      clear operand field
                    ldd       12,s      load child node
                    pshs      d         push it
                    lbsr      LinkNode  free the child node
                    leas      2,s        drop argument
                    ldd       10,s      load operand
EmitOperandJoin     pshs      d         push it
                    lbsr      LinkNode  free the operand node
DropAndReturn       leas      2,s        drop argument
                    lbra      ReturnNodeU return the node

DispatchByTagMain   cmpx      #88       tag X
                    lbeq      FoldXYNode fold X node
                    cmpx      #89       tag Y
                    lbeq      FoldXYNode fold Y node
                    cmpx      #80       tag P
                    lbeq      FoldPtrNode fold P node
                    cmpx      #81       tag Q
                    lbeq      FoldNegate2 fold negate
                    cmpx      #87       tag W
                    lbeq      FoldWNode fold W node
                    cmpx      #82       tag R
                    lbeq      FoldRNode fold R node
                    cmpx      #83       tag S
                    lbeq      FoldSNode fold S node
                    lbra      ReturnNodeU default return node

LoadTagDispatch2    ldx       6,s       load node tag
                    lbra      DispatchAddrTag dispatch on tag

FoldAddrNode        ldx       12,s      load child node
                    ldd       6,x       its tag
                    cmpd      #54       compare to constant 6
                    bne       FoldConvertJ not constant try next
                    bra       InitStoreNode build store node

BuildStoreFromX     leas      -14,x     restore frame from x
InitStoreNode       ldd       #54       tag 6 constant
                    std       6,u       set result tag
                    clra                zero high
                    clrb                zero low
                    std       18,u      clear extra field
                    ldx       10,s      operand node
                    ldd       8,x       its value
                    pshs      d         push value
                    ldx       14,s      target node
                    ldd       8,x       its value
                    pshs      d         push value
                    ldd       10,s      load operand
                    pshs      d         push it
                    lbsr      FoldBinaryOp compute folded constant
                    leas      6,s        drop three arguments
                    lbra      ClearNodeFields clear fields and return

FoldConvertJ        ldx       12,s      child node
                    ldd       6,x       its tag
                    cmpd      #74       compare to J
                    bne       FoldConvertK not J try K
                    leas      -2,s       make local slot
                    ldx       14,s      target node
                    ldd       8,x       its value
                    std       ,s        save it
                    bne       SelectConvertOp nonzero use existing node
                    ldd       #4        request four bytes
                    pshs      d         push size
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop argument
                    std       ,s        save new node
SelectConvertOp     ldx       8,s       load conversion source tag
                    bra       DispatchConvertTag dispatch conversion

ConvertToC          ldx       ,s        load node
                    pshs      x         push it
                    ldx       2,s       load target
                    lbsr      LongNeg   convert to C form
                    bra       FinishConvert finish conversion

ConvertToD          ldx       ,s        load node
                    pshs      x         push it
                    ldx       2,s       load target
                    lbsr      LongNot   convert to D form
FinishConvert       lbsr      StoreLong finalize conversion
                    bra       StoreConverted store converted value

DispatchConvertTag  cmpx      #67       tag C
                    beq       ConvertToC convert to C
                    cmpx      #68       tag D
                    beq       ConvertToD convert to D
StoreConverted      ldd       ,s        load converted node
                    ldx       14,s      target node
                    std       8,x       store value into target
                    bra       EmitAndReturn emit and return

FoldConvertK        ldx       12,s      child node
                    ldd       6,x       its tag
                    cmpd      #75       compare to K
                    bne       ReturnNodeU not K return node
                    leas      -2,s       make local slot
                    ldx       14,s      target node
                    ldd       8,x       its value
                    std       ,s        save it
                    beq       EmitAndReturn zero just emit
                    ldx       ,s        load node
                    pshs      x         push it
                    ldx       2,s       load target
                    lbsr      NegateNumWork convert the node
                    lbsr      SwapNumWork finalize conversion
EmitAndReturn       pshs      u         push result node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop argument
                    ldu       14,s      reload target node
                    lbra      DropAndReturn drop and return

DispatchAddrTag     cmpx      #64       tag @
                    lbeq      FoldAddrNode fold address node
                    cmpx      #68       tag D
                    lbeq      FoldAddrNode fold address node
                    cmpx      #67       tag C
                    lbeq      FoldAddrNode fold address node
ReturnNodeU         tfr       u,d       return node pointer in d
TeardownReturn      leas      14,s       release local frame
                    puls      pc,u      restore u and return

IsFoldableTag       pshs      u         save u
                    ldd       #$FFC0    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load node argument
                    stu       -2,s      stash node pointer
                    beq       ReturnFalse null node return zero
                    ldx       6,u       load node tag
                    bra       MatchFoldTag test against foldable tags

ReturnTrue          ldd       #1        result true
                    puls      pc,u      restore u and return

MatchFoldTag        cmpx      #118      tag v
                    beq       ReturnTrue foldable return true
                    cmpx      #111      tag o
                    lbeq      ReturnTrue return true
                    cmpx      #54       tag 6
                    lbeq      ReturnTrue return true
                    cmpx      #74       tag J
                    lbeq      ReturnTrue return true
                    cmpx      #75       tag K
                    lbeq      ReturnTrue return true
                    cmpx      #52       tag 4
                    lbeq      ReturnTrue return true
                    cmpx      #55       tag 7
                    lbeq      ReturnTrue return true
ReturnFalse         clra                result false high
                    clrb                result false low
                    puls      pc,u      restore u and return

PrintNodeMsg        pshs      u         save u
                    ldd       #$FFBA    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    leax      MsgDivZero,pcr point at message string
                    pshs      x         push string pointer
                    lbsr      PrintErrLoc print the message
                    leas      2,s        drop argument
                    puls      pc,u      restore u and return

GenSymbolExpr       pshs      u         save u
                    ldd       #$FF9C    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    leas      -20,s      reserve locals
                    ldx       24,s      load argument node
                    ldu       10,x      load its list pointer
                    ldx       24,s      reload argument node
                    ldd       12,x      load a field
                    std       18,s      save it locally
                    ldd       #2        constant two
                    std       10,s      init local
                    std       8,s       init local
                    clra                zero high
                    clrb                zero low
                    std       6,s       clear local
                    ldd       #1        constant one
                    std       12,s      init local counter
                    ldx       24,s      argument node
                    ldd       6,x       load its tag
                    std       14,s      save tag locally
                    tfr       d,x       tag into x
                    lbra      DispatchOp enter processing loop

CheckSymDefined     ldx       24,s      argument node
                    ldd       8,x       load its value field
                    std       16,s      save pointer locally
                    ldx       16,s      reload pointer
                    ldd       8,x       load referenced value
                    cmpd      #_start   compare against module base
                    bne       GenSymbolRef defined generate ref
                    leax      MsgTypedefNotVar,pcr point at message string
                    pshs      x         push string pointer
                    ldd       26,s      load line context
                    pshs      d         push it
                    lbsr      PrintErrSpan report undefined symbol
                    leas      4,s        drop arguments
                    ldd       24,s      argument node
                    pshs      d         push it
                    lbsr      SetErrSym recover from error
                    leas      2,s        drop argument
                    lbra      WriteNodeType continue processing

GenSymbolRef        ldd       [16,s]    load symbol attribute word
                    std       12,s      save it locally
                    ldx       16,s      reload pointer
                    ldd       4,x       load type field
                    std       6,s       save it locally
                    ldd       12,s      reload attributes
                    clra                keep low byte
                    andb      #$0f      mask storage class nibble
                    cmpd      #10       compare to class ten
                    bne       GenStorageClass not that class skip
                    leas      -2,s       make local slot
                    ldx       18,s      load list pointer
                    ldd       2,x       load offset field
                    std       ,s        save it
                    ldd       14,s      load current tag
                    andb      #$F0      mask high nibble
                    addd      [,s]      add referenced offset
                    std       [18,s]    store back through list
                    std       14,s      update local tag
                    ldx       ,s        reload pointer
                    ldd       2,x       load offset again
                    pshs      d         push it
                    ldd       10,s      load count
                    pshs      d         push it
                    ldd       22,s      load context
                    pshs      d         push it
                    lbsr      SetNodeTypeSize emit field access code
                    leas      6,s        drop three arguments
                    leas      2,s        drop local slot
GenStorageClass     ldx       16,s      reload pointer
                    ldd       2,x       load offset field
                    std       10,s      save as operand
                    ldd       12,s      reload attributes
                    clra                keep low byte
                    andb      #$30      mask storage-class bits
                    cmpd      #32       compare to static class
                    beq       GenStaticExtern handle static storage
                    ldd       12,s      reload attributes
                    clra                keep low byte
                    andb      #$30      mask storage-class bits
                    cmpd      #48       compare to extern class
                    lbne      PlainTypeCase neither other storage
GenStaticExtern     ldu       24,s      argument node
                    ldd       10,s      load operand offset
                    std       2,u       store into node
                    ldx       24,s      reload node
                    ldd       16,x      load a field
                    pshs      d         push it
                    ldx       26,s      load outer node
                    ldd       14,x      load its field
                    pshs      d         push it
                    clra                zero high
                    clrb                zero low
                    pshs      d         push zero
                    clra                zero high
                    clrb                zero low
                    pshs      d         push zero
                    pshs      u         push node
                    ldd       #65       tag A address
                    pshs      d         push tag
                    lbsr      NewExprNode build an address node
                    leas      12,s       drop six arguments
                    std       24,s      save the new node
                    ldd       12,s      reload attributes
                    clra                keep low byte
                    andb      #$30      mask storage-class bits
                    cmpd      #32       compare to static class
                    bne       ReloadWorkType not static skip
                    ldd       6,s       load type field
                    pshs      d         push it
                    lbsr      GetNodeType get type size
                    leas      2,s        drop argument
                    std       6,s       save size back
                    ldd       12,s      reload attributes
                    pshs      d         push it
                    lbsr      RemovePtrLevel emit storage directive
                    leas      2,s        drop argument
                    bra       StoreTypeInNode join the type-store path

ReloadWorkType      ldd       12,s      reload the working type
StoreTypeInNode     std       ,u        store type into the node
                    pshs      d         pass the type argument
                    lbsr      AddPtrLevel add one level of indirection to type
                    leas      2,s        drop the argument
                    std       12,s      save the pointer type
                    ldd       #1        mark result as true
                    std       18,u      store the flag in the node
                    bra       SetResultTrue go set result true

PlainTypeCase       ldx       16,s      get the operand node
                    ldd       8,x       load its element type
                    std       4,s       save the element type
                    tfr       d,x       copy for operator test
                    bra       CheckPtrOp test the operator kind

StorePtrElemType    ldd       4,s       reload the element type
                    ldx       24,s      get the result node
                    std       6,x       store element type in node
                    clra                zero the value
                    clrb                zero the value
                    ldx       24,s      result node again
                    std       8,x       clear the node size field
                    bra       SetResultTrue result true

CheckPtrOp          cmpx      #118      is it the address operator
                    beq       StorePtrElemType yes handle pointer element
                    cmpx      #111      is it the deref operator
                    lbeq      StorePtrElemType yes handle pointer element
SetResultTrue       ldd       #1        result true
                    bra       StoreResultDone store the result

SetResultFalse      clra                result false
                    clrb                result false
StoreResultDone     std       8,s       store the result flag
                    lbra      WriteNodeType return

CaseType8           ldd       #8        builtin type code 8
                    std       12,s      set working type
                    ldd       #1        result true
                    std       8,s       store result flag
                    ldd       #4        size four
                    lbra      SetNodeSizeExit finish the node

CaseType6           ldd       #6        builtin type code 6
                    std       12,s      set working type
                    ldd       #1        result true
                    std       8,s       store result flag
                    ldd       #8        size eight
                    lbra      SetNodeSizeExit finish the node

CaseType18          ldd       #18       builtin type code 18
                    std       12,s      set working type
                    ldd       #1        result true
                    lbra      SetNodeSizeExit finish the node

CastOp              pshs      u         pass the node
                    lbsr      ChkUndeclared evaluate the cast operand
                    leas      2,s        drop the argument
                    ldd       [24,s]    load the operand type
                    std       12,s      save the working type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #48       is it a function type
                    beq       CannotCastErr cannot cast a function
                    ldd       12,s      reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #32       is it an array type
                    bne       CastCheckPtr no continue the cast
CannotCastErr       leax      MsgCannotCast,pcr cannot cast message
                    pshs      x         push message pointer
                    ldd       26,s      source line number
                    pshs      d         push line number
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       12,s      reload the type
                    pshs      d         push type argument
                    lbsr      AddPtrLevel add indirection to type
                    leas      2,s        drop the argument
                    std       12,s      save the adjusted type
CastCheckPtr        ldd       12,s      reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #16       is it a pointer type
                    bne       CastConvert no default conversion
                    ldd       #1        conversion flag one
                    pshs      d         push flag
                    pshs      u         push node
                    lbsr      InsertConvNode convert the operand type
                    leas      4,s        drop the arguments
                    bra       CastDone  finish the cast

CastConvert         ldd       12,s      reload the type
                    pshs      d         push type
                    pshs      u         push node
                    lbsr      InsertConvNode convert the operand type
                    leas      4,s        drop the arguments
                    std       12,s      save the converted type
CastDone            ldx       24,s      get the result node
                    ldd       4,x       copy element type field
                    std       6,s       save it
                    ldx       24,s      result node again
                    ldd       2,x       copy node field
                    std       10,s      save it
                    ldd       24,s      node pointer
                    pshs      d         push node
                    lbsr      LinkNode  free the operand node
                    leas      2,s        drop the argument
                    stu       24,s      keep the returned node
                    lbra      WriteNodeType return

AddrOfOp            ldd       #1        addressable-check flag one
                    pshs      d         push flag
                    pshs      u         push node
                    lbsr      ClassifyNode check operand is addressable
                    leas      4,s        drop the arguments
                    ldd       6,u       get the operator code
                    cmpd      #118      is it address-of
                    beq       CantTakeAddrErr yes go error check
                    ldd       6,u       reload operator code
                    cmpd      #111      is it deref
                    bne       AddrOfSetNode neither continue
CantTakeAddrErr     leax      MsgNoAddress,pcr can't take address message
                    pshs      x         push message pointer
                    ldd       26,s      line number
                    pshs      d         push line number
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    pshs      u         push node
                    lbsr      SetErrSym release the node
                    leas      2,s        drop the argument
AddrOfSetNode       ldd       18,u      node flag
                    std       8,s       save it
                    ldd       2,u       node field
                    std       10,s      save it
                    ldd       ,u        node type
                    pshs      d         push type
                    lbsr      AddPtrLevel add indirection to take address
                    leas      2,s        drop the argument
                    std       12,s      save the pointer type
                    ldd       4,u       element type
                    std       6,s       save it
                    lbra      WriteNodeType return

DerefOp             ldd       4,u       element type
                    std       6,s       save it
                    ldd       ,u        node type
                    std       12,s      save working type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #16       is it a pointer type
                    bne       PtrRequiredErr no report error
                    ldd       12,s      reload the type
                    pshs      d         push type
                    lbsr      RemovePtrLevel remove one indirection
                    leas      2,s        drop the argument
                    std       12,s      save the dereferenced type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #32       is result an array type
                    bne       DerefSetNode no finish
                    ldd       12,s      reload the type
                    pshs      d         push type
                    lbsr      RemovePtrLevel deref again for array element
                    std       ,s        replace the argument
                    lbsr      AddPtrLevel re-add indirection
                    leas      2,s        drop the argument
                    std       12,s      save the adjusted type
                    ldd       24,s      node pointer
                    pshs      d         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    stu       24,s      keep the returned node
                    bra       DerefSetNode finish

PtrRequiredErr      leax      MsgPtrRequired,pcr pointer required message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    pshs      u         push node
                    lbsr      SetErrSym release the node
                    leas      2,s        drop the argument
                    ldd       #17       default int type
                    std       ,u        store into node
                    ldd       #1        flag one
                    std       12,s      save it
                    clra                zero
                    clrb                zero
                    std       6,s       clear element type
DerefSetNode        ldd       18,u      node flag
                    std       8,s       save it
                    ldd       2,u       node field
SetNodeSizeExit     std       10,s      store node size field
                    lbra      WriteNodeType return

BinaryOpOperandA    leax      ,s        address of local
                    pshs      x         push it
                    leax      14,s      address of another local
                    pshs      x         push it
                    ldd       22,s      operand argument
                    pshs      d         push it
                    lbsr      ProcStructRef split the operands
                    leas      6,s        drop the arguments
                    std       10,s      save result
                    ldx       18,s      operand node
                    ldd       4,x       element type
                    std       6,s       save it
                    ldd       #1        addressable-check flag one
                    pshs      d         push flag
                    pshs      u         push node
                    lbsr      ClassifyNode check operand is addressable
                    leas      4,s        drop the arguments
                    ldx       18,s      operand node
                    ldd       8,x       its size field
                    bne       OperandHasType nonzero handle type
                    ldd       ,s        local flag
                    bne       OperandHasType nonzero handle type
                    ldd       18,s      node pointer
                    pshs      d         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    ldd       24,s      result node
                    pshs      d         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    stu       24,s      keep the returned node
                    ldx       24,s      result node
                    ldd       18,x      its flag
                    std       8,s       save it
                    lbra      OperandExit return

OperandHasType      ldd       18,u      node flag
                    std       8,s       save it
                    ldd       6,u       operator code
                    cmpd      #66       is it a call node
                    bne       MakeConvertNode no build convert node
                    ldd       10,u      node pointer field
                    std       16,s      save it
                    pshs      u         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    ldu       16,s      restore saved node
                    tfr       u,d       copy for storing
                    ldx       24,s      result node
                    std       10,x      store field
                    bra       OperandDone finish operand

MakeConvertNode     ldd       ,u        node type
                    std       4,s       save it
                    ldd       16,u      node field
                    pshs      d         push it
                    ldd       14,u      node field
                    pshs      d         push it
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    pshs      u         push operand node
                    ldd       #65       convert node opcode
                    pshs      d         push opcode
                    lbsr      NewExprNode allocate a conversion node
                    leas      12,s       drop the arguments
                    ldx       24,s      result node
                    std       10,x      store the new node
                    tfr       d,u       new node pointer
                    ldd       4,s       saved type
                    pshs      d         push type
                    lbsr      AddPtrLevel add indirection to type
                    leas      2,s        drop the argument
                    std       ,u        store type in new node
OperandDone         ldd       8,s       node flag
                    std       18,u      store into node
                    leax      20,s      restore frame pointer
                    lbra      RestoreFrame build the node

OperandExit         lbra      WriteNodeType return

BinaryOpOperandB    leax      ,s        address of local
                    pshs      x         push it
                    leax      14,s      address of another local
                    pshs      x         push it
                    ldd       22,s      operand argument
                    pshs      d         push it
                    lbsr      ProcStructRef split the operands
                    leas      6,s        drop the arguments
                    std       10,s      save result
                    ldx       18,s      operand node
                    ldd       4,x       element type
                    std       6,s       save it
                    ldd       ,u        node type
                    std       4,s       save it
                    cmpd      #1        is it plain int
                    beq       OperandBType yes accept
                    ldd       4,s       reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #16       is it a pointer type
                    bne       NotPtrType no set false
                    ldd       #1        true
                    bra       CheckPtrOrInt go test

NotPtrType          clra                false
                    clrb                false
CheckPtrOrInt       bne       OperandBType pointer or integer accepted
                    leax      MsgPtrOrIntReq,pcr pointer or integer required message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       #54       default type
                    std       6,u       store into node
                    clra                zero
                    clrb                zero
                    std       8,u       clear node field
                    clra                zero
                    clrb                zero
                    std       18,u      clear node flag
OperandBType        ldd       18,u      node flag
                    std       8,s       save it
                    bra       BuildBinaryNode build binary node

RestoreFrame        leas      -20,x     restore the stack frame
BuildBinaryNode     ldd       #80       binary node opcode
                    ldx       24,s      result node
                    std       6,x       store operator code
                    ldd       24,s      node pointer
                    pshs      d         push node
                    lbsr      SimplifyExpr link operand into node
                    leas      2,s        drop the argument
                    std       24,s      keep the returned node
                    ldd       ,s        local flag
                    bne       BinaryNodeExit skip the node build
                    ldd       12,s      working type
                    pshs      d         push type
                    lbsr      AddPtrLevel add indirection to type
                    leas      2,s        drop the argument
                    std       [24,s]    store type in node
                    ldd       8,s       node flag
                    ldx       24,s      result node
                    std       18,x      store into node
                    ldd       10,s      node field
                    ldx       24,s      result node
                    std       2,x       store into node
                    ldx       24,s      result node
                    ldd       16,x      node field
                    pshs      d         push it
                    ldx       26,s      caller frame
                    ldd       14,x      node field
                    pshs      d         push it
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    ldd       32,s      operand node
                    pshs      d         push it
                    ldd       #66       call node opcode
                    pshs      d         push opcode
                    lbsr      NewExprNode allocate the node
                    leas      12,s       drop the arguments
                    std       24,s      keep the new node
BinaryNodeExit      lbra      WriteNodeType return

CallOp              ldd       ,u        node type
                    std       12,s      save it
                    ldd       6,u       operator code
                    cmpd      #65       is it a convert node
                    bne       CheckFuncType no check function type
                    ldd       12,s      reload the type
                    pshs      d         push type
                    lbsr      RemovePtrLevel remove one indirection
                    leas      2,s        drop the argument
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #48       is it a function type
                    bne       CheckFuncType no continue
                    ldd       10,u      node field
                    ldx       24,s      result node
                    std       10,x      store into node
                    std       16,s      save node field
                    pshs      u         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    ldd       [16,s]    load node type
DerefTypeCont       pshs      d         push type
                    lbsr      RemovePtrLevel remove one indirection
                    leas      2,s        drop the argument
                    lbra      CallSetNode finish the call node

CheckFuncType       ldd       12,s      reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #48       is it a function type
                    bne       ImplicitFuncDecl no maybe implicit
                    ldd       12,s      plain type
                    bra       DerefTypeCont deref the function type

ImplicitFuncDecl    ldd       12,s      reload the type
                    bne       NotFunctionErr nonzero not a function
                    ldd       8,u       node field
                    std       16,s      save it
                    ldd       #49       identifier node opcode
                    std       [16,s]    store node type
                    ldd       #2        field value
                    ldx       16,s      saved node
                    std       2,x       store into node
                    clra                zero
                    clrb                zero
                    ldx       16,s      saved node
                    std       4,x       clear field
                    ldd       #14       field value
                    ldx       16,s      saved node
                    std       8,x       store into node
                    clra                zero
                    clrb                zero
                    ldx       16,s      saved node
                    std       12,x      clear field
                    ldd       #6        count six
                    pshs      d         push count
                    pshs      u         push node
                    ldd       20,s      operand argument
                    pshs      d         push it
                    lbsr      CopyBlock copy the node bytes
                    leas      6,s        drop the arguments
                    ldd       #1        result true
                    bra       CallSetNode finish the call node

NotFunctionErr      leax      MsgNotFunction,pcr not a function message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       12,s      reload the type
                    clra                clear high byte
                    andb      #$0f      isolate base type bits
CallSetNode         std       12,s      save the working type
                    ldd       4,u       element type
                    std       6,s       save it
                    ldd       2,u       node field
                    std       10,s      save it
ProcessCallArgs     pshs      u         pass the node
                    lbsr      ChkUndeclared evaluate the operand
                    leas      2,s        drop the argument
                    pshs      u         push node pointer argument
                    lbsr      ChkNotStruct call operand helper
                    leas      2,s        drop argument
                    ldx       ,u        load result operand pointer
                    bra       CheckOperandKind go check operand kind

SetType1Emit        ldd       #1        select type code one
                    bra       EmitTypedNode emit typed node

SetType6Emit        ldd       #6        select type code six
EmitTypedNode       pshs      d         push type code
                    pshs      u         push node pointer
                    lbsr      InsertConvNode emit conversion
                    leas      4,s        drop arguments
                    bra       OpDoneJoin join common tail

CheckOperandKind    cmpx      #2        is operand kind two
                    beq       SetType1Emit yes handle as type one
                    cmpx      #5        is operand kind five
                    beq       SetType6Emit yes handle as type six
OpDoneJoin          lbra      WriteNodeType back to dispatch loop

CopyNodeFields      ldx       18,s      load left operand pointer
                    ldd       2,x       fetch its type field
                    std       10,s      save into frame
                    ldd       [18,s]    dereference operand type
                    std       12,s      save current type
                    ldx       18,s      reload operand pointer
                    ldd       4,x       fetch its size field
                    std       6,s       save size
                    lbra      WriteNodeType back to dispatch loop

EvalUnaryPtr        ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    beq       ResultOneFinish yes skip evaluation
                    pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
ResultOneFinish     ldd       #1        result type is one
                    lbra      StoreOpType finish node

EvalUnaryFinish     pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    lbra      StoreOpType finish node

EvalCheckType6      pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    std       12,s      save resulting type
                    cmpd      #6        is it type six
                    lbne      JoinExit  no back to dispatch
                    pshs      u         push node pointer
                    lbsr      ErrMustBeIntegral dereference operand
                    leas      2,s        drop argument
                    pshs      u         push node pointer
                    lbra      EmitNode25E6 emit and continue

ProcessArrayIndex   clra                zero initial value
                    clrb                zero low byte
                    pshs      d         push zero argument
                    pshs      u         push node pointer
                    lbsr      ClassifyNode evaluate both operands
                    leas      4,s        drop arguments
                    ldd       2,u       fetch node base type
                    std       10,s      save into frame
                    ldd       ,u        load node type word
                    std       12,s      save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    beq       DefaultSizeOne plain scalar default size one
                    ldd       4,u       load element size
                    pshs      d         push size
                    ldd       2,u       load base type
                    pshs      d         push type
                    ldd       16,s      load other operand type
                    pshs      d         push it
                    lbsr      RemovePtrLevel compute result type
                    std       ,s        store result on stack
                    lbsr      ComputeElemSize scale operands by size
                    leas      6,s        drop arguments
                    bra       StoreNodeSize store computed size

DefaultSizeOne      ldd       #1        default size one
StoreNodeSize       ldx       24,s      load result node pointer
                    std       8,x       store size into node
                    ldd       18,u      load node link field
                    std       8,s       save it
                    ldd       6,u       load node operator code
                    cmpd      #66       is it operator hex42
                    lbne      TailJoinD no back to dispatch
                    ldd       8,s       reload saved value
                    addd      #1        increment it
                    lbra      StoreOffsetJoin store size and continue

EvalDerefPtr        ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    beq       CheckDerefClass yes skip evaluation
                    pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
CheckDerefClass     ldd       [18,s]    dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    lbeq      JoinExit  yes back to dispatch
                    ldd       18,s      load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    bra       PopAndJoin pop and continue

EvalRhsCheck6       ldd       18,s      load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
                    leas      4,s        drop arguments
                    std       12,s      save resulting type
                    cmpd      #6        is it type six
                    bne       TailJoinA no back to dispatch
                    leax      20,s      point at frame block
                    bra       RestoreThenErr restore and report error

TailJoinA           lbra      WriteNodeType back to dispatch loop

EvalBothCheck6      pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    std       12,s      save resulting type
                    cmpd      #6        is it type six
                    beq       ReportTypeErr yes report error
                    ldd       18,s      load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    cmpd      #6        is it type six
                    bne       EmitAssignOne no emit assignment
                    bra       ReportTypeErr report error

RestoreThenErr      leas      -20,x     restore stack frame
ReportTypeErr       leax      MsgBothIntegral,pcr point at error message
                    pshs      x         push message pointer
                    ldd       26,s      load context value
                    pshs      d         push it
                    lbsr      PrintErrSpan report compile error
                    leas      4,s        drop arguments
                    ldd       24,s      reload node pointer
                    pshs      d         push it
EmitNode25E6        lbsr      SetErrSym emit node
PopAndJoin          leas      2,s        drop argument
JoinExit            lbra      WriteNodeType back to dispatch loop

EmitAssignOne       ldd       #1        result type one
                    pshs      d         push type
                    ldd       20,s      load operand pointer
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    lbra      PopFourJoin pop and continue

CheckPtrArith       ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       EvalRhsCheck7 not pointer evaluate
                    ldd       [18,s]    dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    beq       AdjustPtrSize4 both pointers adjust size
EvalRhsCheck7       ldd       18,s      load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
                    leas      4,s        drop arguments
                    cmpd      #7        is result type seven
                    bne       TailJoinB no back to dispatch
AdjustPtrSize4      ldd       14,s      load size field
                    addd      #4        bump by four
                    ldx       24,s      load result node pointer
                    std       6,x       store adjusted size
TailJoinB           lbra      WriteNodeType back to dispatch loop

ComparePtrEqual     ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       EvalRhsDefault not pointer evaluate
                    ldd       [18,s]    dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       ClearPtrFlag mismatch clear flag
                    ldd       #1        both pointers set flag
                    bra       TestPtrFlag test the flag

ClearPtrFlag        clra                clear flag value
                    clrb                zero low byte
TestPtrFlag         bne       TailJoinC flag set back to dispatch
                    ldd       18,s      load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    ldd       #1        result type one
                    pshs      d         push type
                    ldd       20,s      load operand pointer
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    bra       PopFourJoin pop and continue

EvalRhsDefault      ldd       18,s      load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
PopFourJoin         leas      4,s        drop arguments
TailJoinC           lbra      WriteNodeType back to dispatch loop

SwapPtrOperands     ldd       [18,s]    dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       LoadNodeType not pointer keep order
                    leas      -2,s       make scratch slot
                    stu       ,s        save node pointer
                    ldu       20,s      load other operand
                    ldd       ,s        reload saved node
                    std       20,s      swap operands
                    leas      2,s        drop scratch slot
                    ldx       24,s      load result node pointer
                    stu       10,x      store swapped operand
LoadNodeType        ldd       2,u       fetch node base type
                    std       10,s      save into frame
                    ldd       ,u        load node type word
                    std       12,s      save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       EvalRhsAddOffset not pointer evaluate
                    ldd       4,u       load element size
                    std       6,s       save size
                    leax      20,s      point at frame block
                    lbra      FixFrameEmit fix frame and emit

EvalRhsAddOffset    ldd       18,s      load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
                    leas      4,s        drop arguments
                    std       12,s      save resulting type
                    ldd       18,u      load node link field
                    ldx       18,s      load operand pointer
                    addd      18,x      add operand offsets
StoreOffsetJoin     std       8,s       save combined offset
TailJoinD           lbra      WriteNodeType back to dispatch loop

PtrCompareOp        ldd       18,u      load node link field
                    ldx       18,s      load operand pointer
                    addd      18,x      add operand offsets
                    std       8,s       save combined offset
                    ldd       ,u        load node type word
                    std       12,s      save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    lbne      ProcBinType not pointer finish node
                    ldd       2,u       fetch base type
                    std       10,s      save into frame
                    ldd       4,u       load element size
                    std       6,s       save size
                    ldd       [18,s]    dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    lbne      EmitPtrScale not pointer emit scale
                    ldd       8,s       load combined offset
                    ldx       24,s      load result node pointer
                    std       18,x      store into node
                    ldd       12,s      load node type
                    cmpd      [18,s]    compare with operand type
                    bne       TypeMismatchErr differ report error
                    ldd       10,s      load base type
                    ldx       18,s      load operand pointer
                    cmpd      2,x       compare base types
                    beq       ConstFoldCompare match constant fold
TypeMismatchErr     leax      MsgPtrMismatch,pcr point at error message
                    pshs      x         push message pointer
                    ldd       26,s      load context value
                    pshs      d         push it
                    lbsr      PrintErrSpan report compile error
                    leas      4,s        drop arguments
                    lbra      SetResultTwo set result and finish

ConstFoldCompare    ldd       12,s      load node type
                    pshs      d         push type
                    lbsr      RemovePtrLevel compute result type
                    leas      2,s        drop argument
                    std       12,s      save adjusted type
                    ldd       6,s       load size
                    pshs      d         push size
                    ldd       12,s      load type
                    pshs      d         push type
                    ldd       16,s      load operand
                    pshs      d         push it
                    lbsr      ComputeElemSize scale operands
                    leas      6,s        drop arguments
                    std       10,s      save scaled result
                    cmpd      #1        is result one
                    lbeq      SetResultTwo yes just finish
                    ldd       #2        result type two
                    std       8,s       save it
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       14,s      load operand value
                    pshs      d         push it
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       #54       opcode hex36
                    pshs      d         push opcode
                    lbsr      NewExprNode emit intermediate instruction
                    leas      12,s       drop arguments
                    std       16,s      save emitted node
                    ldx       24,s      load result node pointer
                    ldd       16,x      load its field
                    pshs      d         push it
                    ldx       26,s      load context pointer
                    ldd       14,x      load field
                    pshs      d         push it
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       22,s      load value
                    pshs      d         push it
                    ldd       32,s      load value
                    pshs      d         push it
                    ldd       #83       opcode hex53
                    pshs      d         push opcode
                    lbsr      NewExprNode emit intermediate instruction
                    leas      12,s       drop arguments
                    std       24,s      save emitted node
SetResultTwo        ldd       #2        result type two
                    std       10,s      save it
                    clra                clear high byte
                    clrb                zero low byte
                    std       6,s       clear size
                    ldd       #1        set result flag one
                    lbra      StoreOpType finish node

FixFrameEmit        leas      -20,x     restore stack frame
EmitPtrScale        ldd       18,s      load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    ldd       [18,s]    dereference operand type
                    pshs      d         push it
                    lbsr      IsIntegral test type compatibility
                    std       ,s++      save result and drop
                    bne       EmitScaledOp nonzero skip conversion
                    ldd       18,s      load operand pointer
                    pshs      d         push it
                    lbsr      ErrMustBeIntegral dereference operand
                    leas      2,s        drop argument
                    ldd       18,s      load operand pointer
                    pshs      d         push it
                    lbsr      SetErrSym emit node
                    leas      2,s        drop argument
EmitScaledOp        ldd       #1        result type one
                    pshs      d         push type
                    ldd       20,s      load operand pointer
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    leas      4,s        drop arguments
                    ldd       18,s      load operand pointer
                    pshs      d         push it
                    ldd       8,s       load offset
                    pshs      d         push it
                    ldd       16,s      load operand
                    pshs      d         push it
                    ldd       16,s      load operand
                    pshs      d         push it
                    lbsr      ScalePointer emit scaled operation
                    leas      8,s        drop arguments
                    ldx       24,s      load result node pointer
                    std       12,x      store into node
                    ldd       18,u      load node link field
                    ldx       18,s      load operand pointer
                    addd      18,x      add operand offsets
                    std       8,s       save combined offset
                    lbra      WriteNodeType back to dispatch loop

ProcessAssignOp     clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    pshs      u         push node pointer
                    lbsr      ClassifyNode evaluate both operands
                    leas      4,s        drop arguments
                    ldd       18,s      load left operand
                    pshs      d         push it
                    lbsr      ChkUndeclared process operand
                    leas      2,s        drop argument
                    ldd       18,s      load left operand
                    pshs      d         push it
                    lbsr      ChkNotStruct load operand value
                    leas      2,s        drop argument
                    std       2,s       save right type
                    ldd       ,u        load node type word
                    std       12,s      save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       CheckRightPtr not pointer check right
                    ldd       2,s       load right type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    beq       CheckRightPtr both pointers continue
                    ldd       2,s       load right type
                    pshs      d         push it
                    lbsr      IsIntegral test type compatibility
                    std       ,s++      save result and drop
                    lbeq      ConvOpErr compatible handle specially
CheckRightPtr       ldd       2,s       load right type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    bne       EmitAssignStore not pointer emit store
                    ldd       12,s      load left type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it pointer class
                    beq       EmitAssignStore both pointers emit store
                    ldd       12,s      load left type
                    pshs      d         push it
                    lbsr      IsIntegral test type compatibility
                    std       ,s++      save result and drop
                    lbeq      ConvOpErr compatible handle specially
EmitAssignStore     ldd       12,s      load left type
                    pshs      d         push it
                    ldd       20,s      load operand
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    leas      4,s        pop the two arguments
                    leax      20,s      point past the local frame
                    lbra      RestoreFrameCopy continue into node-type copy

ProcConvOp          leas      -20,x     allocate local frame for conversion op
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    pshs      u         push node pointer
                    lbsr      ClassifyNode call node helper
                    leas      4,s        drop the arguments
                    ldd       18,s      load node pointer
                    pshs      d         pass as argument
                    lbsr      CoerceOperand coerce the operand type
                    leas      2,s        drop argument
                    ldd       18,s      reload node pointer
                    pshs      d         pass as argument
                    lbsr      ChkNotStruct call node helper
                    leas      2,s        drop argument
                    std       2,s       save returned value
                    ldd       ,u        load node operator/type
                    std       12,s      save as result type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #16       test for pointer class
                    bne       DispatchConvOp not pointer, dispatch other op
                    ldx       14,s      load operator code
                    bra       CheckAddrOps check specific pointer ops

MakeIntConv         ldd       #1        integer type
                    pshs      d         push target type
                    ldd       20,s      load node pointer
                    pshs      d         push as argument
                    lbsr      InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    leax      20,s      point past frame
                    bra       ConvFixFrame continue setting result type

ConvOpErr           leax      20,s      restore frame pointer
                    lbra      ReportOpErr report operator error

CheckAddrOps        cmpx      #161      indirection operator?
                    beq       MakeIntConv yes, convert to int
                    cmpx      #160      address-of operator?
                    lbeq      MakeIntConv yes, convert to int
                    bra       ConvOpErr otherwise operator error

DispatchConvOp      ldx       14,s      load operator code
                    lbra      CheckIncrOps dispatch by operator

ConvByType          ldd       12,s      load result type
                    cmpd      #5        test for float type
                    bne       ConvKeepType no, keep existing type
                    ldd       #6        promote to double type
                    bra       EmitConvNode emit the conversion

ConvKeepType        ldd       12,s      keep existing type
EmitConvNode        pshs      d         push target type
                    ldd       20,s      load node pointer
                    pshs      d         push as argument
                    lbsr      InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    bra       SetConvResult set result type

ConvFixFrame        leas      -20,x     restore local frame
SetConvResult       ldd       14,s      load operator code
                    addd      #$FFB0    offset into type table
                    ldx       24,s      load result node pointer
                    std       6,x       store node subtype
                    ldd       24,s      load result node pointer
                    pshs      d         push as argument
                    lbsr      GenSymbolExpr call node helper
                    leas      2,s        drop argument
                    std       24,s      save updated node pointer
                    ldd       12,s      load result type
                    cmpd      #2        test for long type
                    bne       CheckSubtypeSame no, skip pointer handling
                    ldd       10,u      load node pointer field
                    ldx       24,s      load result node
                    std       10,x      copy pointer field across
                    pshs      u         push node pointer
                    lbsr      LinkNode  call node helper
                    leas      2,s        drop argument
                    ldx       24,s      load result node
                    ldu       10,x      reload node pointer field
                    ldd       #1        integer type
                    std       12,s      set result type
CheckSubtypeSame    ldd       14,s      load operator code
                    addd      #$FFB0    offset into type table
                    ldx       24,s      load result node
                    cmpd      6,x       compare with stored subtype
                    bne       CopyNodeType differ, copy node type
                    ldd       14,s      load operator code
                    ldx       24,s      load result node
                    std       6,x       store operator as subtype
                    bra       CopyNodeType copy node type

CheckIncrOps        cmpx      #166      post-increment operator?
                    beq       SetConvResult yes, set result type
                    cmpx      #165      pre-increment operator?
                    lbeq      SetConvResult yes, set result type
                    lbra      ConvByType otherwise convert by type

RestoreFrameCopy    leas      -20,x     restore local frame
CopyNodeType        ldd       2,u       load node type field
                    std       10,s      save result subfield
                    ldd       18,u      load node size field
                    ldx       18,s      load other operand
                    addd      18,x      add operand sizes
                    std       8,s       save combined size
                    ldd       4,u       load node field
                    lbra      SetResultField set result field

ReportOpErr         leas      -20,x     restore local frame
                    leax      MsgTypeMismatch,pcr point to error message
                    pshs      x         push message pointer
                    ldd       26,s      load source location
                    pshs      d         push as argument
                    lbsr      PrintErrSpan report the error
                    lbra      OpErrDone finish with error

ProcAssignOp        ldd       ,u        load node operator
                    std       12,s      save as result type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #16       test for pointer class
                    bne       DerefLvalType not pointer, other handling
                    ldd       2,u       load node type field
                    std       10,s      save result subfield
                    ldd       18,u      load node size field
                    std       8,s       save result size
                    ldd       2,u       reload node type field
                    std       6,s       save result field
                    ldd       [18,s]    load type through operand
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #16       test for pointer class
                    bne       CheckLvalCase not pointer, check lvalue
                    ldd       12,s      load result type
                    cmpd      [18,s]    compare with operand type
                    bne       TypeMismatchErr2 differ, type mismatch
                    ldd       2,u       load node type field
                    ldx       18,s      load operand pointer
                    cmpd      2,x       compare target types
                    beq       AssignOk  match, assignment ok
TypeMismatchErr2    leax      MsgPtrMismatch2,pcr point to mismatch message
                    pshs      x         push message pointer
                    ldd       26,s      load source location
                    pshs      d         push as argument
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    lbra      WriteNodeType write node type

AssignOk            clra                clear high byte
                    clrb                clear low byte
                    std       6,s       clear result field
                    lbra      WriteNodeType write node type

CheckLvalCase       ldd       18,s      load operand pointer
                    pshs      d         push as argument
DoLvalCheck         lbsr      ForceStorClass force storage-class node
                    leas      2,s        drop argument
                    lbra      WriteNodeType write node type

DerefLvalType       ldd       [18,s]    load type through operand
                    std       12,s      save as result type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #16       test for pointer class
                    bne       ProcBinType not pointer, binary op
                    ldx       18,s      load operand pointer
                    ldd       2,x       load type field
                    std       10,s      save result subfield
                    ldx       18,s      reload operand pointer
                    ldd       18,x      load size field
                    std       8,s       save result size
                    ldx       18,s      reload operand pointer
                    ldd       4,x       load node field
                    std       6,s       save result field
                    pshs      u         push node pointer
                    bra       DoLvalCheck force storage-class node

ProcBinType         ldd       18,s      load operand pointer
                    pshs      d         push as argument
                    pshs      u         push node pointer
                    lbsr      UsualArithConv call binary-type helper
                    leas      4,s        drop the arguments
StoreOpType         std       12,s      save as result type
                    lbra      WriteNodeType write node type

CopyLvalType        ldd       [18,s]    load type through operand
                    std       12,s      save as result type
                    ldx       18,s      load operand pointer
                    ldd       2,x       load type field
                    std       10,s      save result subfield
                    ldx       18,s      reload operand pointer
                    ldd       4,x       load node field
SetResultField      std       6,s       save result field
                    lbra      WriteNodeType write node type

ProcDefaultOp       ldd       14,s      load operator code
                    cmpd      #160      test conversion-op range
                    blt       BadOpErr  below range, bad operator
                    leax      20,s      point past frame
                    lbra      ProcConvOp process conversion operator

BadOpErr            leax      MsgTypeCheck,pcr point to error message
                    pshs      x         push message pointer
                    ldd       26,s      load source location
                    pshs      d         push as argument
                    lbsr      ReportFmtErr report the error
OpErrDone           leas      4,s        drop the arguments
                    lbra      WriteNodeType write node type

DispatchOp          cmpx      #52       operator code $34?
                    lbeq      CheckSymDefined dispatch to its handler
                    cmpx      #54       operator code $36?
                    lbeq      SetResultFalse dispatch to its handler
                    cmpx      #74       operator code $4A?
                    lbeq      CaseType8 dispatch to its handler
                    cmpx      #75       operator code $4B?
                    lbeq      CaseType6 dispatch to its handler
                    cmpx      #55       operator code $37?
                    lbeq      CaseType18 dispatch to its handler
                    cmpx      #32       operator code $20?
                    lbeq      CastOp    dispatch to its handler
                    cmpx      #65       operator code $41?
                    lbeq      AddrOfOp  dispatch to its handler
                    cmpx      #66       operator code $42?
                    lbeq      DerefOp   dispatch to its handler
                    cmpx      #69       operator code $45?
                    lbeq      BinaryOpOperandA dispatch to its handler
                    cmpx      #70       operator code $46?
                    lbeq      BinaryOpOperandB dispatch to its handler
                    cmpx      #101      operator code $65?
                    lbeq      CallOp    dispatch to its handler
                    cmpx      #11       operator code $0B?
                    lbeq      ProcessCallArgs dispatch to its handler
                    cmpx      #48       operator code $30?
                    lbeq      CopyNodeFields dispatch to its handler
                    cmpx      #64       operator code $40?
                    lbeq      EvalUnaryPtr dispatch to its handler
                    cmpx      #67       operator code $43?
                    lbeq      EvalUnaryFinish dispatch to its handler
                    cmpx      #68       operator code $44?
                    lbeq      EvalCheckType6 dispatch to its handler
                    cmpx      #60       relational operator $3C?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #62       relational operator $3E?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #61       relational operator $3D?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #63       relational operator $3F?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #71       operator code $47?
                    lbeq      EvalDerefPtr dispatch to its handler
                    cmpx      #72       operator code $48?
                    lbeq      EvalDerefPtr dispatch to its handler
                    cmpx      #83       operator code $53?
                    lbeq      ProcBinType dispatch to binary handler
                    cmpx      #82       operator code $52?
                    lbeq      ProcBinType dispatch to binary handler
                    cmpx      #87       operator code $57?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #88       operator code $58?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #89       operator code $59?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #84       operator code $54?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #86       operator code $56?
                    lbeq      EvalBothCheck6 dispatch to its handler
                    cmpx      #85       operator code $55?
                    lbeq      EvalBothCheck6 dispatch to its handler
                    cmpx      #93       operator code $5D?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #95       operator code $5F?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #92       operator code $5C?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #94       operator code $5E?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #90       operator code $5A?
                    lbeq      ComparePtrEqual dispatch to its handler
                    cmpx      #91       operator code $5B?
                    lbeq      ComparePtrEqual dispatch to its handler
                    cmpx      #80       operator code $50?
                    lbeq      SwapPtrOperands dispatch to its handler
                    cmpx      #81       operator code $51?
                    lbeq      PtrCompareOp dispatch to its handler
                    cmpx      #120      operator code $78?
                    lbeq      ProcessAssignOp dispatch to its handler
                    cmpx      #47       operator code $2F?
                    lbeq      ProcAssignOp dispatch to assignment handler
                    cmpx      #100      operator code $64?
                    lbeq      CopyLvalType dispatch to its handler
                    lbra      ProcDefaultOp otherwise default operator handling

WriteNodeType       ldd       12,s      load computed type
                    std       [24,s]    store into result node
                    ldd       10,s      load result subfield
                    ldx       24,s      load result node
                    std       2,x       store node subfield
                    ldd       8,s       load result size
                    ldx       24,s      load result node
                    std       18,x      store node size
                    ldd       6,s       load result field
                    ldx       24,s      load result node
                    std       4,x       store node field
                    ldd       24,s      return result node pointer
                    leas      20,s       release the local frame
                    puls      pc,u      restore u and return

ForceStorClass      pshs      u         save caller u
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load node argument
                    ldd       6,u       load node subtype
                    cmpd      #54       test for storage-class op
                    bne       StorClassErr no, report and force
                    ldd       8,u       load node field
                    beq       StorClassDone zero, already valid
StorClassErr        leax      MsgShouldBeNull,pcr point to error message
                    pshs      x         push message pointer
                    pshs      u         push node pointer
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       #54       storage-class op code
                    std       6,u       force node subtype
                    clra                clear high byte
                    clrb                clear low byte
                    std       8,u       clear node field
StorClassDone       puls      pc,u      restore u and return

CoerceOperand       pshs      u         save caller u
                    ldd       #$FFB6    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load node argument
                    leas      -2,s       allocate local
                    pshs      u         push node pointer
                    lbsr      ChkUndeclared call node helper
                    leas      2,s        drop argument
                    ldd       ,u        load node type
                    std       ,s        save locally
                    tfr       d,x       into x for dispatch
                    bra       CoerceDispatch dispatch by type

CoerceToInt         ldd       #1        integer type
                    bra       StoreCoerceType store coercion type

CoerceToDouble      ldd       #6        double type
StoreCoerceType     std       ,s        save target type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    bsr       InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    bra       CoerceDone store result and return

CoerceErr           leax      MsgTypeError,pcr point to error message
                    pshs      x         push message pointer
                    pshs      u         push node pointer
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       #1        integer type
                    std       ,s        save target type
                    bra       CoerceDone store result and return

CoerceDispatch      cmpx      #2        long type?
                    beq       CoerceToInt coerce to int
                    cmpx      #5        float type?
                    beq       CoerceToDouble coerce to double
                    cmpx      #6        double type?
                    beq       CoerceDone already usable
                    cmpx      #8        pointer type?
                    beq       CoerceDone already usable
                    cmpx      #1        int type?
                    beq       CoerceDone already usable
                    cmpx      #7        type $07?
                    beq       CoerceDone already usable
                    bra       CoerceErr otherwise coercion error

CoerceDone          ldd       ,s        load target type
                    std       ,u        store into node
                    leas      2,s        release local
                    puls      pc,u      restore u and return

InsertConvNode      pshs      u         save caller u
                    ldd       #$FFAC    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load node argument
                    leas      -4,s       allocate locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear local
                    ldx       ,u        load node type
                    lbra      OpKindSwitch dispatch by node type

ConvLoadType        ldx       10,s      load operand type
                    bra       ConvDispatch dispatch conversion

ConvOp85            ldd       #133      conversion op $85
                    bra       StoreConvOp store conversion op

ConvViaInt          ldd       #1        integer type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    bsr       InsertConvNode recurse to insert conversion
                    leas      4,s        drop the arguments
                    ldd       #131      conversion op $83
StoreConvOp         std       ,s        save conversion op
                    lbra      FinalizeOrError build conversion node

ConvDouble          ldd       #1        integer type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    lbsr      InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    ldd       10,s      load operand type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    lbsr      InsertConvNode insert second conversion
                    leas      4,s        drop the arguments
                    lbra      FinalizeOrError build conversion node

ConvDispatch        cmpx      #1        int type?
                    beq       ConvOp85  use conversion op $85
                    cmpx      #7        type $07?
                    lbeq      ConvOp85  use conversion op $85
                    cmpx      #8        pointer type?
                    beq       ConvViaInt convert via int
                    cmpx      #6        double type?
                    beq       ConvDouble double conversion
                    cmpx      #5        float type?
                    lbeq      ConvDouble double conversion
                    lbra      FinalizeOrError otherwise build conversion node

CheckPtrClass2      ldd       ,u        load node type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #16       test for pointer class
                    lbne      FinalizeOrError not pointer, build node
ConvPtrCase         ldx       10,s      load operand type
                    lbra      Op1TypeSwitch dispatch pointer conversion

ConvConstNode       ldd       6,u       load node subtype
                    cmpd      #54       storage-class op?
                    bne       ErrMsg83  no, other handling
                    ldd       #4        allocation size four
                    pshs      d         push as argument
                    lbsr      AllocMem  allocate memory
                    leas      2,s        drop argument
                    std       2,s       save the allocation
                    ldd       8,u       load node field
                    ldx       2,s       load result node pointer
                    std       2,x       store computed value into node
                    bge       SignZero  non-negative needs zero sign
                    ldd       #$FFFF    negative sign extension word
                    bra       StoreSign go store the sign

SignZero            clra                positive sign high byte
                    clrb                positive sign low byte
StoreSign           std       [2,s]     write sign word through pointer
                    ldd       2,s       reload node pointer
                    std       8,u       set node operand field
                    bra       MakeAddrNode build address node

AddrNodeMerge       leas      -4,x      normalize stack after merge
MakeAddrNode        ldd       #74       address-of node tag
                    std       6,u       set node opcode
                    ldd       #4        pointer size four bytes
SetAddrSize         std       2,u       set node size
                    lbra      FinalizeOrError finalize node

ErrMsg83            ldd       #131      type-error message 0x83
                    bra       SetMsgOp1 store message and finalize

Op1CharInt          ldd       #1        result type int
                    std       10,s      save operand type
                    lbra      FinalizeOrError finalize node

Op1CoerceErr        ldd       #6        coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    ldd       #141      type-error message 0x8D
                    bra       SetMsgOp1 store message and finalize

Op1MakeDeref        ldd       6,u       load node opcode
                    cmpd      #54       is it an lvalue node
                    bne       ErrMsg8E  no, report error
                    ldd       #8        allocate eight bytes
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop argument
                    std       2,s       save new node pointer
                    ldx       2,s       reload new node pointer
                    pshs      x         push new node
                    ldd       8,u       operand pointer
                    lbsr      IntToNum  build subtree
                    lbsr      SwapNumWork finish subtree
                    bra       FinishDeref attach and tag node

DerefMerge          leas      -4,x      normalize stack after merge
FinishDeref         ldd       2,s       new node pointer
                    std       8,u       set operand field
                    ldd       #75       dereference node tag
                    std       6,u       set node opcode
                    ldd       #8        size eight bytes
                    bra       SetAddrSize set size and finalize

ErrMsg8E            ldd       #142      type-error message 0x8E
SetMsgOp1           std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op1TypeSwitch       cmpx      #8        operand type long
                    lbeq      ConvConstNode handle long operand
                    cmpx      #2        operand type char
                    lbeq      Op1CharInt handle char operand
                    cmpx      #5        operand type struct
                    beq       Op1CoerceErr handle struct operand
                    cmpx      #6        operand type float
                    beq       Op1MakeDeref handle float operand
                    lbra      FinalizeOrError nothing to do, finalize

Op7Entry            ldx       10,s      reload operand type
                    bra       Op7TypeSwitch dispatch on type

ErrMsg86            ldd       #134      type-error message 0x86
                    bra       SetMsgOp7 store message and finalize

Op7CoerceErr        ldd       #6        coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    ldd       #141      type-error message 0x8D
                    bra       SetMsgOp7 store message and finalize

ErrMsg92            ldd       #146      type-error message 0x92
SetMsgOp7           std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op7CharInt          ldd       #1        result type int
                    std       10,s      save operand type
                    lbra      FinalizeOrError finalize node

Op7TypeSwitch       cmpx      #8        operand type long
                    beq       ErrMsg86  error for this operator
                    cmpx      #5        operand type struct
                    beq       Op7CoerceErr coerce then error
                    cmpx      #6        operand type float
                    beq       ErrMsg92  error 0x92
                    cmpx      #2        operand type char
                    beq       Op7CharInt result int
                    lbra      FinalizeOrError finalize node

Op8Entry            ldx       10,s      reload operand type
                    lbra      Op8TypeSwitch dispatch on type

ChkAddressable      ldd       10,s      load operand type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #16       is it addressable
                    lbne      FinalizeOrError no, finalize
MakeIntNode         ldd       6,u       load node opcode
                    cmpd      #74       is it an address node
                    bne       ErrMsg84  no, error 0x84
                    ldd       8,u       collapse to operand
                    std       2,s       save operand pointer
                    ldx       2,s       reload operand pointer
                    ldd       2,x       load pointed node
                    std       8,u       set operand field
                    bra       SetIntNode tag as lvalue node

IntNodeMerge        leas      -4,x      normalize stack after merge
SetIntNode          ldd       #54       lvalue node tag
                    std       6,u       set node opcode
                    ldd       #2        size two bytes
                    std       2,u       set node size
                    lbra      FinalizeOrError finalize node

ErrMsg84            ldd       #132      type-error message 0x84
                    bra       SetMsgOp8 store message and finalize

Op8CoerceErr        ldd       #6        coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    ldd       #141      type-error message 0x8D
                    bra       SetMsgOp8 store message and finalize

CollapseAddrNode    ldd       6,u       load node opcode
                    cmpd      #74       is it an address node
                    bne       ErrMsg90  no, error 0x90
                    ldd       #8        allocate eight bytes
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop argument
                    std       2,s       save new node pointer
                    ldx       2,s       reload new node pointer
                    pshs      x         push new node
                    ldx       8,u       operand pointer
                    lbsr      ClearNumWork build subtree
                    lbsr      SwapNumWork finish subtree
                    leax      4,s       point past pushed args
                    lbra      DerefMerge attach as deref node

ErrMsg90            ldd       #144      type-error message 0x90
SetMsgOp8           std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op8TypeSwitch       cmpx      #1        operand type int
                    lbeq      MakeIntNode make lvalue node
                    cmpx      #7        operand type pointer
                    lbeq      MakeIntNode make lvalue node
                    cmpx      #2        operand type char
                    lbeq      MakeIntNode make lvalue node
                    cmpx      #5        operand type struct
                    beq       Op8CoerceErr coerce then error
                    cmpx      #6        operand type float
                    beq       CollapseAddrNode collapse address node
                    lbra      ChkAddressable default class check

Op5Entry            ldx       10,s      reload operand type
                    bra       Op5TypeSwitch dispatch on type

Op5CoerceBoth       ldd       #6        coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce first operand
                    leas      4,s        drop arguments
                    ldd       10,s      operand type again
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce second operand
                    leas      4,s        drop arguments
                    lbra      FinalizeOrError finalize node

ErrMsg8C            ldd       #140      type-error message 0x8C
                    std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op5TypeSwitch       cmpx      #8        operand type long
                    beq       Op5CoerceBoth coerce operands
                    cmpx      #7        operand type pointer
                    lbeq      Op5CoerceBoth coerce operands
                    cmpx      #2        operand type char
                    lbeq      Op5CoerceBoth coerce operands
                    cmpx      #1        operand type int
                    lbeq      Op5CoerceBoth coerce operands
                    cmpx      #6        operand type float
                    beq       ErrMsg8C  error 0x8C
                    lbra      FinalizeOrError finalize node

Op6Entry            ldx       10,s      reload operand type
                    bra       Op6TypeSwitch dispatch on type

Op6DerefTag         ldd       6,u       load node opcode
                    cmpd      #75       is it a deref node
                    bne       ErrMsg8F  no, error 0x8F
                    ldx       8,u       operand pointer
                    lbsr      GetNumValue simplify subtree
                    std       8,u       set operand field
                    leax      4,s       point past args
                    lbra      IntNodeMerge make lvalue node

ErrMsg8F            ldd       #143      type-error message 0x8F
                    bra       SetMsgOp6 store message and finalize

Op6AddrTag          ldd       6,u       load node opcode
                    cmpd      #75       is it a deref node
                    bne       ErrMsg91  no, error 0x91
                    ldx       8,u       operand pointer
                    pshs      x         push operand pointer
                    ldx       8,u       operand pointer again
                    lbsr      NormalizeNum build subtree
                    lbsr      StoreLong finish subtree
                    leax      4,s       point past args
                    lbra      AddrNodeMerge build address node

ErrMsg91            ldd       #145      type-error message 0x91
                    bra       SetMsgOp6 store message and finalize

ErrMsg8D            ldd       #141      type-error message 0x8D
SetMsgOp6           std       ,s        store message code
                    bra       FinalizeOrError finalize with error

Op6TypeSwitch       cmpx      #2        operand type char
                    beq       Op6DerefTag handle deref node
                    cmpx      #7        operand type pointer
                    lbeq      Op6DerefTag handle deref node
                    cmpx      #1        operand type int
                    lbeq      Op6DerefTag handle deref node
                    cmpx      #8        operand type long
                    beq       Op6AddrTag handle address node
                    cmpx      #5        operand type struct
                    beq       ErrMsg8D  error 0x8D
                    bra       FinalizeOrError finalize node

OpKindSwitch        cmpx      #2        operator kind 2
                    lbeq      ConvLoadType handle operator two
                    cmpx      #1        operator kind 1
                    lbeq      ConvPtrCase handle operator one
                    cmpx      #7        operator kind 7
                    lbeq      Op7Entry  handle operator seven
                    cmpx      #8        operator kind 8
                    lbeq      Op8Entry  handle operator eight
                    cmpx      #5        operator kind 5
                    lbeq      Op5Entry  handle operator five
                    cmpx      #6        operator kind 6
                    lbeq      Op6Entry  handle operator six
                    lbra      CheckPtrClass2 default class check

FinalizeOrError     ldd       ,s        load error message accumulator
                    beq       ReturnType none, just return type
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    lbsr      NewExprNode build an error node
                    leas      12,s       drop arguments
                    std       2,s       save node pointer
                    pshs      d         push message argument
                    pshs      u         push node argument
                    lbsr      CopyStruct report the error message
                    leas      4,s        drop arguments
                    ldd       ,s        message code
                    std       6,u       store into node
                    ldd       2,s       node pointer
                    std       10,u      link error node
                    clra                clear field high
                    clrb                clear field low
                    std       12,u      clear node field
ReturnType          ldd       10,s      load result operand type
                    lbra      StoreResultRet store result and return

UsualArithConv      pshs      u         save the caller u register
                    ldd       #$FFB4    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load node argument
                    leas      -4,s       reserve locals
                    pshs      u         push operand node
                    lbsr      CoerceOperand get base type of operand
                    leas      2,s        drop argument
                    std       2,s       save first operand type
                    ldd       10,s      second operand node
                    pshs      d         push operand node
                    lbsr      CoerceOperand get base type of operand
                    leas      2,s        drop argument
                    std       ,s        save second operand type
                    ldd       2,s       first operand type
                    cmpd      #6        is it float
                    bne       ChkRhsFloat check other operand
                    ldd       #6        common type float
                    bra       CoerceLhs coerce and finish

ChkRhsFloat         ldd       ,s        second operand type
                    cmpd      #6        is it float
                    bne       ChkLhsLong check for long
                    ldd       #6        common type float
                    bra       CoerceRhs coerce and finish

ChkLhsLong          ldd       2,s       first operand type
                    cmpd      #8        is it long
                    bne       ChkRhsLong check other operand
                    ldd       #8        common type long
CoerceLhs           pshs      d         push target type
                    ldd       12,s      operand node
                    pshs      d         push operand node
                    bra       ApplyCoerce apply coercion

ChkRhsLong          ldd       ,s        second operand type
                    cmpd      #8        is it long
                    bne       ChkPointer check for pointer
                    ldd       #8        common type long
CoerceRhs           pshs      d         push target type
                    pshs      u         push operand node
ApplyCoerce         lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    bra       ConvRet   return result

ChkPointer          ldd       2,s       first operand type
                    cmpd      #7        is it pointer
                    beq       ResultPointer result pointer
                    ldd       ,s        second operand type
                    cmpd      #7        is it pointer
                    bne       ResultInt neither, result int
ResultPointer       ldd       #7        common type pointer
                    std       [10,s]    store through node pointer
StoreResultRet      std       ,u        store result type
                    bra       ConvRet   return result

ResultInt           ldd       #1        default result type int
ConvRet             leas      4,s        drop locals
                    puls      pc,u      restore u and return

ScalePointer        pshs      u         save the caller u register
                    ldd       #$FFB0    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldd       8,s       load argument
                    pshs      d         push argument
                    ldd       6,s       load argument
                    pshs      d         push argument
                    ldd       10,s      load node argument
                    pshs      d         push node argument
                    lbsr      RemovePtrLevel compute element scale factor
                    std       ,s        save scale result
                    lbsr      ComputeElemSize get type size
                    leas      6,s        drop arguments
                    std       4,s       save element size
                    cmpd      #1        is scale one
                    bne       BuildScaleNode no, build scale node
                    ldd       10,s      return node unchanged
                    puls      pc,u      restore u and return

BuildScaleNode      ldx       10,s      node pointer
                    ldd       16,x      load type field
                    pshs      d         push type field
                    ldx       12,s      load node pointer
                    ldd       14,x      load node field
                    pshs      d         push node field
                    ldd       8,s       size value
                    pshs      d         push size value
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    ldd       #54       constant node tag
                    pshs      d         push node tag
                    lbsr      NewExprNode build constant node
                    leas      12,s       drop arguments
                    tfr       d,u       constant node pointer
                    ldd       #1        constant value one
                    std       ,u        set node value
                    ldx       10,s      node pointer
                    ldd       16,x      load type field
                    pshs      d         push type field
                    ldx       12,s      load node pointer
                    ldd       14,x      load node field
                    pshs      d         push node field
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    pshs      u         push constant node
                    ldd       18,s      size operand
                    pshs      d         push size operand
                    ldd       #82       multiply node tag
                    pshs      d         push node tag
                    lbsr      NewExprNode build multiply node
                    leas      12,s       drop arguments
                    pshs      d         push result node
                    lbsr      SimplifyExpr simplify subtree
                    leas      2,s        drop argument
                    tfr       d,u       result node pointer
                    ldd       6,u       load node opcode
                    cmpd      #54       is it a constant
                    bne       ScaleTwo  no, scale two
                    clra                scale zero high
                    clrb                scale zero low
                    bra       SetScaleFields set node fields

ScaleTwo            ldd       #2        scale factor two
SetScaleFields      std       18,u      set scale field
                    ldd       #1        node value one
                    std       ,u        set node value
                    ldd       #2        node size two
                    std       2,u       set node size
                    tfr       u,d       return node pointer
                    puls      pc,u      restore u and return

ClassifyNode        pshs      u         save the caller u register
                    ldd       #$FFB6    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load node argument
                    leas      -2,s       reserve local
                    ldd       6,u       load node opcode
                    std       ,s        save opcode
                    tfr       d,x       opcode into index register
                    cmpx      #118      opcode 0x76
                    lbeq      ExprEpilogue handle these opcodes
                    cmpx      #111      opcode 0x6F
                    lbeq      ExprEpilogue handle these opcodes
                    cmpx      #66       opcode 0x42
                    lbeq      ExprEpilogue handle these opcodes
                    ldd       ,s        load opcode
                    cmpd      #52       opcode 0x34
                    bne       LvalueErr no, continue dispatch
                    pshs      u         save node pointer
                    bsr       ChkUndeclared check the node for an undeclared variable
                    leas      2,s        drop the pushed argument
                    ldd       8,s       load the caller flag
                    lbne      ExprEpilogue if set, finish and return
                    ldd       ,u        load the node type word
                    clra                keep only the low byte
                    andb      #$30      isolate the storage-class bits
                    cmpd      #32       is it a bitfield/lvalue kind
                    bne       LvalSetFalse no, clear the flag
                    ldd       #1        yes, flag as lvalue
                    bra       LvalTestArray test the result

LvalSetFalse        clra                clear high byte
                    clrb                result is false
LvalTestArray       bne       LvalueErr if lvalue, skip the integer check
                    ldd       ,u        reload the node type
                    cmpd      #4        is it a plain integer type
                    lbne      ExprEpilogue if not, just return
LvalueErr           leax      MsgLvalueReq,pcr point to the lvalue-required message
                    pshs      x         pass the message pointer
                    pshs      u         pass the node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    pshs      u         pass the node
                    lbsr      SetErrSym reset the node to the error symbol
                    leas      2,s        clean up the argument
                    lbra      ExprEpilogue finish and return

ChkUndeclared       pshs      u         save the caller u register
                    ldd       #$FFB8    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       4,s       get the node argument
                    ldd       6,u       load the node type field
                    cmpd      #52       is it a symbol reference
                    lbne      ExprReturn if not, just return
                    ldd       ,u        load the symbol pointer
                    lbne      ExprReturn if resolved, return
                    leax      MsgUndeclared,pcr point to the undeclared-variable message
                    pshs      x         pass the message pointer
                    pshs      u         pass the node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    pshs      u         pass the node
                    lbsr      SetErrSym reset the node to the error symbol
                    lbra      ExprEpilogue finish and return

ProcStructRef       pshs      u         save the caller u register
                    ldd       #$FFB6    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       4,s       get the node argument
                    leas      -2,s       allocate a local
                    ldd       ,u        load node field zero
                    std       [8,s]     store through the result pointer
                    ldd       6,u       load the node type field
                    cmpd      #65       is it a pointer type
                    bne       StructRefZero if not, zero the result
                    ldd       #1        flag the pointer case
                    std       [10,s]    store through the second result pointer
                    ldd       10,u      load the member offset
                    std       ,s        save it in the local
                    ldd       4,u       load the node value
                    ldx       ,s        get the local pointer
                    std       4,x       copy the value into the target
                    pshs      u         pass the node
                    ldd       2,s       load the local pointer
                    pshs      d         pass it
                    lbsr      CopyStruct process the member reference
                    leas      4,s        clean up the arguments
                    ldd       ,s        reload the local
                    pshs      d         pass it
                    lbsr      LinkNode  process the value
                    leas      2,s        clean up the argument
                    bra       StructRefBody continue to the member body

StructRefZero       clra                clear high byte
                    clrb                value is zero
                    std       [10,s]    clear the second result
StructRefBody       pshs      u         pass the node
                    lbsr      ChkUndeclared check the node for an undeclared variable
                    leas      2,s        clean up the argument
                    ldd       6,u       load the node type field
                    cmpd      #52       is it a symbol reference
                    bne       MemberErr if not, report the member error
                    ldd       8,u       load the symbol pointer
                    std       ,s        save it in the local
                    ldx       ,s        get the symbol pointer
                    ldd       8,x       load the symbol type field
                    cmpd      #17       is it a struct or union
                    beq       SetStructMember yes, set the struct type
                    leax      2,s       point past the local
                    bra       MemberFixup fix up the member

SetStructMember     ldd       #54       select the struct-member node type
                    std       6,u       set the node type
                    ldx       ,s        get the symbol pointer
                    ldd       6,x       load the symbol subtype
                    std       8,u       store it into the node
                    clra                clear high byte
                    clrb                zero
                    std       18,u      clear node field twelve
                    ldd       #1        set the node flag
                    std       ,u        store the flag
                    ldx       ,s        get the symbol pointer
                    ldd       2,x       load the symbol value
                    bra       ExprEpilogue finish and return

                    bra       MemberErr unreachable fallthrough guard

MemberFixup         leas      -2,x      adjust the stack via the pointer
MemberErr           leax      MsgStructMember,pcr point to the struct-member message
                    pshs      x         pass the message pointer
                    pshs      u         pass the node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    pshs      u         pass the node
                    lbsr      SetErrSym reset the node to the error symbol
                    leas      2,s        clean up the argument
                    ldd       #54       select the struct-member node type
                    std       6,u       set the node type
                    clra                clear high byte
                    clrb                zero
                    std       8,u       clear node field eight
                    clra                clear high byte
                    clrb                zero
                    std       18,u      clear node field twelve
                    ldd       #1        set the node flag
                    std       [8,s]     store through the result pointer
                    ldd       #2        return value two
ExprEpilogue        leas      2,s        release the local
ExprReturn          puls      pc,u      restore u and return

ChkNotStruct        pshs      u         save the caller u register
                    ldd       #$FFB8    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       4,s       get the node argument
                    ldd       ,u        load the node type word
                    cmpd      #4        is it a structure
                    beq       StructInapproprErr yes, report the error
                    ldd       ,u        reload the node type
                    cmpd      #3        is it a union
                    bne       ChkNotStructRet if neither, just return
StructInapproprErr  leax      MsgStructInapprop,pcr point to the struct/union-inappropriate message
                    pshs      x         pass the message pointer
                    pshs      u         pass the node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    pshs      u         pass the node
                    bsr       SetErrSym reset the node to the error symbol
                    leas      2,s        clean up the argument
ChkNotStructRet     ldd       ,u        load the node type for return
                    puls      pc,u      restore u and return

SetErrSym           pshs      u         save the caller u register
                    ldd       #$FFB6    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       4,s       get the node argument
                    ldd       #6        length six bytes
                    pshs      d         pass the length
                    pshs      u         pass the node
                    leax      DummyErrorSymbol,y   point to the dummy error symbol
                    pshs      x         pass it
                    lbsr      CopyBlock copy the error symbol into the node
                    leas      6,s        clean up the arguments
                    ldd       #1        value one
                    std       18,u      mark node field twelve
                    ldd       10,u      load node field ten
                    pshs      d         pass it
                    lbsr      WalkTree  free the sub-node
                    leas      2,s        clean up the argument
                    ldd       12,u      load node field twelve
                    pshs      d         pass it
                    lbsr      WalkTree  free the sub-node
                    leas      2,s        clean up the argument
                    clra                clear high byte
                    clrb                zero
                    std       12,u      clear node field twelve
                    std       10,u      clear node field ten
                    ldd       #52       select the symbol-reference type
                    std       6,u       set the node type
                    leax      DummyErrorSymbol,y   point to the dummy error symbol
                    stx       8,u       attach it to the node
                    puls      pc,u      restore u and return

IsIntegral          pshs      u         save the caller u register
                    ldd       #$FFC0    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldx       4,s       get the type-code argument
                    bra       IsIntegralCmp test against the integral codes

RetIntegral         ldd       #1        result is true
                    puls      pc,u      restore u and return

IsIntegralCmp       cmpx      #1        is it type code one
                    beq       RetIntegral yes, integral
                    cmpx      #2        is it type code two
                    lbeq      RetIntegral yes, integral
                    cmpx      #8        is it type code eight
                    lbeq      RetIntegral yes, integral
                    cmpx      #7        is it type code seven
                    lbeq      RetIntegral yes, integral
                    clra                clear high byte
                    clrb                result is false
                    puls      pc,u      restore u and return

ErrMustBeIntegral   pshs      u         save the caller u register
                    ldd       #$FFB8    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    leax      MsgMustBeIntegral,pcr point to the must-be-integral message
                    pshs      x         pass the message pointer
                    ldd       6,s       load the caller argument
                    pshs      d         pass it
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    puls      pc,u      restore u and return

MsgDivZero          fcc       /divide by zero/
                    fcb       C$NULL
MsgTypedefNotVar    fcc       /typedef - not a variable/
                    fcb       C$NULL
MsgCannotCast       fcc       /cannot cast/
                    fcb       C$NULL
MsgNoAddress        fcc       /can't take address/
                    fcb       C$NULL
MsgPtrRequired      fcc       /pointer required/
                    fcb       C$NULL
MsgPtrOrIntReq      fcc       /pointer or integer required/
                    fcb       C$NULL
MsgNotFunction      fcc       /not a function/
                    fcb       C$NULL
MsgBothIntegral     fcc       /both must be integral/
                    fcb       C$NULL
MsgPtrMismatch      fcc       /pointer mismatch/
                    fcb       C$NULL
MsgTypeMismatch     fcc       /type mismatch/
                    fcb       C$NULL
MsgPtrMismatch2     fcc       /pointer mismatch/
                    fcb       C$NULL
MsgTypeCheck        fcc       /type check/
                    fcb       C$NULL
MsgShouldBeNull     fcc       /should be NULL/
                    fcb       C$NULL
MsgTypeError        fcc       /type error/
                    fcb       C$NULL
MsgLvalueReq        fcc       /lvalue required/
                    fcb       C$NULL
MsgUndeclared       fcc       /undeclared variable/
                    fcb       C$NULL
MsgStructMember     fcc       /struct member required/
                    fcb       C$NULL
MsgStructInapprop   fcc       /structure or union inappropriate/
                    fcb       C$NULL
MsgMustBeIntegral   fcc       /must be integral/
                    fcb       C$NULL
ParseStatement      pshs      u         save the caller u register
                    ldd       #$FFBA    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldd       GlbVar005F load the current token
                    cmpd      #'(       is it a semicolon
                    beq       StmtDispatch yes, dispatch it
                    clra                clear high byte
                    clrb                zero
                    std       GlbVar004F clear the label flag
                    bra       StmtDispatch dispatch the statement

StmtLoop            leas      ,x        restore the stack pointer
StmtDispatch        ldx       GlbVar005F load the current token
                    lbra      ClassifyStmt classify the statement

KwDispatch2         ldx       GlbVar0061 load the keyword subtype
                    bra       KwDispatch dispatch the keyword

ParseIfEntry        lbsr      ParseIfStmt parse an if statement
                    puls      pc,u      restore u and return

HandleKw14          lbsr      WhileStmt parse the statement
                    puls      pc,u      restore u and return

HandleKw12          lbsr      ParseReturnStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw17          lbsr      CaseStmt  parse the statement
                    puls      pc,u      restore u and return

HandleKw16          lbsr      SwitchStmt parse the statement
                    puls      pc,u      restore u and return

HandleKw18          lbsr      ParseBreakStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw19          lbsr      ParseContinueStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw1B          lbsr      DefaultStmt parse the statement
                    puls      pc,u      restore u and return

HandleKw1C          lbsr      ForStmt   parse the statement
                    puls      pc,u      restore u and return

HandleKw1A          lbsr      DoWhileStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw1D          lbsr      ParseGotoStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

StrayElseErr        leax      MsgNoIfForElse,pcr point to the stray-else message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        clean up the argument
                    lbsr      ScanToken advance to the next token
                    lbra      LabelDone resume the statement loop

NotKeywordStmt      leax      ,s        point at the stack
                    lbra      ExprStmtEntry parse as an expression statement

KwDispatch          cmpx      #19       is it the if keyword
                    beq       ParseIfEntry yes, parse if
                    cmpx      #20       keyword code fourteen
                    beq       HandleKw14 dispatch it
                    cmpx      #18       keyword code twelve
                    beq       HandleKw12 dispatch it
                    cmpx      #23       keyword code seventeen
                    beq       HandleKw17 dispatch it
                    cmpx      #22       keyword code sixteen
                    beq       HandleKw16 dispatch it
                    cmpx      #24       keyword code eighteen
                    beq       HandleKw18 dispatch it
                    cmpx      #25       keyword code nineteen
                    beq       HandleKw19 dispatch it
                    cmpx      #27       keyword code 0x1b
                    beq       HandleKw1B dispatch it
                    cmpx      #28       keyword code 0x1c
                    beq       HandleKw1C dispatch it
                    cmpx      #26       keyword code 0x1a
                    beq       HandleKw1A dispatch it
                    cmpx      #29       keyword code 0x1d
                    beq       HandleKw1D dispatch it
                    cmpx      #21       is it the else keyword
                    beq       StrayElseErr yes, stray-else error
                    bra       NotKeywordStmt otherwise expression statement

ParseBlock          lbsr      ParseBlock2 parse a brace block
                    lbsr      ScanToken advance to the next token
                    puls      pc,u      restore u and return

StmtEofRet          puls      pc,u      restore u and return

IdentOrLabel        lbsr      SkipWhitespace parse the identifier expression
                    ldb       GlbVar0065 load the following character
                    cmpb      #':       is it a colon
                    bne       NotLabelStmt no, treat as an expression
                    lbsr      ParseLabelStmt define the statement label
LabelDone           leax      ,s        point at the stack
                    lbra      StmtLoop  loop for the next statement

NotLabelStmt        leax      ,s        point at the stack
                    bra       ExprStmtRestore handle as an expression statement

ExprStmtEntry       leas      ,x        restore the stack pointer
ParseExprStmt       lbsr      IsQualifierKw parse an expression
                    std       -2,s      save the result node
                    bne       ExprStmtErr if error, report it
                    lbsr      ClassifyType parse an expression alternate
                    std       -2,s      save the result node
                    beq       EmitExprStmt if empty, emit the statement
ExprStmtErr         leax      MsgIllegalDecl,pcr point to the syntax-error message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        clean up the argument
SkipToSemiLoop      lbsr      ScanToken advance to the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #'(       is it a semicolon
                    bne       SkipToSemiLoop no, keep skipping
                    bra       ExpectSemi consume the semicolon

ExprStmtRestore     leas      ,x        restore the stack pointer
EmitExprStmt        clra                clear high byte
                    clrb                zero
                    pshs      d         reserve the result slot
                    lbsr      ParseExprStmt2 evaluate the expression
                    std       ,s++      store and pop the result
                    bne       ExpectSemi if valid, expect the semicolon
                    leax      MsgSyntaxError,pcr point to the missing-expression message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        clean up the argument
                    lbsr      SyncDeclarator recover from the error
                    puls      pc,u      restore u and return

                    bra       ExpectSemi unreachable, expect the semicolon

ClassifyStmt        cmpx      #'(       is it a semicolon
                    beq       ExpectSemi yes, consume it
                    cmpx      #51       is it a reserved word
                    lbeq      KwDispatch2 yes, dispatch the keyword
                    cmpx      #')       is it an open brace
                    lbeq      ParseBlock yes, parse a block
                    cmpx      #$FFFF    is it end of input
                    lbeq      StmtEofRet yes, just return
                    cmpx      #52       is it an identifier
                    lbeq      IdentOrLabel yes, maybe a label
                    lbra      ParseExprStmt otherwise expression statement

ExpectSemi          ldd       #'(       semicolon token
                    pshs      d         pass the expected token
                    lbsr      ExpectToken require the semicolon
                    leas      2,s        clean up the argument
                    puls      pc,u      restore u and return

ParseIfStmt         pshs      u         save the caller u register
                    ldd       #$FFAE    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    leas      -6,s       allocate the locals
                    lbsr      ScanToken advance past the if keyword
                    lbsr      ParseParenExpr2 parse the parenthesized condition
                    std       ,s        save the condition node
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label number
                    std       GlbVar002B update the counter
                    tfr       d,u       keep the false label
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate another label number
                    std       GlbVar002B update the counter
                    std       4,s       save the end label
                    ldd       GlbVar005F load the current token
                    cmpd      #'(       is it a semicolon
                    bne       IfThenBody no, parse the then body
                    lbsr      ScanToken advance to the next token
                    clra                clear high byte
                    clrb                zero
                    pshs      d         pass zero
                    ldd       6,s       load the false label
                    pshs      d         pass it
                    pshs      u         pass the condition
                    ldd       6,s       reload the false label
                    pshs      d         pass it
                    lbsr      EmitCondNode emit the conditional branch
                    leas      8,s        clean up the arguments
                    ldd       4,s       load the end label
                    pshs      d         pass it
                    lbsr      EmitLocalRef emit the label
                    leas      2,s        clean up the argument
                    stu       2,s       save the returned node
                    bra       CheckElse check for an else clause

IfThenBody          ldd       #1        value one
                    pshs      d         pass it
                    ldd       6,s       load the false label
                    pshs      d         pass it
                    pshs      u         pass the condition
                    ldd       6,s       reload the false label
                    pshs      d         pass it
                    lbsr      EmitCondNode emit the conditional branch
                    leas      8,s        clean up the arguments
                    pshs      u         pass the condition
                    lbsr      EmitLocalRef emit the label
                    leas      2,s        clean up the argument
                    lbsr      ParseStatement parse the then statement
                    ldd       4,s       load the end label
                    std       2,s       save it
CheckElse           ldd       GlbVar005F load the current token
                    cmpd      #51       is it a reserved word
                    bne       IfStmtDone no, finish the if
                    ldd       GlbVar0061 load the keyword subtype
                    cmpd      #21       is it the else keyword
                    bne       IfStmtDone no, finish the if
                    lbsr      ScanToken advance past else
                    ldd       GlbVar005F load the current token
                    cmpd      #'(       compare token type against paren tag
                    beq       IfStmtDone no else clause, skip to end
                    cmpu      2,s       compare against saved else label
                    beq       IfElseBody else absent, parse else body directly
                    clra                clear high byte of argument
                    clrb                clear low byte of argument
                    pshs      d         push zero argument
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate the next label number
                    std       GlbVar002B store label counter back
                    std       4,s       remember the new end label
                    pshs      d         push the end label argument
                    ldd       #124      tag for a goto node
                    pshs      d         push the node tag
                    lbsr      EmitOpCode emit goto past the else clause
                    leas      6,s        drop the three arguments
                    ldd       4,s       reload the end label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the branch-over label
                    leas      2,s        drop the argument
IfElseBody          lbsr      ParseStatement parse the else-clause statement
IfStmtDone          ldd       2,s       load the if end label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the end label
                    leas      2,s        drop the argument
                    leas      6,s        tear down the frame
                    puls      pc,u      restore u and return

WhileStmt           pshs      u         save u on entry
                    ldd       #$FFAA    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leas      -10,s      allocate local frame
                    ldd       GlbVar0053 save the current break label
                    std       8,s       stash on the stack frame
                    ldd       GlbVar0055 save the current continue label
                    std       6,s       stash on the stack frame
                    ldd       RecordContextField,y   save loop context field
                    std       4,s       stash on the stack frame
                    ldd       RecordContextField2,y   save second context field
                    std       2,s       stash on the stack frame
                    lbsr      ScanToken consume the while token
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a new label
                    std       GlbVar002B store counter back
                    std       GlbVar0053 set as the new break label
                    ldd       GlbVar002F load current token position
                    std       RecordContextField2,y   record into context field
                    std       RecordContextField,y   record into context field
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate another label
                    std       GlbVar002B store counter back
                    std       GlbVar0055 set as the new continue label
                    lbsr      ParseParenExpr2 parse the loop condition expression
                    std       ,s        save the condition result
                    ldd       GlbVar005F load current token type
                    cmpd      #'(       compare against paren tag
                    bne       WhileEmitBody not that token, emit body path
                    ldu       GlbVar0055 reuse continue label
                    bra       WhileEmitTest skip ahead to test emit

WhileEmitBody       clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar0055 load the continue label
                    pshs      d         push it as argument
                    ldd       #124      goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the continue point
                    leas      6,s        drop the three arguments
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label
                    std       GlbVar002B store counter back
                    tfr       d,u       move label into u
                    pshs      u         push it as argument
                    lbsr      EmitLocalRef define the body-top label
                    leas      2,s        drop the argument
                    lbsr      ParseStatement parse the loop body statement
WhileEmitTest       ldd       GlbVar0055 load the continue label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the continue label
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    pshs      u         push the continue label
                    ldd       6,s       reload the condition result
                    pshs      d         push it as argument
                    lbsr      EmitCondNode emit conditional back-jump on true
                    leas      8,s        drop the four arguments
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the break label
                    leas      2,s        drop the argument
                    ldd       8,s       restore the saved break label
                    std       GlbVar0053 put it back in the global
                    ldd       6,s       restore the saved continue label
                    std       GlbVar0055 put it back in the global
                    ldd       4,s       restore saved context field
                    std       RecordContextField,y   put it back
                    ldd       2,s       restore second context field
                    std       RecordContextField2,y   put it back
                    leas      10,s       tear down the frame
                    puls      pc,u      restore u and return

SwitchStmt          pshs      u         save u on entry
                    ldd       #$FFA8    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leas      -14,s      allocate local frame
                    lbsr      ScanToken consume the switch token
                    ldd       GlbVar0057 load the switch nesting counter
                    addd      #1        increment for this switch
                    std       GlbVar0057 store counter back
                    ldd       GlbVar005B save current case-list tail
                    std       ,s        stash on the frame
                    ldd       GlbVar0059 save current case chain head
                    std       10,s      stash on the frame
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0059 reset the case chain
                    ldd       GlbVar0053 save current break label
                    std       12,s      stash on the frame
                    ldd       DefaultLabel,y   save current default label
                    std       8,s       stash on the frame
                    ldd       RecordContextField,y   save context field
                    std       2,s       stash on the frame
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label
                    std       GlbVar002B store counter back
                    std       GlbVar0053 set as the new break label
                    ldd       GlbVar002F load current token position
                    std       RecordContextField,y   record into context field
                    clra                clear high byte
                    clrb                clear low byte
                    std       DefaultLabel,y   clear the default label
                    ldd       #'-       open-paren token expected
                    pshs      d         push the expected token
                    lbsr      ExpectToken require the open paren
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    lbsr      ParseExpr parse the switch expression
                    std       ,s        save the expression result
                    lbsr      OptExprTree resolve the expression type
                    leas      2,s        drop the argument
                    tfr       d,u       move result into u
                    stu       -2,s      save expression pointer
                    beq       SwitchExprErr null expression, report error
                    pshs      u         push the expression pointer
                    lbsr      ChkUndeclared fetch its type node
                    leas      2,s        drop the argument
                    ldx       ,u        load the type code
                    bra       SwitchCheckType dispatch on the type

SwitchExprInt       ldd       #1        integer promotion flag
                    pshs      d         push the flag
                    pshs      u         push the expression
                    lbsr      InsertConvNode coerce switch expression to int
                    leas      4,s        drop the two arguments
                    bra       SwitchExprDone expression done

SwitchExprOther     pshs      u         push the expression
                    lbsr      ErrMustBeIntegral apply value conversion
                    leas      2,s        drop the argument
                    pshs      u         push the expression
                    lbsr      SetErrSym emit the converted value
                    leas      2,s        drop the argument
                    bra       SwitchExprDone expression done

SwitchCheckType     cmpx      #2        is the type char/int
                    beq       SwitchExprInt yes, promote to int
                    cmpx      #8        is the type unsigned
                    lbeq      SwitchExprInt yes, promote to int
                    cmpx      #1        is the type already word
                    beq       SwitchExprDone yes, expression done
                    cmpx      #7        is the type pointer
                    beq       SwitchExprDone yes, expression done
                    bra       SwitchExprOther otherwise convert the value

SwitchExprDone      pshs      u         push the expression
                    lbsr      EmitStmtMode1 finalise the expression node
                    leas      2,s        drop the argument
                    pshs      u         push the expression
                    lbsr      WalkTree  emit the switch value load
                    leas      2,s        drop the argument
                    bra       SwitchAfterExpr continue after expression

SwitchExprErr       lbsr      ExprMissingErr report missing switch expression
SwitchAfterExpr     ldd       #'.       close-paren token expected
                    pshs      d         push the expected token
                    lbsr      ExpectToken require the close paren
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label
                    std       GlbVar002B store counter back
                    std       8,s       remember the case-test label
                    pshs      d         push it as argument
                    ldd       #124      goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the case tests
                    leas      6,s        drop the three arguments
                    lbsr      ParseStatement parse the switch body statement
                    ldd       GlbVar004F any implicit fall-off
                    bne       SwitchDefTestLabel handled, skip break goto
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    ldd       #124      goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the break point
                    leas      6,s        drop the three arguments
SwitchDefTestLabel  ldd       6,s       load the case-test label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the case-test label
                    leas      2,s        drop the argument
                    ldu       GlbVar0059 load the case chain head
                    bra       SwitchCaseTest enter the case emit loop

SwitchCaseLoop      ldd       ,u        load the next case node
                    std       4,s       save the chain link
                    ldd       2,u       load the case value
                    pshs      d         push it as argument
                    ldd       4,u       load the case label
                    pshs      d         push it as argument
                    ldd       #125      case-compare node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit the case comparison
                    leas      6,s        drop the three arguments
                    ldd       GlbVar0045 load the free-list head
                    std       ,u        link node onto free list
                    stu       GlbVar0045 return node to the free list
                    ldu       4,s       advance to the next case node
SwitchCaseTest      stu       -2,s      save loop pointer, test null
                    bne       SwitchCaseLoop more cases, loop back
                    ldd       DefaultLabel,y   any default label
                    beq       SwitchEpilogue none, skip default goto
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       DefaultLabel,y   load the default label
                    pshs      d         push it as argument
                    ldd       #124      goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the default
                    leas      6,s        drop the three arguments
SwitchEpilogue      ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the break label
                    leas      2,s        drop the argument
                    ldd       10,s      restore saved case chain
                    std       GlbVar0059 put it back
                    ldd       8,s       restore saved default label
                    std       DefaultLabel,y   put it back
                    ldd       GlbVar0057 load the switch nesting counter
                    addd      #$FFFF    decrement leaving this switch
                    std       GlbVar0057 store counter back
                    ldd       ,s        restore saved case-list tail
                    std       GlbVar005B put it back
                    ldd       12,s      restore saved break label
                    std       GlbVar0053 put it back
                    ldd       2,s       restore saved context field
                    std       RecordContextField,y   put it back
                    lbra      LoopStmtDone jump to the shared epilogue

CaseStmt            pshs      u         save u on entry
                    ldd       #$FFB8    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leas      -2,s       allocate local frame
                    lbsr      ScanToken consume the case token
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    lbsr      EvalConstOperand parse the constant case value
                    leas      2,s        drop the argument
                    std       ,s        save the case value
                    ldd       #'/       colon token expected
                    pshs      d         push the expected token
                    lbsr      ExpectToken require the colon
                    leas      2,s        drop the argument
                    ldd       GlbVar0057 are we inside a switch
                    beq       CaseNotInSwitch no, report the error
                    ldu       GlbVar0045 load the free-list head
                    beq       CaseAllocNode empty, allocate a new node
                    ldd       ,u        load the next free node
                    std       GlbVar0045 unlink it from the free list
                    bra       CaseLinkNode use this node

CaseAllocNode       ldd       #6        case-node size
                    pshs      d         push the size
                    lbsr      AllocMem  allocate node memory
                    leas      2,s        drop the argument
                    tfr       d,u       use the allocated node
CaseLinkNode        ldd       GlbVar0059 any existing case chain
                    beq       CaseFirstNode none, set as head
                    stu       [>GlbVar005B,y] link onto the chain tail
                    bra       CaseStoreNode update the tail

CaseFirstNode       stu       GlbVar0059 set the case chain head
CaseStoreNode       stu       GlbVar005B record as the new tail
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,u        clear the node link
                    ldd       ,s        load the case value
                    std       2,u       store into the node
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate the case label
                    std       GlbVar002B store counter back
                    std       4,u       store label into the node
                    pshs      d         push the case label
                    lbsr      EmitLocalRef define the case label
                    leas      2,s        drop the argument
                    bra       StmtRet2  return via shared exit

CaseNotInSwitch     bsr       NotInSwitchErr emit not-in-switch error
                    bra       StmtRet2  return via shared exit

DefaultStmt         pshs      u         save u on entry
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  verify stack space available
                    lbsr      ScanToken consume the default token
                    ldd       GlbVar0057 are we inside a switch
                    bne       DefaultCheckDup
                    bsr       NotInSwitchErr no, report the error
DefaultCheckDup     ldd       DefaultLabel,y   any existing default label
                    beq       DefaultAllocLabel none, allocate one
                    leax      MsgMultipleDefaults,pcr duplicate-default message
                    pshs      x         push the message pointer
                    lbsr      PrintErrLoc report the error
                    bra       DefaultExpectColon skip the label allocation

DefaultAllocLabel   ldd       GlbVar002B load the label counter
                    addd      #1        allocate the default label
                    std       GlbVar002B store counter back
                    std       DefaultLabel,y   store as the default label
                    pshs      d         push the default label
                    lbsr      EmitLocalRef define the default label
DefaultExpectColon  leas      2,s        drop the argument
                    ldd       #'/       colon token expected
                    pshs      d         push the expected token
                    lbsr      ExpectToken require the colon
                    bra       StmtRet2  return via shared exit

NotInSwitchErr      pshs      u         save u on entry
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leax      MsgNoSwitch,pcr not-in-switch message
                    pshs      x         push the message pointer
                    lbsr      PrintErrLoc report the error
StmtRet2            leas      2,s        drop the argument
                    puls      pc,u      restore u and return

DoWhileStmt         pshs      u         save u on entry
                    ldd       #$FFAA    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leas      -10,s      allocate local frame
                    ldd       GlbVar0053 save current break label
                    std       8,s       stash on the frame
                    ldd       GlbVar0055 save current continue label
                    std       6,s       stash on the frame
                    ldd       RecordContextField2,y   save context field
                    std       ,s        stash on the frame
                    ldd       RecordContextField,y   save context field
                    std       2,s       stash on the frame
                    ldd       GlbVar002F load current token position
                    std       RecordContextField2,y   record into context field
                    std       RecordContextField,y   record into context field
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label
                    std       GlbVar002B store counter back
                    std       GlbVar0055 set as the new continue label
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label
                    std       GlbVar002B store counter back
                    std       GlbVar0053 set as the new break label
                    lbsr      ScanToken consume the do token
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate the loop-top label
                    std       GlbVar002B store counter back
                    std       4,s       remember the loop-top label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the loop-top label
                    leas      2,s        drop the argument
                    lbsr      ParseStatement parse the loop body statement
                    ldd       GlbVar005F load current token type
                    cmpd      #51       is it the while keyword
                    bne       DoMissingWhile no, report missing while
                    ldd       GlbVar0061 load token keyword id
                    cmpd      #20       confirm it is while
                    beq       DoEmitTest correct, emit the test
DoMissingWhile      leax      MsgWhileExpected,pcr missing-while message
                    pshs      x         push the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop the argument
DoEmitTest          lbsr      ScanToken consume the while token
                    ldd       GlbVar0055 load the continue label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the continue label
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    ldd       8,s       push the loop-top label
                    pshs      d         push the loop-top label argument
                    lbsr      ParseParenExpr2 parse the condition expression
                    pshs      d         push the condition result
                    lbsr      EmitCondNode emit conditional jump to top
                    leas      8,s        drop the four arguments
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the break label
                    leas      2,s        drop the argument
                    ldd       8,s       restore saved break label
                    std       GlbVar0053 put it back
                    ldd       6,s       restore saved continue label
                    std       GlbVar0055 put it back
                    ldd       2,s       restore saved context field
                    std       RecordContextField,y   put it back
                    ldd       ,s        restore saved context field
                    std       RecordContextField2,y   put it back
                    leas      10,s       tear down the frame
                    puls      pc,u      restore u and return

ForStmt             pshs      u         save u on entry
                    ldd       #$FFA6    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leas      -14,s      allocate local frame
                    clra                clear high byte
                    clrb                clear low byte
                    std       2,s       zero a frame slot
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        zero a frame slot
                    ldu       GlbVar0053 save current break label
                    ldd       GlbVar0055 save current continue label
                    std       12,s      stash on the frame
                    ldd       RecordContextField,y   save context field
                    std       6,s       stash on the frame
                    ldd       RecordContextField2,y   save context field
                    std       4,s       stash on the frame
                    ldd       GlbVar002F load current token position
                    std       RecordContextField,y   record into context field
                    std       RecordContextField2,y   record into context field
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label
                    std       GlbVar002B store counter back
                    std       10,s      save the value into a local slot
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate the next label number
                    std       GlbVar002B bump the label counter
                    std       GlbVar0053 set this as the loop break label
                    lbsr      ScanToken advance to the next token
                    ldd       #45       loop-start marker opcode
                    pshs      d         push the opcode argument
                    lbsr      ExpectToken emit the intermediate marker
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      ParseExprStmt2 parse and emit the init expression
                    leas      2,s        discard the argument
                    ldd       #40       condition marker opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    ldd       GlbVar005F load the current token
                    cmpd      #40       is the condition empty
                    beq       LoopEmptyCond skip the condition if none
                    lbsr      ParseExpr2 parse the loop condition expression
                    std       2,s       save the condition node
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate another label number
                    std       GlbVar002B bump the label counter
                    std       10,s      save the loop label
                    pshs      d         push the label
                    ldd       #124      conditional-branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the conditional branch node
                    leas      6,s        discard the arguments
LoopEmptyCond       ldd       #40       increment marker opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      ParseExpr begin parsing the increment expression
                    std       ,s        save the partial result
                    lbsr      OptExprTree parse the rest of the expression
                    leas      2,s        discard the argument
                    std       ,s        save the increment node
                    beq       LoopNoIncr no increment expression present
                    ldd       ,s        load the increment node
                    pshs      d         push it
                    lbsr      ChkUndeclared process the increment expression
                    leas      2,s        discard the argument
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate the continue label
                    std       GlbVar002B bump the label counter
                    bra       LoopSetContLabel set the continue label

LoopNoIncr          ldd       10,s      reuse the loop label
LoopSetContLabel    std       GlbVar0055 set the loop continue label
                    ldd       #46       loop-end marker opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    ldd       10,s      load the continue label
                    pshs      d         push it
                    lbsr      EmitLocalRef build the label reference node
                    leas      2,s        discard the argument
                    lbsr      ParseStatement parse the loop body statement
                    ldd       ,s        load the body result
                    beq       LoopEmitCondBack skip if no body node
                    ldd       GlbVar0055 load the continue label
                    pshs      d         push it
                    lbsr      EmitLocalRef build the label node
                    leas      2,s        discard the argument
                    ldd       ,s        load the body node
                    pshs      d         push it
                    lbsr      EmitExprNode emit the body expression
                    leas      2,s        discard the argument
LoopEmitCondBack    ldd       2,s       load the condition node
                    beq       LoopEmitUncondBack no condition, emit unconditional loop
                    ldd       8,s       load the loop label
                    pshs      d         push it
                    lbsr      EmitLocalRef build the loop label node
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it
                    ldd       14,s      load the condition node
                    pshs      d         push it
                    ldd       8,s       load the loop label node
                    pshs      d         push it
                    lbsr      EmitCondNode emit the conditional loop-back node
                    leas      8,s        discard the arguments
                    bra       LoopRestoreLabels finish the loop

LoopEmitUncondBack  clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       12,s      load the loop label
                    pshs      d         push it
                    ldd       #124      branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the unconditional loop-back node
                    leas      6,s        discard the arguments
LoopRestoreLabels   ldd       GlbVar0053 load the break label
                    pshs      d         push it
                    lbsr      EmitLocalRef build the break label node
                    leas      2,s        discard the argument
                    stu       GlbVar0053 restore the outer break label
                    ldd       12,s      load the saved continue label
                    std       GlbVar0055 restore the outer continue label
                    ldd       6,s       load the saved outer break slot
                    std       RecordContextField,y   restore the outer break slot
                    ldd       4,s       load the saved outer continue slot
                    std       RecordContextField2,y   restore the outer continue slot
LoopStmtDone        leas      14,s       tear down the stack frame
                    puls      pc,u      return

ParseReturnStmt     pshs      u         save the caller u register
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #40       is there no return value
                    lbeq      EmitBareReturn emit a bare return if so
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      ParseExpr begin parsing the return expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the expression node
                    stu       -2,s      save it in a local
                    beq       EmitBareReturn emit a bare return if empty
                    pshs      u         push the node
                    lbsr      OptExprTree parse the rest of the expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the expression node
                    pshs      u         push it
                    lbsr      ChkUndeclared process the expression tree
                    leas      2,s        discard the argument
                    pshs      u         push the node
                    lbsr      ChkNotStruct coerce to the return type
                    leas      2,s        discard the argument
                    ldd       GlbVar004D load the current type
                    clra                keep only the low byte
                    andb      #$30      isolate the storage-class bits
                    cmpd      #16       is it a plain type
                    bne       ReturnUseDeclType otherwise use the declared type
                    ldd       #1        use the default type
                    bra       ReturnHaveType continue

ReturnUseDeclType   ldd       GlbVar004D load the declared type
ReturnHaveType      pshs      d         push the type
                    pshs      u         push the node
                    lbsr      InsertConvNode check type compatibility
                    leas      4,s        discard the arguments
                    ldd       GlbVar004D load the return type
                    pshs      d         push it
                    pshs      u         push the node
                    ldd       #18       return opcode
                    pshs      d         push the opcode
                    lbsr      EmitNodeRecord emit the return node
                    leas      6,s        discard the arguments
                    pshs      u         push the node
                    lbsr      WalkTree  finalize and emit the expression
                    leas      2,s        discard the argument
EmitBareReturn      clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      EmitLabelOffset build an empty node
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       #18       return opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the return node
                    leas      6,s        discard the arguments
                    ldd       #18       return statement opcode
                    lbra      SetStmtOpcode record the statement opcode

ParseBreakStmt      pshs      u         save the caller u register
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar0053 load the break label
                    bne       EmitBreakJump emit a jump if inside a loop
                    leax      MsgBreakError,pcr point to the break-outside-loop message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    bra       BreakStmtDone finish

EmitBreakJump       ldd       RecordContextField,y   load the loop break node
                    pshs      d         push it
                    lbsr      EmitLabelOffset build the label node
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it
                    ldd       #124      branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the break jump node
                    leas      6,s        discard the arguments
BreakStmtDone       ldd       #24       break statement opcode
                    lbra      SetStmtOpcode record the statement opcode

ParseContinueStmt   pshs      u         save the caller u register
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar0055 load the continue label
                    bne       EmitContinueJump emit a jump if inside a loop
                    leax      MsgContinueError,pcr point to the continue-outside-loop message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    bra       ContinueStmtDone finish

EmitContinueJump    ldd       RecordContextField2,y   load the loop continue node
                    pshs      d         push it
                    lbsr      EmitLabelOffset build the label node
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       GlbVar0055 load the continue label
                    pshs      d         push it
                    ldd       #124      branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the continue jump node
                    leas      6,s        discard the arguments
ContinueStmtDone    ldd       #25       continue statement opcode
                    bra       SetStmtOpcode record the statement opcode

ParseGotoStmt       pshs      u         save the caller u register
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #52       is it a label identifier
                    beq       EmitGotoJump process the goto target
                    leax      MsgLabelRequired,pcr point to the missing-label message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    bra       GotoSetOpcode finish

EmitGotoJump        lbsr      FindOrMakeLabel find or create the target label
                    tfr       d,u       keep the label node
                    stu       -2,s      save it in a local
                    beq       GotoAdvance skip if none
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       6,u       load the label number
                    pshs      d         push it
                    ldd       #29       goto opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the goto node
                    leas      6,s        discard the arguments
                    ldd       10,u      load the label flags
                    orb       #$02      mark the label referenced
                    std       10,u      store the flags
GotoAdvance         lbsr      ScanToken advance past the label
GotoSetOpcode       ldd       #29       goto statement opcode
SetStmtOpcode       std       GlbVar004F record the statement opcode
                    puls      pc,u      return

ParseLabelStmt      pshs      u         save the caller u register
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    bsr       FindOrMakeLabel find or create the label
                    tfr       d,u       keep the label node
                    stu       -2,s      save it in a local
                    beq       LabelStmtDone skip if none
                    ldd       8,u       load the label state
                    cmpd      #15       is it already defined
                    bne       DefineLabelHere otherwise define it now
                    lbsr      ReportMsgErr report the redefined-label error
                    bra       LabelStmtDone finish

DefineLabelHere     ldd       #15       defined-label state
                    std       8,u       mark the label defined
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       6,u       load the label number
                    pshs      d         push it
                    ldd       #9        label opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the label-definition node
                    leas      6,s        discard the arguments
                    ldd       10,u      load the label flags
                    orb       #$01      mark the label defined
                    std       10,u      store the flags
LabelStmtDone       lbsr      ScanToken advance to the next token
                    lbsr      ScanToken advance again past the colon
                    puls      pc,u      return

FindOrMakeLabel     pshs      u         save the caller u register
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldu       GlbVar0061 load the identifier symbol pointer
                    ldd       ,u        load its type
                    cmpd      #9        is it already a label
                    lbeq      ReturnNodeInD return the existing label
                    ldd       ,u        reload its type
                    beq       InitLabelSym reuse the empty symbol
                    ldd       12,u      is the symbol name in use
                    beq       FreeOldLabelName free the old name
                    leax      MsgAlreadyLocal,pcr point to the duplicate-label message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    clra                return a null node
                    clrb                return a null node
                    puls      pc,u      return

FreeOldLabelName    pshs      u         push the symbol
                    lbsr      AllocNode free the old name string
                    leas      2,s        discard the argument
InitLabelSym        ldd       #9        label type
                    std       ,u        mark the symbol as a label
                    ldd       #13       undefined-label state
                    std       8,u       set the initial state
                    ldd       GlbVar002B load the label counter
                    addd      #1        allocate a label number
                    std       GlbVar002B bump the label counter
                    std       6,u       store the label number
                    clra                prepare a null value
                    clrb                prepare a null value
                    std       10,u      clear the label flags
                    ldd       GlbVar0051 load the current name pointer
                    std       12,u      store the label name
                    ldd       GlbVar0049 load the label list head
                    std       16,u      link into the label list
                    stu       GlbVar0049 make this the new list head
                    lbra      ReturnNodeInD return the label node

ParseExprStmt2      pshs      u         save the caller u register
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldd       4,s       load the argument node
                    pshs      d         push it
                    lbsr      ParseExpr begin parsing an expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the node
                    stu       -2,s      save it in a local
                    lbeq      ReturnNodeInD return null if empty
                    pshs      u         push the node
                    lbsr      OptExprTree parse the rest of the expression
                    std       ,s        save the expression node
                    bsr       EmitExprNode emit the expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the result node
                    lbra      ReturnNodeInD return the node

EmitExprNode        pshs      u         save the caller u register
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the expression node
                    pshs      u         push it
                    lbsr      ChkUndeclared process the expression tree
                    leas      2,s        discard the argument
                    ldx       6,u       load the node operator
                    bra       CheckRelSwap check for a relational swap

RelSwapToLess       ldd       #60       less-than operator
                    bra       StoreRelOp store it

RelSwapToLessEq     ldd       #61       less-or-equal operator
StoreRelOp          std       6,u       replace the node operator
                    bra       EmitRelNode emit the node

CheckRelSwap        cmpx      #62       is it greater-than
                    beq       RelSwapToLess swap to less-than
                    cmpx      #63       is it greater-or-equal
                    beq       RelSwapToLessEq swap to less-or-equal
EmitRelNode         pshs      u         push the node
                    lbsr      EmitStmtMode4 allocate the result node
                    leas      2,s        discard the argument
                    tfr       d,u       keep the result node
                    pshs      u         push it
                    lbsr      WalkTree  finalize and emit the expression
                    lbra      ExprReturnTail return the node

ParseParenExpr2     pshs      u         save the caller u register
                    ldd       #$FFB8    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       make room for a local
                    ldd       #45       subexpression start marker
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    bsr       ParseExpr2 parse the subexpression
                    std       ,s        save the node
                    ldd       #46       subexpression end marker
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    ldd       ,s        load the saved node
                    lbra      CondEmitDone emit and return the node

ParseExpr2          pshs      u         save the caller u register
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      ParseExpr begin parsing an expression
                    std       ,s        save the partial node
                    lbsr      OptExprTree parse the rest of the expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the node
                    stu       -2,s      save it in a local
                    beq       ExprExpectedErr error if the expression is missing
                    pshs      u         push the node
                    lbsr      ChkUndeclared process the expression tree
                    bra       ExprReturnTail return the node

ExprExpectedErr     leax      MsgConditionNeeded,pcr point to the expression-expected message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
ExprReturnTail      leas      2,s        discard the argument
ReturnNodeInD       tfr       u,d       return the node in D
                    puls      pc,u      restore u and return

EmitCondNode        pshs      u         save the caller u register
                    ldd       #$FFB4    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the target node
                    stu       -2,s      save it in a local
                    beq       CondNodeReturn return if null
                    ldd       10,s      load the third argument
                    pshs      d         push it
                    ldd       10,s      load the second argument
                    pshs      d         push it
                    ldd       10,s      load the first argument
                    pshs      d         push it
                    pshs      u         push the node
                    lbsr      EmitStmtMode2 build the three-child node
                    leas      8,s        discard the arguments
                    pshs      u         push the node
                    lbsr      WalkTree  finalize and emit the expression
CondEmitDone        leas      2,s        discard the argument
CondNodeReturn      puls      pc,u      restore u and return

MsgNoIfForElse      fcc       /no 'if' for 'else'/
                    fcb       C$NULL
MsgIllegalDecl      fcc       /illegal declaration/
                    fcb       C$NULL
MsgSyntaxError      fcc       /syntax error/
                    fcb       C$NULL
MsgMultipleDefaults fcc       /multiple defaults/
                    fcb       C$NULL
MsgNoSwitch         fcc       /no switch statement/
                    fcb       C$NULL
MsgWhileExpected    fcc       /while expected/
                    fcb       C$NULL
MsgBreakError       fcc       /break error/
                    fcb       C$NULL
MsgContinueError    fcc       /continue error/
                    fcb       C$NULL
MsgLabelRequired    fcc       /label required/
                    fcb       C$NULL
MsgAlreadyLocal     fcc       /already a local variable/
                    fcb       C$NULL
MsgConditionNeeded  fcc       /condition needed/
                    fcb       C$NULL
ParseMulExpr        pshs      u         save the caller u register
                    ldd       #$FFA2    stack space required
                    lbsr      stkcheck  check for stack overflow
                    leas      -20,s      allocate local frame
                    bra       CheckStar enter the star-check loop

StarErrLoop         leax      MsgTooManyBrackets,pcr point to the error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    lbsr      ScanToken advance to next token
CheckStar           ldd       GlbVar005F load current token
                    cmpd      #42       is it a star
                    beq       StarErrLoop loop back while star
                    ldd       GlbVar005F load current token
                    cmpd      #')       is it a close paren
                    bne       ParseOperand no, parse the operand
                    leax      MsgFuncHeaderMissing,pcr point to the error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte for zero value
                    pshs      d         push zero argument
                    lbsr      ParseBlock2 build a node
                    leas      2,s        drop the argument
                    leax      >GlbVar0049,y  point to work-area field
                    pshs      x         push field pointer
                    lbsr      EndScopeCheck emit into the node
                    leas      2,s        drop the argument
                    lbsr      ScanToken advance to next token
                    lbra      ParseMulDone jump to exit

ParseOperand        lbsr      ParsePostfixOp parse the operand subexpression
                    std       10,s      save its type
                    tfr       d,x       copy type into x for testing
                    bra       CheckOperandTok check operand token kind

IdentToken          leax      MsgStorageError,pcr point to the error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
SetDefaultType      ldd       #12       default type code
                    std       10,s      store the type
                    bra       CombineType go combine types

CheckOperandTok     cmpx      #16       is token 0010
                    beq       IdentToken handle as identifier
                    cmpx      #13       is token 000D
                    lbeq      IdentToken handle as identifier
                    stx       -2,s      save the token
                    beq       SetDefaultType zero means set default type
CombineType         leax      ,s        point to local slot
                    pshs      x         push its pointer
                    leax      6,s       point to local slot
                    pshs      x         push its pointer
                    leax      22,s      point to local slot
                    pshs      x         push its pointer
                    lbsr      ParseDeclSpec resolve and combine types
                    leas      6,s        drop three arguments
                    std       8,s       save the result
                    bne       NextOperand nonzero result, continue
                    ldd       #1        default result of one
                    std       8,s       store the result
NextOperand         ldd       4,s       load saved value
                    std       12,s      copy into slot
                    ldd       8,s       load combine result
                    pshs      d         push as argument
                    leax      14,s      point to local
                    pshs      x         push its pointer
                    leax      6,s       point to local
                    pshs      x         push its pointer
                    lbsr      ParseTypeSpec compute combined type
                    leas      6,s        drop the arguments
                    std       6,s       save combined type
                    ldu       2,s       load node pointer
                    bne       HaveNode  branch when node exists
                    ldd       6,s       load the type
                    cmpd      #4        is type four
                    beq       NoNode    accept without node
                    ldd       6,s       load the type
                    cmpd      #3        is type three
                    beq       NoNode    accept without node
                    lbsr      ErrIdentMissing report a type error
NoNode              leax      20,s      point past the locals
                    lbra      RestoreLocals go restore stack

HaveNode            ldd       6,s       load the type
                    clra                clear high byte
                    andb      #$30      mask the class bits
                    cmpd      #48       is it pointer class
                    bne       UseSavedType no, use saved type
                    ldd       GlbVar005F load current token
                    cmpd      #48       compare token 0030
                    beq       PtrOpType select pointer op
                    ldd       GlbVar005F load current token
                    cmpd      #'(       is it open paren
                    bne       PlainOpType no, plain op type
PtrOpType           ldd       #14       pointer operation type
                    bra       StoreOpType2 store the op type

PlainOpType         ldd       #12       plain operation type
                    bra       StoreOpType2 store the op type

UseSavedType        ldd       10,s      use previously saved type
StoreOpType2        std       14,s      store the operation type
                    ldd       ,u        load node first field
                    beq       InitNode2 empty node, initialise
                    ldd       ,s        load a saved value
                    pshs      d         push as argument
                    ldd       8,s       load a saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      CheckTypeMatch check type compatibility
                    leas      6,s        drop the arguments
                    std       -2,s      save the result
                    lbne      CheckLvalue nonzero, skip node fill
                    ldd       14,s      load the op type
                    cmpd      #14       is it pointer op
                    lbeq      CheckLvalue skip node fill
                    ldd       8,u       load node op field
                    cmpd      #14       is it pointer op
                    beq       FillNode  fill this node
                    ldd       8,u       load node op field
                    cmpd      #34       is it op 0022
                    beq       FillNode  fill this node
                    lbsr      ReportMsgErr report an error
                    lbra      CheckLvalue skip node fill

FillNode            ldd       14,s      load the op type
                    std       8,u       store into node op field
                    ldd       12,s      load saved value
                    std       4,u       store into node field
                    ldd       ,s        load saved value
                    std       10,u      store into node field
                    leax      20,s      point past the locals
                    bra       RestoreFromX go restore stack from x

InitNode2           ldd       6,s       load the type
                    std       ,u        store into node first field
                    clra                clear high byte
                    clrb                clear low byte
                    std       12,u      zero the node field
                    ldd       14,s      load the op type
                    std       8,u       store into node op field
                    ldd       ,s        load saved value
                    std       10,u      store into node field
                    bra       EmitBinOp go emit the operation

RestoreFromX        leas      -20,x     restore stack pointer from x
EmitBinOp           ldd       18,s      load a saved value
                    pshs      d         push as argument
                    ldd       14,s      load the op type
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      SetNodeTypeSize emit the binary operation
                    leas      6,s        drop the arguments
                    std       16,s      save the result
                    ldd       6,s       load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #48       is pointer class
                    lbeq      CheckLvalue yes, skip ahead
                    ldd       GlbVar005F load current token
                    cmpd      #120      is it subscript token
                    bne       CheckArithType no, check arithmetic
                    ldd       6,s       load the type
                    pshs      d         push as argument
                    ldd       16,s      load the result
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      ParseInitializer handle the subscript
BinOpDone           leas      6,s        drop the arguments
                    lbra      FixupOpType go fix up the op type

CheckArithType      ldd       16,s      load the result
                    bne       DispatchByOp nonzero, continue
                    ldd       14,s      load the op type
                    cmpd      #14       is it pointer op
                    beq       DispatchByOp pointer op, continue
                    lbsr      ErrCannotEvalSize report an error
                    lbra      FixupOpType go fix up the op type

DispatchByOp        ldx       14,s      load the op type into x
                    bra       OpDispatch dispatch on the op

EmitDerefOp         ldd       14,s      load the op type
                    cmpd      #35       is it indirect op
                    bne       ClearDerefFlag no, clear the flag
                    ldd       #1        set the flag
                    bra       CallDeref go call emitter

ClearDerefFlag      clra                clear high byte
                    clrb                clear low byte
CallDeref           pshs      d         push the flag argument
                    ldd       18,s      load a saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      EmitLabelSpace emit the dereference
                    bra       BinOpDone finish this operation

EmitNegOp           ldd       14,s      load the op type
                    cmpd      #33       is it op 0021
                    bne       ClearNegFlag no, clear the flag
                    ldd       #1        set the flag
                    bra       CallNeg   go call emitter

ClearNegFlag        clra                clear high byte
                    clrb                clear low byte
CallNeg             pshs      d         push the flag argument
                    ldd       18,s      load a saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      EmitLabelColon emit the operation
                    lbra      BinOpDone finish this operation

OpDispatch          cmpx      #35       is op indirect
                    beq       EmitDerefOp emit dereference
                    cmpx      #15       is op 000F
                    lbeq      EmitDerefOp emit dereference
                    cmpx      #33       is op 0021
                    beq       EmitNegOp emit negate
                    cmpx      #12       is op 000C
                    lbeq      EmitNegOp emit negate
FixupOpType         ldd       14,s      load the op type
                    cmpd      #15       is it op 000F
                    bne       CheckOp23 no, check op 0023
                    ldd       #12       map to op 000C
                    bra       StoreAdjOp store the adjusted op

CheckOp23           ldd       14,s      load the op type
                    cmpd      #35       is it op 0023
                    bne       CheckLvalue no, keep the op
                    ldd       #33       map to op 0021
StoreAdjOp          std       8,u       store adjusted op into node
CheckLvalue         ldd       6,s       load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #48       is pointer class
                    lbne      CheckContinue no, check for more
                    ldd       6,s       load the type
                    pshs      d         push as argument
                    lbsr      RemovePtrLevel dereference the type
                    leas      2,s        drop the argument
                    std       6,s       save the element type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #32       is it struct class
                    beq       IllegalLvalErr illegal, report it
                    ldd       6,s       load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #48       is pointer class
                    beq       IllegalLvalErr illegal, report it
                    ldd       6,s       load the type
                    cmpd      #4        is type four
                    beq       IllegalLvalErr illegal, report it
                    ldd       6,s       load the type
                    cmpd      #3        is type three
                    bne       CheckPtrOp2 no, valid element
IllegalLvalErr      leax      MsgFuncTypeError,pcr point to error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    ldd       #49       force type code
                    std       ,u        store into node
                    ldd       #1        default element type
                    std       6,s       store the type
CheckPtrOp2         ldd       14,s      load the op type
                    cmpd      #14       is it pointer op
                    bne       EmitLoad  no, emit a load
                    leax      >GlbVar0047,y  point to work-area field
                    pshs      x         push field pointer
                    lbsr      EndScopeCheck emit into the node
                    leas      2,s        drop the argument
                    bra       CheckContinue go check for more

EmitLoad            ldd       6,s       load the type
                    std       GlbVar004D store into the type global
                    ldd       10,s      load saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      ParseStructDecl emit the load
                    leas      4,s        drop the arguments
                    bra       ParseMulDone go to exit

                    bra       CheckContinue dead fall-through branch

RestoreLocals       leas      -20,x     restore stack pointer from x
CheckContinue       ldd       GlbVar005F load current token
                    cmpd      #48       compare token 0030
                    bne       ExpectParen not that token, expect paren
                    lbsr      ScanToken advance to next token
                    lbra      NextOperand loop for next operand

ExpectParen         ldd       #'(       open paren expected
                    pshs      d         push expected token
                    lbsr      ExpectToken require the token
                    std       ,s++      pop the argument
                    beq       ParseMulDone got it, go to exit
                    lbsr      SyncDeclarator error recovery
ParseMulDone        leas      20,s       release the locals
                    puls      pc,u      restore u and return

ParseCastExpr       pshs      u         save the caller u register
                    ldd       #$FFA4    stack space required
                    lbsr      stkcheck  check for stack overflow
                    leas      -18,s      allocate local frame
                    lbsr      ParsePostfixOp parse the subexpression
                    std       16,s      save its type
                    tfr       d,x       copy type into x
                    bra       CheckCastTok test the token

CastErr             leax      MsgArgStorage,pcr push message argument
                    pshs      x         print the error
                    lbsr      PrintErrLoc drop the argument
                    leas      2,s        default cast type
SetCastType         ldd       #13       store the type
                    std       16,s      go combine types
                    bra       CombineCastType store the token

CheckCastTok        stx       -2,s      zero means default type
                    beq       SetCastType is token 0010
                    cmpx      #16       combine types
                    beq       CombineCastType
                    bra       CastErr   otherwise cast error

CombineCastType     leax      ,s        point to local slot
                    pshs      x         push its pointer
                    leax      12,s      point to local slot
                    pshs      x         push its pointer
                    leax      12,s      point to local slot
                    pshs      x         push its pointer
                    lbsr      ParseDeclSpec resolve and combine types
                    leas      6,s        drop three arguments
                    std       14,s      save the result
                    bne       BuildCastType nonzero, continue
                    ldd       #1        default result of one
                    std       14,s      store the result
BuildCastType       ldd       10,s      load saved value
                    std       12,s      copy into slot
                    ldd       14,s      load combine result
                    pshs      d         push as argument
                    leax      14,s      point to local
                    pshs      x         push its pointer
                    leax      6,s       point to local
                    pshs      x         push its pointer
                    lbsr      ParseTypeSpec compute combined type
                    leas      6,s        drop the arguments
                    std       4,s       save combined type
                    ldu       2,s       load node pointer
                    ldd       4,s       load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #48       is pointer class
                    beq       CastTypeErr yes, illegal cast type
                    ldd       4,s       load the type
                    cmpd      #4        is type four
                    beq       CastTypeErr illegal cast type
                    ldd       4,s       load the type
                    cmpd      #10       is type 000A
                    bne       CheckStructClass no, check struct class
CastTypeErr         leax      MsgArgError,pcr point to error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    bra       CastNoNode go handle missing node

CheckStructClass    ldd       4,s       load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #32       is it struct class
                    bne       CheckType5 no, check type five
                    ldd       4,s       load the type
                    pshs      d         push as argument
                    lbsr      RemovePtrLevel dereference the type
                    std       ,s        store back
                    lbsr      AddPtrLevel get the element type
                    leas      2,s        drop the argument
                    bra       StoreCastType store the cast type

CheckType5          ldd       4,s       load the type
                    cmpd      #5        is type five
                    bne       CheckNullNode no, keep the type
                    ldd       #6        promote to type six
StoreCastType       std       4,s       store the cast type
CheckNullNode       cmpu      #0        is the node null
                    bne       EmitCast  no, emit the cast
                    lbsr      ErrIdentMissing report an error
CastNoNode          leax      18,s      point past the locals
                    lbra      RestoreDeclFrame go to exit

EmitCast            ldd       4,s       load the type
                    pshs      d         push as argument
                    ldd       18,s      load a saved value
                    pshs      d         push as argument
                    lbsr      ClassifyType2 build the cast node
                    leas      4,s        drop the arguments
                    std       6,s       save the node pointer
                    ldx       8,u       load node op field into x
                    bra       CastOpDispatch dispatch on the op

FillCastNode        ldd       4,s       load the type
                    std       ,u        store into node
                    ldd       6,s       load the node pointer
                    std       8,u       store into node op field
                    ldd       ,s        load a saved value
                    std       10,u      store into node field
                    ldd       8,s       load a saved value
                    pshs      d         push as argument
                    ldd       14,s      load the op type
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      SetNodeTypeSize emit the binary operation
                    leas      6,s        drop the arguments
                    std       -2,s      save the result
                    bne       DeclEndTokChk nonzero, done
                    lbsr      ErrCannotEvalSize report an error
                    bra       DeclEndTokChk go finish

CastLvalErr         lbsr      ReportMsgErr report an lvalue error
                    bra       DeclEndTokChk go finish

CastMsgErr          leax      MsgNotArgument,pcr point to error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    bra       DeclEndTokChk go finish

CastOpDispatch      cmpx      #11       is op 000B
                    beq       FillCastNode branch when token type $000B
                    cmpx      #13       check for token type $000D
                    beq       CastLvalErr handle the $000D case
                    cmpx      #16       check for token type $0010
                    lbeq      CastLvalErr handle $0010 like $000D
                    bra       CastMsgErr otherwise report not an argument

RestoreDeclFrame    leas      -18,x     restore stack to saved frame base
DeclEndTokChk       ldd       GlbVar005F load current token
                    cmpd      #120      check for token $0078
                    bne       DeclOpenBraceChk skip if not that token
                    lbsr      ErrCannotInit report and skip on unexpected token
DeclOpenBraceChk    ldd       GlbVar005F load current token
                    cmpd      #'0       check for open-brace token $0030
                    bne       DeclExpectClose skip if not
                    lbsr      ScanToken advance to next token
                    lbra      BuildCastType loop back to parse next declaration

DeclExpectClose     ldd       #40       expected close token $0028
                    pshs      d         push expected token argument
                    lbsr      ExpectToken match/expect the token
                    std       ,s++      store result and pop argument
                    lbeq      ParseStructExit exit if token matched
                    lbsr      SyncDeclarator consume/handle the token
                    lbra      ParseStructExit return from routine

ParseStructBody     pshs      u         save the caller u register
                    ldd       #$FF9E    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    leas      -18,s      allocate local frame
                    lbsr      ParsePostfixOp parse base type and storage class
                    std       16,s      save returned type
                    tfr       d,x       copy type into X for dispatch
                    bra       StorageClassChk enter declarator dispatch

StorageErr          leax      MsgStorageError2,pcr point to storage error message
                    pshs      x         push message pointer
                    lbsr      PrintErrLoc print the error
                    leas      2,s        pop argument
SetDefaultType2     ldd       #13       default type token $000D
                    std       16,s      store as current type
                    bra       BuildDeclarator continue building declarator

StorageClassChk     cmpx      #33       check for invalid storage token $0021
                    beq       StorageErr report storage error
                    stx       -2,s      save declarator type
                    beq       SetDefaultType2 use default if type was zero
BuildDeclarator     leax      2,s       point to type slot
                    pshs      x         push type pointer argument
                    leax      12,s      point to name buffer
                    pshs      x         push name pointer argument
                    leax      12,s      point to declarator argument
                    pshs      x         push declarator pointer argument
                    lbsr      ParseDeclSpec parse the declarator
                    leas      6,s        pop the three arguments
                    std       14,s      save declarator result
                    bne       MemberLoop continue if non-null
                    ldd       #1        default value 1
                    std       14,s      store default declarator
MemberLoop          leas      -6,s       reserve space for arguments
                    ldd       16,s      load base type
                    std       ,s        set as first argument
                    ldd       20,s      load declarator name
                    pshs      d         push name argument
                    leax      2,s       point past pushed word
                    pshs      x         push pointer argument
                    leax      14,s      point to type slot
                    pshs      x         push type pointer argument
                    lbsr      ParseTypeSpec declare and install the symbol
                    leas      6,s        pop arguments
                    std       18,s      save symbol/type result
                    ldu       10,s      load existing symbol pointer
                    bne       MemberHasSym branch if symbol already exists
                    ldd       18,s      load type result
                    cmpd      #4        check for type $0004
                    lbeq      MemberCleanup done if plain type
                    ldd       18,s      reload type result
                    cmpd      #3        check for type $0003
                    lbeq      MemberCleanup done if that type
                    lbsr      ErrIdentMissing report undefined type error
                    lbra      MemberCleanup done with member

MemberHasSym        ldd       18,s      load member type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #48       check for class $0030
                    beq       SetNewSymbol handle that storage class
                    ldd       22,s      load token/class field
                    cmpd      #14       check for token $000E
                    bne       ClassifyMember branch to redeclare handling
SetNewSymbol        ldd       ,u        load existing symbol type
                    bne       CheckRedeclType branch if already defined
                    ldd       18,s      load new type
                    std       ,u        set symbol type
                    ldd       #14       mark class $000E
                    std       8,u       store class into symbol
                    clra                zero high byte
                    clrb                zero low byte
                    std       12,u      clear symbol offset
                    ldd       8,s       load size/value
                    std       10,u      store into symbol
                    ldd       14,s      load declarator
                    pshs      d         push argument
                    ldd       2,s       load extra field
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      SetNodeTypeSize emit and record symbol
                    bra       MemberEmitDone continue after emit

CheckRedeclType     ldd       8,s       load value
                    pshs      d         push argument
                    ldd       20,s      load name
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      CheckTypeMatch check declared type matches
MemberEmitDone      leas      6,s        pop arguments
                    bra       MemberCleanup done with member

ClassifyMember      ldd       18,s      load type
                    pshs      d         push argument
                    ldd       24,s      load extra field
                    pshs      d         push argument
                    lbsr      ClassifyType2 classify the member type
                    leas      4,s        pop arguments
                    std       4,s       save classified type
                    ldd       ,u        load existing symbol type
                    beq       InstallSymbol branch if new symbol
                    ldd       12,u      load symbol scope level
                    cmpd      GlbVar0051 compare with current block level
                    bne       HideOuterSym branch if different scope
                    lbsr      ReportMsgErr report redefinition
MemberCleanup       leax      24,s      compute frame base
                    lbra      FrameRestore18 clean up stack and exit

HideOuterSym        pshs      u         push old symbol pointer
                    lbsr      AllocNode unlink outer-scope symbol
                    leas      2,s        pop argument
InstallSymbol       ldd       18,s      load type
                    std       ,u        set symbol type
                    ldd       4,s       load classified type
                    std       8,u       store class into symbol
                    ldd       8,s       load value/size
                    std       10,u      store into symbol
                    ldd       GlbVar0051 load current block level
                    std       12,u      record symbol scope
                    ldd       GlbVar004B load current symbol-list head
                    std       16,u      link previous head
                    stu       GlbVar004B make this symbol the head
                    ldd       14,s      load declarator
                    pshs      d         push argument
                    ldd       2,s       load extra field
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      SetNodeTypeSize emit and record symbol
                    leas      6,s        pop arguments
                    std       2,s       save emit result
                    bne       LoadClassType branch if success
                    ldd       GlbVar005F load current token
                    cmpd      #120      check for token $0078
                    beq       LoadClassType skip error if match
                    lbsr      ErrCannotEvalSize report emit error
LoadClassType       ldx       4,s       load classified type into X
                    bra       OffsetTypeChk dispatch on member type

StructOffsetAdj     ldd       GlbVar0031 load current struct offset
                    subd      2,s       subtract member size
                    std       GlbVar0031 update struct offset
                    ldd       GlbVar0031 reload offset value
                    bra       StoreSymOffset store as symbol offset

BumpFieldCount      ldd       GlbVar002B load field counter
                    addd      #1        increment counter
                    std       GlbVar002B update field counter
StoreSymOffset      std       6,u       store offset into symbol
                    bra       TypedefCtxChk continue after offset

OffsetTypeChk       cmpx      #13       check for type $000D
                    beq       StructOffsetAdj handle struct-member offset
                    cmpx      #35       check for type $0023
                    beq       BumpFieldCount handle enum counter
                    cmpx      #15       check for type $000F
                    lbeq      BumpFieldCount handle like $0023
TypedefCtxChk       ldd       GlbVar005F load current token
                    cmpd      #120      check for token $0078
                    lbne      ClassDispatch branch if not typedef context
                    ldd       4,s       load classified class
                    cmpd      #15       check for class $000F
                    beq       RegisterTypedef handle typedef
                    ldd       4,s       reload class
                    cmpd      #35       check for class $0023
                    bne       PtrMemberAlloc branch if not
RegisterTypedef     ldd       18,s      load type
                    pshs      d         push argument
                    ldd       6,s       load symbol offset
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      ParseInitializer register the typedef
ArgPopContinue      leas      6,s        pop arguments
                    lbra      NextMemberChk continue after typedef

PtrMemberAlloc      lbsr      ScanToken advance to next token
                    ldd       18,s      load type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #32       check for class $0020
                    lbeq      MemberErr2 report on invalid class
                    ldd       18,s      reload type
                    cmpd      #4        check for type $0004
                    lbeq      MemberErr2 report error on that type
                    ldd       #2        allocate 2 bytes
                    pshs      d         push size argument
                    lbsr      ParseExpr allocate a node
                    leas      2,s        pop argument
                    std       12,s      save node pointer
                    beq       MemberErr2 error if allocation failed
                    ldd       GlbVar0009 load free-list head
                    beq       AllocNode2 branch if free list empty
                    ldd       GlbVar0009 reload free head
                    std       6,s       save reused node pointer
                    tfr       d,x       node into X
                    ldd       ,x        load next link
                    std       GlbVar0009 advance the free list
                    clra                zero high byte
                    clrb                zero low byte
                    std       [6,s]     clear the node link
                    bra       LinkNode2 continue with node

AllocNode2          ldd       #6        request 6-byte node
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate the node
                    leas      2,s        pop argument
                    std       6,s       save node pointer
LinkNode2           ldd       12,s      load data pointer
                    ldx       6,s       load node pointer
                    std       2,x       store data into node
                    ldx       6,s       reload node pointer
                    stu       4,x       store symbol pointer into node
                    ldd       GlbVar0005 load list tail
                    beq       SetListHead branch if list empty
                    ldd       6,s       load node pointer
                    std       [>GlbVar0007,y] link node onto tail
                    bra       SetListTail continue

SetListHead         ldd       6,s       load node pointer
                    std       GlbVar0005 set list head
SetListTail         ldd       6,s       load node pointer
                    std       GlbVar0007 set list tail
                    bra       NextMemberChk continue after link

MemberErr2          lbsr      ErrCannotInit report and skip on error
                    bra       NextMemberChk continue after error

ClassDispatch       ldx       4,s       load class into X
                    bra       EnumClassChk dispatch on class

RecordEnumMember    ldd       4,s       load class
                    cmpd      #35       check for class $0023
                    bne       ZeroEnumFlag branch if not
                    ldd       #1        flag value 1
                    bra       PushEnumArgs use the flag

ZeroEnumFlag        clra                zero high byte
                    clrb                zero flag value
PushEnumArgs        pshs      d         push flag argument
                    ldd       4,s       load class
                    pshs      d         push class argument
                    ldd       6,u       load symbol offset
                    pshs      d         push offset argument
                    lbsr      EmitRmbVar record enum member
                    lbra      ArgPopContinue continue after record

EnumClassChk        cmpx      #15       check for class $000F
                    beq       RecordEnumMember handle enum member
                    cmpx      #35       check for class $0023
                    lbeq      RecordEnumMember handle enum member
                    bra       NextMemberChk otherwise continue

FrameRestore18      leas      -24,x     restore stack to frame base
NextMemberChk       ldd       GlbVar005F load current token
                    cmpd      #'0       check for open-brace $0030
                    beq       AdvanceNextMember loop for another member
                    leas      6,s        pop locals
                    bra       ExpectCloseBrace finish the declaration

AdvanceNextMember   lbsr      ScanToken advance to next token
                    leas      6,s        pop locals
                    lbra      MemberLoop parse the next member

ExpectCloseBrace    ldd       #40       expected close token $0028
                    pshs      d         push expected token
                    lbsr      ExpectToken match/expect the token
                    leas      2,s        pop argument
ParseStructExit     leas      18,s       release local frame
                    puls      pc,u      restore u and return

CheckTypeMatch      pshs      u         save the caller u register
                    ldd       #$FFBA    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    ldu       4,s       load symbol pointer argument
                    ldd       ,u        load existing type
                    cmpd      6,s       compare with new type
                    bne       DeclMismatchErr mismatch if different
                    ldd       6,s       load new type
                    cmpd      #4        check for type $0004
                    bne       TypeMatchOk match if not $0004
                    ldd       10,u      load existing size
                    cmpd      8,s       compare with new size
                    beq       TypeMatchOk match if sizes equal
DeclMismatchErr     leax      MsgDeclMismatch,pcr point to declaration mismatch message
                    pshs      x         push message pointer
                    lbsr      PrintErrLoc print the error
                    leas      2,s        pop argument
                    ldd       #1        return mismatch flag 1
                    puls      pc,u      restore u and return

TypeMatchOk         clra                zero high byte
                    clrb                return 0 for match
                    puls      pc,u      restore u and return

ClassifyType2       pshs      u         save the caller u register
                    ldd       #$FFC0    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    ldd       4,s       load type argument
                    cmpd      #16       check for type $0010
                    bne       RetInputType branch if not $0010
                    ldd       GlbVar0003 load nesting depth
                    cmpd      #1        compare with one
                    bge       RetTypeCR branch if already nested
                    ldx       6,s       load class argument into X
                    bra       NestClassChk dispatch on class

ClassBitsChk        ldd       6,s       load class
                    clra                clear high byte
                    andb      #$30      isolate class bits
                    cmpd      #16       check for class $0010
                    bne       RetTypeCR branch if not
IncNestDepth        ldd       GlbVar0003 load nesting depth
                    addd      #1        increment depth
                    std       GlbVar0003 update nesting depth
                    cmpd      #1        compare with one
                    bne       NestTokenAlt branch if deeper
                    ldd       #111      return token $006F
                    bra       ClassifyRet go return it

NestTokenAlt        ldd       #118      return token $0076
ClassifyRet         puls      pc,u      restore u and return

NestClassChk        cmpx      #1        check for class $0001
                    beq       IncNestDepth handle nesting
                    cmpx      #7        check for class $0007
                    lbeq      IncNestDepth handle nesting
                    bra       ClassBitsChk otherwise test class bits

RetTypeCR           ldd       #13       return type token $000D
                    puls      pc,u      restore u and return

RetInputType        ldd       4,s       return input type unchanged
                    puls      pc,u      restore u and return

ParseStructDecl     pshs      u         save the caller u register
                    ldd       #$FFAC    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    leas      -10,s      allocate local frame
                    ldd       #1        initial block level 1
                    std       GlbVar0051 reset current block level
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar002F clear global counter
                    std       GlbVar003B clear global counter
                    std       GlbVar0031 clear struct offset
                    std       GlbVar0003 clear nesting depth
                    std       GlbVar0033 clear global flag
                    bra       StructMemberChk enter member loop

StructMemberLoop    lbsr      ParseCastExpr parse one struct member
StructMemberChk     ldd       GlbVar005F load current token
                    cmpd      #')       check for close-paren $0029
                    bne       StructMemberLoop keep parsing until close
                    ldd       14,s      load aggregate size field
                    addd      #20       add offset of 20
                    std       2,s       save pointer
                    ldd       GlbVar0037 load aggregate flag
                    beq       SetAggFlag skip if flag not set
                    ldd       GlbVar002B load member count
                    addd      #1        increment count
                    std       GlbVar002B update member count
                    std       ,s        save count
                    pshs      d         push argument
                    ldd       4,s       load extra field
                    pshs      d         push argument
                    lbsr      EmitPublicLabel record aggregate size
                    leas      4,s        pop arguments
SetAggFlag          ldd       ,s        load saved value
                    pshs      d         push argument
                    ldd       18,s      load aggregate type
                    cmpd      #15       check for type $000F
                    beq       UnionFlagZero branch if union
                    ldd       #1        flag 1 for struct
                    bra       FinalizeAgg use the flag

UnionFlagZero       clra                zero high byte
                    clrb                zero flag for union
FinalizeAgg         pshs      d         push flag argument
                    ldd       6,s       load extra field
                    pshs      d         push argument
                    lbsr      EmitStaticSym finalize aggregate type
                    leas      6,s        pop arguments
                    ldu       GlbVar0047 load member list head
                    ldd       #4        initial running size 4
                    std       8,s       save running size
                    lbra      FieldOffsetLoop enter member sizing loop

SizeMemberLoop      leas      -2,s       reserve temp slot
                    ldd       10,s      load running offset
                    std       6,u       store member offset
                    ldx       ,u        load member type
                    bra       MemberTypeChk dispatch on member type

MemberSize4         ldd       #4        size 4 bytes
                    bra       StoreMemberSize set member size

MemberSize8         ldd       #8        size 8 bytes
                    bra       StoreMemberSize set member size

BitfieldOffset      ldd       6,u       load member offset
                    addd      #1        increment offset
                    std       6,u       update member offset
MemberSize2         ldd       #2        size 2 bytes
StoreMemberSize     std       ,s        save member size
                    bra       LoadSubtype continue after size

MemberTypeChk       cmpx      #8        check for type $0008
                    beq       MemberSize4 size as 4 bytes
                    cmpx      #5        check for type $0005
                    lbeq      MemberSize4 size as 4 bytes
                    cmpx      #6        check for type $0006
                    beq       MemberSize8 size as 8 bytes
                    cmpx      #2        check for type $0002
                    beq       BitfieldOffset handle bitfield offset case
                    bra       MemberSize2 default size 2 bytes

LoadSubtype         ldd       8,u       load member subtype
                    std       8,s       save subtype
                    tfr       d,x       subtype into X
                    bra       MatchTypeKw dispatch on subtype

ComputeNestedSize   ldd       10,s      load argument
                    pshs      d         push argument
                    ldd       10,s      load argument
                    pshs      d         push argument
                    lbsr      EmitOpCode compute nested aggregate size
                    leas      4,s        pop arguments
                    bra       AddFieldOffset continue after size

SubtypeCR           ldd       #13       default subtype token $000D
                    std       8,u       store member subtype
                    bra       AddFieldOffset jump into the offset accumulation

MatchTypeKw         cmpx      #111      compare token against type keyword $6f
                    beq       ComputeNestedSize matched, go handle it
                    cmpx      #118      compare token against type keyword $76
                    lbeq      ComputeNestedSize matched, go handle it
                    cmpx      #11       compare token against type code $0b
                    beq       SubtypeCR matched, go handle it
AddFieldOffset      ldd       10,s      load the accumulated offset
                    addd      ,s        add the current field size
                    std       10,s      store the updated offset
                    ldu       16,u      follow the link to the next entry
                    leas      2,s        drop the temporary
FieldOffsetLoop     stu       -2,s      save the next entry pointer
                    lbne      SizeMemberLoop loop while more entries remain
                    ldd       GlbVar0047 load the saved global
                    std       4,s       stash it in a local
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar0047 clear the global
                    lbsr      ParseBlock2 parse the block body
                    leax      4,s       point at the saved value
                    pshs      x         pass it as an argument
                    lbsr      EndScopeCheck free/restore it
                    leas      2,s        drop the argument
                    leax      >GlbVar0049,y  point at global $0049
                    pshs      x         pass it as an argument
                    lbsr      EndScopeCheck free/restore it
                    leas      2,s        drop the argument
                    ldd       GlbVar004F load the current context type
                    cmpd      #18       is it type $12
                    beq       ResetContextType skip the emit if so
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       #18       push type code $12
                    pshs      d         push it as argument
                    lbsr      EmitOpCode emit the type record
                    leas      6,s        drop the arguments
ResetContextType    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004F reset the context type
                    lbsr      EmitEndMarker finalise pending output
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar0051 reset the block nesting level
                    ldd       GlbVar005F load the current token
                    cmpd      #$FFFF    is it end of file
                    bne       GetTokenDone no, continue normally
                    leax      MsgFuncUnfinished,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop the argument
GetTokenDone        lbsr      ScanToken get the next token
                    leas      10,s       release the locals
                    puls      pc,u      return to caller

ParseBlock2         pshs      u         save the caller u register
                    ldd       #$FFAA    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -6,s       allocate the locals
                    ldd       GlbVar004B load the current global
                    std       2,s       save it in a local
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004B clear the global
                    lbsr      ScanToken get the next token
                    ldd       GlbVar0051 load the block nesting level
                    addd      #1        increment it
                    std       GlbVar0051 store deeper nesting level
                    ldd       GlbVar0031 load the current frame offset
                    std       ,s        save the base offset
                    bra       StmtLoopTop enter the statement loop

StmtLoop2           lbsr      ParseStructBody parse a statement
StmtLoopTop         lbsr      IsQualifierKw parse a declaration
                    std       -2,s      save the result
                    bne       StmtLoop2 loop if one was parsed
                    lbsr      ClassifyType parse a statement
                    std       -2,s      save the result
                    lbne      StmtLoop2 loop if one was parsed
                    ldd       GlbVar003B load the recorded max offset
                    cmpd      GlbVar0031 compare with the current offset
                    ble       KeepMaxOffset keep max if already larger
                    ldd       GlbVar0031 take the current offset
                    std       GlbVar003B as the new maximum
KeepMaxOffset       ldd       GlbVar0031 load the current offset
                    pshs      d         pass it as argument
                    lbsr      EmitLabelOffset restore the enclosing scope
                    leas      2,s        drop the argument
                    std       GlbVar002F store the resulting offset
                    lbra      LocalListTop go free the local list

FreeLocalLoop       ldd       GlbVar0005 load the local list head
                    std       4,s       save it in a local
                    ldx       4,s       point at the entry
                    ldu       2,x       follow the entry link
                    ldd       16,u      load a node field
                    pshs      d         push it as argument
                    ldd       14,u      load a node field
                    pshs      d         push it as argument
                    ldx       8,s       point at the saved entry
                    ldd       4,x       load its field
                    pshs      d         push it as argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       #52       push node type $34
                    pshs      d         push it as argument
                    lbsr      NewExprNode build a tree node
                    leas      12,s       drop the arguments
                    tfr       d,u       keep the node pointer
                    ldd       16,u      load a node field
                    pshs      d         push it as argument
                    ldd       14,u      load a node field
                    pshs      d         push it as argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldx       10,s      point at the saved entry
                    ldd       2,x       load its field
                    pshs      d         push it as argument
                    pshs      u         push the node pointer
                    ldd       #120      push node type $78
                    pshs      d         push it as argument
                    lbsr      NewExprNode build a tree node
                    leas      12,s       drop the arguments
                    tfr       d,u       keep the node pointer
                    pshs      u         push the node pointer
                    lbsr      OptExprTree transform the node
                    std       ,s        replace argument with result
                    lbsr      EmitStmtMode4 further transform the node
                    std       ,s        replace argument with result
                    lbsr      WalkTree  emit code for the node
                    leas      2,s        drop the argument
                    ldd       [4,s]     load the next list link
                    std       4,s       save it in a local
                    ldd       GlbVar0009 load a global value
                    std       [>GlbVar0005,y] store it into the entry
                    ldd       GlbVar0005 load the list head
                    std       GlbVar0009 save it in the global
                    ldd       4,s       reload the next link
                    std       GlbVar0005 advance the list head
LocalListTop        ldd       GlbVar0005 is the local list nonempty
                    lbne      FreeLocalLoop loop for the next local
                    bra       SkipToBraceTop list drained, continue

SkipToBrace         lbsr      ParseStatement skip a stray construct
SkipToBraceTop      ldd       GlbVar005F load the current token
                    cmpd      #'*       is it a close brace
                    beq       RestoreScope done if so
                    ldd       GlbVar005F reload the token
                    cmpd      #$FFFF    is it end of file
                    bne       SkipToBrace keep skipping until then
RestoreScope        leax      >GlbVar004B,y  point at global $004b
                    pshs      x         pass it as argument
                    lbsr      EndScopeCheck free/restore it
                    leas      2,s        drop the argument
                    ldd       2,s       load the saved global value
                    std       GlbVar004B restore the global
                    ldd       GlbVar0051 load the block nesting level
                    addd      #$FFFF    decrement it
                    std       GlbVar0051 store shallower nesting level
                    ldd       ,s        load the saved base offset
                    std       GlbVar0031 restore the current offset
                    ldd       GlbVar004F load the context type
                    cmpd      #18       is it type $12
                    beq       KeepOffset keep the offset directly
                    ldd       ,s        load the saved offset
                    pshs      d         pass it as argument
                    lbsr      EmitLabelOffset restore the enclosing scope
                    leas      2,s        drop the argument
                    bra       SetFinalOffset continue

KeepOffset          ldd       ,s        load the saved offset
SetFinalOffset      std       GlbVar002F store the final offset
                    leas      6,s        release the locals
                    puls      pc,u      return to caller

ParseIdentList      pshs      u         save the caller u register
                    ldd       #$FFB8    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate the local
                    clra                zero high byte
                    clrb                zero low byte
                    std       [6,s]     clear the caller's list pointer
IdentLoop           lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #'.       is it a semicolon
                    lbeq      ExpectSemi2 end of the list
                    ldd       GlbVar005F reload the token
                    cmpd      #52       is it an identifier
                    bne       ParseMemberDecl not identifier, parse member
                    ldu       GlbVar0061 load the symbol pointer
                    ldd       8,u       load its type field
                    cmpd      #11       is it type $0b
                    bne       CheckRedefine no, check for redefinition
                    leax      MsgNamedTwice,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the error
                    bra       PopErrArg skip the redefinition path

CheckRedefine       ldd       ,u        is the symbol already defined
                    beq       InitIdentSym no, initialise it
                    pshs      u         push the symbol pointer
                    lbsr      AllocNode report the redefinition
PopErrArg           leas      2,s        drop the argument
InitIdentSym        ldd       #1        mark the symbol defined
                    std       ,u        store the flag
                    ldd       #11       set type code $0b
                    std       8,u       store it in the symbol
                    ldd       #1        set field value 1
                    std       12,u      store it in the symbol
                    ldd       #2        set storage class 2
                    std       2,u       store it in the symbol
                    ldd       [6,s]     load the current list head
                    beq       SetListHead2 empty, set first node
                    ldx       ,s        point at the last node
                    stu       16,x      link the new node in
                    bra       LinkDone2 skip the head assignment

SetListHead2        stu       [6,s]     store node as the list head
LinkDone2           clra                zero high byte
                    clrb                zero low byte
                    std       16,u      clear the node link
                    stu       ,s        remember node as last
                    lbsr      ScanToken get the next token
                    bra       CheckComma go check for a comma

ParseMemberDecl     lbsr      ErrIdentMissing parse a member declaration
CheckComma          ldd       GlbVar005F load the current token
                    cmpd      #'0       is it a comma
                    lbeq      IdentLoop loop for the next member
ExpectSemi2         ldd       #'.       expect a semicolon
                    pshs      d         pass it as argument
                    lbsr      ExpectToken require the token
                    leas      2,s        drop the argument
                    bra       EpilogueDrop2 return via shared epilogue

ParsePostfixOp      pshs      u         save the caller u register
                    ldd       #$FFBA    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate the local
                    lbsr      IsQualifierKw parse a declarator
                    std       -2,s      save the result
                    beq       ReturnZero none, return zero
                    ldd       GlbVar0061 load the token value
                    std       ,s        save the node
                    lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #51       is it operator token $33
                    bne       ReturnNode no, return the node
                    ldd       GlbVar0061 load the token value
                    cmpd      #33       is it keyword $21
                    bne       ReturnNode no, return the node
                    ldx       ,s        load the saved node
                    bra       CheckNodeKind go inspect its kind

UseOp23             ldd       #35       choose operator code $23
                    bra       StoreOp   store it

UseOp22             ldd       #34       choose operator code $22
StoreOp             std       ,s        store the chosen operator
                    bra       AdvanceOp consume the operator token

CheckNodeKind       cmpx      #15       is the node kind $0f
                    beq       UseOp23   use operator $23
                    cmpx      #14       is the node kind $0e
                    beq       UseOp22   use operator $22
AdvanceOp           lbsr      ScanToken consume the operator token
ReturnNode          ldd       ,s        load the result node
                    bra       EpilogueDrop2 return it

ReturnZero          clra                zero high byte
                    clrb                zero low byte
EpilogueDrop2       leas      2,s        release the local
                    puls      pc,u      return to caller

ParseDeclSpec       pshs      u         save the caller u register
                    ldd       #$FF98    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -26,s      allocate the locals
                    clra                zero high byte
                    clrb                zero low byte
                    std       2,s       clear the type field
                    ldd       #2        default storage class 2
                    std       ,s        store it
                    clra                zero high byte
                    clrb                zero low byte
                    std       [34,s]    clear the caller's output pointer
                    ldd       GlbVar005F load the current token
                    cmpd      #51       is it keyword token $33
                    lbne      TryTypedefName no, handle elsewhere
                    ldd       GlbVar0061 load the token value
                    std       2,s       save it as the type
                    tfr       d,x       copy it into index register
                    lbra      TokenTypeDispatch jump into the specifier handling

SpecClass1          ldd       #1        select storage class 1
                    std       2,s       store it
SpecLoop            lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #51       is it keyword token $33
                    lbne      ReturnNoType no, specifiers done
                    ldd       GlbVar0061 load the token value
                    cmpd      #1        is it keyword $01
                    lbne      ReturnNoType no, specifiers done
                    bra       NextSpecTok consume it as a specifier

SpecBaseInt         ldd       #1        select base type 1
                    bra       SetBaseType store it

SpecTypedef         lbsr      ScanToken get the next token
                    ldd       #4        select base type 4
                    std       ,s        store it
                    ldd       GlbVar005F load the current token
                    cmpd      #51       is it keyword token $33
                    lbne      ReturnNoType no, specifiers done
                    ldd       GlbVar0061 load the token value
                    cmpd      #1        is it keyword $01
                    beq       NextSpecTok consume it as a specifier
                    ldd       GlbVar0061 reload the token value
                    cmpd      #5        is it keyword $05
                    lbne      ReturnNoType no, specifiers done
SpecLong            ldd       #6        set modifier code $06
                    std       2,s       store the type modifier
                    ldd       #8        select base type 8 for long
                    bra       SetBaseType store it

SpecBase4           ldd       #4        select base type 4
SetBaseType         std       ,s        store the base type
NextSpecTok         lbsr      ScanToken get the next token
                    lbra      ReturnNoType continue the specifier loop

SpecVoid            clra                zero high byte
                    clrb                zero low byte
                    std       2,s       clear the type for void
                    lbra      ReturnNoType continue the specifier loop

ParseStructSpec     clra                zero high byte
                    clrb                zero low byte
                    std       22,s      clear the struct pointer
                    std       ,s        clear the base type
                    ldd       GlbVar0041 load the lookup-suppress flag
                    addd      #1        increment it
                    std       GlbVar0041 suppress ordinary lookup
                    clra                zero high byte
                    clrb                zero low byte
                    std       24,s      clear the tag symbol
                    lbsr      ScanToken get the next token
                    ldd       GlbVar0041 reload the flag
                    addd      #$FFFF    decrement it
                    std       GlbVar0041 restore ordinary lookup
                    ldd       GlbVar005F load the current token
                    cmpd      #52       is it an identifier
                    lbne      ExpectBrace no tag, expect a brace
                    ldd       GlbVar0061 load the symbol pointer
                    std       24,s      save it as the tag symbol
                    ldd       [24,s]    load its defined flag
                    bne       CheckTagType already known tag
                    ldd       #10       mark the tag defined
                    std       [24,s]    store the flag
                    ldd       #8        struct type code $08
                    ldx       24,s      point at the tag symbol
                    std       8,x       set its type field
                    bra       TagBodyOrRef go parse the body or reference

CheckTagType        ldx       24,s      point at the tag symbol
                    ldd       8,x       load its existing type
                    cmpd      #8        is it a struct type
                    beq       TagBodyOrRef ok, continue
                    leax      MsgNameClash,pcr point at the conflict message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the tag conflict
                    leas      2,s        drop the argument
TagBodyOrRef        lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #')       is it an open brace
                    beq       CheckComplete yes, parse the body
                    ldd       [24,s]    load the tag state
                    cmpd      #4        is it a complete type
                    bne       ReturnTagRef no, return a tag reference
                    ldx       24,s      point at the tag symbol
                    ldd       2,x       load its member list
                    std       [30,s]    return via the output pointer
                    ldx       24,s      point at the tag symbol
                    ldd       10,x      load its size
                    std       [34,s]    return via the output pointer
                    ldd       #4        result type code $04
                    lbra      ReturnType2 return the result

ReturnTagRef        ldd       24,s      load the tag symbol
                    std       [30,s]    return via the output pointer
                    ldd       #10       result type code $0a
                    lbra      ReturnType2 return the result

CheckComplete       ldd       [24,s]    load the tag state
                    cmpd      #4        is it already complete
                    bne       ExpectBrace no, parse the body
                    lbsr      ReportMsgErr report the tag redefinition
ExpectBrace         ldd       GlbVar005F load the current token
                    cmpd      #')       is it an open brace
                    beq       EnterStructBody yes, parse the members
                    leax      MsgStructSyntax,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the missing brace
                    leas      2,s        drop the argument
                    lbra      ReturnNoType return through the loop tail

EnterStructBody     ldd       GlbVar0041 load the lookup-suppress flag
                    addd      #1        increment it
                    std       GlbVar0041 enter the member scope
MemberLoop2         ldd       GlbVar0041 reload the flag
                    std       16,s      save it in a local
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar0041 clear the flag for lookup
                    lbsr      ScanToken get the next token
                    ldd       16,s      reload the saved flag
                    std       GlbVar0041 restore the flag
                    ldd       GlbVar005F load the current token
                    cmpd      #'*       is it a close brace
                    lbeq      CloseTypeScope end of the member list
                    leax      4,s       point at a local
                    pshs      x         pass it as argument
                    leax      14,s      point at a local
                    pshs      x         pass it as argument
                    leax      24,s      point at a local
                    pshs      x         pass it as argument
                    lbsr      ParseDeclSpec recurse to parse the member type
                    leas      6,s        drop the arguments
                    std       18,s      save the member type
                    bra       MemberNext process the member

MemberNext          leas      -4,s       allocate a temporary
                    ldd       16,s      load the saved flag
                    std       2,s       save it in a local
                    ldd       GlbVar005F load the current token
                    cmpd      #40       is it token $28
                    lbeq      DropTagLocals handle it specially
                    ldd       GlbVar0051 load the block nesting level
                    addd      #1        increment it
                    std       GlbVar0051 store deeper nesting level
                    ldd       22,s      load a member field
                    pshs      d         push it as argument
                    leax      4,s       point at a local
                    pshs      x         pass it as argument
                    leax      4,s       point to local argument slot
                    pshs      x         pass pointer argument
                    lbsr      ParseTypeSpec parse the struct/union type specifier
                    leas      6,s        drop the pushed arguments
                    std       18,s      save the returned type
                    ldu       ,s        reload the tag entry pointer
                    ldd       GlbVar0051 load the current nesting level
                    addd      #$FFFF    decrement the nesting level
                    std       GlbVar0051 store the nesting level
                    cmpu      #0        test the tag entry pointer for null
                    bne       CheckExistingTag branch if a tag entry exists
                    lbsr      ErrIdentMissing handle the missing tag entry
                    leax      30,s      compute the stack cleanup pointer
                    lbra      RestoreStackX jump to restore the stack

CheckExistingTag    ldd       ,u        load the first tag entry field
                    beq       FillTagEntry branch if the slot is empty
                    ldd       12,u      load the entry nesting level
                    cmpd      GlbVar0051 compare with the current level
                    bne       FreeOldTag branch if a different scope
                    ldd       ,u        load the entry type
                    cmpd      18,s      compare with the parsed type
                    bne       TagRedefinedErr branch on redefinition mismatch
                    ldd       8,u       load the entry kind field
                    cmpd      #17       compare with the struct kind
                    bne       TagRedefinedErr branch if kind mismatch
                    ldd       6,u       load the entry tag id
                    cmpd      26,s      compare with the current tag id
                    beq       FillTagEntry branch if the same tag is reused
TagRedefinedErr     leax      MsgStructMemberMismatch,pcr point to the redefinition message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc print the error message
                    bra       AfterTagError continue after the error

FreeOldTag          pshs      u         pass the old entry pointer
                    lbsr      AllocNode free the old tag entry
AfterTagError       leas      2,s        drop the pushed argument
FillTagEntry        ldd       18,s      load the parsed type
                    cmpd      #10       compare with the enum type
                    bne       StoreTagFields branch if not an enum
                    leax      MsgUndefStructure,pcr point to the warning message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc print the message
                    leas      2,s        drop the argument
StoreTagFields      ldd       18,s      load the parsed type
                    std       ,u        store the type in the entry
                    ldd       #17       load the struct kind constant
                    std       8,u       set the entry kind field
                    ldd       26,s      load the tag id
                    std       6,u       store the tag id in the entry
                    ldd       8,s       load the member list pointer
                    std       10,u      store the member list in the entry
                    ldd       24,s      load the layout argument
                    pshs      d         push the argument
                    ldd       4,s       load the layout argument
                    pshs      d         push the argument
                    pshs      u         push the entry pointer
                    lbsr      SetNodeTypeSize compute the member layout size
                    leas      6,s        drop the arguments
                    std       14,s      save the returned size
                    beq       EmptyTagBody branch if zero size
                    ldd       6,s       load the member class
                    cmpd      #4        compare with the union class
                    bne       MaxMemberSize branch if not a union
                    ldd       26,s      load the current offset
                    addd      14,s      add the member size
                    std       26,s      update the offset
                    bra       StoreMemberSize2 go store the size

MaxMemberSize       ldd       14,s      load the member size
                    cmpd      4,s       compare with the running maximum
                    ble       KeepCurMax branch if not larger
                    ldd       14,s      take the member size
                    bra       StoreMemberSize2 store it as the new maximum

KeepCurMax          ldd       4,s       keep the current maximum
StoreMemberSize2    std       4,s       store the size or maximum
                    bra       LinkTagEntry continue

EmptyTagBody        lbsr      ErrCannotEvalSize handle the empty member body
LinkTagEntry        ldd       GlbVar0051 load the nesting level
                    std       12,u      store the level in the entry
                    ldd       GlbVar004B load the symbol list head
                    std       16,u      chain it into the entry
                    stu       GlbVar004B make the entry the new list head
                    ldd       6,s       load the member class
                    cmpd      #4        compare with the union class
                    bne       AfterTagBody branch if not a union
                    ldd       #4        allocation size for a node
                    pshs      d         push the size
                    lbsr      AllocMem  allocate a list node
                    leas      2,s        drop the argument
                    std       12,s      save the node pointer
                    ldx       12,s      reload the node pointer
                    stu       2,x       store the entry in the node
                    ldd       [38,s]    load the list head indirectly
                    beq       SetUnionHead branch if the list is empty
                    ldd       12,s      load the node pointer
                    std       [10,s]    append the node to the tail
                    bra       UpdateUnionTail continue

SetUnionHead        ldd       12,s      load the node pointer
                    std       [38,s]    set the list head
UpdateUnionTail     ldd       12,s      load the node pointer
                    std       10,s      update the tail pointer
                    bra       AfterTagBody continue

RestoreStackX       leas      -30,x     restore the stack from the pointer
AfterTagBody        ldd       GlbVar005F load the current token
                    cmpd      #'0       compare with the comma token
                    beq       NextDeclarator branch if a comma follows
DropTagLocals       leas      4,s        drop the tag locals
                    bra       CheckDeclEnd continue

NextDeclarator      lbsr      ScanToken advance to the next token
                    leas      4,s        drop the tag locals
                    lbra      MemberNext loop for the next declarator

CheckDeclEnd        ldd       GlbVar005F load the current token
                    cmpd      #'(       compare with the semicolon token
                    lbeq      MemberLoop2 loop if the declaration ends
CloseTypeScope      ldd       GlbVar0041 load the scope counter
                    addd      #$FFFF    decrement the scope counter
                    std       GlbVar0041 store the counter
                    ldd       24,s      load the list pointer
                    beq       EmitTypeEnd branch if null
                    ldd       ,s        load the value to store
                    ldx       24,s      load the list pointer
                    std       2,x       store the field
                    ldd       #4        load the type constant
                    std       [24,s]    store the type indirectly
                    ldd       [34,s]    load the field value
                    ldx       24,s      load the list pointer
                    std       10,x      store the field
EmitTypeEnd         ldd       #42       load the closing type opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the instruction
                    leas      2,s        drop the argument
                    bra       ReturnNoType go return the type

TokenTypeDispatch   cmpx      #10       compare the token subtype
                    lbeq      SpecClass1 dispatch to the handler
                    cmpx      #7        compare the token subtype
                    lbeq      SpecLoop  dispatch to the handler
                    cmpx      #2        compare the token subtype
                    lbeq      SpecBaseInt dispatch to the handler
                    cmpx      #1        compare the token subtype
                    lbeq      NextSpecTok dispatch to the handler
                    cmpx      #8        compare the token subtype
                    lbeq      SpecTypedef dispatch to the handler
                    cmpx      #6        compare the token subtype
                    lbeq      SpecLong  dispatch to the handler
                    cmpx      #5        compare the token subtype
                    lbeq      SpecBase4 dispatch to the handler
                    cmpx      #3        compare the token subtype
                    lbeq      ParseStructSpec dispatch to the handler
                    cmpx      #4        compare the token subtype
                    lbeq      ParseStructSpec dispatch to the handler
                    lbra      SpecVoid  take the default case

TryTypedefName      ldd       GlbVar005F load the current token
                    cmpd      #52       compare with the identifier token
                    bne       ReturnNoType branch if not an identifier
                    ldu       GlbVar0061 load the token symbol pointer
                    ldd       8,u       load the symbol kind
                    cmpd      #_start   compare with the typedef marker
                    bne       ReturnNoType branch if not a typedef
                    ldd       2,u       load the typedef type
                    std       [30,s]    return the type indirectly
                    ldd       4,u       load the typedef field
                    std       [32,s]    return the field indirectly
                    ldd       10,u      load the typedef size
                    std       [34,s]    return the size indirectly
                    lbsr      ScanToken advance to the next token
                    ldd       ,u        load the symbol value
                    bra       ReturnType2 go return the type

ReturnNoType        ldd       ,s        load the result value
                    std       [30,s]    return the type indirectly
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       [32,s]    clear the field return
                    ldd       2,s       load the result value
ReturnType2         leas      26,s       deallocate the frame
                    puls      pc,u      restore and return

ParseTypeSpec       pshs      u         save the u register
                    ldd       #$FFAA    load the frame size
                    lbsr      stkcheck  check the stack space
                    leas      -12,s      allocate the local frame
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       [16,s]    clear the output type
                    std       10,s      clear the flags accumulator
                    bra       TypeSpecLoop enter the type loop

MergeQualifier      ldd       10,s      load the type flags
                    pshs      d         push the flags
                    lbsr      AddPtrLevel merge the qualifier
                    leas      2,s        drop the argument
                    std       10,s      store the updated flags
                    lbsr      ScanToken advance to the next token
TypeSpecLoop        ldd       GlbVar005F load the current token
                    cmpd      #66       compare with the qualifier token
                    beq       MergeQualifier loop if a qualifier
                    ldd       GlbVar005F load the current token
                    cmpd      #52       compare with the identifier token
                    bne       CheckStructKw branch if not an identifier
                    ldd       GlbVar0061 load the symbol pointer
                    std       [16,s]    store it as the type
                    lbsr      ScanToken advance to the next token
                    bra       ClassifyType3 continue

CheckStructKw       ldd       GlbVar005F load the current token
                    cmpd      #45       compare with the struct keyword
                    bne       ClassifyType3 branch if not a struct
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar0051 load the nesting level
                    addd      #1        increment the level
                    std       GlbVar0051 store the level
                    ldd       20,s      load the argument
                    pshs      d         push the argument
                    ldd       20,s      load the argument
                    pshs      d         push the argument
                    ldd       20,s      load the argument
                    pshs      d         push the argument
                    lbsr      ParseTypeSpec recurse to parse the type
                    leas      6,s        drop the arguments
                    std       20,s      save the result
                    ldd       GlbVar0051 load the nesting level
                    addd      #$FFFF    decrement the level
                    std       GlbVar0051 store the level
                    ldd       #46       load the emit opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the instruction
                    leas      2,s        drop the argument
ClassifyType3       ldd       GlbVar005F load the current token
                    cmpd      #45       compare with the struct keyword
                    bne       BeginEnumBody branch if a basic type
                    ldd       10,s      load the type flags
                    aslb                shift the flags left
                    rola                rotate the high byte
                    aslb                shift the flags left again
                    rola                rotate the high byte
                    addd      #48       set the struct class bits
                    std       10,s      store the type flags
                    ldd       GlbVar0051 load the nesting level
                    bne       NestedStructTag branch if nested
                    leax      >GlbVar0047,y  point to the global tag buffer
                    pshs      x         push the pointer
                    lbsr      ParseIdentList process the struct tag
                    bra       StructTagDone continue

NestedStructTag     leax      ,s        point to the local buffer
                    pshs      x         push the pointer
                    lbsr      ParseIdentList process the struct tag
                    leas      2,s        drop the argument
                    leax      ,s        point to the local buffer
                    pshs      x         push the pointer
                    lbsr      EndScopeCheck register the nested tag
StructTagDone       leas      2,s        drop the argument
                    lbra      FinishTypeNode go finish the declaration

BeginEnumBody       clra                clear the high byte
                    clrb                clear the low byte
                    std       6,s       clear the field
                    std       4,s       clear the field
                    std       2,s       clear the field
                    ldd       GlbVar0041 load the scope counter
                    std       8,s       save the counter
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       GlbVar0041 reset the scope counter
                    lbra      EnumLoopCheck enter the enum loop check

EnumMemberLoop      ldd       10,s      load the type flags
                    aslb                shift the flags left
                    rola                rotate the high byte
                    aslb                shift the flags left again
                    rola                rotate the high byte
                    addd      #32       set the enum class bits
                    std       10,s      store the type flags
                    lbsr      ScanToken advance to the next token
                    ldd       #4        node size to allocate
                    pshs      d         push the size
                    lbsr      AllocMem  allocate the enum node
                    leas      2,s        drop the argument
                    tfr       d,u       move the node pointer to u
                    ldd       4,s       load the first-member flag
                    bne       EvalEnumValue branch if not the first
                    ldd       GlbVar005F load the current token
                    cmpd      #44       compare with the close token
                    bne       EvalEnumValue branch if more members follow
                    clra                clear the high byte
                    clrb                clear the low byte
                    bra       StoreEnumValue go store the value

EvalEnumValue       clra                clear the high byte
                    clrb                clear the low byte
                    pshs      d         push the argument
                    lbsr      EvalConstOperand evaluate the constant expression
                    leas      2,s        drop the argument
StoreEnumValue      std       ,u        store the enum value in the node
                    ldd       6,s       load the list tail
                    beq       SetEnumHead branch if the list is empty
                    ldx       6,s       load the tail pointer
                    stu       2,x       append the node to the list
                    bra       LinkEnumNode continue

SetEnumHead         stu       2,s       set the list head
LinkEnumNode        stu       6,s       update the tail pointer
                    ldd       #44       load the emit opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the instruction
                    leas      2,s        drop the argument
                    ldd       4,s       load the member count
                    addd      #1        increment the count
                    std       4,s       store the count
EnumLoopCheck       ldd       GlbVar005F load the current token
                    cmpd      #43       compare with the enum member token
                    lbeq      EnumMemberLoop loop for the next member
                    ldd       8,s       load the saved counter
                    std       GlbVar0041 restore the scope counter
                    ldd       2,s       load the list head
                    beq       FinishTypeNode branch if empty
                    ldd       [18,s]    load the existing head indirectly
                    std       2,u       link it into the node
                    ldd       2,s       load the list head
                    std       [18,s]    store the new head
FinishTypeNode      ldd       10,s      load the type flags
                    pshs      d         push the flags
                    ldd       22,s      load the argument
                    pshs      d         push the argument
                    bsr       ComputeTypeSize finalize the type node
                    leas      4,s        drop the arguments
                    leas      12,s       deallocate the frame
                    puls      pc,u      restore and return

ComputeTypeSize     pshs      u         save the u register
                    ldd       #$FFBC    load the frame size
                    lbsr      stkcheck  check the stack space
                    leas      -2,s       allocate the local
                    ldd       6,s       load the type flags
                    std       ,s        save the working copy
                    bra       SizeLoopCheck enter the size loop

DeriveSizeLoop      ldd       ,s        load the pointer levels
                    pshs      d         push the value
                    ldd       #2        pointer size constant
                    lbsr      AsrEntry  scale by the pointer size
                    std       ,s        store the result
                    ldd       8,s       load the array count
                    pshs      d         push the value
                    ldd       #2        element size constant
                    lbsr      AslEntry  scale by the element size
                    std       8,s       store the result
SizeLoopCheck       ldd       ,s        load the type flags
                    clra                clear the high byte
                    andb      #$30      mask the pointer/array bits
                    bne       DeriveSizeLoop loop while pointer or array
                    ldd       6,s       load the base value
                    addd      8,s       add the computed size
                    lbra      CleanupRet return the combined size

SetNodeTypeSize     pshs      u         save the u register
                    ldd       #$FFB2    load the frame size
                    lbsr      stkcheck  check the stack space
                    ldu       4,s       load the target node pointer
                    leas      -4,s       allocate the locals
                    ldd       ,u        load the node type word
                    std       2,s       save the type word
                    clra                clear the high byte
                    andb      #$0f      mask the base type nibble
                    tfr       d,x       move the type index to x
                    bra       BaseTypeDispatch dispatch on the base type

Size1               ldd       #1        size of one byte
                    bra       StoreBaseSize go store the size

Size2               ldd       #2        size of two bytes
                    bra       StoreBaseSize go store the size

Size4               ldd       #4        size of four bytes
                    bra       StoreBaseSize go store the size

Size8               ldd       #8        size of eight bytes
                    bra       StoreBaseSize go store the size

SizeFromTag         ldd       12,s      size taken from the tag argument
                    bra       StoreBaseSize go store the size

SizeZero            clra                clear the high byte
                    clrb                clear the low byte
StoreBaseSize       std       ,s        save the computed size
                    bra       WriteNodeSize continue

BaseTypeDispatch    cmpx      #2        compare with the char type
                    beq       Size1     select size one
                    cmpx      #1        compare with the int type
                    beq       Size2     select size two
                    cmpx      #7        compare with the type index
                    lbeq      Size2     select size two
                    cmpx      #8        compare with the type index
                    beq       Size4     select size four
                    cmpx      #5        compare with the type index
                    lbeq      Size4     select size four
                    cmpx      #6        compare with the double type
                    beq       Size8     select size eight
                    cmpx      #3        compare with the struct type
                    beq       SizeFromTag select size from tag
                    cmpx      #4        compare with the union type
                    lbeq      SizeFromTag select size from tag
                    cmpx      #10       compare with the void type
                    beq       SizeZero  select size zero
WriteNodeSize       ldd       ,s        load the computed size
                    beq       UseFallbackSize branch if zero
                    ldd       ,s        load the computed size
                    bra       StoreNodeSize2 store it in the node

UseFallbackSize     ldd       12,s      use the fallback size
StoreNodeSize2      std       2,u       store the size in the node
                    ldd       10,s      load the field value
                    std       4,u       store the field in the node
                    pshs      d         push the argument
                    ldd       2,s       load the type word
                    pshs      d         push the argument
                    ldd       6,s       load the flags
                    pshs      d         push the argument
                    bsr       ComputeElemSize compute the element size
                    leas      6,s        drop the arguments
                    leas      4,s        deallocate the frame
                    puls      pc,u      restore and return

ComputeElemSize     pshs      u         save the u register
                    ldd       #$FFB8    load the frame size
                    lbsr      stkcheck  check the stack space
                    ldu       8,s       load the node pointer
                    leas      -2,s       allocate the local
                    ldd       6,s       load the type flags
                    clra                clear the high byte
                    andb      #$30      mask the pointer/array bits
                    cmpd      #16       compare with the pointer class
                    beq       IsPointerType branch if a pointer
                    ldd       6,s       load the type flags
                    clra                clear the high byte
                    andb      #$30      mask the pointer/array bits
                    cmpd      #48       compare with the array class
                    bne       LoadTypeFlags branch if neither
IsPointerType       ldd       #2        pointer or array element size
                    lbra      CleanupRet return the size

LoadTypeFlags       ldd       6,s       load the type flags
                    clra                clear the high byte
                    andb      #$30      mask off the type field bits
                    cmpd      #32       test for array type marker
                    bne       ReturnAggSize not an array type so branch away
                    ldd       #1        start element count at one
                    std       ,s        store initial count
TypeSizeLoop        ldd       ,s        reload the count
                    pshs      d         save count on stack
                    ldd       ,u        load the type word
                    lbsr      MulEntry  convert or size the type
                    std       ,s        store back
                    ldu       2,u       follow pointer to base type
                    ldd       6,s       load working size
                    pshs      d         pass it
                    lbsr      RemovePtrLevel multiply or accumulate size
                    leas      2,s        drop argument
                    std       6,s       store updated size
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #32       still an array type?
                    beq       TypeSizeLoop keep looping over array levels
                    ldd       ,s        load the count
                    pshs      d         pass count
                    ldd       8,s       load the type word
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #16       is it a pointer type?
                    bne       ScalarSize not a pointer so branch
                    ldd       #2        pointer size is two
                    bra       FinishTypeSize go finish

ScalarSize          ldd       10,s      load scalar element size
FinishTypeSize      lbsr      MulEntry   convert or size the type
                    lbra      CleanupRet return the computed size

ReturnAggSize       ldd       8,s       load aggregate size
                    lbra      CleanupRet return the size

EndScopeCheck       pshs      u         save the caller u register
                    ldd       #$FF74    stack frame size
                    lbsr      stkcheck  check for stack space
                    leas      -64,s      allocate locals
                    ldu       [68,s]    load symbol table head pointer
                    lbra      ScopeLoopTest enter the scan loop

ScopeSymLoop        ldd       16,u      load the next-symbol link
                    std       60,s      save the iterator
                    ldd       ,u        load the symbol type
                    cmpd      #9        is this a label symbol?
                    bne       AfterLabelChk not a label
                    ldd       10,u      load the label flags
                    clra                clear high byte
                    andb      #$01      test the defined bit
                    bne       AfterLabelChk label is defined so skip
                    ldd       #8        push name length
                    pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       #20       offset to the name field
                    addd      ,s++      compute name pointer
                    pshs      d         push name pointer
                    leax      MsgLabelUndefined,pcr point at label undefined message
                    pshs      x         push it
                    leax      6,s       point at buffer
                    pshs      x         push it
                    lbsr      StrCpy    format the message
                    leas      4,s        drop arguments
                    pshs      d         push result
                    lbsr      strncat   build error text
                    leas      6,s        drop arguments
                    pshs      d         push result
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
AfterLabelChk       ldx       8,u       load the symbol subtype
                    bra       CheckBraceType test the brace markers

DecNestLevel        ldd       GlbVar0003 load the nesting counter
                    addd      #$FFFF    decrement it
                    std       GlbVar0003 store back
                    bra       RemoveFromChain continue removal

CheckBraceType      cmpx      #111      is it an open-scope marker?
                    beq       DecNestLevel decrement nesting level
                    cmpx      #118      is it a close-scope marker?
                    lbeq      DecNestLevel decrement nesting level
RemoveFromChain     ldd       14,u      load the symbol hash slot
                    std       62,s      save it
                    cmpd      GlbVar0066 below the hash table base?
                    bls       ChainHeadCheck yes so just free it
                    ldd       62,s      reload the hash slot
                    cmpd      GlbVar0068 above the hash table top?
                    bcc       ChainHeadCheck yes so just free it
                    pshs      u         push the symbol
                    lbsr      FreeNode  free the symbol
                    leas      2,s        drop argument
                    bra       NextScopeSym go to next entry

ChainHeadCheck      cmpu      [62,s]    is symbol the chain head?
                    bne       ChainWalkInit no so walk the chain
                    ldd       18,u      load its chain link
                    std       [62,s]    unlink from chain head
                    bra       FreeSymbol go free the symbol

ChainWalkInit       ldd       [62,s]    load the chain head
                    bra       ChainWalkStep begin predecessor walk

ChainWalkLoop       ldx       62,s      load current chain node
                    ldd       18,x      follow chain link
ChainWalkStep       std       62,s      save chain pointer
                    ldx       62,s      reload chain pointer
                    cmpu      18,x      is this the predecessor?
                    bne       ChainWalkLoop keep walking the chain
                    ldd       18,u      load symbol chain link
                    ldx       62,s      load predecessor
                    std       18,x      splice symbol out of chain
FreeSymbol          ldd       GlbVar0019 load free list head
                    std       18,u      link symbol into free list
                    stu       GlbVar0019 make symbol new free head
NextScopeSym        ldu       60,s      restore iterator to next symbol
ScopeLoopTest       stu       -2,s      save current symbol pointer
                    lbne      ScopeSymLoop loop while more symbols remain
                    clra                clear high byte
                    clrb                clear low byte
                    std       [68,s]    clear the table head pointer
                    leas      64,s       release locals
                    puls      pc,u      return

ErrCannotEvalSize   pshs      u         save the caller u register
                    ldd       #$FFBA    stack frame size
                    lbsr      stkcheck  check for stack space
                    leax      MsgCannotEvalSize,pcr point at cannot evaluate size message
                    bra       PrintErrRet go print the error

ErrIdentMissing     pshs      u         save the caller u register
                    ldd       #$FFBA    stack frame size
                    lbsr      stkcheck  check for stack space
                    leax      MsgIdentMissing,pcr point at identifier missing message
PrintErrRet         pshs      x         push the message
                    lbsr      PrintErrLoc report the error
CleanupRet          leas      2,s        release argument
                    puls      pc,u      return

MsgTooManyBrackets  fcc       /too many brackets/
                    fcb       C$NULL
MsgFuncHeaderMissing fcc       /function header missing/
                    fcb       C$NULL
MsgStorageError     fcc       /storage error/
                    fcb       C$NULL
MsgFuncTypeError    fcc       /function type error/
                    fcb       C$NULL
MsgArgStorage       fcc       /argument storage/
                    fcb       C$NULL
MsgArgError         fcc       /argument error/
                    fcb       C$NULL
MsgNotArgument      fcc       /not an argument/
                    fcb       C$NULL
MsgStorageError2    fcc       /storage error/
                    fcb       C$NULL
MsgDeclMismatch     fcc       /declaration mismatch/
                    fcb       C$NULL
MsgFuncUnfinished   fcc       /function unfinished/
                    fcb       C$NULL
MsgNamedTwice       fcc       /named twice/
                    fcb       C$NULL
MsgNameClash        fcc       /name clash/
                    fcb       C$NULL
MsgStructSyntax     fcc       /struct syntax/
                    fcb       C$NULL
MsgStructMemberMismatch fcc       /struct member mismatch/
                    fcb       C$NULL
MsgUndefStructure   fcc       /undefined structure/
                    fcb       C$NULL
MsgLabelUndefined   fcc       /label undefined : /
                    fcb       C$NULL
MsgCannotEvalSize   fcc       /cannot evaluate size/
                    fcb       C$NULL
MsgIdentMissing     fcc       /identifier missing/
                    fcb       C$NULL
ParseInitializer    pshs      u         save the caller u register
                    ldd       #$FFB0    stack frame size
                    lbsr      stkcheck  check for stack space
                    ldu       4,s       load the symbol pointer argument
                    leas      -4,s       allocate locals
                    ldx       10,s      load the token argument
                    bra       InitTypeSwitch go dispatch on token

DeclareAndExit      lbsr      ErrCannotInit declare the symbol
                    lbra      ParseInitExit return via exit

SetFlagOne          ldd       #1        select setup flag one
                    bra       CallSetup go do setup

SetFlagZero         clra                clear high byte
                    clrb                clear setup flag
CallSetup           pshs      d         push the flag
                    lbsr      EmitSectLetter run the setup call
                    leas      2,s        drop argument
                    bra       NotStructMember continue parsing

InitTypeSwitch      cmpx      #_start   token is zero?
                    beq       DeclareAndExit handle it
                    cmpx      #14       token type matches?
                    lbeq      DeclareAndExit handle it
                    cmpx      #34       token type matches?
                    lbeq      DeclareAndExit handle it
                    cmpx      #33       token type matches?
                    beq       SetFlagOne use setup flag one
                    cmpx      #35       token type matches?
                    lbeq      SetFlagOne use setup flag one
                    bra       SetFlagZero otherwise clear flag

NotStructMember     ldd       GlbVar0051 load the struct-member flag
                    bne       StructMemberPath member path if set
                    leax      20,u      point at the name field
                    stx       2,s       save the pointer
                    ldd       10,s      load the token
                    cmpd      #15       token is a pointer marker?
                    beq       SetPtrType treat as pointer type
                    ldd       10,s      reload token
                    cmpd      #35       token type matches?
                    beq       SetPtrType treat as pointer type
                    ldd       #1        default flag one
                    bra       CallDeclare go call declare

SetPtrType          ldd       #12       set pointer type code
                    std       8,u       store type on symbol
                    clra                clear high byte
                    clrb                clear low byte
CallDeclare         pshs      d         push the flag
                    ldd       4,s       load pointer argument
                    pshs      d         push it
                    lbsr      EmitLabelDef declare the identifier
                    leas      4,s        drop arguments
                    bra       CheckAssignTok go check for initializer

StructMemberPath    lbsr      EmitStar  process struct member
                    ldd       6,u       load member size
                    pshs      d         push it
                    lbsr      EmitTempRef allocate member storage
                    leas      2,s        drop argument
                    lbsr      EmitNewline finalize member
CheckAssignTok      ldd       12,s      load the current token
                    cmpd      #34       is it an assignment token?
                    bne       SetFlagTwoTok no initializer present
                    ldd       #1        set initializer flag one
                    std       GlbVar000B store the flag global
                    lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #55       is it a special init token?
                    bne       SetFlagTwo no so set flag two
                    ldd       4,u       load symbol address
                    std       2,s       save it
                    ldd       [2,s]     already has a value?
                    bne       CalcInitDiff yes handle difference
                    ldd       GlbVar0017 load location counter
                    std       [2,s]     store as symbol value
                    bra       NextTokAndExit go get next token

CalcInitDiff        ldd       [2,s]     load symbol value
                    subd      GlbVar0017 subtract location counter
                    std       ,s        store the difference
                    blt       NegSizeErr negative so report error
                    ldd       ,s        load the difference
                    pshs      d         push it
                    lbsr      EmitCharConst reserve that many bytes
                    bra       InitDiffDone done

NegSizeErr          leax      MsgTooLong,pcr point at size error message
                    pshs      x         push it
                    lbsr      PrintErrLoc report the error
InitDiffDone        leas      2,s        drop argument
NextTokAndExit      lbsr      ScanToken get the next token
                    leax      4,s       restore stack pointer
                    lbra      AdjustFrame return via exit

SetFlagTwo          ldd       #2        initializer flag two
                    std       GlbVar000B store the flag global
                    bra       CheckBraceInit continue

SetFlagTwoTok       ldd       #2        initializer flag two
                    std       GlbVar000B store the flag global
                    lbsr      ScanToken get the next token
CheckBraceInit      ldd       12,s      load the current token
                    cmpd      #4        is it an open-brace token?
                    bne       IsArrayInit no scalar initializer
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push depth zero
                    ldd       10,u      load array element count
CallParseInitList   pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       18,s      load symbol argument
                    pshs      d         push it
                    bsr       ParseInitList parse the initializer list
                    leas      8,s        drop arguments
                    bra       InitFinish go finish

IsArrayInit         ldd       12,s      load the current token
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #32       is it an array type?
                    bne       ScalarInit no so scalar path
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push depth zero
                    ldd       4,u       load array field
                    bra       CallParseInitList parse the initializer list

ScalarInit          ldd       #1        depth one
                    pshs      d         push it
                    ldd       4,u       load symbol field
                    pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       18,s      load argument
                    pshs      d         push it
                    bsr       ParseInitList parse the initializer list
                    leas      8,s        drop arguments
                    std       -2,s      save result
                    bne       InitFinish nonzero so skip
                    lbsr      SkipInitTokens emit scalar initializer
                    bra       InitFinish go finish

AdjustFrame         leas      -4,x      adjust frame
InitFinish          lbsr      EmitEndLetter finalize the initializer
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000B clear the initializer flag
ParseInitExit       leas      4,s        release locals
                    puls      pc,u      return

ParseInitList       pshs      u         save the caller u register
                    ldd       #$FFA8    stack frame size
                    lbsr      stkcheck  check for stack space
                    ldu       6,s       load the symbol pointer argument
                    leas      -12,s      allocate locals
                    ldd       22,s      load the nesting depth argument
                    bne       HaveDepth nonzero depth path
                    ldd       #')       open-brace token code
                    pshs      d         push it
                    lbsr      ExpectToken expect the open brace
                    leas      2,s        drop argument
                    bra       CheckArrayInit continue

HaveDepth           ldd       GlbVar005F load the current token
                    cmpd      #')       is it an open brace?
                    bne       NoOpenBrace no open brace seen
                    ldd       #1        note brace present
                    std       10,s      save flag
                    lbsr      ScanToken get the next token
                    bra       CheckArrayInit continue

NoOpenBrace         clra                clear high byte
                    clrb                clear low byte
                    std       10,s      clear brace flag
CheckArrayInit      ldd       16,s      load the type word
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #32       is it an array type?
                    lbne      InitArrayType not an array so handle elsewhere
                    ldd       [20,s]    load the declared array size
                    std       2,s       save it
                    bne       HaveElemSize nonzero so keep it
                    ldd       #$FFFF    mark size as unknown
                    std       2,s       save it
HaveElemSize        ldd       16,s      reload the type word
                    pshs      d         push it
                    lbsr      RemovePtrLevel compute element type
                    leas      2,s        drop argument
                    std       8,s       save element type
                    cmpd      #4        is element a struct?
                    bne       LoadElemSize no so load its size
                    ldd       10,u      load struct size
                    bra       InitCountSetup go store element size

LoadElemSize        ldx       20,s      load type pointer
                    ldd       2,x       load element size
InitCountSetup      std       4,s       store element size
                    clra                clear high byte
                    clrb                clear low byte
                    std       6,s       initialize element index
                    bra       InitListLoop enter list loop

InitElemLoop        ldd       22,s      load the depth
                    addd      #1        increment depth
                    pshs      d         push it
                    ldd       6,s       load index
                    pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       14,s      load element type argument
                    pshs      d         push it
                    lbsr      ParseInitList recurse into nested initializer
                    leas      8,s        drop arguments
                    std       -2,s      save result
                    lbeq      InitFail  zero so bail out
                    ldd       6,s       load the index
                    addd      #1        advance the index
                    std       6,s       store it
                    cmpd      2,s       reached the declared size?
                    bcc       AfterElems yes so stop
                    ldd       GlbVar005F load the current token
                    cmpd      #'0       is it a comma?
                    bne       AfterElems no so stop
                    lbsr      ScanToken get the next token
                    bra       InitListLoop continue the loop

InitListLoop        ldd       GlbVar005F load the current token
                    cmpd      #'*       is it a close brace?
                    bne       InitElemLoop no so parse another element
AfterElems          ldd       2,s       load the declared size
                    cmpd      #$FFFF    was the size unknown?
                    bne       CheckCount no so check the count
                    ldd       6,s       load the counted elements
                    std       [20,s]    store the inferred array size
                    bra       InitListEnd go finish list

CheckCount          ldd       6,s       load the actual count
                    cmpd      2,s       matches the declared size?
                    bcc       InitListEnd yes so finish
                    ldx       20,s      load type pointer
                    ldd       2,x       load element size
                    pshs      d         push it
                    ldd       2,u       load symbol value
                    pshs      d         push it
                    ldd       12,s      load token
                    pshs      d         push it
                    lbsr      ComputeElemSize compute fill amount
                    leas      6,s        drop arguments
                    pshs      d         push result
                    ldd       4,s       load one value
                    subd      8,s       subtract another
                    lbsr      MulEntry  size the difference
                    pshs      d         push it
                    lbsr      EmitRzb   emit padding for missing elements
                    leas      2,s        drop argument
                    bra       InitListEnd go finish list

FrameFixup          leas      -12,x     frame fixup
InitListEnd         ldd       22,s      load the depth
                    beq       CheckComma2 zero depth so continue
                    ldd       10,s      load brace flag
                    lbeq      InitOk    brace was present go finish
CheckComma2         ldd       GlbVar005F load the current token
                    cmpd      #'0       is it a comma?
                    bne       CheckCloseBrace no so check brace
                    lbsr      ScanToken get the next token
CheckCloseBrace     ldd       GlbVar005F load the current token
                    cmpd      #'*       is it a close brace?
                    bne       InitListErr no so report error
                    lbsr      ScanToken get the next token
                    lbra      InitOk    go finish

InitListErr         leax      MsgTooManyElements,pcr point at initializer error message
                    pshs      x         push it
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
                    lbsr      SkipInitTokens skip malformed initializer tokens
                    lbra      InitOk    return with success

InitArrayType       ldd       16,s      load the declared type
                    cmpd      #4        is it an array type
                    lbne      ScalarInit2 not array, do scalar init
                    ldd       20,s      load the element count
                    std       ,s        save the count locally
                    bne       MemberEndCheck nonzero elements, process them
                    leax      MsgUnionsNotAllowed,pcr point at unions-not-allowed message
                    lbra      ReportInitErr report the error

InitMemberLoop      ldx       ,s        get member list pointer
                    ldu       2,x       follow to member entry
                    ldd       22,s      load current offset
                    addd      #1        bump the index
                    pshs      d         save it
                    ldd       ,u        load member type
                    cmpd      #4        is member an array
                    bne       NonArrayMember no, use plain size
                    ldd       10,u      array element size
                    bra       GotMemberSize got the array size

NonArrayMember      ldd       4,u       scalar member size
GotMemberSize       pshs      d         pass the size
                    pshs      u         pass member pointer
                    ldd       ,u        member type again
                    pshs      d         pass the type
                    lbsr      ParseInitList recurse to init this member
                    leas      8,s        clean the arguments
                    std       -2,s      save result
                    lbeq      InitFail  failed, return zero
                    ldd       [,s]      follow to next member
                    std       ,s        update the pointer
                    beq       RemainCheck no more, finish
                    ldd       GlbVar005F load current token
                    cmpd      #'0       is it a comma separator
                    bne       RemainCheck no, done with members
                    lbsr      ScanToken advance to next token
                    bra       MemberEndCheck check for end token

MemberEndCheck      ldd       GlbVar005F load current token
                    cmpd      #'*       is it the closing brace
                    bne       InitMemberLoop no, process next member
                    bra       RemainCheck done

FillRemainLoop      ldx       ,s        get member pointer
                    ldu       2,x       follow to member entry
                    ldd       4,u       pass member field
                    pshs      d         push it
                    ldd       2,u       pass member field
                    pshs      d         push it
                    ldd       ,u        member type
                    pshs      d         push it
                    lbsr      ComputeElemSize compute member size
                    leas      6,s        drop arguments
                    pshs      d         pass the size
                    bsr       EmitRzb   emit rzb padding
                    leas      2,s        clean up
                    ldd       [,s]      advance to next member
                    std       ,s        update the pointer
RemainCheck         ldd       ,s        any member left
                    bne       FillRemainLoop yes, keep padding
                    leax      12,s      release locals
                    lbra      FrameFixup return to caller

ScalarInit2         ldd       16,s      reload the type
                    pshs      d         pass it
                    bsr       ParseScalarInit parse a scalar initializer
                    std       ,s++      save node and drop arg
                    beq       ConstReqErr none, need constant expression
                    ldd       10,s      test the flag
                    beq       InitOk    zero, return success
                    ldd       #'*       closing brace token
                    pshs      d         push it
                    lbsr      ExpectToken expect the brace
                    leas      2,s        clean up
InitOk              ldd       #1        return success
                    bra       InitReturn go to common return

ConstReqErr         leax      MsgConstExprRequired,pcr point at constant-expression message
ReportInitErr       pshs      x         push it
                    lbsr      PrintErrLoc print the error
                    leas      2,s        clean up
                    lbsr      SkipInitTokens skip to resync point
InitFail            clra                clear high byte
                    clrb                return zero
InitReturn          leas      12,s       release locals
                    puls      pc,u      return

EmitRzb             pshs      u         save the caller u register
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    lbsr      EmitStar  start a new asm line
                    leax      MsgRzb,pcr point at rzb keyword
                    pshs      x         push it
                    lbsr      EmitSpaceText emit the directive text
                    leas      2,s        clean up
                    ldd       4,s       load the byte count
                    pshs      d         push it
                    lbsr      EmitDecimal emit the number
                    leas      2,s        clean up
                    lbsr      EmitNewline emit newline
                    puls      pc,u      return

ParseScalarInit     pshs      u         save the caller u register
                    ldd       #$FFB0    requested frame size
                    lbsr      stkcheck  check stack space
                    leas      -8,s       reserve locals
                    ldd       #2        pass parse mode
                    pshs      d         push it
                    lbsr      ParseExpr begin expression
                    std       ,s        save partial result
                    lbsr      OptExprTree parse a constant expression
                    leas      2,s        clean up
                    tfr       d,u       result node in u
                    stu       -2,s      save it
                    bne       GotInitNode got a node
                    clra                clear high byte
                    clrb                return zero
                    lbra      ScalarInitRet exit with no node

GotInitNode         clra                clear high byte
                    clrb                clear low byte
                    std       4,s       clear value slot
                    ldd       #1        initial code one
                    std       2,s       save it
                    ldd       ,u        load node type
                    std       ,s        save it
                    ldd       12,s      load declared type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #16       is it scalar class
                    bne       NonScalarClass no, other handling
                    ldx       ,s        node type into x
                    bra       DispatchNodeType dispatch on node type

SelectCodeOne       ldd       #1        select conversion code one
                    bra       ConvertNode convert with that code

CheckClassBits      ldd       ,s        node type
                    clra                clear high byte
                    andb      #$30      isolate class bits
                    cmpd      #16       is it scalar class
                    beq       CheckOpcode yes, use as is
                    bra       DropAndFinish otherwise skip conversion

DispatchNodeType    cmpx      #8        type is code eight
                    beq       SelectCodeOne select code one
                    cmpx      #1        type is code one
                    beq       CheckOpcode use as is
                    cmpx      #7        type is code seven
                    beq       CheckOpcode use as is
                    bra       CheckClassBits check class bits

NonScalarClass      ldd       ,s        node type
                    clra                clear high byte
                    andb      #$30      isolate class bits
                    cmpd      #16       is it scalar class
                    bne       CheckCharType no, other handling
                    ldd       12,s      declared type
                    pshs      d         push it
                    lbsr      IsIntegral resolve type node
                    std       ,s++      save and drop arg
                    bne       CheckOpcode nonzero, use it
DropAndFinish       leax      8,s       drop locals
                    bra       AdjustStack fix stack and finish

CheckCharType       ldd       12,s      declared type
                    cmpd      #5        is it a char type
                    bne       UseDeclaredType no
                    ldd       #6        promote to int
                    bra       ConvertNode convert as int

UseDeclaredType     ldd       12,s      declared type
ConvertNode         pshs      d         push it
                    pshs      u         pass the node
                    lbsr      InsertConvNode coerce to type
                    leas      4,s        clean up
CheckOpcode         ldd       6,u       load node opcode
                    cmpd      #80       is it a constant
                    beq       GotAddrConst handle it
                    ldd       6,u       opcode again
                    cmpd      #81       is it negated constant
                    bne       CheckNameRef no, other opcode
GotAddrConst        ldd       12,u      load address field
                    std       6,s       save it
                    tfr       d,x       pointer into x
                    ldd       6,x       load its opcode
                    cmpd      #54       is it a struct member
                    beq       CheckNegConst handle negation
                    bra       ZeroResult not a struct, zero result

AdjustStack         leas      -8,x      restore stack from x
ZeroResult          clra                clear high byte
                    clrb                clear low byte
                    std       2,s       clear result
                    leax      8,s       drop locals
                    lbra      AdjustStack2 finish

CheckNegConst       ldd       6,u       load node opcode
                    cmpd      #81       is it negated
                    bne       LoadConstVal no
                    ldx       6,s       pointer into x
                    ldd       8,x       load value
                    nega                negate high
                    negb                negate low
                    sbca      #0        complete the negation
                    bra       StoreConstVal store negated value

LoadConstVal        ldx       6,s       pointer into x
                    ldd       8,x       load value
StoreConstVal       std       4,s       save the value
                    ldd       6,s       pass the node
                    pshs      d         push it
                    lbsr      WalkTree  free the node
                    leas      2,s        clean up
                    stu       6,s       save new node
                    ldu       10,u      follow the link
                    ldd       6,s       pass the node
                    pshs      d         push it
                    lbsr      LinkNode  rebuild the node
                    leas      2,s        clean up
CheckNameRef        ldd       6,u       load node opcode
                    cmpd      #65       is it a name reference
                    bne       LoadOpcode2 no
                    ldd       10,u      symbol pointer
                    std       6,s       save it
                    tfr       d,x       pointer into x
                    ldx       8,x       follow to type
                    ldx       8,x       follow to base type
                    bra       DispatchNameType dispatch on type

ClearResult         clra                clear high byte
                    clrb                clear low byte
                    std       2,s       clear result
                    lbra      FinishInit finish

EmitStringInit      ldd       #1        initializer active
                    std       GlbVar000D set initializer flag
                    ldd       4,s       pass field
                    pshs      d         push it
                    ldd       8,s       pass field
                    pshs      d         push it
                    lbsr      AdvanceOffset emit the initializer
                    leas      4,s        clean up
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000D clear initializer flag
                    lbra      FinishInit finish

DispatchNameType    cmpx      #15       type code fifteen
                    beq       EmitStringInit emit string init
                    cmpx      #14       type code fourteen
                    lbeq      EmitStringInit emit string init
                    cmpx      #12       type code twelve
                    lbeq      EmitStringInit emit string init
                    cmpx      #33       type code thirtythree
                    lbeq      EmitStringInit emit string init
                    cmpx      #34       type code thirtyfour
                    lbeq      EmitStringInit emit string init
                    bra       ClearResult none matched, clear

LoadOpcode2         ldx       6,u       load node opcode
                    bra       DispatchOpcode2 dispatch on it

CheckCharType2      ldd       12,s      declared type
                    cmpd      #5        is it a char
                    bne       EmitScalarInit no
                    ldx       8,u       string pointer
                    pshs      x         push it
                    ldx       8,u       string pointer again
                    lbsr      LoadNumWork register the string
                    lbsr      SwapNumWork finalize the string
EmitScalarInit      ldd       12,s      declared type
                    pshs      d         push it
                    ldd       8,u       pass the value
                    pshs      d         push it
                    bsr       EmitInitValue emit the init value
                    leas      4,s        clean up
                    bra       FinishInit finish

EmitFloatInit       lbsr      EmitFdb   prepare float emit
                    ldd       8,u       pass the value
                    pshs      d         push it
                    lbsr      EmitStmtLine emit float constant
                    leas      2,s        clean up
                    bra       FinishInit finish

DispatchOpcode2     cmpx      #75       opcode is char literal
                    beq       CheckCharType2 handle it
                    cmpx      #54       opcode is member
                    beq       EmitScalarInit emit scalar init
                    cmpx      #74       opcode is like member
                    lbeq      EmitScalarInit emit scalar init
                    cmpx      #55       opcode is float
                    beq       EmitFloatInit emit float init
                    lbra      ClearResult none matched, clear

AdjustStack2        leas      -8,x      restore stack from x
FinishInit          pshs      u         pass the node
                    lbsr      WalkTree  free the node
                    leas      2,s        clean up
                    ldd       2,s       load result
ScalarInitRet       leas      8,s        release locals
                    puls      pc,u      return

EmitInitValue       pshs      u         save the caller u register
                    ldd       #$FFB6    requested frame size
                    lbsr      stkcheck  check stack space
                    ldu       4,s       load the value node
                    leas      -2,s       reserve a local
                    ldx       8,s       load element type
                    bra       DispatchSize dispatch on it

EmitNumberVal       lbsr      EmitFcb   prepare number emit
                    pshs      u         pass the node
                    lbsr      EmitDecimal emit the number
                    leas      2,s        clean up
                    lbsr      EmitNewline emit newline
                    bra       EmitValRet finish

SetByteSize         ldd       #1        one byte
                    bra       StoreSize store the size

SetWordSize         ldd       #2        two bytes
StoreSize           std       ,s        store the size
                    bra       EmitSizedVal emit sized value

EmitLargeVal        ldd       8,s       pass the value
                    pshs      d         push it
                    pshs      u         pass the node
                    lbsr      EmitFloatField emit long value
                    bra       DropFour  finish

DispatchSize        cmpx      #2        type code two
                    beq       EmitNumberVal emit number
                    cmpx      #1        type code one
                    beq       SetByteSize one byte
                    cmpx      #7        type code seven
                    lbeq      SetByteSize one byte
                    cmpx      #8        type code eight
                    beq       SetWordSize two bytes
                    cmpx      #5        type code five
                    beq       EmitLargeVal emit large value
                    cmpx      #6        type code six
                    lbeq      EmitLargeVal emit large value
                    lbra      SetByteSize default one byte

EmitSizedVal        ldd       ,s        the chosen size
                    pshs      d         push it
                    pshs      u         pass the node
                    lbsr      EmitInitList emit sized value
DropFour            leas      4,s        clean up
EmitValRet          leas      2,s        drop local
                    puls      pc,u      return

ErrCannotInit       pshs      u         save the caller u register
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    leax      MsgCannotInit,pcr point at cannot-initialize message
                    pshs      x         push it
                    lbsr      PrintErrLoc print the error
                    leas      2,s        clean up
                    bsr       SkipInitTokens skip to resync point
                    puls      pc,u      return

SkipInitTokens      pshs      u         save the caller u register
                    ldd       #$FFBC    requested frame size
                    lbsr      stkcheck  check stack space
SkipLoop            ldx       GlbVar005F load current token
                    bra       SkipCheck check it

SkipDone            puls      pc,u      stop skipping and return

SkipAdvance         lbsr      ScanToken advance to next token
                    bra       SkipLoop  reload token

SkipCheck           cmpx      #'0       is it a comma
                    beq       SkipDone  stop skipping
                    cmpx      #'(       is it open brace
                    lbeq      SkipDone  stop skipping
                    cmpx      #$FFFF    is it end of file
                    lbeq      SkipDone  stop skipping
                    bra       SkipAdvance otherwise keep skipping

                    puls      pc,u      return

MsgTooLong          fcc       /too long/
                    fcb       C$NULL
MsgTooManyElements  fcc       /too many elements/
                    fcb       C$NULL
MsgUnionsNotAllowed fcc       /unions not allowed/
                    fcb       C$NULL
MsgConstExprRequired fcc       /constant expression required/
                    fcb       C$NULL
MsgRzb              fcc       /rzb /
                    fcb       C$NULL
MsgCannotInit       fcc       /cannot initialize/
                    fcb       C$NULL
EmitLabelDef        pshs      u         save the caller u register
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    lbsr      EmitStar  start a new asm line
                    ldd       4,s       the label value
                    pshs      d         push it
                    lbsr      EmitName8 emit the label
                    leas      2,s        clean up
                    ldd       6,s       test colon flag
                    lbeq      EmitNewlineRet no colon needed
                    ldd       #':       colon character
                    pshs      d         push it
                    bsr       EmitCharOut emit the colon
                    lbra      DropAndNewline finish

EmitSpaceText       pshs      u         save the caller u register
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       GlbVar0025 output path number
                    pshs      d         push it
                    ldd       #'        space character
                    pshs      d         push it
                    lbsr      PutChar2  write it to output
                    leas      4,s        clean up
                    ldd       4,s       text argument
                    pshs      d         push it
                    bsr       EmitText  emit the text
                    lbra      EmitReturn finish

                    pshs      u         save the caller u register
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       4,s       text argument
                    pshs      d         push it
                    bsr       EmitSpaceText emit space then text
                    lbra      DropAndNewline finish

EmitNewline         pshs      u         save the caller u register
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       GlbVar0025 output path number
                    pshs      d         push it
                    ldd       #13       carriage return
                    bra       EmitCharTail write it out

EmitCharOut         pshs      u         save the caller u register
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       GlbVar0025 output path number
                    pshs      d         push it
                    ldd       6,s       the character argument
EmitCharTail        pshs      d         push it
                    lbsr      PutChar2  write it to output
                    lbra      EmitCleanupRet finish

EmitText            pshs      u         save the caller u register
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       4,s       load the argument
                    pshs      d         save value argument for fprintf
                    ldd       GlbVar0025 load output file pointer
                    pshs      d         pass file to fprintf
                    lbsr      fprintf   format and emit
                    lbra      EmitCleanupRet drop args and return

EmitDecimal         pshs      u         save the caller u register
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       4,s       load the number argument
                    pshs      d         pass value to formatter
                    leax      FmtPctD,pcr point at the %d format
                    lbra      EmitFprintf emit via fprintf

EmitLocalRef        pshs      u         save the caller u register
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       #'l       the 'l' prefix character
                    pshs      d         pass char to emitter
                    bsr       EmitCharOut emit the 'l' prefix
                    leas      2,s        drop char argument
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    ldd       6,s       load the number argument
                    pshs      d         pass value
                    lbsr      PutWord   emit decimal number
                    leas      4,s        drop args
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004F clear pending flag
                    puls      pc,u      return

EmitStmtLine        pshs      u         save the caller u register
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004F clear pending flag
                    ldd       4,s       load node argument
                    pshs      d         pass node
                    bsr       EmitTempRef emit the temp reference
DropAndNewline      leas      2,s        drop argument
EmitNewlineRet      lbsr      EmitNewline emit trailing newline
                    puls      pc,u      return

EmitTempRef         pshs      u         save the caller u register
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       #'_       the '_' prefix character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the '_' prefix
                    leas      2,s        drop char argument
                    ldd       4,s       load the number
                    pshs      d         pass value
                    lbsr      EmitDecimal emit decimal number
                    lbra      EmitReturn clean up and return

EmitName8           pshs      u         save the caller u register
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       4,s       load the name pointer
                    pshs      d         pass name
                    leax      FmtPct8s,pcr point at the %.8s format
                    lbra      EmitFprintf emit via fprintf

EmitLabelOffset     pshs      u         save the caller u register
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       reserve local slot
                    ldd       6,s       load the value
                    subd      GlbVar002F subtract base global
                    std       ,s        store the offset
                    beq       EmitResult skip emit when zero
                    ldd       #'M       the 'M' prefix character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the 'M' prefix
                    leas      2,s        drop char argument
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    ldd       2,s       load the offset
                    pshs      d         pass value
                    lbsr      PutWord   emit decimal offset
                    leas      4,s        drop args
EmitResult          ldd       6,s       load original value for result
                    lbra      EmitReturn clean up and return

EmitOpCode          pshs      u         save the caller u register
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       GlbVar0025 load output file into u
                    ldx       4,s       load operator code
                    lbra      DispatchOp2 dispatch on operator

OpEmitJ             ldd       #'J       the 'J' mnemonic character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the 'J'
                    leas      2,s        drop char argument
                    pshs      u         save file pointer
                    ldd       10,s      load number argument
                    bra       EmitOpNumberTail emit the number

OpEmitR             ldd       #'r       the 'r' mnemonic character
                    lbra      EmitCharDone emit char and return

OpEmitG             ldd       #'G       the 'G' mnemonic character
                    bra       EmitCharThenNum emit char then number

OpEmitLowJ          ldd       #'j       the 'j' mnemonic character
                    bra       EmitCharThenNum emit char then number

OpEmitD             ldd       #'D       the 'D' mnemonic character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the 'D'
                    leas      2,s        drop char argument
                    pshs      u         save file pointer
                    ldd       GlbVar002B load label counter
                    addd      #1        increment counter
                    std       GlbVar002B store new counter
EmitOpNumberTail    pshs      d         pass number
                    lbsr      PutWord   emit decimal number
                    leas      4,s        drop args
                    bra       EmitNumArg continue to number tail

OpEmitY             ldd       #'Y       the 'Y' mnemonic character
                    bra       EmitCharThenNum emit char then number

OpEmitU             ldd       #'U       the 'U' mnemonic character
EmitCharThenNum     pshs      d         pass char
                    lbsr      EmitCharOut emit the mnemonic char
                    leas      2,s        drop char argument
EmitNumArg          pshs      u         save file pointer
                    ldd       8,s       load number argument
                    pshs      d         pass value
                    lbsr      PutWord   emit decimal number
EmitCleanupRet      leas      4,s        drop args
                    puls      pc,u      return

DispatchOp2         cmpx      #125      operator $7D?
                    lbeq      OpEmitJ   emit 'J'
                    cmpx      #18       operator $12?
                    beq       OpEmitR   emit 'r'
                    cmpx      #29       operator $1D?
                    beq       OpEmitG   emit 'G'
                    cmpx      #124      operator $7C?
                    beq       OpEmitLowJ emit 'j'
                    cmpx      #9        operator $09?
                    beq       OpEmitD   emit 'D'
                    cmpx      #118      operator $76?
                    beq       OpEmitY   emit 'Y'
                    cmpx      #111      operator $6F?
                    beq       OpEmitU   emit 'U'
                    puls      pc,u      no match, return

EmitStar            pshs      u         save the caller u register
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       #'*       the '*' character
EmitCharDone        pshs      d         pass char
                    lbsr      EmitCharOut emit the char
                    lbra      EmitReturn clean up and return

EmitFuncLine        pshs      u         save the caller u register
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       4,s       load the name pointer
                    pshs      d         pass name
                    leax      FmtFPctS,pcr point at the F%s format
EmitFprintf         pshs      x         pass format string
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    lbsr      fprintf   format and emit
                    lbra      CostRet   clean up and return

EmitStmtMode1       pshs      u         save the caller u register
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       4,s       load node argument
                    pshs      d         pass node
                    ldd       #1        select mode 1
                    bra       EmitStmtCall call node emitter

EmitStmtMode2       pshs      u         save the caller u register
                    ldd       #$FFB2    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       10,s      push arg
                    pshs      d         pass arg
                    ldd       10,s      push arg
                    pshs      d         pass arg
                    ldd       10,s      push arg
                    pshs      d         pass arg
                    ldd       10,s      push arg
                    pshs      d         pass arg
                    ldd       #2        select mode 2
                    pshs      d         pass mode
                    bsr       EmitNodeRecord emit node record
                    leas      10,s       drop args
                    bra       EmitStmtRet return node result

EmitStmtMode4       pshs      u         save the caller u register
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       4,s       load node argument
                    pshs      d         pass node
                    ldd       #4        select mode 4
EmitStmtCall        pshs      d         pass mode
                    bsr       EmitNodeRecord emit node record
                    leas      4,s        drop args
EmitStmtRet         ldd       4,s       load result to return
                    puls      pc,u      return

EmitNodeRecord      pshs      u         save the caller u register
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       GlbVar0025 load output file into u
                    pshs      u         save file pointer
                    ldd       #84       the 'T' record prefix
                    pshs      d         pass char
                    lbsr      PutChar2  emit the 'T' prefix
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       6,s       load node value
                    pshs      d         pass value
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       GlbVar002B load label counter
                    pshs      d         pass counter
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       GlbVar002F load base global
                    pshs      d         pass value
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    ldx       4,s       load node type
                    bra       DispatchRec dispatch on node type

RecCaseTwo          pshs      u         save file pointer
                    ldd       10,s      load arg
                    pshs      d         pass value
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       12,s      load arg
                    pshs      d         pass value
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       14,s      load arg
                    pshs      d         pass value
                    lbsr      PutChar2  emit char
                    bra       RecCaseDone finish this case

RecCaseFive         pshs      u         save file pointer
                    ldd       GlbVar000D load global
                    bra       EmitRecNum emit that number

RecCaseTwelve       pshs      u         save file pointer
                    ldd       10,s      load arg
EmitRecNum          pshs      d         pass value
                    lbsr      PutWord   emit number
RecCaseDone         leas      4,s        drop args
                    bra       EmitRecTail continue to record tail

DispatchRec         cmpx      #2        node type $02?
                    beq       RecCaseTwo handle case two
                    cmpx      #5        node type $05?
                    beq       RecCaseFive handle case five
                    cmpx      #18       node type $12?
                    beq       RecCaseTwelve handle case twelve
EmitRecTail         ldd       GlbVar002B load label counter
                    pshs      d         save counter
                    ldd       6,s       load mode
                    cmpd      #2        mode 2?
                    bne       RecFlagZero no, use flag zero
                    ldd       #1        yes, use flag one
                    bra       RecFlagSet proceed with flag

RecFlagZero         clra                zero high byte
                    clrb                zero low byte
RecFlagSet          pshs      d         push cost flag
                    ldd       10,s      load node
                    pshs      d         pass node
                    bsr       EvalTreeCost compute tree cost
                    leas      4,s        drop args
                    addd      ,s++      add saved counter
                    std       GlbVar002B update counter
                    ldd       6,s       load mode/node for tail
                    lbra      EmitRightChild emit tree and return

EvalTreeCost        pshs      u         save the caller u register
                    ldd       #$FFB0    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       4,s       load node pointer
                    leas      -6,s       reserve local slots
                    stu       -2,s      save node pointer
                    lbeq      CostNull  return zero if null
                    ldx       6,u       load node type
                    lbra      DispatchCost dispatch on node type

CostCaseGH          ldd       12,s      load flag
                    beq       CostGHFour flag zero uses weight 4
                    ldd       #1        weight 1
                    bra       CostGHStore store the weight

CostGHFour          ldd       #4        weight 4
CostGHStore         std       4,s       store left weight
                    ldd       #1        right weight 1
                    bra       CostStoreZero store weights

CostCase40          ldd       #3        weight 3
                    std       4,s       store left weight
                    ldd       #1        right weight 1
                    bra       CostStoreMid store weights

CostCaseRange       ldd       12,s      load flag
                    beq       CostRangeThree flag zero uses weight 3
                    clra                zero high byte
                    clrb                zero low byte
                    bra       CostRangeStore use weight 0

CostRangeThree      ldd       #3        weight 3
CostRangeStore      std       4,s       store left weight
                    clra                zero high byte
                    clrb                zero low byte
                    bra       CostStoreZero store weights

CostCase64          ldd       #3        weight 3
                    std       4,s       store left weight
                    ldd       #1        right weight 1
                    std       2,s       store mid weight
                    clra                zero high byte
                    clrb                zero low byte
                    std       ,s        store low weight
                    lbra      CostRecurse recurse over children

CostCase4B          ldd       #1        weight 1
                    std       4,s       store left weight
                    clra                zero high byte
                    clrb                zero low byte
                    std       12,s      clear flag slot
CostStoreZero       std       ,s        store low weight
CostStoreMid        std       2,s       store mid weight
                    lbra      CostRecurse recurse over children

CostDefault         clra                zero high byte
                    clrb                zero low byte
                    std       12,s      clear flag slot
                    std       ,s        clear low weight
                    std       2,s       clear mid weight
                    std       4,s       clear left weight
                    bra       CostRecurse recurse over children

DispatchCost        cmpx      #71       node type $47?
                    lbeq      CostCaseGH handle case
                    cmpx      #72       node type $48?
                    lbeq      CostCaseGH handle case
                    cmpx      #64       node type $40?
                    lbeq      CostCase40 handle case
                    cmpx      #90       node type $5A?
                    lbeq      CostCaseRange handle range case
                    cmpx      #91       node type $5B?
                    lbeq      CostCaseRange handle range case
                    cmpx      #92       node type $5C?
                    lbeq      CostCaseRange handle range case
                    cmpx      #93       node type $5D?
                    lbeq      CostCaseRange handle range case
                    cmpx      #94       node type $5E?
                    lbeq      CostCaseRange handle range case
                    cmpx      #95       node type $5F?
                    lbeq      CostCaseRange handle range case
                    cmpx      #96       node type $60?
                    lbeq      CostCaseRange handle range case
                    cmpx      #97       node type $61?
                    lbeq      CostCaseRange handle range case
                    cmpx      #98       node type $62?
                    lbeq      CostCaseRange handle range case
                    cmpx      #99       node type $63?
                    lbeq      CostCaseRange handle range case
                    cmpx      #100      node type $64?
                    lbeq      CostCase64 handle case
                    cmpx      #75       node type $4B?
                    lbeq      CostCase4B handle case
                    cmpx      #74       node type $4A?
                    lbeq      CostCase4B handle case
                    lbra      CostDefault default case

CostRecurse         ldd       2,s       load flag
                    pshs      d         pass flag
                    ldd       10,u      load left child
                    pshs      d         pass child
                    lbsr      EvalTreeCost recurse on left child
                    leas      4,s        drop args
                    addd      4,s       add left weight
                    pshs      d         save subtotal
                    ldd       2,s       load flag
                    pshs      d         pass flag
                    ldd       12,u      load right child
                    pshs      d         pass child
                    lbsr      EvalTreeCost recurse on right child
                    leas      4,s        drop args
                    addd      ,s++      sum both subtotals
                    bra       CostRet   return the total

CostNull            clra                zero high byte
                    clrb                zero low byte
CostRet             leas      6,s        drop locals
                    puls      pc,u      return

EmitExprTree        pshs      u         save the caller u register
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       4,s       load node pointer
                    stu       -2,s      save node pointer
                    lbeq      EmitRet2  return if null
                    pshs      u         pass node pointer
                    bsr       EmitChildFlag emit node header char
                    leas      2,s        drop argument
                    ldd       10,u      load left child
                    pshs      d         pass child
                    bsr       EmitExprTree recurse on left child
                    leas      2,s        drop argument
                    ldd       12,u      load right child
EmitRightChild      pshs      d         pass child
                    lbsr      EmitExprTree recurse on right child
                    lbra      EmitReturn clean up and return

EmitChildFlag       pshs      u         save the caller u register
                    ldd       #$FFAA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       4,s       load node pointer
                    leas      -2,s       reserve local slot
                    ldd       10,u      load left child
                    beq       KindLeftCheck no left child
                    ldd       12,u      load right child
                    beq       KindLeftCheck left but no right child
                    ldd       #66       'B' both children
                    bra       EmitKindChar emit the kind char

KindLeftCheck       ldd       10,u      reload left child
                    beq       KindRightCheck neither child present
                    ldd       #76       'L' left child only
                    bra       EmitKindChar emit the kind char

KindRightCheck      ldd       12,u      load right child
                    beq       KindNone  no children present
                    ldd       #82       'R' right child only
                    bra       EmitKindChar emit the kind char

KindNone            ldd       #78       'N' no children
EmitKindChar        std       ,s        store the kind char
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    ldd       2,s       load the kind char
                    pshs      d         pass char
                    lbsr      PutChar2  emit the kind char
                    leas      4,s        drop the two call arguments
                    ldd       GlbVar0025 load the output stream global
                    pshs      d         push as first argument
                    ldd       ,u        load first structure field
                    pshs      d         push as value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the two arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       2,u       load next structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       6,u       load structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       14,u      load structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    leax      LineBuffer,y   point at global table base
                    pshs      x         save base pointer
                    ldd       16,u      load structure field
                    subd      ,s++      subtract base to get relative value
                    pshs      d         push the computed value
                    lbsr      PutChar2  emit the relative value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       18,u      load structure field
                    pshs      d         push value argument
                    lbsr      PutChar2  emit the value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       20,u      load structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       6,u       load the type code field
                    cmpd      #52       check for type code $34
                    lbne      CheckFloatType branch if not that type
                    ldu       8,u       follow pointer to sub-node
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       ,u        load sub-node field
                    pshs      d         push value argument
                    lbsr      PutChar2  emit the value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       8,u       load sub-node field
                    pshs      d         push value argument
                    lbsr      PutChar2  emit the value
                    leas      4,s        drop the arguments
                    ldx       8,u       load sub-node tag
                    bra       CheckExprTag check tag against known set

EmitSubExpr         pshs      u         save node pointer
                    ldd       #20       offset to sub-field
                    addd      ,s++      add to node pointer
                    pshs      d         push the field address
                    lbsr      EmitName8 recurse to emit sub-expression
                    leas      2,s        drop the argument
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    clra                high byte zero
                    clrb                form zero value
                    pshs      d         push zero value
                    lbsr      PutChar2  emit the value
                    lbra      EmitCleanup done, clean up and return

EmitFieldValue      ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       6,u       load field value
                    lbra      PushEmitValue emit and finish

CheckExprTag        cmpx      #14       tag equals code $0E
                    beq       EmitSubExpr handle as sub-expression
                    cmpx      #12       tag equals code $0C
                    lbeq      EmitSubExpr handle as sub-expression
                    cmpx      #33       tag equals code $21
                    lbeq      EmitSubExpr handle as sub-expression
                    cmpx      #34       tag equals code $22
                    lbeq      EmitSubExpr handle as sub-expression
                    bra       EmitFieldValue otherwise emit field value

CheckFloatType      ldd       6,u       load the type code
                    cmpd      #74       is it float type $4A
                    bne       CheckDoubleType no, check double type
                    leas      -4,s       allocate 4-byte temp buffer
                    leax      ,s        point at the temp buffer
                    pshs      x         push buffer pointer
                    bsr       FloatConstAddr skip over inline float constant
                    fcb       0,$00,$00,$00
FloatConstAddr      puls      x         recover the constant address
                    lbsr      StoreLong copy the float constant
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       #1        element count one
                    pshs      d         push element count
                    ldd       #4        element size four bytes
                    pshs      d         push element size
                    ldu       8,u       follow the value pointer
                    beq       UseFloatTemp null, use the temp buffer
                    tfr       u,d       use the value pointer
                    bra       EmitFloatData go push data pointer

UseFloatTemp        leax      6,s       point at the temp buffer
                    tfr       x,d       use the buffer address
EmitFloatData       pshs      d         push the data pointer
                    lbsr      EmitFloatBytes emit the float bytes
                    leas      8,s        drop the arguments
                    bra       EmitCleanup clean up and return

CheckDoubleType     ldd       6,u       load the type code
                    cmpd      #75       is it double type $4B
                    bne       EmitDefaultValue no, take default path
                    leas      -8,s       allocate 8-byte temp buffer
                    leax      ,s        point at the temp buffer
                    pshs      x         push buffer pointer
                    bsr       DoubleConstAddr skip over inline double constant
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
DoubleConstAddr     puls      x         recover the constant address
                    lbsr      SwapNumWork copy the double constant
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       #1        element count one
                    pshs      d         push element count
                    ldd       #8        element size eight bytes
                    pshs      d         push element size
                    ldu       8,u       follow the value pointer
                    beq       UseDoubleTemp null, use the temp buffer
                    tfr       u,d       use the value pointer
                    bra       EmitDoubleData go push data pointer

UseDoubleTemp       leax      6,s       point at the temp buffer
                    tfr       x,d       use the buffer address
EmitDoubleData      pshs      d         push the data pointer
                    lbsr      EmitFloatBytes emit the double bytes
                    leas      8,s        drop the arguments
                    leas      8,s        release the temp buffer
                    lbra      EmitReturn clean up and return

EmitDefaultValue    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       8,u       load the value field
PushEmitValue       pshs      d         push value argument
                    lbsr      PutWord   emit the value
EmitCleanup         leas      4,s        drop the arguments
                    lbra      EmitReturn return

EmitInitList        pshs      u         save the caller u register
                    ldd       #$FFB8    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the node argument
                    leas      -2,s       allocate a local
                    lbsr      EmitFdb   get the element count
                    ldd       8,s       load the returned count
                    cmpd      #1        single element
                    bne       InitNotSingle no, handle multiple elements
                    pshs      u         push the node pointer
                    lbsr      EmitDecimal emit the single initializer
InitDone            leas      2,s        drop the argument
                    lbra      InitFinish2 finish the emit

InitNotSingle       cmpu      #0        is the node pointer null
                    bne       InitEachElem no, emit each element
                    ldd       #1        start index at one
                    std       ,s        store loop counter
                    bra       ZeroFillTest enter the zero-fill loop

ZeroFillLoop2       leax      StrZeroComma,pcr point at the "0," string
                    pshs      x         push string argument
                    lbsr      EmitText  output the string
                    leas      2,s        drop the argument
ZeroFillTest        ldd       ,s        load loop counter
                    addd      #1        increment counter
                    std       ,s        store it back
                    subd      #1        restore pre-increment value
                    cmpd      8,s       compare against element count
                    blt       ZeroFillLoop2 loop while below the count
                    ldd       #'0       character '0'
                    pshs      d         push it
                    lbsr      EmitCharOut output the final zero
                    bra       InitDone  finish

InitEachElem        clra                high byte zero
                    clrb                index starts at zero
                    bra       ElemNext  enter the element loop

ElemLoop            ldd       ,u++      load next element pointer
                    pshs      d         push the element
                    lbsr      EmitDecimal emit the initializer
                    leas      2,s        drop the argument
                    ldd       8,s       load the element count
                    addd      #$FFFF    count minus one
                    cmpd      ,s        is this the last element
                    beq       ElemNoComma yes, skip the separator
                    ldd       #',       character ','
                    pshs      d         push the separator
                    lbsr      EmitCharOut output the comma
                    leas      2,s        drop the argument
ElemNoComma         ldd       ,s        load the index
                    addd      #1        increment the index
ElemNext            std       ,s        store the index
                    ldd       ,s        reload the index
                    cmpd      8,s       compare against the count
                    blt       ElemLoop  loop over the elements
InitFinish2         lbsr      EmitNewline finish the output
EmitReturn          leas      2,s        release the local
EmitRet2            puls      pc,u      restore and return

EmitFloatField      pshs      u         save the caller u register
                    ldd       #$FFB4    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the node argument
                    ldd       #'f       character 'f' marker
                    pshs      d         push it
                    lbsr      EmitCharOut output the 'f' marker
                    leas      2,s        drop the argument
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       8,s       load the value field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       #1        element count one
                    pshs      d         push element count
                    ldd       #8        element size eight bytes
                    pshs      d         push element size
                    pshs      u         push the node pointer
                    lbsr      EmitFloatBytes emit the double value bytes
                    leas      8,s        drop the arguments
                    puls      pc,u      restore and return

AdvanceOffset       pshs      u         save the caller u register
                    ldd       #$FFB8    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       load the node argument
                    ldd       20,u      load current offset field
                    addd      6,s       add increment argument
                    std       20,u      store updated offset
                    pshs      u         push the node pointer
                    ldd       #5        selector value five
                    pshs      d         push the selector
                    lbsr      EmitNodeRecord process node with selector
                    leas      4,s        drop the arguments
                    puls      pc,u      restore and return

FmtPctD             fcc       /%d/
                    fcb       C$NULL
FmtPct8s            fcc       /%.8s/
                    fcb       C$NULL
FmtFPctS            fcc       /F%s/
                    fcb       C$CR,C$NULL
StrZeroComma        fcc       /0,/
                    fcb       C$NULL
PrintfBuf           pshs      u         save the caller u register
                    leax      StdoutStream,y   point at internal output buffer
                    stx       GlbVar000F set the output pointer global
                    ldd       #1        mode one, stream output
                    std       GlbVar0015 set the output mode
                    leax      6,s       point past the format argument
                    pshs      x         push the varargs pointer
                    ldd       6,s       load the format string argument
                    bra       RunPrintf run the formatter

fprintf             pshs      u         save the caller u register
                    ldd       4,s       load the stream argument
                    std       GlbVar000F set the output pointer global
                    ldd       #1        mode one, stream output
                    std       GlbVar0015 set the output mode
                    leax      8,s       point past the arguments
                    pshs      x         push the varargs pointer
                    ldd       8,s       load the format string argument
RunPrintf           pshs      d         push the format string
                    bsr       doprnt    run the formatter
                    leas      4,s        drop the arguments
                    puls      pc,u      restore and return

Sprintf             pshs      u         save the caller u register
                    ldd       4,s       load the destination buffer argument
                    std       GlbVar000F set the output pointer global
                    ldd       #2        mode two, memory buffer output
                    std       GlbVar0015 set the output mode
                    leax      8,s       point past the arguments
                    pshs      x         push the varargs pointer
                    ldd       8,s       load the format string argument
                    pshs      d         push the format string
                    bsr       doprnt    run the formatter
                    leas      4,s        drop the arguments
                    clra                high byte zero
                    clrb                form null byte
                    stb       [>GlbVar000F,y] null-terminate the output buffer
                    puls      pc,u      restore and return

doprnt              pshs      u         save the caller u register
                    ldu       4,s       load the format string pointer
                    leas      -11,s      allocate the local frame
                    bra       FmtScanLoop enter the format scan loop

PutLiteralChar      ldb       8,s       load the current char
                    lbeq      FmtDone   null terminator ends the format
                    ldb       8,s       reload the char
                    sex                 sign extend to word
                    pshs      d         push the char
                    lbsr      PutChar   output the literal character
                    leas      2,s        drop the argument
FmtScanLoop         ldb       ,u+       read next format char
                    stb       8,s       save the current char
                    cmpb      #'%       is it '%'
                    bne       PutLiteralChar no, output literally
                    ldb       ,u+       read the conversion char
                    stb       8,s       save it
                    clra                high byte zero
                    clrb                form zero
                    std       2,s       clear the precision
                    std       6,s       clear the width
                    ldb       8,s       load the conversion char
                    cmpb      #'-       is it the '-' flag
                    bne       NoLeftFlag no left-justify flag
                    ldd       #1        flag value one
                    std       GlbVar0011 set left-justify flag
                    ldb       ,u+       read the next char
                    stb       8,s       save the char
                    bra       CheckZeroFlag continue parsing

NoLeftFlag          clra                high byte zero
                    clrb                form zero
                    std       GlbVar0011 clear left-justify flag
CheckZeroFlag       ldb       8,s       load the char
                    cmpb      #'0       is it the '0' flag
                    bne       PadSpace  no, use space padding
                    ldd       #'0       pad character '0'
                    bra       StorePadChar store the pad char

PadSpace            ldd       #'        pad character space
StorePadChar        std       GlbVar0013 store the pad character
                    bra       CheckWidthDigit parse the width digits

WidthDigit          ldd       6,s       load the current width
                    pshs      d         push it
                    ldd       #10       multiplier ten
                    lbsr      MulEntry  multiply width by ten
                    pshs      d         push the product
                    ldb       10,s      load the digit char
                    sex                 sign extend
                    addd      #$FFD0    subtract '0' for digit value
                    addd      ,s++      add to width times ten
                    std       6,s       store the new width
                    ldb       ,u+       read the next char
                    stb       8,s       save the char
CheckWidthDigit     ldb       8,s       load the char
                    sex                 sign extend
                    leax      CtypeTab,y point at char class table
                    leax      d,x       index by the char
                    ldb       ,x        load the class byte
                    cmpb      #107      is it a digit class
                    beq       WidthDigit yes, accumulate width digit
                    ldb       8,s       load the char
                    cmpb      #'.       is it the '.' precision marker
                    bne       NoPrecision no precision given
                    ldd       #1        precision-present flag
                    std       4,s       set the precision flag
                    bra       CheckPrecDigit parse the precision digits

PrecDigit           ldd       2,s       load the current precision
                    pshs      d         push it
                    ldd       #10       multiplier ten
                    lbsr      MulEntry  multiply precision by ten
                    pshs      d         push the product
                    ldb       10,s      load the digit char
                    sex                 sign extend
                    addd      #$FFD0    subtract '0' for digit value
                    addd      ,s++      add to precision times ten
                    std       2,s       store the new precision
CheckPrecDigit      ldb       ,u+       read the next char
                    stb       8,s       save the char
                    ldb       8,s       reload the char
                    sex                 sign extend
                    leax      CtypeTab,y point at char class table
                    leax      d,x       index by the char
                    ldb       ,x        load the class byte
                    cmpb      #107      is it a digit class
                    beq       PrecDigit yes, accumulate precision digit
                    bra       DispatchConv done parsing precision

NoPrecision         clra                high byte zero
                    clrb                form zero
                    std       4,s       clear the precision flag
DispatchConv        ldb       8,s       load the conversion char
                    sex                 sign extend
                    tfr       d,x       index into dispatch
                    lbra      FmtDispatch dispatch on conversion char

FmtSignedDec        ldd       6,s       load the width
                    pshs      d         push the width
                    ldx       19,s      load value-args pointer
                    leax      2,x       advance past two-byte arg
                    stx       19,s      store updated pointer
                    ldd       -2,x      load the argument value
                    pshs      d         push the argument
                    lbsr      FormatSignedDecimal format signed integer
                    bra       StoreConvStr store result and continue

FmtUnsignedDec      ldd       6,s       load the width
                    pshs      d         push the width
                    ldx       19,s      load value-args pointer
                    leax      2,x       advance past two-byte arg
                    stx       19,s      store updated pointer
                    ldd       -2,x      load the argument value
                    pshs      d         push the argument
                    lbsr      IntToHex  format unsigned integer
StoreConvStr        std       ,s        save formatted string pointer
                    lbra      FmtOutStr output the field

FmtCharArg          ldx       17,s      load value-args pointer
                    leax      2,x       advance past two-byte arg
                    stx       17,s      store updated pointer
                    ldd       -2,x      load the argument value
                    lbra      FmtPutOne output the character field

FmtStringArg        ldx       17,s      load value-args pointer
                    leax      2,x       advance past two-byte arg
                    stx       17,s      store updated pointer
                    ldd       -2,x      load the string argument pointer
                    std       9,s       save the string pointer
                    ldd       4,s       load the precision flag
                    beq       FmtOutStrArg no precision, output full string
                    ldd       9,s       load the string pointer
                    std       4,s       set the scan pointer
                    bra       StrLenTest enter the length-limit loop

StrLenLoop          ldb       [9,s]     load char at string pointer
                    beq       StrLenDone end of the string
                    ldd       9,s       load the string pointer
                    addd      #1        advance the pointer
                    std       9,s       store the pointer
StrLenTest          ldd       2,s       load remaining precision
                    addd      #$FFFF    decrement it
                    std       2,s       store it back
                    subd      #$FFFF    restore pre-decrement value
                    bne       StrLenLoop loop while precision remains
StrLenDone          ldd       6,s       load the width
                    pshs      d         push the width
                    ldd       11,s      load range end pointer
                    subd      6,s       compute the range length
                    pshs      d         push length argument
                    ldd       8,s       load range start pointer
                    pshs      d         push start pointer argument
                    lbsr      OutputMemRange output the memory range
                    leas      6,s        drop the arguments
                    bra       FmtNextArg continue the format loop

FmtOutStrArg        ldd       6,s       load the argument value
                    pshs      d         push it
                    ldd       11,s      load the string pointer
                    pshs      d         push the string pointer
FmtOutStr           lbsr      OutputStringN output the string
                    leas      4,s        drop the arguments
FmtNextArg          lbra      FmtScanLoop back to the format loop

FmtLiteralChar      ldb       8,s       load the format character
                    sex                 sign extend to a word
FmtPutOne           pshs      d         push the character
                    lbsr      PutChar   output a single character
                    leas      2,s        drop the argument
                    lbra      FmtScanLoop back to the format loop

FmtDispatch         cmpx      #100      is it a 'd' decimal specifier
                    lbeq      FmtSignedDec handle decimal conversion
                    cmpx      #120      is it an 'x' hex specifier
                    lbeq      FmtUnsignedDec handle hex conversion
                    cmpx      #99       is it a 'c' char specifier
                    lbeq      FmtCharArg handle character output
                    cmpx      #115      is it an 's' string specifier
                    lbeq      FmtStringArg handle string output
                    bra       FmtLiteralChar otherwise output the literal character

FmtDone             leas      11,s       drop the format locals
                    puls      pc,u      return from format

FormatSignedDecimal pshs      u,d       save registers and reserve a local
                    leax      OutputBuffer,y   point at the conversion buffer
                    stx       ,s        save the buffer pointer
                    ldd       6,s       load the signed value
                    bge       ConvertAbsValue non-negative, skip sign handling
                    ldd       6,s       reload the value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        finish two's complement
                    std       6,s       store the absolute value
                    bge       EmitMinusSign negation valid, not the minimum
                    leax      MsgMinInt,pcr point at the -32768 text
                    pshs      x         push the string pointer
                    leax      OutputBuffer,y   point at the buffer
                    pshs      x         push the buffer pointer
                    lbsr      StrCpy    copy the literal string
                    leas      4,s        drop the arguments
                    lbra      FmtArgDone done with this argument

EmitMinusSign       ldd       #'-       the '-' character
                    ldx       ,s        load the buffer pointer
                    leax      1,x       advance the pointer
                    stx       ,s        save it back
                    stb       -1,x      store the minus sign
ConvertAbsValue     ldd       6,s       load the absolute value
                    pshs      d         push value argument
                    ldd       2,s       load the buffer pointer
                    pshs      d         push the buffer pointer
                    bsr       IntToDecimal convert to decimal digits
                    leas      4,s        drop the arguments
                    leax      OutputBuffer,y   point at the buffer start
                    tfr       x,d       return the buffer pointer
                    lbra      FmtArgDone done with this argument

IntToDecimal        pshs      u,y,x,d   save registers and reserve locals
                    ldu       10,s      load the output buffer pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       2,s       clear leading-zero flag
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear the digit counter
                    bra       DecNormalizeTest enter the normalize test

DecNormalizeLoop    ldd       ,s        load the counter
                    addd      #1        increment it
                    std       ,s        store the counter
                    ldd       12,s      load the running remainder
                    subd      Pow10,y   adjust by a power of ten
                    std       12,s      store the remainder
DecNormalizeTest    ldd       12,s      load the running remainder
                    blt       DecNormalizeLoop keep normalizing while below zero
                    leax      Pow10,y   point at the divisor table
                    stx       4,s       save the divisor pointer
                    bra       DecPowerLoop enter the digit loop

DecCountLoop        ldd       ,s        load the digit count
                    addd      #1        increment the digit
                    std       ,s        store the count
DecSubTest          ldd       12,s      load the remainder
                    subd      [4,s]     subtract the current power of ten
                    std       12,s      store the remainder
                    bge       DecCountLoop still fits, count another
                    ldd       12,s      load the remainder
                    addd      [4,s]     restore the last subtraction
                    std       12,s      store the remainder
                    ldd       ,s        load the digit value
                    beq       DecDigitSeen zero digit, skip flag
                    ldd       #1        set flag
                    std       2,s       mark significant digit seen
DecDigitSeen        ldd       2,s       load the significant flag
                    beq       DecStoreDigit none yet, suppress leading zero
                    ldd       ,s        load the digit
                    addd      #48       convert to ascii
                    stb       ,u+       store the digit character
DecStoreDigit       clra                clear high byte
                    clrb                clear low byte
                    std       ,s        reset the digit count
                    ldd       4,s       load the divisor pointer
                    addd      #2        advance to the next power
                    std       4,s       store the pointer
DecPowerLoop        ldd       4,s       load the divisor pointer
                    cmpd      GlbVar0001 reached the end of table
                    bne       DecSubTest more powers, continue
                    ldd       12,s      load the final remainder
                    addd      #48       convert last digit to ascii
                    stb       ,u+       store the final digit
                    clra                clear high byte
                    clrb                clear low byte
                    stb       ,u        null terminate the string
                    ldd       10,s      return the buffer pointer
                    leas      6,s        drop the locals
                    puls      pc,u      return

IntToHex            pshs      u,x,d     save registers and reserve locals
                    leax      OutputBuffer,y   point at the output buffer
                    stx       2,s       save the buffer pointer
                    leau      TempDigitBuffer,y   point at the temp digit buffer
HexNibbleLoop       ldd       8,s       load the value
                    clra                keep only the low byte
                    andb      #$0f      mask the low nibble
                    std       ,s        save the nibble
                    pshs      d         push the nibble
                    ldd       2,s       reload the nibble
                    cmpd      #9        is it greater than nine
                    ble       HexDigitBase decimal-range digit
                    ldd       #87       use 'a'-10 base for letters
                    bra       HexStoreNibble combine base and nibble

HexDigitBase        ldd       #48       use '0' base for digits
HexStoreNibble      addd      ,s++      add nibble to base, drop temp
                    stb       ,u+       store the hex character
                    ldd       8,s       load the value
                    lsra                shift right one bit
                    rorb                rotate low byte
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate, value now divided by sixteen
                    anda      #$0f      clear the high nibble
                    std       8,s       store the shifted value
                    bne       HexNibbleLoop more nibbles remain
                    bra       HexCopyTest enter the reversal loop

HexCopyLoop         ldb       ,u        load a digit from temp buffer
                    ldx       2,s       load the output pointer
                    leax      1,x       advance it
                    stx       2,s       store the pointer
                    stb       -1,x      copy the digit to output
HexCopyTest         leau      -1,u      step back through temp buffer
                    pshs      u         push the temp pointer
                    leax      TempDigitBuffer,y   point at temp buffer start
                    cmpx      ,s++      reached the start
                    bls       HexCopyLoop more digits to copy
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [2,s]     null terminate the output
                    leax      OutputBuffer,y   point at the output buffer
                    tfr       x,d       return the buffer pointer
                    lbra      PutCharCleanup done

OutputStringN       pshs      u         save u
                    ldu       6,s       load the string pointer
                    leas      -2,s       reserve a local
                    ldd       6,s       load the string pointer
                    pshs      d         push it
                    lbsr      strlen    compute the string length
                    leas      2,s        drop the argument
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        finish negation
                    leau      d,u       point past the string end
                    ldd       GlbVar0011 load the left-justify flag
                    bne       StrCharNext left justify, skip pre-padding
                    bra       StrPrePadTest check the pad width

StrPrePadLoop       ldd       GlbVar0013 load the pad character
                    pshs      d         push the pad character
                    lbsr      PutChar   output the padding
                    leas      2,s        drop the argument
StrPrePadTest       tfr       u,d       load the remaining width
                    leau      -1,u      decrement it
                    std       -2,s      save the counter
                    bgt       StrPrePadLoop pad while width remains
                    bra       StrCharNext done pre-padding

StrCharOut          ldd       ,s        load the current character
                    pshs      d         push it
                    lbsr      PutChar   output the character
                    leas      2,s        drop the argument
StrCharNext         ldx       6,s       load the string pointer
                    leax      1,x       advance it
                    stx       6,s       store the pointer
                    ldb       -1,x      load the next character
                    sex                 sign extend
                    std       ,s        save the character
                    bne       StrCharOut non-null, output it
                    ldd       GlbVar0011 load the left-justify flag
                    lbeq      FmtArgDone right justify done, return
                    bra       StrPostPadTest do post-padding

StrPostPadLoop      ldd       GlbVar0013 load the pad character
                    pshs      d         push the pad character
                    lbsr      PutChar   output the padding
                    leas      2,s        drop the argument
StrPostPadTest      tfr       u,d       load the remaining width
                    leau      -1,u      decrement it
                    std       -2,s      save the counter
                    bgt       StrPostPadLoop pad while width remains
                    lbra      FmtArgDone return

OutputMemRange      pshs      u         save u
                    ldu       4,s       load the range start pointer
                    leas      -2,s       reserve a local
                    ldd       10,s      load the range end
                    subd      8,s       compute the length
                    std       ,s        save the remaining count
                    ldd       GlbVar0011 load the left-justify flag
                    bne       RangeByteTest left justify, skip pre-padding
                    bra       RangePrePadTest check the pad width

RangePrePadLoop     ldd       GlbVar0013 load the pad character
                    pshs      d         push the pad character
                    bsr       PutChar   output the padding
                    leas      2,s        drop the argument
RangePrePadTest     ldd       ,s        load the width counter
                    addd      #$FFFF    decrement it
                    std       ,s        store the counter
                    subd      #$FFFF    test the count
                    bgt       RangePrePadLoop pad while width remains
                    bra       RangeByteTest done pre-padding

RangeByteOut        ldb       ,u+       load the next byte from range
                    sex                 sign extend
                    pshs      d         push the byte
                    bsr       PutChar   output the byte
                    leas      2,s        drop the argument
RangeByteTest       ldd       8,s       load the remaining length
                    addd      #$FFFF    decrement it
                    std       8,s       store the length
                    subd      #$FFFF    test the count
                    bne       RangeByteOut more bytes to output
                    ldd       GlbVar0011 load the left-justify flag
                    beq       FmtArgDone right justify done, return
                    bra       RangePostPadTest do post-padding

RangePostPadLoop    ldd       GlbVar0013 load the pad character
                    pshs      d         push the pad character
                    bsr       PutChar   output the padding
                    leas      2,s        drop the argument
RangePostPadTest    ldd       ,s        load the width counter
                    addd      #$FFFF    decrement it
                    std       ,s        store the counter
                    subd      #$FFFF    test the count
                    bgt       RangePostPadLoop pad while width remains
FmtArgDone          leas      2,s        drop the local
                    puls      pc,u      return

PutChar             pshs      u         save u
                    ldd       GlbVar0015 load the output mode flag
                    cmpd      #2        buffer mode
                    bne       PutCharFile file mode, write out
                    ldd       4,s       load the character
                    ldx       GlbVar000F load the buffer pointer
                    leax      1,x       advance it
                    stx       GlbVar000F store the pointer
                    stb       -1,x      store the character in buffer
                    bra       PutCharDone done

PutCharFile         ldd       GlbVar000F load the file handle
                    pshs      d         push it
                    ldd       6,s       load the character
                    pshs      d         push it
                    lbsr      PutChar2  write the character to output
PutCharCleanup      leas      4,s        drop the arguments
PutCharDone         puls      pc,u      return

MsgMinInt           fcc       /-32768/
                    fcb       C$NULL
CvtFloatDigits      ldx       2,s       load pointer to bignum accumulator
                    leas      -8,s       reserve a local copy
                    ldd       5,x       load the low word
                    aslb                shift left one bit
                    rola                rotate high byte
                    std       5,x       store the doubled low word
                    std       5,s       save a copy
                    ldd       3,x       load the next word
                    rolb                shift left with carry
                    rola                rotate high byte
                    std       3,x       store it
                    std       3,s       save a copy
                    ldd       1,x       load the next word
                    rolb                shift left with carry
                    rola                rotate high byte
                    std       1,x       store it
                    std       1,s       save a copy
                    lda       ,x        load the top byte
                    rola                shift left with carry
                    sta       ,x        store it
                    sta       ,s        save a copy, accumulator now doubled
                    asl       6,x       shift accumulator left again
                    rol       5,x       propagate carry
                    rol       4,x       propagate carry
                    rol       3,x       propagate carry
                    rol       2,x       propagate carry
                    rol       1,x       propagate carry
                    rol       ,x        top byte, value now times four
                    bcs       MulOverflow overflow
                    asl       6,x       shift left again
                    rol       5,x       propagate carry
                    rol       4,x       propagate carry
                    rol       3,x       propagate carry
                    rol       2,x       propagate carry
                    rol       1,x       propagate carry
                    rol       ,x        top byte, value now times eight
                    bcs       MulOverflow overflow
                    ldd       5,x       load low word times eight
                    addd      5,s       add the saved copy times two
                    std       5,x       store, value now times ten
                    ldd       3,x       load the next word
                    adcb      4,s       add with carry
                    adca      3,s       add with carry
                    std       3,x       store it
                    ldd       1,x       load the next word
                    adcb      2,s       add with carry
                    adca      1,s       add with carry
                    std       1,x       store it
                    ldb       ,x        load the top byte
                    adcb      ,s        add with carry
                    stb       ,x        store, accumulator times ten
                    bcs       MulOverflow overflow
                    ldb       13,s      load the incoming digit
                    andb      #$0f      mask to a nibble
                    clra                clear the high byte
                    addd      5,x       add digit to the low word
                    std       5,x       store it
                    ldd       #0        zero
                    adcb      4,x       propagate carry
                    adca      3,x       propagate carry
                    std       3,x       store it
                    ldd       #0        zero
                    adcb      2,x       propagate carry
                    adca      1,x       propagate carry
                    std       1,x       store it
                    lda       #0        zero
                    adca      ,x        propagate carry to top byte
                    sta       ,x        store the final accumulator
                    bcs       MulOverflow overflow
                    leas      8,s        drop the local
                    clra                clear high byte
                    clrb                return success
                    rts                 return

MulOverflow         ldd       #1        overflow result
                    leas      8,s        drop the local
                    rts                 return

ScanToken           pshs      u         save u
                    leas      -21,s      reserve locals
                    lbsr      SkipWhitespace read the next input token
                    ldb       GlbVar0065 load the token class
                    sex                 sign extend
                    cmpd      #$FFFF    end of input
                    bne       ScanTokenBody not eof, continue
                    ldd       #$FFFF    the eof marker
                    std       GlbVar005F store the token result
                    leas      21,s       drop the locals
                    puls      pc,u      return

ScanTokenBody       ldd       GlbVar006A load the current position
                    addd      #$FFFF    step back one
                    std       GlbVar0063 save the start position
                    ldd       GlbLineNum load the current line pointer
                    std       GlbVar003F save it
                    bra       ScanClassLoop enter the scan loop

BadCharErr          leax      MsgBadChar,pcr point at the bad-character message
                    pshs      x         push it
                    lbsr      PrintErrLoc print the error message
                    leas      2,s        drop the argument
                    lbsr      NextChar  advance the scanner
                    ldd       GlbVar006A load the position
                    std       GlbVar0063 update the start position
ScanClassLoop       ldb       GlbVar0065 load the character class
                    sex                 sign extend
                    leax      CtypeTab,y point at the transition table
                    leax      d,x       index by the class
                    ldb       ,x        load the next state
                    sex                 sign extend
                    std       GlbVar005F store the state
                    beq       BadCharErr still skipping, loop
                    ldb       GlbVar0065 load the character class
                    sex                 sign extend
                    leax      ActionTable,y   point at the action table
                    leax      d,x       index by the class
                    ldb       ,x        load the action code
                    sex                 sign extend
                    std       GlbVar0061 store the action
                    ldx       GlbVar005F load the token state
                    lbra      DispatchOpTail process the token

BuildExprNode       leax      10,s      point at first operand slot
                    pshs      x         push it
                    lbsr      ScanIdentifier parse the left operand
                    leas      2,s        drop the argument
                    leax      10,s      point at second operand slot
                    pshs      x         push it
                    lbsr      LookupSymbol parse the right operand
                    leas      2,s        drop the argument
                    tfr       d,u       node pointer
                    ldd       ,u        load the node type
                    std       GlbVar005F save the type
                    cmpd      #51       is it a specific node type
                    bne       ExprNodeDefault no, build a default node
                    ldd       8,u       load a node subfield
                    std       GlbVar0061 save the value
                    cmpd      #59       matches a special value
                    lbne      ClassifyOpExit no, emit the node
                    ldd       #59       special node type
                    std       GlbVar005F set the type
                    ldd       #14       special value
                    std       GlbVar0061 set the value
                    lbra      ClassifyOpExit emit the node

ExprNodeDefault     ldd       #52       default node type
                    std       GlbVar005F set the type
                    stu       GlbVar0061 store node pointer as value
                    lbra      ClassifyOpExit emit the node

ParseExprOne        leax      ,s        point at a local slot
                    pshs      x         push the pointer argument
                    ldd       #1        the flag value
                    pshs      d         push the flag
                    lbsr      ScanNumber evaluate the expression
                    leas      4,s        drop the arguments
                    std       19,s      store the result
                    bra       ClassifyOpEntry enter operator classification

ClassifyOpReenter   leas      -21,x     restore stack frame after building node
ClassifyOpEntry     leax      ,s        point at current frame
                    stx       8,s       save the caller u register local
                    ldx       19,s      load the operator token type
                    bra       DispatchSpecialTok dispatch on special token

TokLoadPrec         ldd       [8,s]     load precedence via node pointer
                    bra       SetPrecDefaultOp store it as precedence

TokBuildNode4       ldd       #4        request four bytes
                    pshs      d         pass size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop size argument
                    tfr       d,u       keep node pointer
                    leax      ,u        point at the new node
                    pshs      x         pass node pointer
                    ldx       10,s      load the current operand
                    lbsr      StoreLong build the subtree
                    stu       GlbVar0061 store node as operand
                    ldd       #74       opcode for this operator
                    bra       StoreOpcodeExit store opcode and exit

TokBuildNode8       ldd       #8        request eight bytes
                    pshs      d         pass size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop size argument
                    tfr       d,u       keep node pointer
                    leax      ,u        point at the new node
                    pshs      x         pass node pointer
                    ldx       10,s      load the current operand
                    lbsr      SwapNumWork build the subtree
                    stu       GlbVar0061 store node as operand
                    ldd       #75       opcode for this operator
                    bra       StoreOpcodeExit store opcode and exit

TokUnknownErr       leax      MsgConstOverflow,pcr point at error message
                    pshs      x         pass message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
                    ldd       #1        default precedence
SetPrecDefaultOp    std       GlbVar0061 set operator precedence
                    ldd       #54       default opcode
StoreOpcodeExit     std       GlbVar005F set operator opcode
                    lbra      ClassifyOpExit done classifying

DispatchSpecialTok  cmpx      #1        token type one
                    beq       TokLoadPrec handle it
                    cmpx      #8        token type eight
                    beq       TokBuildNode4 handle it
                    cmpx      #6        token type six
                    beq       TokBuildNode8 handle it
                    bra       TokUnknownErr otherwise unknown operator

TokOp36Form         lbsr      ParseCharConst parse this operand form
                    ldd       #54       opcode for it
                    bra       StoreOpcode5F store and exit

TokOp37Form         lbsr      ParseStringConst parse alternate operand form
                    ldd       #55       opcode for it
StoreOpcode5F       std       GlbVar005F set operator opcode
                    lbra      ClassifyOpExit done

ClassifyBinOp       lbsr      NextChar  consume the operator token
                    ldx       GlbVar005F reload the opcode value
                    lbra      DispatchBinOp classify the binary operator

OpSubscript         ldb       GlbVar0065 lookahead character
                    sex                 sign extend to d
                    leax      CtypeTab,y base of the character-class table
                    leax      d,x       index by the character
                    ldb       ,x        fetch its class byte
                    cmpb      #107      is it the expected class
                    lbne      ClassifyOpExit no, abandon classification
                    leax      ,s        point at frame
                    pshs      x         pass frame pointer
                    ldd       #6        size argument
                    pshs      d         pass size argument
                    lbsr      ScanNumber build indexed node
                    leas      4,s        drop arguments
                    std       19,s      save resulting token
                    leax      21,s      recompute frame pointer
                    lbra      ClassifyOpReenter re-dispatch on the node

OpAnd               ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkAndNext check ampersand follow-on

OpLogAnd            ldd       #71       opcode for logical and
                    std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #5        precedence for logical and
                    bra       StorePrecExit set precedence and exit

OpAndAssign         ldd       #167      opcode for and-assign
                    std       GlbVar005F set operator opcode
                    ldd       #2        precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

ChkAndNext          cmpx      #38       following ampersand
                    beq       OpLogAnd  logical and
                    cmpx      #61       following equals
                    beq       OpAndAssign and-assign
                    lbra      ClassifyOpExit plain and, done

OpXorAssign         ldb       GlbVar0065 lookahead character
                    cmpb      #'=       is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       #90       opcode for xor-assign
                    std       GlbVar005F set operator opcode
                    ldd       #9        precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

OpOr                ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkOrNext check pipe follow-on

OpLogOr             ldd       #72       opcode for logical or
                    std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #4        precedence for logical or
                    bra       StorePrecExit set precedence and exit

OpOrAssign          ldd       #168      opcode for or-assign
StoreOpAdvance      std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #2        precedence for assignment
StorePrecExit       std       GlbVar0061 set operator precedence
                    lbra      ClassifyOpExit done

ChkOrNext           cmpx      #124      following pipe
                    beq       OpLogOr   logical or
                    cmpx      #61       following equals
                    beq       OpOrAssign or-assign
                    lbra      ClassifyOpExit plain or, done

OpEqEq              ldb       GlbVar0065 lookahead character
                    cmpb      #'=       is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       #91       opcode for equality
                    std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #9        precedence for equality
                    bra       StorePrecExit set precedence and exit

OpNotEq             ldb       GlbVar0065 lookahead character
                    cmpb      #'=       is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       #162      opcode for not-equal
                    bra       StoreOpAdvance store and set precedence

OpMulDivModAssign   ldb       GlbVar0065 lookahead character
                    cmpb      #'=       is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       GlbVar005F current operator opcode
                    addd      #80       bias to compound-assign form
                    lbra      StoreOpAdvance store and set precedence

OpLess              ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkLessNext check less-than follow-on

OpShiftLeft         ldd       #86       opcode for shift left
                    std       GlbVar005F set operator opcode
                    ldd       #11       precedence for shift
                    std       GlbVar0061 set operator precedence
                    lbsr      NextChar  consume second character
                    ldb       GlbVar0065 new lookahead character
                    cmpb      #'=       is it equals
                    lbne      ClassifyOpExit plain shift, done
                    ldd       #166      opcode for shift-left-assign
                    std       GlbVar005F set operator opcode
                    ldd       #2        precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

OpLessEq            ldd       #92       opcode for less-or-equal
                    std       GlbVar005F set operator opcode
                    ldd       #10       precedence for comparison
                    lbra      StorePrecConsume store precedence and exit

ChkLessNext         cmpx      #60       following less-than
                    beq       OpShiftLeft shift left
                    cmpx      #61       following equals
                    beq       OpLessEq  less-or-equal
                    lbra      ClassifyOpExit plain less-than, done

OpGreater           ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkGreaterNext check greater-than follow-on

OpShiftRight        ldd       #85       opcode for shift right
                    std       GlbVar005F set operator opcode
                    ldd       #11       precedence for shift
                    std       GlbVar0061 set operator precedence
                    lbsr      NextChar  consume second character
                    ldb       GlbVar0065 new lookahead character
                    cmpb      #'=       is it equals
                    lbne      ClassifyOpExit plain shift, done
                    ldd       #165      opcode for shift-right-assign
                    std       GlbVar005F set operator opcode
                    ldd       #2        precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

OpGreaterEq         ldd       #94       opcode for greater-or-equal
                    std       GlbVar005F set operator opcode
                    ldd       #10       precedence for comparison
                    lbra      StorePrecConsume store precedence and exit

ChkGreaterNext      cmpx      #62       following greater-than
                    beq       OpShiftRight shift right
                    cmpx      #61       following equals
                    beq       OpGreaterEq greater-or-equal
                    lbra      ClassifyOpExit plain greater-than, done

OpPlus              ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkPlusNext check plus follow-on

OpIncrement         ldd       #60       opcode for increment
                    std       GlbVar005F set operator opcode
                    ldd       #14       precedence for increment
                    bra       StorePrecConsume store precedence and exit

OpPlusAssign        ldd       #160      opcode for plus-assign
                    std       GlbVar005F set operator opcode
                    ldd       #2        precedence for assignment
                    bra       StorePrecConsume store precedence and exit

ChkPlusNext         cmpx      #43       following plus
                    beq       OpIncrement increment
                    cmpx      #61       following equals
                    beq       OpPlusAssign plus-assign
                    lbra      ClassifyOpExit plain plus, done

OpMinus             ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkMinusNext check minus follow-on

OpDecrement         ldd       #61       opcode for decrement
                    std       GlbVar005F set operator opcode
                    ldd       #14       precedence for decrement
                    bra       StorePrecConsume store precedence and exit

OpMinusAssign       ldd       #161      opcode for minus-assign
                    std       GlbVar005F set operator opcode
                    ldd       #2        precedence for assignment
                    bra       StorePrecConsume store precedence and exit

OpArrow             ldd       #70       opcode for arrow operator
                    std       GlbVar005F set operator opcode
                    ldd       #15       precedence for arrow
StorePrecConsume    std       GlbVar0061 set operator precedence
                    lbsr      NextChar  consume second character
                    lbra      ClassifyOpExit done

ChkMinusNext        cmpx      #45       following minus
                    beq       OpDecrement decrement
                    cmpx      #61       following equals
                    beq       OpMinusAssign minus-assign
                    cmpx      #62       following greater-than
                    beq       OpArrow   arrow operator
                    lbra      ClassifyOpExit plain minus, done

DispatchBinOp       cmpx      #69       subscript operator token
                    lbeq      OpSubscript handle it
                    cmpx      #65       and operator token
                    lbeq      OpAnd     handle it
                    cmpx      #120      xor operator token
                    lbeq      OpXorAssign handle it
                    cmpx      #88       or operator token
                    lbeq      OpOr      handle it
                    cmpx      #64       equals operator token
                    lbeq      OpEqEq    handle it
                    cmpx      #66       bang operator token
                    lbeq      OpNotEq   handle it
                    cmpx      #83       star operator token
                    lbeq      OpMulDivModAssign handle it
                    cmpx      #'T       slash operator token
                    lbeq      OpMulDivModAssign handle it
                    cmpx      #89       percent operator token
                    lbeq      OpMulDivModAssign handle it
                    cmpx      #93       less-than operator token
                    lbeq      OpLess    handle it
                    cmpx      #95       greater-than operator token
                    lbeq      OpGreater handle it
                    cmpx      #80       plus operator token
                    lbeq      OpPlus    handle it
                    cmpx      #67       minus operator token
                    lbeq      OpMinus   handle it
                    bra       ClassifyOpExit unrecognised, done

DispatchOpTail      cmpx      #106      token type six-a
                    lbeq      BuildExprNode handle it
                    cmpx      #107      token type six-b
                    lbeq      ParseExprOne handle it
                    cmpx      #104      token type six-eight
                    lbeq      TokOp36Form handle it
                    cmpx      #105      token type six-nine
                    lbeq      TokOp37Form handle it
                    lbra      ClassifyBinOp otherwise classify binary op

ClassifyOpExit      leas      21,s       release stack frame
                    puls      pc,u      restore and return

InitKeywordTable    pshs      u         save the caller u register
                    ldd       #6        token code for this keyword
                    pshs      d         pass token code
                    leax      KwDouble,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword in table
                    leas      4,s        drop arguments
                    ldd       #5        token code for keyword
                    pshs      d         pass token code
                    leax      KwFloat,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #_start   token code for keyword
                    pshs      d         pass token code
                    leax      KwTypedef,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #15       token code for keyword
                    pshs      d         pass token code
                    leax      KwStatic,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #59       token code for keyword
                    pshs      d         pass token code
                    leax      KwSizeof,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #1        token code for keyword
                    pshs      d         pass token code
                    leax      KwInt,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #1        flag value
                    std       GlbVar0041 mark keyword class active
                    ldd       #1        token code for keyword
                    pshs      d         pass token code
                    leax      KwIntB,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #5        token code for keyword
                    pshs      d         pass token code
                    leax      KwFloatB,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0041 clear keyword class flag
                    ldd       #2        token code for keyword
                    pshs      d         pass token code
                    leax      KwChar,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #10       token code for keyword
                    pshs      d         pass token code
                    leax      KwShort,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #13       token code for keyword
                    pshs      d         pass token code
                    leax      KwAuto,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #14       token code for keyword
                    pshs      d         pass token code
                    leax      KwExtern,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #33       token code for keyword
                    pshs      d         pass token code
                    leax      KwDirect,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #16       token code for keyword
                    pshs      d         pass token code
                    leax      KwRegister,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #29       token code for keyword
                    pshs      d         pass token code
                    leax      KwGoto,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #18       token code for keyword
                    pshs      d         pass token code
                    leax      KwReturn,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #19       token code for keyword
                    pshs      d         pass token code
                    leax      KwIf,pcr  keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #20       token code for keyword
                    pshs      d         pass token code
                    leax      KwWhile,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #21       token code for keyword
                    pshs      d         pass token code
                    leax      KwElse,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #22       token code for keyword
                    pshs      d         pass token code
                    leax      KwSwitch,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #23       token code for keyword
                    pshs      d         pass token code
                    leax      KwCase,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #24       token code for keyword
                    pshs      d         pass token code
                    leax      KwBreak,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #25       token code for keyword
                    pshs      d         pass token code
                    leax      KwContinue,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #26       token code 0x1a for keyword
                    pshs      d         pass the token code
                    leax      KwDo,pcr  point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #27       token code 0x1b
                    pshs      d         pass the token code
                    leax      KwDefault,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #28       token code 0x1c
                    pshs      d         pass the token code
                    leax      KwFor,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #4        token code 4
                    pshs      d         pass the token code
                    leax      KwStruct,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #3        token code 3
                    pshs      d         pass the token code
                    leax      KwUnion,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #7        token code 7
                    pshs      d         pass the token code
                    leax      KwUnsigned,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #8        token code 8
                    pshs      d         pass the token code
                    leax      KwLong,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    leax      KwErrno,pcr point to symbol name string
                    pshs      x         pass name pointer argument
                    lbsr      LookupSymbol look up or create symbol node
                    leas      2,s        drop the argument
                    tfr       d,u       symbol node pointer into u
                    ldd       #1        kind value 1
                    std       ,u        set node kind field
                    ldd       #14       value 0x0e
                    std       8,u       set node value field
                    ldd       #2        type value 2
                    std       2,u       set node type field
                    leax      KwLseek,pcr point to symbol name string
                    pshs      x         pass name pointer argument
                    lbsr      LookupSymbol look up or create symbol node
                    leas      2,s        drop the argument
                    tfr       d,u       symbol node pointer into u
                    ldd       #56       kind value 0x38
                    std       ,u        set node kind field
                    ldd       #12       value 0x0c
                    std       8,u       set node value field
                    ldd       #4        type value 4
                    std       2,u       set node type field
                    puls      pc,u      return from keyword setup

ScanIdentifier      pshs      u         save the caller u register
                    ldu       4,s       load output buffer pointer
                    leas      -2,s       reserve char counter local
                    ldd       #1        start count at one
                    bra       IdentCopyTest enter copy test

IdentCopyLoop       ldb       GlbVar0065 load current source character
                    stb       ,u+       store character into buffer
                    lbsr      NextChar  advance to next source character
                    ldd       ,s        load current count
                    addd      #1        increment character count
IdentCopyTest       std       ,s        save updated count
                    ldb       GlbVar0065 load current source character
                    sex                 sign-extend to word
                    pshs      d         pass the character
                    bsr       IsIdentChar test if identifier character
                    std       ,s++      pop the result
                    beq       LoadFinalCount stop if not identifier char
                    ldd       ,s        load count
                    cmpd      #8        compare against eight-char limit
                    ble       IdentCopyLoop keep copying while within limit
LoadFinalCount      ldd       ,s        load final count
                    cmpd      #2        was it exactly two chars
                    bne       ClearTerminator skip if not two
                    ldd       #'_       underscore fill character
                    stb       ,u+       append underscore to buffer
ClearTerminator     clra                clear terminator byte
                    clrb                clear low byte
                    stb       ,u        null terminate the buffer
                    bra       IdentSkipTest enter skip loop

IdentSkipRest       lbsr      NextChar  advance past extra ident char
IdentSkipTest       ldb       GlbVar0065 load current source character
                    sex                 sign-extend to word
                    pshs      d         pass the character
                    bsr       IsIdentChar test if identifier character
                    std       ,s++      pop the result
                    bne       IdentSkipRest skip remaining identifier chars
                    lbra      PopRetU   return via shared epilogue

IsIdentChar         pshs      u         save the caller u register
                    ldd       4,s       load the character argument
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index by character
                    ldb       ,x        load character class
                    cmpb      #'j       class 0x6a is a letter
                    beq       IdentCharYes yes it is ident char
                    ldd       4,s       reload character argument
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index by character
                    ldb       ,x        load character class
                    cmpb      #'k       class 0x6b is digit or underscore
                    bne       IdentCharNo not an identifier char
IdentCharYes        ldd       #1        return true
                    bra       IdentCharDone go to return

IdentCharNo         clra                clear high byte
                    clrb                clear low byte for false
IdentCharDone       puls      pc,u      return result

LookupSymbol        pshs      u,y,x,d   save registers
                    ldd       GlbVar0041 load table-select flag
                    beq       UseTableB use table b if zero
                    leax      SymbolTable,y   point to symbol table a
                    bra       HashLookup skip alternate table

UseTableB           leax      SymbolTableB,y   point to symbol table b
HashLookup          tfr       x,d       table base to d
                    std       2,s       save table base local
                    ldd       10,s      load name pointer argument
                    pshs      d         pass the name
                    lbsr      HashName  hash the name string
                    leas      2,s        drop argument
                    aslb                double the hash
                    rola                finish doubling
                    addd      2,s       add table base for bucket slot
                    std       4,s       save bucket slot address
                    ldu       [4,s]     load bucket chain head
                    bra       ChainWalk enter chain walk

CompareNames        ldb       20,u      load node kind byte
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       [12,s]    load search kind byte
                    sex                 sign-extend
                    cmpd      ,s++      compare node kind
                    bne       NextInChain skip if kind differs
                    ldd       #8        name length eight
                    pshs      d         pass length
                    pshs      u         pass node pointer
                    ldd       #20       offset to node name field
                    addd      ,s++      compute name field address
                    pshs      d         pass node name address
                    ldd       14,s      load search name pointer
                    pshs      d         pass search name
                    lbsr      strncmp   compare the two names
                    leas      6,s        drop arguments
                    std       -2,s      store compare result
                    beq       SymNodeReady match found so done
NextInChain         ldu       18,u      follow chain to next node
ChainWalk           stu       -2,s      save current node pointer
                    bne       CompareNames keep walking while non-null
                    ldu       GlbVar0019 load free list head
                    beq       AllocSymNode allocate fresh if empty
                    ldd       18,u      load next free node
                    std       GlbVar0019 pop node off free list
                    bra       InitSymNode go initialize node

AllocSymNode        ldd       #28       node size 0x1c
                    pshs      d         pass size
                    lbsr      AllocMem  allocate symbol node
                    leas      2,s        drop argument
                    tfr       d,u       node pointer into u
InitSymNode         ldd       #8        name length eight
                    pshs      d         pass length
                    ldd       12,s      load search name pointer
                    pshs      d         pass name
                    pshs      u         pass node pointer
                    ldd       #20       offset to node name field
                    addd      ,s++      compute name field address
                    pshs      d         pass destination
                    lbsr      StrNCpy   copy name into node
                    leas      6,s        drop arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,u        clear node kind field
                    clra                clear high byte
                    clrb                clear low byte
                    std       8,u       clear node value field
                    ldd       [4,s]     load current bucket head
                    std       18,u      link node into chain
                    stu       [4,s]     make node the bucket head
                    ldd       4,s       load bucket slot address
                    std       14,u      store back pointer in node
SymNodeReady        tfr       u,d       return node pointer in d
                    leas      6,s        release locals
                    puls      pc,u      return to caller

InstallKeyword      pshs      u         save the caller u register
                    leas      -9,s       reserve nine-byte name buffer
                    ldd       #8        copy length eight
                    pshs      d         pass length
                    ldd       15,s      load source name pointer
                    pshs      d         pass source
                    leax      4,s       point to local buffer
                    pshs      x         pass destination
                    lbsr      StrNCpy   copy name into buffer
                    leas      6,s        drop arguments
                    clra                clear high byte
                    clrb                clear low byte
                    stb       8,s       null terminate buffer
                    leax      ,s        point to buffer
                    pshs      x         pass name
                    lbsr      LookupSymbol look up or create symbol
                    leas      2,s        drop argument
                    tfr       d,u       node pointer into u
                    ldd       #51       keyword kind 0x33
                    std       ,u        set node kind field
                    ldd       15,s      load token code argument
                    std       8,u       set node token field
                    leas      9,s        release buffer
                    puls      pc,u      return to caller

HashName            pshs      u         save the caller u register
                    ldu       4,s       load string pointer
                    leas      -4,s       reserve accumulator locals
                    clra                clear high byte
                    clrb                clear low byte
                    bra       HashNextChar enter hash loop

HashAddLoop         ldd       2,s       load running hash
                    addd      ,s        add character value
HashNextChar        std       2,s       save running hash
                    ldb       ,u+       load next character
                    sex                 sign-extend
                    std       ,s        store current char
                    bne       HashAddLoop loop until null terminator
                    ldd       2,s       load hash sum
                    clra                clear high byte
                    andb      #$7f      mask to bucket range
                    leas      4,s        release locals
                    puls      pc,u      return hash in d

AllocMem            pshs      u,d       save registers
                    ldd       6,s       load requested size
                    pshs      d         pass size
                    lbsr      GrowHeap  allocate from heap
                    leas      2,s        drop argument
                    std       ,s        save returned pointer
                    cmpd      #$FFFF    check allocation failure
                    bne       MemTrackFirst continue if allocated
                    leax      MsgOutOfMemory,pcr point to out-of-memory message
                    pshs      x         pass message
                    lbsr      ReportTokenErr report fatal error
                    leas      2,s        drop argument
MemTrackFirst       ldd       GlbVar0066 load first-alloc pointer
                    bne       MemTrackHigh skip if already set
                    ldd       ,s        load this allocation
                    std       GlbVar0066 record first allocation
MemTrackHigh        ldd       ,s        load allocation pointer
                    addd      6,s       add size
                    std       GlbVar0068 update heap high-water mark
                    ldd       ,s        load returned pointer
PopRetU             leas      2,s        release local
                    puls      pc,u      return to caller

ScanNumber          pshs      u         save the caller u register
                    ldu       6,s       load result descriptor pointer
                    leas      -16,s      reserve number-parse locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       2,s       zero the accumulator
                    leax      8,s       point to accumulator buffer
                    pshs      x         pass its address
                    bsr       ScanNumBody call with inline data pointer
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
ScanNumBody         puls      x         recover accumulator data pointer
                    lbsr      SwapNumWork initialize big-number accumulator
                    leax      8,s       point to local accumulator
                    stx       ,s        store accumulator pointer
                    ldd       20,s      load token type
                    cmpd      #6        already a number token
                    bne       CheckLeadingZero skip if not
                    leax      16,s      point to result slot
                    lbra      FloatEntry return existing number

CheckLeadingZero    ldb       GlbVar0065 load current character
                    cmpb      #'0       is it a leading zero
                    lbne      ClassifyNumChar no, parse decimal digits
                    leas      -6,s       reserve extra locals
                    lbsr      NextChar  advance past the zero
                    ldb       GlbVar0065 load next character
                    cmpb      #'.       is it a decimal point
                    bne       PrepRadix not a dotted number
                    lbsr      NextChar  advance past the point
                    leax      22,s      point to float result
                    lbra      FloatEntry go parse float

PrepRadix           leax      2,s       point to radix buffer
                    pshs      x         pass its address
                    bsr       GotRadixBuf call with inline data pointer
                    fcb       0,$00,$00,$00
GotRadixBuf         puls      x         recover radix buffer pointer
                    lbsr      StoreLong reset big-number accumulator
                    ldb       GlbVar0065 load next character
                    cmpb      #'x       lowercase x means hex
                    beq       ParseHexLiteral yes, parse hex
                    ldb       GlbVar0065 load character
                    cmpb      #'X       uppercase X means hex
                    lbne      DecNextDigit not hex so parse octal
ParseHexLiteral     leas      -2,s       reserve local
                    bra       HexNextDigit enter hex scan

HexDigitLoop        leax      4,s       point to accumulator
                    pshs      x         pass it
                    leax      6,s       point to accumulator
                    pshs      x         pass it
                    ldd       #4        shift amount four bits
                    lbsr      LongShiftLeft shift accumulator left by four
                    ldd       2,x       load accumulator high word
                    pshs      d         pass it
                    ldd       ,x        load accumulator low word
                    pshs      d         pass it
                    ldd       6,s       load current hex character
                    cmpd      #'A       compare with letter A
                    blt       HexDigitDec digit is 0-9
                    ldd       #'7       letter offset 0x37
                    bra       HexDigitAccum use letter offset

HexDigitDec         ldd       #48       digit offset 0x30
HexDigitAccum       pshs      d         pass offset
                    ldd       8,s       load hex character
                    subd      ,s++      subtract offset for digit value
                    lbsr      IntToLong add digit into accumulator
                    lbsr      LongAdd   normalize big number
                    lbsr      StoreLong store accumulator back
HexNextDigit        lbsr      NextChar  advance to next character
                    ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    pshs      d         pass character
                    lbsr      IsHexDigit test if hex digit
                    leas      2,s        drop argument
                    std       ,s        store result
                    bne       HexDigitLoop keep scanning hex digits
                    leas      2,s        drop local
                    bra       CheckLongSuffix finished number, check suffix

DecDigitLoop        leax      2,s       point to accumulator
                    pshs      x         pass it
                    leax      4,s       point to accumulator
                    pshs      x         pass it
                    ldd       #3        shift-multiply parameter
                    lbsr      LongShiftLeft multiply accumulator by ten
                    ldd       2,x       load accumulator high word
                    pshs      d         pass it
                    ldd       ,x        load accumulator low word
                    pshs      d         pass it
                    ldb       GlbVar0065 load current digit char
                    sex                 sign-extend
                    addd      #$FFD0    subtract 0x30 for digit value
                    lbsr      IntToLong add digit into accumulator
                    lbsr      LongAdd   normalize big number
                    lbsr      StoreLong store accumulator back
                    lbsr      NextChar  advance to next character
DecNextDigit        ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    pshs      d         pass character
                    lbsr      IsOctalDigit test if decimal digit
                    std       ,s++      store result
                    bne       DecDigitLoop loop while digit
CheckLongSuffix     leax      2,s       point to result slot
                    stx       ,s        store result pointer
                    ldb       GlbVar0065 load current character
                    cmpb      #'L       uppercase L suffix
                    beq       GotLongSuffix yes, long constant
                    ldb       GlbVar0065 load character
                    cmpb      #'l       lowercase l suffix
                    bne       StoreIntValue no suffix
GotLongSuffix       lbsr      NextChar  advance past suffix
                    leax      22,s      point to long result slot
                    bra       AdjustStackFrame finish long integer

StoreIntValue       ldd       [,s]      load parsed value
                    bne       FinishInteger nonzero so store it
                    ldd       4,s       load computed value
                    std       ,u        store into result node
                    ldd       #1        mark integer result
                    bra       NumberReturn go return

                    bra       FinishInteger otherwise finish

AdjustStackFrame    leas      -22,x     adjust frame for long result
FinishInteger       leax      ,u        point to result node
                    pshs      x         pass it
                    leax      4,s       point to accumulator
                    lbsr      StoreLong store accumulator into node
                    ldd       #8        integer result type 8
NumberReturn        leas      22,s       release parse locals
                    puls      pc,u      return to caller

                    bra       ClassifyNumChar reclassify the character

FloatFracDigit      ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    pshs      d         pass character
                    leax      10,s      point to conversion buffer
                    pshs      x         pass it
                    lbsr      CvtFloatDigits convert accumulated float digits
                    leas      4,s        drop arguments
                    std       -2,s      store result
                    bne       ContinueFloat nonzero, continue float
                    lbsr      NextChar  advance to next character
ClassifyNumChar     ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index by character
                    ldb       ,x        load character class
                    cmpb      #107      class 0x6b is a digit
                    beq       FloatFracDigit yes, accumulate fraction digit
                    ldb       GlbVar0065 load character
                    cmpb      #'.       is it a decimal point
                    beq       IsFloatLiteral yes, it is a float
                    ldb       GlbVar0065 load character
                    cmpb      #'e       exponent letter e
                    beq       IsFloatLiteral yes, it is a float
                    ldb       GlbVar0065 load character
                    cmpb      #'E       exponent letter E
                    lbne      TestZeroValue not a float, handle elsewhere
IsFloatLiteral      ldb       GlbVar0065 load current character
                    cmpb      #'.       is it a decimal point
                    bne       CheckExponent no decimal point
                    lbsr      NextChar  advance past the point
                    bra       FracDigitTest go accumulate fraction

FloatEntry          leas      -16,x     adjust frame for float result
                    bra       FracDigitTest go accumulate fraction

FloatFracDigit2     ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    pshs      d         pass character
                    leax      10,s      point to conversion buffer
                    pshs      x         pass it
                    lbsr      CvtFloatDigits convert accumulated float digits
                    leas      4,s        drop arguments
                    std       -2,s      store result
                    beq       FracDigitCount zero so stop
ContinueFloat       lbsr      NextChar  advance to next character
                    lbra      ValueZero go parse exponent

FracDigitCount      lbsr      NextChar  advance to next character
                    ldd       2,s       load the decimal exponent
                    addd      #1        count one more fractional digit
                    std       2,s       save the decimal exponent
FracDigitTest       ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    leax      CtypeTab,y point at the character class table
                    leax      d,x       index by the character
                    ldb       ,x        read its character class
                    cmpb      #107      is it a digit
                    beq       FloatFracDigit2 loop for the next fraction digit
CheckExponent       ldb       GlbVar0065 load the current character
                    cmpb      #'E       is it exponent 'E'
                    beq       ParseExponent handle the exponent
                    ldb       GlbVar0065 load the current character
                    cmpb      #'e       is it exponent 'e'
                    lbne      FinalizeExponent no exponent, finalize the value
ParseExponent       ldd       #1        default exponent sign positive
                    std       4,s       store the exponent sign
                    lbsr      NextChar  advance past the 'e'
                    ldb       GlbVar0065 load the current character
                    cmpb      #'+       is it a plus sign
                    bne       CheckExpMinus otherwise check for minus
                    lbsr      NextChar  consume the plus sign
                    bra       ExpDigitInit go read exponent digits

CheckExpMinus       ldb       GlbVar0065 load the current character
                    cmpb      #'-       is it a minus sign
                    bne       ExpDigitInit no sign present
                    lbsr      NextChar  consume the minus sign
                    clra                clear D
                    clrb                clear D
                    std       4,s       mark the exponent negative
ExpDigitInit        clra                clear D
                    clrb                clear D
                    std       6,s       clear the exponent value
                    bra       ExpDigitTest test for exponent digits

ExpDigitLoop        ldd       6,s       load the exponent value
                    pshs      d         save it
                    ldd       #10       base ten multiplier
                    lbsr      MulEntry  multiply accumulator by ten
                    pshs      d         save the product
                    ldb       GlbVar0065 load the current digit
                    sex                 sign extend to word
                    addd      #$FFD0    convert ascii digit to value
                    addd      ,s++      add into the exponent accumulator
                    std       6,s       store the exponent value
                    lbsr      NextChar  advance to next character
ExpDigitTest        ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    leax      CtypeTab,y point at the character class table
                    leax      d,x       index by the character
                    ldb       ,x        read its character class
                    cmpb      #107      is it a digit
                    beq       ExpDigitLoop loop for the next exponent digit
                    ldd       6,s       load the exponent value
                    cmpd      #40       clamp exponent at forty
                    lbge      ValueZero too large, use zero
                    ldd       2,s       load the fractional place count
                    pshs      d         save it
                    ldd       6,s       load the exponent value
                    beq       ExpPositive positive exponent branch
                    ldd       8,s       load the base exponent
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        finish two's complement
                    bra       ExpCombine combine with the place count

ExpPositive         ldd       8,s       load the base exponent
ExpCombine          addd      ,s++      add the place count
                    std       2,s       store the net exponent
FinalizeExponent    ldd       2,s       load the net exponent
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        finish two's complement
                    ldx       ,s        point at the number struct
                    stb       7,x       store exponent into the struct
                    ldb       [,s]      load the type byte
                    clra                clear high byte
                    andb      #$7f      mask off the sign bit
                    stb       [,s]      store the type flag back
                    leax      ,u        point at the result buffer
                    pshs      x         pass it as argument
                    leax      10,s      point at the number struct
                    lbsr      SwapNumWork build the float constant
                    ldd       #6        result is float type
                    lbra      NumReturn return the constant

TestZeroValue       ldb       [,s]      test number byte zero
                    bne       ValueZero nonzero, value is not zero
                    ldx       ,s        point at the number struct
                    ldb       1,x       test byte one
                    bne       ValueZero nonzero, value is not zero
                    ldx       ,s        point at the number struct
                    ldb       2,x       test byte two
                    beq       CheckLongSuffix2 all zero, value is zero
ValueZero           clra                clear D
                    clrb                clear D
                    lbra      NumReturn return zero value

CheckLongSuffix2    ldb       GlbVar0065 load the current character
                    cmpb      #'l       is it 'l' suffix
                    beq       LongSuffix handle the long suffix
                    ldb       GlbVar0065 load the current character
                    cmpb      #'L       is it 'L' suffix
                    bne       CheckIntRange no suffix, check int range
LongSuffix          leas      -2,s       reserve two bytes
                    lbsr      NextChar  consume the suffix
                    bra       BuildLongConst build the long constant

AllocTwoBytes       leas      -18,x     reserve two bytes
BuildLongConst      ldd       2,s       load the value
                    addd      #3        bias by three
                    std       ,s        store into the slot
                    leax      ,u        point at the result buffer
                    pshs      x         pass it as argument
                    ldx       2,s       load the value pointer
                    lbsr      StoreLong build the long constant
                    ldd       #8        result is long type
                    bra       IntLongReturn return the constant

CheckIntRange       ldx       ,s        point at the number struct
                    ldb       3,x       test byte three
                    bne       NeedLong  nonzero, value needs long
                    ldx       ,s        point at the number struct
                    ldb       4,x       test byte four
                    beq       BuildIntConst fits in an int
NeedLong            leax      16,s      point past the struct
                    bra       AllocTwoBytes build the long constant

BuildIntConst       leas      -2,s       reserve two bytes
                    ldd       2,s       load the value
                    addd      #5        bias by five
                    std       ,s        store into the slot
                    ldd       [,s]      load the int value
                    std       ,u        store into the result buffer
                    ldd       #1        result is int type
IntLongReturn       leas      18,s       unwind the stack frame
                    puls      pc,u      return

NumReturn           leas      16,s       unwind the stack frame
                    puls      pc,u      return

ParseCharConst      pshs      u         save the caller u register
                    lbsr      NextChar  advance past the opening quote
                    ldb       GlbVar0065 load the current character
                    cmpb      #'\       is it a backslash escape
                    bne       CharConstPlain plain character
                    lbsr      ParseEscape parse the escape sequence
                    std       GlbVar0061 store the character value
                    bra       CharConstClose check the closing quote

CharConstPlain      ldb       GlbVar0065 load the character
                    sex                 sign extend to word
                    std       GlbVar0061 store the character value
                    lbsr      NextChar  advance to next character
CharConstClose      ldb       GlbVar0065 load the current character
                    cmpb      #''       is it the closing quote
                    lbeq      ConstClose yes, finish the constant
                    leax      MsgUntermCharConst,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    lbra      ConstReturn return

ParseStringConst    pshs      u         save the caller u register
                    ldx       GlbVar000B load the section selector
                    bra       SegDispatch dispatch on the section

AllocStringLabel    ldd       GlbVar006C load the string label
                    bne       LoadStringSeg already have a label
                    leax      StrModeWPlus,pcr point at the label format
                    pshs      x         pass it as argument
                    leax      NameBuf,y point at the name buffer
                    pshs      x         pass it as argument
                    lbsr      Fopen     format the string label
                    leas      4,s        clean up arguments
                    std       GlbVar006C save the string label
                    bne       LoadStringSeg got a label
                    leax      MsgCantOpenStrings,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      ReportTokenErr report the error
                    leas      2,s        discard the argument
LoadStringSeg       ldd       GlbVar006C load the string label
                    bra       StoreOutSeg store the output section

LoadConstSeg        ldd       GlbVar0025 load the constant label
StoreOutSeg         std       GlbVar001B store the output section
                    bra       StringEmitInit start emitting the string

SegDispatch         stx       -2,s      save the section selector
                    beq       AllocStringLabel section zero, need a label
                    cmpx      #2        section two, need a label
                    lbeq      AllocStringLabel same, need a label
                    cmpx      #1        is it section one
                    beq       LoadConstSeg use the constant section
StringEmitInit      clra                clear D
                    clrb                clear D
                    std       GlbVar0017 clear the string length
                    ldd       GlbVar000B load the section selector
                    cmpd      #1        is it section one
                    beq       StringBody skip the label emit
                    ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       #108      constant section number
                    pshs      d         pass it as argument
                    lbsr      PutChar2  switch output section
                    leas      4,s        clean up arguments
                    ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       GlbVar002B load the label counter
                    addd      #1        next label number
                    std       GlbVar002B save the label counter
                    std       GlbVar0061 store the label number
                    pshs      d         pass it as argument
                    lbsr      PutWord   emit the string label
                    leas      4,s        clean up arguments
StringBody          lbsr      NextChar  advance past the opening quote
                    ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       #115      string section number
                    pshs      d         pass it as argument
                    lbsr      PutChar2  switch output section
                    leas      4,s        clean up arguments
                    bra       StringCharTest enter the string body loop

StringCharLoop      leax      LineBuffer,y   point at the source buffer end
                    pshs      x         pass it as argument
                    ldd       GlbVar006A load the source pointer
                    subd      ,s++      reached the buffer end
                    bne       StringEscape still room in the buffer
                    leax      MsgUntermString,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    bra       StringTerminate terminate the string

StringEscape        ldb       GlbVar0065 load the current character
                    cmpb      #'\       is it a backslash escape
                    bne       StringPlainChar plain character
                    lbsr      ParseEscape parse the escape sequence
                    pshs      d         pass the value as argument
                    bsr       EmitStringChar emit the string character
                    leas      2,s        discard the argument
                    bra       StringCharTest next character

StringPlainChar     ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    pshs      d         pass the value as argument
                    bsr       EmitStringChar emit the string character
                    leas      2,s        discard the argument
                    lbsr      NextChar  advance to next character
StringCharTest      ldb       GlbVar0065 load the current character
                    cmpb      #'"       is it the closing quote
                    bne       StringCharLoop no, loop for the next character
StringTerminate     ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    clra                clear D
                    clrb                clear D
                    pshs      d         pass the null terminator
                    lbsr      PutChar2  emit the terminating null
                    leas      4,s        clean up arguments
                    ldd       GlbVar0017 load the string length
                    addd      #1        count the terminator
                    std       GlbVar0017 store the string length
ConstClose          lbsr      NextChar  advance past the closing quote
ConstReturn         puls      pc,u      return

EmitStringChar      pshs      u         save the caller u register
                    ldd       4,s       load the character value
                    beq       EmitBackslash zero, emit escaped
                    ldd       4,s       load the character value
                    cmpd      #'\       is it a backslash
                    bne       EmitCharByte emit it plainly
EmitBackslash       ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       #'\       backslash to escape it
                    pshs      d         pass it as argument
                    lbsr      PutChar2  emit the backslash
                    leas      4,s        clean up arguments
EmitCharByte        ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       6,s       load the character value
                    pshs      d         pass it as argument
                    lbsr      PutChar2  emit the character
                    leas      4,s        clean up arguments
                    ldd       GlbVar0017 load the string length
                    addd      #1        count the character
                    std       GlbVar0017 store the string length
                    puls      pc,u      return

EmitCharConst       pshs      u         save the caller u register
                    lbsr      EmitStar  prepare the output buffer
                    ldd       4,s       load the character value
                    pshs      d         pass it as argument
                    leax      FmtRzb,pcr point at the format string
                    pshs      x         pass it as argument
                    ldd       GlbVar001B load the output stream
                    pshs      d         pass it as argument
                    lbsr      fprintf   print the character constant
                    leas      6,s        clean up arguments
                    puls      pc,u      return

ParseEscape         pshs      u,d       save u and char
                    lbsr      NextChar  advance past the backslash
                    ldb       GlbVar0065 load the escape character
                    sex                 sign extend to word
                    tfr       d,u       keep the escape character
                    lbsr      NextChar  advance to next character
                    leax      ,u        load the escape character
                    bra       EscDispatch dispatch on the escape

EscLinefeed         ldd       #10       linefeed value
                    lbra      OctalEscapeExit return the escape value

EscTab              ldd       #9        tab value
                    lbra      OctalEscapeExit return the escape value

EscBackspace        ldd       #8        backspace value
                    lbra      OctalEscapeExit return the escape value

EscVertTab          ldd       #11       vertical tab value
                    lbra      OctalEscapeExit return the escape value

EscCarriageRet      ldd       #13       carriage return value
                    lbra      OctalEscapeExit return the escape value

EscFormFeed         ldd       #12       form feed value
                    lbra      OctalEscapeExit return the escape value

EscNewlineSpace     ldd       #'        space value
                    lbra      OctalEscapeExit return the escape value

EscDispatch         cmpx      #110      is escape 'n'
                    beq       EscCarriageRet yes, carriage return
                    cmpx      #108      is escape 'l'
                    beq       EscLinefeed yes, linefeed
                    cmpx      #116      is escape 't'
                    beq       EscTab    yes, tab
                    cmpx      #98       is escape 'b'
                    beq       EscBackspace yes, backspace
                    cmpx      #118      is escape 'v'
                    beq       EscVertTab yes, vertical tab
                    cmpx      #114      is escape 'r'
                    lbeq      EscCarriageRet yes, carriage return
                    cmpx      #102      is escape 'f'
                    beq       EscFormFeed yes, form feed
                    cmpx      #13       is escaped newline
                    beq       EscNewlineSpace yes, becomes a space
                    cmpu      #120      is escape 'x' for hex
                    lbne      CheckDecEscape otherwise try decimal
                    leas      -2,s       reserve two bytes
                    clra                clear D
                    clrb                clear D
                    std       2,s       clear the hex accumulator
                    tfr       d,u       start accumulator at zero
                    bra       HexDigitTest test for hex digits

HexDigitLoop2       tfr       u,d       load the accumulator
                    aslb                shift left one bit
                    rola                carry into high byte
                    aslb                shift left one bit
                    rola                carry into high byte
                    aslb                shift left one bit
                    rola                carry into high byte
                    aslb                shift left one bit
                    rola                carry into high byte
                    pshs      d         save the shifted value
                    ldd       2,s       load the digit character
                    cmpd      #'A       is it a letter digit
                    bge       HexLetterDigit yes, convert from letter
                    ldd       2,s       load the digit character
                    addd      #$FFD0    convert '0'-'9' to value
                    bra       HexAddDigit add into the accumulator

HexLetterDigit      ldd       2,s       load the digit character
                    addd      #$FFC9    convert 'A'-'F' to value
HexAddDigit         addd      ,s++      add into the accumulator
                    tfr       d,u       keep the accumulator
                    lbsr      NextChar  advance to next character
HexDigitTest        ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    pshs      d         pass it as argument
                    lbsr      IsHexDigit classify the hex digit
                    leas      2,s        discard the argument
                    std       ,s        store the classification
                    beq       HexDone   not a hex digit, stop
                    ldd       2,s       load the digit count
                    addd      #1        increment it
                    std       2,s       save the digit count
                    subd      #1        restore the count
                    cmpd      #2        limit to two hex digits
                    blt       HexDigitLoop2 loop for the next hex digit
HexDone             leas      2,s        discard the count
                    lbra      OctalEscapeDone return the hex value

CheckDecEscape      cmpu      #100      is escape 'd' for decimal
                    bne       ParseOctEscape otherwise treat as octal
                    clra                clear D
                    clrb                clear D
                    std       ,s        clear the decimal accumulator
                    tfr       d,u       start accumulator at zero
                    bra       DecDigitTest test for decimal digits

DecDigitLoop2       pshs      u         save the accumulator
                    ldd       #10       base ten multiplier
                    lbsr      MulEntry  multiply accumulator by ten
                    pshs      d         save the product
                    ldb       GlbVar0065 load the current digit
                    sex                 sign extend to word
                    addd      ,s++      add the scaled accumulator
                    addd      #$FFD0    convert ascii digit to value
                    tfr       d,u       keep the accumulator
                    lbsr      NextChar  advance to next character
DecDigitTest        ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    leax      CtypeTab,y point at the character class table
                    leax      d,x       index by the character
                    ldb       ,x        read its character class
                    cmpb      #107      is it a digit
                    lbne      OctalEscapeDone no, return the value
                    ldd       ,s        load the digit count
                    addd      #1        increment it
                    std       ,s        save the digit count
                    subd      #1        restore the count
                    cmpd      #3        limit to three decimal digits
                    blt       DecDigitLoop2 loop for the next decimal digit
                    bra       OctalEscapeDone return the value

ParseOctEscape      pshs      u         save the caller u register
                    lbsr      IsOctalDigit classify the octal digit
                    std       ,s++      store the classification
                    beq       OctalEscapeDone not octal, return the char
                    leau      -48,u     convert the first octal digit
                    clra                clear D
                    clrb                clear D
                    std       ,s        clear the digit count
                    bra       OctalDigitCheck test for more octal digits

OctDigitLoop        tfr       u,d       load the accumulator
                    aslb                shift left one bit
                    rola                carry into high byte
                    aslb                shift left one bit
                    rola                carry into high byte
                    aslb                shift left one bit
                    rola                carry into high byte
                    pshs      d         save the shifted value
                    ldb       GlbVar0065 load the current digit
                    sex                 sign extend to word
                    addd      #$FFD0    convert ascii digit to value
                    addd      ,s++      add into the accumulator
                    tfr       d,u       keep the accumulator
                    lbsr      NextChar  advance to next character
OctalDigitCheck     ldb       GlbVar0065 load current input character
                    sex                 sign extend to word
                    pshs      d         pass character as argument
                    bsr       IsOctalDigit test whether it is an octal digit
                    std       ,s++      store result and pop
                    beq       OctalEscapeDone not octal, finish escape
                    ldd       ,s        load the octal digit count
                    addd      #1        increment the count
                    std       ,s        save the count
                    subd      #1        restore the count value
                    cmpd      #3        allow up to three octal digits
                    blt       OctDigitLoop loop to accumulate another digit
OctalEscapeDone     tfr       u,d       return the accumulated escape value
OctalEscapeExit     leas      2,s        drop the local
                    puls      pc,u      return

IsOctalDigit        pshs      u         save the caller u register
                    ldb       5,s       load the character argument
                    cmpb      #'7       compare to '7'
                    bgt       NotDigit  above octal range, not a digit
                    ldb       5,s       reload the character
                    cmpb      #'0       compare to '0'
                    blt       NotDigit  below octal range, not a digit
                    ldd       #1        result is true
                    bra       DigitTestRet return

IsHexDigit          pshs      u         save the caller u register
                    ldb       5,s       load the character argument
                    sex                 extend to word
                    leax      CtypeTab,y point at the character-class table
                    leax      d,x       index by the character
                    ldb       ,x        load the class byte
                    cmpb      #107      is it the digit class
                    beq       HexDigitOk yes, accept it
                    ldb       5,s       reload the character
                    clra                clear the high byte
                    andb      #$5f      force to uppercase
                    stb       5,s       save uppercased character
                    cmpd      #65       compare to 'A'
                    blt       NotDigit  below hex letters, reject
                    ldb       5,s       reload the character
                    cmpb      #'F       compare to 'F'
                    bgt       NotDigit  above hex letters, reject
HexDigitOk          ldb       5,s       load the character value
                    sex                 extend to word
                    bra       DigitTestRet return the value

NotDigit            clra                result is zero
                    clrb                result is zero
DigitTestRet        puls      pc,u      return

MsgBadChar          fcc       /bad character/
                    fcb       C$NULL
MsgConstOverflow    fcc       /constant overflow/
                    fcb       C$NULL
KwDouble            fcc       /double/
                    fcb       C$NULL
KwFloat             fcc       /float/
                    fcb       C$NULL
KwTypedef           fcc       /typedef/
                    fcb       C$NULL
KwStatic            fcc       /static/
                    fcb       C$NULL
KwSizeof            fcc       /sizeof/
                    fcb       C$NULL
KwInt               fcc       /int/
                    fcb       C$NULL
KwIntB              fcc       /int/
                    fcb       C$NULL
KwFloatB            fcc       /float/
                    fcb       C$NULL
KwChar              fcc       /char/
                    fcb       C$NULL
KwShort             fcc       /short/
                    fcb       C$NULL
KwAuto              fcc       /auto/
                    fcb       C$NULL
KwExtern            fcc       /extern/
                    fcb       C$NULL
KwDirect            fcc       /direct/
                    fcb       C$NULL
KwRegister          fcc       /register/
                    fcb       C$NULL
KwGoto              fcc       /goto/
                    fcb       C$NULL
KwReturn            fcc       /return/
                    fcb       C$NULL
KwIf                fcc       /if/
                    fcb       C$NULL
KwWhile             fcc       /while/
                    fcb       C$NULL
KwElse              fcc       /else/
                    fcb       C$NULL
KwSwitch            fcc       /switch/
                    fcb       C$NULL
KwCase              fcc       /case/
                    fcb       C$NULL
KwBreak             fcc       /break/
                    fcb       C$NULL
KwContinue          fcc       /continue/
                    fcb       C$NULL
KwDo                fcc       /do/
                    fcb       C$NULL
KwDefault           fcc       /default/
                    fcb       C$NULL
KwFor               fcc       /for/
                    fcb       C$NULL
KwStruct            fcc       /struct/
                    fcb       C$NULL
KwUnion             fcc       /union/
                    fcb       C$NULL
KwUnsigned          fcc       /unsigned/
                    fcb       C$NULL
KwLong              fcc       /long/
                    fcb       C$NULL
KwErrno             fcc       /errno/
                    fcb       C$NULL
KwLseek             fcc       /lseek/
                    fcb       C$NULL
MsgOutOfMemory      fcc       /out of memory/
                    fcb       C$NULL
MsgUntermCharConst  fcc       /unterminated character constant/
                    fcb       C$NULL
StrModeWPlus        fcc       /w+/
                    fcb       C$NULL
MsgCantOpenStrings  fcc       /can't open strings file/
                    fcb       C$NULL
MsgUntermString     fcc       /unterminated string/
                    fcb       C$NULL
FmtRzb              fcc       / rzb %d/
                    fcb       C$CR,C$NULL
InitScanBuffer      pshs      u         save the caller u register
                    leax      LineBuffer,y   point at the line buffer
                    stx       GlbVar006A set the current line pointer
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       LineBuffer,y   clear first buffer byte
                    ldd       #'        space character
                    bra       StoreCurChar store it as current char

SkipWhitespace      pshs      u         save the caller u register
                    bra       SkipWsCheck go check the current char

SkipWsLoop          bsr       NextChar  fetch the next character
SkipWsCheck         ldb       GlbVar0065 load current char
                    cmpb      #'        is it a space
                    beq       SkipWsLoop skip the whitespace
                    ldb       GlbVar0065 reload current char
                    cmpb      #9        is it a tab
                    lbeq      SkipWsLoop skip the whitespace
                    puls      pc,u      return

NextChar            pshs      u         save the caller u register
                    ldx       GlbVar006A load the line pointer
                    leax      1,x       advance past this char
                    stx       GlbVar006A save updated pointer
                    ldb       -1,x      load the character
                    stb       GlbVar0065 store as current char
                    bne       NextCharRet non-null, done
                    bsr       RefillLine end of line, refill buffer
StoreCurChar        stb       GlbVar0065 store the returned char
NextCharRet         puls      pc,u      return

RefillLine          pshs      u         save the caller u register
                    leas      -8,s       reserve locals
                    ldd       GlbVar001D check the init flag
                    bne       RefillNotFirst already started
                    ldd       #1        mark as initialized
                    std       GlbVar001D save the init flag
                    leax      EmptyLineStr,pcr point at the empty line
                    stx       GlbVar006A set line pointer
                    lbra      RetSpace  return a space

RefillNotFirst      clra                clear the high byte
                    clrb                clear the low byte
                    std       GlbVar001D clear the init flag
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      PreviousLineBuffer,y   point at the save buffer
                    pshs      x         push as argument
                    lbsr      StrCpy    copy line into the save buffer
                    leas      4,s        drop arguments
ReadLineLoop        lbsr      GetSourceLine read the next source line
                    std       GlbVar006A save the line pointer
                    lbeq      LineEof   end of file
                    ldb       [>GlbVar006A,y] load the first character
                    cmpb      #'#       is it a '#' directive
                    lbne      BumpLineNum not a directive, count line
                    ldx       GlbVar006A reload line pointer
                    ldb       1,x       load the directive code
                    sex                 extend to word
                    std       4,s       save the directive code
                    lbsr      GetSourceLine read the argument line
                    std       -2,s      save it
                    lbeq      LineEof   end of file
                    ldx       4,s       reload the directive code
                    lbra      DispatchDirective dispatch on the directive

DirLineNum          leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    lbsr      ParseDecimal parse the line number
                    leas      2,s        drop argument
                    std       GlbLineNum set the line counter
                    bra       ReadLineLoop continue reading

DirFlushHook        lbsr      EmitComment invoke the flush hook
DirEmitLine         lbsr      EmitStar  flush pending output
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      FmtS,pcr  '%s' format string
                    lbra      EmitFprintfTail emit via fprintf

DirIncludeFile      leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      FilenameBuffer,y   point at the filename buffer
                    pshs      x         push as argument
                    lbsr      StrCpy    copy line into filename
                    leas      4,s        drop arguments
                    leax      FilenameBuffer,y   point at the filename buffer
                    pshs      x         push as argument
                    lbsr      EmitFuncLine open the named file
                    leas      2,s        drop argument
                    lbsr      GetSourceLine read the next line
                    std       -2,s      save it
                    lbne      ReadLineLoop not eof, keep reading
                    lbra      LineEof   end of file

DirLineMarker       leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      NameBuffer,y   point at the name buffer
                    pshs      x         push as argument
                    lbsr      StrCpy    copy line into name
                    leas      4,s        drop arguments
                    lbsr      GetSourceLine read the next line
                    std       -2,s      save it
                    lbeq      LineEof   end of file
                    lbsr      EmitStar  flush pending output
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    lbsr      ParseDecimal parse the number
                    std       ,s        save it
                    leax      NameBuffer,y   point at the name buffer
                    pshs      x         push as argument
                    leax      MsgPsect,pcr format string
                    pshs      x         push as argument
                    ldd       GlbVar0025 output file handle
                    pshs      d         push as argument
                    lbsr      fprintf   emit the line marker
                    leas      8,s        drop arguments
                    lbsr      EmitStar  flush pending output
                    leax      NameBuffer,y   point at the name buffer
                    pshs      x         push as argument
                    leax      MsgNam,pcr format string
EmitFprintfTail     pshs      x         push as argument
                    ldd       GlbVar0025 output file handle
                    pshs      d         push as argument
                    lbsr      fprintf   emit formatted text
                    leas      6,s        drop arguments
                    lbra      ReadLineLoop continue reading

DirRangeMarker      leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      NameBuffer,y   point at the name buffer
                    pshs      x         push as argument
                    lbsr      StrCpy    copy line into name
                    leas      4,s        drop arguments
                    lbsr      GetSourceLine read the next line
                    std       -2,s      save it
                    beq       LineEof   end of file
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    lbsr      ParseDecimal parse first number
                    leas      2,s        drop argument
                    std       6,s       save it
                    lbsr      GetSourceLine read the next line
                    std       -2,s      save it
                    beq       LineEof   end of file
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    lbsr      ParseDecimal parse second number
                    leas      2,s        drop argument
                    std       2,s       save the count
                    lbsr      GetSourceLine read the next line
                    std       -2,s      save it
                    bne       BuildMarker not eof, proceed
LineEof             ldd       #$FFFF    return end of file
                    lbra      RefillExit exit

BuildMarker         ldd       6,s       load the first value
                    beq       BuildPlainMarker zero, emit plain form
                    ldd       6,s       reload the value
                    pshs      d         push as argument
                    leax      FilenameBuffer,y   point at the filename buffer
                    pshs      x         push as argument
                    leax      MsgLineRef,pcr format string
                    pshs      x         push as argument
                    lbsr      PrintfBuf build the output string
                    leas      6,s        drop arguments
                    bra       AppendLineText append the line text

BuildPlainMarker    leax      MsgArgument,pcr plain format string
                    pshs      x         push as argument
                    lbsr      PrintfBuf build the output string
                    leas      2,s        drop argument
AppendLineText      leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      MsgBanner,pcr format string
                    pshs      x         push as argument
                    lbsr      PrintfBuf append to the output
                    leas      4,s        drop arguments
                    ldb       NameBuffer,y   check the name buffer
                    beq       CheckDirType1 empty, skip padding
                    leax      NameBuffer,y   point at the name buffer
                    pshs      x         push as argument
                    lbsr      PutStringLine emit the name
                    leas      2,s        drop argument
                    bra       EmitSpaceNext enter the space loop

EmitSpaceLoop       leax      StdoutStream,y   point at the output buffer
                    pshs      x         push as argument
                    ldd       #'        space character
                    pshs      d         push as argument
                    lbsr      PutChar2  emit a padding space
                    leas      4,s        drop arguments
EmitSpaceNext       ldd       2,s       load remaining count
                    addd      #$FFFF    decrement it
                    std       2,s       save the count
                    subd      #$FFFF    test the count
                    bne       EmitSpaceLoop more spaces to emit
                    leax      MsgCaret2,pcr format string
                    pshs      x         push as argument
                    lbsr      PutStringLine emit it
                    leas      2,s        drop argument
CheckDirType1       ldd       4,s       load the directive code
                    cmpd      #49       is it type one
                    lbne      ReadLineLoop no, continue reading
                    lbsr      EmitDataInit handle the special case
                    lbra      ReadLineLoop continue reading

DispatchDirective   cmpx      #53       directive code 0x35
                    lbeq      DirLineNum handle line-number directive
                    cmpx      #54       directive code 0x36
                    lbeq      DirFlushHook handle flush directive
                    cmpx      #50       directive code 0x32
                    lbeq      DirEmitLine handle emit-line directive
                    cmpx      #55       directive code 0x37
                    lbeq      DirIncludeFile handle include directive
                    cmpx      #80       directive code 0x50
                    lbeq      DirLineMarker handle line-marker directive
                    cmpx      #48       directive code 0x30
                    lbeq      DirRangeMarker handle range-marker directive
                    cmpx      #49       directive code 0x31
                    lbeq      DirRangeMarker handle range-marker directive
                    lbra      ReadLineLoop unknown, continue reading

BumpLineNum         ldd       GlbLineNum load the line number
                    addd      #1        advance one line
                    std       GlbLineNum save the line number
RetSpace            ldd       #'        return a space
RefillExit          leas      8,s        drop locals
                    puls      pc,u      return

ParseDecimal        pshs      u         save the caller u register
                    ldu       4,s       load the string pointer argument
                    leas      -4,s       reserve locals
                    clra                clear the high byte
                    clrb                result starts at zero
                    bra       ParseDecStore go read first char

ParseDecLoop        ldd       ,s        load the running total
                    pshs      d         push it
                    ldd       #10       multiply by ten
                    lbsr      MulEntry  do the multiply
                    pshs      d         push the product
                    ldd       4,s       load the digit char
                    addd      #$FFD0    subtract '0'
                    addd      ,s++      add to total times ten
ParseDecStore       std       ,s        save the total
                    ldb       ,u+       load the next char
                    sex                 extend to word
                    std       2,s       save the char
                    leax      CtypeTab,y point at character-class table
                    leax      d,x       index by the char
                    ldb       ,x        load the class byte
                    cmpb      #107      is it a digit
                    beq       ParseDecLoop yes, accumulate it
                    ldd       ,s        load the final total
                    leas      4,s        drop locals
                    puls      pc,u      return

GetSourceLine       pshs      u,d       save u and value
                    leau      LineBuffer,y   point at the line buffer
                    ldd       GlbVar0023 load the source file handle
                    pshs      d         push as argument
                    lbsr      GetChar   read a character
                    leas      2,s        drop argument
                    std       ,s        save it
                    cmpd      #$FFFF    end of file
                    lbne      GetLineCheckFull got a char, store it
                    ldx       GlbVar0023 load the file handle
                    ldd       6,x       check the file flags
                    clra                clear the high byte
                    andb      #$20      test the error bit
                    beq       GetLineNull no error
                    leax      OutputStream,y   error context
                    pshs      x         push as argument
                    leax      MsgTempFileErr,pcr error format string
                    pshs      x         push as argument
                    lbsr      FputStr   report the read error
                    leas      4,s        drop arguments
                    lbsr      EmitDataInit abort compilation
GetLineNull         clra                clear the high byte
                    clrb                return null pointer
                    bra       GetLineExit go to exit

GetLineNext         ldx       ,s        load the current char
                    bra       GetLineClassify classify it

GetLineDone         clra                clear the high byte
                    clrb                clear the low byte
                    stb       ,u        null-terminate the buffer
                    leax      LineBuffer,y   point at buffer start
                    tfr       x,d       return the buffer pointer
                    bra       GetLineExit go to exit

GetLineStore        ldd       ,s        load the current char
                    stb       ,u+       store into the buffer
                    ldd       GlbVar0023 load the file handle
                    pshs      d         push as argument
                    lbsr      GetChar   read the next character
                    leas      2,s        drop argument
                    std       ,s        save it
                    bra       GetLineCheckFull check for buffer overflow

GetLineClassify     cmpx      #13       is it a carriage return
                    beq       GetLineDone end of line
                    cmpx      #$FFFF    is it end of file
                    lbeq      GetLineDone end of line
                    bra       GetLineStore store the character

GetLineCheckFull    cmpu      IsBufferFull,y   is the buffer full
                    bne       GetLineNext room left, continue
                    ldd       GlbLineNum load the line number
                    addd      #1        advance one line
                    std       GlbLineNum save the line number
                    std       GlbVar003F record the line number
                    leax      LineBuffer,y   point at the line buffer
                    stx       GlbVar0063 save the buffer pointer
                    leax      >MsgLineTooLong,pcr line-too-long message
                    pshs      x         push as argument
                    lbsr      ReportTokenErr report the error
                    leas      2,s        drop argument
GetLineExit         leas      2,s        drop the local
                    puls      pc,u      return

EmptyLineStr        fcb       C$NULL
FmtS                fcc       /%s/
                    fcb       C$CR,C$NULL
MsgPsect            fcc       / psect %s,0,0,%d,0,0/
                    fcb       C$CR,C$NULL
MsgNam              fcc       / nam %s/
                    fcb       C$CR,C$NULL
MsgLineRef          fcc       /%s : line %d /
                    fcb       C$NULL
MsgArgument         fcc       /argument : /
                    fcb       C$NULL
MsgBanner           fcc       /**** %s ****/
                    fcb       C$CR,C$NULL
MsgCaret2           fcb       $5E
                    fcb       C$NULL
MsgTempFileErr      fcc       /INPUT FILE ERROR : TEMPORARY FILE/
                    fcb       C$CR,C$NULL
MsgLineTooLong      fcc       /input line too long/
                    fcb       C$NULL
EmitStringTable     pshs      u         save the caller u register
                    lbsr      DumpStrings dump the string constant table
                    lbra      EmitSectEnd emit the section end and return

EmitRmbVar          pshs      u         save the caller u register
                    ldd       8,s       load the section flag argument
                    pshs      d         pass it
                    lbsr      EmitSectLetter emit the data or variable section letter
                    leas      2,s        drop the argument
                    lbsr      EmitStar  emit leading indentation
                    ldd       4,s       load the symbol argument
                    pshs      d         pass it
                    lbsr      EmitTempRef emit the symbol name
                    leas      2,s        drop the argument
                    ldd       6,s       load the size argument
                    pshs      d         pass the size
                    leax      MsgRmb,pcr point to the " rmb %d" format
                    pshs      x         pass the format string
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the rmb directive
                    bra       EmitRmbCleanup clean up and finish

EmitLabelColon      pshs      u         save the caller u register
                    ldd       8,s       load the section flag
                    pshs      d         pass it
                    lbsr      EmitSectLetter emit the section letter
                    leas      2,s        drop the argument
                    ldd       #':       colon separator character
                    bra       EmitLabelRmbTail join the common emit path

EmitLabelSpace      pshs      u         save the caller u register
                    ldd       8,s       load the section flag
                    pshs      d         pass it
                    lbsr      EmitSectLetter emit the section letter
                    leas      2,s        drop the argument
                    ldd       #'        space separator character
EmitLabelRmbTail    pshs      d         pass the separator character
                    ldd       8,s       load an argument
                    pshs      d         pass it
                    ldd       8,s       load an argument
                    pshs      d         pass it
                    bsr       EmitLabeledRmb emit the labelled rmb line
EmitRmbCleanup      leas      6,s        drop the three arguments
EmitSectEnd         lbsr      EmitEndLetter emit the end-of-section letter
                    puls      pc,u      restore and return

EmitLabeledRmb      pshs      u         save the caller u register
                    lbsr      EmitStar  emit leading indentation
                    ldd       6,s       load the size argument
                    pshs      d         pass it
                    ldb       11,s      load the separator character byte
                    sex                 sign-extend to a word
                    pshs      d         pass the separator
                    ldd       8,s       load the base offset
                    addd      #20       add the fixed bias
                    pshs      d         pass the computed value
                    leax      MsgLabelRmb,pcr point to the "%.8s%c rmb %d" format
                    pshs      x         pass the format
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the labelled rmb line
                    leas      10,s       drop the arguments
                    puls      pc,u      restore and return

EmitStaticSym       pshs      u         save the caller u register
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       #'S       static marker character
                    pshs      d         pass the character
                    lbsr      PutChar2  write the character
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       8,s       load the argument character
                    pshs      d         pass the character
                    lbsr      PutChar2  write the character
                    leas      4,s        drop the arguments
                    ldd       GlbVar0035 check the flag global
                    bne       EmitNameField skip label numbering if set
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       GlbVar002B load the label counter
                    addd      #1        bump it
                    std       GlbVar002B store it back
                    pshs      d         pass the new label number
                    lbsr      PutWord   print the label number
                    leas      4,s        drop the arguments
EmitNameField       clra                zero
                    clrb                terminator character
                    pshs      d         pass it
                    ldd       6,s       load the name pointer
                    pshs      d         pass it
                    leax      MsgNameFmt,pcr point to the "%.8s%c" format
                    pshs      x         pass the format
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the truncated name
                    leas      8,s        drop the arguments
                    ldd       GlbVar0037 check the secondary flag
                    lbeq      EmitEndDone done if it is clear
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       10,s      load the value argument
                    pshs      d         pass it
                    lbsr      PutWord   print the value
                    bra       EmitEndCleanup clean up and return

EmitPublicLabel     pshs      u         save the caller u register
                    ldd       #'p       public marker character
                    pshs      d         pass it
                    lbsr      EmitCharOut write the character
                    leas      2,s        drop the argument
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       8,s       load the value argument
                    pshs      d         pass it
                    lbsr      PutWord   print the value
                    leas      4,s        drop the arguments
                    clra                zero
                    clrb                terminator character
                    pshs      d         pass it
                    ldd       6,s       load the name pointer
                    pshs      d         pass it
                    leax      MsgNameFmt2,pcr point to the "%.8s%c" format
                    pshs      x         pass the format
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the truncated name
                    leas      8,s        drop the arguments
                    puls      pc,u      restore and return

EmitEndMarker       pshs      u         save the caller u register
                    ldd       GlbVar0035 check the flag global
                    bne       EmitEndDone skip if it is set
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       #'E       end marker character
                    pshs      d         pass it
                    lbsr      PutChar2  write the character
EmitEndCleanup      leas      4,s        drop the arguments
EmitEndDone         puls      pc,u      restore and return

EmitFcb             pshs      u         save the caller u register
                    lbsr      EmitStar  emit leading indentation
                    leax      MsgFcb,pcr point to the "fcb " directive
                    bra       EmitDirective join the common emit path

EmitFdb             pshs      u         save the caller u register
                    lbsr      EmitStar  emit leading indentation
                    leax      MsgFdb,pcr point to the "fdb " directive
EmitDirective       pshs      x         pass the directive string
                    lbsr      EmitSpaceText emit the directive
                    lbra      EmitCleanup2 clean up and return

EmitComment         pshs      u         save the caller u register
                    lbsr      EmitStar  emit leading indentation
                    leax      MsgStarSpace,pcr point to the "* " comment prefix
                    pshs      x         pass the string
                    lbsr      EmitText  emit the comment prefix
                    lbra      EmitCleanup2 clean up and return

EmitSectLetter      pshs      u         save the caller u register
                    ldd       4,s       load the section flag argument
                    beq       EmitVarLetter variable section if zero
                    ldd       #'d       data section letter
                    bra       EmitLetterTail emit it

EmitVarLetter       ldd       #'v       variable section letter
                    bra       EmitLetterTail emit it

EmitEndLetter       pshs      u         save the caller u register
                    ldd       #'e       end section letter
EmitLetterTail      pshs      d         pass the letter
                    lbsr      EmitCharOut write the character
                    lbra      EmitCleanup2 clean up and return

PlaceSymbol         pshs      u         save the caller u register
                    ldd       4,s       load the symbol pointer argument
                    pshs      d         pass it
                    lbsr      FlushStream resolve the symbol
                    leas      2,s        drop the argument
                    ldx       4,s       reload the symbol pointer
                    ldd       2,x       load its base value
                    ldx       4,s       reload the symbol pointer
                    addd      11,x      add its size field
                    ldx       4,s       reload the symbol pointer
                    std       4,x       store the computed address
                    std       [4,s]     store through the pointer too
                    ldx       4,s       reload the symbol pointer
                    ldd       6,x       load the flag word
                    anda      #$FE      clear a flag bit
                    andb      #$EF      clear another flag bit
                    std       6,x       store the flags back
                    clra                zero
                    clrb                zero
                    pshs      d         pass a zero argument
                    clra                zero
                    clrb                zero
                    pshs      d         pass a zero argument
                    pshs      d         pass a zero argument
                    ldx       10,s      reload the symbol pointer
                    ldd       8,x       load a field
                    pshs      d         pass it
                    lbsr      lseek     process the symbol
                    leas      8,s        drop the arguments
                    ldd       ResultLowWord,y   load the result value
                    puls      pc,u      restore and return

DumpStrings         pshs      u         save the caller u register
                    ldd       GlbVar006C load the string table head
                    lbeq      EmitReturn2 nothing to dump
                    ldd       GlbVar006C reload the head
                    pshs      d         pass it
                    bsr       PlaceSymbol resolve the first entry
                    leas      2,s        drop the argument
                    bra       DumpStringLoop enter the dump loop

DumpStringNext      ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    pshs      u         pass the current entry
                    lbsr      PutChar2  write it out
                    leas      4,s        drop the arguments
DumpStringLoop      ldd       GlbVar006C load the string table head
                    pshs      d         pass it
                    lbsr      GetChar   get the next entry
                    leas      2,s        drop the argument
                    tfr       d,u       keep the entry in u
                    cmpu      #$FFFF    end of the list?
                    bne       DumpStringNext loop while more remain
                    ldx       GlbVar006C load the table head
                    ldd       6,x       load the flag word
                    clra                isolate the low byte
                    andb      #$20      test the flag bit
                    beq       DumpStringEmit skip if clear
                    leax      MsgDumpStrings,pcr point to the "dumpstrings" text
                    ldd       6,x       reload the flag word
                    clra                isolate the low byte
                    andb      #$20      test the flag bit
DumpStringEmit      ldd       GlbVar006C load the table head
                    pshs      d         pass it
                    lbsr      CloseFile look up the label number
                    leas      2,s        drop the argument
                    leax      NameBuf,y point to the work buffer
                    pshs      x         pass it
                    lbsr      unlink    emit the string label
                    bra       EmitCleanup2 clean up and return

EmitDataInit        pshs      u,d       save u and reserve a local
                    ldd       Errno,y   load the current value
                    beq       DefaultCount default if zero
                    ldd       Errno,y   reload the value
                    bra       EmitDataBody use it

DefaultCount        ldd       #1        default value of one
EmitDataBody        std       ,s        store it into the local
                    leax      StdoutStream,y   point to the work field
                    pshs      x         pass it
                    lbsr      FlushStream resolve it
                    leas      2,s        drop the argument
                    ldd       GlbVar006C load the string table head
                    beq       EmitDataPtr skip if empty
                    ldd       GlbVar006C reload the head
                    pshs      d         pass it
                    lbsr      CloseFile look up the label number
                    leas      2,s        drop the argument
                    leax      NameBuf,y point to the work buffer
                    pshs      x         pass it
                    lbsr      unlink    emit the string label
                    leas      2,s        drop the argument
EmitDataPtr         ldd       GlbVar001F load another global pointer
                    beq       EmitDataFinish skip if null
                    ldd       GlbVar0023 load the associated global
                    pshs      d         pass it
                    lbsr      CloseFile look up the label number
                    leas      2,s        drop the argument
                    ldd       GlbVar001F reload the pointer
                    pshs      d         pass it
                    lbsr      unlink    emit the label
                    leas      2,s        drop the argument
EmitDataFinish      ldd       ,s        load the local count
                    pshs      d         pass it
                    lbsr      _exit     finalise the output
                    leas      2,s        drop the argument
EmitCleanup2        leas      2,s        drop the reserved local
EmitReturn2         puls      pc,u      restore and return

MsgRmb              fcc       / rmb %d/
                    fcb       C$CR,C$NULL
MsgLabelRmb         fcc       /%.8s%c rmb %d/
                    fcb       C$CR,C$NULL
MsgNameFmt          fcc       /%.8s%c/
                    fcb       C$NULL
MsgNameFmt2         fcc       /%.8s%c/
                    fcb       C$NULL
MsgFcb              fcc       /fcb /
                    fcb       C$NULL
MsgFdb              fcc       /fdb /
                    fcb       C$NULL
MsgStarSpace        fcc       /* /
                    fcb       C$NULL
MsgDumpStrings      fcc       /dumpstrings/
                    fcb       C$NULL
LoadNumWork         pshs      u         save the caller u register
                    leau      NumberWorkArea,y   point to the number work area
                    ldd       ,x        copy the first word
                    std       ,u        into the work area
                    ldd       2,x       copy the second word
                    std       2,u       into the work area
                    ldd       4,x       copy the third word
                    std       4,u       into the work area
                    ldd       6,x       copy the fourth word
                    std       6,u       into the work area
                    tfr       u,x       return the work area pointer
                    puls      pc,u      restore and return

NegateNumWork       bsr       LoadNumWork copy the number into the work area
                    lda       ,x        load the sign byte
                    eora      #$80      flip the sign bit
                    sta       ,x        store it back
                    rts                 return

GetNumValue         bsr       NormalizeNum normalise the number
                    ldd       2,x       fetch the resulting value
                    rts                 return

NormalizeNum        lda       ,x        load the sign byte
                    pshs      a         save it
                    bsr       LoadNumWork copy the number into the work area
                    bsr       ConvertDigits convert the digits
                    leax      3,x       advance past the header
                    lda       ,s+       recover the sign byte
                    bpl       NormNumDone positive, so done
                    lbra      LongNegDo negate the result

NormNumDone         rts                 return

ConvertDigits       lda       7,x       load the digit count
                    blt       PackBinary branch if already binary
                    pshs      x         save the base pointer
                    leax      7,x       point past to the digits
                    pshs      x,a       save the pointer and count
                    bra       DigitCountLoop enter the conversion loop

DigitMulLoop        ldx       1,s       load the digit pointer
                    ldb       #6        six bytes to process
                    pshs      b         save the byte counter
                    clra                clear the carry accumulator
ByteMulLoop         pshs      a         save the carry
                    lda       #10       multiply by ten
                    ldb       ,-x       take the next byte
                    mul                 times ten
                    addb      ,s+       add the carried value
                    adca      #0        propagate the carry
                    stb       ,x        store the digit back
                    dec       ,s        decrement the byte counter
                    bpl       ByteMulLoop loop over the bytes
                    leas      1,s        drop the counter
DigitCountLoop      dec       ,s        decrement the digit counter
                    bge       DigitMulLoop loop over the digits
                    leas      3,s        drop the locals
                    puls      pc,x      restore and return

PackBinary          pshs      u,x,a     save the registers
                    leau      7,x       point past the header
                    pshs      u         save the end pointer
ScanByteLoop        cmpx      ,s        reached the end?
                    bcc       PackDone  done scanning
                    lda       ,x+       load the next byte
                    beq       ScanByteLoop skip zero bytes
                    leax      -1,x      step back to the byte
                    pshs      x         save its address
                    clrb                clear the result accumulator
                    asl       ,x        shift a bit out
                    rolb                into the accumulator
                    asl       ,x        shift the next bit
                    rolb                into the accumulator
                    asl       ,x        shift the next bit
                    rolb                into the accumulator
                    lda       #5        five more bits
BitShiftLoop        asl       ,x        shift a bit out
                    rolb                into the accumulator
                    cmpb      #C$LF      decimal overflow?
                    bcs       BitNext   no adjust needed
                    subb      #10       subtract ten
                    inc       ,x        carry into the digit
BitNext             deca                count down the bits
                    bne       BitShiftLoop loop over the bits
                    lda       #8        eight bits for the next byte
                    leax      1,x       advance to the next byte
                    cmpx      2,s       past the end?
                    bcs       BitShiftLoop keep converting
                    puls      x         restore the digit pointer
                    inc       2,s       advance the scan
                    bne       ScanByteLoop continue scanning
PackDone            leas      3,s        drop the locals
                    puls      pc,u,x    restore and return

SwapNumWork         pshs      u         save the caller u register
                    ldu       4,s       load the destination pointer
                    exg       x,u       swap source and destination
                    ldd       ,u        copy the first word
                    std       ,x        into the destination
                    ldd       2,u       copy the second word
                    std       2,x       into the destination
                    ldd       4,u       copy the third word
                    std       4,x       into the destination
                    ldd       6,u       copy the fourth word
                    std       6,x       into the destination
                    puls      u         restore the caller u register
                    puls      d         pop the adjusted value
                    std       ,s        overwrite the stacked argument
                    rts                 return

IntToNum            leax      NumberWorkArea,y   point to the number work area
                    std       -2,s      stash the integer value
                    bpl       IntToNumPos positive value
                    nega                negate the value
                    negb                negate the value
                    sbca      #0        negate the value
                    std       5,x       store the magnitude
                    lda       #128      set the sign bit
IntToNumStore       sta       ,x        store the sign byte
                    clra                zero
                    clrb                zero
                    std       1,x       clear a header word
                    std       3,x       clear a header word
                    sta       7,x       clear the digit count
                    rts                 return

IntToNumPos         std       5,x       store the magnitude
                    clra                clear the sign byte
                    bra       IntToNumStore finish building the number

ClearNumWork        pshs      u         save the caller u register
                    leau      NumberWorkArea,y   point to the number work area
                    clra                zero
                    clrb                zero
                    std       ,u        clear the first word
                    std       2,u       clear the second word
                    ldd       ,x        load the source value
                    pshs      d         save it
                    std       3,u       store computed value into the structure
                    ldd       2,x       load the source low word
                    std       5,u       store into the structure
                    clr       7,u       clear the trailing byte
                    ldd       ,s++      pop the saved sign flag
                    bpl       NegDone   skip negation when non-negative
                    lda       #128      negative sign marker
                    sta       ,u        flag the value as negative
                    ldd       #0        zero for subtraction
                    subd      5,u       negate the low word
                    std       5,u       store negated low word
                    ldd       #0        zero for subtraction
                    sbcb      4,u       negate high word with borrow
                    sbca      3,u       continue the borrow
                    std       3,u       store negated high word
NegDone             tfr       u,x       return the structure pointer
                    puls      pc,u      return to caller

main                pshs      u         save the caller u register
                    leax      EmitDataInit,pcr point at the startup banner
                    pshs      x         push the banner argument
                    lbsr      InstallIntercept print the banner
                    leas      2,s        drop the argument
                    leax      NameBuf,y point at a global buffer
                    pshs      x         push it
                    lbsr      FormatXCounter initialize the buffer
                    leas      2,s        drop the argument
                    leax      NameDummy,pcr point at the _dummy_ name
                    pshs      x         push it
                    ldd       GlobalPointerArgument,y   global pointer argument
                    pshs      d         push it
                    lbsr      StrCpy    set up the default file name
                    leas      4,s        drop the arguments
                    lbsr      InitKeywordTable initialize compiler state
                    leax      FileTab,y file table base
                    stx       GlbVar0023 save as input file pointer
                    leax      StdoutStream,y   stdout stream
                    stx       GlbVar0025 save as output file pointer
                    lbra      ArgLoopNext enter the argument loop

ArgLoop             ldx       6,s       argv pointer
                    leax      2,x       advance to the next argument
                    stx       6,s       store advanced argv
                    ldu       ,x        load argument string pointer
                    ldb       ,u        first character
                    cmpb      #'-       is it a dash flag
                    lbne      InputFileArg no, treat as input file
                    lbra      NextFlag  yes, process flag characters

NextFlagChar        ldb       ,u        current flag character
                    sex                 sign extend to word
                    tfr       d,x       move into X for dispatch
                    lbra      FlagDispatch dispatch on the flag letter

FlagE               ldd       #1        set the e flag
                    std       GlbVar0021 store the flag
                    lbra      NextFlag  continue scanning flags

FlagS               ldd       #1        set the s flag
                    std       GlbVar0035 store the flag
                    lbra      NextFlag  continue scanning flags

FlagN               ldd       GlbVar0039 load the n counter
                    addd      #1        increment it
                    std       GlbVar0039 store it back
                    lbra      NextFlag  continue scanning flags

FlagO               leau      1,u       skip past the o letter
                    ldb       ,u        next character
                    cmpb      #'=       expect an equals sign
                    bne       FlagODone none, flag is complete
                    leax      ModeWStr,pcr write mode string
                    pshs      x         push it
                    leau      1,u       file name after the equals
                    pshs      u         push it
                    lbsr      Fopen     open the output file
                    leas      4,s        drop the arguments
                    std       GlbVar0025 save output file pointer
                    bne       FlagODone opened, continue
                    pshs      u         push the failing name
                    leax      MsgCantOpen,pcr cant open message
                    pshs      x         push it
                    leax      OutputStream,y   stderr stream
                    pshs      x         push it
                    lbsr      fprintf   report the error
                    leas      6,s        drop the arguments
                    lbsr      AbortExit abort compilation
FlagODone           leax      ,s        current stack pointer
                    bra       FlagArgEnd done with this flag argument

FlagP               ldd       #1        set the p flag
                    std       GlbVar0037 store the flag
                    bra       NextFlag  continue scanning flags

FlagUnknown         ldb       ,u        the unknown flag letter
                    sex                 sign extend to word
                    pshs      d         push it
                    leax      MsgUnknownFlag,pcr unknown flag message
                    pshs      x         push it
                    leax      OutputStream,y   stderr stream
                    pshs      x         push it
                    lbsr      fprintf   report the bad flag
                    leas      6,s        drop the arguments
                    lbsr      AbortExit abort compilation
                    bra       NextFlag  continue scanning flags

FlagDispatch        cmpx      #'e       letter e
                    lbeq      FlagE     handle the e flag
                    cmpx      #'s       letter s
                    lbeq      FlagS     handle the s flag
                    cmpx      #'n       letter n
                    lbeq      FlagN     handle the n flag
                    cmpx      #'o       letter o
                    lbeq      FlagO     handle the o flag
                    cmpx      #'p       letter p
                    beq       FlagP     handle the p flag
                    bra       FlagUnknown otherwise unknown flag

NextFlag            leau      1,u       advance to the next flag character
                    ldb       ,u        load it
                    lbne      NextFlagChar more characters to process
                    bra       ArgLoopNext end of this argument

FlagArgEnd          leas      ,x        restore the stack
                    bra       ArgLoopNext next argument

InputFileArg        ldd       GlbVar0072 input file already given
                    bne       ArgLoopNext yes, ignore the extra argument
                    ldd       GlbVar0072 reload the flag
                    addd      #1        increment it
                    std       GlbVar0072 mark input file seen
                    leax      FileTab,y file table base
                    pshs      x         push it
                    leax      ModeRStr,pcr read mode string
                    pshs      x         push it
                    ldd       [10,s]    argument file name pointer
                    pshs      d         push it
                    lbsr      FopenBuffered open the input file
                    leas      6,s        drop the arguments
                    std       GlbVar0023 save input file pointer
                    bne       InputOpened opened successfully
                    leax      MsgCantOpenInput,pcr cant open input message
                    pshs      x         push it
                    lbsr      ReportTokenErr print the error
                    leas      2,s        drop the argument
InputOpened         ldd       [6,s]     argument name pointer
                    std       GlbVar001F remember the source file name
ArgLoopNext         ldd       4,s       argument counter
                    addd      #$FFFF    decrement it
                    std       4,s       store it back
                    lbgt      ArgLoop   more arguments to process
                    lbsr      InitScanBuffer finish initialization
                    lbsr      ScanToken start the compile
                    bra       CompileTest enter the compile loop

CompileLoop         lbsr      ParseMulExpr parse the next declaration
CompileTest         ldd       GlbVar005F current token
                    cmpd      #$FFFF    end of file marker
                    bne       CompileLoop not yet, keep parsing
                    lbsr      EmitStringTable finalize the output
                    ldx       GlbVar0025 output file pointer
                    ldd       6,x       status flags
                    clra                clear high byte
                    andb      #$20      write error bit
                    beq       CloseOutput no write error
                    leax      MsgWriteError,pcr write error message
                    pshs      x         push it
                    lbsr      ReportTokenErr report the error
                    leas      2,s        drop the argument
CloseOutput         leax      StdoutStream,y   stdout stream
                    pshs      x         push it
                    lbsr      FlushStream flush and close output
                    leas      2,s        drop the argument
                    ldd       GlbErrCount error count
                    beq       MainDone  none, exit cleanly
                    ldd       GlbErrCount reload error count
                    pshs      d         push it
                    leax      MsgErrorCount,pcr error count message
                    pshs      x         push it
                    leax      OutputStream,y   stderr stream
                    pshs      x         push it
                    lbsr      fprintf   report the error count
                    leas      6,s        drop the arguments
                    bsr       AbortExit abort with cleanup
MainDone            puls      pc,u      return from main

AbortExit           pshs      u         save the caller u register
                    ldd       GlbVar001F temporary file name
                    beq       DoExit    none to remove
                    ldd       GlbVar001F reload the name
                    pshs      d         push it
                    lbsr      unlink    delete the temp file
                    leas      2,s        drop the argument
DoExit              ldd       #1        exit status one
                    pshs      d         push it
                    lbsr      exit      terminate the program
                    leas      2,s        drop the argument
                    puls      pc,u      return to caller

NameDummy           fcc       /_dummy_/
                    fcb       C$NULL
ModeWStr            fcb       $77
                    fcb       C$NULL
MsgCantOpen         fcc       /can't open %s/
                    fcb       C$CR,C$NULL
MsgUnknownFlag      fcc       /unknown flag : -%c/
                    fcb       C$CR,C$NULL
ModeRStr            fcb       $72
                    fcb       C$NULL
MsgCantOpenInput    fcc       /can't open input file/
                    fcb       C$NULL
MsgWriteError       fcc       /error writing assembly code file/
                    fcb       C$NULL
MsgErrorCount       fcc       /errors in compilation : %d/
                    fcb       C$CR,C$NULL
AllocFileSlot       pshs      u         save the caller u register
                    leau      FileTab,y file table base
SlotScanLoop        ldd       6,u       entry status flags
                    clra                clear high byte
                    andb      #$03      in-use bits
                    lbeq      SlotFound free slot found
                    leau      13,u      advance to next entry
                    pshs      u         push it
                    leax      TableLimit,y   table limit
                    cmpx      ,s++      past the end
                    bhi       SlotScanLoop keep scanning
                    ldd       #200      too many open files error
                    std       Errno,y   set errno
                    lbra      ReturnNull return null

                    puls      pc,u      return to caller

SetupFile           pshs      u         save the caller u register
                    ldu       8,s       supplied slot pointer
                    bne       HaveSlot  already have one
                    bsr       AllocFileSlot allocate a slot
                    tfr       d,u       move into U
HaveSlot            stu       -2,s      remember the slot
                    beq       ReturnNull allocation failed
                    ldd       4,s       file descriptor
                    std       8,u       store it in the slot
                    ldx       6,s       mode string
                    ldb       1,x       second character
                    cmpb      #'+       is it plus
                    beq       ModeReadWrite yes, read-write
                    ldx       6,s       reload mode string
                    ldb       2,x       third character
                    cmpb      #'+       is it plus
                    bne       ModeSingle no, single mode
ModeReadWrite       ldd       6,u       current flags
                    orb       #$03      set read-write bits
                    bra       StoreMode store the mode

ModeSingle          ldd       6,u       current flags
                    pshs      d         push them
                    ldb       [8,s]     mode first character
                    cmpb      #'r       is it r
                    beq       ModeReadBit read bit
                    ldb       [8,s]     reload mode character
                    cmpb      #'d       is it d
                    bne       ModeWriteBit no, write bit
ModeReadBit         ldd       #1        read bit
                    bra       ModeCombine combine the flags

ModeWriteBit        ldd       #2        write bit
ModeCombine         ora       ,s+       merge existing flags
                    orb       ,s+       merge low byte
StoreMode           std       6,u       store the mode flags
                    ldd       2,u       buffer start
                    addd      11,u      add buffer size
                    std       4,u       set buffer end
                    std       ,u        set current pointer
SlotFound           tfr       u,d       return the slot pointer
                    puls      pc,u      return to caller

ReturnNull          clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u      return null

OpenFileMode        pshs      u         save the caller u register
                    ldu       4,s       file descriptor argument
                    leas      -4,s       reserve local workspace
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear the permission word
                    ldx       10,s      mode string
                    ldb       1,x       second character
                    sex                 sign extend
                    tfr       d,x       move into X
                    bra       ModeExtCheck check mode extensions

ModeX               ldx       10,s      mode string
                    ldb       2,x       third character
                    cmpb      #'+       plus modifier
                    bne       ModeXPlain no, read only
                    ldd       #7        read-write-execute perms
                    bra       SetPerm   store the permission

ModeXPlain          ldd       #4        read permission
                    bra       SetPerm   store the permission

ModePlus            ldd       #3        read-write perms
SetPerm             std       ,s        store the permission word
                    bra       ModeMainChar process the primary mode

ModeBadExt          leax      4,s       discard workspace
                    lbra      ModeBad   bad mode string

ModeExtCheck        stx       -2,s      save the mode character
                    beq       ModeMainChar end of extensions
                    cmpx      #120      x extension
                    beq       ModeX     handle x
                    cmpx      #43       plus extension
                    beq       ModePlus  handle plus
                    bra       ModeBadExt unexpected character

ModeMainChar        ldb       [10,s]    primary mode character
                    sex                 sign extend
                    tfr       d,x       move into X
                    lbra      ModeDispatch dispatch on the mode

ModeR               ldd       ,s        permission word
                    orb       #$01      mark read
                    bra       DoOpen    open the file

ModeA               ldd       ,s        permission word
                    orb       #$02      mark write
                    pshs      d         push it
                    pshs      u         push the name
                    lbsr      open      open the file
                    leas      4,s        drop the arguments
                    std       2,s       save the descriptor
                    cmpd      #$FFFF    open failed
                    beq       ModeW     try creating instead
                    ldd       #2        seek from end
                    pshs      d         push it
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push offset high
                    pshs      d         push offset low
                    ldd       8,s       the descriptor
                    pshs      d         push it
                    lbsr      lseek     seek to end for append
                    leas      8,s        drop the arguments
                    bra       OpenReturn done opening

ModeW               ldd       ,s        permission word
                    orb       #$02      mark write
                    pshs      d         push it
                    pshs      u         push the name
                    lbsr      creat     create the file
                    bra       OpenDone  store the descriptor

ModeD               ldd       ,s        permission word
                    orb       #$81      mark directory read
DoOpen              pshs      d         push it
                    pshs      u         push the name
                    lbsr      open      open the file
OpenDone            leas      4,s        drop the arguments
                    std       2,s       save the descriptor
                    bra       OpenReturn done opening

ModeBad             leas      -4,x      restore the stack
SetErrBadMode       ldd       #203      bad mode error
                    std       Errno,y   set errno
                    clra                clear high byte
                    clrb                clear low byte
                    bra       OpenExit  return failure

ModeDispatch        cmpx      #114      r read mode
                    lbeq      ModeR     handle read
                    cmpx      #97       a append mode
                    lbeq      ModeA     handle append
                    cmpx      #119      w write mode
                    beq       ModeW     handle write
                    cmpx      #100      d directory mode
                    beq       ModeD     handle directory
                    bra       SetErrBadMode unrecognized mode

OpenReturn          ldd       2,s       return the descriptor
OpenExit            leas      4,s        discard the workspace
                    puls      pc,u      return to caller

                    pshs      u         save the caller u register
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         null buffer argument
                    ldd       8,s       mode string
                    pshs      d         push it
                    ldd       8,s       file name
                    pshs      d         push it
                    lbra      CallSetupFile open with default slot

Fopen               pshs      u         save the caller u register
                    ldd       6,s       mode string
                    pshs      d         push it
                    ldd       6,s       file name
                    pshs      d         push it
                    lbsr      OpenFileMode open the file descriptor
                    leas      4,s        drop the arguments
                    tfr       d,u       move into U
                    cmpu      #$FFFF    open failed
                    bne       FopenOk   opened successfully
                    clra                clear high byte
                    clrb                clear low byte
                    bra       FopenExit return null

FopenOk             clra                clear high byte
                    clrb                no supplied slot
                    bra       StreamInit build the stream

FopenBuffered       pshs      u         save the caller u register
                    ldd       8,s       buffer size hint
                    pshs      d         push it
                    lbsr      CloseFile allocate a buffer
                    leas      2,s        drop the argument
                    ldd       6,s       mode string
                    pshs      d         push it
                    ldd       6,s       file name
                    pshs      d         push it
                    lbsr      OpenFileMode open the file descriptor
                    leas      4,s        drop the arguments
                    tfr       d,u       move into U
                    stu       -2,s      save the descriptor
                    bge       StreamOk  opened successfully
                    clra                clear high byte
                    clrb                clear low byte
                    bra       FopenExit return null

StreamOk            ldd       8,s       allocated buffer
StreamInit          pshs      d         push it
                    ldd       8,s       mode string
                    pshs      d         push it
                    pshs      u         push the descriptor
CallSetupFile       lbsr      SetupFile build the stream structure
                    leas      6,s        drop the arguments
FopenExit           puls      pc,u      return to caller

PutStringLine       pshs      u         save the caller u register
                    leax      StdoutStream,y   stdout stream
                    pshs      x         push it
                    ldd       6,s       string argument
                    pshs      d         push it
                    bsr       FputStr   write the string
                    leas      4,s        drop the arguments
                    leax      StdoutStream,y   stdout stream
                    pshs      x         push it
                    ldd       #13       carriage return
                    pshs      d         push it
                    lbsr      PutChar2  write the newline
                    leas      4,s        drop the arguments
                    puls      pc,u      return to caller

FputStr             pshs      u         save the caller u register
                    ldu       4,s       stream pointer
                    leas      -1,s       reserve a local byte
                    bra       CopyByteStore enter the write loop

FputStrLoop         ldd       7,s       load the string pointer
                    pshs      d         push the character
                    ldb       2,s       get low byte of the char argument
                    sex                 sign-extend the char to 16 bits
                    pshs      d         push the character argument
                    lbsr      PutChar2  output the character via putc
                    leas      4,s        drop the pushed arguments
CopyByteStore       ldb       ,u+       fetch the next source byte
                    stb       ,s        store byte into the local
                    bne       FputStrLoop loop while byte is nonzero
                    leas      1,s        release the local byte
                    puls      pc,u      restore u and return

FormatXCounter      pshs      u,d       save the u and d registers
                    ldu       6,s       load the string argument pointer
                    bra       FormatXScanLoop enter the scan loop

FormatXNext         leau      1,u       advance to the next character
FormatXScanLoop     ldb       ,u        read the current character
                    sex                 sign-extend the character
                    std       ,s        save the current character
                    beq       FormatXFound stop at the end of string
                    ldd       ,s        reload the character
                    cmpd      #88       compare with 'X'
                    bne       FormatXNext keep scanning until 'X'
FormatXFound        ldd       ,s        reload the last character
                    beq       FormatXDone done if end of string reached
                    lbsr      GetProcId fetch the counter value to format
                    pshs      d         push the number to format
                    leax      >FmtDecimal,pcr point at the "%d" format
                    pshs      x         push the format string
                    pshs      u         push the destination pointer
                    lbsr      Sprintf   format the number into the buffer
                    leas      6,s        drop the three arguments
FormatXDone         ldd       6,s       return the original pointer
                    leas      2,s        release the local
                    puls      pc,u      restore and return

FmtDecimal          fcc       /%d/
                    fcb       C$NULL
EmitFloatBytes      pshs      u         save u
                    ldu       4,s       load the array pointer argument
                    leas      -4,s       reserve two locals
                    clra                clear high byte of row index
                    clrb                clear low byte of row index
                    bra       PutTableRowNext enter the outer loop

PutTableRow         clra                clear high byte of column index
                    clrb                clear low byte of column index
                    std       ,s        initialise the inner counter
                    bra       PutTableInnerNext enter the inner loop

PutTableCell        ldd       14,s      load the file pointer
                    pshs      d         push the file
                    ldb       ,u+       fetch the next byte
                    sex                 sign-extend the char
                    pshs      d         push the char
                    lbsr      PutChar2  output the character via putc
                    leas      4,s        drop the arguments
                    ldx       14,s      reload the file pointer
                    ldd       6,x       load the stream flags
                    clra                clear high byte
                    andb      #$20      test the error bit
                    bne       PutTableDone abort on write error
PutTableInnerNext   ldd       ,s        load the inner counter
                    addd      #1        increment it
                    std       ,s        store it back
                    subd      #1        recover the pre-increment value
                    cmpd      10,s      compare against the inner limit
                    blt       PutTableCell repeat the inner loop
                    ldd       2,s       load the row counter
                    addd      #1        increment the row
PutTableRowNext     std       2,s       store the row counter
                    ldd       2,s       reload the row counter
                    cmpd      12,s      compare against the row limit
                    blt       PutTableRow repeat the outer loop
PutTableDone        ldd       2,s       return the row counter
                    leas      4,s        release the locals
                    puls      pc,u      restore and return

PutChar2            pshs      u         save u
                    ldu       6,s       load the FILE pointer argument
                    ldd       6,u       load the stream flags
                    anda      #$80      isolate the active bit
                    andb      #$22      isolate the write mode bits
                    cmpd      #$8002    test for an active write stream
                    beq       PutcModeOk proceed if mode is ok
                    ldd       6,u       reload the flags
                    clra                clear high byte
                    andb      #$22      check the write mode bits
                    cmpd      #2        test whether it is a write stream
                    lbne      IoFail    fail if not writable
                    pshs      u         push the FILE
                    lbsr      PrepBuffer initialise the stream for writing
                    leas      2,s        drop the argument
PutcModeOk          ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$04      test the unbuffered bit
                    beq       PutcBuffered take the buffered path
                    ldd       #1        length of one byte
                    pshs      d         push the count
                    leax      7,s       point at the char byte
                    pshs      x         push the data pointer
                    ldd       8,u       load the file descriptor
                    pshs      d         push the path number
                    ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$40      test the text-mode bit
                    beq       PutcPickBinary pick the binary write routine
                    leax      writeln,pcr select the text write routine
                    bra       PutcDoWrite go call it

PutcPickBinary      leax      write,pcr select the binary write routine
PutcDoWrite         tfr       x,d       move routine address
                    tfr       d,x       back into x
                    jsr       ,x        perform the low-level write
                    leas      6,s        drop the write arguments
                    cmpd      #$FFFF    test for a write error
                    bne       PutcDone  return on success
                    ldd       6,u       reload the flags
                    orb       #$20      set the error bit
                    std       6,u       store the flags
                    lbra      IoFail    return failure

PutcBuffered        ldd       6,u       load the flags
                    anda      #$01      test the read-active bit
                    clrb                clear low byte
                    std       -2,s      save the test result
                    bne       PutcStore buffer already set up
                    pshs      u         push the FILE
                    lbsr      FlushBuffer flush and allocate the buffer
                    leas      2,s        drop the argument
PutcStore           ldd       ,u        load the current buffer pointer
                    addd      #1        advance it
                    std       ,u        store it back
                    subd      #1        recover the old pointer
                    tfr       d,x       into x
                    ldd       4,s       load the char
                    stb       ,x        store the char into the buffer
                    ldd       ,u        load the buffer pointer
                    cmpd      4,u       compare against the buffer end
                    bcc       PutcFlush flush when the buffer is full
                    ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$40      test the line-buffered bit
                    beq       PutcDone  done if fully buffered
                    ldd       4,s       reload the char
                    cmpd      #13       was it a carriage return
                    bne       PutcDone  done unless newline
PutcFlush           pshs      u         push the FILE
                    lbsr      FlushBuffer flush the buffer
                    std       ,s++      save status and drop the argument
                    lbne      IoFail    fail on flush error
PutcDone            ldd       4,s       return the written char
                    puls      pc,u      restore and return

PutWord             pshs      u         save u
                    ldu       4,s       load the FILE pointer argument
                    ldd       6,s       load the word value argument
                    pshs      d         push the word
                    pshs      u         push the FILE
                    ldd       #8        shift count of eight
                    lbsr      LsrEntry  shift the high byte down
                    pshs      d         push the high byte
                    lbsr      PutChar2  output the high byte via putc
                    leas      4,s        drop the arguments
                    ldd       6,s       reload the word value
                    pshs      d         push the low byte
                    pshs      u         push the FILE
                    lbsr      PutChar2  output the low byte via putc
                    lbra      FlushRet  return

CloseAllFiles       pshs      u,d       save the u and d registers
                    leau      FileTab,y point at the first FILE table entry
                    clra                clear high byte of index
                    clrb                clear low byte of index
                    std       ,s        initialise the loop counter
                    bra       CloseFileNext enter the loop

CloseFileLoop       tfr       u,d       current FILE pointer
                    leau      13,u      advance to the next FILE entry
                    pshs      d         push the FILE pointer
                    bsr       CloseFile close this stream
                    leas      2,s        drop the argument
CloseFileNext       ldd       ,s        load the index
                    addd      #1        increment it
                    std       ,s        store it back
                    subd      #1        recover the old index
                    cmpd      #16       done after all sixteen streams
                    blt       CloseFileLoop loop over the streams
                    lbra      IoReturn  return

CloseFile           pshs      u         save u
                    ldu       4,s       load the FILE pointer argument
                    leas      -2,s       reserve a local
                    cmpu      #0        test for a null stream
                    beq       CloseFileNull treat null as an error
                    ldd       6,u       load the flags
                    bne       CloseFileOpen proceed if the stream is open
CloseFileNull       ldd       #$FFFF    EOF/error result
                    lbra      IoReturn  return

CloseFileOpen       ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$02      test the dirty/write bit
                    beq       CloseNoFlush skip flush if clean
                    pshs      u         push the FILE
                    bsr       FlushStream flush the stream
                    leas      2,s        drop the argument
                    bra       CloseSaveStatus continue

CloseNoFlush        clra                clear high byte of status
                    clrb                clear low byte of status
CloseSaveStatus     std       ,s        save the flush result
                    ldd       8,u       load the file descriptor
                    pshs      d         push the path number
                    lbsr      close     close the OS path
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    std       6,u       mark the stream closed
                    ldd       ,s        return the flush status
                    bra       IoReturn  return

FlushStream         pshs      u         save u
                    ldu       4,s       load the FILE pointer argument
                    beq       IoFail    fail if null
                    ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$22      isolate the mode bits
                    cmpd      #2        test whether it is a write stream
                    beq       FlushWritable flush if writable
IoFail              ldd       #$FFFF    error result
                    puls      pc,u      restore and return

FlushWritable       ldd       6,u       load the flags
                    anda      #$80      isolate the active bit
                    clrb                clear low byte
                    std       -2,s      save the active test
                    bne       FlushDoWrite already active
                    pshs      u         push the FILE
                    lbsr      PrepBuffer set up the stream buffer
                    leas      2,s        drop the argument
FlushDoWrite        pshs      u         push the FILE
                    bsr       FlushBuffer flush the buffer
IoReturn            leas      2,s        release the local
                    puls      pc,u      restore and return

                    use       lib/flushbuffer.asm
FileTell            equ       NullBufDesc file position helper in this module

NullBufDesc         pshs      u         save u
                    puls      pc,u      return the caller pointer

GetChar             pshs      u         save u
                    ldu       4,s       load the FILE pointer argument
                    beq       GetcEof   EOF if null
                    ldd       6,u       load the flags
                    anda      #$01      test the read-active bit
                    clrb                clear low byte
                    std       -2,s      save the test
                    bne       GetcEof   return EOF if not readable
                    ldd       ,u        load the current pointer
                    cmpd      4,u       compare against the buffer end
                    bcc       GetcRefill refill when the buffer is empty
                    ldd       ,u        load the current pointer
                    addd      #1        advance it
                    std       ,u        store it back
                    subd      #1        recover the old pointer
                    tfr       d,x       into x
                    ldb       ,x        fetch the buffered byte
                    clra                zero-extend to a word
                    lbra      GetcDone  return the character

GetcRefill          pshs      u         push the FILE
                    lbsr      FillBuffer refill the buffer
                    lbra      DropResult return the result

                    pshs      u         save u for ungetc
                    ldu       6,s       load the FILE pointer argument
                    beq       GetcEof   EOF if null
                    ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$01      test the read-active bit
                    beq       GetcEof   fail if not reading
                    ldd       4,s       load the pushback char
                    cmpd      #$FFFF    reject pushing EOF
                    beq       GetcEof   reject EOF pushback
                    ldd       ,u        load the current pointer
                    cmpd      2,u       at the buffer base
                    bhi       UngetcStore room to push back
GetcEof             ldd       #$FFFF    EOF/error result
                    puls      pc,u      restore and return

UngetcStore         ldd       ,u        load the current pointer
                    addd      #$FFFF    back up one byte
                    std       ,u        store the pointer
                    tfr       d,x       into x
                    ldd       4,s       load the pushback char
                    stb       ,x        store char back into the buffer
                    ldd       4,s       reload the char
                    puls      pc,u      return the pushed char

                    pshs      u         save u for getw
                    ldu       4,s       load the FILE pointer argument
                    leas      -4,s       reserve two locals
                    pshs      u         push the FILE
                    lbsr      GetChar   read the high byte via getc
                    leas      2,s        drop the argument
                    std       2,s       save the high byte
                    cmpd      #$FFFF    test for EOF
                    beq       GetwEof   bail on EOF
                    pshs      u         push the FILE
                    lbsr      GetChar   read the low byte via getc
                    leas      2,s        drop the argument
                    std       ,s        save the low byte
                    cmpd      #$FFFF    test for EOF
                    bne       GetwCombine combine if valid
GetwEof             ldd       #$FFFF    EOF result
                    bra       GetwReturn return

GetwCombine         ldd       2,s       load the high byte
                    pshs      d         push it
                    ldd       #8        shift count of eight
                    lbsr      AslEntry  shift high byte up and combine
                    addd      ,s        add the low byte
GetwReturn          leas      4,s        release the locals
                    puls      pc,u      restore and return

FillBuffer          pshs      u         save u
                    ldu       4,s       load the FILE pointer argument
                    leas      -2,s       reserve a local
                    ldd       6,u       load the flags
                    anda      #$80      isolate the active bit
                    andb      #$31      isolate the mode bits
                    cmpd      #$8001    test for an active read stream
                    beq       FillCheckStdin proceed
                    ldd       6,u       reload the flags
                    clra                clear high byte
                    andb      #$31      check the mode bits
                    cmpd      #1        test whether it is a read stream
                    lbne      ReturnEof fail if not readable
                    pshs      u         push the FILE
                    lbsr      PrepBuffer set up the read buffer
                    leas      2,s        drop the argument
FillCheckStdin      leax      FileTab,y point at the stdin FILE entry
                    pshs      x         push it
                    cmpu      ,s++      is this stdin
                    bne       FillCheckBuf no, skip the stdout flush
                    ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$40      test the text-mode bit
                    beq       FillCheckBuf skip unless line-buffered
                    leax      StdoutStream,y   point at the stdout FILE entry
                    pshs      x         push it
                    lbsr      FlushStream flush stdout before reading
                    leas      2,s        drop the argument
FillCheckBuf        ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$08      test the buffer-allocated bit
                    beq       FillOneByte allocate a buffer if needed
                    ldd       11,u      load the buffer size
                    pshs      d         push the size
                    ldd       2,u       load the buffer base
                    pshs      d         push the base
                    ldd       8,u       load the file descriptor
                    pshs      d         push the path number
                    ldd       6,u       load the flags
                    clra                clear high byte
                    andb      #$40      mask flag bit 6
                    beq       SelReadFn bit clear, select read function
                    leax      readln,pcr point to write io function
                    bra       CallIoFn  go call it

SelReadFn           leax      read,pcr  point to read io function
CallIoFn            tfr       x,d       move function pointer to d
                    tfr       d,x       back into x for indirect call
                    jsr       ,x        call the selected io function
                    bra       AfterRead handle the result

FillOneByte         ldd       #1        request one byte
                    pshs      d         push count argument
                    leax      10,u      point to inline buffer
                    stx       2,u       set current pointer to buffer start
                    pshs      x         push buffer pointer argument
                    ldd       8,u       load buffer id
                    pshs      d         push id argument
                    lbsr      read      read one byte into buffer
AfterRead           leas      6,s        drop the three arguments
                    std       ,s        save read result
                    ldd       ,s        reload result
                    bgt       ReturnByte got a byte, return it
                    ldd       6,u       load flags for eof/error path
                    pshs      d         save flags on stack
                    ldd       2,s       check the status code
                    beq       SetErrFlag zero means error flag
                    ldd       #32       eof flag value
                    bra       MergeFlags go merge it

SetErrFlag          ldd       #16       error flag value
MergeFlags          ora       ,s+       merge into existing flags
                    orb       ,s+       merge the low byte too
                    std       6,u       store updated flags
ReturnEof           ldd       #$FFFF    return -1 for end of file
                    bra       DropResult go return

ReturnByte          ldd       2,u       load current pointer
                    addd      #1        advance past the byte
                    std       ,u        update position
                    ldd       2,u       reload pointer
                    addd      ,s        add byte count
                    std       4,u       store new end pointer
                    ldb       [2,u]     fetch the byte read
                    clra                zero-extend to a word
DropResult          leas      2,s        drop saved result local
GetcDone            puls      pc,u      restore and return

PrepBuffer          pshs      u         save u
                    ldu       4,s       load the buffer struct pointer
                    ldd       6,u       load flags
                    clra                isolate low byte
                    andb      #$C0      test already-sized bits
                    bne       MarkInited skip if already initialized
                    leas      -32,s      reserve a 32-byte local
                    leax      ,s        point x at the local
                    pshs      x         push buffer argument
                    ldd       8,u       load buffer id
                    pshs      d         push id argument
                    clra                zero offset high
                    clrb                zero offset low
                    pshs      d         push zero offset argument
                    lbsr      GetStat   query the buffer
                    leas      6,s        drop arguments
                    ldd       6,u       load flags
                    pshs      d         save flags
                    ldb       2,s       check the query result
                    bne       PickFlag80 nonzero selects other flag
                    ldd       #64       init flag value
                    bra       OrInitFlags go merge

PickFlag80          ldd       #128      alternate init flag value
OrInitFlags         ora       ,s+       merge into flags
                    orb       ,s+       merge low byte
                    std       6,u       store flags
                    leas      32,s       release the local
MarkInited          ldd       6,u       load flags
                    ora       #$80      mark as initialized
                    std       6,u       store back
                    clra                isolate low byte
                    andb      #$0C      test allocation-state bits
                    beq       CheckSize not yet allocated
                    puls      pc,u      already done, return

CheckSize           ldd       11,u      load size field
                    bne       CheckAlloc already sized
                    ldd       6,u       load flags
                    clra                isolate low byte
                    andb      #$40      test flag bit 6
                    beq       Size256   clear selects size 256
                    ldd       #128      buffer size 128
                    bra       StoreSize2 store it

Size256             ldd       #256      buffer size 256
StoreSize2          std       11,u      store the buffer size
CheckAlloc          ldd       2,u       load data pointer
                    bne       MarkHeap  already allocated
                    ldd       11,u      load size
                    pshs      d         push size argument
                    lbsr      RegionAlloc allocate memory
                    leas      2,s        drop argument
                    std       2,u       store data pointer
                    cmpd      #$FFFF    allocation failed
                    beq       UseInline fall back to inline buffer
MarkHeap            ldd       6,u       load flags
                    orb       #$08      mark heap-allocated
                    std       6,u       store flags
                    bra       ComputeBounds compute bounds

UseInline           ldd       6,u       load flags
                    orb       #$04      mark inline fallback
                    std       6,u       store flags
                    leax      10,u      point at inline buffer
                    stx       2,u       set data pointer inline
                    ldd       #1        inline size one
                    std       11,u      store size
ComputeBounds       ldd       2,u       load data pointer
                    addd      11,u      add size
                    std       4,u       store end pointer
                    std       ,u        store position too
                    puls      pc,u      return

strlen              pshs      u         save u
                    ldu       4,s       load string pointer
StrLenLoop2         ldb       ,u+       fetch byte, advance
                    bne       StrLenLoop2 loop until null
                    tfr       u,d       end pointer to d
                    subd      4,s       subtract start pointer
                    addd      #$FFFF    minus one for the null
                    puls      pc,u      return length

StrCpy              pshs      u         save u
                    ldu       6,s       load source pointer
                    leas      -2,s       reserve dest cursor
                    ldd       6,s       load dest pointer
                    std       ,s        initialize cursor
StrCpyLoop          ldb       ,u+       fetch source byte
                    ldx       ,s        load dest cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    stb       -1,x      store byte to dest
                    bne       StrCpyLoop loop until null copied
                    bra       StrRetDest return dest pointer

strcat              pshs      u         save u
                    ldu       6,s       load source pointer
                    leas      -2,s       reserve dest cursor
                    ldd       6,s       load dest pointer
                    std       ,s        initialize cursor
StrCatScanLoop      ldx       ,s        load cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    ldb       -1,x      fetch dest byte
                    bne       StrCatScanLoop scan to end of dest
                    ldd       ,s        cursor past the null
                    addd      #$FFFF    back up to the null
                    std       ,s        save append point
StrCatCopyLoop      ldb       ,u+       fetch source byte
                    ldx       ,s        load cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    stb       -1,x      append byte
                    bne       StrCatCopyLoop loop until null copied
StrRetDest          ldd       6,s       return dest pointer
                    leas      2,s        drop cursor
                    puls      pc,u      return

                    pshs      u         save u
                    ldu       4,s       load first pointer
                    bra       StrCmpLoop enter compare loop

StrCmpEqual         ldx       6,s       load second pointer
                    leax      1,x       advance it
                    stx       6,s       save cursor
                    ldb       -1,x      fetch second byte
                    bne       StrCmpAdv nonzero, keep comparing
                    clra                strings equal
                    clrb                result zero
                    puls      pc,u      return equal

StrCmpAdv           leau      1,u       advance first pointer
StrCmpLoop          ldb       ,u        fetch first char
                    sex                 sign-extend to word
                    pshs      d         save first char
                    ldb       [8,s]     fetch second char
                    sex                 sign-extend
                    cmpd      ,s++      compare the chars
                    beq       StrCmpEqual equal, keep comparing
                    ldb       [6,s]     load second char
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       ,u        load first char
                    sex                 sign-extend
                    subd      ,s++      first minus second
                    puls      pc,u      return the difference

StrNCpy             pshs      u         save u
                    ldu       6,s       load source pointer
                    leas      -2,s       reserve cursor
                    ldd       6,s       load dest pointer
                    std       ,s        initialize cursor
StrNCpyLoop         ldd       10,s      load remaining count
                    addd      #$FFFF    decrement it
                    std       10,s      save count
                    subd      #$FFFF    test original count
                    ble       StrNCpyPadLoop count exhausted
                    ldb       ,u+       fetch source byte
                    ldx       ,s        load cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    stb       -1,x      store byte
                    bne       StrNCpyLoop loop while nonzero
                    bra       StrNCpyPadLoop hit null, go pad

StrNCpyPad          clra                zero pad byte high
                    clrb                zero pad byte low
                    ldx       ,s        load cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    stb       -1,x      store null pad
StrNCpyPadLoop      ldd       10,s      load remaining count
                    addd      #$FFFF    decrement
                    std       10,s      save
                    subd      #$FFFF    test count
                    bgt       StrNCpyPad more padding needed
                    lbra      StrNRetDest return dest pointer

strncmp             pshs      u         save u
                    ldu       4,s       load first pointer
                    bra       StrNCmpLoop enter compare loop

StrNCmpAdv          ldx       6,s       load second pointer
                    leax      1,x       advance it
                    stx       6,s       save cursor
                    ldb       -1,x      fetch second byte
                    bne       StrNCmpNext nonzero, continue
                    clra                strings equal so far
                    clrb                result zero
                    puls      pc,u      return

StrNCmpNext         leau      1,u       advance first pointer
StrNCmpLoop         ldd       8,s       load remaining count
                    addd      #$FFFF    decrement
                    std       8,s       save
                    subd      #$FFFF    test count
                    ble       StrNCmpEnd count exhausted
                    ldb       ,u        fetch first byte
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       [8,s]     fetch second byte
                    sex                 sign-extend
                    cmpd      ,s++      compare
                    beq       StrNCmpAdv equal, keep comparing
StrNCmpEnd          ldd       8,s       load remaining count
                    bge       StrNCmpDiff still within count
                    clra                count expired, equal
                    clrb                zero result
                    bra       StrNCmpDone return

StrNCmpDiff         ldb       [6,s]     fetch second char
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       ,u        fetch first char
                    sex                 sign-extend
                    subd      ,s++      compute difference
StrNCmpDone         puls      pc,u      return

strncat             pshs      u         save u
                    ldu       6,s       load source pointer
                    leas      -2,s       reserve cursor
                    ldd       6,s       load dest pointer
                    std       ,s        initialize cursor
StrNCatScanLoop     ldx       ,s        load cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    ldb       -1,x      fetch dest byte
                    bne       StrNCatScanLoop scan to end of dest
                    ldd       ,s        cursor past the null
                    addd      #$FFFF    back up to the null
                    std       ,s        save append point
StrNCatCopyLoop     ldd       10,s      load remaining count
                    addd      #$FFFF    decrement
                    std       10,s      save
                    subd      #$FFFF    test count
                    ble       StrNCatTerm count exhausted
                    ldb       ,u+       fetch source byte
                    ldx       ,s        load cursor
                    leax      1,x       advance cursor
                    stx       ,s        save cursor
                    stb       -1,x      append byte
                    bne       StrNCatCopyLoop loop while nonzero
StrNCatTerm         ldd       10,s      load remaining count
                    bge       StrNRetDest no terminator needed
                    clra                need a null terminator
                    clrb                zero
                    stb       [,s]      store terminating null
StrNRetDest         ldd       6,s       return dest pointer
                    leas      2,s        drop cursor
                    puls      pc,u      return

                    pshs      u         save u
                    ldu       4,s       load dest pointer
UnpackNameLoop      ldx       6,s       load source cursor
                    leax      1,x       advance cursor
                    stx       6,s       save cursor
                    ldb       -1,x      fetch source byte
                    stb       ,u+       store to dest
                    bgt       UnpackNameLoop loop while high bit clear
                    ldb       -1,u      fetch last stored byte
                    clra                clear high byte
                    andb      #$7f      strip terminator high bit
                    stb       -1,u      store cleaned byte
                    clra                zero
                    clrb                zero
                    stb       ,u        null-terminate the string
                    ldd       4,s       return dest pointer
                    puls      pc,u      return

LongAdd             ldd       4,s       load addend low word
                    addd      2,x       add operand low word
                    std       ResultLowWord,y   store result low word
                    ldd       2,s       load addend high word
                    adcb      1,x       add with carry
                    adca      ,x        add high byte with carry
                    std       NumberWorkArea,y   store result high word
                    lbra      LongArithRet finalize and return

                    ldd       4,s       load minuend low word
                    subd      2,x       subtract operand low word
                    std       ResultLowWord,y   store result low word
                    ldd       2,s       load minuend high word
                    sbcb      1,x       subtract with borrow
                    sbca      ,x        subtract high byte with borrow
                    std       NumberWorkArea,y   store result high word
                    lbra      LongArithRet finalize and return

LongNeg             lbsr      CopyToScratch copy operand to scratch
LongNegDo           ldd       #0        zero
                    subd      2,x       zero minus low word
                    std       2,x       store negated low word
                    ldd       #0        zero
                    sbcb      1,x       subtract low byte with borrow
                    sbca      ,x        subtract high byte with borrow
                    std       ,x        store negated high word
                    rts                 return

LongNot             ldd       ,x        load high word
                    coma                complement high byte
                    comb                complement low byte
                    std       NumberWorkArea,y   store to scratch high
                    ldd       2,x       load low word
                    coma                complement high byte
                    comb                complement low byte
                    leax      NumberWorkArea,y   point x at scratch
                    std       2,x       store complemented low word
                    rts                 return

IntToLong           leax      NumberWorkArea,y   point x at scratch
                    std       2,x       store the low word
                    tfr       a,b       high byte to b
                    sex                 sign-extend it
                    tfr       a,b       replicate the sign byte
                    std       ,x        store sign-extended high word
                    rts                 return
                    leax      NumberWorkArea,y   point x at scratch
                    std       2,x       store the low word
                    clr       ,x        zero high byte
                    clr       1,x       zero next byte
                    rts                 return

StoreLong           pshs      y         save y
                    ldy       4,s       load destination pointer
                    ldd       ,x        load source high word
                    std       ,y        store to dest
                    ldd       2,x       load source low word
                    std       Dest,y     store to dest
                    puls      x         restore x
                    exg       y,x       swap the pointers
                    puls      d         pop saved value
                    std       ,s        place return result
                    rts                 return

LongShiftLeft       ldx       2,s       load operand pointer
                    pshs      b         save shift count
                    lbsr      CopyToScratch copy operand to scratch
                    puls      b         restore count
                    tstb                count zero
                    beq       ShiftLeftDone nothing to shift
ShiftLeftLoop       asl       3,x       shift lowest byte left
                    rol       2,x       rotate carry up
                    rol       1,x       rotate carry up
                    rol       ,x        rotate into high byte
                    decb                decrement count
                    bne       ShiftLeftLoop loop
ShiftLeftDone       puls      d         pop saved value
                    std       ,s        place result
                    rts                 return
                    ldx       2,s       load operand pointer
                    pshs      b         save shift count
                    lbsr      CopyToScratch copy operand to scratch
                    puls      b         restore count
                    tstb                count zero
                    beq       ShiftRightDone nothing to shift
ShiftRightLoop      asr       ,x        arithmetic shift high byte right
                    ror       1,x       rotate carry down
                    ror       2,x       rotate carry down
                    ror       3,x       rotate into low byte
                    decb                decrement count
                    bne       ShiftRightLoop loop
ShiftRightDone      puls      d         pop saved value
                    std       ,s        place result
                    rts                 return

LongArithRet        tfr       cc,a      save condition codes
                    puls      x         pop return address
                    stx       2,s       relocate it
                    leas      2,s        drop slot
                    leax      NumberWorkArea,y   point to result scratch
                    tfr       a,cc      restore condition codes
                    rts                 return with result pointer

CopyToScratch       ldd       ,x        load operand high word
                    std       NumberWorkArea,y   copy to scratch
                    ldd       2,x       load operand low word
                    leax      NumberWorkArea,y   repoint x at scratch
                    std       2,x       store low word
                    rts                 return

                    use       lib/imul.asm
                    clr       ResultSignFlag,y   clear the result sign flag
                    leax      >UDivEntry,pcr select the unsigned divide routine
                    stx       DivideRoutinePointer,y   store the divide routine pointer
                    bra       DivZeroCheck go check for a zero divisor

SignedDivSetup      leax      >SDivEntry,pcr select the signed divide routine
                    stx       DivideRoutinePointer,y   store the divide routine pointer
                    clr       ResultSignFlag,y   clear the result sign flag
                    tst       2,s       test the sign of the dividend
                    bpl       DivZeroCheck skip if the dividend is non-negative
                    inc       ResultSignFlag,y   mark the result sign as negative
DivZeroCheck        subd      #0        test the divisor for zero
                    bne       DivCallSel divide if the divisor is nonzero
                    puls      x         recover the return address
                    ldd       ,s++      recover the dividend
                    jmp       ,x        return the dividend unchanged on zero divisor

DivCallSel          ldx       2,s       load the dividend
                    pshs      x         pass it to the divide routine
                    jsr       [DivideRoutinePointer,y] call the selected divide routine
                    ldd       ,s        fetch the returned value
                    std       2,s       save the returned value
                    tfr       x,d       move the result into d
                    tst       ResultSignFlag,y   check the result sign flag
                    beq       DivStoreResult skip negate if positive
                    nega                negate the result
                    negb                negate the result
                    sbca      #0        negate the result
DivStoreResult      std       ,s++      store the final result
                    rts                 return

                    use       lib/divide.asm

                    use       lib/shift.asm

SendSignal          std       Errno,y   store the signal code
                    pshs      y,b       save registers
                    os9       F$ID      get our process id
                    puls      y,b       restore registers
                    os9       F$Send    send the signal to ourselves
                    rts                 return

GetStat             lda       5,s       load the path number
                    ldb       3,s       load the status function selector
                    beq       GetStatX  branch on selector value
                    cmpb      #1        selector one
                    beq       GetStatCall handle with a plain call
                    cmpb      #6        selector six
                    beq       GetStatCall handle with a plain call
                    cmpb      #2        selector two
                    beq       GetStatXU handle with a pointer return
                    cmpb      #5        selector five
                    beq       GetStatXU handle with a pointer return
                    ldb       #E$UnkSvc unknown function error
                    lbra      SysCallErr report the error

                    use       lib/getstat.asm

GetStatX            ldx       6,s       load the parameter register
GetStatCall         os9       I$GetStt  get file status
                    lbra      SysCallRet return the status result

                    lda       5,s       load the path number
                    ldb       3,s       load the setstat selector
                    beq       SetStatX  branch on selector value
                    cmpb      #2        selector two
                    beq       SetStatXU handle with a pointer parameter
                    ldb       #E$UnkSvc unknown function error
                    lbra      SysCallErr report the error

SetStatX            ldx       6,s       load the parameter register
                    os9       I$SetStt  set file status
                    lbra      SysCallRet return the result

                    use       lib/setstat.asm

                    use       lib/access.asm

                    use       lib/openpath.asm

                    use       lib/closepath.asm

                    ldx       2,s       load the pathname
                    ldb       5,s       load the access mode
                    os9       I$MakDir  make the directory
                    lbra      SysCallRet return the result

                    use       lib/createheadb.asm
                    use       lib/createtail.asm

                    use       lib/deletepath.asm

                    lda       3,s       load the path number
                    os9       I$Dup     duplicate the path
                    lbcs      SysCallErr report the error
                    tfr       a,b       return the new path number
                    clra                clear the high byte
                    rts                 return

                    use       lib/readpath.asm

                    use       lib/writepath.asm

                    use       lib/seek.asm
HighResultWord      equ       NumberWorkArea this module's long-value high cell
LowResultWord       equ       ResultLowWord this module's long-value low cell

GrowHeap            ldd       BreakPointer,y   load the current break pointer
                    pshs      d         save it
                    ldd       4,s       load the requested size
                    cmpd      UpdateFreeSpace,y   compare with the free space
                    bcs       HeapAlloc enough free already
                    addd      BreakPointer,y   compute the needed top
                    pshs      y         save the base
                    subd      ,s        compute the growth amount
                    os9       F$Mem     request more memory
                    tfr       y,d       new memory top
                    puls      y         restore y
                    bcc       HeapGrown branch on success
                    ldd       #$FFFF    return failure
                    leas      2,s        drop the local
                    rts                 return

HeapGrown           std       BreakPointer,y   save the new break pointer
                    addd      UpdateFreeSpace,y   recompute the free space
                    subd      ,s        recompute the free space
                    std       UpdateFreeSpace,y   update the free space
HeapAlloc           leas      2,s        drop the local
                    ldd       UpdateFreeSpace,y   load the free space
                    pshs      d         save it
                    subd      4,s       deduct the requested size
                    std       UpdateFreeSpace,y   update the free space
                    ldd       BreakPointer,y   load the break pointer
                    subd      ,s++      back up by the requested size
                    pshs      d         save the allocation address
                    clra                zero fill value
                    ldx       ,s        point at the allocation
HeapZeroLoop        sta       ,x+       clear the allocated bytes
                    cmpx      BreakPointer,y   until reaching the break
                    bcs       HeapZeroLoop loop
                    puls      pc,d      return the allocation address

RegionAlloc         ldd       2,s       load the requested size
                    addd      RegionPointer,y   add to the region pointer
                    bcs       RegionFail fail on overflow
                    cmpd      RegionLimit,y   compare with the region limit
                    bcc       RegionFail fail if past the limit
                    pshs      d         save the new top
                    ldx       RegionPointer,y   load the old region pointer
                    clra                zero fill value
RegionZeroLoop      cmpx      ,s        reached the new top
                    bcc       RegionDone done filling
                    sta       ,x+       clear a byte
                    bra       RegionZeroLoop loop

RegionDone          ldd       RegionPointer,y   pick up the new top
                    puls      x         save the new region pointer
                    stx       RegionPointer,y   return
                    rts

RegionFail          ldd       #$FFFF    return failure
                    rts                 return

GetProcId           pshs      y         save y
                    os9       F$ID      get the process id
                    puls      y         restore y
                    bcc       GetProcIdOk branch on success
                    lbcs      SysCallErr report the error
GetProcIdOk         tfr       a,b       return the process id
                    clra                clear the high byte
                    rts                 return

GetUserId           pshs      y         save y
                    os9       F$ID      get the process id and user
                    bcc       GetUserIdOk branch on success
GetUserIdErr        puls      y         restore y
                    lbra      SysCallErr report the error

GetUserIdOk         tfr       y,d       return the user id
                    puls      pc,y      return

                    pshs      y         save y
                    bsr       GetUserId get the current user id
                    std       -2,s      save it
                    beq       SetUserCall allow if super user
                    ldb       #E$FNA    permission error
                    bra       GetUserIdErr report the error

SetUserCall         ldy       4,s       load the new user id
                    os9       F$SUser   change the user id
                    bcc       SetUserOk branch on success
                    cmpb      #208      was it an unsupported call
                    bne       GetUserIdErr report any other error
                    tfr       y,d       move the id into d
                    ldy       >GlbVar004B load the process descriptor pointer
                    std       GlbVar0009,y     store the user id directly
SetUserOk           clra                indicate success
                    clrb                indicate success
                    puls      pc,y      return

InstallIntercept    pshs      u         save u
                    tfr       y,u       point u at our globals
                    ldx       4,s       load the handler address
                    stx       SignalHandler,y   save the signal handler
                    leax      >IcptHandler,pcr point at the intercept routine
                    os9       F$Icpt    install the signal intercept
                    puls      u         restore u
                    lbra      SysCallRet return through the shared carry-check epilogue

IcptHandler         tfr       u,y       recover the intercept work pointer into y
                    clra                clear high byte of pushed argument
                    pshs      d         push the signal number argument
                    jsr       [SignalHandler,y] call the installed user signal handler
                    leas      2,s        discard the pushed argument
                    rti                 return from the intercept

                    use       lib/syscallerr.asm

exit                lbsr      RtsStub   call the rts stub during teardown
                    lbsr      CloseAllFiles flush and finalize output before exit
_exit               ldd       2,s       load the exit status from the stack
                    os9       F$Exit    terminate the process
RtsStub             rts                 return to caller

* ------------------------------------------------------------------
* WorkBlockImage - cc1-style init image for the work block (see _start):
* rts stub + count/block table + relocation dirs + module-name string.
* ------------------------------------------------------------------
                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       WBIcount2-WBIblock1 count1 = length of block1 (DP data)

                    * ---- block1: DP data image  ->  data base
WBIblock1           fcb       $00
WBIblk1ptr          fdb       CtypeTab  reloc2 data-to-data pointer to the ctype table

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
WBIcount2           fdb       WBIblk2End-WBIblock2 count2 = length of block2 (non-DP data)

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fcc       /x expected/
                    fcb       $00
Pow10Img            fdb       10000,1000,100,10 powers of ten
CtypeTabImg         fcb       0,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       C$NULL,C$NULL
                    fcb       109,$40,$69
                    fcb       C$NULL,C$NULL
                    fcc       |TAh-.BP0CESkkkkkkkkkk/(]x_d|
                    fcb       C$NULL
                    fcc       /jjjjjjjjjjjjjjjjjjjjjjjjjj+f,Yj/
                    fcb       C$NULL
                    fcc       /jjjjjjjjjjjjjjjjjjjjjjjjjj)X*D/
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$09,$00,$00,$00,$0D,$0E
                    fcb       0,$00,$00,$0E,$0C,$01,$0E,$0F
                    fcb       13,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$03,$00,$0A,$02,$0A
                    fcb       3,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$07
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$06,$00,$0E
                    fcb       $00
WBIptr2             fdb       LineBuffer+$FF reloc2 data-to-data ptr into the line buffer
                    fcb       0,$01,$00,$02,$00
                    fcb       0,$00,$00,$00,$0C,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00
WBIptr3             fdb       DummyErrorSymbol+$14 reloc2 data-to-data ptr into dummy symbol
NameBufImg          fcc       /cstr.XXXXX/
                    fcb       $00
FileTabImg          fcb       0,$00,$00,$00,$00,$00,$00
                    fcb       1,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$02,$00,$01
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00
                    fcb       $42
                    fcb       0,$02,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00,$00,$00
                    fcb       0,$00,$00,$00,$00,$00

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
WBIblk2End          fdb       (reloc1End-reloc1Start)/2 nreloc1 = text-reloc count; marks block2 end

                    * ---- reloc1: text relocation offsets
reloc1Start         equ       *
reloc1End           equ       *

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       (reloc2End-reloc2Start)/2 nreloc2 = data-reloc count

                    * ---- reloc2: data relocation offsets
reloc2Start         fdb       WBIblk1ptr-WBIblock1,HDRADV+WBIptr2-WBIblock2,HDRADV+WBIptr3-WBIblock2
reloc2End           equ       *

                    * ---- name: trailing module-name string
                    fcc       /c.pass1/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end