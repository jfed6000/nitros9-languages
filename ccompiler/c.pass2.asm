                    nam       c.pass2
                    ttl       program module

* Annotated 2026-07-14 (Claude Code):
*   - renamed disassembled labels to meaningful names
*   - added an inline comment to every instruction
*   - re-disassembled the "**** STACK OVERFLOW ****" banner that had
*     been decoded as instructions
*   - separated the direct-page globals from the startup code they had
*     been mis-resolved onto (disassembler assumed DP=$00); they are now
*     a direct-page equate block with the references repointed
*   - verified byte-identical to the original assembly (module CRC $F98F29)

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
LowWordDestination  rmb       $1
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
GlbMaxCaseVal       rmb       $2
GlbVar0019          rmb       $2
GlbVar001B          rmb       $2
GlbVar001D          rmb       $2
GlbVar001F          rmb       $2
GlbVar0021          rmb       $2
GlbType5Val         rmb       $2
GlbVar0025          rmb       $2
LookupTable         rmb       $1C
Pow10               rmb       $8
FreeRoot            rmb       $2
GlobalField         rmb       $2
SSuffixString       rmb       $2
PushMnemonicPointer rmb       $2
StackPointerRegister rmb       $2
RegisterName        rmb       $2
NodeFieldY          rmb       $2
RegisterNameTable   rmb       $68
Stdin               rmb       $D
Stdout              rmb       $D
Stderr              rmb       $B6
PastTableEnd        rmb       $1
CtypeTab            rmb       $C0
HeapTop             rmb       $2
TempBuffer          rmb       $2
OutputArea          rmb       $2
OutputArea2         rmb       $4
BumpPointer         rmb       $2
Limit               rmb       $2
ErrorCode           rmb       $2
FilenameBuffer      rmb       $1D
BufferEndPointer    rmb       $1
OutputNameAlready   rmb       $2
Label               rmb       $2
InputFilename       rmb       $2
ConversionBuffer    rmb       $A
TempHexBuffer       rmb       $A
ArenaBase           rmb       $2
NodeSize            rmb       $2
RingTableBase       rmb       $3C
HeadIndex           rmb       $2
TailIndex           rmb       $2
LabelId             rmb       $2
ColumnCounter       rmb       $2
ResultSignFlag      rmb       $1
HelperVector        rmb       $2
FreeSpace           rmb       $2
                    rmb       $A80     remaining data, bss and heap
size                equ       .

name                equ       *
                    fcs       /c.pass2/
                    fcb       edition

* --- shared C runtime startup (see lib/cstart.asm) ---
RTBASE              equ       $0212     runtime-globals block base in the data area
DATAEND             equ       $02E7     end of static data / heap start / stack limit
HDRADV              equ       $0027     advance to where the non-DP data starts
                    use       lib/cstart.asm

main                pshs      u         save caller frame
                    ldd       #$FF86    stack need for main
                    lbsr      stkcheck  verify stack space
                    leas      -36,s      allocate the local frame
                    lbra      ArgLoopTop jump to the argument loop

ArgProcess          ldx       $2a,s     load the argv pointer
                    leax      $02,x     advance to the next argument
                    stx       $2a,s     save updated argv pointer
                    ldu       ,x        load the current argument string
                    ldb       ,u        fetch the first character
                    cmpb      #$2d      is it an option dash
                    lbne      HandleFileArg no, treat as a filename
                    lbra      NextOptChar parse the option characters

LoadOptChar         ldb       ,u        load the option character
                    sex                 sign extend to a word
                    tfr       d,x       move into x for compare
                    lbra      OptDispatch dispatch on the option

OptSetS             ldd       #$0001    flag value one
                    std       GlbVar0011 set the -s option flag
                    lbra      NextOptChar next option character

OptSetN             ldd       #$0001    flag value one
                    std       GlbVar0015 set the -n option flag
                    leax      MsgDevNull,pcr point at the option name
                    pshs      x         push the argument
                    lbsr      OpenOutputFile process the option
                    leas      2,s        drop the argument
                    lbra      NextOptChar next option character

OptSetO             leau      $01,u     advance past the o
                    ldb       ,u        fetch the following char
                    cmpb      #$3d      is it an equals sign
                    bne       OptBadO   no, malformed option
                    leau      $01,u     skip the equals
                    pshs      u         push the value string
                    lbsr      OpenOutputFile process the -o value
                    leas      2,s        drop the argument
                    leax      $24,s     point past the local frame
                    lbra      RestoreFrame resume the argument loop

OptBadO             leau      -$01,u    back up the pointer
                    pshs      u         push the option text
                    leax      MsgBadArg,pcr point at the format string
                    pshs      x         push the format
                    leax      Stderr,y  stderr stream pointer
                    pshs      x         push the stream
                    lbsr      fprintf   print the error message
                    leas      6,s        drop the arguments
                    lbsr      FatalExit count the error
OptSetP             ldd       #$0001    flag value one
                    std       GlbVar0013 set the -p option flag
                    bra       NextOptChar next option character

OptUnknown          ldb       ,u        load the option character
                    sex                 sign extend to a word
                    pshs      d         push the character
                    leax      MsgBadOption,pcr unknown option format
                    pshs      x         push the format
                    leax      Stderr,y  stderr stream pointer
                    pshs      x         push the stream
                    lbsr      fprintf   print the warning message
                    leas      6,s        drop the arguments
                    lbsr      FatalExit count the error
                    bra       NextOptChar next option character

OptDispatch         cmpx      #$0073    is option s
                    lbeq      OptSetS   handle -s
                    cmpx      #$006E    is option n
                    lbeq      OptSetN   handle -n
                    cmpx      #$006F    is option o
                    lbeq      OptSetO   handle -o
                    cmpx      #$0070    is option p
                    beq       OptSetP   handle -p
                    bra       OptUnknown unknown option

NextOptChar         leau      $01,u     advance to next character
                    ldb       ,u        fetch the character
                    lbne      LoadOptChar more option characters
                    bra       ArgLoopTop argument fully parsed

HandleFileArg       ldd       GlbVar0003 input file already open
                    beq       OpenInput no, open the input
                    ldd       OutputNameAlready,y   output name already set
                    beq       SaveOutName no, set the output name
                    leax      MsgTooManyFiles,pcr too many files format
                    pshs      x         push the format
                    leax      Stderr,y  stderr stream pointer
                    pshs      x         push the stream
                    lbsr      fprintf   print the error message
                    leas      4,s        drop the arguments
                    lbsr      FatalExit count the error
SaveOutName         stu       OutputNameAlready,y   save the output filename
                    bra       ArgLoopTop next argument

OpenInput           leax      ModeRead,pcr default extension string
                    pshs      x         push the extension
                    pshs      u         push the filename
                    lbsr      CompareOperands open the input source file
                    leas      4,s        drop the arguments
                    std       GlbVar0003 save the input file handle
                    bne       SaveInName opened successfully
                    pshs      u         push the filename
                    leax      MsgCantOpenR,pcr cannot open format string
                    pshs      x         push the format
                    leax      Stderr,y  stderr stream pointer
                    pshs      x         push the stream
                    lbsr      fprintf   print the error message
                    leas      6,s        drop the arguments
                    lbsr      FatalExit count the error
SaveInName          stu       InputFilename,y   save the input filename
                    bra       ArgLoopTop next argument

RestoreFrame        leas      -$24,x    reset stack to frame base
ArgLoopTop          ldd       $28,s     load remaining arg count
                    addd      #$FFFF    decrement the count
                    std       $28,s     save the updated count
                    lbne      ArgProcess process the next argument
                    ldd       GlbVar0005 output stream already set
                    bne       CheckInDefault yes, keep it
                    leax      Stdout,y  default output to stdout
                    stx       GlbVar0005 store the output stream
CheckInDefault      ldd       GlbVar0003 input stream already set
                    bne       CheckOutName yes, keep it
                    leax      Stdin,y   default input to stdin
                    stx       GlbVar0003 store the input stream
CheckOutName        ldd       OutputNameAlready,y   output name already set
                    bne       EnterCodegen yes, keep it
                    leax      EmptyStr,pcr default output name
                    stx       OutputNameAlready,y   store the output name
EnterCodegen        lbra      NextRecord enter the code generator loop

CaseLoadNode        ldx       $1a,s     load saved node pointer
                    lbra      DispatchRecord continue into dispatch

EmitTokenLoop       ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchByte read intermediate token
                    leas      2,s        drop the argument
                    std       $1a,s     save the token
                    cmpd      #$FFFF    end marker
                    beq       EmitTokensDone done with the list
                    ldd       GlbVar0005 output stream
                    pshs      d         push the stream
                    ldd       $1C,s     the token
                    pshs      d         push the token
                    lbsr      GenOperand3 emit the token
                    leas      4,s        drop the arguments
                    ldd       $1a,s     reload the token
                    cmpd      #$000D    carriage return terminator
                    bne       EmitTokenLoop continue reading tokens
EmitTokensDone      lbra      NextRecord back to main loop

EmitBinaryOp        ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       GlbVar0007 save the value
                    leax      $14,s     point at operand buffer
                    pshs      x         push the buffer pointer
                    ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchByte read intermediate token
                    leas      2,s        drop the argument
                    clra                clear high byte
                    lbsr      SignExtendLong build a register operand
                    pshs      x         save the register descriptor
                    ldd       #$0010    operand size sixteen
                    lbsr      ShiftLeftLong set the operand size
                    lbsr      StoreLong flush the operand
                    leax      $14,s     point at operand buffer
                    pshs      x         push the buffer pointer
                    ldd       $02,x     load buffer high word
                    pshs      d         push it
                    ldd       ,x        load buffer low word
                    pshs      d         push it
                    ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    lbsr      SignExtendLong build a register operand
                    lbsr      IntAdd32  build a memory operand
                    lbsr      StoreLong flush the operand
                    leax      $14,s     point at operand buffer
                    ldd       $02,x     load buffer high word
                    pshs      d         push it
                    ldd       ,x        load buffer low word
                    pshs      d         push it
                    ldd       GlbVar0007 reload the saved value
                    pshs      d         push it
                    lbsr      RingAdvance emit the instruction
                    leas      6,s        drop the arguments
                    lbra      NextRecord back to main loop

EmitSwitchNode      ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read the node type
                    leas      2,s        drop the argument
                    std       $22,s     save the node type
                    ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       GlbVar000B save the first operand
                    ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       GlbVar000D save the second operand
                    ldd       GlbMaxCaseVal load the running maximum
                    cmpd      GlbVar000D compare with the new value
                    ble       MaxKept   keep the old maximum
                    ldd       GlbVar000D take the larger value
                    std       GlbMaxCaseVal update the running maximum
MaxKept             ldx       $22,s     load the node type
                    bra       NodeTypeDispatch dispatch on the node type

NodeType2           ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       $1e,s     save the first field
                    ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       $20,s     save the second field
                    ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchByte read intermediate token
                    leas      2,s        drop the argument
                    std       $1C,s     save the third field
                    bra       EmitNode  emit the node

NodeType5           ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       GlbType5Val save the type five operand
                    bra       EmitNode  emit the node

NodeType18          ldd       GlbVar0003 input stream
                    pshs      d         push the stream
                    lbsr      FetchWord read intermediate word
                    leas      2,s        drop the argument
                    std       $18,s     save the operand field
                    bra       EmitNode  emit the node

NodeTypeDispatch    cmpx      #$0002    node type two
                    beq       NodeType2 handle type two
                    cmpx      #$0005    node type five
                    beq       NodeType5 handle type five
                    cmpx      #$0012    node type eighteen
                    beq       NodeType18 handle type eighteen
EmitNode            lbsr      BuildExprNode allocate a label
                    std       Label,y   save the current label
                    ldx       $22,s     reload the node type
                    lbra      DispatchNode dispatch the node emit

EmitNodeA           ldd       $1C,s     third field
                    pshs      d         push it
                    ldd       $22,s     node type
                    pshs      d         push it
                    ldd       $22,s     node type again
                    pshs      d         push it
                    ldd       Label,y   current label
                    pshs      d         push it
                    lbsr      GenExpr2  emit the construct
                    leas      8,s        drop the arguments
                    lbra      FinishOperand continue the main loop

EmitNodeB           ldd       $18,s     operand field
                    pshs      d         push it
                    ldd       Label,y   current label
                    pshs      d         push it
                    lbsr      LoadOperandReg emit the construct
                    leas      4,s        drop the arguments
                    lbra      FinishOperand continue the main loop

EmitNodeC           ldd       Label,y   current label
                    pshs      d         push it
                    lbsr      GenExpr   emit the construct
                    leas      2,s        drop the argument
                    std       Label,y   update the current label
                    lbra      FinishOperand continue the main loop

EmitNodeD           ldd       Label,y   current label
                    pshs      d         push it
                    lbsr      ForceReg71 emit the construct
                    leas      2,s        drop the argument
                    lbra      FinishOperand continue the main loop

EmitNodeE           lbsr      EmitFdb   emit the prologue
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero
                    ldd       Label,y   current label
                    pshs      d         push value as emit argument
                    ldd       #$0077    load constant $77
                    pshs      d         push it as argument
                    lbsr      EmitAddrMode call emit helper
                    leas      6,s        drop the three arguments
                    lbsr      EmitNewline call emit helper
                    clra                zero accumulator a
                    clrb                zero accumulator b
                    std       GlbType5Val clear global at $0023
                    bra       FinishOperand join shared operand tail

EmitTypeDefault     ldd       $22,s     load the local operand
                    pshs      d         push as fprintf argument
                    leax      MsgBadAction,pcr address of format string
                    pshs      x         push format pointer
                    leax      Stderr,y  output file pointer
                    pshs      x         push FILE argument
                    lbsr      fprintf   print the formatted operand
                    leas      6,s        drop the three arguments
                    lbsr      FatalExit emit trailer
                    bra       FinishOperand join operand tail

DispatchNode        cmpx      #$0002    dispatch on node type 2
                    lbeq      EmitNodeA branch to type-2 handler
                    cmpx      #$0012    node type $12
                    lbeq      EmitNodeB branch to that handler
                    cmpx      #$0004    node type 4
                    lbeq      EmitNodeC branch to that handler
                    cmpx      #$0001    node type 1
                    lbeq      EmitNodeD branch to that handler
                    cmpx      #$0005    node type 5
                    beq       EmitNodeE branch to that handler
                    bra       EmitTypeDefault default: formatted emit

FinishOperand       ldd       Label,y   load current node pointer
                    pshs      d         push as argument
                    lbsr      WalkTreeChildren free or emit the node
                    lbra      DoneOperand operand done

GenLabelRecord      ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a number from input
                    std       ,s        overwrite argument with result
                    lbsr      EmitLocalLabelLine emit the value
                    lbra      DoneOperand operand done

GenDataRecord       ldd       $1a,s     load current record character
                    cmpd      #$0064    is the character 'd'
                    bne       DataFlagZero no, treat as 'v'
                    ldd       #$0001    flag one for 'd'
                    bra       DataEmit  go emit with flag

DataFlagZero        clra                zero accumulator a
                    clrb                zero accumulator b for 'v'
DataEmit            pshs      d         push the flag
                    lbsr      EmitVsect emit data directive
                    bra       DoneOperand operand done

GenERecord          lbsr      EmitEndsect emit the 'e' record
                    lbra      NextRecord read next record

StringCharLoop      ldd       $1a,s     load current character
                    cmpd      #$FFFF    end of input marker
                    beq       StringDone finish the string
                    ldd       $1a,s     reload character
                    cmpd      #$005C    backslash escape
                    bne       EmitStringChar no, emit the character
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read the escaped character
                    leas      2,s        drop the argument
                    std       $1a,s     store escaped character
EmitStringChar      ldd       $1a,s     load character to emit
                    pshs      d         push as argument
                    lbsr      EmitStrChar emit one string character
                    leas      2,s        drop the argument
GenStringRecord     ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read next character
                    leas      2,s        drop the argument
                    std       $1a,s     store the character
                    bne       StringCharLoop loop while nonzero
StringDone          clra                zero accumulator a
                    clrb                zero terminator
                    pshs      d         push the terminator
                    lbsr      EmitStrChar emit string terminator
                    bra       DoneOperand operand done

GenMRecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a number from input
                    std       ,s        overwrite argument
                    lbsr      EmitLeas  emit the value
DoneOperand         leas      2,s        drop the operand
                    lbra      NextRecord read next record

GenRRecord          clra                zero accumulator a
                    clrb                zero accumulator b
                    pshs      d         push zero operand
                    clra                zero accumulator a
                    clrb                zero accumulator b
                    pshs      d         push zero operand
                    ldd       #$0012    load opcode $12
                    lbra      EmitOpTwoArgs emit the instruction

GenJRecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read first operand
                    leas      2,s        drop the argument
                    std       $18,s     save first operand
                    pshs      d         push it as argument
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read second operand
                    std       ,s        into argument slot
                    ldd       #$007D    load opcode $7D
                    bra       EmitOpTwoArgs emit the instruction

GenGRecord          clra                zero accumulator a
                    clrb                zero accumulator b
                    pshs      d         push zero operand
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read operand
                    std       ,s        into argument slot
                    ldd       #$001D    load opcode $1D
                    bra       EmitOpTwoArgs emit the instruction

GenLowJRecord       clra                zero accumulator a
                    clrb                zero accumulator b
                    pshs      d         push zero operand
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read operand
                    std       ,s        into argument slot
                    ldd       #$007C    load opcode $7C
                    bra       EmitOpTwoArgs emit the instruction

GenDRecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read first operand
                    leas      2,s        drop the argument
                    std       $18,s     save first operand
                    pshs      d         push it as argument
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read second operand
                    std       ,s        into argument slot
                    ldd       #$0009    load opcode $09
EmitOpTwoArgs       pshs      d         push the opcode
                    lbsr      GenOperand emit the instruction
                    leas      6,s        drop the three arguments
                    lbra      NextRecord read next record

GenYRecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read operand
                    std       ,s        into argument slot
                    ldd       #$0076    load opcode $76
                    bra       EmitOpOneArg emit with one operand

GenURecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read operand
                    std       ,s        into argument slot
                    ldd       #$006F    load opcode $6F
EmitOpOneArg        pshs      d         push the opcode
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the two arguments
                    lbra      NextRecord read next record

GenSRecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a token
                    leas      2,s        drop the argument
                    std       $18,s     save the token
                    ldd       GlbVar0011 check global flag
                    bne       StringBufInit skip if flag set
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a number
                    leas      2,s        drop the argument
                    std       GlbVar000B store into global
StringBufInit       leau      ,s        buffer pointer is stack
                    bra       ReadBufChar enter read loop

StoreBufChar        ldd       $1a,s     load current character
                    stb       ,u+       store character into buffer
ReadBufChar         ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read next character
                    leas      2,s        drop the argument
                    std       $1a,s     store the character
                    bne       StoreBufChar loop while nonzero
                    clra                zero accumulator a
                    clrb                zero accumulator b
                    stb       ,u        null-terminate the buffer
                    ldd       GlbVar0013 check global flag
                    beq       EmitSymbol skip if flag clear
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a number
                    leas      2,s        drop the argument
                    std       $1a,s     save it
EmitSymbol          ldd       $1a,s     load argument
                    pshs      d         push it
                    ldd       GlbVar000B load global
                    pshs      d         push it
                    ldd       $1C,s     load local
                    pshs      d         push it
                    leax      $06,s     buffer pointer
                    pshs      x         push it
                    lbsr      EmitFuncProlog emit the symbol
                    leas      8,s        drop the four arguments
                    lbra      NextRecord read next record

GenEndRecord        lbsr      EmitFrameEqu emit the 'E' record
                    lbra      NextRecord read next record

GenFuncRecord       leas      -10,s      reserve locals
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a number
                    leas      2,s        drop the argument
                    std       ,s        save local
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    ldd       #$0001    load constant one
                    pshs      d         push it
                    ldd       #$0008    load constant eight
                    pshs      d         push it
                    leax      $08,s     pointer argument
                    pshs      x         push it
                    lbsr      FillBuffer lookup or build
                    leas      8,s        drop the arguments
                    leax      $02,s     pointer argument
                    pshs      x         push it
                    lbsr      EvalFloatNode process it
                    leas      2,s        drop the argument
                    ldd       ,s        load the result
                    cmpd      #$0006    is it type 6
                    bne       FuncRecordAlt no, alternate path
                    ldd       #$0004    load constant four
                    pshs      d         push it
                    leax      $04,s     pointer argument
                    pshs      x         push it
                    lbsr      EmitCaseTable emit it
                    bra       FuncRecordDone merge

FuncRecordAlt       leas      -4,s       more locals
                    leax      ,s        pointer to locals
                    pshs      x         push it
                    leax      $08,s     pointer argument
                    lbsr      FpMoveTemp compute
                    lbsr      CopyFloat4 compute
                    ldd       #$0002    load constant two
                    pshs      d         push it
                    leax      $02,s     pointer argument
                    pshs      x         push it
                    lbsr      EmitCaseTable emit it
                    leas      4,s        drop the arguments
FuncRecordDone      leas      4,s        release inner locals
                    leas      10,s       release locals
                    lbra      NextRecord read next record

                    leas      10,s       unreachable frame cleanup
GenPRecord          lbsr      EmitLiterals emit the 'p' record
                    lbra      NextRecord read next record

GenFileRecord       leau      FilenameBuffer,y   point at filename buffer
                    bra       ReadFileChar enter the loop

FileCharLoop        ldd       $1a,s     load current character
                    cmpd      #$FFFF    end of input marker
                    beq       FileNameDone filename done
                    leax      BufferEndPointer,y   buffer end pointer
                    pshs      x         push it
                    cmpu      ,s++      is the buffer full
                    beq       ReadFileChar yes, skip the store
                    ldd       $1a,s     load the character
                    stb       ,u+       store into the buffer
ReadFileChar        ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read next character
                    leas      2,s        drop the argument
                    std       $1a,s     store the character
                    cmpd      #$000D    carriage return
                    bne       FileCharLoop loop until carriage return
FileNameDone        clra                zero accumulator a
                    clrb                zero accumulator b
                    stb       ,u        null-terminate the buffer
                    lbra      NextRecord read next record

EmitUnknownRecord   ldd       $1a,s     load unknown record character
                    pshs      d         push as argument
                    leax      MsgBadCode,pcr format string address
                    pshs      x         push it
                    leax      Stderr,y  output file pointer
                    pshs      x         push it
                    lbsr      fprintf   print the diagnostic
                    leas      6,s        drop the arguments
                    lbsr      FatalExit emit trailer
                    lbra      NextRecord read next record

DispatchRecord      cmpx      #$002A    record type '*'
                    lbeq      EmitTokenLoop branch to its handler
                    cmpx      #$004F    record type 'O'
                    lbeq      EmitBinaryOp branch to its handler
                    cmpx      #$0054    record type 'T'
                    lbeq      EmitSwitchNode branch to its handler
                    cmpx      #$006C    record type 'l'
                    lbeq      GenLabelRecord branch to its handler
                    cmpx      #$0076    record type 'v'
                    lbeq      GenDataRecord branch to its handler
                    cmpx      #$0064    record type 'd'
                    lbeq      GenDataRecord branch to same handler
                    cmpx      #$0065    record type 'e'
                    lbeq      GenERecord branch to its handler
                    cmpx      #$0073    record type 's'
                    lbeq      GenStringRecord branch to its handler
                    cmpx      #$004D    record type 'M'
                    lbeq      GenMRecord branch to its handler
                    cmpx      #$0072    record type 'r'
                    lbeq      GenRRecord branch to its handler
                    cmpx      #$004A    record type 'J'
                    lbeq      GenJRecord branch to its handler
                    cmpx      #$0047    record type 'G'
                    lbeq      GenGRecord branch to its handler
                    cmpx      #$006A    record type 'j'
                    lbeq      GenLowJRecord branch to its handler
                    cmpx      #$0044    record type 'D'
                    lbeq      GenDRecord branch to its handler
                    cmpx      #$0059    record type 'Y'
                    lbeq      GenYRecord branch to its handler
                    cmpx      #$0055    record type 'U'
                    lbeq      GenURecord branch to its handler
                    cmpx      #$0053    record type 'S'
                    lbeq      GenSRecord branch to its handler
                    cmpx      #$0045    record type 'E'
                    lbeq      GenEndRecord branch to its handler
                    cmpx      #$0066    record type 'f'
                    lbeq      GenFuncRecord branch to its handler
                    cmpx      #$0070    record type 'p'
                    lbeq      GenPRecord branch to its handler
                    cmpx      #$0046    record type 'F'
                    lbeq      GenFileRecord branch to its handler
                    cmpx      #$000D    end-of-record carriage return
                    beq       NextRecord just read next record
                    lbra      EmitUnknownRecord unknown record diagnostic

NextRecord          ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read next record character
                    leas      2,s        drop the argument
                    std       $1a,s     store record character
                    cmpd      #$FFFF    end of input marker
                    lbne      CaseLoadNode no, go process it
                    leas      36,s       release the frame
                    puls      pc,u      return to caller

BuildExprNode       pshs      u         save frame pointer
                    ldd       #$FFAA    stack-check size
                    lbsr      stkcheck  verify stack room
                    leas      -10,s      reserve locals
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a token
                    leas      2,s        drop the argument
                    std       $06,s     save the token
                    ldd       #$0016    node size 22 bytes
                    pshs      d         push it
                    lbsr      $310F     allocate the node
                    leas      2,s        drop the argument
                    tfr       d,u       node pointer in u
                    stu       -$02,s    save the pointer
                    bne       FillNodeFields allocation succeeded
                    lbsr      EmitNodeRef out of memory
FillNodeFields      ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a field
                    leas      2,s        drop the argument
                    std       ,u        store into node offset 0
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a field
                    leas      2,s        drop the argument
                    std       $02,u     store into node offset 2
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a field
                    leas      2,s        drop the argument
                    std       $06,u     store into node offset 6
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a field
                    leas      2,s        drop the argument
                    std       $0e,u     store into node offset 14
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a byte field
                    leas      2,s        drop the argument
                    clra                clear the high byte
                    std       $10,u     store into node offset 16
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a field
                    leas      2,s        drop the argument
                    std       $12,u     store into node offset 18
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchWord read a field
                    leas      2,s        drop the argument
                    std       $14,u     store into node offset 20
                    ldx       $06,u     load child pointer
                    lbra      NodeDataDispatch continue building the node

BuildChildNode      ldd       #$000D    child node size 13 bytes
                    pshs      d         push it
                    lbsr      $310F     allocate the child node
                    leas      2,s        drop the argument
                    std       $08,s     save the pointer
                    std       $08,u     link into parent node
                    ldd       $08,s     reload the pointer
                    bne       AllocOk   allocation succeeded
                    lbsr      EmitNodeRef out of memory
AllocOk             ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a field
                    leas      2,s        drop the argument
                    ldx       $08,s     child node pointer
                    std       $02,x     store into child offset 2
                    ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a field
                    leas      2,s        drop the argument
                    std       [$08,s]   store through node pointer
                    ldx       [$08,s]   load node pointer
                    bra       NameTypeCheck continue building

InitStringBuffer    ldd       $08,s     child node pointer
                    addd      #$0004    offset to string buffer
                    std       $04,s     save buffer pointer
StringByteLoop      ldd       GlbVar0003 input file pointer
                    pshs      d         push as argument
                    lbsr      FetchByte read a character
                    leas      2,s        drop the argument
                    ldx       $04,s     load buffer pointer
                    leax      $01,x     advance the pointer
                    stx       $04,s     save the pointer
                    stb       -$01,x    store character in buffer
                    bne       StringByteLoop loop while nonzero
                    clra                clear the high byte
                    clrb                clear low byte for terminator
                    stb       [$04,s]   store null terminator via pointer
                    lbra      ReadOperandKind continue to operand kind read

ReadFieldWord       ldd       GlbVar0003 load input file pointer
                    pshs      d         pass input file as argument
                    lbsr      FetchWord read a word value from input
                    leas      2,s        drop the argument
                    ldx       $08,s     load the node buffer pointer
                    std       $04,x     store value into node field
                    lbra      ReadOperandKind continue to operand kind read

NameTypeCheck       cmpx      #$000E    check for subtype 0e
                    beq       InitStringBuffer copy name for this subtype
                    cmpx      #$000C    check for subtype 0c
                    lbeq      InitStringBuffer copy name for this subtype
                    cmpx      #$0021    check for subtype 21
                    lbeq      InitStringBuffer copy name for this subtype
                    cmpx      #$0022    check for subtype 22
                    lbeq      InitStringBuffer copy name for this subtype
                    bra       ReadFieldWord otherwise read a word field

ReadConst4          ldd       #$0004    allocation size four bytes
                    pshs      d         pass allocation size
                    lbsr      $310F     allocate memory
                    leas      2,s        drop the argument
                    std       $02,s     save allocated pointer
                    bne       ReadConst4Fill allocation succeeded
                    lbsr      EmitNodeRef report out of memory
ReadConst4Fill      ldd       GlbVar0003 load input file pointer
                    pshs      d         pass input file
                    ldd       #$0001    element count one
                    pshs      d         pass element count
                    ldd       #$0004    element size four
                    pshs      d         pass element size
                    ldd       $08,s     load allocated buffer pointer
                    pshs      d         pass destination buffer
                    lbsr      FillBuffer read the block from input
                    leas      8,s        drop the arguments
                    ldd       $02,s     reload the buffer pointer
                    bra       StoreNodeVal store pointer into node

ReadConst8          ldd       #$0008    allocation size eight bytes
                    pshs      d         pass allocation size
                    lbsr      $310F     allocate memory
                    leas      2,s        drop the argument
                    std       ,s        save allocated pointer
                    bne       ReadConst8Fill allocation succeeded
                    lbsr      EmitNodeRef report out of memory
ReadConst8Fill      ldd       GlbVar0003 load input file pointer
                    pshs      d         pass input file
                    ldd       #$0001    element count one
                    pshs      d         pass element count
                    ldd       #$0008    element size eight
                    pshs      d         pass element size
                    ldd       $06,s     load buffer pointer
                    pshs      d         pass destination buffer
                    lbsr      FillBuffer read the block from input
                    leas      8,s        drop the arguments
                    ldd       ,s        reload the buffer pointer
                    pshs      d         pass the double constant
                    lbsr      EvalFloatNode process the double constant
                    leas      2,s        drop the argument
                    ldd       ,s        reload the pointer
                    bra       StoreNodeVal store pointer into node

ReadFieldDefault    ldd       GlbVar0003 load input file pointer
                    pshs      d         pass input file
                    lbsr      FetchWord read a word value from input
                    leas      2,s        drop the argument
StoreNodeVal        std       $08,u     store value into node field
                    bra       ReadOperandKind continue to operand kind read

NodeDataDispatch    cmpx      #$0034    node type string constant?
                    lbeq      BuildChildNode read a name node
                    cmpx      #$004A    node type 4a?
                    lbeq      ReadConst4 read a four-byte constant
                    cmpx      #$004B    node type 4b?
                    beq       ReadConst8 read an eight-byte constant
                    bra       ReadFieldDefault default read a word field

ReadOperandKind     clra                clear high byte
                    clrb                clear low byte
                    std       $0a,u     clear operand value field
                    ldx       $06,s     load node operand kind
                    bra       OperandKindDispatch dispatch on operand kind

ReadBothChildren    lbsr      BuildExprNode recursively read child node
                    std       $0a,u     store as left child pointer
ReadRightChild      lbsr      BuildExprNode read child node
                    bra       StoreRightChild store as right child

ReadLeftChild       lbsr      BuildExprNode read child node
                    std       $0a,u     store as left child pointer
NoChildren          clra                clear high byte
                    clrb                clear low byte
StoreRightChild     std       $0C,u     store right child pointer
                    bra       ReadNodeDone node build complete

BadNodeTypeErr      ldd       $06,s     load node operand kind
                    pshs      d         pass the kind value
                    leax      MsgBadNodeType,pcr bad node type format string
                    pshs      x         pass the format string
                    leax      Stderr,y  point at stderr stream
                    pshs      x         pass the output stream
                    lbsr      fprintf   print the error message
                    leas      6,s        drop the arguments
                    lbsr      FatalExit exit fatally
                    bra       ReadNodeDone node build complete

OperandKindDispatch cmpx      #$0042    operand kind B both children
                    beq       ReadBothChildren read both children
                    cmpx      #$0052    operand kind R right child
                    beq       ReadRightChild read right child
                    cmpx      #$004C    operand kind L left child
                    beq       ReadLeftChild read left child
                    cmpx      #$004E    operand kind N no children
                    beq       NoChildren no children to read
                    bra       BadNodeTypeErr unknown kind is an error

ReadNodeDone        tfr       u,d       return the node pointer
                    leas      10,s       release the locals
                    puls      pc,u      restore and return

EvalFloatNode       pshs      u         save frame pointer
                    ldd       #$FFAE    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer argument
                    leas      -8,s       reserve local storage
                    stu       $06,s     save the node pointer
                    ldx       $06,s     reload the node pointer
                    ldb       $07,x     load the exponent byte
                    sex                 sign extend it
                    std       $02,s     save the exponent
                    ldd       #$00B8    load exponent bias
                    ldx       $06,s     reload the node pointer
                    stb       $07,x     store biased exponent byte
                    ldb       [$06,s]   load the sign byte
                    clra                clear high byte
                    andb      #$80      isolate the sign bit
                    std       ,s        save the sign flag
                    beq       FloatSignDone positive value skip clearing
                    ldb       [$06,s]   reload the sign byte
                    clra                clear high byte
                    andb      #$7f      clear the sign bit
                    stb       [$06,s]   store absolute mantissa byte
FloatSignDone       leax      ,u        point at the node
                    pshs      x         pass the node pointer
                    pshs      u         pass the node pointer
                    lbsr      FpNumCvt  emit conversion helper
                    leas      2,s        drop the argument
                    lbsr      CopyFloat8 emit follow-on helper
                    ldd       $02,s     load the exponent value
                    bge       FloatSetNeg non-negative exponent
                    ldd       $02,s     load the exponent value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      propagate the borrow
                    std       $02,s     store absolute exponent
                    clra                clear high byte
                    clrb                clear low byte
                    bra       FloatStoreSign sign flag zero

FloatSetNeg         ldd       #$0001    sign flag one
FloatStoreSign      std       $04,s     store the sign flag
                    leax      ,u        point at the node
                    pshs      x         pass the node pointer
                    ldd       $06,s     load a working value
                    pshs      d         pass working value
                    ldd       $06,s     load a working value
                    pshs      d         pass working value
                    leax      ,u        point at the node
                    lbsr      PushArg8  emit conversion helper
                    lbsr      EmitDecimal2 emit conversion helper
                    leas      12,s       drop the arguments
                    lbsr      CopyFloat8 emit follow-on helper
                    ldd       ,s        load the sign flag
                    beq       EvalFloatDone positive skip the negate
                    leax      ,u        point at the node
                    pshs      x         pass the node pointer
                    leax      ,u        point at the node
                    lbsr      FpNegate  emit the negate
                    lbsr      CopyFloat8 emit follow-on helper
EvalFloatDone       leas      8,s        release the locals
                    puls      pc,u      restore and return

OpenOutputFile      pshs      u         save frame pointer
                    ldd       #$FFB6    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldd       GlbVar0005 output file already open?
                    beq       DoOpenOutput not open so open it
                    puls      pc,u      already open return

DoOpenOutput        leax      ModeWrite,pcr write mode string
                    pshs      x         pass the mode
                    ldd       $06,s     load the output filename
                    pshs      d         pass the filename
                    lbsr      CompareOperands open the output file
                    leas      4,s        drop the arguments
                    std       GlbVar0005 save the output file pointer
                    bne       OpenOutputDone open succeeded
                    ldd       $04,s     load the filename
                    pshs      d         pass the filename
                    leax      MsgCantOpenW,pcr cannot open format string
                    pshs      x         pass the format
                    leax      Stderr,y  point at stderr stream
                    pshs      x         pass the output stream
                    lbsr      fprintf   report the open error
                    leas      6,s        drop the arguments
                    lbsr      FatalExit exit fatally
OpenOutputDone      puls      pc,u      return from open output

LoadOperandReg      pshs      u         save frame pointer
                    ldd       #$FFB6    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer argument
                    ldx       $06,s     load operand size
                    lbra      LoadOperandDispatch dispatch on operand size

LoadOperand8        pshs      u         pass the node pointer
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    leax      ,s        point at the result
                    bra       LoadOperandCont continue emitting

LoadOperand56       pshs      u         pass the node pointer
                    lbsr      GenLongExpr evaluate the operand
                    leas      2,s        drop the argument
                    bra       EmitRegMove continue emitting

LoadOperandCont     leas      ,x        restore the stack pointer
EmitRegMove         ldd       $06,u     load current operand type
                    cmpd      #$0080    already in target register?
                    lbeq      LoadOperandDone yes so done
                    ldd       #$0080    destination register code
                    pshs      d         pass destination code
                    ldd       #$006F    opcode selector
                    pshs      d         pass opcode selector
                    ldd       #$007F    source operand code
                    pshs      d         pass source code
                    lbsr      GenOperand emit the move instruction
                    leas      6,s        drop the arguments
                    ldd       #$006F    opcode selector
                    pshs      d         pass opcode selector
                    ldd       #$007A    operand code
                    pshs      d         pass operand code
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldx       $06,s     load operand size
                    bra       RegMoveDispatch dispatch the register move

EmitRegMove56       ldd       $06,s     load operand size
                    pshs      d         pass operand size
                    ldd       #$0089    operand code
                    pshs      d         pass operand code
                    ldd       #$0087    opcode selector
                    pshs      d         pass opcode selector
                    lbsr      GenOperand emit the instruction
                    leas      6,s        drop the arguments
                    bra       LoadOperandDone move complete

EmitRegMoveDefault  ldd       #$0089    operand code
                    pshs      d         pass operand code
                    ldd       #$0088    opcode selector
                    pshs      d         pass opcode selector
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    bra       LoadOperandDone move complete

RegMoveDispatch     cmpx      #$0005    operand size five?
                    beq       EmitRegMove56 emit five/six move
                    cmpx      #$0006    operand size six?
                    lbeq      EmitRegMove56 emit five/six move
                    bra       EmitRegMoveDefault otherwise default move

LoadOperandForce    pshs      u         pass the node pointer
                    lbsr      ForceReg70 force operand to register
                    leas      2,s        drop the argument
                    bra       LoadOperandDone load complete

LoadOperandDispatch cmpx      #$0008    operand size eight?
                    lbeq      LoadOperand8 load an eight-byte operand
                    cmpx      #$0005    operand size five?
                    lbeq      LoadOperand56 load a five/six operand
                    cmpx      #$0006    operand size six?
                    lbeq      LoadOperand56 load a five/six operand
                    bra       LoadOperandForce otherwise force to register

LoadOperandDone     puls      pc,u      return from load operand

EmitLeas            pshs      u         save frame pointer
                    ldd       #$FFB6    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldd       $04,s     load the leas offset
                    pshs      d         pass the offset
                    leax      MsgLeas,pcr leas output format string
                    pshs      x         pass the format
                    ldd       GlbVar0005 load the output file
                    pshs      d         pass the output file
                    lbsr      fprintf   emit the leas instruction
                    leas      6,s        drop the arguments
                    puls      pc,u      return from emit leas

FatalExit           pshs      u         save frame pointer
                    ldd       #$FFBA    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldd       InputFilename,y   temp file handle set?
                    beq       DoExit    none so skip removal
                    ldd       InputFilename,y   load temp file handle
                    pshs      d         pass the handle
                    lbsr      DeletePath remove the temp file
                    leas      2,s        drop the argument
DoExit              ldd       #$0001    exit status one
                    pshs      d         pass exit status
                    lbsr      exit      terminate the program
                    leas      2,s        drop the argument
                    puls      pc,u      unreached return

MsgDevNull          fcc       |/dev/null|
                    fcb       C$NULL
MsgBadArg           fcc       /bad argument: %s/
                    fcb       C$CR,C$NULL
MsgBadOption        fcc       /bad option flag: +%c/
                    fcb       C$CR,C$NULL
MsgTooManyFiles     fcc       /too many files/
                    fcb       C$NULL
ModeRead            fcb       $72
                    fcb       C$NULL
MsgCantOpenR        fcc       /can't open %s/
                    fcb       C$CR,C$NULL
EmptyStr            fcb       C$NULL
MsgBadAction        fcc       /bad action code: %d/
                    fcb       C$CR,C$NULL
MsgBadCode          fcc       /bad code in intermediate file: %02x/
                    fcb       C$CR,C$NULL
MsgBadNodeType      fcc       /bad node type: %02x/
                    fcb       C$CR,C$NULL
ModeWrite           fcb       $77
                    fcb       C$NULL
MsgCantOpenW        fcc       /can't open %s/
                    fcb       C$CR,C$NULL
MsgLeas             fcc       / leas %d,s/
                    fcb       C$CR,C$NULL
ForceReg70          pshs      u         save frame pointer
                    ldd       #$FFB4    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer argument
                    pshs      u         pass the node pointer
                    lbsr      EvalOperandTree evaluate the operand tree
                    leas      2,s        drop the argument
                    ldd       $06,u     load current operand type
                    cmpd      #$0070    already register type 70?
                    beq       ForceRegDone yes so done
                    pshs      u         pass the node pointer
                    ldd       #$0077    operand code
                    pshs      d         pass operand code
                    ldd       #$0070    target register code
                    pshs      d         pass target code
                    ldd       #$0075    opcode selector
                    pshs      d         pass opcode selector
                    lbsr      GenOperand emit load into register
                    leas      8,s        drop the arguments
                    ldd       #$0070    new operand type 70
                    bra       SetNodeType update the node type

ForceReg71          pshs      u         save frame pointer
                    ldd       #$FFB4    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer argument
                    pshs      u         pass the node pointer
                    lbsr      GenLeafAddr evaluate the operand tree
                    leas      2,s        drop the argument
                    ldd       $06,u     load current operand type
                    cmpd      #$0071    already register type 71?
                    beq       ForceRegDone yes so done
                    pshs      u         pass the node pointer
                    ldd       #$0077    operand code
                    pshs      d         pass operand code
                    ldd       #$0071    target register code
                    pshs      d         pass target code
                    ldd       #$0075    opcode selector
                    pshs      d         pass opcode selector
                    lbsr      GenOperand emit load into register
                    leas      8,s        drop the arguments
                    ldd       #$0071    new operand type 71
SetNodeType         std       $06,u     update the node operand type
ForceRegDone        puls      pc,u      return from register coercion

EvalOperandTree     pshs      u         save frame pointer
                    ldd       #$FFBA    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer argument
                    ldx       ,u        load node type field
                    bra       EvalTreeDispatch dispatch on node type

EvalTree8           pshs      u         pass the node pointer
                    lbsr      EvalOperand evaluate the subtree
                    bra       EvalTreeCleanup cleanup and finish

EvalTree56          pshs      u         pass the node pointer
                    lbsr      GenLongExpr evaluate the subtree
                    bra       EvalTreeCleanup cleanup and finish

EvalTreeDefault     pshs      u         pass the node pointer
                    lbsr      GenExpr   evaluate the subtree
                    leas      2,s        drop the argument
                    pshs      u         pass the node pointer
                    bsr       FoldRegOperand fold the register operand
EvalTreeCleanup     leas      2,s        drop the argument
                    bra       EvalTreeDone return from operand tree eval

EvalTreeDispatch    cmpx      #$0008    subtree size eight?
                    beq       EvalTree8 evaluate an eight subtree
                    cmpx      #$0005    subtree size five?
                    beq       EvalTree56 evaluate a five/six subtree
                    cmpx      #$0006    subtree size six?
                    lbeq      EvalTree56 evaluate a five/six subtree
                    bra       EvalTreeDefault otherwise default subtree

EvalTreeDone        puls      pc,u      return from operand tree eval

FoldRegOperand      pshs      u         save frame pointer
                    ldd       #$FFB4    stack frame size
                    lbsr      stkcheck  verify stack space
                    ldu       $04,s     load node pointer argument
                    ldx       $06,u     load operand type field
                    lbra      DispatchLoc dispatch on operand type

FoldRegLoad         pshs      u         pass the node pointer
                    ldd       #$0077    operand code
                    pshs      d         pass operand code
                    ldd       #$0071    target register code
                    pshs      d         pass target code
                    ldd       #$0075    opcode selector
                    pshs      d         pass opcode selector
                    lbsr      GenOperand emit load into register
                    leas      8,s        drop the arguments
                    ldd       #$0071    new operand type 71
                    std       $06,u     set the operand type
                    clra                clear high byte
                    clrb                clear low byte
                    std       $08,u     clear the operand value
                    lbra      CoerceDone fold complete

FoldRegIndexed      ldd       $0a,u     load the operand offset value
                    pshs      d         pass the offset
                    ldd       #$0077    operand code
                    pshs      d         pass operand code
                    ldd       #$0071    target register code
                    pshs      d         pass target code
                    ldd       #$007F    index operand code
                    pshs      d         pass index code
                    lbsr      GenOperand emit the indexed load
                    leas      8,s        drop the arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       $08,u     clear the operand value
                    ldd       #$0071    new operand type 71
                    bra       StoreLoc  continue folding

CoerceDefault       pshs      u         save node pointer for default coercion
                    ldd       #$0077    first operand code for emit
                    pshs      d         push emit argument
                    ldd       #$0070    second operand code
                    pshs      d         push emit argument
                    ldd       #$0075    third operand code
                    pshs      d         push emit argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop the pushed arguments
                    bra       DefaultLoc70 go set default result location

                    leas      ,x        dead thunk fragment
DefaultLoc70        ldd       #$0070    default result location code
StoreLoc            std       $06,u     store location field into node
                    bra       CoerceDone return from coercion

DispatchLoc         cmpx      #$0037    match location type $0037
                    lbeq      FoldRegLoad handle constant coercion
                    cmpx      #$0041    match location type $0041
                    beq       FoldRegIndexed handle address coercion
                    cmpx      #$0071    already in register, done
                    beq       CoerceDone already in register, done
                    cmpx      #$0070    already in register, done
                    beq       CoerceDone already in register, done
                    cmpx      #$006F    already in place, done
                    beq       CoerceDone already in place, done
                    cmpx      #$0076    already in place, done
                    beq       CoerceDone already in place, done
                    bra       CoerceDefault otherwise use default coercion

CoerceDone          puls      pc,u      return node to caller

GenExpr             pshs      u         save caller register
                    ldd       #$FFB4    reserve frame size for check
                    lbsr      stkcheck  check stack space available
                    ldu       $04,s     load node pointer argument
                    leas      -2,s       allocate one local word
                    ldd       $06,u     read node location field
                    std       ,s        save location copy locally
                    cmpd      #$0030    is this a comma/sequence node
                    bne       GenSimple no, handle simple node
                    leas      -2,s       allocate another local
                    ldd       $0C,u     fetch right child pointer
                    std       ,s        stash right child
                    ldd       $0a,u     fetch left child pointer
                    pshs      d         push as argument
                    bsr       GenExpr   recurse to generate left child
                    std       ,s        save returned node
                    lbsr      WalkTreeChildren free register bookkeeping
                    leas      2,s        drop argument
                    pshs      u         push current node
                    ldd       $02,s     fetch saved right child
                    pshs      d         push as argument
                    lbsr      CopyNode  allocate register for operand
                    leas      4,s        drop arguments
                    ldd       ,s        reload local
                    pshs      d         push argument
                    lbsr      FreeNode  release register
                    leas      2,s        drop argument
                    pshs      u         push node for recursion
                    lbsr      GenExpr   recurse to generate right child
                    leas      2,s        drop argument
                    leas      2,s        drop local
                    lbra      GenExprDone return generated node

GenSimple           ldd       ,u        read node operator word
                    cmpd      #$0008    is it a leaf/constant node
                    bne       GenType56Check no, keep checking
                    pshs      u         push node argument
                    lbsr      GenExpr3  generate leaf code
                    leas      2,s        drop argument
                    lbra      GenExprDone return generated node

GenType56Check      ldd       ,u        read operator word
                    cmpd      #$0005    operator type $0005
                    beq       GenType56 handle it
                    ldd       ,u        read operator again
                    cmpd      #$0006    operator type $0006
                    bne       GenLookup neither, keep going
GenType56           pshs      u         push node argument
                    lbsr      GenLongNode generate type 5/6 code
                    leas      2,s        drop argument
                    lbra      GenExprDone return generated node

GenLookup           ldd       ,s        load location field
                    pshs      d         push argument
                    lbsr      IsOpInRange look up operand handler
                    std       ,s++      pop lookup result
                    beq       GenByType none found, dispatch by type
                    pshs      u         push node argument
                    ldd       $02,s     fetch stashed value
                    pshs      d         push argument
                    lbsr      EmitBinOp generate via binary-op emitter
                    leas      4,s        drop arguments
                    lbra      GenExprDone return generated node

GenByType           ldx       ,s        load node location type
                    lbra      TypeDispatch dispatch by node type

GenType78           pshs      u         push node argument
                    lbsr      GenLoadTree generate type $0078 code
                    lbra      GenTail   finish via common tail

GenType85           ldd       $0a,u     fetch left child
                    pshs      d         push argument
                    lbsr      GenExpr   recurse on child
                    lbra      GenTail   finish via common tail

GenType84           ldd       $0a,u     fetch child pointer
                    pshs      d         push argument
                    lbsr      GenExpr3  generate leaf code
                    leas      2,s        drop argument
                    ldd       $0a,u     fetch child again
                    pshs      d         push argument
                    ldd       #$0077    operand code for emit
                    pshs      d         push argument
                    ldd       #$0084    operator code $0084
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop arguments
                    bra       SetLoc70  set result location

GenType8F           ldd       $0a,u     fetch child pointer
                    pshs      d         push argument
                    lbsr      GenLongExpr generate child code
                    leas      2,s        drop argument
                    ldd       #$008F    operand code $008F
                    pshs      d         push argument
                    ldd       #$0087    operator code $0087
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    bra       GenDropSet drop args and set location

GenType42           pshs      u         push node argument
                    lbsr      GenLoadLeaf generate type $0042 code
                    bra       GenTail   finish via common tail

GenType40           pshs      u         push node argument
                    lbsr      GenBoolBranch generate code
                    bra       GenTail   finish via common tail

GenType44           ldd       $0a,u     fetch child pointer
                    pshs      d         push argument
                    lbsr      ForceReg70 generate child code
                    leas      2,s        drop argument
                    ldd       ,s        reload operand code
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      2,s        drop argument
                    bra       SetLoc70  set result location

GenType64           leax      ForceReg70,pcr pass child generator address
                    pshs      x         push argument
                    pshs      u         push node
                    lbsr      GenBoolBranchInd generate type $0064 code
GenDropSet          leas      4,s        drop the pushed arguments
SetLoc70            ldd       #$0070    default result location code
                    std       $06,u     store location into node
                    lbra      GenExprDone return generated node

GenCompare          ldd       #$0070    default result location code
                    pshs      d         push argument
                    pshs      u         push node
                    lbsr      GenBinaryNode generate comparison code
                    bra       GenTail4  finish via four-byte tail

GenType65           pshs      u         push node argument
                    lbsr      GenExprList generate type $0065 code
GenTail             leas      2,s        drop argument
                    lbra      GenExprDone return generated node

GenDefault          ldd       ,s        load location type
                    cmpd      #$00A0    compare against high threshold
                    blt       GenLowType below, take low-type path
                    ldd       ,s        reload location type
                    pshs      d         push argument
                    pshs      u         push node
                    lbsr      GenStoreTree generate code
                    bra       GenTail4  finish via four-byte tail

GenLowType          leax      MsgTranslation,pcr point to format string
                    pshs      x         push argument
                    pshs      u         push node
                    lbsr      BuildLabelText report/handle low type
                    leas      4,s        drop arguments
                    ldd       ,s        reload location code
                    pshs      d         push argument
                    leax      MsgPctXCR,pcr point to format string
                    pshs      x         push argument
                    lbsr      Printf    emit formatted output
GenTail4            leas      4,s        drop the arguments
                    lbra      GenExprDone return generated node

TypeDispatch        cmpx      #$0037    match node type $0037
                    lbeq      GenExprDone pass through unchanged
                    cmpx      #$0034    match node type $0034
                    lbeq      GenExprDone pass through unchanged
                    cmpx      #$0076    match node type $0076
                    lbeq      GenExprDone pass through unchanged
                    cmpx      #$006F    match node type $006F
                    lbeq      GenExprDone pass through unchanged
                    cmpx      #$0041    match node type $0041
                    beq       GenExprDone pass through unchanged
                    cmpx      #$0036    match node type $0036
                    beq       GenExprDone pass through unchanged
                    cmpx      #$0078    match node type $0078
                    lbeq      GenType78 handle it
                    cmpx      #$0085    match node type $0085
                    lbeq      GenType85 handle it
                    cmpx      #$0084    match node type $0084
                    lbeq      GenType84 handle it
                    cmpx      #$008F    match node type $008F
                    lbeq      GenType8F handle it
                    cmpx      #$0042    match node type $0042
                    lbeq      GenType42 handle it
                    cmpx      #$0040    match node type $0040
                    lbeq      GenType40 handle it
                    cmpx      #$0047    match node type $0047
                    lbeq      GenType40 handle it
                    cmpx      #$0048    match node type $0048
                    lbeq      GenType40 handle it
                    cmpx      #$0044    match node type $0044
                    lbeq      GenType44 handle it
                    cmpx      #$0043    match node type $0043
                    lbeq      GenType44 handle it
                    cmpx      #$0064    match node type $0064
                    lbeq      GenType64 handle it
                    cmpx      #$003C    match comparison type $003C
                    lbeq      GenCompare handle it
                    cmpx      #$003E    match comparison type $003E
                    lbeq      GenCompare handle it
                    cmpx      #$003D    match comparison type $003D
                    lbeq      GenCompare handle it
                    cmpx      #$003F    match comparison type $003F
                    lbeq      GenCompare handle it
                    cmpx      #$0065    match node type $0065
                    lbeq      GenType65 handle it
                    lbra      GenDefault otherwise take default path

GenExprDone         tfr       u,d       return node pointer in d
                    leas      2,s        drop local
                    puls      pc,u      return to caller

EmitBinOp           pshs      u         save caller register
                    ldd       #$FFAE    reserve frame size for check
                    lbsr      stkcheck  check stack space available
                    leas      -6,s       allocate three local words
                    ldx       $0C,s     load node argument
                    ldu       $0a,x     fetch left child pointer
                    ldx       $0C,s     reload node argument
                    ldd       $0C,x     fetch right child pointer
                    std       $04,s     save right child locally
                    ldd       ,u        read left child operator
                    cmpd      #$0007    is it type $0007
                    bne       NonSevenPath no, take non-seven path
                    ldx       $0a,s     load operator code
                    bra       RelOpSwitch map relational operator

MapOp4E             ldd       #$004E    mapped opcode for $0053
                    bra       StoreMapOp store the mapped opcode

MapOp4C             ldd       #$004C    mapped opcode for $0054
                    bra       StoreMapOp store the mapped opcode

MapOp4D             ldd       #$004D    mapped opcode for $0055
StoreMapOp          std       $0a,s     store mapped opcode locally
                    bra       BinOpTail continue to emitter tail

RelOpSwitch         cmpx      #$0053    operator $0053
                    beq       MapOp4E   map it
                    cmpx      #$0054    operator $0054
                    beq       MapOp4C   map it
                    cmpx      #$0055    operator $0055
                    beq       MapOp4D   map it
                    bra       BinOpTail otherwise continue unmapped

NonSevenPath        ldx       $0a,s     load operator code
                    bra       AddrOpSwitch dispatch address-op switch

OptDeref            ldd       $06,u     read left child location
                    cmpd      #$0041    is it address type $0041
                    bne       BinOpTail no, continue unmapped
                    ldx       $04,s     load right child pointer
                    ldd       $06,x     read right child location
                    cmpd      #$0036    is it register type $0036
                    beq       BinOpTail yes, continue unmapped
                    ldd       $0C,s     load node argument
                    pshs      d         push argument
                    lbsr      GenLeafAddr optimize/generate deref
                    leas      2,s        drop argument
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0019 clear global flag at $0019
                    lbra      GenReturn return early

                    bra       BinOpTail fallthrough guard to tail

AddrOpSwitch        cmpx      #$0050    operator $0050
                    beq       OptDeref  optimize it
                    cmpx      #$0051    operator $0051
                    lbeq      OptDeref  optimize it
BinOpTail           ldx       $0a,s     load operator code
                    lbra      DispatchBinOp dispatch to instruction emitter

GenStore            ldd       $04,s     load node argument
                    pshs      d         push argument
                    lbsr      NodeIsConst classify operand
                    std       ,s++      pop classification result
                    bne       GenStoreAlt nonzero, take alternate path
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      EvalOperandTree generate operand code
                    leas      2,s        drop argument
                    ldx       $04,s     load node pointer
                    ldd       $06,x     read node location field
                    pshs      d         push argument
                    ldd       #$007A    operand code for emit
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop arguments
                    ldd       #$006E    result location code
                    ldx       $04,s     load node pointer
                    std       $06,x     store location into node
                    pshs      u         push node
                    lbsr      ForceReg70 generate remaining code
                    bra       GenStoreEmit go emit store instruction

GenStoreAlt         pshs      u         push node
                    lbsr      ForceReg70 generate operand code
                    leas      2,s        drop argument
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      GenExpr   recurse to generate node
GenStoreEmit        leas      2,s        drop argument
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    ldd       #$0077    operand code for emit
                    pshs      d         push argument
                    ldd       #$0070    operand code for emit
                    pshs      d         push argument
                    ldd       #$0051    store operator code $0051
                    lbra      EmitAndDone emit instruction and finish

GenCommutative      pshs      u         push node
                    lbsr      NodeIsConst classify first operand
                    std       ,s++      pop classification result
                    beq       CheckLoc36 zero, check location
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      NodeIsConst classify second operand
                    std       ,s++      pop classification result
                    beq       SwapOperands zero, swap operands
CheckLoc36          ldd       $06,u     read operand location
                    cmpd      #$0036    is it register type $0036
                    bne       GenOperandLoad no, load operand
SwapOperands        leas      -2,s       allocate swap slot
                    stu       ,s        store first operand
                    ldu       $06,s     load saved second operand
                    ldd       ,s        reload first operand
                    std       $06,s     store swapped operand
                    leas      2,s        drop swap slot
GenOperandLoad      ldd       $06,u     read operand location
                    pshs      d         push argument
                    lbsr      IsFloatType look up operand emitter
                    std       ,s++      pop lookup result
                    beq       GenLeftFirst none, generate left first
                    ldd       $06,u     reload operand location
EmitLoad7A          pshs      d         push argument
                    ldd       #$007A    operand code for emit
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop arguments
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      ForceReg70 generate operand code
                    leas      2,s        drop argument
                    ldd       #$006E    result location code
                    ldx       $04,s     load node pointer
                    std       $06,x     store location into node
                    bra       EmitBinTail go emit binary operation

GenLeftFirst        pshs      u         push node
                    lbsr      ForceReg70 generate left operand
                    leas      2,s        drop argument
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      NodeIsConst classify right operand
                    std       ,s++      pop classification result
                    bne       GenRightRecurse nonzero, recurse on right
                    ldd       #$0070    result location code
                    bra       EmitLoad7A go emit load

GenRightRecurse     ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      GenExpr   recurse to generate right
                    leas      2,s        drop argument
                    ldd       $0a,s     reload mapped operator
                    cmpd      #$0050    was it address op $0050
                    beq       EmitBinTail yes, skip extra emit
                    ldd       $04,s     reload node
                    pshs      d         push argument
                    lbsr      ResolveNegFlag generate extra code
                    leas      2,s        drop argument
EmitBinTail         ldd       $04,s     reload node
                    pshs      d         push argument
                    ldd       #$0077    operand code for emit
                    pshs      d         push argument
                    ldd       #$0070    operand code for emit
                    pshs      d         push argument
                    ldd       $10,s     fetch mapped operator code
EmitAndDone         pshs      d         push operator argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    lbra      ClearFlagExit return generated node

GenSimpleCall       ldd       $0C,s     load node argument
                    pshs      d         push argument
                    lbsr      GenBoolBranch generate code
                    lbra      EmitBinaryDone return generated node

GenIndexed          ldx       $04,s     load node pointer
                    ldd       $06,x     read node location field
                    cmpd      #$0036    is it register type $0036
                    lbne      RestoreArgsJoin no, take non-indexed path
                    ldx       $04,s     reload node pointer
                    ldd       $08,x     read operand size/value
                    std       ,s        save size locally
                    bra       CheckSmallSize check size threshold

GenNegIndex         leas      -$06,x    negative-index frame adjust
CheckSmallSize      ldd       ,s        load operand size
                    cmpd      #$0004    is it larger than four
                    bhi       RestoreArgsJoin yes, non-indexed path
                    pshs      u         push node
                    lbsr      ForceReg70 generate operand code
GenIndexTail        leas      2,s        drop argument
                    bra       DecCountLoop continue index generation

IndexOpSwitch       ldx       $0a,s     load operator code
                    bra       IndexOpDispatch dispatch index-op switch

MapOp98             ldd       #$0098    select index opcode $0098
                    bra       StoreOpEmit emit the selected opcode

MapOp96             ldd       #$0096    select index opcode $0096
                    bra       StoreOpEmit emit the selected opcode

MapOp97             ldd       #$0097    select index opcode $0097
StoreOpEmit         pshs      d         push opcode argument
                    lbsr      GenOperand emit instruction
                    bra       GenIndexTail continue index generation

IndexOpDispatch     cmpx      #$0056
                    beq       MapOp98   branch for matching node opcode
                    cmpx      #$0055    compare node opcode with $55
                    beq       MapOp96   branch on opcode $55
                    cmpx      #$004D    compare node opcode with $4D
                    beq       MapOp97   branch on opcode $4D
DecCountLoop        ldd       ,s        load loop counter
                    addd      #$FFFF    decrement counter
                    std       ,s        store decremented counter
                    subd      #$FFFF    restore to test original value
                    bne       IndexOpSwitch loop while counter nonzero
                    ldd       #$0001    flag value one
                    std       GlbVar0019 set global result flag
                    leax      $06,s     point past saved arguments
                    lbra      RestoreFrameExit go finish result node

RestoreArgsJoin     leax      $06,s     restore stack past arguments
                    bra       RestoreFrameJoin join common handler

CommuteAssign       ldd       $06,u     load right operand opcode
                    cmpd      #$0036    is it a constant node
                    bne       FoldConstOperand no skip operand swap
                    leas      -2,s       make scratch slot
                    stu       ,s        save node pointer
                    ldu       $06,s     load other operand
                    ldd       ,s        reload node pointer
                    std       $06,s     swap operands
                    leas      2,s        drop scratch slot
FoldConstOperand    ldx       $04,s     load node pointer
                    ldd       $06,x     load right operand opcode
                    cmpd      #$0036    is it constant
                    bne       GenBinaryOp no use generic handler
                    ldx       $04,s     reload node pointer
                    ldd       $08,x     load constant value
                    pshs      d         pass constant value
                    lbsr      LookupConstSlot look up constant slot index
                    leas      2,s        drop argument
                    std       ,s        save lookup result
                    beq       GenBinaryOp not found use generic
                    ldd       ,s        reload folded value
                    ldx       $04,s     reload node pointer
                    std       $08,x     store folded operand
                    ldd       $0a,s     load current operator
                    cmpd      #$0052    is it operator $52
                    bne       OpDefault4D no choose default operator
                    ldd       #$0056    pick operator $56
                    bra       StoreNewOp store chosen operator

OpDefault4D         ldd       #$004D    default operator $4D
StoreNewOp          std       $0a,s     store new operator
                    leax      $06,s     point past arguments
                    lbra      GenNegIndex reprocess folded node

RestoreFrameJoin    leas      -$06,x    restore stack frame
GenBinaryOp         pshs      u         pass node pointer
                    lbsr      EvalOperandTree generate left subtree
                    leas      2,s        drop argument
                    ldd       $06,u     load operator opcode
                    pshs      d         pass operator
                    ldd       #$007A    push mnemonic $7A
                    pshs      d         pass mnemonic
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop arguments
                    ldd       $04,s     load node pointer
                    pshs      d         pass node pointer
                    lbsr      ForceReg70 generate right subtree
                    leas      2,s        drop argument
                    ldd       $0a,s     load operator
                    pshs      d         pass operator
                    lbsr      GenOperand emit instruction
EmitBinaryDone      leas      2,s        drop argument
                    lbra      ClearFlagExit clear flag and finish

ErrBinaryOp         leax      MsgBinaryOp,pcr point at binary-op error string
                    pshs      x         pass message pointer
                    ldd       $0e,s     load node context
                    pshs      d         pass context
                    lbsr      BuildLabelText report internal error
                    leas      4,s        drop arguments
                    lbra      ClearFlagExit clear flag and finish

DispatchBinOp       cmpx      #$0051    dispatch on node opcode $51
                    lbeq      GenStore  handle opcode $51
                    cmpx      #$0057    compare opcode $57
                    lbeq      GenCommutative handle opcode $57
                    cmpx      #$0058    compare opcode $58
                    lbeq      GenCommutative handle opcode $58
                    cmpx      #$0059    compare opcode $59
                    lbeq      GenCommutative handle opcode $59
                    cmpx      #$0050    compare opcode $50
                    lbeq      GenCommutative handle opcode $50
                    cmpx      #$005A    compare opcode $5A
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$005B    compare opcode $5B
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$005F    compare opcode $5F
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$005D    compare opcode $5D
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$005C    compare opcode $5C
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$005E    compare opcode $5E
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$0063    compare opcode $63
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$0061    compare opcode $61
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$0060    compare opcode $60
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$0062    compare opcode $62
                    lbeq      GenSimpleCall handle unary-class opcode
                    cmpx      #$004D    compare opcode $4D
                    lbeq      GenIndexed handle commutative opcode
                    cmpx      #$0055    compare opcode $55
                    lbeq      GenIndexed handle commutative opcode
                    cmpx      #$0056    compare opcode $56
                    lbeq      GenIndexed handle commutative opcode
                    cmpx      #$0052    compare opcode $52
                    lbeq      CommuteAssign handle commute-assign case
                    cmpx      #$004E    compare opcode $4E
                    lbeq      FoldConstOperand handle fold-constant case
                    cmpx      #$0053    compare opcode $53
                    lbeq      GenBinaryOp handle via generic binary op
                    cmpx      #$004C    compare opcode $4C
                    lbeq      GenBinaryOp handle via generic binary op
                    cmpx      #$0054    compare opcode $54
                    lbeq      GenBinaryOp handle via generic binary op
                    lbra      ErrBinaryOp default report error

                    leas      -$06,x    dead stack adjust
ClearFlagExit       clra                result high byte zero
                    clrb                result low byte zero
                    std       GlbVar0019 clear global result flag
                    bra       SetResultReg set result node

RestoreFrameExit    leas      -$06,x    restore stack frame
SetResultReg        ldd       #$0070    result register-node opcode
                    ldx       $0C,s     load result node pointer
                    std       $06,x     store result opcode
                    lbra      GenReturn return from generator

LookupConstSlot     pshs      u         save frame pointer
                    ldd       #$FFC0    stack frame size
                    lbsr      stkcheck  check stack overflow
                    ldu       #$0000    start index zero
                    bra       LookupCheck test loop bound first

LookupLoop          tfr       u,d       index to d
                    leau      $01,u     advance index
                    aslb                multiply index low by two
                    rola                multiply index high by two
                    leax      >LookupTable,y  point at lookup table
                    leax      d,x       index into table
                    ldd       ,x        load table entry
                    cmpd      $04,s     compare with target value
                    bne       LookupCheck no match continue search
                    tfr       u,d       return matched index
                    puls      pc,u      restore frame and return

LookupCheck         cmpu      #$000E    reached table end
                    blt       LookupLoop no keep searching
                    lbra      RetZero   not found error exit

GenBoolBranch       pshs      u         save frame pointer
                    ldd       #$FFB0    stack frame size
                    lbsr      stkcheck  check stack overflow
                    ldu       $04,s     load node argument
                    leas      -4,s       allocate locals
                    ldd       #$0001    constant one field
                    pshs      d         push node field
                    ldd       GlbVar000B load label counter
                    addd      #$0001    next label number
                    std       GlbVar000B update label counter
                    std       $02,s     save first label
                    pshs      d         push label
                    ldd       GlbVar000B load label counter
                    addd      #$0001    next label number
                    std       GlbVar000B update label counter
                    std       $06,s     save second label
                    pshs      d         push label
                    pshs      u         push node pointer
                    lbsr      GenExpr2  build tree node
                    leas      8,s        drop arguments
                    ldd       $02,s     load first label
                    pshs      d         pass label
                    lbsr      EmitLocalLabelLine emit label definition
                    leas      2,s        drop argument
                    ldd       #$0001    operand field one
                    pshs      d         push operand field
                    ldd       #$0036    constant node opcode
                    pshs      d         push node opcode
                    ldd       #$0070    register node opcode
                    pshs      d         push node opcode
                    ldd       #$0075    branch node opcode
                    pshs      d         push node opcode
                    lbsr      GenOperand emit branch instruction
                    leas      8,s        drop arguments
                    ldd       #$0001    operand field one
                    pshs      d         push operand field
                    ldd       GlbVar000B load label counter
                    addd      #$0001    next label number
                    std       GlbVar000B update label counter
                    std       $04,s     save third label
                    pshs      d         push label
                    ldd       #$007C    jump node opcode
                    pshs      d         push node opcode
                    lbsr      GenOperand emit jump instruction
                    leas      6,s        drop arguments
                    ldd       ,s        load pushed field
                    pshs      d         push field
                    lbsr      EmitLocalLabelLine emit label definition
                    leas      2,s        drop argument
                    clra                value zero high
                    clrb                value zero low
                    pshs      d         push zero
                    ldd       #$0036    constant node opcode
                    pshs      d         push node opcode
                    ldd       #$0070    register node opcode
                    pshs      d         push node opcode
                    ldd       #$0075    branch node opcode
                    pshs      d         push node opcode
                    lbsr      GenOperand emit branch instruction
                    leas      8,s        drop arguments
                    ldd       $02,s     load first label
                    pshs      d         pass label
                    lbsr      EmitLocalLabelLine emit label definition
                    leas      2,s        drop argument
                    ldd       #$0070    result register-node opcode
                    std       $06,u     store result opcode
                    lbra      LeafEpilogue return from generator

GenBoolBranchInd    pshs      u         save frame pointer
                    ldd       #$FFAE    stack frame size
                    lbsr      stkcheck  check stack overflow
                    ldu       $04,s     load node argument
                    leas      -6,s       allocate locals
                    ldd       #$0001    constant one field
                    pshs      d         push field
                    ldd       GlbVar000B load label counter
                    addd      #$0001    next label number
                    std       GlbVar000B update label counter
                    std       $02,s     save first label
                    pshs      d         push label
                    ldd       GlbVar000B load label counter
                    addd      #$0001    next label number
                    std       GlbVar000B update label counter
                    std       $08,s     save second label
                    pshs      d         push label
                    ldd       $0a,u     load node subfield
                    pshs      d         push subfield
                    lbsr      GenExpr2  build tree node
                    leas      8,s        drop arguments
                    ldu       $0C,u     follow node link
                    ldd       $04,s     load label
                    pshs      d         pass label
                    lbsr      EmitLocalLabelLine emit label definition
                    leas      2,s        drop argument
                    ldd       $0a,u     load call target field
                    pshs      d         pass field
                    jsr       [$0e,s]   call through function pointer
                    leas      2,s        drop argument
                    clra                value zero high
                    clrb                value zero low
                    pshs      d         push zero
                    ldd       GlbVar000B load label counter
                    addd      #$0001    next label number
                    std       GlbVar000B update label counter
                    std       $04,s     save third label
                    pshs      d         push label
                    ldd       #$007C    jump node opcode
                    pshs      d         push node opcode
                    lbsr      GenOperand emit jump instruction
                    leas      6,s        drop arguments
                    ldd       ,s        load pushed field
                    pshs      d         push field
                    lbsr      EmitLocalLabelLine emit label definition
                    leas      2,s        drop argument
                    ldd       $0C,u     load node link field
                    pshs      d         pass field
                    jsr       [$0e,s]   call through function pointer
                    leas      2,s        drop argument
                    ldd       $02,s     load first label
                    pshs      d         pass label
                    lbsr      EmitLocalLabelLine emit label definition
                    leas      2,s        drop argument
GenReturn           leas      6,s        drop locals
                    puls      pc,u      restore frame and return

GenExprList         pshs      u         save frame pointer
                    ldd       #$FFB2    stack frame size
                    lbsr      stkcheck  check stack overflow
                    leas      -4,s       allocate locals
                    ldd       GlbVar000D load list head
                    std       ,s        save current node
                    ldd       $08,s     load argument
                    std       $02,s     save argument node
                    lbra      ExprListNext enter chain loop

ExprListLoop        ldx       $02,s     load current node
                    ldu       $0a,x     load node expression
                    ldd       ,u        load expression opcode
                    cmpd      #$0008    is it a store node
                    bne       CheckAddSub no check other types
                    ldd       $06,u     load subopcode
                    cmpd      #$004A    is it opcode $4A
                    bne       GenIndirectCall no handle general store
                    pshs      u         pass expression node
                    lbsr      LoadLongConst generate special store
                    leas      2,s        drop argument
                    lbra      ExprListNext continue chain

GenIndirectCall     pshs      u         pass expression node
                    lbsr      EvalOperand generate address
                    leas      2,s        drop argument
                    ldd       #$006E    operand opcode
                    pshs      d         push operand opcode
                    ldd       #$0088    indirect-call node opcode
                    bra       DoEmit    emit instruction

CheckAddSub         ldd       ,u        load expression opcode
                    cmpd      #$0005    is it add node
                    beq       GenLeaArg yes handle lea
                    ldd       ,u        reload opcode
                    cmpd      #$0006    is it subtract node
                    bne       GenValueArg no handle generic
GenLeaArg           pshs      u         pass expression node
                    lbsr      GenLongExpr generate address expression
                    leas      2,s        drop argument
                    ldd       #$006E    operand opcode
                    pshs      d         push operand opcode
                    ldd       #$0087    lea node opcode
                    bra       DoEmit    emit instruction

GenValueArg         pshs      u         pass expression node
                    lbsr      GenExpr   generate value into register
                    leas      2,s        drop argument
                    ldx       $06,u     load result register opcode
                    bra       CheckRegClass check register class

ForceIntoReg        pshs      u         pass expression node
                    lbsr      FoldRegOperand force value into register
                    leas      2,s        drop argument
                    bra       EmitPushArg emit push

CheckRegClass       cmpx      #$0070    is result in d
                    beq       EmitPushArg yes emit push
                    cmpx      #$0071    compare register opcode $71
                    beq       EmitPushArg yes emit push
                    cmpx      #$006F    compare register opcode $6F
                    beq       EmitPushArg yes emit push
                    cmpx      #$0076    compare register opcode $76
                    beq       EmitPushArg yes emit push
                    bra       ForceIntoReg otherwise force into register

EmitPushArg         ldd       $06,u     load register opcode
                    pshs      d         push register opcode
                    ldd       #$007A    push mnemonic $7A
DoEmit              pshs      d         pass mnemonic
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop arguments
ExprListNext        ldx       $02,s     load current node
                    ldd       $0C,x     load next link
                    std       $02,s     advance current node
                    lbne      ExprListLoop loop while more nodes
                    ldx       $08,s     load argument node
                    ldd       $0a,x     load expression
                    pshs      d         pass expression
                    lbsr      GenExpr   generate value into register
                    leas      2,s        drop argument
                    ldx       $08,s     reload argument node
                    ldd       $0a,x     load expression
                    pshs      d         pass expression
                    ldd       #$0077    operand opcode
                    pshs      d         push operand opcode
                    ldd       #$0065    call node opcode
                    pshs      d         push node opcode
                    lbsr      GenOperand emit call instruction
                    leas      6,s        drop arguments
                    ldd       ,s        load pushed field
                    pshs      d         push field
                    lbsr      EmitStackAdjust2 patch stack adjustment
                    leas      2,s        drop argument
                    std       GlbVar000D update list head
                    ldd       #$0070    result register-node opcode
                    ldx       $08,s     load result node
                    std       $06,x     store result opcode
                    lbra      LeafEpilogue return from generator

IsSimpleAddr        pshs      u         save frame pointer
                    ldd       #$FFB8    stack frame size
                    lbsr      stkcheck  check stack overflow
                    ldu       $04,s     load node argument
                    leas      -2,s       allocate local
                    ldx       $06,u     load node opcode
                    bra       ClassifyNode classify node opcode

InspectIndChild     ldd       $0a,u     load child pointer
                    std       ,s        save child pointer
                    tfr       d,x       child pointer to x
                    ldx       $06,x     load grandchild opcode
                    bra       ClassifyChild classify child opcode

ReturnTrue          ldd       #$0001    return true
                    bra       AddrReturn return result

CheckChildAddr      ldd       ,s        load child pointer
                    pshs      d         pass child
                    bsr       IsIndexedAddr check child node
                    leas      2,s        drop argument
                    bra       AddrReturn return result

ClassifyChild       cmpx      #$0036    is child constant
                    beq       ReturnTrue yes return true
                    cmpx      #$0034    is child a name
                    lbeq      ReturnTrue yes return true
                    cmpx      #$0076    compare child opcode $76
                    lbeq      ReturnTrue yes return true
                    cmpx      #$006F    compare child opcode $6F
                    lbeq      ReturnTrue yes return true
                    bra       CheckChildAddr otherwise check deeper

ClassifyNode        cmpx      #$0034    is node a name
                    lbeq      ReturnTrue yes return true
                    cmpx      #$0036    is node constant
                    lbeq      ReturnTrue yes return true
                    cmpx      #$0042    is node an indirection
                    beq       InspectIndChild yes inspect child
                    clra                return false high
                    clrb                return false low
AddrReturn          leas      2,s        drop local
                    puls      pc,u      restore frame and return

IsIndexedAddr       pshs      u         save frame pointer
                    ldd       #$FFBA    stack frame size
                    lbsr      stkcheck  check stack overflow
                    ldu       $04,s     load node argument
                    ldx       $06,u     load node opcode
                    bra       IndexOpSwitch2 classify node opcode

TestIndexEligible   ldx       $0a,u     load left child
                    ldd       $06,x     load child opcode
                    pshs      d         pass opcode
                    lbsr      IsFloatType test register-index eligible
                    std       ,s++      save result drop slot
                    lbeq      RetZero   not eligible fail
                    ldx       $0C,u     load right child
                    ldd       $06,x     load child opcode
                    cmpd      #$0036    is it constant
                    lbne      RetZero   no fail
                    bra       AddrTrue  accept indexed address

                    lbra      RetZero   dead fail exit

IndexOpSwitch2      cmpx      #$0050    is node an index op
                    beq       TestIndexEligible yes test eligibility
                    cmpx      #$0051    compare node opcode $51
                    lbeq      TestIndexEligible take zero branch
                    bra       RetZero   return zero

IsSmallSize         pshs      u         save frame pointer
                    ldd       #$FFC0    frame size minus 64
                    lbsr      stkcheck  check stack space
                    ldx       $04,s     load node argument
                    ldd       $12,x     read size field
                    cmpd      #$0002    compare size to two
                    bge       RetZero   return zero if not small
                    ldd       #$0001    result one
                    bra       RetVal    return the value

IsAddrNode          pshs      u         save frame pointer
                    ldd       #$FFC0    frame size
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     load node argument
                    ldx       $06,u     read node type
                    bra       AddrDispatch dispatch on type

AddrChkChild        ldx       $0a,u     load child pointer
                    ldd       $06,x     read child type
                    cmpd      #$0041    child type $41?
                    bne       RetZero   return zero if not
AddrTrue            ldd       #$0001    result one
                    puls      pc,u      return the value

                    bra       RetZero   fall through to return zero

AddrDispatch        cmpx      #$0050    type $50?
                    beq       AddrChkChild check child
                    cmpx      #$0051    type $51?
                    lbeq      AddrChkChild check child
                    cmpx      #$0037    type $37?
                    beq       AddrTrue  return one
                    cmpx      #$0041    type $41?
                    lbeq      AddrTrue  return one
RetZero             clra                result zero
                    clrb                result zero
RetVal              puls      pc,u      return

ResolveNegFlag      pshs      u         save frame pointer
                    ldd       #$FFB4    frame size minus 76
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     load node argument
                    ldd       $06,u     read type flag field
                    anda      #$80      isolate high bit
                    clrb                clear low byte
                    std       -$02,s    save negate flag local
                    beq       NegDone   done if flag clear
                    ldd       $06,u     reload type field
                    anda      #$7f      clear the high bit
                    std       $06,u     store cleared type back
                    pshs      u         push node argument
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldd       #$0071    operand value
                    pshs      d         push argument
                    ldd       #$0075    operand value
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    ldd       #$0093    new type $93
                    std       $06,u     set node type
                    clra                zero
                    clrb                zero
                    std       $08,u     clear field $08
NegDone             puls      pc,u      return

GenLoadTree         pshs      u         save frame pointer
                    ldd       #$FFB0    frame size minus 80
                    lbsr      stkcheck  check stack space
                    leas      -4,s       reserve locals
                    ldx       $08,s     load node argument
                    ldd       $0C,x     read field $0C
                    std       ,s        save local
                    ldx       $08,s     reload node argument
                    ldu       $0a,x     load child pointer
                    ldd       $06,u     read child type
                    pshs      d         push type
                    lbsr      IsFloatType classify type
                    std       ,s++      save result and pop
                    lbeq      GenLoadAlt branch if not classified
                    ldd       ,s        reload type
                    pshs      d         push it
                    lbsr      IsIndexedAddr test predicate
                    std       ,s++      save result and pop
                    beq       GenLoadPlain branch if false
                    ldd       ,s        reload type
                    pshs      d         push it
                    lbsr      GenLeafAddr process operand
                    bra       GenLoadChild continue

GenLoadPlain        ldd       ,s        reload type
                    pshs      d         push it
                    lbsr      GenExpr   process operand
GenLoadChild        leas      2,s        drop argument
                    ldx       ,s        load child pointer
                    ldx       $06,x     read child type
                    bra       GenLoadDispatch dispatch on type

GenLoadIndex        ldx       ,s        load child pointer
                    ldd       $0a,x     read field $0a
                    pshs      d         push argument
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldd       $06,u     read node type
                    pshs      d         push argument
                    ldd       #$007F    operand value
                    bra       GenLoadEmitTail go emit

GenLoadDeref        ldd       ,s        load pointer
                    pshs      d         push argument
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldd       #$0070    operand value
                    pshs      d         push argument
                    ldd       #$0075    operand value
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
GenLoadEmit         ldd       ,s        load pointer
                    pshs      d         push argument
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldd       $06,u     read node type
                    pshs      d         push argument
                    ldd       #$0075    operand value
GenLoadEmitTail     pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    lbra      GenSetType go set result type

GenLoadDispatch     cmpx      #$0041    type $41?
                    beq       GenLoadIndex indexed case
                    cmpx      #$0085    type $85?
                    beq       GenLoadDeref deref case
                    bra       GenLoadEmit default emit

GenLoadAlt          pshs      u         push node
                    lbsr      IsSimpleAddr classify node
                    std       ,s++      save result and pop
                    beq       GenLoadReg branch if false
                    ldd       ,u        read node field
                    cmpd      #$0002    compare to two
                    beq       GenLoadReg branch if equal
                    ldd       ,s        reload
                    pshs      d         push it
                    lbsr      IsIndexedAddr test predicate
                    std       ,s++      save result and pop
                    bne       GenLoadStore branch if true
                    ldd       ,s        reload
                    pshs      d         push it
                    lbsr      IsAddrNode test address predicate
                    std       ,s++      save result and pop
                    beq       GenLoadReg branch if false
GenLoadStore        pshs      u         push node
                    lbsr      GenExpr   process operand
                    leas      2,s        drop argument
                    ldd       ,s        reload
                    pshs      d         push it
                    lbsr      GenDerefNode process operand
                    lbra      GenLoadCleanup go cleanup

GenLoadReg          ldx       ,s        load pointer
                    ldd       $06,x     read type
                    pshs      d         push it
                    lbsr      IsFloatType classify type
                    std       ,s++      save result and pop
                    beq       GenLoadSize branch if not classified
                    pshs      u         push node
                    lbsr      GenExpr   process operand
                    leas      2,s        drop argument
                    ldd       ,u        read node field
                    cmpd      #$0002    compare to two
                    lbne      GenLoadTail branch if not two
                    ldd       ,s        reload
                    pshs      d         push it
                    lbsr      ForceReg70 process operand
                    bra       GenLoadCleanup go cleanup

GenLoadSize         pshs      u         push node
                    lbsr      IsSmallSize test size predicate
                    std       ,s++      save result and pop
                    beq       GenLoadSpill branch if false
                    ldd       ,s        reload
                    pshs      d         push it
                    lbsr      ForceReg70 process operand
                    leas      2,s        drop argument
                    pshs      u         push node
                    lbsr      GenExpr   process operand
                    bra       GenLoadCleanup go cleanup

GenLoadSpill        pshs      u         push node
                    lbsr      GenExpr   process operand
                    leas      2,s        drop argument
                    ldd       ,s        reload
                    pshs      d         push it
                    lbsr      IsSimpleAddr classify node
                    std       ,s++      save result and pop
                    bne       GenLoadFinal branch if true
                    ldd       $06,u     read node type
                    anda      #$7f      clear high bit
                    tfr       d,x       move into x to compare
                    bra       GenLoadFreeChk dispatch

GenLoadFree         pshs      u         push node
                    lbsr      GenAddrOffset spill or free operand
                    leas      2,s        drop argument
                    bra       GenLoadFinal continue

GenLoadFreeChk      cmpx      #$0095    type $95?
                    beq       GenLoadFinal skip spill
                    cmpx      #$0094    type $94?
                    beq       GenLoadFinal skip spill
                    bra       GenLoadFree spill operand

GenLoadFinal        ldd       ,s        reload
                    pshs      d         push it
                    lbsr      EvalOperandTree process operand
GenLoadCleanup      leas      2,s        drop argument
GenLoadTail         pshs      u         push node
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldx       $04,s     load node
                    ldd       $06,x     read type
                    pshs      d         push argument
                    ldd       #$0079    operand value
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    ldx       ,s        load pointer
                    ldd       $06,x     read type
                    lbra      GenStoreType go set result type

GenStoreTree        pshs      u         save frame pointer
                    ldd       #$FFB0    frame size minus 80
                    lbsr      stkcheck  check stack space
                    leas      -4,s       reserve locals
                    ldx       $08,s     load node argument
                    ldd       $0C,x     read field $0C
                    std       $02,s     save local
                    ldx       $08,s     reload node argument
                    ldu       $0a,x     load child pointer
                    pshs      u         push child
                    lbsr      GenExpr   process operand
                    leas      2,s        drop argument
                    ldd       $0a,s     load $0C local
                    addd      #$FFB0    offset by minus 80
                    std       $0a,s     store back
                    ldd       ,u        read child type
                    cmpd      #$0007    compare to seven
                    bne       StoreEmit skip if not seven
                    ldx       $0a,s     load local
                    bra       StoreOpDispatch dispatch

StoreOp4E           ldd       #$004E    opcode $4E
                    bra       StoreOpSet set store opcode

StoreOp4D           ldd       #$004D    opcode $4D
                    bra       StoreOpSet set store opcode

StoreOp4C           ldd       #$004C    opcode $4C
StoreOpSet          std       $0a,s     set store opcode local
                    bra       StoreEmit continue

StoreOpDispatch     cmpx      #$0053    type $53?
                    beq       StoreOp4E opcode $4E
                    cmpx      #$0055    type $55?
                    beq       StoreOp4D opcode $4D
                    cmpx      #$0054    type $54?
                    beq       StoreOp4C opcode $4C
StoreEmit           ldd       $06,u     read child type
                    anda      #$7f      clear high bit
                    std       ,s        save local
                    pshs      d         push it
                    lbsr      IsFloatType classify type
                    std       ,s++      save result and pop
                    lbeq      StoreLoadEmit branch if not classified
                    ldx       $0a,s     load store opcode local
                    lbra      StoreDispatch2 dispatch

StoreConst          ldx       $02,s     load $0C local
                    ldd       $06,x     read type
                    cmpd      #$0036    type $36?
                    bne       StoreGeneric generic case
                    ldd       $0a,s     load store opcode
                    cmpd      #$0050    opcode $50?
                    bne       StoreConstNeg negate case
                    ldx       $02,s     load pointer
                    ldd       $08,x     read constant value
                    bra       StoreConstEmit go emit

StoreConstNeg       ldx       $02,s     load pointer
                    ldd       $08,x     read constant value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish two's complement
StoreConstEmit      pshs      d         push constant
                    ldd       #$0036    operand $36
                    pshs      d         push argument
                    ldd       $04,s     load store opcode
                    pshs      d         push argument
                    ldd       #$0074    opcode selector
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    bra       GenSetType go set result type

StoreGeneric        ldd       $02,s     load pointer
                    pshs      d         push it
                    lbsr      ForceReg70 process operand
                    leas      2,s        drop argument
                    ldd       $0a,s     load store opcode
                    cmpd      #$0051    opcode $51?
                    bne       StoreGenericEmit skip extra emit
                    ldd       #$0043    operand $43
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      2,s        drop argument
StoreGenericEmit    ldd       #$0070    operand value
                    pshs      d         push argument
                    ldd       $02,s     load pointer
                    pshs      d         push argument
                    ldd       #$0074    opcode selector
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop arguments
GenSetType          ldd       $06,u     read child type
GenStoreType        ldx       $08,s     load node
                    std       $06,x     store result type
                    clra                zero
                    clrb                zero
                    ldx       $08,s     reload node
                    std       $08,x     clear field $08
                    lbra      LeafEpilogue return

StoreLea            leax      $04,s     point at store opcode local
                    bra       StoreLeaAdj adjust and emit

StorePtrEmit        ldd       $06,u     read node type
                    pshs      d         push argument
                    ldd       #$007A    opcode selector
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop arguments
                    ldd       $02,s     load pointer
                    pshs      d         push it
                    lbsr      ForceReg70 process operand
                    leas      2,s        drop argument
                    ldd       $0a,s     load store opcode
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      2,s        drop argument
                    lbra      EmitAddrTemplate continue

StoreDispatch2      cmpx      #$0050    opcode $50?
                    lbeq      StoreConst constant case
                    cmpx      #$0051    opcode $51?
                    lbeq      StoreConst constant case
                    cmpx      #$0057    opcode $57?
                    beq       StoreLea  lea case
                    cmpx      #$0058    opcode $58?
                    lbeq      StoreLea  lea case
                    cmpx      #$0059    opcode $59?
                    lbeq      StoreLea  lea case
                    bra       StorePtrEmit pointer emit

StoreLeaAdj         leas      -$04,x    adjust store opcode pointer
StoreLoadEmit       pshs      u         push child
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldd       #$0070    operand value
                    pshs      d         push argument
                    ldd       #$0075    operand value
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    ldd       ,u        read child type
                    cmpd      #$0002    compare to two
                    bne       StoreLoadDone skip if not two
                    ldd       #$0085    operand $85
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      2,s        drop argument
StoreLoadDone       ldx       $0a,s     load store opcode local
                    lbra      MatchStoreOp continue

StoreLoadReg        ldd       $02,s     load pointer
                    pshs      d         push it
                    lbsr      IsSimpleAddr classify node
                    std       ,s++      save result and pop
                    beq       StoreLoadAlt branch if false
                    ldd       $02,s     load pointer
                    pshs      d         push it
                    lbsr      GenExpr   process operand
                    leas      2,s        drop argument
                    ldx       $0a,s     load store opcode local
                    bra       StoreLoadDispatch dispatch

StoreLoadNeg        ldd       $02,s     load pointer
                    pshs      d         push it
                    lbsr      ResolveNegFlag resolve negate flag
                    leas      2,s        drop argument
                    bra       StoreLoadEmit2 continue

StoreLoadDispatch   cmpx      #$0057    opcode $57?
                    beq       StoreLoadNeg resolve negate
                    cmpx      #$0058    opcode $58?
                    lbeq      StoreLoadNeg resolve negate
                    cmpx      #$0059    opcode $59?
                    lbeq      StoreLoadNeg resolve negate
StoreLoadEmit2      ldd       $02,s     load pointer
                    pshs      d         push argument
                    ldd       #$0077    opcode selector
                    pshs      d         push argument
                    ldd       #$0070    operand value
                    pshs      d         push argument
                    ldd       $10,s     load store opcode
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop arguments
                    lbra      EmitAddrTemplate continue

StoreLoadAlt        ldd       ,s        load pointer
                    cmpd      #$0094    type $94?
                    beq       StoreLoadPtr skip spill
                    ldd       ,s        reload
                    cmpd      #$0095    type $95?
                    beq       StoreLoadPtr skip spill
                    pshs      u         push child
                    lbsr      GenAddrOffset spill or free operand
                    leas      2,s        drop argument
StoreLoadPtr        ldd       #$0070    operand value
                    pshs      d         push argument
                    ldd       #$007A    opcode selector
                    pshs      d         push argument
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop arguments
                    ldd       $02,s     load pointer
                    pshs      d         push it
                    lbsr      ForceReg70 process operand
                    leas      2,s        drop argument
                    ldd       $0a,s     load store opcode
                    cmpd      #$0051    opcode $51?
                    bne       StoreLoadFixup skip if not $51
                    ldd       #$004F    new opcode $4F
                    std       $0a,s     set store opcode
StoreLoadFixup      ldd       #$006E    operand $6E
                    pshs      d         push argument
                    ldd       #$0070    operand value
                    pshs      d         push argument
                    ldd       $0e,s     load store opcode
                    pshs      d         push third template operand
                    lbsr      GenOperand emit code template
                    leas      6,s        drop pushed operands
                    bra       EmitAddrTemplate go rewrite node as address

MatchStoreOp        cmpx      #$0057    test operator code 0x57
                    lbeq      StoreLoadReg matched, handle as store op
                    cmpx      #$0058    test operator code 0x58
                    lbeq      StoreLoadReg matched, handle as store op
                    cmpx      #$0059    test operator code 0x59
                    lbeq      StoreLoadReg matched, handle as store op
                    cmpx      #$0050    test operator code 0x50
                    lbeq      StoreLoadReg matched, handle as store op
                    cmpx      #$0051    test operator code 0x51
                    lbeq      StoreLoadReg matched, handle as store op
                    lbra      StoreLoadAlt none matched, take default path

EmitAddrTemplate    pshs      u         push node pointer for emit
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       #$0070    template code p
                    pshs      d         push it
                    ldd       #$0079    template code y
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    ldd       #$0070    new operator 0x70
                    ldx       $08,s     reload node pointer
                    std       $06,x     set node operator field
                    lbra      LeafEpilogue return via common epilogue

GenAddrOffset       pshs      u         save node pointer
                    ldd       #$FFB4    frame size for stack check
                    lbsr      stkcheck  verify stack room
                    ldu       $04,s     load node pointer argument
                    ldd       $06,u     load node operator field
                    anda      #$7f      strip evaluated flag
                    cmpd      #$0034    is it a constant node
                    bne       GenOffsetPart no, handle other case
                    puls      pc,u      yes, nothing to do, return

GenOffsetPart       pshs      u         push node pointer argument
                    lbsr      ResolveNegFlag evaluate the subtree
                    leas      2,s        drop argument
                    ldd       $08,u     load node offset value
                    beq       GenIndexEmit zero offset, skip emit
                    ldd       $08,u     reload offset value
                    pshs      d         push offset operand
                    ldd       #$0036    template code
                    pshs      d         push it
                    ldd       #$0071    template code q
                    pshs      d         push it
                    ldd       #$0074    template code t
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
GenIndexEmit        ldd       #$0071    template code q
                    pshs      d         push it
                    ldd       #$007A    template code z
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      4,s        drop pushed operands
                    ldd       #$806E    new operator with evaluated flag
                    std       $06,u     set node operator field
                    puls      pc,u      return

GenLoadLeaf         pshs      u         save node pointer
                    ldd       #$FFB0    frame size for stack check
                    lbsr      stkcheck  verify stack room
                    ldu       $04,s     load node pointer argument
                    leas      -4,s       allocate local slots
                    ldd       $0a,u     load left child pointer
                    std       $02,s     save child pointer local
                    pshs      d         push child pointer
                    lbsr      GenLeafAddr generate leaf address
                    leas      2,s        drop argument
                    ldx       $02,s     reload child pointer
                    ldd       $06,x     load child operator field
                    std       ,s        save operator local
                    anda      #$80      isolate evaluated flag
                    clrb                clear low byte
                    std       -$02,s    save flag local
                    lbeq      HandleUnevaluated child not evaluated, branch
                    ldd       ,s        reload operator
                    anda      #$7f      strip evaluated flag
                    std       ,s        store operator back
                    tfr       d,x       move operator to x for dispatch
                    bra       DispatchEvalOp dispatch on evaluated operator

EmitConstLoad       ldx       $02,s     reload child pointer
                    ldd       $08,x     load child value
                    pshs      d         push value operand
                    ldd       $02,s     load operator local
                    pshs      d         push it
                    ldd       #$0071    template code q
                    pshs      d         push it
                    ldd       #$0075    template code u
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    bra       SetOp8093 continue after emit

ReportBadOp         leax      MsgIndirect1,pcr point to error message string
                    pshs      x         push string pointer
                    ldd       $04,s     push offending operator
                    pshs      d         push it
                    lbsr      BuildLabelText report compiler error
                    leas      4,s        drop arguments
                    bra       SetOp8093 continue after error

DispatchEvalOp      cmpx      #$0034    operator is a constant
                    beq       EmitConstLoad handle constant load
                    cmpx      #$0093    operator 0x93
                    lbeq      EmitConstLoad handle it
                    cmpx      #$0094    operator 0x94
                    lbeq      EmitConstLoad handle it
                    cmpx      #$0095    operator 0x95
                    lbeq      EmitConstLoad handle it
                    bra       ReportBadOp otherwise report bad operator

SetOp8093           ldd       #$8093    result operator 0x8093
                    std       ,s        store operator local
                    clra                zero high byte
                    clrb                zero low byte
                    std       $08,u     clear node value field
                    lbra      SetNodeOp finish node update

HandleUnevaluated   ldx       ,s        load operator for dispatch
                    lbra      DispatchUnevalOp dispatch unevaluated operator

SetOp95             ldd       #$0095    select operator 0x95
                    bra       StoreOpLocal store it

SetOp94             ldd       #$0094    select operator 0x94
                    bra       StoreOpLocal store it

SetOp93             ldd       #$0093    select operator 0x93
                    bra       StoreOpLocal store it

SetEvalFlag         ldd       ,s        load current operator
                    ora       #$80      set evaluated flag
StoreOpLocal        std       ,s        store operator local
                    leax      $04,s     point past local slots
                    bra       RestoreStack continue

SetConstOp          ldd       #$8034    constant operator with flag
                    std       ,s        store operator local
                    ldx       $02,s     reload child pointer
                    ldd       $14,x     load child field 0x14
                    std       $14,u     copy into node
                    bra       LoadChildValue continue

RestoreStack        leas      -$04,x    restore stack pointer
LoadChildValue      ldx       $02,s     reload child pointer
                    ldd       $08,x     load child value
                    bra       SetNodeValue store into node value

EmitRegLoad         ldd       $02,s     load child pointer operand
                    pshs      d         push operand
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       #$0071    template code q
                    pshs      d         push it
                    ldd       #$0075    template code u
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    ldd       #$0093    result operator 0x93
                    std       ,s        store operator local
                    clra                zero high byte
                    clrb                zero low byte
SetNodeValue        std       $08,u     set node value field
                    bra       SetNodeOp finish node update

ClearNodeValue      clra                zero high byte
                    clrb                zero low byte
                    std       $08,u     clear node value field
                    ldx       $02,s     reload child pointer
                    ldd       $08,x     load child value
                    std       $14,u     copy to node field 0x14
                    ldd       #$0034    select constant operator
                    bra       StoreResultOp store it

ReportBadOp2        leax      MsgIndirect2,pcr point to error message string
                    pshs      x         push string pointer
                    pshs      u         push node pointer
                    lbsr      BuildLabelText report compiler error
                    leas      4,s        drop arguments
                    ldd       #$0093    result operator 0x93
StoreResultOp       std       ,s        store operator local
                    bra       SetNodeOp finish node update

DispatchUnevalOp    cmpx      #$006F    operator 0x6f
                    lbeq      SetOp95   handle it
                    cmpx      #$0076    operator 0x76
                    lbeq      SetOp94   handle it
                    cmpx      #$0071    operator 0x71
                    lbeq      SetOp93   handle it
                    cmpx      #$0093    operator 0x93
                    lbeq      SetEvalFlag handle it
                    cmpx      #$0094    operator 0x94
                    lbeq      SetEvalFlag handle it
                    cmpx      #$0095    operator 0x95
                    lbeq      SetEvalFlag handle it
                    cmpx      #$0034    constant operator
                    lbeq      SetConstOp handle it
                    cmpx      #$0070    operator 0x70
                    lbeq      EmitRegLoad handle it
                    cmpx      #$0036    operator 0x36
                    beq       ClearNodeValue handle it
                    bra       ReportBadOp2 otherwise report bad operator

SetNodeOp           ldd       ,s        load final operator
                    std       $06,u     set node operator field
LeafEpilogue        leas      4,s        release local slots
                    puls      pc,u      return

GenBinaryNode       pshs      u         save node pointer
                    ldd       #$FFAC    frame size for stack check
                    lbsr      stkcheck  verify stack room
                    leas      -8,s       allocate local slots
                    ldx       $0C,s     load node pointer argument
                    ldu       $0a,x     load right child pointer
                    pshs      u         push child pointer
                    lbsr      GenExpr   evaluate the child
                    leas      2,s        drop argument
                    ldx       $0C,s     reload node pointer
                    ldd       $06,x     load node operator
                    std       $02,s     save operator local
                    ldd       $06,u     load child operator
                    std       ,s        save child operator local
                    pshs      d         push child operator
                    lbsr      IsFloatType classify operator
                    std       ,s++      save result, drop argument
                    beq       CheckDerefOp zero result, branch
                    ldx       $02,s     load node operator
                    bra       DispatchNodeOp dispatch on operator

EmitLeftLoad        ldd       $0e,s     load result operator local
                    cmpd      #$0070    is it 0x70
                    bne       CopyResultOp no, use result operator
                    pshs      u         push child pointer
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       $12,s     push operand
                    pshs      d         push it
                    ldd       #$0075    template code u
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    bra       LoadNodeValue continue

CopyResultOp        ldd       ,s        load result operator
                    std       $0e,s     save into local
                    bra       LoadNodeValue continue

DispatchNodeOp      cmpx      #$003E    operator 0x3e
                    beq       EmitLeftLoad handle it
                    cmpx      #$003F    operator 0x3f
                    lbeq      EmitLeftLoad handle it
                    bra       CopyResultOp default handling

CheckDerefOp        ldd       $0e,s     load result operator local
                    cmpd      #$0071    is it 0x71
                    bne       EmitLoadTemplate no, emit template
                    ldd       ,s        load result operator
                    anda      #$7f      strip evaluated flag
                    cmpd      #$0034    is it a constant
                    beq       EmitLoadTemplate yes, skip rewrite
                    ldd       #$0070    rewrite operator to 0x70
                    std       $0e,s     store local
EmitLoadTemplate    pshs      u         push child pointer
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       $12,s     push operand
                    pshs      d         push it
                    ldd       #$0075    template code u
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    ldd       $0e,s     load result operator local
                    std       ,s        save it
LoadNodeValue       ldx       $0C,s     load node pointer
                    ldd       $08,x     load node value field
                    std       $06,s     save value local
                    ldx       $02,s     load node operator
                    bra       DispatchNegOp dispatch on operator

NegateValue         ldd       $06,s     load value operand
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      complete 16-bit negate
                    std       $06,s     store negated value
CheckOp70a          ldd       ,s        load operator local
                    cmpd      #$0070    is it 0x70
                    bne       EmitStoreT no, use register form
                    ldd       $06,s     load value operand
                    pshs      d         push operand
                    ldd       #$0036    template code
                    pshs      d         push it
                    ldd       $04,s     push operand
                    pshs      d         push it
                    ldd       #$0050    immediate template 0x50
                    bra       EmitTemplateTail emit shared tail

EmitStoreT          ldd       $06,s     load value operand
                    pshs      d         push operand
                    ldd       #$0036    template code
                    pshs      d         push it
                    ldd       $04,s     push operand
                    pshs      d         push it
                    ldd       #$0074    register template t
EmitTemplateTail    pshs      d         push final template code
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    bra       EmitAddrY continue

DispatchNegOp       cmpx      #$003D    operator 0x3d
                    beq       NegateValue handle negate
                    cmpx      #$003F    operator 0x3f
                    lbeq      NegateValue handle negate
                    bra       CheckOp70a default handling

EmitAddrY           pshs      u         push child pointer
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       $04,s     push operand
                    pshs      d         push it
                    ldd       #$0079    template code y
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    ldx       $02,s     load node operator
                    bra       DispatchStoreOp dispatch on operator

ZeroValue           clra                zero high byte
                    clrb                zero low byte
                    bra       SetNodeValue2 store zero value

EmitConstStore      ldd       ,s        load operator local
                    cmpd      #$0070    is it 0x70
                    bne       NegateStoreValue no, negate value
                    ldd       $06,s     load value operand
                    pshs      d         push operand
                    ldd       #$0036    template code
                    pshs      d         push it
                    ldd       #$0070    template code p
                    pshs      d         push it
                    ldd       #$0051    immediate template 0x51
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    bra       FinishBinary continue

NegateStoreValue    ldd       $06,s     load value operand
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      complete 16-bit negate
SetNodeValue2       ldx       $0C,s     load node pointer
                    std       $08,x     set node value field
                    bra       FinishBinary continue

DispatchStoreOp     cmpx      #$003E    operator 0x3e
                    beq       EmitConstStore handle it
                    cmpx      #$003F    operator 0x3f
                    lbeq      EmitConstStore handle it
                    bra       ZeroValue default handling

FinishBinary        ldd       $0e,s     load result operator local
                    ldx       $0C,s     load node pointer
                    std       $06,x     set node operator field
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar0019 clear global flag
                    lbra      GenExit   return via epilogue

GenDerefNode        pshs      u         save node pointer
                    ldd       #$FFB4    frame size for stack check
                    lbsr      stkcheck  verify stack room
                    ldu       $04,s     load node pointer argument
                    pshs      u         push node pointer
                    bsr       GenLeafAddr generate leaf address
                    leas      2,s        drop argument
                    ldd       $06,u     load node operator
                    cmpd      #$0071    is it 0x71
                    bne       EmitDerefLoad no, emit load
                    ldd       $08,u     load node value
                    beq       SetOp71   zero value, skip emit
EmitDerefLoad       pshs      u         push node pointer
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       #$0071    template code q
                    pshs      d         push it
                    ldd       #$0075    template code u
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
SetOp71             ldd       #$0071    normalize operator to 0x71
                    std       $06,u     set node operator field
                    puls      pc,u      return

GenLeafAddr         pshs      u         save node pointer
                    ldd       #$FFAC    frame size for stack check
                    lbsr      stkcheck  verify stack room
                    leas      -8,s       allocate local slots
                    ldx       $0C,s     load node pointer argument
                    ldu       $0a,x     load left child pointer
                    ldx       $0C,s     reload node pointer
                    ldd       $0C,x     load node field 0x0c
                    std       $06,s     save local
                    ldd       #$0071    default operator 0x71
                    std       ,s        save operator local
                    ldx       $0C,s     reload node pointer
                    ldd       $06,x     load node operator
                    std       $02,s     save operator local
                    tfr       d,x       move operator to x for dispatch
                    lbra      NodeDispatch dispatch on operator

CaseLoadNode2       ldd       $0C,s     load node field operand
                    pshs      d         push argument
                    lbsr      GenLoadLeaf generate load leaf
                    lbra      DefaultDrop continue

CaseBinaryOp        ldd       #$0071    operator 0x71
                    pshs      d         push argument
                    ldd       $0e,s     load operand
                    pshs      d         push argument
                    lbsr      GenBinaryNode generate binary op
                    leas      4,s        drop arguments
                    lbra      GenExit   return via epilogue

EmitTemplate7F      pshs      u         push child pointer
                    ldd       #$0077    template code w
                    pshs      d         push it
                    ldd       #$0071    template code q
                    pshs      d         push it
                    ldd       #$007F    template code 0x7f
                    pshs      d         push it
                    lbsr      GenOperand emit code template
                    leas      8,s        drop pushed operands
                    clra                zero high byte
                    clrb                zero low byte
                    lbra      StoreNodeVal2 continue with zero result

CaseEvalSub         ldd       $0C,s     load node field operand
                    pshs      d         push argument
                    lbsr      ForceReg70 evaluate the subtree
                    lbra      DefaultDrop continue

CheckCallOp         ldd       $06,u     load node operator
                    cmpd      #$0041    is it 0x41
                    beq       GenOp50   handle it
                    ldx       $06,s     load node pointer
                    ldd       $12,x     load node field 0x12
                    lbne      Op50Default skip to done if type nonzero
GenOp50             ldd       $06,u     load node operand type
                    pshs      d         push operand type
                    lbsr      IsFloatType check if float or double type
                    std       ,s++      store result and pop
                    bne       Op50Float branch if float type
                    ldd       $06,u     reload operand type
                    cmpd      #$0041    compare against operator 0x41
                    bne       Op50Swap  branch if not that operator
Op50Float           ldx       $06,s     load node pointer
                    ldd       $06,x     load its operand type
                    cmpd      #$0036    compare against literal 0x36
                    bne       Op50Emit  branch if not literal
                    pshs      u         push node
                    lbsr      GenLeafAddr recurse to generate subtree
                    leas      2,s        drop argument
                    ldd       $06,u     load operand
                    std       ,s        save it locally
                    ldx       $06,s     reload node pointer
                    ldd       $08,x     load value field
                    lbra      StoreResult store result and finish

Op50Emit            ldd       $06,s     load node pointer
                    pshs      d         push it
                    lbsr      ForceReg70 call codegen helper
                    leas      2,s        drop argument
                    pshs      u         push node
                    lbsr      GenLeafAddr recurse to generate subtree
                    leas      2,s        drop argument
                    ldd       $02,s     load saved direction flag
                    cmpd      #$0051    compare against 0x51
                    bne       LoadOperand branch if not
                    ldd       #$0043    conversion opcode 0x43
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      2,s        drop argument
LoadOperand         ldd       $06,u     load operand
                    pshs      d         push it
                    ldd       #$0070    operand code 0x70
                    pshs      d         push it
                    ldd       #$007B    opcode 0x7B
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop three arguments
                    lbra      ZeroResult zero result and finish

Op50Swap            ldd       $02,s     load direction flag
                    cmpd      #$0050    compare against 0x50
                    bne       Op50Leaf  branch if not
                    ldd       $12,u     load node weight
                    ldx       $06,s     load other node
                    cmpd      $12,x     compare weights
                    bge       Op50Leaf  skip swap if greater equal
                    leas      -2,s       make room on stack
                    stu       ,s        save node pointer
                    ldu       $08,s     load other pointer
                    ldd       ,s        load saved node
                    std       $08,s     swap the operands
                    leas      2,s        drop temporary
Op50Leaf            ldd       $06,s     load node pointer
                    pshs      d         push it
                    lbsr      IsSimpleAddr check leaf condition
                    std       ,s++      store result and pop
                    bne       Op50Recurse branch if leaf
                    ldx       $06,s     load node pointer
                    ldd       $06,x     load its type
                    pshs      d         push it
                    lbsr      IsFloatType check float type
                    std       ,s++      store result and pop
                    bne       Op50Recurse branch if float
Op50Default         leax      $08,s     point at result slot
                    lbra      DefaultRestore go to default handler

Op50Recurse         pshs      u         push node
                    lbsr      GenLeafAddr recurse to generate subtree
                    leas      2,s        drop argument
                    ldd       $06,u     load operand type
                    anda      #$7f      mask off high bit
                    tfr       d,x       move subtype into x
                    lbra      SubDispatch dispatch on subtype

SubOp70             ldd       $02,s     load direction flag
                    cmpd      #$0050    compare against 0x50
                    bne       EmitConvert branch if not
                    ldx       $06,s     load node pointer
                    ldd       $06,x     load its type
                    cmpd      #$0036    compare against literal 0x36
                    beq       EmitConvert branch if literal
                    ldd       $06,s     load node pointer
                    pshs      d         push it
                    lbsr      ForceReg71 call codegen helper
                    leas      2,s        drop argument
                    clra                clear high byte
                    clrb                clear low byte
                    std       $08,u     zero value field
                    leax      $08,s     point at result slot
                    lbra      OffsetRestore continue offset path

EmitConvert         pshs      u         push node
                    ldd       #$0077    code 0x77
                    pshs      d         push it
                    ldd       #$0071    code 0x71
                    pshs      d         push it
                    ldd       #$0075    conversion opcode 0x75
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop four arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       $08,u     zero value field
                    bra       EmitCommon join common emit

SubOp76             ldd       $06,u     load operand
                    std       ,s        save it locally
                    bra       EmitCommon join common emit

XlateErr            leax      MsgXTranslate,pcr point at x-translate message
                    pshs      x         push message pointer
                    pshs      u         push node
                    lbsr      BuildLabelText report error
                    leas      4,s        drop arguments
                    bra       EmitCommon join common emit

SubDispatch         cmpx      #$0070    subtype 0x70
                    lbeq      SubOp70   handle it
                    cmpx      #$0034    subtype 0x34
                    beq       EmitConvert emit conversion
                    cmpx      #$0037    subtype 0x37
                    lbeq      EmitConvert emit conversion
                    cmpx      #$0093    subtype 0x93
                    lbeq      EmitConvert emit conversion
                    cmpx      #$0094    subtype 0x94
                    lbeq      EmitConvert emit conversion
                    cmpx      #$0095    subtype 0x95
                    lbeq      EmitConvert emit conversion
                    cmpx      #$0071    subtype 0x71
                    beq       EmitCommon join common emit
                    cmpx      #$0076    subtype 0x76
                    beq       SubOp76   load operand path
                    cmpx      #$006F    subtype 0x6F
                    lbeq      SubOp76   load operand path
                    bra       XlateErr  unknown subtype, report error

EmitCommon          ldx       $06,s     load node pointer
                    ldd       $06,x     load its type
                    cmpd      #$0036    compare against literal 0x36
                    bne       EmitLoadCvt branch if not literal
                    ldx       $06,s     reload node pointer
                    ldd       $08,x     load value field
                    bra       StoreResult store result and finish

EmitLoadCvt         ldd       $06,s     load node pointer
                    pshs      d         push it
                    lbsr      ForceReg70 call codegen helper
                    leas      2,s        drop argument
                    ldd       $02,s     load direction flag
                    cmpd      #$0051    compare against 0x51
                    bne       EmitOffset branch if not
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero
                    ldd       #$0043    conversion opcode 0x43
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop three arguments
                    bra       EmitOffset continue offset emit

OffsetRestore       leas      -$08,x    restore stack from x
EmitOffset          ldd       ,s        load saved value
                    pshs      d         push it
                    ldd       #$0070    code 0x70
                    pshs      d         push it
                    ldd       #$007B    opcode 0x7B
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop three arguments
                    ldd       #$0071    result type 0x71
                    std       ,s        store as type
ZeroResult          clra                clear high byte
                    clrb                clear low byte
StoreResult         std       $04,s     store result value
                    ldd       $02,s     load direction flag
                    cmpd      #$0050    compare against 0x50
                    bne       NegResult branch if not add
                    ldd       $04,s     load result
                    bra       AddBase   add base value

NegResult           ldd       $04,s     load result
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish two-byte negation
AddBase             addd      $08,u     add node base value
StoreNodeVal2       ldx       $0C,s     load target node
                    std       $08,x     store value field
                    bra       StoreNodeType store type then exit

DefaultRestore      leas      -$08,x    restore stack from x
GenDefault2         ldd       $0C,s     load target node
                    pshs      d         push it
                    lbsr      GenExpr   call default helper
DefaultDrop         leas      2,s        drop argument
                    bra       GenExit   exit generator

NodeDispatch        cmpx      #$0042    operator 0x42
                    lbeq      CaseLoadNode2 handle it
                    cmpx      #$0034    operator 0x34
                    beq       GenExit   nothing to do
                    cmpx      #$0076    operator 0x76
                    beq       GenExit   nothing to do
                    cmpx      #$006F    operator 0x6F
                    beq       GenExit   nothing to do
                    cmpx      #$0036    operator 0x36
                    beq       GenExit   nothing to do
                    cmpx      #$0037    operator 0x37
                    beq       GenExit   nothing to do
                    cmpx      #$003E    operator 0x3E
                    lbeq      CaseBinaryOp handle it
                    cmpx      #$003C    operator 0x3C
                    lbeq      CaseBinaryOp handle it
                    cmpx      #$003D    operator 0x3D
                    lbeq      CaseBinaryOp handle it
                    cmpx      #$003F    operator 0x3F
                    lbeq      CaseBinaryOp handle it
                    cmpx      #$0041    operator 0x41
                    lbeq      EmitTemplate7F handle it
                    cmpx      #$0085    operator 0x85
                    lbeq      CaseEvalSub handle it
                    cmpx      #$0051    operator 0x51
                    lbeq      CheckCallOp handle it
                    cmpx      #$0050    operator 0x50
                    lbeq      GenOp50   handle it
                    bra       GenDefault2 fall to default handler

StoreNodeType       ldd       ,s        load saved type
                    ldx       $0C,s     load target node
                    std       $06,x     store type field
GenExit             leas      8,s        drop locals
                    puls      pc,u      restore and return

IsFloatType         pshs      u         save u
                    ldd       #$FFC0    stack frame size
                    lbsr      stkcheck  check stack space
                    ldd       $04,s     load type argument
                    cmpd      #$006F    is it float
                    beq       RetTrue   yes return true
                    ldd       $04,s     reload type argument
                    cmpd      #$0076    is it double
                    bne       RetFalse  no return false
RetTrue             ldd       #$0001    result true
                    bra       IsFloatRet return

RetFalse            clra                result false high
                    clrb                result false low
IsFloatRet          puls      pc,u      restore and return

MsgTranslation      fcc       /translation/
                    fcb       C$NULL
MsgPctXCR           fcb       $25,$78
                    fcb       C$CR,C$NULL
MsgBinaryOp         fcc       /binary op./
                    fcb       C$NULL
MsgIndirect1        fcc       /indirection/
                    fcb       C$NULL
MsgIndirect2        fcc       /indirection/
                    fcb       C$NULL
MsgXTranslate       fcc       /x translate/
                    fcb       C$NULL
GenExpr2            pshs      u         save u
                    ldd       #$FFAE    stack frame size
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     load node argument
                    leas      -4,s       allocate locals
                    ldd       $06,u     load node operator
                    std       $02,s     save it locally
                    tfr       d,x       move operator into x
                    lbra      ExprDispatch dispatch on operator

GenOp47             ldd       #$0001    flag value one
                    pshs      d         push it
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       GlbVar000B load label counter
                    addd      #$0001    increment counter
                    std       GlbVar000B save new label number
                    std       $04,s     store label number
                    pshs      d         push it
                    ldd       $0a,u     load node child
                    pshs      d         push it
                    bsr       GenExpr2  recurse to generate subtree
                    leas      8,s        drop arguments
                    leax      $04,s     point at result
                    bra       Op47Merge merge

GenOp48             clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push flag zero
                    ldd       GlbVar000B load label counter
                    addd      #$0001    increment counter
                    std       GlbVar000B save new label number
                    std       $02,s     store label number
                    pshs      d         push it
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       $0a,u     load node child
                    pshs      d         push it
                    lbsr      GenExpr2  recurse to generate subtree
                    leas      8,s        drop arguments
                    bra       Op48Merge merge

Op47Merge           leas      -$04,x    restore stack from x
Op48Merge           ldd       ,s        load result
                    pshs      d         push it
                    lbsr      EmitLocalLabelLine emit label or jump
                    lbra      IndirectMerge continue

GenOp40             ldd       #$0001    constant one
                    subd      $0e,s     subtract argument to invert flag
                    pshs      d         push inverted flag
                    ldd       $0C,s     load argument
                    pshs      d         push it
                    ldd       $10,s     load argument
                    pshs      d         push it
                    ldd       $0a,u     load node child
                    lbra      EmitTernary recurse via ternary emit

GenCompare2         ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    pshs      u         push node
                    ldd       $0a,s     load argument
                    pshs      d         push it
                    lbsr      GenCompare3 generate comparison code
                    leas      10,s       drop arguments
                    lbra      GenCmpExit finish

GenLogic            ldd       $08,u     load node value
                    beq       GenLogicAlt branch if zero
                    ldd       $0e,s     load flag
                    bne       GenLogicAlt branch if set
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero
                    ldd       $0C,s     load argument
                    bra       EmitLogicOp emit operand

GenLogicAlt         ldd       $0e,s     load flag
                    lbeq      GenCmpExit nothing to emit
                    ldd       $08,u     load node value
                    lbne      GenCmpExit nothing to emit
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero
                    ldd       $0e,s     load flag
EmitLogicOp         pshs      d         push operand
                    ldd       #$007C    logical opcode 0x7C
                    lbra      EmitOperand emit operand

GenIndirect         ldd       $0a,u     load node child
                    pshs      d         push it
                    lbsr      GenExpr   call codegen helper
IndirectMerge       leas      2,s        drop argument
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       $0e,s     load argument
                    pshs      d         push it
                    ldd       $0C,u     load node child
EmitTernary         pshs      d         push it
                    lbsr      GenExpr2  recurse to generate subtree
                    leas      8,s        drop arguments
                    lbra      GenCmpExit finish

GenAddress          ldd       ,u        load node operator
                    cmpd      #$0008    compare against 0x08
                    bne       GenAddrAlt branch if not
                    pshs      u         push node
                    lbsr      EvalOperand generate reference
                    leas      2,s        drop argument
                    ldd       #$008B    code 0x8B
                    pshs      d         push it
                    ldd       #$0088    opcode 0x88
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop two arguments
                    bra       EmitLoadEA continue

GenAddrAlt          ldd       ,u        load node operator
                    cmpd      #$0005    compare against 0x05
                    beq       GenAddrSym branch if match
                    ldd       ,u        reload operator
                    cmpd      #$0006    compare against 0x06
                    bne       GenAddrExpr branch if not
GenAddrSym          ldd       $06,u     load node operand
                    cmpd      #$008C    compare against 0x8C
                    bne       EmitSymRef branch if not
                    ldu       $0a,u     follow child pointer
EmitSymRef          pshs      u         push node
                    lbsr      GenLongExpr generate reference
                    leas      2,s        drop argument
                    ldd       ,u        load operator
                    pshs      d         push it
                    ldd       #$008B    code 0x8B
                    pshs      d         push it
                    ldd       #$0087    opcode 0x87
                    pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop three arguments
                    bra       EmitLoadEA continue

GenAddrExpr         pshs      u         push node
                    lbsr      GenSubtree generate address expression
                    leas      2,s        drop argument
                    bra       EmitLoadEA continue

                    leas      -$04,x    dead code, restore stack
EmitLoadEA          ldd       $0e,s     load direction flag
                    beq       EmitLoadReg branch if zero
                    ldd       $0C,s     load argument
                    pshs      d         push it
                    ldd       #$005A    opcode 0x5A
                    bra       EmitLea   emit operand

EmitLoadReg         ldd       $0a,s     load argument
                    pshs      d         push it
                    ldd       #$005B    opcode 0x5B
EmitLea             pshs      d         push it
                    ldd       #$0082    base code 0x82
EmitOperand         pshs      d         push it
                    lbsr      GenOperand emit instruction
                    leas      6,s        drop three arguments
                    bra       GenCmpExit finish

ExprDispatch        cmpx      #$0047    operator 0x47
                    lbeq      GenOp47   handle it
                    cmpx      #$0048    operator 0x48
                    lbeq      GenOp48   handle it
                    cmpx      #$0040    operator 0x40
                    lbeq      GenOp40   handle it
                    cmpx      #$005A    operator 0x5A
                    lbeq      GenCompare2 handle compare
                    cmpx      #$005B    operator 0x5B
                    lbeq      GenCompare2 handle compare
                    cmpx      #$005C    operator 0x5C
                    lbeq      GenCompare2 handle compare
                    cmpx      #$005D    operator 0x5D
                    lbeq      GenCompare2 handle compare
                    cmpx      #$005E    check node type $5e
                    lbeq      GenCompare2 shared handler for these types
                    cmpx      #$005F    check node type $5f
                    lbeq      GenCompare2 same handler
                    cmpx      #$0060    check node type $60
                    lbeq      GenCompare2 same handler
                    cmpx      #$0061    check node type $61
                    lbeq      GenCompare2 same handler
                    cmpx      #$0062    check node type $62
                    lbeq      GenCompare2 same handler
                    cmpx      #$0063    check node type $63
                    lbeq      GenCompare2 same handler
                    cmpx      #$0036    check node type $36
                    lbeq      GenLogic  go to that handler
                    cmpx      #$004B    check node type $4b
                    lbeq      GenLogic  same handler
                    cmpx      #$004A    check node type $4a
                    lbeq      GenLogic  same handler
                    cmpx      #$0030    check node type $30
                    lbeq      GenIndirect go to that handler
                    lbra      GenAddress default handler

GenCmpExit          leas      4,s        drop locals
                    puls      pc,u      restore and return

GenCompare3         pshs      u         save frame pointer
                    ldd       #$FFAE    stack space needed
                    lbsr      stkcheck  check stack space
                    leas      -6,s       allocate locals
                    ldx       $0C,s     load node pointer arg
                    ldd       $0a,x     load field from node
                    std       ,s        save into local
                    ldx       $0C,s     reload node pointer
                    ldu       $0C,x     load child pointer
                    ldd       $12,s     load the swap flag arg
                    beq       CmpArgDefault branch if zero
                    ldd       $10,s     load alternate operand arg
                    bra       CmpArgStore join

CmpArgDefault       ldd       $0e,s     load default operand arg
CmpArgStore         std       $02,s     store selected operand local
                    ldd       $12,s     test swap flag again
                    beq       CmpNoSwap skip reversal if zero
                    ldd       $0a,s     load compare operator local
                    pshs      d         pass as arg
                    lbsr      SwapCompareOp reverse the compare operator
                    leas      2,s        drop arg
                    bra       CmpOpStored join

CmpNoSwap           ldd       $0a,s     load compare operator local
CmpOpStored         std       $0a,s     store operator back
                    ldd       [,s]      load node type via pointer
                    cmpd      #$0008    is it type 8
                    bne       CmpNotType8 no, other handling
                    ldd       $0C,s     load node pointer
                    pshs      d         pass as arg
                    lbsr      GenExpr3  handle type 8 node
                    bra       CmpEmitDone join to finish

CmpNotType8         ldd       [,s]      reload node type
                    cmpd      #$0005    is it type 5
                    beq       CmpType56 yes
                    ldd       [,s]      reload node type
                    cmpd      #$0006    is it type 6
                    bne       CmpGeneral neither, general path
CmpType56           ldd       $0C,s     load node pointer
                    pshs      d         pass as arg
                    lbsr      GenLongNode handle type 5 or 6 node
CmpEmitDone         leas      2,s        drop arg
                    leax      $06,s     point at locals block
                    lbra      CmpEmitRewind finish emission

CmpGeneral          ldd       ,s        load first local
                    pshs      d         pass as arg
                    lbsr      IsZeroConst classify the operand
                    std       ,s++      store result and test
                    bne       CmpSwapOperands branch if nonzero
                    ldd       ,s        load local
                    pshs      d         pass as arg
                    lbsr      NodeIsConst test node is constant
                    std       ,s++      store and test
                    beq       CmpCheckOp branch if not constant
                    pshs      u         pass child pointer
                    lbsr      NodeIsConst test child is constant
                    std       ,s++      store and test
                    beq       CmpSwapOperands branch if not
CmpCheckOp          ldd       $06,u     load child operator
                    pshs      d         pass as arg
                    lbsr      IsFloatType test operator property
                    std       ,s++      store and test
                    beq       CmpRightOp branch if false
                    ldx       ,s        load local pointer
                    ldd       $06,x     load its operator
                    pshs      d         pass as arg
                    lbsr      IsFloatType test operator property
                    std       ,s++      store and test
                    bne       CmpRightOp branch if true
CmpSwapOperands     ldd       ,s        load local
                    std       $04,s     save it
                    stu       ,s        store child pointer into local
                    ldu       $04,s     swap into u
                    ldd       $0a,s     load compare operator
                    pshs      d         pass as arg
                    lbsr      AdjustByType adjust operator by type
                    leas      2,s        drop arg
                    std       $0a,s     store adjusted operator
CmpRightOp          ldx       ,s        load node pointer
                    ldd       $06,x     load operator field
                    std       $04,s     save it
                    pshs      d         pass as arg
                    lbsr      IsFloatType test operator property
                    std       ,s++      store and test
                    lbeq      CmpLeftConst branch if false
                    pshs      u         pass child pointer
                    lbsr      GenExpr   generate operand code
                    leas      2,s        drop arg
                    ldx       $06,u     load child operator
                    bra       CmpDispatchOp dispatch on operator

CmpGenIncr          pshs      u         pass child pointer
                    lbsr      EvalOperandTree generate operand code
                    leas      2,s        drop arg
                    leax      $06,s     point at locals
                    bra       CmpRewind go emit

CmpGenPush          pshs      u         save child pointer
                    ldd       #$0077    operand descriptor
                    pshs      d         push arg
                    ldd       #$0070    register code
                    pshs      d         push arg
                    ldd       #$0075    mnemonic code
                    pshs      d         push arg
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop args
                    ldd       #$0070    register code
                    std       $06,u     set child result register
                    bra       CmpEmitNeg continue

CmpRewind           leas      -$06,x    rewind pointer
CmpEmitNeg          ldd       $06,u     load child result register
                    pshs      d         push arg
                    ldd       #$007A    mnemonic code
                    pshs      d         push arg
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop args
                    ldd       #$006E    register code
                    std       $06,u     set child result register
                    lbra      CmpEmitTest continue emission

CmpDispatchOp       cmpx      #$0041    operator type $41
                    beq       CmpGenIncr handle it
                    cmpx      #$0085    operator type $85
                    beq       CmpGenPush handle it
                    cmpx      #$0071    operator type $71
                    beq       CmpEmitNeg handle it
                    cmpx      #$0076    operator type $76
                    lbeq      CmpEmitNeg handle it
                    cmpx      #$006F    operator type $6f
                    lbeq      CmpEmitNeg handle it
                    cmpx      #$0070    operator type $70
                    lbeq      CmpEmitNeg handle it
                    lbra      CmpEmitTest default continue

CmpLeftConst        pshs      u         pass child pointer
                    lbsr      IsZeroConst classify the operand
                    std       ,s++      store and test
                    beq       CmpEvalLeft branch if zero
                    ldd       $0a,s     load operator value
                    cmpd      #$0060    compare threshold
                    bge       CmpEvalLeft branch if large
                    ldd       ,s        load node pointer
                    pshs      d         pass as arg
                    lbsr      GenSubtree generate subtree code
                    leas      2,s        drop arg
                    lbra      CmpEmitBranch finish emission

CmpEvalLeft         ldd       ,s        load node pointer
                    pshs      d         pass as arg
                    lbsr      EvalOperandTree generate operand code
                    leas      2,s        drop arg
                    ldx       ,s        load node pointer
                    ldd       $06,x     load operator field
                    std       $04,s     save it
                    pshs      u         pass child pointer
                    lbsr      IsSimpleAddr evaluate the child
                    std       ,s++      store and test
                    bne       CmpGenLeft branch if nonzero
                    ldd       $04,s     load saved operator
                    cmpd      #$0070    is it register $70
                    bne       CmpConvertLeft no, emit convert
                    pshs      u         pass child pointer
                    lbsr      NodeIsConst test node is constant
                    std       ,s++      store and test
                    beq       CmpConvertLeft branch if not constant
CmpGenLeft          pshs      u         pass child pointer
                    lbsr      GenExpr   generate operand code
                    leas      2,s        drop arg
                    bra       CmpEmitTest continue

CmpConvertLeft      ldd       $04,s     load operator
                    pshs      d         push arg
                    ldd       #$007A    mnemonic code
                    pshs      d         push arg
                    lbsr      GenOperand emit instruction
                    leas      4,s        drop args
                    ldd       #$006E    register code
                    ldx       ,s        load node pointer
                    std       $06,x     set result register
                    pshs      u         pass child pointer
                    lbsr      EvalOperandTree generate operand code
                    leas      2,s        drop arg
                    ldd       $06,u     load child result register
                    std       $04,s     save it
                    ldu       ,s        load node pointer into u
                    ldd       $0a,s     load compare operator
                    pshs      d         push arg
                    lbsr      AdjustByType adjust operator by type
                    leas      2,s        drop arg
                    std       $0a,s     store adjusted operator
CmpEmitTest         pshs      u         save pointer
                    ldd       #$0077    operand descriptor
                    pshs      d         push arg
                    ldd       $08,s     load result register
                    pshs      d         push arg
                    ldd       #$0081    mnemonic code
                    pshs      d         push arg
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop args
                    bra       CmpEmitBranch finish

CmpEmitRewind       leas      -$06,x    rewind pointer
CmpEmitBranch       ldd       $02,s     load target operand
                    pshs      d         push arg
                    ldd       $0C,s     load node pointer
                    pshs      d         push arg
                    ldd       #$0082    mnemonic code
                    pshs      d         push arg
                    lbsr      GenOperand emit the branch instruction
                    leas      6,s        drop args
                    leas      6,s        drop locals
                    puls      pc,u      restore and return

NodeIsConst         pshs      u         save frame pointer
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  check stack space
                    ldx       $04,s     load node pointer arg
                    ldx       $06,x     load operator field
                    bra       NodeConstDispatch dispatch on operator

ConstTrue           ldd       #$0001    return true
                    puls      pc,u      restore and return

NodeCheckDelegate   ldd       $04,s     load node pointer
                    pshs      d         pass as arg
                    lbsr      IsSmallSize test node property
                    leas      2,s        drop arg
                    puls      pc,u      return result

NodeConstDispatch   cmpx      #$0034    operator type $34
                    beq       ConstTrue constant, return true
                    cmpx      #$0036    operator type $36
                    lbeq      ConstTrue constant, return true
                    cmpx      #$0042    operator type $42
                    beq       NodeCheckDelegate delegate the check
                    lbra      NotZeroConst default return false

                    pshs      u         save frame pointer
                    ldd       #$FFC0    stack space needed
                    lbsr      stkcheck  check stack space
                    ldx       $04,s     load node pointer arg
                    ldd       $06,x     load operator field
                    cmpd      #$0034    is it type $34
                    lbne      NotZeroConst no, return false
                    ldx       $04,s     reload node pointer
                    ldd       [$08,x]   load referenced value
                    cmpd      #$000D    compare to $0d
                    lbne      NotZeroConst mismatch, return false
                    ldd       #$0001    return true
                    lbra      ZeroConstRet return with value

GenSubtree          pshs      u         save frame pointer
                    ldd       #$FFB0    stack space needed
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     load node pointer arg
                    leas      -4,s       allocate locals
                    clra                zero
                    clrb                zero
                    std       ,s        clear the flag local
                    ldx       $06,u     load operator field
                    bra       SubDispatch2 dispatch on operator

SubType57           ldd       $0C,u     load right child pointer
                    std       $02,s     save it
                    tfr       d,x       into x
                    ldd       $06,x     load child operator
                    cmpd      #$0036    is it type $36
                    bne       SubSetFlag no, mark flag
                    ldx       $02,s     reload child pointer
                    ldd       $08,x     load child value
                    cmpd      #$00FF    compare to $ff
                    lbls      SubFlagZero small enough, done
                    bra       SubSetFlag else mark flag

SubType78           ldx       $0a,u     load left child pointer
                    ldd       $06,x     load its operator
                    pshs      d         pass as arg
                    lbsr      IsFloatType test operator property
                    std       ,s++      store and test
                    lbeq      SubFlagZero done if false
                    ldd       $0C,u     load right child pointer
                    pshs      d         pass as arg
                    lbsr      NodeIsConst test child is constant
                    std       ,s++      store and test
                    lbne      SubFlagZero done if true
                    bra       SubSetFlag else mark flag

SubMarkTest         ldx       $0a,u     load left child pointer
                    ldd       $06,x     load its operator
                    pshs      d         pass as arg
                    lbsr      IsFloatType test operator property
                    std       ,s++      store and test
                    lbeq      SubFlagZero done if false
SubSetFlag          ldd       #$0001    set the flag true
                    std       ,s        store flag
                    lbra      SubFlagZero done

SubDispatch2        cmpx      #$0057    operator type $57
                    beq       SubType57 handle it
                    cmpx      #$0078    operator type $78
                    beq       SubType78 handle it
                    cmpx      #$003E    operator type $3e
                    beq       SubMarkTest handle it
                    cmpx      #$003F    operator type $3f
                    lbeq      SubMarkTest handle it
                    cmpx      #$003D    operator type $3d
                    lbeq      SubMarkTest handle it
                    cmpx      #$003C    operator type $3c
                    lbeq      SubMarkTest handle it
                    cmpx      #$00A0    operator type $a0
                    lbeq      SubMarkTest handle it
                    cmpx      #$00A1    operator type $a1
                    lbeq      SubMarkTest handle it
                    cmpx      #$00A7    operator type $a7
                    lbeq      SubMarkTest handle it
                    cmpx      #$00A8    operator type $a8
                    lbeq      SubMarkTest handle it
                    cmpx      #$00A9    operator type $a9
                    lbeq      SubMarkTest handle it
                    cmpx      #$0076    operator type $76
                    beq       SubSetFlag mark flag
                    cmpx      #$006F    operator type $6f
                    lbeq      SubSetFlag mark flag
                    cmpx      #$0058    operator type $58
                    lbeq      SubSetFlag mark flag
                    cmpx      #$0059    operator type $59
                    lbeq      SubSetFlag mark flag
                    cmpx      #$0044    operator type $44
                    lbeq      SubSetFlag mark flag
                    cmpx      #$0043    operator type $43
                    lbeq      SubSetFlag mark flag
                    cmpx      #$0065    operator type $65
                    lbeq      SubSetFlag mark flag
SubFlagZero         clra                zero result
                    clrb                zero result
                    std       GlbVar0019 save computed flag global
                    pshs      u         pass node pointer
                    lbsr      GenExpr   generate operand code
                    leas      2,s        drop arg
                    ldx       $06,u     load operator field
                    bra       SubEmitDispatch dispatch on operator

SubEmitCheck        ldd       ,s        load flag local
                    bne       SubEmitOp nonzero, emit
                    ldd       GlbVar0019 load saved flag
                    beq       SubGenDone both zero, skip
SubEmitOp           clra                zero
                    clrb                zero
                    pshs      d         push arg
                    ldd       #$0036    node type code
                    pshs      d         push arg
                    ldd       $06,u     load operator
                    pshs      d         push arg
                    ldd       #$0081    mnemonic code
                    bra       SubEmitArg go emit

SubFollowChild      ldu       $0a,u     follow to left child
SubEmitLoad         pshs      u         save pointer
                    ldd       #$0077    operand descriptor
                    pshs      d         push arg
                    ldd       #$0070    register code
                    pshs      d         push arg
                    ldd       #$0075    mnemonic code
SubEmitArg          pshs      d         push arg
                    lbsr      GenOperand emit instruction
                    leas      8,s        drop args
                    bra       SubGenDone done

SubEmitDispatch     cmpx      #$0071    operator type $71
                    beq       SubEmitCheck handle it
                    cmpx      #$0070    operator type $70
                    lbeq      SubEmitCheck handle it
                    cmpx      #$0076    operator type $76
                    lbeq      SubEmitCheck handle it
                    cmpx      #$006F    operator type $6f
                    lbeq      SubEmitCheck handle it
                    cmpx      #$0085    operator type $85
                    beq       SubFollowChild handle it
                    bra       SubEmitLoad default emit

SubGenDone          leas      4,s        drop locals
                    puls      pc,u      restore and return

SwapCompareOp       pshs      u         save frame pointer
                    ldd       #$FFC0    stack space needed
                    lbsr      stkcheck  check stack space
                    ldx       $04,s     load operator arg
                    bra       SwapDispatch dispatch on operator

SwapTo5B            ldd       #$005B    return swapped operator
                    puls      pc,u      return

SwapTo5A            ldd       #$005A    return swapped operator
                    puls      pc,u      return

ReflectOp           ldd       $04,s     load operator
                    cmpd      #$005F    compare threshold
                    ble       ReflectLow branch if low
                    ldd       #$00C3    high base value
                    bra       ReflectSub join

ReflectLow          ldd       #$00BB    low base value
ReflectSub          subd      $04,s     reflect the operator
                    puls      pc,u      return reflected operator

SwapDispatch        cmpx      #$005A    operator $5a
                    beq       SwapTo5B  swap to $5b
                    cmpx      #$005B    operator $5b
                    beq       SwapTo5A  swap to $5a
                    bra       ReflectOp else reflect

                    puls      pc,u      return (unreached)

AdjustByType        pshs      u         save frame pointer
                    ldd       #$FFC0    stack space needed
                    lbsr      stkcheck  check stack space
                    ldx       $04,s     load operator arg
                    bra       AdjDispatch dispatch on operator

AdjSame             ldd       $04,s     return operator unchanged
                    puls      pc,u      return

AdjPlus2            ldd       $04,s     load operator
                    addd      #$0002    add two
                    puls      pc,u      return operator plus two

AdjMinus2           ldd       $04,s     load operator
                    addd      #$FFFE    subtract two
                    puls      pc,u      return operator minus two

AdjDispatch         cmpx      #$005A    operator $5a
                    beq       AdjSame   return unchanged
                    cmpx      #$005B    operator $5b
                    lbeq      AdjSame   return unchanged
                    cmpx      #$005C    operator $5c
                    beq       AdjPlus2  branch if operator matched
                    cmpx      #$005D    compare operator with $005D
                    lbeq      AdjPlus2  matched, take that path
                    cmpx      #$0060    compare operator with $0060
                    lbeq      AdjPlus2  matched, take that path
                    cmpx      #$0061    compare operator with $0061
                    lbeq      AdjPlus2  matched, take that path
                    bra       AdjMinus2 none matched, other case

                    puls      pc,u      restore and return

IsZeroConst         pshs      u         save the frame pointer
                    ldd       #$FFC0    stack space needed
                    lbsr      stkcheck  verify stack headroom
                    ldu       $04,s     fetch the node pointer argument
                    ldd       $06,u     load the node operator code
                    cmpd      #$0036    is it a constant node
                    bne       NotZeroConst no, return false
                    ldd       $08,u     load the constant value
                    bne       NotZeroConst nonzero, return false
                    ldd       #$0001    result true
                    bra       ZeroConstRet return with result

NotZeroConst        clra                result false high byte
                    clrb                result false low byte
ZeroConstRet        puls      pc,u      restore and return

EvalOperand         pshs      u         save the frame pointer
                    ldd       #$FFBA    stack space needed
                    lbsr      stkcheck  verify stack headroom
                    ldd       $04,s     fetch the node pointer
                    pshs      d         pass node as argument
                    bsr       GenExpr3  generate code for the node
                    leas      2,s        drop the argument
                    ldd       $04,s     fetch the node pointer again
                    pshs      d         pass node as argument
                    lbsr      EmitLoad  finish emission for the node
                    leas      2,s        drop the argument
                    puls      pc,u      restore and return

GenExpr3            pshs      u         save the frame pointer
                    ldd       #$FFAE    stack space needed
                    lbsr      stkcheck  verify stack headroom
                    ldu       $04,s     fetch the node pointer
                    leas      -6,s       reserve local slots
                    ldd       $06,u     load the node operator code
                    std       $02,s     save operator in a local
                    tfr       d,x       operator into index for dispatch
                    lbra      GenExprDispatch dispatch on the operator

GenOp42             pshs      u         save the frame pointer
                    lbsr      GenLoadLeaf process the node
                    leas      2,s        drop the argument
                    pshs      u         save the frame pointer
                    lbsr      ResolveNegFlag process the node again
                    leas      2,s        drop the argument
                    ldx       $06,u     reload the node operator
                    bra       GenOp42Check check the result register type

GenOp42Emit         ldd       $08,u     load the left child
                    lbeq      GenExprDone2 no child, done
                    pshs      u         save the frame pointer
                    ldd       #$0077    push mnemonic code
                    pshs      d         as argument
                    ldd       #$007B    push operand code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      6,s        drop the arguments
                    lbra      SetRegResult set register result

GenOp42Check        cmpx      #$0093    result register type $0093
                    beq       GenOp42Emit matched, emit
                    cmpx      #$0094    result register type $0094
                    lbeq      GenOp42Emit matched, emit
                    cmpx      #$0095    result register type $0095
                    lbeq      GenOp42Emit matched, emit
                    lbra      GenExprDone2 otherwise done

GenNegOp            ldd       $0a,u     load the child pointer
                    pshs      d         pass as argument
                    lbsr      ForceReg70 generate the subexpression
                    leas      2,s        drop the argument
                    ldd       #$0086    result operator $0086
                    lbra      EmitFinalOp emit and finish

GenOp91             ldd       $0a,u     load the child pointer
                    pshs      d         pass as argument
                    lbsr      GenLongExpr process the child
                    leas      2,s        drop the argument
                    ldd       $0a,u     load the child pointer
                    pshs      d         push as argument
                    ldd       #$0091    push operator code $0091
                    pshs      d         as argument
                    ldd       #$0087    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      6,s        drop the arguments
                    lbra      EmitDoneLeaf finish and set leaf result

GenOp83             ldd       $0a,u     load the child pointer
                    pshs      d         pass as argument
                    lbsr      ForceReg70 generate the subexpression
                    leas      2,s        drop the argument
                    ldd       #$0083    push operator code $0083
                    pshs      d         as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    bra       SetLeafResult set leaf result

SetLeafFixup        leas      -$06,x    stack pointer fixup
SetLeafResult       ldd       #$0080    leaf result type $0080
                    std       $06,u     store into the node operator
                    lbra      GenExprDone2 done

GenLoadImm          ldd       $08,u     load the child value
                    pshs      d         push as argument
                    ldd       #$004A    push operator code $004A
                    pshs      d         as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      6,s        drop the arguments
                    ldd       #$0004    push size four
                    pshs      d         as argument
                    ldd       $08,u     push the child value
                    pshs      d         as argument
                    lbsr      InsertFreeBlock reserve a temporary
                    bra       CompareDone join the compare tail

GenOp64             leax      EvalOperand,pcr pass EvalOperand as callback
                    pshs      x         push the callback
                    pshs      u         push the frame pointer
                    lbsr      GenBoolBranchInd apply callback over the tree
                    bra       CompareDone join the compare tail

GenCompareOp        ldd       $0a,u     load the child pointer
                    pshs      d         pass as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    ldd       $02,s     load the result register
                    pshs      d         push as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
CompareDone         leas      4,s        drop the arguments
                    leax      $06,s     point past the locals
                    lbra      SetRegResultFixup set register result

GenLogicalOp        clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push zero operand
                    ldd       #$0080    push operand code $0080
                    pshs      d         as argument
                    ldd       #$0071    push mnemonic code
                    pshs      d         as argument
                    ldd       #$007F    push operand code $007F
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      8,s        drop the arguments
                    ldd       #$0071    push mnemonic code
                    pshs      d         as argument
                    ldd       #$007A    push operand code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldd       $0a,u     load the child pointer
                    pshs      d         pass as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    ldd       $02,s     load the result register
                    pshs      d         push as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldd       #$0089    push operand code
                    pshs      d         as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldd       $02,s     reload the operator
                    cmpd      #$003E    which comparison variant
                    bne       CompareSwap not $003E, use other
                    ldd       #$003F    result operator $003F
                    lbra      EmitFinalOp emit and finish

CompareSwap         ldd       #$003E    result operator $003E
                    lbra      EmitFinalOp emit and finish

GenOp65             pshs      u         save the frame pointer
                    lbsr      GenExprList process the node
                    leas      2,s        drop the argument
                    lbra      EmitDoneLeaf finish and set leaf result

GenAssignOp         ldx       $0a,u     left child pointer
                    ldd       $06,x     left child operator
                    cmpd      #$004A    is it a load node
                    bne       CheckRightLoad no, skip the swap
                    leas      -2,s       reserve a temporary
                    ldd       $0a,u     load left child
                    std       ,s        stash it
                    ldd       $0C,u     load right child
                    std       $0a,u     move into left slot
                    ldd       ,s        reload stashed left
                    std       $0C,u     move into right slot
                    leas      2,s        drop the temporary
CheckRightLoad      ldx       $0C,u     right child pointer
                    ldd       $06,x     right child operator
                    cmpd      #$004A    is it a load node
                    lbne      GenBinOp  no, fall to generic binop
                    ldx       $0C,u     right child pointer
                    ldd       $08,x     right child value
                    std       $04,s     save pointer local
                    ldd       [$04,s]   dereference it
                    bne       GenBinOp  nonzero, generic binop
                    ldx       $04,s     reload the pointer
                    ldd       $02,x     load the symbol field
                    pshs      d         push as argument
                    lbsr      LookupConstSlot look it up
                    leas      2,s        drop the argument
                    std       ,s        stash the result
                    beq       GenBinOp  none found, generic binop
                    ldd       #$0004    push size four
                    pshs      d         as argument
                    ldd       $06,s     push the lookup result
                    pshs      d         as argument
                    lbsr      InsertFreeBlock reserve storage
                    leas      4,s        drop the arguments
                    ldd       $0C,u     load right child
                    std       $04,s     save pointer local
                    ldd       ,s        reload stashed result
                    ldx       $04,s     reload the pointer
                    std       $08,x     store the value field
                    ldd       #$0036    constant operator $0036
                    ldx       $04,s     reload the pointer
                    std       $06,x     store the operator field
                    ldd       #$0001    mark value present
                    std       [$04,s]   through the pointer
                    ldd       $02,s     reload the operator
                    cmpd      #$0052    is it operator $0052
                    bne       AssignOp55 no, use $0055
                    ldd       #$0056    store mnemonic $0056
                    bra       AssignStoreType store the type

AssignOp55          ldd       #$0055    store mnemonic $0055
AssignStoreType     std       $02,s     save the store type
                    leax      $06,s     point past the locals
                    bra       GenOp56Fixup generate the store

GenBinOp            ldd       $0a,u     load left child
                    std       $04,s     save pointer local
                    ldx       $04,s     reload the pointer
                    ldd       $06,x     left child operator
                    cmpd      #$004A    is it a load node
                    bne       BinOpEvalLeft no, evaluate it
                    ldd       $04,s     reload the pointer
                    pshs      d         push as argument
                    lbsr      LoadLongConst handle the load node
                    leas      2,s        drop the argument
                    bra       BinOpEvalRight evaluate the right operand

BinOpEvalLeft       ldd       $04,s     reload the pointer
                    pshs      d         push as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    ldd       #$006E    push mnemonic code
                    pshs      d         as argument
                    ldd       #$0088    push operand code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
BinOpEvalRight      ldd       $0C,u     load right child
                    pshs      d         push as argument
                    lbsr      EvalOperand evaluate the operand
                    bra       BinOpEmitTail finish the binop emit

GenOp56Fixup        leas      -$06,x    stack pointer fixup
GenOp56             ldd       $0a,u     load left child
                    pshs      d         push as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    ldd       #$0071    push mnemonic code
                    pshs      d         as argument
                    ldd       #$007A    push operand code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldd       $0C,u     load right child
                    pshs      d         push as argument
                    lbsr      ForceReg70 generate the subexpression
BinOpEmitTail       leas      2,s        drop the argument
                    ldd       $02,s     load the store type
EmitFinalOp         pshs      d         push as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
EmitDoneLeaf        leax      $06,s     point past the locals
                    lbra      SetLeafFixup set leaf result

GenOp78             ldd       $0a,u     load left child
                    pshs      d         push as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    ldd       #$0071    push mnemonic code
                    pshs      d         as argument
                    ldd       #$007A    push operand code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldd       $0C,u     load right child
                    pshs      d         push as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    leax      $06,s     point past the locals
                    bra       DefaultFixup emit the default tail

GenDefaultOp        leas      -$06,x    stack pointer fixup
                    ldd       $0a,u     load left child
                    std       $04,s     save pointer local
                    pshs      d         push as argument
                    lbsr      EvalOperand evaluate the operand
                    leas      2,s        drop the argument
                    ldd       #$0071    push mnemonic code
                    pshs      d         as argument
                    ldd       #$007A    push operand code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    ldd       $02,s     reload the operator
                    addd      #$FFB0    adjust the operator code
                    std       $06,u     store into the node
                    ldd       #$0093    register result $0093
                    ldx       $04,s     reload the pointer
                    std       $06,x     store the operator field
                    pshs      u         save the frame pointer
                    lbsr      GenExpr3  recurse to generate code
                    leas      2,s        drop the argument
                    bra       EmitDefaultTail emit the default tail

DefaultFixup        leas      -$06,x    stack pointer fixup
EmitDefaultTail     ldd       #$0089    push operand code
                    pshs      d         as argument
                    ldd       #$0088    push mnemonic code
                    pshs      d         as argument
                    lbsr      GenOperand emit the instruction
                    leas      4,s        drop the arguments
                    bra       SetRegResult set register result

SetRegResultFixup   leas      -$06,x    stack pointer fixup
SetRegResult        ldd       #$0093    register result type $0093
                    std       $06,u     store into the node operator
                    clra                clear value high byte
                    clrb                clear value low byte
                    std       $08,u     store the value field
                    lbra      GenExprDone2 done

GenOpFallback       ldd       $02,s     reload the operator
                    cmpd      #$00A0    compare against $00A0
                    blt       GenExprErr below range, error
                    leax      $06,s     point past the locals
                    lbra      GenDefaultOp generic operator emit

GenExprErr          leax      MsgLongs,pcr point at the error message
                    pshs      x         push the message
                    pshs      u         push the frame pointer
                    lbsr      BuildLabelText report the error
                    leas      4,s        drop the arguments
                    lbra      GenExprDone2 done

GenExprDispatch     cmpx      #$0080    already-generated result $0080
                    lbeq      GenExprDone2 done
                    cmpx      #$0093    register result $0093
                    lbeq      GenExprDone2 done
                    cmpx      #$0094    register result $0094
                    lbeq      GenExprDone2 done
                    cmpx      #$0095    register result $0095
                    lbeq      GenExprDone2 done
                    cmpx      #$0034    operator $0034
                    lbeq      GenExprDone2 done
                    cmpx      #$0042    operator $0042
                    lbeq      GenOp42   handle it
                    cmpx      #$0086    operator $0086
                    lbeq      GenNegOp  handle it
                    cmpx      #$0091    operator $0091
                    lbeq      GenOp91   handle it
                    cmpx      #$0083    operator $0083
                    lbeq      GenOp83   handle it
                    cmpx      #$004A    load operator $004A
                    lbeq      GenLoadImm handle it
                    cmpx      #$0064    operator $0064
                    lbeq      GenOp64   handle it
                    cmpx      #$003C    comparison operator $003C
                    lbeq      GenCompareOp handle it
                    cmpx      #$003D    comparison operator $003D
                    lbeq      GenCompareOp handle it
                    cmpx      #$0044    comparison operator $0044
                    lbeq      GenCompareOp handle it
                    cmpx      #$0043    comparison operator $0043
                    lbeq      GenCompareOp handle it
                    cmpx      #$003E    logical operator $003E
                    lbeq      GenLogicalOp handle it
                    cmpx      #$003F    logical operator $003F
                    lbeq      GenLogicalOp handle it
                    cmpx      #$0065    operator $0065
                    lbeq      GenOp65   handle it
                    cmpx      #$0052    assignment operator $0052
                    lbeq      GenAssignOp handle it
                    cmpx      #$0053    binary operator $0053
                    lbeq      GenBinOp  handle it
                    cmpx      #$005A    binary operator $005A
                    lbeq      GenBinOp  handle it
                    cmpx      #$005B    binary operator $005B
                    lbeq      GenBinOp  handle it
                    cmpx      #$005E    binary operator $005E
                    lbeq      GenBinOp  handle it
                    cmpx      #$005C    binary operator $005C
                    lbeq      GenBinOp  handle it
                    cmpx      #$005F    binary operator $005F
                    lbeq      GenBinOp  handle it
                    cmpx      #$005D    binary operator $005D
                    lbeq      GenBinOp  handle it
                    cmpx      #$0050    binary operator $0050
                    lbeq      GenBinOp  handle it
                    cmpx      #$0051    binary operator $0051
                    lbeq      GenBinOp  handle it
                    cmpx      #$0054    binary operator $0054
                    lbeq      GenBinOp  handle it
                    cmpx      #$0057    binary operator $0057
                    lbeq      GenBinOp  handle it
                    cmpx      #$0058    binary operator $0058
                    lbeq      GenBinOp  handle it
                    cmpx      #$0059    binary operator $0059
                    lbeq      GenBinOp  handle it
                    cmpx      #$0056    operator $0056
                    lbeq      GenOp56   handle it
                    cmpx      #$0055    operator $0055
                    lbeq      GenOp56   handle it
                    cmpx      #$0078    operator $0078
                    lbeq      GenOp78   handle it
                    lbra      GenOpFallback otherwise fall back

GenExprDone2        leas      6,s        deallocate the locals
                    puls      pc,u      restore and return

EmitLoad            pshs      u         save the frame pointer
                    ldd       #$FFB4    stack space needed
                    lbsr      stkcheck  verify stack headroom
                    ldx       $04,s     fetch the node pointer
                    ldx       $06,x     load the node operator
                    bra       EmitTypeConv continue emission

EmitConv34          ldd       $04,s     load node argument
                    pshs      d         push as emit operand
                    ldd       #$0077    template selector code
                    pshs      d         push template arg
                    ldd       #$0071    operand code
                    pshs      d         push operand
                    ldd       #$007F    format code
                    pshs      d         push format
                    lbsr      GenOperand emit instruction line
                    leas      8,s        drop four emit args
                    bra       ConvDone  conversion done, exit

EmitConv94          ldd       $04,s     load node argument
                    pshs      d         push as emit operand
                    ldd       #$0077    operand code
                    pshs      d         push operand
                    ldd       #$007B    format code
                    pshs      d         push format
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three emit args
                    bra       ConvDone  conversion done, exit

EmitTypeConv        cmpx      #$0034    match node type $0034
                    beq       EmitConv34 emit that conversion
                    cmpx      #$0094    match node type $0094
                    beq       EmitConv94 emit that conversion
                    cmpx      #$0095    match node type $0095
                    lbeq      EmitConv94 emit that conversion
ConvDone            puls      pc,u      return to caller

LoadLongConst       pshs      u         save frame pointer
                    ldd       #$FFB2    stack headroom needed
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     node pointer argument
                    leas      -2,s       reserve local slot
                    ldd       $08,u     long value pointer field
                    std       ,s        save pointer local
                    ldx       ,s        pointer to value bytes
                    lda       ,x        first constant byte
                    ora       $01,x     or in second byte
                    ora       $02,x     or in third byte
                    ora       $03,x     test all four bytes
                    beq       ZeroLongPath zero constant path
                    ldx       ,s        reload value pointer
                    ldd       $02,x     high word of constant
                    pshs      d         push emit operand
                    ldd       #$0036    template code
                    pshs      d         push
                    ldd       #$0070    operand code
                    pshs      d         push
                    ldd       #$0075    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      8,s        drop four args
                    ldd       #$0070    operand code
                    pshs      d         push
                    ldd       #$007A    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       [,s]      load low word via pointer
                    pshs      d         push emit operand
                    ldd       #$0036    template code
                    pshs      d         push
                    ldd       #$0070    operand code
                    pshs      d         push
                    ldd       #$0075    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      8,s        drop four args
                    bra       EmitLongLoad join common tail

ZeroLongPath        clra                zero high word
                    clrb                clear low byte
                    pshs      d         push emit operand
                    ldd       #$0036    template code
                    pshs      d         push
                    ldd       #$0070    operand code
                    pshs      d         push
                    ldd       #$0075    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      8,s        drop four args
                    ldd       #$0070    operand code
                    pshs      d         push
                    ldd       #$007A    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
EmitLongLoad        ldd       #$0070    operand code
                    pshs      d         push
                    ldd       #$007A    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       #$0004    length four
                    pshs      d         push length
                    ldd       $02,s     value pointer local
                    pshs      d         push pointer
                    lbsr      InsertFreeBlock emit long constant data
                    leas      4,s        drop two args
                    clra                clear D
                    clrb                clear low byte
                    std       $08,u     clear value pointer field
                    leas      2,s        release local slot
                    puls      pc,u      return

MsgLongs            fcc       /longs/
                    fcb       C$NULL
GenLongExpr         pshs      u         save frame pointer
                    ldd       #$FFBA    stack headroom needed
                    lbsr      stkcheck  check stack space
                    ldd       $04,s     node argument
                    pshs      d         push argument
                    bsr       GenLongNode generate long node
                    leas      2,s        drop argument
                    ldd       $04,s     node argument again
                    pshs      d         push argument
                    lbsr      EmitLoad  post-process result
                    leas      2,s        drop argument
                    puls      pc,u      return

GenLongNode         pshs      u         save frame pointer
                    ldd       #$FFAE    stack headroom needed
                    lbsr      stkcheck  check stack space
                    ldu       $04,s     node pointer argument
                    leas      -8,s       reserve eight-byte locals
                    ldd       ,u        node type field
                    std       $02,s     save node type local
                    ldd       $06,u     operator code field
                    std       $06,s     save operator local
                    tfr       d,x       operator code to X
                    lbra      DispatchLongOp dispatch on operator

GenSimpleLong       pshs      u         save frame pointer
                    lbsr      GenExpr3  handle simple node
                    leas      2,s        drop argument
                    lbra      GenLongDone done

GenLongDeref        ldd       $0a,u     left child pointer
                    pshs      d         push child
                    lbsr      ForceReg70 evaluate child expression
                    leas      2,s        drop child
                    bra       EmitResult87 join result emit

SetResultRegA       leas      -$08,x    reset stack to saved point
EmitResult87        ldd       $06,s     result operand
                    pshs      d         push operand
                    ldd       #$0087    format code
                    pshs      d         push format
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    bra       SetResultD set result register

SetResDReset        leas      -$08,x    reset stack to saved point
SetResultD          ldd       #$0080    result register code
                    std       $06,u     store as node result
                    lbra      GenLongDone done

GenLongEval         ldd       $0a,u     child pointer
                    pshs      d         push child
                    lbsr      EvalOperand evaluate child expression
                    bra       GenLongChildDone finish child

GenLongChild        ldd       $0a,u     child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
GenLongChildDone    leas      2,s        drop child
                    leax      $08,s     save teardown point in X
                    bra       SetResultRegA emit result

GenLongIndex        ldd       $08,u     value field
                    pshs      d         push operand
                    ldd       #$004B    template code
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
                    ldd       #$0093    result register code
                    std       $06,u     store node result
                    ldd       #$0008    length eight
                    pshs      d         push length
                    ldd       $08,u     value pointer
                    pshs      d         push pointer
                    lbsr      InsertFreeBlock emit long constant data
                    leas      4,s        drop two args
                    lbra      ClearAndDone finish and clear

GenLongApply        leax      GenLongExpr,pcr point to long-expr handler
                    pshs      x         push function pointer
                    pshs      u         push node pointer
                    lbsr      GenBoolBranchInd apply generic handler
                    leas      4,s        drop two args
                    bra       UnaryDone finish

GenLongUnary        ldd       $0a,u     child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    ldd       $02,s     result operand
                    pshs      d         push
                    ldd       $08,s     prior operand
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
UnaryDone           leax      $08,s     save teardown point in X
                    lbra      SetResultReset finish result

GenLongCompare      ldd       #$0080    register code
                    pshs      d         push
                    ldd       #$0071    operand code
                    pshs      d         push
                    ldd       #$007F    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
                    ldd       #$0071    operand code
                    pshs      d         push
                    ldd       #$007A    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       $0a,u     child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    ldd       $02,s     result operand
                    pshs      d         push
                    ldd       $08,s     prior operand
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
                    ldd       $02,s     result operand
                    pshs      d         push
                    ldd       #$0089    operand code
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
                    ldd       $02,s     result operand
                    pshs      d         push
                    ldd       $08,s     operator code
                    cmpd      #$003E    is it less-than compare
                    bne       CmpNormal no, keep sense
                    ldd       #$003F    swap to opposite compare
                    bra       EmitCmpOp emit chosen compare

CmpNormal           ldd       #$003E    keep original compare
EmitCmpOp           pshs      d         push compare op
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
                    bra       BinaryDone comparison done

GenLongSpecial      pshs      u         push node pointer
                    lbsr      GenExprList handle special node
                    leas      2,s        drop argument
                    bra       BinaryDone comparison done

GenLongBinary       ldd       $0a,u     left child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    ldd       #$006E    operand code
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       $0C,u     right child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    ldd       $06,s     result operand
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
BinaryDone          leax      $08,s     save teardown point in X
                    lbra      SetResDReset set result register

GenLongShift        ldd       $0a,u     left child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    ldd       #$0071    operand code
                    pshs      d         push
                    ldd       #$007A    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       $0C,u     right child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    leax      $08,s     save teardown point in X
                    lbra      ShiftDone finish shift

GenLongAssign       leas      -$08,x    reset stack to saved point
                    ldd       $0a,u     left child pointer
                    std       $04,s     save child local
                    ldd       $02,s     node type field
                    cmpd      #$0005    is indirect type five
                    bne       AssignPlain no, plain assign
                    ldx       $04,s     child pointer
                    ldd       $0a,x     grandchild pointer
                    pshs      d         push
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop
                    ldd       #$0071    operand code
                    pshs      d         push
                    ldd       #$007A    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       #$008C    operand code
                    pshs      d         push
                    ldd       #$0087    format code
                    bra       EmitAssign emit deferred store

AssignPlain         ldd       $04,s     child pointer
                    pshs      d         push child
                    lbsr      GenLongExpr generate long expression
                    leas      2,s        drop child
                    ldd       #$0071    operand code
                    pshs      d         push
                    ldd       #$007A    format code
EmitAssign          pshs      d         push format
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    ldd       $06,s     result operand
                    addd      #$FFB0    add frame bias
                    std       $06,u     store result operand
                    ldd       #$0093    result register code
                    ldx       $04,s     child pointer
                    std       $06,x     set child result
                    pshs      u         push node pointer
                    lbsr      GenLongNode recurse generate node
                    leas      2,s        drop argument
                    ldd       $02,s     node type field
                    cmpd      #$0005    is indirect type five
                    bne       EmitStore89 no, skip extra store
                    ldd       #$008D    operand code
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      4,s        drop two args
                    bra       EmitStore89 continue

ShiftDone           leas      -$08,x    reset stack to saved point
EmitStore89         ldd       $02,s     result operand
                    pshs      d         push
                    ldd       #$0089    operand code
                    pshs      d         push
                    ldd       #$0087    format code
                    pshs      d         push
                    lbsr      GenOperand emit instruction line
                    leas      6,s        drop three args
                    bra       SetResult93 finish result

SetResultReset      leas      -$08,x    reset stack to saved point
SetResult93         ldd       #$0093    result register code
                    std       $06,u     store node result
ClearAndDone        clra                clear D
                    clrb                clear low byte
                    std       $08,u     clear value field
                    lbra      GenLongDone done

GenLongStore        ldd       $06,s     operand code
                    cmpd      #$00A0    below limit
                    blt       FloatFallback yes, handle assignment
                    leax      $08,s     save teardown point in X
                    lbra      GenLongAssign generate assignment

FloatFallback       leax      MsgFloats,pcr point to floats message
                    pshs      x         push message pointer
                    pshs      u         push node pointer
                    lbsr      BuildLabelText report unsupported error
                    leas      4,s        drop two args
                    lbra      GenLongDone done

DispatchLongOp      cmpx      #$0080    match operator $0080
                    lbeq      GenLongDone nothing to emit
                    cmpx      #$0093    match $0093
                    lbeq      GenLongDone nothing to emit
                    cmpx      #$0094    match $0094
                    lbeq      GenLongDone nothing to emit
                    cmpx      #$0095    match $0095
                    lbeq      GenLongDone nothing to emit
                    cmpx      #$0034    match $0034
                    lbeq      GenLongDone nothing to emit
                    cmpx      #$0042    match $0042
                    lbeq      GenSimpleLong simple node case
                    cmpx      #$0092    match $0092
                    lbeq      GenLongDeref deref case
                    cmpx      #$008E    match $008E
                    lbeq      GenLongDeref deref case
                    cmpx      #$0090    match $0090
                    lbeq      GenLongEval evaluate case
                    cmpx      #$008D    match $008D
                    lbeq      GenLongChild child case
                    cmpx      #$008C    match $008C
                    lbeq      GenLongChild child case
                    cmpx      #$004B    match $004B
                    lbeq      GenLongIndex index case
                    cmpx      #$0064    match $0064
                    lbeq      GenLongApply apply case
                    cmpx      #$003C    match $003C
                    lbeq      GenLongUnary unary case
                    cmpx      #$003D    match $003D
                    lbeq      GenLongUnary unary case
                    cmpx      #$0043    match $0043
                    lbeq      GenLongUnary unary case
                    cmpx      #$003E    match $003E
                    lbeq      GenLongCompare compare case
                    cmpx      #$003F    match $003F
                    lbeq      GenLongCompare compare case
                    cmpx      #$0065    match $0065
                    lbeq      GenLongSpecial special case
                    cmpx      #$005A    match $005A
                    lbeq      GenLongBinary binary case
                    cmpx      #$005B    match $005B
                    lbeq      GenLongBinary binary case
                    cmpx      #$005E    match $005E
                    lbeq      GenLongBinary binary case
                    cmpx      #$005C    match $005C
                    lbeq      GenLongBinary binary case
                    cmpx      #$005F    match $005F
                    lbeq      GenLongBinary binary case
                    cmpx      #$005D    match $005D
                    lbeq      GenLongBinary binary case
                    cmpx      #$0050    match $0050
                    lbeq      GenLongBinary binary case
                    cmpx      #$0051    match $0051
                    lbeq      GenLongBinary binary case
                    cmpx      #$0052    match $0052
                    lbeq      GenLongBinary binary case
                    cmpx      #$0053    match $0053
                    lbeq      GenLongBinary binary case
                    cmpx      #$0078    match $0078
                    lbeq      GenLongShift shift case
                    lbra      GenLongStore default store case

GenLongDone         leas      8,s        begin epilogue teardown
                    puls      pc,u      restore and return

MsgFloats           fcc       /floats/
                    fcb       C$NULL
Printf              pshs      u         save u register
                    leax      Stdout,y  point at stdout file structure
                    stx       GlbVar001B set output pointer
                    ldd       #$0001    select file output mode
                    std       GlbVar0021 store output mode
                    leax      $06,s     address of variadic arguments
                    pshs      x         push argument pointer
                    ldd       $06,s     reload format string pointer
                    bra       PrintfTail join common printf tail

fprintf             pshs      u         save u register
                    ldd       $04,s     get file pointer argument
                    std       GlbVar001B set output target
                    ldd       #$0001    select file output mode
                    std       GlbVar0021 store output mode
                    leax      $08,s     address of variadic arguments
                    pshs      x         push argument pointer
                    ldd       $08,s     get format string pointer
PrintfTail          pshs      d         push format string pointer
                    bsr       doprnt    run the formatter
                    leas      4,s        drop the pushed arguments
                    puls      pc,u      restore and return

                    pshs      u         save u register
                    ldd       $04,s     get buffer pointer argument
                    std       GlbVar001B set output target
                    ldd       #$0002    select string output mode
                    std       GlbVar0021 store output mode
                    leax      $08,s     address of variadic arguments
                    pshs      x         push argument pointer
                    ldd       $08,s     get format string pointer
                    pshs      d         push format string pointer
                    bsr       doprnt    run the formatter
                    leas      4,s        drop the pushed arguments
                    clra                zero high byte
                    clrb                zero terminator
                    stb       [GlbVar001B,y]   null-terminate the buffer via output pointer global
                    puls      pc,u      restore and return

doprnt              pshs      u         save u register
                    ldu       $04,s     load variadic argument pointer
                    leas      -11,s      reserve local frame
                    bra       FmtLoop   enter format loop

PrntLiteral         ldb       $08,s     get current format char
                    lbeq      DoprntDone end of string then finish
                    ldb       $08,s     reload the char
                    sex                 sign-extend to d
                    pshs      d         push the character
                    lbsr      EmitByte  output the character
                    leas      2,s        drop pushed char
FmtLoop             ldb       ,u+       fetch next format char
                    stb       $08,s     save current char
                    cmpb      #$25      is it a percent
                    bne       PrntLiteral no then emit literally
                    ldb       ,u+       fetch char after percent
                    stb       $08,s     save it
                    clra                zero high byte
                    clrb                zero low byte
                    std       $02,s     clear precision
                    std       $06,s     clear field width
                    ldb       $08,s     get flag character
                    cmpb      #$2d      is it minus
                    bne       NoLeftFlag no then clear left flag
                    ldd       #$0001    flag value one
                    std       GlbVar001D mark left-justify
                    ldb       ,u+       consume next char
                    stb       $08,s     save it
                    bra       CheckZeroPad continue to pad check

NoLeftFlag          clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar001D clear left-justify flag
CheckZeroPad        ldb       $08,s     get current char
                    cmpb      #$30      is it a zero
                    bne       UseSpacePad no then use space pad
                    ldd       #$0030    zero pad character
                    bra       SetPadChar store pad character

UseSpacePad         ldd       #$0020    space pad character
SetPadChar          std       GlbVar001F set the pad character
                    bra       WidthScanLoop enter width scan

WidthDigit          ldd       $06,s     current width
                    pshs      d         save it
                    ldd       #$000A    times ten
                    lbsr      MulEntry  multiply width by ten
                    pshs      d         save product
                    ldb       $0a,s     get the digit char
                    sex                 sign-extend
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add width times ten
                    std       $06,s     store new width
                    ldb       ,u+       fetch next char
                    stb       $08,s     save it
WidthScanLoop       ldb       $08,s     get current char
                    sex                 sign-extend
                    leax      CtypeTab,y point at ctype table
                    leax      d,x       index by character
                    ldb       ,x        load class bits
                    clra                clear high byte
                    andb      #$08      test digit bit
                    bne       WidthDigit a digit then accumulate width
                    ldb       $08,s     get current char
                    cmpb      #$2e      is it a dot
                    bne       NoPrecision no then no precision
                    ldd       #$0001    precision present
                    std       $04,s     set precision flag
                    bra       PrecScanLoop scan precision digits

PrecDigit           ldd       $02,s     current precision
                    pshs      d         save it
                    ldd       #$000A    times ten
                    lbsr      MulEntry  multiply precision by ten
                    pshs      d         save product
                    ldb       $0a,s     get digit char
                    sex                 sign-extend
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add precision times ten
                    std       $02,s     store new precision
PrecScanLoop        ldb       ,u+       fetch next char
                    stb       $08,s     save it
                    ldb       $08,s     reload char
                    sex                 sign-extend
                    leax      CtypeTab,y point at ctype table
                    leax      d,x       index by character
                    ldb       ,x        load class bits
                    clra                clear high byte
                    andb      #$08      test digit bit
                    bne       PrecDigit a digit then accumulate precision
                    bra       DispatchConv done scanning precision

NoPrecision         clra                zero high byte
                    clrb                zero low byte
                    std       $04,s     clear precision flag
DispatchConv        ldb       $08,s     get conversion char
                    sex                 sign-extend
                    tfr       d,x       move into x for dispatch
                    lbra      ConvDispatch dispatch on conversion

FmtDecimal          ldd       $06,s     field width
                    pshs      d         push width
                    ldx       $13,s     variadic argument pointer
                    leax      $02,x     advance past int arg
                    stx       $13,s     save updated pointer
                    ldd       -$02,x    fetch the int argument
                    pshs      d         push value
                    lbsr      IntToDecimal convert to decimal string
                    bra       StoreConvResult output the field

FmtHex              ldd       $06,s     field width
                    pshs      d         push width
                    ldx       $13,s     variadic argument pointer
                    leax      $02,x     advance past int arg
                    stx       $13,s     save updated pointer
                    ldd       -$02,x    fetch the int argument
                    pshs      d         push value
                    lbsr      IntToHex  convert to hex string
StoreConvResult     std       ,s        store result string pointer
                    lbra      OutputField output the field

FmtChar             ldx       $11,s     variadic argument pointer
                    leax      $02,x     advance past char arg
                    stx       $11,s     save updated pointer
                    ldd       -$02,x    fetch the char argument
                    lbra      PutConvChar output the character

FmtString           ldx       $11,s     variadic argument pointer
                    leax      $02,x     advance past string arg
                    stx       $11,s     save updated pointer
                    ldd       -$02,x    fetch the string pointer
                    std       $09,s     save string pointer
                    ldd       $04,s     precision flag
                    beq       StrFieldSimple none then output whole string
                    ldd       $09,s     string pointer
                    std       $04,s     copy as scan pointer
                    bra       StrLenCount count the characters

StrLenLoop          ldb       [$09,s]   load current char
                    beq       StrFieldOut end then output field
                    ldd       $09,s     scan pointer
                    addd      #$0001    advance
                    std       $09,s     save it
StrLenCount         ldd       $02,s     precision remaining
                    addd      #$FFFF    decrement
                    std       $02,s     save it
                    subd      #$FFFF    test against zero
                    bne       StrLenLoop more then keep counting
StrFieldOut         ldd       $06,s     field width
                    pshs      d         push width
                    ldd       $0b,s     original string pointer
                    subd      $06,s     length is scan minus start
                    pshs      d         push length
                    ldd       $08,s     string pointer
                    pshs      d         push string pointer
                    lbsr      PutStrFieldN output padded field
                    leas      6,s        drop the arguments
                    bra       FieldDone back to format loop

StrFieldSimple      ldd       $06,s     field width
                    pshs      d         push width
                    ldd       $0b,s     string pointer
                    pshs      d         push string pointer
OutputField         lbsr      PutStrField output padded field
                    leas      4,s        drop the arguments
FieldDone           lbra      FmtLoop   back to format loop

FmtDefaultChar      ldb       $08,s     get conversion char
                    sex                 sign-extend
PutConvChar         pshs      d         push the character
                    lbsr      EmitByte  output the character
                    leas      2,s        drop pushed char
                    lbra      FmtLoop   back to format loop

ConvDispatch        cmpx      #$0064    is it the d letter
                    lbeq      FmtDecimal handle decimal
                    cmpx      #$0078    is it the x letter
                    lbeq      FmtHex    handle hex
                    cmpx      #$0063    is it the c letter
                    lbeq      FmtChar   handle char
                    cmpx      #$0073    is it the s letter
                    lbeq      FmtString handle string
                    bra       FmtDefaultChar else emit char literally

DoprntDone          leas      11,s       release local frame
                    puls      pc,u      restore and return

IntToDecimal        pshs      u,d       save regs and value
                    leax      ConversionBuffer,y   point at conversion buffer
                    stx       ,s        save buffer pointer
                    ldd       $06,s     the value
                    bge       ConvMagnitude non-negative then convert
                    ldd       $06,s     the value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish the negation
                    std       $06,s     store absolute value
                    bge       EmitMinus ok then emit sign
                    leax      StrMinInt,pcr point at overflow string
                    pshs      x         push it
                    leax      ConversionBuffer,y   point at conversion buffer
                    pshs      x         push buffer
                    lbsr      StrCopy   copy the string
                    leas      4,s        drop the arguments
                    lbra      RepeatByteDone return the buffer

EmitMinus           ldd       #$002D    minus sign
                    ldx       ,s        buffer pointer
                    leax      $01,x     advance
                    stx       ,s        save pointer
                    stb       -$01,x    write the minus sign
ConvMagnitude       ldd       $06,s     the magnitude
                    pshs      d         push value
                    ldd       $02,s     buffer pointer
                    pshs      d         push buffer
                    bsr       UnsignedToDec convert magnitude to digits
                    leas      4,s        drop the arguments
                    leax      ConversionBuffer,y   point at conversion buffer
                    tfr       x,d       return the buffer pointer
                    lbra      RepeatByteDone return

UnsignedToDec       pshs      u,y,x,d   save regs and arguments
                    ldu       $0a,s     output buffer pointer
                    clra                zero high byte
                    clrb                zero low byte
                    std       $02,s     clear digit-seen flag
                    clra                zero high byte
                    clrb                zero low byte
                    std       ,s        clear digit accumulator
                    bra       DecSeedCheck enter seed loop

DecSeedLoop         ldd       ,s        digit accumulator
                    addd      #$0001    increment
                    std       ,s        save it
                    ldd       $0C,s     remaining value
                    subd      >Pow10,y  subtract seed power of ten
                    std       $0C,s     save remainder
DecSeedCheck        ldd       $0C,s     remaining value
                    blt       DecSeedLoop still short then adjust again
                    leax      >Pow10,y  point at divisor table
                    stx       $04,s     save table pointer
                    bra       DecDivLoop enter division loop

DecDigitInc         ldd       ,s        digit count
                    addd      #$0001    increment
                    std       ,s        save it
DecSubLoop          ldd       $0C,s     remaining value
                    subd      [$04,s]   subtract current power of ten
                    std       $0C,s     save remainder
                    bge       DecDigitInc still fits then count again
                    ldd       $0C,s     remainder went negative
                    addd      [$04,s]   add power back
                    std       $0C,s     restore value
                    ldd       ,s        digit value
                    beq       DecDigitSeen zero digit check
                    ldd       #$0001    mark one
                    std       $02,s     set digit-seen flag
DecDigitSeen        ldd       $02,s     digit-seen flag
                    beq       DecNextPower suppress leading zero
                    ldd       ,s        digit value
                    addd      #$0030    convert to ascii
                    stb       ,u+       emit the digit
DecNextPower        clra                zero high byte
                    clrb                zero low byte
                    std       ,s        reset digit count
                    ldd       $04,s     table pointer
                    addd      #$0002    advance to next power
                    std       $04,s     save it
DecDivLoop          ldd       $04,s     table pointer
                    cmpd      GlbVar0001 reached table end
                    bne       DecSubLoop no then extract next digit
                    ldd       $0C,s     final remainder
                    addd      #$0030    convert to ascii
                    stb       ,u+       emit last digit
                    clra                zero high byte
                    clrb                zero low byte
                    stb       ,u        null-terminate the buffer
                    ldd       $0a,s     return buffer pointer
                    leas      6,s        release locals
                    puls      pc,u      restore and return

IntToHex            pshs      u,x,d     save regs and value
                    leax      ConversionBuffer,y   point at conversion buffer
                    stx       $02,s     save buffer pointer
                    leau      TempHexBuffer,y   point at temp hex buffer
HexNibbleLoop       ldd       $08,s     the value
                    clra                clear high byte
                    andb      #$0f      isolate low nibble
                    std       ,s        save nibble
                    pshs      d         push nibble
                    ldd       $02,s     reload nibble
                    cmpd      #$0009    greater than nine
                    ble       HexDigit09 no then plain digit
                    ldd       #$0057    letter base a minus ten
                    bra       HexEmit   form the letter

HexDigit09          ldd       #$0030    ascii zero base
HexEmit             addd      ,s++      add the nibble value
                    stb       ,u+       emit the hex char
                    ldd       $08,s     the value
                    lsra                shift right one bit
                    rorb                rotate through low byte
                    lsra                shift right one bit
                    rorb                rotate through low byte
                    lsra                shift right one bit
                    rorb                rotate through low byte
                    lsra                shift right one bit
                    rorb                rotate through low byte
                    anda      #$0f      mask off high nibble
                    std       $08,s     save shifted value
                    bne       HexNibbleLoop more nibbles then continue
                    bra       HexReverseCheck reverse the digits

HexReverseLoop      ldb       ,u        get char from temp
                    ldx       $02,s     output pointer
                    leax      $01,x     advance
                    stx       $02,s     save it
                    stb       -$01,x    copy char to buffer
HexReverseCheck     leau      -$01,u    step back in temp
                    pshs      u         save pointer
                    leax      TempHexBuffer,y   start of temp buffer
                    cmpx      ,s++      reached the start
                    bls       HexReverseLoop not yet then copy more
                    clra                zero high byte
                    clrb                zero low byte
                    stb       [$02,s]   null-terminate buffer
                    leax      ConversionBuffer,y   point at conversion buffer
                    tfr       x,d       return the pointer
                    lbra      EmitByteCleanup return

PutStrField         pshs      u         save u register
                    ldu       $06,s     load field width
                    leas      -2,s       reserve local
                    ldd       $06,s     string pointer
                    pshs      d         push for strlen
                    lbsr      StrLen    get string length
                    leas      2,s        drop the argument
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish the negation
                    leau      d,u       pad count is width minus length
                    ldd       GlbVar001D left-justify flag
                    bne       FieldCharNext left then skip leading pad
                    bra       PadLeadCheck compute leading pad

PadLeadLoop         ldd       GlbVar001F pad character
                    pshs      d         push it
                    lbsr      EmitByte  output pad char
                    leas      2,s        drop char
PadLeadCheck        tfr       u,d       pad count
                    leau      -$01,u    decrement
                    std       -$02,s    save remaining
                    bgt       PadLeadLoop more then keep padding
                    bra       FieldCharNext done leading pad

FieldCharLoop       ldd       ,s        current char
                    pshs      d         push it
                    lbsr      EmitByte  output the char
                    leas      2,s        drop char
FieldCharNext       ldx       $06,s     string pointer
                    leax      $01,x     advance
                    stx       $06,s     save it
                    ldb       -$01,x    load next char
                    sex                 sign-extend
                    std       ,s        save char
                    bne       FieldCharLoop not null then output it
                    ldd       GlbVar001D left-justify flag
                    lbeq      RepeatByteDone right then done
                    bra       PadTrailCheck else trailing pad

PadTrailLoop        ldd       GlbVar001F pad character
                    pshs      d         push it
                    lbsr      EmitByte  output pad char
                    leas      2,s        drop char
PadTrailCheck       tfr       u,d       remaining pad count
                    leau      -$01,u    decrement
                    std       -$02,s    save remaining
                    bgt       PadTrailLoop more then keep padding
                    lbra      RepeatByteDone done

PutStrFieldN        pshs      u         save u register
                    ldu       $04,s     buffer pointer
                    leas      -2,s       reserve local
                    ldd       $0a,s     field width
                    subd      $08,s     minus the length
                    std       ,s        save pad count
                    ldd       GlbVar001D left-justify flag
                    bne       FieldNCharCheck left then skip leading pad
                    bra       FieldNPadCheck compute leading pad

FieldNPadLoop       ldd       GlbVar001F pad character
                    pshs      d         push it
                    bsr       EmitByte  output pad char
                    leas      2,s        drop char
FieldNPadCheck      ldd       ,s        pad count
                    addd      #$FFFF    decrement
                    std       ,s        save it
                    subd      #$FFFF    test against zero
                    bgt       FieldNPadLoop more then keep padding
                    bra       FieldNCharCheck done leading pad

FieldNCharLoop      ldb       ,u+       next char
                    sex                 sign-extend
                    pshs      d         push char
                    bsr       EmitByte  output the char
                    leas      2,s        drop char
FieldNCharCheck     ldd       $08,s     remaining length
                    addd      #$FFFF    decrement
                    std       $08,s     save it
                    subd      #$FFFF    test against zero
                    bne       FieldNCharLoop more chars then output
                    ldd       GlbVar001D load the repeat count global
                    beq       RepeatByteDone skip loop if count is zero
                    bra       RepeatByteCond enter loop at the condition test

RepeatByteLoop      ldd       GlbVar001F fetch the byte value to repeat
                    pshs      d         pass value as argument
                    bsr       EmitByte  emit one byte
                    leas      2,s        drop the argument
RepeatByteCond      ldd       ,s        load loop counter from stack
                    addd      #$FFFF    decrement the counter
                    std       ,s        store counter back
                    subd      #$FFFF    restore value for the test
                    bgt       RepeatByteLoop loop while counter still positive
RepeatByteDone      leas      2,s        drop the counter
                    puls      pc,u      return to caller

EmitByte            pshs      u         save frame pointer
                    ldd       GlbVar0021 load current output mode
                    cmpd      #$0002    check for direct byte mode
                    bne       EmitByteBuffered otherwise emit via buffer helper
                    ldd       $04,s     fetch the byte argument
                    ldx       GlbVar001B load output buffer pointer
                    leax      $01,x     advance the pointer
                    stx       GlbVar001B save advanced pointer
                    stb       -$01,x    store the byte into the buffer
                    bra       EmitByteRet done with this byte

EmitByteBuffered    ldd       GlbVar001B load buffer pointer
                    pshs      d         pass pointer to helper
                    ldd       $06,s     fetch the byte argument
                    pshs      d         pass the value
                    lbsr      GenOperand3 write byte through helper
EmitByteCleanup     leas      4,s        drop the helper arguments
EmitByteRet         puls      pc,u      return to caller

StrMinInt           fcc       /-32768/
                    fcb       C$NULL
                    pshs      u,x,d     save registers and make room
                    ldd       $08,s     fetch the requested size
                    pshs      d         pass size
                    lbsr      SizeToQuads round size up to quad units
                    leas      2,s        drop the argument
                    std       ,s        save rounded size as request
                    lbeq      AllocFail fail if rounded size is zero
                    ldd       >FreeRoot,y load free-list root pointer
                    std       $02,s     save as current node
                    bne       AllocScanInit if list exists, start scanning
                    leax      ArenaBase,y   point at the arena base
                    stx       $02,s     set as current node
                    tfr       x,d       copy the pointer
                    std       >FreeRoot,y initialise free-list root
                    std       ArenaBase,y   self-link the first node
                    clra                clear high byte
                    clrb                clear low byte
                    std       NodeSize,y   clear the node size
AllocScanInit       ldu       [$02,s]   load current node pointer
AllocScanLoop       ldd       $02,u     load this node's size
                    cmpd      ,s        compare against request
                    bcs       AllocEndOfList too small, keep scanning
                    ldd       $02,u     reload node size
                    cmpd      ,s        compare against request again
                    bne       SplitBlock larger than request, split it
                    ldd       ,u        exact fit: load next pointer
                    std       [$02,s]   unlink this node
                    bra       TakeBlock go take the block

SplitBlock          ldd       $02,u     load node size
                    subd      ,s        subtract the request
                    std       $02,u     shrink the free node
                    aslb                scale remainder to byte offset
                    rola                propagate carry
                    aslb                continue scaling
                    rola                propagate carry
                    leau      d,u       advance to the tail block
                    ldd       ,s        load request size
                    std       $02,u     record allocated block size
TakeBlock           ldd       $02,s     load current node pointer
                    std       >FreeRoot,y update the free-list root
                    stu       $02,s     save the allocated block
                    bra       ClearBlockCond go clear the block

ClearBlockLoop      ldx       $02,s     load block pointer
                    leax      $01,x     advance pointer
                    stx       $02,s     save pointer
                    clra                clear high byte
                    clrb                clear low byte
                    stb       -$01,x    zero a block byte
ClearBlockCond      ldd       $08,s     load remaining byte count
                    addd      #$FFFF    decrement count
                    std       $08,s     save count
                    subd      #$FFFF    restore for the test
                    bne       ClearBlockLoop loop until block cleared
                    tfr       u,d       return the block pointer
                    bra       AllocRet  go to return

AllocEndOfList      cmpu      >FreeRoot,y reached the list root again
                    bne       AllocNext not root, continue the scan
                    ldd       ,s        load request size
                    pshs      d         pass size
                    bsr       GrowArena grow the arena
                    leas      2,s        drop the argument
                    tfr       d,u       new block pointer
                    stu       -$02,s    save the new block
                    bne       AllocNext got memory, retry scan
AllocFail           clra                clear high byte
                    clrb                clear low byte for null
                    bra       AllocRet  go to return

AllocNext           stu       $02,s     set current node
                    ldu       ,u        follow the next link
                    lbra      AllocScanLoop continue the scan loop

AllocRet            leas      4,s        drop the locals
                    puls      pc,u      return the block

SizeToQuads         pshs      u         save register
                    ldd       $04,s     load the size
                    addd      #$0003    add three to round up
                    lsra                shift high byte right
                    rorb                rotate into low byte
                    lsra                shift again for divide by four
                    rorb                rotate into low byte
                    puls      pc,u      return the quad count

GrowArena           pshs      u,d       save registers
                    ldd       $06,s     load requested size
                    addd      #$007F    round up toward a page
                    pshs      d         pass value
                    ldd       #$0007    shift count of seven
                    lbsr      LsrEntry  divide down to page count
                    pshs      d         pass page count
                    ldd       #$0007    shift count of seven
                    lbsr      AslEntry  multiply back to byte size
                    std       ,s        save byte size
                    pshs      d         pass value
                    ldd       #$0004    constant four
                    lbsr      MulEntry  compute size operand
                    std       ,s        save result
                    pshs      d         pass value
                    lbsr      GrowHeap  request memory from the system
                    leas      2,s        drop arguments
                    tfr       d,u       new memory pointer
                    cmpu      #$FFFF    check for allocation failure
                    bne       GrowArenaOk got memory, continue
                    clra                clear high byte
                    clrb                clear low byte for null
                    lbra      MemDone   go to return

GrowArenaOk         ldd       ,s        load the size
                    pshs      d         pass size
                    pshs      u         pass new block
                    bsr       InsertFreeBlock insert block into free list
                    leas      4,s        drop arguments
                    ldd       >FreeRoot,y return the free-list root
                    lbra      MemDone   go to return

InsertFreeBlock     pshs      u,d       save registers
                    ldu       $06,s     load block to insert
                    lbeq      MemDone   nothing to insert if null
                    ldd       $08,s     load the size
                    pshs      d         pass size
                    lbsr      SizeToQuads round to quad units
                    leas      2,s        drop argument
                    std       $08,s     save rounded size
                    ldd       >FreeRoot,y load free-list root
                    bra       InsertScanCond enter the insertion scan

InsertScanLoop      ldd       ,s        load current node
                    cmpd      [,s]      compare against its link
                    bcs       InsertFollowLink below range, follow link
                    cmpu      ,s        insert point above current
                    bhi       InsertMergeNext found the slot
                    cmpu      [,s]      compare against link
                    bcs       InsertMergeNext found the slot
InsertFollowLink    ldd       [,s]      follow the next link
InsertScanCond      std       ,s        set current node
                    cmpu      ,s        compare insert point
                    bls       InsertScanLoop keep scanning forward
                    cmpu      [,s]      compare against link
                    lbcc      InsertScanLoop continue scanning
InsertMergeNext     pshs      u         save insert pointer
                    ldd       $0a,s     load current block size
                    aslb                scale size to byte offset
                    rola                propagate carry
                    aslb                continue scaling
                    rola                propagate carry
                    addd      ,s++      add base to get block end
                    cmpd      [,s]      adjacent to next node
                    bne       InsertNoMergeNext not adjacent, skip merge
                    ldd       $08,s     load block size
                    pshs      d         pass size
                    ldx       [$02,s]   load next node pointer
                    ldd       $02,x     load next node size
                    addd      ,s++      combine the sizes
                    std       $08,s     save merged size
                    ldx       ,s        load current pointer
                    ldd       [,x]      load successor of next
                    bra       InsertLinkNext go link successor

InsertNoMergeNext   ldd       [,s]      load next pointer
InsertLinkNext      std       ,u        link block to successor
                    ldx       ,s        load current pointer
                    ldd       $02,x     load current block size
                    aslb                scale size to byte offset
                    rola                propagate carry
                    aslb                continue scaling
                    rola                propagate carry
                    addd      ,s        add base to get end
                    pshs      d         pass value
                    cmpu      ,s++      adjacent to previous block
                    bne       InsertNoMergePrev not adjacent, keep separate
                    ldx       ,s        load previous pointer
                    ldd       $02,x     load previous size
                    addd      $08,s     merge in block size
                    std       $02,x     grow the previous block
                    ldd       ,u        load block successor
                    std       [,s]      relink previous node
                    bra       InsertStoreSize go store size

InsertNoMergePrev   stu       [,s]      link previous to the block
InsertStoreSize     ldd       $08,s     load block size
                    std       $02,u     store the block size
                    ldd       ,s        load current pointer
                    std       >FreeRoot,y update the free-list root
MemDone             leas      2,s        drop the local
                    puls      pc,u      return to caller

GenOperand          pshs      u         save frame pointer
                    ldu       $0a,s     load the node pointer
                    leas      -8,s       make room for locals
                    ldd       $0C,s     load the operation code
                    cmpd      #$0088    check for special op $88
                    bne       GenCheck87 not $88, try next
                    ldd       $10,s     load argument
                    pshs      d         pass argument
                    ldd       $10,s     load argument
                    pshs      d         pass argument
                    lbsr      GenLongOp handle op $88
                    lbra      BinaryDone2 go to shared exit

GenCheck87          ldd       $0C,s     reload the opcode
                    cmpd      #$0087    check for op $87
                    bne       GenDispatch not $87, dispatch
                    ldd       $10,s     load argument
                    pshs      d         pass argument
                    ldd       $10,s     load argument
                    pshs      d         pass argument
                    lbsr      GenFloatOp handle op $87
                    lbra      BinaryDone2 go to shared exit

GenDispatch         ldx       $0C,s     opcode into index register
                    lbra      GenNodeDispatch dispatch through jump table

GenPushChar         ldd       $0e,s     load argument
                    pshs      d         pass argument
                    lbsr      RegToLetter resolve the register name
                    std       ,s        save result
                    leax      FmtPshs,pcr point at the pshs format string
                    pshs      x         pass format
                    ldd       GlbVar0005 load output file handle
                    pshs      d         pass file handle
                    lbsr      fprintf   emit the pshs instruction
                    leas      6,s        drop arguments
                    ldd       GlbVar000D load current stack offset
                    subd      #$0002    account for the push
                    std       GlbVar000D save updated offset
                    cmpd      GlbMaxCaseVal compare against low-water mark
                    lbge      GenOpExit skip if not a new minimum
                    ldd       GlbVar000D load current offset
                    std       GlbMaxCaseVal update the low-water mark
                    lbra      GenOpExit go to shared exit

GenLoadByte         ldd       $10,s     load argument
                    pshs      d         pass argument
                    ldd       #$0036    opcode constant
                    pshs      d         pass value
                    ldd       #$0071    opcode constant
                    pshs      d         pass value
                    ldd       #$0081    opcode constant
                    pshs      d         pass value
                    lbsr      GenOperand recurse to generate operand
                    leas      8,s        drop arguments
                    ldd       $0e,s     load argument
                    std       $10,s     store as node argument
                    ldd       #$005A    set operation constant
                    std       $0e,s     store as node opcode
EmitLbMnem          leax      OpLb,pcr  point at the long-branch mnemonic
                    pshs      x         pass mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    ldd       $0e,s     load operand
                    pshs      d         pass operand
                    lbsr      CondMnemonic emit the operand
                    std       ,s        save result
                    lbra      EmitOperandTail continue at operand tail

GenPulsUPC          leax      OpPulsUPc,pcr point at the puls u,pc string
                    lbra      EmitOperandStr emit it and finish

GenReturn2          pshs      u         save register
                    ldd       $12,s     load argument
                    pshs      d         pass argument
                    ldd       $10,s     load argument
                    pshs      d         pass argument
                    lbsr      GenLogicOp generate the return sequence
                    leas      6,s        drop arguments
                    lbra      GenOpExit go to shared exit

GenMult             leax      RtnCcmult,pcr point at the ccmult helper name
                    bra       EmitRuntimeCall emit runtime call

GenUDiv             leax      RtnCcudiv,pcr point at the ccudiv helper name
                    bra       EmitRuntimeCall emit runtime call

GenDiv              leax      RtnCcdiv,pcr point at the ccdiv helper name
                    bra       EmitRuntimeCall emit runtime call

GenAsl              leax      RtnCcasl,pcr point at the ccasl helper name
                    bra       EmitRuntimeCall emit runtime call

GenAsr              leax      RtnCcasr,pcr point at the ccasr helper name
                    bra       EmitRuntimeCall emit runtime call

GenLsr              leax      RtnCclsr,pcr point at the cclsr helper name
                    bra       EmitRuntimeCall emit runtime call

GenUMod             leax      RtnCcumod,pcr point at the ccumod helper name
                    bra       EmitRuntimeCall emit runtime call

GenMod              leax      RtnCcmod,pcr point at the ccmod helper name
EmitRuntimeCall     pshs      x         pass the helper name
                    lbsr      GenPushWord emit the runtime-helper call
                    lbra      EmitStrDone go to shared tail

GenNega             leax      OpNegD,pcr point at the nega mnemonic
                    lbra      EmitOperandStr emit it and finish

GenComa             leax      OpComD,pcr point at the coma mnemonic
                    lbra      EmitOperandStr emit it and finish

GenLeax             leax      OpLeax,pcr point at the leax mnemonic
                    pshs      x         pass mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    ldd       GlbVar000D load stack offset
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      finish the negation
                    pshs      d         pass negated offset
                    lbsr      EmitDecimal emit the number operand
                    leas      2,s        drop argument
                    ldd       >SSuffixString,y  load frame-register name
                    pshs      d         pass operand
                    lbsr      EmitString emit the register operand
                    leas      2,s        drop argument
                    lbsr      EmitNewline emit a newline
EmitStackAdjust     ldd       >StackPointerRegister,y  load stack-pointer register name
                    pshs      d         pass operand
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    ldd       $0e,s     load operand
                    bra       EmitOperandTail2 go emit final operand

GenLeasFrame        ldd       >StackPointerRegister,y  load stack-pointer register name
                    pshs      d         pass operand
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    ldd       $10,s     load argument
                    pshs      d         pass operand
                    lbsr      EmitLocalLabelLine emit the operand
                    leas      2,s        drop argument
                    ldd       $0e,s     load argument
                    pshs      d         pass operand
                    lbsr      EmitLocalLabelLine emit the operand
                    leas      2,s        drop argument
                    leax      OpLeas,pcr point at the leas mnemonic
                    pshs      x         pass mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    ldd       GlbVar000D load stack offset
                    pshs      d         pass value
                    lbsr      EmitDecimal emit the number operand
                    leas      2,s        drop argument
                    leax      OpCommaX,pcr point at the ,x operand suffix
                    pshs      x         pass operand
EmitOperandTail     lbsr      EmitString emit the string operand
                    leas      2,s        drop argument
                    ldd       $10,s     load operand
EmitOperandTail2    pshs      d         pass operand
                    lbsr      EmitLocalLabelLine emit the operand
                    lbra      EmitStrDone go to shared tail

GenJsrCall          ldd       #$0004    size constant four
                    std       GlbVar000F set the operand size
                    ldx       $10,s     load the node pointer
                    ldd       $06,x     load the node type
                    cmpd      #$0034    check for direct type $34
                    bne       GenIndirectJsr not direct, use general path
                    ldx       $10,s     reload node pointer
                    ldd       $08,x     load the offset value
                    std       $04,s     save it
                    beq       GenIndirectJsr zero offset, use general path
                    ldd       >PushMnemonicPointer,y  load mnemonic register name
                    pshs      d         pass operand
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         pass zero
                    ldd       $06,s     load argument
                    addd      #$0004    add offset constant
                    pshs      d         pass value
                    lbsr      EmitLabelDef emit the direct-call operand
                    lbra      BinaryDone2 go to shared exit

GenIndirectJsr      leax      OpJsr,pcr point at the jsr mnemonic
                    pshs      x         pass mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         pass zero
                    ldd       $12,s     load argument
                    pshs      d         pass argument
                    ldd       $12,s     load argument
                    pshs      d         pass argument
                    lbsr      EmitAddrMode emit the indirect-call operand
                    leas      6,s        drop arguments
                    lbra      EmitLineDone go to shared exit

GenSex              leax      OpSex,pcr point at the sex mnemonic
                    bra       EmitOperandStr emit it and finish

GenLoadConst        leax      OpLd,pcr  point at the ld mnemonic
                    pshs      x         pass mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop argument
                    ldd       #$0002    size constant two
                    pshs      d         pass value
                    ldd       $12,s     load argument
                    pshs      d         pass argument
                    ldd       $12,s     load argument
                    pshs      d         pass argument
                    ldd       #$0064    operation constant
                    pshs      d         pass value
                    lbsr      EmitInsnOperand emit the load operand
                    lbra      GenCleanupDone go to shared exit

GenAslb             leax      OpAslbRola,pcr point at the aslb mnemonic
                    bra       EmitOperandStr emit it and finish

GenAsra             leax      OpAsraRorb,pcr point at the asra mnemonic
                    bra       EmitOperandStr emit it and finish

GenLsra             leax      OpLsraRorb,pcr point at the lsra mnemonic
EmitOperandStr      pshs      x         push operand string pointer
                    lbra      EmitStrTail go emit the string

EmitLdy             leax      OpLdy,pcr point to ldy mnemonic
                    pshs      x         push mnemonic pointer
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    leax      $08,s     point past local frame
                    bra       LdyLduBody join common body

EmitLdu             leax      OpLdu,pcr point to ldu mnemonic
                    pshs      x         push mnemonic pointer
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    bra       LdyLduEmit join common emit

LdyLduBody          leas      -$08,x    restore stack to frame
LdyLduEmit          ldd       $0e,s     load node operand field
                    pshs      d         pass as argument
                    lbsr      EmitDecimal emit operand
                    leas      2,s        drop the argument
                    ldd       >SSuffixString,y  load global temp field
                    pshs      d         pass as argument
                    lbsr      EmitString emit register operand
                    leas      2,s        drop the argument
EmitLineDone        lbsr      EmitNewline finish emitting the line
                    lbra      GenOpExit return to generator loop

EmitLeax            leax      OpLeax2,pcr point to leax mnemonic
                    pshs      x         push mnemonic pointer
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    ldx       $0e,s     load operand node
                    bra       LeaxOperandSel dispatch on operand type

EmitIndexReg        ldx       $10,s     load node pointer
                    ldd       $06,x     load its type field
                    std       $06,s     save current type
                    cmpd      #$0094    is it type 0x94
                    bne       CheckType95 no, check next
                    ldd       #$0079    pick register code y
                    bra       EmitIndexFmt emit the index

CheckType95         ldd       $06,s     reload the type
                    cmpd      #$0095    is it type 0x95
                    bne       RegDefaultX no, use default
                    ldd       #$0075    pick register code u
                    bra       EmitIndexFmt emit the index

RegDefaultX         ldd       #$0078    default register code x
EmitIndexFmt        std       $06,s     store selected register
                    pshs      d         pass register char
                    ldx       $12,s     load node pointer
                    ldd       $08,x     load offset value
                    pshs      d         pass the offset
                    leax      FmtNumComma,pcr point to %d,%c format
                    pshs      x         push format string
                    ldd       GlbVar0005 output file handle
                    pshs      d         push the file handle
                    lbsr      fprintf   emit indexed operand
                    lbra      GenCleanupDone clean up and return

EmitDReg            ldd       $10,s     load node pointer
                    pshs      d         pass the node
                    lbsr      RegToLetter resolve register
                    std       ,s        save the result
                    leax      FmtDComma,pcr point to d,%c format
                    lbra      FprintfEmitTail emit via fprintf tail

LeaxOperandSel      cmpx      #$0077    is operand type 0x77
                    beq       EmitIndexReg handle indexed operand
                    cmpx      #$0070    is operand type 0x70
                    beq       EmitDReg  handle d register
                    lbra      GenOpExit otherwise return

GenNodeDispatch     cmpx      #$007A    is operator 0x7a
                    lbeq      GenPushChar dispatch to handler
                    cmpx      #$007D    is operator 0x7d
                    lbeq      GenLoadByte dispatch to handler
                    cmpx      #$0082    is operator 0x82
                    lbeq      EmitLbMnem dispatch to handler
                    cmpx      #$0012    is operator 0x12
                    lbeq      GenPulsUPC dispatch to handler
                    cmpx      #$0057    is operator 0x57
                    lbeq      GenReturn2 dispatch to handler
                    cmpx      #$0058    is operator 0x58
                    lbeq      GenReturn2 dispatch to handler
                    cmpx      #$0059    is operator 0x59
                    lbeq      GenReturn2 dispatch to handler
                    cmpx      #$0052    is operator 0x52
                    lbeq      GenMult   dispatch to handler
                    cmpx      #$004E    is operator 0x4e
                    lbeq      GenUDiv   dispatch to handler
                    cmpx      #$0053    is operator 0x53
                    lbeq      GenDiv    dispatch to handler
                    cmpx      #$0056    is operator 0x56
                    lbeq      GenAsl    dispatch to handler
                    cmpx      #$0055    is operator 0x55
                    lbeq      GenAsr    dispatch to handler
                    cmpx      #$004D    is operator 0x4d
                    lbeq      GenLsr    dispatch to handler
                    cmpx      #$004C    is operator 0x4c
                    lbeq      GenUMod   dispatch to handler
                    cmpx      #$0054    is operator 0x54
                    lbeq      GenMod    dispatch to handler
                    cmpx      #$0043    is operator 0x43
                    lbeq      GenNega   dispatch to handler
                    cmpx      #$0044    is operator 0x44
                    lbeq      GenComa   dispatch to handler
                    cmpx      #$001D    is operator 0x1d
                    lbeq      GenLeax   dispatch to handler
                    cmpx      #$007C    is operator 0x7c
                    lbeq      EmitStackAdjust dispatch to handler
                    cmpx      #$0009    is operator 0x09
                    lbeq      GenLeasFrame dispatch to handler
                    cmpx      #$0065    is operator 0x65
                    lbeq      GenJsrCall dispatch to handler
                    cmpx      #$0085    is operator 0x85
                    lbeq      GenSex    dispatch to handler
                    cmpx      #$0084    is operator 0x84
                    lbeq      GenLoadConst dispatch to handler
                    cmpx      #$0098    is operator 0x98
                    lbeq      GenAslb   dispatch to handler
                    cmpx      #$0096    is operator 0x96
                    lbeq      GenAsra   dispatch to handler
                    cmpx      #$0097    is operator 0x97
                    lbeq      GenLsra   dispatch to handler
                    cmpx      #$0076    is operator 0x76
                    lbeq      EmitLdy   dispatch to handler
                    cmpx      #$006F    is operator 0x6f
                    lbeq      EmitLdu   dispatch to handler
                    cmpx      #$007B    is operator 0x7b
                    lbeq      EmitLeax  dispatch to handler
                    ldd       $0e,s     load left operand field
                    pshs      d         pass it
                    lbsr      RegToLetter resolve register
                    leas      2,s        drop the argument
                    std       $06,s     save the register
                    ldd       $10,s     load node pointer
                    cmpd      #$0077    is it indexed type
                    lbne      GenChildCode no, generate child
                    ldd       $06,u     load parent type
                    cmpd      #$0085    is it type 0x85
                    bne       ConvertCheck no, other conversion
                    ldd       $0a,u     load node field
                    pshs      d         push argument
                    ldd       #$0077    push type 0x77
                    pshs      d         push it
                    ldd       #$0070    push type 0x70
                    pshs      d         push it
                    ldd       $12,s     load node pointer
                    pshs      d         push it
                    lbsr      GenOperand generate subexpression
                    leas      8,s        drop four arguments
                    ldx       $0C,s     load result type
                    bra       SignExtendSel select sign-extend op

EmitSex             leax      OpSex2,pcr point to sex string
                    bra       SignExtendEmit emit it

EmitAdca            leax      OpAdca0,pcr point to adca #0
                    bra       SignExtendEmit emit it

EmitSbca            leax      OpSbca0,pcr point to sbca #0
SignExtendEmit      pshs      x         push string pointer
                    lbsr      EmitSpaceStrLine emit the string
                    leas      2,s        drop the argument
                    bra       SetResultTypeD set result type

SignExtendSel       cmpx      #$0075    is type 0x75
                    beq       EmitSex   emit sex
                    cmpx      #$004F    is type 0x4f
                    beq       EmitAdca  emit adca
                    cmpx      #$0050    is type 0x50
                    lbeq      EmitAdca  emit adca
                    cmpx      #$0051    is type 0x51
                    beq       EmitSbca  emit sbca
SetResultTypeD      ldd       #$0070    result type d
                    std       $06,u     store result type
                    lbra      GenOpExit return to loop

ConvertCheck        ldd       ,u        load node opcode
                    cmpd      #$0002    is it opcode 2
                    bne       GenChildCode no, generate child
                    ldd       $0C,s     load the type
                    cmpd      #$007F    is it 0x7f
                    beq       GenChildCode yes, skip
                    ldd       $06,s     load the register
                    cmpd      #$0078    is register x
                    beq       GenChildCode yes, skip
                    ldd       #$0062    set type 0x62
                    std       $06,s     save it
GenChildCode        ldx       $0C,s     load child node
                    lbra      GenLeaDispatch generate child code

IndirectSetup       ldd       $10,s     load node pointer
                    cmpd      #$0077    is indexed type
                    lbne      EmitLoadDefault no, other path
                    ldd       $08,u     load address field
                    std       ,s        save it
                    ldd       $06,u     load type field
                    std       $02,s     save it
                    tfr       d,x       move type to x
                    lbra      StoreTypeSel dispatch on type

EmitStore           ldd       $0e,s     load operand type
                    cmpd      #$0070    is it type d
                    beq       EmitStoreDirect handle direct
                    ldd       $06,s     load the register
                    pshs      d         pass it
                    lbsr      EmitLeaPrefix resolve operand
                    leas      2,s        drop the argument
                    ldd       $02,s     load saved type
                    pshs      d         pass it
                    lbsr      RegToLetter resolve register
                    std       ,s        save the result
                    ldd       $02,s     reload the type
                    pshs      d         pass it
                    leax      FmtNumComma2,pcr point to %d,%c format
                    lbra      FprintfExg emit via fprintf

EmitStoreDirect     ldd       #$0064    push type 0x64
                    pshs      d         push it
                    ldd       $04,s     load node field
                    pshs      d         pass it
                    lbsr      RegToLetter resolve register
                    std       ,s        save the result
                    lbsr      EmitTfrRegs emit operand
                    leas      4,s        drop two arguments
                    ldd       ,s        load the result
                    lbeq      GenOpExit nothing to do, return
                    ldd       ,s        reload the result
                    pshs      d         push it
                    ldd       #$0036    push type 0x36
                    pshs      d         push it
                    ldd       #$0070    push type 0x70
                    pshs      d         push it
                    ldd       #$0050    push type 0x50
                    pshs      d         push it
                    lbsr      GenOperand generate subexpression
                    lbra      GenCleanupDone clean up and return

EmitDRegStore       ldd       $0e,s     load operand type
                    cmpd      #$0070    is it type d
                    lbeq      GenOpExit yes, return
                    ldd       $06,s     load the register
                    pshs      d         pass it
                    ldd       #$0064    load type 0x64
                    lbra      EmitBinaryTail emit binary tail

EmitBinaryOp2       ldd       $08,u     load address field
                    pshs      d         pass it
                    ldd       $08,s     load the operand
                    pshs      d         pass it
                    lbsr      EmitLeaPcr emit binary operation
                    lbra      BinaryDone2 finish and return

SetType36Retry      ldd       #$0036    set type 0x36
                    std       $10,s     store node type
                    ldu       ,s        reload node pointer
                    bra       EmitLoadDefault continue default path

StoreTypeSel        cmpx      #$0071    is type 0x71
                    lbeq      EmitStore handle store
                    cmpx      #$0076    is type 0x76
                    lbeq      EmitStore handle store
                    cmpx      #$006F    is type 0x6f
                    lbeq      EmitStore handle store
                    cmpx      #$0070    is type 0x70
                    beq       EmitDRegStore handle d register
                    cmpx      #$0037    is type 0x37
                    beq       EmitBinaryOp2 handle binary op
                    cmpx      #$0036    is type 0x36
                    beq       SetType36Retry set type and retry
EmitLoadDefault     ldd       $0e,s     load operand type
                    cmpd      #$0070    is it type d
                    bne       EmitLdFall no, emit load
                    ldd       $10,s     load node type
                    cmpd      #$0036    is it type 0x36
                    bne       EmitLdFall no, emit load
                    cmpu      #$0000    is node pointer null
                    bne       EmitLdFall no, emit load
                    leax      OpClraClrb,pcr point to clra string
                    pshs      x         push the string
EmitStrTail         lbsr      EmitSpaceStrLine emit the string
EmitStrDone         leas      2,s        drop the argument
                    lbra      GenOpExit return to loop

EmitLdFall          leax      OpLd2,pcr point to ld mnemonic
                    lbra      EmitMnemonicTail emit mnemonic tail

EmitStoreTmp        ldd       $10,s     load node type
                    cmpd      #$0036    is it type 0x36
                    bne       EmitCmp   no, emit compare
                    cmpu      #$0000    is node pointer null
                    bne       EmitCmp   no, emit compare
                    ldd       $06,s     load the register
                    pshs      d         pass it
                    leax      FmtStStack,pcr point to st%c -2,s format
FprintfEmitTail     pshs      x         push format string
                    ldd       GlbVar0005 output file handle
                    pshs      d         push it
                    lbsr      fprintf   emit the store
                    leas      6,s        drop the arguments
                    lbra      GenOpExit return to loop

EmitCmp             leax      OpCmp,pcr point to cmp mnemonic
                    pshs      x         push mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    ldd       $06,s     load the register
                    cmpd      #$0062    is it register 0x62
                    bne       FrameSetup8 no, continue
                    ldd       #$0064    replace with 0x64
                    std       $06,s     save it
                    bra       FrameSetup8 continue

IndirectCompare     ldd       $10,s     load node type
                    cmpd      #$0077    is indexed type
                    bne       EmitSt    no, emit store
                    ldd       $06,u     load type field
                    std       $02,s     save it
                    pshs      d         pass it
                    lbsr      IsFloatType look up operand
                    std       ,s++      save result and drop
                    beq       EmitSt    none, emit store
                    ldd       $02,s     load saved type
                    cmpd      $0e,s     same as operand type
                    lbeq      GenOpExit yes, return
                    ldd       $02,s     reload the type
                    pshs      d         pass it
                    lbsr      RegToLetter resolve register
                    std       ,s        save the result
                    ldd       $08,s     load the operand
EmitBinaryTail      pshs      d         pass it
                    lbsr      EmitTfrRegs emit operand
BinaryDone2         leas      4,s        drop two arguments
                    lbra      GenOpExit return to loop

EmitSt              leax      OpSt,pcr  point to st mnemonic
                    bra       EmitMnemonicTail emit mnemonic tail

EmitSub             leax      OpSub,pcr point to sub mnemonic
EmitMnemonicTail    pshs      x         push mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
FrameSetup8         leax      $08,s     point past local frame
                    bra       FrameBody join common body

EmitAddConst        ldd       #$0043    push type 0x43
                    pshs      d         push it
                    lbsr      GenOperand generate subexpression
                    leas      2,s        drop the argument
EmitAddTail         leax      OpAdd,pcr point to add mnemonic
                    lbra      LeaEmitTail emit mnemonic tail

FrameBody           leas      -$08,x    restore stack to frame
                    lbra      BuildCallFrame build call frame

IndirectAdd         ldd       $10,s     load node type
                    cmpd      #$0077    is indexed type
                    lbne      EmitLea2  no, emit lea
                    ldd       [$08,u]   load indirect address
                    std       $02,s     save it
                    tfr       d,x       move to x
                    bra       OffsetTypeSel dispatch on type

EmitOffsetLoad      ldd       $06,s     load the register
                    pshs      d         pass it
                    lbsr      EmitLeaPrefix resolve operand
                    leas      2,s        drop the argument
                    ldd       #$003E    push char >
                    pshs      d         push it
                    lbsr      EmitChar  emit the prefix
                    leas      2,s        drop the argument
                    ldd       $02,s     load saved type
                    cmpd      #$0023    is it type 0x23
                    bne       AddOffset4 no, add offset
                    ldx       $08,u     load address field
                    ldd       $04,x     load its value
                    pshs      d         pass it
                    lbsr      EmitLocalLabel emit constant
                    bra       OffsetEmitTail continue emit

AddOffset4          ldd       $08,u     load address field
                    addd      #$0004    add four to it
                    pshs      d         pass it
                    lbsr      EmitSymbol2 emit label reference
OffsetEmitTail      leas      2,s        drop the argument
                    ldd       $14,u     load node field
                    pshs      d         pass it
                    lbsr      EmitSignedOffset emit operand
                    leas      2,s        drop the argument
                    ldd       >GlobalField,y  load global field
                    pshs      d         pass it
                    lbsr      EmitString emit register operand
                    lbra      EmitArgTerm finish and return

OffsetTypeSel       cmpx      #$0021    is type 0x21
                    beq       EmitOffsetLoad handle offset load
                    cmpx      #$0022    is type 0x22
                    lbeq      EmitOffsetLoad handle offset load
                    cmpx      #$0023    is type 0x23
                    lbeq      EmitOffsetLoad handle offset load
EmitLea2            leax      OpLea,pcr point to lea mnemonic
LeaEmitTail         pshs      x         push mnemonic
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
BuildCallFrame      clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push null argument
                    pshs      u         push node pointer
                    ldd       $14,s     load node field
                    pshs      d         pass it
                    ldd       $0C,s     load node field
                    pshs      d         pass it
                    lbsr      EmitInsnOperand generate operand code
                    bra       GenCleanupDone clean up and return

EmitExg             ldd       $10,s     load node pointer
                    pshs      d         pass it
                    lbsr      RegToLetter resolve register
                    std       ,s        save the result
                    ldd       $08,s     load node field
                    pshs      d         pass it
                    leax      FmtExg,pcr point to exg %c,%c format
FprintfExg          pshs      x         push format string
                    ldd       GlbVar0005 output file handle
                    pshs      d         push it
                    lbsr      fprintf   emit the instruction
GenCleanupDone      leas      8,s        drop the arguments
                    lbra      GenOpExit return to loop

EmitStoreIndexed    ldd       $06,s     load the register
                    pshs      d         pass it
                    lbsr      EmitLeaPrefix resolve operand
                    leas      2,s        drop the argument
                    ldx       $10,s     load node pointer
                    bra       LeaOpDispatch continue generation

EmitDComma          leax      OpDComma,pcr point to d, string
                    pshs      x         push the string
                    lbsr      EmitString emit register operand
                    leas      2,s        drop the argument
                    leax      $08,s     point past local frame
                    bra       CaseLeaAdjust join common body

PushNodeEmit        pshs      u         push node pointer
                    lbsr      EmitDecimal emit operand
                    leas      2,s        drop the argument
                    ldd       #$002C    load comma character constant
                    pshs      d         push it as argument
                    lbsr      EmitChar  emit the character
                    leas      2,s        drop the argument
                    bra       EmitLeaArg join common emit path

CaseLeaAdjust       leas      -$08,x    adjust operand pointer by minus eight
EmitLeaArg          ldd       $06,s     load operand field from stack
                    pshs      d         push it as argument
                    lbsr      EmitChar  emit the operand
EmitArgTerm         leas      2,s        drop the argument
                    lbsr      EmitNewline emit line terminator
                    lbra      GenOpExit return through common exit

EmitLeaString       leax      MsgLeaArg,pcr point at 'LEA arg' string
                    pshs      x         push string argument
                    lbsr      EmitValueRef emit the string
                    leas      2,s        drop the argument
                    lbra      GenOpExit return through common exit

LeaOpDispatch       cmpx      #$0070    test for operand form $70
                    beq       EmitDComma handle that form
                    cmpx      #$0036    test for operand form $36
                    beq       PushNodeEmit handle that form
                    bra       EmitLeaString otherwise emit lea string

EmitNodeField       ldd       >NodeFieldY,y  load node field at y+$57
                    pshs      d         push as argument
                    lbsr      EmitValueRef emit it
                    leas      2,s        drop the argument
                    lbra      GenOpExit return through common exit

GenLeaDispatch      cmpx      #$0075    test operator code
                    lbeq      IndirectSetup go to matching handler
                    cmpx      #$0081    test operator code
                    lbeq      EmitStoreTmp go to matching handler
                    cmpx      #$0079    test operator code
                    lbeq      IndirectCompare go to matching handler
                    cmpx      #$0051    test operator code
                    lbeq      EmitSub   go to matching handler
                    cmpx      #$004F    test operator code
                    lbeq      EmitAddConst go to matching handler
                    cmpx      #$0050    test operator code
                    lbeq      EmitAddTail go to matching handler
                    cmpx      #$007F    test operator code
                    lbeq      IndirectAdd go to matching handler
                    cmpx      #$0073    test operator code
                    lbeq      EmitExg   go to matching handler
                    cmpx      #$0074    test operator code
                    lbeq      EmitStoreIndexed go to matching handler
                    bra       EmitNodeField default to node-field emit

RegToLetter         pshs      u         save frame register
                    ldx       $04,s     load register code argument
                    bra       RegLetterDispatch enter letter dispatch

RegLetterD          ldd       #$0064    return letter 'd'
                    puls      pc,u      restore frame and return

RegLetterX          ldd       #$0078    return letter 'x'
                    puls      pc,u      restore frame and return

RegLetterY          ldd       #$0079    return letter 'y'
                    puls      pc,u      restore frame and return

RegLetterU          ldd       #$0075    return letter 'u'
                    puls      pc,u      restore frame and return

RegLetterSpace      ldd       #$0020    return default space
                    puls      pc,u      restore frame and return

RegLetterDispatch   cmpx      #$0070    is register code d
                    beq       RegLetterD yes return d
                    cmpx      #$0071    is register code x
                    beq       RegLetterX yes return x
                    cmpx      #$0076    is register code y
                    beq       RegLetterY yes return y
                    cmpx      #$006F    is register code u
                    beq       RegLetterU yes return u
                    bra       RegLetterSpace otherwise return space

                    puls      pc,u      restore frame and return

EmitTfrRegs         pshs      u         save frame register
                    ldd       $06,s     load first register operand
                    pshs      d         push as argument
                    ldd       $06,s     load second register operand
                    pshs      d         push as argument
                    leax      FmtTfr,pcr point at ' tfr %c,%c' format
                    pshs      x         push format argument
                    ldd       GlbVar0005 load output stream
                    pshs      d         push stream argument
                    lbsr      fprintf   emit formatted transfer
GenOpExit           leas      8,s        drop the pushed arguments
                    puls      pc,u      restore frame and return

GenLongOp           pshs      u         save frame register
                    ldx       $04,s     load operator code argument
                    lbra      GenLongDispatch enter long dispatch

GenLongLeaf         ldd       #$0002    push size two
                    pshs      d         push it
                    ldd       #$0093    push operand code $93
                    pshs      d         push it
                    ldd       #$0070    push register d code
                    pshs      d         push it
                    ldd       #$0075    push register u code
                    pshs      d         push it
                    lbsr      GenOperand emit long instruction
                    leas      8,s        drop the arguments
                    ldd       #$0070    push register d code
                    pshs      d         push it
                    ldd       #$007A    push operand code $7A
                    pshs      d         push it
                    lbsr      GenOperand emit long instruction
                    leas      4,s        drop the arguments
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero value
                    ldd       #$0093    push operand code $93
                    pshs      d         push it
                    ldd       #$0070    push register d code
                    pshs      d         push it
                    ldd       #$0075    push register u code
                    pshs      d         push it
                    lbsr      GenOperand emit long instruction
                    leas      8,s        drop the arguments
                    ldd       #$0070    push register d code
                    pshs      d         push it
                    ldd       #$007A    push operand code $7A
                    pshs      d         push it
                    lbsr      GenOperand emit long instruction
                    lbra      GenFloatExit return through float exit

EmitLdaZeroX        leax      OpOrPointer4,pcr point at 'lda 0,x' string
                    pshs      x         push string argument
                    lbsr      EmitSpaceStrLine emit the string
                    lbra      DropArgRet return through common exit

EmitLmove           leax      RtLmove,pcr point at '_lmove' string
                    bra       GenLongShift2 emit shift-style long call

EmitLadd            leax      RtLadd,pcr point at '_ladd' string
                    bra       GenLongCall emit long runtime call

EmitLsub            leax      RtLsub,pcr point at '_lsub' string
                    bra       GenLongCall emit long runtime call

EmitLmul            leax      RtLmul,pcr point at '_lmul' string
                    bra       GenLongCall emit long runtime call

EmitLdiv            leax      RtLdiv,pcr point at '_ldiv' string
                    bra       GenLongCall emit long runtime call

EmitLmod            leax      RtLmod,pcr point at '_lmod' string
                    bra       GenLongCall emit long runtime call

EmitLand            leax      RtLand,pcr point at '_land' string
                    bra       GenLongCall emit long runtime call

EmitLor             leax      RtLor,pcr point at '_lor' string
                    bra       GenLongCall emit long runtime call

EmitLxor            leax      RtLxor,pcr point at '_lxor' string
                    bra       GenLongCall emit long runtime call

EmitLshl            leax      RtLshl,pcr point at '_lshl' string
                    bra       GenLongShift2 emit shift-style long call

EmitLshr            leax      RtLshr,pcr point at '_lshr' string
GenLongShift2       pshs      x         push mnemonic argument
                    lbsr      GenPushLong emit the instruction line
                    leas      2,s        drop the argument
                    ldd       GlbVar000D load stack-depth global
                    subd      #$0002    account for popped two bytes
                    lbra      StoreStackDepth store depth and return

EmitLcmpr           leax      RtLcmpr,pcr point at '_lcmpr' string
GenLongCall         pshs      x         push mnemonic argument
                    lbsr      GenPushLong emit the instruction line
                    lbra      DropArgRet return through common exit

EmitLneg            leax      RtLneg,pcr point at '_lneg' string
                    bra       GenLongUnary2 emit unary long call

EmitLcompl          leax      RtLcompl,pcr point at '_lcompl' string
                    bra       GenLongUnary2 emit unary long call

EmitLitol           leax      RtLitol,pcr point at '_litol' string
                    bra       GenLongUnary2 emit unary long call

EmitLutol           leax      RtLutol,pcr point at '_lutol' string
                    bra       GenLongUnary2 emit unary long call

EmitLinc            leax      RtLinc,pcr point at '_linc' string
                    bra       GenLongUnary2 emit unary long call

EmitLdec            leax      RtLdec,pcr point at '_ldec' string
GenLongUnary2       pshs      x         push mnemonic argument
                    lbsr      GenPushLong emit the instruction line
                    leas      2,s        drop the argument
                    ldd       GlbVar000D load stack-depth global
                    subd      #$0004    account for popped four bytes
                    lbra      StoreStackDepth store depth and return

GenLongStack        ldd       #$0002    push size two
                    pshs      d         push it
                    ldd       $08,s     load node operand from stack
                    pshs      d         push it
                    lbra      GenFloatStack emit long stack helper

GenLongError        leax      MsgCodgenLongs,pcr point at 'codgen - longs' message
                    pshs      x         push message argument
                    lbsr      EmitValueRef emit the error text
                    leas      2,s        drop the argument
                    ldd       >NodeFieldY,y  load node field at y+$57
                    pshs      d         push it
                    lbsr      EmitString emit operand
                    leas      2,s        drop the argument
                    ldd       $04,s     load operand from stack
                    pshs      d         push it
                    lbsr      EmitDecimal emit operand
                    leas      2,s        drop the argument
                    lbsr      EmitNewline emit line terminator
                    lbra      GenLongRet return via long-error return

GenLongDispatch     cmpx      #$006E    test operator code $6E
                    lbeq      GenLongLeaf go emit long leaf
                    cmpx      #$008B    test operator code $8B
                    lbeq      EmitLdaZeroX go emit lda 0,x
                    cmpx      #$0089    test operator code $89
                    lbeq      EmitLmove go emit _lmove
                    cmpx      #$0050    test operator code $50
                    lbeq      EmitLadd  go emit _ladd
                    cmpx      #$0051    test operator code $51
                    lbeq      EmitLsub  go emit _lsub
                    cmpx      #$0052    test operator code $52
                    lbeq      EmitLmul  go emit _lmul
                    cmpx      #$0053    test operator code $53
                    lbeq      EmitLdiv  go emit _ldiv
                    cmpx      #$0054    test operator code $54
                    lbeq      EmitLmod  go emit _lmod
                    cmpx      #$0057    test operator code $57
                    lbeq      EmitLand  go emit _land
                    cmpx      #$0058    test operator code $58
                    lbeq      EmitLor   go emit _lor
                    cmpx      #$0059    test operator code $59
                    lbeq      EmitLxor  go emit _lxor
                    cmpx      #$0056    test operator code $56
                    lbeq      EmitLshl  go emit _lshl
                    cmpx      #$0055    test operator code $55
                    lbeq      EmitLshr  go emit _lshr
                    cmpx      #$005A    test operator code $5A
                    lbeq      EmitLcmpr go emit _lcmpr
                    cmpx      #$005B    test operator code $5B
                    lbeq      EmitLcmpr go emit _lcmpr
                    cmpx      #$005E    test operator code $5E
                    lbeq      EmitLcmpr go emit _lcmpr
                    cmpx      #$005C    test operator code $5C
                    lbeq      EmitLcmpr go emit _lcmpr
                    cmpx      #$005F    test operator code $5F
                    lbeq      EmitLcmpr go emit _lcmpr
                    cmpx      #$005D    test operator code $5D
                    lbeq      EmitLcmpr go emit _lcmpr
                    cmpx      #$0043    test operator code $43
                    lbeq      EmitLneg  go emit _lneg
                    cmpx      #$0044    test operator code $44
                    lbeq      EmitLcompl go emit _lcompl
                    cmpx      #$0083    test operator code $83
                    lbeq      EmitLitol go emit _litol
                    cmpx      #$0086    test operator code $86
                    lbeq      EmitLutol go emit _lutol
                    cmpx      #$003C    test operator code $3C
                    lbeq      EmitLinc  go emit _linc
                    cmpx      #$003E    test operator code $3E
                    lbeq      EmitLinc  go emit _linc
                    cmpx      #$003D    test operator code $3D
                    lbeq      EmitLdec  go emit _ldec
                    cmpx      #$003F    test operator code $3F
                    lbeq      EmitLdec  go emit _ldec
                    cmpx      #$004A    test operator code $4A
                    lbeq      GenLongStack go emit long stack
                    lbra      GenLongError otherwise emit long error

GenLongRet          puls      pc,u      restore frame and return

GenFloatOp          pshs      u         save frame register
                    ldu       $06,s     load second node pointer
                    ldx       $04,s     load operator code argument
                    lbra      GenFloatDispatch enter float dispatch

EmitDstack          ldd       #$0004    push size four
                    pshs      d         push it
                    pshs      u         push node pointer
GenFloatStack       lbsr      GenSwitchCode emit float stack helper
GenFloatExit        leas      4,s        drop the arguments
                    puls      pc,u      restore frame and return

EmitDstackPop       leax      RtDstack,pcr point at '_dstack' string
                    pshs      x         push mnemonic argument
                    lbsr      GenPushOperand emit the float call
                    leas      2,s        drop the argument
                    ldd       GlbVar000D load stack-depth global
                    subd      #$0008    account for popped eight bytes
                    lbra      StoreStackDepth store depth and return

EmitFloatLoad       cmpu      #$0005    is operand size five
                    bne       FloatLoadDouble no use double form
                    ldd       #$0033    select float offset $33
                    bra       EmitFloatLoadFmt skip to format emit

FloatLoadDouble     ldd       #$0037    select double offset $37
EmitFloatLoadFmt    pshs      d         push chosen offset
                    leax      FmtLdaReg,pcr point at ' lda %c,x' format
                    pshs      x         push format argument
                    ldd       GlbVar0005 load output stream
                    pshs      d         push stream argument
                    lbsr      fprintf   emit formatted float load
                    leas      6,s        drop the arguments
                    puls      pc,u      restore frame and return

EmitFloatMove       cmpu      #$0005    is operand size five
                    bne       EmitDmoveSel no use double move
                    leax      RtFmove,pcr point at '_fmove' string
                    bra       GenMoveCall go emit move call

EmitDmoveSel        leax      RtDmove,pcr point at '_dmove' string
GenMoveCall         tfr       x,d       move mnemonic into d
                    pshs      d         push as argument
                    lbsr      GenPushOperand emit the move call
                    lbra      AdjustDepthWord return via float epilogue

EmitDadd            leax      RtDadd,pcr point at '_dadd' string
                    bra       GenFloatBin emit binary float call

EmitDsub            leax      RtDsub,pcr point at '_dsub' string
                    bra       GenFloatBin emit binary float call

EmitDmul            leax      RtDmul,pcr point at '_dmul' string
                    bra       GenFloatBin emit binary float call

EmitDdiv            leax      RtDdiv,pcr point at '_ddiv' string
                    bra       GenFloatBin emit binary float call

EmitDcmpr           leax      RtDcmpr,pcr point at '_dcmpr' string
GenFloatBin         pshs      x         push mnemonic argument
                    lbsr      GenPushOperand emit the float call
                    leas      2,s        drop the argument
                    ldd       GlbVar000D load stack-depth global
                    addd      #$0008    account for pushed eight bytes
                    lbra      StoreStackDepth store depth and return

EmitDneg            leax      RtDneg,pcr point at '_dneg' string
                    bra       GenFloatCall emit unary float call

EmitFloatInc        cmpu      #$0005    is operand size five
                    bne       EmitDincSel no use double increment
                    leax      RtFinc,pcr point at '_finc' string
                    bra       GenIncDecCall go emit inc/dec call

EmitDincSel         leax      RtDinc,pcr point at '_dinc' string
                    bra       GenIncDecCall go emit inc/dec call

EmitFloatDec        cmpu      #$0005    is operand size five
                    bne       EmitDdecSel no use double decrement
                    leax      RtFdec,pcr point at '_fdec' string
                    bra       GenIncDecCall go emit inc/dec call

EmitDdecSel         leax      RtDdec,pcr point at '_ddec' string
GenIncDecCall       tfr       x,d       move mnemonic into d
                    pshs      d         push as argument
                    bra       GenFloatCallEmit emit the inc/dec call

EmitDtof            leax      RtDtof,pcr point at '_dtof' string
                    bra       GenFloatCall emit conversion call

EmitFtod            leax      RtFtod,pcr point at '_ftod' string
                    bra       GenFloatCall emit conversion call

EmitLtod            leax      RtLtod,pcr point at '_ltod' string
                    bra       GenFloatCall emit conversion call

EmitItod            leax      RtItod,pcr point at '_itod' string
                    bra       GenFloatCall emit conversion call

EmitUtod            leax      RtUtod,pcr point at '_utod' string
                    bra       GenFloatCall emit conversion call

EmitDtol            leax      RtDtol,pcr point at '_dtol' string
                    bra       GenFloatCall emit conversion call

EmitDtoi            leax      RtDtoi,pcr point at '_dtoi' string
GenFloatCall        pshs      x         push mnemonic argument
GenFloatCallEmit    lbsr      GenPushOperand emit the float call
                    lbra      DropArgRet return through common exit

GenFloatError       leax      MsgCodgenFloats,pcr point at 'codgen - floats' message
                    pshs      x         push message argument
                    lbsr      EmitValueRef emit the error text
                    leas      2,s        drop the argument
                    ldd       >NodeFieldY,y  load node field at y+$57
                    pshs      d         push it
                    lbsr      EmitString emit operand
                    leas      2,s        drop the argument
                    ldd       $04,s     load operand from stack
                    pshs      d         push it
                    lbsr      EmitDecimal emit operand
                    leas      2,s        drop the argument
                    lbsr      EmitNewline emit line terminator
                    lbra      EmptyRet  return via float-error exit

GenFloatDispatch    cmpx      #$004B    test operator code $4B
                    lbeq      EmitDstack go emit _dstack
                    cmpx      #$006E    test operator code $6E
                    lbeq      EmitDstackPop go emit _dstack pop
                    cmpx      #$008B    test operator code $8B
                    lbeq      EmitFloatLoad go emit float load
                    cmpx      #$0089    test operator code $89
                    lbeq      EmitFloatMove go emit move
                    cmpx      #$0050    test operator code $50
                    lbeq      EmitDadd  go emit _dadd
                    cmpx      #$0051    test operator code $51
                    lbeq      EmitDsub  go emit _dsub
                    cmpx      #$0052    test operator code $52
                    lbeq      EmitDmul  go emit _dmul
                    cmpx      #$0053    test operator code $53
                    lbeq      EmitDdiv  go emit _ddiv
                    cmpx      #$005A    test operator code $5A
                    lbeq      EmitDcmpr go emit _dcmpr
                    cmpx      #$005B    test operator code $5B
                    lbeq      EmitDcmpr go emit _dcmpr
                    cmpx      #$005E    test operator code $5E
                    lbeq      EmitDcmpr go emit _dcmpr
                    cmpx      #$005C    test operator code $5C
                    lbeq      EmitDcmpr go emit _dcmpr
                    cmpx      #$005F    test operator code $5F
                    lbeq      EmitDcmpr go emit _dcmpr
                    cmpx      #$005D    test operator code $5D
                    lbeq      EmitDcmpr go emit _dcmpr
                    cmpx      #$0043    test operator code $43
                    lbeq      EmitDneg  go emit _dneg
                    cmpx      #$003C    test operator code $3C
                    lbeq      EmitFloatInc go emit float increment
                    cmpx      #$003E    test operator code $3E
                    lbeq      EmitFloatInc go emit float increment
                    cmpx      #$003D    test operator code $3D
                    lbeq      EmitFloatDec go emit float decrement
                    cmpx      #$003F    test operator code $3F
                    lbeq      EmitFloatDec go emit float decrement
                    cmpx      #$008D    test operator code $8D
                    lbeq      EmitDtof  go emit _dtof
                    cmpx      #$008C    test operator code $8C
                    lbeq      EmitFtod  go emit _ftod
                    cmpx      #$0090    test operator code $90
                    lbeq      EmitLtod  go emit _ltod
                    cmpx      #$008E    test operator code $8E
                    lbeq      EmitItod  go emit _itod
                    cmpx      #$0092    test operator code $92
                    lbeq      EmitUtod  go emit _utod
                    cmpx      #$0091    test operator code $91
                    lbeq      EmitDtol  go emit _dtol
                    cmpx      #$008F    compare node op code
                    lbeq      EmitDtoi  branch when op is 0x8f
                    lbra      GenFloatError otherwise continue dispatch

EmptyRet            puls      pc,u      return-only stub

GenSwitchCode       pshs      u,d       save registers on entry
                    leax      OpBsr,pcr point to 'bsr ' string
                    pshs      x         push string argument
                    lbsr      EmitSpaceStr emit 'bsr '
                    leas      2,s        drop the argument
                    ldd       GlbVar000B load the label counter
                    addd      #$0001    advance to next label number
                    std       GlbVar000B store the label counter
                    std       ,s        keep label number local
                    pshs      d         push label number
                    lbsr      EmitLocalLabelLine emit '_<num>' label
                    leas      2,s        drop the argument
                    ldd       $08,s     load first argument
                    pshs      d         push it
                    ldd       $08,s     load second argument
                    pshs      d         push it
                    bsr       EmitCaseTable emit the case table
                    leas      4,s        drop the two arguments
                    ldd       ,s        reload label number
                    pshs      d         push it
                    lbsr      EmitLocalLabel emit '_<num>' symbol
                    leas      2,s        drop the argument
                    leax      OpPulsX,pcr point to 'puls x' string
                    pshs      x         push it
                    lbsr      EmitSpaceStrLine emit 'puls x' line
                    leas      2,s        drop the argument
                    lbra      DropArgRet return via common exit

EmitCaseTable       pshs      u         save u on entry
                    ldu       $04,s     load table pointer argument
                    leas      -2,s       reserve a local
                    lbsr      EmitFdb   compute table setup
                    ldd       $08,s     load the case count
                    cmpd      #$0001    is the count exactly one
                    bne       NotSingleCase no, handle multi/list case
                    pshs      u         push the table pointer
                    lbsr      EmitDecimal emit the single value
CaseTableDone       leas      2,s        drop the argument
                    lbra      EmitTableEnd finish the table

NotSingleCase       cmpu      #$0000    is the table pointer null
                    bne       ListModeInit no, emit value list
                    ldd       #$0001    start fill index at one
                    std       ,s        store the counter
                    bra       ZeroFillCheck enter the fill loop check

ZeroFillLoop        leax      FmtZeroComma,pcr point to '0,' string
                    pshs      x         push it
                    lbsr      EmitString emit '0,'
                    leas      2,s        drop the argument
ZeroFillCheck       ldd       ,s        load the counter
                    addd      #$0001    increment it
                    std       ,s        store it back
                    subd      #$0001    restore the compare value
                    cmpd      $08,s     compare against the count
                    blt       ZeroFillLoop loop while below count
                    ldd       #$0030    '0' terminating character
                    pshs      d         push it
                    lbsr      EmitChar  emit trailing '0'
                    bra       CaseTableDone finish the table

ListModeInit        clra                clear the index high
                    clrb                clear the index low
                    bra       CaseValueNext enter the value loop test

CaseValueLoop       ldd       ,u++      load next table entry
                    pshs      d         push the value
                    lbsr      EmitDecimal emit the number
                    leas      2,s        drop the argument
                    ldd       $08,s     load the count
                    addd      #$FFFF    compute count minus one
                    cmpd      ,s        is this the last entry
                    beq       SkipComma skip comma when last
                    ldd       #$002C    ',' separator character
                    pshs      d         push it
                    lbsr      EmitChar  emit the comma
                    leas      2,s        drop the argument
SkipComma           ldd       ,s        load the index
                    addd      #$0001    increment it
CaseValueNext       std       ,s        store the index
                    ldd       ,s        reload the index
                    cmpd      $08,s     compare against the count
                    blt       CaseValueLoop loop over remaining values
EmitTableEnd        lbsr      EmitNewline emit a newline
                    lbra      DropArgRet return via common exit

GenPushWord         pshs      u         save u on entry
                    ldd       >PushMnemonicPointer,y  load push mnemonic pointer
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    ldd       $04,s     load the operand
                    pshs      d         push it
                    lbsr      EmitSpaceStrLine emit operand and newline
AdjustDepthWord     leas      2,s        drop the argument
                    ldd       GlbVar000D load the stack depth
                    addd      #$0002    grow it by two
                    bra       StoreStackDepth go store the depth

GenPushLong         pshs      u         save u on entry
                    ldd       >PushMnemonicPointer,y  load push mnemonic pointer
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    ldd       $04,s     load the operand
                    pshs      d         push it
                    lbsr      EmitSpaceStrLine emit operand and newline
                    leas      2,s        drop the argument
                    ldd       GlbVar000D load the stack depth
                    addd      #$0004    grow it by four
StoreStackDepth     std       GlbVar000D store the stack depth
                    puls      pc,u      return

GenPushOperand      pshs      u         save u on entry
                    ldd       >PushMnemonicPointer,y  load push mnemonic pointer
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    ldd       $04,s     load the operand
                    pshs      d         push it
                    lbsr      EmitSpaceStrLine emit operand and newline
                    lbra      DropArgRet return via common exit

GenLogicOp          pshs      u         save u on entry
                    ldu       $04,s     load node pointer argument
                    leas      -6,s       reserve locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     clear the size flag
                    ldd       $0C,s     load the op code
                    cmpd      #$0077    is it the deref op 0x77
                    bne       LogicHaveOp no, operand already resolved
                    ldd       [$0e,s]   dereference the operand
                    cmpd      #$0002    is the size two
                    bne       ClearSizeFlag no, clear flag
                    ldd       #$0001    set the size flag
                    bra       StoreSizeFlag go store the flag

ClearSizeFlag       clra                clear high byte
                    clrb                clear low byte
StoreSizeFlag       std       $02,s     store the size flag
                    ldx       $0e,s     load the node pointer
                    ldd       $06,x     load subfield op
                    std       $0C,s     save it as op
                    ldx       $0e,s     reload the node pointer
                    ldd       $08,x     load subfield operand
                    std       $0e,s     save it as operand
LogicHaveOp         leax      ,u        x holds the node pointer
                    bra       DispatchLogicOp dispatch on the op

MnemonicAnd         leax      OpAnd,pcr select 'and' mnemonic
                    bra       StoreMnemonic store the mnemonic

MnemonicOr          leax      OpOr,pcr  select 'or' mnemonic
                    bra       StoreMnemonic store the mnemonic

MnemonicEor         leax      OpEor,pcr select 'eor' mnemonic
StoreMnemonic       stx       $04,s     save mnemonic pointer
                    bra       LogicEmit continue with emission

DispatchLogicOp     cmpx      #$0057    is op the and code
                    beq       MnemonicAnd yes, use 'and'
                    cmpx      #$0058    is op the or code
                    beq       MnemonicOr yes, use 'or'
                    cmpx      #$0059    is op the eor code
                    beq       MnemonicEor yes, use 'eor'
LogicEmit           ldx       $0C,s     load the op code
                    lbra      DispatchLoadOp dispatch operand load

GenLoadHalves       ldd       $02,s     load the size flag
                    beq       GenLoadFull flag clear, full path
                    cmpu      #$0057    is operand in a register
                    bne       LoadEmitMnemonic no, skip register move
                    ldd       >RegisterName,y  load register name
                    pshs      d         push it
                    lbsr      EmitSpaceStrLine emit operand and newline
                    leas      2,s        drop the argument
LoadEmitMnemonic    ldd       $04,s     load the mnemonic
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    bra       GenLoadLowByte continue at low-byte emit

GenLoadFull         ldd       $04,s     load the mnemonic
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero flag argument
                    ldd       $10,s     load an argument
                    pshs      d         push it
                    ldd       $10,s     load an argument
                    pshs      d         push it
                    ldd       #$0061    'a' register operand code
                    pshs      d         push it
                    lbsr      EmitInsnOperand emit the a-half instruction
                    leas      8,s        drop the arguments
                    ldd       $04,s     load the mnemonic
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    ldd       #$0001    set flag one
GenLoadLowByte      pshs      d         push the flag argument
                    ldd       $10,s     load an argument
                    pshs      d         push it
                    ldd       $10,s     load an argument
                    pshs      d         push it
                    ldd       #$0062    'b' register operand code
                    pshs      d         push it
                    lbsr      EmitInsnOperand emit the b-half instruction
                    leas      8,s        drop the arguments
                    lbra      OperandRet return via common exit

GenMaskByte         ldd       $0e,s     load the operand
                    pshs      d         push it
                    ldd       #$0008    byte mask/size eight
                    lbsr      AsrEntry  compute the masked value
                    clra                clear high byte
                    std       ,s        store the result
                    tfr       d,x       move it into x
                    bra       DispatchLowByte dispatch on low byte

EmitLowClr          cmpu      #$0057    is operand a register
                    bne       GenMaskHigh no, done
                    ldd       >RegisterName,y  load register name
                    pshs      d         push it
                    bra       EmitLowLine go emit the line

EmitLowCom          cmpu      #$0057    is operand a register
                    beq       GenMaskHigh yes, done
                    cmpu      #$0059    is it the other register
                    bne       EmitLowMask no, emit masked
                    leax      OpComa,pcr select 'coma' mnemonic
                    pshs      x         push it
EmitLowLine         lbsr      EmitSpaceStrLine emit the line
                    leas      2,s        drop the argument
                    bra       GenMaskHigh done

EmitLowMask         ldd       $04,s     load the mnemonic
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push it
                    ldd       $02,s     load the mask value
                    pshs      d         push it
                    ldd       #$0036    push op code 0x36
                    pshs      d         'a' operand code
                    ldd       #$0061    push it
                    pshs      d         push it
                    lbsr      EmitInsnOperand emit the instruction
                    leas      8,s        drop the arguments
                    bra       GenMaskHigh done

DispatchLowByte     stx       -$02,s    store x as local
                    beq       EmitLowClr zero byte case
                    cmpx      #$00FF    is it all ones
                    beq       EmitLowCom yes, com case
                    bra       EmitLowMask else emit masked

GenMaskHigh         ldd       $0e,s     load the high byte
                    clra                clear the high half
                    std       ,s        store it
                    tfr       d,x       move into x
                    bra       DispatchHighByte dispatch on high byte

EmitHighClr         cmpu      #$0057    is operand a register
                    lbne      OperandRet no, done
                    leax      OpClrb,pcr select 'clrb' mnemonic
                    bra       EmitHighLine go emit line

EmitHighCom         cmpu      #$0057    is operand a register
                    lbeq      OperandRet yes, done
                    cmpu      #$0059    is it the other register
                    bne       EmitHighMask no, emit masked
                    leax      OpComb,pcr select 'comb' mnemonic
EmitHighLine        pshs      x         push the mnemonic
                    lbsr      EmitSpaceStrLine emit the line
                    leas      2,s        drop the argument
                    lbra      OperandRet done

EmitHighMask        ldd       $04,s     load the mnemonic
                    pshs      d         push it
                    lbsr      EmitSpaceStr emit the mnemonic
                    leas      2,s        drop the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push it
                    ldd       $02,s     load the mask value
                    pshs      d         push it
                    ldd       #$0036    push op code 0x36
                    pshs      d         'b' operand code
                    ldd       #$0062    push it
                    pshs      d         push it
                    lbsr      EmitInsnOperand emit the instruction
                    leas      8,s        drop the arguments
                    lbra      OperandRet done

DispatchHighByte    stx       -$02,s    store x as local
                    beq       EmitHighClr zero byte case
                    cmpx      #$00FF    is it all ones
                    beq       EmitHighCom yes, com case
                    bra       EmitHighMask else emit masked

GenStackPop         ldd       $04,s     load the operand
                    pshs      d         push it
                    ldd       $06,s     load an argument
                    pshs      d         push it
                    leax      FmtStackByteOps,pcr ' %sa ,s+' stack-pop format
                    pshs      x         push the format
                    ldd       GlbVar0005 the output file
                    pshs      d         push it
                    lbsr      fprintf   emit the stack-pop instruction
                    leas      8,s        drop the arguments
                    ldd       GlbVar000D load the stack depth
                    addd      #$0002    shrink tracking by two
                    std       GlbVar000D store the stack depth
                    lbra      OperandRet done

CompilerTrouble     leax      MsgCompilerTrouble,pcr 'compiler trouble' message
                    pshs      x         push it
                    lbsr      EmitValueRef report the error
                    lbra      EpilogDropChar return

DispatchLoadOp      cmpx      #$0034    is op 0x34
                    lbeq      GenLoadHalves handle load halves
                    cmpx      #$0094    is op 0x94
                    lbeq      GenLoadHalves handle load halves
                    cmpx      #$0095    is op 0x95
                    lbeq      GenLoadHalves handle load halves
                    cmpx      #$0093    is op 0x93
                    lbeq      GenLoadHalves handle load halves
                    cmpx      #$0036    is op 0x36
                    lbeq      GenMaskByte handle mask byte
                    cmpx      #$006E    is op 0x6e
                    beq       GenStackPop handle stack pop
                    bra       CompilerTrouble else compiler trouble

EmitInsnOperand     pshs      u         save u on entry
                    ldd       $04,s     load the mnemonic char
                    pshs      d         push it
                    lbsr      EmitChar  emit the mnemonic char
                    leas      2,s        drop the argument
                    ldd       #$0020    space character
                    pshs      d         push it
                    lbsr      EmitChar  emit the space
                    leas      2,s        drop the argument
                    ldd       $0a,s     load an operand argument
                    pshs      d         push it
                    ldd       $0a,s     load an argument
                    pshs      d         push it
                    ldd       $0a,s     load an argument
                    pshs      d         push it
                    bsr       EmitAddrMode emit the addressing mode
                    leas      6,s        drop the arguments
                    lbsr      EmitNewline emit a newline
                    puls      pc,u      return

EmitSignedOffset    pshs      u         save u on entry
                    ldu       $04,s     load the value argument
                    stu       -$02,s    save it as local
                    beq       PulsRet   zero value, emit nothing
                    cmpu      #$0000    is the value negative
                    ble       EmitOffsetValue yes, skip the plus sign
                    ldd       #$002B    '+' character
                    pshs      d         push it
                    lbsr      EmitChar  emit the '+'
                    leas      2,s        drop the argument
EmitOffsetValue     pshs      u         push the value
                    lbsr      EmitDecimal emit the number
DropArgRet          leas      2,s        drop the argument
PulsRet             puls      pc,u      return

EmitAddrMode        pshs      u,y,x,d   save registers on entry
                    ldd       $0a,s     load the mode byte
                    anda      #$80      test the indexed bit
                    clrb                clear low byte
                    std       -$02,s    store the flag
                    beq       AddrModeInner not indexed, skip bracket
                    ldd       #$005B    '[' character
                    pshs      d         push it
                    lbsr      EmitChar  emit the '['
                    leas      2,s        drop the argument
AddrModeInner       ldd       $0a,s     reload the mode byte
                    anda      #$7f      strip the indexed bit
                    tfr       d,x       move into x
                    lbra      OperandOpDispatch dispatch on addressing mode

EmitOperandField    ldu       $0C,s     load the node pointer
                    ldd       $06,u     load the field type
                    cmpd      #$0041    is it type 0x41
                    bne       EmitOffsetOperand no, emit offset operand
                    ldd       #$0023    '#' character
                    pshs      d         push it
                    lbsr      EmitChar  emit the '#'
                    leas      2,s        drop the argument
                    ldd       $0e,s     load an argument
                    pshs      d         push it
                    ldd       $0a,u     load a node field
                    pshs      d         push it
                    ldd       #$0077    op code 0x77
                    bra       EmitOperandMode go emit mode

EmitOffsetOperand   ldd       $0e,s     load the base offset
                    addd      $14,u     add the field offset
                    pshs      d         push it
                    ldd       $08,u     load a node field
                    pshs      d         push it
                    ldd       $06,u     load a node field
EmitOperandMode     pshs      d         push it
                    bsr       EmitAddrMode emit the addressing mode
                    leas      6,s        drop the arguments
                    lbra      OperandRet done

EmitImmHash         ldd       #$0023    '#' character
                    pshs      d         push it
                    lbsr      EmitChar  emit the '#'
                    leas      2,s        drop the argument
                    ldd       $0C,s     load the operand
                    lbra      PushConstOffset emit the immediate value

EmitFloatAcc        leax      RtFlacc,pcr '_flacc' float accumulator symbol
                    pshs      x         push it
                    lbsr      EmitString emit '_flacc'
                    leas      2,s        drop the argument
                    ldd       $0e,s     load the offset
                    pshs      d         push it
                    lbsr      EmitSignedOffset emit the signed offset
                    leas      2,s        drop the argument
                    ldd       >GlobalField,y  load a global
                    pshs      d         push it
                    lbsr      EmitString emit the string
                    lbra      OperandDone done

GenDerefNode2       ldd       $0C,s     load the node pointer
                    std       ,s        save it as local
                    lbeq      GenConstOffset null node, done
                    ldd       [,s]      dereference the node
                    std       $02,s     save the value
                    tfr       d,x       move into x
                    lbra      OperandBaseDispatch dispatch on value

LoadNodeFieldX      ldx       ,s        load the node pointer
                    ldd       $04,x     load a node field
                    subd      GlbVar000D subtract the global stack base
                    addd      $0e,s     add the frame displacement argument
                    std       $0C,s     save the computed operand offset
                    pshs      d         push the offset for emission
                    lbsr      EmitDecimal emit the offset as decimal
                    leas      2,s        drop the argument
                    ldd       >SSuffixString,y  load the ',s' suffix string
                    lbra      PushModeSuffix emit the addressing suffix

GenNumLabelBase     ldd       GlbType5Val test the no-prefix global flag
                    bne       EmitLocalLabelRef skip the prefix when flag set
                    ldd       $0a,s     load the operand type flags
                    anda      #$80      isolate the sign bit
                    clrb                clear the low byte
                    std       -$02,s    save the sign test
                    beq       SelectLtPrefix positive selects the '<' prefix
                    ldd       #$003E    load the '>' extended prefix
                    bra       EmitAddrPrefix go emit it

SelectLtPrefix      ldd       #$003C    load the '<' direct prefix
EmitAddrPrefix      pshs      d         push the prefix char
                    lbsr      EmitChar  emit the addressing prefix
                    leas      2,s        drop the char
EmitLocalLabelRef   ldx       ,s        get the node pointer
                    ldd       $04,x     load the local label number
                    pshs      d         push it
                    lbsr      EmitLocalLabel emit the '_<num>' label reference
                    leas      2,s        drop the argument
                    leax      $06,s     point past the frame args
                    bra       RestoreLabelStack restore stack and continue

GenNamedBase        ldd       GlbType5Val test the no-prefix flag
                    bne       EmitSymbolBase skip the prefix when set
                    ldd       $0a,s     load the operand type flags
                    anda      #$80      isolate the sign bit
                    clrb                clear the low byte
                    std       -$02,s    save the sign test
                    beq       SelectLtPrefix2 positive selects the '<' prefix
                    ldd       #$003E    load the '>' extended prefix
                    bra       EmitAddrPrefix2 go emit it

SelectLtPrefix2     ldd       #$003C    load the '<' direct prefix
EmitAddrPrefix2     pshs      d         push the prefix char
                    lbsr      EmitChar  emit the addressing prefix
                    leas      2,s        drop the char
EmitSymbolBase      ldd       ,s        get the node pointer
                    addd      #$0004    point at the symbol name field
                    pshs      d         push the name pointer
                    lbsr      EmitSymbol2 emit the symbol name
                    leas      2,s        drop the argument
                    bra       EmitOffsetAndMode continue with the offset suffix

RestoreLabelStack   leas      -$06,x    restore stack after label path
EmitOffsetAndMode   ldd       $0e,s     load the operand offset
                    pshs      d         push it
                    lbsr      EmitSignedOffset emit the signed offset
                    leas      2,s        drop it
                    ldd       $0a,s     load the operand type flags
                    anda      #$80      isolate the indirect bit
                    clrb                clear the low byte
                    std       -$02,s    save the test
                    bne       CheckPcrMode indirect uses the pcr check
                    ldd       GlbType5Val test the no-prefix flag
                    lbne      OperandEpilog done when flag set
                    ldd       $02,s     load the operand base type
                    cmpd      #$0021    named symbol type?
                    lbeq      OperandEpilog needs no suffix
                    ldd       $02,s     reload the base type
                    cmpd      #$0022    named symbol type?
                    lbeq      OperandEpilog needs no suffix
                    ldd       $02,s     reload the base type
                    cmpd      #$0023    numeric label type?
                    lbeq      OperandEpilog needs no suffix
CheckPcrMode        ldx       ,s        get the node pointer
                    ldd       $02,x     load the addressing attributes
                    clra                clear the high byte
                    andb      #$30      isolate the mode bits
                    cmpd      #$0030    pcr-relative mode?
                    bne       LoadRegSuffix otherwise use register suffix
                    leax      FmtPcr,pcr load the ',pcr' suffix
                    pshs      x         push it
                    bra       EmitModeSuffix emit the suffix

LoadRegSuffix       ldd       >GlobalField,y  load the register-relative suffix
PushModeSuffix      pshs      d         push the suffix string
EmitModeSuffix      lbsr      EmitString emit the addressing suffix
                    lbra      OperandDone operand emission done

StorageErr          leax      MsgStorageError,pcr load the 'storage error' message
                    lbra      EmitDiag  report the diagnostic

OperandBaseDispatch cmpx      #$000D    stack-local base type?
                    lbeq      LoadNodeFieldX emit the stack offset
                    cmpx      #$0023    numeric label reference?
                    lbeq      GenNumLabelBase emit the '_<num>' label
                    cmpx      #$000F    direct label type?
                    lbeq      EmitLocalLabelRef emit the '_<num>' label
                    cmpx      #$0021    named symbol type?
                    lbeq      GenNamedBase emit name with prefix
                    cmpx      #$0022    named symbol type?
                    lbeq      GenNamedBase emit name with prefix
                    cmpx      #$000E    named base type?
                    lbeq      EmitSymbolBase emit the symbol name
                    cmpx      #$000C    named base type?
                    lbeq      EmitSymbolBase emit the symbol name
                    bra       StorageErr unknown storage class

GenConstOffset      ldd       $0e,s     load the constant offset
PushConstOffset     pshs      d         push it
                    lbsr      EmitDecimal emit it as decimal
                    lbra      OperandDone operand emission done

GenIndexed2         ldd       $0C,s     load the base offset
                    addd      $0e,s     add the displacement
                    std       $0C,s     save the combined offset
                    pshs      d         push it
                    lbsr      EmitDecimal emit the decimal offset
                    leas      2,s        drop it
                    ldd       #$002C    load the ',' separator
                    pshs      d         push it
                    lbsr      EmitChar  emit the comma
                    leas      2,s        drop it
                    ldd       $0a,s     load the operator code
                    anda      #$7f      mask off the flag bit
                    tfr       d,x       into x for dispatch
                    bra       IndexRegDispatch select the index register

SelectRegX          ldd       #$0078    load the 'x' register char
                    bra       EmitIndexReg2 emit it

SelectRegY          ldd       #$0079    load the 'y' register char
                    bra       EmitIndexReg2 emit it

SelectRegU          ldd       #$0075    load the 'u' register char
EmitIndexReg2       pshs      d         push the register char
                    lbsr      EmitChar  emit the index register
                    leas      2,s        drop it
                    lbra      OperandEpilog operand emission done

IndexRegDispatch    cmpx      #$0093    indexed on X?
                    beq       SelectRegX emit 'x'
                    cmpx      #$0094    indexed on Y?
                    beq       SelectRegY emit 'y'
                    cmpx      #$0095    indexed on U?
                    beq       SelectRegU emit 'u'
                    bra       OperandEpilog none, just finish

GenStackPush        ldd       >SSuffixString,y  load the ',s' suffix string
                    pshs      d         push it
                    lbsr      EmitString emit it
                    leas      2,s        drop it
                    leax      MsgPlusPlus,pcr load the '++' auto-increment
                    pshs      x         push it
                    lbsr      EmitString emit '++'
                    leas      2,s        drop it
                    ldd       GlbVar000D load the stack depth global
                    addd      #$0002    account for the push
                    std       GlbVar000D update the stack depth
                    bra       OperandEpilog operand emission done

DerefErr            leax      MsgDereference,pcr load the 'dereference' message
EmitDiag            pshs      x         push the message pointer
                    lbsr      EmitValueRef report the diagnostic
OperandDone         leas      2,s        drop the argument
                    bra       OperandEpilog operand emission done

OperandOpDispatch   cmpx      #$0077    indirect through pointer?
                    lbeq      EmitOperandField handle it
                    cmpx      #$0036    immediate constant?
                    lbeq      EmitImmHash handle it
                    cmpx      #$0080    absolute reference?
                    lbeq      EmitFloatAcc handle it
                    cmpx      #$0034    memory reference?
                    lbeq      GenDerefNode2 handle it
                    cmpx      #$0093    indexed on X?
                    lbeq      GenIndexed2 emit indexed operand
                    cmpx      #$0094    indexed on Y?
                    lbeq      GenIndexed2 emit indexed operand
                    cmpx      #$0095    indexed on U?
                    lbeq      GenIndexed2 emit indexed operand
                    cmpx      #$006E    stack push?
                    beq       GenStackPush handle it
                    bra       DerefErr  unknown, report dereference error

OperandEpilog       ldd       $0a,s     load the operand type flags
                    anda      #$80      isolate the indirect bit
                    clrb                clear the low byte
                    std       -$02,s    save the test
                    lbeq      OperandRet not indirect, just return
                    ldd       #$005D    load the ']' close bracket
                    pshs      d         push it
                    lbsr      EmitChar  emit the closing bracket
EpilogDropChar      leas      2,s        drop the char
                    lbra      OperandRet return from operand emitter

CondMnemonic        pshs      u         save the frame pointer
                    ldx       $04,s     load the condition code
                    bra       CondDispatch dispatch on it

CondDefault         leax      MsgRelOp,pcr load the 'rel op' message
                    pshs      x         push it
                    lbsr      EmitValueRef report the diagnostic
                    leas      2,s        drop the argument
CondEq              leax      CcEq,pcr  load the 'eq ' mnemonic
                    bra       CondReturn return it

CondNe              leax      CcNe,pcr  load the 'ne ' mnemonic
                    bra       CondReturn return it

CondLe              leax      CcLe,pcr  load the 'le ' mnemonic
                    bra       CondReturn return it

CondLt              leax      CcLt,pcr  load the 'lt ' mnemonic
                    bra       CondReturn return it

CondGe              leax      CcGe,pcr  load the 'ge ' mnemonic
                    bra       CondReturn return it

CondGt              leax      CcGt,pcr  load the 'gt ' mnemonic
                    bra       CondReturn return it

CondLs              leax      CcLs,pcr  load the 'ls ' mnemonic
                    bra       CondReturn return it

CondLo              leax      CcLo,pcr  load the 'lo ' mnemonic
                    bra       CondReturn return it

CondHs              leax      CcHs,pcr  load the 'hs ' mnemonic
                    bra       CondReturn return it

CondHi              leax      CcHi,pcr  load the 'hi ' mnemonic
CondReturn          tfr       x,d       mnemonic pointer into d
                    puls      pc,u      return it

CondDispatch        cmpx      #$005A    equal condition?
                    beq       CondEq    return 'eq '
                    cmpx      #$005B    not-equal condition?
                    beq       CondNe    return 'ne '
                    cmpx      #$005C    less-or-equal condition?
                    beq       CondLe    return 'le '
                    cmpx      #$005D    less-than condition?
                    beq       CondLt    return 'lt '
                    cmpx      #$005E    greater-or-equal condition?
                    beq       CondGe    return 'ge '
                    cmpx      #$005F    greater-than condition?
                    beq       CondGt    return 'gt '
                    cmpx      #$0060    lower-or-same condition?
                    beq       CondLs    return 'ls '
                    cmpx      #$0061    lower condition?
                    beq       CondLo    return 'lo '
                    cmpx      #$0062    higher-or-same condition?
                    beq       CondHs    return 'hs '
                    cmpx      #$0063    higher condition?
                    beq       CondHi    return 'hi '
                    lbra      CondDefault unknown condition code

                    puls      pc,u      return the mnemonic

EmitSpaceStr        pshs      u         save the frame pointer
                    ldd       GlbVar0005 load the output file
                    pshs      d         push it
                    ldd       #$0020    load a space char
                    pshs      d         push it
                    lbsr      GenOperand3 emit the leading space
                    leas      4,s        drop the args
                    ldd       $04,s     load the string pointer
                    pshs      d         push it
                    bsr       EmitString emit the string
                    lbra      EmitRet2  return

EmitSpaceStrLine    pshs      u         save the frame pointer
                    ldd       $04,s     load the string argument
                    pshs      d         push it
                    bsr       EmitSpaceStr emit space then string
                    lbra      EmitNewlineRet finish with newline

EmitNewline         pshs      u         save the frame pointer
                    ldd       GlbVar0005 load the output file
                    pshs      d         push it
                    ldd       #$000D    load a carriage return
                    bra       EmitCharPush emit it

EmitChar            pshs      u         save the frame pointer
                    ldd       GlbVar0005 load the output file
                    pshs      d         push it
                    ldd       $06,s     load the char argument
EmitCharPush        pshs      d         push the char
                    lbsr      GenOperand3 write it to the file
                    bra       EmitStringRet clean up and return

EmitString          pshs      u         save the frame pointer
                    ldd       $04,s     load the format string
                    pshs      d         push it
                    ldd       GlbVar0005 load the output file
                    pshs      d         push it
                    lbsr      fprintf   print the string
EmitStringRet       leas      4,s        drop the args
                    puls      pc,u      return

EmitDecimal         pshs      u         save the frame pointer
                    ldd       $04,s     load the number
                    pshs      d         push it
                    leax      FmtNum,pcr load the '%d' format
                    lbra      FprintfArg print via fprintf

EmitLocalLabelLine  pshs      u         save the frame pointer
                    ldd       $04,s     load the label number
                    pshs      d         push it
                    bsr       EmitLocalLabel emit the '_<num>' label
                    lbra      EmitNewlineRet finish with newline

EmitLocalLabel      pshs      u         save the frame pointer
                    ldd       #$005F    load the '_' prefix
                    pshs      d         push it
                    bsr       EmitChar  emit the underscore
                    leas      2,s        drop it
                    ldd       $04,s     load the label number
                    pshs      d         push it
                    bsr       EmitDecimal emit it as decimal
                    bra       EmitRet2  return

EmitSymbol2         pshs      u         save the frame pointer
                    ldd       $04,s     load the name pointer
                    pshs      d         push it
                    leax      FmtName8,pcr load the '%.8s' format
                    lbra      FprintfArg print the name

EmitStackAdjust2    pshs      u,d       save frame and value
                    ldd       $06,s     load the target stack depth
                    subd      GlbVar000D subtract the current depth
                    std       ,s        save the difference
                    beq       StackAdjustDone no adjustment needed
                    leax      OpLeas2,pcr load the 'leas ' mnemonic
                    pshs      x         push it
                    lbsr      EmitSpaceStr emit ' leas '
                    leas      2,s        drop it
                    ldd       ,s        load the difference
                    pshs      d         push it
                    lbsr      EmitDecimal emit it as decimal
                    leas      2,s        drop it
                    ldd       >SSuffixString,y  load the ',s' suffix
                    pshs      d         push it
                    lbsr      EmitString emit the suffix
                    leas      2,s        drop it
                    lbsr      EmitNewline emit a newline
StackAdjustDone     ldd       $06,s     return the target depth
EmitRet2            leas      2,s        drop the locals
                    puls      pc,u      return

EmitLabelDef        pshs      u         save the frame pointer
                    ldd       $04,s     load the name pointer
                    pshs      d         push it
                    bsr       EmitSymbol2 emit the symbol name
                    leas      2,s        drop it
                    ldd       $06,s     load the colon flag
                    beq       EmitNewlineTail no colon wanted
                    ldd       #$003A    load a ':' char
                    pshs      d         push it
                    lbsr      EmitChar  emit the colon
EmitNewlineRet      leas      2,s        drop the char
EmitNewlineTail     lbsr      EmitNewline emit a newline
                    puls      pc,u      return

EmitLeaPrefix       pshs      u         save the frame pointer
                    ldd       $04,s     load the register char
                    pshs      d         push it
                    leax      FmtLeaReg,pcr load the ' lea%c ' format
FprintfArg          pshs      x         push the format string
                    ldd       GlbVar0005 load the output file
                    pshs      d         push it
                    lbsr      fprintf   emit via fprintf
OperandRet          leas      6,s        drop the args
                    puls      pc,u      return

EmitLeaPcr          pshs      u         save the frame pointer
                    ldd       $04,s     load the register char
                    pshs      d         push it
                    bsr       EmitLeaPrefix emit ' leaR '
                    leas      2,s        drop it
                    ldd       $06,s     load the label number
                    pshs      d         push it
                    ldd       #$005F    load the '_' prefix
                    pshs      d         push it
                    leax      FmtPcrRef,pcr load the '%c%d,pcr' format
                    pshs      x         push it
                    ldd       GlbVar0005 load the output file
                    pshs      d         push it
                    lbsr      fprintf   emit '_<num>,pcr'
                    leas      8,s        drop the args
                    puls      pc,u      return

                    fcb       $2C,$79
                    fcb       C$NULL
                    fcb       $2C,$73
                    fcb       C$NULL
OpLbsr              fcc       /lbsr /
                    fcb       C$NULL
                    fcc       /lbra /
                    fcb       C$NULL
                    fcc       /clra/
                    fcb       C$NULL
                    fcc       /unknown operator : /
                    fcb       C$NULL
FmtPshs             fcc       / pshs %c/
                    fcb       C$CR,C$NULL
OpLb                fcb       $6C,$62
                    fcb       C$NULL
OpPulsUPc           fcc       /puls u,pc/
                    fcb       C$CR,C$NULL
RtnCcmult           fcc       /ccmult/
                    fcb       C$NULL
RtnCcudiv           fcc       /ccudiv/
                    fcb       C$NULL
RtnCcdiv            fcc       /ccdiv/
                    fcb       C$NULL
RtnCcasl            fcc       /ccasl/
                    fcb       C$NULL
RtnCcasr            fcc       /ccasr/
                    fcb       C$NULL
RtnCclsr            fcc       /cclsr/
                    fcb       C$NULL
RtnCcumod           fcc       /ccumod/
                    fcb       C$NULL
RtnCcmod            fcc       /ccmod/
                    fcb       C$NULL
OpNegD              fcc       /nega/
                    fcb       C$CR
                    fcc       / negb/
                    fcb       C$CR
                    fcc       / sbca #0/
                    fcb       C$NULL
OpComD              fcc       /coma/
                    fcb       C$CR
                    fcc       / comb/
                    fcb       C$NULL
OpLeax              fcc       /leax /
                    fcb       C$NULL
OpLeas              fcc       /leas /
                    fcb       C$NULL
OpCommaX            fcb       $2C,$78
                    fcb       C$CR,C$NULL
OpJsr               fcc       /jsr /
                    fcb       C$NULL
OpSex               fcb       $73,$65,$78
                    fcb       C$NULL
OpLd                fcb       $6C,$64
                    fcb       C$NULL
OpAslbRola          fcc       /aslb/
                    fcb       C$CR
                    fcc       / rola/
                    fcb       C$NULL
OpAsraRorb          fcc       /asra/
                    fcb       C$CR
                    fcc       / rorb/
                    fcb       C$NULL
OpLsraRorb          fcc       /lsra/
                    fcb       C$CR
                    fcc       / rorb/
                    fcb       C$NULL
OpLdy               fcc       /ldy /
                    fcb       C$NULL
OpLdu               fcc       /ldu /
                    fcb       C$NULL
OpLeax2             fcc       /leax /
                    fcb       C$NULL
FmtNumComma         fcc       /%d,%c/
                    fcb       C$CR,C$NULL
FmtDComma           fcc       /d,%c/
                    fcb       C$CR,C$NULL
OpSex2              fcb       $73,$65,$78
                    fcb       C$NULL
OpAdca0             fcc       /adca #0/
                    fcb       C$NULL
OpSbca0             fcc       /sbca #0/
                    fcb       C$NULL
FmtNumComma2        fcc       /%d,%c/
                    fcb       C$CR,C$NULL
OpClraClrb          fcc       /clra/
                    fcb       C$CR
                    fcc       / clrb/
                    fcb       C$NULL
OpLd2               fcb       $6C,$64
                    fcb       C$NULL
FmtStStack          fcc       / st%c -2,s/
                    fcb       C$CR,C$NULL
OpCmp               fcb       $63,$6D,$70
                    fcb       C$NULL
OpSt                fcb       $73,$74
                    fcb       C$NULL
OpSub               fcb       $73,$75,$62
                    fcb       C$NULL
OpAdd               fcb       $61,$64,$64
                    fcb       C$NULL
OpLea               fcb       $6C,$65,$61
                    fcb       C$NULL
FmtExg              fcc       / exg %c,%c/
                    fcb       C$CR,C$NULL
OpDComma            fcb       $64,$2C
                    fcb       C$NULL
MsgLeaArg           fcc       /LEA arg/
                    fcb       C$NULL
FmtTfr              fcc       / tfr %c,%c/
                    fcb       C$CR,C$NULL
OpOrPointer4        fcc       /lda 0,x/
                    fcb       C$CR
                    fcc       / ora 1,x/
                    fcb       C$CR
                    fcc       / ora 2,x/
                    fcb       C$CR
                    fcc       / ora 3,x/
                    fcb       C$NULL
RtLmove             fcc       /_lmove/
                    fcb       C$NULL
RtLadd              fcc       /_ladd/
                    fcb       C$NULL
RtLsub              fcc       /_lsub/
                    fcb       C$NULL
RtLmul              fcc       /_lmul/
                    fcb       C$NULL
RtLdiv              fcc       /_ldiv/
                    fcb       C$NULL
RtLmod              fcc       /_lmod/
                    fcb       C$NULL
RtLand              fcc       /_land/
                    fcb       C$NULL
RtLor               fcc       /_lor/
                    fcb       C$NULL
RtLxor              fcc       /_lxor/
                    fcb       C$NULL
RtLshl              fcc       /_lshl/
                    fcb       C$NULL
RtLshr              fcc       /_lshr/
                    fcb       C$NULL
RtLcmpr             fcc       /_lcmpr/
                    fcb       C$NULL
RtLneg              fcc       /_lneg/
                    fcb       C$NULL
RtLcompl            fcc       /_lcompl/
                    fcb       C$NULL
RtLitol             fcc       /_litol/
                    fcb       C$NULL
RtLutol             fcc       /_lutol/
                    fcb       C$NULL
RtLinc              fcc       /_linc/
                    fcb       C$NULL
RtLdec              fcc       /_ldec/
                    fcb       C$NULL
MsgCodgenLongs      fcc       /codgen - longs/
                    fcb       C$NULL
RtDstack            fcc       /_dstack/
                    fcb       C$NULL
FmtLdaReg           fcc       / lda %c,x/
                    fcb       C$CR,C$NULL
RtFmove             fcc       /_fmove/
                    fcb       C$NULL
RtDmove             fcc       /_dmove/
                    fcb       C$NULL
RtDadd              fcc       /_dadd/
                    fcb       C$NULL
RtDsub              fcc       /_dsub/
                    fcb       C$NULL
RtDmul              fcc       /_dmul/
                    fcb       C$NULL
RtDdiv              fcc       /_ddiv/
                    fcb       C$NULL
RtDcmpr             fcc       /_dcmpr/
                    fcb       C$NULL
RtDneg              fcc       /_dneg/
                    fcb       C$NULL
RtFinc              fcc       /_finc/
                    fcb       C$NULL
RtDinc              fcc       /_dinc/
                    fcb       C$NULL
RtFdec              fcc       /_fdec/
                    fcb       C$NULL
RtDdec              fcc       /_ddec/
                    fcb       C$NULL
RtDtof              fcc       /_dtof/
                    fcb       C$NULL
RtFtod              fcc       /_ftod/
                    fcb       C$NULL
RtLtod              fcc       /_ltod/
                    fcb       C$NULL
RtItod              fcc       /_itod/
                    fcb       C$NULL
RtUtod              fcc       /_utod/
                    fcb       C$NULL
RtDtol              fcc       /_dtol/
                    fcb       C$NULL
RtDtoi              fcc       /_dtoi/
                    fcb       C$NULL
MsgCodgenFloats     fcc       /codgen - floats/
                    fcb       C$NULL
OpBsr               fcc       /bsr /
                    fcb       C$NULL
OpPulsX             fcc       /puls x/
                    fcb       C$NULL
FmtZeroComma        fcb       $30,$2C
                    fcb       C$NULL
OpAnd               fcb       $61,$6E,$64
                    fcb       C$NULL
OpOr                fcb       $6F,$72
                    fcb       C$NULL
OpEor               fcb       $65,$6F,$72
                    fcb       C$NULL
OpComa              fcc       /coma/
                    fcb       C$NULL
OpClrb              fcc       /clrb/
                    fcb       C$NULL
OpComb              fcc       /comb/
                    fcb       C$NULL
FmtStackByteOps     fcc       / %sa ,s+/
                    fcb       C$CR
                    fcc       / %sb ,s+/
                    fcb       C$CR,C$NULL
MsgCompilerTrouble  fcc       /compiler trouble/
                    fcb       C$NULL
RtFlacc             fcc       /_flacc/
                    fcb       C$NULL
FmtPcr              fcc       /,pcr/
                    fcb       C$NULL
MsgStorageError     fcc       /storage error/
                    fcb       C$NULL
MsgPlusPlus         fcb       $2B,$2B
                    fcb       C$NULL
MsgDereference      fcc       /dereference/
                    fcb       C$NULL
MsgRelOp            fcc       /rel op/
                    fcb       C$NULL
CcEq                fcb       $65,$71,$20
                    fcb       C$NULL
CcNe                fcb       $6E,$65,$20
                    fcb       C$NULL
CcLe                fcb       $6C,$65,$20
                    fcb       C$NULL
CcLt                fcb       $6C,$74,$20
                    fcb       C$NULL
CcGe                fcb       $67,$65,$20
                    fcb       C$NULL
CcGt                fcb       $67,$74,$20
                    fcb       C$NULL
CcLs                fcb       $6C,$73,$20
                    fcb       C$NULL
CcLo                fcb       $6C,$6F,$20
                    fcb       C$NULL
CcHs                fcb       $68,$73,$20
                    fcb       C$NULL
CcHi                fcb       $68,$69,$20
                    fcb       C$NULL
FmtNum              fcb       $25,$64
                    fcb       C$NULL
FmtName8            fcc       /%.8s/
                    fcb       C$NULL
OpLeas2             fcc       /leas /
                    fcb       C$NULL
FmtLeaReg           fcc       / lea%c /
                    fcb       C$NULL
FmtPcrRef           fcc       /%c%d,pcr/
                    fcb       C$CR,C$NULL
EmitValueRef        pshs      u         save the frame pointer
                    ldd       $04,s     load the caller argument
                    pshs      d         push as first argument
                    ldd       Label,y   load the global work pointer
                    pshs      d         push as second argument
                    bsr       BuildLabelText build the label text
                    lbra      FreeCleanup tail return through teardown

EmitNodeRef         pshs      u         save the frame pointer
                    leax      MsgOutOfMemory,pcr point at the format string
                    pshs      x         push string argument
                    ldd       Label,y   load the global work pointer
                    pshs      d         push the node argument
                    bsr       EmitNodeFields emit the node fields
                    leas      4,s        drop the two arguments
                    lbsr      FatalExit flush the output line
                    puls      pc,u      restore and return

BuildLabelText      pshs      u         save the frame pointer
                    leas      -50,s      reserve local buffer
                    leax      MsgCompilerError,pcr point at the format string
                    pshs      x         push format argument
                    leax      $02,s     point at local buffer
                    pshs      x         push buffer destination
                    lbsr      StrCopy   format into the buffer
                    leas      4,s        drop the arguments
                    ldd       $38,s     load the caller value
                    pshs      d         push it
                    leax      $02,s     point at the buffer
                    pshs      x         push the buffer
                    lbsr      StrCat    append the formatted value
                    leas      4,s        drop the arguments
                    leax      ,s        point at buffer start
                    pshs      x         push the buffer pointer
                    ldd       $38,s     load the caller node
                    pshs      d         push the node
                    bsr       EmitNodeFields emit the node fields
                    leas      4,s        drop the arguments
                    leas      50,s       release the local buffer
                    puls      pc,u      restore and return

EmitNodeFields      pshs      u         save the frame pointer
                    ldu       $04,s     load the tree node pointer
                    ldd       $0e,u     load a node field
                    pshs      d         push it
                    ldd       $08,s     reload the string argument
                    pshs      d         push it
                    ldd       $10,u     load the node type field
                    pshs      d         push it
                    lbsr      EmitLabelRef emit the code line
                    lbra      CopyNodeDone tail return through teardown

RingAdvance         pshs      u         save the frame pointer
                    ldd       HeadIndex,y   load the ring head index
                    addd      #$0001    advance to the next slot
                    pshs      d         push dividend
                    ldd       #$000A    ring size ten
                    lbsr      DivSignedSetup wrap index modulo ring size
                    std       HeadIndex,y   store the wrapped index
                    cmpd      TailIndex,y   compare with the tail index
                    bne       RingStore skip if no collision
                    ldd       TailIndex,y   load the tail index
                    addd      #$0001    advance the tail
                    pshs      d         push dividend
                    ldd       #$000A    ring size ten
                    lbsr      DivSignedSetup wrap tail modulo ring size
                    std       TailIndex,y   store the wrapped tail
RingStore           ldd       HeadIndex,y   load the head index
                    pshs      d         push the index
                    ldd       #$0006    entry size six
                    lbsr      MulEntry  multiply to a byte offset
                    leax      RingTableBase,y   point at ring table base
                    leax      d,x       index to the slot
                    leau      ,x        keep the slot pointer
                    ldd       $04,s     load the caller value
                    std       ,u        store value in the slot
                    leax      $02,u     point past the value field
                    pshs      x         push destination
                    leax      $08,s     point at the caller name
                    lbsr      StoreLong copy name into the slot
                    puls      pc,u      restore and return

RingLookup          pshs      u,d       save frame and search key
                    ldd       HeadIndex,y   load the head index
                    bra       RingSetIndex enter scan at store

RingLookupLoop      ldd       ,s        load the current index
                    pshs      d         push the index
                    ldd       #$0006    entry size six
                    lbsr      MulEntry  multiply to a byte offset
                    leax      RingTableBase,y   point at ring table base
                    leax      d,x       index to the slot
                    leau      ,x        keep the slot pointer
                    ldd       ,u        load the slot value
                    cmpd      $06,s     compare with the search key
                    bne       RingStepBack try previous slot if different
                    leax      $02,u     point at the matched name
                    bra       RingReturn return the matched entry

RingStepBack        ldd       ,s        load the current index
                    addd      #$FFFF    step the index backward
                    std       ,s        save the stepped index
                    bge       RingCheckTail keep if still non negative
                    ldd       #$0009    wrap to the top slot
RingSetIndex        std       ,s        store the index
RingCheckTail       ldd       ,s        reload the index
                    cmpd      TailIndex,y   compare with the tail index
                    bne       RingLookupLoop keep scanning until tail
                    bsr       RingSentinel grab the sentinel pointer
                    fcb       $FF,$FF,$FF,$FF
RingSentinel        puls      x         pop pointer to the sentinel
RingReturn          leau      TempBuffer,y   point at the result buffer
                    pshs      u         push destination
                    lbsr      StoreLong copy name into the result
                    lbra      FreeTreeDone tail return through teardown

EmitLabelRef        pshs      u         save the frame pointer
                    leas      -5,s       reserve local scratch
                    leax      FilenameBuffer,y   point at the name buffer
                    pshs      x         push source pointer
                    leax      FmtNameColon,pcr point at the format string
                    pshs      x         push format
                    lbsr      Printf    format into the buffer
                    leas      4,s        drop the arguments
                    ldd       $09,s     load the caller value
                    pshs      d         push it
                    ldd       $0f,s     load the caller field
                    pshs      d         push it
                    leax      FmtLineNum,pcr point at the format string
                    pshs      x         push format
                    lbsr      Printf    append formatted text
                    leas      6,s        drop the arguments
                    ldd       $0b,s     load the caller value
                    pshs      d         push it
                    leax      FmtBanner,pcr point at the format string
                    pshs      x         push format
                    lbsr      Printf    append formatted text
                    leas      4,s        drop the arguments
                    ldd       LabelId,y   load the current label id
                    bne       LabelExists reuse if already assigned
                    leax      StrModeR,pcr point at the label prefix
                    pshs      x         push prefix
                    ldd       OutputNameAlready,y   load the next label counter
                    pshs      d         push counter
                    lbsr      CompareOperands allocate a new label
                    leas      4,s        drop the arguments
                    std       LabelId,y   save the label id
                    beq       LabelSame skip body if none
LabelExists         leax      $01,s     point at the scratch byte
                    pshs      x         push destination
                    ldd       $0f,s     load the caller key
                    pshs      d         push key
                    lbsr      RingLookup look up label in the ring
                    leas      2,s        drop the argument
                    lbsr      StoreLong copy the name string
                    ldd       $02,x     load the high word
                    pshs      d         push it
                    ldd       ,x        load the low word
                    pshs      d         push it
                    bsr       NameSentinel grab the compare pointer
                    fcb       $FF,$FF,$FF,$FF
NameSentinel        puls      x         pop pointer to the sentinel
                    lbsr      IntCmp32  compare the two names
                    bne       LabelNew  differ so emit new label
LabelSame           leax      $05,s     point past the scratch
                    lbra      RestoreStack2 join the counter update

LabelNew            clra                clear the high byte
                    clrb                clear the low byte
                    pshs      d         push a zero terminator
                    leax      $03,s     point at the name buffer
                    ldd       $02,x     load the high word
                    pshs      d         push it
                    ldd       ,x        load the low word
                    pshs      d         push it
                    ldd       LabelId,y   load the label id
                    pshs      d         push it
                    lbsr      PlaceOperand register the new label
                    leas      8,s        drop the arguments
EmitLabelLoop       leax      Stdout,y  point at the output buffer
                    pshs      x         push buffer
                    ldd       LabelId,y   load the label id
                    pshs      d         push id
                    lbsr      FetchByte fetch the next label char
                    leas      2,s        drop the argument
                    stb       $02,s     store the returned char
                    sex                 sign extend to a word
                    pshs      d         push char
                    lbsr      GenOperand3 emit char to the buffer
                    leas      4,s        drop the arguments
                    ldb       ,s        reload the emitted char
                    cmpb      #C$CR      check for carriage return
                    bne       EmitLabelLoop keep emitting until return
                    bra       PadCheck  enter the caret pad loop

EmitPadLoop         leax      Stdout,y  point at the output buffer
                    pshs      x         push buffer
                    ldd       #$0020    space character
                    pshs      d         push space
                    lbsr      GenOperand3 emit a leading space
                    leas      4,s        drop the arguments
PadCheck            ldd       $09,s     load the column counter
                    addd      #$FFFF    decrement the counter
                    std       $09,s     save the counter
                    subd      #$FFFF    test if still positive
                    bgt       EmitPadLoop keep padding spaces
                    leax      Stdout,y  point at the output buffer
                    pshs      x         push buffer
                    ldd       #$005E    caret character
                    pshs      d         push caret
                    lbsr      GenOperand3 emit the caret
                    leas      4,s        drop the arguments
                    leax      Stdout,y  point at the output buffer
                    pshs      x         push buffer
                    ldd       #$000D    carriage return
                    pshs      d         push return
                    lbsr      GenOperand3 emit the line terminator
                    leas      4,s        drop the arguments
                    bra       BumpErrorCount join the counter update

RestoreStack2       leas      -$05,x    balance the stack pointer
BumpErrorCount      ldd       GlbVar0009 load the error counter
                    addd      #$0001    bump the error count
                    std       GlbVar0009 save the error count
                    cmpd      #_start   compare with the error limit
                    ble       ErrorCountOk continue if under limit
                    leax      Stdout,y  point at the output buffer
                    pshs      x         push buffer
                    lbsr      SpillOperand flush the output
                    leas      2,s        drop the argument
                    leax      MsgTooManyErrors,pcr point at the abort message
                    pshs      x         push message
                    leax      Stderr,y  point at the stderr stream
                    pshs      x         push stream
                    lbsr      fprintf   print the abort message
                    leas      4,s        drop the arguments
                    ldd       #$0001    exit status one
                    pshs      d         push status
                    lbsr      exit      abort compilation
                    leas      2,s        drop the argument
ErrorCountOk        leas      5,s        release the local scratch
                    puls      pc,u      restore and return

WalkTreeChildren    pshs      u         save the frame pointer
                    ldu       $04,s     load the tree node pointer
                    stu       -$02,s    stash node and test for null
                    beq       FreeTreeRet stop at a leaf
                    ldd       $0a,u     load the left child pointer
                    pshs      d         push child
                    bsr       WalkTreeChildren recurse into left child
                    leas      2,s        drop the argument
                    ldd       $0C,u     load the right child pointer
                    pshs      d         push child
                    lbsr      WalkTreeChildren emit code for this node
                    leas      2,s        drop the pushed argument
                    pshs      u         pass the node pointer
                    bsr       FreeNode  free the node structure
FreeTreeDone        leas      2,s        drop the argument
FreeTreeRet         puls      pc,u      restore and return

FreeNode            pshs      u         save u for the free routine
                    ldu       $04,s     load the node pointer
                    stu       -$02,s    test the pointer
                    beq       FreeRet   nothing to free if null
                    ldx       $06,u     get the node type
                    bra       FreeTypeSwitch select the sub-block size

FreeSize13          ldd       #$000D    sub-block is 13 bytes
                    bra       FreeSubBlock free the sub-block

FreeSize8           ldd       #$0008    sub-block is 8 bytes
                    bra       FreeSubBlock free the sub-block

FreeSize4           ldd       #$0004    sub-block is 4 bytes
FreeSubBlock        pshs      d         push the block size
                    ldd       $08,u     load the sub-block pointer
                    pshs      d         push the pointer
                    lbsr      InsertFreeBlock free the sub-block
                    leas      4,s        clean up the arguments
                    bra       FreeNodeSelf now free the node itself

FreeTypeSwitch      cmpx      #$0034    node type 0x34
                    beq       FreeSize13 free a 13-byte sub-block
                    cmpx      #$004B    node type 0x4b
                    beq       FreeSize8 free an 8-byte sub-block
                    cmpx      #$004A    node type 0x4a
                    beq       FreeSize4 free a 4-byte sub-block
FreeNodeSelf        ldd       #$0016    node is 22 bytes
                    pshs      d         push the node size
                    pshs      u         push the node pointer
                    lbsr      InsertFreeBlock free the node
FreeCleanup         leas      4,s        clean up arguments
FreeRet             puls      pc,u      restore and return

CopyNode            pshs      u         save u
                    ldd       #$0016    copy 22 bytes
                    pshs      d         push the count
                    ldd       $08,s     load the destination
                    pshs      d         push destination
                    ldd       $08,s     load the source
                    pshs      d         push source
                    bsr       CopyBytes2 copy the node
CopyNodeDone        leas      6,s        clean up arguments
                    puls      pc,u      restore and return

                    pshs      u         save u
                    ldd       $04,s     load the first value
                    asra                shift right one nibble
                    rorb                shift right one nibble
                    asra                shift right one nibble
                    rorb                shift right one nibble
                    andb      #$F0      keep the high nibble
                    pshs      d         hold the high nibble
                    ldd       $06,s     load the second value
                    clra                clear the high byte
                    andb      #$0f      keep the low nibble
                    addd      ,s++      combine the two nibbles
                    puls      pc,u      restore and return

IsOpInRange         pshs      u         save u
                    ldu       $04,s     load the value to test
                    cmpu      #$004C    below 0x4c
                    blt       RangeFalse out of range
                    cmpu      #$0063    above 0x63
                    bgt       RangeFalse out of range
                    ldd       #$0001    in range returns true
                    bra       RangeRet  return the result

RangeFalse          clra                return false
                    clrb                return false
RangeRet            puls      pc,u      restore and return

CopyBytes2          pshs      u         save u
                    ldu       $04,s     load the source pointer
                    bra       CopyTest  start the copy loop

CopyLoop            ldb       ,u+       read a source byte
                    ldx       $06,s     load the destination pointer
                    leax      $01,x     advance destination
                    stx       $06,s     save destination
                    stb       -$01,x    store the byte
CopyTest            ldd       $08,s     load the remaining count
                    addd      #$FFFF    decrement the count
                    std       $08,s     save the count
                    subd      #$FFFF    test for zero
                    bne       CopyLoop  copy more bytes
                    puls      pc,u      restore and return

MsgOutOfMemory      fcc       /out of memory/
                    fcb       C$NULL
MsgCompilerError    fcc       /compiler error - /
                    fcb       C$NULL
FmtNameColon        fcc       /%s: /
                    fcb       C$NULL
FmtLineNum          fcc       /line %d  /
                    fcb       C$NULL
FmtBanner           fcc       /****  %s  ****/
                    fcb       C$CR,C$NULL
StrModeR            fcb       $72
                    fcb       C$NULL
MsgTooManyErrors    fcc       /too many errors - ABORT/
                    fcb       C$CR,C$NULL
EmitFdb             pshs      u         save u
                    leax      OpFdb,pcr point at the fdb mnemonic
                    pshs      x         push the string
                    lbsr      EmitSpaceStr emit the fdb mnemonic
                    lbra      EmitDone  clean up and return

EmitFuncProlog      pshs      u         save u
                    ldu       $04,s     load the function name pointer
                    pshs      u         push the name
                    leax      FmtTtl,pcr point at the ttl format
                    pshs      x         push the format
                    ldd       GlbVar0005 load the output handle
                    pshs      d         push the handle
                    lbsr      fprintf   emit the ttl directive
                    leas      6,s        clean up arguments
                    ldd       $06,s     load the second argument
                    pshs      d         push it
                    pshs      u         push the name
                    lbsr      EmitLabelDef record the function symbol
                    leas      4,s        clean up arguments
                    clra                clear the frame globals
                    clrb                clear the frame globals
                    std       GlbVar000D reset argument size
                    std       GlbVar000F reset local size
                    std       GlbMaxCaseVal reset the frame counter
                    leax      OpPshsU,pcr point at the entry save
                    pshs      x         push the string
                    lbsr      EmitSpaceStrLine emit pshs u
                    leas      2,s        clean up argument
                    ldd       GlbVar0011 check the no-stackcheck flag
                    bne       PrologProfCheck skip stack check if set
                    ldd       $08,s     load the frame size symbol
                    std       GlbVar0025 remember the frame symbol
                    pshs      d         push it
                    leax      FmtStkCheck,pcr point at the stkcheck code
                    pshs      x         push the format
                    ldd       GlbVar0005 load the output handle
                    pshs      d         push the handle
                    lbsr      fprintf   emit the stack check call
                    leas      6,s        clean up arguments
PrologProfCheck     ldd       GlbVar0013 check the profiling flag
                    lbeq      EmitRet   skip profiling if off
                    leax      OpLeax3,pcr point at the leax mnemonic
                    pshs      x         push the string
                    lbsr      EmitSpaceStr emit the leax
                    leas      2,s        clean up argument
                    ldd       $0a,s     load the profile counter
                    pshs      d         push it
                    lbsr      EmitLocalLabel emit its number
                    leas      2,s        clean up argument
                    leax      FragPcrPshs,pcr point at the pcr fragment
                    pshs      x         push the fragment
                    lbsr      EmitString emit the fragment
                    leas      2,s        clean up argument
                    pshs      u         push the function name
                    lbsr      EmitSymbol2 emit the name
                    leas      2,s        clean up argument
                    leax      FragProfCall,pcr point at the prof call
                    pshs      x         push the fragment
                    lbsr      EmitString emit the profiling call
                    lbra      EmitDone  clean up and return

EmitFrameEqu        pshs      u         save u
                    ldd       GlbVar0011 check the no-stackcheck flag
                    bne       FrameEquRet skip if set
                    ldd       GlbMaxCaseVal load the frame counter
                    subd      GlbVar000F subtract the local size
                    addd      #$FFC0    bias the frame size
                    pshs      d         push the frame size
                    ldd       GlbVar0025 load the frame symbol
                    pshs      d         push it
                    leax      FmtFrameEqu,pcr point at the equ format
                    pshs      x         push the format
                    ldd       GlbVar0005 load the output handle
                    pshs      d         push the handle
                    lbsr      fprintf   emit the frame-size equate
                    leas      8,s        clean up arguments
FrameEquRet         puls      pc,u      restore and return

EmitVsect           pshs      u         save u
                    ldd       $04,s     load the dp flag
                    beq       VsectPlain plain vsect if zero
                    leax      OpVsectDp,pcr point at vsect dp
                    bra       VsectEmit emit the directive

VsectPlain          leax      OpVsect,pcr point at vsect
VsectEmit           tfr       x,d       move the string pointer
                    pshs      d         push it
                    bra       SectEmit  emit the directive

EmitEndsect         pshs      u         save u
                    leax      OpEndsect,pcr point at endsect
                    pshs      x         push it
SectEmit            lbsr      EmitSpaceStrLine emit the section directive
                    bra       EmitDone  clean up and return

EmitLiterals        pshs      u,d       save registers
                    ldd       GlbVar0003 load the string list head
                    pshs      d         push it
                    lbsr      FetchWord get the first entry
                    std       ,s        save the current entry
                    lbsr      EmitLocalLabel emit its label number
                    bra       LitNext   enter the loop

LitLoop             ldd       ,s        load the current character
                    pshs      d         push it
                    bsr       EmitStrChar emit the character
LitNext             leas      2,s        drop the pushed value
                    ldd       GlbVar0003 load the string list head
                    pshs      d         push it
                    lbsr      FetchByte get the next entry
                    leas      2,s        clean up argument
                    std       ,s        save the entry
                    bne       LitLoop   loop while entries remain
                    clra                terminate with a null
                    clrb                terminate with a null
                    pshs      d         push the null
                    bsr       EmitStrChar flush the closing quote
                    leas      2,s        clean up argument
EmitDone            leas      2,s        drop the saved value
EmitRet             puls      pc,u      restore and return

EmitStrChar         pshs      u         save u
                    ldd       ColumnCounter,y   load the column counter
                    bne       StrCharCheck continue current line if open
                    leax      OpFccOpen,pcr point at the fcc open
                    pshs      x         push it
                    ldd       GlbVar0005 load the output handle
                    pshs      d         push the handle
                    lbsr      fprintf   open a new fcc line
                    leas      4,s        clean up arguments
StrCharCheck        ldd       $04,s     load the character
                    cmpd      #$0020    below a space
                    blt       StrCharHex emit as hex byte
                    ldd       $04,s     reload the character
                    cmpd      #$0022    is it a quote
                    bne       StrCharPrint otherwise emit literally
StrCharHex          ldd       $04,s     load the character
                    pshs      d         push it
                    leax      FmtFcbHex,pcr point at the fcb hex format
                    pshs      x         push the format
                    ldd       GlbVar0005 load the output handle
                    pshs      d         push the handle
                    lbsr      fprintf   emit close quote and hex byte
                    leas      6,s        clean up arguments
                    bra       StrCharReset reset the column

StrCharPrint        ldd       GlbVar0005 push it
                    pshs      d         load the character
                    ldd       $06,s     push it
                    pshs      d         write the character directly
                    lbsr      GenOperand3 clean up arguments
                    leas      4,s        load the column counter
                    ldd       ColumnCounter,y   advance the column
                    addd      #$0001    save the column
                    std       ColumnCounter,y   test the previous value
                    subd      #$0001    line is under 75 chars
                    cmpd      #$004B    keep filling the line
                    blt       StrCharRet point at the closing quote
                    leax      StrQuoteEol,pcr push it
                    pshs      x         load the output handle
                    ldd       GlbVar0005 push the handle
                    pshs      d         close the fcc line
                    lbsr      fprintf   clean up arguments
                    leas      4,s
StrCharReset        clra                reset the column counter
                    clrb                reset the column counter
                    std       ColumnCounter,y   save the column counter
StrCharRet          puls      pc,u      restore and return

OpFdb               fcc       /fdb /
                    fcb       C$NULL
FmtTtl              fcc       / ttl %.8s/
                    fcb       C$CR,C$NULL
OpPshsU             fcc       /pshs u/
                    fcb       C$NULL
FmtStkCheck         fcc       / ldd #_%d/
                    fcb       C$CR
                    fcc       / lbsr _stkcheck/
                    fcb       C$CR,C$NULL
OpLeax3             fcc       /leax /
                    fcb       C$NULL
FragPcrPshs         fcc       /,pcr/
                    fcb       C$CR
                    fcc       / pshs x/
                    fcb       C$CR
                    fcc       / leax /
                    fcb       C$NULL
FragProfCall        fcc       /,pcr/
                    fcb       C$CR
                    fcc       / pshs x/
                    fcb       C$CR
                    fcc       / lbsr _prof/
                    fcb       C$CR
                    fcc       / leas 4,s/
                    fcb       C$CR,C$NULL
FmtFrameEqu         fcc       /_%d equ %d/
                    fcb       C$CR,C$CR,C$NULL
OpVsectDp           fcc       /vsect dp/
                    fcb       C$NULL
OpVsect             fcc       /vsect/
                    fcb       C$NULL
OpEndsect           fcc       /endsect/
                    fcb       C$NULL
OpFccOpen           fcc       / fcc "/
                    fcb       C$NULL
FmtFcbHex           fcb       $22
                    fcb       C$CR
                    fcc       / fcb $%x/
                    fcb       C$CR,C$NULL
StrQuoteEol         fcb       $22
                    fcb       C$CR,C$NULL
AllocSlot           pshs      u         save u
                    leau      Stdin,y   point at the slot table
SlotScanLoop        ldd       $06,u     load the slot flags
                    clra                isolate the low byte
                    andb      #$03      check the in-use bits
                    lbeq      SlotRet   return this free slot
                    leau      $0d,u     advance to next slot
                    pshs      u         push the slot pointer
                    leax      PastTableEnd,y   point past the table end
                    cmpx      ,s++      still within the table
                    bhi       SlotScanLoop scan the next slot
                    ldd       #$00C8    flag out of slots
                    std       ErrorCode,y   set the error code
                    lbra      SlotNull  return null

                    puls      pc,u      restore and return

SetupSlot           pshs      u         save u
                    ldu       $08,s     load the given slot
                    bne       SlotInit  use it if supplied
                    bsr       AllocSlot allocate a free slot
                    tfr       d,u       move it into u
SlotInit            stu       -$02,s    test the slot pointer
                    beq       SlotNull  return null if none
                    ldd       $04,s     load the value argument
                    std       $08,u     store it in the slot
                    ldx       $06,s     load the operand string
                    ldb       $01,x     read the second character
                    cmpb      #$2b      is it a plus
                    beq       SlotFlagAuto mark as auto-increment
                    ldx       $06,s     reload the string
                    ldb       $02,x     read the third character
                    cmpb      #$2b      is it a plus
                    bne       SlotFlagReg otherwise classify by register
SlotFlagAuto        ldd       $06,u     load the slot flags
                    orb       #$03      set auto-increment bits
                    bra       SlotStore store the flags

SlotFlagReg         ldd       $06,u     load the slot flags
                    pshs      d         hold the flags
                    ldb       [$08,s]   read the register letter
                    cmpb      #$72      is it r
                    beq       SlotTypeOne register type one
                    ldb       [$08,s]   reload the letter
                    cmpb      #$64      is it d
                    bne       SlotTypeTwo otherwise type two
SlotTypeOne         ldd       #$0001    register type one
                    bra       SlotFlagMerge merge the flags

SlotTypeTwo         ldd       #$0002    register type two
SlotFlagMerge       ora       ,s+       merge with the flags
                    orb       ,s+       merge with the flags
SlotStore           std       $06,u     store the slot flags
                    ldd       $02,u     load the base value
                    addd      $0b,u     add the offset
                    std       $04,u     store the effective value
                    std       ,u        and the current value
SlotRet             tfr       u,d       return the slot pointer
                    puls      pc,u      restore and return

SlotNull            clra                return null
                    clrb                return null
                    puls      pc,u      restore and return

GenOperand2         pshs      u         save u
                    ldu       $04,s     load the target operand
                    leas      -4,s       reserve two locals
                    clra                clear the mode local
                    clrb                clear the mode local
                    std       ,s        store the cleared mode
                    ldx       $0a,s     load the operand string
                    ldb       $01,x     read the second character
                    sex                 sign extend it
                    tfr       d,x       into x for dispatch
                    bra       OperClassLoop classify the character

OperIndexX          ldx       $0a,s     reload the operand string
                    ldb       $02,x     read the third character
                    cmpb      #$2b      is it a plus
                    bne       OperIndexed otherwise indexed
                    ldd       #$0007    auto-increment mode
                    bra       OperSetMode store the mode

OperIndexed         ldd       #$0004    indexed x mode
                    bra       OperSetMode store the mode

OperAutoInc         ldd       #$0003    auto-increment plus mode
OperSetMode         std       ,s        save the mode
                    bra       OperReadReg read the operand register

OperUnknown         leax      $04,s     drop the locals
                    lbra      AddrRestoreStack handle default operand

OperClassLoop       stx       -$02,s    test the character
                    beq       OperReadReg no addressing char
                    cmpx      #$0078    is it x
                    beq       OperIndexX handle indexed x
                    cmpx      #$002B    is it a plus
                    beq       OperAutoInc handle auto-increment
                    bra       OperUnknown unknown addressing

OperReadReg         ldb       [$0a,s]   read the register letter
                    sex                 sign extend it
                    tfr       d,x       into x for dispatch
                    lbra      AddrModeDispatch dispatch on the register

OperModeReg         ldd       ,s        load the mode
                    orb       #$01      set the register bit
                    bra       OperEmit  emit the operand

OperModeSlot        ldd       ,s        load the mode
                    orb       #$02      set the second flag
                    pshs      d         hold the mode
                    pshs      u         push the operand
                    lbsr      OpenPath  look up the register slot
                    leas      4,s        clean up arguments
                    std       $02,s     save the slot result
                    cmpd      #$FFFF    was it found
                    beq       OperModeAlt fall back if not
                    ldd       #$0002    argument count two
                    pshs      d         push it
                    clra                push null arguments
                    clrb                push null arguments
                    pshs      d         push the null
                    pshs      d         push the null
                    ldd       $08,s     load the operand
                    pshs      d         push it
                    lbsr      SeekPath  generate the reference
                    leas      8,s        clean up arguments
                    bra       AddrLoadResult operand done

OperModeAlt         ldd       ,s        load the mode
                    orb       #$02      set the second flag
                    pshs      d         push the mode
                    pshs      u         push the operand
                    lbsr      CreateFile look up alternate slot
                    bra       AddrSaveResult continue

OperModeDir         ldd       ,s        load the mode
                    orb       #$81      set direct and register bits
OperEmit            pshs      d         push the mode
                    pshs      u         push the operand
                    lbsr      OpenPath  call operand emitter for this mode
AddrSaveResult      leas      4,s        drop pushed operand arguments
                    std       $02,s     save returned operand pointer
                    bra       AddrLoadResult go to finish

AddrRestoreStack    leas      -$04,x    restore stack pointer after adjustment
AddrBadMode         ldd       #$00CB    load unknown-mode error code
                    std       ErrorCode,y   store error into work area
                    clra                zero result high byte
                    clrb                zero result low byte
                    bra       AddrReturn2 return with error

AddrModeDispatch    cmpx      #$0072    operand letter is 'r'
                    lbeq      OperModeReg handle register operand
                    cmpx      #$0061    operand letter is 'a'
                    lbeq      OperModeSlot handle address operand
                    cmpx      #$0077    operand letter is 'w'
                    beq       OperModeAlt handle word operand
                    cmpx      #$0064    operand letter is 'd'
                    beq       OperModeDir handle 'd' operand
                    bra       AddrBadMode unknown letter is an error

AddrLoadResult      ldd       $02,s     reload saved result
AddrReturn2         leas      4,s        drop locals
                    puls      pc,u      return to caller

                    pshs      u         save frame pointer
                    clra                zero first argument high
                    clrb                zero first argument low
                    pshs      d         push zero argument
                    ldd       $08,s     fetch caller argument
                    pshs      d         push it
                    ldd       $08,s     fetch second caller argument
                    pshs      d         push it
                    lbra      CompareCallEmit jump into shared emit tail

CompareOperands     pshs      u         save frame pointer
                    ldd       $06,s     fetch first operand argument
                    pshs      d         push it
                    ldd       $06,s     fetch second operand argument
                    pshs      d         push it
                    lbsr      GenOperand2 evaluate the operand
                    leas      4,s        drop arguments
                    tfr       d,u       move result to u
                    cmpu      #$FFFF    check for failure sentinel
                    bne       CompareFirstOk result valid, continue
                    clra                zero result high
                    clrb                zero result low
                    bra       CompareReturn return zero

CompareFirstOk      clra                zero result high
                    clrb                zero result low
                    bra       CompareEmit proceed to emit

                    pshs      u         alternate entry saving frame
                    ldd       $08,s     fetch argument
                    pshs      d         push it
                    lbsr      ReleaseBuffer release the buffer
                    leas      2,s        drop argument
                    ldd       $06,s     fetch operand argument
                    pshs      d         push it
                    ldd       $06,s     fetch second operand argument
                    pshs      d         push it
                    lbsr      GenOperand2 evaluate the operand
                    leas      4,s        drop arguments
                    tfr       d,u       move result to u
                    stu       -$02,s    save operand result
                    bge       CompareSecond non-negative, continue emit
                    clra                zero result high
                    clrb                zero result low
                    bra       CompareReturn return zero

CompareSecond       ldd       $08,s     load emit argument
CompareEmit         pshs      d         push it
                    ldd       $08,s     fetch second argument
                    pshs      d         push it
                    pshs      u         push operand pointer
CompareCallEmit     lbsr      SetupSlot emit the node
                    leas      6,s        drop arguments
CompareReturn       puls      pc,u      return to caller

FillBuffer          pshs      u         save frame pointer
                    ldu       $04,s     load destination buffer pointer
                    leas      -6,s       reserve local slots
                    clra                zero outer counter high
                    clrb                zero outer counter low
                    bra       FillOuterTest enter outer loop test

FillOuterLoop       ldd       $0C,s     load per-row count
                    std       $04,s     initialise inner counter
                    bra       FillInnerTest enter inner loop

FillByteLoop        ldd       $10,s     fetch source argument
                    pshs      d         push it
                    lbsr      FetchByte get next value
                    leas      2,s        drop argument
                    std       ,s        save fetched value
                    cmpd      #$FFFF    end-of-data sentinel
                    beq       FillDone  done filling
                    ldd       ,s        reload value
                    stb       ,u+       store byte into buffer
FillInnerTest       ldd       $04,s     load inner counter
                    addd      #$FFFF    decrement it
                    std       $04,s     save inner counter
                    subd      #$FFFF    test original counter
                    bgt       FillByteLoop loop while positive
                    ldd       $02,s     load outer counter
                    addd      #$0001    increment it
FillOuterTest       std       $02,s     save outer counter
                    ldd       $02,s     reload outer counter
                    cmpd      $0e,s     compare against limit
                    blt       FillOuterLoop loop while below
FillDone            ldd       $02,s     return byte count
                    leas      6,s        drop locals
                    puls      pc,u      return to caller

PlaceOperand        pshs      u         save frame pointer
                    ldu       $04,s     load buffer descriptor
                    leas      -6,s       reserve local slots
                    cmpu      #$0000    null descriptor?
                    beq       PlaceFail yes, fail
                    ldd       $06,u     load descriptor flags
                    clra                clear high byte
                    andb      #$03      mask type bits
                    bne       PlaceCheckHigh typed, continue
PlaceFail           ldd       #$FFFF    failure result
                    lbra      PlaceReturn return failure

PlaceCheckHigh      ldd       $06,u     load descriptor flags
                    anda      #$80      test high bit
                    clrb                clear low byte
                    std       -$02,s    save masked flag
                    bne       PlaceCheckLow high bit set path
                    pshs      u         push descriptor
                    lbsr      AllocTemp prepare the buffer
                    leas      2,s        drop argument
                    lbra      PlaceEmit go emit operand

PlaceCheckLow       ldd       $06,u     load descriptor flags
                    anda      #$01      test bit zero
                    clrb                clear low byte
                    std       -$02,s    save masked flag
                    beq       PlaceInRange bit clear path
                    pshs      u         push descriptor
                    lbsr      SpillOperand spill the buffer
                    leas      2,s        drop argument
                    ldd       $06,u     load flags
                    anda      #$FE      clear bit zero
                    std       $06,u     store flags back
                    ldd       $02,u     load base position
                    addd      $0b,u     add buffer size
                    std       $04,u     set end position
                    lbra      PlaceStorePos store position and go

PlaceInRange        ldd       ,u        load current position
                    cmpd      $04,u     compare to end
                    lbcc      PlaceEmit at or past end, emit
                    leax      $02,s     point at local pair
                    pshs      x         push pointer
                    leax      $0e,s     point at operand arguments
                    lbsr      StoreLong push operand pair
                    ldx       $10,s     load returned code
                    lbra      PlaceDispatch dispatch on code

PlaceDefault        leax      $02,s     point at locals
                    pshs      x         push pointer
                    ldd       $02,x     push operand high word
                    pshs      d         push it
                    ldd       ,x        push operand low word
                    pshs      d         push it
                    pshs      u         push descriptor
                    lbsr      DefaultOperand compute default operand
                    leas      2,s        drop argument
                    lbsr      IntSub32  arithmetic helper
                    lbsr      StoreLong push result operand
PlaceCompare        ldd       $0b,u     load buffer size
                    lbsr      SignExtendLong push size constant
                    ldd       $02,x     push operand high word
                    pshs      d         push it
                    ldd       ,x        push operand low word
                    pshs      d         push it
                    leax      $06,s     point at second operand
                    ldd       $02,x     push high word
                    pshs      d         push it
                    ldd       ,x        push low word
                    pshs      d         push it
                    bsr       PlaceConstZero fetch inline zero constant pointer
                    fcb       $00,$00,$00,$00
PlaceConstZero      puls      x         pull constant pointer into x
                    lbsr      IntCmp32  compare operand pair
                    bge       PlaceCmpHigh non-negative, use as is
                    leax      $06,s     point at second operand
                    lbsr      NegLong   negate helper
                    bra       PlaceCmpAgain continue

PlaceCmpHigh        leax      $06,s     point at second operand
PlaceCmpAgain       lbsr      IntCmp32  compare operand pair
                    blt       PlaceMerge below, merge out
                    ldd       $04,s     load computed offset
                    addd      ,u        add current position
                    std       ,s        save it
                    cmpd      $02,u     compare against base
                    bcs       PlaceMerge below base, skip
                    ldd       ,s        reload value
                    cmpd      $04,u     compare against end
                    bcc       PlaceMerge at or past end, skip
                    ldd       ,s        reload value
                    std       ,u        update position
                    ldd       $06,u     load flags
                    andb      #$EF      clear allocation bit
                    std       $06,u     store flags back
                    lbra      PlaceOk   success

                    bra       PlaceMerge otherwise merge out

PlaceDispatch       stx       -$02,s    save dispatch code
                    lbeq      PlaceDefault code zero handler
                    cmpx      #$0001    code one?
                    lbeq      PlaceCompare code one handler
PlaceMerge          ldd       $10,s     load single-arg flag
                    cmpd      #$0001    is it one?
                    bne       PlaceSetEnd no, use end
                    leax      $0C,s     point at operand
                    pshs      x         push pointer
                    ldd       $02,x     push high word
                    pshs      d         push it
                    ldd       ,x        push low word
                    pshs      d         push it
                    ldd       $04,u     load end position
                    subd      ,u        subtract current position
                    lbsr      SignExtendLong push difference constant
                    lbsr      IntSub32  arithmetic helper
                    lbsr      StoreLong push result
PlaceSetEnd         ldd       $04,u     load end position
PlaceStorePos       std       ,u        store as new position
PlaceEmit           ldd       $06,u     load flags
                    andb      #$EF      clear allocation bit
                    std       $06,u     store flags back
                    ldd       $10,s     load single-arg flag
                    pshs      d         push it
                    leax      $0e,s     point at operand arguments
                    ldd       $02,x     push high word
                    pshs      d         push it
                    ldd       ,x        push low word
                    pshs      d         push it
                    ldd       $08,u     push buffer handle
                    pshs      d         push it
                    lbsr      SeekPath  emit the instruction
                    leas      8,s        drop arguments
                    ldd       $02,x     push high word
                    pshs      d         push it
                    ldd       ,x        push low word
                    pshs      d         push it
                    bsr       PlaceConstFF fetch inline $FFFF constant pointer
                    fcb       $FF,$FF,$FF,$FF
PlaceConstFF        puls      x         pull constant pointer into x
                    lbsr      IntCmp32  compare operand pair
                    bne       PlaceOk   differ, success
                    ldd       #$FFFF    equal means failure
                    bra       PlaceReturn return failure

PlaceOk             clra                zero result high
                    clrb                zero result low
PlaceReturn         leas      6,s        drop locals
                    puls      pc,u      return to caller

                    pshs      u         save frame pointer
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero
                    pshs      d         push zero again
                    ldd       $0a,s     fetch descriptor argument
                    pshs      d         push it
                    lbsr      PlaceOperand place the operand
                    leas      8,s        drop arguments
                    puls      pc,u      return to caller

DefaultOperand      pshs      u         save frame pointer
                    ldu       $04,s     load descriptor
                    beq       DefaultUseFixed null, use fixed default
                    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$03      mask type bits
                    bne       DefaultTyped typed descriptor
DefaultUseFixed     bsr       DefaultFixedBuf fetch inline default pointer
                    fcb       $FF,$FF,$FF,$FF
DefaultFixedBuf     puls      x         pull pointer into x
                    leau      TempBuffer,y   point at fixed default buffer
                    pshs      u         push it
                    lbsr      StoreLong push operand
                    puls      pc,u      return to caller

DefaultTyped        ldd       $06,u     load flags
                    anda      #$80      test high bit
                    clrb                clear low byte
                    std       -$02,s    save masked flag
                    bne       DefaultEmit set, skip prepare
                    pshs      u         push descriptor
                    lbsr      AllocTemp prepare the buffer
                    leas      2,s        drop argument
DefaultEmit         ldd       #$0001    constant one
                    pshs      d         push it
                    clra                zero argument high
                    clrb                zero argument low
                    pshs      d         push zero
                    pshs      d         push zero again
                    ldd       $08,u     push buffer handle
                    pshs      d         push it
                    lbsr      SeekPath  emit the instruction
                    leas      8,s        drop arguments
                    ldd       $02,x     push high word
                    pshs      d         push it
                    ldd       ,x        push low word
                    pshs      d         push it
                    ldd       $06,u     load flags
                    anda      #$01      test bit zero
                    clrb                clear low byte
                    std       -$02,s    save masked flag
                    beq       DefaultUseEnd clear, use end
                    ldd       $02,u     use base position
                    bra       DefaultOffset continue

DefaultUseEnd       ldd       $04,u     use end position
DefaultOffset       pshs      d         push chosen position
                    ldd       ,u        load current position
                    subd      ,s++      compute offset difference
                    lbsr      SignExtendLong push offset constant
                    lbsr      IntAdd32  emit operand
                    puls      pc,u      return to caller

GenOperand3         pshs      u         save frame pointer
                    ldu       $06,s     load operand descriptor
                    ldd       $06,u     load flags
                    anda      #$80      keep high bit
                    andb      #$22      mask bits one and five
                    cmpd      #$8002    specific flag pattern?
                    beq       GenOpEmit yes, emit path
                    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$22      mask bits one and five
                    cmpd      #$0002    pattern present?
                    lbne      SpillFail no, other handling
                    pshs      u         push descriptor
                    lbsr      AllocTemp prepare the buffer
                    leas      2,s        drop argument
GenOpEmit           ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$04      test bit two
                    beq       GenOpAppend clear, append path
                    ldd       #$0001    constant one
                    pshs      d         push it
                    leax      $07,s     point at local
                    pshs      x         push pointer
                    ldd       $08,u     push buffer handle
                    pshs      d         push it
                    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       GenOpLoadFunc clear, use default function
                    leax      WriteLine,pcr load alternate emit function
                    bra       GenOpCallFunc continue

GenOpLoadFunc       leax      WritePath,pcr load default emit function
GenOpCallFunc       tfr       x,d       copy pointer to d
                    tfr       d,x       copy pointer back to x
                    jsr       ,x        call selected emitter
                    leas      6,s        drop arguments
                    cmpd      #$FFFF    failed?
                    bne       GenOpReturn no, return result
                    ldd       $06,u     load flags
                    orb       #$20      set retry bit
                    std       $06,u     store flags back
                    lbra      SpillFail retry other handling

GenOpAppend         ldd       $06,u     load flags
                    anda      #$01      test bit zero
                    clrb                clear low byte
                    std       -$02,s    save masked flag
                    bne       GenOpStoreByte set, skip spill
                    pshs      u         push descriptor
                    lbsr      EmitOperandRange spill the buffer
                    leas      2,s        drop argument
GenOpStoreByte      ldd       ,u        load current position
                    addd      #$0001    advance one byte
                    std       ,u        store new position
                    subd      #$0001    back to old position
                    tfr       d,x       make it a pointer
                    ldd       $04,s     load byte value
                    stb       ,x        store byte into buffer
                    ldd       ,u        reload position
                    cmpd      $04,u     compare against end
                    bcc       GenOpFlush buffer full, flush
                    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       GenOpReturn clear, return
                    ldd       $04,s     load byte value
                    cmpd      #$000D    is it a newline?
                    bne       GenOpReturn no, return
GenOpFlush          pshs      u         push descriptor
                    lbsr      EmitOperandRange flush the buffer
                    std       ,s++      save flush result
                    lbne      SpillFail error path
GenOpReturn         ldd       $04,s     return the byte
                    puls      pc,u      return to caller

                    pshs      u         save frame pointer
                    ldu       $04,s     load descriptor
                    ldd       $06,s     fetch second argument
                    pshs      d         push it
                    pshs      u         push descriptor
                    ldd       #$0008    field size eight
                    lbsr      LsrEntry  fetch field byte
                    pshs      d         push it
                    lbsr      GenOperand3 emit first operand byte
                    leas      4,s        drop arguments
                    ldd       $06,s     fetch second argument
                    pshs      d         push it
                    pshs      u         push descriptor
                    lbsr      GenOperand3 emit second operand byte
                    lbra      RangeExit return to caller

ClearBufTable       pshs      u,d       save frame and index
                    leau      Stdin,y   point at buffer table base
                    clra                zero index high
                    clrb                zero index low
                    std       ,s        initialise index
                    bra       ClearBufNext enter loop test

ClearBufLoop        tfr       u,d       copy entry pointer to d
                    leau      $0d,u     advance to next entry
                    pshs      d         push entry pointer
                    bsr       ReleaseBuffer release this buffer
                    leas      2,s        drop argument
ClearBufNext        ldd       ,s        load index
                    addd      #$0001    increment it
                    std       ,s        store index
                    subd      #$0001    restore for test
                    cmpd      #$0010    sixteen entries done?
                    blt       ClearBufLoop loop while below
                    lbra      SpillDone return done

ReleaseBuffer       pshs      u         save frame pointer
                    ldu       $04,s     load buffer descriptor
                    leas      -2,s       reserve local
                    cmpu      #$0000    null descriptor?
                    beq       ReleaseNone yes, nothing to do
                    ldd       $06,u     load flags
                    bne       ReleaseCheckFlag allocated, check further
ReleaseNone         ldd       #$FFFF    nothing to release
                    lbra      SpillDone return failure sentinel

ReleaseCheckFlag    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$02      test bit one
                    beq       ZeroResult2 clear, skip
                    pshs      u         push descriptor
                    bsr       SpillOperand call to spill the operand
                    leas      2,s        drop the pushed argument
                    bra       StoreResult2 go store the result

ZeroResult2         clra                zero the high byte
                    clrb                zero the low byte
StoreResult2        std       ,s        store result on the stack
                    ldd       $08,u     load the id field
                    pshs      d         push it as argument
                    lbsr      ClosePath call the helper routine
                    leas      2,s        drop the argument
                    clra                zero high byte
                    clrb                zero low byte
                    std       $06,u     clear the operand flags
                    ldd       ,s        reload the saved result
                    bra       SpillDone jump to common exit

SpillOperand        pshs      u         save u register
                    ldu       $04,s     load the operand pointer argument
                    beq       SpillFail null pointer so fail
                    ldd       $06,u     load the operand flags
                    clra                keep only the low byte
                    andb      #$22      mask the flag bits
                    cmpd      #$0002    test for the target flag value
                    beq       SpillProceed matched so proceed
SpillFail           ldd       #$FFFF    load failure return value
                    puls      pc,u      restore and return

SpillProceed        ldd       $06,u     reload the flags
                    anda      #$80      isolate the high sign bit
                    clrb                clear low byte
                    std       -$02,s    save the local flag test
                    bne       SpillEmitRange already spilled so skip alloc
                    pshs      u         push the operand
                    lbsr      AllocTemp allocate a temp buffer
                    leas      2,s        drop the argument
SpillEmitRange      pshs      u         push the operand
                    bsr       EmitOperandRange emit the operand range
SpillDone           leas      2,s        drop the argument
                    puls      pc,u      restore and return

EmitOperandRange    pshs      u         save u register
                    ldu       $04,s     load the operand pointer
                    leas      -4,s       reserve local slots
                    ldd       $06,u     load the flags
                    anda      #$01      isolate bit zero
                    clrb                clear low byte
                    std       -$02,s    save the local test
                    bne       RangeCheckLen bit set so skip
                    ldd       ,u        load the base pointer
                    cmpd      $04,u     compare against end pointer
                    beq       RangeCheckLen equal so skip
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push the zero argument
                    pshs      u         push the operand
                    lbsr      DefaultOperand call helper returning pointer
                    leas      2,s        drop the argument
                    ldd       $02,x     load a field from result
                    pshs      d         push it
                    ldd       ,x        load the first field
                    pshs      d         push it
                    ldd       $08,u     load the id field
                    pshs      d         push it
                    lbsr      SeekPath  emit the call
                    leas      8,s        drop the arguments
RangeCheckLen       ldd       ,u        load the base pointer
                    subd      $02,u     subtract the mid pointer
                    std       $02,s     save the range length
                    lbeq      RangeFinalize zero length so finalize
                    ldd       $06,u     load the flags
                    anda      #$01      isolate bit zero
                    clrb                clear low byte
                    std       -$02,s    save local test
                    lbeq      RangeFinalize not set so finalize
                    ldd       $06,u     reload flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       RangeEmitAlt clear so take alt path
                    ldd       $02,u     load the mid pointer
                    bra       RangeStoreBase enter the store loop

RangeEmitLoop       ldd       $02,s     load the length
                    pshs      d         push it
                    ldd       ,u        load the base
                    pshs      d         push it
                    ldd       $08,u     load the id
                    pshs      d         push it
                    lbsr      WriteLine emit a chunk
                    leas      6,s        drop the arguments
                    std       ,s        save the emitted count
                    cmpd      #$FFFF    check for failure
                    bne       RangeAdvance ok so continue
                    leax      $04,s     point at the local
                    bra       RangeErrAdjust go set error flags

RangeAdvance        ldd       $02,s     load the length
                    subd      ,s        subtract emitted count
                    std       $02,s     update remaining length
                    ldd       ,u        load the base
                    addd      ,s        advance by emitted count
RangeStoreBase      std       ,u        store the updated base
                    ldd       $02,s     load remaining length
                    bne       RangeEmitLoop loop while nonzero
                    bra       RangeFinalize done so finalize

RangeEmitAlt        ldd       $02,s     load the length
                    pshs      d         push it
                    ldd       $02,u     load the mid pointer
                    pshs      d         push it
                    ldd       $08,u     load the id
                    pshs      d         push it
                    lbsr      WritePath emit the alternate form
                    leas      6,s        drop the arguments
                    cmpd      $02,s     compare emitted with length
                    beq       RangeFinalize matched so finalize
                    bra       RangeSetError go set error flags

RangeErrAdjust      leas      -$04,x    adjust the pointer
RangeSetError       ldd       $06,u     load the flags
                    orb       #$20      set the error bit
                    std       $06,u     store the flags
                    ldd       $04,u     load the end pointer
                    std       ,u        store it as base
                    ldd       #$FFFF    mark failure result
                    bra       RangeExit exit the routine

RangeFinalize       ldd       $06,u     load the flags
                    ora       #$01      set the done bit
                    std       $06,u     store the flags
                    ldd       $02,u     load the mid pointer
                    std       ,u        set it as base
                    addd      $0b,u     add the buffer size
                    std       $04,u     set the end pointer
                    clra                zero high byte
                    clrb                zero low byte for success
RangeExit           leas      4,s        drop the locals
                    puls      pc,u      restore and return

FetchByte           pshs      u         save u register
                    ldu       $04,s     load the operand pointer
                    beq       FetchFail null so fail
                    ldd       $06,u     load the flags
                    anda      #$01      isolate bit zero
                    clrb                clear low byte
                    std       -$02,s    save local test
                    bne       FetchFail bit set so fail
                    ldd       ,u        load the base pointer
                    cmpd      $04,u     compare against end
                    bcc       FetchByteRefill at end so refill
                    ldd       ,u        load the base
                    addd      #$0001    increment it
                    std       ,u        store advanced base
                    subd      #$0001    back to the old base
                    tfr       d,x       pointer into x
                    ldb       ,x        load the byte
                    clra                zero-extend it
                    lbra      FetchReturn return the fetched byte

FetchByteRefill     pshs      u         push the operand
                    lbsr      EmitLoad2 refill the buffer
                    lbra      EmitLoadDrop return the result

                    pshs      u         push the operand
                    ldu       $06,s     load an operand pointer
                    beq       FetchFail null so fail
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$01      isolate bit zero
                    beq       FetchFail clear so fail
                    ldd       $04,s     load the value argument
                    cmpd      #$FFFF    check for sentinel
                    beq       FetchFail sentinel so fail
                    ldd       ,u        load the base
                    cmpd      $02,u     compare against mid
                    bhi       StoreByteBack above so store byte
FetchFail           ldd       #$FFFF    load failure value
                    puls      pc,u      restore and return

StoreByteBack       ldd       ,u        load the base
                    addd      #$FFFF    decrement it
                    std       ,u        store the base
                    tfr       d,x       pointer into x
                    ldd       $04,s     load the value byte
                    stb       ,x        store byte at pointer
                    ldd       $04,s     reload the value
                    puls      pc,u      restore and return

FetchWord           pshs      u         save u register
                    ldu       $04,s     load the operand pointer
                    leas      -4,s       reserve local slots
                    pshs      u         push the operand
                    lbsr      FetchByte fetch the high byte
                    leas      2,s        drop the argument
                    std       $02,s     save the high byte
                    cmpd      #$FFFF    check for failure
                    beq       FetchWordFail fail so bail out
                    pshs      u         push the operand
                    lbsr      FetchByte fetch the low byte
                    leas      2,s        drop the argument
                    std       ,s        save the low byte
                    cmpd      #$FFFF    check for failure
                    bne       FetchWordCombine ok so combine
FetchWordFail       ldd       #$FFFF    load failure value
                    bra       FetchWordExit go to exit

FetchWordCombine    ldd       $02,s     load the high byte
                    pshs      d         push it
                    ldd       #$0008    shift count of eight
                    lbsr      AslEntry  shift high byte left
                    addd      ,s        add the low byte
FetchWordExit       leas      4,s        drop the locals
                    puls      pc,u      restore and return

EmitLoad2           pshs      u         save u register
                    ldu       $04,s     load the operand pointer
                    leas      -2,s       reserve a local slot
                    ldd       $06,u     load the flags
                    anda      #$80      isolate the sign bit
                    andb      #$31      mask low bits
                    cmpd      #$8001    test the flag combination
                    beq       EmitLoadIndex matched so emit index
                    ldd       $06,u     reload flags
                    clra                clear high byte
                    andb      #$31      mask low bits
                    cmpd      #$0001    test for value one
                    lbne      EmitLoadFail no match so fail
                    pshs      u         push the operand
                    lbsr      AllocTemp allocate a temp buffer
                    leas      2,s        drop the argument
EmitLoadIndex       leax      Stdin,y   load the base table entry
                    pshs      x         push the pointer
                    cmpu      ,s++      compare with operand pointer
                    bne       EmitLoadData differ so skip
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       EmitLoadData clear so skip
                    leax      Stdout,y  load another table entry
                    pshs      x         push the pointer
                    lbsr      SpillOperand spill that operand
                    leas      2,s        drop the argument
EmitLoadData        ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$08      test bit three
                    beq       EmitLoadDefault2 clear so default path
                    ldd       $0b,u     load the size
                    pshs      d         push it
                    ldd       $02,u     load the mid pointer
                    pshs      d         push it
                    ldd       $08,u     load the id
                    pshs      d         push it
                    ldd       $06,u     reload flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       EmitPtrSmall clear so small routine
                    leax      ReadLine,pcr select the large emit routine
                    bra       EmitCallPtr go call it

EmitPtrSmall        leax      ReadPath,pcr select the small emit routine
EmitCallPtr         tfr       x,d       move pointer to d
                    tfr       d,x       move back to x
                    jsr       ,x        call the emit routine
                    bra       EmitLoadResult go inspect the result

EmitLoadDefault2    ldd       #$0001    count of one
                    pshs      d         push it
                    leax      $0a,u     point at inline buffer
                    stx       $02,u     set the mid pointer
                    pshs      x         push the buffer pointer
                    ldd       $08,u     load the id
                    pshs      d         push it
                    lbsr      ReadPath  emit the default load
EmitLoadResult      leas      6,s        drop the arguments
                    std       ,s        save the emit result
                    ldd       ,s        reload it
                    bgt       EmitLoadOk positive so advance
                    ldd       $06,u     load the flags
                    pshs      d         push them
                    ldd       $02,s     load the result
                    beq       FlagWriteRead zero so read flag
                    ldd       #$0020    select write flag bit
                    bra       FlagCombine go combine flags

FlagWriteRead       ldd       #$0010    select read flag bit
FlagCombine         ora       ,s+       combine into flag high
                    orb       ,s+       combine into flag low
                    std       $06,u     store the flags
EmitLoadFail        ldd       #$FFFF    load failure value
                    bra       EmitLoadDrop go to exit

EmitLoadOk          ldd       $02,u     load the mid pointer
                    addd      #$0001    increment it
                    std       ,u        store as base
                    ldd       $02,u     reload the mid pointer
                    addd      ,s        add the emitted count
                    std       $04,u     set the end pointer
                    ldb       [$02,u]   load byte via mid pointer
                    clra                zero-extend it
EmitLoadDrop        leas      2,s        drop the local
FetchReturn         puls      pc,u      restore and return

AllocTemp           pshs      u         save u register
                    ldu       $04,s     load the operand pointer
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$C0      test the allocated bits
                    bne       AllocMark already allocated so skip
                    leas      -32,s      reserve a scratch buffer
                    leax      ,s        point at the buffer
                    pshs      x         push the pointer
                    ldd       $08,u     load the id
                    pshs      d         push it
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push the zero argument
                    lbsr      GetStat   format into the buffer
                    leas      6,s        drop the arguments
                    ldd       $06,u     load the flags
                    pshs      d         push them
                    ldb       $02,s     load the result low byte
                    bne       AllocFlagHigh nonzero so high flag
                    ldd       #$0040    select low alloc flag
                    bra       AllocFlagStore go store flags

AllocFlagHigh       ldd       #$0080    select high alloc flag
AllocFlagStore      ora       ,s+       combine into flag high
                    orb       ,s+       combine into flag low
                    std       $06,u     store the flags
                    leas      32,s       release the scratch buffer
AllocMark           ldd       $06,u     load the flags
                    ora       #$80      set the allocated marker
                    std       $06,u     store the flags
                    clra                clear high byte
                    andb      #$0C      test the buffer-present bits
                    beq       AllocSize none so allocate
                    puls      pc,u      already present so return

AllocSize           ldd       $0b,u     load the size field
                    bne       AllocBuffer nonzero so use it
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       AllocSize256 clear so larger default
                    ldd       #$0080    select 128-byte default size
                    bra       AllocSizeStore go store size

AllocSize256        ldd       #$0100    select 256-byte default size
AllocSizeStore      std       $0b,u     store the size field
AllocBuffer         ldd       $02,u     load the mid pointer
                    bne       AllocBufferOk present so mark heap
                    ldd       $0b,u     load the size
                    pshs      d         push it
                    lbsr      BumpAlloc allocate a memory buffer
                    leas      2,s        drop the argument
                    std       $02,u     store the buffer pointer
                    cmpd      #$FFFF    check for failure
                    beq       AllocBufferInline fail so use inline buffer
AllocBufferOk       ldd       $06,u     load the flags
                    orb       #$08      set the heap-buffer bit
                    std       $06,u     store the flags
                    bra       AllocSetPointers go set the pointers

AllocBufferInline   ldd       $06,u     load the flags
                    orb       #$04      set the inline-buffer bit
                    std       $06,u     store the flags
                    leax      $0a,u     point at inline buffer
                    stx       $02,u     set the mid pointer
                    ldd       #$0001    size of one byte
                    std       $0b,u     store the size field
AllocSetPointers    ldd       $02,u     load the mid pointer
                    addd      $0b,u     add the buffer size
                    std       $04,u     set the end pointer
                    std       ,u        also set the base
                    puls      pc,u      restore and return

EmitOperandStr2     pshs      u         save u register
                    ldd       $0C,s     load the first argument
                    beq       EmitOperandStrPlain zero so plain path
                    ldd       $0e,s     load the second argument
                    beq       EmitOperandStrAlt zero so alternate path
                    leax      $04,s     point at the locals
                    lbsr      PushArg8  call the helper
                    ldd       $14,s     load the register value
                    aslb                multiply value by eight
                    rola                propagate carry
                    aslb                continue shift
                    rola                propagate carry
                    aslb                continue shift
                    rola                propagate carry
                    leax      >RegisterNameTable,y  point at register-name table
                    leax      d,x       index into the table
                    lbsr      FpMultiply emit the register operand
                    bra       EmitOperandStrTail go to common tail

EmitOperandStrAlt   leax      $04,s     point at the locals
                    lbsr      PushArg8  call the helper
                    ldd       $14,s     load the register value
                    aslb                multiply value by eight
                    rola                propagate carry
                    aslb                continue shift
                    rola                propagate carry
                    aslb                continue shift
                    rola                propagate carry
                    leax      >RegisterNameTable,y  point at register-name table
                    leax      d,x       index into the table
                    lbsr      FpDivide  emit the alternate register operand
                    bra       EmitOperandStrTail go to common tail

EmitOperandStrPlain leax      $04,s     point at the locals
EmitOperandStrTail  leau      TempBuffer,y   point at the output buffer
                    pshs      u         push the buffer
                    lbsr      CopyFloat8 emit the assembled string
                    puls      pc,u      restore and return

EmitDecimal2        pshs      u         save u register
                    ldd       $0C,s     load the number argument
                    cmpd      #$0009    compare against nine
                    ble       EmitDecimalDigit below ten so emit digit
                    leax      $04,s     point at the locals
                    pshs      x         push the pointer
                    ldd       $10,s     load the value
                    pshs      d         push it
                    ldd       $10,s     load the value again
                    pshs      d         push it
                    ldd       #$000A    divisor of ten
                    lbsr      DivSigned divide by ten
                    addd      #$0009    bias by nine
                    pshs      d         push the quotient
                    leax      $0a,s     point at the arguments
                    lbsr      PushArg8  call the helper
                    lbsr      EmitOperandStr2 recurse on the high digits
                    leas      12,s       drop the arguments
                    lbsr      CopyFloat8 emit the assembled part
EmitDecimalDigit    ldd       $0e,s     load the low argument
                    pshs      d         push it
                    ldd       $0e,s     load it again
                    pshs      d         push it
                    ldd       #$000A    divisor of ten
                    lbsr      DivSignedSetup compute the remainder
                    pshs      d         push the digit
                    leax      $08,s     point at the arguments
                    lbsr      PushArg8  call the helper
                    lbsr      EmitOperandStr2 emit the single digit
                    leas      12,s       drop the arguments
                    puls      pc,u      restore and return

StrLen              pshs      u         save u register
                    ldu       $04,s     load the string pointer
StrLenLoop2         ldb       ,u+       scan the next byte
                    bne       StrLenLoop2 loop until terminator
                    tfr       u,d       move end pointer to d
                    subd      $04,s     subtract the start pointer
                    addd      #$FFFF    minus one for terminator
                    puls      pc,u      restore and return

StrCopy             pshs      u         save u register
                    ldu       $06,s     load the source pointer
                    leas      -2,s       reserve a local slot
                    ldd       $06,s     load the destination pointer
                    std       ,s        save it locally
StrCopyLoop         ldb       ,u+       load the next source byte
                    ldx       ,s        load the destination pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save the pointer
                    stb       -$01,x    store the byte
                    bne       StrCopyLoop loop while nonzero
                    bra       StrCatDone done, jump to finish

StrCat              pshs      u         save u
                    ldu       $06,s     load source pointer
                    leas      -2,s       make room for a local
                    ldd       $06,s     load dest pointer
                    std       ,s        save it
StrCatEndLoop       ldx       ,s        load dest pointer
                    leax      $01,x     advance
                    stx       ,s        save
                    ldb       -$01,x    read dest byte
                    bne       StrCatEndLoop loop to end of dest string
                    ldd       ,s        load end pointer
                    addd      #$FFFF    back up one to the null
                    std       ,s        save
StrCatCopyLoop      ldb       ,u+       read a source byte
                    ldx       ,s        load dest pointer
                    leax      $01,x     advance
                    stx       ,s        save
                    stb       -$01,x    store the byte
                    bne       StrCatCopyLoop loop until null copied
StrCatDone          ldd       $06,s     load result pointer
                    leas      2,s        drop the local
                    puls      pc,u      restore and return

                    pshs      u         save u
                    ldu       $04,s     load pointer argument
                    bra       ScanMatchLoop enter the scan loop

StrScanLoop         ldx       $06,s     load pointer
                    leax      $01,x     advance
                    stx       $06,s     save
                    ldb       -$01,x    read the byte
                    bne       StrScanNext continue while nonzero
                    clra                clear high result
                    clrb                clear low result (not found)
                    puls      pc,u      restore and return

StrScanNext         leau      $01,u     advance u
ScanMatchLoop       ldb       ,u        read char at u
                    sex                 sign extend to d
                    pshs      d         save it
                    ldb       [$08,s]   read the target char
                    sex                 sign extend
                    cmpd      ,s++      compare the two chars
                    beq       StrScanLoop loop while equal
                    ldb       [$06,s]   read char
                    sex                 sign extend
                    pshs      d         save
                    ldb       ,u        read char at u
                    sex                 sign extend
                    subd      ,s++      compute the difference
                    puls      pc,u      return the difference

FpNumCvt            ldx       $02,s     load argument pointer
                    lbsr      PushArg8  convert the operand
                    bsr       FpNormStore normalize and store the value
                    rts                 return

FpNormStore         pshs      u         save u
                    leas      -30,s      allocate a 30-byte fp frame
                    tfr       s,u       point u at the frame
                    clr       $1d,u     clear the overflow flag
                    clr       $19,u     clear the sign field
                    lbsr      FpNormalize normalize the value
                    lbra      FpStoreResult store result and return

FpNegate            ldd       ,x        load sign and exponent
                    eora      #$80      flip the sign bit
                    lbra      StoreOutputMantD store back (negated)

                    lbsr      FpUnpackArgs load the operands
                    lbsr      FpAdd     perform the fp add
                    lbra      FpStoreResult store the result

                    lbsr      FpUnpackArgs load the operands
                    lbsr      FpSubtract perform the fp subtract
                    lbra      FpStoreResult store the result

FpMultiply          lbsr      FpUnpackArgs load the operands
                    lbsr      FpMulExp  perform the fp multiply
                    bra       FpStoreResult store the result

FpDivide            lbsr      FpUnpackArgs load the operands
                    lbsr      FpDivExp  perform the fp divide
                    bra       FpStoreResult store the result

FpFetchOperand      lbsr      StoreOutputMant fetch the operand
                    lbra      FloatToFixed process it

                    bsr       FpFetchOperand fetch the operand
                    ldd       $02,x     load value word
                    rts                 return
                    ldd       ,x        load value
                    std       TempBuffer,y   save to the temp buffer
                    ldd       $02,x     load next word
                    leax      TempBuffer,y   point at the temp buffer
                    std       $02,x     store
                    lbra      NormMantissa process it

                    leax      TempBuffer,y   point at the temp buffer
                    std       $02,x     store
                    tfr       a,b       move a into b
                    sex                 sign extend
                    tfr       a,b       move a into b
                    std       ,x        store
                    lbra      NormMantissa process it

                    leax      TempBuffer,y   point at the temp buffer
                    std       $02,x     store
                    clr       ,x        clear
                    clr       $01,x     clear
                    lbra      NormMantissa process it

FpMoveTemp          ldd       ,x        load value
                    std       TempBuffer,y   save to the temp buffer
                    lda       $02,x     load a byte
                    ldb       $07,x     load a byte
                    leax      TempBuffer,y   point at the temp buffer
                    std       $02,x     store
                    rts                 return
                    ldd       ,x        load value
                    std       TempBuffer,y   save to the temp buffer
                    ldd       $02,x     load next word
                    leax      TempBuffer,y   point at the temp buffer
                    sta       $02,x     store high byte
                    stb       $07,x     store low byte
                    clr       $03,x     clear
                    clr       $04,x     clear
                    clr       $05,x     clear
                    clr       $06,x     clear
                    rts                 return

FpStoreResult       leax      TempBuffer,y   point at the result buffer
                    ldd       $22,u     load mantissa bytes
                    std       ,x        store
                    ldd       $24,u     load mantissa bytes
                    std       $02,x     store
                    ldd       $26,u     load mantissa bytes
                    std       $04,x     store
                    ldd       $28,u     load mantissa and exponent bytes
                    std       $06,x     store
                    leas      $1e,u     drop the fp frame
                    puls      u         restore u
                    puls      d         pull the return pointer
                    std       $06,s     place it on the stack
                    leas      6,s        adjust the stack
                    rts                 return
                    lda       $02,s     load sign of a
                    eora      ,x        compare with sign of b
                    bmi       CmpSignDiff branch if signs differ
                    lda       $02,s     reload sign of a
                    bmi       CmpBothNeg branch if both negative
                    lda       $09,s     load exponent of a
                    beq       CmpBZero  branch if exponent zero
                    ldb       $07,x     load exponent of b
                    beq       CmpGreater b zero means a is greater
                    cmpa      $07,x     compare the exponents
                    bne       CmpByMag  differ, compare magnitudes
                    ldd       $02,s     load mantissa a
                    cmpd      ,x        compare mantissa
                    bne       CmpByMag  differ, compare magnitudes
                    ldd       $04,s     load next mantissa word
                    cmpd      $02,x     compare mantissa
                    bne       CmpByMag  differ, compare magnitudes
                    ldd       $06,s     load next mantissa word
                    cmpd      $04,x     compare mantissa
                    bne       CmpByMag  differ, compare magnitudes
                    lda       $08,s     load low guard byte
                    anda      #$FE      mask the guard bit
                    pshs      a         save
                    ldb       $06,x     load b low byte
                    andb      #$FE      mask the guard bit
                    cmpa      ,s+       compare
                    bne       CmpByMag  differ, compare magnitudes
                    bra       CmpReturn equal

CmpBZero            lda       $07,x     load exponent of b
                    bne       CmpLess   nonzero means a is less
                    clra                clear
                    bra       CmpReturn equal (both zero)

CmpBothNeg          lda       $07,x     load exponent of b
                    cmpa      $09,s     compare exponents
CmpByMag            bhi       CmpGreater a exponent greater
                    bcs       CmpLess   a exponent less
                    ldd       ,x        load mantissa b
                    cmpd      $02,s     compare
                    bne       CmpByMag  recheck via magnitude
                    ldd       $02,x     load next mantissa word
                    cmpd      $04,s     compare
                    bne       CmpByMag  recheck via magnitude
                    ldd       $04,x     load next mantissa word
                    cmpd      $06,s     compare
                    bne       CmpByMag  recheck via magnitude
                    lda       $06,x     load b low byte
                    anda      #$FE      mask the guard bit
                    pshs      a         save
                    lda       $08,s     load a low byte
                    anda      #$FE      mask the guard bit
                    cmpa      ,s+       compare
                    bne       CmpByMag  differ, compare magnitudes
                    bra       CmpReturn equal

CmpSignDiff         lda       ,x        load sign of b
                    bpl       CmpLess   b positive means a is less
CmpGreater          lda       #$01      result is greater
                    andcc     #$FE      clear carry
CmpReturn           pshs      cc        save flags
                    ldd       $01,s     reload return value
                    std       $09,s     place result
                    puls      cc        restore flags
                    leas      8,s        drop the locals
                    rts                 return

CmpLess             clra                clear result
                    cmpa      #$01      set carry (less)
                    bra       CmpReturn finish

FpSubtract          lda       $17,u     load exponent of b
                    beq       FpCopyA   b zero, just copy a
                    ldb       $1C,u     load sign
                    eorb      #$80      flip sign for subtract
                    stb       $1C,u     save
                    eorb      $18,u     combine with sign of a
                    stb       $19,u     save result sign
                    ldb       $29,u     load exponent of a
                    bne       FpAlignExp a nonzero, align
                    lbsr      LoadWorkMantissa handle zero operand
                    lda       $22,u     load mantissa high
                    lbra      FpPackSign pack the result

FpCopyA             lda       $22,u     load mantissa high
                    ldb       $18,u     load sign
                    lbra      FpPack    pack the result

FpAdd               lbeq      LoadWorkMantissa handle both zero
                    lda       $17,u     load exponent of b
                    beq       FpCopyA   b zero, copy a
FpAlignExp          suba      $29,u     exponent difference
                    beq       FpExpEqual equal exponents
                    sta       ,u        save the shift count
                    bcs       FpShiftB  b smaller, shift b instead
                    ldb       $17,u     load exponent of b
                    stb       $29,u     use the larger exponent
                    ldd       $22,u     load mantissa a
FpShiftALoop        lsra                shift mantissa right
                    rorb                shift right
                    ror       $24,u     shift right
                    ror       $25,u     shift right
                    ror       $26,u     shift right
                    ror       $27,u     shift right
                    ror       $28,u     shift right
                    dec       ,u        decrement shift count
                    bne       FpShiftALoop loop until aligned
                    std       $22,u     store shifted mantissa
FpAddOrSub          lda       $19,u     load the sign
                    bmi       FpNegCarry negative means subtract
                    bra       FpAddMant otherwise add

FpExpEqual          inc       ,u        bump shift count
                    orcc      #$01      set carry
                    bra       FpAddOrSub go handle add or subtract

FpShiftB            ldd       $10,u     load mantissa b
FpShiftBLoop        lsra                shift right
                    rorb                shift right
                    ror       $12,u     shift right
                    ror       $13,u     shift right
                    ror       $14,u     shift right
                    ror       $15,u     shift right
                    ror       $16,u     shift right
                    inc       ,u        increment shift count
                    bne       FpShiftBLoop loop until aligned
                    std       $10,u     store shifted mantissa
                    lda       $19,u     load the sign
                    bmi       FpSubMant negative means subtract
FpAddMant           ldd       $27,u     add the mantissas
                    adcb      $16,u     add with carry
                    adca      $15,u     add with carry
                    std       $27,u     store
                    ldd       $25,u     load next word
                    adcb      $14,u     add with carry
                    adca      $13,u     add with carry
                    std       $25,u     store
                    ldb       $24,u     load byte
                    adcb      $12,u     add with carry
                    stb       $24,u     store
                    ldd       $22,u     load high word
                    adcb      $11,u     add with carry
                    adca      $10,u     add with carry
                    std       $22,u     store
                    bcc       FpAddNorm no carry out
                    inc       $29,u     carry out, bump exponent
                    ror       $22,u     shift the carry back in
                    ror       $23,u     shift right
                    ror       $24,u     shift right
                    ror       $25,u     shift right
                    ror       $26,u     shift right
                    ror       $27,u     shift right
                    ror       $28,u     shift right
FpAddNorm           lda       $1C,u     load the sign
                    sta       $19,u     store it
                    bra       FpNormalize normalize

FpNegCarry          rola                rebuild carry flag
                    coma                complement
                    asra                restore carry from add
FpSubMant           ldd       $27,u     subtract the mantissas
                    sbcb      $16,u     subtract with borrow
                    sbca      $15,u     subtract with borrow
                    std       $27,u     store
                    ldd       $25,u     load next word
                    sbcb      $14,u     subtract with borrow
                    sbca      $13,u     subtract with borrow
                    std       $25,u     store
                    ldd       $23,u     load next word
                    sbcb      $12,u     subtract with borrow
                    sbca      $11,u     subtract with borrow
                    std       $23,u     store
                    lda       $22,u     load high byte
                    sbca      $10,u     subtract with borrow
                    sta       $22,u     store
                    lda       $18,u     load the sign
                    bcc       FpSetSign no borrow, result positive
                    com       $22,u     negate the mantissa
                    com       $23,u     complement
                    com       $24,u     complement
                    com       $25,u     complement
                    com       $26,u     complement
                    com       $27,u     complement
                    com       $28,u     complement
                    lda       ,u        load low byte
                    beq       FpSubSign already zero, skip carry
                    lbsr      RoundMantissa propagate the carry
FpSubSign           lda       $1C,u     load the sign
FpSetSign           sta       $19,u     store the result sign
FpNormalize         clr       ,u        clear the low guard byte
FpNormLoop          lda       $22,u     load mantissa high
                    bmi       FpPackSign already normalized
                    ora       $23,u     test all mantissa bytes
                    ora       $24,u     test
                    ora       $25,u     test
                    ora       $26,u     test
                    ora       $27,u     test
                    ora       $28,u     test
                    beq       FpZeroExp mantissa is zero
                    ldd       $22,u     load mantissa high word
FpNormShiftLoop     dec       $29,u     decrement exponent
                    bne       ShiftMantissa skip underflow
                    dec       $1d,u     mark underflow
ShiftMantissa       asl       ,u        shift mantissa left
                    rol       $28,u     shift left
                    rol       $27,u     shift left
                    rol       $26,u     shift left
                    rol       $25,u     shift left
                    rol       $24,u     shift left
                    rolb                shift left
                    rola                shift left
                    bpl       FpNormShiftLoop loop until normalized
                    stb       $23,u     store mantissa byte
                    ldb       $29,u     load exponent
                    beq       FpCheckOverflow zero, check overflow
FpPackSign          ldb       $19,u     load the sign
FpPack              anda      #$7f      clear sign bit of mantissa
                    andb      #$80      isolate the sign bit
                    pshs      b         save it
                    adda      ,s+       merge sign into high byte
                    sta       $22,u     store
                    tst       $1d,u     test overflow flag
                    bne       FpCheckOverflow overflow, check it
FpRet               rts                 return

FpZeroExp           sta       $29,u     clear exponent for zero result
                    rts                 return

FpCheckOverflow     lda       $1d,u     load overflow flag
                    ldb       $29,u     load exponent
                    subd      #$0000    test the value
                    beq       FpUnderflow underflow
                    bmi       FpUnderflow underflow
FpOverflowErr       ldd       #$0028    error code 40 (overflow)
                    lbra      SendSignal report the error

FpUnderflow         lbsr      FpSetZero zero the value
                    bra       FpOverflowErr report the error

FpMulExp            beq       FpSetZero zero, result is zero
                    lda       $17,u     load exponent of b
                    beq       FpSetZero b zero, result is zero
                    lbsr      MantMul   multiply the mantissas
                    clra                clear high
                    ldb       $29,u     load exponent of a
                    addb      $17,u     add the exponents
                    adca      #$00      carry into high
                    subd      #$0080    remove the bias
                    stb       $29,u     store exponent
                    sta       $1d,u     store overflow flag
                    lbsr      FpNormLoop normalize
                    lda       ,u        load byte
                    bpl       FpRet     positive, done
                    lbra      RoundMantissa round the result

FpSetZero           clra                clear
                    sta       $29,u     clear exponent
                    bra       FpFillMant fill with zero

FpDivExp            ldb       $17,u     load divisor exponent
                    bne       FpDivNonZero nonzero, proceed
                    ldd       #$0029    error code 41 (divide by zero)
                    lbra      SendSignal report the error

FpDivNonZero        tsta                test dividend exponent
                    beq       FpSetZero zero, result is zero
                    lbsr      MantDiv   divide the mantissas
                    clra                clear high
                    ldb       $29,u     load exponent of a
                    subb      $17,u     subtract the exponents
                    sbca      #$00      borrow into high
                    addd      #$0081    add the bias
                    sta       $1d,u     store overflow flag
                    stb       $29,u     store exponent
                    lda       $06,u     load byte
                    coma                complement
                    asra                set carry
                    ror       $22,u     shift mantissa right
                    ror       $23,u     shift right
                    ror       $24,u     shift right
                    ror       $25,u     shift right
                    ror       $26,u     shift right
                    ror       $27,u     shift right
                    ror       $28,u     shift right
                    ror       ,u        shift right
                    lbsr      FpNormLoop normalize
                    lda       ,u        load byte
                    bpl       FpExpDone positive, done
                    lbra      RoundMantissa round the result

FpCopyMant          pshs      a         save fill byte
                    ldd       $22,u     copy mantissa word
                    std       ,u        store
                    ldd       $24,u     copy mantissa word
                    std       $02,u     store
                    ldd       $26,u     copy mantissa word
                    std       $04,u     store
                    ldb       $28,u     copy mantissa byte
                    stb       $06,u     store
                    puls      a         restore
FpFillMant          sta       $22,u     fill mantissa byte
                    sta       $23,u     fill mantissa byte
                    sta       $24,u     fill mantissa byte
                    sta       $25,u     fill mantissa byte
                    sta       $26,u     fill mantissa byte
                    sta       $27,u     fill mantissa byte
                    sta       $28,u     store low mantissa byte of prior result
FpExpDone           rts                 return to caller

MantMul             clra                clear the working sign
                    bsr       FpCopyMant clear the product accumulator
                    ldb       #$38      56-bit multiply loop count
                    stb       $08,u     set the loop counter
MantMulLoop         lda       $06,u     fetch next multiplier byte
                    lsra                shift multiplier lsb into carry
                    bcc       MantMulShift skip the add when the bit is zero
                    ldd       $27,u     add multiplicand into the product
                    addd      $15,u     add low word of multiplicand
                    std       $27,u     store product low word
                    ldd       $25,u     next product word up
                    adcb      $14,u     add with carry
                    adca      $13,u     add with carry
                    std       $25,u     store product word
                    ldd       $23,u     next product word up
                    adcb      $12,u     add with carry
                    adca      $11,u     add with carry
                    std       $23,u     store product word
                    lda       $22,u     top product byte
                    adca      $10,u     add top multiplicand byte
                    sta       $22,u     store top product byte
MantMulShift        ror       $22,u     shift product and multiplier right one bit
                    ror       $23,u     continue the right shift
                    ror       $24,u     continue the right shift
                    ror       $25,u     continue the right shift
                    ror       $26,u     continue the right shift
                    ror       $27,u     continue the right shift
                    ror       $28,u     continue the right shift
                    ror       ,u        continue the right shift
                    ror       $01,u     continue the right shift
                    ror       $02,u     continue the right shift
                    ror       $03,u     continue the right shift
                    ror       $04,u     continue the right shift
                    ror       $05,u     continue the right shift
                    ror       $06,u     continue the right shift
                    dec       $08,u     count down the bit loop
                    bne       MantMulLoop repeat for every multiplier bit
                    rts                 multiply complete, return

MantDiv             clra                clear the working sign
                    lbsr      FpCopyMant clear the remainder accumulator
                    ldb       #$39      57-step divide count
                    stb       $08,u     set the loop counter
MantDivLoop         ldb       ,u        high remainder byte
                    cmpb      $10,u     compare remainder against divisor
                    bcs       MantDivShift too small, skip the subtract
                    ldd       $05,u     trial subtract of divisor
                    subd      $15,u     subtract divisor low
                    std       $0d,u     stash partial result
                    ldd       $03,u     next remainder word up
                    sbcb      $14,u     subtract with borrow
                    sbca      $13,u     subtract with borrow
                    std       $0b,u     stash partial result
                    ldb       $02,u     top remainder byte
                    sbcb      $12,u     subtract with borrow
                    stb       $0a,u     stash partial result
                    ldd       ,u        top remainder word
                    sbcb      $11,u     subtract with borrow
                    sbca      $10,u     subtract with borrow
                    bcs       MantDivShift borrow: discard the trial subtract
                    std       ,u        keep the subtraction result
                    lda       $0a,u     copy stashed byte back
                    sta       $02,u     restore remainder
                    ldd       $0b,u     copy stashed word back
                    std       $03,u     restore remainder
                    ldd       $0d,u     copy stashed word back
                    std       $05,u     restore remainder
MantDivShift        rol       $28,u     shift dividend and quotient left
                    rol       $27,u     continue the left shift
                    rol       $26,u     continue the left shift
                    rol       $25,u     continue the left shift
                    rol       $24,u     continue the left shift
                    rol       $23,u     continue the left shift
                    rol       $22,u     continue the left shift
                    rol       $06,u     continue the left shift
                    rol       $05,u     continue the left shift
                    rol       $04,u     continue the left shift
                    rol       $03,u     continue the left shift
                    rol       $02,u     continue the left shift
                    rol       $01,u     continue the left shift
                    rol       ,u        continue the left shift
                    dec       $08,u     count down the divide loop
                    bhi       MantDivLoop loop while steps remain
                    beq       MantDivDone final step handled specially
                    ldd       $05,u     last subtract of divisor
                    subd      $15,u     subtract divisor low
                    std       $05,u     store remainder
                    ldd       $03,u     next word up
                    sbcb      $14,u     subtract with borrow
                    sbca      $13,u     subtract with borrow
                    std       $03,u     store remainder
                    ldd       $01,u     next word up
                    sbcb      $12,u     subtract with borrow
                    sbca      $11,u     subtract with borrow
                    std       $01,u     store remainder
                    lda       ,u        top remainder byte
                    sbca      $10,u     subtract with borrow
                    sta       ,u        store remainder
                    clra                clear carry before the shift
                    bra       MantDivShift merge back into the shift

MantDivDone         ror       ,u        restore the final quotient bit
                    com       $22,u     complement the quotient bytes
                    com       $23,u     complement the quotient bytes
                    com       $24,u     complement the quotient bytes
                    com       $25,u     complement the quotient bytes
                    com       $26,u     complement the quotient bytes
                    com       $27,u     complement the quotient bytes
                    com       $28,u     complement the quotient bytes
                    rts                 divide complete, return

FpUnpackArgs        puls      d         grab the caller return address
                    pshs      u         save the caller frame pointer
                    leas      -30,s      allocate the unpack work area
                    tfr       s,u       point u at the work area
                    pshs      d         push the return address back
                    clr       $1d,u     clear the result flag
                    ldd       $06,x     copy operand mantissa low
                    std       $16,u     into the work area
                    ldd       $04,x     copy next mantissa word
                    std       $14,u     into the work area
                    ldd       $02,x     copy next mantissa word
                    std       $12,u     into the work area
                    ldd       ,x        high word carries the exponent
                    stb       $11,u     store high mantissa byte
                    tfr       a,b       exponent into b
                    sta       $1C,u     save the raw exponent byte
                    ora       #$80      set the implicit leading bit
                    sta       $10,u     store the working exponent
                    eorb      $22,u     combine the two operand signs
                    stb       $19,u     store the result sign
                    lda       $22,u     second operand exponent
                    sta       $18,u     save second operand sign
                    ora       #$80      set its implicit leading bit
                    sta       $22,u     store back
                    lda       $29,u     fetch guard byte
                    rts                 return to caller
                    leax      $22,u     point x at the mantissa to normalise
NormMantissa        lda       #$A0      starting exponent value
                    sta       $07,x     set the exponent
                    clr       $04,x     clear guard byte
                    clr       $05,x     clear guard byte
                    clr       $06,x     clear guard byte
                    lda       ,x        load high byte
                    tfr       a,b       copy to b
                    orb       $01,x     test whether mantissa is zero
                    orb       $02,x     or in next byte
                    orb       $03,x     or in next byte
                    beq       ZeroExponent all zero: emit zero result
                    ldb       $01,x     reload second byte
                    tsta                test sign of the mantissa
                    bpl       NormShiftLoop positive: go normalise
                    pshs      d         save while negating
                    clra                clear a
                    clrb                clear b
                    subd      $02,x     two's complement low word
                    std       $02,x     store negated low word
                    ldd       #$0000    zero for high borrow
                    sbcb      $01,s     subtract with borrow
                    sbca      ,s        subtract with borrow
                    leas      2,s        drop the saved word
                    bvs       NormMask  handle the overflow edge case
NormShiftLoop       dec       $07,x     decrement exponent per shift
                    asl       $03,x     shift mantissa left
                    rol       $02,x     shift mantissa left
                    rolb                shift mantissa left
                    rola                shift mantissa left
                    bpl       NormShiftLoop repeat until leading bit set
NormMask            anda      #$7f      clear the sign position
                    tst       ,x        test original sign
                    bpl       NormStore positive: keep as is
                    ora       #$80      set the sign bit
NormStore           std       ,x        store normalised high word
                    rts                 return to caller
                    leax      $22,u     point x at the mantissa
                    clr       $04,x     clear guard byte
                    clr       $05,x     clear guard byte
                    clr       $06,x     clear guard byte
ZeroExponent        clr       $07,x     zero the exponent
ZeroMantissa        clr       ,x        zero the mantissa
                    clr       $01,x     zero the mantissa
                    clr       $02,x     zero the mantissa
                    clr       $03,x     zero the mantissa
                    rts                 return to caller

FpOverflow          ldd       #$002A    overflow error code 42
                    lbra      SendSignal report the error

                    leax      $22,u     point x at the value to convert
FloatToFixed        ldb       $07,x     get the exponent
                    beq       ZeroMantissa zero exponent: result is zero
                    subb      #$81      remove the exponent bias
                    bcs       FixSmall  magnitude below one
                    negb                negate to a shift count
                    addb      #$1f      compute the right-shift count
                    bmi       FpOverflow too large: overflow
                    bne       FixShiftPrep needs shifting
                    ldd       ,x        exactly the boundary value
                    cmpd      #$8000    compare against the minimum
                    bne       FpOverflow not exact minimum: overflow
                    lda       $02,x     check remaining bytes are zero
                    ora       $03,x     or in next byte
                    ora       $04,x     or in next byte
                    ora       $05,x     or in next byte
                    ora       $06,x     or in next byte
                    bne       FpOverflow nonzero: overflow
                    rts                 in range, return

FixShiftPrep        pshs      b         save the shift count
                    ldd       ,x        load high word
                    bmi       FixShiftNegInit negative value path
                    ora       #$80      set the implicit bit
FixShiftPos         lsra                shift mantissa right
                    rorb                shift mantissa right
                    ror       $02,x     shift mantissa right
                    ror       $03,x     shift mantissa right
                    dec       ,s        count down the shifts
                    bne       FixShiftPos repeat until shifted
                    std       ,x        store the converted integer
                    puls      pc,b      return to caller

FixShiftNegInit     clr       ,-s       init the sticky/round counter
FixShiftNeg         lsra                shift mantissa right
                    rorb                shift mantissa right
                    ror       $02,x     shift mantissa right
                    ror       $03,x     shift mantissa right
                    ror       $04,x     shift mantissa right
                    ror       $05,x     shift mantissa right
                    ror       $06,x     shift mantissa right
                    bcc       FixShiftNext track bits shifted out
                    inc       ,s        count a lost one bit
FixShiftNext        dec       $01,s     count down the shifts
                    bne       FixShiftNeg repeat until shifted
                    std       ,x        store the shifted value
                    ldd       ,s++      retrieve the round info
                    bne       FixRoundUp round up needed
                    lda       $04,x     check the sticky bytes
                    ora       $05,x     or in next byte
                    ora       $06,x     or in next byte
                    beq       FixNegate nothing lost: just negate
FixRoundUp          ldd       $02,x     round the result up
                    addd      #$0001    add one
                    std       $02,x     store low word
                    ldd       ,x        high word
                    adcb      #$00      add carry
                    adca      #$00      add carry
                    bcs       FpOverflow carry out: overflow
                    std       ,x        store high word
FixNegate           clra                negate the result
                    clrb                clear b
                    subd      $02,x     subtract low word
                    std       $02,x     store negated low word
                    ldd       #$0000    zero for high borrow
                    sbcb      $01,x     subtract with borrow
                    sbca      ,x        subtract with borrow
                    std       ,x        store negated high word
                    rts                 return to caller

FixSmall            lda       ,x        check sign of small value
                    lbpl      ZeroMantissa positive: result is zero
                    ldd       #$FFFF    negative: result is minus one
                    std       $02,x     store low word
                    std       ,x        store high word
                    rts                 return to caller

RoundMantissa       inc       $28,u     round up mantissa, cascade carry
                    bne       RoundRts  no carry: done
                    inc       $27,u     carry into next byte
                    bne       RoundRts  no carry: done
                    inc       $26,u     carry into next byte
                    bne       RoundRts  no carry: done
                    inc       $25,u     carry into next byte
                    bne       RoundRts  no carry: done
                    inc       $24,u     carry into next byte
                    bne       RoundRts  no carry: done
                    inc       $23,u     carry into next byte
                    bne       RoundRts  no carry: done
                    ldb       $22,u     high mantissa byte
                    tfr       b,a       copy to a
                    anda      #$7f      drop the sign bit
                    inca                carry into the high byte
                    bpl       RoundSign no exponent overflow
                    inc       $29,u     bump the exponent
                    anda      #$7f      mask sign again
RoundSign           andb      #$80      isolate the sign bit
                    pshs      b         stash it
                    adda      ,s+       merge the sign back in
                    sta       $22,u     store the high byte
RoundRts            rts                 return to caller

FpScratch           fcb       $00,$00,$00,$00,$00,$00,$00,$81
                    leax      >FpScratch,pcr point x at the scratch operand
LoadWorkMantissa    pshs      a         save a
                    ldd       ,x        copy operand mantissa into work area
                    std       $22,u     store into work area
                    ldd       $02,x     next word
                    std       $24,u     store into work area
                    ldd       $04,x     next word
                    std       $26,u     store into work area
                    ldd       $06,x     next word
                    std       $28,u     store into work area
                    puls      pc,a      restore a and return

StoreWorkMantissa   pshs      a         save a
                    ldd       $22,u     copy work mantissa out to x
                    std       ,x        store to buffer
                    ldd       $24,u     next word
                    std       $02,x     store to buffer
                    ldd       $26,u     next word
                    std       $04,x     store to buffer
                    ldd       $28,u     next word
                    std       $06,x     store to buffer
                    puls      pc,a      restore a and return

StoreOutputMant     ldd       ,x        load result high word
StoreOutputMantD    std       TempBuffer,y   store into the output area
                    ldd       $02,x     next word
                    std       OutputArea,y   store into the output area
                    ldd       $04,x     next word
                    std       OutputArea2,y   store into the output area
                    ldd       $06,x     next word
                    leax      TempBuffer,y   repoint x at the output
                    std       $06,x     store the last word
                    rts                 return to caller
                    pshs      x         save the operand pointer
                    bsr       PushArg8  build eight-byte argument
                    leax      FpScratch,pcr scratch as second operand
                    pshs      x         push it
                    lbsr      FpUnpackArgs unpack the operands
                    lbsr      FpAdd     perform the operation
FpStoreResult8      ldx       $2a,u     result destination
                    bsr       StoreWorkMantissa store the result out
                    ldx       $1e,u     restore the caller frame
                    leas      $2a,u     release the work area
                    tfr       x,u       move frame into u
                    puls      pc,x      return to caller

                    pshs      x         save the operand pointer
                    bsr       PushArg8  build eight-byte argument
                    leax      >FpScratch,pcr scratch as second operand
                    pshs      x         push it
                    lbsr      FpUnpackArgs unpack the operands
                    lbsr      FpSubtract perform the operation
                    bra       FpStoreResult8 store and return

                    pshs      x         save the operand pointer
                    bsr       PushArg4  build four-byte argument
                    leax      FpScratch,pcr scratch as second operand
                    pshs      x         push it
                    lbsr      FpUnpackArgs unpack the operands
                    lbsr      FpAdd     perform the operation
FpStoreResult4      ldx       $2a,u     result destination
                    ldd       $22,u     store four-byte result
                    std       ,x        store high word
                    lda       $24,u     result byte
                    ldb       $29,u     guard byte
                    std       $02,x     store low word
                    ldx       $1e,u     restore the caller frame
                    leas      $2a,u     release the work area
                    tfr       x,u       move frame into u
                    puls      pc,x      return to caller

                    pshs      x         save the operand pointer
                    bsr       PushArg4  build four-byte argument
                    leax      FpScratch,pcr scratch as second operand
                    pshs      x         push it
                    lbsr      FpUnpackArgs unpack the operands
                    lbsr      FpSubtract perform the operation
                    bra       FpStoreResult4 store and return

PushArg4            leas      -8,s       allocate the argument buffer
                    ldd       $08,s     fetch the return address
                    std       ,s        move it below the buffer
                    clra                clear a
                    clrb                clear b
                    std       $05,s     zero the low bytes
                    std       $07,s     zero the low bytes
                    ldd       ,x        copy four-byte value
                    std       $02,s     store into the buffer
                    ldd       $02,x     remaining bytes
                    sta       $04,s     store high byte
                    stb       $09,s     store low byte
                    rts                 return to caller

PushArg8            leas      -8,s       allocate the argument buffer
                    ldd       $08,s     fetch the return address
                    std       ,s        move it below the buffer
                    ldd       ,x        copy eight-byte value
                    std       $02,s     store into the buffer
                    ldd       $02,x     next word
                    std       $04,s     store into the buffer
                    ldd       $04,x     next word
                    std       $06,s     store into the buffer
                    ldd       $06,x     next word
                    std       $08,s     store into the buffer
                    rts                 return to caller

CopyFloat4          pshs      u         save u
                    ldu       $04,s     get the source pointer
                    exg       x,u       swap source and destination
                    ldd       ,u        copy four bytes
                    std       ,x        store to destination
                    ldd       $02,u     next word
                    std       $02,x     store to destination
                    bra       CopyFloatDone finish up

CopyFloat8          pshs      u         save u
                    ldu       $04,s     get the source pointer
                    exg       x,u       swap source and destination
                    ldd       ,u        copy eight bytes
                    std       ,x        store to destination
                    ldd       $02,u     next word
                    std       $02,x     store to destination
                    ldd       $04,u     next word
                    std       $04,x     store to destination
                    ldd       $06,u     next word
                    std       $06,x     store to destination
CopyFloatDone       puls      u         restore u
                    puls      d         pop the return address
                    std       ,s        fix up the stack
                    rts                 return to caller

IntAdd32            ldd       $04,s     low word of first operand
                    addd      $02,x     add second operand low
                    std       OutputArea,y   store the sum low
                    ldd       $02,s     high word
                    adcb      $01,x     add with carry
                    adca      ,x        add with carry
                    std       TempBuffer,y   store the sum high
                    lbra      ReturnTempPtr finish the operation

IntSub32            ldd       $04,s     low word of first operand
                    subd      $02,x     subtract second operand low
                    std       OutputArea,y   store the difference low
                    ldd       $02,s     high word
                    sbcb      $01,x     subtract with borrow
                    sbca      ,x        subtract with borrow
                    std       TempBuffer,y   store the difference high
                    lbra      ReturnTempPtr finish the operation

IntCmp32            ldd       $02,s     high word of first operand
                    cmpd      ,x        compare the high words
                    bne       CmpPushCC differ: result is known
                    ldd       $04,s     compare the low words
                    cmpd      $02,x     compare low word
                    beq       CmpPushCC equal: comparison done
                    bcs       CmpLess2  first operand is smaller
                    lda       #$01      first operand is larger
                    andcc     #$FE      clear carry
                    bra       CmpPushCC go capture the flags

CmpLess2            clra                clear a
                    cmpa      #$01      set carry for less-than
CmpPushCC           pshs      cc        capture the comparison flags
                    ldd       $01,s     fetch saved value
                    std       $05,s     store into result slot
                    puls      cc        restore condition codes
                    leas      4,s        drop the local frame
                    rts                 return to caller

NegLong             lbsr      CopyOperandToTemp copy operand into temp buffer
                    ldd       #$0000    zero for the subtract
                    subd      $02,x     negate the low word
                    std       $02,x     store low word back
                    ldd       #$0000    zero for subtract with borrow
                    sbcb      $01,x     borrow through next byte
                    sbca      ,x        negate the high byte
                    std       ,x        store high word back
                    rts                 return the negated long
                    ldd       ,x        load high word
                    coma                ones-complement high byte
                    comb                ones-complement next byte
                    std       TempBuffer,y   save into temp buffer
                    ldd       $02,x     load low word
                    coma                ones-complement low byte
                    comb                ones-complement next byte
                    leax      TempBuffer,y   point at the temp buffer
                    std       $02,x     store complemented low word
                    rts                 return the complemented long

SignExtendLong      leax      TempBuffer,y   point at temp long buffer
                    std       $02,x     store value as low word
                    tfr       a,b       move high byte for sign extend
                    sex                 sign-extend into d
                    tfr       a,b       propagate sign byte
                    std       ,x        store sign-extended high word
                    rts                 return the widened long
                    leax      TempBuffer,y   point at temp long buffer
                    std       $02,x     store value as low word
                    clr       ,x        zero the high byte
                    clr       $01,x     zero the next high byte
                    rts                 return the zero-extended long

StoreLong           pshs      y         save y register
                    ldy       $04,s     get destination pointer
                    ldd       ,x        load high word from source
                    std       ,y        store high word to destination
                    ldd       $02,x     load low word from source
                    std       LowWordDestination,y     store low word to destination
                    puls      x         restore pointer register
                    exg       y,x       swap the pointers back
                    puls      d         pop the passed word
                    std       ,s        leave result on stack
                    rts                 return

ShiftLeftLong       ldx       $02,s     get pointer to the long
                    pshs      b         save the shift count
                    lbsr      CopyOperandToTemp copy operand into temp
                    puls      b         restore shift count
                    tstb                any bits to shift
                    beq       ShiftLeftLongDone skip when count is zero
ShiftLeftLongLoop   asl       $03,x     shift low byte left
                    rol       $02,x     rotate carry upward
                    rol       $01,x     rotate carry upward
                    rol       ,x        into the high byte
                    decb                decrement the count
                    bne       ShiftLeftLongLoop loop until done
ShiftLeftLongDone   puls      d         pop the passed word
                    std       ,s        store the result
                    rts                 return
                    ldx       $02,s     get pointer to the long
                    pshs      b         save the shift count
                    lbsr      CopyOperandToTemp copy operand into temp
                    puls      b         restore shift count
                    tstb                any bits to shift
                    beq       AsrLongDone skip when count is zero
AsrLongLoop         asr       ,x        arithmetic shift high byte right
                    ror       $01,x     rotate carry downward
                    ror       $02,x     rotate carry downward
                    ror       $03,x     into the low byte
                    decb                decrement the count
                    bne       AsrLongLoop loop until done
AsrLongDone         puls      d         pop the passed word
                    std       ,s        store the result
                    rts                 return

ReturnTempPtr       tfr       cc,a      save condition codes
                    puls      x         pop return word off stack
                    stx       $02,s     stash it below
                    leas      2,s        drop the slot
                    leax      TempBuffer,y   point at temp buffer for return
                    tfr       a,cc      restore condition codes
                    rts                 return the temp pointer

CopyOperandToTemp   ldd       ,x        load high word
                    std       TempBuffer,y   save into temp buffer
                    ldd       $02,x     load low word
                    leax      TempBuffer,y   point x at the temp buffer
                    std       $02,x     store low word into temp
                    rts                 return with x on temp

                    use       lib/imul.asm
                    clr       ResultSignFlag,y   clear the result sign flag
                    leax      >DivUnsigned,pcr point at unsigned divide helper
                    stx       HelperVector,y   store helper vector
                    bra       DivCheckZero join the common divide path

DivSignedSetup      leax      >DivSigned,pcr point at signed divide helper
                    stx       HelperVector,y   store helper vector
                    clr       ResultSignFlag,y   clear the result sign flag
                    tst       $02,s     test the dividend sign
                    bpl       DivCheckZero positive, keep sign flag clear
                    inc       ResultSignFlag,y   mark result negative
DivCheckZero        subd      #$0000    test divisor for zero
                    bne       DivCallHelper nonzero, proceed
                    puls      x         discard helper pointer
                    ldd       ,s++      pop the return word
                    jmp       ,x        return early

DivCallHelper       ldx       $02,s     placeholder
                    pshs      x         pass it to helper
                    jsr       [HelperVector,y] call the divide helper
                    ldd       ,s        grab remainder
                    std       $02,s     stash remainder
                    tfr       x,d       move quotient to d
                    tst       ResultSignFlag,y   is result meant negative
                    beq       DivStoreResult no, skip negate
                    nega                negate quotient
                    negb                negate quotient
                    sbca      #$00      finish the negate
DivStoreResult      std       ,s++      store the result
                    rts                 return

DivUnsigned         subd      #$0000    test divisor for zero
                    beq       DivByZero zero divisor, raise signal
                    pshs      d         save divisor
                    leas      -2,s       make room for quotient
                    clr       ,s        clear quotient high
                    clr       $01,s     clear quotient low
                    bra       DivNormalize enter division

DivByZero           puls      d         restore the word
                    std       ,s        put it back
                    ldd       #$002D    arithmetic-error signal code
                    lbra      SendSignal send the fatal signal

DivSigned           subd      #$0000    test divisor for zero
                    beq       DivByZero zero divisor, raise signal
                    pshs      d         save divisor
                    leas      -2,s       make room for sign flag
                    clr       ,s        clear sign flag
                    clr       $01,s     clear sign flag byte
                    tsta                is divisor negative
                    bpl       DivAbsDividend no, keep it
                    nega                take absolute value
                    negb                take absolute value
                    sbca      #$00      finish the negate
                    inc       $01,s     note divisor sign
                    std       $02,s     store absolute divisor
DivAbsDividend      ldd       $06,s     load the dividend
                    bpl       DivNormalize positive, keep it
                    nega                take absolute value
                    negb                take absolute value
                    sbca      #$00      finish the negate
                    com       $01,s     flip the result sign flag
                    std       $06,s     store absolute dividend
DivNormalize        lda       #$01      seed the bit counter
DivNormalizeLoop    inca                count another bit
                    asl       $03,s     normalize divisor left
                    rol       $02,s     rotate high word
                    bpl       DivNormalizeLoop until top bit is set
                    sta       ,s        save the bit count
                    ldd       $06,s     load the dividend
                    clr       $06,s     clear quotient high
                    clr       $07,s     clear quotient low
DivMainLoop         subd      $02,s     trial subtract divisor
                    bcc       DivBitOne branch if it fit
                    addd      $02,s     restore the dividend
                    andcc     #$FE      clear quotient bit
                    bra       DivShiftQuotient merge the bit

DivBitOne           orcc      #$01      set the quotient bit
DivShiftQuotient    rol       $07,s     shift bit into quotient
                    rol       $06,s     shift quotient high
                    lsr       $02,s     shift divisor right
                    ror       $03,s     rotate divisor low
                    dec       ,s        decrement bit count
                    bne       DivMainLoop loop over the bits
                    std       $02,s     save remainder
                    tst       $01,s     is result negative
                    beq       DivSwapResults no, skip negate
                    ldd       $06,s     negate the quotient
                    nega                negate the quotient
                    negb                negate the quotient
                    sbca      #$00      finish the negate
                    std       $06,s     store signed quotient
DivSwapResults      ldx       $04,s     grab caller pointer
                    ldd       $06,s     load quotient
                    std       $04,s     place quotient for return
                    stx       $06,s     restore caller pointer
                    ldx       $02,s     remainder into x
                    ldd       $04,s     quotient into d
                    leas      6,s        drop the work frame
                    rts                 return quotient and remainder

                    use       lib/shift.asm

SendSignal          std       ErrorCode,y   save the signal code
                    pshs      y,b       preserve y and code
                    os9       F$ID      get own process id
                    puls      y,b       restore y and code
                    os9       F$Send    send the signal
                    rts                 return

GetStat             lda       $05,s     path number
                    ldb       $03,s     getstat function code
                    beq       GetStatDefault zero means default status
                    cmpb      #$01      function one
                    beq       GetStatCall handle it as default call
                    cmpb      #$06      function six
                    beq       GetStatCall handle it as default call
                    cmpb      #$02      function two
                    beq       GetStatDevInfo return device info
                    cmpb      #$05      function five
                    beq       GetStatDevInfo return device info
                    ldb       #$D0      bad function error
                    lbra      FailClearErrno return the error

GetStatDevInfo      pshs      u         save u
                    os9       I$GetStt  issue getstat
                    bcc       GetStatStore branch on success
                    puls      u         restore u
                    lbra      FailClearErrno return the error

GetStatStore        stx       [$08,s]   store returned x into caller
                    ldx       $08,s     reload caller pointer
                    stu       $02,x     store returned u
                    puls      u         restore u
                    clra                clear error high
                    clrb                clear error low
                    rts                 return success

GetStatDefault      ldx       $06,s     load status register block
GetStatCall         os9       I$GetStt  issue getstat
                    lbra      CheckIoResult return the status

                    lda       $05,s     path number
                    ldb       $03,s     setstat function code
                    beq       SetStatSimple zero means simple setstat
                    cmpb      #$02      function two
                    beq       SetStatWithU setstat with extra value
                    ldb       #$D0      bad function error
                    lbra      FailClearErrno return the error

SetStatSimple       ldx       $06,s     load status block
                    os9       I$SetStt  issue setstat
                    lbra      CheckIoResult return the status

SetStatWithU        pshs      u         save u
                    ldx       $08,s     load status block
                    ldu       $0a,s     load extra value
                    os9       I$SetStt  issue setstat
                    puls      u         restore u
                    lbra      CheckIoResult return the status

                    ldx       $02,s     pathname pointer
                    lda       $05,s     access mode
                    os9       I$Open    probe by opening
                    bcs       OpenProbeDone branch if open failed
                    os9       I$Close   close the probe path
OpenProbeDone       lbra      CheckIoResult return the status

OpenPath            ldx       $02,s     pathname pointer
                    lda       $05,s     access mode
                    os9       I$Open    open the file
                    lbcs      FailClearErrno return on error
                    tfr       a,b       path number into b
                    clra                clear high result
                    rts                 return the path number

ClosePath           lda       $03,s     path number
                    os9       I$Close   close the path
                    lbra      CheckIoResult return the status

                    ldx       $02,s     pathname pointer
                    ldb       $05,s     attribute byte
                    os9       I$MakDir  make the directory
                    lbra      CheckIoResult return the status

CreateFile          ldx       $02,s     pathname pointer
                    lda       $05,s     mode byte
                    tfr       a,b       copy to attribute byte
                    andb      #$24      mask attribute bits
                    orb       #$0b      set access permissions
                    os9       I$Create  create the file
                    bcs       CreateExists handle create errors
CreateOk            tfr       a,b       path number into b
                    clra                clear high result
                    rts                 return the path number

CreateExists        cmpb      #$DA      is it file-exists error
                    lbne      FailClearErrno no, propagate the error
                    lda       $05,s     reload the mode
                    bita      #$80      exclusive create requested
                    lbne      FailClearErrno yes, fail the create
                    anda      #$07      mask to access bits
                    ldx       $02,s     pathname pointer
                    os9       I$Open    open the existing file
                    lbcs      FailClearErrno return on error
                    pshs      u,a       save u and mode
                    ldx       #$0000    zero position
                    leau      ,x        zero the offset
                    ldb       #$02      size setstat function
                    os9       I$SetStt  truncate to zero length
                    puls      u,a       restore u and mode
                    bcc       CreateOk  branch on success
                    pshs      b         save the error
                    os9       I$Close   close the path
                    puls      b         restore the error
                    lbra      FailClearErrno return the error

DeletePath          ldx       $02,s     pathname pointer
                    os9       I$Delete  delete the file
                    lbra      CheckIoResult return the status

                    lda       $03,s     path number to duplicate
                    os9       I$Dup     duplicate the path
                    lbcs      FailClearErrno return on error
                    tfr       a,b       new path number into b
                    clra                clear high result
                    rts                 return the path number

ReadPath            pshs      y         save y
                    ldx       $06,s     buffer pointer
                    lda       $05,s     path number
                    ldy       $08,s     byte count
                    pshs      y         save requested count
                    os9       I$Read    read the bytes
ReadCheck           bcc       ReadOk    branch on success
                    cmpb      #$D3      is it end of file
                    bne       ReadErr   no, other error
                    clra                return zero count high
                    clrb                return zero count low
                    puls      pc,y,x    return end of file

ReadErr             puls      y,x       restore registers
                    lbra      FailClearErrno return the error

ReadOk              tfr       y,d       return the byte count
                    puls      pc,y,x    restore and return

ReadLine            pshs      y         save y
                    lda       $05,s     path number
                    ldx       $06,s     buffer pointer
                    ldy       $08,s     byte count
                    pshs      y         save requested count
                    os9       I$ReadLn  read a line
                    bra       ReadCheck share the read check

WritePath           pshs      y         save y
                    ldy       $08,s     byte count
                    beq       WriteOk   nothing to write
                    lda       $05,s     path number
                    ldx       $06,s     buffer pointer
                    os9       I$Write   write the bytes
WriteCheck          bcc       WriteOk   branch on success
                    puls      y         restore y
                    lbra      FailClearErrno return the error

WriteOk             tfr       y,d       return the byte count
                    puls      pc,y      restore and return

WriteLine           pshs      y         save y
                    ldy       $08,s     byte count
                    beq       WriteOk   nothing to write
                    lda       $05,s     path number
                    ldx       $06,s     buffer pointer
                    os9       I$WritLn  write a line
                    bra       WriteCheck share the write check

SeekPath            pshs      u         save u
                    ldd       $0a,s     whence argument
                    bne       CheckWhence not seek from start
                    ldu       #$0000    zero position high
                    ldx       #$0000    zero position low
                    bra       SeekCompute perform the seek

CheckWhence         cmpd      #$0001    whence value one
                    beq       SeekFromCur seek from current
                    cmpd      #$0002    whence value two
                    beq       SeekFromEnd handle seek relative to end
                    ldb       #$F7      set error code for bad whence
SeekErr             clra                clear high byte of errno
                    std       ErrorCode,y   store os-9 error code in work block
                    ldd       #$FFFF    prepare minus one result
                    leax      TempBuffer,y   point at result position buffer
                    std       ,x        store -1 high word
                    std       $02,x     store -1 low word
                    puls      pc,u      return failure

SeekFromEnd         lda       $05,s     load file path number
                    ldb       #$02      getstat code for file size
                    os9       I$GetStt  get end-of-file position
                    bcs       SeekErr   bail out on error
                    bra       SeekCompute go compute seek target

SeekFromCur         lda       $05,s     load file path number
                    ldb       #$05      getstat code for current position
                    os9       I$GetStt  get current file position
                    bcs       SeekErr   bail out on error
SeekCompute         tfr       u,d       low word of base position
                    addd      $08,s     add low word of offset
                    std       OutputArea,y   save new position low word
                    tfr       d,u       keep low word in u
                    tfr       x,d       high word of base position
                    adcb      $07,s     add offset high with carry
                    adca      $06,s     add offset top byte
                    bmi       SeekErr   reject negative position
                    tfr       d,x       high word into x
                    std       TempBuffer,y   save new position high word
                    lda       $05,s     reload file path number
                    os9       I$Seek    seek to computed position
                    bcs       SeekErr   bail out on error
                    leax      TempBuffer,y   point at new position buffer
                    puls      pc,u      return success

GrowHeap            ldd       HeapTop,y   load current heap top
                    pshs      d         save heap top
                    ldd       $04,s     load requested size
                    cmpd      FreeSpace,y   compare against free space
                    bcs       GrowHeapTail enough room so skip allocation
                    addd      HeapTop,y   new top after request
                    pshs      y         save work block pointer
                    subd      ,s        bytes needed from process base
                    os9       F$Mem     request more memory
                    tfr       y,d       new memory top into d
                    puls      y         restore work block pointer
                    bcc       GrowHeapOk allocation succeeded
                    ldd       #$FFFF    prepare failure return
                    leas      2,s        drop saved heap top
                    rts                 return error

GrowHeapOk          std       HeapTop,y   save new heap top
                    addd      FreeSpace,y   add old free count
                    subd      ,s        minus old top gives grown free
                    std       FreeSpace,y   update free space count
GrowHeapTail        leas      2,s        drop saved heap top
                    ldd       FreeSpace,y   load free space
                    pshs      d         save free space
                    subd      $04,s     subtract requested size
                    std       FreeSpace,y   reduce free space count
                    ldd       HeapTop,y   load heap top
                    subd      ,s++      subtract free to get block start
                    pshs      d         save block start pointer
                    clra                zero fill byte
                    ldx       ,s        load fill pointer
ZeroFillLoop2       sta       ,x+       zero one byte
                    cmpx      HeapTop,y   reached heap top yet
                    bcs       ZeroFillLoop2 keep zeroing
                    puls      pc,d      return block pointer

BumpAlloc           ldd       $02,s     load requested size
                    addd      BumpPointer,y   add to current bump pointer
                    bcs       BumpAllocErr overflow so fail
                    cmpd      Limit,y   compare against limit
                    bcc       BumpAllocErr beyond limit so fail
                    pshs      d         save new bump pointer
                    ldx       BumpPointer,y   load old bump pointer
                    clra                zero fill byte
BumpFillLoop        cmpx      ,s        reached new pointer yet
                    bcc       BumpAllocOk done filling
                    sta       ,x+       zero one byte
                    bra       BumpFillLoop continue filling

BumpAllocOk         ldd       BumpPointer,y   old pointer as result
                    puls      x         load new bump pointer
                    stx       BumpPointer,y   store advanced pointer
                    rts                 return old pointer

BumpAllocErr        ldd       #$FFFF    prepare failure return
                    rts                 return error

FailClearErrno      clra                clear high byte
                    std       ErrorCode,y   clear errno in work block
                    ldd       #$FFFF    prepare minus one
                    rts                 return failure

CheckIoResult       bcs       FailClearErrno error on carry set
                    clra                clear high byte
                    clrb                clear low byte
                    rts                 return zero success

exit                lbsr      CleanupStub run cleanup hook
                    lbsr      ClearBufTable flush and close output
_exit               ldd       $02,s     load exit status
                    os9       F$Exit    terminate process
CleanupStub         rts                 empty cleanup stub

* ------------------------------------------------------------------
* WorkBlockImage - cc1-style init image for the work block (see _start):
* rts stub + count/block table + relocation dirs + module-name string.
* ------------------------------------------------------------------
                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       $0003

                    * ---- block1: DP data image  ->  data base
                    fcb       $00,$00
                    fcb       $4B

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
                    fdb       $01EB

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fcb       $00,$02,$00,$04,$00,$08
                    fcb       $00,$10,$00
                    fcb       $20
                    fcb       $00
                    fcb       $40
                    fcb       $00,$80,$01,$00,$02,$00,$04,$00
                    fcb       $08,$00,$10,$00
                    fcb       $20
                    fcb       $00
                    fcb       $40
                    fcb       $00
Pow10Img            fdb       10000,1000,100,10 powers of ten
FreeRootImg         fcb       $00,$00
                    fcb       $44
                    fcb       $C9
                    fcb       $44
                    fcb       $CC
                    fcb       $44
                    fcb       $CF
                    fcb       $44
                    fcb       $D5
                    fcb       $44
                    fcb       $DB
                    fcb       $44
                    fcb       $E0,$00,$00,$00,$00,$00,$00,$00
                    fcb       $80
                    fcb       $20
                    fcb       $00,$00,$00,$00,$00,$00,$84
                    fcb       $48
                    fcb       $00,$00,$00,$00,$00,$00,$87
                    fcb       $7A
                    fcb       $00,$00,$00,$00,$00,$00,$8A,$1C
                    fcb       $40
                    fcb       $00,$00,$00,$00,$00,$8E
                    fcb       $43,$50
                    fcb       $00,$00,$00,$00,$00,$91
                    fcb       $74,$24
                    fcb       $00,$00,$00,$00,$00,$94,$18,$96
                    fcb       $80,$00,$00,$00,$00,$98
                    fcb       $3E
                    fcb       $BC
                    fcb       $20
                    fcb       $00,$00,$00,$00,$9B
                    fcb       $6E,$6B,$28
                    fcb       $00,$00,$00,$00,$9E,$15,$02,$F9
                    fcb       $00,$00,$00,$00,$A2
                    fcb       $2D,$78
                    fcb       $EB,$C5,$AC
                    fcb       $62
                    fcb       $00,$C3
                    fcb       $49
                    fcb       $F2,$C9,$CD,$04
                    fcb       $67,$4F
                    fcb       $E4
StdinImg            fcb       $00,$00,$00,$00,$00,$00,$00
                    fcb       $01,$00,$00,$00,$00,$00
StdoutImg           fcb       $00,$00
                    fcb       $00,$00,$00,$00,$00,$02,$00,$01
                    fcb       $00,$00,$00
StderrImg           fcb       $00,$00,$00,$00,$00
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
                    fcb       $00,$00,$00,$00,$00,$00,$00
CtypeTabImg         fcb       $01
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01
                    fcb       $11,$11,$01,$11,$11,$01,$01,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01
                    fcc       /0               HHHHHHHHHH       BBBBBB/
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02
                    fcc       /      DDDDDD/
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04
                    fcc       /    /
                    fcb       $01

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
                    fdb       $0006

                    * ---- reloc1: text relocation offsets
                    fdb       $0057,$0055,$0053,$0051,$004F,$004D

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       $0001

                    * ---- reloc2: data relocation offsets
                    fdb       $0001

                    * ---- name: trailing module-name string
                    fcc       /c.pass2/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end
