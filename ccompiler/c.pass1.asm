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
rev                 set       $01
edition             set       $05

                    mod       eom,name,tylg,atrv,_start,size

                    * ------------------------------------------------------------------
                    * Data area (named rmb fields).  rmb reserves RAM without emitting
                    * bytes; OS-9 allocates <size> at load, cstart inits from WorkBlockImage.
                    * Names for ,y-referenced fields are derived from the code comments.
                    * ------------------------------------------------------------------
                    rmb       $1
GlbVar0001          rmb       $1
Dest                rmb       $1
GlbVar0003          rmb       $2
GlbVar0005          rmb       $2
GlbVar0007          rmb       $2
GlbVar0009          rmb       $2
GlbVar000B          rmb       $2
GlbVar000D          rmb       $2
GlbVar000F          rmb       $2
GlbVar0011          rmb       $2
GlbVar0013          rmb       $2
GlbVar0015          rmb       $2
GlbVar0017          rmb       $2
GlbVar0019          rmb       $2
GlbVar001B          rmb       $2
GlbVar001D          rmb       $2
GlbVar001F          rmb       $2
GlbVar0021          rmb       $2
GlbVar0023          rmb       $2
GlbVar0025          rmb       $2
GlbLineNum          rmb       $2
GlbErrCount         rmb       $2
GlbVar002B          rmb       $2
GlbNodeList         rmb       $2
GlbVar002F          rmb       $2
GlbVar0031          rmb       $2
GlbVar0033          rmb       $2
GlbVar0035          rmb       $2
GlbVar0037          rmb       $2
GlbVar0039          rmb       $2
GlbVar003B          rmb       $4
GlbVar003F          rmb       $2
GlbVar0041          rmb       $2
GlbFreeList         rmb       $2
GlbVar0045          rmb       $2
GlbVar0047          rmb       $2
GlbVar0049          rmb       $2
GlbVar004B          rmb       $2
GlbVar004D          rmb       $2
GlbVar004F          rmb       $2
GlbVar0051          rmb       $2
GlbVar0053          rmb       $2
GlbVar0055          rmb       $2
GlbVar0057          rmb       $2
GlbVar0059          rmb       $2
GlbVar005B          rmb       $4
GlbVar005F          rmb       $2
GlbVar0061          rmb       $2
GlbVar0063          rmb       $2
GlbVar0065          rmb       $1
GlbVar0066          rmb       $2
GlbVar0068          rmb       $2
GlbVar006A          rmb       $2
GlbVar006C          rmb       $6
GlbVar0072          rmb       $4
MsgBuf              rmb       $B
Pow10               rmb       $8
CtypeTab            rmb       $80
ActionTable         rmb       $80
IsBufferFull        rmb       $2
DummyErrorSymbol    rmb       $1C
GlobalPointerArgument rmb       $2
NameBuf             rmb       $B
FileTab             rmb       $D
StdoutStream        rmb       $D
OutputStream        rmb       $B6
TableLimit          rmb       $40
BreakPointer        rmb       $2
NumberWorkArea      rmb       $2
ResultLowWord       rmb       $6
RegionPointer       rmb       $2
RegionLimit         rmb       $2
Errno               rmb       $2
DefaultLabel        rmb       $2
RecordContextField  rmb       $2
RecordContextField2 rmb       $2
OutputBuffer        rmb       $A
TempDigitBuffer     rmb       $A
NameBuffer          rmb       $100
FilenameBuffer      rmb       $1E
SymbolTableB        rmb       $100
SymbolTable         rmb       $100
LineBuffer          rmb       $100
PreviousLineBuffer  rmb       $100
ResultSignFlag      rmb       $1
DivideRoutinePointer rmb       $2
UpdateFreeSpace     rmb       $2
SignalHandler       rmb       $2
                    rmb       $780     remaining data, bss and heap
size                equ       .

name                equ       *
                    fcs       /c.pass1/
                    fcb       edition

* --- shared C runtime startup (see lib/cstart.asm) ---
RTBASE              equ       $0284     runtime-globals block base in the data area
DATAEND             equ       $0813     end of static data / heap start / stack limit
HDRADV              equ       $0076     advance to where the non-DP data starts
                    use       lib/cstart.asm

AllocNode           pshs      u         save the frame
                    ldu       $04,s     load the parent node argument
                    leas      -6,s       allocate local slots
                    ldd       GlbFreeList load the free-list head
                    std       $02,s     save it
                    beq       AllocFromHeap allocate from heap if empty
                    ldx       $02,s     take a node from the free list
                    ldd       $10,x     load the next free pointer
                    std       GlbFreeList unlink node from the free list
                    bra       InitNode  node obtained

AllocFromHeap       ldd       #$0012    request eighteen bytes
                    pshs      d         push the size
                    lbsr      AllocMem  allocate from the heap
                    leas      2,s        drop the size argument
                    std       $02,s     save the new node pointer
InitNode            ldd       #$0012    copy length eighteen bytes
                    pshs      d         push the length
                    ldd       $04,s     source template pointer
                    pshs      d         push the source
                    stu       $08,s     stash the destination node
                    pshs      u         push the destination node
                    bsr       CopyBlock copy template into the node
                    leas      6,s        drop the copy arguments
                    ldd       #$0009    nine words to clear
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
                    ldd       $02,s     the new node pointer
                    ldx       $04,s     the parent node
                    std       $0e,x     link node into the parent
                    lbra      Drop6Ret  return the new node

FreeNode            pshs      u         save the frame
                    ldu       $04,s     load the node argument
                    leas      -2,s       allocate a local slot
                    ldd       $0e,u     load the child link
                    std       ,s        save it
                    ldd       #$0012    copy length eighteen bytes
                    pshs      d         push the length
                    pshs      u         push the source node
                    ldd       $04,s     child pointer as destination
                    pshs      d         push the destination
                    bsr       CopyBlock copy the node contents
                    leas      6,s        drop the copy arguments
                    ldd       GlbFreeList current free-list head
                    ldx       ,s        the child pointer
                    std       $10,x     chain node onto the free list
                    ldd       ,s        reload the node pointer
                    std       GlbFreeList push node onto the free list
                    lbra      DropArgRet return

CopyBlock           pshs      u         save the frame
                    ldu       $04,s     source pointer
                    bra       CopyByteTest enter the copy loop

CopyByteLoop        ldb       ,u+       read a source byte
                    ldx       $06,s     load the destination pointer
                    leax      $01,x     advance the destination
                    stx       $06,s     save the destination back
                    stb       -$01,x    store the copied byte
CopyByteTest        ldd       $08,s     load the remaining count
                    addd      #$FFFF    decrement the count
                    std       $08,s     store the count back
                    subd      #$FFFF    test for zero
                    bne       CopyByteLoop copy the next byte
                    puls      pc,u      return from the copy

PrintFileName       pshs      u         save the frame
                    leax      FilenameBuffer,y   point at the file name buffer
                    pshs      x         push the file name argument
                    leax      FmtNameColon,pcr point at the format string
                    pshs      x         push the format
                    lbsr      Fprintf3Arg print the source file name
                    lbra      PopArgsRet return

ReportTokenErr      pshs      u         save the frame
                    ldd       $04,s     load the token argument
                    pshs      d         push it
                    bsr       PrintErrLoc print the error location
                    leas      2,s        drop the argument
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    lbsr      FlushStream flush the output stream
                    lbra      ReportErrExit return

ReportMsgErr        pshs      u         save the frame
                    leax      MsgMultiDef,pcr point at the message string
                    pshs      x         push the message
                    bsr       PrintErrLoc print the error with the message
                    lbra      DropArgRet return

PrintErrLoc         pshs      u         save the frame
                    ldd       GlbVar003F load the current line number
                    pshs      d         push the line number
                    ldd       $06,s     load the error argument
                    pshs      d         push it
                    leax      LineBuffer,y   point at the source line buffer
                    pshs      x         push the buffer
                    ldd       GlbVar0063 load the column position
                    bra       SpanReport compute and report the error

ReportFmtErr        pshs      u         save the frame
                    leas      -50,s      allocate the format buffer
                    leax      MsgCompilerErr,pcr point at the format string
                    pshs      x         push the format
                    leax      $02,s     point at the work buffer
                    pshs      x         push the buffer
                    lbsr      StrCpy    format into the buffer
                    leas      4,s        drop the format arguments
                    ldd       $38,s     load the first value
                    pshs      d         push it
                    leax      $02,s     point at the work buffer
                    pshs      x         push the buffer
                    lbsr      StrCat    append the formatted text
                    leas      4,s        drop the arguments
                    leax      ,s        point at the built string
                    pshs      x         push the string
                    ldd       $38,s     load the second value
                    pshs      d         push it
                    bsr       PrintErrSpan report the error span
                    leas      4,s        drop the arguments
                    leas      50,s       release the format buffer
                    puls      pc,u      return

PrintErrSpan        pshs      u         save the frame
                    ldu       $04,s     load the node argument
                    ldd       $0e,u     load the span start
                    pshs      d         push it
                    ldd       $08,s     load the line argument
                    pshs      d         push it
                    leax      LineBuffer,y   point at the source line buffer
                    pshs      x         push the buffer
                    ldd       $10,u     load the span end
SpanReport          subd      ,s++      compute the span length
                    pshs      d         push it
                    bsr       PrintDiagnostic print the diagnostic
                    lbra      Drop6Ret  return

PrintDiagnostic     pshs      u         save the frame
                    ldu       $04,s     load the column count
                    lbsr      PrintFileName print the source file name
                    ldd       $08,s     load the line argument
                    pshs      d         push it
                    leax      FmtLineNum,pcr point at the line format
                    pshs      x         push the format
                    lbsr      Fprintf3Arg print the line number
                    leas      4,s        drop the arguments
                    ldd       $06,s     load the column argument
                    pshs      d         push it
                    leax      FmtBanner,pcr point at the column format
                    pshs      x         push the format
                    lbsr      Fprintf3Arg print the column number
                    leas      4,s        drop the arguments
                    ldd       $08,s     load the error line number
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
                    cmpd      $08,s     error on the previous line
                    bne       BumpErrCount skip source echo otherwise
                    leax      PreviousLineBuffer,y   point at the previous line buffer
                    pshs      x         push the buffer
                    lbsr      PrintStrLn print the previous source line
                    leas      2,s        drop the argument
                    bra       CaretPadTest draw the caret

CaretFromStack      leas      ,x        restore the stack pointer
                    bra       CaretPadTest draw the caret

CaretPadLoop        ldd       #$0020    space character
                    pshs      d         push it
                    lbsr      PutCharOut print a space
                    leas      2,s        drop the argument
                    leau      -$01,u    count down the columns
CaretPadTest        cmpu      #$0000    more columns to pad
                    bgt       CaretPadLoop pad up to the error column
                    leax      MsgCaret,pcr point at the caret string
                    pshs      x         push it
                    bsr       PrintStrLn print the caret marker
                    leas      2,s        drop the argument
BumpErrCount        ldd       GlbErrCount load the error count
                    addd      #$0001    increment it
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

Fprintf3Arg         pshs      u         save the frame
                    ldd       $08,s     load the third argument
                    pshs      d         push it
                    ldd       $08,s     load the second argument
                    pshs      d         push it
                    ldd       $08,s     load the first argument
                    pshs      d         push it
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    lbsr      fprintf   formatted print
                    leas      8,s        drop the print arguments
                    puls      pc,u      return

PrintStrLn          pshs      u         save the frame
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    ldd       $06,s     load the string pointer
                    pshs      d         push it
                    lbsr      FputStr   write the string
                    leas      4,s        drop the arguments
                    ldd       #$000D    carriage return
                    pshs      d         push it
                    bsr       PutCharOut print the newline
                    bra       DropArgRet return

PutCharOut          pshs      u         save the frame
                    leax      OutputStream,y   point at the output stream
                    pshs      x         push the stream
                    ldb       $07,s     load the character argument
                    sex                 sign-extend to a word
                    pshs      d         push it
                    lbsr      PutChar2  write the character
PopArgsRet          leas      4,s        drop the arguments
                    puls      pc,u      return

WalkTree            pshs      u         save the frame
                    ldu       $04,s     load the tree node
                    stu       -$02,s    test the node pointer
                    beq       RetU      return on a null node
                    ldd       $0a,u     load the left child
                    pshs      d         push it
                    bsr       WalkTree  recurse the left subtree
                    leas      2,s        drop the argument
                    ldd       $0C,u     load the right child
                    pshs      d         push it
                    lbsr      WalkTree  recurse the right subtree
                    leas      2,s        drop the argument
                    pshs      u         push the current node
                    bsr       LinkNode  link node into the list
DropArgRet          leas      2,s        drop the argument
RetU                puls      pc,u      return

LinkNode            pshs      u         save the frame
                    ldu       $04,s     load the node argument
                    stu       -$02,s    test the node pointer
                    beq       LinkDone  skip if null
                    ldd       GlbNodeList load the node list head
                    std       $0a,u     chain onto the list
                    stu       GlbNodeList push node onto the list
LinkDone            puls      pc,u      return

CopyStruct          pshs      u         save the frame
                    ldd       #$0016    copy length twenty-two bytes
                    pshs      d         push the length
                    ldd       $08,s     source pointer
                    pshs      d         push the source
                    ldd       $08,s     destination pointer
                    pshs      d         push the destination
                    lbsr      CopyBlock copy the structure
Drop6Ret            leas      6,s        drop the arguments
                    puls      pc,u      return

ClassifyType        pshs      u         save the frame
                    ldd       GlbVar005F load the current type
                    cmpd      #$0033    is it a basic type
                    bne       CheckType34 not a scalar type
                    ldx       GlbVar0061 load the type subclass
                    cmpx      #$0001    compare against subclass one
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0002    compare against subclass two
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0007    compare against subclass seven
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$000A    compare against subclass ten
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0008    compare against subclass eight
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0004    compare against subclass four
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0003    compare against subclass three
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0006    compare against subclass six
                    lbeq      RetOne    matched a scalar type
                    cmpx      #$0005    compare against subclass five
                    lbeq      RetOne    matched a scalar type
                    lbra      RetZero   not a base type keyword, return zero

CheckType34         ldd       GlbVar005F load the current token kind
                    cmpd      #$0034    is it type kind 0x34
                    lbne      RetZero   no, return zero
                    ldx       GlbVar0061 token value is a pointer
                    ldd       $08,x     fetch the type field
                    cmpd      #_start   compare against base type code
                    bra       Type34Match test the match

IsQualifierKw       pshs      u         save the frame pointer
                    ldd       GlbVar005F current token kind
                    cmpd      #$0033    is it keyword kind 0x33
                    lbne      RetZero   no, return zero
                    ldx       GlbVar0061 token value
                    cmpx      #$000E    qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #$000D    qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #_start   qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #$0010    qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #$000F    qualifier keyword code
                    lbeq      RetOne    matched, return one
                    cmpx      #$0021    qualifier keyword code
Type34Match         lbeq      RetOne    matched, return one
                    lbra      RetZero   none matched, return zero

RemovePtrLevel      pshs      u         save the frame pointer
                    ldd       $04,s     load the type word argument
                    asra                shift high byte right
                    rorb                rotate into low byte
                    asra                shift right again
                    rorb                rotate into low byte
                    andb      #$F0      keep the indirection nibble
                    bra       CombineTypeBits combine with base type

AddPtrLevel         pshs      u         save the frame pointer
                    ldd       $04,s     load the type word argument
                    andb      #$F0      mask the indirection nibble
                    aslb                shift low byte left
                    rola                rotate into high byte
                    aslb                shift left again
                    rola                rotate into high byte
                    addd      #$0010    bump the indirection count
CombineTypeBits     pshs      d         save the new indirection bits
                    ldd       $06,s     reload the original type word
                    clra                clear high byte
                    andb      #$0f      keep the base type nibble
                    addd      ,s++      merge base type with indirection
                    puls      pc,u      return the combined type

IsOpToken           pshs      u         save the frame pointer
                    ldu       $04,s     load the token code argument
                    cmpu      #$004C    below operator range
                    blt       RetZero   not an operator, return zero
                    cmpu      #$0063    above operator range
                    bgt       RetZero   not an operator, return zero
                    ldd       #$0001    it is an operator
                    bra       ExpectRet return one

GetNodeType         pshs      u         save the frame pointer
                    ldu       $04,s     load the node pointer argument
                    stu       -$02,s    test for null
                    beq       RetZero   null, return zero
                    ldd       $02,u     fetch the node type field
                    bra       ExpectRet return it

ExpectToken         pshs      u         save the frame pointer
                    ldd       GlbVar005F load the current token
                    cmpd      $04,s     does it match the expected token
                    bne       ExpectErr no, report the error
                    lbsr      ScanToken consume the token
RetZero             clra                result high byte zero
                    clrb                result low byte zero
ExpectRet           puls      pc,u      return

ExpectErr           ldu       #$0000    start at character table index zero
                    bra       FindCharCond enter the search loop

FindCharLoop        tfr       u,d       index into d
                    leax      CtypeTab,y token-to-character table base
                    leax      d,x       index into the table
                    ldb       ,x        fetch the char for this token
                    sex                 sign extend to d
                    cmpd      $04,s     does it match the expected token
                    beq       CharFound found the character
                    leau      $01,u     advance to next index
FindCharCond        cmpu      #$0080    end of the table
                    blt       FindCharLoop keep searching
CharFound           tfr       u,d       index into d
                    stb       >MsgBuf,y store char into the message buffer
                    leax      >MsgBuf,y point at the buffer
                    pshs      x         pass to print
                    lbsr      PrintErrLoc print expected-token error
                    leas      2,s        drop the argument
RetOne              ldd       #$0001    return one
                    puls      pc,u      return

SyncDeclarator      pshs      u         save the frame pointer
                    bra       SyncCheck check the current token first

SyncLoop            lbsr      ScanToken advance to the next token
SyncCheck           ldd       GlbVar005F load the current token
                    cmpd      #$0028    open paren
                    beq       SyncDone  stop, found declarator start
                    ldd       GlbVar005F reload current token
                    cmpd      #$002A    pointer star
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
ParseExpr           pshs      u         save the frame pointer
                    ldd       #$FFA2    stack space needed
                    lbsr      stkcheck  verify stack space
                    leas      -14,s      allocate locals
                    lbsr      ParsePrimary parse the left operand
                    std       $0C,s     save the operand node
                    lbne      CheckPrecLoop got operand, climb precedence
                    clra                no operand, result high zero
                    clrb                result low zero
                    lbra      ParseExprExit return

                    lbra      CheckPrecLoop unreachable fallthrough

ParseExprLoop       ldd       GlbVar005F operator token kind
                    std       $0a,s     save the operator kind
                    ldd       GlbVar0061 operator value
                    std       $08,s     save the operator value
                    std       ,s        also as working precedence
                    ldd       GlbVar003F current line number
                    std       $04,s     save the line
                    ldd       GlbVar0063 source position
                    std       $02,s     save the position
                    lbsr      ScanToken consume the operator token
                    ldx       $0a,s     reload the operator
                    bra       CheckSpecialOp classify the operator

CheckOpPrec         ldd       $0a,s     operator kind
                    cmpd      #$00A0    below assignment range
                    blt       BumpPrec  treat with normal precedence
                    ldd       $0a,s     reload operator kind
                    cmpd      #$00A9    assignment operator range
                    ble       BuildBinNode right associative, keep value
BumpPrec            ldd       $08,s     operator value
                    addd      #$0001    bump precedence for left associative
                    std       ,s        update working precedence
                    bra       BuildBinNode build the binary node

CheckSpecialOp      cmpx      #$0064    special operator check
                    beq       BuildBinNode keep operator value
                    cmpx      #$0078    special operator check
                    beq       BuildBinNode keep operator value
                    bra       CheckOpPrec otherwise check precedence

BuildBinNode        ldd       ,s        working precedence
                    pshs      d         pass as argument
                    lbsr      ParseExpr recurse for the right operand
                    leas      2,s        drop the argument
                    tfr       d,u       right operand node
                    stu       -$02,s    test for null
                    lbeq      MissingRhsErr missing right operand
                    ldd       $0a,s     operator kind
                    cmpd      #$0064    comma-like operator
                    lbne      MakeBinNode otherwise build normal node
                    ldd       #$002F    node kind
                    pshs      d         push kind
                    lbsr      ExpectToken expect matching token
                    std       ,s++      save and discard result
                    bne       FreeAndReturn on error, cleanup
                    ldd       GlbVar0063 source position
                    std       $02,s     save position
                    ldd       GlbVar003F current line
                    std       $04,s     save line
                    ldd       #$0003    node kind
                    pshs      d         push kind
                    lbsr      ParseExpr parse another operand
                    leas      2,s        drop the argument
                    std       $06,s     save the operand
                    beq       MissingOperandErr missing operand error
                    ldd       $02,s     position argument
                    pshs      d         push
                    ldd       $06,s     operand argument
                    pshs      d         push
                    ldd       #$0003    node kind argument
                    pshs      d         push
                    ldd       $0C,s     left operand argument
                    pshs      d         push
                    pshs      u         right operand argument
                    ldd       #$002F    node kind argument
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
                    leax      $0e,s     restore the frame
                    bra       ExprRestoreStack return path

MakeBinNode         ldd       $02,s     position argument
                    pshs      d         push
                    ldd       $06,s     operand value argument
                    pshs      d         push
                    ldd       $0C,s     left operand argument
                    pshs      d         push
                    pshs      u         right operand argument
                    ldd       $14,s     line argument
                    pshs      d         push
                    ldd       $14,s     operator kind argument
                    pshs      d         push
                    lbsr      NewExprNode build the binary node
                    leas      12,s       drop the arguments
                    std       $0C,s     save as the new left operand
                    bra       CheckPrecLoop climb precedence again

MissingRhsErr       leax      MsgOperandExpected,pcr missing operand message
                    pshs      x         push
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
CheckPrecLoop       lbsr      IsTypeToken look up next operator precedence
                    std       -$02,s    test it
                    beq       ParseExprDone no operator, done
                    ldd       $12,s     outer precedence
                    cmpd      GlbVar0061 versus this operator's precedence
                    lble      ParseExprLoop higher, keep building
                    bra       ParseExprDone else done

ExprRestoreStack    leas      -$0e,x    restore stack from saved frame
ParseExprDone       ldd       $0C,s     result node
ParseExprExit       leas      14,s       free the locals
                    puls      pc,u      return

ParsePrimary        pshs      u         save the frame pointer
                    ldd       #$FFA4    stack space needed
                    lbsr      stkcheck  verify stack space
                    leas      -12,s      allocate locals
                    ldu       #$0000    null result node
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
                    std       -$02,s    test it
                    beq       SizeofExpr not a type, sizeof expression
                    lbsr      ParseCast build the type node
                    tfr       d,u       type node
                    ldd       #$002E    expect close paren
                    pshs      d         push
                    lbsr      ExpectToken expect it
                    leas      2,s        drop the argument
                    bsr       ParsePrimary parse the cast operand
                    std       $0a,u     attach the operand
                    lbne      LeftOperandCheck on error finish
                    pshs      u         cast node
                    lbsr      LinkNode  link the node
                    leas      2,s        drop the argument
                    ldu       #$0000    clear result
                    lbra      LeftOperandCheck finish

SizeofExpr          clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero argument
                    lbsr      ParseExpr parse the operand expression
                    leas      2,s        drop the argument
                    tfr       d,u       operand node
                    stu       -$02,s    test it
                    bne       ExpectCloseParen got operand
                    bra       SizeofBuildNode build empty node

SizeofRestoreStack  leas      -$0C,x    restore stack from saved frame
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
                    ldd       #$0036    sizeof node kind
                    pshs      d         push
                    lbsr      NewExprNode build the sizeof node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
ExpectCloseParen    ldd       #$002E    expect close paren
                    pshs      d         push
                    lbsr      ExpectToken expect it
                    lbra      PrimaryTail finish

ParseUnaryPrefix    ldd       GlbVar005F operator token
                    std       $08,s     save the operator
                    ldd       GlbVar003F current line
                    std       $06,s     save line
                    ldd       GlbVar0063 source position
                    std       $04,s     save position
                    lbsr      ScanToken advance past the operator
                    lbsr      ParsePrimary parse the operand
                    std       $0a,s     save the operand
                    beq       UnaryOperandErr missing operand
                    ldd       $04,s     position argument
                    pshs      d         push
                    ldd       $08,s     operator argument
                    pshs      d         push
                    ldd       #$000E    prefix node kind
                    pshs      d         push
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    ldd       $12,s     operand argument
                    pshs      d         push
                    ldd       $12,s     operand argument
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
                    std       $06,s     save line
                    ldd       GlbVar0063 source position
                    std       $04,s     save position
                    lbsr      ScanToken advance past the token
                    ldd       GlbVar005F current token
                    cmpd      #$002D    type-cast marker
                    bne       ParenSubExpr no, parse a subexpression
                    lbsr      ScanToken advance
                    lbsr      ClassifyType is it a type keyword
                    std       -$02,s    test it
                    beq       ParenExprNoType not a type
                    lbsr      ParseCast build the type node
                    std       $0a,s     save the type
                    bra       ParenExpectClose expect the close paren

ParenExprNoType     clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero argument
                    lbsr      ParseExpr parse the expression
                    leas      2,s        drop the argument
                    std       $0a,s     save the node
                    bne       ParenExpectClose got it
                    leax      $0C,s     restore frame pointer
                    lbra      SizeofRestoreStack handle the missing operand

ParenExpectClose    ldd       #$002E    expect close paren
                    pshs      d         push
                    lbsr      ExpectToken expect it
                    leas      2,s        drop the argument
                    bra       ParenBuildNode build the node

ParenSubExpr        lbsr      ParsePrimary parse the operand
                    std       $0a,s     save the operand
ParenBuildNode      ldd       $0a,s     operand or type node
                    std       ,s        store working copy
                    ldd       $04,s     position argument
                    pshs      d         push
                    ldd       $08,s     line argument
                    pshs      d         push
                    leax      $04,s     pointer to the node
                    pshs      x         push
                    lbsr      EmitExpr  compute the node result
                    std       ,s        store the result
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         zero field
                    ldd       #$0036    sizeof node kind
                    pshs      d         push
                    lbsr      NewExprNode build the node
                    leas      12,s       drop the arguments
                    tfr       d,u       result node
                    ldd       ,s        the node
                    pshs      d         push
                    lbsr      WalkTree  free the temporary tree
PrimaryTail         leas      2,s        drop the argument
                    bra       LeftOperandCheck finish

ParsePrimaryDispatch cmpx      #$0037    leaf token: constant
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #$0034    leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #$004A    leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #$004B    leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #$0036    leaf token
                    lbeq      MakeLeafNode build a leaf node
                    cmpx      #$002D    cast or sizeof marker
                    lbeq      ParseCastOrSizeof parse cast or sizeof
                    cmpx      #$0040    prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #$0043    prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #$0044    prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #$0042    prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #$003D    prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #$003C    prefix operator token
                    lbeq      ParseUnaryPrefix parse unary prefix
                    cmpx      #$0041    compare token against a type keyword
                    lbeq      ParseUnaryPrefix branch to that keyword handler
                    cmpx      #$003B    compare token 3B
                    lbeq      ParseParenExpr branch to its handler
LeftOperandCheck    cmpu      #$0000    test whether a left operand exists yet
                    bne       OpDispatchA have operand, dispatch operator
                    clra                result high byte zero
                    clrb                result low byte zero
                    lbra      BinParseDone return empty expression

OpDispatchA         ldx       GlbVar005F load current token type
                    lbra      OpTableA  dispatch on the operator token

BuildNodeTok2D      ldd       GlbVar0063 save current line number
                    std       $04,s     stash line in frame
                    ldd       GlbVar003F save file/column global
                    std       $06,s     stash it in frame
                    lbsr      ScanToken advance to next token
                    ldd       $04,s     reload saved line
                    pshs      d         pass as node argument
                    ldd       $08,s     load left operand pointer
                    pshs      d         pass left operand
                    ldd       #$000F    node type field
                    pshs      d         pass type field
                    lbsr      ParsePostfix parse the right-hand postfix operand
                    pshs      d         pass right operand
                    pshs      u         pass left node
                    ldd       #$0065    operator code for the node
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the binary tree node
                    leas      12,s       drop node arguments
                    tfr       d,u       new node becomes current
                    ldd       #$002E    following operator token
                    lbra      EmitOpAndLoop emit it and continue loop

BuildNodeTok2B      lbsr      ScanToken advance past the operator token
                    ldd       #$0002    lookup kind two
                    pshs      d         pass lookup kind
                    lbsr      ParseExpr look up the operand symbol
                    leas      2,s        drop argument
                    std       $0a,s     save returned pointer
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
                    ldd       #$0036    constant node kind
                    pshs      d         pass node kind
                    lbsr      NewExprNode build a placeholder constant node
                    leas      12,s       drop arguments
                    std       $0a,s     save as operand
Tok2BNodeChain      ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       #$000C    node type field
                    pshs      d         pass type field
                    ldd       $10,s     left operand pointer
                    pshs      d         pass left operand
                    pshs      u         pass current node
                    ldd       #$0050    operator code
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the tree node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       #$000F    node type field
                    pshs      d         pass type field
                    clra                null operand high
                    clrb                null operand low
                    pshs      d         pass null operand
                    pshs      u         pass current node
                    ldd       #$0042    operator code
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the tree node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    ldd       #$002C    operator token to emit
EmitOpAndLoop       pshs      d         pass token
                    lbsr      ExpectToken emit the operator token
                    leas      2,s        drop argument
                    lbra      OpDispatchA loop for next operator

BuildNodeTok45      ldd       GlbVar005F current token type
                    std       $08,s     save token type
                    ldd       GlbVar003F file/column global
                    std       $06,s     save it in frame
                    ldd       GlbVar0063 line number
                    std       $04,s     save it in frame
                    ldd       GlbVar0041 nesting counter
                    addd      #$0001    increment it
                    std       GlbVar0041 store back
                    lbsr      ScanToken advance to next token
                    ldd       GlbVar0041 reload nesting counter
                    addd      #$FFFF    decrement it back
                    std       GlbVar0041 store back
                    ldd       GlbVar005F new token type
                    cmpd      #$0034    is it a constant token
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
                    std       $0a,s     save operand node
                    ldd       $04,s     saved line/frame value
                    pshs      d         pass it
                    ldd       $08,s     saved frame value
                    pshs      d         pass it
                    ldd       #$000F    node type field
                    pshs      d         pass type field
                    ldd       $10,s     operand node
                    pshs      d         pass operand
                    pshs      u         pass current node
                    ldd       $12,s     operator code from frame
                    pshs      d         pass operator code
                    lbsr      NewExprNode build the binary node
                    leas      12,s       drop arguments
                    tfr       d,u       becomes current node
                    lbsr      ScanToken advance to next token
                    lbra      OpDispatchA loop for next operator

OpTableA            cmpx      #$002D    operator token 2D
                    lbeq      BuildNodeTok2D handle it
                    cmpx      #$002B    operator token 2B
                    lbeq      BuildNodeTok2B handle it
                    cmpx      #$0045    operator token 45
                    lbeq      BuildNodeTok45 handle it
                    cmpx      #$0046    operator token 46
                    lbeq      BuildNodeTok45 handle it
OpDispatchB         ldx       GlbVar005F reload current token type
                    bra       OpTableB  dispatch the second operator set

BuildNodeTok3C      ldd       #$003E    canonical operator code 3E
                    std       GlbVar005F override current token
                    leax      $0C,s     point at frame slot
                    bra       RelNodeAlloc go build the node

BuildNodeTok3D      ldd       #$003F    canonical operator code 3F
                    std       GlbVar005F override current token
                    bra       RelNodeBuild go build the node

RelNodeAlloc        leas      -$0C,x    reserve node argument space
RelNodeBuild        ldd       GlbVar0063 line number
                    pshs      d         pass line number
                    ldd       GlbVar003F file/column global
                    pshs      d         pass it
                    ldd       #$000E    node type field
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

OpTableB            cmpx      #$003C    operator token 3C
                    beq       BuildNodeTok3C handle it
                    cmpx      #$003D    operator token 3D
                    beq       BuildNodeTok3D handle it
MergeResult         tfr       u,d       move current node to return register
BinParseDone        leas      12,s       release locals
                    puls      pc,u      return to caller

ParsePostfix        pshs      u         save caller frame pointer
                    ldd       #$FFAE    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate a local
                    ldu       #$0000    null accumulator node
                    bra       PostfixLoop enter the postfix loop

PostfixLoop         ldd       GlbVar005F current token type
                    cmpd      #$002E    is it the postfix separator
                    beq       PostfixDone none, finish
                    ldd       #$0002    lookup kind two
                    pshs      d         pass kind
                    lbsr      ParseExpr look up member operand
                    leas      2,s        drop argument
                    std       ,s        save operand pointer
                    beq       PostfixCheckChain not found, skip node build
                    ldx       ,s        operand pointer
                    ldd       $10,x     its type field
                    pshs      d         pass it
                    ldx       $02,s     previous node pointer
                    ldd       $0e,x     its field
                    pshs      d         pass it
                    clra                null field high
                    clrb                null field low
                    pshs      d         pass null field
                    pshs      u         pass accumulator node
                    ldd       $08,s     operand pointer
                    pshs      d         pass operand
                    ldd       #$000B    postfix node kind
                    pshs      d         pass node kind
                    lbsr      NewExprNode build the postfix node
                    leas      12,s       drop arguments
                    std       ,s        save the node
                    ldu       ,s        becomes accumulator
PostfixCheckChain   ldd       GlbVar005F current token type
                    cmpd      #$0030    chained postfix operator
                    bne       PostfixDone no, finish loop
                    lbsr      ScanToken advance to next token
                    bra       PostfixLoop loop for next postfix

PostfixDone         tfr       u,d       move accumulator to return register
                    bra       ConstOpExit go to shared epilogue

EvalConstOperand    pshs      u         save caller frame pointer
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate a local
                    ldd       $06,s     argument value
                    pshs      d         pass it
                    lbsr      ParseExpr look up the operand
                    std       ,s        save operand pointer
                    lbsr      OptExprTree resolve or evaluate the node
                    leas      2,s        drop argument
                    tfr       d,u       result node pointer
                    stu       -$02,s    save local copy
                    beq       NotConstErr null, emit error
                    ldd       $06,u     node kind field
                    cmpd      #$0036    is it a constant node
                    bne       NotConstErr no, emit error
                    ldd       $08,u     constant value
                    std       ,s        save the value
                    bra       FreeConstNode proceed to free node

NotConstErr         clra                zero value high
                    clrb                zero value low
                    std       ,s        store zero value
                    leax      MsgConstantRequired,pcr constant-required message
                    pshs      x         pass the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
FreeConstNode       stu       -$02,s    reload node pointer
                    beq       ConstResult null, skip freeing
                    pshs      u         pass node pointer
                    lbsr      WalkTree  free the temporary node
                    leas      2,s        drop argument
ConstResult         ldd       ,s        load constant value to return
ConstOpExit         leas      2,s        release the local
                    puls      pc,u      return to caller

IsTypeToken         pshs      u         save caller frame pointer
                    ldd       #$FFC0    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    ldx       GlbVar005F current token type
                    bra       TypeTokTable dispatch the type test

TokAToType          ldd       #$0057    canonical type token
                    std       GlbVar005F rewrite current token
                    ldd       #$0008    type size
                    bra       SetTypeSize store the size

TokBToType          ldd       #$0052    canonical type token
                    std       GlbVar005F rewrite current token
                    ldd       #$000D    type size
                    bra       SetTypeSize store the size

TokCToType          ldd       #$0051    canonical type token
                    std       GlbVar005F rewrite current token
                    ldd       #$000C    type size
SetTypeSize         std       GlbVar0061 store type size global
TokIsType           ldd       #$0001    token is a type
                    puls      pc,u      return true

CheckTypeRange      ldd       GlbVar005F current token type
                    cmpd      #$0047    below the type range
                    blt       CheckTypeRange2 if so, check extended range
                    ldd       GlbVar005F current token type
                    cmpd      #$005F    within the first type range
                    ble       TypeYes   yes, it is a type
CheckTypeRange2     ldd       GlbVar005F current token type
                    cmpd      #$00A0    below extended type range
                    lblt      ConstOpZero no, not a type
                    ldd       GlbVar005F current token type
                    cmpd      #$00A9    above extended type range
                    lbgt      ConstOpZero no, not a type
TypeYes             ldd       #$0001    token is a type
                    lbra      ConstOpReturn return true

TypeTokTable        cmpx      #$0041    type keyword A
                    beq       TokAToType map it
                    cmpx      #$0042    type keyword B
                    beq       TokBToType map it
                    cmpx      #$0043    type keyword C
                    beq       TokCToType map it
                    cmpx      #$0030    already a type token
                    beq       TokIsType return true
                    cmpx      #$0078    already a type token
                    lbeq      TokIsType return true
                    cmpx      #$0064    already a type token
                    lbeq      TokIsType return true
                    cmpx      #$002F    not a type token
                    lbeq      ConstOpZero return false
                    bra       CheckTypeRange check the type code ranges

                    puls      pc,u      return (unreached)

FoldBinaryOp        pshs      u         save caller frame pointer
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  verify stack space
                    ldx       $04,s     operator code to fold
                    lbra      FoldBinaryConst dispatch to the fold routine

FoldAdd             ldd       $06,s     left operand
                    addd      $08,s     add the right operand
                    puls      pc,u      return the sum

FoldSub             ldd       $06,s     left operand
                    subd      $08,s     subtract the right operand
                    puls      pc,u      return the difference

FoldMul             ldd       $06,s     left operand
                    pshs      d         pass it
                    ldd       $0a,s     right operand
                    lbsr      MulEntry  multiply
                    puls      pc,u      return the product

FoldDiv             ldd       $08,s     right operand is the divisor
                    beq       FoldDivZero zero divisor, division error
                    ldd       $06,s     left operand
                    pshs      d         pass it
                    ldd       $0a,s     divisor
                    lbsr      SDivImpl  divide
                    bra       FoldDivDone return the quotient

FoldMod             ldd       $08,s     right operand is the divisor
                    beq       FoldDivZero zero divisor, division error
                    ldd       $06,s     left operand
                    pshs      d         pass it
                    ldd       $0a,s     divisor
                    lbsr      SignedDivSetup take the modulo
FoldDivDone         puls      pc,u      return the result

FoldDivZero         lbsr      PrintNodeMsg report divide by zero
                    lbra      ConstOpZero return zero

FoldAnd             ldd       $06,s     left operand
                    anda      $08,s     and the high byte
                    andb      $09,s     and the low byte
                    puls      pc,u      return the bitwise and

FoldOr              ldd       $06,s     left operand
                    ora       $08,s     or the high byte
                    orb       $09,s     or the low byte
                    puls      pc,u      return the bitwise or

FoldXor             ldd       $06,s     left operand
                    eora      $08,s     xor the high byte
                    eorb      $09,s     xor the low byte
                    puls      pc,u      return the bitwise xor

FoldShiftLeft       ldd       $06,s     left operand
                    pshs      d         pass it
                    ldd       $0a,s     shift count
                    lbsr      AslEntry  shift left
                    puls      pc,u      return the shifted value

FoldShiftRight      ldd       $06,s     left operand
                    pshs      d         pass it
                    ldd       $0a,s     shift count
                    lbsr      AsrEntry  shift right
                    puls      pc,u      return the shifted value

FoldEqual           ldd       $06,s     left operand
                    cmpd      $08,s     compare with right operand
                    lbne      ConstOpZero not equal, return zero
                    ldd       #$0001    equal, result true
                    lbra      ConstOpReturn return one

FoldNotEqual        ldd       $06,s     left operand
                    cmpd      $08,s     compare with right operand
                    lbeq      ConstOpZero equal, return zero
                    ldd       #$0001    unequal, result true
                    lbra      ConstOpReturn return one

FoldGreater         ldd       $06,s     left operand
                    cmpd      $08,s     compare with right operand
                    lble      ConstOpZero not greater, return zero
                    ldd       #$0001    greater, result true
                    lbra      ConstOpReturn return one

FoldLess            ldd       $06,s     left operand
                    cmpd      $08,s     compare with right operand
                    lbge      ConstOpZero not less, return zero
                    ldd       #$0001    less, result true
                    lbra      ConstOpReturn return one

FoldGreaterEq       ldd       $06,s     left operand
                    cmpd      $08,s     compare with right operand
                    lblt      ConstOpZero less, return zero
                    ldd       #$0001    not less, result true
                    lbra      ConstOpReturn return one

FoldLessEq          ldd       $06,s     left operand
                    cmpd      $08,s     compare with right operand
                    lbgt      ConstOpZero greater, return zero
                    ldd       #$0001    not greater, result true
                    lbra      ConstOpReturn return one

FoldNegate          ldd       $06,s     operand
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish 16-bit negation
                    puls      pc,u      return the negation

FoldLogNot          ldd       $06,s     operand
                    lbne      ConstOpZero nonzero, return zero
                    ldd       #$0001    zero, result true
                    lbra      ConstOpReturn return one

FoldBitNot          ldd       $06,s     operand
                    coma                complement high byte
                    comb                complement low byte
                    puls      pc,u      return the complement

FoldLogAnd          ldd       $06,s     left operand
                    lbeq      ConstOpZero zero, result false
                    ldd       $08,s     right operand
                    lbeq      ConstOpZero zero, result false
                    ldd       #$0001    both nonzero, result true
                    lbra      ConstOpReturn return one

FoldLogOr           ldd       $06,s     left operand
                    bne       FoldLogOrTrue nonzero, result true
                    ldd       $08,s     right operand
                    lbeq      ConstOpZero both zero, result false
FoldLogOrTrue       ldd       #$0001    result true
                    lbra      ConstOpReturn return one

FoldUnsignedOp      leas      -4,s       allocate locals
                    ldd       $0C,s     left operand
                    std       $02,s     save as local
                    ldd       $0a,s     load left operand value
                    std       ,s        store as comparison left side
                    ldx       $08,s     load the relational operator code
                    bra       ConstCmpDispatch dispatch by relational operator

ConstCmpLE          ldd       ,s        load left operand
                    cmpd      $02,s     compare against right operand
                    bhi       ConstCmpFalse if left higher then result is false
                    ldd       #$0001    result is true
                    bra       ConstCmpDone return the folded value

ConstCmpLT          ldd       ,s        load left operand
                    cmpd      $02,s     compare against right operand
                    bcc       ConstCmpFalse if left greater or equal then false
                    ldd       #$0001    result is true
                    bra       ConstCmpDone return the folded value

ConstCmpGE          ldd       ,s        load left operand
                    cmpd      $02,s     compare against right operand
                    bcs       ConstCmpFalse if left less then false
                    ldd       #$0001    result is true
                    bra       ConstCmpDone return the folded value

ConstCmpGT          ldd       ,s        load left operand
                    cmpd      $02,s     compare against right operand
                    bls       ConstCmpFalse if left less or equal then false
                    ldd       #$0001    result is true
                    bra       ConstCmpDone return the folded value

ConstCmpFalse       clra                clear high byte of result
                    clrb                result is false
ConstCmpDone        leas      4,s        drop the operand scratch
                    puls      pc,u      return the folded value

ConstCmpDispatch    cmpx      #$0060    operator is less-or-equal
                    beq       ConstCmpLE handle less-or-equal
                    cmpx      #$0061    operator is less-than
                    beq       ConstCmpLT handle less-than
                    cmpx      #$0062    operator is greater-or-equal
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

FoldBinaryConst     cmpx      #$0050    operator code $0050
                    lbeq      FoldAdd   dispatch to its handler
                    cmpx      #$0051    operator code $0051
                    lbeq      FoldSub   dispatch to its handler
                    cmpx      #$0052    operator code $0052
                    lbeq      FoldMul   dispatch to its handler
                    cmpx      #$0053    operator code $0053
                    lbeq      FoldDiv   dispatch to its handler
                    cmpx      #$0054    operator code $0054
                    lbeq      FoldMod   dispatch to its handler
                    cmpx      #$0057    operator code $0057
                    lbeq      FoldAnd   dispatch to its handler
                    cmpx      #$0058    operator code $0058
                    lbeq      FoldOr    dispatch to its handler
                    cmpx      #$0059    operator code $0059
                    lbeq      FoldXor   dispatch to its handler
                    cmpx      #$0056    operator code $0056
                    lbeq      FoldShiftLeft dispatch to its handler
                    cmpx      #$0055    operator code $0055
                    lbeq      FoldShiftRight dispatch to its handler
                    cmpx      #$005A    operator code $005A
                    lbeq      FoldEqual dispatch to its handler
                    cmpx      #$005B    operator code $005B
                    lbeq      FoldNotEqual dispatch to its handler
                    cmpx      #$005F    operator code $005F
                    lbeq      FoldGreater dispatch to its handler
                    cmpx      #$005D    operator code $005D
                    lbeq      FoldLess  dispatch to its handler
                    cmpx      #$005E    operator code $005E
                    lbeq      FoldGreaterEq dispatch to its handler
                    cmpx      #$005C    operator code $005C
                    lbeq      FoldLessEq dispatch to its handler
                    cmpx      #$0043    operator code $0043
                    lbeq      FoldNegate dispatch to its handler
                    cmpx      #$0040    operator code $0040
                    lbeq      FoldLogNot dispatch to its handler
                    cmpx      #$0044    operator code $0044
                    lbeq      FoldBitNot dispatch to its handler
                    cmpx      #$0047    operator code $0047
                    lbeq      FoldLogAnd dispatch to its handler
                    cmpx      #$0048    operator code $0048
                    lbeq      FoldLogOr dispatch to its handler
                    cmpx      #$0060    relational operator $0060
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    cmpx      #$0061    relational operator $0061
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    cmpx      #$0062    relational operator $0062
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    cmpx      #$0063    relational operator $0063
                    lbeq      FoldUnsignedOp dispatch to relational setup
                    lbra      ConstOpError unknown operator error

                    puls      pc,u      return

ParseCast           pshs      u         save the caller frame pointer
                    ldd       #$FFA2    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    leas      -14,s      reserve local storage
                    ldd       GlbVar003F load the current token global
                    std       $04,s     save it in a local
                    ldd       GlbVar0063 load the current type global
                    std       $02,s     save it in a local
                    leax      ,s        point at local buffer
                    pshs      x         pass the pointer
                    leax      $0C,s     point at another local
                    pshs      x         pass the pointer
                    leax      $10,s     point at the argument slot
                    pshs      x         pass the pointer
                    lbsr      ParseDeclSpec parse the type specifier
                    leas      6,s        drop the three pointers
                    std       $08,s     save the parsed type
                    pshs      d         pass the type
                    leax      $0C,s     point at local
                    pshs      x         pass the pointer
                    leax      $0a,s     point at local
                    pshs      x         pass the pointer
                    lbsr      ParseTypeSpec parse the abstract declarator
                    leas      6,s        drop the arguments
                    std       $08,s     save the declarator result
                    leax      >GlbVar0047,y  point at the type table entry
                    pshs      x         pass the pointer
                    lbsr      EndScopeCheck build the cast type
                    leas      2,s        drop the argument
                    ldd       $06,s     load the returned status
                    beq       BuildCastNode no error so continue
                    leax      MsgNameInCast,pcr point at name-in-a-cast message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop the argument
BuildCastNode       ldd       $02,s     load the saved type
                    pshs      d         push as node argument
                    ldd       $06,s     load the declarator
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
                    ldd       #$0020    node kind is cast
                    pshs      d         push the node kind
                    bsr       NewExprNode allocate the cast node
                    leas      12,s       drop the six arguments
                    std       $06,s     save the node pointer
                    ldd       $08,s     load the parsed type
                    std       [$06,s]   store it into the node
                    ldd       $0C,s     load a field
                    pshs      d         push as argument
                    ldd       $0C,s     load a field
                    pshs      d         push as argument
                    ldd       $0a,s     load a field
                    pshs      d         push as argument
                    lbsr      SetNodeTypeSize finalize the cast node
                    leas      6,s        drop the arguments
                    ldd       $06,s     return the node pointer
                    leas      14,s       release the locals
                    puls      pc,u      return

NewExprNode         pshs      u         save the caller frame pointer
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldd       GlbNodeList load the node free list head
                    beq       NewNodeAlloc if empty allocate fresh
                    ldu       GlbNodeList take the head node
                    ldd       $0a,u     load its next-free link
                    std       GlbNodeList unlink from the free list
                    bra       NewNodeFill go fill the node

NewNodeAlloc        ldd       #$0016    node size is 22 bytes
                    pshs      d         pass the size
                    lbsr      AllocMem  allocate memory
                    leas      2,s        drop the size argument
                    tfr       d,u       node pointer into U
NewNodeFill         ldd       $04,s     load the first argument
                    std       $06,u     store the node kind
                    ldd       $06,s     load an argument
                    std       $0a,u     store the left child
                    ldd       $08,s     load an argument
                    std       $0C,u     store the right child
                    ldd       $0a,s     load an argument
                    std       $08,u     store the value field
                    ldd       $0C,s     load an argument
                    std       $0e,u     store a field
                    ldd       $0e,s     load an argument
                    std       $10,u     store a field
                    clra                clear high byte
                    clrb                clear low byte
                    std       $14,u     clear the last field
                    tfr       u,d       return the node pointer
                    puls      pc,u      return

ExprMissingErr      pshs      u         save the caller frame pointer
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    leax      MsgExpressionMissing,pcr point at expression-missing message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    lbra      EmitExprDone return

EmitExpr            pshs      u         save the caller frame pointer
                    ldd       #$FFB6    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       [$04,s]   load the expression node
                    ldx       $06,u     load its node type
                    bra       EmitExprDispatch dispatch on node type

EmitExprOpt         pshs      u         save the caller frame pointer
                    lbsr      OptExprTree optimize the expression tree
                    leas      2,s        drop the argument
                    std       [$04,s]   store the optimized node back
                    tfr       d,u       node pointer into U
                    leax      ,s        point at scratch
                    bra       EmitLeafRestore emit the node

EmitDeref           ldd       [$08,u]   load the indirect target
                    std       ,u        overwrite the node value
                    pshs      u         pass the node
                    lbsr      ChkUndeclared resolve the indirection
                    leas      2,s        drop the argument
                    ldu       $08,u     follow the pointer
                    bra       EmitLeaf  emit the node

EmitLeafRestore     leas      ,x        restore the stack pointer
EmitLeaf            ldd       $04,u     load a node field
                    pshs      d         push as argument
                    ldd       $02,u     load a node field
                    pshs      d         push as argument
                    ldd       ,u        load the node value
                    pshs      d         push as argument
                    lbsr      ComputeElemSize emit the operand
                    leas      6,s        drop the arguments
                    puls      pc,u      return

EmitExprField       pshs      u         save the caller frame pointer
                    ldd       #$000C    field offset
                    addd      ,s++      add to the node pointer
                    pshs      d         push the field pointer
                    bsr       EmitExpr  recurse into the subexpression
EmitExprDone        leas      2,s        drop the argument
                    puls      pc,u      return

EmitExprDispatch    cmpx      #$0034    node type indirection
                    beq       EmitDeref handle indirection
                    cmpx      #$0020    node type leaf
                    beq       EmitLeaf  emit as leaf
                    cmpx      #$0045    node type field
                    beq       EmitExprField handle field
                    cmpx      #$0046    node type field
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
OptExprTree         pshs      u         save the caller frame pointer
                    ldd       #$FFAE    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the expression node
                    leas      -12,s      reserve local storage
                    stu       -$02,s    save the node pointer
                    lbeq      OptExprDone null node so return
                    ldd       $0a,u     load the left child
                    pshs      d         pass it
                    bsr       OptExprTree optimize the left subtree
                    leas      2,s        drop the argument
                    std       $0a,u     store the optimized left child
                    ldd       $0C,u     load the right child
                    pshs      d         pass it
                    lbsr      OptExprTree optimize the right subtree
                    leas      2,s        drop the argument
                    std       $0C,u     store the optimized right child
                    pshs      u         pass the node
                    lbsr      GenSymbolExpr get the operator descriptor
                    leas      2,s        drop the argument
                    tfr       d,u       descriptor into U
                    pshs      u         pass the node
                    lbsr      IsFoldableTag try constant folding
                    std       ,s++      save the fold result
                    beq       OptRebalance not folded so keep optimizing
                    leax      $0C,s     adjust stack for the result
                    lbra      OptAdjustLocals return the folded node

OptRebalance        pshs      u         pass the descriptor
                    lbsr      SimplifyExpr simplify the expression
                    leas      2,s        drop the argument
                    tfr       d,u       result into U
                    ldd       $0a,u     load the left child
                    std       $0a,s     save it
                    ldd       $0C,u     load the right child
                    std       $08,s     save it
                    ldd       $06,u     load the operator
                    std       $04,s     save it
                    cmpd      #$0064    operator is index or deref
                    bne       OptCheckAddSub no so check associativity
                    ldx       $0a,s     load the left child node
                    ldd       $06,x     load its operator
                    cmpd      #$0036    is it a constant
                    bne       OptCheckAddSub no so check associativity
                    ldx       $0a,s     reload the left child
                    ldd       $08,x     load the child value
                    beq       OptSwapOperand zero so swap operands
                    ldx       $08,s     load the right child
                    ldd       $0a,x     load an operand
                    std       $02,s     save the operand
                    ldx       $08,s     reload the right child
                    ldd       $0C,x     load an operand
                    bra       OptEmitPair emit the operand pair

OptSwapOperand      ldx       $08,s     load the right child
                    ldd       $0C,x     load an operand
                    std       $02,s     save the operand
                    ldx       $08,s     reload the right child
                    ldd       $0a,x     load an operand
OptEmitPair         pshs      d         push the operand
                    lbsr      WalkTree  emit the operand
                    leas      2,s        drop the argument
                    ldd       $08,s     load a node
                    pshs      d         pass it
                    lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    ldd       $0a,s     load a node
                    pshs      d         pass it
                    lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    pshs      u         push the result node
                    bra       OptFreeTail finish

OptCheckAddSub      ldd       $04,s     load the operator
                    cmpd      #$0042    operator is add
                    bne       OptCheckSubAdd no so check subtract form
                    ldx       $0a,s     load the left child
                    ldd       $06,x     load its operator
                    cmpd      #$0041    is left a subtract
                    beq       OptCombineNested yes so combine them
OptCheckSubAdd      ldd       $04,s     load the operator
                    cmpd      #$0041    operator is subtract
                    bne       OptExprDone no so done
                    ldx       $0a,s     load the left child
                    ldd       $06,x     load its operator
                    cmpd      #$0042    is left an add
                    bne       OptExprDone no so done
OptCombineNested    ldx       $0a,s     load the left child
                    ldd       $0a,x     load the nested operand
                    std       $02,s     save it
                    ldd       ,u        load the node value
                    std       [$02,s]   patch the nested node
                    ldd       $02,u     load a node field
                    ldx       $02,s     load the saved node pointer
                    std       $02,x     copy the field across
                    pshs      u         pass the node
                    lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    ldd       $0a,s     load a node
                    pshs      d         pass it
OptFreeTail         lbsr      LinkNode  release the node
                    leas      2,s        drop the argument
                    ldu       $02,s     reload the result node
                    bra       OptExprDone done

OptAdjustLocals     leas      -$0C,x    restore reserved locals via X
OptExprDone         tfr       u,d       return the node pointer
                    leas      12,s       release the locals
                    puls      pc,u      return

SimplifyExpr        pshs      u         save the caller frame pointer
                    ldd       #$FFA8    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the expression node
                    leas      -14,s      reserve local storage
                    stu       -$02,s    save the node pointer
                    bne       SimplifyClassify non-null so proceed
                    clra                clear high byte
                    clrb                clear low byte
                    lbra      TeardownReturn return null result

SimplifyClassify    ldd       $0a,u     load the left child
                    std       $0C,s     save it
                    ldd       $0C,u     load the right child
                    std       $0a,s     save it
                    ldd       $06,u     load the operator
                    std       $06,s     save it
                    pshs      d         pass the operator
                    lbsr      IsOpToken classify the operator
                    std       ,s++      save the classification
                    bne       CheckConstOperands commutative so continue
                    ldd       $06,s     load the operator
                    cmpd      #$0047    operator is a comparison
                    beq       CheckConstOperands treat as commutative
                    ldd       $06,s     load the operator
                    cmpd      #$0048    operator is a comparison
                    lbne      LoadTagDispatch2 otherwise skip reordering
CheckConstOperands  ldx       $0C,s     load the left child
                    ldd       $06,x     load its operator
                    cmpd      #$0036    is left a constant
                    bne       LeftNotConst no so flag zero
                    ldd       #$0001    flag left is constant
                    bra       CheckRightConst save the flag

LeftNotConst        clra                clear high byte
                    clrb                clear low byte
CheckRightConst     std       $02,s     save the left-constant flag
                    pshs      d         push the flag
                    ldx       $0C,s     load the right child
                    ldd       $06,x     load its operator
                    cmpd      #$0036    is right a constant
                    bne       RightNotConst no so flag zero
                    ldd       #$0001    flag right is constant
                    bra       BothConstFlags save the flag

RightNotConst       clra                clear high byte
                    clrb                clear low byte
BothConstFlags      std       $02,s     save the right-constant flag
                    anda      ,s+       and with left flag high byte
                    andb      ,s+       and with left flag low byte
                    std       -$02,s    save the both-constant flag
                    beq       TestLeftConst not both constant so continue
                    leax      $0e,s     both constant path
                    lbra      BuildStoreFromX fold the two constants

TestLeftConst       ldd       $02,s     load the left-constant flag
                    beq       LoadTagAndDispatch left not constant so skip
                    ldx       $06,s     load the operator class
                    bra       CheckPtrClassTags reorder the operands

SwapOperands        ldd       $0C,s     load the right child
                    std       $08,s     stash it
                    ldd       $0a,s     load the left child
                    std       $0C,s     move it
                    std       $0a,u     update the node left child
                    ldd       $08,s     reload the stashed child
                    std       $0a,s     restore it
                    std       $0C,u     update the node right child
                    ldd       #$0001    mark swapped
                    std       ,s        set the swapped flag
                    bra       LoadTagAndDispatch continue

CheckPtrClassTags   cmpx      #$0050    compare node tag to P pointer
                    beq       SwapOperands branch when pointer-class tag
                    cmpx      #$0052    compare tag to R register
                    lbeq      SwapOperands branch when register tag
                    cmpx      #$0057    compare tag to W
                    lbeq      SwapOperands branch when W tag
                    cmpx      #$0058    compare tag to X
                    lbeq      SwapOperands branch when X tag
                    cmpx      #$0059    compare tag to Y
                    lbeq      SwapOperands branch when Y tag
LoadTagAndDispatch  ldx       $06,s     load the current node tag
                    lbra      DispatchByTagMain dispatch on the tag

FoldXYNode          ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU nothing to fold return node
                    ldx       $0a,s     load operand node pointer
                    ldd       $08,x     load its value field
                    lbeq      EmitOperandPair fold when operand value zero
                    lbra      ReturnNodeU otherwise return the node

FoldPtrNode         ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       $0a,s     load operand node pointer
                    ldd       $08,x     load its value field
                    lbeq      EmitOperandPair fold zero operand
                    ldx       $0C,s     load child node
                    ldx       $06,x     load child node tag
                    lbra      DispatchChildTag dispatch on child tag

FoldArrayRef        ldx       $0C,s     load child node
                    ldx       $0a,x     load grandchild pointer
                    ldd       $14,x     load its offset value
                    leax      $14,x     point at that field
                    pshs      x,d       save pointer and value
                    ldx       $0e,s     load target node
                    ldd       $08,x     load target value
                    addd      ,s++      add saved offset
                    std       [,s++]    store back through pointer
                    bra       EmitBinaryChildren emit the folded children

EmitPairFromX       leas      -$0e,x    restore frame from x
EmitBinaryChildren  ldd       $0C,s     load left child node
                    std       $08,s     stash as first operand
                    pshs      u         push result node
                    lbsr      LinkNode  free the child node
                    leas      2,s        drop argument
                    ldd       $0a,s     load second operand
                    pshs      d         push it
                    lbsr      LinkNode  free the operand node
                    leas      2,s        drop argument
                    ldu       $08,s     reload result node
                    lbra      ReturnNodeU return the node

FoldPtrConstAdd     ldx       $0C,s     load child node
                    ldx       $0C,x     load grandchild node
                    ldd       $06,x     load its tag
                    cmpd      #$0036    compare to constant 6
                    lbne      ReturnNodeU not constant return node
                    ldx       $0C,s     reload child node
                    ldx       $0C,x     grandchild node
                    ldd       $08,x     load constant value
                    leax      $08,x     point at value field
                    pshs      x,d       save pointer and value
                    ldx       $0e,s     target node
                    ldd       $08,x     its value
                    addd      ,s++      add constant offset
                    lbra      StoreThroughPtr store through pointer and fold

DispatchChildTag    cmpx      #$0041    child tag A array
                    lbeq      FoldArrayRef fold array reference
                    cmpx      #$0050    child tag P pointer
                    beq       FoldPtrConstAdd fold pointer add
                    lbra      ReturnNodeU otherwise return node

FoldNegate2         ldd       ,s        test left operand flag
                    beq       MakeConstNode handle no-operand case
                    ldx       $0a,s     operand node
                    ldd       $08,x     load its value
                    nega                negate value high byte
                    negb                negate value low byte
                    sbca      #$00      finish two's complement
                    ldx       $0a,s     reload operand node
                    std       $08,x     store negated value
                    ldd       #$0050    tag P pointer
                    std       $06,u     set result tag to pointer
                    pshs      u         push result node
                    lbsr      SimplifyExpr re-simplify the node
                    leas      2,s        drop argument
                    lbra      TeardownReturn return folded node

MakeConstNode       ldd       $02,s     test right operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       $0C,s     load child node
                    ldd       $08,x     load its value
                    lbne      ReturnNodeU nonzero return node
                    ldd       #$0043    tag C constant
                    std       $06,u     set result tag
                    ldd       $0a,s     load operand
                    std       $0a,u     store into result
                    clra                zero high
                    clrb                zero low
                    std       $0C,u     clear child pointer
                    ldd       $0C,s     load child node
                    lbra      EmitOperandJoin emit and return

FoldWNode           ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       $0a,s     operand node
                    ldd       $08,x     its value
                    beq       BuildIndirectNode fold zero to indirect
                    lbra      ReturnNodeU otherwise return node

FoldRNode           ldd       ,s        test left operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       $0a,s     operand node
                    ldx       $08,x     load its value as pointer
                    bra       ClassifyRValue classify the rvalue

BuildIndirectNode   leax      $0e,s     point at frame node
                    lbra      BuildSixFromX build indirect node

FoldRegConst        ldx       $0C,s     load child node
                    ldd       $06,x     load its tag
                    cmpd      #$0052    compare to R register
                    lbne      ReturnNodeU not register return node
                    ldx       $0C,s     reload child node
                    ldx       $0C,x     grandchild node
                    ldd       $06,x     its tag
                    cmpd      #$0036    compare to constant 6
                    lbne      ReturnNodeU not constant return node
                    ldx       $0C,s     reload child node
                    ldx       $0C,x     grandchild node
                    ldd       $08,x     load constant value
                    leax      $08,x     point at value field
                    pshs      x,d       save pointer and value
                    ldx       $0e,s     target node
                    ldd       $08,x     its value
                    lbsr      MulEntry  combine the two values
StoreThroughPtr     std       [,s++]    store result through pointer
                    bra       EmitOperandPair emit operand pair

ClassifyRValue      stx       -$02,s    stash rvalue pointer
                    beq       BuildIndirectNode zero build indirect node
                    cmpx      #$0001    value equals one
                    beq       EmitOperandPair fold to operand pair
                    bra       FoldRegConst else try register-const fold

FoldSNode           ldd       ,s        test left operand flag
                    beq       CheckRightZero no operand case
                    ldx       $0a,s     operand node
                    ldd       $08,x     its value
                    cmpd      #$0001    value equals one
                    bne       CheckRightZero not one other case
EmitOperandPair     leax      $0e,s     point at frame node
                    lbra      EmitPairFromX emit paired children

CheckRightZero      ldd       $02,s     test right operand flag
                    lbeq      ReturnNodeU return node if none
                    ldx       $0C,s     child node
                    ldd       $08,x     its value
                    lbne      ReturnNodeU nonzero return node
                    bra       InitSixNode build constant node

BuildSixFromX       leas      -$0e,x    restore frame from x
InitSixNode         ldd       #$0036    tag 6 integer constant
                    std       $06,u     set result tag
                    clra                zero high
                    clrb                zero low
ClearNodeFields     std       $08,u     clear value field
                    clra                zero high
                    clrb                zero low
                    std       $0C,u     clear child pointer
                    std       $0a,u     clear operand field
                    ldd       $0C,s     load child node
                    pshs      d         push it
                    lbsr      LinkNode  free the child node
                    leas      2,s        drop argument
                    ldd       $0a,s     load operand
EmitOperandJoin     pshs      d         push it
                    lbsr      LinkNode  free the operand node
DropAndReturn       leas      2,s        drop argument
                    lbra      ReturnNodeU return the node

DispatchByTagMain   cmpx      #$0058    tag X
                    lbeq      FoldXYNode fold X node
                    cmpx      #$0059    tag Y
                    lbeq      FoldXYNode fold Y node
                    cmpx      #$0050    tag P
                    lbeq      FoldPtrNode fold P node
                    cmpx      #$0051    tag Q
                    lbeq      FoldNegate2 fold negate
                    cmpx      #$0057    tag W
                    lbeq      FoldWNode fold W node
                    cmpx      #$0052    tag R
                    lbeq      FoldRNode fold R node
                    cmpx      #$0053    tag S
                    lbeq      FoldSNode fold S node
                    lbra      ReturnNodeU default return node

LoadTagDispatch2    ldx       $06,s     load node tag
                    lbra      DispatchAddrTag dispatch on tag

FoldAddrNode        ldx       $0C,s     load child node
                    ldd       $06,x     its tag
                    cmpd      #$0036    compare to constant 6
                    bne       FoldConvertJ not constant try next
                    bra       InitStoreNode build store node

BuildStoreFromX     leas      -$0e,x    restore frame from x
InitStoreNode       ldd       #$0036    tag 6 constant
                    std       $06,u     set result tag
                    clra                zero high
                    clrb                zero low
                    std       $12,u     clear extra field
                    ldx       $0a,s     operand node
                    ldd       $08,x     its value
                    pshs      d         push value
                    ldx       $0e,s     target node
                    ldd       $08,x     its value
                    pshs      d         push value
                    ldd       $0a,s     load operand
                    pshs      d         push it
                    lbsr      FoldBinaryOp compute folded constant
                    leas      6,s        drop three arguments
                    lbra      ClearNodeFields clear fields and return

FoldConvertJ        ldx       $0C,s     child node
                    ldd       $06,x     its tag
                    cmpd      #$004A    compare to J
                    bne       FoldConvertK not J try K
                    leas      -2,s       make local slot
                    ldx       $0e,s     target node
                    ldd       $08,x     its value
                    std       ,s        save it
                    bne       SelectConvertOp nonzero use existing node
                    ldd       #$0004    request four bytes
                    pshs      d         push size
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop argument
                    std       ,s        save new node
SelectConvertOp     ldx       $08,s     load conversion source tag
                    bra       DispatchConvertTag dispatch conversion

ConvertToC          ldx       ,s        load node
                    pshs      x         push it
                    ldx       $02,s     load target
                    lbsr      LongNeg   convert to C form
                    bra       FinishConvert finish conversion

ConvertToD          ldx       ,s        load node
                    pshs      x         push it
                    ldx       $02,s     load target
                    lbsr      LongNot   convert to D form
FinishConvert       lbsr      StoreLong finalize conversion
                    bra       StoreConverted store converted value

DispatchConvertTag  cmpx      #$0043    tag C
                    beq       ConvertToC convert to C
                    cmpx      #$0044    tag D
                    beq       ConvertToD convert to D
StoreConverted      ldd       ,s        load converted node
                    ldx       $0e,s     target node
                    std       $08,x     store value into target
                    bra       EmitAndReturn emit and return

FoldConvertK        ldx       $0C,s     child node
                    ldd       $06,x     its tag
                    cmpd      #$004B    compare to K
                    bne       ReturnNodeU not K return node
                    leas      -2,s       make local slot
                    ldx       $0e,s     target node
                    ldd       $08,x     its value
                    std       ,s        save it
                    beq       EmitAndReturn zero just emit
                    ldx       ,s        load node
                    pshs      x         push it
                    ldx       $02,s     load target
                    lbsr      NegateNumWork convert the node
                    lbsr      SwapNumWork finalize conversion
EmitAndReturn       pshs      u         push result node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop argument
                    ldu       $0e,s     reload target node
                    lbra      DropAndReturn drop and return

DispatchAddrTag     cmpx      #$0040    tag @
                    lbeq      FoldAddrNode fold address node
                    cmpx      #$0044    tag D
                    lbeq      FoldAddrNode fold address node
                    cmpx      #$0043    tag C
                    lbeq      FoldAddrNode fold address node
ReturnNodeU         tfr       u,d       return node pointer in d
TeardownReturn      leas      14,s       release local frame
                    puls      pc,u      restore u and return

IsFoldableTag       pshs      u         save u
                    ldd       #$FFC0    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load node argument
                    stu       -$02,s    stash node pointer
                    beq       ReturnFalse null node return zero
                    ldx       $06,u     load node tag
                    bra       MatchFoldTag test against foldable tags

ReturnTrue          ldd       #$0001    result true
                    puls      pc,u      restore u and return

MatchFoldTag        cmpx      #$0076    tag v
                    beq       ReturnTrue foldable return true
                    cmpx      #$006F    tag o
                    lbeq      ReturnTrue return true
                    cmpx      #$0036    tag 6
                    lbeq      ReturnTrue return true
                    cmpx      #$004A    tag J
                    lbeq      ReturnTrue return true
                    cmpx      #$004B    tag K
                    lbeq      ReturnTrue return true
                    cmpx      #$0034    tag 4
                    lbeq      ReturnTrue return true
                    cmpx      #$0037    tag 7
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
                    ldx       $18,s     load argument node
                    ldu       $0a,x     load its list pointer
                    ldx       $18,s     reload argument node
                    ldd       $0C,x     load a field
                    std       $12,s     save it locally
                    ldd       #$0002    constant two
                    std       $0a,s     init local
                    std       $08,s     init local
                    clra                zero high
                    clrb                zero low
                    std       $06,s     clear local
                    ldd       #$0001    constant one
                    std       $0C,s     init local counter
                    ldx       $18,s     argument node
                    ldd       $06,x     load its tag
                    std       $0e,s     save tag locally
                    tfr       d,x       tag into x
                    lbra      DispatchOp enter processing loop

CheckSymDefined     ldx       $18,s     argument node
                    ldd       $08,x     load its value field
                    std       $10,s     save pointer locally
                    ldx       $10,s     reload pointer
                    ldd       $08,x     load referenced value
                    cmpd      #_start   compare against module base
                    bne       GenSymbolRef defined generate ref
                    leax      MsgTypedefNotVar,pcr point at message string
                    pshs      x         push string pointer
                    ldd       $1a,s     load line context
                    pshs      d         push it
                    lbsr      PrintErrSpan report undefined symbol
                    leas      4,s        drop arguments
                    ldd       $18,s     argument node
                    pshs      d         push it
                    lbsr      SetErrSym recover from error
                    leas      2,s        drop argument
                    lbra      WriteNodeType continue processing

GenSymbolRef        ldd       [$10,s]   load symbol attribute word
                    std       $0C,s     save it locally
                    ldx       $10,s     reload pointer
                    ldd       $04,x     load type field
                    std       $06,s     save it locally
                    ldd       $0C,s     reload attributes
                    clra                keep low byte
                    andb      #$0f      mask storage class nibble
                    cmpd      #$000A    compare to class ten
                    bne       GenStorageClass not that class skip
                    leas      -2,s       make local slot
                    ldx       $12,s     load list pointer
                    ldd       $02,x     load offset field
                    std       ,s        save it
                    ldd       $0e,s     load current tag
                    andb      #$F0      mask high nibble
                    addd      [,s]      add referenced offset
                    std       [$12,s]   store back through list
                    std       $0e,s     update local tag
                    ldx       ,s        reload pointer
                    ldd       $02,x     load offset again
                    pshs      d         push it
                    ldd       $0a,s     load count
                    pshs      d         push it
                    ldd       $16,s     load context
                    pshs      d         push it
                    lbsr      SetNodeTypeSize emit field access code
                    leas      6,s        drop three arguments
                    leas      2,s        drop local slot
GenStorageClass     ldx       $10,s     reload pointer
                    ldd       $02,x     load offset field
                    std       $0a,s     save as operand
                    ldd       $0C,s     reload attributes
                    clra                keep low byte
                    andb      #$30      mask storage-class bits
                    cmpd      #$0020    compare to static class
                    beq       GenStaticExtern handle static storage
                    ldd       $0C,s     reload attributes
                    clra                keep low byte
                    andb      #$30      mask storage-class bits
                    cmpd      #$0030    compare to extern class
                    lbne      PlainTypeCase neither other storage
GenStaticExtern     ldu       $18,s     argument node
                    ldd       $0a,s     load operand offset
                    std       $02,u     store into node
                    ldx       $18,s     reload node
                    ldd       $10,x     load a field
                    pshs      d         push it
                    ldx       $1a,s     load outer node
                    ldd       $0e,x     load its field
                    pshs      d         push it
                    clra                zero high
                    clrb                zero low
                    pshs      d         push zero
                    clra                zero high
                    clrb                zero low
                    pshs      d         push zero
                    pshs      u         push node
                    ldd       #$0041    tag A address
                    pshs      d         push tag
                    lbsr      NewExprNode build an address node
                    leas      12,s       drop six arguments
                    std       $18,s     save the new node
                    ldd       $0C,s     reload attributes
                    clra                keep low byte
                    andb      #$30      mask storage-class bits
                    cmpd      #$0020    compare to static class
                    bne       ReloadWorkType not static skip
                    ldd       $06,s     load type field
                    pshs      d         push it
                    lbsr      GetNodeType get type size
                    leas      2,s        drop argument
                    std       $06,s     save size back
                    ldd       $0C,s     reload attributes
                    pshs      d         push it
                    lbsr      RemovePtrLevel emit storage directive
                    leas      2,s        drop argument
                    bra       StoreTypeInNode join the type-store path

ReloadWorkType      ldd       $0C,s     reload the working type
StoreTypeInNode     std       ,u        store type into the node
                    pshs      d         pass the type argument
                    lbsr      AddPtrLevel add one level of indirection to type
                    leas      2,s        drop the argument
                    std       $0C,s     save the pointer type
                    ldd       #$0001    mark result as true
                    std       $12,u     store the flag in the node
                    bra       SetResultTrue go set result true

PlainTypeCase       ldx       $10,s     get the operand node
                    ldd       $08,x     load its element type
                    std       $04,s     save the element type
                    tfr       d,x       copy for operator test
                    bra       CheckPtrOp test the operator kind

StorePtrElemType    ldd       $04,s     reload the element type
                    ldx       $18,s     get the result node
                    std       $06,x     store element type in node
                    clra                zero the value
                    clrb                zero the value
                    ldx       $18,s     result node again
                    std       $08,x     clear the node size field
                    bra       SetResultTrue result true

CheckPtrOp          cmpx      #$0076    is it the address operator
                    beq       StorePtrElemType yes handle pointer element
                    cmpx      #$006F    is it the deref operator
                    lbeq      StorePtrElemType yes handle pointer element
SetResultTrue       ldd       #$0001    result true
                    bra       StoreResultDone store the result

SetResultFalse      clra                result false
                    clrb                result false
StoreResultDone     std       $08,s     store the result flag
                    lbra      WriteNodeType return

CaseType8           ldd       #$0008    builtin type code 8
                    std       $0C,s     set working type
                    ldd       #$0001    result true
                    std       $08,s     store result flag
                    ldd       #$0004    size four
                    lbra      SetNodeSizeExit finish the node

CaseType6           ldd       #$0006    builtin type code 6
                    std       $0C,s     set working type
                    ldd       #$0001    result true
                    std       $08,s     store result flag
                    ldd       #$0008    size eight
                    lbra      SetNodeSizeExit finish the node

CaseType18          ldd       #$0012    builtin type code 18
                    std       $0C,s     set working type
                    ldd       #$0001    result true
                    lbra      SetNodeSizeExit finish the node

CastOp              pshs      u         pass the node
                    lbsr      ChkUndeclared evaluate the cast operand
                    leas      2,s        drop the argument
                    ldd       [$18,s]   load the operand type
                    std       $0C,s     save the working type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0030    is it a function type
                    beq       CannotCastErr cannot cast a function
                    ldd       $0C,s     reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0020    is it an array type
                    bne       CastCheckPtr no continue the cast
CannotCastErr       leax      MsgCannotCast,pcr cannot cast message
                    pshs      x         push message pointer
                    ldd       $1a,s     source line number
                    pshs      d         push line number
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       $0C,s     reload the type
                    pshs      d         push type argument
                    lbsr      AddPtrLevel add indirection to type
                    leas      2,s        drop the argument
                    std       $0C,s     save the adjusted type
CastCheckPtr        ldd       $0C,s     reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0010    is it a pointer type
                    bne       CastConvert no default conversion
                    ldd       #$0001    conversion flag one
                    pshs      d         push flag
                    pshs      u         push node
                    lbsr      InsertConvNode convert the operand type
                    leas      4,s        drop the arguments
                    bra       CastDone  finish the cast

CastConvert         ldd       $0C,s     reload the type
                    pshs      d         push type
                    pshs      u         push node
                    lbsr      InsertConvNode convert the operand type
                    leas      4,s        drop the arguments
                    std       $0C,s     save the converted type
CastDone            ldx       $18,s     get the result node
                    ldd       $04,x     copy element type field
                    std       $06,s     save it
                    ldx       $18,s     result node again
                    ldd       $02,x     copy node field
                    std       $0a,s     save it
                    ldd       $18,s     node pointer
                    pshs      d         push node
                    lbsr      LinkNode  free the operand node
                    leas      2,s        drop the argument
                    stu       $18,s     keep the returned node
                    lbra      WriteNodeType return

AddrOfOp            ldd       #$0001    addressable-check flag one
                    pshs      d         push flag
                    pshs      u         push node
                    lbsr      ClassifyNode check operand is addressable
                    leas      4,s        drop the arguments
                    ldd       $06,u     get the operator code
                    cmpd      #$0076    is it address-of
                    beq       CantTakeAddrErr yes go error check
                    ldd       $06,u     reload operator code
                    cmpd      #$006F    is it deref
                    bne       AddrOfSetNode neither continue
CantTakeAddrErr     leax      MsgNoAddress,pcr can't take address message
                    pshs      x         push message pointer
                    ldd       $1a,s     line number
                    pshs      d         push line number
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    pshs      u         push node
                    lbsr      SetErrSym release the node
                    leas      2,s        drop the argument
AddrOfSetNode       ldd       $12,u     node flag
                    std       $08,s     save it
                    ldd       $02,u     node field
                    std       $0a,s     save it
                    ldd       ,u        node type
                    pshs      d         push type
                    lbsr      AddPtrLevel add indirection to take address
                    leas      2,s        drop the argument
                    std       $0C,s     save the pointer type
                    ldd       $04,u     element type
                    std       $06,s     save it
                    lbra      WriteNodeType return

DerefOp             ldd       $04,u     element type
                    std       $06,s     save it
                    ldd       ,u        node type
                    std       $0C,s     save working type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0010    is it a pointer type
                    bne       PtrRequiredErr no report error
                    ldd       $0C,s     reload the type
                    pshs      d         push type
                    lbsr      RemovePtrLevel remove one indirection
                    leas      2,s        drop the argument
                    std       $0C,s     save the dereferenced type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0020    is result an array type
                    bne       DerefSetNode no finish
                    ldd       $0C,s     reload the type
                    pshs      d         push type
                    lbsr      RemovePtrLevel deref again for array element
                    std       ,s        replace the argument
                    lbsr      AddPtrLevel re-add indirection
                    leas      2,s        drop the argument
                    std       $0C,s     save the adjusted type
                    ldd       $18,s     node pointer
                    pshs      d         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    stu       $18,s     keep the returned node
                    bra       DerefSetNode finish

PtrRequiredErr      leax      MsgPtrRequired,pcr pointer required message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    pshs      u         push node
                    lbsr      SetErrSym release the node
                    leas      2,s        drop the argument
                    ldd       #$0011    default int type
                    std       ,u        store into node
                    ldd       #$0001    flag one
                    std       $0C,s     save it
                    clra                zero
                    clrb                zero
                    std       $06,s     clear element type
DerefSetNode        ldd       $12,u     node flag
                    std       $08,s     save it
                    ldd       $02,u     node field
SetNodeSizeExit     std       $0a,s     store node size field
                    lbra      WriteNodeType return

BinaryOpOperandA    leax      ,s        address of local
                    pshs      x         push it
                    leax      $0e,s     address of another local
                    pshs      x         push it
                    ldd       $16,s     operand argument
                    pshs      d         push it
                    lbsr      ProcStructRef split the operands
                    leas      6,s        drop the arguments
                    std       $0a,s     save result
                    ldx       $12,s     operand node
                    ldd       $04,x     element type
                    std       $06,s     save it
                    ldd       #$0001    addressable-check flag one
                    pshs      d         push flag
                    pshs      u         push node
                    lbsr      ClassifyNode check operand is addressable
                    leas      4,s        drop the arguments
                    ldx       $12,s     operand node
                    ldd       $08,x     its size field
                    bne       OperandHasType nonzero handle type
                    ldd       ,s        local flag
                    bne       OperandHasType nonzero handle type
                    ldd       $12,s     node pointer
                    pshs      d         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    ldd       $18,s     result node
                    pshs      d         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    stu       $18,s     keep the returned node
                    ldx       $18,s     result node
                    ldd       $12,x     its flag
                    std       $08,s     save it
                    lbra      OperandExit return

OperandHasType      ldd       $12,u     node flag
                    std       $08,s     save it
                    ldd       $06,u     operator code
                    cmpd      #$0042    is it a call node
                    bne       MakeConvertNode no build convert node
                    ldd       $0a,u     node pointer field
                    std       $10,s     save it
                    pshs      u         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    ldu       $10,s     restore saved node
                    tfr       u,d       copy for storing
                    ldx       $18,s     result node
                    std       $0a,x     store field
                    bra       OperandDone finish operand

MakeConvertNode     ldd       ,u        node type
                    std       $04,s     save it
                    ldd       $10,u     node field
                    pshs      d         push it
                    ldd       $0e,u     node field
                    pshs      d         push it
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    pshs      u         push operand node
                    ldd       #$0041    convert node opcode
                    pshs      d         push opcode
                    lbsr      NewExprNode allocate a conversion node
                    leas      12,s       drop the arguments
                    ldx       $18,s     result node
                    std       $0a,x     store the new node
                    tfr       d,u       new node pointer
                    ldd       $04,s     saved type
                    pshs      d         push type
                    lbsr      AddPtrLevel add indirection to type
                    leas      2,s        drop the argument
                    std       ,u        store type in new node
OperandDone         ldd       $08,s     node flag
                    std       $12,u     store into node
                    leax      $14,s     restore frame pointer
                    lbra      RestoreFrame build the node

OperandExit         lbra      WriteNodeType return

BinaryOpOperandB    leax      ,s        address of local
                    pshs      x         push it
                    leax      $0e,s     address of another local
                    pshs      x         push it
                    ldd       $16,s     operand argument
                    pshs      d         push it
                    lbsr      ProcStructRef split the operands
                    leas      6,s        drop the arguments
                    std       $0a,s     save result
                    ldx       $12,s     operand node
                    ldd       $04,x     element type
                    std       $06,s     save it
                    ldd       ,u        node type
                    std       $04,s     save it
                    cmpd      #$0001    is it plain int
                    beq       OperandBType yes accept
                    ldd       $04,s     reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0010    is it a pointer type
                    bne       NotPtrType no set false
                    ldd       #$0001    true
                    bra       CheckPtrOrInt go test

NotPtrType          clra                false
                    clrb                false
CheckPtrOrInt       bne       OperandBType pointer or integer accepted
                    leax      MsgPtrOrIntReq,pcr pointer or integer required message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       #$0036    default type
                    std       $06,u     store into node
                    clra                zero
                    clrb                zero
                    std       $08,u     clear node field
                    clra                zero
                    clrb                zero
                    std       $12,u     clear node flag
OperandBType        ldd       $12,u     node flag
                    std       $08,s     save it
                    bra       BuildBinaryNode build binary node

RestoreFrame        leas      -$14,x    restore the stack frame
BuildBinaryNode     ldd       #$0050    binary node opcode
                    ldx       $18,s     result node
                    std       $06,x     store operator code
                    ldd       $18,s     node pointer
                    pshs      d         push node
                    lbsr      SimplifyExpr link operand into node
                    leas      2,s        drop the argument
                    std       $18,s     keep the returned node
                    ldd       ,s        local flag
                    bne       BinaryNodeExit skip the node build
                    ldd       $0C,s     working type
                    pshs      d         push type
                    lbsr      AddPtrLevel add indirection to type
                    leas      2,s        drop the argument
                    std       [$18,s]   store type in node
                    ldd       $08,s     node flag
                    ldx       $18,s     result node
                    std       $12,x     store into node
                    ldd       $0a,s     node field
                    ldx       $18,s     result node
                    std       $02,x     store into node
                    ldx       $18,s     result node
                    ldd       $10,x     node field
                    pshs      d         push it
                    ldx       $1a,s     caller frame
                    ldd       $0e,x     node field
                    pshs      d         push it
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    clra                zero
                    clrb                zero
                    pshs      d         push zero argument
                    ldd       $20,s     operand node
                    pshs      d         push it
                    ldd       #$0042    call node opcode
                    pshs      d         push opcode
                    lbsr      NewExprNode allocate the node
                    leas      12,s       drop the arguments
                    std       $18,s     keep the new node
BinaryNodeExit      lbra      WriteNodeType return

CallOp              ldd       ,u        node type
                    std       $0C,s     save it
                    ldd       $06,u     operator code
                    cmpd      #$0041    is it a convert node
                    bne       CheckFuncType no check function type
                    ldd       $0C,s     reload the type
                    pshs      d         push type
                    lbsr      RemovePtrLevel remove one indirection
                    leas      2,s        drop the argument
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0030    is it a function type
                    bne       CheckFuncType no continue
                    ldd       $0a,u     node field
                    ldx       $18,s     result node
                    std       $0a,x     store into node
                    std       $10,s     save node field
                    pshs      u         push node
                    lbsr      LinkNode  free the node
                    leas      2,s        drop the argument
                    ldd       [$10,s]   load node type
DerefTypeCont       pshs      d         push type
                    lbsr      RemovePtrLevel remove one indirection
                    leas      2,s        drop the argument
                    lbra      CallSetNode finish the call node

CheckFuncType       ldd       $0C,s     reload the type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0030    is it a function type
                    bne       ImplicitFuncDecl no maybe implicit
                    ldd       $0C,s     plain type
                    bra       DerefTypeCont deref the function type

ImplicitFuncDecl    ldd       $0C,s     reload the type
                    bne       NotFunctionErr nonzero not a function
                    ldd       $08,u     node field
                    std       $10,s     save it
                    ldd       #$0031    identifier node opcode
                    std       [$10,s]   store node type
                    ldd       #$0002    field value
                    ldx       $10,s     saved node
                    std       $02,x     store into node
                    clra                zero
                    clrb                zero
                    ldx       $10,s     saved node
                    std       $04,x     clear field
                    ldd       #$000E    field value
                    ldx       $10,s     saved node
                    std       $08,x     store into node
                    clra                zero
                    clrb                zero
                    ldx       $10,s     saved node
                    std       $0C,x     clear field
                    ldd       #$0006    count six
                    pshs      d         push count
                    pshs      u         push node
                    ldd       $14,s     operand argument
                    pshs      d         push it
                    lbsr      CopyBlock copy the node bytes
                    leas      6,s        drop the arguments
                    ldd       #$0001    result true
                    bra       CallSetNode finish the call node

NotFunctionErr      leax      MsgNotFunction,pcr not a function message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       $0C,s     reload the type
                    clra                clear high byte
                    andb      #$0f      isolate base type bits
CallSetNode         std       $0C,s     save the working type
                    ldd       $04,u     element type
                    std       $06,s     save it
                    ldd       $02,u     node field
                    std       $0a,s     save it
ProcessCallArgs     pshs      u         pass the node
                    lbsr      ChkUndeclared evaluate the operand
                    leas      2,s        drop the argument
                    pshs      u         push node pointer argument
                    lbsr      ChkNotStruct call operand helper
                    leas      2,s        drop argument
                    ldx       ,u        load result operand pointer
                    bra       CheckOperandKind go check operand kind

SetType1Emit        ldd       #$0001    select type code one
                    bra       EmitTypedNode emit typed node

SetType6Emit        ldd       #$0006    select type code six
EmitTypedNode       pshs      d         push type code
                    pshs      u         push node pointer
                    lbsr      InsertConvNode emit conversion
                    leas      4,s        drop arguments
                    bra       OpDoneJoin join common tail

CheckOperandKind    cmpx      #$0002    is operand kind two
                    beq       SetType1Emit yes handle as type one
                    cmpx      #$0005    is operand kind five
                    beq       SetType6Emit yes handle as type six
OpDoneJoin          lbra      WriteNodeType back to dispatch loop

CopyNodeFields      ldx       $12,s     load left operand pointer
                    ldd       $02,x     fetch its type field
                    std       $0a,s     save into frame
                    ldd       [$12,s]   dereference operand type
                    std       $0C,s     save current type
                    ldx       $12,s     reload operand pointer
                    ldd       $04,x     fetch its size field
                    std       $06,s     save size
                    lbra      WriteNodeType back to dispatch loop

EvalUnaryPtr        ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    beq       ResultOneFinish yes skip evaluation
                    pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
ResultOneFinish     ldd       #$0001    result type is one
                    lbra      StoreOpType finish node

EvalUnaryFinish     pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    lbra      StoreOpType finish node

EvalCheckType6      pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    std       $0C,s     save resulting type
                    cmpd      #$0006    is it type six
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
                    ldd       $02,u     fetch node base type
                    std       $0a,s     save into frame
                    ldd       ,u        load node type word
                    std       $0C,s     save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    beq       DefaultSizeOne plain scalar default size one
                    ldd       $04,u     load element size
                    pshs      d         push size
                    ldd       $02,u     load base type
                    pshs      d         push type
                    ldd       $10,s     load other operand type
                    pshs      d         push it
                    lbsr      RemovePtrLevel compute result type
                    std       ,s        store result on stack
                    lbsr      ComputeElemSize scale operands by size
                    leas      6,s        drop arguments
                    bra       StoreNodeSize store computed size

DefaultSizeOne      ldd       #$0001    default size one
StoreNodeSize       ldx       $18,s     load result node pointer
                    std       $08,x     store size into node
                    ldd       $12,u     load node link field
                    std       $08,s     save it
                    ldd       $06,u     load node operator code
                    cmpd      #$0042    is it operator hex42
                    lbne      TailJoinD no back to dispatch
                    ldd       $08,s     reload saved value
                    addd      #$0001    increment it
                    lbra      StoreOffsetJoin store size and continue

EvalDerefPtr        ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    beq       CheckDerefClass yes skip evaluation
                    pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
CheckDerefClass     ldd       [$12,s]   dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    lbeq      JoinExit  yes back to dispatch
                    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    bra       PopAndJoin pop and continue

EvalRhsCheck6       ldd       $12,s     load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
                    leas      4,s        drop arguments
                    std       $0C,s     save resulting type
                    cmpd      #$0006    is it type six
                    bne       TailJoinA no back to dispatch
                    leax      $14,s     point at frame block
                    bra       RestoreThenErr restore and report error

TailJoinA           lbra      WriteNodeType back to dispatch loop

EvalBothCheck6      pshs      u         push node pointer
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    std       $0C,s     save resulting type
                    cmpd      #$0006    is it type six
                    beq       ReportTypeErr yes report error
                    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    cmpd      #$0006    is it type six
                    bne       EmitAssignOne no emit assignment
                    bra       ReportTypeErr report error

RestoreThenErr      leas      -$14,x    restore stack frame
ReportTypeErr       leax      MsgBothIntegral,pcr point at error message
                    pshs      x         push message pointer
                    ldd       $1a,s     load context value
                    pshs      d         push it
                    lbsr      PrintErrSpan report compile error
                    leas      4,s        drop arguments
                    ldd       $18,s     reload node pointer
                    pshs      d         push it
EmitNode25E6        lbsr      SetErrSym emit node
PopAndJoin          leas      2,s        drop argument
JoinExit            lbra      WriteNodeType back to dispatch loop

EmitAssignOne       ldd       #$0001    result type one
                    pshs      d         push type
                    ldd       $14,s     load operand pointer
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    lbra      PopFourJoin pop and continue

CheckPtrArith       ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       EvalRhsCheck7 not pointer evaluate
                    ldd       [$12,s]   dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    beq       AdjustPtrSize4 both pointers adjust size
EvalRhsCheck7       ldd       $12,s     load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
                    leas      4,s        drop arguments
                    cmpd      #$0007    is result type seven
                    bne       TailJoinB no back to dispatch
AdjustPtrSize4      ldd       $0e,s     load size field
                    addd      #$0004    bump by four
                    ldx       $18,s     load result node pointer
                    std       $06,x     store adjusted size
TailJoinB           lbra      WriteNodeType back to dispatch loop

ComparePtrEqual     ldd       ,u        load node type word
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       EvalRhsDefault not pointer evaluate
                    ldd       [$12,s]   dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       ClearPtrFlag mismatch clear flag
                    ldd       #$0001    both pointers set flag
                    bra       TestPtrFlag test the flag

ClearPtrFlag        clra                clear flag value
                    clrb                zero low byte
TestPtrFlag         bne       TailJoinC flag set back to dispatch
                    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    ldd       #$0001    result type one
                    pshs      d         push type
                    ldd       $14,s     load operand pointer
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    bra       PopFourJoin pop and continue

EvalRhsDefault      ldd       $12,s     load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
PopFourJoin         leas      4,s        drop arguments
TailJoinC           lbra      WriteNodeType back to dispatch loop

SwapPtrOperands     ldd       [$12,s]   dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       LoadNodeType not pointer keep order
                    leas      -2,s       make scratch slot
                    stu       ,s        save node pointer
                    ldu       $14,s     load other operand
                    ldd       ,s        reload saved node
                    std       $14,s     swap operands
                    leas      2,s        drop scratch slot
                    ldx       $18,s     load result node pointer
                    stu       $0a,x     store swapped operand
LoadNodeType        ldd       $02,u     fetch node base type
                    std       $0a,s     save into frame
                    ldd       ,u        load node type word
                    std       $0C,s     save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       EvalRhsAddOffset not pointer evaluate
                    ldd       $04,u     load element size
                    std       $06,s     save size
                    leax      $14,s     point at frame block
                    lbra      FixFrameEmit fix frame and emit

EvalRhsAddOffset    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    pshs      u         push node pointer
                    lbsr      UsualArithConv evaluate right operand
                    leas      4,s        drop arguments
                    std       $0C,s     save resulting type
                    ldd       $12,u     load node link field
                    ldx       $12,s     load operand pointer
                    addd      $12,x     add operand offsets
StoreOffsetJoin     std       $08,s     save combined offset
TailJoinD           lbra      WriteNodeType back to dispatch loop

PtrCompareOp        ldd       $12,u     load node link field
                    ldx       $12,s     load operand pointer
                    addd      $12,x     add operand offsets
                    std       $08,s     save combined offset
                    ldd       ,u        load node type word
                    std       $0C,s     save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    lbne      ProcBinType not pointer finish node
                    ldd       $02,u     fetch base type
                    std       $0a,s     save into frame
                    ldd       $04,u     load element size
                    std       $06,s     save size
                    ldd       [$12,s]   dereference operand type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    lbne      EmitPtrScale not pointer emit scale
                    ldd       $08,s     load combined offset
                    ldx       $18,s     load result node pointer
                    std       $12,x     store into node
                    ldd       $0C,s     load node type
                    cmpd      [$12,s]   compare with operand type
                    bne       TypeMismatchErr differ report error
                    ldd       $0a,s     load base type
                    ldx       $12,s     load operand pointer
                    cmpd      $02,x     compare base types
                    beq       ConstFoldCompare match constant fold
TypeMismatchErr     leax      MsgPtrMismatch,pcr point at error message
                    pshs      x         push message pointer
                    ldd       $1a,s     load context value
                    pshs      d         push it
                    lbsr      PrintErrSpan report compile error
                    leas      4,s        drop arguments
                    lbra      SetResultTwo set result and finish

ConstFoldCompare    ldd       $0C,s     load node type
                    pshs      d         push type
                    lbsr      RemovePtrLevel compute result type
                    leas      2,s        drop argument
                    std       $0C,s     save adjusted type
                    ldd       $06,s     load size
                    pshs      d         push size
                    ldd       $0C,s     load type
                    pshs      d         push type
                    ldd       $10,s     load operand
                    pshs      d         push it
                    lbsr      ComputeElemSize scale operands
                    leas      6,s        drop arguments
                    std       $0a,s     save scaled result
                    cmpd      #$0001    is result one
                    lbeq      SetResultTwo yes just finish
                    ldd       #$0002    result type two
                    std       $08,s     save it
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       $0e,s     load operand value
                    pshs      d         push it
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       #$0036    opcode hex36
                    pshs      d         push opcode
                    lbsr      NewExprNode emit intermediate instruction
                    leas      12,s       drop arguments
                    std       $10,s     save emitted node
                    ldx       $18,s     load result node pointer
                    ldd       $10,x     load its field
                    pshs      d         push it
                    ldx       $1a,s     load context pointer
                    ldd       $0e,x     load field
                    pshs      d         push it
                    clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       $16,s     load value
                    pshs      d         push it
                    ldd       $20,s     load value
                    pshs      d         push it
                    ldd       #$0053    opcode hex53
                    pshs      d         push opcode
                    lbsr      NewExprNode emit intermediate instruction
                    leas      12,s       drop arguments
                    std       $18,s     save emitted node
SetResultTwo        ldd       #$0002    result type two
                    std       $0a,s     save it
                    clra                clear high byte
                    clrb                zero low byte
                    std       $06,s     clear size
                    ldd       #$0001    set result flag one
                    lbra      StoreOpType finish node

FixFrameEmit        leas      -$14,x    restore stack frame
EmitPtrScale        ldd       $12,s     load operand pointer
                    pshs      d         push it
                    lbsr      CoerceOperand evaluate subexpression
                    leas      2,s        drop argument
                    ldd       [$12,s]   dereference operand type
                    pshs      d         push it
                    lbsr      IsIntegral test type compatibility
                    std       ,s++      save result and drop
                    bne       EmitScaledOp nonzero skip conversion
                    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    lbsr      ErrMustBeIntegral dereference operand
                    leas      2,s        drop argument
                    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    lbsr      SetErrSym emit node
                    leas      2,s        drop argument
EmitScaledOp        ldd       #$0001    result type one
                    pshs      d         push type
                    ldd       $14,s     load operand pointer
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    leas      4,s        drop arguments
                    ldd       $12,s     load operand pointer
                    pshs      d         push it
                    ldd       $08,s     load offset
                    pshs      d         push it
                    ldd       $10,s     load operand
                    pshs      d         push it
                    ldd       $10,s     load operand
                    pshs      d         push it
                    lbsr      ScalePointer emit scaled operation
                    leas      8,s        drop arguments
                    ldx       $18,s     load result node pointer
                    std       $0C,x     store into node
                    ldd       $12,u     load node link field
                    ldx       $12,s     load operand pointer
                    addd      $12,x     add operand offsets
                    std       $08,s     save combined offset
                    lbra      WriteNodeType back to dispatch loop

ProcessAssignOp     clra                clear high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    pshs      u         push node pointer
                    lbsr      ClassifyNode evaluate both operands
                    leas      4,s        drop arguments
                    ldd       $12,s     load left operand
                    pshs      d         push it
                    lbsr      ChkUndeclared process operand
                    leas      2,s        drop argument
                    ldd       $12,s     load left operand
                    pshs      d         push it
                    lbsr      ChkNotStruct load operand value
                    leas      2,s        drop argument
                    std       $02,s     save right type
                    ldd       ,u        load node type word
                    std       $0C,s     save current type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       CheckRightPtr not pointer check right
                    ldd       $02,s     load right type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    beq       CheckRightPtr both pointers continue
                    ldd       $02,s     load right type
                    pshs      d         push it
                    lbsr      IsIntegral test type compatibility
                    std       ,s++      save result and drop
                    lbeq      ConvOpErr compatible handle specially
CheckRightPtr       ldd       $02,s     load right type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    bne       EmitAssignStore not pointer emit store
                    ldd       $0C,s     load left type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it pointer class
                    beq       EmitAssignStore both pointers emit store
                    ldd       $0C,s     load left type
                    pshs      d         push it
                    lbsr      IsIntegral test type compatibility
                    std       ,s++      save result and drop
                    lbeq      ConvOpErr compatible handle specially
EmitAssignStore     ldd       $0C,s     load left type
                    pshs      d         push it
                    ldd       $14,s     load operand
                    pshs      d         push it
                    lbsr      InsertConvNode emit conversion
                    leas      4,s        pop the two arguments
                    leax      $14,s     point past the local frame
                    lbra      RestoreFrameCopy continue into node-type copy

ProcConvOp          leas      -$14,x    allocate local frame for conversion op
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    pshs      u         push node pointer
                    lbsr      ClassifyNode call node helper
                    leas      4,s        drop the arguments
                    ldd       $12,s     load node pointer
                    pshs      d         pass as argument
                    lbsr      CoerceOperand coerce the operand type
                    leas      2,s        drop argument
                    ldd       $12,s     reload node pointer
                    pshs      d         pass as argument
                    lbsr      ChkNotStruct call node helper
                    leas      2,s        drop argument
                    std       $02,s     save returned value
                    ldd       ,u        load node operator/type
                    std       $0C,s     save as result type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #$0010    test for pointer class
                    bne       DispatchConvOp not pointer, dispatch other op
                    ldx       $0e,s     load operator code
                    bra       CheckAddrOps check specific pointer ops

MakeIntConv         ldd       #$0001    integer type
                    pshs      d         push target type
                    ldd       $14,s     load node pointer
                    pshs      d         push as argument
                    lbsr      InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    leax      $14,s     point past frame
                    bra       ConvFixFrame continue setting result type

ConvOpErr           leax      $14,s     restore frame pointer
                    lbra      ReportOpErr report operator error

CheckAddrOps        cmpx      #$00A1    indirection operator?
                    beq       MakeIntConv yes, convert to int
                    cmpx      #$00A0    address-of operator?
                    lbeq      MakeIntConv yes, convert to int
                    bra       ConvOpErr otherwise operator error

DispatchConvOp      ldx       $0e,s     load operator code
                    lbra      CheckIncrOps dispatch by operator

ConvByType          ldd       $0C,s     load result type
                    cmpd      #$0005    test for float type
                    bne       ConvKeepType no, keep existing type
                    ldd       #$0006    promote to double type
                    bra       EmitConvNode emit the conversion

ConvKeepType        ldd       $0C,s     keep existing type
EmitConvNode        pshs      d         push target type
                    ldd       $14,s     load node pointer
                    pshs      d         push as argument
                    lbsr      InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    bra       SetConvResult set result type

ConvFixFrame        leas      -$14,x    restore local frame
SetConvResult       ldd       $0e,s     load operator code
                    addd      #$FFB0    offset into type table
                    ldx       $18,s     load result node pointer
                    std       $06,x     store node subtype
                    ldd       $18,s     load result node pointer
                    pshs      d         push as argument
                    lbsr      GenSymbolExpr call node helper
                    leas      2,s        drop argument
                    std       $18,s     save updated node pointer
                    ldd       $0C,s     load result type
                    cmpd      #$0002    test for long type
                    bne       CheckSubtypeSame no, skip pointer handling
                    ldd       $0a,u     load node pointer field
                    ldx       $18,s     load result node
                    std       $0a,x     copy pointer field across
                    pshs      u         push node pointer
                    lbsr      LinkNode  call node helper
                    leas      2,s        drop argument
                    ldx       $18,s     load result node
                    ldu       $0a,x     reload node pointer field
                    ldd       #$0001    integer type
                    std       $0C,s     set result type
CheckSubtypeSame    ldd       $0e,s     load operator code
                    addd      #$FFB0    offset into type table
                    ldx       $18,s     load result node
                    cmpd      $06,x     compare with stored subtype
                    bne       CopyNodeType differ, copy node type
                    ldd       $0e,s     load operator code
                    ldx       $18,s     load result node
                    std       $06,x     store operator as subtype
                    bra       CopyNodeType copy node type

CheckIncrOps        cmpx      #$00A6    post-increment operator?
                    beq       SetConvResult yes, set result type
                    cmpx      #$00A5    pre-increment operator?
                    lbeq      SetConvResult yes, set result type
                    lbra      ConvByType otherwise convert by type

RestoreFrameCopy    leas      -$14,x    restore local frame
CopyNodeType        ldd       $02,u     load node type field
                    std       $0a,s     save result subfield
                    ldd       $12,u     load node size field
                    ldx       $12,s     load other operand
                    addd      $12,x     add operand sizes
                    std       $08,s     save combined size
                    ldd       $04,u     load node field
                    lbra      SetResultField set result field

ReportOpErr         leas      -$14,x    restore local frame
                    leax      MsgTypeMismatch,pcr point to error message
                    pshs      x         push message pointer
                    ldd       $1a,s     load source location
                    pshs      d         push as argument
                    lbsr      PrintErrSpan report the error
                    lbra      OpErrDone finish with error

ProcAssignOp        ldd       ,u        load node operator
                    std       $0C,s     save as result type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #$0010    test for pointer class
                    bne       DerefLvalType not pointer, other handling
                    ldd       $02,u     load node type field
                    std       $0a,s     save result subfield
                    ldd       $12,u     load node size field
                    std       $08,s     save result size
                    ldd       $02,u     reload node type field
                    std       $06,s     save result field
                    ldd       [$12,s]   load type through operand
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #$0010    test for pointer class
                    bne       CheckLvalCase not pointer, check lvalue
                    ldd       $0C,s     load result type
                    cmpd      [$12,s]   compare with operand type
                    bne       TypeMismatchErr2 differ, type mismatch
                    ldd       $02,u     load node type field
                    ldx       $12,s     load operand pointer
                    cmpd      $02,x     compare target types
                    beq       AssignOk  match, assignment ok
TypeMismatchErr2    leax      MsgPtrMismatch2,pcr point to mismatch message
                    pshs      x         push message pointer
                    ldd       $1a,s     load source location
                    pshs      d         push as argument
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    lbra      WriteNodeType write node type

AssignOk            clra                clear high byte
                    clrb                clear low byte
                    std       $06,s     clear result field
                    lbra      WriteNodeType write node type

CheckLvalCase       ldd       $12,s     load operand pointer
                    pshs      d         push as argument
DoLvalCheck         lbsr      ForceStorClass force storage-class node
                    leas      2,s        drop argument
                    lbra      WriteNodeType write node type

DerefLvalType       ldd       [$12,s]   load type through operand
                    std       $0C,s     save as result type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #$0010    test for pointer class
                    bne       ProcBinType not pointer, binary op
                    ldx       $12,s     load operand pointer
                    ldd       $02,x     load type field
                    std       $0a,s     save result subfield
                    ldx       $12,s     reload operand pointer
                    ldd       $12,x     load size field
                    std       $08,s     save result size
                    ldx       $12,s     reload operand pointer
                    ldd       $04,x     load node field
                    std       $06,s     save result field
                    pshs      u         push node pointer
                    bra       DoLvalCheck force storage-class node

ProcBinType         ldd       $12,s     load operand pointer
                    pshs      d         push as argument
                    pshs      u         push node pointer
                    lbsr      UsualArithConv call binary-type helper
                    leas      4,s        drop the arguments
StoreOpType         std       $0C,s     save as result type
                    lbra      WriteNodeType write node type

CopyLvalType        ldd       [$12,s]   load type through operand
                    std       $0C,s     save as result type
                    ldx       $12,s     load operand pointer
                    ldd       $02,x     load type field
                    std       $0a,s     save result subfield
                    ldx       $12,s     reload operand pointer
                    ldd       $04,x     load node field
SetResultField      std       $06,s     save result field
                    lbra      WriteNodeType write node type

ProcDefaultOp       ldd       $0e,s     load operator code
                    cmpd      #$00A0    test conversion-op range
                    blt       BadOpErr  below range, bad operator
                    leax      $14,s     point past frame
                    lbra      ProcConvOp process conversion operator

BadOpErr            leax      MsgTypeCheck,pcr point to error message
                    pshs      x         push message pointer
                    ldd       $1a,s     load source location
                    pshs      d         push as argument
                    lbsr      ReportFmtErr report the error
OpErrDone           leas      4,s        drop the arguments
                    lbra      WriteNodeType write node type

DispatchOp          cmpx      #$0034    operator code $34?
                    lbeq      CheckSymDefined dispatch to its handler
                    cmpx      #$0036    operator code $36?
                    lbeq      SetResultFalse dispatch to its handler
                    cmpx      #$004A    operator code $4A?
                    lbeq      CaseType8 dispatch to its handler
                    cmpx      #$004B    operator code $4B?
                    lbeq      CaseType6 dispatch to its handler
                    cmpx      #$0037    operator code $37?
                    lbeq      CaseType18 dispatch to its handler
                    cmpx      #$0020    operator code $20?
                    lbeq      CastOp    dispatch to its handler
                    cmpx      #$0041    operator code $41?
                    lbeq      AddrOfOp  dispatch to its handler
                    cmpx      #$0042    operator code $42?
                    lbeq      DerefOp   dispatch to its handler
                    cmpx      #$0045    operator code $45?
                    lbeq      BinaryOpOperandA dispatch to its handler
                    cmpx      #$0046    operator code $46?
                    lbeq      BinaryOpOperandB dispatch to its handler
                    cmpx      #$0065    operator code $65?
                    lbeq      CallOp    dispatch to its handler
                    cmpx      #$000B    operator code $0B?
                    lbeq      ProcessCallArgs dispatch to its handler
                    cmpx      #$0030    operator code $30?
                    lbeq      CopyNodeFields dispatch to its handler
                    cmpx      #$0040    operator code $40?
                    lbeq      EvalUnaryPtr dispatch to its handler
                    cmpx      #$0043    operator code $43?
                    lbeq      EvalUnaryFinish dispatch to its handler
                    cmpx      #$0044    operator code $44?
                    lbeq      EvalCheckType6 dispatch to its handler
                    cmpx      #$003C    relational operator $3C?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #$003E    relational operator $3E?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #$003D    relational operator $3D?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #$003F    relational operator $3F?
                    lbeq      ProcessArrayIndex dispatch to comparison handler
                    cmpx      #$0047    operator code $47?
                    lbeq      EvalDerefPtr dispatch to its handler
                    cmpx      #$0048    operator code $48?
                    lbeq      EvalDerefPtr dispatch to its handler
                    cmpx      #$0053    operator code $53?
                    lbeq      ProcBinType dispatch to binary handler
                    cmpx      #$0052    operator code $52?
                    lbeq      ProcBinType dispatch to binary handler
                    cmpx      #$0057    operator code $57?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #$0058    operator code $58?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #$0059    operator code $59?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #$0054    operator code $54?
                    lbeq      EvalRhsCheck6 dispatch to its handler
                    cmpx      #$0056    operator code $56?
                    lbeq      EvalBothCheck6 dispatch to its handler
                    cmpx      #$0055    operator code $55?
                    lbeq      EvalBothCheck6 dispatch to its handler
                    cmpx      #$005D    operator code $5D?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #$005F    operator code $5F?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #$005C    operator code $5C?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #$005E    operator code $5E?
                    lbeq      CheckPtrArith dispatch to its handler
                    cmpx      #$005A    operator code $5A?
                    lbeq      ComparePtrEqual dispatch to its handler
                    cmpx      #$005B    operator code $5B?
                    lbeq      ComparePtrEqual dispatch to its handler
                    cmpx      #$0050    operator code $50?
                    lbeq      SwapPtrOperands dispatch to its handler
                    cmpx      #$0051    operator code $51?
                    lbeq      PtrCompareOp dispatch to its handler
                    cmpx      #$0078    operator code $78?
                    lbeq      ProcessAssignOp dispatch to its handler
                    cmpx      #$002F    operator code $2F?
                    lbeq      ProcAssignOp dispatch to assignment handler
                    cmpx      #$0064    operator code $64?
                    lbeq      CopyLvalType dispatch to its handler
                    lbra      ProcDefaultOp otherwise default operator handling

WriteNodeType       ldd       $0C,s     load computed type
                    std       [$18,s]   store into result node
                    ldd       $0a,s     load result subfield
                    ldx       $18,s     load result node
                    std       $02,x     store node subfield
                    ldd       $08,s     load result size
                    ldx       $18,s     load result node
                    std       $12,x     store node size
                    ldd       $06,s     load result field
                    ldx       $18,s     load result node
                    std       $04,x     store node field
                    ldd       $18,s     return result node pointer
                    leas      20,s       release the local frame
                    puls      pc,u      restore u and return

ForceStorClass      pshs      u         save caller u
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load node argument
                    ldd       $06,u     load node subtype
                    cmpd      #$0036    test for storage-class op
                    bne       StorClassErr no, report and force
                    ldd       $08,u     load node field
                    beq       StorClassDone zero, already valid
StorClassErr        leax      MsgShouldBeNull,pcr point to error message
                    pshs      x         push message pointer
                    pshs      u         push node pointer
                    lbsr      PrintErrSpan report the error
                    leas      4,s        drop the arguments
                    ldd       #$0036    storage-class op code
                    std       $06,u     force node subtype
                    clra                clear high byte
                    clrb                clear low byte
                    std       $08,u     clear node field
StorClassDone       puls      pc,u      restore u and return

CoerceOperand       pshs      u         save caller u
                    ldd       #$FFB6    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load node argument
                    leas      -2,s       allocate local
                    pshs      u         push node pointer
                    lbsr      ChkUndeclared call node helper
                    leas      2,s        drop argument
                    ldd       ,u        load node type
                    std       ,s        save locally
                    tfr       d,x       into x for dispatch
                    bra       CoerceDispatch dispatch by type

CoerceToInt         ldd       #$0001    integer type
                    bra       StoreCoerceType store coercion type

CoerceToDouble      ldd       #$0006    double type
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
                    ldd       #$0001    integer type
                    std       ,s        save target type
                    bra       CoerceDone store result and return

CoerceDispatch      cmpx      #$0002    long type?
                    beq       CoerceToInt coerce to int
                    cmpx      #$0005    float type?
                    beq       CoerceToDouble coerce to double
                    cmpx      #$0006    double type?
                    beq       CoerceDone already usable
                    cmpx      #$0008    pointer type?
                    beq       CoerceDone already usable
                    cmpx      #$0001    int type?
                    beq       CoerceDone already usable
                    cmpx      #$0007    type $07?
                    beq       CoerceDone already usable
                    bra       CoerceErr otherwise coercion error

CoerceDone          ldd       ,s        load target type
                    std       ,u        store into node
                    leas      2,s        release local
                    puls      pc,u      restore u and return

InsertConvNode      pshs      u         save caller u
                    ldd       #$FFAC    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load node argument
                    leas      -4,s       allocate locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear local
                    ldx       ,u        load node type
                    lbra      OpKindSwitch dispatch by node type

ConvLoadType        ldx       $0a,s     load operand type
                    bra       ConvDispatch dispatch conversion

ConvOp85            ldd       #$0085    conversion op $85
                    bra       StoreConvOp store conversion op

ConvViaInt          ldd       #$0001    integer type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    bsr       InsertConvNode recurse to insert conversion
                    leas      4,s        drop the arguments
                    ldd       #$0083    conversion op $83
StoreConvOp         std       ,s        save conversion op
                    lbra      FinalizeOrError build conversion node

ConvDouble          ldd       #$0001    integer type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    lbsr      InsertConvNode insert conversion node
                    leas      4,s        drop the arguments
                    ldd       $0a,s     load operand type
                    pshs      d         push target type
                    pshs      u         push node pointer
                    lbsr      InsertConvNode insert second conversion
                    leas      4,s        drop the arguments
                    lbra      FinalizeOrError build conversion node

ConvDispatch        cmpx      #$0001    int type?
                    beq       ConvOp85  use conversion op $85
                    cmpx      #$0007    type $07?
                    lbeq      ConvOp85  use conversion op $85
                    cmpx      #$0008    pointer type?
                    beq       ConvViaInt convert via int
                    cmpx      #$0006    double type?
                    beq       ConvDouble double conversion
                    cmpx      #$0005    float type?
                    lbeq      ConvDouble double conversion
                    lbra      FinalizeOrError otherwise build conversion node

CheckPtrClass2      ldd       ,u        load node type
                    clra                clear high byte
                    andb      #$30      isolate type-class bits
                    cmpd      #$0010    test for pointer class
                    lbne      FinalizeOrError not pointer, build node
ConvPtrCase         ldx       $0a,s     load operand type
                    lbra      Op1TypeSwitch dispatch pointer conversion

ConvConstNode       ldd       $06,u     load node subtype
                    cmpd      #$0036    storage-class op?
                    bne       ErrMsg83  no, other handling
                    ldd       #$0004    allocation size four
                    pshs      d         push as argument
                    lbsr      AllocMem  allocate memory
                    leas      2,s        drop argument
                    std       $02,s     save the allocation
                    ldd       $08,u     load node field
                    ldx       $02,s     load result node pointer
                    std       $02,x     store computed value into node
                    bge       SignZero  non-negative needs zero sign
                    ldd       #$FFFF    negative sign extension word
                    bra       StoreSign go store the sign

SignZero            clra                positive sign high byte
                    clrb                positive sign low byte
StoreSign           std       [$02,s]   write sign word through pointer
                    ldd       $02,s     reload node pointer
                    std       $08,u     set node operand field
                    bra       MakeAddrNode build address node

AddrNodeMerge       leas      -$04,x    normalize stack after merge
MakeAddrNode        ldd       #$004A    address-of node tag
                    std       $06,u     set node opcode
                    ldd       #$0004    pointer size four bytes
SetAddrSize         std       $02,u     set node size
                    lbra      FinalizeOrError finalize node

ErrMsg83            ldd       #$0083    type-error message 0x83
                    bra       SetMsgOp1 store message and finalize

Op1CharInt          ldd       #$0001    result type int
                    std       $0a,s     save operand type
                    lbra      FinalizeOrError finalize node

Op1CoerceErr        ldd       #$0006    coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    ldd       #$008D    type-error message 0x8D
                    bra       SetMsgOp1 store message and finalize

Op1MakeDeref        ldd       $06,u     load node opcode
                    cmpd      #$0036    is it an lvalue node
                    bne       ErrMsg8E  no, report error
                    ldd       #$0008    allocate eight bytes
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop argument
                    std       $02,s     save new node pointer
                    ldx       $02,s     reload new node pointer
                    pshs      x         push new node
                    ldd       $08,u     operand pointer
                    lbsr      IntToNum  build subtree
                    lbsr      SwapNumWork finish subtree
                    bra       FinishDeref attach and tag node

DerefMerge          leas      -$04,x    normalize stack after merge
FinishDeref         ldd       $02,s     new node pointer
                    std       $08,u     set operand field
                    ldd       #$004B    dereference node tag
                    std       $06,u     set node opcode
                    ldd       #$0008    size eight bytes
                    bra       SetAddrSize set size and finalize

ErrMsg8E            ldd       #$008E    type-error message 0x8E
SetMsgOp1           std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op1TypeSwitch       cmpx      #$0008    operand type long
                    lbeq      ConvConstNode handle long operand
                    cmpx      #$0002    operand type char
                    lbeq      Op1CharInt handle char operand
                    cmpx      #$0005    operand type struct
                    beq       Op1CoerceErr handle struct operand
                    cmpx      #$0006    operand type float
                    beq       Op1MakeDeref handle float operand
                    lbra      FinalizeOrError nothing to do, finalize

Op7Entry            ldx       $0a,s     reload operand type
                    bra       Op7TypeSwitch dispatch on type

ErrMsg86            ldd       #$0086    type-error message 0x86
                    bra       SetMsgOp7 store message and finalize

Op7CoerceErr        ldd       #$0006    coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    ldd       #$008D    type-error message 0x8D
                    bra       SetMsgOp7 store message and finalize

ErrMsg92            ldd       #$0092    type-error message 0x92
SetMsgOp7           std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op7CharInt          ldd       #$0001    result type int
                    std       $0a,s     save operand type
                    lbra      FinalizeOrError finalize node

Op7TypeSwitch       cmpx      #$0008    operand type long
                    beq       ErrMsg86  error for this operator
                    cmpx      #$0005    operand type struct
                    beq       Op7CoerceErr coerce then error
                    cmpx      #$0006    operand type float
                    beq       ErrMsg92  error 0x92
                    cmpx      #$0002    operand type char
                    beq       Op7CharInt result int
                    lbra      FinalizeOrError finalize node

Op8Entry            ldx       $0a,s     reload operand type
                    lbra      Op8TypeSwitch dispatch on type

ChkAddressable      ldd       $0a,s     load operand type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0010    is it addressable
                    lbne      FinalizeOrError no, finalize
MakeIntNode         ldd       $06,u     load node opcode
                    cmpd      #$004A    is it an address node
                    bne       ErrMsg84  no, error 0x84
                    ldd       $08,u     collapse to operand
                    std       $02,s     save operand pointer
                    ldx       $02,s     reload operand pointer
                    ldd       $02,x     load pointed node
                    std       $08,u     set operand field
                    bra       SetIntNode tag as lvalue node

IntNodeMerge        leas      -$04,x    normalize stack after merge
SetIntNode          ldd       #$0036    lvalue node tag
                    std       $06,u     set node opcode
                    ldd       #$0002    size two bytes
                    std       $02,u     set node size
                    lbra      FinalizeOrError finalize node

ErrMsg84            ldd       #$0084    type-error message 0x84
                    bra       SetMsgOp8 store message and finalize

Op8CoerceErr        ldd       #$0006    coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    ldd       #$008D    type-error message 0x8D
                    bra       SetMsgOp8 store message and finalize

CollapseAddrNode    ldd       $06,u     load node opcode
                    cmpd      #$004A    is it an address node
                    bne       ErrMsg90  no, error 0x90
                    ldd       #$0008    allocate eight bytes
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop argument
                    std       $02,s     save new node pointer
                    ldx       $02,s     reload new node pointer
                    pshs      x         push new node
                    ldx       $08,u     operand pointer
                    lbsr      ClearNumWork build subtree
                    lbsr      SwapNumWork finish subtree
                    leax      $04,s     point past pushed args
                    lbra      DerefMerge attach as deref node

ErrMsg90            ldd       #$0090    type-error message 0x90
SetMsgOp8           std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op8TypeSwitch       cmpx      #$0001    operand type int
                    lbeq      MakeIntNode make lvalue node
                    cmpx      #$0007    operand type pointer
                    lbeq      MakeIntNode make lvalue node
                    cmpx      #$0002    operand type char
                    lbeq      MakeIntNode make lvalue node
                    cmpx      #$0005    operand type struct
                    beq       Op8CoerceErr coerce then error
                    cmpx      #$0006    operand type float
                    beq       CollapseAddrNode collapse address node
                    lbra      ChkAddressable default class check

Op5Entry            ldx       $0a,s     reload operand type
                    bra       Op5TypeSwitch dispatch on type

Op5CoerceBoth       ldd       #$0006    coerce target type float
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce first operand
                    leas      4,s        drop arguments
                    ldd       $0a,s     operand type again
                    pshs      d         push target type
                    pshs      u         push node argument
                    lbsr      InsertConvNode coerce second operand
                    leas      4,s        drop arguments
                    lbra      FinalizeOrError finalize node

ErrMsg8C            ldd       #$008C    type-error message 0x8C
                    std       ,s        store message code
                    lbra      FinalizeOrError finalize with error

Op5TypeSwitch       cmpx      #$0008    operand type long
                    beq       Op5CoerceBoth coerce operands
                    cmpx      #$0007    operand type pointer
                    lbeq      Op5CoerceBoth coerce operands
                    cmpx      #$0002    operand type char
                    lbeq      Op5CoerceBoth coerce operands
                    cmpx      #$0001    operand type int
                    lbeq      Op5CoerceBoth coerce operands
                    cmpx      #$0006    operand type float
                    beq       ErrMsg8C  error 0x8C
                    lbra      FinalizeOrError finalize node

Op6Entry            ldx       $0a,s     reload operand type
                    bra       Op6TypeSwitch dispatch on type

Op6DerefTag         ldd       $06,u     load node opcode
                    cmpd      #$004B    is it a deref node
                    bne       ErrMsg8F  no, error 0x8F
                    ldx       $08,u     operand pointer
                    lbsr      GetNumValue simplify subtree
                    std       $08,u     set operand field
                    leax      $04,s     point past args
                    lbra      IntNodeMerge make lvalue node

ErrMsg8F            ldd       #$008F    type-error message 0x8F
                    bra       SetMsgOp6 store message and finalize

Op6AddrTag          ldd       $06,u     load node opcode
                    cmpd      #$004B    is it a deref node
                    bne       ErrMsg91  no, error 0x91
                    ldx       $08,u     operand pointer
                    pshs      x         push operand pointer
                    ldx       $08,u     operand pointer again
                    lbsr      NormalizeNum build subtree
                    lbsr      StoreLong finish subtree
                    leax      $04,s     point past args
                    lbra      AddrNodeMerge build address node

ErrMsg91            ldd       #$0091    type-error message 0x91
                    bra       SetMsgOp6 store message and finalize

ErrMsg8D            ldd       #$008D    type-error message 0x8D
SetMsgOp6           std       ,s        store message code
                    bra       FinalizeOrError finalize with error

Op6TypeSwitch       cmpx      #$0002    operand type char
                    beq       Op6DerefTag handle deref node
                    cmpx      #$0007    operand type pointer
                    lbeq      Op6DerefTag handle deref node
                    cmpx      #$0001    operand type int
                    lbeq      Op6DerefTag handle deref node
                    cmpx      #$0008    operand type long
                    beq       Op6AddrTag handle address node
                    cmpx      #$0005    operand type struct
                    beq       ErrMsg8D  error 0x8D
                    bra       FinalizeOrError finalize node

OpKindSwitch        cmpx      #$0002    operator kind 2
                    lbeq      ConvLoadType handle operator two
                    cmpx      #$0001    operator kind 1
                    lbeq      ConvPtrCase handle operator one
                    cmpx      #$0007    operator kind 7
                    lbeq      Op7Entry  handle operator seven
                    cmpx      #$0008    operator kind 8
                    lbeq      Op8Entry  handle operator eight
                    cmpx      #$0005    operator kind 5
                    lbeq      Op5Entry  handle operator five
                    cmpx      #$0006    operator kind 6
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
                    std       $02,s     save node pointer
                    pshs      d         push message argument
                    pshs      u         push node argument
                    lbsr      CopyStruct report the error message
                    leas      4,s        drop arguments
                    ldd       ,s        message code
                    std       $06,u     store into node
                    ldd       $02,s     node pointer
                    std       $0a,u     link error node
                    clra                clear field high
                    clrb                clear field low
                    std       $0C,u     clear node field
ReturnType          ldd       $0a,s     load result operand type
                    lbra      StoreResultRet store result and return

UsualArithConv      pshs      u         save frame pointer
                    ldd       #$FFB4    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load node argument
                    leas      -4,s       reserve locals
                    pshs      u         push operand node
                    lbsr      CoerceOperand get base type of operand
                    leas      2,s        drop argument
                    std       $02,s     save first operand type
                    ldd       $0a,s     second operand node
                    pshs      d         push operand node
                    lbsr      CoerceOperand get base type of operand
                    leas      2,s        drop argument
                    std       ,s        save second operand type
                    ldd       $02,s     first operand type
                    cmpd      #$0006    is it float
                    bne       ChkRhsFloat check other operand
                    ldd       #$0006    common type float
                    bra       CoerceLhs coerce and finish

ChkRhsFloat         ldd       ,s        second operand type
                    cmpd      #$0006    is it float
                    bne       ChkLhsLong check for long
                    ldd       #$0006    common type float
                    bra       CoerceRhs coerce and finish

ChkLhsLong          ldd       $02,s     first operand type
                    cmpd      #$0008    is it long
                    bne       ChkRhsLong check other operand
                    ldd       #$0008    common type long
CoerceLhs           pshs      d         push target type
                    ldd       $0C,s     operand node
                    pshs      d         push operand node
                    bra       ApplyCoerce apply coercion

ChkRhsLong          ldd       ,s        second operand type
                    cmpd      #$0008    is it long
                    bne       ChkPointer check for pointer
                    ldd       #$0008    common type long
CoerceRhs           pshs      d         push target type
                    pshs      u         push operand node
ApplyCoerce         lbsr      InsertConvNode coerce the operand
                    leas      4,s        drop arguments
                    bra       ConvRet   return result

ChkPointer          ldd       $02,s     first operand type
                    cmpd      #$0007    is it pointer
                    beq       ResultPointer result pointer
                    ldd       ,s        second operand type
                    cmpd      #$0007    is it pointer
                    bne       ResultInt neither, result int
ResultPointer       ldd       #$0007    common type pointer
                    std       [$0a,s]   store through node pointer
StoreResultRet      std       ,u        store result type
                    bra       ConvRet   return result

ResultInt           ldd       #$0001    default result type int
ConvRet             leas      4,s        drop locals
                    puls      pc,u      restore frame and return

ScalePointer        pshs      u         save frame pointer
                    ldd       #$FFB0    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldd       $08,s     load argument
                    pshs      d         push argument
                    ldd       $06,s     load argument
                    pshs      d         push argument
                    ldd       $0a,s     load node argument
                    pshs      d         push node argument
                    lbsr      RemovePtrLevel compute element scale factor
                    std       ,s        save scale result
                    lbsr      ComputeElemSize get type size
                    leas      6,s        drop arguments
                    std       $04,s     save element size
                    cmpd      #$0001    is scale one
                    bne       BuildScaleNode no, build scale node
                    ldd       $0a,s     return node unchanged
                    puls      pc,u      restore frame and return

BuildScaleNode      ldx       $0a,s     node pointer
                    ldd       $10,x     load type field
                    pshs      d         push type field
                    ldx       $0C,s     load node pointer
                    ldd       $0e,x     load node field
                    pshs      d         push node field
                    ldd       $08,s     size value
                    pshs      d         push size value
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    ldd       #$0036    constant node tag
                    pshs      d         push node tag
                    lbsr      NewExprNode build constant node
                    leas      12,s       drop arguments
                    tfr       d,u       constant node pointer
                    ldd       #$0001    constant value one
                    std       ,u        set node value
                    ldx       $0a,s     node pointer
                    ldd       $10,x     load type field
                    pshs      d         push type field
                    ldx       $0C,s     load node pointer
                    ldd       $0e,x     load node field
                    pshs      d         push node field
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero argument
                    pshs      u         push constant node
                    ldd       $12,s     size operand
                    pshs      d         push size operand
                    ldd       #$0052    multiply node tag
                    pshs      d         push node tag
                    lbsr      NewExprNode build multiply node
                    leas      12,s       drop arguments
                    pshs      d         push result node
                    lbsr      SimplifyExpr simplify subtree
                    leas      2,s        drop argument
                    tfr       d,u       result node pointer
                    ldd       $06,u     load node opcode
                    cmpd      #$0036    is it a constant
                    bne       ScaleTwo  no, scale two
                    clra                scale zero high
                    clrb                scale zero low
                    bra       SetScaleFields set node fields

ScaleTwo            ldd       #$0002    scale factor two
SetScaleFields      std       $12,u     set scale field
                    ldd       #$0001    node value one
                    std       ,u        set node value
                    ldd       #$0002    node size two
                    std       $02,u     set node size
                    tfr       u,d       return node pointer
                    puls      pc,u      restore frame and return

ClassifyNode        pshs      u         save frame pointer
                    ldd       #$FFB6    frame size for stack check
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load node argument
                    leas      -2,s       reserve local
                    ldd       $06,u     load node opcode
                    std       ,s        save opcode
                    tfr       d,x       opcode into index register
                    cmpx      #$0076    opcode 0x76
                    lbeq      ExprEpilogue handle these opcodes
                    cmpx      #$006F    opcode 0x6F
                    lbeq      ExprEpilogue handle these opcodes
                    cmpx      #$0042    opcode 0x42
                    lbeq      ExprEpilogue handle these opcodes
                    ldd       ,s        load opcode
                    cmpd      #$0034    opcode 0x34
                    bne       LvalueErr no, continue dispatch
                    pshs      u         save node pointer
                    bsr       ChkUndeclared check the node for an undeclared variable
                    leas      2,s        drop the pushed argument
                    ldd       $08,s     load the caller flag
                    lbne      ExprEpilogue if set, finish and return
                    ldd       ,u        load the node type word
                    clra                keep only the low byte
                    andb      #$30      isolate the storage-class bits
                    cmpd      #$0020    is it a bitfield/lvalue kind
                    bne       LvalSetFalse no, clear the flag
                    ldd       #$0001    yes, flag as lvalue
                    bra       LvalTestArray test the result

LvalSetFalse        clra                clear high byte
                    clrb                result is false
LvalTestArray       bne       LvalueErr if lvalue, skip the integer check
                    ldd       ,u        reload the node type
                    cmpd      #$0004    is it a plain integer type
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

ChkUndeclared       pshs      u         save the caller frame pointer
                    ldd       #$FFB8    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       $04,s     get the node argument
                    ldd       $06,u     load the node type field
                    cmpd      #$0034    is it a symbol reference
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

ProcStructRef       pshs      u         save the caller frame pointer
                    ldd       #$FFB6    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       $04,s     get the node argument
                    leas      -2,s       allocate a local
                    ldd       ,u        load node field zero
                    std       [$08,s]   store through the result pointer
                    ldd       $06,u     load the node type field
                    cmpd      #$0041    is it a pointer type
                    bne       StructRefZero if not, zero the result
                    ldd       #$0001    flag the pointer case
                    std       [$0a,s]   store through the second result pointer
                    ldd       $0a,u     load the member offset
                    std       ,s        save it in the local
                    ldd       $04,u     load the node value
                    ldx       ,s        get the local pointer
                    std       $04,x     copy the value into the target
                    pshs      u         pass the node
                    ldd       $02,s     load the local pointer
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
                    std       [$0a,s]   clear the second result
StructRefBody       pshs      u         pass the node
                    lbsr      ChkUndeclared check the node for an undeclared variable
                    leas      2,s        clean up the argument
                    ldd       $06,u     load the node type field
                    cmpd      #$0034    is it a symbol reference
                    bne       MemberErr if not, report the member error
                    ldd       $08,u     load the symbol pointer
                    std       ,s        save it in the local
                    ldx       ,s        get the symbol pointer
                    ldd       $08,x     load the symbol type field
                    cmpd      #$0011    is it a struct or union
                    beq       SetStructMember yes, set the struct type
                    leax      $02,s     point past the local
                    bra       MemberFixup fix up the member

SetStructMember     ldd       #$0036    select the struct-member node type
                    std       $06,u     set the node type
                    ldx       ,s        get the symbol pointer
                    ldd       $06,x     load the symbol subtype
                    std       $08,u     store it into the node
                    clra                clear high byte
                    clrb                zero
                    std       $12,u     clear node field twelve
                    ldd       #$0001    set the node flag
                    std       ,u        store the flag
                    ldx       ,s        get the symbol pointer
                    ldd       $02,x     load the symbol value
                    bra       ExprEpilogue finish and return

                    bra       MemberErr unreachable fallthrough guard

MemberFixup         leas      -$02,x    adjust the stack via the pointer
MemberErr           leax      MsgStructMember,pcr point to the struct-member message
                    pshs      x         pass the message pointer
                    pshs      u         pass the node
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    pshs      u         pass the node
                    lbsr      SetErrSym reset the node to the error symbol
                    leas      2,s        clean up the argument
                    ldd       #$0036    select the struct-member node type
                    std       $06,u     set the node type
                    clra                clear high byte
                    clrb                zero
                    std       $08,u     clear node field eight
                    clra                clear high byte
                    clrb                zero
                    std       $12,u     clear node field twelve
                    ldd       #$0001    set the node flag
                    std       [$08,s]   store through the result pointer
                    ldd       #$0002    return value two
ExprEpilogue        leas      2,s        release the local
ExprReturn          puls      pc,u      restore frame and return

ChkNotStruct        pshs      u         save the caller frame pointer
                    ldd       #$FFB8    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       $04,s     get the node argument
                    ldd       ,u        load the node type word
                    cmpd      #$0004    is it a structure
                    beq       StructInapproprErr yes, report the error
                    ldd       ,u        reload the node type
                    cmpd      #$0003    is it a union
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
                    puls      pc,u      restore frame and return

SetErrSym           pshs      u         save the caller frame pointer
                    ldd       #$FFB6    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldu       $04,s     get the node argument
                    ldd       #$0006    length six bytes
                    pshs      d         pass the length
                    pshs      u         pass the node
                    leax      DummyErrorSymbol,y   point to the dummy error symbol
                    pshs      x         pass it
                    lbsr      CopyBlock copy the error symbol into the node
                    leas      6,s        clean up the arguments
                    ldd       #$0001    value one
                    std       $12,u     mark node field twelve
                    ldd       $0a,u     load node field ten
                    pshs      d         pass it
                    lbsr      WalkTree  free the sub-node
                    leas      2,s        clean up the argument
                    ldd       $0C,u     load node field twelve
                    pshs      d         pass it
                    lbsr      WalkTree  free the sub-node
                    leas      2,s        clean up the argument
                    clra                clear high byte
                    clrb                zero
                    std       $0C,u     clear node field twelve
                    std       $0a,u     clear node field ten
                    ldd       #$0034    select the symbol-reference type
                    std       $06,u     set the node type
                    leax      DummyErrorSymbol,y   point to the dummy error symbol
                    stx       $08,u     attach it to the node
                    puls      pc,u      restore frame and return

IsIntegral          pshs      u         save the caller frame pointer
                    ldd       #$FFC0    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldx       $04,s     get the type-code argument
                    bra       IsIntegralCmp test against the integral codes

RetIntegral         ldd       #$0001    result is true
                    puls      pc,u      restore frame and return

IsIntegralCmp       cmpx      #$0001    is it type code one
                    beq       RetIntegral yes, integral
                    cmpx      #$0002    is it type code two
                    lbeq      RetIntegral yes, integral
                    cmpx      #$0008    is it type code eight
                    lbeq      RetIntegral yes, integral
                    cmpx      #$0007    is it type code seven
                    lbeq      RetIntegral yes, integral
                    clra                clear high byte
                    clrb                result is false
                    puls      pc,u      restore frame and return

ErrMustBeIntegral   pshs      u         save the caller frame pointer
                    ldd       #$FFB8    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    leax      MsgMustBeIntegral,pcr point to the must-be-integral message
                    pshs      x         pass the message pointer
                    ldd       $06,s     load the caller argument
                    pshs      d         pass it
                    lbsr      PrintErrSpan report the error
                    leas      4,s        clean up the arguments
                    puls      pc,u      restore frame and return

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
ParseStatement      pshs      u         save the caller frame pointer
                    ldd       #$FFBA    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    is it a semicolon
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
                    puls      pc,u      restore frame and return

HandleKw14          lbsr      WhileStmt parse the statement
                    puls      pc,u      restore frame and return

HandleKw12          lbsr      ParseReturnStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw17          lbsr      CaseStmt  parse the statement
                    puls      pc,u      restore frame and return

HandleKw16          lbsr      SwitchStmt parse the statement
                    puls      pc,u      restore frame and return

HandleKw18          lbsr      ParseBreakStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw19          lbsr      ParseContinueStmt parse the statement
                    lbra      ExpectSemi expect the semicolon

HandleKw1B          lbsr      DefaultStmt parse the statement
                    puls      pc,u      restore frame and return

HandleKw1C          lbsr      ForStmt   parse the statement
                    puls      pc,u      restore frame and return

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

KwDispatch          cmpx      #$0013    is it the if keyword
                    beq       ParseIfEntry yes, parse if
                    cmpx      #$0014    keyword code fourteen
                    beq       HandleKw14 dispatch it
                    cmpx      #$0012    keyword code twelve
                    beq       HandleKw12 dispatch it
                    cmpx      #$0017    keyword code seventeen
                    beq       HandleKw17 dispatch it
                    cmpx      #$0016    keyword code sixteen
                    beq       HandleKw16 dispatch it
                    cmpx      #$0018    keyword code eighteen
                    beq       HandleKw18 dispatch it
                    cmpx      #$0019    keyword code nineteen
                    beq       HandleKw19 dispatch it
                    cmpx      #$001B    keyword code 0x1b
                    beq       HandleKw1B dispatch it
                    cmpx      #$001C    keyword code 0x1c
                    beq       HandleKw1C dispatch it
                    cmpx      #$001A    keyword code 0x1a
                    beq       HandleKw1A dispatch it
                    cmpx      #$001D    keyword code 0x1d
                    beq       HandleKw1D dispatch it
                    cmpx      #$0015    is it the else keyword
                    beq       StrayElseErr yes, stray-else error
                    bra       NotKeywordStmt otherwise expression statement

ParseBlock          lbsr      ParseBlock2 parse a brace block
                    lbsr      ScanToken advance to the next token
                    puls      pc,u      restore frame and return

StmtEofRet          puls      pc,u      restore frame and return

IdentOrLabel        lbsr      SkipWhitespace parse the identifier expression
                    ldb       GlbVar0065 load the following character
                    cmpb      #$3a      is it a colon
                    bne       NotLabelStmt no, treat as an expression
                    lbsr      ParseLabelStmt define the statement label
LabelDone           leax      ,s        point at the stack
                    lbra      StmtLoop  loop for the next statement

NotLabelStmt        leax      ,s        point at the stack
                    bra       ExprStmtRestore handle as an expression statement

ExprStmtEntry       leas      ,x        restore the stack pointer
ParseExprStmt       lbsr      IsQualifierKw parse an expression
                    std       -$02,s    save the result node
                    bne       ExprStmtErr if error, report it
                    lbsr      ClassifyType parse an expression alternate
                    std       -$02,s    save the result node
                    beq       EmitExprStmt if empty, emit the statement
ExprStmtErr         leax      MsgIllegalDecl,pcr point to the syntax-error message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        clean up the argument
SkipToSemiLoop      lbsr      ScanToken advance to the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    is it a semicolon
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
                    puls      pc,u      restore frame and return

                    bra       ExpectSemi unreachable, expect the semicolon

ClassifyStmt        cmpx      #$0028    is it a semicolon
                    beq       ExpectSemi yes, consume it
                    cmpx      #$0033    is it a reserved word
                    lbeq      KwDispatch2 yes, dispatch the keyword
                    cmpx      #$0029    is it an open brace
                    lbeq      ParseBlock yes, parse a block
                    cmpx      #$FFFF    is it end of input
                    lbeq      StmtEofRet yes, just return
                    cmpx      #$0034    is it an identifier
                    lbeq      IdentOrLabel yes, maybe a label
                    lbra      ParseExprStmt otherwise expression statement

ExpectSemi          ldd       #$0028    semicolon token
                    pshs      d         pass the expected token
                    lbsr      ExpectToken require the semicolon
                    leas      2,s        clean up the argument
                    puls      pc,u      restore frame and return

ParseIfStmt         pshs      u         save the caller frame pointer
                    ldd       #$FFAE    request stack frame space
                    lbsr      stkcheck  verify stack depth
                    leas      -6,s       allocate the locals
                    lbsr      ScanToken advance past the if keyword
                    lbsr      ParseParenExpr2 parse the parenthesized condition
                    std       ,s        save the condition node
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label number
                    std       GlbVar002B update the counter
                    tfr       d,u       keep the false label
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate another label number
                    std       GlbVar002B update the counter
                    std       $04,s     save the end label
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    is it a semicolon
                    bne       IfThenBody no, parse the then body
                    lbsr      ScanToken advance to the next token
                    clra                clear high byte
                    clrb                zero
                    pshs      d         pass zero
                    ldd       $06,s     load the false label
                    pshs      d         pass it
                    pshs      u         pass the condition
                    ldd       $06,s     reload the false label
                    pshs      d         pass it
                    lbsr      EmitCondNode emit the conditional branch
                    leas      8,s        clean up the arguments
                    ldd       $04,s     load the end label
                    pshs      d         pass it
                    lbsr      EmitLocalRef emit the label
                    leas      2,s        clean up the argument
                    stu       $02,s     save the returned node
                    bra       CheckElse check for an else clause

IfThenBody          ldd       #$0001    value one
                    pshs      d         pass it
                    ldd       $06,s     load the false label
                    pshs      d         pass it
                    pshs      u         pass the condition
                    ldd       $06,s     reload the false label
                    pshs      d         pass it
                    lbsr      EmitCondNode emit the conditional branch
                    leas      8,s        clean up the arguments
                    pshs      u         pass the condition
                    lbsr      EmitLocalRef emit the label
                    leas      2,s        clean up the argument
                    lbsr      ParseStatement parse the then statement
                    ldd       $04,s     load the end label
                    std       $02,s     save it
CheckElse           ldd       GlbVar005F load the current token
                    cmpd      #$0033    is it a reserved word
                    bne       IfStmtDone no, finish the if
                    ldd       GlbVar0061 load the keyword subtype
                    cmpd      #$0015    is it the else keyword
                    bne       IfStmtDone no, finish the if
                    lbsr      ScanToken advance past else
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    compare token type against paren tag
                    beq       IfStmtDone no else clause, skip to end
                    cmpu      $02,s     compare against saved else label
                    beq       IfElseBody else absent, parse else body directly
                    clra                clear high byte of argument
                    clrb                clear low byte of argument
                    pshs      d         push zero argument
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate the next label number
                    std       GlbVar002B store label counter back
                    std       $04,s     remember the new end label
                    pshs      d         push the end label argument
                    ldd       #$007C    tag for a goto node
                    pshs      d         push the node tag
                    lbsr      EmitOpCode emit goto past the else clause
                    leas      6,s        drop the three arguments
                    ldd       $04,s     reload the end label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the branch-over label
                    leas      2,s        drop the argument
IfElseBody          lbsr      ParseStatement parse the else-clause statement
IfStmtDone          ldd       $02,s     load the if end label
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
                    std       $08,s     stash on the stack frame
                    ldd       GlbVar0055 save the current continue label
                    std       $06,s     stash on the stack frame
                    ldd       RecordContextField,y   save loop context field
                    std       $04,s     stash on the stack frame
                    ldd       RecordContextField2,y   save second context field
                    std       $02,s     stash on the stack frame
                    lbsr      ScanToken consume the while token
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a new label
                    std       GlbVar002B store counter back
                    std       GlbVar0053 set as the new break label
                    ldd       GlbVar002F load current token position
                    std       RecordContextField2,y   record into context field
                    std       RecordContextField,y   record into context field
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate another label
                    std       GlbVar002B store counter back
                    std       GlbVar0055 set as the new continue label
                    lbsr      ParseParenExpr2 parse the loop condition expression
                    std       ,s        save the condition result
                    ldd       GlbVar005F load current token type
                    cmpd      #$0028    compare against paren tag
                    bne       WhileEmitBody not that token, emit body path
                    ldu       GlbVar0055 reuse continue label
                    bra       WhileEmitTest skip ahead to test emit

WhileEmitBody       clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar0055 load the continue label
                    pshs      d         push it as argument
                    ldd       #$007C    goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the continue point
                    leas      6,s        drop the three arguments
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label
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
                    ldd       $06,s     reload the condition result
                    pshs      d         push it as argument
                    lbsr      EmitCondNode emit conditional back-jump on true
                    leas      8,s        drop the four arguments
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the break label
                    leas      2,s        drop the argument
                    ldd       $08,s     restore the saved break label
                    std       GlbVar0053 put it back in the global
                    ldd       $06,s     restore the saved continue label
                    std       GlbVar0055 put it back in the global
                    ldd       $04,s     restore saved context field
                    std       RecordContextField,y   put it back
                    ldd       $02,s     restore second context field
                    std       RecordContextField2,y   put it back
                    leas      10,s       tear down the frame
                    puls      pc,u      restore u and return

SwitchStmt          pshs      u         save u on entry
                    ldd       #$FFA8    stack space needed
                    lbsr      stkcheck  verify stack space available
                    leas      -14,s      allocate local frame
                    lbsr      ScanToken consume the switch token
                    ldd       GlbVar0057 load the switch nesting counter
                    addd      #$0001    increment for this switch
                    std       GlbVar0057 store counter back
                    ldd       GlbVar005B save current case-list tail
                    std       ,s        stash on the frame
                    ldd       GlbVar0059 save current case chain head
                    std       $0a,s     stash on the frame
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0059 reset the case chain
                    ldd       GlbVar0053 save current break label
                    std       $0C,s     stash on the frame
                    ldd       DefaultLabel,y   save current default label
                    std       $08,s     stash on the frame
                    ldd       RecordContextField,y   save context field
                    std       $02,s     stash on the frame
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label
                    std       GlbVar002B store counter back
                    std       GlbVar0053 set as the new break label
                    ldd       GlbVar002F load current token position
                    std       RecordContextField,y   record into context field
                    clra                clear high byte
                    clrb                clear low byte
                    std       DefaultLabel,y   clear the default label
                    ldd       #$002D    open-paren token expected
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
                    stu       -$02,s    save expression pointer
                    beq       SwitchExprErr null expression, report error
                    pshs      u         push the expression pointer
                    lbsr      ChkUndeclared fetch its type node
                    leas      2,s        drop the argument
                    ldx       ,u        load the type code
                    bra       SwitchCheckType dispatch on the type

SwitchExprInt       ldd       #$0001    integer promotion flag
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

SwitchCheckType     cmpx      #$0002    is the type char/int
                    beq       SwitchExprInt yes, promote to int
                    cmpx      #$0008    is the type unsigned
                    lbeq      SwitchExprInt yes, promote to int
                    cmpx      #$0001    is the type already word
                    beq       SwitchExprDone yes, expression done
                    cmpx      #$0007    is the type pointer
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
SwitchAfterExpr     ldd       #$002E    close-paren token expected
                    pshs      d         push the expected token
                    lbsr      ExpectToken require the close paren
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label
                    std       GlbVar002B store counter back
                    std       $08,s     remember the case-test label
                    pshs      d         push it as argument
                    ldd       #$007C    goto node tag
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
                    ldd       #$007C    goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the break point
                    leas      6,s        drop the three arguments
SwitchDefTestLabel  ldd       $06,s     load the case-test label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the case-test label
                    leas      2,s        drop the argument
                    ldu       GlbVar0059 load the case chain head
                    bra       SwitchCaseTest enter the case emit loop

SwitchCaseLoop      ldd       ,u        load the next case node
                    std       $04,s     save the chain link
                    ldd       $02,u     load the case value
                    pshs      d         push it as argument
                    ldd       $04,u     load the case label
                    pshs      d         push it as argument
                    ldd       #$007D    case-compare node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit the case comparison
                    leas      6,s        drop the three arguments
                    ldd       GlbVar0045 load the free-list head
                    std       ,u        link node onto free list
                    stu       GlbVar0045 return node to the free list
                    ldu       $04,s     advance to the next case node
SwitchCaseTest      stu       -$02,s    save loop pointer, test null
                    bne       SwitchCaseLoop more cases, loop back
                    ldd       DefaultLabel,y   any default label
                    beq       SwitchEpilogue none, skip default goto
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       DefaultLabel,y   load the default label
                    pshs      d         push it as argument
                    ldd       #$007C    goto node tag
                    pshs      d         push the tag
                    lbsr      EmitOpCode emit goto to the default
                    leas      6,s        drop the three arguments
SwitchEpilogue      ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the break label
                    leas      2,s        drop the argument
                    ldd       $0a,s     restore saved case chain
                    std       GlbVar0059 put it back
                    ldd       $08,s     restore saved default label
                    std       DefaultLabel,y   put it back
                    ldd       GlbVar0057 load the switch nesting counter
                    addd      #$FFFF    decrement leaving this switch
                    std       GlbVar0057 store counter back
                    ldd       ,s        restore saved case-list tail
                    std       GlbVar005B put it back
                    ldd       $0C,s     restore saved break label
                    std       GlbVar0053 put it back
                    ldd       $02,s     restore saved context field
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
                    ldd       #$002F    colon token expected
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

CaseAllocNode       ldd       #$0006    case-node size
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
                    std       $02,u     store into the node
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate the case label
                    std       GlbVar002B store counter back
                    std       $04,u     store label into the node
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
                    addd      #$0001    allocate the default label
                    std       GlbVar002B store counter back
                    std       DefaultLabel,y   store as the default label
                    pshs      d         push the default label
                    lbsr      EmitLocalRef define the default label
DefaultExpectColon  leas      2,s        drop the argument
                    ldd       #$002F    colon token expected
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
                    std       $08,s     stash on the frame
                    ldd       GlbVar0055 save current continue label
                    std       $06,s     stash on the frame
                    ldd       RecordContextField2,y   save context field
                    std       ,s        stash on the frame
                    ldd       RecordContextField,y   save context field
                    std       $02,s     stash on the frame
                    ldd       GlbVar002F load current token position
                    std       RecordContextField2,y   record into context field
                    std       RecordContextField,y   record into context field
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label
                    std       GlbVar002B store counter back
                    std       GlbVar0055 set as the new continue label
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label
                    std       GlbVar002B store counter back
                    std       GlbVar0053 set as the new break label
                    lbsr      ScanToken consume the do token
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate the loop-top label
                    std       GlbVar002B store counter back
                    std       $04,s     remember the loop-top label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the loop-top label
                    leas      2,s        drop the argument
                    lbsr      ParseStatement parse the loop body statement
                    ldd       GlbVar005F load current token type
                    cmpd      #$0033    is it the while keyword
                    bne       DoMissingWhile no, report missing while
                    ldd       GlbVar0061 load token keyword id
                    cmpd      #$0014    confirm it is while
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
                    ldd       $08,s     push the loop-top label
                    pshs      d         push the loop-top label argument
                    lbsr      ParseParenExpr2 parse the condition expression
                    pshs      d         push the condition result
                    lbsr      EmitCondNode emit conditional jump to top
                    leas      8,s        drop the four arguments
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it as argument
                    lbsr      EmitLocalRef define the break label
                    leas      2,s        drop the argument
                    ldd       $08,s     restore saved break label
                    std       GlbVar0053 put it back
                    ldd       $06,s     restore saved continue label
                    std       GlbVar0055 put it back
                    ldd       $02,s     restore saved context field
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
                    std       $02,s     zero a frame slot
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        zero a frame slot
                    ldu       GlbVar0053 save current break label
                    ldd       GlbVar0055 save current continue label
                    std       $0C,s     stash on the frame
                    ldd       RecordContextField,y   save context field
                    std       $06,s     stash on the frame
                    ldd       RecordContextField2,y   save context field
                    std       $04,s     stash on the frame
                    ldd       GlbVar002F load current token position
                    std       RecordContextField,y   record into context field
                    std       RecordContextField2,y   record into context field
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label
                    std       GlbVar002B store counter back
                    std       $0a,s     save the value into a local slot
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate the next label number
                    std       GlbVar002B bump the label counter
                    std       GlbVar0053 set this as the loop break label
                    lbsr      ScanToken advance to the next token
                    ldd       #$002D    loop-start marker opcode
                    pshs      d         push the opcode argument
                    lbsr      ExpectToken emit the intermediate marker
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      ParseExprStmt2 parse and emit the init expression
                    leas      2,s        discard the argument
                    ldd       #$0028    condition marker opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    is the condition empty
                    beq       LoopEmptyCond skip the condition if none
                    lbsr      ParseExpr2 parse the loop condition expression
                    std       $02,s     save the condition node
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate another label number
                    std       GlbVar002B bump the label counter
                    std       $0a,s     save the loop label
                    pshs      d         push the label
                    ldd       #$007C    conditional-branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the conditional branch node
                    leas      6,s        discard the arguments
LoopEmptyCond       ldd       #$0028    increment marker opcode
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
                    addd      #$0001    allocate the continue label
                    std       GlbVar002B bump the label counter
                    bra       LoopSetContLabel set the continue label

LoopNoIncr          ldd       $0a,s     reuse the loop label
LoopSetContLabel    std       GlbVar0055 set the loop continue label
                    ldd       #$002E    loop-end marker opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    ldd       $0a,s     load the continue label
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
LoopEmitCondBack    ldd       $02,s     load the condition node
                    beq       LoopEmitUncondBack no condition, emit unconditional loop
                    ldd       $08,s     load the loop label
                    pshs      d         push it
                    lbsr      EmitLocalRef build the loop label node
                    leas      2,s        discard the argument
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       GlbVar0053 load the break label
                    pshs      d         push it
                    ldd       $0e,s     load the condition node
                    pshs      d         push it
                    ldd       $08,s     load the loop label node
                    pshs      d         push it
                    lbsr      EmitCondNode emit the conditional loop-back node
                    leas      8,s        discard the arguments
                    bra       LoopRestoreLabels finish the loop

LoopEmitUncondBack  clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       $0C,s     load the loop label
                    pshs      d         push it
                    ldd       #$007C    branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the unconditional loop-back node
                    leas      6,s        discard the arguments
LoopRestoreLabels   ldd       GlbVar0053 load the break label
                    pshs      d         push it
                    lbsr      EmitLocalRef build the break label node
                    leas      2,s        discard the argument
                    stu       GlbVar0053 restore the outer break label
                    ldd       $0C,s     load the saved continue label
                    std       GlbVar0055 restore the outer continue label
                    ldd       $06,s     load the saved outer break slot
                    std       RecordContextField,y   restore the outer break slot
                    ldd       $04,s     load the saved outer continue slot
                    std       RecordContextField2,y   restore the outer continue slot
LoopStmtDone        leas      14,s       tear down the stack frame
                    puls      pc,u      return

ParseReturnStmt     pshs      u         save the caller frame pointer
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    is there no return value
                    lbeq      EmitBareReturn emit a bare return if so
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    lbsr      ParseExpr begin parsing the return expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the expression node
                    stu       -$02,s    save it in a local
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
                    cmpd      #$0010    is it a plain type
                    bne       ReturnUseDeclType otherwise use the declared type
                    ldd       #$0001    use the default type
                    bra       ReturnHaveType continue

ReturnUseDeclType   ldd       GlbVar004D load the declared type
ReturnHaveType      pshs      d         push the type
                    pshs      u         push the node
                    lbsr      InsertConvNode check type compatibility
                    leas      4,s        discard the arguments
                    ldd       GlbVar004D load the return type
                    pshs      d         push it
                    pshs      u         push the node
                    ldd       #$0012    return opcode
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
                    ldd       #$0012    return opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the return node
                    leas      6,s        discard the arguments
                    ldd       #$0012    return statement opcode
                    lbra      SetStmtOpcode record the statement opcode

ParseBreakStmt      pshs      u         save the caller frame pointer
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
                    ldd       #$007C    branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the break jump node
                    leas      6,s        discard the arguments
BreakStmtDone       ldd       #$0018    break statement opcode
                    lbra      SetStmtOpcode record the statement opcode

ParseContinueStmt   pshs      u         save the caller frame pointer
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
                    ldd       #$007C    branch opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the continue jump node
                    leas      6,s        discard the arguments
ContinueStmtDone    ldd       #$0019    continue statement opcode
                    bra       SetStmtOpcode record the statement opcode

ParseGotoStmt       pshs      u         save the caller frame pointer
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0034    is it a label identifier
                    beq       EmitGotoJump process the goto target
                    leax      MsgLabelRequired,pcr point to the missing-label message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    bra       GotoSetOpcode finish

EmitGotoJump        lbsr      FindOrMakeLabel find or create the target label
                    tfr       d,u       keep the label node
                    stu       -$02,s    save it in a local
                    beq       GotoAdvance skip if none
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       $06,u     load the label number
                    pshs      d         push it
                    ldd       #$001D    goto opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the goto node
                    leas      6,s        discard the arguments
                    ldd       $0a,u     load the label flags
                    orb       #$02      mark the label referenced
                    std       $0a,u     store the flags
GotoAdvance         lbsr      ScanToken advance past the label
GotoSetOpcode       ldd       #$001D    goto statement opcode
SetStmtOpcode       std       GlbVar004F record the statement opcode
                    puls      pc,u      return

ParseLabelStmt      pshs      u         save the caller frame pointer
                    ldd       #$FFB6    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    bsr       FindOrMakeLabel find or create the label
                    tfr       d,u       keep the label node
                    stu       -$02,s    save it in a local
                    beq       LabelStmtDone skip if none
                    ldd       $08,u     load the label state
                    cmpd      #$000F    is it already defined
                    bne       DefineLabelHere otherwise define it now
                    lbsr      ReportMsgErr report the redefined-label error
                    bra       LabelStmtDone finish

DefineLabelHere     ldd       #$000F    defined-label state
                    std       $08,u     mark the label defined
                    clra                prepare a null value
                    clrb                prepare a null value
                    pshs      d         push a null argument
                    ldd       $06,u     load the label number
                    pshs      d         push it
                    ldd       #$0009    label opcode
                    pshs      d         push the opcode
                    lbsr      EmitOpCode emit the label-definition node
                    leas      6,s        discard the arguments
                    ldd       $0a,u     load the label flags
                    orb       #$01      mark the label defined
                    std       $0a,u     store the flags
LabelStmtDone       lbsr      ScanToken advance to the next token
                    lbsr      ScanToken advance again past the colon
                    puls      pc,u      return

FindOrMakeLabel     pshs      u         save the caller frame pointer
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldu       GlbVar0061 load the identifier symbol pointer
                    ldd       ,u        load its type
                    cmpd      #$0009    is it already a label
                    lbeq      ReturnNodeInD return the existing label
                    ldd       ,u        reload its type
                    beq       InitLabelSym reuse the empty symbol
                    ldd       $0C,u     is the symbol name in use
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
InitLabelSym        ldd       #$0009    label type
                    std       ,u        mark the symbol as a label
                    ldd       #$000D    undefined-label state
                    std       $08,u     set the initial state
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    allocate a label number
                    std       GlbVar002B bump the label counter
                    std       $06,u     store the label number
                    clra                prepare a null value
                    clrb                prepare a null value
                    std       $0a,u     clear the label flags
                    ldd       GlbVar0051 load the current name pointer
                    std       $0C,u     store the label name
                    ldd       GlbVar0049 load the label list head
                    std       $10,u     link into the label list
                    stu       GlbVar0049 make this the new list head
                    lbra      ReturnNodeInD return the label node

ParseExprStmt2      pshs      u         save the caller frame pointer
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldd       $04,s     load the argument node
                    pshs      d         push it
                    lbsr      ParseExpr begin parsing an expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the node
                    stu       -$02,s    save it in a local
                    lbeq      ReturnNodeInD return null if empty
                    pshs      u         push the node
                    lbsr      OptExprTree parse the rest of the expression
                    std       ,s        save the expression node
                    bsr       EmitExprNode emit the expression
                    leas      2,s        discard the argument
                    tfr       d,u       keep the result node
                    lbra      ReturnNodeInD return the node

EmitExprNode        pshs      u         save the caller frame pointer
                    ldd       #$FFBA    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the expression node
                    pshs      u         push it
                    lbsr      ChkUndeclared process the expression tree
                    leas      2,s        discard the argument
                    ldx       $06,u     load the node operator
                    bra       CheckRelSwap check for a relational swap

RelSwapToLess       ldd       #$003C    less-than operator
                    bra       StoreRelOp store it

RelSwapToLessEq     ldd       #$003D    less-or-equal operator
StoreRelOp          std       $06,u     replace the node operator
                    bra       EmitRelNode emit the node

CheckRelSwap        cmpx      #$003E    is it greater-than
                    beq       RelSwapToLess swap to less-than
                    cmpx      #$003F    is it greater-or-equal
                    beq       RelSwapToLessEq swap to less-or-equal
EmitRelNode         pshs      u         push the node
                    lbsr      EmitStmtMode4 allocate the result node
                    leas      2,s        discard the argument
                    tfr       d,u       keep the result node
                    pshs      u         push it
                    lbsr      WalkTree  finalize and emit the expression
                    lbra      ExprReturnTail return the node

ParseParenExpr2     pshs      u         save the caller frame pointer
                    ldd       #$FFB8    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       make room for a local
                    ldd       #$002D    subexpression start marker
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    bsr       ParseExpr2 parse the subexpression
                    std       ,s        save the node
                    ldd       #$002E    subexpression end marker
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the marker
                    leas      2,s        discard the argument
                    ldd       ,s        load the saved node
                    lbra      CondEmitDone emit and return the node

ParseExpr2          pshs      u         save the caller frame pointer
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
                    stu       -$02,s    save it in a local
                    beq       ExprExpectedErr error if the expression is missing
                    pshs      u         push the node
                    lbsr      ChkUndeclared process the expression tree
                    bra       ExprReturnTail return the node

ExprExpectedErr     leax      MsgConditionNeeded,pcr point to the expression-expected message
                    pshs      x         push the message
                    lbsr      PrintErrLoc report the error
ExprReturnTail      leas      2,s        discard the argument
ReturnNodeInD       tfr       u,d       return the node in D
                    puls      pc,u      restore frame and return

EmitCondNode        pshs      u         save the caller frame pointer
                    ldd       #$FFB4    load the negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the target node
                    stu       -$02,s    save it in a local
                    beq       CondNodeReturn return if null
                    ldd       $0a,s     load the third argument
                    pshs      d         push it
                    ldd       $0a,s     load the second argument
                    pshs      d         push it
                    ldd       $0a,s     load the first argument
                    pshs      d         push it
                    pshs      u         push the node
                    lbsr      EmitStmtMode2 build the three-child node
                    leas      8,s        discard the arguments
                    pshs      u         push the node
                    lbsr      WalkTree  finalize and emit the expression
CondEmitDone        leas      2,s        discard the argument
CondNodeReturn      puls      pc,u      restore frame and return

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
ParseMulExpr        pshs      u         save caller frame pointer
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
                    cmpd      #$002A    is it a star
                    beq       StarErrLoop loop back while star
                    ldd       GlbVar005F load current token
                    cmpd      #$0029    is it a close paren
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
                    std       $0a,s     save its type
                    tfr       d,x       copy type into x for testing
                    bra       CheckOperandTok check operand token kind

IdentToken          leax      MsgStorageError,pcr point to the error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
SetDefaultType      ldd       #$000C    default type code
                    std       $0a,s     store the type
                    bra       CombineType go combine types

CheckOperandTok     cmpx      #$0010    is token 0010
                    beq       IdentToken handle as identifier
                    cmpx      #$000D    is token 000D
                    lbeq      IdentToken handle as identifier
                    stx       -$02,s    save the token
                    beq       SetDefaultType zero means set default type
CombineType         leax      ,s        point to local slot
                    pshs      x         push its pointer
                    leax      $06,s     point to local slot
                    pshs      x         push its pointer
                    leax      $16,s     point to local slot
                    pshs      x         push its pointer
                    lbsr      ParseDeclSpec resolve and combine types
                    leas      6,s        drop three arguments
                    std       $08,s     save the result
                    bne       NextOperand nonzero result, continue
                    ldd       #$0001    default result of one
                    std       $08,s     store the result
NextOperand         ldd       $04,s     load saved value
                    std       $0C,s     copy into slot
                    ldd       $08,s     load combine result
                    pshs      d         push as argument
                    leax      $0e,s     point to local
                    pshs      x         push its pointer
                    leax      $06,s     point to local
                    pshs      x         push its pointer
                    lbsr      ParseTypeSpec compute combined type
                    leas      6,s        drop the arguments
                    std       $06,s     save combined type
                    ldu       $02,s     load node pointer
                    bne       HaveNode  branch when node exists
                    ldd       $06,s     load the type
                    cmpd      #$0004    is type four
                    beq       NoNode    accept without node
                    ldd       $06,s     load the type
                    cmpd      #$0003    is type three
                    beq       NoNode    accept without node
                    lbsr      ErrIdentMissing report a type error
NoNode              leax      $14,s     point past the locals
                    lbra      RestoreLocals go restore stack

HaveNode            ldd       $06,s     load the type
                    clra                clear high byte
                    andb      #$30      mask the class bits
                    cmpd      #$0030    is it pointer class
                    bne       UseSavedType no, use saved type
                    ldd       GlbVar005F load current token
                    cmpd      #$0030    compare token 0030
                    beq       PtrOpType select pointer op
                    ldd       GlbVar005F load current token
                    cmpd      #$0028    is it open paren
                    bne       PlainOpType no, plain op type
PtrOpType           ldd       #$000E    pointer operation type
                    bra       StoreOpType2 store the op type

PlainOpType         ldd       #$000C    plain operation type
                    bra       StoreOpType2 store the op type

UseSavedType        ldd       $0a,s     use previously saved type
StoreOpType2        std       $0e,s     store the operation type
                    ldd       ,u        load node first field
                    beq       InitNode2 empty node, initialise
                    ldd       ,s        load a saved value
                    pshs      d         push as argument
                    ldd       $08,s     load a saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      CheckTypeMatch check type compatibility
                    leas      6,s        drop the arguments
                    std       -$02,s    save the result
                    lbne      CheckLvalue nonzero, skip node fill
                    ldd       $0e,s     load the op type
                    cmpd      #$000E    is it pointer op
                    lbeq      CheckLvalue skip node fill
                    ldd       $08,u     load node op field
                    cmpd      #$000E    is it pointer op
                    beq       FillNode  fill this node
                    ldd       $08,u     load node op field
                    cmpd      #$0022    is it op 0022
                    beq       FillNode  fill this node
                    lbsr      ReportMsgErr report an error
                    lbra      CheckLvalue skip node fill

FillNode            ldd       $0e,s     load the op type
                    std       $08,u     store into node op field
                    ldd       $0C,s     load saved value
                    std       $04,u     store into node field
                    ldd       ,s        load saved value
                    std       $0a,u     store into node field
                    leax      $14,s     point past the locals
                    bra       RestoreFromX go restore stack from x

InitNode2           ldd       $06,s     load the type
                    std       ,u        store into node first field
                    clra                clear high byte
                    clrb                clear low byte
                    std       $0C,u     zero the node field
                    ldd       $0e,s     load the op type
                    std       $08,u     store into node op field
                    ldd       ,s        load saved value
                    std       $0a,u     store into node field
                    bra       EmitBinOp go emit the operation

RestoreFromX        leas      -$14,x    restore stack pointer from x
EmitBinOp           ldd       $12,s     load a saved value
                    pshs      d         push as argument
                    ldd       $0e,s     load the op type
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      SetNodeTypeSize emit the binary operation
                    leas      6,s        drop the arguments
                    std       $10,s     save the result
                    ldd       $06,s     load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #$0030    is pointer class
                    lbeq      CheckLvalue yes, skip ahead
                    ldd       GlbVar005F load current token
                    cmpd      #$0078    is it subscript token
                    bne       CheckArithType no, check arithmetic
                    ldd       $06,s     load the type
                    pshs      d         push as argument
                    ldd       $10,s     load the result
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      ParseInitializer handle the subscript
BinOpDone           leas      6,s        drop the arguments
                    lbra      FixupOpType go fix up the op type

CheckArithType      ldd       $10,s     load the result
                    bne       DispatchByOp nonzero, continue
                    ldd       $0e,s     load the op type
                    cmpd      #$000E    is it pointer op
                    beq       DispatchByOp pointer op, continue
                    lbsr      ErrCannotEvalSize report an error
                    lbra      FixupOpType go fix up the op type

DispatchByOp        ldx       $0e,s     load the op type into x
                    bra       OpDispatch dispatch on the op

EmitDerefOp         ldd       $0e,s     load the op type
                    cmpd      #$0023    is it indirect op
                    bne       ClearDerefFlag no, clear the flag
                    ldd       #$0001    set the flag
                    bra       CallDeref go call emitter

ClearDerefFlag      clra                clear high byte
                    clrb                clear low byte
CallDeref           pshs      d         push the flag argument
                    ldd       $12,s     load a saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      EmitLabelSpace emit the dereference
                    bra       BinOpDone finish this operation

EmitNegOp           ldd       $0e,s     load the op type
                    cmpd      #$0021    is it op 0021
                    bne       ClearNegFlag no, clear the flag
                    ldd       #$0001    set the flag
                    bra       CallNeg   go call emitter

ClearNegFlag        clra                clear high byte
                    clrb                clear low byte
CallNeg             pshs      d         push the flag argument
                    ldd       $12,s     load a saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      EmitLabelColon emit the operation
                    lbra      BinOpDone finish this operation

OpDispatch          cmpx      #$0023    is op indirect
                    beq       EmitDerefOp emit dereference
                    cmpx      #$000F    is op 000F
                    lbeq      EmitDerefOp emit dereference
                    cmpx      #$0021    is op 0021
                    beq       EmitNegOp emit negate
                    cmpx      #$000C    is op 000C
                    lbeq      EmitNegOp emit negate
FixupOpType         ldd       $0e,s     load the op type
                    cmpd      #$000F    is it op 000F
                    bne       CheckOp23 no, check op 0023
                    ldd       #$000C    map to op 000C
                    bra       StoreAdjOp store the adjusted op

CheckOp23           ldd       $0e,s     load the op type
                    cmpd      #$0023    is it op 0023
                    bne       CheckLvalue no, keep the op
                    ldd       #$0021    map to op 0021
StoreAdjOp          std       $08,u     store adjusted op into node
CheckLvalue         ldd       $06,s     load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #$0030    is pointer class
                    lbne      CheckContinue no, check for more
                    ldd       $06,s     load the type
                    pshs      d         push as argument
                    lbsr      RemovePtrLevel dereference the type
                    leas      2,s        drop the argument
                    std       $06,s     save the element type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #$0020    is it struct class
                    beq       IllegalLvalErr illegal, report it
                    ldd       $06,s     load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #$0030    is pointer class
                    beq       IllegalLvalErr illegal, report it
                    ldd       $06,s     load the type
                    cmpd      #$0004    is type four
                    beq       IllegalLvalErr illegal, report it
                    ldd       $06,s     load the type
                    cmpd      #$0003    is type three
                    bne       CheckPtrOp2 no, valid element
IllegalLvalErr      leax      MsgFuncTypeError,pcr point to error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    ldd       #$0031    force type code
                    std       ,u        store into node
                    ldd       #$0001    default element type
                    std       $06,s     store the type
CheckPtrOp2         ldd       $0e,s     load the op type
                    cmpd      #$000E    is it pointer op
                    bne       EmitLoad  no, emit a load
                    leax      >GlbVar0047,y  point to work-area field
                    pshs      x         push field pointer
                    lbsr      EndScopeCheck emit into the node
                    leas      2,s        drop the argument
                    bra       CheckContinue go check for more

EmitLoad            ldd       $06,s     load the type
                    std       GlbVar004D store into the type global
                    ldd       $0a,s     load saved value
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      ParseStructDecl emit the load
                    leas      4,s        drop the arguments
                    bra       ParseMulDone go to exit

                    bra       CheckContinue dead fall-through branch

RestoreLocals       leas      -$14,x    restore stack pointer from x
CheckContinue       ldd       GlbVar005F load current token
                    cmpd      #$0030    compare token 0030
                    bne       ExpectParen not that token, expect paren
                    lbsr      ScanToken advance to next token
                    lbra      NextOperand loop for next operand

ExpectParen         ldd       #$0028    open paren expected
                    pshs      d         push expected token
                    lbsr      ExpectToken require the token
                    std       ,s++      pop the argument
                    beq       ParseMulDone got it, go to exit
                    lbsr      SyncDeclarator error recovery
ParseMulDone        leas      20,s       release the locals
                    puls      pc,u      restore frame and return

ParseCastExpr       pshs      u         save caller frame pointer
                    ldd       #$FFA4    stack space required
                    lbsr      stkcheck  check for stack overflow
                    leas      -18,s      allocate local frame
                    lbsr      ParsePostfixOp parse the subexpression
                    std       $10,s     save its type
                    tfr       d,x       copy type into x
                    bra       CheckCastTok test the token

CastErr             leax      MsgArgStorage,pcr push message argument
                    pshs      x         print the error
                    lbsr      PrintErrLoc drop the argument
                    leas      2,s        default cast type
SetCastType         ldd       #$000D    store the type
                    std       $10,s     go combine types
                    bra       CombineCastType store the token

CheckCastTok        stx       -$02,s    zero means default type
                    beq       SetCastType is token 0010
                    cmpx      #$0010    combine types
                    beq       CombineCastType
                    bra       CastErr   otherwise cast error

CombineCastType     leax      ,s        point to local slot
                    pshs      x         push its pointer
                    leax      $0C,s     point to local slot
                    pshs      x         push its pointer
                    leax      $0C,s     point to local slot
                    pshs      x         push its pointer
                    lbsr      ParseDeclSpec resolve and combine types
                    leas      6,s        drop three arguments
                    std       $0e,s     save the result
                    bne       BuildCastType nonzero, continue
                    ldd       #$0001    default result of one
                    std       $0e,s     store the result
BuildCastType       ldd       $0a,s     load saved value
                    std       $0C,s     copy into slot
                    ldd       $0e,s     load combine result
                    pshs      d         push as argument
                    leax      $0e,s     point to local
                    pshs      x         push its pointer
                    leax      $06,s     point to local
                    pshs      x         push its pointer
                    lbsr      ParseTypeSpec compute combined type
                    leas      6,s        drop the arguments
                    std       $04,s     save combined type
                    ldu       $02,s     load node pointer
                    ldd       $04,s     load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #$0030    is pointer class
                    beq       CastTypeErr yes, illegal cast type
                    ldd       $04,s     load the type
                    cmpd      #$0004    is type four
                    beq       CastTypeErr illegal cast type
                    ldd       $04,s     load the type
                    cmpd      #$000A    is type 000A
                    bne       CheckStructClass no, check struct class
CastTypeErr         leax      MsgArgError,pcr point to error message
                    pshs      x         push message argument
                    lbsr      PrintErrLoc print the error
                    leas      2,s        drop the argument
                    bra       CastNoNode go handle missing node

CheckStructClass    ldd       $04,s     load the type
                    clra                clear high byte
                    andb      #$30      mask class bits
                    cmpd      #$0020    is it struct class
                    bne       CheckType5 no, check type five
                    ldd       $04,s     load the type
                    pshs      d         push as argument
                    lbsr      RemovePtrLevel dereference the type
                    std       ,s        store back
                    lbsr      AddPtrLevel get the element type
                    leas      2,s        drop the argument
                    bra       StoreCastType store the cast type

CheckType5          ldd       $04,s     load the type
                    cmpd      #$0005    is type five
                    bne       CheckNullNode no, keep the type
                    ldd       #$0006    promote to type six
StoreCastType       std       $04,s     store the cast type
CheckNullNode       cmpu      #$0000    is the node null
                    bne       EmitCast  no, emit the cast
                    lbsr      ErrIdentMissing report an error
CastNoNode          leax      $12,s     point past the locals
                    lbra      RestoreDeclFrame go to exit

EmitCast            ldd       $04,s     load the type
                    pshs      d         push as argument
                    ldd       $12,s     load a saved value
                    pshs      d         push as argument
                    lbsr      ClassifyType2 build the cast node
                    leas      4,s        drop the arguments
                    std       $06,s     save the node pointer
                    ldx       $08,u     load node op field into x
                    bra       CastOpDispatch dispatch on the op

FillCastNode        ldd       $04,s     load the type
                    std       ,u        store into node
                    ldd       $06,s     load the node pointer
                    std       $08,u     store into node op field
                    ldd       ,s        load a saved value
                    std       $0a,u     store into node field
                    ldd       $08,s     load a saved value
                    pshs      d         push as argument
                    ldd       $0e,s     load the op type
                    pshs      d         push as argument
                    pshs      u         push the node pointer
                    lbsr      SetNodeTypeSize emit the binary operation
                    leas      6,s        drop the arguments
                    std       -$02,s    save the result
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

CastOpDispatch      cmpx      #$000B    is op 000B
                    beq       FillCastNode branch when token type $000B
                    cmpx      #$000D    check for token type $000D
                    beq       CastLvalErr handle the $000D case
                    cmpx      #$0010    check for token type $0010
                    lbeq      CastLvalErr handle $0010 like $000D
                    bra       CastMsgErr otherwise report not an argument

RestoreDeclFrame    leas      -$12,x    restore stack to saved frame base
DeclEndTokChk       ldd       GlbVar005F load current token
                    cmpd      #$0078    check for token $0078
                    bne       DeclOpenBraceChk skip if not that token
                    lbsr      ErrCannotInit report and skip on unexpected token
DeclOpenBraceChk    ldd       GlbVar005F load current token
                    cmpd      #$0030    check for open-brace token $0030
                    bne       DeclExpectClose skip if not
                    lbsr      ScanToken advance to next token
                    lbra      BuildCastType loop back to parse next declaration

DeclExpectClose     ldd       #$0028    expected close token $0028
                    pshs      d         push expected token argument
                    lbsr      ExpectToken match/expect the token
                    std       ,s++      store result and pop argument
                    lbeq      ParseStructExit exit if token matched
                    lbsr      SyncDeclarator consume/handle the token
                    lbra      ParseStructExit return from routine

ParseStructBody     pshs      u         save caller frame pointer
                    ldd       #$FF9E    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    leas      -18,s      allocate local frame
                    lbsr      ParsePostfixOp parse base type and storage class
                    std       $10,s     save returned type
                    tfr       d,x       copy type into X for dispatch
                    bra       StorageClassChk enter declarator dispatch

StorageErr          leax      MsgStorageError2,pcr point to storage error message
                    pshs      x         push message pointer
                    lbsr      PrintErrLoc print the error
                    leas      2,s        pop argument
SetDefaultType2     ldd       #$000D    default type token $000D
                    std       $10,s     store as current type
                    bra       BuildDeclarator continue building declarator

StorageClassChk     cmpx      #$0021    check for invalid storage token $0021
                    beq       StorageErr report storage error
                    stx       -$02,s    save declarator type
                    beq       SetDefaultType2 use default if type was zero
BuildDeclarator     leax      $02,s     point to type slot
                    pshs      x         push type pointer argument
                    leax      $0C,s     point to name buffer
                    pshs      x         push name pointer argument
                    leax      $0C,s     point to declarator argument
                    pshs      x         push declarator pointer argument
                    lbsr      ParseDeclSpec parse the declarator
                    leas      6,s        pop the three arguments
                    std       $0e,s     save declarator result
                    bne       MemberLoop continue if non-null
                    ldd       #$0001    default value 1
                    std       $0e,s     store default declarator
MemberLoop          leas      -6,s       reserve space for arguments
                    ldd       $10,s     load base type
                    std       ,s        set as first argument
                    ldd       $14,s     load declarator name
                    pshs      d         push name argument
                    leax      $02,s     point past pushed word
                    pshs      x         push pointer argument
                    leax      $0e,s     point to type slot
                    pshs      x         push type pointer argument
                    lbsr      ParseTypeSpec declare and install the symbol
                    leas      6,s        pop arguments
                    std       $12,s     save symbol/type result
                    ldu       $0a,s     load existing symbol pointer
                    bne       MemberHasSym branch if symbol already exists
                    ldd       $12,s     load type result
                    cmpd      #$0004    check for type $0004
                    lbeq      MemberCleanup done if plain type
                    ldd       $12,s     reload type result
                    cmpd      #$0003    check for type $0003
                    lbeq      MemberCleanup done if that type
                    lbsr      ErrIdentMissing report undefined type error
                    lbra      MemberCleanup done with member

MemberHasSym        ldd       $12,s     load member type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0030    check for class $0030
                    beq       SetNewSymbol handle that storage class
                    ldd       $16,s     load token/class field
                    cmpd      #$000E    check for token $000E
                    bne       ClassifyMember branch to redeclare handling
SetNewSymbol        ldd       ,u        load existing symbol type
                    bne       CheckRedeclType branch if already defined
                    ldd       $12,s     load new type
                    std       ,u        set symbol type
                    ldd       #$000E    mark class $000E
                    std       $08,u     store class into symbol
                    clra                zero high byte
                    clrb                zero low byte
                    std       $0C,u     clear symbol offset
                    ldd       $08,s     load size/value
                    std       $0a,u     store into symbol
                    ldd       $0e,s     load declarator
                    pshs      d         push argument
                    ldd       $02,s     load extra field
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      SetNodeTypeSize emit and record symbol
                    bra       MemberEmitDone continue after emit

CheckRedeclType     ldd       $08,s     load value
                    pshs      d         push argument
                    ldd       $14,s     load name
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      CheckTypeMatch check declared type matches
MemberEmitDone      leas      6,s        pop arguments
                    bra       MemberCleanup done with member

ClassifyMember      ldd       $12,s     load type
                    pshs      d         push argument
                    ldd       $18,s     load extra field
                    pshs      d         push argument
                    lbsr      ClassifyType2 classify the member type
                    leas      4,s        pop arguments
                    std       $04,s     save classified type
                    ldd       ,u        load existing symbol type
                    beq       InstallSymbol branch if new symbol
                    ldd       $0C,u     load symbol scope level
                    cmpd      GlbVar0051 compare with current block level
                    bne       HideOuterSym branch if different scope
                    lbsr      ReportMsgErr report redefinition
MemberCleanup       leax      $18,s     compute frame base
                    lbra      FrameRestore18 clean up stack and exit

HideOuterSym        pshs      u         push old symbol pointer
                    lbsr      AllocNode unlink outer-scope symbol
                    leas      2,s        pop argument
InstallSymbol       ldd       $12,s     load type
                    std       ,u        set symbol type
                    ldd       $04,s     load classified type
                    std       $08,u     store class into symbol
                    ldd       $08,s     load value/size
                    std       $0a,u     store into symbol
                    ldd       GlbVar0051 load current block level
                    std       $0C,u     record symbol scope
                    ldd       GlbVar004B load current symbol-list head
                    std       $10,u     link previous head
                    stu       GlbVar004B make this symbol the head
                    ldd       $0e,s     load declarator
                    pshs      d         push argument
                    ldd       $02,s     load extra field
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      SetNodeTypeSize emit and record symbol
                    leas      6,s        pop arguments
                    std       $02,s     save emit result
                    bne       LoadClassType branch if success
                    ldd       GlbVar005F load current token
                    cmpd      #$0078    check for token $0078
                    beq       LoadClassType skip error if match
                    lbsr      ErrCannotEvalSize report emit error
LoadClassType       ldx       $04,s     load classified type into X
                    bra       OffsetTypeChk dispatch on member type

StructOffsetAdj     ldd       GlbVar0031 load current struct offset
                    subd      $02,s     subtract member size
                    std       GlbVar0031 update struct offset
                    ldd       GlbVar0031 reload offset value
                    bra       StoreSymOffset store as symbol offset

BumpFieldCount      ldd       GlbVar002B load field counter
                    addd      #$0001    increment counter
                    std       GlbVar002B update field counter
StoreSymOffset      std       $06,u     store offset into symbol
                    bra       TypedefCtxChk continue after offset

OffsetTypeChk       cmpx      #$000D    check for type $000D
                    beq       StructOffsetAdj handle struct-member offset
                    cmpx      #$0023    check for type $0023
                    beq       BumpFieldCount handle enum counter
                    cmpx      #$000F    check for type $000F
                    lbeq      BumpFieldCount handle like $0023
TypedefCtxChk       ldd       GlbVar005F load current token
                    cmpd      #$0078    check for token $0078
                    lbne      ClassDispatch branch if not typedef context
                    ldd       $04,s     load classified class
                    cmpd      #$000F    check for class $000F
                    beq       RegisterTypedef handle typedef
                    ldd       $04,s     reload class
                    cmpd      #$0023    check for class $0023
                    bne       PtrMemberAlloc branch if not
RegisterTypedef     ldd       $12,s     load type
                    pshs      d         push argument
                    ldd       $06,s     load symbol offset
                    pshs      d         push argument
                    pshs      u         push symbol pointer
                    lbsr      ParseInitializer register the typedef
ArgPopContinue      leas      6,s        pop arguments
                    lbra      NextMemberChk continue after typedef

PtrMemberAlloc      lbsr      ScanToken advance to next token
                    ldd       $12,s     load type
                    clra                clear high byte
                    andb      #$30      isolate storage-class bits
                    cmpd      #$0020    check for class $0020
                    lbeq      MemberErr2 report on invalid class
                    ldd       $12,s     reload type
                    cmpd      #$0004    check for type $0004
                    lbeq      MemberErr2 report error on that type
                    ldd       #$0002    allocate 2 bytes
                    pshs      d         push size argument
                    lbsr      ParseExpr allocate a node
                    leas      2,s        pop argument
                    std       $0C,s     save node pointer
                    beq       MemberErr2 error if allocation failed
                    ldd       GlbVar0009 load free-list head
                    beq       AllocNode2 branch if free list empty
                    ldd       GlbVar0009 reload free head
                    std       $06,s     save reused node pointer
                    tfr       d,x       node into X
                    ldd       ,x        load next link
                    std       GlbVar0009 advance the free list
                    clra                zero high byte
                    clrb                zero low byte
                    std       [$06,s]   clear the node link
                    bra       LinkNode2 continue with node

AllocNode2          ldd       #$0006    request 6-byte node
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate the node
                    leas      2,s        pop argument
                    std       $06,s     save node pointer
LinkNode2           ldd       $0C,s     load data pointer
                    ldx       $06,s     load node pointer
                    std       $02,x     store data into node
                    ldx       $06,s     reload node pointer
                    stu       $04,x     store symbol pointer into node
                    ldd       GlbVar0005 load list tail
                    beq       SetListHead branch if list empty
                    ldd       $06,s     load node pointer
                    std       [>GlbVar0007,y] link node onto tail
                    bra       SetListTail continue

SetListHead         ldd       $06,s     load node pointer
                    std       GlbVar0005 set list head
SetListTail         ldd       $06,s     load node pointer
                    std       GlbVar0007 set list tail
                    bra       NextMemberChk continue after link

MemberErr2          lbsr      ErrCannotInit report and skip on error
                    bra       NextMemberChk continue after error

ClassDispatch       ldx       $04,s     load class into X
                    bra       EnumClassChk dispatch on class

RecordEnumMember    ldd       $04,s     load class
                    cmpd      #$0023    check for class $0023
                    bne       ZeroEnumFlag branch if not
                    ldd       #$0001    flag value 1
                    bra       PushEnumArgs use the flag

ZeroEnumFlag        clra                zero high byte
                    clrb                zero flag value
PushEnumArgs        pshs      d         push flag argument
                    ldd       $04,s     load class
                    pshs      d         push class argument
                    ldd       $06,u     load symbol offset
                    pshs      d         push offset argument
                    lbsr      EmitRmbVar record enum member
                    lbra      ArgPopContinue continue after record

EnumClassChk        cmpx      #$000F    check for class $000F
                    beq       RecordEnumMember handle enum member
                    cmpx      #$0023    check for class $0023
                    lbeq      RecordEnumMember handle enum member
                    bra       NextMemberChk otherwise continue

FrameRestore18      leas      -$18,x    restore stack to frame base
NextMemberChk       ldd       GlbVar005F load current token
                    cmpd      #$0030    check for open-brace $0030
                    beq       AdvanceNextMember loop for another member
                    leas      6,s        pop locals
                    bra       ExpectCloseBrace finish the declaration

AdvanceNextMember   lbsr      ScanToken advance to next token
                    leas      6,s        pop locals
                    lbra      MemberLoop parse the next member

ExpectCloseBrace    ldd       #$0028    expected close token $0028
                    pshs      d         push expected token
                    lbsr      ExpectToken match/expect the token
                    leas      2,s        pop argument
ParseStructExit     leas      18,s       release local frame
                    puls      pc,u      restore frame and return

CheckTypeMatch      pshs      u         save caller frame pointer
                    ldd       #$FFBA    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    ldu       $04,s     load symbol pointer argument
                    ldd       ,u        load existing type
                    cmpd      $06,s     compare with new type
                    bne       DeclMismatchErr mismatch if different
                    ldd       $06,s     load new type
                    cmpd      #$0004    check for type $0004
                    bne       TypeMatchOk match if not $0004
                    ldd       $0a,u     load existing size
                    cmpd      $08,s     compare with new size
                    beq       TypeMatchOk match if sizes equal
DeclMismatchErr     leax      MsgDeclMismatch,pcr point to declaration mismatch message
                    pshs      x         push message pointer
                    lbsr      PrintErrLoc print the error
                    leas      2,s        pop argument
                    ldd       #$0001    return mismatch flag 1
                    puls      pc,u      restore frame and return

TypeMatchOk         clra                zero high byte
                    clrb                return 0 for match
                    puls      pc,u      restore frame and return

ClassifyType2       pshs      u         save caller frame pointer
                    ldd       #$FFC0    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    ldd       $04,s     load type argument
                    cmpd      #$0010    check for type $0010
                    bne       RetInputType branch if not $0010
                    ldd       GlbVar0003 load nesting depth
                    cmpd      #$0001    compare with one
                    bge       RetTypeCR branch if already nested
                    ldx       $06,s     load class argument into X
                    bra       NestClassChk dispatch on class

ClassBitsChk        ldd       $06,s     load class
                    clra                clear high byte
                    andb      #$30      isolate class bits
                    cmpd      #$0010    check for class $0010
                    bne       RetTypeCR branch if not
IncNestDepth        ldd       GlbVar0003 load nesting depth
                    addd      #$0001    increment depth
                    std       GlbVar0003 update nesting depth
                    cmpd      #$0001    compare with one
                    bne       NestTokenAlt branch if deeper
                    ldd       #$006F    return token $006F
                    bra       ClassifyRet go return it

NestTokenAlt        ldd       #$0076    return token $0076
ClassifyRet         puls      pc,u      restore frame and return

NestClassChk        cmpx      #$0001    check for class $0001
                    beq       IncNestDepth handle nesting
                    cmpx      #$0007    check for class $0007
                    lbeq      IncNestDepth handle nesting
                    bra       ClassBitsChk otherwise test class bits

RetTypeCR           ldd       #$000D    return type token $000D
                    puls      pc,u      restore frame and return

RetInputType        ldd       $04,s     return input type unchanged
                    puls      pc,u      restore frame and return

ParseStructDecl     pshs      u         save caller frame pointer
                    ldd       #$FFAC    request stack frame space
                    lbsr      stkcheck  verify stack space available
                    leas      -10,s      allocate local frame
                    ldd       #$0001    initial block level 1
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
                    cmpd      #$0029    check for close-paren $0029
                    bne       StructMemberLoop keep parsing until close
                    ldd       $0e,s     load aggregate size field
                    addd      #$0014    add offset of 20
                    std       $02,s     save pointer
                    ldd       GlbVar0037 load aggregate flag
                    beq       SetAggFlag skip if flag not set
                    ldd       GlbVar002B load member count
                    addd      #$0001    increment count
                    std       GlbVar002B update member count
                    std       ,s        save count
                    pshs      d         push argument
                    ldd       $04,s     load extra field
                    pshs      d         push argument
                    lbsr      EmitPublicLabel record aggregate size
                    leas      4,s        pop arguments
SetAggFlag          ldd       ,s        load saved value
                    pshs      d         push argument
                    ldd       $12,s     load aggregate type
                    cmpd      #$000F    check for type $000F
                    beq       UnionFlagZero branch if union
                    ldd       #$0001    flag 1 for struct
                    bra       FinalizeAgg use the flag

UnionFlagZero       clra                zero high byte
                    clrb                zero flag for union
FinalizeAgg         pshs      d         push flag argument
                    ldd       $06,s     load extra field
                    pshs      d         push argument
                    lbsr      EmitStaticSym finalize aggregate type
                    leas      6,s        pop arguments
                    ldu       GlbVar0047 load member list head
                    ldd       #$0004    initial running size 4
                    std       $08,s     save running size
                    lbra      FieldOffsetLoop enter member sizing loop

SizeMemberLoop      leas      -2,s       reserve temp slot
                    ldd       $0a,s     load running offset
                    std       $06,u     store member offset
                    ldx       ,u        load member type
                    bra       MemberTypeChk dispatch on member type

MemberSize4         ldd       #$0004    size 4 bytes
                    bra       StoreMemberSize set member size

MemberSize8         ldd       #$0008    size 8 bytes
                    bra       StoreMemberSize set member size

BitfieldOffset      ldd       $06,u     load member offset
                    addd      #$0001    increment offset
                    std       $06,u     update member offset
MemberSize2         ldd       #$0002    size 2 bytes
StoreMemberSize     std       ,s        save member size
                    bra       LoadSubtype continue after size

MemberTypeChk       cmpx      #$0008    check for type $0008
                    beq       MemberSize4 size as 4 bytes
                    cmpx      #$0005    check for type $0005
                    lbeq      MemberSize4 size as 4 bytes
                    cmpx      #$0006    check for type $0006
                    beq       MemberSize8 size as 8 bytes
                    cmpx      #$0002    check for type $0002
                    beq       BitfieldOffset handle bitfield offset case
                    bra       MemberSize2 default size 2 bytes

LoadSubtype         ldd       $08,u     load member subtype
                    std       $08,s     save subtype
                    tfr       d,x       subtype into X
                    bra       MatchTypeKw dispatch on subtype

ComputeNestedSize   ldd       $0a,s     load argument
                    pshs      d         push argument
                    ldd       $0a,s     load argument
                    pshs      d         push argument
                    lbsr      EmitOpCode compute nested aggregate size
                    leas      4,s        pop arguments
                    bra       AddFieldOffset continue after size

SubtypeCR           ldd       #$000D    default subtype token $000D
                    std       $08,u     store member subtype
                    bra       AddFieldOffset jump into the offset accumulation

MatchTypeKw         cmpx      #$006F    compare token against type keyword $6f
                    beq       ComputeNestedSize matched, go handle it
                    cmpx      #$0076    compare token against type keyword $76
                    lbeq      ComputeNestedSize matched, go handle it
                    cmpx      #$000B    compare token against type code $0b
                    beq       SubtypeCR matched, go handle it
AddFieldOffset      ldd       $0a,s     load the accumulated offset
                    addd      ,s        add the current field size
                    std       $0a,s     store the updated offset
                    ldu       $10,u     follow the link to the next entry
                    leas      2,s        drop the temporary
FieldOffsetLoop     stu       -$02,s    save the next entry pointer
                    lbne      SizeMemberLoop loop while more entries remain
                    ldd       GlbVar0047 load the saved global
                    std       $04,s     stash it in a local
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar0047 clear the global
                    lbsr      ParseBlock2 parse the block body
                    leax      $04,s     point at the saved value
                    pshs      x         pass it as an argument
                    lbsr      EndScopeCheck free/restore it
                    leas      2,s        drop the argument
                    leax      >GlbVar0049,y  point at global $0049
                    pshs      x         pass it as an argument
                    lbsr      EndScopeCheck free/restore it
                    leas      2,s        drop the argument
                    ldd       GlbVar004F load the current context type
                    cmpd      #$0012    is it type $12
                    beq       ResetContextType skip the emit if so
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       #$0012    push type code $12
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

ParseBlock2         pshs      u         save caller frame pointer
                    ldd       #$FFAA    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -6,s       allocate the locals
                    ldd       GlbVar004B load the current global
                    std       $02,s     save it in a local
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004B clear the global
                    lbsr      ScanToken get the next token
                    ldd       GlbVar0051 load the block nesting level
                    addd      #$0001    increment it
                    std       GlbVar0051 store deeper nesting level
                    ldd       GlbVar0031 load the current frame offset
                    std       ,s        save the base offset
                    bra       StmtLoopTop enter the statement loop

StmtLoop2           lbsr      ParseStructBody parse a statement
StmtLoopTop         lbsr      IsQualifierKw parse a declaration
                    std       -$02,s    save the result
                    bne       StmtLoop2 loop if one was parsed
                    lbsr      ClassifyType parse a statement
                    std       -$02,s    save the result
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
                    std       $04,s     save it in a local
                    ldx       $04,s     point at the entry
                    ldu       $02,x     follow the entry link
                    ldd       $10,u     load a node field
                    pshs      d         push it as argument
                    ldd       $0e,u     load a node field
                    pshs      d         push it as argument
                    ldx       $08,s     point at the saved entry
                    ldd       $04,x     load its field
                    pshs      d         push it as argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldd       #$0034    push node type $34
                    pshs      d         push it as argument
                    lbsr      NewExprNode build a tree node
                    leas      12,s       drop the arguments
                    tfr       d,u       keep the node pointer
                    ldd       $10,u     load a node field
                    pshs      d         push it as argument
                    ldd       $0e,u     load a node field
                    pshs      d         push it as argument
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero argument
                    ldx       $0a,s     point at the saved entry
                    ldd       $02,x     load its field
                    pshs      d         push it as argument
                    pshs      u         push the node pointer
                    ldd       #$0078    push node type $78
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
                    ldd       [$04,s]   load the next list link
                    std       $04,s     save it in a local
                    ldd       GlbVar0009 load a global value
                    std       [>GlbVar0005,y] store it into the entry
                    ldd       GlbVar0005 load the list head
                    std       GlbVar0009 save it in the global
                    ldd       $04,s     reload the next link
                    std       GlbVar0005 advance the list head
LocalListTop        ldd       GlbVar0005 is the local list nonempty
                    lbne      FreeLocalLoop loop for the next local
                    bra       SkipToBraceTop list drained, continue

SkipToBrace         lbsr      ParseStatement skip a stray construct
SkipToBraceTop      ldd       GlbVar005F load the current token
                    cmpd      #$002A    is it a close brace
                    beq       RestoreScope done if so
                    ldd       GlbVar005F reload the token
                    cmpd      #$FFFF    is it end of file
                    bne       SkipToBrace keep skipping until then
RestoreScope        leax      >GlbVar004B,y  point at global $004b
                    pshs      x         pass it as argument
                    lbsr      EndScopeCheck free/restore it
                    leas      2,s        drop the argument
                    ldd       $02,s     load the saved global value
                    std       GlbVar004B restore the global
                    ldd       GlbVar0051 load the block nesting level
                    addd      #$FFFF    decrement it
                    std       GlbVar0051 store shallower nesting level
                    ldd       ,s        load the saved base offset
                    std       GlbVar0031 restore the current offset
                    ldd       GlbVar004F load the context type
                    cmpd      #$0012    is it type $12
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

ParseIdentList      pshs      u         save caller frame pointer
                    ldd       #$FFB8    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate the local
                    clra                zero high byte
                    clrb                zero low byte
                    std       [$06,s]   clear the caller's list pointer
IdentLoop           lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$002E    is it a semicolon
                    lbeq      ExpectSemi2 end of the list
                    ldd       GlbVar005F reload the token
                    cmpd      #$0034    is it an identifier
                    bne       ParseMemberDecl not identifier, parse member
                    ldu       GlbVar0061 load the symbol pointer
                    ldd       $08,u     load its type field
                    cmpd      #$000B    is it type $0b
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
InitIdentSym        ldd       #$0001    mark the symbol defined
                    std       ,u        store the flag
                    ldd       #$000B    set type code $0b
                    std       $08,u     store it in the symbol
                    ldd       #$0001    set field value 1
                    std       $0C,u     store it in the symbol
                    ldd       #$0002    set storage class 2
                    std       $02,u     store it in the symbol
                    ldd       [$06,s]   load the current list head
                    beq       SetListHead2 empty, set first node
                    ldx       ,s        point at the last node
                    stu       $10,x     link the new node in
                    bra       LinkDone2 skip the head assignment

SetListHead2        stu       [$06,s]   store node as the list head
LinkDone2           clra                zero high byte
                    clrb                zero low byte
                    std       $10,u     clear the node link
                    stu       ,s        remember node as last
                    lbsr      ScanToken get the next token
                    bra       CheckComma go check for a comma

ParseMemberDecl     lbsr      ErrIdentMissing parse a member declaration
CheckComma          ldd       GlbVar005F load the current token
                    cmpd      #$0030    is it a comma
                    lbeq      IdentLoop loop for the next member
ExpectSemi2         ldd       #$002E    expect a semicolon
                    pshs      d         pass it as argument
                    lbsr      ExpectToken require the token
                    leas      2,s        drop the argument
                    bra       EpilogueDrop2 return via shared epilogue

ParsePostfixOp      pshs      u         save caller frame pointer
                    ldd       #$FFBA    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       allocate the local
                    lbsr      IsQualifierKw parse a declarator
                    std       -$02,s    save the result
                    beq       ReturnZero none, return zero
                    ldd       GlbVar0061 load the token value
                    std       ,s        save the node
                    lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0033    is it operator token $33
                    bne       ReturnNode no, return the node
                    ldd       GlbVar0061 load the token value
                    cmpd      #$0021    is it keyword $21
                    bne       ReturnNode no, return the node
                    ldx       ,s        load the saved node
                    bra       CheckNodeKind go inspect its kind

UseOp23             ldd       #$0023    choose operator code $23
                    bra       StoreOp   store it

UseOp22             ldd       #$0022    choose operator code $22
StoreOp             std       ,s        store the chosen operator
                    bra       AdvanceOp consume the operator token

CheckNodeKind       cmpx      #$000F    is the node kind $0f
                    beq       UseOp23   use operator $23
                    cmpx      #$000E    is the node kind $0e
                    beq       UseOp22   use operator $22
AdvanceOp           lbsr      ScanToken consume the operator token
ReturnNode          ldd       ,s        load the result node
                    bra       EpilogueDrop2 return it

ReturnZero          clra                zero high byte
                    clrb                zero low byte
EpilogueDrop2       leas      2,s        release the local
                    puls      pc,u      return to caller

ParseDeclSpec       pshs      u         save caller frame pointer
                    ldd       #$FF98    frame size marker for stack check
                    lbsr      stkcheck  verify stack space
                    leas      -26,s      allocate the locals
                    clra                zero high byte
                    clrb                zero low byte
                    std       $02,s     clear the type field
                    ldd       #$0002    default storage class 2
                    std       ,s        store it
                    clra                zero high byte
                    clrb                zero low byte
                    std       [$22,s]   clear the caller's output pointer
                    ldd       GlbVar005F load the current token
                    cmpd      #$0033    is it keyword token $33
                    lbne      TryTypedefName no, handle elsewhere
                    ldd       GlbVar0061 load the token value
                    std       $02,s     save it as the type
                    tfr       d,x       copy it into index register
                    lbra      TokenTypeDispatch jump into the specifier handling

SpecClass1          ldd       #$0001    select storage class 1
                    std       $02,s     store it
SpecLoop            lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0033    is it keyword token $33
                    lbne      ReturnNoType no, specifiers done
                    ldd       GlbVar0061 load the token value
                    cmpd      #$0001    is it keyword $01
                    lbne      ReturnNoType no, specifiers done
                    bra       NextSpecTok consume it as a specifier

SpecBaseInt         ldd       #$0001    select base type 1
                    bra       SetBaseType store it

SpecTypedef         lbsr      ScanToken get the next token
                    ldd       #$0004    select base type 4
                    std       ,s        store it
                    ldd       GlbVar005F load the current token
                    cmpd      #$0033    is it keyword token $33
                    lbne      ReturnNoType no, specifiers done
                    ldd       GlbVar0061 load the token value
                    cmpd      #$0001    is it keyword $01
                    beq       NextSpecTok consume it as a specifier
                    ldd       GlbVar0061 reload the token value
                    cmpd      #$0005    is it keyword $05
                    lbne      ReturnNoType no, specifiers done
SpecLong            ldd       #$0006    set modifier code $06
                    std       $02,s     store the type modifier
                    ldd       #$0008    select base type 8 for long
                    bra       SetBaseType store it

SpecBase4           ldd       #$0004    select base type 4
SetBaseType         std       ,s        store the base type
NextSpecTok         lbsr      ScanToken get the next token
                    lbra      ReturnNoType continue the specifier loop

SpecVoid            clra                zero high byte
                    clrb                zero low byte
                    std       $02,s     clear the type for void
                    lbra      ReturnNoType continue the specifier loop

ParseStructSpec     clra                zero high byte
                    clrb                zero low byte
                    std       $16,s     clear the struct pointer
                    std       ,s        clear the base type
                    ldd       GlbVar0041 load the lookup-suppress flag
                    addd      #$0001    increment it
                    std       GlbVar0041 suppress ordinary lookup
                    clra                zero high byte
                    clrb                zero low byte
                    std       $18,s     clear the tag symbol
                    lbsr      ScanToken get the next token
                    ldd       GlbVar0041 reload the flag
                    addd      #$FFFF    decrement it
                    std       GlbVar0041 restore ordinary lookup
                    ldd       GlbVar005F load the current token
                    cmpd      #$0034    is it an identifier
                    lbne      ExpectBrace no tag, expect a brace
                    ldd       GlbVar0061 load the symbol pointer
                    std       $18,s     save it as the tag symbol
                    ldd       [$18,s]   load its defined flag
                    bne       CheckTagType already known tag
                    ldd       #$000A    mark the tag defined
                    std       [$18,s]   store the flag
                    ldd       #$0008    struct type code $08
                    ldx       $18,s     point at the tag symbol
                    std       $08,x     set its type field
                    bra       TagBodyOrRef go parse the body or reference

CheckTagType        ldx       $18,s     point at the tag symbol
                    ldd       $08,x     load its existing type
                    cmpd      #$0008    is it a struct type
                    beq       TagBodyOrRef ok, continue
                    leax      MsgNameClash,pcr point at the conflict message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the tag conflict
                    leas      2,s        drop the argument
TagBodyOrRef        lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0029    is it an open brace
                    beq       CheckComplete yes, parse the body
                    ldd       [$18,s]   load the tag state
                    cmpd      #$0004    is it a complete type
                    bne       ReturnTagRef no, return a tag reference
                    ldx       $18,s     point at the tag symbol
                    ldd       $02,x     load its member list
                    std       [$1e,s]   return via the output pointer
                    ldx       $18,s     point at the tag symbol
                    ldd       $0a,x     load its size
                    std       [$22,s]   return via the output pointer
                    ldd       #$0004    result type code $04
                    lbra      ReturnType2 return the result

ReturnTagRef        ldd       $18,s     load the tag symbol
                    std       [$1e,s]   return via the output pointer
                    ldd       #$000A    result type code $0a
                    lbra      ReturnType2 return the result

CheckComplete       ldd       [$18,s]   load the tag state
                    cmpd      #$0004    is it already complete
                    bne       ExpectBrace no, parse the body
                    lbsr      ReportMsgErr report the tag redefinition
ExpectBrace         ldd       GlbVar005F load the current token
                    cmpd      #$0029    is it an open brace
                    beq       EnterStructBody yes, parse the members
                    leax      MsgStructSyntax,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the missing brace
                    leas      2,s        drop the argument
                    lbra      ReturnNoType return through the loop tail

EnterStructBody     ldd       GlbVar0041 load the lookup-suppress flag
                    addd      #$0001    increment it
                    std       GlbVar0041 enter the member scope
MemberLoop2         ldd       GlbVar0041 reload the flag
                    std       $10,s     save it in a local
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar0041 clear the flag for lookup
                    lbsr      ScanToken get the next token
                    ldd       $10,s     reload the saved flag
                    std       GlbVar0041 restore the flag
                    ldd       GlbVar005F load the current token
                    cmpd      #$002A    is it a close brace
                    lbeq      CloseTypeScope end of the member list
                    leax      $04,s     point at a local
                    pshs      x         pass it as argument
                    leax      $0e,s     point at a local
                    pshs      x         pass it as argument
                    leax      $18,s     point at a local
                    pshs      x         pass it as argument
                    lbsr      ParseDeclSpec recurse to parse the member type
                    leas      6,s        drop the arguments
                    std       $12,s     save the member type
                    bra       MemberNext process the member

MemberNext          leas      -4,s       allocate a temporary
                    ldd       $10,s     load the saved flag
                    std       $02,s     save it in a local
                    ldd       GlbVar005F load the current token
                    cmpd      #$0028    is it token $28
                    lbeq      DropTagLocals handle it specially
                    ldd       GlbVar0051 load the block nesting level
                    addd      #$0001    increment it
                    std       GlbVar0051 store deeper nesting level
                    ldd       $16,s     load a member field
                    pshs      d         push it as argument
                    leax      $04,s     point at a local
                    pshs      x         pass it as argument
                    leax      $04,s     point to local argument slot
                    pshs      x         pass pointer argument
                    lbsr      ParseTypeSpec parse the struct/union type specifier
                    leas      6,s        drop the pushed arguments
                    std       $12,s     save the returned type
                    ldu       ,s        reload the tag entry pointer
                    ldd       GlbVar0051 load the current nesting level
                    addd      #$FFFF    decrement the nesting level
                    std       GlbVar0051 store the nesting level
                    cmpu      #$0000    test the tag entry pointer for null
                    bne       CheckExistingTag branch if a tag entry exists
                    lbsr      ErrIdentMissing handle the missing tag entry
                    leax      $1e,s     compute the stack cleanup pointer
                    lbra      RestoreStackX jump to restore the stack

CheckExistingTag    ldd       ,u        load the first tag entry field
                    beq       FillTagEntry branch if the slot is empty
                    ldd       $0C,u     load the entry nesting level
                    cmpd      GlbVar0051 compare with the current level
                    bne       FreeOldTag branch if a different scope
                    ldd       ,u        load the entry type
                    cmpd      $12,s     compare with the parsed type
                    bne       TagRedefinedErr branch on redefinition mismatch
                    ldd       $08,u     load the entry kind field
                    cmpd      #$0011    compare with the struct kind
                    bne       TagRedefinedErr branch if kind mismatch
                    ldd       $06,u     load the entry tag id
                    cmpd      $1a,s     compare with the current tag id
                    beq       FillTagEntry branch if the same tag is reused
TagRedefinedErr     leax      MsgStructMemberMismatch,pcr point to the redefinition message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc print the error message
                    bra       AfterTagError continue after the error

FreeOldTag          pshs      u         pass the old entry pointer
                    lbsr      AllocNode free the old tag entry
AfterTagError       leas      2,s        drop the pushed argument
FillTagEntry        ldd       $12,s     load the parsed type
                    cmpd      #$000A    compare with the enum type
                    bne       StoreTagFields branch if not an enum
                    leax      MsgUndefStructure,pcr point to the warning message
                    pshs      x         pass the message pointer
                    lbsr      PrintErrLoc print the message
                    leas      2,s        drop the argument
StoreTagFields      ldd       $12,s     load the parsed type
                    std       ,u        store the type in the entry
                    ldd       #$0011    load the struct kind constant
                    std       $08,u     set the entry kind field
                    ldd       $1a,s     load the tag id
                    std       $06,u     store the tag id in the entry
                    ldd       $08,s     load the member list pointer
                    std       $0a,u     store the member list in the entry
                    ldd       $18,s     load the layout argument
                    pshs      d         push the argument
                    ldd       $04,s     load the layout argument
                    pshs      d         push the argument
                    pshs      u         push the entry pointer
                    lbsr      SetNodeTypeSize compute the member layout size
                    leas      6,s        drop the arguments
                    std       $0e,s     save the returned size
                    beq       EmptyTagBody branch if zero size
                    ldd       $06,s     load the member class
                    cmpd      #$0004    compare with the union class
                    bne       MaxMemberSize branch if not a union
                    ldd       $1a,s     load the current offset
                    addd      $0e,s     add the member size
                    std       $1a,s     update the offset
                    bra       StoreMemberSize2 go store the size

MaxMemberSize       ldd       $0e,s     load the member size
                    cmpd      $04,s     compare with the running maximum
                    ble       KeepCurMax branch if not larger
                    ldd       $0e,s     take the member size
                    bra       StoreMemberSize2 store it as the new maximum

KeepCurMax          ldd       $04,s     keep the current maximum
StoreMemberSize2    std       $04,s     store the size or maximum
                    bra       LinkTagEntry continue

EmptyTagBody        lbsr      ErrCannotEvalSize handle the empty member body
LinkTagEntry        ldd       GlbVar0051 load the nesting level
                    std       $0C,u     store the level in the entry
                    ldd       GlbVar004B load the symbol list head
                    std       $10,u     chain it into the entry
                    stu       GlbVar004B make the entry the new list head
                    ldd       $06,s     load the member class
                    cmpd      #$0004    compare with the union class
                    bne       AfterTagBody branch if not a union
                    ldd       #$0004    allocation size for a node
                    pshs      d         push the size
                    lbsr      AllocMem  allocate a list node
                    leas      2,s        drop the argument
                    std       $0C,s     save the node pointer
                    ldx       $0C,s     reload the node pointer
                    stu       $02,x     store the entry in the node
                    ldd       [$26,s]   load the list head indirectly
                    beq       SetUnionHead branch if the list is empty
                    ldd       $0C,s     load the node pointer
                    std       [$0a,s]   append the node to the tail
                    bra       UpdateUnionTail continue

SetUnionHead        ldd       $0C,s     load the node pointer
                    std       [$26,s]   set the list head
UpdateUnionTail     ldd       $0C,s     load the node pointer
                    std       $0a,s     update the tail pointer
                    bra       AfterTagBody continue

RestoreStackX       leas      -$1e,x    restore the stack from the pointer
AfterTagBody        ldd       GlbVar005F load the current token
                    cmpd      #$0030    compare with the comma token
                    beq       NextDeclarator branch if a comma follows
DropTagLocals       leas      4,s        drop the tag locals
                    bra       CheckDeclEnd continue

NextDeclarator      lbsr      ScanToken advance to the next token
                    leas      4,s        drop the tag locals
                    lbra      MemberNext loop for the next declarator

CheckDeclEnd        ldd       GlbVar005F load the current token
                    cmpd      #$0028    compare with the semicolon token
                    lbeq      MemberLoop2 loop if the declaration ends
CloseTypeScope      ldd       GlbVar0041 load the scope counter
                    addd      #$FFFF    decrement the scope counter
                    std       GlbVar0041 store the counter
                    ldd       $18,s     load the list pointer
                    beq       EmitTypeEnd branch if null
                    ldd       ,s        load the value to store
                    ldx       $18,s     load the list pointer
                    std       $02,x     store the field
                    ldd       #$0004    load the type constant
                    std       [$18,s]   store the type indirectly
                    ldd       [$22,s]   load the field value
                    ldx       $18,s     load the list pointer
                    std       $0a,x     store the field
EmitTypeEnd         ldd       #$002A    load the closing type opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the instruction
                    leas      2,s        drop the argument
                    bra       ReturnNoType go return the type

TokenTypeDispatch   cmpx      #$000A    compare the token subtype
                    lbeq      SpecClass1 dispatch to the handler
                    cmpx      #$0007    compare the token subtype
                    lbeq      SpecLoop  dispatch to the handler
                    cmpx      #$0002    compare the token subtype
                    lbeq      SpecBaseInt dispatch to the handler
                    cmpx      #$0001    compare the token subtype
                    lbeq      NextSpecTok dispatch to the handler
                    cmpx      #$0008    compare the token subtype
                    lbeq      SpecTypedef dispatch to the handler
                    cmpx      #$0006    compare the token subtype
                    lbeq      SpecLong  dispatch to the handler
                    cmpx      #$0005    compare the token subtype
                    lbeq      SpecBase4 dispatch to the handler
                    cmpx      #$0003    compare the token subtype
                    lbeq      ParseStructSpec dispatch to the handler
                    cmpx      #$0004    compare the token subtype
                    lbeq      ParseStructSpec dispatch to the handler
                    lbra      SpecVoid  take the default case

TryTypedefName      ldd       GlbVar005F load the current token
                    cmpd      #$0034    compare with the identifier token
                    bne       ReturnNoType branch if not an identifier
                    ldu       GlbVar0061 load the token symbol pointer
                    ldd       $08,u     load the symbol kind
                    cmpd      #_start   compare with the typedef marker
                    bne       ReturnNoType branch if not a typedef
                    ldd       $02,u     load the typedef type
                    std       [$1e,s]   return the type indirectly
                    ldd       $04,u     load the typedef field
                    std       [$20,s]   return the field indirectly
                    ldd       $0a,u     load the typedef size
                    std       [$22,s]   return the size indirectly
                    lbsr      ScanToken advance to the next token
                    ldd       ,u        load the symbol value
                    bra       ReturnType2 go return the type

ReturnNoType        ldd       ,s        load the result value
                    std       [$1e,s]   return the type indirectly
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       [$20,s]   clear the field return
                    ldd       $02,s     load the result value
ReturnType2         leas      26,s       deallocate the frame
                    puls      pc,u      restore and return

ParseTypeSpec       pshs      u         save the u register
                    ldd       #$FFAA    load the frame size
                    lbsr      stkcheck  check the stack space
                    leas      -12,s      allocate the local frame
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       [$10,s]   clear the output type
                    std       $0a,s     clear the flags accumulator
                    bra       TypeSpecLoop enter the type loop

MergeQualifier      ldd       $0a,s     load the type flags
                    pshs      d         push the flags
                    lbsr      AddPtrLevel merge the qualifier
                    leas      2,s        drop the argument
                    std       $0a,s     store the updated flags
                    lbsr      ScanToken advance to the next token
TypeSpecLoop        ldd       GlbVar005F load the current token
                    cmpd      #$0042    compare with the qualifier token
                    beq       MergeQualifier loop if a qualifier
                    ldd       GlbVar005F load the current token
                    cmpd      #$0034    compare with the identifier token
                    bne       CheckStructKw branch if not an identifier
                    ldd       GlbVar0061 load the symbol pointer
                    std       [$10,s]   store it as the type
                    lbsr      ScanToken advance to the next token
                    bra       ClassifyType3 continue

CheckStructKw       ldd       GlbVar005F load the current token
                    cmpd      #$002D    compare with the struct keyword
                    bne       ClassifyType3 branch if not a struct
                    lbsr      ScanToken advance to the next token
                    ldd       GlbVar0051 load the nesting level
                    addd      #$0001    increment the level
                    std       GlbVar0051 store the level
                    ldd       $14,s     load the argument
                    pshs      d         push the argument
                    ldd       $14,s     load the argument
                    pshs      d         push the argument
                    ldd       $14,s     load the argument
                    pshs      d         push the argument
                    lbsr      ParseTypeSpec recurse to parse the type
                    leas      6,s        drop the arguments
                    std       $14,s     save the result
                    ldd       GlbVar0051 load the nesting level
                    addd      #$FFFF    decrement the level
                    std       GlbVar0051 store the level
                    ldd       #$002E    load the emit opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the instruction
                    leas      2,s        drop the argument
ClassifyType3       ldd       GlbVar005F load the current token
                    cmpd      #$002D    compare with the struct keyword
                    bne       BeginEnumBody branch if a basic type
                    ldd       $0a,s     load the type flags
                    aslb                shift the flags left
                    rola                rotate the high byte
                    aslb                shift the flags left again
                    rola                rotate the high byte
                    addd      #$0030    set the struct class bits
                    std       $0a,s     store the type flags
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
                    std       $06,s     clear the field
                    std       $04,s     clear the field
                    std       $02,s     clear the field
                    ldd       GlbVar0041 load the scope counter
                    std       $08,s     save the counter
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       GlbVar0041 reset the scope counter
                    lbra      EnumLoopCheck enter the enum loop check

EnumMemberLoop      ldd       $0a,s     load the type flags
                    aslb                shift the flags left
                    rola                rotate the high byte
                    aslb                shift the flags left again
                    rola                rotate the high byte
                    addd      #$0020    set the enum class bits
                    std       $0a,s     store the type flags
                    lbsr      ScanToken advance to the next token
                    ldd       #$0004    node size to allocate
                    pshs      d         push the size
                    lbsr      AllocMem  allocate the enum node
                    leas      2,s        drop the argument
                    tfr       d,u       move the node pointer to u
                    ldd       $04,s     load the first-member flag
                    bne       EvalEnumValue branch if not the first
                    ldd       GlbVar005F load the current token
                    cmpd      #$002C    compare with the close token
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
                    ldd       $06,s     load the list tail
                    beq       SetEnumHead branch if the list is empty
                    ldx       $06,s     load the tail pointer
                    stu       $02,x     append the node to the list
                    bra       LinkEnumNode continue

SetEnumHead         stu       $02,s     set the list head
LinkEnumNode        stu       $06,s     update the tail pointer
                    ldd       #$002C    load the emit opcode
                    pshs      d         push the opcode
                    lbsr      ExpectToken emit the instruction
                    leas      2,s        drop the argument
                    ldd       $04,s     load the member count
                    addd      #$0001    increment the count
                    std       $04,s     store the count
EnumLoopCheck       ldd       GlbVar005F load the current token
                    cmpd      #$002B    compare with the enum member token
                    lbeq      EnumMemberLoop loop for the next member
                    ldd       $08,s     load the saved counter
                    std       GlbVar0041 restore the scope counter
                    ldd       $02,s     load the list head
                    beq       FinishTypeNode branch if empty
                    ldd       [$12,s]   load the existing head indirectly
                    std       $02,u     link it into the node
                    ldd       $02,s     load the list head
                    std       [$12,s]   store the new head
FinishTypeNode      ldd       $0a,s     load the type flags
                    pshs      d         push the flags
                    ldd       $16,s     load the argument
                    pshs      d         push the argument
                    bsr       ComputeTypeSize finalize the type node
                    leas      4,s        drop the arguments
                    leas      12,s       deallocate the frame
                    puls      pc,u      restore and return

ComputeTypeSize     pshs      u         save the u register
                    ldd       #$FFBC    load the frame size
                    lbsr      stkcheck  check the stack space
                    leas      -2,s       allocate the local
                    ldd       $06,s     load the type flags
                    std       ,s        save the working copy
                    bra       SizeLoopCheck enter the size loop

DeriveSizeLoop      ldd       ,s        load the pointer levels
                    pshs      d         push the value
                    ldd       #$0002    pointer size constant
                    lbsr      AsrEntry  scale by the pointer size
                    std       ,s        store the result
                    ldd       $08,s     load the array count
                    pshs      d         push the value
                    ldd       #$0002    element size constant
                    lbsr      AslEntry  scale by the element size
                    std       $08,s     store the result
SizeLoopCheck       ldd       ,s        load the type flags
                    clra                clear the high byte
                    andb      #$30      mask the pointer/array bits
                    bne       DeriveSizeLoop loop while pointer or array
                    ldd       $06,s     load the base value
                    addd      $08,s     add the computed size
                    lbra      CleanupRet return the combined size

SetNodeTypeSize     pshs      u         save the u register
                    ldd       #$FFB2    load the frame size
                    lbsr      stkcheck  check the stack space
                    ldu       $04,s     load the target node pointer
                    leas      -4,s       allocate the locals
                    ldd       ,u        load the node type word
                    std       $02,s     save the type word
                    clra                clear the high byte
                    andb      #$0f      mask the base type nibble
                    tfr       d,x       move the type index to x
                    bra       BaseTypeDispatch dispatch on the base type

Size1               ldd       #$0001    size of one byte
                    bra       StoreBaseSize go store the size

Size2               ldd       #$0002    size of two bytes
                    bra       StoreBaseSize go store the size

Size4               ldd       #$0004    size of four bytes
                    bra       StoreBaseSize go store the size

Size8               ldd       #$0008    size of eight bytes
                    bra       StoreBaseSize go store the size

SizeFromTag         ldd       $0C,s     size taken from the tag argument
                    bra       StoreBaseSize go store the size

SizeZero            clra                clear the high byte
                    clrb                clear the low byte
StoreBaseSize       std       ,s        save the computed size
                    bra       WriteNodeSize continue

BaseTypeDispatch    cmpx      #$0002    compare with the char type
                    beq       Size1     select size one
                    cmpx      #$0001    compare with the int type
                    beq       Size2     select size two
                    cmpx      #$0007    compare with the type index
                    lbeq      Size2     select size two
                    cmpx      #$0008    compare with the type index
                    beq       Size4     select size four
                    cmpx      #$0005    compare with the type index
                    lbeq      Size4     select size four
                    cmpx      #$0006    compare with the double type
                    beq       Size8     select size eight
                    cmpx      #$0003    compare with the struct type
                    beq       SizeFromTag select size from tag
                    cmpx      #$0004    compare with the union type
                    lbeq      SizeFromTag select size from tag
                    cmpx      #$000A    compare with the void type
                    beq       SizeZero  select size zero
WriteNodeSize       ldd       ,s        load the computed size
                    beq       UseFallbackSize branch if zero
                    ldd       ,s        load the computed size
                    bra       StoreNodeSize2 store it in the node

UseFallbackSize     ldd       $0C,s     use the fallback size
StoreNodeSize2      std       $02,u     store the size in the node
                    ldd       $0a,s     load the field value
                    std       $04,u     store the field in the node
                    pshs      d         push the argument
                    ldd       $02,s     load the type word
                    pshs      d         push the argument
                    ldd       $06,s     load the flags
                    pshs      d         push the argument
                    bsr       ComputeElemSize compute the element size
                    leas      6,s        drop the arguments
                    leas      4,s        deallocate the frame
                    puls      pc,u      restore and return

ComputeElemSize     pshs      u         save the u register
                    ldd       #$FFB8    load the frame size
                    lbsr      stkcheck  check the stack space
                    ldu       $08,s     load the node pointer
                    leas      -2,s       allocate the local
                    ldd       $06,s     load the type flags
                    clra                clear the high byte
                    andb      #$30      mask the pointer/array bits
                    cmpd      #$0010    compare with the pointer class
                    beq       IsPointerType branch if a pointer
                    ldd       $06,s     load the type flags
                    clra                clear the high byte
                    andb      #$30      mask the pointer/array bits
                    cmpd      #$0030    compare with the array class
                    bne       LoadTypeFlags branch if neither
IsPointerType       ldd       #$0002    pointer or array element size
                    lbra      CleanupRet return the size

LoadTypeFlags       ldd       $06,s     load the type flags
                    clra                clear the high byte
                    andb      #$30      mask off the type field bits
                    cmpd      #$0020    test for array type marker
                    bne       ReturnAggSize not an array type so branch away
                    ldd       #$0001    start element count at one
                    std       ,s        store initial count
TypeSizeLoop        ldd       ,s        reload the count
                    pshs      d         save count on stack
                    ldd       ,u        load the type word
                    lbsr      MulEntry  convert or size the type
                    std       ,s        store back
                    ldu       $02,u     follow pointer to base type
                    ldd       $06,s     load working size
                    pshs      d         pass it
                    lbsr      RemovePtrLevel multiply or accumulate size
                    leas      2,s        drop argument
                    std       $06,s     store updated size
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #$0020    still an array type?
                    beq       TypeSizeLoop keep looping over array levels
                    ldd       ,s        load the count
                    pshs      d         pass count
                    ldd       $08,s     load the type word
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #$0010    is it a pointer type?
                    bne       ScalarSize not a pointer so branch
                    ldd       #$0002    pointer size is two
                    bra       FinishTypeSize go finish

ScalarSize          ldd       $0a,s     load scalar element size
FinishTypeSize      lbsr      MulEntry   convert or size the type
                    lbra      CleanupRet return the computed size

ReturnAggSize       ldd       $08,s     load aggregate size
                    lbra      CleanupRet return the size

EndScopeCheck       pshs      u         save frame pointer
                    ldd       #$FF74    stack frame size
                    lbsr      stkcheck  check for stack space
                    leas      -64,s      allocate locals
                    ldu       [$44,s]   load symbol table head pointer
                    lbra      ScopeLoopTest enter the scan loop

ScopeSymLoop        ldd       $10,u     load the next-symbol link
                    std       $3C,s     save the iterator
                    ldd       ,u        load the symbol type
                    cmpd      #$0009    is this a label symbol?
                    bne       AfterLabelChk not a label
                    ldd       $0a,u     load the label flags
                    clra                clear high byte
                    andb      #$01      test the defined bit
                    bne       AfterLabelChk label is defined so skip
                    ldd       #$0008    push name length
                    pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       #$0014    offset to the name field
                    addd      ,s++      compute name pointer
                    pshs      d         push name pointer
                    leax      MsgLabelUndefined,pcr point at label undefined message
                    pshs      x         push it
                    leax      $06,s     point at buffer
                    pshs      x         push it
                    lbsr      StrCpy    format the message
                    leas      4,s        drop arguments
                    pshs      d         push result
                    lbsr      StrNCat   build error text
                    leas      6,s        drop arguments
                    pshs      d         push result
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
AfterLabelChk       ldx       $08,u     load the symbol subtype
                    bra       CheckBraceType test the brace markers

DecNestLevel        ldd       GlbVar0003 load the nesting counter
                    addd      #$FFFF    decrement it
                    std       GlbVar0003 store back
                    bra       RemoveFromChain continue removal

CheckBraceType      cmpx      #$006F    is it an open-scope marker?
                    beq       DecNestLevel decrement nesting level
                    cmpx      #$0076    is it a close-scope marker?
                    lbeq      DecNestLevel decrement nesting level
RemoveFromChain     ldd       $0e,u     load the symbol hash slot
                    std       $3e,s     save it
                    cmpd      GlbVar0066 below the hash table base?
                    bls       ChainHeadCheck yes so just free it
                    ldd       $3e,s     reload the hash slot
                    cmpd      GlbVar0068 above the hash table top?
                    bcc       ChainHeadCheck yes so just free it
                    pshs      u         push the symbol
                    lbsr      FreeNode  free the symbol
                    leas      2,s        drop argument
                    bra       NextScopeSym go to next entry

ChainHeadCheck      cmpu      [$3e,s]   is symbol the chain head?
                    bne       ChainWalkInit no so walk the chain
                    ldd       $12,u     load its chain link
                    std       [$3e,s]   unlink from chain head
                    bra       FreeSymbol go free the symbol

ChainWalkInit       ldd       [$3e,s]   load the chain head
                    bra       ChainWalkStep begin predecessor walk

ChainWalkLoop       ldx       $3e,s     load current chain node
                    ldd       $12,x     follow chain link
ChainWalkStep       std       $3e,s     save chain pointer
                    ldx       $3e,s     reload chain pointer
                    cmpu      $12,x     is this the predecessor?
                    bne       ChainWalkLoop keep walking the chain
                    ldd       $12,u     load symbol chain link
                    ldx       $3e,s     load predecessor
                    std       $12,x     splice symbol out of chain
FreeSymbol          ldd       GlbVar0019 load free list head
                    std       $12,u     link symbol into free list
                    stu       GlbVar0019 make symbol new free head
NextScopeSym        ldu       $3C,s     restore iterator to next symbol
ScopeLoopTest       stu       -$02,s    save current symbol pointer
                    lbne      ScopeSymLoop loop while more symbols remain
                    clra                clear high byte
                    clrb                clear low byte
                    std       [$44,s]   clear the table head pointer
                    leas      64,s       release locals
                    puls      pc,u      return

ErrCannotEvalSize   pshs      u         save frame pointer
                    ldd       #$FFBA    stack frame size
                    lbsr      stkcheck  check for stack space
                    leax      MsgCannotEvalSize,pcr point at cannot evaluate size message
                    bra       PrintErrRet go print the error

ErrIdentMissing     pshs      u         save frame pointer
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
ParseInitializer    pshs      u         save frame pointer
                    ldd       #$FFB0    stack frame size
                    lbsr      stkcheck  check for stack space
                    ldu       $04,s     load the symbol pointer argument
                    leas      -4,s       allocate locals
                    ldx       $0a,s     load the token argument
                    bra       InitTypeSwitch go dispatch on token

DeclareAndExit      lbsr      ErrCannotInit declare the symbol
                    lbra      ParseInitExit return via exit

SetFlagOne          ldd       #$0001    select setup flag one
                    bra       CallSetup go do setup

SetFlagZero         clra                clear high byte
                    clrb                clear setup flag
CallSetup           pshs      d         push the flag
                    lbsr      EmitSectLetter run the setup call
                    leas      2,s        drop argument
                    bra       NotStructMember continue parsing

InitTypeSwitch      cmpx      #_start   token is zero?
                    beq       DeclareAndExit handle it
                    cmpx      #$000E    token type matches?
                    lbeq      DeclareAndExit handle it
                    cmpx      #$0022    token type matches?
                    lbeq      DeclareAndExit handle it
                    cmpx      #$0021    token type matches?
                    beq       SetFlagOne use setup flag one
                    cmpx      #$0023    token type matches?
                    lbeq      SetFlagOne use setup flag one
                    bra       SetFlagZero otherwise clear flag

NotStructMember     ldd       GlbVar0051 load the struct-member flag
                    bne       StructMemberPath member path if set
                    leax      $14,u     point at the name field
                    stx       $02,s     save the pointer
                    ldd       $0a,s     load the token
                    cmpd      #$000F    token is a pointer marker?
                    beq       SetPtrType treat as pointer type
                    ldd       $0a,s     reload token
                    cmpd      #$0023    token type matches?
                    beq       SetPtrType treat as pointer type
                    ldd       #$0001    default flag one
                    bra       CallDeclare go call declare

SetPtrType          ldd       #$000C    set pointer type code
                    std       $08,u     store type on symbol
                    clra                clear high byte
                    clrb                clear low byte
CallDeclare         pshs      d         push the flag
                    ldd       $04,s     load pointer argument
                    pshs      d         push it
                    lbsr      EmitLabelDef declare the identifier
                    leas      4,s        drop arguments
                    bra       CheckAssignTok go check for initializer

StructMemberPath    lbsr      EmitStar  process struct member
                    ldd       $06,u     load member size
                    pshs      d         push it
                    lbsr      EmitTempRef allocate member storage
                    leas      2,s        drop argument
                    lbsr      EmitNewline finalize member
CheckAssignTok      ldd       $0C,s     load the current token
                    cmpd      #$0022    is it an assignment token?
                    bne       SetFlagTwoTok no initializer present
                    ldd       #$0001    set initializer flag one
                    std       GlbVar000B store the flag global
                    lbsr      ScanToken get the next token
                    ldd       GlbVar005F load the current token
                    cmpd      #$0037    is it a special init token?
                    bne       SetFlagTwo no so set flag two
                    ldd       $04,u     load symbol address
                    std       $02,s     save it
                    ldd       [$02,s]   already has a value?
                    bne       CalcInitDiff yes handle difference
                    ldd       GlbVar0017 load location counter
                    std       [$02,s]   store as symbol value
                    bra       NextTokAndExit go get next token

CalcInitDiff        ldd       [$02,s]   load symbol value
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
                    leax      $04,s     restore stack pointer
                    lbra      AdjustFrame return via exit

SetFlagTwo          ldd       #$0002    initializer flag two
                    std       GlbVar000B store the flag global
                    bra       CheckBraceInit continue

SetFlagTwoTok       ldd       #$0002    initializer flag two
                    std       GlbVar000B store the flag global
                    lbsr      ScanToken get the next token
CheckBraceInit      ldd       $0C,s     load the current token
                    cmpd      #$0004    is it an open-brace token?
                    bne       IsArrayInit no scalar initializer
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push depth zero
                    ldd       $0a,u     load array element count
CallParseInitList   pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       $12,s     load symbol argument
                    pshs      d         push it
                    bsr       ParseInitList parse the initializer list
                    leas      8,s        drop arguments
                    bra       InitFinish go finish

IsArrayInit         ldd       $0C,s     load the current token
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #$0020    is it an array type?
                    bne       ScalarInit no so scalar path
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push depth zero
                    ldd       $04,u     load array field
                    bra       CallParseInitList parse the initializer list

ScalarInit          ldd       #$0001    depth one
                    pshs      d         push it
                    ldd       $04,u     load symbol field
                    pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       $12,s     load argument
                    pshs      d         push it
                    bsr       ParseInitList parse the initializer list
                    leas      8,s        drop arguments
                    std       -$02,s    save result
                    bne       InitFinish nonzero so skip
                    lbsr      SkipInitTokens emit scalar initializer
                    bra       InitFinish go finish

AdjustFrame         leas      -$04,x    adjust frame
InitFinish          lbsr      EmitEndLetter finalize the initializer
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000B clear the initializer flag
ParseInitExit       leas      4,s        release locals
                    puls      pc,u      return

ParseInitList       pshs      u         save frame pointer
                    ldd       #$FFA8    stack frame size
                    lbsr      stkcheck  check for stack space
                    ldu       $06,s     load the symbol pointer argument
                    leas      -12,s      allocate locals
                    ldd       $16,s     load the nesting depth argument
                    bne       HaveDepth nonzero depth path
                    ldd       #$0029    open-brace token code
                    pshs      d         push it
                    lbsr      ExpectToken expect the open brace
                    leas      2,s        drop argument
                    bra       CheckArrayInit continue

HaveDepth           ldd       GlbVar005F load the current token
                    cmpd      #$0029    is it an open brace?
                    bne       NoOpenBrace no open brace seen
                    ldd       #$0001    note brace present
                    std       $0a,s     save flag
                    lbsr      ScanToken get the next token
                    bra       CheckArrayInit continue

NoOpenBrace         clra                clear high byte
                    clrb                clear low byte
                    std       $0a,s     clear brace flag
CheckArrayInit      ldd       $10,s     load the type word
                    clra                clear high byte
                    andb      #$30      mask type bits
                    cmpd      #$0020    is it an array type?
                    lbne      InitArrayType not an array so handle elsewhere
                    ldd       [$14,s]   load the declared array size
                    std       $02,s     save it
                    bne       HaveElemSize nonzero so keep it
                    ldd       #$FFFF    mark size as unknown
                    std       $02,s     save it
HaveElemSize        ldd       $10,s     reload the type word
                    pshs      d         push it
                    lbsr      RemovePtrLevel compute element type
                    leas      2,s        drop argument
                    std       $08,s     save element type
                    cmpd      #$0004    is element a struct?
                    bne       LoadElemSize no so load its size
                    ldd       $0a,u     load struct size
                    bra       InitCountSetup go store element size

LoadElemSize        ldx       $14,s     load type pointer
                    ldd       $02,x     load element size
InitCountSetup      std       $04,s     store element size
                    clra                clear high byte
                    clrb                clear low byte
                    std       $06,s     initialize element index
                    bra       InitListLoop enter list loop

InitElemLoop        ldd       $16,s     load the depth
                    addd      #$0001    increment depth
                    pshs      d         push it
                    ldd       $06,s     load index
                    pshs      d         push it
                    pshs      u         push symbol pointer
                    ldd       $0e,s     load element type argument
                    pshs      d         push it
                    lbsr      ParseInitList recurse into nested initializer
                    leas      8,s        drop arguments
                    std       -$02,s    save result
                    lbeq      InitFail  zero so bail out
                    ldd       $06,s     load the index
                    addd      #$0001    advance the index
                    std       $06,s     store it
                    cmpd      $02,s     reached the declared size?
                    bcc       AfterElems yes so stop
                    ldd       GlbVar005F load the current token
                    cmpd      #$0030    is it a comma?
                    bne       AfterElems no so stop
                    lbsr      ScanToken get the next token
                    bra       InitListLoop continue the loop

InitListLoop        ldd       GlbVar005F load the current token
                    cmpd      #$002A    is it a close brace?
                    bne       InitElemLoop no so parse another element
AfterElems          ldd       $02,s     load the declared size
                    cmpd      #$FFFF    was the size unknown?
                    bne       CheckCount no so check the count
                    ldd       $06,s     load the counted elements
                    std       [$14,s]   store the inferred array size
                    bra       InitListEnd go finish list

CheckCount          ldd       $06,s     load the actual count
                    cmpd      $02,s     matches the declared size?
                    bcc       InitListEnd yes so finish
                    ldx       $14,s     load type pointer
                    ldd       $02,x     load element size
                    pshs      d         push it
                    ldd       $02,u     load symbol value
                    pshs      d         push it
                    ldd       $0C,s     load token
                    pshs      d         push it
                    lbsr      ComputeElemSize compute fill amount
                    leas      6,s        drop arguments
                    pshs      d         push result
                    ldd       $04,s     load one value
                    subd      $08,s     subtract another
                    lbsr      MulEntry  size the difference
                    pshs      d         push it
                    lbsr      EmitRzb   emit padding for missing elements
                    leas      2,s        drop argument
                    bra       InitListEnd go finish list

FrameFixup          leas      -$0C,x    frame fixup
InitListEnd         ldd       $16,s     load the depth
                    beq       CheckComma2 zero depth so continue
                    ldd       $0a,s     load brace flag
                    lbeq      InitOk    brace was present go finish
CheckComma2         ldd       GlbVar005F load the current token
                    cmpd      #$0030    is it a comma?
                    bne       CheckCloseBrace no so check brace
                    lbsr      ScanToken get the next token
CheckCloseBrace     ldd       GlbVar005F load the current token
                    cmpd      #$002A    is it a close brace?
                    bne       InitListErr no so report error
                    lbsr      ScanToken get the next token
                    lbra      InitOk    go finish

InitListErr         leax      MsgTooManyElements,pcr point at initializer error message
                    pshs      x         push it
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
                    lbsr      SkipInitTokens skip malformed initializer tokens
                    lbra      InitOk    return with success

InitArrayType       ldd       $10,s     load the declared type
                    cmpd      #$0004    is it an array type
                    lbne      ScalarInit2 not array, do scalar init
                    ldd       $14,s     load the element count
                    std       ,s        save the count locally
                    bne       MemberEndCheck nonzero elements, process them
                    leax      MsgUnionsNotAllowed,pcr point at unions-not-allowed message
                    lbra      ReportInitErr report the error

InitMemberLoop      ldx       ,s        get member list pointer
                    ldu       $02,x     follow to member entry
                    ldd       $16,s     load current offset
                    addd      #$0001    bump the index
                    pshs      d         save it
                    ldd       ,u        load member type
                    cmpd      #$0004    is member an array
                    bne       NonArrayMember no, use plain size
                    ldd       $0a,u     array element size
                    bra       GotMemberSize got the array size

NonArrayMember      ldd       $04,u     scalar member size
GotMemberSize       pshs      d         pass the size
                    pshs      u         pass member pointer
                    ldd       ,u        member type again
                    pshs      d         pass the type
                    lbsr      ParseInitList recurse to init this member
                    leas      8,s        clean the arguments
                    std       -$02,s    save result
                    lbeq      InitFail  failed, return zero
                    ldd       [,s]      follow to next member
                    std       ,s        update the pointer
                    beq       RemainCheck no more, finish
                    ldd       GlbVar005F load current token
                    cmpd      #$0030    is it a comma separator
                    bne       RemainCheck no, done with members
                    lbsr      ScanToken advance to next token
                    bra       MemberEndCheck check for end token

MemberEndCheck      ldd       GlbVar005F load current token
                    cmpd      #$002A    is it the closing brace
                    bne       InitMemberLoop no, process next member
                    bra       RemainCheck done

FillRemainLoop      ldx       ,s        get member pointer
                    ldu       $02,x     follow to member entry
                    ldd       $04,u     pass member field
                    pshs      d         push it
                    ldd       $02,u     pass member field
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
                    leax      $0C,s     release locals
                    lbra      FrameFixup return to caller

ScalarInit2         ldd       $10,s     reload the type
                    pshs      d         pass it
                    bsr       ParseScalarInit parse a scalar initializer
                    std       ,s++      save node and drop arg
                    beq       ConstReqErr none, need constant expression
                    ldd       $0a,s     test the flag
                    beq       InitOk    zero, return success
                    ldd       #$002A    closing brace token
                    pshs      d         push it
                    lbsr      ExpectToken expect the brace
                    leas      2,s        clean up
InitOk              ldd       #$0001    return success
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

EmitRzb             pshs      u         save frame pointer
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    lbsr      EmitStar  start a new asm line
                    leax      MsgRzb,pcr point at rzb keyword
                    pshs      x         push it
                    lbsr      EmitSpaceText emit the directive text
                    leas      2,s        clean up
                    ldd       $04,s     load the byte count
                    pshs      d         push it
                    lbsr      EmitDecimal emit the number
                    leas      2,s        clean up
                    lbsr      EmitNewline emit newline
                    puls      pc,u      return

ParseScalarInit     pshs      u         save frame pointer
                    ldd       #$FFB0    requested frame size
                    lbsr      stkcheck  check stack space
                    leas      -8,s       reserve locals
                    ldd       #$0002    pass parse mode
                    pshs      d         push it
                    lbsr      ParseExpr begin expression
                    std       ,s        save partial result
                    lbsr      OptExprTree parse a constant expression
                    leas      2,s        clean up
                    tfr       d,u       result node in u
                    stu       -$02,s    save it
                    bne       GotInitNode got a node
                    clra                clear high byte
                    clrb                return zero
                    lbra      ScalarInitRet exit with no node

GotInitNode         clra                clear high byte
                    clrb                clear low byte
                    std       $04,s     clear value slot
                    ldd       #$0001    initial code one
                    std       $02,s     save it
                    ldd       ,u        load node type
                    std       ,s        save it
                    ldd       $0C,s     load declared type
                    clra                clear high byte
                    andb      #$30      isolate type class bits
                    cmpd      #$0010    is it scalar class
                    bne       NonScalarClass no, other handling
                    ldx       ,s        node type into x
                    bra       DispatchNodeType dispatch on node type

SelectCodeOne       ldd       #$0001    select conversion code one
                    bra       ConvertNode convert with that code

CheckClassBits      ldd       ,s        node type
                    clra                clear high byte
                    andb      #$30      isolate class bits
                    cmpd      #$0010    is it scalar class
                    beq       CheckOpcode yes, use as is
                    bra       DropAndFinish otherwise skip conversion

DispatchNodeType    cmpx      #$0008    type is code eight
                    beq       SelectCodeOne select code one
                    cmpx      #$0001    type is code one
                    beq       CheckOpcode use as is
                    cmpx      #$0007    type is code seven
                    beq       CheckOpcode use as is
                    bra       CheckClassBits check class bits

NonScalarClass      ldd       ,s        node type
                    clra                clear high byte
                    andb      #$30      isolate class bits
                    cmpd      #$0010    is it scalar class
                    bne       CheckCharType no, other handling
                    ldd       $0C,s     declared type
                    pshs      d         push it
                    lbsr      IsIntegral resolve type node
                    std       ,s++      save and drop arg
                    bne       CheckOpcode nonzero, use it
DropAndFinish       leax      $08,s     drop locals
                    bra       AdjustStack fix stack and finish

CheckCharType       ldd       $0C,s     declared type
                    cmpd      #$0005    is it a char type
                    bne       UseDeclaredType no
                    ldd       #$0006    promote to int
                    bra       ConvertNode convert as int

UseDeclaredType     ldd       $0C,s     declared type
ConvertNode         pshs      d         push it
                    pshs      u         pass the node
                    lbsr      InsertConvNode coerce to type
                    leas      4,s        clean up
CheckOpcode         ldd       $06,u     load node opcode
                    cmpd      #$0050    is it a constant
                    beq       GotAddrConst handle it
                    ldd       $06,u     opcode again
                    cmpd      #$0051    is it negated constant
                    bne       CheckNameRef no, other opcode
GotAddrConst        ldd       $0C,u     load address field
                    std       $06,s     save it
                    tfr       d,x       pointer into x
                    ldd       $06,x     load its opcode
                    cmpd      #$0036    is it a struct member
                    beq       CheckNegConst handle negation
                    bra       ZeroResult not a struct, zero result

AdjustStack         leas      -$08,x    restore stack from x
ZeroResult          clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     clear result
                    leax      $08,s     drop locals
                    lbra      AdjustStack2 finish

CheckNegConst       ldd       $06,u     load node opcode
                    cmpd      #$0051    is it negated
                    bne       LoadConstVal no
                    ldx       $06,s     pointer into x
                    ldd       $08,x     load value
                    nega                negate high
                    negb                negate low
                    sbca      #$00      complete the negation
                    bra       StoreConstVal store negated value

LoadConstVal        ldx       $06,s     pointer into x
                    ldd       $08,x     load value
StoreConstVal       std       $04,s     save the value
                    ldd       $06,s     pass the node
                    pshs      d         push it
                    lbsr      WalkTree  free the node
                    leas      2,s        clean up
                    stu       $06,s     save new node
                    ldu       $0a,u     follow the link
                    ldd       $06,s     pass the node
                    pshs      d         push it
                    lbsr      LinkNode  rebuild the node
                    leas      2,s        clean up
CheckNameRef        ldd       $06,u     load node opcode
                    cmpd      #$0041    is it a name reference
                    bne       LoadOpcode2 no
                    ldd       $0a,u     symbol pointer
                    std       $06,s     save it
                    tfr       d,x       pointer into x
                    ldx       $08,x     follow to type
                    ldx       $08,x     follow to base type
                    bra       DispatchNameType dispatch on type

ClearResult         clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     clear result
                    lbra      FinishInit finish

EmitStringInit      ldd       #$0001    initializer active
                    std       GlbVar000D set initializer flag
                    ldd       $04,s     pass field
                    pshs      d         push it
                    ldd       $08,s     pass field
                    pshs      d         push it
                    lbsr      AdvanceOffset emit the initializer
                    leas      4,s        clean up
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000D clear initializer flag
                    lbra      FinishInit finish

DispatchNameType    cmpx      #$000F    type code fifteen
                    beq       EmitStringInit emit string init
                    cmpx      #$000E    type code fourteen
                    lbeq      EmitStringInit emit string init
                    cmpx      #$000C    type code twelve
                    lbeq      EmitStringInit emit string init
                    cmpx      #$0021    type code thirtythree
                    lbeq      EmitStringInit emit string init
                    cmpx      #$0022    type code thirtyfour
                    lbeq      EmitStringInit emit string init
                    bra       ClearResult none matched, clear

LoadOpcode2         ldx       $06,u     load node opcode
                    bra       DispatchOpcode2 dispatch on it

CheckCharType2      ldd       $0C,s     declared type
                    cmpd      #$0005    is it a char
                    bne       EmitScalarInit no
                    ldx       $08,u     string pointer
                    pshs      x         push it
                    ldx       $08,u     string pointer again
                    lbsr      LoadNumWork register the string
                    lbsr      SwapNumWork finalize the string
EmitScalarInit      ldd       $0C,s     declared type
                    pshs      d         push it
                    ldd       $08,u     pass the value
                    pshs      d         push it
                    bsr       EmitInitValue emit the init value
                    leas      4,s        clean up
                    bra       FinishInit finish

EmitFloatInit       lbsr      EmitFdb   prepare float emit
                    ldd       $08,u     pass the value
                    pshs      d         push it
                    lbsr      EmitStmtLine emit float constant
                    leas      2,s        clean up
                    bra       FinishInit finish

DispatchOpcode2     cmpx      #$004B    opcode is char literal
                    beq       CheckCharType2 handle it
                    cmpx      #$0036    opcode is member
                    beq       EmitScalarInit emit scalar init
                    cmpx      #$004A    opcode is like member
                    lbeq      EmitScalarInit emit scalar init
                    cmpx      #$0037    opcode is float
                    beq       EmitFloatInit emit float init
                    lbra      ClearResult none matched, clear

AdjustStack2        leas      -$08,x    restore stack from x
FinishInit          pshs      u         pass the node
                    lbsr      WalkTree  free the node
                    leas      2,s        clean up
                    ldd       $02,s     load result
ScalarInitRet       leas      8,s        release locals
                    puls      pc,u      return

EmitInitValue       pshs      u         save frame pointer
                    ldd       #$FFB6    requested frame size
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     load the value node
                    leas      -2,s       reserve a local
                    ldx       $08,s     load element type
                    bra       DispatchSize dispatch on it

EmitNumberVal       lbsr      EmitFcb   prepare number emit
                    pshs      u         pass the node
                    lbsr      EmitDecimal emit the number
                    leas      2,s        clean up
                    lbsr      EmitNewline emit newline
                    bra       EmitValRet finish

SetByteSize         ldd       #$0001    one byte
                    bra       StoreSize store the size

SetWordSize         ldd       #$0002    two bytes
StoreSize           std       ,s        store the size
                    bra       EmitSizedVal emit sized value

EmitLargeVal        ldd       $08,s     pass the value
                    pshs      d         push it
                    pshs      u         pass the node
                    lbsr      EmitFloatField emit long value
                    bra       DropFour  finish

DispatchSize        cmpx      #$0002    type code two
                    beq       EmitNumberVal emit number
                    cmpx      #$0001    type code one
                    beq       SetByteSize one byte
                    cmpx      #$0007    type code seven
                    lbeq      SetByteSize one byte
                    cmpx      #$0008    type code eight
                    beq       SetWordSize two bytes
                    cmpx      #$0005    type code five
                    beq       EmitLargeVal emit large value
                    cmpx      #$0006    type code six
                    lbeq      EmitLargeVal emit large value
                    lbra      SetByteSize default one byte

EmitSizedVal        ldd       ,s        the chosen size
                    pshs      d         push it
                    pshs      u         pass the node
                    lbsr      EmitInitList emit sized value
DropFour            leas      4,s        clean up
EmitValRet          leas      2,s        drop local
                    puls      pc,u      return

ErrCannotInit       pshs      u         save frame pointer
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    leax      MsgCannotInit,pcr point at cannot-initialize message
                    pshs      x         push it
                    lbsr      PrintErrLoc print the error
                    leas      2,s        clean up
                    bsr       SkipInitTokens skip to resync point
                    puls      pc,u      return

SkipInitTokens      pshs      u         save frame pointer
                    ldd       #$FFBC    requested frame size
                    lbsr      stkcheck  check stack space
SkipLoop            ldx       GlbVar005F load current token
                    bra       SkipCheck check it

SkipDone            puls      pc,u      stop skipping and return

SkipAdvance         lbsr      ScanToken advance to next token
                    bra       SkipLoop  reload token

SkipCheck           cmpx      #$0030    is it a comma
                    beq       SkipDone  stop skipping
                    cmpx      #$0028    is it open brace
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
EmitLabelDef        pshs      u         save frame pointer
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    lbsr      EmitStar  start a new asm line
                    ldd       $04,s     the label value
                    pshs      d         push it
                    lbsr      EmitName8 emit the label
                    leas      2,s        clean up
                    ldd       $06,s     test colon flag
                    lbeq      EmitNewlineRet no colon needed
                    ldd       #$003A    colon character
                    pshs      d         push it
                    bsr       EmitCharOut emit the colon
                    lbra      DropAndNewline finish

EmitSpaceText       pshs      u         save frame pointer
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       GlbVar0025 output path number
                    pshs      d         push it
                    ldd       #$0020    space character
                    pshs      d         push it
                    lbsr      PutChar2  write it to output
                    leas      4,s        clean up
                    ldd       $04,s     text argument
                    pshs      d         push it
                    bsr       EmitText  emit the text
                    lbra      EmitReturn finish

                    pshs      u         save frame pointer
                    ldd       #$FFBA    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       $04,s     text argument
                    pshs      d         push it
                    bsr       EmitSpaceText emit space then text
                    lbra      DropAndNewline finish

EmitNewline         pshs      u         save frame pointer
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       GlbVar0025 output path number
                    pshs      d         push it
                    ldd       #$000D    carriage return
                    bra       EmitCharTail write it out

EmitCharOut         pshs      u         save frame pointer
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       GlbVar0025 output path number
                    pshs      d         push it
                    ldd       $06,s     the character argument
EmitCharTail        pshs      d         push it
                    lbsr      PutChar2  write it to output
                    lbra      EmitCleanupRet finish

EmitText            pshs      u         save frame pointer
                    ldd       #$FFB8    requested frame size
                    lbsr      stkcheck  check stack space
                    ldd       $04,s     load the argument
                    pshs      d         save value argument for fprintf
                    ldd       GlbVar0025 load output file pointer
                    pshs      d         pass file to fprintf
                    lbsr      fprintf   format and emit
                    lbra      EmitCleanupRet drop args and return

EmitDecimal         pshs      u         save frame pointer
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       $04,s     load the number argument
                    pshs      d         pass value to formatter
                    leax      FmtPctD,pcr point at the %d format
                    lbra      EmitFprintf emit via fprintf

EmitLocalRef        pshs      u         save frame pointer
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       #$006C    the 'l' prefix character
                    pshs      d         pass char to emitter
                    bsr       EmitCharOut emit the 'l' prefix
                    leas      2,s        drop char argument
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    ldd       $06,s     load the number argument
                    pshs      d         pass value
                    lbsr      PutWord   emit decimal number
                    leas      4,s        drop args
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004F clear pending flag
                    puls      pc,u      return

EmitStmtLine        pshs      u         save frame pointer
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar004F clear pending flag
                    ldd       $04,s     load node argument
                    pshs      d         pass node
                    bsr       EmitTempRef emit the temp reference
DropAndNewline      leas      2,s        drop argument
EmitNewlineRet      lbsr      EmitNewline emit trailing newline
                    puls      pc,u      return

EmitTempRef         pshs      u         save frame pointer
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       #$005F    the '_' prefix character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the '_' prefix
                    leas      2,s        drop char argument
                    ldd       $04,s     load the number
                    pshs      d         pass value
                    lbsr      EmitDecimal emit decimal number
                    lbra      EmitReturn clean up and return

EmitName8           pshs      u         save frame pointer
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       $04,s     load the name pointer
                    pshs      d         pass name
                    leax      FmtPct8s,pcr point at the %.8s format
                    lbra      EmitFprintf emit via fprintf

EmitLabelOffset     pshs      u         save frame pointer
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -2,s       reserve local slot
                    ldd       $06,s     load the value
                    subd      GlbVar002F subtract base global
                    std       ,s        store the offset
                    beq       EmitResult skip emit when zero
                    ldd       #$004D    the 'M' prefix character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the 'M' prefix
                    leas      2,s        drop char argument
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    ldd       $02,s     load the offset
                    pshs      d         pass value
                    lbsr      PutWord   emit decimal offset
                    leas      4,s        drop args
EmitResult          ldd       $06,s     load original value for result
                    lbra      EmitReturn clean up and return

EmitOpCode          pshs      u         save frame pointer
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       GlbVar0025 load output file into u
                    ldx       $04,s     load operator code
                    lbra      DispatchOp2 dispatch on operator

OpEmitJ             ldd       #$004A    the 'J' mnemonic character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the 'J'
                    leas      2,s        drop char argument
                    pshs      u         save file pointer
                    ldd       $0a,s     load number argument
                    bra       EmitOpNumberTail emit the number

OpEmitR             ldd       #$0072    the 'r' mnemonic character
                    lbra      EmitCharDone emit char and return

OpEmitG             ldd       #$0047    the 'G' mnemonic character
                    bra       EmitCharThenNum emit char then number

OpEmitLowJ          ldd       #$006A    the 'j' mnemonic character
                    bra       EmitCharThenNum emit char then number

OpEmitD             ldd       #$0044    the 'D' mnemonic character
                    pshs      d         pass char
                    lbsr      EmitCharOut emit the 'D'
                    leas      2,s        drop char argument
                    pshs      u         save file pointer
                    ldd       GlbVar002B load label counter
                    addd      #$0001    increment counter
                    std       GlbVar002B store new counter
EmitOpNumberTail    pshs      d         pass number
                    lbsr      PutWord   emit decimal number
                    leas      4,s        drop args
                    bra       EmitNumArg continue to number tail

OpEmitY             ldd       #$0059    the 'Y' mnemonic character
                    bra       EmitCharThenNum emit char then number

OpEmitU             ldd       #$0055    the 'U' mnemonic character
EmitCharThenNum     pshs      d         pass char
                    lbsr      EmitCharOut emit the mnemonic char
                    leas      2,s        drop char argument
EmitNumArg          pshs      u         save file pointer
                    ldd       $08,s     load number argument
                    pshs      d         pass value
                    lbsr      PutWord   emit decimal number
EmitCleanupRet      leas      4,s        drop args
                    puls      pc,u      return

DispatchOp2         cmpx      #$007D    operator $7D?
                    lbeq      OpEmitJ   emit 'J'
                    cmpx      #$0012    operator $12?
                    beq       OpEmitR   emit 'r'
                    cmpx      #$001D    operator $1D?
                    beq       OpEmitG   emit 'G'
                    cmpx      #$007C    operator $7C?
                    beq       OpEmitLowJ emit 'j'
                    cmpx      #$0009    operator $09?
                    beq       OpEmitD   emit 'D'
                    cmpx      #$0076    operator $76?
                    beq       OpEmitY   emit 'Y'
                    cmpx      #$006F    operator $6F?
                    beq       OpEmitU   emit 'U'
                    puls      pc,u      no match, return

EmitStar            pshs      u         save frame pointer
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       #$002A    the '*' character
EmitCharDone        pshs      d         pass char
                    lbsr      EmitCharOut emit the char
                    lbra      EmitReturn clean up and return

EmitFuncLine        pshs      u         save frame pointer
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       $04,s     load the name pointer
                    pshs      d         pass name
                    leax      FmtFPctS,pcr point at the F%s format
EmitFprintf         pshs      x         pass format string
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    lbsr      fprintf   format and emit
                    lbra      CostRet   clean up and return

EmitStmtMode1       pshs      u         save frame pointer
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       $04,s     load node argument
                    pshs      d         pass node
                    ldd       #$0001    select mode 1
                    bra       EmitStmtCall call node emitter

EmitStmtMode2       pshs      u         save frame pointer
                    ldd       #$FFB2    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       $0a,s     push arg
                    pshs      d         pass arg
                    ldd       $0a,s     push arg
                    pshs      d         pass arg
                    ldd       $0a,s     push arg
                    pshs      d         pass arg
                    ldd       $0a,s     push arg
                    pshs      d         pass arg
                    ldd       #$0002    select mode 2
                    pshs      d         pass mode
                    bsr       EmitNodeRecord emit node record
                    leas      10,s       drop args
                    bra       EmitStmtRet return node result

EmitStmtMode4       pshs      u         save frame pointer
                    ldd       #$FFB8    stack check size
                    lbsr      stkcheck  verify stack space
                    ldd       $04,s     load node argument
                    pshs      d         pass node
                    ldd       #$0004    select mode 4
EmitStmtCall        pshs      d         pass mode
                    bsr       EmitNodeRecord emit node record
                    leas      4,s        drop args
EmitStmtRet         ldd       $04,s     load result to return
                    puls      pc,u      return

EmitNodeRecord      pshs      u         save frame pointer
                    ldd       #$FFB6    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       GlbVar0025 load output file into u
                    pshs      u         save file pointer
                    ldd       #$0054    the 'T' record prefix
                    pshs      d         pass char
                    lbsr      PutChar2  emit the 'T' prefix
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       $06,s     load node value
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
                    ldx       $04,s     load node type
                    bra       DispatchRec dispatch on node type

RecCaseTwo          pshs      u         save file pointer
                    ldd       $0a,s     load arg
                    pshs      d         pass value
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       $0C,s     load arg
                    pshs      d         pass value
                    lbsr      PutWord   emit number
                    leas      4,s        drop args
                    pshs      u         save file pointer
                    ldd       $0e,s     load arg
                    pshs      d         pass value
                    lbsr      PutChar2  emit char
                    bra       RecCaseDone finish this case

RecCaseFive         pshs      u         save file pointer
                    ldd       GlbVar000D load global
                    bra       EmitRecNum emit that number

RecCaseTwelve       pshs      u         save file pointer
                    ldd       $0a,s     load arg
EmitRecNum          pshs      d         pass value
                    lbsr      PutWord   emit number
RecCaseDone         leas      4,s        drop args
                    bra       EmitRecTail continue to record tail

DispatchRec         cmpx      #$0002    node type $02?
                    beq       RecCaseTwo handle case two
                    cmpx      #$0005    node type $05?
                    beq       RecCaseFive handle case five
                    cmpx      #$0012    node type $12?
                    beq       RecCaseTwelve handle case twelve
EmitRecTail         ldd       GlbVar002B load label counter
                    pshs      d         save counter
                    ldd       $06,s     load mode
                    cmpd      #$0002    mode 2?
                    bne       RecFlagZero no, use flag zero
                    ldd       #$0001    yes, use flag one
                    bra       RecFlagSet proceed with flag

RecFlagZero         clra                zero high byte
                    clrb                zero low byte
RecFlagSet          pshs      d         push cost flag
                    ldd       $0a,s     load node
                    pshs      d         pass node
                    bsr       EvalTreeCost compute tree cost
                    leas      4,s        drop args
                    addd      ,s++      add saved counter
                    std       GlbVar002B update counter
                    ldd       $06,s     load mode/node for tail
                    lbra      EmitRightChild emit tree and return

EvalTreeCost        pshs      u         save frame pointer
                    ldd       #$FFB0    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer
                    leas      -6,s       reserve local slots
                    stu       -$02,s    save node pointer
                    lbeq      CostNull  return zero if null
                    ldx       $06,u     load node type
                    lbra      DispatchCost dispatch on node type

CostCaseGH          ldd       $0C,s     load flag
                    beq       CostGHFour flag zero uses weight 4
                    ldd       #$0001    weight 1
                    bra       CostGHStore store the weight

CostGHFour          ldd       #$0004    weight 4
CostGHStore         std       $04,s     store left weight
                    ldd       #$0001    right weight 1
                    bra       CostStoreZero store weights

CostCase40          ldd       #$0003    weight 3
                    std       $04,s     store left weight
                    ldd       #$0001    right weight 1
                    bra       CostStoreMid store weights

CostCaseRange       ldd       $0C,s     load flag
                    beq       CostRangeThree flag zero uses weight 3
                    clra                zero high byte
                    clrb                zero low byte
                    bra       CostRangeStore use weight 0

CostRangeThree      ldd       #$0003    weight 3
CostRangeStore      std       $04,s     store left weight
                    clra                zero high byte
                    clrb                zero low byte
                    bra       CostStoreZero store weights

CostCase64          ldd       #$0003    weight 3
                    std       $04,s     store left weight
                    ldd       #$0001    right weight 1
                    std       $02,s     store mid weight
                    clra                zero high byte
                    clrb                zero low byte
                    std       ,s        store low weight
                    lbra      CostRecurse recurse over children

CostCase4B          ldd       #$0001    weight 1
                    std       $04,s     store left weight
                    clra                zero high byte
                    clrb                zero low byte
                    std       $0C,s     clear flag slot
CostStoreZero       std       ,s        store low weight
CostStoreMid        std       $02,s     store mid weight
                    lbra      CostRecurse recurse over children

CostDefault         clra                zero high byte
                    clrb                zero low byte
                    std       $0C,s     clear flag slot
                    std       ,s        clear low weight
                    std       $02,s     clear mid weight
                    std       $04,s     clear left weight
                    bra       CostRecurse recurse over children

DispatchCost        cmpx      #$0047    node type $47?
                    lbeq      CostCaseGH handle case
                    cmpx      #$0048    node type $48?
                    lbeq      CostCaseGH handle case
                    cmpx      #$0040    node type $40?
                    lbeq      CostCase40 handle case
                    cmpx      #$005A    node type $5A?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$005B    node type $5B?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$005C    node type $5C?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$005D    node type $5D?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$005E    node type $5E?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$005F    node type $5F?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$0060    node type $60?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$0061    node type $61?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$0062    node type $62?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$0063    node type $63?
                    lbeq      CostCaseRange handle range case
                    cmpx      #$0064    node type $64?
                    lbeq      CostCase64 handle case
                    cmpx      #$004B    node type $4B?
                    lbeq      CostCase4B handle case
                    cmpx      #$004A    node type $4A?
                    lbeq      CostCase4B handle case
                    lbra      CostDefault default case

CostRecurse         ldd       $02,s     load flag
                    pshs      d         pass flag
                    ldd       $0a,u     load left child
                    pshs      d         pass child
                    lbsr      EvalTreeCost recurse on left child
                    leas      4,s        drop args
                    addd      $04,s     add left weight
                    pshs      d         save subtotal
                    ldd       $02,s     load flag
                    pshs      d         pass flag
                    ldd       $0C,u     load right child
                    pshs      d         pass child
                    lbsr      EvalTreeCost recurse on right child
                    leas      4,s        drop args
                    addd      ,s++      sum both subtotals
                    bra       CostRet   return the total

CostNull            clra                zero high byte
                    clrb                zero low byte
CostRet             leas      6,s        drop locals
                    puls      pc,u      return

EmitExprTree        pshs      u         save frame pointer
                    ldd       #$FFBA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer
                    stu       -$02,s    save node pointer
                    lbeq      EmitRet2  return if null
                    pshs      u         pass node pointer
                    bsr       EmitChildFlag emit node header char
                    leas      2,s        drop argument
                    ldd       $0a,u     load left child
                    pshs      d         pass child
                    bsr       EmitExprTree recurse on left child
                    leas      2,s        drop argument
                    ldd       $0C,u     load right child
EmitRightChild      pshs      d         pass child
                    lbsr      EmitExprTree recurse on right child
                    lbra      EmitReturn clean up and return

EmitChildFlag       pshs      u         save frame pointer
                    ldd       #$FFAA    stack check size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer
                    leas      -2,s       reserve local slot
                    ldd       $0a,u     load left child
                    beq       KindLeftCheck no left child
                    ldd       $0C,u     load right child
                    beq       KindLeftCheck left but no right child
                    ldd       #$0042    'B' both children
                    bra       EmitKindChar emit the kind char

KindLeftCheck       ldd       $0a,u     reload left child
                    beq       KindRightCheck neither child present
                    ldd       #$004C    'L' left child only
                    bra       EmitKindChar emit the kind char

KindRightCheck      ldd       $0C,u     load right child
                    beq       KindNone  no children present
                    ldd       #$0052    'R' right child only
                    bra       EmitKindChar emit the kind char

KindNone            ldd       #$004E    'N' no children
EmitKindChar        std       ,s        store the kind char
                    ldd       GlbVar0025 load output file
                    pshs      d         pass file
                    ldd       $02,s     load the kind char
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
                    ldd       $02,u     load next structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $06,u     load structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $0e,u     load structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    leax      LineBuffer,y   point at global table base
                    pshs      x         save base pointer
                    ldd       $10,u     load structure field
                    subd      ,s++      subtract base to get relative value
                    pshs      d         push the computed value
                    lbsr      PutChar2  emit the relative value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $12,u     load structure field
                    pshs      d         push value argument
                    lbsr      PutChar2  emit the value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $14,u     load structure field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the field
                    leas      4,s        drop the arguments
                    ldd       $06,u     load the type code field
                    cmpd      #$0034    check for type code $34
                    lbne      CheckFloatType branch if not that type
                    ldu       $08,u     follow pointer to sub-node
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       ,u        load sub-node field
                    pshs      d         push value argument
                    lbsr      PutChar2  emit the value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $08,u     load sub-node field
                    pshs      d         push value argument
                    lbsr      PutChar2  emit the value
                    leas      4,s        drop the arguments
                    ldx       $08,u     load sub-node tag
                    bra       CheckExprTag check tag against known set

EmitSubExpr         pshs      u         save node pointer
                    ldd       #$0014    offset to sub-field
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
                    ldd       $06,u     load field value
                    lbra      PushEmitValue emit and finish

CheckExprTag        cmpx      #$000E    tag equals code $0E
                    beq       EmitSubExpr handle as sub-expression
                    cmpx      #$000C    tag equals code $0C
                    lbeq      EmitSubExpr handle as sub-expression
                    cmpx      #$0021    tag equals code $21
                    lbeq      EmitSubExpr handle as sub-expression
                    cmpx      #$0022    tag equals code $22
                    lbeq      EmitSubExpr handle as sub-expression
                    bra       EmitFieldValue otherwise emit field value

CheckFloatType      ldd       $06,u     load the type code
                    cmpd      #$004A    is it float type $4A
                    bne       CheckDoubleType no, check double type
                    leas      -4,s       allocate 4-byte temp buffer
                    leax      ,s        point at the temp buffer
                    pshs      x         push buffer pointer
                    bsr       FloatConstAddr skip over inline float constant
                    fcb       $00,$00,$00,$00
FloatConstAddr      puls      x         recover the constant address
                    lbsr      StoreLong copy the float constant
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       #$0001    element count one
                    pshs      d         push element count
                    ldd       #$0004    element size four bytes
                    pshs      d         push element size
                    ldu       $08,u     follow the value pointer
                    beq       UseFloatTemp null, use the temp buffer
                    tfr       u,d       use the value pointer
                    bra       EmitFloatData go push data pointer

UseFloatTemp        leax      $06,s     point at the temp buffer
                    tfr       x,d       use the buffer address
EmitFloatData       pshs      d         push the data pointer
                    lbsr      $6EB7     emit the float bytes
                    leas      8,s        drop the arguments
                    bra       EmitCleanup clean up and return

CheckDoubleType     ldd       $06,u     load the type code
                    cmpd      #$004B    is it double type $4B
                    bne       EmitDefaultValue no, take default path
                    leas      -8,s       allocate 8-byte temp buffer
                    leax      ,s        point at the temp buffer
                    pshs      x         push buffer pointer
                    bsr       DoubleConstAddr skip over inline double constant
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
DoubleConstAddr     puls      x         recover the constant address
                    lbsr      SwapNumWork copy the double constant
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       #$0001    element count one
                    pshs      d         push element count
                    ldd       #$0008    element size eight bytes
                    pshs      d         push element size
                    ldu       $08,u     follow the value pointer
                    beq       UseDoubleTemp null, use the temp buffer
                    tfr       u,d       use the value pointer
                    bra       EmitDoubleData go push data pointer

UseDoubleTemp       leax      $06,s     point at the temp buffer
                    tfr       x,d       use the buffer address
EmitDoubleData      pshs      d         push the data pointer
                    lbsr      $6EB7     emit the double bytes
                    leas      8,s        drop the arguments
                    leas      8,s        release the temp buffer
                    lbra      EmitReturn clean up and return

EmitDefaultValue    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $08,u     load the value field
PushEmitValue       pshs      d         push value argument
                    lbsr      PutWord   emit the value
EmitCleanup         leas      4,s        drop the arguments
                    lbra      EmitReturn return

EmitInitList        pshs      u         save the caller frame pointer
                    ldd       #$FFB8    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the node argument
                    leas      -2,s       allocate a local
                    lbsr      EmitFdb   get the element count
                    ldd       $08,s     load the returned count
                    cmpd      #$0001    single element
                    bne       InitNotSingle no, handle multiple elements
                    pshs      u         push the node pointer
                    lbsr      EmitDecimal emit the single initializer
InitDone            leas      2,s        drop the argument
                    lbra      InitFinish2 finish the emit

InitNotSingle       cmpu      #$0000    is the node pointer null
                    bne       InitEachElem no, emit each element
                    ldd       #$0001    start index at one
                    std       ,s        store loop counter
                    bra       ZeroFillTest enter the zero-fill loop

ZeroFillLoop2       leax      StrZeroComma,pcr point at the "0," string
                    pshs      x         push string argument
                    lbsr      EmitText  output the string
                    leas      2,s        drop the argument
ZeroFillTest        ldd       ,s        load loop counter
                    addd      #$0001    increment counter
                    std       ,s        store it back
                    subd      #$0001    restore pre-increment value
                    cmpd      $08,s     compare against element count
                    blt       ZeroFillLoop2 loop while below the count
                    ldd       #$0030    character '0'
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
                    ldd       $08,s     load the element count
                    addd      #$FFFF    count minus one
                    cmpd      ,s        is this the last element
                    beq       ElemNoComma yes, skip the separator
                    ldd       #$002C    character ','
                    pshs      d         push the separator
                    lbsr      EmitCharOut output the comma
                    leas      2,s        drop the argument
ElemNoComma         ldd       ,s        load the index
                    addd      #$0001    increment the index
ElemNext            std       ,s        store the index
                    ldd       ,s        reload the index
                    cmpd      $08,s     compare against the count
                    blt       ElemLoop  loop over the elements
InitFinish2         lbsr      EmitNewline finish the output
EmitReturn          leas      2,s        release the local
EmitRet2            puls      pc,u      restore and return

EmitFloatField      pshs      u         save the caller frame
                    ldd       #$FFB4    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the node argument
                    ldd       #$0066    character 'f' marker
                    pshs      d         push it
                    lbsr      EmitCharOut output the 'f' marker
                    leas      2,s        drop the argument
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       $08,s     load the value field
                    pshs      d         push value argument
                    lbsr      PutWord   emit the value
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load output stream
                    pshs      d         push stream argument
                    ldd       #$0001    element count one
                    pshs      d         push element count
                    ldd       #$0008    element size eight bytes
                    pshs      d         push element size
                    pshs      u         push the node pointer
                    lbsr      $6EB7     emit the double value bytes
                    leas      8,s        drop the arguments
                    puls      pc,u      restore and return

AdvanceOffset       pshs      u         save the caller frame
                    ldd       #$FFB8    stack space needed
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load the node argument
                    ldd       $14,u     load current offset field
                    addd      $06,s     add increment argument
                    std       $14,u     store updated offset
                    pshs      u         push the node pointer
                    ldd       #$0005    selector value five
                    pshs      d         push the selector
                    lbsr      EmitNodeRecord process node with selector
                    leas      4,s        drop the arguments
                    puls      pc,u      restore and return

FmtPctD             fcb       $25,$64
                    fcb       C$NULL
FmtPct8s            fcc       /%.8s/
                    fcb       C$NULL
FmtFPctS            fcb       $46,$25,$73
                    fcb       C$CR,C$NULL
StrZeroComma        fcb       $30,$2C
                    fcb       C$NULL
PrintfBuf           pshs      u         save the caller frame
                    leax      StdoutStream,y   point at internal output buffer
                    stx       GlbVar000F set the output pointer global
                    ldd       #$0001    mode one, stream output
                    std       GlbVar0015 set the output mode
                    leax      $06,s     point past the format argument
                    pshs      x         push the varargs pointer
                    ldd       $06,s     load the format string argument
                    bra       RunPrintf run the formatter

fprintf             pshs      u         save the caller frame
                    ldd       $04,s     load the stream argument
                    std       GlbVar000F set the output pointer global
                    ldd       #$0001    mode one, stream output
                    std       GlbVar0015 set the output mode
                    leax      $08,s     point past the arguments
                    pshs      x         push the varargs pointer
                    ldd       $08,s     load the format string argument
RunPrintf           pshs      d         push the format string
                    bsr       doprnt    run the formatter
                    leas      4,s        drop the arguments
                    puls      pc,u      restore and return

Sprintf             pshs      u         save the caller frame
                    ldd       $04,s     load the destination buffer argument
                    std       GlbVar000F set the output pointer global
                    ldd       #$0002    mode two, memory buffer output
                    std       GlbVar0015 set the output mode
                    leax      $08,s     point past the arguments
                    pshs      x         push the varargs pointer
                    ldd       $08,s     load the format string argument
                    pshs      d         push the format string
                    bsr       doprnt    run the formatter
                    leas      4,s        drop the arguments
                    clra                high byte zero
                    clrb                form null byte
                    stb       [>GlbVar000F,y] null-terminate the output buffer
                    puls      pc,u      restore and return

doprnt              pshs      u         save the caller frame
                    ldu       $04,s     load the format string pointer
                    leas      -11,s      allocate the local frame
                    bra       FmtScanLoop enter the format scan loop

PutLiteralChar      ldb       $08,s     load the current char
                    lbeq      FmtDone   null terminator ends the format
                    ldb       $08,s     reload the char
                    sex                 sign extend to word
                    pshs      d         push the char
                    lbsr      PutChar   output the literal character
                    leas      2,s        drop the argument
FmtScanLoop         ldb       ,u+       read next format char
                    stb       $08,s     save the current char
                    cmpb      #$25      is it '%'
                    bne       PutLiteralChar no, output literally
                    ldb       ,u+       read the conversion char
                    stb       $08,s     save it
                    clra                high byte zero
                    clrb                form zero
                    std       $02,s     clear the precision
                    std       $06,s     clear the width
                    ldb       $08,s     load the conversion char
                    cmpb      #$2d      is it the '-' flag
                    bne       NoLeftFlag no left-justify flag
                    ldd       #$0001    flag value one
                    std       GlbVar0011 set left-justify flag
                    ldb       ,u+       read the next char
                    stb       $08,s     save the char
                    bra       CheckZeroFlag continue parsing

NoLeftFlag          clra                high byte zero
                    clrb                form zero
                    std       GlbVar0011 clear left-justify flag
CheckZeroFlag       ldb       $08,s     load the char
                    cmpb      #$30      is it the '0' flag
                    bne       PadSpace  no, use space padding
                    ldd       #$0030    pad character '0'
                    bra       StorePadChar store the pad char

PadSpace            ldd       #$0020    pad character space
StorePadChar        std       GlbVar0013 store the pad character
                    bra       CheckWidthDigit parse the width digits

WidthDigit          ldd       $06,s     load the current width
                    pshs      d         push it
                    ldd       #$000A    multiplier ten
                    lbsr      MulEntry  multiply width by ten
                    pshs      d         push the product
                    ldb       $0a,s     load the digit char
                    sex                 sign extend
                    addd      #$FFD0    subtract '0' for digit value
                    addd      ,s++      add to width times ten
                    std       $06,s     store the new width
                    ldb       ,u+       read the next char
                    stb       $08,s     save the char
CheckWidthDigit     ldb       $08,s     load the char
                    sex                 sign extend
                    leax      CtypeTab,y point at char class table
                    leax      d,x       index by the char
                    ldb       ,x        load the class byte
                    cmpb      #$6b      is it a digit class
                    beq       WidthDigit yes, accumulate width digit
                    ldb       $08,s     load the char
                    cmpb      #$2e      is it the '.' precision marker
                    bne       NoPrecision no precision given
                    ldd       #$0001    precision-present flag
                    std       $04,s     set the precision flag
                    bra       CheckPrecDigit parse the precision digits

PrecDigit           ldd       $02,s     load the current precision
                    pshs      d         push it
                    ldd       #$000A    multiplier ten
                    lbsr      MulEntry  multiply precision by ten
                    pshs      d         push the product
                    ldb       $0a,s     load the digit char
                    sex                 sign extend
                    addd      #$FFD0    subtract '0' for digit value
                    addd      ,s++      add to precision times ten
                    std       $02,s     store the new precision
CheckPrecDigit      ldb       ,u+       read the next char
                    stb       $08,s     save the char
                    ldb       $08,s     reload the char
                    sex                 sign extend
                    leax      CtypeTab,y point at char class table
                    leax      d,x       index by the char
                    ldb       ,x        load the class byte
                    cmpb      #$6b      is it a digit class
                    beq       PrecDigit yes, accumulate precision digit
                    bra       DispatchConv done parsing precision

NoPrecision         clra                high byte zero
                    clrb                form zero
                    std       $04,s     clear the precision flag
DispatchConv        ldb       $08,s     load the conversion char
                    sex                 sign extend
                    tfr       d,x       index into dispatch
                    lbra      FmtDispatch dispatch on conversion char

FmtSignedDec        ldd       $06,s     load the width
                    pshs      d         push the width
                    ldx       $13,s     load value-args pointer
                    leax      $02,x     advance past two-byte arg
                    stx       $13,s     store updated pointer
                    ldd       -$02,x    load the argument value
                    pshs      d         push the argument
                    lbsr      FormatSignedDecimal format signed integer
                    bra       StoreConvStr store result and continue

FmtUnsignedDec      ldd       $06,s     load the width
                    pshs      d         push the width
                    ldx       $13,s     load value-args pointer
                    leax      $02,x     advance past two-byte arg
                    stx       $13,s     store updated pointer
                    ldd       -$02,x    load the argument value
                    pshs      d         push the argument
                    lbsr      IntToHex  format unsigned integer
StoreConvStr        std       ,s        save formatted string pointer
                    lbra      FmtOutStr output the field

FmtCharArg          ldx       $11,s     load value-args pointer
                    leax      $02,x     advance past two-byte arg
                    stx       $11,s     store updated pointer
                    ldd       -$02,x    load the argument value
                    lbra      FmtPutOne output the character field

FmtStringArg        ldx       $11,s     load value-args pointer
                    leax      $02,x     advance past two-byte arg
                    stx       $11,s     store updated pointer
                    ldd       -$02,x    load the string argument pointer
                    std       $09,s     save the string pointer
                    ldd       $04,s     load the precision flag
                    beq       FmtOutStrArg no precision, output full string
                    ldd       $09,s     load the string pointer
                    std       $04,s     set the scan pointer
                    bra       StrLenTest enter the length-limit loop

StrLenLoop          ldb       [$09,s]   load char at string pointer
                    beq       StrLenDone end of the string
                    ldd       $09,s     load the string pointer
                    addd      #$0001    advance the pointer
                    std       $09,s     store the pointer
StrLenTest          ldd       $02,s     load remaining precision
                    addd      #$FFFF    decrement it
                    std       $02,s     store it back
                    subd      #$FFFF    restore pre-decrement value
                    bne       StrLenLoop loop while precision remains
StrLenDone          ldd       $06,s     load the width
                    pshs      d         push the width
                    ldd       $0b,s     load range end pointer
                    subd      $06,s     compute the range length
                    pshs      d         push length argument
                    ldd       $08,s     load range start pointer
                    pshs      d         push start pointer argument
                    lbsr      OutputMemRange output the memory range
                    leas      6,s        drop the arguments
                    bra       FmtNextArg continue the format loop

FmtOutStrArg        ldd       $06,s     load the argument value
                    pshs      d         push it
                    ldd       $0b,s     load the string pointer
                    pshs      d         push the string pointer
FmtOutStr           lbsr      OutputStringN output the string
                    leas      4,s        drop the arguments
FmtNextArg          lbra      FmtScanLoop back to the format loop

FmtLiteralChar      ldb       $08,s     load the format character
                    sex                 sign extend to a word
FmtPutOne           pshs      d         push the character
                    lbsr      PutChar   output a single character
                    leas      2,s        drop the argument
                    lbra      FmtScanLoop back to the format loop

FmtDispatch         cmpx      #$0064    is it a 'd' decimal specifier
                    lbeq      FmtSignedDec handle decimal conversion
                    cmpx      #$0078    is it an 'x' hex specifier
                    lbeq      FmtUnsignedDec handle hex conversion
                    cmpx      #$0063    is it a 'c' char specifier
                    lbeq      FmtCharArg handle character output
                    cmpx      #$0073    is it an 's' string specifier
                    lbeq      FmtStringArg handle string output
                    bra       FmtLiteralChar otherwise output the literal character

FmtDone             leas      11,s       drop the format locals
                    puls      pc,u      return from format

FormatSignedDecimal pshs      u,d       save registers and reserve a local
                    leax      OutputBuffer,y   point at the conversion buffer
                    stx       ,s        save the buffer pointer
                    ldd       $06,s     load the signed value
                    bge       ConvertAbsValue non-negative, skip sign handling
                    ldd       $06,s     reload the value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish two's complement
                    std       $06,s     store the absolute value
                    bge       EmitMinusSign negation valid, not the minimum
                    leax      MsgMinInt,pcr point at the -32768 text
                    pshs      x         push the string pointer
                    leax      OutputBuffer,y   point at the buffer
                    pshs      x         push the buffer pointer
                    lbsr      StrCpy    copy the literal string
                    leas      4,s        drop the arguments
                    lbra      FmtArgDone done with this argument

EmitMinusSign       ldd       #$002D    the '-' character
                    ldx       ,s        load the buffer pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save it back
                    stb       -$01,x    store the minus sign
ConvertAbsValue     ldd       $06,s     load the absolute value
                    pshs      d         push value argument
                    ldd       $02,s     load the buffer pointer
                    pshs      d         push the buffer pointer
                    bsr       IntToDecimal convert to decimal digits
                    leas      4,s        drop the arguments
                    leax      OutputBuffer,y   point at the buffer start
                    tfr       x,d       return the buffer pointer
                    lbra      FmtArgDone done with this argument

IntToDecimal        pshs      u,y,x,d   save registers and reserve locals
                    ldu       $0a,s     load the output buffer pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     clear leading-zero flag
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear the digit counter
                    bra       DecNormalizeTest enter the normalize test

DecNormalizeLoop    ldd       ,s        load the counter
                    addd      #$0001    increment it
                    std       ,s        store the counter
                    ldd       $0C,s     load the running remainder
                    subd      Pow10,y   adjust by a power of ten
                    std       $0C,s     store the remainder
DecNormalizeTest    ldd       $0C,s     load the running remainder
                    blt       DecNormalizeLoop keep normalizing while below zero
                    leax      Pow10,y   point at the divisor table
                    stx       $04,s     save the divisor pointer
                    bra       DecPowerLoop enter the digit loop

DecCountLoop        ldd       ,s        load the digit count
                    addd      #$0001    increment the digit
                    std       ,s        store the count
DecSubTest          ldd       $0C,s     load the remainder
                    subd      [$04,s]   subtract the current power of ten
                    std       $0C,s     store the remainder
                    bge       DecCountLoop still fits, count another
                    ldd       $0C,s     load the remainder
                    addd      [$04,s]   restore the last subtraction
                    std       $0C,s     store the remainder
                    ldd       ,s        load the digit value
                    beq       DecDigitSeen zero digit, skip flag
                    ldd       #$0001    set flag
                    std       $02,s     mark significant digit seen
DecDigitSeen        ldd       $02,s     load the significant flag
                    beq       DecStoreDigit none yet, suppress leading zero
                    ldd       ,s        load the digit
                    addd      #$0030    convert to ascii
                    stb       ,u+       store the digit character
DecStoreDigit       clra                clear high byte
                    clrb                clear low byte
                    std       ,s        reset the digit count
                    ldd       $04,s     load the divisor pointer
                    addd      #$0002    advance to the next power
                    std       $04,s     store the pointer
DecPowerLoop        ldd       $04,s     load the divisor pointer
                    cmpd      GlbVar0001 reached the end of table
                    bne       DecSubTest more powers, continue
                    ldd       $0C,s     load the final remainder
                    addd      #$0030    convert last digit to ascii
                    stb       ,u+       store the final digit
                    clra                clear high byte
                    clrb                clear low byte
                    stb       ,u        null terminate the string
                    ldd       $0a,s     return the buffer pointer
                    leas      6,s        drop the locals
                    puls      pc,u      return

IntToHex            pshs      u,x,d     save registers and reserve locals
                    leax      OutputBuffer,y   point at the output buffer
                    stx       $02,s     save the buffer pointer
                    leau      TempDigitBuffer,y   point at the temp digit buffer
HexNibbleLoop       ldd       $08,s     load the value
                    clra                keep only the low byte
                    andb      #$0f      mask the low nibble
                    std       ,s        save the nibble
                    pshs      d         push the nibble
                    ldd       $02,s     reload the nibble
                    cmpd      #$0009    is it greater than nine
                    ble       HexDigitBase decimal-range digit
                    ldd       #$0057    use 'a'-10 base for letters
                    bra       HexStoreNibble combine base and nibble

HexDigitBase        ldd       #$0030    use '0' base for digits
HexStoreNibble      addd      ,s++      add nibble to base, drop temp
                    stb       ,u+       store the hex character
                    ldd       $08,s     load the value
                    lsra                shift right one bit
                    rorb                rotate low byte
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate, value now divided by sixteen
                    anda      #$0f      clear the high nibble
                    std       $08,s     store the shifted value
                    bne       HexNibbleLoop more nibbles remain
                    bra       HexCopyTest enter the reversal loop

HexCopyLoop         ldb       ,u        load a digit from temp buffer
                    ldx       $02,s     load the output pointer
                    leax      $01,x     advance it
                    stx       $02,s     store the pointer
                    stb       -$01,x    copy the digit to output
HexCopyTest         leau      -$01,u    step back through temp buffer
                    pshs      u         push the temp pointer
                    leax      TempDigitBuffer,y   point at temp buffer start
                    cmpx      ,s++      reached the start
                    bls       HexCopyLoop more digits to copy
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [$02,s]   null terminate the output
                    leax      OutputBuffer,y   point at the output buffer
                    tfr       x,d       return the buffer pointer
                    lbra      PutCharCleanup done

OutputStringN       pshs      u         save u
                    ldu       $06,s     load the string pointer
                    leas      -2,s       reserve a local
                    ldd       $06,s     load the string pointer
                    pshs      d         push it
                    lbsr      StrLen    compute the string length
                    leas      2,s        drop the argument
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish negation
                    leau      d,u       point past the string end
                    ldd       GlbVar0011 load the left-justify flag
                    bne       StrCharNext left justify, skip pre-padding
                    bra       StrPrePadTest check the pad width

StrPrePadLoop       ldd       GlbVar0013 load the pad character
                    pshs      d         push the pad character
                    lbsr      PutChar   output the padding
                    leas      2,s        drop the argument
StrPrePadTest       tfr       u,d       load the remaining width
                    leau      -$01,u    decrement it
                    std       -$02,s    save the counter
                    bgt       StrPrePadLoop pad while width remains
                    bra       StrCharNext done pre-padding

StrCharOut          ldd       ,s        load the current character
                    pshs      d         push it
                    lbsr      PutChar   output the character
                    leas      2,s        drop the argument
StrCharNext         ldx       $06,s     load the string pointer
                    leax      $01,x     advance it
                    stx       $06,s     store the pointer
                    ldb       -$01,x    load the next character
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
                    leau      -$01,u    decrement it
                    std       -$02,s    save the counter
                    bgt       StrPostPadLoop pad while width remains
                    lbra      FmtArgDone return

OutputMemRange      pshs      u         save u
                    ldu       $04,s     load the range start pointer
                    leas      -2,s       reserve a local
                    ldd       $0a,s     load the range end
                    subd      $08,s     compute the length
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
RangeByteTest       ldd       $08,s     load the remaining length
                    addd      #$FFFF    decrement it
                    std       $08,s     store the length
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
                    cmpd      #$0002    buffer mode
                    bne       PutCharFile file mode, write out
                    ldd       $04,s     load the character
                    ldx       GlbVar000F load the buffer pointer
                    leax      $01,x     advance it
                    stx       GlbVar000F store the pointer
                    stb       -$01,x    store the character in buffer
                    bra       PutCharDone done

PutCharFile         ldd       GlbVar000F load the file handle
                    pshs      d         push it
                    ldd       $06,s     load the character
                    pshs      d         push it
                    lbsr      PutChar2  write the character to output
PutCharCleanup      leas      4,s        drop the arguments
PutCharDone         puls      pc,u      return

MsgMinInt           fcc       /-32768/
                    fcb       C$NULL
                    ldx       $02,s     load pointer to bignum accumulator
                    leas      -8,s       reserve a local copy
                    ldd       $05,x     load the low word
                    aslb                shift left one bit
                    rola                rotate high byte
                    std       $05,x     store the doubled low word
                    std       $05,s     save a copy
                    ldd       $03,x     load the next word
                    rolb                shift left with carry
                    rola                rotate high byte
                    std       $03,x     store it
                    std       $03,s     save a copy
                    ldd       $01,x     load the next word
                    rolb                shift left with carry
                    rola                rotate high byte
                    std       $01,x     store it
                    std       $01,s     save a copy
                    lda       ,x        load the top byte
                    rola                shift left with carry
                    sta       ,x        store it
                    sta       ,s        save a copy, accumulator now doubled
                    asl       $06,x     shift accumulator left again
                    rol       $05,x     propagate carry
                    rol       $04,x     propagate carry
                    rol       $03,x     propagate carry
                    rol       $02,x     propagate carry
                    rol       $01,x     propagate carry
                    rol       ,x        top byte, value now times four
                    bcs       MulOverflow overflow
                    asl       $06,x     shift left again
                    rol       $05,x     propagate carry
                    rol       $04,x     propagate carry
                    rol       $03,x     propagate carry
                    rol       $02,x     propagate carry
                    rol       $01,x     propagate carry
                    rol       ,x        top byte, value now times eight
                    bcs       MulOverflow overflow
                    ldd       $05,x     load low word times eight
                    addd      $05,s     add the saved copy times two
                    std       $05,x     store, value now times ten
                    ldd       $03,x     load the next word
                    adcb      $04,s     add with carry
                    adca      $03,s     add with carry
                    std       $03,x     store it
                    ldd       $01,x     load the next word
                    adcb      $02,s     add with carry
                    adca      $01,s     add with carry
                    std       $01,x     store it
                    ldb       ,x        load the top byte
                    adcb      ,s        add with carry
                    stb       ,x        store, accumulator times ten
                    bcs       MulOverflow overflow
                    ldb       $0d,s     load the incoming digit
                    andb      #$0f      mask to a nibble
                    clra                clear the high byte
                    addd      $05,x     add digit to the low word
                    std       $05,x     store it
                    ldd       #$0000    zero
                    adcb      $04,x     propagate carry
                    adca      $03,x     propagate carry
                    std       $03,x     store it
                    ldd       #$0000    zero
                    adcb      $02,x     propagate carry
                    adca      $01,x     propagate carry
                    std       $01,x     store it
                    lda       #$00      zero
                    adca      ,x        propagate carry to top byte
                    sta       ,x        store the final accumulator
                    bcs       MulOverflow overflow
                    leas      8,s        drop the local
                    clra                clear high byte
                    clrb                return success
                    rts                 return

MulOverflow         ldd       #$0001    overflow result
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

BuildExprNode       leax      $0a,s     point at first operand slot
                    pshs      x         push it
                    lbsr      ScanIdentifier parse the left operand
                    leas      2,s        drop the argument
                    leax      $0a,s     point at second operand slot
                    pshs      x         push it
                    lbsr      LookupSymbol parse the right operand
                    leas      2,s        drop the argument
                    tfr       d,u       node pointer
                    ldd       ,u        load the node type
                    std       GlbVar005F save the type
                    cmpd      #$0033    is it a specific node type
                    bne       ExprNodeDefault no, build a default node
                    ldd       $08,u     load a node subfield
                    std       GlbVar0061 save the value
                    cmpd      #$003B    matches a special value
                    lbne      ClassifyOpExit no, emit the node
                    ldd       #$003B    special node type
                    std       GlbVar005F set the type
                    ldd       #$000E    special value
                    std       GlbVar0061 set the value
                    lbra      ClassifyOpExit emit the node

ExprNodeDefault     ldd       #$0034    default node type
                    std       GlbVar005F set the type
                    stu       GlbVar0061 store node pointer as value
                    lbra      ClassifyOpExit emit the node

ParseExprOne        leax      ,s        point at a local slot
                    pshs      x         push the pointer argument
                    ldd       #$0001    the flag value
                    pshs      d         push the flag
                    lbsr      ScanNumber evaluate the expression
                    leas      4,s        drop the arguments
                    std       $13,s     store the result
                    bra       ClassifyOpEntry enter operator classification

ClassifyOpReenter   leas      -$15,x    restore stack frame after building node
ClassifyOpEntry     leax      ,s        point at current frame
                    stx       $08,s     save frame pointer local
                    ldx       $13,s     load the operator token type
                    bra       DispatchSpecialTok dispatch on special token

TokLoadPrec         ldd       [$08,s]   load precedence via node pointer
                    bra       SetPrecDefaultOp store it as precedence

TokBuildNode4       ldd       #$0004    request four bytes
                    pshs      d         pass size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop size argument
                    tfr       d,u       keep node pointer
                    leax      ,u        point at the new node
                    pshs      x         pass node pointer
                    ldx       $0a,s     load the current operand
                    lbsr      StoreLong build the subtree
                    stu       GlbVar0061 store node as operand
                    ldd       #$004A    opcode for this operator
                    bra       StoreOpcodeExit store opcode and exit

TokBuildNode8       ldd       #$0008    request eight bytes
                    pshs      d         pass size argument
                    lbsr      AllocMem  allocate a node
                    leas      2,s        drop size argument
                    tfr       d,u       keep node pointer
                    leax      ,u        point at the new node
                    pshs      x         pass node pointer
                    ldx       $0a,s     load the current operand
                    lbsr      SwapNumWork build the subtree
                    stu       GlbVar0061 store node as operand
                    ldd       #$004B    opcode for this operator
                    bra       StoreOpcodeExit store opcode and exit

TokUnknownErr       leax      MsgConstOverflow,pcr point at error message
                    pshs      x         pass message pointer
                    lbsr      PrintErrLoc report the error
                    leas      2,s        drop argument
                    ldd       #$0001    default precedence
SetPrecDefaultOp    std       GlbVar0061 set operator precedence
                    ldd       #$0036    default opcode
StoreOpcodeExit     std       GlbVar005F set operator opcode
                    lbra      ClassifyOpExit done classifying

DispatchSpecialTok  cmpx      #$0001    token type one
                    beq       TokLoadPrec handle it
                    cmpx      #$0008    token type eight
                    beq       TokBuildNode4 handle it
                    cmpx      #$0006    token type six
                    beq       TokBuildNode8 handle it
                    bra       TokUnknownErr otherwise unknown operator

TokOp36Form         lbsr      ParseCharConst parse this operand form
                    ldd       #$0036    opcode for it
                    bra       StoreOpcode5F store and exit

TokOp37Form         lbsr      ParseStringConst parse alternate operand form
                    ldd       #$0037    opcode for it
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
                    cmpb      #$6b      is it the expected class
                    lbne      ClassifyOpExit no, abandon classification
                    leax      ,s        point at frame
                    pshs      x         pass frame pointer
                    ldd       #$0006    size argument
                    pshs      d         pass size argument
                    lbsr      ScanNumber build indexed node
                    leas      4,s        drop arguments
                    std       $13,s     save resulting token
                    leax      $15,s     recompute frame pointer
                    lbra      ClassifyOpReenter re-dispatch on the node

OpAnd               ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkAndNext check ampersand follow-on

OpLogAnd            ldd       #$0047    opcode for logical and
                    std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #$0005    precedence for logical and
                    bra       StorePrecExit set precedence and exit

OpAndAssign         ldd       #$00A7    opcode for and-assign
                    std       GlbVar005F set operator opcode
                    ldd       #$0002    precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

ChkAndNext          cmpx      #$0026    following ampersand
                    beq       OpLogAnd  logical and
                    cmpx      #$003D    following equals
                    beq       OpAndAssign and-assign
                    lbra      ClassifyOpExit plain and, done

OpXorAssign         ldb       GlbVar0065 lookahead character
                    cmpb      #$3d      is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       #$005A    opcode for xor-assign
                    std       GlbVar005F set operator opcode
                    ldd       #$0009    precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

OpOr                ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkOrNext check pipe follow-on

OpLogOr             ldd       #$0048    opcode for logical or
                    std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #$0004    precedence for logical or
                    bra       StorePrecExit set precedence and exit

OpOrAssign          ldd       #$00A8    opcode for or-assign
StoreOpAdvance      std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #$0002    precedence for assignment
StorePrecExit       std       GlbVar0061 set operator precedence
                    lbra      ClassifyOpExit done

ChkOrNext           cmpx      #$007C    following pipe
                    beq       OpLogOr   logical or
                    cmpx      #$003D    following equals
                    beq       OpOrAssign or-assign
                    lbra      ClassifyOpExit plain or, done

OpEqEq              ldb       GlbVar0065 lookahead character
                    cmpb      #$3d      is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       #$005B    opcode for equality
                    std       GlbVar005F set operator opcode
                    lbsr      NextChar  consume second character
                    ldd       #$0009    precedence for equality
                    bra       StorePrecExit set precedence and exit

OpNotEq             ldb       GlbVar0065 lookahead character
                    cmpb      #$3d      is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       #$00A2    opcode for not-equal
                    bra       StoreOpAdvance store and set precedence

OpMulDivModAssign   ldb       GlbVar0065 lookahead character
                    cmpb      #$3d      is it equals
                    lbne      ClassifyOpExit no, done
                    ldd       GlbVar005F current operator opcode
                    addd      #$0050    bias to compound-assign form
                    lbra      StoreOpAdvance store and set precedence

OpLess              ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkLessNext check less-than follow-on

OpShiftLeft         ldd       #$0056    opcode for shift left
                    std       GlbVar005F set operator opcode
                    ldd       #$000B    precedence for shift
                    std       GlbVar0061 set operator precedence
                    lbsr      NextChar  consume second character
                    ldb       GlbVar0065 new lookahead character
                    cmpb      #$3d      is it equals
                    lbne      ClassifyOpExit plain shift, done
                    ldd       #$00A6    opcode for shift-left-assign
                    std       GlbVar005F set operator opcode
                    ldd       #$0002    precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

OpLessEq            ldd       #$005C    opcode for less-or-equal
                    std       GlbVar005F set operator opcode
                    ldd       #$000A    precedence for comparison
                    lbra      StorePrecConsume store precedence and exit

ChkLessNext         cmpx      #$003C    following less-than
                    beq       OpShiftLeft shift left
                    cmpx      #$003D    following equals
                    beq       OpLessEq  less-or-equal
                    lbra      ClassifyOpExit plain less-than, done

OpGreater           ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkGreaterNext check greater-than follow-on

OpShiftRight        ldd       #$0055    opcode for shift right
                    std       GlbVar005F set operator opcode
                    ldd       #$000B    precedence for shift
                    std       GlbVar0061 set operator precedence
                    lbsr      NextChar  consume second character
                    ldb       GlbVar0065 new lookahead character
                    cmpb      #$3d      is it equals
                    lbne      ClassifyOpExit plain shift, done
                    ldd       #$00A5    opcode for shift-right-assign
                    std       GlbVar005F set operator opcode
                    ldd       #$0002    precedence for assignment
                    lbra      StorePrecConsume store precedence and exit

OpGreaterEq         ldd       #$005E    opcode for greater-or-equal
                    std       GlbVar005F set operator opcode
                    ldd       #$000A    precedence for comparison
                    lbra      StorePrecConsume store precedence and exit

ChkGreaterNext      cmpx      #$003E    following greater-than
                    beq       OpShiftRight shift right
                    cmpx      #$003D    following equals
                    beq       OpGreaterEq greater-or-equal
                    lbra      ClassifyOpExit plain greater-than, done

OpPlus              ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkPlusNext check plus follow-on

OpIncrement         ldd       #$003C    opcode for increment
                    std       GlbVar005F set operator opcode
                    ldd       #$000E    precedence for increment
                    bra       StorePrecConsume store precedence and exit

OpPlusAssign        ldd       #$00A0    opcode for plus-assign
                    std       GlbVar005F set operator opcode
                    ldd       #$0002    precedence for assignment
                    bra       StorePrecConsume store precedence and exit

ChkPlusNext         cmpx      #$002B    following plus
                    beq       OpIncrement increment
                    cmpx      #$003D    following equals
                    beq       OpPlusAssign plus-assign
                    lbra      ClassifyOpExit plain plus, done

OpMinus             ldb       GlbVar0065 lookahead character
                    sex                 sign extend
                    tfr       d,x       into x for comparison
                    bra       ChkMinusNext check minus follow-on

OpDecrement         ldd       #$003D    opcode for decrement
                    std       GlbVar005F set operator opcode
                    ldd       #$000E    precedence for decrement
                    bra       StorePrecConsume store precedence and exit

OpMinusAssign       ldd       #$00A1    opcode for minus-assign
                    std       GlbVar005F set operator opcode
                    ldd       #$0002    precedence for assignment
                    bra       StorePrecConsume store precedence and exit

OpArrow             ldd       #$0046    opcode for arrow operator
                    std       GlbVar005F set operator opcode
                    ldd       #$000F    precedence for arrow
StorePrecConsume    std       GlbVar0061 set operator precedence
                    lbsr      NextChar  consume second character
                    lbra      ClassifyOpExit done

ChkMinusNext        cmpx      #$002D    following minus
                    beq       OpDecrement decrement
                    cmpx      #$003D    following equals
                    beq       OpMinusAssign minus-assign
                    cmpx      #$003E    following greater-than
                    beq       OpArrow   arrow operator
                    lbra      ClassifyOpExit plain minus, done

DispatchBinOp       cmpx      #$0045    subscript operator token
                    lbeq      OpSubscript handle it
                    cmpx      #$0041    and operator token
                    lbeq      OpAnd     handle it
                    cmpx      #$0078    xor operator token
                    lbeq      OpXorAssign handle it
                    cmpx      #$0058    or operator token
                    lbeq      OpOr      handle it
                    cmpx      #$0040    equals operator token
                    lbeq      OpEqEq    handle it
                    cmpx      #$0042    bang operator token
                    lbeq      OpNotEq   handle it
                    cmpx      #$0053    star operator token
                    lbeq      OpMulDivModAssign handle it
                    cmpx      #$0054    slash operator token
                    lbeq      OpMulDivModAssign handle it
                    cmpx      #$0059    percent operator token
                    lbeq      OpMulDivModAssign handle it
                    cmpx      #$005D    less-than operator token
                    lbeq      OpLess    handle it
                    cmpx      #$005F    greater-than operator token
                    lbeq      OpGreater handle it
                    cmpx      #$0050    plus operator token
                    lbeq      OpPlus    handle it
                    cmpx      #$0043    minus operator token
                    lbeq      OpMinus   handle it
                    bra       ClassifyOpExit unrecognised, done

DispatchOpTail      cmpx      #$006A    token type six-a
                    lbeq      BuildExprNode handle it
                    cmpx      #$006B    token type six-b
                    lbeq      ParseExprOne handle it
                    cmpx      #$0068    token type six-eight
                    lbeq      TokOp36Form handle it
                    cmpx      #$0069    token type six-nine
                    lbeq      TokOp37Form handle it
                    lbra      ClassifyBinOp otherwise classify binary op

ClassifyOpExit      leas      21,s       release stack frame
                    puls      pc,u      restore and return

InitKeywordTable    pshs      u         save caller frame pointer
                    ldd       #$0006    token code for this keyword
                    pshs      d         pass token code
                    leax      KwDouble,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword in table
                    leas      4,s        drop arguments
                    ldd       #$0005    token code for keyword
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
                    ldd       #$000F    token code for keyword
                    pshs      d         pass token code
                    leax      KwStatic,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$003B    token code for keyword
                    pshs      d         pass token code
                    leax      KwSizeof,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0001    token code for keyword
                    pshs      d         pass token code
                    leax      KwInt,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0001    flag value
                    std       GlbVar0041 mark keyword class active
                    ldd       #$0001    token code for keyword
                    pshs      d         pass token code
                    leax      KwIntB,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0005    token code for keyword
                    pshs      d         pass token code
                    leax      KwFloatB,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0041 clear keyword class flag
                    ldd       #$0002    token code for keyword
                    pshs      d         pass token code
                    leax      KwChar,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$000A    token code for keyword
                    pshs      d         pass token code
                    leax      KwShort,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$000D    token code for keyword
                    pshs      d         pass token code
                    leax      KwAuto,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$000E    token code for keyword
                    pshs      d         pass token code
                    leax      KwExtern,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0021    token code for keyword
                    pshs      d         pass token code
                    leax      KwDirect,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0010    token code for keyword
                    pshs      d         pass token code
                    leax      KwRegister,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$001D    token code for keyword
                    pshs      d         pass token code
                    leax      KwGoto,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0012    token code for keyword
                    pshs      d         pass token code
                    leax      KwReturn,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0013    token code for keyword
                    pshs      d         pass token code
                    leax      KwIf,pcr  keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0014    token code for keyword
                    pshs      d         pass token code
                    leax      KwWhile,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0015    token code for keyword
                    pshs      d         pass token code
                    leax      KwElse,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0016    token code for keyword
                    pshs      d         pass token code
                    leax      KwSwitch,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0017    token code for keyword
                    pshs      d         pass token code
                    leax      KwCase,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0018    token code for keyword
                    pshs      d         pass token code
                    leax      KwBreak,pcr keyword string
                    pshs      x         pass string pointer
                    lbsr      InstallKeyword install keyword
                    leas      4,s        drop arguments
                    ldd       #$0019    token code for keyword
                    pshs      d         pass token code
                    leax      KwContinue,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$001A    token code 0x1a for keyword
                    pshs      d         pass the token code
                    leax      KwDo,pcr  point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$001B    token code 0x1b
                    pshs      d         pass the token code
                    leax      KwDefault,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$001C    token code 0x1c
                    pshs      d         pass the token code
                    leax      KwFor,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$0004    token code 4
                    pshs      d         pass the token code
                    leax      KwStruct,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$0003    token code 3
                    pshs      d         pass the token code
                    leax      KwUnion,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$0007    token code 7
                    pshs      d         pass the token code
                    leax      KwUnsigned,pcr point to keyword name string
                    pshs      x         pass name pointer argument
                    lbsr      InstallKeyword install keyword in symbol table
                    leas      4,s        drop the arguments
                    ldd       #$0008    token code 8
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
                    ldd       #$0001    kind value 1
                    std       ,u        set node kind field
                    ldd       #$000E    value 0x0e
                    std       $08,u     set node value field
                    ldd       #$0002    type value 2
                    std       $02,u     set node type field
                    leax      KwLseek,pcr point to symbol name string
                    pshs      x         pass name pointer argument
                    lbsr      LookupSymbol look up or create symbol node
                    leas      2,s        drop the argument
                    tfr       d,u       symbol node pointer into u
                    ldd       #$0038    kind value 0x38
                    std       ,u        set node kind field
                    ldd       #$000C    value 0x0c
                    std       $08,u     set node value field
                    ldd       #$0004    type value 4
                    std       $02,u     set node type field
                    puls      pc,u      return from keyword setup

ScanIdentifier      pshs      u         save caller frame pointer
                    ldu       $04,s     load output buffer pointer
                    leas      -2,s       reserve char counter local
                    ldd       #$0001    start count at one
                    bra       IdentCopyTest enter copy test

IdentCopyLoop       ldb       GlbVar0065 load current source character
                    stb       ,u+       store character into buffer
                    lbsr      NextChar  advance to next source character
                    ldd       ,s        load current count
                    addd      #$0001    increment character count
IdentCopyTest       std       ,s        save updated count
                    ldb       GlbVar0065 load current source character
                    sex                 sign-extend to word
                    pshs      d         pass the character
                    bsr       IsIdentChar test if identifier character
                    std       ,s++      pop the result
                    beq       LoadFinalCount stop if not identifier char
                    ldd       ,s        load count
                    cmpd      #$0008    compare against eight-char limit
                    ble       IdentCopyLoop keep copying while within limit
LoadFinalCount      ldd       ,s        load final count
                    cmpd      #$0002    was it exactly two chars
                    bne       ClearTerminator skip if not two
                    ldd       #$005F    underscore fill character
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

IsIdentChar         pshs      u         save caller frame pointer
                    ldd       $04,s     load the character argument
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index by character
                    ldb       ,x        load character class
                    cmpb      #$6a      class 0x6a is a letter
                    beq       IdentCharYes yes it is ident char
                    ldd       $04,s     reload character argument
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index by character
                    ldb       ,x        load character class
                    cmpb      #$6b      class 0x6b is digit or underscore
                    bne       IdentCharNo not an identifier char
IdentCharYes        ldd       #$0001    return true
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
                    std       $02,s     save table base local
                    ldd       $0a,s     load name pointer argument
                    pshs      d         pass the name
                    lbsr      HashName  hash the name string
                    leas      2,s        drop argument
                    aslb                double the hash
                    rola                finish doubling
                    addd      $02,s     add table base for bucket slot
                    std       $04,s     save bucket slot address
                    ldu       [$04,s]   load bucket chain head
                    bra       ChainWalk enter chain walk

CompareNames        ldb       $14,u     load node kind byte
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       [$0C,s]   load search kind byte
                    sex                 sign-extend
                    cmpd      ,s++      compare node kind
                    bne       NextInChain skip if kind differs
                    ldd       #$0008    name length eight
                    pshs      d         pass length
                    pshs      u         pass node pointer
                    ldd       #$0014    offset to node name field
                    addd      ,s++      compute name field address
                    pshs      d         pass node name address
                    ldd       $0e,s     load search name pointer
                    pshs      d         pass search name
                    lbsr      StrNCmp   compare the two names
                    leas      6,s        drop arguments
                    std       -$02,s    store compare result
                    beq       SymNodeReady match found so done
NextInChain         ldu       $12,u     follow chain to next node
ChainWalk           stu       -$02,s    save current node pointer
                    bne       CompareNames keep walking while non-null
                    ldu       GlbVar0019 load free list head
                    beq       AllocSymNode allocate fresh if empty
                    ldd       $12,u     load next free node
                    std       GlbVar0019 pop node off free list
                    bra       InitSymNode go initialize node

AllocSymNode        ldd       #$001C    node size 0x1c
                    pshs      d         pass size
                    lbsr      AllocMem  allocate symbol node
                    leas      2,s        drop argument
                    tfr       d,u       node pointer into u
InitSymNode         ldd       #$0008    name length eight
                    pshs      d         pass length
                    ldd       $0C,s     load search name pointer
                    pshs      d         pass name
                    pshs      u         pass node pointer
                    ldd       #$0014    offset to node name field
                    addd      ,s++      compute name field address
                    pshs      d         pass destination
                    lbsr      StrNCpy   copy name into node
                    leas      6,s        drop arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,u        clear node kind field
                    clra                clear high byte
                    clrb                clear low byte
                    std       $08,u     clear node value field
                    ldd       [$04,s]   load current bucket head
                    std       $12,u     link node into chain
                    stu       [$04,s]   make node the bucket head
                    ldd       $04,s     load bucket slot address
                    std       $0e,u     store back pointer in node
SymNodeReady        tfr       u,d       return node pointer in d
                    leas      6,s        release locals
                    puls      pc,u      return to caller

InstallKeyword      pshs      u         save caller frame pointer
                    leas      -9,s       reserve nine-byte name buffer
                    ldd       #$0008    copy length eight
                    pshs      d         pass length
                    ldd       $0f,s     load source name pointer
                    pshs      d         pass source
                    leax      $04,s     point to local buffer
                    pshs      x         pass destination
                    lbsr      StrNCpy   copy name into buffer
                    leas      6,s        drop arguments
                    clra                clear high byte
                    clrb                clear low byte
                    stb       $08,s     null terminate buffer
                    leax      ,s        point to buffer
                    pshs      x         pass name
                    lbsr      LookupSymbol look up or create symbol
                    leas      2,s        drop argument
                    tfr       d,u       node pointer into u
                    ldd       #$0033    keyword kind 0x33
                    std       ,u        set node kind field
                    ldd       $0f,s     load token code argument
                    std       $08,u     set node token field
                    leas      9,s        release buffer
                    puls      pc,u      return to caller

HashName            pshs      u         save caller frame pointer
                    ldu       $04,s     load string pointer
                    leas      -4,s       reserve accumulator locals
                    clra                clear high byte
                    clrb                clear low byte
                    bra       HashNextChar enter hash loop

HashAddLoop         ldd       $02,s     load running hash
                    addd      ,s        add character value
HashNextChar        std       $02,s     save running hash
                    ldb       ,u+       load next character
                    sex                 sign-extend
                    std       ,s        store current char
                    bne       HashAddLoop loop until null terminator
                    ldd       $02,s     load hash sum
                    clra                clear high byte
                    andb      #$7f      mask to bucket range
                    leas      4,s        release locals
                    puls      pc,u      return hash in d

AllocMem            pshs      u,d       save registers
                    ldd       $06,s     load requested size
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
                    addd      $06,s     add size
                    std       GlbVar0068 update heap high-water mark
                    ldd       ,s        load returned pointer
PopRetU             leas      2,s        release local
                    puls      pc,u      return to caller

ScanNumber          pshs      u         save caller frame pointer
                    ldu       $06,s     load result descriptor pointer
                    leas      -16,s      reserve number-parse locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     zero the accumulator
                    leax      $08,s     point to accumulator buffer
                    pshs      x         pass its address
                    bsr       ScanNumBody call with inline data pointer
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
ScanNumBody         puls      x         recover accumulator data pointer
                    lbsr      SwapNumWork initialize big-number accumulator
                    leax      $08,s     point to local accumulator
                    stx       ,s        store accumulator pointer
                    ldd       $14,s     load token type
                    cmpd      #$0006    already a number token
                    bne       CheckLeadingZero skip if not
                    leax      $10,s     point to result slot
                    lbra      FloatEntry return existing number

CheckLeadingZero    ldb       GlbVar0065 load current character
                    cmpb      #$30      is it a leading zero
                    lbne      ClassifyNumChar no, parse decimal digits
                    leas      -6,s       reserve extra locals
                    lbsr      NextChar  advance past the zero
                    ldb       GlbVar0065 load next character
                    cmpb      #$2e      is it a decimal point
                    bne       PrepRadix not a dotted number
                    lbsr      NextChar  advance past the point
                    leax      $16,s     point to float result
                    lbra      FloatEntry go parse float

PrepRadix           leax      $02,s     point to radix buffer
                    pshs      x         pass its address
                    bsr       GotRadixBuf call with inline data pointer
                    fcb       $00,$00,$00,$00
GotRadixBuf         puls      x         recover radix buffer pointer
                    lbsr      StoreLong reset big-number accumulator
                    ldb       GlbVar0065 load next character
                    cmpb      #$78      lowercase x means hex
                    beq       ParseHexLiteral yes, parse hex
                    ldb       GlbVar0065 load character
                    cmpb      #$58      uppercase X means hex
                    lbne      DecNextDigit not hex so parse octal
ParseHexLiteral     leas      -2,s       reserve local
                    bra       HexNextDigit enter hex scan

HexDigitLoop        leax      $04,s     point to accumulator
                    pshs      x         pass it
                    leax      $06,s     point to accumulator
                    pshs      x         pass it
                    ldd       #$0004    shift amount four bits
                    lbsr      LongShiftLeft shift accumulator left by four
                    ldd       $02,x     load accumulator high word
                    pshs      d         pass it
                    ldd       ,x        load accumulator low word
                    pshs      d         pass it
                    ldd       $06,s     load current hex character
                    cmpd      #$0041    compare with letter A
                    blt       HexDigitDec digit is 0-9
                    ldd       #$0037    letter offset 0x37
                    bra       HexDigitAccum use letter offset

HexDigitDec         ldd       #$0030    digit offset 0x30
HexDigitAccum       pshs      d         pass offset
                    ldd       $08,s     load hex character
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

DecDigitLoop        leax      $02,s     point to accumulator
                    pshs      x         pass it
                    leax      $04,s     point to accumulator
                    pshs      x         pass it
                    ldd       #$0003    shift-multiply parameter
                    lbsr      LongShiftLeft multiply accumulator by ten
                    ldd       $02,x     load accumulator high word
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
CheckLongSuffix     leax      $02,s     point to result slot
                    stx       ,s        store result pointer
                    ldb       GlbVar0065 load current character
                    cmpb      #$4C      uppercase L suffix
                    beq       GotLongSuffix yes, long constant
                    ldb       GlbVar0065 load character
                    cmpb      #$6C      lowercase l suffix
                    bne       StoreIntValue no suffix
GotLongSuffix       lbsr      NextChar  advance past suffix
                    leax      $16,s     point to long result slot
                    bra       AdjustStackFrame finish long integer

StoreIntValue       ldd       [,s]      load parsed value
                    bne       FinishInteger nonzero so store it
                    ldd       $04,s     load computed value
                    std       ,u        store into result node
                    ldd       #$0001    mark integer result
                    bra       NumberReturn go return

                    bra       FinishInteger otherwise finish

AdjustStackFrame    leas      -$16,x    adjust frame for long result
FinishInteger       leax      ,u        point to result node
                    pshs      x         pass it
                    leax      $04,s     point to accumulator
                    lbsr      StoreLong store accumulator into node
                    ldd       #$0008    integer result type 8
NumberReturn        leas      22,s       release parse locals
                    puls      pc,u      return to caller

                    bra       ClassifyNumChar reclassify the character

FloatFracDigit      ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    pshs      d         pass character
                    leax      $0a,s     point to conversion buffer
                    pshs      x         pass it
                    lbsr      $549C     convert accumulated float digits
                    leas      4,s        drop arguments
                    std       -$02,s    store result
                    bne       ContinueFloat nonzero, continue float
                    lbsr      NextChar  advance to next character
ClassifyNumChar     ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index by character
                    ldb       ,x        load character class
                    cmpb      #$6b      class 0x6b is a digit
                    beq       FloatFracDigit yes, accumulate fraction digit
                    ldb       GlbVar0065 load character
                    cmpb      #$2e      is it a decimal point
                    beq       IsFloatLiteral yes, it is a float
                    ldb       GlbVar0065 load character
                    cmpb      #$65      exponent letter e
                    beq       IsFloatLiteral yes, it is a float
                    ldb       GlbVar0065 load character
                    cmpb      #$45      exponent letter E
                    lbne      TestZeroValue not a float, handle elsewhere
IsFloatLiteral      ldb       GlbVar0065 load current character
                    cmpb      #$2e      is it a decimal point
                    bne       CheckExponent no decimal point
                    lbsr      NextChar  advance past the point
                    bra       FracDigitTest go accumulate fraction

FloatEntry          leas      -$10,x    adjust frame for float result
                    bra       FracDigitTest go accumulate fraction

FloatFracDigit2     ldb       GlbVar0065 load current character
                    sex                 sign-extend
                    pshs      d         pass character
                    leax      $0a,s     point to conversion buffer
                    pshs      x         pass it
                    lbsr      $549C     convert accumulated float digits
                    leas      4,s        drop arguments
                    std       -$02,s    store result
                    beq       FracDigitCount zero so stop
ContinueFloat       lbsr      NextChar  advance to next character
                    lbra      ValueZero go parse exponent

FracDigitCount      lbsr      NextChar  advance to next character
                    ldd       $02,s     load the decimal exponent
                    addd      #$0001    count one more fractional digit
                    std       $02,s     save the decimal exponent
FracDigitTest       ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    leax      CtypeTab,y point at the character class table
                    leax      d,x       index by the character
                    ldb       ,x        read its character class
                    cmpb      #$6b      is it a digit
                    beq       FloatFracDigit2 loop for the next fraction digit
CheckExponent       ldb       GlbVar0065 load the current character
                    cmpb      #$45      is it exponent 'E'
                    beq       ParseExponent handle the exponent
                    ldb       GlbVar0065 load the current character
                    cmpb      #$65      is it exponent 'e'
                    lbne      FinalizeExponent no exponent, finalize the value
ParseExponent       ldd       #$0001    default exponent sign positive
                    std       $04,s     store the exponent sign
                    lbsr      NextChar  advance past the 'e'
                    ldb       GlbVar0065 load the current character
                    cmpb      #$2b      is it a plus sign
                    bne       CheckExpMinus otherwise check for minus
                    lbsr      NextChar  consume the plus sign
                    bra       ExpDigitInit go read exponent digits

CheckExpMinus       ldb       GlbVar0065 load the current character
                    cmpb      #$2d      is it a minus sign
                    bne       ExpDigitInit no sign present
                    lbsr      NextChar  consume the minus sign
                    clra                clear D
                    clrb                clear D
                    std       $04,s     mark the exponent negative
ExpDigitInit        clra                clear D
                    clrb                clear D
                    std       $06,s     clear the exponent value
                    bra       ExpDigitTest test for exponent digits

ExpDigitLoop        ldd       $06,s     load the exponent value
                    pshs      d         save it
                    ldd       #$000A    base ten multiplier
                    lbsr      MulEntry  multiply accumulator by ten
                    pshs      d         save the product
                    ldb       GlbVar0065 load the current digit
                    sex                 sign extend to word
                    addd      #$FFD0    convert ascii digit to value
                    addd      ,s++      add into the exponent accumulator
                    std       $06,s     store the exponent value
                    lbsr      NextChar  advance to next character
ExpDigitTest        ldb       GlbVar0065 load the current character
                    sex                 sign extend to word
                    leax      CtypeTab,y point at the character class table
                    leax      d,x       index by the character
                    ldb       ,x        read its character class
                    cmpb      #$6b      is it a digit
                    beq       ExpDigitLoop loop for the next exponent digit
                    ldd       $06,s     load the exponent value
                    cmpd      #$0028    clamp exponent at forty
                    lbge      ValueZero too large, use zero
                    ldd       $02,s     load the fractional place count
                    pshs      d         save it
                    ldd       $06,s     load the exponent value
                    beq       ExpPositive positive exponent branch
                    ldd       $08,s     load the base exponent
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish two's complement
                    bra       ExpCombine combine with the place count

ExpPositive         ldd       $08,s     load the base exponent
ExpCombine          addd      ,s++      add the place count
                    std       $02,s     store the net exponent
FinalizeExponent    ldd       $02,s     load the net exponent
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish two's complement
                    ldx       ,s        point at the number struct
                    stb       $07,x     store exponent into the struct
                    ldb       [,s]      load the type byte
                    clra                clear high byte
                    andb      #$7f      mask off the sign bit
                    stb       [,s]      store the type flag back
                    leax      ,u        point at the result buffer
                    pshs      x         pass it as argument
                    leax      $0a,s     point at the number struct
                    lbsr      SwapNumWork build the float constant
                    ldd       #$0006    result is float type
                    lbra      NumReturn return the constant

TestZeroValue       ldb       [,s]      test number byte zero
                    bne       ValueZero nonzero, value is not zero
                    ldx       ,s        point at the number struct
                    ldb       $01,x     test byte one
                    bne       ValueZero nonzero, value is not zero
                    ldx       ,s        point at the number struct
                    ldb       $02,x     test byte two
                    beq       CheckLongSuffix2 all zero, value is zero
ValueZero           clra                clear D
                    clrb                clear D
                    lbra      NumReturn return zero value

CheckLongSuffix2    ldb       GlbVar0065 load the current character
                    cmpb      #$6C      is it 'l' suffix
                    beq       LongSuffix handle the long suffix
                    ldb       GlbVar0065 load the current character
                    cmpb      #$4C      is it 'L' suffix
                    bne       CheckIntRange no suffix, check int range
LongSuffix          leas      -2,s       reserve two bytes
                    lbsr      NextChar  consume the suffix
                    bra       BuildLongConst build the long constant

AllocTwoBytes       leas      -$12,x    reserve two bytes
BuildLongConst      ldd       $02,s     load the value
                    addd      #$0003    bias by three
                    std       ,s        store into the slot
                    leax      ,u        point at the result buffer
                    pshs      x         pass it as argument
                    ldx       $02,s     load the value pointer
                    lbsr      StoreLong build the long constant
                    ldd       #$0008    result is long type
                    bra       IntLongReturn return the constant

CheckIntRange       ldx       ,s        point at the number struct
                    ldb       $03,x     test byte three
                    bne       NeedLong  nonzero, value needs long
                    ldx       ,s        point at the number struct
                    ldb       $04,x     test byte four
                    beq       BuildIntConst fits in an int
NeedLong            leax      $10,s     point past the struct
                    bra       AllocTwoBytes build the long constant

BuildIntConst       leas      -2,s       reserve two bytes
                    ldd       $02,s     load the value
                    addd      #$0005    bias by five
                    std       ,s        store into the slot
                    ldd       [,s]      load the int value
                    std       ,u        store into the result buffer
                    ldd       #$0001    result is int type
IntLongReturn       leas      18,s       unwind the stack frame
                    puls      pc,u      return

NumReturn           leas      16,s       unwind the stack frame
                    puls      pc,u      return

ParseCharConst      pshs      u         save frame pointer
                    lbsr      NextChar  advance past the opening quote
                    ldb       GlbVar0065 load the current character
                    cmpb      #$5C      is it a backslash escape
                    bne       CharConstPlain plain character
                    lbsr      ParseEscape parse the escape sequence
                    std       GlbVar0061 store the character value
                    bra       CharConstClose check the closing quote

CharConstPlain      ldb       GlbVar0065 load the character
                    sex                 sign extend to word
                    std       GlbVar0061 store the character value
                    lbsr      NextChar  advance to next character
CharConstClose      ldb       GlbVar0065 load the current character
                    cmpb      #$27      is it the closing quote
                    lbeq      ConstClose yes, finish the constant
                    leax      MsgUntermCharConst,pcr point at the error message
                    pshs      x         pass it as argument
                    lbsr      PrintErrLoc report the error
                    leas      2,s        discard the argument
                    lbra      ConstReturn return

ParseStringConst    pshs      u         save frame pointer
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

SegDispatch         stx       -$02,s    save the section selector
                    beq       AllocStringLabel section zero, need a label
                    cmpx      #$0002    section two, need a label
                    lbeq      AllocStringLabel same, need a label
                    cmpx      #$0001    is it section one
                    beq       LoadConstSeg use the constant section
StringEmitInit      clra                clear D
                    clrb                clear D
                    std       GlbVar0017 clear the string length
                    ldd       GlbVar000B load the section selector
                    cmpd      #$0001    is it section one
                    beq       StringBody skip the label emit
                    ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       #$006C    constant section number
                    pshs      d         pass it as argument
                    lbsr      PutChar2  switch output section
                    leas      4,s        clean up arguments
                    ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    next label number
                    std       GlbVar002B save the label counter
                    std       GlbVar0061 store the label number
                    pshs      d         pass it as argument
                    lbsr      PutWord   emit the string label
                    leas      4,s        clean up arguments
StringBody          lbsr      NextChar  advance past the opening quote
                    ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       #$0073    string section number
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
                    cmpb      #$5C      is it a backslash escape
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
                    cmpb      #$22      is it the closing quote
                    bne       StringCharLoop no, loop for the next character
StringTerminate     ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    clra                clear D
                    clrb                clear D
                    pshs      d         pass the null terminator
                    lbsr      PutChar2  emit the terminating null
                    leas      4,s        clean up arguments
                    ldd       GlbVar0017 load the string length
                    addd      #$0001    count the terminator
                    std       GlbVar0017 store the string length
ConstClose          lbsr      NextChar  advance past the closing quote
ConstReturn         puls      pc,u      return

EmitStringChar      pshs      u         save frame pointer
                    ldd       $04,s     load the character value
                    beq       EmitBackslash zero, emit escaped
                    ldd       $04,s     load the character value
                    cmpd      #$005C    is it a backslash
                    bne       EmitCharByte emit it plainly
EmitBackslash       ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       #$005C    backslash to escape it
                    pshs      d         pass it as argument
                    lbsr      PutChar2  emit the backslash
                    leas      4,s        clean up arguments
EmitCharByte        ldd       GlbVar001B load the output section
                    pshs      d         pass it as argument
                    ldd       $06,s     load the character value
                    pshs      d         pass it as argument
                    lbsr      PutChar2  emit the character
                    leas      4,s        clean up arguments
                    ldd       GlbVar0017 load the string length
                    addd      #$0001    count the character
                    std       GlbVar0017 store the string length
                    puls      pc,u      return

EmitCharConst       pshs      u         save frame pointer
                    lbsr      EmitStar  prepare the output buffer
                    ldd       $04,s     load the character value
                    pshs      d         pass it as argument
                    leax      FmtRzb,pcr point at the format string
                    pshs      x         pass it as argument
                    ldd       GlbVar001B load the output stream
                    pshs      d         pass it as argument
                    lbsr      fprintf   print the character constant
                    leas      6,s        clean up arguments
                    puls      pc,u      return

ParseEscape         pshs      u,d       save frame pointer and char
                    lbsr      NextChar  advance past the backslash
                    ldb       GlbVar0065 load the escape character
                    sex                 sign extend to word
                    tfr       d,u       keep the escape character
                    lbsr      NextChar  advance to next character
                    leax      ,u        load the escape character
                    bra       EscDispatch dispatch on the escape

EscLinefeed         ldd       #$000A    linefeed value
                    lbra      OctalEscapeExit return the escape value

EscTab              ldd       #$0009    tab value
                    lbra      OctalEscapeExit return the escape value

EscBackspace        ldd       #$0008    backspace value
                    lbra      OctalEscapeExit return the escape value

EscVertTab          ldd       #$000B    vertical tab value
                    lbra      OctalEscapeExit return the escape value

EscCarriageRet      ldd       #$000D    carriage return value
                    lbra      OctalEscapeExit return the escape value

EscFormFeed         ldd       #$000C    form feed value
                    lbra      OctalEscapeExit return the escape value

EscNewlineSpace     ldd       #$0020    space value
                    lbra      OctalEscapeExit return the escape value

EscDispatch         cmpx      #$006E    is escape 'n'
                    beq       EscCarriageRet yes, carriage return
                    cmpx      #$006C    is escape 'l'
                    beq       EscLinefeed yes, linefeed
                    cmpx      #$0074    is escape 't'
                    beq       EscTab    yes, tab
                    cmpx      #$0062    is escape 'b'
                    beq       EscBackspace yes, backspace
                    cmpx      #$0076    is escape 'v'
                    beq       EscVertTab yes, vertical tab
                    cmpx      #$0072    is escape 'r'
                    lbeq      EscCarriageRet yes, carriage return
                    cmpx      #$0066    is escape 'f'
                    beq       EscFormFeed yes, form feed
                    cmpx      #$000D    is escaped newline
                    beq       EscNewlineSpace yes, becomes a space
                    cmpu      #$0078    is escape 'x' for hex
                    lbne      CheckDecEscape otherwise try decimal
                    leas      -2,s       reserve two bytes
                    clra                clear D
                    clrb                clear D
                    std       $02,s     clear the hex accumulator
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
                    ldd       $02,s     load the digit character
                    cmpd      #$0041    is it a letter digit
                    bge       HexLetterDigit yes, convert from letter
                    ldd       $02,s     load the digit character
                    addd      #$FFD0    convert '0'-'9' to value
                    bra       HexAddDigit add into the accumulator

HexLetterDigit      ldd       $02,s     load the digit character
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
                    ldd       $02,s     load the digit count
                    addd      #$0001    increment it
                    std       $02,s     save the digit count
                    subd      #$0001    restore the count
                    cmpd      #$0002    limit to two hex digits
                    blt       HexDigitLoop2 loop for the next hex digit
HexDone             leas      2,s        discard the count
                    lbra      OctalEscapeDone return the hex value

CheckDecEscape      cmpu      #$0064    is escape 'd' for decimal
                    bne       ParseOctEscape otherwise treat as octal
                    clra                clear D
                    clrb                clear D
                    std       ,s        clear the decimal accumulator
                    tfr       d,u       start accumulator at zero
                    bra       DecDigitTest test for decimal digits

DecDigitLoop2       pshs      u         save the accumulator
                    ldd       #$000A    base ten multiplier
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
                    cmpb      #$6b      is it a digit
                    lbne      OctalEscapeDone no, return the value
                    ldd       ,s        load the digit count
                    addd      #$0001    increment it
                    std       ,s        save the digit count
                    subd      #$0001    restore the count
                    cmpd      #$0003    limit to three decimal digits
                    blt       DecDigitLoop2 loop for the next decimal digit
                    bra       OctalEscapeDone return the value

ParseOctEscape      pshs      u         save frame pointer
                    lbsr      IsOctalDigit classify the octal digit
                    std       ,s++      store the classification
                    beq       OctalEscapeDone not octal, return the char
                    leau      -$30,u    convert the first octal digit
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
                    addd      #$0001    increment the count
                    std       ,s        save the count
                    subd      #$0001    restore the count value
                    cmpd      #$0003    allow up to three octal digits
                    blt       OctDigitLoop loop to accumulate another digit
OctalEscapeDone     tfr       u,d       return the accumulated escape value
OctalEscapeExit     leas      2,s        drop the local
                    puls      pc,u      return

IsOctalDigit        pshs      u         save frame pointer
                    ldb       $05,s     load the character argument
                    cmpb      #$37      compare to '7'
                    bgt       NotDigit  above octal range, not a digit
                    ldb       $05,s     reload the character
                    cmpb      #$30      compare to '0'
                    blt       NotDigit  below octal range, not a digit
                    ldd       #$0001    result is true
                    bra       DigitTestRet return

IsHexDigit          pshs      u         save frame pointer
                    ldb       $05,s     load the character argument
                    sex                 extend to word
                    leax      CtypeTab,y point at the character-class table
                    leax      d,x       index by the character
                    ldb       ,x        load the class byte
                    cmpb      #$6b      is it the digit class
                    beq       HexDigitOk yes, accept it
                    ldb       $05,s     reload the character
                    clra                clear the high byte
                    andb      #$5f      force to uppercase
                    stb       $05,s     save uppercased character
                    cmpd      #$0041    compare to 'A'
                    blt       NotDigit  below hex letters, reject
                    ldb       $05,s     reload the character
                    cmpb      #$46      compare to 'F'
                    bgt       NotDigit  above hex letters, reject
HexDigitOk          ldb       $05,s     load the character value
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
KwInt               fcb       $69,$6E,$74
                    fcb       C$NULL
KwIntB              fcb       $69,$6E,$74
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
KwIf                fcb       $69,$66
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
KwDo                fcb       $64,$6F
                    fcb       C$NULL
KwDefault           fcc       /default/
                    fcb       C$NULL
KwFor               fcb       $66,$6F,$72
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
StrModeWPlus        fcb       $77,$2B
                    fcb       C$NULL
MsgCantOpenStrings  fcc       /can't open strings file/
                    fcb       C$NULL
MsgUntermString     fcc       /unterminated string/
                    fcb       C$NULL
FmtRzb              fcc       / rzb %d/
                    fcb       C$CR,C$NULL
InitScanBuffer      pshs      u         save frame pointer
                    leax      LineBuffer,y   point at the line buffer
                    stx       GlbVar006A set the current line pointer
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       LineBuffer,y   clear first buffer byte
                    ldd       #$0020    space character
                    bra       StoreCurChar store it as current char

SkipWhitespace      pshs      u         save frame pointer
                    bra       SkipWsCheck go check the current char

SkipWsLoop          bsr       NextChar  fetch the next character
SkipWsCheck         ldb       GlbVar0065 load current char
                    cmpb      #$20      is it a space
                    beq       SkipWsLoop skip the whitespace
                    ldb       GlbVar0065 reload current char
                    cmpb      #$09      is it a tab
                    lbeq      SkipWsLoop skip the whitespace
                    puls      pc,u      return

NextChar            pshs      u         save frame pointer
                    ldx       GlbVar006A load the line pointer
                    leax      $01,x     advance past this char
                    stx       GlbVar006A save updated pointer
                    ldb       -$01,x    load the character
                    stb       GlbVar0065 store as current char
                    bne       NextCharRet non-null, done
                    bsr       RefillLine end of line, refill buffer
StoreCurChar        stb       GlbVar0065 store the returned char
NextCharRet         puls      pc,u      return

RefillLine          pshs      u         save frame pointer
                    leas      -8,s       reserve locals
                    ldd       GlbVar001D check the init flag
                    bne       RefillNotFirst already started
                    ldd       #$0001    mark as initialized
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
                    cmpb      #$23      is it a '#' directive
                    lbne      BumpLineNum not a directive, count line
                    ldx       GlbVar006A reload line pointer
                    ldb       $01,x     load the directive code
                    sex                 extend to word
                    std       $04,s     save the directive code
                    lbsr      GetSourceLine read the argument line
                    std       -$02,s    save it
                    lbeq      LineEof   end of file
                    ldx       $04,s     reload the directive code
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
                    std       -$02,s    save it
                    lbne      ReadLineLoop not eof, keep reading
                    lbra      LineEof   end of file

DirLineMarker       leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    leax      NameBuffer,y   point at the name buffer
                    pshs      x         push as argument
                    lbsr      StrCpy    copy line into name
                    leas      4,s        drop arguments
                    lbsr      GetSourceLine read the next line
                    std       -$02,s    save it
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
                    std       -$02,s    save it
                    beq       LineEof   end of file
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    lbsr      ParseDecimal parse first number
                    leas      2,s        drop argument
                    std       $06,s     save it
                    lbsr      GetSourceLine read the next line
                    std       -$02,s    save it
                    beq       LineEof   end of file
                    leax      LineBuffer,y   point at the line buffer
                    pshs      x         push as argument
                    lbsr      ParseDecimal parse second number
                    leas      2,s        drop argument
                    std       $02,s     save the count
                    lbsr      GetSourceLine read the next line
                    std       -$02,s    save it
                    bne       BuildMarker not eof, proceed
LineEof             ldd       #$FFFF    return end of file
                    lbra      RefillExit exit

BuildMarker         ldd       $06,s     load the first value
                    beq       BuildPlainMarker zero, emit plain form
                    ldd       $06,s     reload the value
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
                    ldd       #$0020    space character
                    pshs      d         push as argument
                    lbsr      PutChar2  emit a padding space
                    leas      4,s        drop arguments
EmitSpaceNext       ldd       $02,s     load remaining count
                    addd      #$FFFF    decrement it
                    std       $02,s     save the count
                    subd      #$FFFF    test the count
                    bne       EmitSpaceLoop more spaces to emit
                    leax      MsgCaret2,pcr format string
                    pshs      x         push as argument
                    lbsr      PutStringLine emit it
                    leas      2,s        drop argument
CheckDirType1       ldd       $04,s     load the directive code
                    cmpd      #$0031    is it type one
                    lbne      ReadLineLoop no, continue reading
                    lbsr      EmitDataInit handle the special case
                    lbra      ReadLineLoop continue reading

DispatchDirective   cmpx      #$0035    directive code 0x35
                    lbeq      DirLineNum handle line-number directive
                    cmpx      #$0036    directive code 0x36
                    lbeq      DirFlushHook handle flush directive
                    cmpx      #$0032    directive code 0x32
                    lbeq      DirEmitLine handle emit-line directive
                    cmpx      #$0037    directive code 0x37
                    lbeq      DirIncludeFile handle include directive
                    cmpx      #$0050    directive code 0x50
                    lbeq      DirLineMarker handle line-marker directive
                    cmpx      #$0030    directive code 0x30
                    lbeq      DirRangeMarker handle range-marker directive
                    cmpx      #$0031    directive code 0x31
                    lbeq      DirRangeMarker handle range-marker directive
                    lbra      ReadLineLoop unknown, continue reading

BumpLineNum         ldd       GlbLineNum load the line number
                    addd      #$0001    advance one line
                    std       GlbLineNum save the line number
RetSpace            ldd       #$0020    return a space
RefillExit          leas      8,s        drop locals
                    puls      pc,u      return

ParseDecimal        pshs      u         save frame pointer
                    ldu       $04,s     load the string pointer argument
                    leas      -4,s       reserve locals
                    clra                clear the high byte
                    clrb                result starts at zero
                    bra       ParseDecStore go read first char

ParseDecLoop        ldd       ,s        load the running total
                    pshs      d         push it
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  do the multiply
                    pshs      d         push the product
                    ldd       $04,s     load the digit char
                    addd      #$FFD0    subtract '0'
                    addd      ,s++      add to total times ten
ParseDecStore       std       ,s        save the total
                    ldb       ,u+       load the next char
                    sex                 extend to word
                    std       $02,s     save the char
                    leax      CtypeTab,y point at character-class table
                    leax      d,x       index by the char
                    ldb       ,x        load the class byte
                    cmpb      #$6b      is it a digit
                    beq       ParseDecLoop yes, accumulate it
                    ldd       ,s        load the final total
                    leas      4,s        drop locals
                    puls      pc,u      return

GetSourceLine       pshs      u,d       save frame and value
                    leau      LineBuffer,y   point at the line buffer
                    ldd       GlbVar0023 load the source file handle
                    pshs      d         push as argument
                    lbsr      GetChar   read a character
                    leas      2,s        drop argument
                    std       ,s        save it
                    cmpd      #$FFFF    end of file
                    lbne      GetLineCheckFull got a char, store it
                    ldx       GlbVar0023 load the file handle
                    ldd       $06,x     check the file flags
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

GetLineClassify     cmpx      #$000D    is it a carriage return
                    beq       GetLineDone end of line
                    cmpx      #$FFFF    is it end of file
                    lbeq      GetLineDone end of line
                    bra       GetLineStore store the character

GetLineCheckFull    cmpu      IsBufferFull,y   is the buffer full
                    bne       GetLineNext room left, continue
                    ldd       GlbLineNum load the line number
                    addd      #$0001    advance one line
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
FmtS                fcb       $25,$73
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
EmitStringTable     pshs      u         save the frame pointer
                    lbsr      DumpStrings dump the string constant table
                    lbra      EmitSectEnd emit the section end and return

EmitRmbVar          pshs      u         save the frame pointer
                    ldd       $08,s     load the section flag argument
                    pshs      d         pass it
                    lbsr      EmitSectLetter emit the data or variable section letter
                    leas      2,s        drop the argument
                    lbsr      EmitStar  emit leading indentation
                    ldd       $04,s     load the symbol argument
                    pshs      d         pass it
                    lbsr      EmitTempRef emit the symbol name
                    leas      2,s        drop the argument
                    ldd       $06,s     load the size argument
                    pshs      d         pass the size
                    leax      MsgRmb,pcr point to the " rmb %d" format
                    pshs      x         pass the format string
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the rmb directive
                    bra       EmitRmbCleanup clean up and finish

EmitLabelColon      pshs      u         save the frame pointer
                    ldd       $08,s     load the section flag
                    pshs      d         pass it
                    lbsr      EmitSectLetter emit the section letter
                    leas      2,s        drop the argument
                    ldd       #$003A    colon separator character
                    bra       EmitLabelRmbTail join the common emit path

EmitLabelSpace      pshs      u         save the frame pointer
                    ldd       $08,s     load the section flag
                    pshs      d         pass it
                    lbsr      EmitSectLetter emit the section letter
                    leas      2,s        drop the argument
                    ldd       #$0020    space separator character
EmitLabelRmbTail    pshs      d         pass the separator character
                    ldd       $08,s     load an argument
                    pshs      d         pass it
                    ldd       $08,s     load an argument
                    pshs      d         pass it
                    bsr       EmitLabeledRmb emit the labelled rmb line
EmitRmbCleanup      leas      6,s        drop the three arguments
EmitSectEnd         lbsr      EmitEndLetter emit the end-of-section letter
                    puls      pc,u      restore and return

EmitLabeledRmb      pshs      u         save the frame pointer
                    lbsr      EmitStar  emit leading indentation
                    ldd       $06,s     load the size argument
                    pshs      d         pass it
                    ldb       $0b,s     load the separator character byte
                    sex                 sign-extend to a word
                    pshs      d         pass the separator
                    ldd       $08,s     load the base offset
                    addd      #$0014    add the fixed bias
                    pshs      d         pass the computed value
                    leax      MsgLabelRmb,pcr point to the "%.8s%c rmb %d" format
                    pshs      x         pass the format
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the labelled rmb line
                    leas      10,s       drop the arguments
                    puls      pc,u      restore and return

EmitStaticSym       pshs      u         save the frame pointer
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       #$0053    static marker character
                    pshs      d         pass the character
                    lbsr      PutChar2  write the character
                    leas      4,s        drop the arguments
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       $08,s     load the argument character
                    pshs      d         pass the character
                    lbsr      PutChar2  write the character
                    leas      4,s        drop the arguments
                    ldd       GlbVar0035 check the flag global
                    bne       EmitNameField skip label numbering if set
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       GlbVar002B load the label counter
                    addd      #$0001    bump it
                    std       GlbVar002B store it back
                    pshs      d         pass the new label number
                    lbsr      PutWord   print the label number
                    leas      4,s        drop the arguments
EmitNameField       clra                zero
                    clrb                terminator character
                    pshs      d         pass it
                    ldd       $06,s     load the name pointer
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
                    ldd       $0a,s     load the value argument
                    pshs      d         pass it
                    lbsr      PutWord   print the value
                    bra       EmitEndCleanup clean up and return

EmitPublicLabel     pshs      u         save the frame pointer
                    ldd       #$0070    public marker character
                    pshs      d         pass it
                    lbsr      EmitCharOut write the character
                    leas      2,s        drop the argument
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       $08,s     load the value argument
                    pshs      d         pass it
                    lbsr      PutWord   print the value
                    leas      4,s        drop the arguments
                    clra                zero
                    clrb                terminator character
                    pshs      d         pass it
                    ldd       $06,s     load the name pointer
                    pshs      d         pass it
                    leax      MsgNameFmt2,pcr point to the "%.8s%c" format
                    pshs      x         pass the format
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    lbsr      fprintf   print the truncated name
                    leas      8,s        drop the arguments
                    puls      pc,u      restore and return

EmitEndMarker       pshs      u         save the frame pointer
                    ldd       GlbVar0035 check the flag global
                    bne       EmitEndDone skip if it is set
                    ldd       GlbVar0025 load the output stream
                    pshs      d         pass the stream
                    ldd       #$0045    end marker character
                    pshs      d         pass it
                    lbsr      PutChar2  write the character
EmitEndCleanup      leas      4,s        drop the arguments
EmitEndDone         puls      pc,u      restore and return

EmitFcb             pshs      u         save the frame pointer
                    lbsr      EmitStar  emit leading indentation
                    leax      MsgFcb,pcr point to the "fcb " directive
                    bra       EmitDirective join the common emit path

EmitFdb             pshs      u         save the frame pointer
                    lbsr      EmitStar  emit leading indentation
                    leax      MsgFdb,pcr point to the "fdb " directive
EmitDirective       pshs      x         pass the directive string
                    lbsr      EmitSpaceText emit the directive
                    lbra      EmitCleanup2 clean up and return

EmitComment         pshs      u         save the frame pointer
                    lbsr      EmitStar  emit leading indentation
                    leax      MsgStarSpace,pcr point to the "* " comment prefix
                    pshs      x         pass the string
                    lbsr      EmitText  emit the comment prefix
                    lbra      EmitCleanup2 clean up and return

EmitSectLetter      pshs      u         save the frame pointer
                    ldd       $04,s     load the section flag argument
                    beq       EmitVarLetter variable section if zero
                    ldd       #$0064    data section letter
                    bra       EmitLetterTail emit it

EmitVarLetter       ldd       #$0076    variable section letter
                    bra       EmitLetterTail emit it

EmitEndLetter       pshs      u         save the frame pointer
                    ldd       #$0065    end section letter
EmitLetterTail      pshs      d         pass the letter
                    lbsr      EmitCharOut write the character
                    lbra      EmitCleanup2 clean up and return

PlaceSymbol         pshs      u         save the frame pointer
                    ldd       $04,s     load the symbol pointer argument
                    pshs      d         pass it
                    lbsr      FlushStream resolve the symbol
                    leas      2,s        drop the argument
                    ldx       $04,s     reload the symbol pointer
                    ldd       $02,x     load its base value
                    ldx       $04,s     reload the symbol pointer
                    addd      $0b,x     add its size field
                    ldx       $04,s     reload the symbol pointer
                    std       $04,x     store the computed address
                    std       [$04,s]   store through the pointer too
                    ldx       $04,s     reload the symbol pointer
                    ldd       $06,x     load the flag word
                    anda      #$FE      clear a flag bit
                    andb      #$EF      clear another flag bit
                    std       $06,x     store the flags back
                    clra                zero
                    clrb                zero
                    pshs      d         pass a zero argument
                    clra                zero
                    clrb                zero
                    pshs      d         pass a zero argument
                    pshs      d         pass a zero argument
                    ldx       $0a,s     reload the symbol pointer
                    ldd       $08,x     load a field
                    pshs      d         pass it
                    lbsr      SeekFile  process the symbol
                    leas      8,s        drop the arguments
                    ldd       ResultLowWord,y   load the result value
                    puls      pc,u      restore and return

DumpStrings         pshs      u         save the frame pointer
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
                    ldd       $06,x     load the flag word
                    clra                isolate the low byte
                    andb      #$20      test the flag bit
                    beq       DumpStringEmit skip if clear
                    leax      MsgDumpStrings,pcr point to the "dumpstrings" text
                    ldd       $06,x     reload the flag word
                    clra                isolate the low byte
                    andb      #$20      test the flag bit
DumpStringEmit      ldd       GlbVar006C load the table head
                    pshs      d         pass it
                    lbsr      CloseFile look up the label number
                    leas      2,s        drop the argument
                    leax      NameBuf,y point to the work buffer
                    pshs      x         pass it
                    lbsr      DeleteFile emit the string label
                    bra       EmitCleanup2 clean up and return

EmitDataInit        pshs      u,d       save the frame and reserve a local
                    ldd       Errno,y   load the current value
                    beq       DefaultCount default if zero
                    ldd       Errno,y   reload the value
                    bra       EmitDataBody use it

DefaultCount        ldd       #$0001    default value of one
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
                    lbsr      DeleteFile emit the string label
                    leas      2,s        drop the argument
EmitDataPtr         ldd       GlbVar001F load another global pointer
                    beq       EmitDataFinish skip if null
                    ldd       GlbVar0023 load the associated global
                    pshs      d         pass it
                    lbsr      CloseFile look up the label number
                    leas      2,s        drop the argument
                    ldd       GlbVar001F reload the pointer
                    pshs      d         pass it
                    lbsr      DeleteFile emit the label
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
MsgStarSpace        fcb       $2A,$20
                    fcb       C$NULL
MsgDumpStrings      fcc       /dumpstrings/
                    fcb       C$NULL
LoadNumWork         pshs      u         save the frame pointer
                    leau      NumberWorkArea,y   point to the number work area
                    ldd       ,x        copy the first word
                    std       ,u        into the work area
                    ldd       $02,x     copy the second word
                    std       $02,u     into the work area
                    ldd       $04,x     copy the third word
                    std       $04,u     into the work area
                    ldd       $06,x     copy the fourth word
                    std       $06,u     into the work area
                    tfr       u,x       return the work area pointer
                    puls      pc,u      restore and return

NegateNumWork       bsr       LoadNumWork copy the number into the work area
                    lda       ,x        load the sign byte
                    eora      #$80      flip the sign bit
                    sta       ,x        store it back
                    rts                 return

GetNumValue         bsr       NormalizeNum normalise the number
                    ldd       $02,x     fetch the resulting value
                    rts                 return

NormalizeNum        lda       ,x        load the sign byte
                    pshs      a         save it
                    bsr       LoadNumWork copy the number into the work area
                    bsr       ConvertDigits convert the digits
                    leax      $03,x     advance past the header
                    lda       ,s+       recover the sign byte
                    bpl       NormNumDone positive, so done
                    lbra      LongNegDo negate the result

NormNumDone         rts                 return

ConvertDigits       lda       $07,x     load the digit count
                    blt       PackBinary branch if already binary
                    pshs      x         save the base pointer
                    leax      $07,x     point past to the digits
                    pshs      x,a       save the pointer and count
                    bra       DigitCountLoop enter the conversion loop

DigitMulLoop        ldx       $01,s     load the digit pointer
                    ldb       #$06      six bytes to process
                    pshs      b         save the byte counter
                    clra                clear the carry accumulator
ByteMulLoop         pshs      a         save the carry
                    lda       #$0a      multiply by ten
                    ldb       ,-x       take the next byte
                    mul                 times ten
                    addb      ,s+       add the carried value
                    adca      #$00      propagate the carry
                    stb       ,x        store the digit back
                    dec       ,s        decrement the byte counter
                    bpl       ByteMulLoop loop over the bytes
                    leas      1,s        drop the counter
DigitCountLoop      dec       ,s        decrement the digit counter
                    bge       DigitMulLoop loop over the digits
                    leas      3,s        drop the locals
                    puls      pc,x      restore and return

PackBinary          pshs      u,x,a     save the registers
                    leau      $07,x     point past the header
                    pshs      u         save the end pointer
ScanByteLoop        cmpx      ,s        reached the end?
                    bcc       PackDone  done scanning
                    lda       ,x+       load the next byte
                    beq       ScanByteLoop skip zero bytes
                    leax      -$01,x    step back to the byte
                    pshs      x         save its address
                    clrb                clear the result accumulator
                    asl       ,x        shift a bit out
                    rolb                into the accumulator
                    asl       ,x        shift the next bit
                    rolb                into the accumulator
                    asl       ,x        shift the next bit
                    rolb                into the accumulator
                    lda       #$05      five more bits
BitShiftLoop        asl       ,x        shift a bit out
                    rolb                into the accumulator
                    cmpb      #C$LF      decimal overflow?
                    bcs       BitNext   no adjust needed
                    subb      #$0a      subtract ten
                    inc       ,x        carry into the digit
BitNext             deca                count down the bits
                    bne       BitShiftLoop loop over the bits
                    lda       #$08      eight bits for the next byte
                    leax      $01,x     advance to the next byte
                    cmpx      $02,s     past the end?
                    bcs       BitShiftLoop keep converting
                    puls      x         restore the digit pointer
                    inc       $02,s     advance the scan
                    bne       ScanByteLoop continue scanning
PackDone            leas      3,s        drop the locals
                    puls      pc,u,x    restore and return

SwapNumWork         pshs      u         save the frame pointer
                    ldu       $04,s     load the destination pointer
                    exg       x,u       swap source and destination
                    ldd       ,u        copy the first word
                    std       ,x        into the destination
                    ldd       $02,u     copy the second word
                    std       $02,x     into the destination
                    ldd       $04,u     copy the third word
                    std       $04,x     into the destination
                    ldd       $06,u     copy the fourth word
                    std       $06,x     into the destination
                    puls      u         restore the frame pointer
                    puls      d         pop the adjusted value
                    std       ,s        overwrite the stacked argument
                    rts                 return

IntToNum            leax      NumberWorkArea,y   point to the number work area
                    std       -$02,s    stash the integer value
                    bpl       IntToNumPos positive value
                    nega                negate the value
                    negb                negate the value
                    sbca      #$00      negate the value
                    std       $05,x     store the magnitude
                    lda       #$80      set the sign bit
IntToNumStore       sta       ,x        store the sign byte
                    clra                zero
                    clrb                zero
                    std       $01,x     clear a header word
                    std       $03,x     clear a header word
                    sta       $07,x     clear the digit count
                    rts                 return

IntToNumPos         std       $05,x     store the magnitude
                    clra                clear the sign byte
                    bra       IntToNumStore finish building the number

ClearNumWork        pshs      u         save the frame pointer
                    leau      NumberWorkArea,y   point to the number work area
                    clra                zero
                    clrb                zero
                    std       ,u        clear the first word
                    std       $02,u     clear the second word
                    ldd       ,x        load the source value
                    pshs      d         save it
                    std       $03,u     store computed value into the structure
                    ldd       $02,x     load the source low word
                    std       $05,u     store into the structure
                    clr       $07,u     clear the trailing byte
                    ldd       ,s++      pop the saved sign flag
                    bpl       NegDone   skip negation when non-negative
                    lda       #$80      negative sign marker
                    sta       ,u        flag the value as negative
                    ldd       #$0000    zero for subtraction
                    subd      $05,u     negate the low word
                    std       $05,u     store negated low word
                    ldd       #$0000    zero for subtraction
                    sbcb      $04,u     negate high word with borrow
                    sbca      $03,u     continue the borrow
                    std       $03,u     store negated high word
NegDone             tfr       u,x       return the structure pointer
                    puls      pc,u      return to caller

main                pshs      u         save the frame pointer
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

ArgLoop             ldx       $06,s     argv pointer
                    leax      $02,x     advance to the next argument
                    stx       $06,s     store advanced argv
                    ldu       ,x        load argument string pointer
                    ldb       ,u        first character
                    cmpb      #$2d      is it a dash flag
                    lbne      InputFileArg no, treat as input file
                    lbra      NextFlag  yes, process flag characters

NextFlagChar        ldb       ,u        current flag character
                    sex                 sign extend to word
                    tfr       d,x       move into X for dispatch
                    lbra      FlagDispatch dispatch on the flag letter

FlagE               ldd       #$0001    set the e flag
                    std       GlbVar0021 store the flag
                    lbra      NextFlag  continue scanning flags

FlagS               ldd       #$0001    set the s flag
                    std       GlbVar0035 store the flag
                    lbra      NextFlag  continue scanning flags

FlagN               ldd       GlbVar0039 load the n counter
                    addd      #$0001    increment it
                    std       GlbVar0039 store it back
                    lbra      NextFlag  continue scanning flags

FlagO               leau      $01,u     skip past the o letter
                    ldb       ,u        next character
                    cmpb      #$3d      expect an equals sign
                    bne       FlagODone none, flag is complete
                    leax      ModeWStr,pcr write mode string
                    pshs      x         push it
                    leau      $01,u     file name after the equals
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

FlagP               ldd       #$0001    set the p flag
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

FlagDispatch        cmpx      #$0065    letter e
                    lbeq      FlagE     handle the e flag
                    cmpx      #$0073    letter s
                    lbeq      FlagS     handle the s flag
                    cmpx      #$006E    letter n
                    lbeq      FlagN     handle the n flag
                    cmpx      #$006F    letter o
                    lbeq      FlagO     handle the o flag
                    cmpx      #$0070    letter p
                    beq       FlagP     handle the p flag
                    bra       FlagUnknown otherwise unknown flag

NextFlag            leau      $01,u     advance to the next flag character
                    ldb       ,u        load it
                    lbne      NextFlagChar more characters to process
                    bra       ArgLoopNext end of this argument

FlagArgEnd          leas      ,x        restore the stack
                    bra       ArgLoopNext next argument

InputFileArg        ldd       GlbVar0072 input file already given
                    bne       ArgLoopNext yes, ignore the extra argument
                    ldd       GlbVar0072 reload the flag
                    addd      #$0001    increment it
                    std       GlbVar0072 mark input file seen
                    leax      FileTab,y file table base
                    pshs      x         push it
                    leax      ModeRStr,pcr read mode string
                    pshs      x         push it
                    ldd       [$0a,s]   argument file name pointer
                    pshs      d         push it
                    lbsr      FopenBuffered open the input file
                    leas      6,s        drop the arguments
                    std       GlbVar0023 save input file pointer
                    bne       InputOpened opened successfully
                    leax      MsgCantOpenInput,pcr cant open input message
                    pshs      x         push it
                    lbsr      ReportTokenErr print the error
                    leas      2,s        drop the argument
InputOpened         ldd       [$06,s]   argument name pointer
                    std       GlbVar001F remember the source file name
ArgLoopNext         ldd       $04,s     argument counter
                    addd      #$FFFF    decrement it
                    std       $04,s     store it back
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
                    ldd       $06,x     status flags
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

AbortExit           pshs      u         save the frame
                    ldd       GlbVar001F temporary file name
                    beq       DoExit    none to remove
                    ldd       GlbVar001F reload the name
                    pshs      d         push it
                    lbsr      DeleteFile delete the temp file
                    leas      2,s        drop the argument
DoExit              ldd       #$0001    exit status one
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
AllocFileSlot       pshs      u         save the frame
                    leau      FileTab,y file table base
SlotScanLoop        ldd       $06,u     entry status flags
                    clra                clear high byte
                    andb      #$03      in-use bits
                    lbeq      SlotFound free slot found
                    leau      $0d,u     advance to next entry
                    pshs      u         push it
                    leax      TableLimit,y   table limit
                    cmpx      ,s++      past the end
                    bhi       SlotScanLoop keep scanning
                    ldd       #$00C8    too many open files error
                    std       Errno,y   set errno
                    lbra      ReturnNull return null

                    puls      pc,u      return to caller

SetupFile           pshs      u         save the frame
                    ldu       $08,s     supplied slot pointer
                    bne       HaveSlot  already have one
                    bsr       AllocFileSlot allocate a slot
                    tfr       d,u       move into U
HaveSlot            stu       -$02,s    remember the slot
                    beq       ReturnNull allocation failed
                    ldd       $04,s     file descriptor
                    std       $08,u     store it in the slot
                    ldx       $06,s     mode string
                    ldb       $01,x     second character
                    cmpb      #$2b      is it plus
                    beq       ModeReadWrite yes, read-write
                    ldx       $06,s     reload mode string
                    ldb       $02,x     third character
                    cmpb      #$2b      is it plus
                    bne       ModeSingle no, single mode
ModeReadWrite       ldd       $06,u     current flags
                    orb       #$03      set read-write bits
                    bra       StoreMode store the mode

ModeSingle          ldd       $06,u     current flags
                    pshs      d         push them
                    ldb       [$08,s]   mode first character
                    cmpb      #$72      is it r
                    beq       ModeReadBit read bit
                    ldb       [$08,s]   reload mode character
                    cmpb      #$64      is it d
                    bne       ModeWriteBit no, write bit
ModeReadBit         ldd       #$0001    read bit
                    bra       ModeCombine combine the flags

ModeWriteBit        ldd       #$0002    write bit
ModeCombine         ora       ,s+       merge existing flags
                    orb       ,s+       merge low byte
StoreMode           std       $06,u     store the mode flags
                    ldd       $02,u     buffer start
                    addd      $0b,u     add buffer size
                    std       $04,u     set buffer end
                    std       ,u        set current pointer
SlotFound           tfr       u,d       return the slot pointer
                    puls      pc,u      return to caller

ReturnNull          clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u      return null

OpenFileMode        pshs      u         save the frame
                    ldu       $04,s     file descriptor argument
                    leas      -4,s       reserve local workspace
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear the permission word
                    ldx       $0a,s     mode string
                    ldb       $01,x     second character
                    sex                 sign extend
                    tfr       d,x       move into X
                    bra       ModeExtCheck check mode extensions

ModeX               ldx       $0a,s     mode string
                    ldb       $02,x     third character
                    cmpb      #$2b      plus modifier
                    bne       ModeXPlain no, read only
                    ldd       #$0007    read-write-execute perms
                    bra       SetPerm   store the permission

ModeXPlain          ldd       #$0004    read permission
                    bra       SetPerm   store the permission

ModePlus            ldd       #$0003    read-write perms
SetPerm             std       ,s        store the permission word
                    bra       ModeMainChar process the primary mode

ModeBadExt          leax      $04,s     discard workspace
                    lbra      ModeBad   bad mode string

ModeExtCheck        stx       -$02,s    save the mode character
                    beq       ModeMainChar end of extensions
                    cmpx      #$0078    x extension
                    beq       ModeX     handle x
                    cmpx      #$002B    plus extension
                    beq       ModePlus  handle plus
                    bra       ModeBadExt unexpected character

ModeMainChar        ldb       [$0a,s]   primary mode character
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
                    lbsr      OpenFile  open the file
                    leas      4,s        drop the arguments
                    std       $02,s     save the descriptor
                    cmpd      #$FFFF    open failed
                    beq       ModeW     try creating instead
                    ldd       #$0002    seek from end
                    pshs      d         push it
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push offset high
                    pshs      d         push offset low
                    ldd       $08,s     the descriptor
                    pshs      d         push it
                    lbsr      SeekFile  seek to end for append
                    leas      8,s        drop the arguments
                    bra       OpenReturn done opening

ModeW               ldd       ,s        permission word
                    orb       #$02      mark write
                    pshs      d         push it
                    pshs      u         push the name
                    lbsr      CreateFile create the file
                    bra       OpenDone  store the descriptor

ModeD               ldd       ,s        permission word
                    orb       #$81      mark directory read
DoOpen              pshs      d         push it
                    pshs      u         push the name
                    lbsr      OpenFile  open the file
OpenDone            leas      4,s        drop the arguments
                    std       $02,s     save the descriptor
                    bra       OpenReturn done opening

ModeBad             leas      -$04,x    restore the stack
SetErrBadMode       ldd       #$00CB    bad mode error
                    std       Errno,y   set errno
                    clra                clear high byte
                    clrb                clear low byte
                    bra       OpenExit  return failure

ModeDispatch        cmpx      #$0072    r read mode
                    lbeq      ModeR     handle read
                    cmpx      #$0061    a append mode
                    lbeq      ModeA     handle append
                    cmpx      #$0077    w write mode
                    beq       ModeW     handle write
                    cmpx      #$0064    d directory mode
                    beq       ModeD     handle directory
                    bra       SetErrBadMode unrecognized mode

OpenReturn          ldd       $02,s     return the descriptor
OpenExit            leas      4,s        discard the workspace
                    puls      pc,u      return to caller

                    pshs      u         save the frame
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         null buffer argument
                    ldd       $08,s     mode string
                    pshs      d         push it
                    ldd       $08,s     file name
                    pshs      d         push it
                    lbra      CallSetupFile open with default slot

Fopen               pshs      u         save the frame
                    ldd       $06,s     mode string
                    pshs      d         push it
                    ldd       $06,s     file name
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

FopenBuffered       pshs      u         save the frame
                    ldd       $08,s     buffer size hint
                    pshs      d         push it
                    lbsr      CloseFile allocate a buffer
                    leas      2,s        drop the argument
                    ldd       $06,s     mode string
                    pshs      d         push it
                    ldd       $06,s     file name
                    pshs      d         push it
                    lbsr      OpenFileMode open the file descriptor
                    leas      4,s        drop the arguments
                    tfr       d,u       move into U
                    stu       -$02,s    save the descriptor
                    bge       StreamOk  opened successfully
                    clra                clear high byte
                    clrb                clear low byte
                    bra       FopenExit return null

StreamOk            ldd       $08,s     allocated buffer
StreamInit          pshs      d         push it
                    ldd       $08,s     mode string
                    pshs      d         push it
                    pshs      u         push the descriptor
CallSetupFile       lbsr      SetupFile build the stream structure
                    leas      6,s        drop the arguments
FopenExit           puls      pc,u      return to caller

PutStringLine       pshs      u         save the frame
                    leax      StdoutStream,y   stdout stream
                    pshs      x         push it
                    ldd       $06,s     string argument
                    pshs      d         push it
                    bsr       FputStr   write the string
                    leas      4,s        drop the arguments
                    leax      StdoutStream,y   stdout stream
                    pshs      x         push it
                    ldd       #$000D    carriage return
                    pshs      d         push it
                    lbsr      PutChar2  write the newline
                    leas      4,s        drop the arguments
                    puls      pc,u      return to caller

FputStr             pshs      u         save the frame
                    ldu       $04,s     stream pointer
                    leas      -1,s       reserve a local byte
                    bra       CopyByteStore enter the write loop

FputStrLoop         ldd       $07,s     load the string pointer
                    pshs      d         push the character
                    ldb       $02,s     get low byte of the char argument
                    sex                 sign-extend the char to 16 bits
                    pshs      d         push the character argument
                    lbsr      PutChar2  output the character via putc
                    leas      4,s        drop the pushed arguments
CopyByteStore       ldb       ,u+       fetch the next source byte
                    stb       ,s        store byte into the local
                    bne       FputStrLoop loop while byte is nonzero
                    leas      1,s        release the local byte
                    puls      pc,u      restore u and return

FormatXCounter      pshs      u,d       save registers and open frame
                    ldu       $06,s     load the string argument pointer
                    bra       FormatXScanLoop enter the scan loop

FormatXNext         leau      $01,u     advance to the next character
FormatXScanLoop     ldb       ,u        read the current character
                    sex                 sign-extend the character
                    std       ,s        save the current character
                    beq       FormatXFound stop at the end of string
                    ldd       ,s        reload the character
                    cmpd      #$0058    compare with 'X'
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
FormatXDone         ldd       $06,s     return the original pointer
                    leas      2,s        release the local
                    puls      pc,u      restore and return

FmtDecimal          fcc       /%d/
                    fcb       C$NULL
                    pshs      u         save u
                    ldu       $04,s     load the array pointer argument
                    leas      -4,s       reserve two locals
                    clra                clear high byte of row index
                    clrb                clear low byte of row index
                    bra       PutTableRowNext enter the outer loop

PutTableRow         clra                clear high byte of column index
                    clrb                clear low byte of column index
                    std       ,s        initialise the inner counter
                    bra       PutTableInnerNext enter the inner loop

PutTableCell        ldd       $0e,s     load the file pointer
                    pshs      d         push the file
                    ldb       ,u+       fetch the next byte
                    sex                 sign-extend the char
                    pshs      d         push the char
                    lbsr      PutChar2  output the character via putc
                    leas      4,s        drop the arguments
                    ldx       $0e,s     reload the file pointer
                    ldd       $06,x     load the stream flags
                    clra                clear high byte
                    andb      #$20      test the error bit
                    bne       PutTableDone abort on write error
PutTableInnerNext   ldd       ,s        load the inner counter
                    addd      #$0001    increment it
                    std       ,s        store it back
                    subd      #$0001    recover the pre-increment value
                    cmpd      $0a,s     compare against the inner limit
                    blt       PutTableCell repeat the inner loop
                    ldd       $02,s     load the row counter
                    addd      #$0001    increment the row
PutTableRowNext     std       $02,s     store the row counter
                    ldd       $02,s     reload the row counter
                    cmpd      $0C,s     compare against the row limit
                    blt       PutTableRow repeat the outer loop
PutTableDone        ldd       $02,s     return the row counter
                    leas      4,s        release the locals
                    puls      pc,u      restore and return

PutChar2            pshs      u         save u
                    ldu       $06,s     load the FILE pointer argument
                    ldd       $06,u     load the stream flags
                    anda      #$80      isolate the active bit
                    andb      #$22      isolate the write mode bits
                    cmpd      #$8002    test for an active write stream
                    beq       PutcModeOk proceed if mode is ok
                    ldd       $06,u     reload the flags
                    clra                clear high byte
                    andb      #$22      check the write mode bits
                    cmpd      #$0002    test whether it is a write stream
                    lbne      IoFail    fail if not writable
                    pshs      u         push the FILE
                    lbsr      PrepBuffer initialise the stream for writing
                    leas      2,s        drop the argument
PutcModeOk          ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$04      test the unbuffered bit
                    beq       PutcBuffered take the buffered path
                    ldd       #$0001    length of one byte
                    pshs      d         push the count
                    leax      $07,s     point at the char byte
                    pshs      x         push the data pointer
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path number
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the text-mode bit
                    beq       PutcPickBinary pick the binary write routine
                    leax      WriteLnFile,pcr select the text write routine
                    bra       PutcDoWrite go call it

PutcPickBinary      leax      WriteFile,pcr select the binary write routine
PutcDoWrite         tfr       x,d       move routine address
                    tfr       d,x       back into x
                    jsr       ,x        perform the low-level write
                    leas      6,s        drop the write arguments
                    cmpd      #$FFFF    test for a write error
                    bne       PutcDone  return on success
                    ldd       $06,u     reload the flags
                    orb       #$20      set the error bit
                    std       $06,u     store the flags
                    lbra      IoFail    return failure

PutcBuffered        ldd       $06,u     load the flags
                    anda      #$01      test the read-active bit
                    clrb                clear low byte
                    std       -$02,s    save the test result
                    bne       PutcStore buffer already set up
                    pshs      u         push the FILE
                    lbsr      FlushBuffer flush and allocate the buffer
                    leas      2,s        drop the argument
PutcStore           ldd       ,u        load the current buffer pointer
                    addd      #$0001    advance it
                    std       ,u        store it back
                    subd      #$0001    recover the old pointer
                    tfr       d,x       into x
                    ldd       $04,s     load the char
                    stb       ,x        store the char into the buffer
                    ldd       ,u        load the buffer pointer
                    cmpd      $04,u     compare against the buffer end
                    bcc       PutcFlush flush when the buffer is full
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the line-buffered bit
                    beq       PutcDone  done if fully buffered
                    ldd       $04,s     reload the char
                    cmpd      #$000D    was it a carriage return
                    bne       PutcDone  done unless newline
PutcFlush           pshs      u         push the FILE
                    lbsr      FlushBuffer flush the buffer
                    std       ,s++      save status and drop the argument
                    lbne      IoFail    fail on flush error
PutcDone            ldd       $04,s     return the written char
                    puls      pc,u      restore and return

PutWord             pshs      u         save u
                    ldu       $04,s     load the FILE pointer argument
                    ldd       $06,s     load the word value argument
                    pshs      d         push the word
                    pshs      u         push the FILE
                    ldd       #$0008    shift count of eight
                    lbsr      LsrEntry  shift the high byte down
                    pshs      d         push the high byte
                    lbsr      PutChar2  output the high byte via putc
                    leas      4,s        drop the arguments
                    ldd       $06,s     reload the word value
                    pshs      d         push the low byte
                    pshs      u         push the FILE
                    lbsr      PutChar2  output the low byte via putc
                    lbra      FlushReturn return

CloseAllFiles       pshs      u,d       save registers and open frame
                    leau      FileTab,y point at the first FILE table entry
                    clra                clear high byte of index
                    clrb                clear low byte of index
                    std       ,s        initialise the loop counter
                    bra       CloseFileNext enter the loop

CloseFileLoop       tfr       u,d       current FILE pointer
                    leau      $0d,u     advance to the next FILE entry
                    pshs      d         push the FILE pointer
                    bsr       CloseFile close this stream
                    leas      2,s        drop the argument
CloseFileNext       ldd       ,s        load the index
                    addd      #$0001    increment it
                    std       ,s        store it back
                    subd      #$0001    recover the old index
                    cmpd      #$0010    done after all sixteen streams
                    blt       CloseFileLoop loop over the streams
                    lbra      IoReturn  return

CloseFile           pshs      u         save u
                    ldu       $04,s     load the FILE pointer argument
                    leas      -2,s       reserve a local
                    cmpu      #$0000    test for a null stream
                    beq       CloseFileNull treat null as an error
                    ldd       $06,u     load the flags
                    bne       CloseFileOpen proceed if the stream is open
CloseFileNull       ldd       #$FFFF    EOF/error result
                    lbra      IoReturn  return

CloseFileOpen       ldd       $06,u     load the flags
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
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path number
                    lbsr      CloseFile2 close the OS path
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    std       $06,u     mark the stream closed
                    ldd       ,s        return the flush status
                    bra       IoReturn  return

FlushStream         pshs      u         save u
                    ldu       $04,s     load the FILE pointer argument
                    beq       IoFail    fail if null
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$22      isolate the mode bits
                    cmpd      #$0002    test whether it is a write stream
                    beq       FlushWritable flush if writable
IoFail              ldd       #$FFFF    error result
                    puls      pc,u      restore and return

FlushWritable       ldd       $06,u     load the flags
                    anda      #$80      isolate the active bit
                    clrb                clear low byte
                    std       -$02,s    save the active test
                    bne       FlushDoWrite already active
                    pshs      u         push the FILE
                    lbsr      PrepBuffer set up the stream buffer
                    leas      2,s        drop the argument
FlushDoWrite        pshs      u         push the FILE
                    bsr       FlushBuffer flush the buffer
IoReturn            leas      2,s        release the local
                    puls      pc,u      restore and return

FlushBuffer         pshs      u         save u
                    ldu       $04,s     load the FILE pointer argument
                    leas      -4,s       reserve two locals
                    ldd       $06,u     load the flags
                    anda      #$01      test the read-active bit
                    clrb                clear low byte
                    std       -$02,s    save the test
                    bne       FlushHasData skip init if already active
                    ldd       ,u        load the current pointer
                    cmpd      $04,u     compare against the buffer end
                    beq       FlushHasData buffer already positioned
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push the argument
                    pshs      u         push the FILE
                    lbsr      NullBufDesc get the buffer descriptor
                    leas      2,s        drop the argument
                    ldd       $02,x     load the seek position
                    pshs      d         push it
                    ldd       ,x        load the seek base
                    pshs      d         push it
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path number
                    lbsr      SeekFile  seek in the file
                    leas      8,s        drop the arguments
FlushHasData        ldd       ,u        load the current pointer
                    subd      $02,u     compute the buffered byte count
                    std       $02,s     save the count
                    lbeq      FlushReset nothing to write, reset
                    ldd       $06,u     load the flags
                    anda      #$01      test the read bit
                    clrb                clear low byte
                    std       -$02,s    save the test
                    lbeq      FlushReset reset if not a read stream
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the text-mode bit
                    beq       FlushBinary take the binary write path
                    ldd       $02,u     load the buffer base
                    bra       FlushTextStore enter the text write loop

FlushTextLoop       ldd       $02,s     load the remaining count
                    pshs      d         push the length
                    ldd       ,u        load the current pointer
                    pshs      d         push the data pointer
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path number
                    lbsr      WriteLnFile text write to the file
                    leas      6,s        drop the arguments
                    std       ,s        save the bytes written
                    cmpd      #$FFFF    test for a write error
                    bne       FlushTextAdvance continue on success
                    leax      $04,s     point at error handling
                    bra       FlushErrRestore handle the write error

FlushTextAdvance    ldd       $02,s     load the remaining count
                    subd      ,s        subtract the bytes written
                    std       $02,s     update the remaining count
                    ldd       ,u        load the current pointer
                    addd      ,s        advance by bytes written
FlushTextStore      std       ,u        store the pointer
                    ldd       $02,s     load the remaining count
                    bne       FlushTextLoop loop until all written
                    bra       FlushReset done, reset the buffer

FlushBinary         ldd       $02,s     load the byte count
                    pshs      d         push the length
                    ldd       $02,u     load the buffer base
                    pshs      d         push the data pointer
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path number
                    lbsr      WriteFile binary write to the file
                    leas      6,s        drop the arguments
                    cmpd      $02,s     were all bytes written
                    beq       FlushReset success, reset the buffer
                    bra       FlushError handle the write error

FlushErrRestore     leas      -$04,x    restore the stack after error
FlushError          ldd       $06,u     load the flags
                    orb       #$20      set the error bit
                    std       $06,u     store the flags
                    ldd       $04,u     load the buffer end
                    std       ,u        reset pointer to the end
                    ldd       #$FFFF    error result
                    bra       FlushReturn return

FlushReset          ldd       $06,u     load the flags
                    ora       #$01      set the read-active bit
                    std       $06,u     store the flags
                    ldd       $02,u     load the buffer base
                    std       ,u        reset pointer to the base
                    addd      $0b,u     add the buffer size
                    std       $04,u     set the buffer end
                    clra                clear high byte of result
                    clrb                clear low byte of result
FlushReturn         leas      4,s        release the locals
                    puls      pc,u      restore and return

NullBufDesc         pshs      u         save u
                    puls      pc,u      return the caller pointer

GetChar             pshs      u         save u
                    ldu       $04,s     load the FILE pointer argument
                    beq       GetcEof   EOF if null
                    ldd       $06,u     load the flags
                    anda      #$01      test the read-active bit
                    clrb                clear low byte
                    std       -$02,s    save the test
                    bne       GetcEof   return EOF if not readable
                    ldd       ,u        load the current pointer
                    cmpd      $04,u     compare against the buffer end
                    bcc       GetcRefill refill when the buffer is empty
                    ldd       ,u        load the current pointer
                    addd      #$0001    advance it
                    std       ,u        store it back
                    subd      #$0001    recover the old pointer
                    tfr       d,x       into x
                    ldb       ,x        fetch the buffered byte
                    clra                zero-extend to a word
                    lbra      GetcDone  return the character

GetcRefill          pshs      u         push the FILE
                    lbsr      FillBuffer refill the buffer
                    lbra      DropResult return the result

                    pshs      u         save u for ungetc
                    ldu       $06,s     load the FILE pointer argument
                    beq       GetcEof   EOF if null
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$01      test the read-active bit
                    beq       GetcEof   fail if not reading
                    ldd       $04,s     load the pushback char
                    cmpd      #$FFFF    reject pushing EOF
                    beq       GetcEof   reject EOF pushback
                    ldd       ,u        load the current pointer
                    cmpd      $02,u     at the buffer base
                    bhi       UngetcStore room to push back
GetcEof             ldd       #$FFFF    EOF/error result
                    puls      pc,u      restore and return

UngetcStore         ldd       ,u        load the current pointer
                    addd      #$FFFF    back up one byte
                    std       ,u        store the pointer
                    tfr       d,x       into x
                    ldd       $04,s     load the pushback char
                    stb       ,x        store char back into the buffer
                    ldd       $04,s     reload the char
                    puls      pc,u      return the pushed char

                    pshs      u         save u for getw
                    ldu       $04,s     load the FILE pointer argument
                    leas      -4,s       reserve two locals
                    pshs      u         push the FILE
                    lbsr      GetChar   read the high byte via getc
                    leas      2,s        drop the argument
                    std       $02,s     save the high byte
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

GetwCombine         ldd       $02,s     load the high byte
                    pshs      d         push it
                    ldd       #$0008    shift count of eight
                    lbsr      AslEntry  shift high byte up and combine
                    addd      ,s        add the low byte
GetwReturn          leas      4,s        release the locals
                    puls      pc,u      restore and return

FillBuffer          pshs      u         save u
                    ldu       $04,s     load the FILE pointer argument
                    leas      -2,s       reserve a local
                    ldd       $06,u     load the flags
                    anda      #$80      isolate the active bit
                    andb      #$31      isolate the mode bits
                    cmpd      #$8001    test for an active read stream
                    beq       FillCheckStdin proceed
                    ldd       $06,u     reload the flags
                    clra                clear high byte
                    andb      #$31      check the mode bits
                    cmpd      #$0001    test whether it is a read stream
                    lbne      ReturnEof fail if not readable
                    pshs      u         push the FILE
                    lbsr      PrepBuffer set up the read buffer
                    leas      2,s        drop the argument
FillCheckStdin      leax      FileTab,y point at the stdin FILE entry
                    pshs      x         push it
                    cmpu      ,s++      is this stdin
                    bne       FillCheckBuf no, skip the stdout flush
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the text-mode bit
                    beq       FillCheckBuf skip unless line-buffered
                    leax      StdoutStream,y   point at the stdout FILE entry
                    pshs      x         push it
                    lbsr      FlushStream flush stdout before reading
                    leas      2,s        drop the argument
FillCheckBuf        ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$08      test the buffer-allocated bit
                    beq       FillOneByte allocate a buffer if needed
                    ldd       $0b,u     load the buffer size
                    pshs      d         push the size
                    ldd       $02,u     load the buffer base
                    pshs      d         push the base
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path number
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      mask flag bit 6
                    beq       SelReadFn bit clear, select read function
                    leax      ReadLnFile,pcr point to write io function
                    bra       CallIoFn  go call it

SelReadFn           leax      ReadFile,pcr point to read io function
CallIoFn            tfr       x,d       move function pointer to d
                    tfr       d,x       back into x for indirect call
                    jsr       ,x        call the selected io function
                    bra       AfterRead handle the result

FillOneByte         ldd       #$0001    request one byte
                    pshs      d         push count argument
                    leax      $0a,u     point to inline buffer
                    stx       $02,u     set current pointer to buffer start
                    pshs      x         push buffer pointer argument
                    ldd       $08,u     load buffer id
                    pshs      d         push id argument
                    lbsr      ReadFile  read one byte into buffer
AfterRead           leas      6,s        drop the three arguments
                    std       ,s        save read result
                    ldd       ,s        reload result
                    bgt       ReturnByte got a byte, return it
                    ldd       $06,u     load flags for eof/error path
                    pshs      d         save flags on stack
                    ldd       $02,s     check the status code
                    beq       SetErrFlag zero means error flag
                    ldd       #$0020    eof flag value
                    bra       MergeFlags go merge it

SetErrFlag          ldd       #$0010    error flag value
MergeFlags          ora       ,s+       merge into existing flags
                    orb       ,s+       merge the low byte too
                    std       $06,u     store updated flags
ReturnEof           ldd       #$FFFF    return -1 for end of file
                    bra       DropResult go return

ReturnByte          ldd       $02,u     load current pointer
                    addd      #$0001    advance past the byte
                    std       ,u        update position
                    ldd       $02,u     reload pointer
                    addd      ,s        add byte count
                    std       $04,u     store new end pointer
                    ldb       [$02,u]   fetch the byte read
                    clra                zero-extend to a word
DropResult          leas      2,s        drop saved result local
GetcDone            puls      pc,u      restore and return

PrepBuffer          pshs      u         save u
                    ldu       $04,s     load the buffer struct pointer
                    ldd       $06,u     load flags
                    clra                isolate low byte
                    andb      #$C0      test already-sized bits
                    bne       MarkInited skip if already initialized
                    leas      -32,s      reserve a 32-byte local
                    leax      ,s        point x at the local
                    pshs      x         push buffer argument
                    ldd       $08,u     load buffer id
                    pshs      d         push id argument
                    clra                zero offset high
                    clrb                zero offset low
                    pshs      d         push zero offset argument
                    lbsr      GetStat   query the buffer
                    leas      6,s        drop arguments
                    ldd       $06,u     load flags
                    pshs      d         save flags
                    ldb       $02,s     check the query result
                    bne       PickFlag80 nonzero selects other flag
                    ldd       #$0040    init flag value
                    bra       OrInitFlags go merge

PickFlag80          ldd       #$0080    alternate init flag value
OrInitFlags         ora       ,s+       merge into flags
                    orb       ,s+       merge low byte
                    std       $06,u     store flags
                    leas      32,s       release the local
MarkInited          ldd       $06,u     load flags
                    ora       #$80      mark as initialized
                    std       $06,u     store back
                    clra                isolate low byte
                    andb      #$0C      test allocation-state bits
                    beq       CheckSize not yet allocated
                    puls      pc,u      already done, return

CheckSize           ldd       $0b,u     load size field
                    bne       CheckAlloc already sized
                    ldd       $06,u     load flags
                    clra                isolate low byte
                    andb      #$40      test flag bit 6
                    beq       Size256   clear selects size 256
                    ldd       #$0080    buffer size 128
                    bra       StoreSize2 store it

Size256             ldd       #$0100    buffer size 256
StoreSize2          std       $0b,u     store the buffer size
CheckAlloc          ldd       $02,u     load data pointer
                    bne       MarkHeap  already allocated
                    ldd       $0b,u     load size
                    pshs      d         push size argument
                    lbsr      RegionAlloc allocate memory
                    leas      2,s        drop argument
                    std       $02,u     store data pointer
                    cmpd      #$FFFF    allocation failed
                    beq       UseInline fall back to inline buffer
MarkHeap            ldd       $06,u     load flags
                    orb       #$08      mark heap-allocated
                    std       $06,u     store flags
                    bra       ComputeBounds compute bounds

UseInline           ldd       $06,u     load flags
                    orb       #$04      mark inline fallback
                    std       $06,u     store flags
                    leax      $0a,u     point at inline buffer
                    stx       $02,u     set data pointer inline
                    ldd       #$0001    inline size one
                    std       $0b,u     store size
ComputeBounds       ldd       $02,u     load data pointer
                    addd      $0b,u     add size
                    std       $04,u     store end pointer
                    std       ,u        store position too
                    puls      pc,u      return

StrLen              pshs      u         save u
                    ldu       $04,s     load string pointer
StrLenLoop2         ldb       ,u+       fetch byte, advance
                    bne       StrLenLoop2 loop until null
                    tfr       u,d       end pointer to d
                    subd      $04,s     subtract start pointer
                    addd      #$FFFF    minus one for the null
                    puls      pc,u      return length

StrCpy              pshs      u         save u
                    ldu       $06,s     load source pointer
                    leas      -2,s       reserve dest cursor
                    ldd       $06,s     load dest pointer
                    std       ,s        initialize cursor
StrCpyLoop          ldb       ,u+       fetch source byte
                    ldx       ,s        load dest cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    stb       -$01,x    store byte to dest
                    bne       StrCpyLoop loop until null copied
                    bra       StrRetDest return dest pointer

StrCat              pshs      u         save u
                    ldu       $06,s     load source pointer
                    leas      -2,s       reserve dest cursor
                    ldd       $06,s     load dest pointer
                    std       ,s        initialize cursor
StrCatScanLoop      ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    ldb       -$01,x    fetch dest byte
                    bne       StrCatScanLoop scan to end of dest
                    ldd       ,s        cursor past the null
                    addd      #$FFFF    back up to the null
                    std       ,s        save append point
StrCatCopyLoop      ldb       ,u+       fetch source byte
                    ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    stb       -$01,x    append byte
                    bne       StrCatCopyLoop loop until null copied
StrRetDest          ldd       $06,s     return dest pointer
                    leas      2,s        drop cursor
                    puls      pc,u      return

                    pshs      u         save u
                    ldu       $04,s     load first pointer
                    bra       StrCmpLoop enter compare loop

StrCmpEqual         ldx       $06,s     load second pointer
                    leax      $01,x     advance it
                    stx       $06,s     save cursor
                    ldb       -$01,x    fetch second byte
                    bne       StrCmpAdv nonzero, keep comparing
                    clra                strings equal
                    clrb                result zero
                    puls      pc,u      return equal

StrCmpAdv           leau      $01,u     advance first pointer
StrCmpLoop          ldb       ,u        fetch first char
                    sex                 sign-extend to word
                    pshs      d         save first char
                    ldb       [$08,s]   fetch second char
                    sex                 sign-extend
                    cmpd      ,s++      compare the chars
                    beq       StrCmpEqual equal, keep comparing
                    ldb       [$06,s]   load second char
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       ,u        load first char
                    sex                 sign-extend
                    subd      ,s++      first minus second
                    puls      pc,u      return the difference

StrNCpy             pshs      u         save u
                    ldu       $06,s     load source pointer
                    leas      -2,s       reserve cursor
                    ldd       $06,s     load dest pointer
                    std       ,s        initialize cursor
StrNCpyLoop         ldd       $0a,s     load remaining count
                    addd      #$FFFF    decrement it
                    std       $0a,s     save count
                    subd      #$FFFF    test original count
                    ble       StrNCpyPadLoop count exhausted
                    ldb       ,u+       fetch source byte
                    ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    stb       -$01,x    store byte
                    bne       StrNCpyLoop loop while nonzero
                    bra       StrNCpyPadLoop hit null, go pad

StrNCpyPad          clra                zero pad byte high
                    clrb                zero pad byte low
                    ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    stb       -$01,x    store null pad
StrNCpyPadLoop      ldd       $0a,s     load remaining count
                    addd      #$FFFF    decrement
                    std       $0a,s     save
                    subd      #$FFFF    test count
                    bgt       StrNCpyPad more padding needed
                    lbra      StrNRetDest return dest pointer

StrNCmp             pshs      u         save u
                    ldu       $04,s     load first pointer
                    bra       StrNCmpLoop enter compare loop

StrNCmpAdv          ldx       $06,s     load second pointer
                    leax      $01,x     advance it
                    stx       $06,s     save cursor
                    ldb       -$01,x    fetch second byte
                    bne       StrNCmpNext nonzero, continue
                    clra                strings equal so far
                    clrb                result zero
                    puls      pc,u      return

StrNCmpNext         leau      $01,u     advance first pointer
StrNCmpLoop         ldd       $08,s     load remaining count
                    addd      #$FFFF    decrement
                    std       $08,s     save
                    subd      #$FFFF    test count
                    ble       StrNCmpEnd count exhausted
                    ldb       ,u        fetch first byte
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       [$08,s]   fetch second byte
                    sex                 sign-extend
                    cmpd      ,s++      compare
                    beq       StrNCmpAdv equal, keep comparing
StrNCmpEnd          ldd       $08,s     load remaining count
                    bge       StrNCmpDiff still within count
                    clra                count expired, equal
                    clrb                zero result
                    bra       StrNCmpDone return

StrNCmpDiff         ldb       [$06,s]   fetch second char
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       ,u        fetch first char
                    sex                 sign-extend
                    subd      ,s++      compute difference
StrNCmpDone         puls      pc,u      return

StrNCat             pshs      u         save u
                    ldu       $06,s     load source pointer
                    leas      -2,s       reserve cursor
                    ldd       $06,s     load dest pointer
                    std       ,s        initialize cursor
StrNCatScanLoop     ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    ldb       -$01,x    fetch dest byte
                    bne       StrNCatScanLoop scan to end of dest
                    ldd       ,s        cursor past the null
                    addd      #$FFFF    back up to the null
                    std       ,s        save append point
StrNCatCopyLoop     ldd       $0a,s     load remaining count
                    addd      #$FFFF    decrement
                    std       $0a,s     save
                    subd      #$FFFF    test count
                    ble       StrNCatTerm count exhausted
                    ldb       ,u+       fetch source byte
                    ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    stb       -$01,x    append byte
                    bne       StrNCatCopyLoop loop while nonzero
StrNCatTerm         ldd       $0a,s     load remaining count
                    bge       StrNRetDest no terminator needed
                    clra                need a null terminator
                    clrb                zero
                    stb       [,s]      store terminating null
StrNRetDest         ldd       $06,s     return dest pointer
                    leas      2,s        drop cursor
                    puls      pc,u      return

                    pshs      u         save u
                    ldu       $04,s     load dest pointer
UnpackNameLoop      ldx       $06,s     load source cursor
                    leax      $01,x     advance cursor
                    stx       $06,s     save cursor
                    ldb       -$01,x    fetch source byte
                    stb       ,u+       store to dest
                    bgt       UnpackNameLoop loop while high bit clear
                    ldb       -$01,u    fetch last stored byte
                    clra                clear high byte
                    andb      #$7f      strip terminator high bit
                    stb       -$01,u    store cleaned byte
                    clra                zero
                    clrb                zero
                    stb       ,u        null-terminate the string
                    ldd       $04,s     return dest pointer
                    puls      pc,u      return

LongAdd             ldd       $04,s     load addend low word
                    addd      $02,x     add operand low word
                    std       ResultLowWord,y   store result low word
                    ldd       $02,s     load addend high word
                    adcb      $01,x     add with carry
                    adca      ,x        add high byte with carry
                    std       NumberWorkArea,y   store result high word
                    lbra      LongArithRet finalize and return

                    ldd       $04,s     load minuend low word
                    subd      $02,x     subtract operand low word
                    std       ResultLowWord,y   store result low word
                    ldd       $02,s     load minuend high word
                    sbcb      $01,x     subtract with borrow
                    sbca      ,x        subtract high byte with borrow
                    std       NumberWorkArea,y   store result high word
                    lbra      LongArithRet finalize and return

LongNeg             lbsr      CopyToScratch copy operand to scratch
LongNegDo           ldd       #$0000    zero
                    subd      $02,x     zero minus low word
                    std       $02,x     store negated low word
                    ldd       #$0000    zero
                    sbcb      $01,x     subtract low byte with borrow
                    sbca      ,x        subtract high byte with borrow
                    std       ,x        store negated high word
                    rts                 return

LongNot             ldd       ,x        load high word
                    coma                complement high byte
                    comb                complement low byte
                    std       NumberWorkArea,y   store to scratch high
                    ldd       $02,x     load low word
                    coma                complement high byte
                    comb                complement low byte
                    leax      NumberWorkArea,y   point x at scratch
                    std       $02,x     store complemented low word
                    rts                 return

IntToLong           leax      NumberWorkArea,y   point x at scratch
                    std       $02,x     store the low word
                    tfr       a,b       high byte to b
                    sex                 sign-extend it
                    tfr       a,b       replicate the sign byte
                    std       ,x        store sign-extended high word
                    rts                 return
                    leax      NumberWorkArea,y   point x at scratch
                    std       $02,x     store the low word
                    clr       ,x        zero high byte
                    clr       $01,x     zero next byte
                    rts                 return

StoreLong           pshs      y         save y
                    ldy       $04,s     load destination pointer
                    ldd       ,x        load source high word
                    std       ,y        store to dest
                    ldd       $02,x     load source low word
                    std       Dest,y     store to dest
                    puls      x         restore x
                    exg       y,x       swap the pointers
                    puls      d         pop saved value
                    std       ,s        place return result
                    rts                 return

LongShiftLeft       ldx       $02,s     load operand pointer
                    pshs      b         save shift count
                    lbsr      CopyToScratch copy operand to scratch
                    puls      b         restore count
                    tstb                count zero
                    beq       ShiftLeftDone nothing to shift
ShiftLeftLoop       asl       $03,x     shift lowest byte left
                    rol       $02,x     rotate carry up
                    rol       $01,x     rotate carry up
                    rol       ,x        rotate into high byte
                    decb                decrement count
                    bne       ShiftLeftLoop loop
ShiftLeftDone       puls      d         pop saved value
                    std       ,s        place result
                    rts                 return
                    ldx       $02,s     load operand pointer
                    pshs      b         save shift count
                    lbsr      CopyToScratch copy operand to scratch
                    puls      b         restore count
                    tstb                count zero
                    beq       ShiftRightDone nothing to shift
ShiftRightLoop      asr       ,x        arithmetic shift high byte right
                    ror       $01,x     rotate carry down
                    ror       $02,x     rotate carry down
                    ror       $03,x     rotate into low byte
                    decb                decrement count
                    bne       ShiftRightLoop loop
ShiftRightDone      puls      d         pop saved value
                    std       ,s        place result
                    rts                 return

LongArithRet        tfr       cc,a      save condition codes
                    puls      x         pop return address
                    stx       $02,s     relocate it
                    leas      2,s        drop slot
                    leax      NumberWorkArea,y   point to result scratch
                    tfr       a,cc      restore condition codes
                    rts                 return with result pointer

CopyToScratch       ldd       ,x        load operand high word
                    std       NumberWorkArea,y   copy to scratch
                    ldd       $02,x     load operand low word
                    leax      NumberWorkArea,y   repoint x at scratch
                    std       $02,x     store low word
                    rts                 return

                    use       lib/imul.asm
                    clr       ResultSignFlag,y   clear the result sign flag
                    leax      >UDivImpl,pcr select the unsigned divide routine
                    stx       DivideRoutinePointer,y   store the divide routine pointer
                    bra       DivZeroCheck go check for a zero divisor

SignedDivSetup      leax      >SDivImpl,pcr select the signed divide routine
                    stx       DivideRoutinePointer,y   store the divide routine pointer
                    clr       ResultSignFlag,y   clear the result sign flag
                    tst       $02,s     test the sign of the dividend
                    bpl       DivZeroCheck skip if the dividend is non-negative
                    inc       ResultSignFlag,y   mark the result sign as negative
DivZeroCheck        subd      #$0000    test the divisor for zero
                    bne       DivCallSel divide if the divisor is nonzero
                    puls      x         recover the return address
                    ldd       ,s++      recover the dividend
                    jmp       ,x        return the dividend unchanged on zero divisor

DivCallSel          ldx       $02,s     load the dividend
                    pshs      x         pass it to the divide routine
                    jsr       [DivideRoutinePointer,y] call the selected divide routine
                    ldd       ,s        fetch the returned value
                    std       $02,s     save the returned value
                    tfr       x,d       move the result into d
                    tst       ResultSignFlag,y   check the result sign flag
                    beq       DivStoreResult skip negate if positive
                    nega                negate the result
                    negb                negate the result
                    sbca      #$00      negate the result
DivStoreResult      std       ,s++      store the final result
                    rts                 return

UDivImpl            subd      #$0000    test the divisor for zero
                    beq       DivByZeroTrap trap divide by zero
                    pshs      d         save the divisor
                    leas      -2,s       make room for locals
                    clr       ,s        clear the sign flag byte
                    clr       $01,s     clear the sign flag byte
                    bra       DivNormBegin begin the division

DivByZeroTrap       puls      d         discard
                    std       ,s        stash
                    ldd       #$002D    divide-by-zero signal code
                    lbra      SendSignal send the signal

SDivImpl            subd      #$0000    test the divisor for zero
                    beq       DivByZeroTrap trap divide by zero
                    pshs      d         save the divisor
                    leas      -2,s       make room for locals
                    clr       ,s        clear the sign flag byte
                    clr       $01,s     clear the sign flag byte
                    tsta                test the sign of the divisor
                    bpl       SDivDividend skip if divisor is positive
                    nega                take absolute value of the divisor
                    negb                take absolute value of the divisor
                    sbca      #$00      take absolute value of the divisor
                    inc       $01,s     note the divisor was negative
                    std       $02,s     save the absolute divisor
SDivDividend        ldd       $06,s     load the dividend
                    bpl       DivNormBegin skip if dividend is positive
                    nega                take absolute value of the dividend
                    negb                take absolute value of the dividend
                    sbca      #$00      take absolute value of the dividend
                    com       $01,s     flip the result sign
                    std       $06,s     save the absolute dividend
DivNormBegin        lda       #$01      initialize the bit counter
DivNormLoop         inca                count divisor bits
                    asl       $03,s     shift the divisor left
                    rol       $02,s     shift the divisor left
                    bpl       DivNormLoop loop until the top bit aligns
                    sta       ,s        save the bit count
                    ldd       $06,s     load the dividend
                    clr       $06,s     clear the quotient accumulator
                    clr       $07,s     clear the quotient accumulator
DivBitLoop          subd      $02,s     trial subtract the divisor
                    bcc       DivBitSet keep the result if it fit
                    addd      $02,s     restore if it did not fit
                    andcc     #$FE      clear the quotient bit
                    bra       DivBitShift continue

DivBitSet           orcc      #$01      set the quotient bit
DivBitShift         rol       $07,s     shift the bit into the quotient
                    rol       $06,s     shift the bit into the quotient
                    lsr       $02,s     shift the divisor right
                    ror       $03,s     shift the divisor right
                    dec       ,s        decrement the bit count
                    bne       DivBitLoop loop over all bits
                    std       $02,s     save the remainder
                    tst       $01,s     check the result sign flag
                    beq       DivSignDone skip negate if positive
                    ldd       $06,s     load the quotient
                    nega                negate the quotient
                    negb                negate the quotient
                    sbca      #$00      negate the quotient
                    std       $06,s     save the signed quotient
DivSignDone         ldx       $04,s     shuffle the results
                    ldd       $06,s     load the quotient
                    std       $04,s     shuffle the results
                    stx       $06,s     shuffle the results
                    ldx       $02,s     load the remainder
                    ldd       $04,s     place result into d
                    leas      6,s        drop the locals
                    rts                 return quotient and remainder

                    use       lib/shift.asm

SendSignal          std       Errno,y   store the signal code
                    pshs      y,b       save registers
                    os9       F$ID      get our process id
                    puls      y,b       restore registers
                    os9       F$Send    send the signal to ourselves
                    rts                 return

GetStat             lda       $05,s     load the path number
                    ldb       $03,s     load the status function selector
                    beq       GetStatX  branch on selector value
                    cmpb      #$01      selector one
                    beq       GetStatCall handle with a plain call
                    cmpb      #$06      selector six
                    beq       GetStatCall handle with a plain call
                    cmpb      #$02      selector two
                    beq       GetStatPtr handle with a pointer return
                    cmpb      #$05      selector five
                    beq       GetStatPtr handle with a pointer return
                    ldb       #$D0      unknown function error
                    lbra      SysCallErr report the error

GetStatPtr          pshs      u         save u
                    os9       I$GetStt  get file status
                    bcc       GetStatStore branch on success
                    puls      u         restore u
                    lbra      SysCallErr report the error

GetStatStore        stx       [$08,s]   return the value through the pointer
                    ldx       $08,s     load the result pointer
                    stu       $02,x     store the second result
                    puls      u         restore u
                    clra                indicate success
                    clrb                indicate success
                    rts                 return

GetStatX            ldx       $06,s     load the parameter register
GetStatCall         os9       I$GetStt  get file status
                    lbra      SysCallRet return the status result

                    lda       $05,s     load the path number
                    ldb       $03,s     load the setstat selector
                    beq       SetStatX  branch on selector value
                    cmpb      #$02      selector two
                    beq       SetStatPtr handle with a pointer parameter
                    ldb       #$D0      unknown function error
                    lbra      SysCallErr report the error

SetStatX            ldx       $06,s     load the parameter register
                    os9       I$SetStt  set file status
                    lbra      SysCallRet return the result

SetStatPtr          pshs      u         save u
                    ldx       $08,s     load the parameter register
                    ldu       $0a,s     load the pointer parameter
                    os9       I$SetStt  set file status
                    puls      u         restore u
                    lbra      SysCallRet return the result

                    ldx       $02,s     load the pathname
                    lda       $05,s     load the access mode
                    os9       I$Open    open to test the file exists
                    bcs       ExistsDone skip close on failure
                    os9       I$Close   close it again
ExistsDone          lbra      SysCallRet return the result

OpenFile            ldx       $02,s     load the pathname
                    lda       $05,s     load the access mode
                    os9       I$Open    open the file
                    lbcs      SysCallErr report the error
                    tfr       a,b       return the path number
                    clra                clear the high byte
                    rts                 return

CloseFile2          lda       $03,s     load the path number
                    os9       I$Close   close the path
                    lbra      SysCallRet return the result

                    ldx       $02,s     load the pathname
                    ldb       $05,s     load the access mode
                    os9       I$MakDir  make the directory
                    lbra      SysCallRet return the result

CreateFile          ldx       $02,s     load the pathname
                    lda       $05,s     load the mode bits
                    tfr       a,b       copy into b
                    andb      #$24      keep the permission bits
                    orb       #$0b      force read write execute create bits
                    os9       I$Create  create the file
                    bcs       CreateExists handle a create error
CreateDone          tfr       a,b       return the path number
                    clra                clear the high byte
                    rts                 return

CreateExists        cmpb      #$DA      was it the already-exists error
                    lbne      SysCallErr report any other error
                    lda       $05,s     reload the mode bits
                    bita      #$80      test the exclusive flag
                    lbne      SysCallErr fail if exclusive create requested
                    anda      #$07      keep only the access bits
                    ldx       $02,s     load the pathname
                    os9       I$Open    open the existing file instead
                    lbcs      SysCallErr report the error
                    pshs      u,a       save registers
                    ldx       #$0000    truncate to zero length
                    leau      ,x        zero the truncate size pointer
                    ldb       #$02      SS.Size set-status code
                    os9       I$SetStt  truncate the file
                    puls      u,a       restore registers
                    bcc       CreateDone return the path on success
                    pshs      b         save the error
                    os9       I$Close   close on failure
                    puls      b         restore the error
                    lbra      SysCallErr report the error

DeleteFile          ldx       $02,s     load the pathname
                    os9       I$Delete  delete the file
                    lbra      SysCallRet return the result

                    lda       $03,s     load the path number
                    os9       I$Dup     duplicate the path
                    lbcs      SysCallErr report the error
                    tfr       a,b       return the new path number
                    clra                clear the high byte
                    rts                 return

ReadFile            pshs      y         save y
                    ldx       $06,s     load the buffer address
                    lda       $05,s     load the path number
                    ldy       $08,s     load the byte count
                    pshs      y         pass the count
                    os9       I$Read    read from the file
ReadResult          bcc       ReadOk    branch on success
                    cmpb      #$D3      was it end of file
                    bne       ReadErr   report any other error
                    clra                return zero bytes at end of file
                    clrb                return zero bytes at end of file
                    puls      pc,y,x    return

ReadErr             puls      y,x       restore registers
                    lbra      SysCallErr report the error

ReadOk              tfr       y,d       return the bytes read
                    puls      pc,y,x    return

ReadLnFile          pshs      y         save y
                    lda       $05,s     load the path number
                    ldx       $06,s     load the buffer address
                    ldy       $08,s     load the byte count
                    pshs      y         pass the count
                    os9       I$ReadLn  read a line
                    bra       ReadResult share the read result handler

WriteFile           pshs      y         save y
                    ldy       $08,s     load the byte count
                    beq       WriteOk   nothing to write
                    lda       $05,s     load the path number
                    ldx       $06,s     load the buffer address
                    os9       I$Write   write to the file
WriteResult         bcc       WriteOk   branch on success
                    puls      y         restore y
                    lbra      SysCallErr report the error

WriteOk             tfr       y,d       return the bytes written
                    puls      pc,y      return

WriteLnFile         pshs      y         save y
                    ldy       $08,s     load the byte count
                    beq       WriteOk   nothing to write
                    lda       $05,s     load the path number
                    ldx       $06,s     load the buffer address
                    os9       I$WritLn  write a line
                    bra       WriteResult share the write result handler

SeekFile            pshs      u         save u
                    ldd       $0a,s     load the whence argument
                    bne       SeekWhence branch if not seek from start
                    ldu       #$0000    base position is zero
                    ldx       #$0000    base position is zero
                    bra       SeekCompute compute the seek

SeekWhence          cmpd      #$0001    seek from current position
                    beq       SeekFromCur handle seek from current
                    cmpd      #$0002    seek from end
                    beq       SeekFromEnd handle seek from end
                    ldb       #$F7      bad argument error
SeekErr             clra                clear the high byte
                    std       Errno,y   store the error number
                    ldd       #$FFFF    return failure
                    leax      NumberWorkArea,y   point at the position result
                    std       ,x        clear the result
                    std       $02,x     clear the result
                    puls      pc,u      return

SeekFromEnd         lda       $05,s     load the path number
                    ldb       #$02      SS.Size get-status code
                    os9       I$GetStt  get the file size
                    bcs       SeekErr   store error on failure
                    bra       SeekCompute compute the seek

SeekFromCur         lda       $05,s     load the path number
                    ldb       #$05      SS.Pos get-status code
                    os9       I$GetStt  get the current position
                    bcs       SeekErr   store error on failure
SeekCompute         tfr       u,d       base position low word
                    addd      $08,s     add the offset low word
                    std       ResultLowWord,y   save the new position low
                    tfr       d,u       move low word to u
                    tfr       x,d       base position high word
                    adcb      $07,s     add the offset high word with carry
                    adca      $06,s     add the offset high word with carry
                    bmi       SeekErr   fail on a negative position
                    tfr       d,x       move high word to x
                    std       NumberWorkArea,y   save the new position high
                    lda       $05,s     load the path number
                    os9       I$Seek    seek to the position
                    bcs       SeekErr   store error on failure
                    leax      NumberWorkArea,y   return the new position pointer
                    puls      pc,u      return

GrowHeap            ldd       BreakPointer,y   load the current break pointer
                    pshs      d         save it
                    ldd       $04,s     load the requested size
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
                    subd      $04,s     deduct the requested size
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

RegionAlloc         ldd       $02,s     load the requested size
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
                    std       -$02,s    save it
                    beq       SetUserCall allow if super user
                    ldb       #$D6      permission error
                    bra       GetUserIdErr report the error

SetUserCall         ldy       $04,s     load the new user id
                    os9       F$SUser   change the user id
                    bcc       SetUserOk branch on success
                    cmpb      #$D0      was it an unsupported call
                    bne       GetUserIdErr report any other error
                    tfr       y,d       move the id into d
                    ldy       >$004B    load the process descriptor pointer
                    std       GlbVar0009,y     store the user id directly
SetUserOk           clra                indicate success
                    clrb                indicate success
                    puls      pc,y      return

InstallIntercept    pshs      u         save u
                    tfr       y,u       point u at our globals
                    ldx       $04,s     load the handler address
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

SysCallErr          clra                clear high byte of the status field
                    std       Errno,y   zero the pending-status field
                    ldd       #$FFFF    load the error return value -1
                    rts                 return with error

SysCallRet          bcs       SysCallErr on carry take the error return path
                    clra                clear high byte of the result
                    clrb                clear low byte of the result
                    rts                 return with success zero

exit                lbsr      RtsStub   call the rts stub during teardown
                    lbsr      CloseAllFiles flush and finalize output before exit
_exit               ldd       $02,s     load the exit status from the stack
                    os9       F$Exit    terminate the process
RtsStub             rts                 return to caller

* ------------------------------------------------------------------
* WorkBlockImage - cc1-style init image for the work block (see _start):
* rts stub + count/block table + relocation dirs + module-name string.
* ------------------------------------------------------------------
                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       $0003

                    * ---- block1: DP data image  ->  data base
                    fcb       $00,$00,$89

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
                    fdb       $020E

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fcb       $78,$20,$65,$78,$70,$65,$63,$74,$65,$64
                    fcb       $00
Pow10Img            fdb       10000,1000,100,10 powers of ten
CtypeTabImg         fcb       $00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       C$NULL,C$NULL
                    fcb       $6D,$40,$69
                    fcb       C$NULL,C$NULL
                    fcc       |TAh-.BP0CESkkkkkkkkkk/(]x_d|
                    fcb       C$NULL
                    fcc       /jjjjjjjjjjjjjjjjjjjjjjjjjj+f,Yj/
                    fcb       C$NULL
                    fcc       /jjjjjjjjjjjjjjjjjjjjjjjjjj)X*D/
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$09,$00,$00,$00,$0D,$0E
                    fcb       $00,$00,$00,$0E,$0C,$01,$0E,$0F
                    fcb       $0D,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$03,$00,$0A,$02,$0A
                    fcb       $03,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$07
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$06,$00,$0E
                    fcb       $00,$07,$0B,$00,$01,$00,$02,$00
                    fcb       $00,$00,$00,$00,$0C,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$01
                    fcb       $9F
NameBufImg          fcb       $63,$73,$74,$72,$2E,$58,$58,$58,$58,$58
                    fcb       $00
FileTabImg          fcb       $00,$00,$00,$00,$00,$00,$00
                    fcb       $01,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$02,$00,$01
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00
                    fcb       $42
                    fcb       $00,$02,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
                    fdb       $0000

                    * ---- reloc1: text relocation offsets

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       $0003

                    * ---- reloc2: data relocation offsets
                    fdb       $0001,$0189,$01A7

                    * ---- name: trailing module-name string
                    fcc       /c.pass1/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end
