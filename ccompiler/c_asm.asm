                    nam       c.asm
                    ttl       program module

* Annotated 2026-07-17 (Claude Code):
*   - this module arrived already ~half annotated (many meaningful labels
*     and source-style comments); a fill-the-gaps pass named the remaining
*     disassembler L#### labels and commented the remaining instructions,
*     preserving the existing labels and comments
*   - stripped the trailing "* addr bytes cycles" listing annotations to
*     match the house style of the other compiler modules
*   - direct-page globals were already declared as rmb fields, so no DP
*     mislabel fix was needed; the stack-overflow banner was already an fcc
*   - a follow-up pass renamed the disassembler U#### / Y#### data globals to
*     descriptive names (e.g. SrcPtr, PassType, PostByte, RelocPtr, CodeSection)
*     using the intent recorded by the earlier comment pass; symbols whose
*     purpose stays ambiguous, or that are mis-disassembled thunk filler
*     (U0000..U0002), are kept by address so the name never lies
*   - because the descriptive data names are longer than the original fixed
*     U#### tokens, the comment column was widened to column 46 file-wide so
*     the comments line up again; the few operands too long to fit still
*     overflow with a single space, as in the sibling modules
*   - verified byte-identical to the original assembly (module CRC $75DE03)

                    use       defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1

                    mod       eom,name,tylg,atrv,_start,size

U0000               rmb       1
U0001               rmb       1
U0002               rmb       1
U0003               rmb       2
U0005               rmb       2
Y0007               rmb       2
Y0009               rmb       2
Y000B               rmb       2
Y000D               rmb       2
Y000F               rmb       2
Y0011               rmb       2
Y0013               rmb       2
CurFileHand         rmb       2
OutFileHand         rmb       2
CurLineNo           rmb       2
PassType            rmb       2
U001D               rmb       2
TypeField           rmb       2
PtrCounter          rmb       2
ErrCount            rmb       2
U0025               rmb       2
CurValue            rmb       2
NestCount           rmb       2
SkipCount           rmb       2
LineCount           rmb       2
LineNumber          rmb       2
OperandVal          rmb       1
U0032               rmb       1
OffsetVal           rmb       2
IndirFlag           rmb       2
OffsetFlag          rmb       2
OffSizeFlag         rmb       4
ListFlag            rmb       2
RelocFlags          rmb       2
U0041               rmb       2
U0043               rmb       2
U0045               rmb       2
U0047               rmb       2
DataLocation        rmb       2
RelocPtr            rmb       2
TargetAddr          rmb       2
WorkPtr             rmb       2
reldt               rmb       2
FieldPtr            rmb       2
UndefCount          rmb       2
IntRelocCnt         rmb       2
ExtRelocCnt         rmb       2
PassFlag            rmb       1
SectType            rmb       1
TypeFlags           rmb       1
SectFlags           rmb       1
LabelFlags          rmb       1
SectSizeByte        rmb       1
ModeFlags           rmb       1
SrcPtr              rmb       2
LabelField          rmb       2
OpcodeField         rmb       2
SearchStrPtr        rmb       2
OperandPtr          rmb       2
CommentPtr          rmb       2
RelocWrPtr          rmb       2
EntryPtr            rmb       2
SectBasePtr         rmb       2
SectSizePtr         rmb       2
CurPtr              rmb       2
InputPtr            rmb       2
BufPtr              rmb       2
CodeSectPtr         rmb       1
U007D               rmb       7
CodeListHd          rmb       12
DataSectPtr         rmb       1
U0091               rmb       7
DataListHd          rmb       12
BssSectPtr          rmb       1
U00A5               rmb       7
BssListHd           rmb       12
AddrMode            rmb       1
OpcodeClass         rmb       1
PostByte            rmb       1
OperandLow          rmb       2
ColumnFlag          rmb       2
CondState           rmb       1
U00C0               rmb       1
U00C1               rmb       1
U00C2               rmb       1
OptionFlag          rmb       1
FlagByte            rmb       1
ListingFlag         rmb       1
SectCount           rmb       1
U00C7               rmb       1
LineAddr            rmb       2
EmitBufPtr          rmb       2
MacroFlag           rmb       2
MarkerFlag          rmb       2
RepeatCount         rmb       2
CondActive          rmb       2
CurListHd           rmb       2
Marker2Flag         rmb       2
LineCounter         rmb       2
OutStream           rmb       2
LinePtr             rmb       2
SavedLineNo         rmb       2
SavedColumn         rmb       2
CtxDepth            rmb       2
WritePtr            rmb       2
FreeListHd          rmb       2
dpsiz               rmb       30
Y0106               rmb       16
CodeSection         rmb       320
DataSection         rmb       8
Y025E               rmb       28
BssSection          rmb       8
HashTable           rmb       88
BranchHashTbl       rmb       76
DispatchTbl         rmb       12
Y0332               rmb       8
RelocArea           rmb       28
Y0356               rmb       4
Y035A               rmb       4
Y035E               rmb       4
RegisterTbl         rmb       30
OptionTbl           rmb       24
JumpTbl1            rmb       22
JumpTbl2            rmb       24
ClassJumpTbl        rmb       14
WorkBuffer          rmb       4
HeaderRec           rmb       4
Y03DC               rmb       2
Y03DE               rmb       1
Y03DF               rmb       5
Y03E4               rmb       2
Y03E6               rmb       2
Y03E8               rmb       2
Y03EA               rmb       2
Y03EC               rmb       2
Y03EE               rmb       2
Y03F0               rmb       2
Y03F2               rmb       2
SavedStkPtr         rmb       2
ArgArrayPtr         rmb       2
Y03F8               rmb       2
ColumnCount         rmb       2
CharClassTbl        rmb       128
PowTenTbl           rmb       8
Y0484               rmb       2
Y0486               rmb       1
Y0487               rmb       2
_iob                rmb       13
OutBuffer           rmb       13
MsgBuffer           rmb       182
argv                rmb       62
_sttop              rmb       2
memend              rmb       2
TempResult          rmb       2
Y059D               rmb       6
_mtop               rmb       2
_stbot              rmb       2
errno               rmb       2
LabelNameBuf        rmb       10
LineBuffer          rmb       1
Y05B4               rmb       9
SymNameBuf          rmb       10
Y05C7               rmb       120
Y063F               rmb       120
Y06B7               rmb       10
ReptBuffer          rmb       4
Y06C5               rmb       256
FreeNode            rmb       2
ListStart           rmb       30
ListEnd             rmb       2
TreeRoot            rmb       2
Y07E9               rmb       4
Y07ED               rmb       4
Y07F1               rmb       4
Y07F5               rmb       4
Y07F9               rmb       1
Y07FA               rmb       1
Y07FB               rmb       1
Y07FC               rmb       1
Y07FD               rmb       2
IncludeStack        rmb       24
ArgBuffer           rmb       62
BufferEnd           rmb       2
InLineBuffer        rmb       256
ContextArray        rmb       80
OutCursor           rmb       2
ConvBuffer          rmb       10
DigitBuffer         rmb       10
DirectOutFlag       rmb       2
PadChar             rmb       2
SignFlag            rmb       1
RoutinePtr          rmb       2
FreeSpace           rmb       2
end                 rmb       1
U09C7               rmb       3967
size                equ       .

name                fcs       /c.asm/
                    fcb       $04

*
* move bytes (Y=From addr, U=To addr, X=Count)
*
* --- shared C runtime startup (see cstart.i) ---
RTBASE              equ       argv      runtime-globals block base in the data area
DATAEND             equ       end       end of static data / heap start / stack limit
HDRADV              equ       dpsiz     advance to where the non-DP data starts
                    use       lib/cstart.asm

main                pshs      U,D       save u and arguments
                    ldd       8,S       load an argument word
                    pshs      D         push it as a parameter
                    ldd       8,S       load the next argument word
                    pshs      D         push it as a parameter
                    lbsr      ParseOrgDirective call the initialization routine
                    leas      4,S       drop the pushed arguments
                    ldb       <OptionFlag test the option flag
                    beq       SetOptions branch if the flag is clear
                    ldd       #1        prepare value one
                    stb       <FlagByte store into the flag byte
SetOptions          ldd       #4        load option code four
                    stb       <CodeSectPtr store the option
                    ldd       #3        load code three
                    stb       <DataSectPtr store the option
                    ldd       #1        prepare value one
                    stb       <BssSectPtr store the option
                    ldd       #2        load code two
                    stb       <U00A5    store the option
                    stb       <U0091    store the same value
                    stb       <U007D    store the same value
                    ldb       <SectCount test another flag byte
                    beq       InitFileLoop branch if it is clear
                    leax      >ModeWrite,PC point at the option string
                    pshs      X         push the string pointer
                    ldd       >Y03F8,Y  load a data word
                    pshs      D         push it as an argument
                    lbsr      OpenFile  call the conversion routine
                    leas      4,S       drop the arguments
                    std       <OutFileHand save the result
InitFileLoop        leax      >ArgBuffer,Y point at the argument buffer
                    stx       ,S        store as the current pointer
                    lbra      FileLoopTest jump into the file loop test

FileLoop            leax      >ModeRead,PC point at the format string
                    pshs      X         push the string pointer
                    ldd       [<2,S]    load the argument via pointer
                    pshs      D         push it as an argument
                    lbsr      OpenFile  call the conversion routine
                    leas      4,S       drop the arguments
                    std       <CurFileHand save the returned handle
                    clra                clear high byte
                    clrb                clear low byte
                    stb       >Y063F,Y  clear a data flag
                    stb       >Y05C7,Y  clear a data flag
                    clra                clear high byte
                    clrb                clear low byte
                    std       <BssListHd clear a variable
                    std       <DataListHd clear a variable
                    std       <CodeListHd clear a variable
                    clra                clear high byte
                    clrb                clear low byte
                    stb       <PassFlag clear the pass flag
                    lbsr      AssemblePass run the assembly pass
                    ldd       <CurFileHand load the file handle
                    pshs      D         push it as an argument
                    lbsr      Rewind    call the routine
                    leas      2,S       drop the argument
                    ldd       #1        prepare value one
                    stb       <PassFlag set the pass flag
                    bsr       AssemblePass run the second pass
                    lbsr      EmitDataSection finalize processing
                    lbsr      EmitModuleSections emit remaining output
                    ldd       <CurFileHand load the file handle
                    pshs      D         push it as an argument
                    lbsr      fclose    close the file
                    std       ,S++      pop and test the result
                    beq       CloseOk   branch if closed cleanly
                    leax      >MsgFileCloseErr,PC point at the error string
                    pshs      X         push the string pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
CloseOk             ldb       <U00C7    test the flag
                    ble       NextFileIndex branch if not positive
                    lbsr      DumpSymbols call the routine
NextFileIndex       ldd       ,S        load the loop index
                    addd      #2        advance by two
                    std       ,S        store it back
FileLoopTest        ldd       ,S        load the loop index
                    cmpd      >ArgArrayPtr,Y compare against the limit
                    lbcs      FileLoop  loop while below the limit
                    lbsr      CloseMacroFile call the finalization routine
                    ldd       <ErrCount test the error count
                    beq       ExitZero  branch if it is zero
                    ldd       #1        set exit code to one
                    bra       DoExit    skip ahead

ExitZero            clra                clear high byte
                    clrb                clear low byte
DoExit              pshs      D         push the exit code
                    lbsr      exit      call exit
                    leas      2,S       drop the argument
                    puls      PC,U,X    restore registers and return

AssemblePass        pshs      U         save the caller u register
                    leas      -1,S      reserve a local byte
                    lbsr      InitSectionDefaults call the routine
                    clra                clear high byte
                    clrb                clear low byte
                    std       <U0025    clear a variable
                    std       <ErrCount clear the error count
                    leax      >Y06C5,Y  point at a buffer
                    stx       <CurPtr   save as the current pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       <LineCounter clear a variable
                    clra                clear high byte
                    clrb                clear low byte
                    std       <LineAddr clear a variable
                    std       <LineCount clear a variable
                    std       <LineNumber clear a variable
                    std       <CurValue clear a variable
                    std       <SkipCount clear a variable
                    std       <NestCount clear a variable
                    ldb       <PassFlag test the pass flag
                    beq       ListFlagOff branch if it is clear
                    ldb       <FlagByte test a flag
                    beq       ListFlagOff branch if it is clear
                    ldb       <OptionFlag test another flag
                    ble       ListFlagOff branch if not positive
                    ldd       #1        prepare value one
                    bra       StoreListFlag skip ahead

ListFlagOff         clra                clear high byte
                    clrb                clear low byte
StoreListFlag       std       <ListFlag store the listing flag
                    lbsr      SyncLineNumbers call the routine
                    bra       NextLine  enter the loop test

LineLoop            bsr       ParseLine process one line
                    std       -2,S      save and test the result
                    beq       FlushLine branch if it is zero
                    ldd       <SrcPtr   load the line pointer
                    std       <CommentPtr save it
FlushLine           lbsr      EmitListingLine call the routine
NextLine            lbsr      ReadInputLine fetch the next line
                    std       -2,S      save and test the result
                    bne       LineLoop  loop if more lines remain
                    leas      1,S       release the local
                    puls      PC,U      restore registers and return

ParseLine           pshs      U         save the caller u register
                    leas      -3,S      reserve local bytes
                    clra                clear high byte
                    clrb                clear low byte
                    std       <ColumnFlag clear a variable
                    std       <OffSizeFlag clear a variable
                    std       <OffsetFlag clear a variable
                    std       <PtrCounter clear a variable
                    std       <U001D    clear a variable
                    std       <OffsetVal clear a variable
                    std       <PassType clear a variable
                    ldd       <RelocPtr load the relocation pointer
                    std       <WorkPtr  save it
                    beq       NoReloc   branch if there is none
                    leax      >reldt,Y  point at the relocation table
                    stx       <WorkPtr  save the pointer
                    ldd       [>RelocPtr,Y] load via the double pointer
                    std       ,X        store into the table
NoReloc             clra                clear high byte
                    clrb                clear low byte
                    std       <EmitBufPtr clear a variable
                    std       <CommentPtr clear a variable
                    std       <OperandPtr clear a variable
                    std       <OpcodeField clear a variable
                    std       <LabelField clear a variable
                    ldb       <SectType copy a flag byte
                    stb       <TypeFlags store it
                    ldb       <SectFlags copy a flag byte
                    stb       <LabelFlags store it
                    ldb       <SectSizeByte copy a flag byte
                    stb       <ModeFlags store it
                    leax      >ListStart,Y point at a buffer
                    stx       >ListEnd,Y save the pointer
                    ldb       <PassFlag test the pass flag
                    beq       ListFlagOff2 branch if it is clear
                    ldb       <FlagByte test a flag
                    beq       ListFlagOff2 branch if it is clear
                    ldb       <OptionFlag test another flag
                    ble       ListFlagOff2 branch if not positive
                    ldd       #1        prepare value one
                    bra       StoreListFlag2 skip ahead

ListFlagOff2        clra                clear high byte
                    clrb                clear low byte
StoreListFlag2      std       <ListFlag store the listing flag
                    clra                clear high byte
                    clrb                clear low byte
                    std       <Marker2Flag clear a variable
                    ldd       <MarkerFlag test a flag
                    beq       CheckColumn branch if it is clear
                    ldb       <U0002    test a counter
                    ble       ClearListFlag branch if not positive
CheckColumn         ldd       <SkipCount test a variable
                    beq       ScanLineStart branch if it is zero
                    ldb       <CondState test a flag
                    bgt       ScanLineStart branch if positive
ClearListFlag       clra                clear high byte
                    clrb                clear low byte
                    std       <ListFlag clear the listing flag
ScanLineStart       ldb       [>SrcPtr,Y] read the current character
                    stb       2,S       save the character
                    lbeq      LineSuccess branch if end of line
                    ldb       2,S       reload the character
                    cmpb      #'*       compare with a star
                    lbeq      LineSuccess branch if a comment line
                    ldb       2,S       reload the character
                    cmpb      #32       compare with a space
                    beq       ParseOpcode branch if blank
                    ldd       <SrcPtr   load the line pointer
                    std       <LabelField save start of the field
                    ldd       <MacroFlag test a flag
                    bne       LabelLoop branch if it is set
                    ldd       <SkipCount test a variable
                    bne       LabelLoop branch if it is set
                    ldd       <CondActive test a flag
                    bne       LabelLoop branch if it is set
                    lbsr      ParseLabel call the routine
                    std       -2,S      save and test the result
                    bne       LabelDone branch if non-zero
                    leax      >MsgBadLabel,PC point at the message string
                    lbra      EmitErrorMsg report and continue

                    bra       LabelDone skip ahead

LabelCheck          ldb       2,S       reload the character
                    cmpb      #32       compare with a space
                    beq       LabelDone branch if blank
                    ldd       <SrcPtr   load the line pointer
                    addd      #1        advance one character
                    std       <SrcPtr   save it back
LabelLoop           ldb       [>SrcPtr,Y] read the next character
                    stb       2,S       save it
                    bne       LabelCheck loop while non-zero
LabelDone           ldb       [>SrcPtr,Y] read the current character
                    cmpb      #32       compare with a space
                    bne       ParseOpcode branch if not blank
                    clra                clear high byte
                    clrb                clear low byte
                    ldx       <SrcPtr   load the line pointer
                    leax      1,X       advance one character
                    stx       <SrcPtr   save it back
                    stb       -1,X      store the null terminator
ParseOpcode         lbsr      SkipSpaces parse the opcode field
                    stb       2,S       save the result
                    lbeq      LineSuccess branch if end of line
                    leax      >LineBuffer,Y point to the line buffer
                    pshs      X         push the buffer pointer argument
                    lbsr      ScanName  read and classify the token
                    std       ,S++      save the result on the stack
                    lbeq      UnknownOpcode branch to error if zero
                    leax      >LineBuffer,Y point to the line buffer
                    stx       <OpcodeField save the token pointer
                    lbsr      SkipSpaces skip trailing whitespace
                    ldd       <CondActive load the conditional-active flag
                    bne       LookupPseudoOp branch if a conditional is active
                    leax      >LineBuffer,Y point to the line buffer
                    pshs      X         push the token pointer
                    lbsr      LookupSymbol look up the label token
                    leas      2,S       discard the argument
                    std       ,S        save the lookup result
                    beq       LookupPseudoOp branch if not found
                    ldd       <MacroFlag load the macro flag
                    lbne      UndefOpErr branch if inside a macro
                    ldd       ,S        reload the lookup result
                    pshs      D         push it as argument
                    lbsr      PushContext process the resolved label
                    leas      2,S       discard the argument
                    lbra      GoLineDone go to line done

LookupPseudoOp      ldd       >Y0011,Y  load the opcode table pointer
                    pshs      D         push the table
                    leax      >HashTable,Y point to the hash table
                    pshs      X         push it
                    leax      >LineBuffer,Y point to the token
                    pshs      X         push the token
                    lbsr      FindKeyword look up the symbol
                    leas      6,S       discard the arguments
                    std       <EntryPtr save the found entry
                    lbeq      OpNotFound branch if not found
                    ldx       <EntryPtr load the entry pointer
                    ldb       3,X       load the type byte
                    clra                clear the high byte
                    andb      #15       mask the low nibble
                    std       <TypeField save the type field
                    ldd       <CondActive load the conditional flag
                    beq       ChkMacroType branch if not conditional
                    ldd       <TypeField load the type field
                    lbne      ClearPendingDone branch if a nonzero type
                    ldx       <EntryPtr load the entry pointer
                    ldb       2,X       load the subtype byte
                    cmpb      #11       compare with endc
                    lbne      ClearPendingDone branch if not endc
                    lbsr      EndrDirective handle the end conditional
                    lbra      AsmLineExit return from the line routine

ChkMacroType        ldd       <MacroFlag load the macro flag
                    beq       HandleCondSkip branch if not in a macro
                    ldd       <TypeField load the type field
                    cmpd      #4        compare with macro type
                    bne       ChkEndMacro branch if not a macro
                    lbsr      EmitFixedMsg3 emit the macro invocation line
                    lbra      AsmLineExit return

ChkEndMacro         ldd       <TypeField load the type field
                    cmpd      #5        compare with endm type
                    lbne      UndefOpErr branch if not endm
                    lbsr      EmitLineEnd end the macro definition
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       <MacroFlag clear the macro flag
GoLineDone          lbra      LineSuccess go to line done

HandleCondSkip      ldd       <SkipCount load the conditional skip count
                    beq       DispatchPseudo branch if not skipping
                    ldd       <TypeField load the type field
                    cmpd      #1        compare with conditional-start type
                    beq       IncCondLevel branch if a conditional start
                    ldd       <TypeField load the type field
                    cmpd      #2        compare with else/endc type
                    lbne      LineSuccess ignore other directives while skipping
                    ldd       <SkipCount load the skip count
                    addd      #-1       decrement the nesting level
                    std       <SkipCount save the skip count
                    ldd       <SkipCount reload the skip count
                    lbeq      LineSuccess done if back to zero
                    ldx       <EntryPtr load the entry pointer
                    ldb       2,X       load the subtype byte
                    lbeq      LineSuccess skip if zero
IncCondLevel        ldd       <SkipCount load the skip count
                    addd      #1        increment the nesting level
                    std       <SkipCount save the skip count
                    lbra      LineSuccess go to line done

DispatchPseudo      ldx       <EntryPtr load the entry pointer
                    ldb       2,X       load the pseudo-op index
                    stb       <OpcodeClass save the opcode index
                    ldd       <SrcPtr   load the source pointer
                    std       <OperandPtr save the operand pointer
                    ldd       <TypeField load the type field
                    aslb                multiply the index by two
                    rola                carry into the high byte
                    leax      >DispatchTbl,Y point to the dispatch table
                    leax      D,X       index into the table
                    jsr       [,X]      call the pseudo-op handler
                    std       -2,S      save the handler result
                    lbeq      ReturnFail branch if it returned zero
                    lbra      ChkTokenConsumed continue processing the line

OpNotFound          ldd       <CondActive load the conditional flag
                    beq       ChkInMacro branch if not conditional
ClearPendingDone    clra                clear the high byte
                    clrb                clear the low byte
                    std       <ListFlag clear the pending flag
                    lbra      LineSuccess go to line done

ChkInMacro          ldd       <MacroFlag load the macro flag
                    beq       ChkCondActive branch if not in a macro
UndefOpErr          lbsr      EmitListLine report an undefined opcode
                    lbra      LineSuccess go to line done

ChkCondActive       ldd       <SkipCount load the skip count
                    beq       ChkBranchOpcode branch if not skipping
                    ldd       <ListFlag load the pending flag
                    lbeq      LineSuccess done if not pending
                    ldb       [>SrcPtr,Y] load the current character
                    lbeq      LineSuccess done if end of line
                    ldd       <SrcPtr   load the source pointer
                    std       <OperandPtr save the operand pointer
                    bra       AdvanceCharLoop enter the scan loop

ScanCharLoop        ldb       [>SrcPtr,Y] load the current character
                    cmpb      #32       compare with a space
                    beq       TokenScanned stop at the space
AdvanceCharLoop     ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance the pointer
                    stx       <SrcPtr   save the pointer
                    ldb       ,X        load the next character
                    bne       ScanCharLoop loop until end of token
TokenScanned        ldb       [>SrcPtr,Y] load the current character
                    lbeq      LineSuccess done if end of line
                    clra                clear the high byte
                    clrb                clear the low byte
                    ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance the pointer
                    stx       <SrcPtr   save the pointer
                    stb       -1,X      terminate the token
                    lbra      LineSuccess go to line done

ChkBranchOpcode     leax      >CodeSection,Y point to the reference address
                    cmpx      <SectBasePtr compare with the current pointer
                    bne       LookupMainOp branch if not at line start
                    ldb       >LineBuffer,Y load the first token character
                    cmpb      #'b       compare with lowercase b
                    beq       LookupBranchOp branch if a branch opcode
                    ldb       >LineBuffer,Y load the first token character
                    cmpb      #'B       compare with uppercase b
                    bne       LookupMainOp branch if not a branch opcode
LookupBranchOp      ldd       >Y0013,Y  load the branch table pointer
                    pshs      D         push the table
                    leax      >BranchHashTbl,Y point to the branch hash table
                    pshs      X         push it
                    leax      >LineBuffer,Y point to the token
                    pshs      X         push the token
                    lbsr      FindKeyword look up the branch opcode
                    leas      6,S       discard the arguments
                    std       <EntryPtr save the found entry
LookupMainOp        ldd       <EntryPtr load the entry pointer
                    bne       ProcessOpcode branch if already found
                    ldd       <SectSizePtr load the main table pointer
                    pshs      D         push the table
                    ldd       <SectBasePtr push the hash table pointer
                    pshs      D         push it
                    leax      >LineBuffer,Y point to the token
                    pshs      X         push the token
                    lbsr      FindKeyword look up the opcode
                    leas      6,S       discard the arguments
                    std       <EntryPtr save the found entry
ProcessOpcode       ldd       <EntryPtr load the entry pointer
                    lbeq      UnknownOpcode branch if opcode unknown
                    ldx       <EntryPtr load the entry pointer
                    ldb       3,X       load the type byte
                    clra                clear the high byte
                    andb      #15       mask the low nibble
                    std       <TypeField save the type field
                    ldd       #1        default operand count to one
                    std       <PassType save the operand count
                    leax      >OpcodeClass,Y point to the opcode-index byte
                    stx       <EmitBufPtr save the operand pointer
                    ldx       <EntryPtr load the entry pointer
                    ldb       3,X       load the type byte
                    clra                clear the high byte
                    andb      #48       mask the mode bits
                    stb       <AddrMode save the addressing mode
                    beq       CallOpHandler branch if simple mode
                    ldb       <AddrMode load the mode bits
                    clra                clear the high byte
                    andb      #16       test bit four
                    beq       SetMode17 branch if not set
                    ldd       #16       select mode value sixteen
                    bra       StoreMode store it

SetMode17           ldd       #17       select mode value seventeen
StoreMode           stb       <AddrMode save the mode value
                    ldd       #2        two operand fields
                    std       <PassType save the operand count
                    leax      >AddrMode,Y point to the mode buffer
                    stx       <EmitBufPtr save the operand pointer
CallOpHandler       ldx       <EntryPtr load the entry pointer
                    ldb       2,X       load the opcode base byte
                    stb       <OpcodeClass save the opcode value
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       <OperandLow clear the operand value
                    stb       <PostByte clear the operand flag
                    ldd       <SrcPtr   load the source pointer
                    std       <OperandPtr save the operand pointer
                    ldd       <TypeField load the type field
                    aslb                multiply the index by two
                    rola                carry into the high byte
                    ldx       <RelocWrPtr load the handler table base
                    leax      D,X       index into the table
                    jsr       [,X]      call the opcode handler
                    std       -2,S      save the handler result
                    bne       EmitOperand branch if it succeeded
ReturnFail          clra                clear the high byte
                    clrb                clear the low byte
                    bra       AsmLineExit return zero

EmitOperand         ldd       <PassType load the operand count
                    pshs      D         push the count
                    ldd       <EmitBufPtr load the operand buffer
                    pshs      D         push it
                    lbsr      UpdateSectionSize emit the operand bytes
                    leas      4,S       discard the arguments
ChkTokenConsumed    ldd       <OperandPtr load the operand pointer
                    cmpd      <SrcPtr   compare with the source pointer
                    bne       AdvancePastToken branch if it advanced
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       <OperandPtr clear the operand pointer
                    bra       LineSuccess go to line done

AdvancePastToken    ldd       <OperandPtr load the operand pointer
                    beq       LineSuccess done if none
                    ldb       [>SrcPtr,Y] load the current character
                    beq       LineSuccess done if end of line
                    clra                clear the high byte
                    clrb                clear the low byte
                    ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance the pointer
                    stx       <SrcPtr   save the pointer
                    stb       -1,X      terminate the token
                    lbsr      SkipSpaces skip trailing whitespace
LineSuccess         ldd       #1        return success value one
                    bra       AsmLineExit return

UnknownOpcode       ldd       <SrcPtr   load the source pointer
                    std       <CommentPtr save the comment pointer
                    leax      >MsgBadMnemonic,PC point to the error format string
EmitErrorMsg        pshs      X         push the format string
                    lbsr      EmitMessageLine emit the error line
                    leas      2,S       discard the argument
AsmLineExit         leas      3,S       discard the local frame
                    puls      PC,U      return

EmitListingLine     pshs      U         save the caller u register
                    ldd       <ListFlag load the pending-line flag
                    lbeq      EmitLineRet return if nothing pending
                    ldd       <U0003    load the current address
                    addd      #-3       bias the address
                    cmpd      <LineAddr compare with the line address
                    bge       ClearPendingFlag branch if in range
                    lbsr      SyncLineNumbers flush the output buffer
ClearPendingFlag    clra                clear the high byte
                    clrb                clear the low byte
                    std       <ListFlag clear the pending flag
                    ldb       <ListingFlag load the listing flag
                    bne       ChkHaveFields branch if listing enabled
                    ldd       <LineNumber load the line number
                    pshs      D         push the line number
                    leax      >FmtDecimal5,PC point to the format string
                    pshs      X         push it
                    lbsr      FormatToScratch format into the buffer
                    leas      4,S       discard the arguments
ChkHaveFields       ldd       <LabelField load the label field
                    bne       BuildHexBytes branch if a label is present
                    ldd       <OpcodeField load the opcode field
                    bne       BuildHexBytes branch if an opcode is present
                    ldd       <PassType load the operand count
                    lble      ChkPrintLine skip if no operands
BuildHexBytes       leas      -2,S      reserve a local slot
                    ldu       <EmitBufPtr load the operand buffer pointer
                    ldd       <WorkPtr  load the symbol pointer
                    beq       AppendAddrField branch if no symbol
                    ldd       [>WorkPtr,Y] load the symbol value
                    pshs      D         push the value
                    leax      >FmtHex4,PC point to the format string
                    pshs      X         push it
                    lbsr      FormatToScratch format into the buffer
                    bra       AppendSeparator continue

AppendAddrField     leax      >OutBuffer,Y point to the output buffer
                    pshs      X         push the buffer
                    leax      >FmtSpaces5,PC point to the format string
                    pshs      X         push it
                    lbsr      Fputs     append to the buffer
AppendSeparator     leas      4,S       discard the arguments
                    leax      >OutBuffer,Y point to the output buffer
                    pshs      X         push the buffer
                    ldd       <ColumnFlag load the column flag
                    beq       UseSpaceSep branch if not set
                    ldd       #61       use an equals sign
                    bra       PushSeparator store the separator

UseSpaceSep         ldd       #32       use a space character
PushSeparator       pshs      D         push the separator
                    lbsr      PutChar   append the character
                    leas      4,S       discard the arguments
                    stu       -2,S      save the operand pointer
                    beq       BlankHexField branch if no bytes to emit
                    clra                clear the high byte
                    clrb                clear the low byte
                    bra       StoreByteIdx enter the byte loop

HexByteLoop         ldd       ,S        load the byte index
                    cmpd      <PassType compare with the count
                    bge       PadHexField branch if past the end
                    ldb       ,U+       load the next operand byte
                    clra                clear the high byte
                    pshs      D         push the byte
                    leax      >FmtHex2,PC point to the hex format
                    pshs      X         push it
                    lbsr      FormatToScratch format into the buffer
                    bra       NextHexByte continue

PadHexField         leax      >OutBuffer,Y point to the output buffer
                    pshs      X         push the buffer
                    leax      >FmtSpaces2,PC point to the pad format
                    pshs      X         push it
                    lbsr      Fputs     append to the buffer
NextHexByte         leas      4,S       discard the arguments
                    ldd       ,S        load the byte index
                    addd      #1        increment the index
StoreByteIdx        std       ,S        save the byte index
                    ldd       ,S        load the byte index
                    cmpd      #5        compare with the field width
                    blt       HexByteLoop loop over the bytes
                    bra       HexFieldDone finish the hex field

BlankHexField       leax      >OutBuffer,Y point to the output buffer
                    pshs      X         push the buffer
                    leax      >FmtSpaces10,PC point to the blank format
                    pshs      X         push it
                    lbsr      Fputs     append to the buffer
                    leas      4,S       discard the arguments
HexFieldDone        leas      2,S       discard the local slot
ChkPrintLine        ldd       <LabelField load the label field
                    bne       DefaultLabel branch if a label is present
                    ldd       <OpcodeField load the opcode field
                    lbeq      ChkComment skip if nothing to print
DefaultLabel        ldd       <LabelField load the label field
                    bne       DefaultOpcode branch if a label is present
                    leax      >NullStrA,PC point to an empty string
                    stx       <LabelField default the label to empty
DefaultOpcode       ldd       <OpcodeField load the opcode field
                    bne       DefaultOperand branch if an opcode is present
                    leax      >NullStrB,PC point to an empty string
                    stx       <OpcodeField default the opcode to empty
DefaultOperand      ldd       <OperandPtr load the operand field
                    bne       FormatLabelOp branch if an operand is present
                    leax      >NullStrC,PC point to an empty string
                    stx       <OperandPtr default the operand to empty
FormatLabelOp       ldd       <OpcodeField load the opcode field
                    pshs      D         push the opcode
                    ldd       <LabelField load the label field
                    pshs      D         push the label
                    ldd       <MarkerFlag load the first marker flag
                    beq       UseSpaceMark branch if not set
                    ldd       <Marker2Flag load the second marker flag
                    bne       UseSpaceMark branch if set
                    ldd       #43       use a plus sign marker
                    bra       AppendLabelOp store the separator

UseSpaceMark        ldd       #32       use a space character
AppendLabelOp       pshs      D         push the separator
                    leax      >FmtListLine,PC point to the format string
                    pshs      X         push it
                    lbsr      FormatToScratch format into the buffer
                    leas      8,S       discard the arguments
                    ldd       <OperandPtr load the operand field
                    pshs      D         push the operand
                    ldd       <Marker2Flag load the marker flag
                    beq       UseAltFormat branch if not set
                    leax      >FmtStr,PC point to the format string
                    bra       FormatOperand use it

UseAltFormat        leax      >FmtStr10,PC point to the alternate format
FormatOperand       tfr       X,D       move the format into the register
                    pshs      D         push the format string
                    lbsr      FormatToScratch format into the buffer
                    leas      4,S       discard the arguments
ChkComment          ldd       <CommentPtr load the comment pointer
                    beq       EmitNewline branch if no comment
                    ldd       <CommentPtr load the comment pointer
                    pshs      D         push the comment
                    leax      >FmtSpaceStr,PC point to the format string
                    pshs      X         push it
                    lbsr      FormatToScratch format into the buffer
                    leas      4,S       discard the arguments
EmitNewline         leax      >OutBuffer,Y point to the output buffer
                    pshs      X         push the buffer
                    ldd       #13       load a carriage return
                    pshs      D         push it
                    lbsr      PutChar   append the newline
                    leas      4,S       discard the arguments
                    ldd       <LineAddr load the line address
                    addd      #1        increment the line count
                    std       <LineAddr save the line count
                    puls      PC,U      return

EmitFixedMsg1       pshs      U         save the caller u register
                    leax      >MsgBadRegList,PC point to the message string
                    pshs      X         push the message
                    bsr       EmitMessageLine emit the message line
                    puls      PC,U,X    return

EmitFixedMsg2       pshs      U         save the caller u register
                    leax      >MsgBadRegName,PC point to the message string
                    pshs      X         push the message
                    bsr       EmitMessageLine emit the message line
                    puls      PC,U,X    return

EmitFixedMsg3       pshs      U         save the caller u register
                    leax      >MsgNestedMacro,PC point to the message string
                    pshs      X         push the message
                    bsr       EmitMessageLine emit the message line
                    puls      PC,U,X    return

EmitMessageLine     pshs      U         save the caller u register
                    ldb       <PassFlag load the listing-enabled flag
                    beq       IncLineCounter skip output if disabled
                    ldd       #1        set the pending flag
                    std       <ListFlag save the pending flag
                    ldd       <LineAddr load the line address
                    beq       FlushBuffer flush if zero
                    ldd       <U0003    load the current address
                    addd      #-4       bias the address
                    cmpd      <LineAddr compare with the line address
                    bge       WriteMessage branch if in range
FlushBuffer         lbsr      SyncLineNumbers flush the output buffer
WriteMessage        ldd       4,S       load the message argument
                    pshs      D         push the message
                    leax      >FmtErrorLine,PC point to the format string
                    pshs      X         push it
                    lbsr      FormatToScratch format into the buffer
                    leas      4,S       discard the arguments
                    ldd       <LineAddr load the line address
                    addd      #1        increment the line count
                    std       <LineAddr save the line count
IncLineCounter      ldd       <ErrCount load the source line counter
                    addd      #1        increment the counter
                    std       <ErrCount save the counter
EmitLineRet         clra                clear the high byte
                    clrb                clear the low byte
                    puls      PC,U      return

FatalError          pshs      U         save the caller u register
                    ldd       4,S       load the message argument
                    pshs      D         push the message
                    leax      >FmtAsmError,PC point to the format string
                    pshs      X         push it
                    leax      >MsgBuffer,Y point to the message buffer
                    pshs      X         push the buffer
                    lbsr      Vsprintf  format the error message
                    leas      6,S       discard the arguments
                    ldd       >errno,Y  load the error number
                    pshs      D         push the errno value
                    lbsr      exit      terminate the program
                    puls      PC,U,X    return unreached

ModeWrite           fcb       $77
                    fcb       C$NULL
ModeRead            fcb       $72
                    fcb       C$NULL
MsgFileCloseErr     fcc       "file close error"
                    fcb       C$NULL
MsgBadLabel         fcc       "bad label"
                    fcb       C$NULL
MsgBadMnemonic      fcc       "bad mnemonic"
                    fcb       C$NULL
FmtDecimal5         fcc       "%05d"
                    fcb       C$NULL
FmtHex4             fcc       " %04x"
                    fcb       C$NULL
FmtSpaces5          fcc       "     "
                    fcb       C$NULL
FmtHex2             fcc       "%02x"
                    fcb       C$NULL
FmtSpaces2          fcc       "  "
                    fcb       C$NULL
FmtSpaces10         fcc       "          "
                    fcb       C$NULL
NullStrA            fcb       C$NULL
NullStrB            fcb       C$NULL
NullStrC            fcb       C$NULL
FmtListLine         fcc       "%c%-8s %-5s "
                    fcb       C$NULL
FmtStr              fcc       "%s"
                    fcb       C$NULL
FmtStr10            fcc       "%-10s"
                    fcb       C$NULL
FmtSpaceStr         fcc       " %s"
                    fcb       C$NULL
MsgBadRegList       fcc       "bad register list"
                    fcb       C$NULL
MsgBadRegName       fcc       "bad register name"
                    fcb       C$NULL
MsgNestedMacro      fcc       "nested MACRO definitions"
                    fcb       C$NULL
FmtErrorLine        fcc       "*** error - %s ***"
                    fcb       C$CR
                    fcb       C$NULL
FmtAsmError         fcc       "asm: %s"
                    fcb       C$CR
                    fcb       C$NULL
FindKeyword         pshs      U,D       save registers and frame
                    leau      >Y06B7,Y  point at the output buffer
                    bra       CopyLoopTest enter the copy loop test

CopyCharLoop        ldb       [<6,S]    load current source char via pointer
                    sex                 sign extend char to word
                    leax      >CharClassTbl,Y point at character-class table
                    leax      D,X       index the table by the char
                    ldb       ,X        load the class flags
                    clra                clear the high byte for indexing
                    andb      #4        test the uppercase-letter flag
                    beq       ForceLower not a letter, force lowercase
                    ldb       [<6,S]    reload the source char
                    sex                 sign-extend the reloaded char
                    bra       StoreCopyChar store the char unchanged

ForceLower          ldb       [<6,S]    reload the source char
                    sex                 sign-extend the reloaded char
                    orb       #32       convert letter to lowercase
StoreCopyChar       stb       ,U        store char into output buffer
                    leau      1,U       advance the buffer pointer
                    ldd       6,S       load the source pointer
                    addd      #1        advance past this char
                    std       6,S       save the source pointer
CopyLoopTest        ldb       [<6,S]    load the next source char
                    bne       CopyCharLoop loop while char is nonzero
                    clra                clear the high byte
                    clrb                form the null terminator
                    stb       ,U        null-terminate the buffer
                    ldd       8,S       load the table pointer argument
                    bra       ScanLoopTest begin the table scan

ScanEntryLoop       ldu       [,S]      load pointer to the table entry
                    leax      >Y06B7,Y  point at the search string
                    stx       <SearchStrPtr save the search string pointer
                    bra       CmpLoopTop enter the compare loop

CmpCharLoop         ldb       ,U        load a table entry char
                    sex                 sign-extend the table char
                    pshs      D         save it for the compare
                    ldx       <SearchStrPtr load the search string pointer
                    leax      1,X       advance the pointer
                    stx       <SearchStrPtr save it back
                    ldb       -1,X      load the search string char
                    sex                 sign-extend the search char
                    cmpd      ,S++      compare the two chars
                    bne       CheckEntryEnd mismatch, try next entry
                    leau      1,U       advance the table pointer
CmpLoopTop          ldb       ,U        load the next table char
                    bne       CmpCharLoop continue while entry char nonzero
CheckEntryEnd       ldb       ,U        check for end of table entry
                    bne       NextTableEntry not fully matched, next entry
                    ldd       ,S        load the matched entry index
                    puls      PC,U,X    return the index

NextTableEntry      ldd       ,S        load the current index
                    addd      #4        step to the next entry
ScanLoopTest        std       ,S        save the index
                    ldd       ,S        load the index
                    cmpd      10,S      compare against the entry count
                    bcs       ScanEntryLoop loop while entries remain
                    clra                clear the result high byte
                    clrb                return zero for not found
                    puls      PC,U,X    return to caller

Lt_08EE             fcc       "psect"
                    fcb       C$NULL
Lt_08F4             fcc       "csect"
                    fcb       C$NULL
Lt_08FA             fcc       "vsect"
                    fcb       C$NULL
Lt_0900             fcc       "end"
                    fcb       C$NULL
Lt_0904             fcc       "lbra"
                    fcb       C$NULL
Lt_0909             fcc       "lbsr"
                    fcb       C$NULL
Lt_090E             fcc       "orcc"
                    fcb       C$NULL
Lt_0913             fcc       "andcc"
                    fcb       C$NULL
Lt_0919             fcc       "cwai"
                    fcb       C$NULL
Lt_091E             fcc       "addd"
                    fcb       C$NULL
Lt_0923             fcc       "subd"
                    fcb       C$NULL
Lt_0928             fcc       "ldd"
                    fcb       C$NULL
Lt_092C             fcc       "ldx"
                    fcb       C$NULL
Lt_0930             fcc       "ldu"
                    fcb       C$NULL
Lt_0934             fcc       "cmpx"
                    fcb       C$NULL
Lt_0939             fcc       "jsr"
                    fcb       C$NULL
Lt_093D             fcc       "std"
                    fcb       C$NULL
Lt_0941             fcc       "stx"
                    fcb       C$NULL
Lt_0945             fcc       "stu"
                    fcb       C$NULL
Lt_0949             fcc       "cmpu"
                    fcb       C$NULL
Lt_094E             fcc       "cmps"
                    fcb       C$NULL
Lt_0953             fcc       "cmpd"
                    fcb       C$NULL
Lt_0958             fcc       "cmpy"
                    fcb       C$NULL
Lt_095D             fcc       "ldy"
                    fcb       C$NULL
Lt_0961             fcc       "lds"
                    fcb       C$NULL
Lt_0965             fcc       "sty"
                    fcb       C$NULL
Lt_0969             fcc       "sts"
                    fcb       C$NULL
Lt_096D             fcc       "add"
                    fcb       C$NULL
Lt_0971             fcc       "cmp"
                    fcb       C$NULL
Lt_0975             fcc       "sub"
                    fcb       C$NULL
Lt_0979             fcc       "sbc"
                    fcb       C$NULL
Lt_097D             fcc       "and"
                    fcb       C$NULL
Lt_0981             fcc       "bit"
                    fcb       C$NULL
Lt_0985             fcc       "ld"
                    fcb       C$NULL
Lt_0988             fcc       "st"
                    fcb       C$NULL
Lt_098B             fcc       "eor"
                    fcb       C$NULL
Lt_098F             fcc       "adc"
                    fcb       C$NULL
Lt_0993             fcc       "org"
                    fcb       C$NULL
Lt_0997             fcc       "or"
                    fcb       C$NULL
Lt_099A             fcc       "neg"
                    fcb       C$NULL
Lt_099E             fcc       "com"
                    fcb       C$NULL
Lt_09A2             fcc       "lsr"
                    fcb       C$NULL
Lt_09A6             fcc       "ror"
                    fcb       C$NULL
Lt_09AA             fcc       "asr"
                    fcb       C$NULL
Lt_09AE             fcc       "lsl"
                    fcb       C$NULL
Lt_09B2             fcc       "asl"
                    fcb       C$NULL
Lt_09B6             fcc       "rol"
                    fcb       C$NULL
Lt_09BA             fcc       "dec"
                    fcb       C$NULL
Lt_09BE             fcc       "inc"
                    fcb       C$NULL
Lt_09C2             fcc       "tst"
                    fcb       C$NULL
Lt_09C6             fcc       "jmp"
                    fcb       C$NULL
Lt_09CA             fcc       "clr"
                    fcb       C$NULL
Lt_09CE             fcc       "rts"
                    fcb       C$NULL
Lt_09D2             fcc       "mul"
                    fcb       C$NULL
Lt_09D6             fcc       "nop"
                    fcb       C$NULL
Lt_09DA             fcc       "sync"
                    fcb       C$NULL
Lt_09DF             fcc       "daa"
                    fcb       C$NULL
Lt_09E3             fcc       "sex"
                    fcb       C$NULL
Lt_09E7             fcc       "abx"
                    fcb       C$NULL
Lt_09EB             fcc       "rti"
                    fcb       C$NULL
Lt_09EF             fcc       "swi2"
                    fcb       C$NULL
Lt_09F4             fcc       "swi3"
                    fcb       C$NULL
Lt_09F9             fcc       "swi"
                    fcb       C$NULL
Lt_09FD             fcc       "leax"
                    fcb       C$NULL
Lt_0A02             fcc       "leay"
                    fcb       C$NULL
Lt_0A07             fcc       "leas"
                    fcb       C$NULL
Lt_0A0C             fcc       "leau"
                    fcb       C$NULL
Lt_0A11             fcc       "tfr"
                    fcb       C$NULL
Lt_0A15             fcc       "exg"
                    fcb       C$NULL
Lt_0A19             fcc       "pshs"
                    fcb       C$NULL
Lt_0A1E             fcc       "puls"
                    fcb       C$NULL
Lt_0A23             fcc       "pshu"
                    fcb       C$NULL
Lt_0A28             fcc       "pulu"
                    fcb       C$NULL
Lt_0A2D             fcc       "lb"
                    fcb       C$NULL
Lt_0A30             fcc       "fcc"
                    fcb       C$NULL
Lt_0A34             fcc       "fdb"
                    fcb       C$NULL
Lt_0A38             fcc       "fcs"
                    fcb       C$NULL
Lt_0A3C             fcc       "fcb"
                    fcb       C$NULL
Lt_0A40             fcc       "rzb"
                    fcb       C$NULL
Lt_0A44             fcc       "vsect"
                    fcb       C$NULL
Lt_0A4A             fcc       "csect"
                    fcb       C$NULL
Lt_0A50             fcc       "ends"
                    fcb       C$NULL
Lt_0A55             fcc       "setdp"
                    fcb       C$NULL
Lt_0A5B             fcc       "os9"
                    fcb       C$NULL
Lt_0A5F             fcc       "rmb"
                    fcb       C$NULL
Lt_0A63             fcc       "ends"
                    fcb       C$NULL
Lt_0A68             fcc       "rmb"
                    fcb       C$NULL
Lt_0A6C             fcc       "fcc"
                    fcb       C$NULL
Lt_0A70             fcc       "fdb"
                    fcb       C$NULL
Lt_0A74             fcc       "fcs"
                    fcb       C$NULL
Lt_0A78             fcc       "fcb"
                    fcb       C$NULL
Lt_0A7C             fcc       "rzb"
                    fcb       C$NULL
Lt_0A80             fcc       "ends"
                    fcb       C$NULL
Lt_0A85             fcc       "rmb"
                    fcb       C$NULL
Lt_0A89             fcc       "ends"
                    fcb       C$NULL
Lt_0A8E             fcc       "nam"
                    fcb       C$NULL
Lt_0A92             fcc       "opt"
                    fcb       C$NULL
Lt_0A96             fcc       "ttl"
                    fcb       C$NULL
Lt_0A9A             fcc       "pag"
                    fcb       C$NULL
Lt_0A9E             fcc       "spc"
                    fcb       C$NULL
Lt_0AA2             fcc       "use"
                    fcb       C$NULL
Lt_0AA6             fcc       "fail"
                    fcb       C$NULL
Lt_0AAB             fcc       "rept"
                    fcb       C$NULL
Lt_0AB0             fcc       "endr"
                    fcb       C$NULL
Lt_0AB5             fcc       "ifeq"
                    fcb       C$NULL
Lt_0ABA             fcc       "ifne"
                    fcb       C$NULL
Lt_0ABF             fcc       "iflt"
                    fcb       C$NULL
Lt_0AC4             fcc       "ifle"
                    fcb       C$NULL
Lt_0AC9             fcc       "ifge"
                    fcb       C$NULL
Lt_0ACE             fcc       "ifgt"
                    fcb       C$NULL
Lt_0AD3             fcc       "ifp1"
                    fcb       C$NULL
Lt_0AD8             fcc       "endc"
                    fcb       C$NULL
Lt_0ADD             fcc       "else"
                    fcb       C$NULL
Lt_0AE2             fcc       "equ"
                    fcb       C$NULL
Lt_0AE6             fcc       "set"
                    fcb       C$NULL
Lt_0AEA             fcc       "macro"
                    fcb       C$NULL
Lt_0AF0             fcc       "endm"
                    fcb       C$NULL
Lt_0AF5             fcc       "bsr"
                    fcb       C$NULL
Lt_0AF9             fcc       "bra"
                    fcb       C$NULL
Lt_0AFD             fcc       "brn"
                    fcb       C$NULL
Lt_0B01             fcc       "bhi"
                    fcb       C$NULL
Lt_0B05             fcc       "bls"
                    fcb       C$NULL
Lt_0B09             fcc       "bhs"
                    fcb       C$NULL
Lt_0B0D             fcc       "bcc"
                    fcb       C$NULL
Lt_0B11             fcc       "blo"
                    fcb       C$NULL
Lt_0B15             fcc       "bcs"
                    fcb       C$NULL
Lt_0B19             fcc       "bne"
                    fcb       C$NULL
Lt_0B1D             fcc       "beq"
                    fcb       C$NULL
Lt_0B21             fcc       "bvc"
                    fcb       C$NULL
Lt_0B25             fcc       "bvs"
                    fcb       C$NULL
Lt_0B29             fcc       "bpl"
                    fcb       C$NULL
Lt_0B2D             fcc       "bmi"
                    fcb       C$NULL
Lt_0B31             fcc       "bge"
                    fcb       C$NULL
Lt_0B35             fcc       "blt"
                    fcb       C$NULL
Lt_0B39             fcc       "bgt"
                    fcb       C$NULL
Lt_0B3D             fcc       "ble"
                    fcb       C$NULL

Lt_0B41             pshs      U         save the caller u register
                    ldd       #3        three bytes for this directive
                    std       <PassType set location-counter increment to three
                    lbra      DispatchMnemonic jump to emit the bytes

Lt_0B4B             pshs      U         save the caller u register
                    ldd       #2        two bytes for this operand
                    std       <PassType set size to two bytes
                    lbsr      ParseHashOperand evaluate the operand expression
                    std       -2,S      save the result
                    lbeq      HandleZeroExpr branch if evaluation failed
                    ldb       <ModeFlags load the flag byte
                    sex                 sign-extend the flag byte
                    orb       #8        set the flag bit
                    stb       <ModeFlags store the flags back
                    lbsr      ParseReloc emit the relocation record
                    ldd       <OperandVal load the evaluated value
                    stb       <PostByte store the low byte
                    lbra      RetTrue   jump to continue

Lt_0B6C             pshs      U         save the caller u register
                    lbsr      ParseHashOperand evaluate the operand expression
                    std       -2,S      save the result
                    beq       EmitByteErr branch on error
                    ldd       <PassType load the location counter
                    addd      #2        add two bytes
                    std       <PassType save the location counter
                    lbsr      ParseValue emit the word value
                    ldd       <OperandVal load the evaluated value
                    std       <PostByte store it
                    bra       EmitByteDone finish the directive

Lt_0B85             pshs      U         save the caller u register
                    ldb       [>SearchStrPtr,Y] load the suffix char via pointer
                    sex                 sign-extend the suffix char
                    tfr       D,X       move it into X
                    bra       CheckByteSuffix dispatch on the suffix

ByteSuffixB         ldb       <OpcodeClass load the flag byte
                    sex                 sign-extend the flag byte
                    orb       #64       set the flag bit
                    stb       <OpcodeClass store the flags back
EmitOneByte         lbsr      ParseHashOperand evaluate the operand expression
                    std       -2,S      save the result
                    beq       EmitByteErr branch on error
                    ldd       <PassType load the location counter
                    addd      #1        add one byte
                    std       <PassType save the location counter
                    ldb       <ModeFlags load the flag byte
                    sex                 sign-extend the flag byte
                    orb       #8        set the flag bit
                    stb       <ModeFlags store the flags back
                    lbsr      ParseReloc emit the byte relocation
                    ldd       <OperandVal load the evaluated value
                    stb       <PostByte store the low byte
EmitByteDone        lbsr      HandleCondSet finish the line
                    puls      PC,U      return to caller

EmitByteErr         lbsr      ParseIndexMode report the error
                    puls      PC,U      return to caller

CheckByteSuffix     cmpx      #98       is the suffix char 'b'
                    beq       ByteSuffixB handle the byte suffix
                    cmpx      #97       is the suffix char 'a'
                    beq       EmitOneByte handle the a suffix
                    bra       BadRegErr take the default path

Lt_0BC9             pshs      U         save the caller u register
                    ldb       <OpcodeClass load the flag byte
                    cmpb      #14       compare against fourteen
                    beq       ParseRegNum branch if matched
                    ldb       [>SearchStrPtr,Y] load the operand char via pointer
                    beq       ParseRegNum branch if null
                    ldb       [>SearchStrPtr,Y] load the operand char via pointer
                    sex                 sign-extend the operand char
                    tfr       D,X       move it into X
                    bra       CheckRegAB dispatch on the char

SetWordFlag         ldb       <OpcodeClass load the flag byte
                    sex                 sign-extend the flag byte
                    orb       #80       set the flag bits
                    bra       StoreOpClass branch to store the opcode class

BadRegErr           lbsr      EmitFixedMsg2 report the bad register error
                    puls      PC,U      return to caller

CheckRegAB          cmpx      #97       compare token to letter a
                    beq       SetRegBit got register a
                    cmpx      #98       compare token to letter b
                    beq       SetWordFlag got register b
                    bra       BadRegErr neither report error

ParseRegNum         lbsr      ParseIndexMode evaluate the register number expression
                    std       -2,S      save the result
                    lbeq      RetFalse  bail out if zero
                    ldb       <OpcodeClass load the opcode class byte
                    clra                clear high byte
                    andb      #240      mask the high nibble
                    lbeq      RetTrue   done if no bits set
SetRegBit           ldb       <OpcodeClass load the opcode class byte
                    sex                 sign extend to d
                    orb       #64       set the register bit
StoreOpClass        stb       <OpcodeClass store the updated opcode class
                    lbra      RetTrue   finished

Lt_0C14             pshs      U         set up the stack frame
                    lbra      RetTrue   finished

Lt_0C19             pshs      U         set up the stack frame
                    lbsr      ParseIndexMode evaluate the expression
                    std       -2,S      save the result
                    beq       HandleZeroExpr zero take default case
                    ldd       #1        set result true
                    bra       RegExprRet return

HandleZeroExpr      lbsr      IllegalModeErr handle the default case
RegExprRet          puls      PC,U      return to caller

Lt_0C2C             pshs      U,X,D     set up frame saving arguments
                    ldd       #2        select pass type two
                    std       <PassType store the pass type
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      D         push zero argument
                    lbsr      MatchRegToken parse the operand
                    leas      2,S       drop the argument
                    std       2,S       save the first result
                    lbeq      OperandErr error if empty
                    ldb       [>SrcPtr,Y] load the current input character
                    cmpb      #',       compare to comma
                    bne       OperandErr no comma report error
                    ldd       <SrcPtr   load the input pointer
                    addd      #1        advance past the comma
                    std       <SrcPtr   store the input pointer
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      D         push zero argument
                    lbsr      MatchRegToken parse the second operand
                    leas      2,S       drop the argument
                    std       ,S        save the second result
                    beq       OperandErr error if empty
                    ldd       2,S       load the first register value
                    eora      ,S        exclusive or against the second
                    eorb      1,S       exclusive or the low byte
                    clra                clear high byte
                    andb      #8        test the size bit for a mismatch
                    bne       RegMismatchErr mismatch report error
                    ldd       2,S       load the first register value
                    aslb                shift into the high nibble
                    rola                propagate the shift
                    aslb                continue the shift
                    rola                propagate the shift
                    aslb                continue the shift
                    rola                propagate the shift
                    aslb                continue the shift
                    rola                propagate the shift
                    ora       ,S        merge the second register value
                    orb       1,S       merge the low byte
                    stb       <PostByte store the combined register byte
                    ldd       #1        set result true
                    bra       ParseRegPairDone return

RegMismatchErr      leax      >MsgRegSizeMismatch,PC point to the mismatch message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    bra       ParseRegPairDone return

OperandErr          lbsr      EmitFixedMsg1 report the operand error
ParseRegPairDone    leas      4,S       drop the locals
                    puls      PC,U      return to caller

Lt_0C92             pshs      U,D       set up frame saving d
                    ldd       #2        select pass type two
                    std       <PassType store the pass type
                    lbsr      SkipSpaces read the next token
                    bra       RegListLoop enter the list loop

AccumRegLoop        ldb       <PostByte load the accumulated byte
                    sex                 sign extend to d
                    ora       ,S        merge the parsed value
                    orb       1,S       merge the low byte
                    stb       <PostByte store the accumulated byte
                    ldb       [>SrcPtr,Y] load the current input character
                    cmpb      #',       compare to comma
                    beq       SkipComma comma continue the list
                    ldd       #1        set result true
                    puls      PC,U,X    return to caller

SkipComma           ldd       <SrcPtr   load the input pointer
                    addd      #1        advance past the comma
                    std       <SrcPtr   store the input pointer
RegListLoop         ldd       #1        push a nonzero flag
                    pshs      D         push the argument
                    lbsr      MatchRegToken parse the operand
                    leas      2,S       drop the argument
                    std       ,S        save the result
                    bne       AccumRegLoop got operand loop back
                    lbsr      EmitFixedMsg1 report the operand error
                    puls      PC,U,X    return to caller

Lt_0CCE             pshs      U         set up the stack frame
                    ldd       #4        select pass type four
                    std       <PassType store the pass type
                    ldd       >Y0013,Y  load the table length
                    pshs      D         push the length argument
                    leax      >BranchHashTbl,Y point to the opcode table
                    pshs      X         push the table pointer
                    leax      >Y05B4,Y  point to the mnemonic key
                    pshs      X         push the key pointer
                    lbsr      FindKeyword search the opcode table
                    leas      6,S       drop the arguments
                    std       <EntryPtr save the entry pointer
                    beq       BadMnemonicErr not found report error
                    ldx       <EntryPtr load the entry pointer
                    ldb       2,X       load the opcode class from the entry
                    stb       <OpcodeClass store the opcode class
DispatchMnemonic    lbsr      DispatchOpcode dispatch the handler
                    puls      PC,U      return to caller

BadMnemonicErr      leax      >MsgBadMnemonic2,PC point to the bad mnemonic message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return to caller

Lt_0D06             pshs      U,D       set up frame saving d
                    ldd       #2        select pass type two
                    std       <PassType store the pass type
                    lbsr      EvalLineExpr evaluate the branch expression
                    std       -2,S      save the result
                    beq       BranchFail zero return false
                    ldb       <PassFlag load the pass flag
                    beq       BranchOk  skip on the first pass
                    ldd       <OperandVal load the current location
                    subd      <TargetAddr subtract the target address
                    addd      #-2       adjust for the branch offset
                    std       ,S        save the offset
                    ldb       <ModeFlags load the opcode flags
                    sex                 sign extend to d
                    orb       #136      set the flag bits
                    stb       <ModeFlags store the opcode flags
                    lbsr      CompactModeList emit the opcode
                    leax      >ListStart,Y point to the current pass
                    cmpx      >ListEnd,Y compare to the last pass
                    bne       EmitBranchByte not final pass skip the range check
                    ldd       ,S        load the offset
                    cmpd      #127      compare to the positive limit
                    bgt       BranchRangeErr out of range too high
                    ldd       ,S        load the offset
                    cmpd      #-128     compare to the negative limit
                    bge       StoreBranchOffset in range continue
BranchRangeErr      ldd       #-2       force a safe offset
                    std       ,S        store the offset
                    leax      >MsgBranchRange,PC point to the range message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    bra       StoreBranchOffset continue

EmitBranchByte      lbsr      ResolveOffsetExpr emit a placeholder branch byte
StoreBranchOffset   ldd       ,S        load the offset
                    stb       <PostByte store the branch offset byte
BranchOk            ldd       #1        set result true
                    puls      PC,U,X    return to caller

BranchFail          clra                clear result
                    clrb                clear low byte
                    puls      PC,U,X    return to caller

Lt_0D67             pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    ldb       <OpcodeClass load the opcode class
                    sex                 sign extend to d
                    aslb                multiply the index by two
                    rola                propagate the carry
                    leax      >JumpTbl1,Y point to the first jump table
                    bra       DispatchHandler dispatch through the table

Lt_0D78             pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    ldb       <OpcodeClass load the opcode class
                    sex                 sign extend to d
                    aslb                multiply the index by two
                    rola                propagate the carry
                    leax      >JumpTbl2,Y point to the second jump table
DispatchHandler     leax      D,X       index into the table
                    jsr       [,X]      call the selected handler
                    puls      PC,U      return to caller

Lt_0D8D             pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    ldd       <NestCount load the nesting count
                    addd      #1        increment it
                    std       <NestCount store the nesting count
                    ldb       <OpcodeClass load the opcode class
                    sex                 sign extend to d
                    aslb                multiply the index by two
                    rola                propagate the carry
                    leax      >ClassJumpTbl,Y point to the class jump table
                    leax      D,X       index into the table
                    ldd       ,X        load the handler address
                    pshs      D         save the handler
                    leax      >IfPass2Handler,PC point to the reference handler
                    cmpx      ,S++      compare the handler address
                    beq       CallOpHandler2 matches skip the evaluation
                    lbsr      EvalLineExpr evaluate the expression
                    std       -2,S      save the result
                    lbeq      RetFalse  bail out if zero
                    leax      >ListStart,Y point to the current pass
                    cmpx      >ListEnd,Y compare to the last pass
                    lbne      ReportExtRef not final pass branch away
CallOpHandler2      ldb       <OpcodeClass load the opcode class
                    sex                 sign extend to d
                    aslb                multiply the index by two
                    rola                propagate the carry
                    leax      >ClassJumpTbl,Y point to the class jump table
                    leax      D,X       index into the table
                    jsr       [,X]      call the selected handler
                    std       -2,S      save the result
                    bne       UpdateCondFlag nonzero skip the increment
                    ldd       <SkipCount load the second count
                    addd      #1        increment it
                    std       <SkipCount store the second count
UpdateCondFlag      ldd       <ListFlag load the conditional flag
                    pshs      D         save it
                    ldb       <CondState load the condition state
                    ble       CondFalse false take zero
                    ldd       #1        set true
                    bra       MergeCond merge the flags

ExtRefErr           pshs      U         set up the stack frame
                    leax      >MsgIllegalExtRef,PC point to the external reference message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return to caller

Lt_0DF8             pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    ldd       <NestCount load the nesting count
                    beq       NestErr   not nested handle endc
                    ldb       <OpcodeClass load the opcode class
                    bne       CheckCount nonzero branch away
                    ldd       <NestCount load the nesting count
                    addd      #-1       decrement it
                    std       <NestCount store the nesting count
                    ldd       <SkipCount load the second count
                    beq       EvalCond  zero skip ahead
DecCount            ldd       <SkipCount load the second count
                    addd      #-1       decrement it
                    bra       StoreCount store the count

CheckCount          ldd       <SkipCount load the second count
                    bne       DecCount  nonzero go decrement
                    ldd       <SkipCount load the second count
                    addd      #1        increment it
StoreCount          std       <SkipCount store the second count
EvalCond            ldd       <ListFlag load the conditional flag
                    pshs      D         save it
                    ldb       <CondState load the condition state
                    ble       CondFalse false take zero
                    ldd       #1        set true
                    bra       MergeCond merge the flags

CondFalse           clra                clear result
                    clrb                clear low byte
MergeCond           anda      ,S+       and with the saved flag
                    andb      ,S+       and the low byte
                    std       <ListFlag store the conditional flag
                    lbra      RetTrue   finished

NestErr             leax      >MsgCondNesting,PC point to the nesting error message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return to caller

Lt_0E46             pshs      U         set up the stack frame
                    bsr       SetCodeSection reset the code section pointers
                    lbsr      ParsePsect clear the assembler tables
                    clra                zero high byte
                    clrb                zero low byte
                    std       <U0041    clear the counter
                    std       <U0045    clear the counter
                    std       <U0043    clear the counter
                    std       <U0047    clear the counter
                    std       <TargetAddr clear the location
                    lbra      RetTrue   finished

SetCodeSection      pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    leax      >CodeSection,Y point to the code section
                    stx       <SectBasePtr store the section base
                    ldd       >Y0009,Y  load the section size
                    std       <SectSizePtr store the section size
                    leax      >RelocArea,Y point to the relocation area
                    stx       <RelocWrPtr store the relocation pointer
                    leax      >CodeSectPtr,Y point to the section buffer
                    stx       <BufPtr   store the buffer pointer
                    ldd       #4        load the type value
                    stb       <SectType store the section type
                    ldd       #162      load the flags value
                    stb       <SectFlags store the section flags
                    ldd       #32       load the size value
                    stb       <SectSizeByte store the section size byte
                    leax      >TargetAddr,Y point to the location field
                    stx       <RelocPtr store the pointer
                    clra                zero high byte
                    clrb                zero low byte
                    std       <FieldPtr clear the field
                    lbra      RetTrue   finished

Lt_0E96             pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    leax      >DataSection,Y point to the data section
                    stx       <SectBasePtr store the section base
                    ldd       >Y000B,Y  load the section size
                    std       <SectSizePtr store the section size
                    leax      >Y0356,Y  point to the relocation area
                    stx       <RelocWrPtr store the relocation pointer
                    clra                zero high byte
                    clrb                zero low byte
                    std       <BufPtr   clear the buffer pointer
                    ldd       #6        load the type value
                    stb       <SectType store the section type
                    ldb       <SectFlags load the section flags
                    clra                clear high byte
                    andb      #2        isolate the flag bit
                    orb       #128      set the high bit
                    stb       <SectFlags store the section flags
                    clra                zero high byte
                    clrb                zero low byte
                    stb       <SectSizeByte clear the section size byte
                    clra                zero high byte
                    clrb                zero low byte
                    std       <RelocPtr clear the pointer
                    leax      >DataLocation,Y point to the location field
                    stx       <FieldPtr store the pointer
                    tfr       X,D       copy the pointer to d
                    std       <WorkPtr  store the working pointer
                    clra                zero high byte
                    clrb                zero low byte
                    std       <DataLocation clear the data location
                    lbsr      SkipSpaces read the next token
                    std       -2,S      save the result
                    beq       RetTrue   finished if none
                    lbsr      EvalLineExpr evaluate the expression
                    std       -2,S      save the result
                    bne       CheckFinalPass got a value continue
RetFalse            clra                clear result
                    clrb                clear low byte
                    puls      PC,U      return to caller

CheckFinalPass      leax      >ListStart,Y point to the current pass
                    cmpx      >ListEnd,Y compare to the last pass
                    beq       SetDataOrigin final pass set the origin
ReportExtRef        lbsr      ExtRefErr report the external reference error
                    puls      PC,U      return to caller

SetDataOrigin       ldd       <OperandVal load the current location
                    std       <DataLocation set the data origin
                    bra       RetTrue   finished

Lt_0EFD             pshs      U         set up the stack frame
                    clra                zero high byte
                    clrb                zero low byte
                    std       <PassType clear the pass type
                    leax      >BssSection,Y point to the bss section
                    stx       <SectBasePtr store the section base
                    ldd       >Y000F,Y  load the section size
                    std       <SectSizePtr store the section size
                    leax      >Y035E,Y  point to the relocation area
                    stx       <RelocWrPtr store the relocation pointer
                    clra                zero high byte
                    clrb                zero low byte
                    stb       <SectType clear the section type
                    lbsr      ParseDPKeyword parse the operand
                    std       -2,S      save the result
                    beq       RetTrue   finished if none
                    ldd       #2        load the type value
                    stb       <SectType store the section type
RetTrue             ldd       #1        set result true
                    puls      PC,U      return to caller

Lt_0F2A             pshs      U         set up the stack frame
                    ldd       <FieldPtr load the section pointer
                    std       <WorkPtr  store the working pointer
                    ldb       <SectFlags load the section flags
                    clra                clear high byte
                    andb      #2        test the data bit
                    beq       SetDataSection not data other section
                    lbsr      SetCodeSection reset the code section
                    bra       SectionRet finished

SetDataSection      lbsr      InitSectionDefaults reset the data section
SectionRet          puls      PC,U      return to caller

Lt_0F41             pshs      U         set up the stack frame
                    ldd       <MacroFlag load the end flag
                    beq       CheckLabel not ended continue
                    lbsr      EmitFixedMsg3 report the duplicate end
                    puls      PC,U      return to caller

CheckLabel          ldd       <LabelField load the label pointer
                    bne       ProcessEnd has a label continue
                    leax      >MsgLabelMissing,PC point to the missing label message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return to caller

ProcessEnd          ldd       #7        load the argument value
                    pshs      D         push the argument
                    lbsr      MergeSymFlags process the end directive
                    leas      2,S       drop the argument
                    ldb       <PassFlag load the pass flag
                    bne       SetEndFlag skip on the later pass
                    lbsr      OpenObjectFile finalize the output
SetEndFlag          ldd       #1        set the end flag value
                    std       <MacroFlag store the end flag
                    puls      PC,U      return to caller

Lt_0F73             pshs      U         set up the stack frame
                    leax      >MsgEndmNoMacro,PC point to the endm message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return to caller

MsgRegSizeMismatch  fcc       "register size mismatch"
                    fcb       C$NULL
MsgBadMnemonic2     fcc       "bad mnemonic"
                    fcb       C$NULL
MsgBranchRange      fcc       "branch out of range"
                    fcb       C$NULL
MsgIllegalExtRef    fcc       "illegal external reference"
                    fcb       C$NULL
MsgCondNesting      fcc       "conditional nesting error"
                    fcb       C$NULL
MsgLabelMissing     fcc       "label missing"
                    fcb       C$NULL
MsgEndmNoMacro      fcc       "ENDM without MACRO"
                    fcb       C$NULL
ParseHashOperand    pshs      U         set up the stack frame
                    lbsr      SkipSpaces read the next token
                    cmpd      #35       compare to a hash
                    bne       BranchOffZero not immediate branch away
                    ldd       <SrcPtr   load the input pointer
                    addd      #1        advance past the hash
                    std       <SrcPtr   store the input pointer
                    lbra      ReturnTrue handle the directive

HandleCondSet       pshs      U         set up the stack frame
                    ldd       <TypeField load the flags
                    clra                clear high byte
                    andb      #64       test the flag bit
                    lbeq      ReturnTrue clear handle the directive
                    ldd       #3        select pass type three
                    std       <PassType store the pass type
                    lbsr      IllegalModeErr handle the case
                    puls      PC,U      return to caller

DispatchOpcode      pshs      U         set up the stack frame
                    ldb       <ModeFlags load flags byte
                    sex                 sign extend flags
                    orb       #128      set high flag bit
                    stb       <ModeFlags store updated flags
                    lbsr      ParseValue call offset helper
                    std       -2,S      save result local
                    bne       EvalBranchRange branch if nonzero result
BranchOffZero       clra                return zero
                    clrb                clear low byte
                    puls      PC,U      return to caller

EvalBranchRange     ldd       <OperandVal load current location
                    subd      <TargetAddr subtract branch base
                    subd      <PassType subtract instruction length
                    std       <PostByte store computed offset
                    ldd       <PostByte reload offset
                    cmpd      #127      compare to byte maximum
                    bgt       BranchNeedsWord too large for byte
                    ldd       <PostByte reload offset
                    cmpd      #-128     compare to byte minimum
                    bge       BranchFitsByte fits in signed byte
BranchNeedsWord     ldd       #1        mark word-sized offset
                    bra       StoreBranchSize go store size

BranchFitsByte      clra                mark byte-sized offset
                    clrb                clear low byte
StoreBranchSize     std       <OffSizeFlag store offset-size flag
                    lbra      ReturnTrue return success

MatchRegToken       pshs      U         save the caller u register
                    leas      -3,S      allocate loop locals
                    clra                start index at zero
                    clrb                clear low byte
                    lbra      MatchRegCheck enter loop check

MatchRegLoop        ldd       1,S       load current index
                    pshs      D         push as argument
                    ldd       #3        element size three
                    lbsr      MulEntry  multiply index by size
                    leax      >RegisterTbl,Y point to register table
                    leax      D,X       index into table
                    ldb       ,X        load table entry character
                    sex                 sign extend
                    pshs      D         save for compare
                    ldb       [>SrcPtr,Y] load current source character
                    clra                clear high byte
                    andb      #223      force uppercase
                    cmpd      ,S++      compare with table entry
                    lbne      NextRegEntry no match, try next
                    ldd       1,S       reload index
                    pshs      D         push as argument
                    ldd       #3        element size three
                    lbsr      MulEntry  multiply index by size
                    leax      >RegisterTbl,Y point to register table
                    leax      D,X       index into table
                    ldb       1,X       load second entry byte
                    stb       ,S        save second character
                    beq       RegCharMatched no second character needed
                    ldx       <SrcPtr   load source pointer
                    ldb       1,X       peek next source character
                    clra                clear high byte
                    andb      #223      force uppercase
                    pshs      D         save for compare
                    ldb       2,S       load table second character
                    sex                 sign extend
                    cmpd      ,S++      compare second character
                    bne       NextRegEntry mismatch, try next entry
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past second character
                    std       <SrcPtr   store source pointer
RegCharMatched      ldd       <SrcPtr   load source pointer
                    addd      #1        advance past register character
                    std       <SrcPtr   store source pointer
                    ldd       7,S       load caller mode argument
                    bne       UseTableField nonzero uses table field
                    ldd       1,S       load matched index
                    cmpd      #4        compare to register split
                    bge       HighRegGroup high register group
                    ldd       1,S       reload index
                    orb       #8        set low-group flag bit
                    bra       MatchRegDone go finish

HighRegGroup        ldd       1,S       reload index
                    addd      #-4       adjust to high group
                    ora       #1        set high-group flag bit
                    bra       MatchRegDone go finish

UseTableField       ldd       1,S       reload matched index
                    pshs      D         push as argument
                    ldd       #3        element size three
                    lbsr      MulEntry  multiply index by size
                    leax      >RegisterTbl,Y point to register table
                    leax      D,X       index into table
                    ldb       2,X       load table result byte
                    sex                 sign extend result
                    bra       MatchRegDone go finish

NextRegEntry        ldd       1,S       reload index
                    addd      #1        increment to next entry
MatchRegCheck       std       1,S       store updated index
                    ldd       1,S       reload index
                    cmpd      #10       compare table length
                    lblt      MatchRegLoop continue scanning
                    clra                no register matched
                    clrb                clear low byte
MatchRegDone        leas      3,S       release loop locals
                    puls      PC,U      return to caller

ParseIndexMode      pshs      U         save the caller u register
                    leas      -1,S      allocate local
                    lbsr      SkipSpaces read next character
                    stb       ,S        save character
                    cmpb      #'[       compare to open bracket
                    bne       NotIndirect not indirect
                    ldd       #1        mark indirect
                    bra       StoreIndirectFlag go store flag

NotIndirect         clra                not indirect
                    clrb                clear low byte
StoreIndirectFlag   std       <IndirFlag store indirect flag
                    beq       ReadIndexChar skip if not indirect
                    ldx       <SrcPtr   load source pointer
                    leax      1,X       advance past bracket
                    stx       <SrcPtr   store source pointer
                    ldb       ,X        read next character
                    stb       ,S        save character
ReadIndexChar       ldb       ,S        load current character
                    sex                 sign extend
                    pshs      D         push as argument
                    lbsr      ParseSizePrefix parse size prefix
                    leas      2,S       drop argument
                    stb       ,S        save returned character
                    cmpb      #',       compare to comma
                    bne       ParseOffsetOperand has offset expression
                    lbsr      ParseAutoMode parse auto increment mode
                    lbra      ParseRegDone return

ParseOffsetOperand  ldx       <SrcPtr   load source pointer
                    ldb       1,X       peek next character
                    cmpb      #',       compare to comma
                    bne       ParseConstOffset not accumulator offset
                    ldb       ,S        load register letter
                    clra                clear high byte
                    andb      #223      force uppercase
                    tfr       D,X       move for compare
                    bra       MatchAccumReg match accumulator register

AccOffsetA          ldd       #134      accumulator A offset postbyte
                    bra       EmitAccOffset go emit

AccOffsetB          ldd       #133      accumulator B offset postbyte
                    bra       EmitAccOffset go emit

AccOffsetD          ldd       #139      accumulator D offset postbyte
EmitAccOffset       stb       <PostByte store postbyte
                    lbsr      FinishAccOffset finish accumulator offset
                    lbra      ParseRegDone return

MatchAccumReg       cmpx      #65       compare to letter A
                    beq       AccOffsetA accumulator A
                    cmpx      #66       compare to letter B
                    beq       AccOffsetB accumulator B
                    cmpx      #68       compare to letter D
                    beq       AccOffsetD accumulator D
ParseConstOffset    lbsr      EvalLineExpr evaluate offset expression
                    ldd       <OperandVal load expression value
                    std       <OffsetVal store offset value
                    ldb       [>SrcPtr,Y] peek next character
                    cmpb      #',       compare to comma
                    bne       CheckOffsetSize not register-relative
                    lbsr      ParseIndexOffset emit constant-offset indexed
                    lbra      ParseRegDone return

CheckOffsetSize     ldd       <IndirFlag load indirect flag
                    bne       EmitWordOffset indirect uses word offset
                    ldd       <OffsetFlag load size-force flag
                    blt       EmitWordOffset forced word offset
                    ldd       <OffsetFlag reload size flag
                    bgt       EmitByteOffset forced byte offset
                    ldd       <OffsetVal load offset value
                    pshs      D         push as argument
                    ldd       #256      byte range value
                    lbsr      SDivEntry check offset range
                    cmpd      <CurValue compare result
                    bne       EmitWordOffset offset needs word form
EmitByteOffset      lbsr      EmitByteOffsetMode emit byte-offset indexed
                    lbra      ParseRegDone return

EmitWordOffset      bsr       EmitWordOffsetMode emit word-offset indexed
                    lbra      ParseRegDone return

ParseSizePrefix     pshs      U         save the caller u register
                    ldb       5,S       load passed character
                    cmpb      #'>       compare to greater-than
                    bne       CheckBytePrefix not word prefix
                    ldd       #-1       force word size
                    bra       StoreSizeFlag go store flag

CheckBytePrefix     ldb       5,S       reload character
                    cmpb      #'<       compare to less-than
                    bne       NoSizePrefix no size prefix
                    ldd       #1        force byte size
                    bra       StoreSizeFlag go store flag

NoSizePrefix        clra                no forced size
                    clrb                clear low byte
StoreSizeFlag       std       <OffsetFlag store size flag
                    ldd       <OffsetFlag reload size flag
                    beq       KeepChar  no prefix consumed
                    ldx       <SrcPtr   load source pointer
                    leax      1,X       advance past prefix
                    stx       <SrcPtr   store source pointer
                    ldb       ,X        read next character
                    bra       SexReturn go return

KeepChar            ldb       5,S       reuse original character
SexReturn           sex                 sign extend result
                    puls      PC,U      return

                    fcb       $35
                    fcb       $C0
FinishAccOffset     pshs      U         save the caller u register
                    ldd       <SrcPtr   load source pointer
                    addd      #2        skip register and comma
                    std       <SrcPtr   store source pointer
                    lbsr      ParseBaseReg parse base register
                    std       -2,S      save result
                    lbeq      IllegalRegExit no register found
                    lbsr      FinishIndexPostbyte finish index postbyte
                    lbra      AutoModeDone return

EmitWordOffsetMode  pshs      U         save the caller u register
                    ldd       <PassType load instruction length
                    addd      #2        add two offset bytes
                    std       <PassType store instruction length
                    ldd       <IndirFlag load indirect flag
                    beq       DirectWordOffset direct word offset
                    ldd       #159      indirect word-offset postbyte
                    stb       <PostByte store postbyte
                    ldd       <OffsetVal load offset value
                    std       <OperandLow store offset operand
                    lbra      FinishAutoMode finish auto mode

DirectWordOffset    lbsr      CompactModeList evaluate register
                    lbsr      ResolveOffsetExpr resolve offset expression
                    ldd       <OffsetVal load offset value
                    std       <PostByte store offset value
                    ldb       <OpcodeClass load mode byte
                    sex                 sign extend
                    orb       #48       set word-offset bits
                    bra       StoreModeByte go store mode byte

EmitByteOffsetMode  pshs      U         save the caller u register
                    ldd       <PassType load instruction length
                    addd      #1        add one offset byte
                    std       <PassType store instruction length
                    ldb       <ModeFlags load flags byte
                    sex                 sign extend
                    orb       #8        set byte-offset flag
                    stb       <ModeFlags store flags
                    lbsr      CompactModeList evaluate register
                    lbsr      ResolveOffsetExpr resolve offset expression
                    ldd       <OffsetVal load offset value
                    stb       <PostByte store offset low byte
                    ldb       <OpcodeClass load mode byte
                    clra                clear high byte
                    andb      #240      mask high nibble
                    lbeq      ReturnTrue no mode bits set
                    ldb       <OpcodeClass reload mode byte
                    sex                 sign extend
                    orb       #16       set indexed indicator bit
StoreModeByte       stb       <OpcodeClass store mode byte
                    lbra      ReturnTrue return success

ParseAutoMode       pshs      U         save the caller u register
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past comma
                    std       <SrcPtr   store source pointer
                    clra                clear offset value
                    clrb                clear low byte
                    std       <OffsetVal store offset value
                    ldb       [>SrcPtr,Y] peek next character
                    cmpb      #'-       compare to minus
                    bne       CheckPostInc not pre-decrement
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past minus
                    std       <SrcPtr   store source pointer
                    ldb       [>SrcPtr,Y] peek next character
                    cmpb      #'-       compare to second minus
                    bne       SinglePreDec single pre-decrement
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past second minus
                    std       <SrcPtr   store source pointer
                    ldd       #131      pre-decrement-two postbyte
                    bra       StorePreDec go store postbyte

SinglePreDec        lbsr      RequireNonIndirect require non-indirect check
                    ldd       #130      pre-decrement-one postbyte
StorePreDec         stb       <PostByte store postbyte
                    lbsr      ParseBaseReg parse base register
                    std       -2,S      save result
                    beq       IllegalRegExit no register found
                    lbsr      FinishIndexPostbyte finish index postbyte
                    bra       AutoModeDone go return

IllegalRegExit      lbsr      IllegalIndexRegErr illegal index register error
AutoModeDone        puls      PC,U      return

CheckPostInc        lbsr      ParseBaseReg parse base register
                    std       -2,S      save result
                    bne       ParsePostInc register found
                    lbsr      EmitPcRelative handle missing base register
                    puls      PC,U      return

ParsePostInc        ldb       [>SrcPtr,Y] peek next character
                    cmpb      #'+       compare to plus
                    bne       EmitZeroOffset not post-increment
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past plus
                    std       <SrcPtr   store source pointer
                    ldb       [>SrcPtr,Y] peek next character
                    cmpb      #'+       compare to second plus
                    bne       SinglePostInc single post-increment
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past second plus
                    std       <SrcPtr   store source pointer
                    ldb       <PostByte load postbyte base
                    sex                 sign extend
                    orb       #129      post-increment-two bits
                    bra       StorePostInc go store postbyte

SinglePostInc       bsr       RequireNonIndirect require non-indirect check
                    ldb       <PostByte load postbyte base
                    sex                 sign extend
                    orb       #128      post-increment-one bit
StorePostInc        stb       <PostByte store postbyte
FinishAutoMode      lbsr      FinishIndexPostbyte finish index postbyte
                    puls      PC,U      return

EmitZeroOffset      lbsr      EmitOffsetPostbyte emit zero-offset indexed
                    puls      PC,U      return

RequireNonIndirect  pshs      U         save the caller u register
                    ldd       <IndirFlag load indirect flag
                    lbeq      ReturnTrue allowed when not indirect
                    lbra      ReturnModeError else illegal mode error

IllegalModeErr      pshs      U         save the caller u register
                    leax      >MsgIllegalMode,PC point to error message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine print error message
                    puls      PC,U,X    return

ParseBaseReg        pshs      U         save the caller u register
                    leas      -1,S      allocate local
                    ldd       #255      sentinel no-match value
                    stb       ,S        store sentinel
                    ldb       [>SrcPtr,Y] peek register character
                    clra                clear high byte
                    andb      #223      force uppercase
                    tfr       D,X       move for compare
                    bra       MatchBaseReg match base register

RegX                clra                register X bits zero
                    clrb                clear low byte
                    bra       StoreRegBits go store bits

RegY                ldd       #32       register Y bits
                    bra       StoreRegBits go store bits

RegU                ldd       #64       register U bits
                    bra       StoreRegBits go store bits

RegS                ldd       #96       register S bits
StoreRegBits        stb       ,S        store register bits
                    bra       CheckRegMatch check match found

MatchBaseReg        cmpx      #88       compare to X
                    beq       RegX      register X
                    cmpx      #89       compare to Y
                    beq       RegY      register Y
                    cmpx      #85       compare to U
                    beq       RegU      register U
                    cmpx      #83       compare to S
                    beq       RegS      register S
CheckRegMatch       ldb       ,S        load register bits
                    cmpb      #255      compare to sentinel
                    beq       NoRegMatch no register matched
                    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past register character
                    std       <SrcPtr   store source pointer
                    ldb       <PostByte load postbyte
                    sex                 sign extend
                    pshs      D         save postbyte
                    ldb       2,S       load register bits
                    sex                 sign extend
                    ora       ,S+       combine postbyte high
                    orb       ,S+       combine postbyte low
                    stb       <PostByte store postbyte
                    ldd       #1        return found
                    bra       ParseRegDone go return

NoRegMatch          clra                return not found
                    clrb                clear low byte
ParseRegDone        leas      1,S       release local
                    puls      PC,U      return to caller

IllegalIndexRegErr  pshs      U         save the caller u register
                    leax      >MsgIllegalIndexReg,PC point to error message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine print error message
                    puls      PC,U,X    return

FinishIndexPostbyte pshs      U         save the caller u register
                    ldb       <OpcodeClass load mode byte
                    sex                 sign extend
                    orb       #32       set indexed flag bit
                    stb       <OpcodeClass store mode byte
                    ldd       <PassType load instruction length
                    addd      #1        add postbyte length
                    std       <PassType store instruction length
                    ldd       <PtrCounter load pointer counter
                    addd      #1        increment counter
                    std       <PtrCounter store counter
                    ldd       <IndirFlag load indirect flag
                    beq       ReadTrailingChar not indirect
                    ldb       <PostByte load postbyte
                    sex                 sign extend
                    orb       #16       set indirect bit
                    stb       <PostByte store postbyte
                    ldb       [>SrcPtr,Y] peek next character
                    cmpb      #']       compare to close bracket
                    beq       SkipCloseBracket bracket present
                    leax      >MsgBracketMissing,PC point to error message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine print bracket-missing error
                    leas      2,S       drop argument
                    bra       ReadTrailingChar go read trailing

SkipCloseBracket    ldd       <SrcPtr   load source pointer
                    addd      #1        advance past bracket
                    std       <SrcPtr   store source pointer
ReadTrailingChar    ldb       [>SrcPtr,Y] peek trailing character
                    sex                 sign extend
                    tfr       D,X       move for compare
                    bra       CheckTrailingSpace check trailing space

SkipTrailingSpace   lbsr      CompactModeList evaluate register
                    bsr       ResolveOffsetExpr resolve offset expression
ReturnTrue          ldd       #1        return success value
                    puls      PC,U      return

ReturnModeError     lbsr      IllegalModeErr illegal addressing mode error
                    puls      PC,U      return

CheckTrailingSpace  cmpx      #32       compare to space
                    beq       SkipTrailingSpace skip trailing space
                    stx       -2,S      save character
                    lbeq      SkipTrailingSpace skip if null
                    bra       ReturnModeError else illegal mode

                    puls      PC,U      unreachable return

ResolveOffsetExpr   pshs      U,X,D     save registers
                    ldb       <PassFlag load pass flag
                    lbeq      ModeScanDone skip when zero
                    leax      >ListStart,Y point to expression stack
                    cmpx      >ListEnd,Y compare stack pointer
                    lbcc      ModeScanDone stack empty
                    ldd       <RelocPtr load offset symbol pointer
                    bne       OffsetHasValue branch if value present
                    lbsr      ExtRefErr record relocation reference
                    lbra      ModeScanDone done

OffsetHasValue      ldb       <ModeFlags load flags byte
                    clra                clear high byte
                    andb      #8        test byte-offset flag
                    beq       WordOffset word-sized offset
                    ldd       #1        one offset byte
                    bra       PushOffsetSize go push size

WordOffset          ldd       #2        two offset bytes
PushOffsetSize      pshs      D         push offset size
                    ldd       [>RelocPtr,Y] load target address
                    addd      <PassType add instruction length
                    subd      ,S++      subtract offset size
                    std       2,S       store computed offset
                    lbra      RelocScanLoop continue processing

PopExprStackLoop    ldx       >ListEnd,Y load stack pointer
                    leax      -3,X      pop stack entry
                    stx       >ListEnd,Y update stack pointer
                    ldu       1,X       load entry pointer
                    ldb       ,U        load entry byte
                    sex                 sign extend
                    pshs      D         save value
                    ldb       <ModeFlags load flags byte
                    sex                 sign extend
                    ora       ,S+       combine flags high
                    orb       ,S+       combine flags low
                    pshs      D         save combined value
                    ldb       [>ListEnd,Y] load byte through the list end pointer
                    sex                 sign extend to sixteen bits
                    ora       ,S+       combine the high flag bits
                    orb       ,S+       combine the low flag bits
                    std       ,S        store the combined value
                    ldb       1,U       load the entry flag byte
                    clra                clear the high byte
                    andb      #66       test the relocation type bits
                    bne       ExtRelocCase branch if extended relocation
                    ldd       #1        prepare the true flag
                    std       <ColumnFlag mark a simple relocation
                    ldd       8,U       load the segment field
                    bne       FirstRelocCase skip the counter bump if nonzero
                    ldd       <IntRelocCnt load the internal-reloc counter
                    addd      #1        increment it
                    std       <IntRelocCnt store the counter
FirstRelocCase      ldd       2,S       load the saved argument
                    pshs      D         push it
                    ldd       2,S       reload the argument
                    pshs      D         push it again
                    pshs      U         push the entry pointer
                    bra       EmitRelocEntry go emit the record

ExtRelocCase        ldd       <ExtRelocCnt load the extended-reloc counter
                    addd      #1        increment it
                    std       <ExtRelocCnt store the counter
                    ldd       2,S       load the saved argument
                    pshs      D         push it
                    ldd       2,S       reload the argument
                    pshs      D         push it again
                    ldd       <BufPtr   load the extra parameter
                    pshs      D         push it
EmitRelocEntry      lbsr      AppendFixup emit the relocation record
                    leas      6,S       drop the arguments
RelocScanLoop       leax      >ListStart,Y point at the list start
                    cmpx      >ListEnd,Y compare with the list end
                    lbcs      PopExprStackLoop loop while entries remain
                    lbra      ModeScanDone done, return

CompactModeList     pshs      U,D       save the registers
                    ldb       <PassFlag load the enable flag
                    beq       CompactDone skip if not set
                    leax      >ListStart,Y point at the list start
                    cmpx      >ListEnd,Y compare with the list end
                    bcc       CompactDone skip if the list is empty
                    leau      >ListStart,Y set the scan pointer to the start
                    bra       ScanEntryCheck enter the scan loop

ScanEntryLoop2      pshs      U         save the scan pointer
                    bsr       FindMatchEntry test this entry for a match
                    std       ,S++      store result and drop the pointer
                    bne       ScanEntryCheck continue if no match
                    ldd       1,U       load the entry field
                    pshs      D         push it
                    lbsr      IsModeMatch test the mode pair
                    std       ,S++      store result and drop it
                    beq       NextScanEntry skip if false
                    stu       ,S        save the current pointer
                    bra       ShiftEntriesStep enter the shift loop

ShiftEntriesLoop    ldb       ,U        load the source byte
                    ldx       ,S        load the destination pointer
                    stb       -3,X      store the byte back
                    ldd       1,U       load the source word
                    ldx       ,S        reload the destination pointer
                    std       -2,X      store the word back
ShiftEntriesStep    ldd       ,S        load the destination pointer
                    addd      #3        advance by one entry
                    std       ,S        store it
                    cmpd      >ListEnd,Y compare with the list end
                    bcs       ShiftEntriesLoop loop while below the end
                    ldd       >ListEnd,Y load the list end
                    addd      #-3       shrink by one entry
                    std       >ListEnd,Y store the new end
                    bra       ScanEntryCheck resume the scan

NextScanEntry       leau      3,U       advance to the next entry
ScanEntryCheck      cmpu      >ListEnd,Y compare with the list end
                    bcs       ScanEntryLoop2 loop while entries remain
CompactDone         clra                clear the result high
                    clrb                clear the result low
                    puls      PC,U,X    restore and return

FindMatchEntry      pshs      U         save u
                    ldu       4,S       load the entry pointer argument
                    leas      -4,S      make local space
                    ldb       [<1,U]    load a byte via the indirect field
                    sex                 sign extend
                    pshs      D         push it
                    ldb       <ModeFlags load the mode byte
                    sex                 sign extend
                    ora       ,S+       combine the bits
                    orb       ,S+       combine the bits
                    pshs      D         push the combined value
                    ldb       ,U        load the entry byte
                    sex                 sign extend
                    ora       ,S+       combine the bits
                    orb       ,S+       combine the bits
                    std       ,S        store the combined value
                    stu       2,S       save the entry pointer
                    lbra      NextMatchEntry enter the scan

MatchScanLoop       ldx       2,S       load the entry pointer
                    ldb       [<1,X]    load a byte via the indirect field
                    sex                 sign extend
                    pshs      D         push it
                    ldb       <ModeFlags load the mode byte
                    sex                 sign extend
                    ora       ,S+       combine the bits
                    orb       ,S+       combine the bits
                    pshs      D         push the combined value
                    ldb       [<4,S]    load a byte via the saved pointer
                    sex                 sign extend
                    ora       ,S+       combine the bits
                    orb       ,S+       combine the bits
                    eora      ,S        compare high via exclusive or
                    eorb      1,S       compare low via exclusive or
                    cmpd      #64       test the match value
                    bne       NextMatchEntry no match, keep scanning
                    bra       RemoveEntryStep match, compact the entries

RemoveEntryLoop     ldb       3,U       load the next entry byte
                    stb       ,U        move it down
                    ldd       4,U       load the next entry word
                    std       1,U       move it down
                    leau      3,U       advance one entry
RemoveEntryStep     pshs      U         save the pointer
                    ldd       #3        one entry size
                    addd      ,S++      compute the next pointer
                    cmpd      2,S       compare with the limit
                    bcs       RemoveEntryLoop loop while below
                    bra       CopyDownStep go to the outer step

CopyDownLoop        ldb       [<2,S]    load a byte via the pointer
                    stb       ,U        store it into the destination
                    ldx       2,S       load the source pointer
                    ldd       1,X       load the source word
                    std       1,U       store it into the destination
                    leau      3,U       advance one entry
CopyDownStep        ldd       2,S       load the current pointer
                    addd      #3        advance one entry
                    std       2,S       store it
                    cmpd      >ListEnd,Y compare with the list end
                    bcs       CopyDownLoop loop while below the end
                    stu       >ListEnd,Y store the new list end
                    ldd       #1        set the true result
                    bra       ModeScanDone return

NextMatchEntry      ldd       2,S       load the current pointer
                    addd      #3        advance one entry
                    std       2,S       store it
                    cmpd      >ListEnd,Y compare with the list end
                    lbcs      MatchScanLoop loop while below the end
                    clra                clear the result high
                    clrb                clear the result low
ModeScanDone        leas      4,S       drop the locals
                    puls      PC,U      restore and return

IsModeMatch         pshs      U         save u
                    ldu       4,S       load the entry pointer argument
                    ldb       ,U        load the mode byte
                    clra                clear the high byte
                    andb      #7        isolate the low mode bits
                    cmpd      #4        test for mode four
                    bne       ModeMatchFalse not it, return false
                    ldb       <ModeFlags load the mode flags
                    clra                clear the high byte
                    andb      #176      mask the flag bits
                    cmpd      #160      test the flag value
                    bne       ModeMatchFalse mismatch, return false
                    ldd       #1        set the true result
                    bra       ModeMatchDone return

ModeMatchFalse      clra                clear the result high
                    clrb                clear the result low
ModeMatchDone       puls      PC,U      restore and return

ParseIndexOffset    pshs      U         save u
                    ldd       <SrcPtr   load the source pointer
                    addd      #1        advance past a character
                    std       <SrcPtr   store it
                    lbsr      ParseBaseReg evaluate the offset expression
                    std       -2,S      save the result
                    bne       HaveOffset nonzero, emit the offset
                    lbsr      EmitPcRelative handle the pc-relative form
                    puls      PC,U      restore and return

HaveOffset          bsr       EmitOffsetPostbyte emit the offset postbyte
                    puls      PC,U      restore and return

EmitOffsetPostbyte  pshs      U         save u
                    ldd       <OffsetFlag load the offset flag
                    blt       Use16BitOffset negative forces the sixteen-bit form
                    ldd       <OffsetFlag reload the flag
                    bne       CheckZeroOffset nonzero, check the ranges
                    ldd       <OffsetVal load the offset value
                    cmpd      #127      compare with the byte maximum
                    bgt       Use16BitOffset too big, use sixteen-bit
                    ldd       <OffsetVal reload the value
                    cmpd      #-128     compare with the byte minimum
                    bge       CheckZeroOffset in range, try a smaller form
Use16BitOffset      ldd       <OffsetVal load the offset value
                    std       <OperandLow store it as the operand
                    ldd       <PassType load the length count
                    addd      #2        add two bytes
                    std       <PassType store the count
                    ldb       <PostByte load the postbyte
                    sex                 sign extend
                    orb       #137      set the sixteen-bit offset bits
                    lbra      StoreIndexPostbyte store and finish

CheckZeroOffset     ldd       <OffsetFlag load the offset flag
                    bne       CheckByteOffset nonzero, try eight-bit
                    ldd       <OffsetVal load the offset value
                    bne       CheckByteOffset nonzero, try eight-bit
                    ldb       <PostByte load the postbyte
                    sex                 sign extend
                    orb       #132      set the no-offset bits
                    lbra      StoreIndexPostbyte store and finish

CheckByteOffset     ldd       <OffsetFlag load the offset flag
                    bgt       Use8BitOffset positive, use eight-bit
                    ldd       <IndirFlag load the sign flag
                    bne       Use8BitOffset set, use eight-bit
                    ldd       <OffsetVal load the offset value
                    cmpd      #15       compare with the five-bit maximum
                    bgt       Use8BitOffset too big, use eight-bit
                    ldd       <OffsetVal reload the value
                    cmpd      #-16      compare with the five-bit minimum
                    bge       Use5BitOffset in range, use five-bit
Use8BitOffset       ldd       <OffsetVal load the offset value
                    stb       <OperandLow store the low byte as the operand
                    ldd       <PassType load the length count
                    addd      #1        add one byte
                    std       <PassType store the count
                    ldb       <ModeFlags load the mode flags
                    sex                 sign extend
                    orb       #8        set the byte-offset flag
                    stb       <ModeFlags store the flags
                    ldb       <PostByte load the postbyte
                    sex                 sign extend
                    orb       #136      set the eight-bit offset bits
                    lbra      StoreIndexPostbyte store and finish

Use5BitOffset       ldb       <PostByte load the postbyte
                    sex                 sign extend
                    pshs      D         push it
                    ldd       <OffsetVal load the offset value
                    clra                clear the high byte
                    andb      #31       mask to five bits
                    ora       ,S+       combine with the postbyte
                    orb       ,S+       combine the low bits
                    lbra      StoreIndexPostbyte store and finish

                    fcb       $35
                    fcb       $C0
EmitPcRelative      pshs      U         save u
                    ldb       [>SrcPtr,Y] load the source character
                    clra                clear the high byte
                    andb      #223      force uppercase
                    cmpd      #80       compare with letter p
                    bne       NotPcRelative not pcr, plain form
                    ldx       <SrcPtr   load the source pointer
                    ldb       1,X       load the next character
                    clra                clear the high byte
                    andb      #223      force uppercase
                    cmpd      #67       compare with letter c
                    beq       GotPcRelative matched pc, handle pcr
NotPcRelative       lbsr      IllegalIndexRegErr process an ordinary offset
                    puls      PC,U      restore and return

GotPcRelative       ldd       <SrcPtr   load the source pointer
                    addd      #2        skip past the pc letters
                    std       <SrcPtr   store it
                    ldb       [>SrcPtr,Y] load the next character
                    clra                clear the high byte
                    andb      #223      force uppercase
                    cmpd      #82       compare with letter r
                    bne       SkipRegChar no r, skip the advance
                    ldd       <SrcPtr   load the source pointer
                    addd      #1        skip past the r
                    std       <SrcPtr   store it
SkipRegChar         ldd       <PassType load the length count
                    addd      #1        add one byte
                    std       <PassType store the count
                    ldb       <ModeFlags load the mode flags
                    sex                 sign extend
                    orb       #128      set the pc-relative flag
                    stb       <ModeFlags store the flags
                    ldd       <OffsetVal load the offset value
                    pshs      D         push it
                    ldd       <TargetAddr load the base address
                    addd      <PassType add the length count
                    addd      #1        add one more byte
                    nega                negate the high byte
                    negb                negate the low byte
                    sbca      #0        finish the negation
                    addd      ,S++      add the offset value
                    std       <OffsetVal store the relative offset
                    ldd       <OffsetFlag load the offset flag
                    ble       Use16BitPcRel not positive, use eight-bit pcr
                    ldd       <OffsetVal load the relative offset
                    stb       <OperandLow store the low byte as the operand
                    ldb       <ModeFlags load the mode flags
                    sex                 sign extend
                    orb       #8        set the byte-offset flag
                    stb       <ModeFlags store the flags
                    ldb       <PostByte load the postbyte
                    sex                 sign extend
                    orb       #140      set the eight-bit pc-relative bits
                    bra       StoreIndexPostbyte store and finish

Use16BitPcRel       ldd       <PassType load the length count
                    addd      #1        add one byte
                    std       <PassType store the count
                    ldd       <OffsetVal load the relative offset
                    addd      #-1       adjust for the extra byte
                    std       <OffsetVal store it
                    std       <OperandLow store it as the operand
                    ldb       <PostByte load the postbyte
                    sex                 sign extend
                    orb       #141      set the sixteen-bit pc-relative bits
StoreIndexPostbyte  stb       <PostByte store the postbyte
                    lbsr      FinishIndexPostbyte emit the assembled bytes
                    puls      PC,U      restore and return

                    puls      PC,U      restore and return

MsgIllegalMode      fcc       "illegal addressing mode"
                    fcb       C$NULL
MsgIllegalIndexReg  fcc       "illegal index register"
                    fcb       C$NULL
MsgBracketMissing   fcc       "bracket missing"
                    fcb       C$NULL
Lt_170E             pshs      U         save u
                    lbsr      GetOperandToken get the operand token
                    std       -2,S      save the result
                    bne       CheckOperandCount nonzero, continue
                    lbra      OperandFail none, return failure

                    bra       CheckOperandCount continue

ProcessOperandLoop  clra                clear the argument high
                    clrb                clear the argument low
                    pshs      D         push it
                    lbsr      EmitByte  process the operand
                    leas      2,S       drop the argument
CheckOperandCount   ldd       <OperandVal load the operand count
                    addd      #-1       decrement it
                    std       <OperandVal store the count
                    subd      #-1       test the count
                    bne       ProcessOperandLoop loop while more remain
                    lbra      ReturnOne return success

Lt_1734             pshs      U         save u
                    bsr       GetOperandToken get the operand token
                    std       -2,S      save the result
                    lbeq      OperandFail none, return failure
                    leax      >reldt,Y  point at the relocation data
                    stx       <WorkPtr  save the pointer
                    pshs      X         push it
                    lbsr      ReadRelocValue read the current value
                    std       [,S++]    store it back
                    ldd       <LabelField load the pass flag
                    beq       WriteRelocValue skip if the first pass
                    ldb       <TypeFlags load the segment flag
                    sex                 sign extend
                    andb      #254      clear the low bit
                    pshs      D         push it
                    lbsr      MergeSymFlags emit the segment
                    leas      2,S       drop the argument
                    ldd       <reldt    load the relocation value
                    pshs      D         push it
                    lbsr      ResolveSym emit the value
                    leas      2,S       drop the argument
WriteRelocValue     ldd       <reldt    load the relocation value
                    addd      <OperandVal add the operand count
                    pshs      D         push it
                    bsr       WriteRelocPtr write the updated value
                    leas      2,S       drop the argument
                    lbra      ReturnOne return success

GetOperandToken     pshs      U,D       save the registers
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        clear the result slot
                    ldu       <InputPtr load the input pointer
                    lbsr      EvalLineExpr read the next token
                    std       -2,S      save the token
                    beq       GetTokenDone none, return
                    lbsr      CompactModeList compact the mode list
                    leax      >ListStart,Y point at the list start
                    cmpx      >ListEnd,Y compare with the list end
                    bne       EvalOperand nonempty, evaluate it
                    ldd       #1        set the flag
                    std       ,S        mark the result
                    bra       GetTokenDone return

EvalOperand         lbsr      ExtRefErr evaluate the expression
                    std       <OperandVal store the value
GetTokenDone        stu       <InputPtr save the input pointer
                    ldd       ,S        load the result
                    puls      PC,U,X    restore and return

ReadRelocValue      pshs      U         save u
                    ldd       <FieldPtr load the pointer
                    bne       DerefValue nonzero, dereference it
                    clra                clear the high byte
                    clrb                clear the low byte
                    bra       ReadValueDone return zero

DerefValue          ldd       [>FieldPtr,Y] load the value it points to
ReadValueDone       puls      PC,U      restore and return

WriteRelocPtr       pshs      U         save u
                    ldd       <FieldPtr load the pointer
                    beq       WriteValueDone skip if null
                    ldd       4,S       load the argument value
                    std       [>FieldPtr,Y] store it via the pointer
WriteValueDone      ldd       4,S       load the argument value
                    puls      PC,U      restore and return

Lt_17BF             pshs      U         save u
                    ldd       #6        select field six
                    pshs      D         push it
                    bsr       ProcessField process the field
                    puls      PC,U,X    restore and return

Lt_17CA             pshs      U         save u
                    ldd       #5        select field five
                    pshs      D         push it
                    bsr       ProcessField process the field
                    puls      PC,U,X    restore and return

ProcessField        pshs      U         save u
                    ldd       <LabelField load the pass flag
                    bne       EmitFieldValue skip on the later pass
                    leax      >MsgLabelMissing2,PC point at the message
                    pshs      X         push it
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    restore and return

EmitFieldValue      ldd       4,S       load the field argument
                    pshs      D         push it
                    lbsr      MergeSymFlags emit the field
                    leas      2,S       drop the argument
                    ldu       <InputPtr load the input pointer
                    lbsr      EvalLineExpr read the next token
                    std       -2,S      save the token
                    bne       HaveFieldToken nonzero, continue
OperandFail         clra                clear the result high
                    clrb                clear the result low
                    puls      PC,U      restore and return

HaveFieldToken      stu       <InputPtr save the input pointer
                    lbsr      CompactModeList compact the mode list
                    ldd       <OperandVal load the operand value
                    pshs      D         push it
                    lbsr      ResolveSym emit the value
                    leas      2,S       drop the argument
                    leax      >OperandVal,Y point at the operand value
                    stx       <WorkPtr  save the pointer
                    lbra      ReturnOne return success

Lt_1813             pshs      U         save u
                    ldd       #1        select mode one
                    pshs      D         push it
                    bsr       ScanModeChars process the mode
                    puls      PC,U,X    restore and return

Lt_181E             pshs      U         save u
                    ldd       #2        select mode two
                    pshs      D         push it
                    bsr       ScanModeChars process the mode
                    puls      PC,U,X    restore and return

ScanModeChars       pshs      U,X,D     save the registers
                    ldb       [>SrcPtr,Y] load the source character
                    stb       1,S       save it
                    lbeq      EmitSingleArg none, exit
                    ldd       <SrcPtr   load the source pointer
                    std       2,S       save it
                    bra       CopyArgCharLoop enter the scan loop

CompareCharLoop     ldb       ,S        load the saved character
                    sex                 sign extend
                    pshs      D         push it
                    ldb       3,S       load another character
                    sex                 sign extend
                    cmpd      ,S++      compare the two
                    beq       ArgTermCheck branch when the character is zero
CopyArgCharLoop     ldx       2,S       load the source pointer
                    leax      1,X       advance past this character
                    stx       2,S       save the updated pointer
                    ldb       ,X        fetch the next character
                    stb       ,S        store the current character
                    bne       CompareCharLoop loop while not the terminator
ArgTermCheck        ldb       ,S        load the current character
                    lbeq      EmitNumericArg branch if end of operand
                    ldd       2,S       load the source pointer
                    subd      #2        back up two bytes
                    std       2,S       save the adjusted pointer
                    cmpd      <SrcPtr   compare against the input pointer
                    bcs       ArgDone   skip if before the input pointer
                    bra       EmitStrLoop enter the string emit loop

EmitStrByteLoop     ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the input pointer
                    ldb       ,X        fetch the character
                    sex                 sign extend to a word
                    pshs      D         pass the character as an argument
                    lbsr      EmitByte  emit the character byte
                    leas      2,S       drop the argument
EmitStrLoop         ldd       <SrcPtr   load the input pointer
                    cmpd      2,S       compare against the end pointer
                    bcs       EmitStrByteLoop loop while more characters remain
                    ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the input pointer
                    ldb       ,X        fetch the final character
                    stb       ,S        store the current character
                    ldd       8,S       load the operand size
                    cmpd      #2        is it a two byte operand
                    bne       EmitLastStrByte skip if not word sized
                    ldb       ,S        load the character
                    sex                 sign extend to a word
                    orb       #128      set the high bit marker
                    stb       ,S        store it back
EmitLastStrByte     ldb       ,S        load the character
                    sex                 sign extend to a word
                    pshs      D         pass the character as an argument
                    lbsr      EmitByte  emit the character byte
                    leas      2,S       drop the argument
ArgDone             ldd       <SrcPtr   load the input pointer
                    addd      #2        skip past the closing quote
                    std       <SrcPtr   save the input pointer
                    ldd       #1        return success
                    bra       OperandCleanup finish the operand

EmitNumericArg      ldd       2,S       load the source pointer
                    std       <SrcPtr   set the input pointer
EmitSingleArg       bsr       ReportOperandErr emit a single numeric operand
                    bra       OperandCleanup finish the operand

ReportOperandErr    pshs      U         save the caller u register
                    leax      >MsgConstantDef,PC point at the error message
                    pshs      X         pass the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return to caller

Lt_18C3             pshs      U         save the caller u register
                    leax      >U0032,Y  point at the byte value
                    stx       >EmitBufPtr,Y set the emit buffer pointer
                    ldd       #1        one byte per operand
                    pshs      D         pass the operand size
                    leax      >ParseReloc,PC point at the fcb handler
                    bra       ProcessOperands process the operand list

Lt_18D8             pshs      U         save the caller u register
                    leax      >OperandVal,Y point at the word value
                    stx       >EmitBufPtr,Y set the emit buffer pointer
                    ldd       #2        two bytes per operand
                    pshs      D         pass the operand size
                    leax      >ParseValue,PC point at the fdb handler
ProcessOperands     pshs      X         pass the handler pointer
                    bsr       EmitOperandList process the operand list
OperandCleanup      leas      4,S       drop the arguments
                    puls      PC,U      return to caller

EmitOperandList     pshs      U         save the caller u register
                    bra       OperandLoop enter the operand loop

NextOperand         bsr       FlushObjBuf flush the object buffer
                    ldd       <SrcPtr   load the input pointer
                    addd      #1        skip past the comma
                    std       <SrcPtr   save the input pointer
OperandLoop         ldd       6,S       load the operand size
                    std       <PassType set the byte count
                    jsr       [<4,S]    call the operand handler
                    ldb       [>SrcPtr,Y] fetch the next character
                    cmpb      #',       is it a comma
                    beq       NextOperand loop for another operand
                    lbra      ReturnOne finish the directive

EmitByte            pshs      U         save the caller u register
                    ldd       <PassType load the buffer index
                    cmpd      #4        is the buffer full
                    blt       StoreBufByte skip flush if room remains
                    bsr       FlushObjBuf flush the object buffer
StoreBufByte        ldd       <PassType load the buffer index
                    addd      #1        advance the index
                    std       <PassType save the index
                    subd      #1        recover the previous index
                    addd      >EmitBufPtr,Y add the buffer base
                    tfr       D,X       form the store address
                    ldb       5,S       load the byte argument
                    stb       ,X        store the byte in the buffer
                    puls      PC,U      return to caller

FlushObjBuf         pshs      U         save the caller u register
                    ldd       <PassType load the byte count
                    pshs      D         pass the byte count
                    ldd       >EmitBufPtr,Y load the buffer pointer
                    pshs      D         pass the buffer pointer
                    lbsr      UpdateSectionSize write the object record
                    leas      4,S       drop the arguments
                    ldd       <ListFlag load the relocation flag
                    beq       ClearBufIndex skip if no relocation
                    lbsr      EmitListingLine emit the relocation record
                    ldb       <PassFlag load the pass flag
                    beq       ClearRelocFlag branch if first pass
                    ldb       <FlagByte load a mode flag
                    beq       ClearRelocFlag branch if clear
                    ldb       <OptionFlag load a mode flag
                    ble       ClearRelocFlag branch if not positive
                    ldb       <U00C1    load a mode flag
                    ble       ClearRelocFlag branch if not positive
                    ldd       #1        set the relocation flag
                    bra       ResetEmitState store the flag

ClearRelocFlag      clra                clear the relocation flag
                    clrb                clear the low byte
ResetEmitState      std       <ListFlag save the relocation flag
                    clra                clear accumulator
                    clrb                clear the low byte
                    std       <CommentPtr reset a counter
                    std       <OperandPtr reset a counter
                    std       <OpcodeField reset a counter
                    std       <LabelField reset a counter
                    ldd       <RelocPtr load the reloc pointer
                    beq       ClearBufIndex skip if none
                    ldd       [>RelocPtr,Y] load the relocation data
                    std       <reldt    save the relocation data
ClearBufIndex       clra                clear accumulator
                    clrb                clear the low byte
                    std       <PassType reset the buffer index
                    puls      PC,U      return to caller

Lt_197F             pshs      U         save the caller u register
                    ldd       #3        three bytes to emit
                    std       <PassType set the byte count
                    lbsr      ParseReloc emit the fcb bytes
                    ldd       #16       load the value sixteen
                    stb       <OpcodeClass store the low byte
                    ldd       #63       load the value sixty three
                    stb       <PostByte store the low byte
                    ldd       <OperandVal load the operand value
                    stb       <OperandLow store the low byte
                    lbra      ReturnOne finish the directive

SetValueHandler     pshs      U         save the caller u register
                    ldb       [>SrcPtr,Y] fetch the current character
                    cmpb      #',       is it a comma
                    bne       ParseSetExpr branch if not a comma
                    ldd       <SrcPtr   load the input pointer
                    addd      #1        skip past the comma
                    bra       StoreInputPtr store and finish

ParseSetExpr        leax      >MsgCommaExpected,PC point at the error message
                    pshs      X         pass the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    restore and continue

Lt_19B6             pshs      U         save the caller u register
                    lbsr      GetOperandToken parse the value expression
                    ldd       <RelocPtr load the reloc pointer
                    beq       SetHandlerRet skip if none
                    ldd       <OperandVal load the operand value
                    std       [>RelocPtr,Y] store into the relocation slot
SetHandlerRet       puls      PC,U      return to caller

Lt_19C7             pshs      U         save the caller u register
                    puls      PC,U      return to caller

Lt_19CB             pshs      U         save the caller u register
                    leax      >Y05C7,Y  point at the name buffer
                    pshs      X         pass the buffer pointer
                    bsr       CopyOperandStr copy the operand string
                    puls      PC,U,X    restore and return

CopyOperandStr      pshs      U         save the caller u register
                    ldu       4,S       load the destination pointer
                    ldb       <PassFlag load the pass flag
                    bne       CopyStrLoop skip the check on the second pass
                    ldb       ,U        load the existing byte
                    lbne      ReturnOne error if already defined
CopyStrLoop         ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the input pointer
                    ldb       -1,X      fetch the character
                    stb       ,U+       store into the destination
                    bne       CopyStrLoop loop until the terminator
                    ldd       <SrcPtr   load the input pointer
                    addd      #-1       back up over the terminator
StoreInputPtr       std       <SrcPtr   save the input pointer
                    lbra      ReturnOne finish the directive

Lt_19FB             pshs      U         save the caller u register
                    leax      >Y063F,Y  point at the name buffer
                    pshs      X         pass the buffer pointer
                    bsr       CopyOperandStr copy the operand string
                    puls      PC,U,X    restore and return

Lt_1A07             pshs      U         save the caller u register
                    lbsr      SyncLineNumbers process the directive
                    bra       ClearRelocDone clear reloc flag and finish

Lt_1A0E             pshs      U         save the caller u register
                    bsr       EvalCountExpr evaluate the count expression
                    std       -2,S      save the result flag
                    beq       RepeatRet skip if evaluation failed
                    bra       RepeatCountLoop enter the repeat loop

RepeatUnitLoop      lbsr      AdvanceLine emit one repeated unit
RepeatCountLoop     ldd       <OperandVal load the repeat count
                    addd      #-1       decrement the count
                    std       <OperandVal save the count
                    subd      #-1       test the count for zero
                    bne       RepeatUnitLoop loop while count remains
ClearRelocDone      clra                clear the relocation flag
                    clrb                clear the low byte
                    std       <ListFlag save the flag
RepeatRet           puls      PC,U      return to caller

EvalCountExpr       pshs      U         save the caller u register
                    lbsr      ParseNumber evaluate the expression
                    std       -2,S      save the result flag
                    beq       EvalExprErr branch if evaluation failed
                    ldd       #1        return success
                    bra       EvalExprRet return to caller

EvalExprErr         leax      >MsgBadNumber,PC point at the error message
                    pshs      X         pass the message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
EvalExprRet         puls      PC,U      return to caller

ParseOptionList     pshs      U         save the caller u register
                    leas      -3,S      reserve local storage
                    lbsr      SkipSpaces fetch the next token
OptionCharLoop      stb       ,S        store the current character
                    ldb       ,S        load the character
                    cmpb      #'-       is it a minus sign
                    beq       GotMinusSign branch if negation
                    ldd       #1        assume a positive sign
                    bra       StoreSign store the sign

GotMinusSign        clra                clear the sign flag
                    clrb                clear the low byte
StoreSign           std       1,S       save the sign flag
                    bne       LookupOption skip if positive
                    ldd       #-1       mark a negative sign
                    std       1,S       save the sign flag
                    ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the sign
                    stx       <SrcPtr   save the input pointer
                    ldb       ,X        fetch the next character
                    stb       ,S        store the character
LookupOption        ldb       ,S        load the character
                    sex                 sign extend to a word
                    orb       #32       convert to lowercase
                    stb       ,S        store the character
                    leau      >OptionTbl,Y point at the option table
                    bra       OptTableCond enter the search loop

OptTableLoop        ldb       ,S        load the character
                    sex                 sign extend to a word
                    pshs      D         save the character
                    ldb       ,U        load the table entry character
                    sex                 sign extend to a word
                    cmpd      ,S++      compare against the character
                    bne       NextOptEntry advance if no match
                    ldb       [<1,U]    load the count field
                    sex                 sign extend to a word
                    addd      1,S       add the sign value
                    stb       [<1,U]    store the updated count
                    bra       OptEntryFound continue after the match

NextOptEntry        leau      3,U       advance to the next entry
OptTableCond        leax      >JumpTbl1,Y point past the table end
                    pshs      X         pass the end pointer
                    cmpu      ,S++      compare against the end
                    bcs       OptTableLoop loop while within the table
OptEntryFound       leax      >JumpTbl1,Y point past the table end
                    pshs      X         pass the end pointer
                    cmpu      ,S++      compare against the end
                    bcs       CheckOptionComma skip if an entry was found
                    ldb       ,S        load the character
                    sex                 sign extend to a word
                    tfr       D,X       move into the index register
                    bra       MatchOptionChar match against the known options

HandleDOption       lbsr      EvalCountExpr evaluate the expression
                    std       -2,S      save the result flag
                    beq       HandleDefaultOpt branch if evaluation failed
                    ldd       <OperandVal load the operand value
                    std       <U0003    store the d option value
                    bra       CheckOptionComma continue after the option

HandleWOption       lbsr      EvalCountExpr evaluate the expression
                    std       -2,S      save the result flag
                    beq       HandleDefaultOpt branch if evaluation failed
                    ldd       <OperandVal load the operand value
                    std       <U0005    store the w option value
                    bra       CheckOptionComma continue after the option

HandleDefaultOpt    bsr       ParseOptExpr handle the default option
                    bra       OptionListRet return from the parser

MatchOptionChar     cmpx      #100      is it the letter d
                    beq       HandleDOption handle the d option
                    cmpx      #119      is it the letter w
                    beq       HandleWOption handle the w option
                    bra       HandleDefaultOpt handle the default option

CheckOptionComma    ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the input pointer
                    ldb       ,X        fetch the next character
                    cmpb      #',       is it a comma
                    bne       OptionListDone branch if no more options
                    ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the comma
                    stx       <SrcPtr   save the input pointer
                    ldb       ,X        fetch the next character
                    lbra      OptionCharLoop loop for another option

OptionListDone      ldd       #1        return success
OptionListRet       leas      3,S       release local storage
                    puls      PC,U      return to caller

ParseOptExpr        pshs      U         save the caller u register
                    leax      >MsgBadOption,PC point at the error message
                    pshs      X         pass the message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    restore and continue

Lt_1B0A             pshs      U         save the caller u register
                    lbsr      EvalLineExpr evaluate the expression
                    std       -2,S      save the result flag
                    beq       StoreLabelRef skip if evaluation failed
                    lbsr      CompactModeList process the value
StoreLabelRef       leax      >ListStart,Y point at the label buffer
                    stx       >ListEnd,Y set the label pointer
                    lbeq      ProcessReptLine branch if the value was zero
                    ldd       <OperandVal load the operand value
                    std       <CurValue save the current value
                    leax      >OperandVal,Y point at the operand value
                    stx       <WorkPtr  set the value pointer
                    lbra      ReturnOne finish the directive

Lt_1B2F             pshs      U         save the caller u register
                    leas      -1,S      reserve local storage
                    ldd       <CurFileHand load the current pointer
                    ldx       >SavedStkPtr,Y load the stack pointer
                    leax      2,X       advance the stack pointer
                    stx       >SavedStkPtr,Y save the stack pointer
                    std       -2,X      push the saved pointer
                    leax      >StrOptionR,PC point at the directive name
                    pshs      X         pass the name pointer
                    ldd       <SrcPtr   load the input pointer
                    pshs      D         pass the input pointer
                    lbsr      OpenFile  process the directive
                    leas      4,S       drop the arguments
                    std       <CurFileHand save the returned pointer
                    bra       ScanLineChar enter the scan loop

LineSpaceCheck      ldb       ,S        load the current character
                    cmpb      #32       is it a space
                    lbeq      DPKeywordFound finish at the space
ScanLineChar        ldx       <SrcPtr   load the input pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the input pointer
                    ldb       ,X        fetch the next character
                    stb       ,S        store the character
                    bne       LineSpaceCheck loop until end of line
                    lbra      DPKeywordFound finish the directive

Lt_1B6B             pshs      U         save the caller u register
                    ldd       <OperandVal load the operand value
                    lbne      ReptReturnZero branch if nonzero
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

Lt_1B79             pshs      U         save the caller u register
                    ldd       <OperandVal load the operand value
                    lbeq      ReptReturnZero branch if zero
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

Lt_1B87             pshs      U         save the caller u register
                    ldd       <OperandVal load the operand value
                    lbge      ReptReturnZero branch if greater or equal
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

Lt_1B95             pshs      U         save the caller u register
                    ldd       <OperandVal load the operand value
                    lbgt      ReptReturnZero branch if greater than
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

Lt_1BA3             pshs      U         save the caller u register
                    ldd       <OperandVal load the operand value
                    lblt      ReptReturnZero branch if less than
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

Lt_1BB1             pshs      U         save the caller u register
                    ldd       <OperandVal load the operand value
                    lble      ReptReturnZero branch if less or equal
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

IfPass2Handler      pshs      U         save the caller u register
                    ldb       <PassFlag load the pass flag
                    lbne      ReptReturnZero branch on the second pass
                    ldd       #1        set the true result
                    lbra      ReptExit  store the condition result

Lt_1BCD             pshs      U         save the caller u register
                    leax      >Y025E,Y  point at a table
                    stx       <SectBasePtr set the pointer
                    ldd       >Y000D,Y  load a value
                    std       <SectSizePtr save the value
                    leax      >Y035A,Y  point at a table
                    stx       <RelocWrPtr set the pointer
                    leax      >BssSectPtr,Y point at a buffer
                    stx       <BufPtr   set the pointer
                    ldd       #1        load the value one
                    stb       <SectType set the mode byte
                    clra                clear accumulator
                    clrb                clear the low byte
                    stb       <SectSizeByte clear the flag byte
                    leax      >U0045,Y  point at the reloc slot
                    stx       <RelocPtr set the reloc pointer
                    leax      >U0041,Y  point at a value
                    stx       <FieldPtr set the pointer
                    bsr       ParseDPKeyword parse the direct page keyword
                    std       -2,S      save the result flag
                    beq       StoreSectReloc skip if not direct page
                    leax      >DataSectPtr,Y point at the reloc slot
                    stx       <BufPtr   set the pointer
                    ldd       #3        load the value three
                    stb       <SectType set the mode byte
                    ldd       #16       load the value sixteen
                    stb       <SectSizeByte set the flag byte
                    leax      >U0047,Y  point at the reloc slot
                    stx       <RelocPtr set the reloc pointer
                    leax      >U0043,Y  point at a value
                    stx       <FieldPtr set the pointer
StoreSectReloc      ldd       [>RelocPtr,Y] load the relocation data
                    std       <reldt    save the relocation data
                    lbra      ReturnOne finish the directive

ParseDPKeyword      pshs      U         save the caller u register
                    leas      -1,S      reserve local storage
                    ldb       [>SrcPtr,Y] fetch the current character
                    clra                clear the high byte
                    andb      #223      convert to uppercase
                    stb       ,S        store the character
                    beq       PrintAndReturn branch if end of line
                    ldb       ,S        load the character
                    cmpb      #68       is it the letter d
                    bne       PrintAndReturn branch if not d
                    ldx       <SrcPtr   load the input pointer
                    ldb       1,X       fetch the next character
                    clra                clear the high byte
                    andb      #223      convert to uppercase
                    cmpd      #80       is it the letter p
                    bne       PrintAndReturn branch if not p
                    ldx       <SrcPtr   load the input pointer
                    ldb       2,X       fetch the following character
                    beq       SkipDPKeyword branch if end of line
                    ldx       <SrcPtr   load the input pointer
                    ldb       2,X       fetch the following character
                    cmpb      #32       is it a space
                    bne       DPKeywordErr branch if not a space
SkipDPKeyword       ldd       <SrcPtr   load the input pointer
                    addd      #2        skip past the keyword
                    std       <SrcPtr   save the input pointer
DPKeywordFound      ldd       #1        return true
                    bra       PrintAndReturn return to caller

DPKeywordErr        leax      >MsgDpSection,PC point at the error message
                    pshs      X         push the message pointer argument
                    lbsr      EmitMessageLine print the error message
                    leas      2,S       discard the argument
PrintAndReturn      leas      1,S       discard one more saved byte
                    puls      PC,U      restore u and return

InitSectionDefaults pshs      U         save the caller u register
                    clra                form zero in d
                    clrb                form zero in d
                    std       <PassType clear the pass type
                    leax      >Y0106,Y  point to the y0106 buffer
                    stx       <SectBasePtr save the buffer pointer
                    ldd       >Y0007,Y  load global y0007
                    std       <SectSizePtr save it
                    leax      >Y0332,Y  point to the y0332 buffer
                    stx       <RelocWrPtr save the buffer pointer
                    clra                form zero in d
                    clrb                form zero in d
                    std       <BufPtr   clear the buffer pointer
                    ldd       #4        load default section value four
                    stb       <SectType set the section type
                    ldd       #160      load default value 160
                    stb       <SectFlags set the section flags
                    clra                form zero in d
                    clrb                form zero in d
                    stb       <SectSizeByte clear the section-size byte
                    clra                form zero in d
                    clrb                form zero in d
                    std       <FieldPtr clear the field pointer
                    std       <RelocPtr clear current value pointer
                    lbra      ReturnOne return one

Lt_1CA5             pshs      U         save the caller u register
                    ldd       <OperandPtr load the fail message pointer
                    beq       UseDefaultFailMsg use default text if none
                    ldd       <OperandPtr load the user message
                    bra       PrintFailMsg go print it

UseDefaultFailMsg   leax      >MsgFail,PC point to the default "fail" text
                    tfr       X,D       move pointer into d
PrintFailMsg        pshs      D         push the message pointer
                    lbsr      EmitMessageLine print the message
                    puls      PC,U,X    discard argument and return

Lt_1CBC             pshs      U         save the caller u register
                    leax      >ReptBuffer,Y point to the rept counter
                    lda       ,X        load first counter byte
                    ora       1,X       or in second byte
                    ora       2,X       or in third byte
                    ora       3,X       or in fourth byte
                    beq       EvalReptCount zero means no active rept
                    leax      >MsgNestedRept,PC point to "nested REPT" text
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine print the error
                    puls      PC,U,X    discard argument and return

EvalReptCount       lbsr      EvalLineExpr evaluate the repeat count
                    std       -2,S      save the count
                    bne       CaptureReptBody nonzero count continues
ReptReturnZero      clra                zero result
                    clrb                zero result
ReptExit            puls      PC,U      return

CaptureReptBody     lbsr      CompactModeList start capturing the rept body
                    leax      >ListStart,Y point to the current input line
                    cmpx      >ListEnd,Y compare with the output pointer
                    beq       SetupReptLoop equal means empty body
ProcessReptLine     lbsr      ExtRefErr process the line
                    puls      PC,U      return

SetupReptLoop       ldd       <OperandVal load the loop count
                    std       <RepeatCount save the remaining count
                    beq       ReptZeroCount zero count takes other path
                    leax      >ReptBuffer,Y point to the rept buffer
                    pshs      X         push the buffer pointer
                    ldd       <MarkerFlag load the mode flag
                    beq       ReptUseDefault use default if zero
                    ldd       <LinePtr  load the alternate value
                    bra       ReptCallHandler continue

ReptUseDefault      ldd       <CurFileHand load the default value
ReptCallHandler     pshs      D         push the argument
                    lbsr      CurFilePos call the replay handler
                    leas      2,S       discard the argument
                    lbra      ReleaseReptBuf go finish

ReptZeroCount       ldd       #1        load one
                    bra       StoreEndrFlag store it and return

EndrDirective       pshs      U         save the caller u register
                    ldd       <CondActive load the endr flag
                    beq       DoEndr    not set, process the endr
                    clra                zero value
                    clrb                zero value
StoreEndrFlag       std       <CondActive store the endr flag
                    lbra      ReturnOne return one

DoEndr              leax      >ReptBuffer,Y point to the rept buffer
                    ldd       2,X       load the second word
                    pshs      D         push it
                    ldd       ,X        load the first word
                    pshs      D         push it
                    bsr       CheckReptActive check the rept is active
                    neg       <U0000    unreachable bytes after tail call
                    neg       <U0000    unreachable bytes after tail call
CheckReptActive     puls      X         discard the return address
                    lbsr      Cmp32     verify a rept is active
                    bne       DecReptCount active, continue processing
                    leax      >MsgEndrNoRept,PC point to "ENDR without REPT" text
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine print the error
                    puls      PC,U,X    discard argument and return

DecReptCount        ldd       <RepeatCount load the remaining repeat count
                    addd      #-1       decrement it
                    std       <RepeatCount save it
                    ble       FinishRept done when count exhausted
                    clra                zero value
                    clrb                zero value
                    pshs      D         push zero argument
                    leax      >ReptBuffer,Y point to the rept buffer
                    ldd       2,X       load the second word
                    pshs      D         push it
                    ldd       ,X        load the first word
                    pshs      D         push it
                    ldd       <MarkerFlag load the mode flag
                    beq       EndrUseDefault use default if zero
                    ldd       <LinePtr  load the alternate value
                    bra       EndrReplay continue

EndrUseDefault      ldd       <CurFileHand load the default value
EndrReplay          pshs      D         push the argument
                    lbsr      Fseek     replay the rept body
                    leas      8,S       discard the arguments
                    clra                zero value
                    clrb                zero value
                    std       <ListFlag clear the listing flag
                    bra       ReturnOne return one

FinishRept          leax      >ReptBuffer,Y point to the rept buffer
                    pshs      X         push the buffer pointer
                    bsr       FinishReptTail finish the rept processing
                    neg       <U0000    unreachable bytes after tail call
                    neg       <U0000    unreachable bytes after tail call
FinishReptTail      puls      X         discard the return address
ReleaseReptBuf      lbsr      StoreLong release the rept capture buffer
ReturnOne           ldd       #1        return value one
                    puls      PC,U      restore u and return

MsgLabelMissing2    fcc       "label missing"
                    fcb       C$NULL
MsgConstantDef      fcc       "constant definition"
                    fcb       C$NULL
MsgCommaExpected    fcc       "comma expected"
                    fcb       C$NULL
MsgBadNumber        fcc       "bad number"
                    fcb       C$NULL
MsgBadOption        fcc       "bad option"
                    fcb       C$NULL
StrOptionR          fcb       $72
                    fcb       C$NULL
MsgDpSection        fcc       "DP section ???"
                    fcb       C$NULL
MsgFail             fcc       "fail"
                    fcb       C$NULL
MsgNestedRept       fcc       "nested REPT"
                    fcb       C$NULL
MsgEndrNoRept       fcc       "ENDR without REPT"
                    fcb       C$NULL
ScanName            pshs      U,D       save u and reserve a local
                    ldb       [>SrcPtr,Y] load the current input character
                    sex                 sign-extend to d
                    leax      >CharClassTbl,Y point to the character class table
                    leax      D,X       index by the character
                    ldb       ,X        load the class flags
                    clra                clear the high byte
                    andb      #6        test the name-start bits
                    lbeq      NotAName  not a name, return zero
                    ldd       #9        maximum name length
                    std       ,S        save the length counter
                    bra       NameCopyLoop enter the copy loop

CopyNameChar        ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance it
                    stx       <SrcPtr   save the source pointer
                    ldb       -1,X      load the character
                    ldx       6,S       load the destination pointer
                    leax      1,X       advance it
                    stx       6,S       save the destination pointer
                    stb       -1,X      store the character
NameCopyLoop        ldd       ,S        load the remaining count
                    addd      #-1       decrement it
                    std       ,S        save the count
                    subd      #-1       test the count for exhaustion
                    ble       TerminateName length exhausted
                    ldb       [>SrcPtr,Y] load the current character
                    sex                 sign-extend to d
                    leax      >CharClassTbl,Y point to the class table
                    leax      D,X       index by the character
                    ldb       ,X        load the class flags
                    clra                clear the high byte
                    andb      #15       test the name-continue bits
                    bne       CopyNameChar still a name character
TerminateName       clra                zero value
                    clrb                zero value
                    stb       [<6,S]    null-terminate the name
                    bra       SkipNameLoop skip any remaining characters

SkipNameStep        ldd       <SrcPtr   load the source pointer
                    addd      #1        advance it
                    std       <SrcPtr   save the source pointer
SkipNameLoop        ldb       [>SrcPtr,Y] load the current character
                    sex                 sign-extend to d
                    leax      >CharClassTbl,Y point to the class table
                    leax      D,X       index by the character
                    ldb       ,X        load the class flags
                    clra                clear the high byte
                    andb      #15       test the name-continue bits
                    bne       SkipNameStep skip trailing name characters
                    ldd       #1        return success
                    puls      PC,U,X    restore and return

NotAName            clra                zero result
                    clrb                zero result
                    puls      PC,U,X    restore and return

ParseLabel          pshs      U,D       save u and reserve a local
                    clra                zero value
                    clrb                zero value
                    std       <InputPtr clear the symbol pointer
                    leax      >LabelNameBuf,Y point to the label name buffer
                    pshs      X         push the buffer pointer
                    lbsr      ScanName  scan the label name
                    std       ,S++      save result, discard argument
                    bne       CheckColon got a name
                    clra                zero result
                    clrb                zero result
                    puls      PC,U,X    no label, return zero

CheckColon          ldb       [>SrcPtr,Y] load the current character
                    cmpb      #':       is it a colon
                    bne       EnterLabelSym no colon present
                    ldd       <SrcPtr   load the source pointer
                    addd      #1        advance past the colon
                    std       <SrcPtr   save the source pointer
                    ldb       <LabelFlags load the label flags
                    sex                 sign-extend to d
                    orb       #4        set the colon flag
                    stb       <LabelFlags save the label flags
EnterLabelSym       leax      >InputPtr,Y point to the symbol pointer
                    pshs      X         push it
                    leax      >LabelNameBuf,Y point to the label name
                    pshs      X         push it
                    lbsr      LookupName look up or enter the symbol
                    leas      4,S       discard the arguments
                    std       ,S        save the symbol pointer
                    ldu       <InputPtr load the symbol record pointer
                    ldb       <PassFlag load the pass flag
                    lbne      LabelPass2 second pass handling
                    ldd       ,S        load the lookup result
                    beq       SetSymbolType new symbol
                    ldd       ,S        load the result
                    pshs      D         push it
                    leax      >InputPtr,Y point to the symbol pointer
                    pshs      X         push it
                    leax      >LabelNameBuf,Y point to the label name
                    pshs      X         push it
                    lbsr      AllocTreeNode enter the new symbol
                    leas      6,S       discard the arguments
                    tfr       D,U       move record pointer to u
                    tfr       U,D       copy it back to d
                    std       <InputPtr save the symbol record pointer
SetSymbolType       ldb       1,U       load the symbol flags
                    clra                clear the high byte
                    andb      #128      test the defined bit
                    bne       CheckSectionType already defined
                    ldb       ,U        load the symbol type byte
                    sex                 sign-extend to d
                    andb      #248      mask off the low bits
                    pshs      D         save it
                    ldb       <TypeFlags load the current type
                    sex                 sign-extend to d
                    ora       ,S+       combine the high byte
                    orb       ,S+       combine the low byte
                    stb       ,U        store the symbol type
                    ldb       1,U       load the symbol flags
                    sex                 sign-extend to d
                    pshs      D         save it
                    ldb       <LabelFlags load the label flags
                    sex                 sign-extend to d
                    ora       ,S+       combine the high byte
                    orb       ,S+       combine the low byte
                    stb       1,U       store the symbol flags
                    ldd       <RelocPtr load the current value pointer
                    beq       CountUndefined none, skip the value
                    ldd       [>RelocPtr,Y] load the current value
                    std       2,U       store as the symbol value
                    bra       CountUndefined continue

CheckSectionType    ldb       ,U        load the symbol type byte
                    clra                clear the high byte
                    andb      #7        mask the section bits
                    cmpd      #5        compare with section five
                    beq       CountUndefined matches, skip
                    ldb       1,U       load the symbol flags
                    sex                 sign-extend to d
                    orb       #64       set the redefinition flag
                    stb       1,U       store the symbol flags
CountUndefined      ldb       1,U       load the symbol flags
                    clra                clear the high byte
                    andb      #198      mask the relevant bits
                    cmpd      #134      test the undefined pattern
                    lbne      LabelDone2 no match, return
                    ldd       <UndefCount load the undefined count
                    addd      #1        increment it
                    std       <UndefCount save it
                    lbra      LabelDone2 return

LabelPass2          ldd       ,S        load the lookup result
                    bne       PrintSymbolLost found, treat as redefinition
                    ldb       1,U       load the symbol flags
                    clra                clear the high byte
                    andb      #128      test the defined bit
                    bne       ClearDefinedFlag already defined
PrintSymbolLost     leax      >MsgSymbolLost,PC point to the message text
                    pshs      X         push the message pointer
                    lbsr      FatalError print the warning
                    leas      2,S       discard the argument
ClearDefinedFlag    ldb       1,U       load the symbol flags
                    sex                 sign-extend to d
                    andb      #239      clear a flag bit
                    stb       1,U       store the symbol flags
                    clra                clear the high byte
                    andb      #64       test the redefinition flag
                    beq       CheckPhaseError not redefined
                    leax      >MsgRedefined,PC point to the message text
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine print the error
                    leas      2,S       discard the argument
                    bra       LabelDone2 return

CheckPhaseError     ldd       <RelocPtr load the current value pointer
                    beq       LabelDone2 none, return
                    ldb       ,U        load the symbol type
                    clra                clear the high byte
                    andb      #7        mask the section bits
                    pshs      D         save it
                    ldb       <SectType load the current section
                    sex                 sign-extend to d
                    cmpd      ,S++      compare the sections
                    bne       LabelDone2 differ, return
                    ldd       2,U       load the symbol value
                    cmpd      [>RelocPtr,Y] compare with the current value
                    beq       LabelDone2 unchanged, return
                    lbsr      PhaseError report the phase error
                    ldd       [>RelocPtr,Y] load the current value
                    std       2,U       update the symbol value
LabelDone2          ldd       #1        return value one
                    puls      PC,U,X    restore and return

DefineSymbol        pshs      U,X,D     save registers and a local
                    leax      >InputPtr,Y point to the symbol pointer
                    pshs      X         push it
                    leax      >SymNameBuf,Y point to the operand name
                    pshs      X         push it
                    lbsr      LookupName look up or enter the symbol
                    leas      4,S       discard the arguments
                    std       ,S        save the lookup result
                    ldu       <InputPtr load the symbol record pointer
                    ldd       ,S        load the lookup result
                    beq       PatchForwardRefs new symbol
                    ldb       <PassFlag load the pass flag
                    bne       PrintNewInPass2 second pass, redefinition
                    ldd       ,S        load the result
                    pshs      D         push it
                    leax      >InputPtr,Y point to the symbol pointer
                    pshs      X         push it
                    leax      >SymNameBuf,Y point to the operand name
                    pshs      X         push it
                    lbsr      AllocTreeNode enter the new symbol
                    leas      6,S       discard the arguments
                    std       <InputPtr save the symbol pointer
                    tfr       D,U       move record pointer to u
                    bra       PatchForwardRefs continue

PrintNewInPass2     leax      >MsgNewSymPass2,PC point to the message text
                    pshs      X         push the message pointer
                    lbsr      FatalError print the warning
                    leas      2,S       discard the argument
PatchForwardRefs    ldb       1,U       load the symbol flags
                    sex                 sign-extend to d
                    eorb      #128      toggle the defined bit
                    clra                clear the high byte
                    andb      #160      test the relevant bits
                    lbeq      CheckReferenced none set
                    ldd       #1        load one
                    std       <RelocFlags set the relocation flags
                    ldb       <PassFlag load the pass flag
                    beq       MarkReferenced first pass
                    ldb       1,U       load the symbol flags
                    clra                clear the high byte
                    andb      #128      test the defined bit
                    beq       MarkReferenced undefined
                    ldb       ,U        load the symbol type
                    clra                clear the high byte
                    andb      #7        mask the section bits
                    cmpd      #6        compare with section six
                    beq       LoadRefChain matches
                    ldb       ,U        load the symbol type
                    clra                clear the high byte
                    andb      #7        mask the section bits
                    cmpd      #5        compare with section five
                    bne       MarkReferenced no match
LoadRefChain        ldd       8,U       load the reference chain head
                    bra       RefChainNext enter the chain loop

PatchRefLoop        ldb       [<2,S]    load byte via the chain pointer
                    stb       [>ListEnd,Y] store at the output pointer
                    ldx       2,S       load the chain pointer
                    ldd       1,X       load the next chain link
                    ldx       >ListEnd,Y load the output pointer
                    std       1,X       store the link
                    pshs      D         push it
                    lbsr      SetSectionDir process the reference
                    leas      2,S       discard the argument
                    ldd       >ListEnd,Y load the output pointer
                    addd      #3        advance past the record
                    std       >ListEnd,Y save the output pointer
                    ldx       2,S       load the chain pointer
                    ldd       3,X       load the next chain entry
RefChainNext        std       2,S       save the chain pointer
                    ldd       2,S       load the chain pointer
                    bne       PatchRefLoop more references to patch
                    bra       SymbolDone done with the chain

MarkReferenced      ldb       <PassFlag load the pass flag
                    bne       EmitSymRecord second pass
                    ldb       1,U       load the symbol flags
                    sex                 sign-extend to d
                    orb       #16       set the referenced flag
                    stb       1,U       store the symbol flags
EmitSymRecord       clra                zero value
                    clrb                zero value
                    stb       [>ListEnd,Y] clear the output byte
                    ldx       >ListEnd,Y load the output pointer
                    stu       1,X       store the symbol record pointer
                    ldd       >ListEnd,Y load the output pointer
                    addd      #3        advance past the record
                    std       >ListEnd,Y save the output pointer
                    bra       EmitSymValue continue

CheckReferenced     ldb       <PassFlag load the pass flag
                    beq       SymbolDone first pass, skip
                    ldb       1,U       load the symbol flags
                    clra                clear the high byte
                    andb      #16       test the referenced flag
                    beq       SymbolDone not referenced, skip
EmitSymValue        pshs      U         push the symbol record pointer
                    bsr       SetSectionDir process the reference
                    leas      2,S       discard the argument
SymbolDone          ldd       2,U       load the symbol value
                    std       <OperandVal save it
                    ldd       #1        return value one
                    lbra      ResolveSymDone return

SetSectionDir       pshs      U         save the caller u register
                    ldu       4,S       load the symbol record pointer
                    ldd       <OffsetFlag load the section direction
                    bne       SectionDirDone already set
                    ldb       ,U        load the symbol type
                    clra                clear the high byte
                    andb      #6        mask the type bits
                    cmpd      #2        compare with two
                    bne       NegDirection not that type
                    ldd       #1        positive direction
                    bra       StoreDirection store it

NegDirection        ldd       #-1       negative direction
StoreDirection      std       <OffsetFlag save the section direction
SectionDirDone      puls      PC,U      restore and return

MergeSymFlags       pshs      U         save the caller u register
                    ldx       <InputPtr point to current symbol
                    ldb       1,X       load symbol flags byte
                    clra                clear high byte
                    andb      #64       test defined bit
                    bne       MergeFlagsDone already defined, done
                    ldb       5,S       load caller type argument
                    cmpb      #5        compare against type five
                    beq       MergeFlagsMatched merge flags if matched
                    ldb       [>InputPtr,Y] load symbol type byte
                    clra                clear high byte
                    andb      #7        isolate type field
                    cmpd      #5        compare type to five
                    bne       MergeFlagsMatched not type five, merge flags
                    ldx       <InputPtr point to symbol again
                    ldb       1,X       load flags byte
                    sex                 sign extend to word
                    orb       #64       set defined bit
                    stb       1,X       store updated flags
                    bra       MergeFlagsDone done

MergeFlagsMatched   ldb       [>InputPtr,Y] load symbol type byte
                    sex                 sign extend
                    andb      #248      clear low three bits
                    pshs      D         save cleared type
                    ldb       7,S       load caller type argument
                    sex                 sign extend
                    ora       ,S+       merge high byte
                    orb       ,S+       merge low byte
                    stb       [>InputPtr,Y] store combined type byte
MergeFlagsDone      puls      PC,U      return

ResolveSym          pshs      U,X,D     save registers
                    ldu       <InputPtr point to current symbol
                    leax      >ListStart,Y address symbol table base
                    cmpx      >ListEnd,Y compare against stack pointer
                    bne       SymNotEmpty not empty, branch
                    ldb       ,U        load symbol type byte
                    clra                clear high byte
                    andb      #4        test external bit
                    beq       CheckSymValue not external, continue
                    ldb       1,U       load flags byte
                    clra                clear high byte
                    andb      #32       test referenced bit
                    beq       CheckSymValue not referenced, continue
                    ldb       1,U       load flags byte
                    sex                 sign extend
                    andb      #223      clear referenced bit
                    stb       1,U       store updated flags
                    lbra      StoreSymValue finish up

CheckSymValue       ldb       <PassFlag load pass number
                    lble      StoreSymValue pass one, finish
                    ldd       8,S       load caller value
                    cmpd      2,U       compare to symbol value
                    lbeq      StoreSymValue unchanged, finish
                    ldb       1,U       load flags byte
                    clra                clear high byte
                    andb      #64       test defined bit
                    lbne      StoreSymValue already defined, finish
                    ldb       ,U        load type byte
                    clra                clear high byte
                    andb      #7        isolate type field
                    cmpd      #5        compare type to five
                    lbeq      StoreSymValue type five, finish
                    lbra      DoPhaseErr report phasing error

SymNotEmpty         ldb       <PassFlag load pass number
                    bne       HandleType6 pass two, branch
                    ldb       ,U        load type byte
                    clra                clear high byte
                    andb      #7        isolate type field
                    cmpd      #6        compare type to six
                    lbne      StoreSymValue not type six, finish
                    ldb       1,U       load flags byte
                    sex                 sign extend
                    orb       #32       set referenced bit
                    stb       1,U       store updated flags
                    bra       EmitFixupTest scan symbol stack

EmitFixupLoop       ldd       >ListEnd,Y load stack pointer
                    addd      #-3       back up one entry
                    std       >ListEnd,Y update stack pointer
                    ldx       >ListEnd,Y point to entry
                    ldd       1,X       load entry value
                    pshs      D         push as argument
                    ldb       [>ListEnd,Y] load entry type byte
                    sex                 sign extend
                    pshs      D         push as argument
                    pshs      U         push symbol pointer
                    lbsr      AppendFixup append fixup record
                    leas      6,S       drop arguments
EmitFixupTest       leax      >ListStart,Y address table base
                    cmpx      >ListEnd,Y compare with stack pointer
                    bcs       EmitFixupLoop more entries, loop
                    lbra      StoreSymValue finish up

HandleType6         ldb       ,U        load type byte
                    clra                clear high byte
                    andb      #7        isolate type field
                    cmpd      #6        compare type to six
                    lbne      PatchErr  not type six, error
                    ldd       8,U       load chain head
                    std       ,S        save into local
                    ldd       >ListEnd,Y load stack pointer
                    std       2,S       save into local
                    bra       ScanChainTest enter scan loop

ScanChainLoop       ldd       2,S       load scan pointer
                    addd      #-3       back up one entry
                    std       2,S       update scan pointer
                    ldx       ,S        load chain node
                    ldd       1,X       load node value
                    ldx       2,S       point to entry
                    cmpd      1,X       compare values
                    bne       CheckResolved mismatch, exit scan
                    ldx       ,S        load chain node
                    ldd       3,X       load next link
                    std       ,S        advance chain
ScanChainTest       ldd       ,S        load chain node
                    beq       CheckResolved end of chain, exit
                    leax      >ListStart,Y address table base
                    cmpx      2,S       compare with scan pointer
                    bcs       ScanChainLoop more to scan, loop
CheckResolved       ldd       ,S        load chain node
                    bne       DoPhaseErr not resolved, phasing error
                    leax      >ListStart,Y address table base
                    cmpx      2,S       compare with scan pointer
                    bne       DoPhaseErr mismatch, phasing error
                    ldd       2,U       load symbol value
                    cmpd      8,S       compare to caller value
                    beq       PatchForward unchanged, resolve
DoPhaseErr          bsr       PhaseError report phasing error
                    bra       StoreSymValue finish up

PatchForward        ldb       1,U       load flags byte
                    clra                clear high byte
                    andb      #4        test forward bit
                    beq       StoreSymValue not set, finish
                    ldd       8,U       load chain head
                    bra       PatchStore enter patch loop

PatchLoop           ldx       ,S        load chain node
                    ldx       1,X       follow to record
                    ldb       1,X       load record flags
                    clra                clear high byte
                    andb      #66       test flag bits
                    bne       PatchNext set, skip patch
                    lbsr      ExtRefErr patch the record
PatchNext           ldx       ,S        load chain node
                    ldd       3,X       load next link
PatchStore          std       ,S        store chain node
                    ldd       ,S        reload chain node
                    bne       PatchLoop more nodes, loop
                    bra       StoreSymValue finish up

PatchErr            lbsr      ExtRefErr report error
StoreSymValue       ldd       8,S       load caller value
                    std       2,U       store into symbol
ResolveSymDone      leas      4,S       drop locals
                    puls      PC,U      return

PhaseError          pshs      U         save the caller u register
                    leax      >MsgPhasingErr,PC point to phasing message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return

AppendFixup         pshs      U         save the caller u register
                    ldd       #5        request five bytes
                    pshs      D         push size argument
                    lbsr      AllocMem  allocate record
                    leas      2,S       drop size argument
                    tfr       D,U       point to new record
                    ldd       6,S       load type argument
                    stb       ,U        store type byte
                    ldd       8,S       load value argument
                    std       1,U       store value word
                    ldx       4,S       load symbol pointer
                    ldd       8,X       load existing chain head
                    std       3,U       link into record
                    ldx       4,S       load symbol pointer
                    stu       8,X       set new chain head
                    puls      PC,U      return

SkipSpaces          ldx       <SrcPtr   load input pointer
SkipSpaceLoop       ldb       ,X+       fetch next character
                    cmpb      #32       is it a space
                    beq       SkipSpaceLoop yes, skip it
                    sex                 sign extend
                    leax      -1,X      back up over character
                    stx       <SrcPtr   save input pointer
                    rts                 return
FindListTail        pshs      U         save the caller u register
                    ldx       4,S       load argument pointer
                    ldu       6,X       load list head
                    ldx       4,S       load argument pointer
                    ldb       1,X       load flags byte
                    clra                clear high byte
                    andb      #8        test list bit
                    beq       FindTailDone not a list, return head
                    bra       FindTailTest enter walk loop

FindTailLoop        ldu       4,U       follow to next node
FindTailTest        ldd       4,U       load next link
                    bne       FindTailLoop more nodes, loop
FindTailDone        tfr       U,D       return tail pointer
                    puls      PC,U      return

AllocTreeNode       pshs      U,D       save registers
                    ldd       >FreeNode,Y load free list head
                    beq       AllocNodeFresh empty, allocate fresh
                    ldu       >FreeNode,Y point to free node
                    ldx       >FreeNode,Y point to free node
                    ldd       4,X       load next free link
                    std       >FreeNode,Y pop from free list
                    clra                clear high byte
                    clrb                clear low byte
                    std       2,U       clear node value
                    stb       1,U       clear flags byte
                    stb       ,U        clear type byte
                    clra                clear high byte
                    clrb                clear low byte
                    std       8,U       clear chain field
                    std       4,U       clear link field
                    bra       LinkTreeNode continue init

AllocNodeFresh      ldd       #20       request twenty bytes
                    pshs      D         push size argument
                    lbsr      AllocMem  allocate node
                    leas      2,S       drop size argument
                    tfr       D,U       point to new node
LinkTreeNode        ldd       [<8,S]    load caller pointer
                    std       ,S        save into local
                    beq       SetTreeRoot null, insert at root
                    ldd       10,S      load comparison result
                    bge       LinkRightChild non-negative, go right
                    ldd       ,S        load parent node
                    std       6,U       set node parent
                    ldx       ,S        load parent node
                    stu       4,X       link as left child
                    bra       CopyNodeName finish insertion

LinkRightChild      ldx       ,S        load parent node
                    ldd       6,X       load parent right link
                    std       6,U       set node right
                    ldx       ,S        load parent node
                    stu       6,X       link as right child
                    ldx       ,S        load parent node
                    ldb       1,X       load parent flags
                    sex                 sign extend
                    orb       #8        set list bit
                    stb       1,X       store parent flags
                    bra       CopyNodeName finish insertion

SetTreeRoot         stu       [>TreeRoot,Y] store as tree root
                    clra                clear high byte
                    clrb                clear low byte
                    std       6,U       clear right link
CopyNodeName        ldd       6,S       load name argument
                    pshs      D         push name pointer
                    pshs      U         push node pointer
                    ldd       #10       offset to name field
                    addd      ,S++      add to node pointer
                    pshs      D         push destination
                    lbsr      strcpy    copy name string
                    leas      4,S       drop arguments
                    tfr       U,D       return node pointer
                    puls      PC,U,X    return

LookupName          pshs      U,D       save registers
                    ldd       #1        initial hash value
                    std       ,S        save hash accumulator
                    leas      -2,S      reserve local
                    ldu       8,S       point to name string
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,S        clear index
HashLoop            ldd       ,S        load hash accumulator
                    pshs      D         save accumulator
                    ldb       ,U        load name character
                    sex                 sign extend
                    addd      ,S++      add into accumulator
                    std       ,S        store accumulator
                    leau      1,U       advance name pointer
                    ldb       ,U        load next character
                    bne       HashLoop  more characters, loop
                    ldd       ,S        load hash accumulator
                    clra                clear high byte
                    andb      #63       mask to table size
                    aslb                multiply by two
                    rola                extend into high byte
                    addd      <CurPtr   add table base
                    std       >TreeRoot,Y save bucket pointer
                    leas      2,S       drop local
                    ldd       [>TreeRoot,Y] load bucket root
                    std       [<8,S]    store into caller
                    tfr       D,U       point to node
                    stu       -2,S      save node pointer
                    beq       LookupDone empty bucket, return
SearchLoop          stu       [<8,S]    store node into caller
                    pshs      U         push node pointer
                    ldd       #10       offset to name field
                    addd      ,S++      add to node pointer
                    pshs      D         push node name
                    ldd       8,S       load search name
                    pshs      D         push search name
                    lbsr      strcmp    compare the names
                    leas      4,S       drop arguments
                    std       ,S        save comparison result
                    bge       SearchRight non-negative, go right
                    ldu       4,U       follow left link
                    bra       SearchNext test next node

SearchRight         ldd       ,S        load comparison result
                    ble       LookupDone equal, found it
                    ldb       1,U       load node flags
                    clra                clear high byte
                    andb      #8        test list bit
                    beq       LookupDone no right child, return
                    ldu       6,U       follow right link
                    bra       SearchNext test next node

SearchNext          stu       -2,S      save node pointer
                    bne       SearchLoop not null, keep searching
LookupDone          ldd       ,S        load comparison result
                    puls      PC,U,X    return

AllocMem            pshs      U,D       save registers
                    ldd       6,S       load size argument
                    pshs      D         push size
                    lbsr      Sbrk      allocate memory
                    leas      2,S       drop size
                    std       ,S        save returned pointer
                    cmpd      #-1       did allocation fail
                    beq       OverflowErr yes, report overflow
                    ldd       ,S        load returned pointer
                    bra       AllocDone return pointer

OverflowErr         leax      >MsgSymTabOvf,PC point to overflow message
                    pshs      X         push message pointer
                    lbsr      FatalError report fatal error
                    leas      2,S       drop argument
AllocDone           puls      PC,U,X    return

MsgSymbolLost       fcc       "symbol lost!?"
                    fcb       C$NULL
MsgRedefined        fcc       "redefined name"
                    fcb       C$NULL
MsgNewSymPass2      fcc       "new symbol in pass two"
                    fcb       C$NULL
MsgPhasingErr       fcc       "phasing error"
                    fcb       C$NULL
MsgSymTabOvf        fcc       "symbol table overflow"
                    fcb       C$NULL
ParseValue          pshs      U         save the caller u register
                    ldd       #-68      request stack space for locals
                    lbsr      stkcheck  check stack space
                    lbsr      EvalLineExpr parse the expression
                    std       -2,S      save result
                    beq       RetZero   nothing parsed, return zero
                    lbsr      CompactModeList process the symbol
                    lbsr      ResolveOffsetExpr emit the value
                    ldb       <ModeFlags load status flags
                    sex                 sign extend
                    andb      #127      clear high bit
                    bra       StoreStatusFlags store and return

ParseReloc          pshs      U         save the caller u register
                    ldd       #-70      request stack space for locals
                    lbsr      stkcheck  check stack space
                    bsr       EvalLineExpr parse the expression
                    std       -2,S      save result
                    bne       EmitReloc parsed, continue
RetZero             clra                clear high byte
                    clrb                clear low byte
                    puls      PC,U      return zero

EmitReloc           ldb       <ModeFlags load status flags
                    sex                 sign extend
                    orb       #8        set relocatable bit
                    stb       <ModeFlags store status flags
                    lbsr      CompactModeList process the symbol
                    leax      >ListStart,Y address table base
                    cmpx      >ListEnd,Y compare with stack pointer
                    bcc       CheckByteRange empty stack, range check
                    lbsr      ResolveOffsetExpr emit the value
                    bra       ClearRelocFlag2 clear flags and return

CheckByteRange      ldd       <OperandVal load computed value
                    cmpd      #256      compare to upper limit
                    bge       RangeErr  too large, error
                    ldd       <OperandVal load computed value
                    cmpd      #-256     compare to lower limit
                    bge       ClearRelocFlag2 in range, return
RangeErr            leax      >MsgValueOutOfRange,PC point to error message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    puls      PC,U,X    return

ClearRelocFlag2     ldb       <ModeFlags load status flags
                    sex                 sign extend
                    andb      #119      clear relocatable bits
StoreStatusFlags    stb       <ModeFlags store status flags
                    ldd       #1        return success
                    puls      PC,U      return

EvalLineExpr        pshs      U         save the caller u register
                    ldd       #-68      request stack space for locals
                    lbsr      stkcheck  check stack space
                    lbsr      SkipSpaces skip leading spaces
                    leax      >ListStart,Y address table base
                    stx       >ListEnd,Y reset symbol stack
                    bsr       EvalAddSub evaluate expression
                    puls      PC,U      return

EvalConstTerm       pshs      U         save the caller u register
                    ldd       #-68      request stack space for locals
                    lbsr      stkcheck  check stack space
                    lbsr      ExtRefErr evaluate the term
                    std       <OperandVal save computed value
                    std       <RelocFlags save relocation flags
                    puls      PC,U      return

EvalAddSub          pshs      U         save the caller u register
                    ldd       #-77      request stack space for locals
                    lbsr      stkcheck  check stack space
                    leas      -7,S      reserve locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       <RelocFlags clear relocation flags
                    lbsr      ParseMulDiv evaluate first operand
                    std       -2,S      save operand result
                    beq       EvalFail  failed, return zero
                    lbra      NextOperator process operator

EvalOperLoop        ldx       <SrcPtr   load input pointer
                    leax      1,X       advance past operator
                    stx       <SrcPtr   save input pointer
                    ldb       -1,X      load operator character
                    stb       ,S        save operator
                    ldd       <OperandVal load current value
                    std       3,S       save into local
                    ldd       >ListEnd,Y load stack pointer
                    std       5,S       save into local
                    ldd       <RelocFlags load relocation flags
                    std       1,S       save into local
                    clra                clear high byte
                    clrb                clear low byte
                    std       <RelocFlags clear relocation flags
                    lbsr      ParseMulDiv evaluate next operand
                    std       -2,S      save operand result
                    bne       CombineTerms success, combine terms
EvalFail            clra                clear high byte
                    clrb                clear low byte
                    lbra      TermScanDone return zero

CombineTerms        ldd       <RelocFlags load relocation flags
                    ora       1,S       merge saved high byte
                    orb       2,S       merge saved low byte
                    std       <RelocFlags store relocation flags
                    ldb       ,S        load operator character
                    cmpb      #'+       is it a plus
                    bne       HandleMinus no, handle minus
                    ldd       3,S       load saved value
                    addd      <OperandVal add operand value
                    std       <OperandVal store sum
                    bra       NextOperator check for more operators

HandleMinus         ldd       3,S       load saved value
                    subd      <OperandVal subtract operand value
                    std       <OperandVal store difference
                    bra       NegateRelocTest negate operand relocations

NegateRelocLoop     ldx       5,S       load saved stack pointer
                    leax      3,X       advance one entry
                    stx       5,S       update pointer
                    ldb       -3,X      load entry type byte
                    sex                 sign extend
                    eorb      #64       flip subtraction bit
                    stb       -3,X      store entry type byte
NegateRelocTest     ldd       5,S       load saved stack pointer
                    cmpd      >ListEnd,Y compare with current
                    bcs       NegateRelocLoop more entries, loop
NextOperator        ldb       [>SrcPtr,Y] load current character
                    cmpb      #'+       is it a plus sign
                    lbeq      EvalOperLoop branch if plus operator
                    ldb       [>SrcPtr,Y] reload current input char
                    cmpb      #'-       is it a minus sign
                    lbeq      EvalOperLoop branch if minus operator
                    ldb       [>SrcPtr,Y] reload current input char
                    sex                 sign extend char to sixteen bits
                    tfr       D,X       move char into index register
                    bra       CheckTerminator go check for terminator

BadOperatorErr      leax      >MsgBadOperator,PC point to bad operator message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    bra       TermScanDone return from term scan

CheckTerminator     cmpx      #32       is char a space
                    beq       TermValid accept as terminator
                    stx       -2,S      save char and set flags
                    beq       TermValid accept if end of line
                    cmpx      #44       is char a comma
                    beq       TermValid accept as terminator
                    cmpx      #41       is char a close paren
                    beq       TermValid accept as terminator
                    cmpx      #93       is char a close bracket
                    beq       TermValid accept as terminator
                    bra       BadOperatorErr otherwise report bad operator

TermValid           ldd       #1        return success flag
TermScanDone        leas      7,S       discard local frame
                    puls      PC,U      return

ParseMulDiv         pshs      U         save the caller u register
                    ldd       #-73      stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -3,S      allocate locals
                    lbsr      ParseAndOr parse higher precedence operand
                    std       -2,S      save result flag
                    lbeq      ReturnZero bail on parse failure
                    bra       MulDivNext check for mul or div operator

MulDivLoop          ldx       <SrcPtr   get input pointer
                    leax      1,X       advance past the operator
                    stx       <SrcPtr   save input pointer
                    ldb       -1,X      get the operator char
                    stb       ,S        save operator
                    ldd       <OperandVal get left operand value
                    std       1,S       save left operand
                    bsr       ParseAndOr parse the right operand
                    std       -2,S      save result flag
                    lbeq      ReturnZero bail on parse failure
                    ldd       <RelocFlags check relocation flag
                    beq       DoMulDiv  plain constant path
                    lbsr      EvalConstTerm emit relocatable operation
                    bra       MulDivNext continue scanning

DoMulDiv            ldb       ,S        get operator
                    cmpb      #42       is it multiply
                    bne       CheckDivZero no, try divide
                    ldd       1,S       get left operand
                    pshs      D         push multiplicand
                    ldd       <OperandVal get right operand
                    lbsr      MulEntry  multiply operands
                    bra       StoreMulDiv store the product

CheckDivZero        ldd       <OperandVal get the divisor
                    bne       DoDivide  nonzero, do divide
                    leax      >MsgZeroDivision,PC point to zero division message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    bra       MulDivNext continue scanning

DoDivide            ldd       1,S       get the dividend
                    pshs      D         push dividend
                    ldd       <OperandVal get the divisor
                    lbsr      UDivEntry divide operands
StoreMulDiv         std       <OperandVal store the result
MulDivNext          ldb       [>SrcPtr,Y] get current char
                    cmpb      #42       is it multiply
                    beq       MulDivLoop loop for another factor
                    ldb       [>SrcPtr,Y] reload current char
                    cmpb      #47       is it divide
                    lbeq      MulDivLoop loop for another factor
                    lbra      AddSubOk  done, return success

ParseAndOr          pshs      U         save the caller u register
                    ldd       #-71      stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -3,S      allocate locals
                    lbsr      ParseAddSub parse higher precedence operand
                    std       -2,S      save result flag
                    lbeq      ReturnZero bail on parse failure
                    bra       AndOrNext check for and or or operator

AndOrLoop           ldx       <SrcPtr   get input pointer
                    leax      1,X       advance past the operator
                    stx       <SrcPtr   save input pointer
                    ldb       -1,X      get operator char
                    stb       ,S        save operator
                    ldd       <OperandVal get left operand
                    std       1,S       save left operand
                    bsr       ParseAddSub parse the right operand
                    std       -2,S      save result flag
                    lbeq      ReturnZero bail on parse failure
                    ldd       <RelocFlags check relocation flag
                    beq       DoAndOr   plain constant path
                    lbsr      EvalConstTerm emit relocatable operation
                    bra       AndOrNext continue scanning

DoAndOr             ldb       ,S        get operator
                    cmpb      #38       is it and
                    bne       DoOr      no, do or
                    ldd       1,S       get left operand
                    anda      <OperandVal and the high byte
                    andb      <U0032    and the low byte
                    bra       StoreAndOr store the result

DoOr                ldd       1,S       get left operand
                    ora       <OperandVal or the high byte
                    orb       <U0032    or the low byte
StoreAndOr          std       <OperandVal store the result
AndOrNext           ldb       [>SrcPtr,Y] get current char
                    cmpb      #38       is it and
                    beq       AndOrLoop loop for another operand
                    ldb       [>SrcPtr,Y] reload current char
                    cmpb      #33       is it or
                    lbeq      AndOrLoop loop for another operand
                    lbra      AddSubOk  done, return success

ParseAddSub         pshs      U         save the caller u register
                    ldd       #-71      stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -3,S      allocate locals
                    ldb       [>SrcPtr,Y] get current char
                    stb       ,S        save it
                    cmpb      #'+       is it plus
                    beq       ParseSignedTerm handle unary sign
                    ldb       ,S        reload char
                    cmpb      #'-       is it minus
                    beq       ParseSignedTerm handle unary sign
                    ldb       ,S        reload char
                    cmpb      #94       is it complement
                    lbne      ParseOperand none, parse the operand
ParseSignedTerm     ldd       <SrcPtr   get input pointer
                    addd      #1        advance past the sign
                    std       <SrcPtr   save input pointer
                    ldd       >ListEnd,Y get reloc list pointer
                    std       1,S       save list pointer
                    bsr       ParseAddSub parse the signed term
                    std       -2,S      save result flag
                    bne       CheckMinusOp proceed if valid
ReturnZero          clra                clear high byte
                    clrb                clear low byte, result zero
                    bra       AddSubDone return failure

CheckMinusOp        ldb       ,S        get sign char
                    cmpb      #'-       is it minus
                    bne       CheckComplement no, try complement
                    ldd       <OperandVal get the value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        propagate borrow to negate value
                    std       <OperandVal store negated value
                    bra       NegateRelocCheck adjust reloc entries

NegateRelocLoop2    ldx       1,S       get reloc list pointer
                    leax      3,X       advance to next entry
                    stx       1,S       save pointer
                    ldb       -3,X      get entry sign flag
                    sex                 sign extend
                    eorb      #64       flip the sign bit
                    stb       -3,X      store flag back
NegateRelocCheck    ldd       1,S       get current pointer
                    cmpd      >ListEnd,Y reached list end
                    bcs       NegateRelocLoop2 loop over entries
                    bra       AddSubOk  done

CheckComplement     ldb       ,S        get sign char
                    cmpb      #94       is it complement
                    bne       AddSubOk  no, done
                    ldd       <RelocFlags check relocation flag
                    beq       DoComplement plain constant path
                    lbsr      EvalConstTerm emit relocatable operation
                    bra       AddSubOk  done

DoComplement        ldd       <OperandVal get the value
                    coma                complement high byte
                    comb                complement low byte
                    std       <OperandVal store the result
AddSubOk            ldd       #1        return success flag
                    bra       AddSubDone return

ParseOperand        bsr       ParsePrimary parse the operand
AddSubDone          leas      3,S       discard locals
                    puls      PC,U      return

ParsePrimary        pshs      U         save the caller u register
                    ldd       #-72      stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -2,S      allocate locals
                    ldb       [>SrcPtr,Y] get current char
                    sex                 sign extend
                    tfr       D,X       move char into index register
                    lbra      PrimaryDispatch dispatch on the char

ParseParen          ldd       <RelocFlags get reloc flag
                    std       ,S        save it
                    ldd       <SrcPtr   get input pointer
                    addd      #1        advance past open paren
                    std       <SrcPtr   save input pointer
                    lbsr      EvalAddSub parse the subexpression
                    std       -2,S      save result flag
                    beq       ParenErrExit bail on parse failure
                    ldb       [>SrcPtr,Y] get current char
                    cmpb      #')       is it close paren
                    bne       ParenMissingErr missing paren error
                    ldd       <RelocFlags get reloc flag
                    ora       ,S        or high byte with saved
                    orb       1,S       or low byte with saved
                    bra       SetRelocFlag set reloc flag and advance

ParenMissingErr     leax      >MsgParenMissing,PC point to parenthesis missing message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
ParenErrExit        clra                clear high byte
                    clrb                clear low byte, result zero
                    puls      PC,U,X    return failure

ParseLocation       ldd       <RelocPtr get symbol pointer
                    bne       EmitLocRef resolved, emit reference
                    ldd       <FieldPtr get org value
                    bne       UseOrgValue use the org value
                    leax      >MsgUndefinedOrg,PC point to undefined org message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    std       <OperandVal store zero value
                    puls      PC,U,X    return

UseOrgValue         ldd       [>FieldPtr,Y] get org value
                    std       <OperandVal store as value
                    bra       AdvanceChar advance past the star

EmitLocRef          ldd       [>RelocPtr,Y] get current location
                    std       <OperandVal store as value
                    ldb       <TypeFlags get relocation type
                    stb       [>ListEnd,Y] store into reloc list
                    ldd       <BufPtr   get current org
                    ldx       >ListEnd,Y get list pointer
                    std       1,X       store org into entry
                    ldd       >ListEnd,Y get list pointer
                    addd      #3        advance to next entry
                    std       >ListEnd,Y save list pointer
                    ldd       #1        set reloc flag value
SetRelocFlag        std       <RelocFlags set the relocation flag
                    bra       AdvanceChar advance past the star

ParseCharLit        ldx       <SrcPtr   get input pointer
                    leax      1,X       advance past the quote
                    stx       <SrcPtr   save input pointer
                    ldb       ,X        get the quoted char
                    sex                 sign extend
                    std       <OperandVal store char value
                    bne       AdvanceChar advance if nonzero
                    clra                clear high byte
                    clrb                clear low byte, result zero
                    puls      PC,U,X    return failure

AdvanceChar         ldd       <SrcPtr   get input pointer
                    addd      #1        advance past the char
                    std       <SrcPtr   save input pointer
                    bra       PrimaryDone return success

ParseNumOrSym       bsr       ParseNumber parse a number
                    std       -2,S      save result flag
                    bne       PrimaryDone return if parsed
                    leax      >SymNameBuf,Y point to symbol name buffer
                    pshs      X         push buffer pointer
                    lbsr      ScanName  look up the symbol
                    std       ,S++      save symbol pointer
                    beq       BadOperandErr undefined operand error
                    lbsr      DefineSymbol fetch the symbol value
                    bra       PrimaryDone return success

BadOperandErr       leax      >MsgBadOperand,PC point to bad operand message
                    pshs      X         push message pointer
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    std       <OperandVal store zero value
                    puls      PC,U,X    return

                    bra       PrimaryDone return success

PrimaryDispatch     cmpx      #40       is char open paren
                    lbeq      ParseParen parse parenthesized expression
                    cmpx      #42       is char a star
                    lbeq      ParseLocation parse location counter
                    cmpx      #39       is char a quote
                    beq       ParseCharLit parse char literal
                    bra       ParseNumOrSym parse number or symbol

PrimaryDone         ldd       #1        return success flag
                    puls      PC,U,X    return

ParseNumber         pshs      U         save the caller u register
                    ldd       #-72      stack check size
                    lbsr      stkcheck  verify stack space
                    leas      -6,S      allocate locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       4,S       clear the radix
                    clra                clear high byte
                    clrb                clear low byte
                    std       2,S       clear digit count
                    ldd       #8        default digit class flag
                    stb       1,S       save digit class flag
                    ldb       [>SrcPtr,Y] get current char
                    stb       ,S        save it
                    sex                 sign extend
                    tfr       D,X       move char into index register
                    bra       NumberBaseDispatch dispatch on base prefix

SetBinaryBase       ldx       <SrcPtr   get input pointer
                    leax      1,X       advance past percent
                    stx       <SrcPtr   save input pointer
                    ldb       ,X        get next char
                    stb       ,S        save it
                    ldd       #2        binary radix
                    std       4,S       set the radix
                    ldd       #16       binary digit class flag
                    bra       StoreBaseFlag store the base flag

SetHexBase          ldx       <SrcPtr   get input pointer
                    leax      1,X       advance past dollar
                    stx       <SrcPtr   save input pointer
                    ldb       ,X        get next char
                    stb       ,S        save it
                    ldd       #16       hex radix
                    std       4,S       set the radix
                    ldd       #32       hex digit class flag
StoreBaseFlag       stb       1,S       save digit class flag
                    bra       CheckRadixSet check radix set

CheckDecimalDigit   ldb       ,S        get current char
                    sex                 sign extend
                    leax      >CharClassTbl,Y point to char class table
                    leax      D,X       index by char
                    ldb       ,X        get class flags
                    clra                clear high byte
                    andb      #8        is it a decimal digit
                    beq       CheckRadixSet not a digit, no radix
                    ldd       #10       decimal radix
                    std       4,S       set the radix
                    bra       CheckRadixSet check radix set

NumberBaseDispatch  cmpx      #37       is char percent
                    beq       SetBinaryBase binary prefix
                    cmpx      #36       is char dollar
                    beq       SetHexBase hex prefix
                    bra       CheckDecimalDigit check for decimal digit

CheckRadixSet       ldd       4,S       get the radix
                    bne       InitAccumulator have a radix, parse digits
                    clra                clear high byte
                    clrb                clear low byte, no number
                    lbra      ParseNumberDone return with no number

InitAccumulator     clra                clear high byte
                    clrb                clear low byte
                    std       <OperandVal clear the accumulator
                    bra       DigitCheck check first digit

AccumDigitLoop      ldd       <OperandVal get the accumulator
                    pshs      D         push it
                    ldd       6,S       get the radix
                    lbsr      MulEntry  multiply accumulator by radix
                    pshs      D         push the product
                    ldb       2,S       get current digit char
                    cmpb      #65       is it a letter
                    bge       HexLetterDigit handle hex letter
                    ldb       2,S       get digit char
                    sex                 sign extend
                    addd      #-48      convert digit to value
                    bra       AddDigitValue add to accumulator

HexLetterDigit      ldb       2,S       get letter char
                    sex                 sign extend
                    addd      #-55      convert hex letter to value
AddDigitValue       addd      ,S++      add to running product
                    std       <OperandVal store the accumulator
                    ldd       2,S       get digit count
                    addd      #1        increment it
                    std       2,S       save the count
                    ldx       <SrcPtr   get input pointer
                    leax      1,X       advance past digit
                    stx       <SrcPtr   save input pointer
                    ldb       ,X        get next char
                    stb       ,S        save current char
DigitCheck          ldb       ,S        get current char
                    sex                 sign extend
                    leax      >CharClassTbl,Y point to char class table
                    leax      D,X       index by char
                    ldb       ,X        get class flags
                    clra                clear high byte
                    andb      #4        is it a letter
                    beq       PlainDigitChar not a letter
                    ldb       ,S        get char
                    clra                clear high byte
                    andb      #223      force uppercase
                    bra       CheckDigitValid check digit validity

PlainDigitChar      ldb       ,S        get char
                    sex                 sign extend
CheckDigitValid     stb       ,S        save normalized char
                    sex                 sign extend
                    leax      >CharClassTbl,Y point to char class table
                    leax      D,X       index by char
                    ldb       ,X        get class flags
                    sex                 sign extend
                    pshs      D         push class flags
                    ldb       3,S       get digit class mask
                    sex                 sign extend
                    anda      ,S+       mask high byte
                    andb      ,S+       mask low byte
                    std       -2,S      save validity result
                    lbne      AccumDigitLoop valid digit, accumulate
                    ldd       2,S       return digit count
ParseNumberDone     leas      6,S       discard locals
                    puls      PC,U      return

MsgValueOutOfRange  fcc       "value out of range"
                    fcb       C$NULL
MsgBadOperator      fcc       "bad operator"
                    fcb       C$NULL
MsgZeroDivision     fcc       "zero division"
                    fcb       C$NULL
MsgParenMissing     fcc       "parenthesis missing"
                    fcb       C$NULL
MsgUndefinedOrg     fcc       "undefined org"
                    fcb       C$NULL
MsgBadOperand       fcc       "bad operand"
                    fcb       C$NULL
ParseOrgDirective   pshs      U         save the caller u register
                    leas      -1,S      allocate local
                    clra                clear high byte
                    clrb                clear low byte
                    std       <OutFileHand clear field
                    std       <CurFileHand clear field
                    leax      >OutBuffer,Y point to line buffer
                    stx       <CurLineNo save buffer pointer
                    lbra      NextArgLoop begin line scan

ScanLineToken       ldx       7,S       get line pointer argument
                    ldb       [,X]      get first char
                    cmpb      #'-       is it a dash
                    bne       CheckBufferLimit not a comment line
                    ldd       [<7,S]    get line pointer
                    addd      #1        advance past the dash
                    std       <SrcPtr   set input pointer
                    lbsr      ParseOptionList scan the token
                    ldb       <SectCount get scan status
                    lbeq      NextArgLoop nothing scanned
                    ldx       <SrcPtr   get input pointer
                    ldb       -1,X      get last char
                    clra                clear high byte
                    andb      #223      force uppercase
                    stb       ,S        save char
                    beq       NextArgLoop end of line
                    ldb       ,S        get char
                    cmpb      #79       is it the letter o
                    bne       NextArgLoop not the option flag
                    ldb       [>SrcPtr,Y] get next char
                    cmpb      #'=       is it equals
                    bne       NextArgLoop not an assignment
                    ldd       >Y03F8,Y  check org already set
                    beq       SetOrgPosition set the org
                    leax      >MsgTooManyObjFiles,PC point to error message
                    pshs      X         push message pointer
                    lbsr      FatalError report the error
                    leas      2,S       drop the argument
                    bra       NextArgLoop continue scanning

SetOrgPosition      ldd       <SrcPtr   get input pointer
                    addd      #1        advance past equals
                    std       <SrcPtr   save input pointer
                    std       >Y03F8,Y  record org position
                    bra       NextArgLoop continue scanning

CheckBufferLimit    leax      >BufferEnd,Y point to buffer end
                    cmpx      >ArgArrayPtr,Y reached the limit
                    bcc       StoreArgPtr buffer full
                    leax      >MsgTooManyInputFiles,PC point to error message
                    pshs      X         push message pointer
                    lbsr      FatalError call the print routine
                    leas      2,S       drop the argument
StoreArgPtr         ldd       [<7,S]    load the argument pointer from the stack
                    ldx       >ArgArrayPtr,Y load the argument array pointer
                    leax      2,X       advance the array pointer
                    stx       >ArgArrayPtr,Y save the updated array pointer
                    std       -2,X      store the argument into the array
NextArgLoop         ldd       7,S       load the source pointer
                    addd      #2        advance by two bytes
                    std       7,S       save the source pointer
                    ldd       5,S       load the remaining count
                    addd      #-1       decrement the counter
                    std       5,S       save the counter
                    lbne      ScanLineToken loop while more arguments
                    leax      >ArgBuffer,Y point to the argument array base
                    cmpx      >ArgArrayPtr,Y compare against the current pointer
                    bne       CheckOutName skip if any arguments were seen
                    leax      >MsgNoInputFile,PC point to the default message
                    pshs      X         push the string argument
                    lbsr      FatalError print the string
                    leas      2,S       drop the argument
CheckOutName        ldd       >Y03F8,Y  load the output name pointer
                    bne       ArgsDone  skip if output already set
                    leax      >NameDefaultOutput,PC point to the default output name
                    stx       >Y03F8,Y  store the default output name
ArgsDone            leas      1,S       release the local byte
                    puls      PC,U      restore and return

OpenFile            pshs      U,D       save u and reserve local
                    ldd       8,S       load the filename argument
                    pshs      D         push the filename
                    ldd       8,S       load the mode argument
                    pshs      D         push the mode
                    lbsr      fopen     open the file
                    leas      4,S       drop the arguments
                    std       ,S        save the file handle local
                    bne       OpenDone  skip if open succeeded
                    ldd       6,S       load the filename argument
                    pshs      D         push the filename
                    leax      >MsgQuotedName,PC point to the error format string
                    pshs      X         push the format string
                    leax      >MsgBuffer,Y point to the message buffer
                    pshs      X         push the buffer
                    lbsr      Vsprintf  format the error message
                    leas      6,S       drop the arguments
                    leax      >MsgCantOpenFile,PC point to the error message
                    pshs      X         push the message
                    lbsr      FatalError print the error
                    leas      2,S       drop the argument
OpenDone            ldd       ,S        load the file handle result
                    puls      PC,U,X    restore and return

SyncLineNumbers     pshs      U         save the caller u register
                    ldb       <PassFlag load the listing flag
                    lbeq      LineSyncDone skip if listing disabled
                    ldd       <ListFlag load the line-number option
                    lbeq      LineSyncDone skip if disabled
                    ldd       >LineAddr,Y load the current line counter
                    beq       WriteObjHeader skip if at line zero
                    ldb       <U00C0    load the flag
                    beq       EmitLineCond skip if flag clear
                    ldd       <CurLineNo load the current line number
                    pshs      D         push the line number
                    ldd       #12       opcode value twelve
                    pshs      D         push the opcode
                    lbsr      PutChar   emit the line directive
                    leas      4,S       drop the arguments
                    bra       WriteObjHeader continue to header

EmitLineLoop        ldd       <CurLineNo load the current line number
                    pshs      D         push the line number
                    ldd       #13       opcode value thirteen
                    pshs      D         push the opcode
                    lbsr      PutChar   emit the line directive
                    leas      4,S       drop the arguments
                    ldd       >LineAddr,Y load the line counter
                    addd      #1        increment the counter
                    std       >LineAddr,Y save the line counter
EmitLineCond        ldd       >LineAddr,Y load the line counter
                    cmpd      <U0003    compare against the target line
                    blt       EmitLineLoop loop until caught up
WriteObjHeader      leax      >Y07F9,Y  point to the name buffer
                    pshs      X         push the buffer pointer
                    lbsr      GetTime   clear and prepare the buffer
                    leas      2,S       drop the argument
                    ldb       >Y07FD,Y  load a value byte
                    sex                 sign extend to a word
                    pshs      D         push the value byte
                    ldb       >Y07FC,Y  load a value byte
                    sex                 sign extend to a word
                    pshs      D         push the value byte
                    ldb       >Y07FB,Y  load a value byte
                    sex                 sign extend to a word
                    pshs      D         push the value byte
                    ldb       >Y07FA,Y  load a value byte
                    sex                 sign extend to a word
                    pshs      D         push the value byte
                    ldb       >Y07F9,Y  load a value byte
                    sex                 sign extend to a word
                    pshs      D         push the value byte
                    leax      >MsgRmaVersion,PC point to the format string
                    pshs      X         push the format string
                    leax      >MsgBanner,PC point to the header template
                    pshs      X         push the template
                    lbsr      FormatToScratch write the formatted header
                    leas      14,S      drop the arguments
                    ldd       <LineCount load the line count
                    addd      #1        increment the count
                    std       <LineCount save the line count
                    pshs      D         push the line count
                    ldd       >ArgBuffer,Y load the argument value
                    pshs      D         push the value
                    leax      >MsgPageHeader,PC point to the format string
                    pshs      X         push the format string
                    lbsr      FormatToScratch write the formatted output
                    leas      6,S       drop the arguments
                    leax      >Y063F,Y  point to a buffer
                    pshs      X         push the buffer
                    leax      >Y05C7,Y  point to another buffer
                    pshs      X         push the buffer
                    leax      >MsgTitleLine,PC point to the format string
                    pshs      X         push the format string
                    lbsr      FormatToScratch write the formatted output
                    leas      6,S       drop the arguments
                    ldd       #3        initial line counter value
                    bra       StoreLineCount store the line counter

AdvanceLine         pshs      U         save the caller u register
                    ldb       <PassFlag load the listing flag
                    beq       LineSyncDone skip if listing disabled
                    ldd       <ListFlag load the line-number option
                    beq       LineSyncDone skip if disabled
                    ldd       <U0003    load the target line number
                    addd      #-3       subtract three
                    cmpd      >LineAddr,Y compare against the line counter
                    bge       EmitEndLine skip if within range
                    lbsr      SyncLineNumbers flush the line directives
EmitEndLine         ldd       <CurLineNo load the current line number
                    pshs      D         push the line number
                    ldd       #13       opcode value thirteen
                    pshs      D         push the opcode
                    lbsr      PutChar   emit the line directive
                    leas      4,S       drop the arguments
                    ldd       >LineAddr,Y load the line counter
                    addd      #1        increment the counter
StoreLineCount      std       >LineAddr,Y save the line counter
LineSyncDone        puls      PC,U      restore and return

ReadInputLine       pshs      U         save the caller u register
                    leas      -3,S      reserve local space
                    lbsr      ExpandMacroLine get the next input line
                    std       -2,S      save the result pointer
                    bne       GotLineOk branch if end reached
NextLineStart       ldb       <U00C2    load the pass flag
                    beq       InitLineBuf skip if not set
                    leax      >IncludeStack,Y point to the include stack
                    cmpx      >SavedStkPtr,Y compare with the stack pointer
                    bne       InitLineBuf skip if not at the base
                    leax      >MsgAsmPrefix,PC point to a string
                    pshs      X         push the string
                    lbsr      FormatToScratch write the output
                    leas      2,S       drop the argument
InitLineBuf         leax      >InLineBuffer,Y point to the line buffer
                    stx       <SrcPtr   save the buffer pointer
                    tfr       X,D       copy the pointer to D
                    std       1,S       save the buffer pointer local
                    bra       NextCharLoop enter the read loop

HandleChar          ldb       ,S        load the current character
                    cmpb      #13       compare with carriage return
                    bne       StoreLineChar branch if not end of line
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       [<1,S]    terminate the line buffer
                    ldd       <LineNumber load the line total
                    addd      #1        increment the total
                    std       <LineNumber save the line total
GotLineOk           ldd       #1        return value one
                    bra       ReadLineExit exit the routine

StoreLineChar       ldb       ,S        load the current character
                    ldx       1,S       load the buffer pointer
                    leax      1,X       advance the buffer pointer
                    stx       1,S       save the buffer pointer
                    stb       -1,X      store the character into the buffer
NextCharLoop        ldd       <CurFileHand load the current file handle
                    pshs      D         push the file handle
                    lbsr      Getc      read the next character
                    leas      2,S       drop the argument
                    stb       ,S        save the character
                    sex                 sign extend to a word
                    cmpd      #-1       check for end of file
                    bne       HandleChar loop if more characters
                    bsr       PopIncludeFile pop the include file
                    std       -2,S      save the result
                    lbne      NextLineStart retry if a file was popped
                    clra                clear the high byte
                    clrb                return value zero
ReadLineExit        leas      3,S       release the local space
                    puls      PC,U      restore and return

PopIncludeFile      pshs      U         save the caller u register
                    leax      >IncludeStack,Y point to the include stack base
                    cmpx      >SavedStkPtr,Y compare with the stack pointer
                    bne       CloseIncludeFile branch if files remain
                    clra                clear the high byte
                    clrb                return value zero
                    puls      PC,U      restore and return

CloseIncludeFile    ldd       <CurFileHand load the current file handle
                    pshs      D         push the file handle
                    lbsr      fclose    close the file
                    std       ,S++      save result and drop it
                    beq       PopStackEntry skip if close succeeded
                    leax      >MsgFileCloseErr2,PC point to the error message
                    pshs      X         push the message
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
PopStackEntry       ldx       >SavedStkPtr,Y load the include stack pointer
                    leax      -2,X      pop one entry
                    stx       >SavedStkPtr,Y save the stack pointer
                    ldd       ,X        load the previous file handle
                    std       <CurFileHand restore the current file handle
                    ldd       #1        return value one
                    puls      PC,U      restore and return

DumpSymbols         pshs      U         save the caller u register
                    leax      >MsgSymbolTable,PC point to the header string
                    pshs      X         push the string
                    lbsr      FormatToScratch write the output
                    leas      2,S       drop the argument
                    ldd       <U0005    load the page line count
                    subd      #24       subtract the page size
                    std       <U0005    save the line count
                    leax      >PrintSymbolEntry,PC point to the callback function
                    pshs      X         push the callback
                    lbsr      WalkSymbols walk the symbol table
                    leas      2,S       drop the argument
                    ldd       >ColumnCount,Y load the column counter
                    ble       WriteTrailer skip if at column start
                    leax      >MsgNewLineA,PC point to the newline string
                    pshs      X         push the string
                    lbsr      FormatToScratch write the output
                    leas      2,S       drop the argument
WriteTrailer        leax      >MsgNewLineB,PC point to the trailer string
                    pshs      X         push the string
                    lbsr      FormatToScratch write the output
                    puls      PC,U,X    restore and return

PrintSymbolEntry    pshs      U         save the caller u register
                    ldu       4,S       load the symbol entry pointer
                    ldd       >ColumnCount,Y load the column counter
                    ble       WriteEntryFields skip if at column start
                    leax      >MsgBarSep,PC point to the separator string
                    pshs      X         push the string
                    lbsr      FormatToScratch write the output
                    leas      2,S       drop the argument
WriteEntryFields    ldd       2,U       load the symbol value
                    pshs      D         push the value
                    ldb       1,U       load a symbol byte
                    clra                clear the high byte
                    pshs      D         push the byte
                    ldb       ,U        load a symbol byte
                    clra                clear the high byte
                    pshs      D         push the byte
                    pshs      U         push the entry pointer
                    ldd       #10       offset to the name field
                    addd      ,S++      add to the entry pointer
                    pshs      D         push the name pointer
                    leax      >MsgSymTableRow,PC point to the format string
                    pshs      X         push the format string
                    lbsr      FormatToScratch write the formatted entry
                    leas      10,S      drop the arguments
                    ldd       >ColumnCount,Y load the column counter
                    addd      #25       advance one column width
                    std       >ColumnCount,Y save the column counter
                    cmpd      <U0005    compare against the page width
                    bgt       PageBreak branch if the line is full
                    ldb       <ListingFlag load the flag
                    beq       EntryDone skip if flag clear
PageBreak           leax      >MsgNewLineC,PC point to the newline string
                    pshs      X         push the string
                    lbsr      FormatToScratch write the output
                    leas      2,S       drop the argument
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       >ColumnCount,Y reset the column counter
EntryDone           puls      PC,U      restore and return

ParsePsect          pshs      U         save the caller u register
                    leas      -16,S     reserve the local buffer
                    ldb       [>SrcPtr,Y] load the first operand character
                    lbeq      EmptyOperand branch if operand empty
                    leas      -2,S      reserve local space
                    leau      2,S       point to the local buffer
                    ldd       #16       buffer size limit
                    std       ,S        save the counter
                    bra       CopyFieldLoop enter the copy loop

CopyFieldChar       ldx       <SrcPtr   load the operand pointer
                    leax      1,X       advance the pointer
                    stx       <SrcPtr   save the pointer
                    ldb       -1,X      load the character
                    stb       ,U+       store into the buffer
CopyFieldLoop       ldd       ,S        load the remaining count
                    addd      #-1       decrement the counter
                    std       ,S        save the counter
                    subd      #-1       restore for the test
                    beq       FieldCopied stop if the buffer is full
                    ldb       [>SrcPtr,Y] load the current character
                    beq       FieldCopied stop at end of string
                    ldb       [>SrcPtr,Y] load the current character
                    cmpb      #',       compare with a comma
                    bne       CopyFieldChar loop until a comma is reached
FieldCopied         clra                clear the high byte
                    clrb                clear the low byte
                    stb       ,U        terminate the buffer
                    lbsr      SetValueHandler evaluate the operand
                    std       -2,S      save the result
                    lbeq      PsectFieldsDone stop if evaluation failed
                    lbsr      EvalLineExpr skip the separator
                    lbsr      CheckNoExternal parse the field
                    ldd       <OperandVal load the parsed value
                    pshs      D         push the value
                    ldd       #8        shift and mask constant
                    lbsr      AslEntry  combine the fields
                    std       >Y03DC,Y  save the result
                    lbsr      SetValueHandler evaluate the next operand
                    std       -2,S      save the result
                    beq       PsectFieldsDone stop if evaluation failed
                    lbsr      EvalLineExpr skip the separator
                    lbsr      CheckNoExternal parse the field
                    ldd       >Y03DC,Y  load the accumulated value
                    pshs      D         push the value
                    ldd       <OperandVal load the parsed value
                    clra                clear the high byte
                    ora       ,S+       combine the high bytes
                    orb       ,S+       combine the low bytes
                    std       >Y03DC,Y  save the combined value
                    lbsr      SetValueHandler evaluate the next operand
                    std       -2,S      save the result
                    beq       PsectFieldsDone stop if evaluation failed
                    lbsr      EvalLineExpr skip the separator
                    lbsr      CheckNoExternal parse the field
                    ldd       <OperandVal load the parsed value
                    clra                clear the high byte
                    stb       >Y03E4,Y  save the field byte
                    lbsr      SetValueHandler evaluate the next operand
                    std       -2,S      save the result
                    beq       PsectFieldsDone stop if evaluation failed
                    lbsr      EvalLineExpr skip the separator
                    lbsr      CheckNoExternal parse the field
                    ldd       <OperandVal load the parsed value
                    std       >Y03F0,Y  save the field value
                    lbsr      SetValueHandler evaluate the next operand
                    std       -2,S      save the result
                    beq       PsectFieldsDone stop if evaluation failed
                    lbsr      EvalLineExpr skip the separator
                    lbsr      CheckNoExternal parse the field
                    ldd       <OperandVal load the parsed value
                    std       >Y03F2,Y  save the field value
PsectFieldsDone     leas      2,S       release the local space
                    bra       WritePsectHeader continue to header write

EmptyOperand        leax      >MsgProgram,PC point to the error message
                    pshs      X         push the message
                    leax      2,S       point to the local buffer
                    pshs      X         push the buffer
                    lbsr      strcpy    report the error
                    leas      4,S       drop the arguments
WritePsectHeader    leax      >Y07F9,Y  point to the name buffer
                    pshs      X         push the buffer
                    lbsr      GetTime   clear and prepare the buffer
                    leas      2,S       drop the argument
                    ldd       #5        copy length five
                    pshs      D         push the length
                    leax      >Y07F9,Y  point to the source buffer
                    pshs      X         push the source
                    leax      >Y03DF,Y  point to the destination
                    pshs      X         push the destination
                    lbsr      memcpy    copy the bytes
                    leas      6,S       drop the arguments
                    ldd       <ErrCount load a field value
                    stb       >Y03DE,Y  save the field byte
                    ldd       <U0041    load a field value
                    std       >Y03E6,Y  save the field
                    ldd       <U0043    load a field value
                    std       >Y03E8,Y  save the field
                    ldd       <U0045    load a field value
                    std       >Y03EA,Y  save the field
                    ldd       <U0047    load a field value
                    std       >Y03EC,Y  save the field
                    ldd       <TargetAddr load a field value
                    std       >Y03EE,Y  save the field
                    ldb       <PassFlag load the listing flag
                    lbeq      EmitBlockDone skip if listing disabled
                    ldd       <OutFileHand load the output file handle
                    lbeq      EmitBlockDone skip if no output file
                    leax      >Y07E9,Y  point to a buffer
                    pshs      X         push the buffer
                    ldd       <OutFileHand load the output file handle
                    pshs      D         push the handle
                    lbsr      CurFilePos position the output file
                    leas      2,S       drop the argument
                    lbsr      StoreLong get the buffer pointer
                    ldd       <OutFileHand load the output file handle
                    pshs      D         push the handle
                    ldd       #1        parameter one
                    pshs      D         push the parameter
                    ldd       #28       write length
                    pshs      D         push the length
                    leax      >HeaderRec,Y point to the header record
                    pshs      X         push the record pointer
                    lbsr      Fwrite    write the header record
                    leas      8,S       drop the arguments
                    ldd       <OutFileHand load the output file handle
                    pshs      D         push the handle
                    leax      2,S       point to the local buffer
                    pshs      X         push the buffer
                    lbsr      Fputs     read or write file data
                    leas      4,S       drop the arguments
                    ldd       <OutFileHand load the output file handle
                    pshs      D         push the handle
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push zero
                    lbsr      PutChar   emit the output
                    leas      4,S       drop the arguments
                    ldd       <OutFileHand load the output file handle
                    pshs      D         push the handle
                    ldd       #1        parameter one
                    pshs      D         push the parameter
                    ldd       #2        write length two
                    pshs      D         push the length
                    leax      >UndefCount,Y point to the value field
                    pshs      X         push the field pointer
                    lbsr      Fwrite    write the value
                    leas      8,S       drop the arguments
                    ldd       <UndefCount load the value
                    beq       WritePsectFields skip if zero
                    leax      >EmitEquateSym,PC point to the callback function
                    pshs      X         push the callback
                    lbsr      WalkSymbols walk the symbol table
                    leas      2,S       drop the argument
WritePsectFields    leax      >Y07F5,Y  point to a field
                    pshs      X         push the field
                    leax      >Y07F1,Y  point to a field
                    pshs      X         push the field
                    leax      >Y07ED,Y  point to a field
                    pshs      X         push the field
                    leax      >WorkBuffer,Y point to a field
                    pshs      X         push the field
                    ldd       <OutFileHand load the output file handle
                    pshs      D         push the handle
                    lbsr      CurFilePos position the output file
                    leas      2,S       drop the argument
                    lbsr      StoreLong get the buffer pointer
                    lbsr      StoreLong get the buffer pointer
                    ldd       2,X       load a field value
                    pshs      D         push the value
                    ldd       ,X        load a field value
                    pshs      D         push the value
                    ldd       <TargetAddr load a field value
                    lbsr      ZeroExtend32 write the field
                    lbsr      Add32     call the emit helper
                    lbsr      StoreLong call the emit helper
                    ldd       2,X       load the second word of the node
                    pshs      D         push the argument
                    ldd       ,X        load the first word of the node
                    pshs      D         push the argument
                    ldd       <U0047    load the global value
                    lbsr      ZeroExtend32 call the record helper
                    lbsr      Add32     call the emit helper
                    lbsr      StoreLong call the emit helper
EmitBlockDone       leas      <16,S     discard the local frame
                    puls      PC,U      restore and return

CheckNoExternal     pshs      U         save the caller u register
                    ldb       <PassFlag load the pass flag
                    lbeq      SectionsDone skip if not set
                    ldd       <ColumnFlag load the external count
                    lbeq      SectionsDone skip if none
                    leax      >MsgNoExternal,PC point to the 'no external allowed' message
                    pshs      X         push the message pointer
                    lbsr      EmitMessageLine report the error
                    lbra      SectionsExit jump to the exit

EmitDataSection     pshs      U,D       save u and reserve a local
                    leax      >HeaderRec,Y point to the data table start
                    tfr       X,D       copy the start pointer to d
                    leax      >Y03DE,Y  point to the data table end
                    nega                negate the high byte
                    negb                negate the low byte
                    sbca      #0        finish the sixteen-bit negate
                    leax      D,X       compute the table span
                    stx       ,S        save the computed span
                    ldd       <OutFileHand load the output flag
                    lbeq      EmitDataDone skip if not writing
                    ldb       <SectCount load the section count
                    lble      EmitDataDone skip if none
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push the zero argument
                    leax      >Y07E9,Y  point to the section name
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    ldd       6,S       load the saved span
                    lbsr      ZeroExtend32 call the record helper
                    lbsr      Add32     call the emit helper
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    lbsr      Fseek     call the emit routine
                    leas      8,S       drop the arguments
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       <ErrCount load the counter
                    pshs      D         push the argument
                    lbsr      PutChar   call the helper
                    leas      4,S       drop the arguments
                    leax      >WorkBuffer,Y point to the work buffer
                    pshs      X         push the pointer
                    leax      >Y07E9,Y  point to the section name
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    ldd       6,S       load the saved span
                    lbsr      ZeroExtend32 call the record helper
                    lbsr      Add32     call the emit helper
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    bsr       EmitInlineData call past the inline data pointer
                    neg       <U0000    inline thunk data byte
                    neg       <U0001    inline thunk data byte
EmitInlineData      puls      X         pull the inline data pointer
                    lbsr      Add32     call the emit helper
                    lbsr      StoreLong call the emit helper
EmitDataDone        puls      PC,U,X    restore and return

UpdateSectionSize   pshs      U         save the caller u register
                    ldd       <RelocPtr load the section pointer
                    lbeq      SectionDone skip if none
                    ldd       6,S       load the size argument
                    lbeq      SectionDone skip if zero
                    ldd       [>RelocPtr,Y] load the current size
                    addd      6,S       add the argument
                    std       [>RelocPtr,Y] store the updated size
                    ldb       <PassFlag load the pass flag
                    lbeq      SectionDone skip on the first pass
                    ldb       <SectFlags load the section flags
                    clra                clear the high byte
                    andb      #2        test bit one
                    lbeq      SectionDone skip if clear
                    ldd       <OutFileHand load the output flag
                    lbeq      SectionDone skip if not writing
                    ldb       <SectCount load the section count
                    lble      SectionDone skip if none
                    ldb       <TypeFlags load the type flags
                    clra                clear the high byte
                    andb      #4        test bit two
                    beq       CheckDataFlag branch if clear
                    leax      >Y07ED,Y  point to the section name
                    bra       HaveSectionName continue

CheckDataFlag       ldb       <TypeFlags load the type flags
                    clra                clear the high byte
                    andb      #2        test bit one
                    beq       UseBssName branch if clear
                    leax      >Y07F1,Y  point to the section name
                    bra       HaveSectionName continue

UseBssName          leax      >Y07F5,Y  point to the default section name
HaveSectionName     tfr       X,D       copy the pointer to d
                    tfr       D,U       save the name pointer
                    leax      >WorkBuffer,Y point to the work buffer
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    leax      ,U        restore the name pointer
                    lbsr      Cmp32     compare the names
                    beq       EmitSizeRecord skip if equal
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push the zero argument
                    leax      ,U        point to the name
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    lbsr      Fseek     call the emit routine
                    leas      8,S       drop the arguments
EmitSizeRecord      ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       #1        constant one
                    pshs      D         push the argument
                    ldd       10,S      load the value
                    pshs      D         push the argument
                    ldd       10,S      load the value
                    pshs      D         push the argument
                    lbsr      Fwrite    call the emit routine
                    leas      8,S       drop the arguments
                    leax      >WorkBuffer,Y point to the work buffer
                    pshs      X         push the pointer
                    leax      ,U        point to the name
                    pshs      X         push the pointer
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    ldd       14,S      load the value
                    lbsr      SignExtend32 call the helper
                    lbsr      Add32     call the emit helper
                    lbsr      StoreLong call the emit helper
                    lbsr      StoreLong call the emit helper
SectionDone         puls      PC,U      restore and return

WalkSymbols         pshs      U,D       save u and argument
                    clra                clear the high byte
                    clrb                clear the low byte
                    bra       WalkLoopTest jump to the loop test

WalkBucketLoop      ldd       ,S        load the bucket index
                    aslb                shift the low byte
                    rola                shift the high byte for times two
                    leax      >Y06C5,Y  point to the hash table
                    leax      D,X       index into the table
                    ldu       ,X        load the bucket head
                    stu       -2,S      save the bucket pointer
                    beq       NextBucket skip the empty bucket
                    bra       ChainTest enter the chain loop

NextChainLink       ldu       4,U       follow the chain link
ChainTest           ldd       4,U       load the next link
                    bne       NextChainLink loop while non-zero
CallbackLoop        pshs      U         push the node pointer
                    jsr       [<8,S]    call the callback
                    leas      2,S       drop the argument
                    pshs      U         push the node pointer
                    lbsr      FindListTail get the previous link
                    leas      2,S       drop the argument
                    tfr       D,U       move the result to u
                    stu       -2,S      save the current node
                    bne       CallbackLoop loop while non-zero
NextBucket          ldd       ,S        load the bucket index
                    addd      #1        increment the index
WalkLoopTest        std       ,S        store the index
                    ldd       ,S        reload the index
                    cmpd      #64       compare to the bucket count
                    blt       WalkBucketLoop loop over all buckets
                    puls      PC,U,X    restore and return

EmitModuleSections  pshs      U         save the caller u register
                    ldd       <OutFileHand load the output flag
                    lbeq      SectionsDone skip if not writing
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push the zero argument
                    leax      >Y07F5,Y  point to the section name
                    ldd       2,X       load the second word
                    pshs      D         push the argument
                    ldd       ,X        load the first word
                    pshs      D         push the argument
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    lbsr      Fseek     call the emit routine
                    leas      8,S       drop the arguments
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       #1        constant one
                    pshs      D         push the argument
                    ldd       #2        constant two
                    pshs      D         push the argument
                    leax      >IntRelocCnt,Y point to the counter
                    pshs      X         push the pointer
                    lbsr      Fwrite    call the emit routine
                    leas      8,S       drop the arguments
                    ldd       <IntRelocCnt load the counter
                    beq       EmitDataNames skip if zero
                    leax      >EmitLabelSym,PC point to the label callback
                    pshs      X         push the callback pointer
                    lbsr      WalkSymbols walk the symbol table
                    leas      2,S       drop the argument
EmitDataNames       ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       #1        constant one
                    pshs      D         push the argument
                    ldd       #2        constant two
                    pshs      D         push the argument
                    leax      >ExtRelocCnt,Y point to the counter
                    pshs      X         push the pointer
                    lbsr      Fwrite    call the emit routine
                    leas      8,S       drop the arguments
                    ldd       <ExtRelocCnt load the counter
                    beq       SectionsDone skip if zero
                    ldd       <CodeListHd load the list head
                    beq       EmitBssNames skip if empty
                    ldd       <CodeListHd reload the list head
                    pshs      D         push the argument
                    lbsr      EmitNameList emit the name list
                    leas      2,S       drop the argument
EmitBssNames        ldd       <DataListHd load the list head
                    beq       EmitCommonNames skip if empty
                    ldd       <DataListHd reload the list head
                    pshs      D         push the argument
                    lbsr      EmitNameList emit the name list
                    leas      2,S       drop the argument
EmitCommonNames     ldd       <BssListHd load the list head
                    beq       SectionsDone skip if empty
                    ldd       <BssListHd reload the list head
                    pshs      D         push the argument
                    lbsr      EmitNameList emit the name list
SectionsExit        leas      2,S       drop the argument
SectionsDone        puls      PC,U      restore and return

EmitEquateSym       pshs      U         save the caller u register
                    ldu       4,S       load the node argument
                    leas      -3,S      reserve the local space
                    ldb       1,U       load the flags byte
                    clra                clear the high byte
                    andb      #198      mask the flag bits
                    cmpd      #134      check for the equate value
                    bne       EquateDone skip if not matching
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    pshs      U         push the node pointer
                    ldd       #10       offset ten
                    addd      ,S++      add to the node pointer
                    pshs      D         push the computed pointer
                    lbsr      Fputs     call the emit routine
                    leas      4,S       drop the arguments
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push the zero argument
                    lbsr      PutChar   call the helper
                    leas      4,S       drop the arguments
                    ldb       ,U        load the first byte
                    stb       ,S        store into the local
                    ldd       2,U       load the node value
                    std       1,S       store into the local
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       #1        constant one
                    pshs      D         push the argument
                    ldd       #3        constant three
                    pshs      D         push the argument
                    leax      6,S       point to the local buffer
                    pshs      X         push the pointer
                    lbsr      Fwrite    call the emit routine
                    leas      8,S       drop the arguments
EquateDone          leas      3,S       discard the local space
                    puls      PC,U      restore and return

EmitLabelSym        pshs      U         save the caller u register
                    ldu       4,S       load the node argument
                    leas      -2,S      reserve the local space
                    ldb       1,U       load the flags byte
                    clra                clear the high byte
                    andb      #66       mask the flag bits
                    lbne      LabelDone3 skip if any set
                    ldd       8,U       load the node value
                    lbeq      LabelDone3 skip if zero
                    ldb       ,U        load the type byte
                    clra                clear the high byte
                    andb      #7        mask the type bits
                    std       ,S        save the type
                    cmpd      #6        check for type six
                    lbeq      LabelDone3 skip if match
                    ldd       ,S        reload the type
                    cmpd      #5        check for type five
                    beq       LabelDone3 skip if match
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    pshs      U         push the node pointer
                    ldd       #10       offset ten
                    addd      ,S++      add to the node pointer
                    pshs      D         push the computed pointer
                    lbsr      Fputs     call the emit routine
                    leas      4,S       drop the arguments
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push the zero argument
                    lbsr      PutChar   call the helper
                    leas      4,S       drop the arguments
                    pshs      U         push the node pointer
                    bsr       ReverseSymbolList reverse the list and count nodes
                    leas      2,S       drop the argument
                    std       ,S        save the node count
                    ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       #1        constant one
                    pshs      D         push the argument
                    ldd       #2        constant two
                    pshs      D         push the argument
                    leax      6,S       point to the local
                    pshs      X         push the pointer
                    lbsr      Fwrite    call the emit routine
                    leas      8,S       drop the arguments
                    ldd       8,U       load the node value
                    pshs      D         push the argument
                    bsr       EmitNameList emit the name list
                    leas      2,S       drop the argument
LabelDone3          puls      PC,U,X    restore and return

ReverseSymbolList   pshs      U,X,D     save registers and reserve locals
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        initialize the count to zero
                    ldx       8,S       load the list header
                    ldu       8,X       load the list head
                    clra                clear the high byte
                    clrb                clear the low byte
                    ldx       8,S       load the list header
                    std       8,X       clear the list head
ReverseLoop         ldd       3,U       load the next link
                    std       2,S       save the next pointer
                    ldx       8,S       load the list header
                    ldd       8,X       load the current head
                    std       3,U       link the node to the head
                    ldx       8,S       load the list header
                    stu       8,X       make the node the new head
                    ldd       ,S        load the count
                    addd      #1        increment the count
                    std       ,S        store the count
                    ldu       2,S       advance to the next node
                    bne       ReverseLoop loop over the list
                    ldd       ,S        load the final count
                    leas      4,S       discard the locals
                    puls      PC,U      restore and return

EmitNameList        pshs      U         save the caller u register
                    ldu       4,S       load the list head argument
NameListLoop        ldd       <OutFileHand load the output flag
                    pshs      D         push the argument
                    ldd       #1        constant one
                    pshs      D         push the argument
                    ldd       #3        constant three
                    pshs      D         push the argument
                    pshs      U         push the node pointer
                    lbsr      Fwrite    call the emit routine
                    leas      8,S       drop the arguments
                    ldu       3,U       follow the chain link
                    stu       -2,S      test the next pointer
                    bne       NameListLoop loop over the list
                    puls      PC,U      restore and return

MsgTooManyObjFiles  fcc       "too many object files"
                    fcb       C$NULL
MsgTooManyInputFiles fcc       "too many input files"
                    fcb       C$NULL
MsgNoInputFile      fcc       "no input file"
                    fcb       C$NULL
NameDefaultOutput   fcc       "output.r"
                    fcb       C$NULL
MsgQuotedName       fcc       /"%s" - /
                    fcb       C$NULL
MsgCantOpenFile     fcc       "can't open file"
                    fcb       C$NULL
MsgBanner           fcc       "Microware OS-9 %s  %d/%02d/%02d  %02d:%02d"
                    fcb       C$NULL
MsgRmaVersion       fcc       "RMA - V1.0"
                    fcb       C$NULL
MsgPageHeader       fcc       "   %-20s Page %5d"
                    fcb       C$CR
                    fcb       C$NULL
MsgTitleLine        fcc       "%s - %s"
                    fcb       C$CR
                    fcb       C$CR
                    fcb       C$NULL
MsgAsmPrefix        fcc       "Asm:"
                    fcb       C$NULL
MsgFileCloseErr2    fcc       "file close error"
                    fcb       C$NULL
MsgSymbolTable      fcb       C$CR
                    fcc       "Symbol Table"
                    fcb       C$CR
                    fcb       C$NULL
MsgNewLineA         fcb       C$CR
                    fcb       C$NULL
MsgNewLineB         fcb       C$CR
                    fcb       C$NULL
MsgBarSep           fcc       "  |"
                    fcb       C$NULL
MsgSymTableRow      fcc       "  %-9s %02x %02x %04x"
                    fcb       C$NULL
MsgNewLineC         fcb       C$CR
                    fcb       C$NULL
MsgProgram          fcc       "program"
                    fcb       C$NULL
MsgNoExternal       fcc       "no external allowed"
                    fcb       C$NULL
OpenObjectFile      pshs      U,D       save u and reserve a local
                    ldb       <PassFlag load the pass flag
                    beq       DoOpenFile branch on the first pass
                    ldd       #1        return one
                    puls      PC,U,X    restore and return

DoOpenFile          ldd       <OutStream load the file handle
                    bne       AddSymbolNode skip if already open
                    leax      >StrModeWPlus,PC point to the file mode
                    pshs      X         push the mode pointer
                    leax      >dpsiz,Y  point to the file name
                    pshs      X         push the name pointer
                    lbsr      fopen     open the file
                    leas      4,S       drop the arguments
                    std       <OutStream save the file handle
                    std       <LinePtr  save a copy of the file handle
                    bne       SetBufferSize skip if the open succeeded
                    leax      >MsgCantOpenMacro,PC point to the error message
                    pshs      X         push the message pointer
                    lbsr      FatalError report the error
                    leas      2,S       drop the argument
SetBufferSize       ldd       #512      buffer size of five hundred twelve
                    ldx       <OutStream load the file handle
                    std       11,X      store the buffer size
AddSymbolNode       ldd       #10       allocation size ten bytes
                    pshs      D         pass the size argument
                    lbsr      AllocMem  allocate the node
                    leas      2,S       drop the argument
                    tfr       D,U       keep the node pointer in u
                    ldd       <CurListHd load the current list head
                    std       ,U        link old head into the node
                    stu       <CurListHd make the node the new head
                    ldd       <InputPtr load the current value
                    std       2,U       save the value in the node
                    ldd       <OutStream load the name pointer
                    std       4,U       save the name pointer in the node
                    ldd       #2        push field-count argument
                    pshs      D         pass the argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      D         push a zero argument
                    pshs      D         push another zero argument
                    ldd       <OutStream load the name pointer
                    pshs      D         pass the name argument
                    lbsr      Fseek     format the definition line
                    leas      8,S       drop the arguments
                    ldd       <InputPtr reload the value
                    addd      #10       skip past the record header
                    std       ,S        save the source pointer
                    bra       PutNameTest enter the copy loop test

PutNameLoop         ldd       <OutStream load the output stream
                    pshs      D         pass the stream argument
                    ldx       2,S       load the source pointer
                    leax      1,X       advance past the character
                    stx       2,S       save the updated pointer
                    ldb       -1,X      fetch the character
                    sex                 sign extend to a word
                    pshs      D         pass the character argument
                    lbsr      PutChar   write the character to the stream
                    leas      4,S       drop the arguments
PutNameTest         ldb       [,S]      peek the next source byte
                    bne       PutNameLoop loop while non zero
                    ldd       <OutStream load the output stream
                    pshs      D         pass the stream argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      D         pass a null character
                    lbsr      PutChar   write the terminating null
                    leas      4,S       drop the arguments
                    ldx       <OutStream load the stream pointer
                    ldd       6,X       load the flag field
                    clra                clear high byte
                    andb      #32       isolate the flush flag bit
                    beq       SymDefFinish skip flush when clear
                    lbsr      MacroFileError flush the stream
SymDefFinish        leax      6,U       point to the node subfield
                    pshs      X         pass the subfield pointer
                    ldd       <OutStream load the stream pointer
                    pshs      D         pass the stream argument
                    lbsr      CurFilePos open the output record
                    leas      2,S       drop the argument
                    lbsr      StoreLong finish the output record
                    ldd       #1        return true
                    puls      PC,U,X    restore and return

EmitListLine        pshs      U         save the caller u register
                    ldb       <PassFlag load the suppress flag
                    lbne      ReturnOne2 skip line when suppressed
                    ldd       #32       space separator character
                    pshs      D         pass the separator argument
                    ldd       <LabelField load the label buffer pointer
                    pshs      D         pass the buffer argument
                    bsr       EmitField write the field and separator
                    leas      4,S       drop the arguments
                    ldd       #32       space separator character
                    pshs      D         pass the separator argument
                    ldd       <OpcodeField load the opcode buffer pointer
                    pshs      D         pass the buffer argument
                    bsr       EmitField write the field and separator
                    leas      4,S       drop the arguments
                    ldd       #13       carriage return separator
                    pshs      D         pass the separator argument
                    ldd       <SrcPtr   load the operand buffer pointer
                    pshs      D         pass the buffer argument
                    bsr       EmitField write the field and separator
                    bra       EmitLineDone finish the line

EmitField           pshs      U         save the caller u register
                    ldu       4,S       load the string argument
                    bra       EmitFieldTest enter the copy loop test

EmitFieldLoop       ldd       <OutStream load the output stream
                    pshs      D         pass the stream argument
                    ldb       ,U+       fetch the next character
                    sex                 sign extend to a word
                    pshs      D         pass the character argument
                    lbsr      PutChar   write the character to the stream
                    leas      4,S       drop the arguments
EmitFieldTest       ldb       ,U        peek the next character
                    bne       EmitFieldLoop loop while non zero
                    ldd       <OutStream load the output stream
                    pshs      D         pass the stream argument
                    ldd       8,S       load the separator character
                    pshs      D         pass the separator argument
                    lbsr      PutChar   write the separator to the stream
                    leas      4,S       drop the arguments
                    ldx       <OutStream load the stream pointer
                    ldd       6,X       load the flag field
                    clra                clear high byte
                    andb      #32       isolate the flush flag bit
                    beq       EmitFieldDone skip flush when clear
                    lbsr      MacroFileError flush the stream
EmitFieldDone       puls      PC,U      restore and return

EmitLineEnd         pshs      U         save the caller u register
                    ldb       <PassFlag load the suppress flag
                    bne       ReturnOne2 skip line when suppressed
                    ldd       <OutStream load the output stream
                    pshs      D         pass the stream argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      D         pass a null character
                    lbsr      PutChar   write the terminating null
EmitLineDone        leas      4,S       drop the arguments
ReturnOne2          ldd       #1        return true
                    puls      PC,U      restore and return

LookupSymbol        pshs      U         save the caller u register
                    ldu       <CurListHd load the list head
                    bra       LookupTest enter the search loop test

LookupCompare       ldb       [<4,S]    load the first key character
                    sex                 sign extend to a word
                    pshs      D         save the key on the stack
                    ldx       2,U       load the node record pointer
                    ldb       10,X      load the stored character
                    sex                 sign extend to a word
                    cmpd      ,S++      compare with the key character
                    bne       LookupNext advance on mismatch
                    ldd       2,U       load the node record pointer
                    addd      #10       point to the name field
                    pshs      D         pass the node name argument
                    ldd       6,S       load the search key pointer
                    pshs      D         pass the key argument
                    lbsr      strcmp    compare the two strings
                    leas      4,S       drop the arguments
                    std       -2,S      save the comparison result
                    bne       LookupNext advance on mismatch
                    tfr       U,D       return the matching node
                    puls      PC,U      restore and return

LookupNext          ldu       ,U        advance to the next node
LookupTest          stu       -2,S      test the node pointer
                    bne       LookupCompare loop while non null
                    clra                return null high byte
                    clrb                return null low byte
                    puls      PC,U      restore and return

PushContext         pshs      U         save the caller u register
                    ldd       <CtxDepth load the context depth
                    addd      #1        increment the depth
                    std       <CtxDepth save the new depth
                    subd      #1        recover the previous depth
                    pshs      D         pass the index argument
                    ldd       #10       context record size ten
                    lbsr      MulEntry  multiply for the offset
                    leax      >ContextArray,Y point to the context array
                    leax      D,X       index the entry
                    leau      ,X        keep the entry pointer
                    ldd       <CtxDepth load the context depth
                    cmpd      #8        compare with the limit
                    ble       CtxDepthOk continue when within the limit
                    leax      >MsgMacroNestDeep,PC point to the overflow message
                    pshs      X         pass the message argument
                    lbsr      FatalError report the error
                    leas      2,S       drop the argument
CtxDepthOk          ldd       <LinePtr  load the current line pointer
                    std       ,U        save it in the entry
                    leax      2,U       point to the name subfield
                    pshs      X         pass the subfield pointer
                    ldd       <LinePtr  load the line pointer
                    pshs      D         pass the line argument
                    lbsr      CurFilePos open the output record
                    leas      2,S       drop the argument
                    lbsr      StoreLong finish the output record
                    ldd       <SavedLineNo load the saved line number
                    std       6,U       save it in the entry
                    ldd       <SavedColumn load the saved column
                    std       8,U       save it in the entry
                    ldx       4,S       load the argument pointer
                    ldd       4,X       load the new line pointer
                    std       <LinePtr  set the current line pointer
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      D         push a zero argument
                    ldx       6,S       load the argument pointer
                    leax      6,X       point to the substructure
                    ldd       2,X       load the second field
                    pshs      D         pass the field argument
                    ldd       ,X        load the first field
                    pshs      D         pass the field argument
                    ldd       <LinePtr  load the line pointer
                    pshs      D         pass the line argument
                    lbsr      Fseek     format the line
                    leas      8,S       drop the arguments
                    ldd       <MacroFlag load the pass flag
                    bne       SkipLineInc skip when on the second pass
                    ldd       <LineCounter load the line counter
                    addd      #1        increment the counter
                    std       <LineCounter save the line counter
SkipLineInc         ldd       <LineCounter load the line counter
                    std       <SavedLineNo save it as the line number
                    lbsr      StoreMacroLine store the macro line
                    std       <SavedColumn save the returned column
                    ldd       #1        set the flag true
                    std       <MarkerFlag mark the active state
                    puls      PC,U      restore and return

PopContext          pshs      U         save the caller u register
                    ldd       <CtxDepth load the context depth
                    addd      #-1       decrement the depth
                    std       <CtxDepth save the new depth
                    pshs      D         pass the index argument
                    ldd       #10       context record size ten
                    lbsr      MulEntry  multiply for the offset
                    leax      >ContextArray,Y point to the context array
                    leax      D,X       index the entry
                    leau      ,X        keep the entry pointer
                    ldd       <CtxDepth load the context depth
                    bge       CtxDepthValid continue when not underflowed
                    leax      >MsgAsmMacroNest,PC point to the underflow message
                    pshs      X         pass the message argument
                    lbsr      FatalError report the error
                    leas      2,S       drop the argument
CtxDepthValid       ldd       ,U        load the saved line pointer
                    std       <LinePtr  restore the current line pointer
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      D         push a zero argument
                    leax      2,U       point to the name subfield
                    ldd       2,X       load the second field
                    pshs      D         pass the field argument
                    ldd       ,X        load the first field
                    pshs      D         pass the field argument
                    ldd       <LinePtr  load the line pointer
                    pshs      D         pass the line argument
                    lbsr      Fseek     format the line
                    leas      8,S       drop the arguments
                    ldd       6,U       load the saved line number
                    std       <SavedLineNo restore the line number
                    ldd       <SavedColumn load the current column
                    pshs      D         pass the column argument
                    lbsr      SwapMacroPtr restore the buffer
                    leas      2,S       drop the argument
                    ldd       8,U       load the saved column
                    std       <SavedColumn restore the column
                    puls      PC,U      restore and return

ExpandMacroLine     pshs      U,D       save u and value
                    lbra      ExpandStateLoop enter the state loop

InitLineBuffer      leax      >InLineBuffer,Y point to the line buffer
                    stx       <SrcPtr   set the operand buffer pointer
                    tfr       X,D       copy the pointer to d
                    std       <WritePtr set the write pointer
                    bra       ReadNextChar read the first character

ScanCharLoop2       ldd       ,S        load the current character
                    cmpd      #13       compare with carriage return
                    bne       CheckBackslash branch when not end of line
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [>WritePtr,Y] terminate the line buffer
                    ldb       <U0002    load the listing flag
                    beq       SkipLineCount skip when not listing
                    ldd       <LineNumber load the line count
                    addd      #1        increment the count
                    std       <LineNumber save the line count
SkipLineCount       ldd       #1        return true
                    puls      PC,U,X    restore and return

CheckBackslash      ldd       ,S        load the current character
                    cmpd      #92       compare with backslash
                    bne       StoreLineChar2 branch when not an escape
                    ldd       <LinePtr  load the line pointer
                    pshs      D         pass the line argument
                    lbsr      Getc      fetch the next character
                    std       ,S        save the character
                    bsr       HandleEscape handle the escape
                    leas      2,S       drop the argument
                    bra       ReadNextChar read the next character

StoreLineChar2      ldd       ,S        load the current character
                    ldx       <WritePtr load the write pointer
                    leax      1,X       advance the write pointer
                    stx       <WritePtr save the write pointer
                    stb       -1,X      store the character
ReadNextChar        ldd       <LinePtr  load the line pointer
                    pshs      D         pass the line argument
                    lbsr      Getc      fetch the next character
                    leas      2,S       drop the argument
                    std       ,S        save the character
                    bgt       ScanCharLoop2 loop while character valid
                    ldd       <CtxDepth load the context depth
                    bne       DoPopContext pop when still nested
                    clra                clear high byte
                    clrb                clear low byte
                    std       <MarkerFlag clear the active state
                    bra       ExpandDone return zero

DoPopContext        lbsr      PopContext pop the context
ExpandStateLoop     ldd       <MarkerFlag load the active state
                    lbne      InitLineBuffer loop while active
ExpandDone          clra                return zero high byte
                    clrb                return zero low byte
                    puls      PC,U,X    restore and return

HandleEscape        pshs      U         save the caller u register
                    ldd       4,S       load the escape character
                    leax      >CharClassTbl,Y point to the class table
                    leax      D,X       index the entry
                    ldb       ,X        load the class flags
                    clra                clear high byte
                    andb      #8        isolate the escape bit
                    beq       EscapeDispatch branch when not special
                    ldd       #1        flag argument one
                    pshs      D         pass the flag argument
                    ldd       6,S       load the escape character
                    pshs      D         pass the character argument
                    lbsr      GetMacroArg emit the substitution
                    leas      4,S       drop the arguments
                    puls      PC,U      restore and return

EscapeDispatch      ldx       4,S       load the escape character
                    lbra      EscapeSwitch dispatch on the character

EmitLocalLabel      ldd       4,S       load the escape character
                    ldx       <WritePtr load the write pointer
                    leax      1,X       advance the write pointer
                    stx       <WritePtr save the write pointer
                    stb       -1,X      store the character
                    ldd       <SavedLineNo load the line number
                    pshs      D         pass the line number argument
                    ldd       #100      modulus one hundred
                    lbsr      Divide32  compute the remainder
                    pshs      D         pass the value argument
                    leax      >FmtPad3,PC point to the format string
                    pshs      X         pass the format argument
                    ldd       <WritePtr load the write pointer
                    pshs      D         pass the destination argument
                    lbsr      Sprintf   format into the buffer
                    leas      6,S       drop the arguments
                    ldd       <WritePtr load the write pointer
                    addd      #3        advance past the digits
                    bra       SaveWritePtr save the write pointer

EmitParamRef        ldd       4,S       load the escape character
                    cmpd      #35       compare with a hash
                    bne       EvalParamArg branch when not a hash
                    ldb       [>SavedColumn,Y] load the argument value
                    sex                 sign extend to a word
                    bra       FormatParam format the argument

EvalParamArg        clra                clear high byte
                    clrb                clear low byte
                    pshs      D         push a zero argument
                    ldd       <LinePtr  load the line pointer
                    pshs      D         pass the line argument
                    lbsr      Getc      fetch the next character
                    std       ,S        save the character
                    lbsr      GetMacroArg evaluate the argument
                    leas      4,S       drop the arguments
FormatParam         pshs      D         pass the value argument
                    leax      >FmtPad2,PC point to the format string
                    pshs      X         pass the format argument
                    ldd       <WritePtr load the write pointer
                    pshs      D         pass the destination argument
                    lbsr      Sprintf   format into the buffer
                    leas      6,S       drop the arguments
                    ldd       <WritePtr load the write pointer
                    addd      #2        advance past the digits
SaveWritePtr        std       <WritePtr save the write pointer
                    bra       HandleEscapeDone finish the escape

StoreEscapeChar     ldd       4,S       load the escape character
                    ldx       <WritePtr load the write pointer
                    leax      1,X       advance the write pointer
                    stx       <WritePtr save the write pointer
                    stb       -1,X      store the character
                    bra       HandleEscapeDone finish the escape

EscapeSwitch        cmpx      #64       compare with the at sign
                    lbeq      EmitLocalLabel emit a local label
                    cmpx      #76       compare with capital l
                    beq       EmitParamRef emit a parameter reference
                    cmpx      #108      compare with lowercase l
                    lbeq      EmitParamRef emit a parameter reference
                    cmpx      #35       compare with a hash
                    lbeq      EmitParamRef emit a parameter reference
                    bra       StoreEscapeChar store the character literally

HandleEscapeDone    puls      PC,U      restore and return

StoreMacroLine      pshs      U,Y,X,D   save u and locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       2,S       clear the local counter
                    ldd       #59       semicolon delimiter
                    std       ,S        save the delimiter local
                    ldd       <FreeListHd load the free list head
                    beq       AllocMacroRecord allocate when empty
                    ldu       <FreeListHd load the free record
                    ldd       [>FreeListHd,Y] load the next free pointer
                    std       <FreeListHd unlink the record
                    bra       InitMacroRecord initialise the record

AllocMacroRecord    ldd       #61       record size sixty-one
                    pshs      D         pass the size argument
                    lbsr      AllocMem  allocate the record
                    leas      2,S       drop the argument
                    tfr       D,U       keep the record pointer
InitMacroRecord     lbsr      SkipSpaces initialise the record
                    ldd       <SrcPtr   load the source pointer
                    std       <OperandPtr save the scan pointer
                    ldd       #1        set the flag true
                    std       <Marker2Flag mark the quote state
                    tfr       U,D       copy the record pointer
                    leau      1,U       advance the write pointer
                    std       4,S       save the record base
                    ldb       [>SrcPtr,Y] load the first character
                    lbeq      EmitArgTerminator finish when the line is empty
                    leas      -2,S      reserve local space
                    lbra      ArgCopyLoop enter the scan loop

ScanMacroChar       ldb       [>SrcPtr,Y] load the current character
                    sex                 sign extend to a word
                    tfr       D,X       move to the index register
                    lbra      ClassifyArgByte dispatch on the character

EndMacroField       clra                clear high byte
                    clrb                clear low byte
                    stb       ,U+       store a terminating null
                    ldd       4,S       load the record base
                    addd      #1        advance the pointer
                    std       4,S       save the record base
                    ldd       <SrcPtr   load the source pointer
                    addd      #1        advance the pointer
                    std       <SrcPtr   save the source pointer
                    lbra      ArgByteNext continue scanning

ReturnMacroRecord   leax      8,S       point to the saved record
                    lbra      ArgFinish return the record

ScanQuoted          ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the source pointer
                    ldb       -1,X      fetch the character
                    stb       1,S       save the quote delimiter
                    bra       QuoteNextChar read the next character

QuoteEscape         ldb       ,S        load the current character
                    cmpb      #'\       compare with backslash
                    bne       StoreQuoteChar branch when not an escape
                    ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the source pointer
                    ldb       -1,X      fetch the escaped character
                    stb       ,S        save the character
StoreQuoteChar      ldb       ,S        load the current character
                    stb       ,U+       store it into the record
QuoteNextChar       ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance past the character
                    stx       <SrcPtr   save the source pointer
                    ldb       -1,X      fetch the next character
                    stb       ,S        save the character
                    beq       QuoteClosed stop at end of string
                    ldb       ,S        load the current character
                    sex                 sign extend to a word
                    pshs      D         save the character on the stack
                    ldb       3,S       load the quote delimiter
                    sex                 sign extend to a word
                    cmpd      ,S++      compare with the delimiter
                    bne       QuoteEscape loop until the delimiter
QuoteClosed         ldb       ,S        load the closing character
                    bne       ArgByteNext if not matched continue the argument scan
                    leax      >MsgUnmatchedQuotes,PC point to the unmatched-quotes message
                    pshs      X         push the message argument
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
                    bra       ArgByteNext resume the argument scan

BackslashEscape     ldd       <SrcPtr   load the source pointer
                    addd      #1        advance past the backslash
                    std       <SrcPtr   save the updated pointer
CopyArgByte         ldx       <SrcPtr   load the source pointer
                    leax      1,X       advance one byte
                    stx       <SrcPtr   save the updated pointer
                    ldb       -1,X      fetch the current byte
                    stb       ,U+       copy the byte to the output buffer
                    bra       ArgByteNext continue the argument scan

ClassifyArgByte     cmpx      #44       is the byte a comma
                    lbeq      EndMacroField yes end this argument
                    cmpx      #32       is it a space
                    lbeq      ReturnMacroRecord yes handle the whitespace
                    cmpx      #39       is it a single quote
                    lbeq      ScanQuoted yes handle the quoted text
                    cmpx      #34       is it a double quote
                    lbeq      ScanQuoted yes handle the quoted text
                    cmpx      #92       is it a backslash
                    beq       BackslashEscape yes copy the escaped byte
                    bra       CopyArgByte otherwise copy the byte verbatim

ArgByteNext         ldd       2,S       load the remaining length count
                    addd      #-1       decrement it
                    std       2,S       save the updated count
ArgCopyLoop         ldd       2,S       load the remaining count
                    beq       ArgCopyDone done when the count reaches zero
                    ldb       [>SrcPtr,Y] read the next source byte
                    stb       ,S        save the byte
                    beq       ArgCopyDone done at end of the string
                    ldb       ,S        reload the byte
                    cmpb      #32       is it a space
                    lbne      ScanMacroChar no keep scanning the argument
ArgCopyDone         ldd       4,S       load the argument count
                    addd      #1        increment it
                    std       4,S       save the updated count
                    leas      2,S       drop the local
                    bra       EmitArgTerminator emit the terminator

ArgFinish           leas      -6,X      unwind the stack frame
EmitArgTerminator   clra                clear the high byte
                    clrb                clear the low byte
                    stb       ,U        null-terminate the argument
                    ldd       ,S        load the argument length
                    bne       ArgLenOk  skip the error if nonzero
                    leax      >MsgArgTooLong,PC point to the arg-too-long message
                    pshs      X         push the message argument
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
ArgLenOk            ldd       2,S       load the argument count
                    cmpd      #9        more than nine arguments
                    ble       ArgReturn no continue
                    leax      >MsgTooManyArgs,PC point to the too-many-args message
                    pshs      X         push the message argument
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
ArgReturn           ldd       2,S       load the result value
                    stb       [<4,S]    store the byte through the result pointer
                    ldd       4,S       load the return value
                    leas      6,S       discard the locals
                    puls      PC,U      restore and return

SwapMacroPtr        pshs      U         save the caller u register
                    ldd       <FreeListHd load the current macro pointer
                    std       [<4,S]    store the old value through the pointer
                    ldd       4,S       load the new pointer argument
                    std       <FreeListHd install the new macro pointer
                    puls      PC,U      restore and return

GetMacroArg         pshs      U,D       save u and value
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        initialize the local counter
                    ldd       6,S       load the argument number
                    subd      #48       convert the ascii digit to a value
                    std       6,S       save the argument index
                    ble       GetMacroArgDone return if not positive
                    ldu       <SavedColumn load the argument storage pointer
                    ldb       ,U        fetch the first stored count
                    sex                 sign-extend to a word
                    cmpd      6,S       compare against the requested index
                    blt       NoParamErr too few report the missing parameter
                    leau      1,U       skip the count byte
                    bra       SkipArgLoop enter the skip loop

SkipStringLoop      ldb       ,U+       scan past this argument string
                    bne       SkipStringLoop until the terminator
SkipArgLoop         ldd       6,S       load the remaining index
                    addd      #-1       decrement it
                    std       6,S       save the updated index
                    lbgt      SkipStringLoop keep skipping arguments
                    bra       CopyArgTest position reached copy it

CopyArgLoop         ldd       8,S       load the copy-enable flag
                    beq       CopyArgNext skip the store when disabled
                    ldb       ,U        fetch the argument byte
                    ldx       <WritePtr load the output pointer
                    leax      1,X       advance it
                    stx       <WritePtr save the updated pointer
                    stb       -1,X      store the byte
CopyArgNext         leau      1,U       advance the source pointer
                    ldd       ,S        load the byte counter
                    addd      #1        increment it
                    std       ,S        save the updated counter
CopyArgTest         ldb       ,U        fetch the current byte
                    bne       CopyArgLoop loop until the terminator
                    bra       GetMacroArgDone done copying the argument

NoParamErr          leax      >MsgNoParamForArg,PC point to the no-param message
                    pshs      X         push the message argument
                    lbsr      EmitMessageLine report the error
                    leas      2,S       drop the argument
GetMacroArgDone     ldd       ,S        load the byte count result
                    puls      PC,U,X    restore and return

CloseMacroFile      pshs      U         save the caller u register
                    ldd       <OutStream load the macro work file pointer
                    pshs      D         push it as the argument
                    lbsr      fclose    close the work file
                    leas      2,S       drop the argument
                    leax      >dpsiz,Y  point to the work file name
                    pshs      X         push it as the argument
                    lbsr      unlink    delete the work file
                    puls      PC,U,X    restore and return

MacroFileError      pshs      U         save the caller u register
                    leax      >MsgMacroFileError,PC point to the macro-file-error message
                    pshs      X         push the message argument
                    lbsr      FatalError report the fatal error
                    puls      PC,U,X    restore and return

StrModeWPlus        fcc       "w+"
                    fcb       C$NULL
MsgCantOpenMacro    fcc       "can't open macro work file"
                    fcb       C$NULL
MsgMacroNestDeep    fcc       "macro nesting too deep"
                    fcb       C$NULL
MsgAsmMacroNest     fcc       "asm err: macro nest"
                    fcb       C$NULL
FmtPad3             fcc       "%03d"
                    fcb       C$NULL
FmtPad2             fcc       "%02d"
                    fcb       C$NULL
MsgUnmatchedQuotes  fcc       "unmatched quotes"
                    fcb       C$NULL
MsgArgTooLong       fcc       "macro arg too long"
                    fcb       C$NULL
MsgTooManyArgs      fcc       "too many args"
                    fcb       C$NULL
MsgNoParamForArg    fcc       "no param for arg"
                    fcb       C$NULL
MsgMacroFileError   fcc       "macro file error"
                    fcb       C$NULL

* fopen

FindFreeStream      pshs      U         save the caller u register
                    leau      >_iob,Y   point to the stream table
FindFreeLoop        ldd       6,U       load the stream flags
                    clra                clear the high byte
                    andb      #3        mask the in-use bits
                    lbeq      ReturnStream free slot found return it
                    leau      13,U      advance to the next stream
                    pshs      U         save the pointer
                    leax      >argv,Y   Should be _iob+208,y
                    cmpx      ,S++      past the end of the table
                    bhi       FindFreeLoop keep searching
                    ldd       #200      prepare the too-many-files error
                    std       >errno,Y  set errno
                    lbra      ReturnNull return null

                    puls      PC,U      restore and return

InitStream          pshs      U         save the caller u register
                    ldu       8,S       load the supplied stream pointer
                    bne       GotStream use it if given
                    bsr       FindFreeStream allocate a free stream
                    tfr       D,U       keep the stream pointer
GotStream           stu       -2,S      save the stream pointer
                    beq       ReturnNull return null if none
                    ldd       4,S       load the file descriptor
                    std       8,U       store the descriptor in the stream
                    ldx       6,S       load the mode string pointer
                    ldb       1,X       fetch the second mode character
                    cmpb      #'+       is it a plus
                    beq       ModeReadWrite yes read-write mode
                    ldx       6,S       reload the mode string
                    ldb       2,X       fetch the third mode character
                    cmpb      #'+       is it a plus
                    bne       ModeSingle no single-direction mode
ModeReadWrite       ldd       6,U       load the stream flags
                    orb       #3        set the read-write bits
                    bra       StoreStreamFlags store the flags

ModeSingle          ldd       6,U       load the stream flags
                    pshs      D         save them
                    ldb       [<8,S]    fetch the first mode character
                    cmpb      #'r       is it 'r'
                    beq       ModeReadFlag yes read mode
                    ldb       [<8,S]    fetch the first mode character
                    cmpb      #'d       is it 'd'
                    bne       ModeWriteFlag no write mode
ModeReadFlag        ldd       #1        read-only flag
                    bra       ModeCombine combine the flags

ModeWriteFlag       ldd       #2        write-only flag
ModeCombine         ora       ,S+       merge the saved high flags
                    orb       ,S+       merge the saved low flags
StoreStreamFlags    std       6,U       store the stream flags
                    ldd       2,U       load the buffer base
                    addd      11,U      add the buffer size
                    std       4,U       set the buffer end pointer
                    std       ,U        set the current pointer
ReturnStream        tfr       U,D       return the stream pointer
                    puls      PC,U      restore and return

ReturnNull          clra                clear the high byte
                    clrb                return null
                    puls      PC,U      restore and return

OpenForMode         pshs      U         save the caller u register
                    ldu       4,S       load the mode string pointer
                    leas      -4,S      make room for locals
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        initialize the flags local
                    ldx       10,S      load the mode string pointer
                    ldb       1,X       fetch the second mode character
                    sex                 sign-extend to a word
                    tfr       D,X       move it into X
                    bra       ModeScanLoop test the character

CheckPlusMode       ldx       10,S      load the mode string pointer
                    ldb       2,X       fetch the third mode character
                    cmpb      #'+       is it a plus
                    bne       NoPlusMode no binary update only
                    ldd       #7        read-write-create flags
                    bra       SetOpenFlags set the flags

NoPlusMode          ldd       #4        write flag
                    bra       SetOpenFlags set the flags

PlusModeFlag        ldd       #3        read-write flags
SetOpenFlags        std       ,S        save the open flags
                    bra       GetPrimaryMode read the primary mode character

BadModeChar         leax      4,S       point past the locals
                    lbra      BadModeUnwind report the bad mode

ModeScanLoop        stx       -2,S      save the mode character
                    beq       GetPrimaryMode done if terminator
                    cmpx      #120      is it 'x'
                    beq       CheckPlusMode yes check for a plus
                    cmpx      #43       is it a plus
                    beq       PlusModeFlag yes read-write
                    bra       BadModeChar otherwise bad mode

GetPrimaryMode      ldb       [<10,S]   fetch the primary mode character
                    sex                 sign-extend to a word
                    tfr       D,X       move it into X
                    lbra      DispatchMode dispatch on the mode

ModeRead2           ldd       ,S        load the open flags
                    orb       #1        set the read bit
                    bra       OpenWithFlags open the file

ModeAppend          ldd       ,S        load the open flags
                    orb       #2        set the write bit
                    pshs      D         push the open flags
                    pshs      U         push the file name
                    lbsr      open      open the existing file
                    leas      4,S       drop the arguments
                    std       2,S       save the descriptor
                    cmpd      #-1       did the open fail
                    beq       ModeWrite2 yes create the file
                    ldd       #2        seek-from-end whence
                    pshs      D         push the whence
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push the offset high word
                    pshs      D         push the offset low word
                    ldd       8,S       load the descriptor
                    pshs      D         push it
                    lbsr      lseek     seek to the end of the file
                    leas      8,S       drop the arguments
                    bra       OpenSuccess return the descriptor

ModeWrite2          ldd       ,S        load the open flags
                    orb       #2        set the write bit
                    pshs      D         push the open flags
                    pshs      U         push the file name
                    lbsr      creat     create the file
                    bra       StoreDescriptor store the descriptor

ModeUpdate          ldd       ,S        load the open flags
                    orb       #129      set the directory update bits
OpenWithFlags       pshs      D         push the open flags
                    pshs      U         push the file name
                    lbsr      open      open the file
StoreDescriptor     leas      4,S       drop the arguments
                    std       2,S       save the descriptor
                    bra       OpenSuccess return the descriptor

BadModeUnwind       leas      -4,X      unwind the stack frame
ModeError           ldd       #203      prepare the bad-mode error
                    std       >errno,Y  set errno
                    clra                clear the high byte
                    clrb                clear the low byte
                    bra       OpenReturn return failure

DispatchMode        cmpx      #114      is the mode 'r'
                    lbeq      ModeRead2 yes open for reading
                    cmpx      #97       is the mode 'a'
                    lbeq      ModeAppend yes open for append
                    cmpx      #119      is the mode 'w'
                    beq       ModeWrite2 yes create for writing
                    cmpx      #100      is the mode 'd'
                    beq       ModeUpdate yes open the directory
                    bra       ModeError otherwise bad mode

OpenSuccess         ldd       2,S       load the descriptor
OpenReturn          leas      4,S       drop the locals
                    puls      PC,U      restore and return

fdopen              pshs      U         save the caller u register
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      D         push a null stream
                    ldd       8,S       load the mode argument
                    pshs      D         push it
                    ldd       8,S       load the descriptor argument
                    pshs      D         push it
                    lbra      InitStreamCall initialize the stream

fopen               pshs      U         save the caller u register
                    ldd       6,S       load the mode string
                    pshs      D         push it
                    ldd       6,S       load the file name
                    pshs      D         push it
                    lbsr      OpenForMode open the file
                    leas      4,S       drop the arguments
                    tfr       D,U       keep the descriptor
                    cmpu      #-1       did the open fail
                    bne       FopenGotFile no continue
                    clra                clear the high byte
                    clrb                return null
                    bra       DoReturn  return

FopenGotFile        clra                clear the high byte
                    clrb                clear the low byte
                    bra       FopenFinish initialize the stream

freopen             pshs      U         save the caller u register
                    ldd       8,S       load the existing stream
                    pshs      D         push it
                    lbsr      fclose    close the old stream
                    leas      2,S       drop the argument
                    ldd       6,S       load the mode string
                    pshs      D         push it
                    ldd       6,S       load the file name
                    pshs      D         push it
                    lbsr      OpenForMode open the file
                    leas      4,S       drop the arguments
                    tfr       D,U       keep the descriptor
                    stu       -2,S      save it
                    bge       FreopenGotFile continue if the open succeeded
                    clra                clear the high byte
                    clrb                return null
                    bra       DoReturn  return

FreopenGotFile      ldd       8,S       load the stream pointer
FopenFinish         pshs      D         push the stream
                    ldd       8,S       load the mode string
                    pshs      D         push it
                    pshs      U         push the descriptor
InitStreamCall      lbsr      InitStream initialize the stream
                    leas      6,S       drop the arguments
DoReturn            puls      PC,U      restore and return

                    pshs      U         save the caller u register
                    leax      >OutBuffer,Y point to the output stream
                    pshs      X         push the stream
                    ldd       6,S       load the string argument
                    pshs      D         push it
                    bsr       Fputs     write the string
                    leas      4,S       drop the arguments
                    leax      >OutBuffer,Y point to the output stream
                    pshs      X         push the stream
                    ldd       #13       carriage return
                    pshs      D         push it
                    lbsr      PutChar   write the newline
                    leas      4,S       drop the arguments
                    puls      PC,U      restore and return

Fputs               pshs      U         save the caller u register
                    ldu       4,S       load the string pointer
                    leas      -1,S      make room for a byte
                    bra       FputsNext read the first byte

FputsWrite          ldd       7,S       load the stream pointer
                    pshs      D         push it
                    ldb       2,S       load the current byte
                    sex                 sign-extend to a word
                    pshs      D         push it
                    lbsr      PutChar   write the byte
                    leas      4,S       drop the arguments
FputsNext           ldb       ,U+       fetch the next string byte
                    stb       ,S        save it
                    bne       FputsWrite write it unless terminator
                    leas      1,S       drop the byte
                    puls      PC,U      restore and return

Fwrite              pshs      U         save the caller u register
                    ldu       4,S       load the buffer pointer
                    leas      -4,S      make room for locals
                    clra                clear the high byte
                    clrb                clear the low byte
                    bra       FwriteNextItem enter the outer loop

FwriteItem          clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        reset the inner counter
                    bra       FwriteCount test the inner count

FwriteByte          ldd       14,S      load the stream pointer
                    pshs      D         push it
                    ldb       ,U+       fetch the next buffer byte
                    sex                 sign-extend to a word
                    pshs      D         push it
                    lbsr      PutChar   write the byte
                    leas      4,S       drop the arguments
                    ldx       14,S      load the stream pointer
                    ldd       6,X       load the stream flags
                    clra                clear the high byte
                    andb      #32       test the error bit
                    bne       FwriteDone stop on a write error
FwriteCount         ldd       ,S        load the inner counter
                    addd      #1        increment it
                    std       ,S        save it
                    subd      #1        recover the previous value
                    cmpd      10,S      compare against the item size
                    blt       FwriteByte keep writing the item
                    ldd       2,S       load the item counter
                    addd      #1        increment it
FwriteNextItem      std       2,S       save the item counter
                    ldd       2,S       reload the item counter
                    cmpd      12,S      compare against the item count
                    blt       FwriteItem process the next item
FwriteDone          ldd       2,S       load the items-written count
                    leas      4,S       drop the locals
                    puls      PC,U      restore and return

FormatToScratch     pshs      U         save the caller u register
                    leax      >OutBuffer,Y point to the scratch buffer
                    stx       >OutCursor,Y set the output cursor
                    leax      6,S       point to the variadic arguments
                    pshs      X         push the argument pointer
                    ldd       6,S       load the format string
                    bra       FormatEmit emit the formatted text

Vsprintf            pshs      U         save the caller u register
                    ldd       4,S       load the output buffer
                    std       >OutCursor,Y set the output cursor
                    leax      8,S       point to the variadic arguments
                    pshs      X         push the argument pointer
                    ldd       8,S       load the format string
FormatEmit          pshs      D         push the format string
                    leax      >PutcViaFlush,PC point to the string-output callback
                    pshs      X         push the callback
                    bsr       DoPrintf  run the formatter
                    leas      6,S       drop the arguments
                    puls      PC,U      restore and return

Sprintf             pshs      U         save the caller u register
                    ldd       4,S       load the output buffer
                    std       >OutCursor,Y set the output cursor
                    leax      8,S       point to the variadic arguments
                    pshs      X         push the argument pointer
                    ldd       8,S       load the format string
                    pshs      D         push it
                    leax      >StoreToStrBuf,PC point to the string-output callback
                    pshs      X         push the callback
                    bsr       DoPrintf  run the formatter
                    leas      6,S       drop the arguments
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       [>OutCursor,Y] null-terminate the output
                    ldd       4,S       load the output buffer
                    puls      PC,U      restore u and return from the routine

DoPrintf            pshs      U         save the caller u register
                    ldu       6,S       load the format string pointer
                    leas      -11,S     allocate the local stack frame
                    bra       ScanFmtLoop jump to read the first format character

EmitLiteralChar     ldb       8,S       reload the current character
                    lbeq      PrintfDone exit when the string terminator is reached
                    ldb       8,S       reload the character
                    sex                 sign-extend the character
                    pshs      D         push the character argument
                    jsr       [<17,S]   call the output routine
                    leas      2,S       drop the pushed argument
ScanFmtLoop         ldb       ,U+       read the next format character
                    stb       8,S       save the current character
                    cmpb      #'%       is it a percent sign
                    bne       EmitLiteralChar if not, output it literally
                    ldb       ,U+       read the character after the percent
                    stb       8,S       save it
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       2,S       clear the precision
                    std       6,S       clear the field width
                    ldb       8,S       reload the flag character
                    cmpb      #45       is it a left-justify minus
                    bne       NoLeftFlag if not, skip the flag
                    ldd       #1        set the left-justify flag
                    std       >DirectOutFlag,Y store the flag
                    ldb       ,U+       read the next character
                    stb       8,S       save it
                    bra       CheckZeroPad continue after the flag

NoLeftFlag          clra                clear the high byte
                    clrb                clear the low byte
                    std       >DirectOutFlag,Y clear the left-justify flag
CheckZeroPad        ldb       8,S       reload the character
                    cmpb      #48       is it a zero pad flag
                    bne       UseSpacePad if not, use space padding
                    ldd       #48       use zero as the pad character
                    bra       SetPadChar store the pad character

UseSpacePad         ldd       #32       use space as the pad character
SetPadChar          std       >PadChar,Y store the chosen pad character
                    bra       WidthDigitTest go test for a width digit

WidthDigitLoop      ldd       6,S       load the current field width
                    pshs      D         save it
                    ldd       #10       load ten
                    lbsr      MulEntry  multiply the width by ten
                    pshs      D         save the product
                    ldb       10,S      load the current digit character
                    sex                 sign-extend it
                    addd      #-48      convert the digit to its value
                    addd      ,S++      add width times ten
                    std       6,S       store the new field width
                    ldb       ,U+       read the next character
                    stb       8,S       save it
WidthDigitTest      ldb       8,S       load the current character
                    sex                 sign-extend it
                    leax      >CharClassTbl,Y point at the character class table
                    leax      D,X       index by the character
                    ldb       ,X        load its class flags
                    clra                clear the high byte
                    andb      #8        test the digit class flag
                    bne       WidthDigitLoop loop while the character is a digit
                    ldb       8,S       load the current character
                    cmpb      #'.       is it a period for precision
                    bne       NoPrecision if not, no precision was given
                    ldd       #1        load one
                    std       4,S       mark precision as present
                    bra       PrecDigitTest go read the precision digits

PrecDigitLoop       ldd       2,S       load the current precision
                    pshs      D         save it
                    ldd       #10       load ten
                    lbsr      MulEntry  multiply the precision by ten
                    pshs      D         save the product
                    ldb       10,S      load the current digit character
                    sex                 sign-extend it
                    addd      #-48      convert the digit to its value
                    addd      ,S++      add precision times ten
                    std       2,S       store the new precision
PrecDigitTest       ldb       ,U+       read the next character
                    stb       8,S       save it
                    ldb       8,S       reload the character
                    sex                 sign-extend it
                    leax      >CharClassTbl,Y point at the character class table
                    leax      D,X       index by the character
                    ldb       ,X        load its class flags
                    clra                clear the high byte
                    andb      #8        test the digit class flag
                    bne       PrecDigitLoop loop while the character is a digit
                    bra       LoadConvChar precision parsing complete

NoPrecision         clra                clear the high byte
                    clrb                clear the low byte
                    std       4,S       clear the precision-present flag
LoadConvChar        ldb       8,S       load the conversion character
                    sex                 sign-extend it
                    tfr       D,X       move it to x for dispatch
                    lbra      DispatchConv dispatch on the conversion type

FmtDecimal          ldd       6,S       load the field width
                    pshs      D         push the width argument
                    ldx       <21,S     load the variadic argument pointer
                    leax      2,X       advance past the argument
                    stx       <21,S     store the updated pointer
                    ldd       -2,X      fetch the integer argument
                    pshs      D         push it
                    lbsr      IntToDecStr convert signed integer to decimal
                    bra       StoreIntResult go store the result

FmtOctal            ldd       6,S       load the field width
                    pshs      D         push the width argument
                    ldx       <21,S     load the variadic argument pointer
                    leax      2,X       advance past the argument
                    stx       <21,S     store the updated pointer
                    ldd       -2,X      fetch the integer argument
                    pshs      D         push it
                    lbsr      UIntToOctStr convert to an octal string
StoreIntResult      std       ,S        save the result pointer
                    lbra      EmitResult go emit the result

FmtHex              ldd       6,S       load the field width
                    pshs      D         push the width argument
                    ldb       10,S      load the conversion character
                    sex                 sign-extend it
                    leax      >CharClassTbl,Y point at the character class table
                    leax      D,X       index by the character
                    ldb       ,X        load its class flags
                    clra                clear the high byte
                    andb      #2        test the uppercase class flag
                    pshs      D         push the case flag
                    ldx       <23,S     load the variadic argument pointer
                    leax      2,X       advance past the argument
                    stx       <23,S     store the updated pointer
                    ldd       -2,X      fetch the integer argument
                    pshs      D         push it
                    lbsr      UIntToHexStr convert to a hex string
                    lbra      DropTwoArgs clean up and emit

FmtUnsigned         ldd       6,S       load the field width
                    pshs      D         push the width argument
                    ldx       <21,S     load the variadic argument pointer
                    leax      2,X       advance past the argument
                    stx       <21,S     store the updated pointer
                    ldd       -2,X      fetch the integer argument
                    pshs      D         push it
                    leax      >ConvBuffer,Y point at the conversion buffer
                    pshs      X         push the buffer pointer
                    lbsr      UIntToDecStr convert unsigned integer to decimal
                    lbra      DropTwoArgs clean up and emit

FmtFloat            ldd       4,S       load the precision-present flag
                    bne       DoFloatFormat keep the precision when given
                    ldd       #6        default precision of six
                    std       2,S       store it
DoFloatFormat       ldd       6,S       load the field width
                    pshs      D         push the width argument
                    leax      <21,S     point at the argument pointer
                    pshs      X         push its address
                    ldd       6,S       load the precision
                    pshs      D         push it
                    ldb       14,S      load the conversion character
                    sex                 sign-extend it
                    pshs      D         push it
                    lbsr      ReturnEmptyStr format the floating-point value
                    leas      6,S       drop the arguments
                    lbra      PushResult emit the result

FmtChar             ldx       <19,S     load the variadic argument pointer
                    leax      2,X       advance past the argument
                    stx       <19,S     store the updated pointer
                    ldd       -2,X      fetch the character argument
                    lbra      OutputChar output the character

FmtString           ldx       <19,S     load the variadic argument pointer
                    leax      2,X       advance past the argument
                    stx       <19,S     store the updated pointer
                    ldd       -2,X      fetch the string pointer
                    std       9,S       save the current string pointer
                    ldd       4,S       load the precision-present flag
                    beq       EmitStringPlain if none, emit the whole string
                    ldd       9,S       load the string pointer
                    std       4,S       save it as the scan pointer
                    bra       StrScanTest begin scanning the string

StrScanLoop         ldb       [<9,S]    load the character at the string pointer
                    beq       EmitStringPadded stop at the null terminator
                    ldd       9,S       load the string pointer
                    addd      #1        advance one character
                    std       9,S       store it
StrScanTest         ldd       2,S       load the remaining precision
                    addd      #-1       decrement it
                    std       2,S       store it
                    subd      #-1       test the pre-decrement value
                    bne       StrScanLoop loop while characters remain
EmitStringPadded    ldd       6,S       load the field width
                    pshs      D         push the width argument
                    ldd       11,S      load the original string pointer
                    subd      6,S       compute the string length
                    pshs      D         push the length
                    ldd       8,S       load the precision
                    pshs      D         push it
                    ldd       <21,S     load the scan pointer
                    pshs      D         push it
                    lbsr      EmitPadded emit the string with padding
                    leas      8,S       drop the arguments
                    bra       BackToScan back to the format loop

EmitStringPlain     ldd       6,S       load the field width
                    pshs      D         push the width argument
                    ldd       11,S      load the string pointer
                    bra       PushResult emit the string

FmtLong             ldb       ,U+       read the character after the l modifier
                    stb       8,S       save the conversion character
                    bra       DoLongFormat go format the long value

                    leas      -11,X     unreachable filler bytes
DoLongFormat        ldd       6,S       load the field width
                    pshs      D         push the width argument
                    leax      <21,S     point at the argument pointer
                    pshs      X         push its address
                    ldb       12,S      load the conversion character
                    sex                 sign-extend it
                    pshs      D         push it
                    lbsr      SelectConvStr format the long integer
DropTwoArgs         leas      4,S       drop two arguments
PushResult          pshs      D         push the result pointer
EmitResult          ldd       <19,S     load the field width for padding
                    pshs      D         push it
                    lbsr      PutSignedField emit the converted digits with padding
                    leas      6,S       drop the arguments
BackToScan          lbra      ScanFmtLoop back to the format loop

DefaultConv         ldb       8,S       load the conversion character
                    sex                 sign-extend it
OutputChar          pshs      D         push the character argument
                    jsr       [<17,S]   call the output routine
                    leas      2,S       drop the argument
                    lbra      ScanFmtLoop back to the format loop

DispatchConv        cmpx      #100      is it the d decimal conversion
                    lbeq      FmtDecimal handle signed decimal
                    cmpx      #111      is it the o octal conversion
                    lbeq      FmtOctal  handle octal
                    cmpx      #120      is it the x hex conversion
                    lbeq      FmtHex    handle hexadecimal
                    cmpx      #88       is it the X hex conversion
                    lbeq      FmtHex    handle hexadecimal
                    cmpx      #117      is it the u unsigned conversion
                    lbeq      FmtUnsigned handle unsigned decimal
                    cmpx      #102      is it the f float conversion
                    lbeq      FmtFloat  handle floating point
                    cmpx      #101      is it the e float conversion
                    lbeq      FmtFloat  handle floating point
                    cmpx      #103      is it the g float conversion
                    lbeq      FmtFloat  handle floating point
                    cmpx      #69       is it the E float conversion
                    lbeq      FmtFloat  handle floating point
                    cmpx      #71       is it the G float conversion
                    lbeq      FmtFloat  handle floating point
                    cmpx      #99       is it the c character conversion
                    lbeq      FmtChar   handle a character
                    cmpx      #115      is it the s string conversion
                    lbeq      FmtString handle a string
                    cmpx      #108      is it the l long modifier
                    lbeq      FmtLong   handle the long modifier
                    bra       DefaultConv otherwise output the character verbatim

PrintfDone          leas      11,S      release the local frame
                    puls      PC,U      restore u and return

IntToDecStr         pshs      U,D       save u and make local space
                    leax      >ConvBuffer,Y point at the output buffer
                    stx       ,S        save the buffer write pointer
                    ldd       6,S       load the value
                    bge       ConvMagnitude skip sign handling if non-negative
                    ldd       6,S       reload the value
                    nega                negate the high byte
                    negb                negate the low byte
                    sbca      #0        complete the negation
                    std       6,S       store the absolute value
                    bge       PutMinusSign if now non-negative, add a minus sign
                    leax      >MsgMinInt,PC point at the overflow text
                    pshs      X         push it
                    leax      >ConvBuffer,Y point at the output buffer
                    pshs      X         push the destination
                    lbsr      strcpy    copy the overflow string
                    leas      4,S       drop the arguments
                    puls      PC,U,X    return the buffer pointer

PutMinusSign        ldd       #45       load a minus sign
                    ldx       ,S        load the buffer pointer
                    leax      1,X       advance it
                    stx       ,S        store the updated pointer
                    stb       -1,X      write the minus sign
ConvMagnitude       ldd       6,S       load the absolute value
                    pshs      D         push it
                    ldd       2,S       load the buffer pointer
                    pshs      D         push it
                    bsr       UIntToDecStr convert the magnitude to decimal
                    leas      4,S       drop the arguments
                    leax      >ConvBuffer,Y point at the output buffer
                    tfr       X,D       return the buffer pointer
                    puls      PC,U,X    restore and return

UIntToDecStr        pshs      U,Y,X,D   save registers and make local space
                    ldu       10,S      load the output buffer pointer
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       2,S       clear the output-started flag
                    clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        clear the digit counter
                    bra       HighDigitTest begin scaling the value

HighDigitLoop       ldd       ,S        load the digit count
                    addd      #1        increment it
                    std       ,S        store it
                    ldd       12,S      load the working value
                    subd      >PowTenTbl,Y subtract the power of ten
                    std       12,S      store the remainder
HighDigitTest       ldd       12,S      load the working value
                    blt       HighDigitLoop keep counting this digit
                    leax      >PowTenTbl,Y point at the powers-of-ten table
                    stx       4,S       save the table pointer
                    bra       PowerTenTest begin emitting digits

CountDigitLoop      ldd       ,S        load the digit value
                    addd      #1        increment it
                    std       ,S        store it
SubPowLoop          ldd       12,S      load the working value
                    subd      [<4,S]    subtract the current power of ten
                    std       12,S      store it back
                    bge       CountDigitLoop loop while still non-negative
                    ldd       12,S      load the working value
                    addd      [<4,S]    add the power of ten back
                    std       12,S      restore the value
                    ldd       ,S        load the digit value
                    beq       CheckDigitStart skip when the digit is zero
                    ldd       #1        load one
                    std       2,S       mark that output has started
CheckDigitStart     ldd       2,S       load the output-started flag
                    beq       NextPowerTen skip a leading zero digit
                    ldd       ,S        load the digit value
                    addd      #48       convert it to ascii
                    stb       ,U+       write the digit to the buffer
NextPowerTen        clra                clear the high byte
                    clrb                clear the low byte
                    std       ,S        reset the digit value
                    ldd       4,S       load the table pointer
                    addd      #2        advance to the next power of ten
                    std       4,S       store it
PowerTenTest        ldd       4,S       load the table pointer
                    cmpd      >Y0484,Y  compare against the table end
                    bne       SubPowLoop loop over the remaining powers
                    ldd       12,S      load the final remainder
                    addd      #48       convert the last digit to ascii
                    stb       ,U+       write it
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       ,U        terminate the string
                    ldd       10,S      return the buffer pointer
                    leas      6,S       drop the locals
                    puls      PC,U      restore and return

UIntToOctStr        pshs      U,D       save u and the value
                    leax      >ConvBuffer,Y point at the output buffer
                    stx       ,S        save the buffer pointer
                    leau      >DigitBuffer,Y point at the scratch digit buffer
OctDigitLoop        ldd       6,S       load the value
                    clra                clear the high byte
                    andb      #7        take the low octal digit
                    addd      #48       convert it to ascii
                    stb       ,U+       store the digit in scratch
                    ldd       6,S       load the value
                    lsra                shift the value right one bit
                    rorb                rotate carry into the low byte
                    lsra                shift right again
                    rorb                rotate through
                    lsra                shift right a third time
                    rorb                divide the value by eight
                    std       6,S       store the shifted value
                    bne       OctDigitLoop loop until the value is zero
                    bra       OctCopyTest begin copying digits in order

OctCopyLoop         ldb       ,U        load a digit from scratch
                    ldx       ,S        load the output pointer
                    leax      1,X       advance it
                    stx       ,S        store it
                    stb       -1,X      copy the digit to the output
OctCopyTest         leau      -1,U      step back through scratch
                    pshs      U         save the scratch pointer
                    leax      >DigitBuffer,Y point at the scratch start
                    cmpx      ,S++      compare with the scratch pointer
                    bls       OctCopyLoop loop while digits remain
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       [,S]      terminate the output string
                    leax      >ConvBuffer,Y point at the output buffer
                    tfr       X,D       return the buffer pointer
                    puls      PC,U,X    restore and return

UIntToHexStr        pshs      U,X,D     save registers and make local space
                    leax      >ConvBuffer,Y point at the output buffer
                    stx       2,S       save the buffer pointer
                    leau      >DigitBuffer,Y point at the scratch digit buffer
HexDigitLoop        ldd       8,S       load the value
                    clra                clear the high byte
                    andb      #15       take the low hex nibble
                    std       ,S        save the nibble
                    pshs      D         push it
                    ldd       2,S       reload the nibble
                    cmpd      #9        is it above nine
                    ble       DigitZeroBase if not, use the digit base
                    ldd       12,S      load the case flag
                    beq       LowercaseBase use lowercase when clear
                    ldd       #65       use the uppercase A base
                    bra       AdjustHexAF skip the lowercase base

LowercaseBase       ldd       #97       use the lowercase a base
AdjustHexAF         addd      #-10      adjust for the a-f range
                    bra       AddNibble add the nibble value

DigitZeroBase       ldd       #48       use the zero digit base
AddNibble           addd      ,S++      add the nibble value
                    stb       ,U+       store the hex digit in scratch
                    ldd       8,S       load the value
                    lsra                shift the value right
                    rorb                rotate through
                    lsra                shift right again
                    rorb                rotate through
                    lsra                shift right a third time
                    rorb                rotate through
                    lsra                shift right a fourth time
                    rorb                divide the value by sixteen
                    anda      #15       mask off the shifted-in bits
                    std       8,S       store the shifted value
                    bne       HexDigitLoop loop until the value is zero
                    bra       HexCopyTest begin copying digits in order

HexCopyLoop         ldb       ,U        load a digit from scratch
                    ldx       2,S       load the output pointer
                    leax      1,X       advance it
                    stx       2,S       store it
                    stb       -1,X      copy the digit to the output
HexCopyTest         leau      -1,U      step back through scratch
                    pshs      U         save the scratch pointer
                    leax      >DigitBuffer,Y point at the scratch start
                    cmpx      ,S++      compare with the scratch pointer
                    bls       HexCopyLoop loop while digits remain
                    clra                clear the high byte
                    clrb                clear the low byte
                    stb       [<2,S]    terminate the output string
                    leax      >ConvBuffer,Y point at the output buffer
                    tfr       X,D       return the buffer pointer
                    lbra      PutcDone  restore and return

EmitPadded          pshs      U         save u
                    ldu       6,S       load the string pointer argument
                    ldd       10,S      load the field width
                    subd      8,S       subtract the string length
                    std       10,S      store the pad count
                    ldd       >DirectOutFlag,Y load the left-justify flag
                    bne       PadRightLoop skip leading pad when left-justified
                    bra       PadCharTest begin the leading pad loop

PadCharLoop         ldd       >PadChar,Y load the pad character
                    pshs      D         push it
                    jsr       [<6,S]    output the pad character
                    leas      2,S       drop the argument
PadCharTest         ldd       10,S      load the remaining pad count
                    addd      #-1       decrement it
                    std       10,S      store it
                    subd      #-1       test the pre-decrement value
                    bgt       PadCharLoop loop while padding remains
                    bra       PadRightLoop begin emitting the string

EmitStrCharLoop     ldb       ,U+       load the next string character
                    sex                 sign-extend it
                    pshs      D         push it
                    jsr       [<6,S]    output the character
                    leas      2,S       drop the pushed arguments
PadRightLoop        ldd       8,S       load the loop counter
                    addd      #-1       decrement the counter
                    std       8,S       save the updated counter
                    subd      #-1       test whether it was zero
                    bne       EmitStrCharLoop repeat while nonzero
                    ldd       >DirectOutFlag,Y load the direct output flag
                    beq       FieldOutDone skip if no callback active
                    bra       FieldFillNext enter the fill loop

FieldFillLoop       ldd       >PadChar,Y load the output function pointer
                    pshs      D         push it as argument
                    jsr       [<6,S]    call the output routine
                    leas      2,S       drop the argument
FieldFillNext       ldd       10,S      load the fill count
                    addd      #-1       decrement it
                    std       10,S      store it back
                    subd      #-1       test remaining count
                    bgt       FieldFillLoop loop while positive
FieldOutDone        puls      PC,U      restore and return

PutSignedField      pshs      U         save the caller u register
                    ldu       6,S       load the argument pointer
                    ldd       8,S       load the value
                    pshs      D         push it
                    pshs      U         push the pointer
                    lbsr      strlen    convert the value to text
                    leas      2,S       drop one argument
                    nega                negate the high byte
                    negb                negate the low byte
                    sbca      #0        finish the two's complement
                    addd      ,S++      add and pop the operand
                    std       8,S       store remaining width
                    ldd       >DirectOutFlag,Y load the direct output flag
                    bne       PutStringNext branch if callback set
                    bra       LeadPadNext enter the pad loop

LeadPadLoop         ldd       >PadChar,Y load the output function pointer
                    pshs      D         push argument
                    jsr       [<6,S]    call the output routine
                    leas      2,S       drop the argument
LeadPadNext         ldd       8,S       load the pad count
                    addd      #-1       decrement it
                    std       8,S       store it back
                    subd      #-1       test remaining count
                    bgt       LeadPadLoop loop while positive
                    bra       PutStringNext proceed to emit digits

PutStringLoop       ldb       ,U+       fetch the next character
                    sex                 sign extend to a word
                    pshs      D         push as argument
                    jsr       [<6,S]    call the output routine
                    leas      2,S       drop the argument
PutStringNext       ldb       ,U        peek the current character
                    bne       PutStringLoop loop until null terminator
                    ldd       >DirectOutFlag,Y load the direct output flag
                    beq       StrFieldDone done if callback clear
                    bra       TrailPadNext enter the trailing pad

TrailPadLoop        ldd       >PadChar,Y load the output function pointer
                    pshs      D         push argument
                    jsr       [<6,S]    call the output routine
                    leas      2,S       drop the argument
TrailPadNext        ldd       8,S       load the pad count
                    addd      #-1       decrement it
                    std       8,S       store it back
                    subd      #-1       test remaining count
                    bgt       TrailPadLoop loop while positive
StrFieldDone        puls      PC,U      restore and return

PutcViaFlush        pshs      U         save the caller u register
                    ldd       >OutCursor,Y load the string buffer pointer
                    pshs      D         push it as the stream
                    ldd       6,S       load the character argument
                    pshs      D         push it
                    lbsr      PutChar   output the character
PutcDone            leas      4,S       drop the arguments
                    puls      PC,U      restore and return

StoreToStrBuf       pshs      U         save the caller u register
                    ldd       4,S       load the character
                    ldx       >OutCursor,Y load the buffer pointer
                    leax      1,X       advance the pointer
                    stx       >OutCursor,Y save the new pointer
                    stb       -1,X      store the byte
                    puls      PC,U      restore and return

MsgMinInt           fcc       "-32768"
                    fcb       C$NULL
Fseek               pshs      U         save the caller u register
                    ldu       4,S       load the file pointer
                    leas      -6,S      allocate the local frame
                    cmpu      #0        check for a null file
                    beq       FseekBadArg branch if null
                    ldd       6,U       load the flags
                    clra                keep the low byte only
                    andb      #3        mask the mode bits
                    bne       FseekHaveFile branch if the file is open
FseekBadArg         ldd       #-1       prepare the error result
                    lbra      FseekExit return the error

FseekHaveFile       ldd       6,U       load the flags
                    anda      #128      test the unallocated buffer bit
                    clrb                clear the low byte
                    std       -2,S      save the test result
                    bne       FseekCheckRead branch if buffer allocated
                    pshs      U         push the file pointer
                    lbsr      GetBuf    allocate the buffer
                    leas      2,S       drop the argument
                    lbra      FseekClearEof continue after allocation

FseekCheckRead      ldd       6,U       load the flags
                    anda      #1        test the read-mode bit
                    clrb                clear the low byte
                    std       -2,S      save the test result
                    beq       FseekInBuffer branch if not reading
                    pshs      U         push the file pointer
                    lbsr      fflush    flush pending output
                    leas      2,S       drop the argument
                    ldd       6,U       load the flags
                    anda      #254      clear the read bit
                    std       6,U       store the flags
                    ldd       2,U       load the buffer base
                    addd      11,U      add the buffer count
                    std       4,U       set the end pointer
                    lbra      FseekSetPtr update the current pointer

FseekInBuffer       ldd       ,U        load the current position
                    cmpd      4,U       compare with the end
                    lbcc      FseekClearEof branch if past the end
                    leax      2,S       point at the offset local
                    pshs      X         push its address
                    leax      14,S      point at the seek argument
                    lbsr      StoreLong copy the long value
                    ldx       <16,S     load the whence argument
                    lbra      SeekDispatch dispatch on the whence

SeekSetHandler      leax      2,S       point at the local
                    pshs      X         push its address
                    ldd       2,X       load the offset low word
                    pshs      D         push it
                    ldd       ,X        load the offset high word
                    pshs      D         push it
                    pshs      U         push the file pointer
                    lbsr      CurFilePos read the current file position
                    leas      2,S       drop the file argument
                    lbsr      Sub32     subtract long values
                    lbsr      StoreLong copy the result
SeekCurHandler      ldd       11,U      load the buffer size
                    lbsr      SignExtend32 sign extend to a long
                    ldd       2,X       load the low word
                    pshs      D         push it
                    ldd       ,X        load the high word
                    pshs      D         push it
                    leax      6,S       point at the second value
                    ldd       2,X       load its low word
                    pshs      D         push it
                    ldd       ,X        load its high word
                    pshs      D         push it
                    bsr       SeekClampThunk compare the two values
                    neg       <U0000    inline long-pointer thunk fragment
                    neg       <U0000    inline long-pointer thunk fragment
SeekClampThunk      puls      X         get the inline argument address
                    lbsr      Cmp32     compare the long values
                    bge       SeekPickFirst branch if first is larger
                    leax      6,S       select the first operand
                    lbsr      Negate32  copy the long value
                    bra       SeekRangeCheck merge the paths

SeekPickFirst       leax      6,S       select the operand
SeekRangeCheck      lbsr      Cmp32     compare the longs again
                    blt       FseekReRead branch if negative
                    ldd       4,S       load the offset low word
                    addd      ,U        add the current position
                    std       ,S        store the computed position
                    cmpd      2,U       compare with the buffer base
                    bcs       FseekReRead branch if before the base
                    ldd       ,S        reload the position
                    cmpd      4,U       compare with the end
                    bcc       FseekReRead branch if past the end
                    ldd       ,S        reload the position
                    std       ,U        set the new current pointer
                    ldd       6,U       load the flags
                    andb      #239      clear the eof bit
                    std       6,U       store the flags
                    lbra      FseekOk   return success

                    bra       FseekReRead fall through to reread

SeekDispatch        stx       -2,S      save the whence value
                    lbeq      SeekSetHandler handle seek-set case
                    cmpx      #1        check for seek-cur
                    lbeq      SeekCurHandler handle seek-cur case
FseekReRead         ldd       <16,S     load the whence
                    cmpd      #1        is it seek-cur
                    bne       FseekSetEnd skip if not seek-cur
                    leax      12,S      point at the position
                    pshs      X         push its address
                    ldd       2,X       load the low word
                    pshs      D         push it
                    ldd       ,X        load the high word
                    pshs      D         push it
                    ldd       4,U       load the end pointer
                    subd      ,U        minus the current pointer
                    lbsr      SignExtend32 sign extend to a long
                    lbsr      Sub32     subtract long values
                    lbsr      StoreLong store the result
FseekSetEnd         ldd       4,U       load the end pointer
FseekSetPtr         std       ,U        set the current pointer
FseekClearEof       ldd       6,U       load the flags
                    andb      #239      clear the eof bit
                    std       6,U       store the flags
                    ldd       <16,S     load the position low word
                    pshs      D         push it
                    leax      14,S      point at the position
                    ldd       2,X       load the low word
                    pshs      D         push it
                    ldd       ,X        load the high word
                    pshs      D         push it
                    ldd       8,U       load the file descriptor
                    pshs      D         push it
                    lbsr      lseek     seek the file
                    leas      8,S       drop the arguments
                    ldd       2,X       load the result low word
                    pshs      D         push it
                    ldd       ,X        load the result high word
                    pshs      D         push it
                    bsr       SeekVerifyThunk check for a seek error
                    stu       >-1       inline pointer thunk fragment
                    fcb       $FF
SeekVerifyThunk     puls      X         get the inline argument address
                    lbsr      Cmp32     compare the long values
                    bne       FseekOk   branch if not equal
                    ldd       #-1       prepare the error result
                    bra       FseekExit return the error

FseekOk             clra                success result high byte
                    clrb                success result low byte
FseekExit           leas      6,S       release the locals
                    puls      PC,U      restore and return

Rewind              pshs      U         save the caller u register
                    clra                zero the high byte
                    clrb                zero the low byte
                    pshs      D         push a zero offset
                    clra                zero the high byte
                    clrb                zero the low byte
                    pshs      D         push a zero word
                    pshs      D         push a zero whence
                    ldd       10,S      load the file pointer
                    pshs      D         push it
                    lbsr      Fseek     seek to the start
                    leas      8,S       drop the arguments
                    puls      PC,U      restore and return

CurFilePos          pshs      U         save the caller u register
                    ldu       4,S       load the file pointer
                    beq       FilePosNull branch if null
                    ldd       6,U       load the flags
                    clra                keep the low byte
                    andb      #3        mask the mode bits
                    bne       FilePosSeek branch if the file is open
FilePosNull         bsr       SeekErrThunk report the error
                    stu       >-1       inline pointer thunk fragment
                    fcb       $FF
SeekErrThunk        puls      X         get the inline argument address
                    leau      >TempResult,Y point at the error buffer
                    pshs      U         push it
                    lbsr      StoreLong copy the value
                    puls      PC,U      restore and return

FilePosSeek         ldd       6,U       load the flags
                    anda      #128      test the unallocated buffer bit
                    clrb                clear the low byte
                    std       -2,S      save the test result
                    bne       FilePosCompute branch if buffer allocated
                    pshs      U         push the file pointer
                    lbsr      GetBuf    allocate the buffer
                    leas      2,S       drop the argument
FilePosCompute      ldd       #1        whence seek-cur
                    pshs      D         push it
                    clra                zero the high byte
                    clrb                zero the low byte
                    pshs      D         push the offset high word
                    pshs      D         push the offset low word
                    ldd       8,U       load the file descriptor
                    pshs      D         push it
                    lbsr      lseek     get the raw file position
                    leas      8,S       drop the arguments
                    ldd       2,X       load the position low word
                    pshs      D         push it
                    ldd       ,X        load the position high word
                    pshs      D         push it
                    ldd       6,U       load the flags
                    anda      #1        test the read-mode bit
                    clrb                clear the low byte
                    std       -2,S      save the test result
                    beq       UseEndPtr branch if writing
                    ldd       2,U       load the buffer base
                    bra       ComputeBuffered merge the paths

UseEndPtr           ldd       4,U       load the end pointer
ComputeBuffered     pshs      D         push the buffer boundary
                    ldd       ,U        load the current pointer
                    subd      ,S++      count of buffered bytes
                    lbsr      SignExtend32 sign extend to a long
                    lbsr      Add32     subtract from the position
                    puls      PC,U      restore and return

PutChar             pshs      U         save the caller u register
                    ldu       6,S       load the file pointer
                    ldd       6,U       load the flags
                    anda      #128      mask the unallocated bit
                    andb      #34       mask the mode bits
                    cmpd      #-32766   test write and unallocated
                    beq       PutCharCheckBuf skip alloc if already set
                    ldd       6,U       load the flags
                    clra                keep the low byte
                    andb      #34       mask the mode bits
                    cmpd      #2        check for write mode
                    lbne      FlushErr  error if not writing
                    pshs      U         push the file pointer
                    lbsr      GetBuf    allocate the buffer
                    leas      2,S       drop the argument
PutCharCheckBuf     ldd       6,U       load the flags
                    clra                keep the low byte
                    andb      #4        test the unbuffered bit
                    beq       PutCharBuffered branch if buffered
                    ldd       #1        length of one byte
                    pshs      D         push it
                    leax      7,S       point at the character
                    pshs      X         push the buffer address
                    ldd       8,U       load the file descriptor
                    pshs      D         push it
                    ldd       6,U       load the flags
                    clra                keep the low byte
                    andb      #64       test the line-buffered bit
                    beq       PutCharPickWrite branch if not line-buffered
                    leax      >writeln,PC select the write routine
                    bra       PutCharCall merge the paths

PutCharPickWrite    leax      >write,PC select the write routine
PutCharCall         tfr       X,D       move address to accumulator
                    tfr       D,X       move it back into X
                    jsr       ,X        call the write routine
                    leas      6,S       drop the arguments
                    cmpd      #-1       check for an error
                    bne       PutCharDone branch if the write succeeded
                    ldd       6,U       load the flags
                    orb       #32       set the error bit
                    std       6,U       store the flags
                    lbra      FlushErr  return the error

PutCharBuffered     ldd       6,U       load the flags
                    anda      #1        test the read-mode bit
                    clrb                clear the low byte
                    std       -2,S      save the test result
                    bne       PutCharStore branch if reading
                    pshs      U         push the file pointer
                    lbsr      WriteBuffer flush the buffer first
                    leas      2,S       drop the argument
PutCharStore        ldd       ,U        load the current pointer
                    addd      #1        advance one byte
                    std       ,U        store the pointer
                    subd      #1        recover the old pointer
                    tfr       D,X       move it into X
                    ldd       4,S       load the character
                    stb       ,X        store the byte in the buffer
                    ldd       ,U        load the current pointer
                    cmpd      4,U       compare with the end
                    bcc       PutCharFlush flush if the buffer is full
                    ldd       6,U       load the flags
                    clra                keep the low byte
                    andb      #64       test the line-buffered bit
                    beq       PutCharDone done if not line-buffered
                    ldd       4,S       load the character
                    cmpd      #13       is it a newline
                    bne       PutCharDone done if not a newline
PutCharFlush        pshs      U         push the file pointer
                    lbsr      WriteBuffer flush the buffer
                    std       ,S++      save the result and pop
                    lbne      FlushErr  error if the flush failed
PutCharDone         ldd       4,S       load the character result
                    puls      PC,U      restore and return

                    pshs      U         save the caller u register
                    ldu       4,S       load the file pointer
                    ldd       6,S       load the argument
                    pshs      D         push it
                    pshs      U         push the file pointer
                    ldd       #8        length of eight
                    lbsr      LsrEntry  measure the field width
                    pshs      D         push the result
                    lbsr      PutChar   output the character
                    leas      4,S       drop the arguments
                    ldd       6,S       reload the argument
                    pshs      D         push it
                    pshs      U         push the file pointer
                    lbsr      PutChar   output the character
                    lbra      SeekExit  tail call to continue

_tidyup             pshs      U,D       save the registers
                    leau      >_iob,Y   point at the stream table
                    clra                zero the index high byte
                    clrb                zero the index low byte
                    std       ,S        initialise the counter
                    bra       TidyNext  enter the loop test

TidyLoop            tfr       U,D       copy the stream pointer
                    leau      13,U      advance to the next stream
                    pshs      D         push the current stream
                    bsr       fclose    close it
                    leas      2,S       drop the argument
TidyNext            ldd       ,S        load the counter
                    addd      #1        increment it
                    std       ,S        store it back
                    subd      #1        recover the previous value
                    cmpd      #16       all streams done
                    blt       TidyLoop  loop if more remain
                    puls      PC,U,X    restore and return

fclose              pshs      U         save the caller u register
                    ldu       4,S       load the file pointer
                    leas      -2,S      allocate a local
                    cmpu      #0        check for a null file
                    beq       FcloseNull branch if null
                    ldd       6,U       load the flags
                    bne       FcloseHaveFlag branch if the file is open
FcloseNull          ldd       #-1       prepare the error result
                    puls      PC,U,X    return the error

FcloseHaveFlag      ldd       6,U       load the flags
                    clra                keep the low byte
                    andb      #2        test the write-mode bit
                    beq       FcloseNoFlush skip the flush if reading
                    pshs      U         push the file pointer
                    bsr       fflush    flush the buffer
                    leas      2,S       drop the argument
                    bra       FcloseDoClose continue to the close

FcloseNoFlush       clra                zero the result high byte
                    clrb                zero the result low byte
FcloseDoClose       std       ,S        save the flush result
                    ldd       8,U       load the file descriptor
                    pshs      D         push it
                    lbsr      close     close the file
                    leas      2,S       drop the argument
                    clra                zero the flags high byte
                    clrb                zero the flags low byte
                    std       6,U       clear the file flags
                    ldd       ,S        load the saved result
                    puls      PC,U,X    restore and return

                    use       lib/fflush.asm
FlushErr            equ       IoErr shared not-writable error return
FlushBuf            equ       WriteBuffer this module's helper name

WriteBuffer         pshs      U         save the caller u register
                    ldu       4,S       load the file pointer
                    leas      -4,S      allocate the locals
                    ldd       6,U       load the flags
                    anda      #1        test the read-mode bit
                    clrb                clear the low byte
                    std       -2,S      store computed flag in local
                    bne       SeekFlushDone skip lseek if not needed
                    ldd       ,U        load current buffer pointer
                    cmpd      4,U       compare against buffer end
                    beq       SeekFlushDone skip lseek if already synced
                    clra                zero for whence seek set
                    clrb                clear low byte
                    pshs      D         push whence argument
                    pshs      U         push file pointer
                    lbsr      CurFilePos compute file position
                    leas      2,S       drop argument
                    ldd       2,X       load offset low word
                    pshs      D         push it
                    ldd       ,X        load offset high word
                    pshs      D         push it
                    ldd       8,U       push file descriptor
                    pshs      D         push it
                    lbsr      lseek     reposition the file
                    leas      8,S       drop arguments
SeekFlushDone       ldd       ,U        load buffer pointer
                    subd      2,U       compute bytes remaining in buffer
                    std       2,S       save byte count
                    lbeq      SeekResetBuf branch if buffer empty
                    ldd       6,U       load status flags
                    anda      #1        isolate error bit
                    clrb                clear low byte
                    std       -2,S      save masked flag
                    lbeq      SeekResetBuf branch if flag clear
                    ldd       6,U       reload status flags
                    clra                clear high byte
                    andb      #64       test write-mode bit
                    beq       SeekReadBuf branch to read path
                    ldd       2,U       load buffer base
                    bra       SeekStorePtr enter write loop

SeekWriteLoop       ldd       2,S       load remaining count
                    pshs      D         push it
                    ldd       ,U        load current pointer
                    pshs      D         push it
                    ldd       8,U       load file descriptor
                    pshs      D         push it
                    lbsr      writeln   write buffer contents
                    leas      6,S       drop arguments
                    std       ,S        save bytes written
                    cmpd      #-1       check for write error
                    bne       SeekWriteAdvance continue if no error
                    leax      4,S       point at error slot
                    bra       SeekResetStack handle write failure

SeekWriteAdvance    ldd       2,S       load remaining count
                    subd      ,S        subtract bytes written
                    std       2,S       update remaining count
                    ldd       ,U        load current pointer
                    addd      ,S        advance buffer pointer
SeekStorePtr        std       ,U        store updated pointer
                    ldd       2,S       load remaining count
                    bne       SeekWriteLoop loop until fully written
                    bra       SeekResetBuf done flushing

SeekReadBuf         ldd       2,S       load count
                    pshs      D         push it
                    ldd       2,U       load buffer base
                    pshs      D         push it
                    ldd       8,U       load file descriptor
                    pshs      D         push it
                    lbsr      write     read buffer contents
                    leas      6,S       drop arguments
                    cmpd      2,S       compare bytes read to count
                    beq       SeekResetBuf success if full read
                    bra       SeekSetError otherwise mark error

SeekResetStack      leas      -4,X      restore stack frame
SeekSetError        ldd       6,U       load status flags
                    orb       #32       set error flag bit
                    std       6,U       store flags
                    ldd       4,U       load buffer end
                    std       ,U        reset pointer to end
                    ldd       #-1       return failure
                    bra       SeekExit  exit

SeekResetBuf        ldd       6,U       load status flags
                    ora       #1        set synced flag bit
                    std       6,U       store flags
                    ldd       2,U       load buffer base
                    std       ,U        reset pointer to base
                    addd      11,U      add buffer size
                    std       4,U       set buffer end
                    clra                clear high byte
                    clrb                return success
SeekExit            leas      4,S       discard locals
                    puls      PC,U      return

Getc                pshs      U         save the caller u register
                    ldu       4,S       load file pointer
                    beq       ReturnEOF return eof if null
                    ldd       6,U       load status flags
                    anda      #1        isolate error bit
                    clrb                clear low byte
                    std       -2,S      save masked flag
                    bne       ReturnEOF return eof if error set
                    ldd       ,U        load buffer pointer
                    cmpd      4,U       compare against buffer end
                    bcc       GetcRefill refill if buffer empty
                    ldd       ,U        load buffer pointer
                    addd      #1        advance pointer
                    std       ,U        store pointer
                    subd      #1        recover old pointer
                    tfr       D,X       into index register
                    ldb       ,X        fetch next character
                    clra                zero-extend to word
                    bra       GetcReturn return the character

GetcRefill          pshs      U         push file pointer
                    lbsr      FillBuf   refill the buffer
                    leas      2,S       drop argument
GetcReturn          puls      PC,U      return

                    pshs      U         save the caller u register
                    ldu       6,S       load file pointer
                    beq       ReturnEOF return eof if null
                    ldd       6,U       load status flags
                    clra                clear high byte
                    andb      #1        isolate mode bit
                    beq       ReturnEOF branch if flag clear
                    ldd       4,S       load character argument
                    cmpd      #-1       check for eof
                    beq       ReturnEOF reject pushing back eof
                    ldd       ,U        load buffer pointer
                    cmpd      2,U       compare against buffer base
                    bhi       UngetcStore room to push back
ReturnEOF           ldd       #-1       return eof
                    puls      PC,U      return

UngetcStore         ldd       ,U        load buffer pointer
                    addd      #-1       back up pointer
                    std       ,U        store pointer
                    tfr       D,X       into index register
                    ldd       4,S       load character
                    stb       ,X        store pushed-back byte
                    ldd       4,S       return the character
                    puls      PC,U      return

                    pshs      U         save the caller u register
                    ldu       4,S       load file pointer
                    leas      -4,S      reserve two locals
                    pshs      U         push file pointer
                    lbsr      Getc      read first byte
                    leas      2,S       drop argument
                    std       2,S       save high byte
                    cmpd      #-1       check for eof
                    beq       GetwEOF   fail on eof
                    pshs      U         push file pointer
                    lbsr      Getc      read second byte
                    leas      2,S       drop argument
                    std       ,S        save low byte
                    cmpd      #-1       check for eof
                    bne       GetwCombine combine if valid
GetwEOF             ldd       #-1       return eof
                    bra       GetwExit  exit

GetwCombine         ldd       2,S       load high byte
                    pshs      D         push it
                    ldd       #8        shift count of eight
                    lbsr      AslEntry  shift high byte left
                    addd      ,S        merge low byte
GetwExit            leas      4,S       discard locals
                    puls      PC,U      return

FillBuf             pshs      U         save the caller u register
                    ldu       4,S       load file pointer
                    leas      -2,S      reserve local
                    ldd       6,U       load status flags
                    anda      #128      isolate high flag bits
                    andb      #49       mask mode bits
                    cmpd      #-32767   test read-only unbuffered
                    beq       FillBufCheckStdin proceed to read
                    ldd       6,U       reload status flags
                    clra                clear high byte
                    andb      #49       mask mode bits
                    cmpd      #1        test read mode
                    beq       FillBufSetup set up buffer first
                    ldd       #-1       return error
                    puls      PC,U,X    return

FillBufSetup        pshs      U         push file pointer
                    lbsr      GetBuf    allocate the buffer
                    leas      2,S       drop argument
FillBufCheckStdin   leax      >_iob,Y   address of stdin entry
                    pshs      X         push it
                    cmpu      ,S++      is this stdin
                    bne       FillBufDoRead skip if not stdin
                    ldd       6,U       load status flags
                    clra                clear high byte
                    andb      #64       test write bit
                    beq       FillBufDoRead skip if not writing
                    leax      >OutBuffer,Y address of stdout pointer
                    pshs      X         push it
                    lbsr      fflush    flush stdout
                    leas      2,S       drop argument
FillBufDoRead       ldd       6,U       load status flags
                    clra                clear high byte
                    andb      #8        test allocated-buffer bit
                    beq       FillBufUnbuffered unbuffered read path
                    ldd       11,U      load buffer size
                    pshs      D         push it
                    ldd       2,U       load buffer base
                    pshs      D         push it
                    ldd       8,U       load file descriptor
                    pshs      D         push it
                    ldd       6,U       load status flags
                    clra                clear high byte
                    andb      #64       test raw-mode bit
                    beq       FillBufSelectRead select plain read routine
                    leax      >readln,PC address of alternate reader
                    bra       FillBufCallRead call it

FillBufSelectRead   leax      >read,PC  address of read routine
FillBufCallRead     tfr       X,D       pointer into d
                    tfr       D,X       into index register
                    jsr       ,X        read into buffer
                    bra       FillBufCheckCount check result

FillBufUnbuffered   ldd       #1        read a single byte
                    pshs      D         push count
                    leax      10,U      address of single-char buffer
                    stx       2,U       set buffer base
                    pshs      X         push it
                    ldd       8,U       load file descriptor
                    pshs      D         push it
                    lbsr      read      read one byte
FillBufCheckCount   leas      6,S       drop arguments
                    std       ,S        save bytes read
                    ldd       ,S        reload byte count
                    bgt       FillBufSuccess success if positive
                    ldd       6,U       load status flags
                    pshs      D         push them
                    ldd       2,S       check read count
                    beq       FillBufSetEOF zero means eof
                    ldd       #32       select error flag bit
                    bra       FillBufSetFlags set it

FillBufSetEOF       ldd       #16       select eof flag bit
FillBufSetFlags     ora       ,S+       merge into flags high byte
                    orb       ,S+       merge into flags low byte
                    std       6,U       store flags
                    ldd       #-1       return eof
                    puls      PC,U,X    return

FillBufSuccess      ldd       2,U       load buffer base
                    addd      #1        skip first byte
                    std       ,U        set current pointer
                    ldd       2,U       reload buffer base
                    addd      ,S        add bytes read
                    std       4,U       set buffer end
                    ldb       [<2,U]    fetch first character
                    clra                zero-extend to word
                    puls      PC,U,X    return the character

GetBuf              pshs      U         save the caller u register
                    ldu       4,S       load file pointer
                    ldd       6,U       load status flags
                    clra                clear high byte
                    andb      #192      test buffering bits
                    bne       GetBufMarkBuffered skip if already set
                    leas      <-32,S    reserve stat buffer
                    leax      ,S        point at stat buffer
                    pshs      X         push it
                    ldd       8,U       load file descriptor
                    pshs      D         push it
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      D         push zero
                    lbsr      GetStatSys get file status
                    leas      6,S       drop arguments
                    ldd       6,U       load status flags
                    pshs      D         push them
                    ldb       2,S       test file type
                    bne       GetBufFullBuf block device selects full buffer
                    ldd       #64       line-buffered flag
                    bra       GetBufSetType apply it

GetBufFullBuf       ldd       #128      fully-buffered flag
GetBufSetType       ora       ,S+       merge into flags high byte
                    orb       ,S+       merge into flags low byte
                    std       6,U       store flags
                    leas      <32,S     release stat buffer
GetBufMarkBuffered  ldd       6,U       load status flags
                    ora       #128      set buffered bit
                    std       6,U       store flags
                    clra                clear high byte
                    andb      #12       test existing buffer bits
                    beq       GetBufDefaultSize none, allocate one
                    puls      PC,U      return

GetBufDefaultSize   ldd       11,U      load buffer size
                    bne       GetBufAlloc use existing size
                    ldd       6,U       load status flags
                    clra                clear high byte
                    andb      #64       test write bit
                    beq       GetBufReadSize default read size
                    ldd       #128      write buffer size
                    bra       GetBufStoreSize apply it

GetBufReadSize      ldd       #256      default buffer size
GetBufStoreSize     std       11,U      store buffer size
GetBufAlloc         ldd       2,U       load buffer base
                    bne       GetBufAllocated already allocated
                    ldd       11,U      load buffer size
                    pshs      D         push it
                    lbsr      GrowMemTop allocate the buffer
                    leas      2,S       drop argument
                    std       2,U       store buffer base
                    cmpd      #-1       check for failure
                    beq       GetBufAllocFail fall back on failure
GetBufAllocated     ldd       6,U       load status flags
                    orb       #8        set allocated-buffer bit
                    std       6,U       store flags
                    bra       GetBufFinish finish setup

GetBufAllocFail     ldd       6,U       load status flags
                    orb       #4        set unbuffered fallback bit
                    std       6,U       store flags
                    leax      10,U      address of single-char buffer
                    stx       2,U       set buffer base
                    ldd       #1        single byte size
                    std       11,U      store buffer size
GetBufFinish        ldd       2,U       load buffer base
                    addd      11,U      add buffer size
                    std       4,U       set buffer end
                    std       ,U        set current pointer
                    puls      PC,U      return

SelectConvStr       pshs      U         save the caller u register
                    ldb       5,S       load format character
                    sex                 sign-extend to word
                    tfr       D,X       into index register
                    bra       ConvDispatch dispatch on character

ConvNumeric         ldd       [<6,S]    load argument pointer
                    addd      #4        advance past argument
                    std       [<6,S]    store updated pointer
                    leax      >EmptyString,PC address of empty string
                    bra       ConvReturn return it

ConvDefault         ldb       5,S       load format character
                    stb       >Y0487,Y  store into single-char string
                    leax      >Y0486,Y  address that string
ConvReturn          tfr       X,D       result pointer into d
                    puls      PC,U      return

ConvDispatch        cmpx      #100      is it letter d
                    beq       ConvNumeric numeric conversion
                    cmpx      #111      is it letter o
                    lbeq      ConvNumeric numeric conversion
                    cmpx      #120      is it letter x
                    lbeq      ConvNumeric numeric conversion
                    bra       ConvDefault default single character

                    puls      PC,U      unreachable return

EmptyString         fcb       $00
ReturnEmptyStr      pshs      U         save the caller u register
                    leax      >EmptyString2,PC address of empty string
                    tfr       X,D       into d for return
                    puls      PC,U      return

EmptyString2        fcb       $00
strlen              pshs      U         save the caller u register
                    ldu       4,S       load string pointer
StrLenLoop          ldb       ,U+       scan next character
                    bne       StrLenLoop loop until null
                    tfr       U,D       end pointer into d
                    subd      4,S       subtract start pointer
                    addd      #-1       exclude terminator
                    puls      PC,U      return length

                    use       lib/strcpy.asm

                    pshs      U         save the caller u register
                    ldu       6,S       load source pointer
                    leas      -2,S      reserve local
                    ldd       6,S       load destination pointer
                    std       ,S        save running pointer
StrCatFindEnd       ldx       ,S        load destination pointer
                    leax      1,X       advance it
                    stx       ,S        store it back
                    ldb       -1,X      load current character
                    bne       StrCatFindEnd loop to end of string
                    ldd       ,S        load end pointer
                    addd      #-1       back up to terminator
                    std       ,S        store append position
StrCatCopyLoop      ldb       ,U+       load source character
                    ldx       ,S        load append pointer
                    leax      1,X       advance it
                    stx       ,S        store it back
                    stb       -1,X      write the character
                    bne       StrCatCopyLoop loop until null copied
                    ldd       6,S       return destination
                    puls      PC,U,X    return

strcmp              pshs      U         save the caller u register
                    ldu       4,S       load first string pointer
                    bra       StrCmpLoop enter compare loop

StrCmpEqual         ldx       6,S       load second string pointer
                    leax      1,X       advance it
                    stx       6,S       store it back
                    ldb       -1,X      load its character
                    bne       StrCmpNext continue if not null
                    clra                clear high byte
                    clrb                strings are equal
                    puls      PC,U      return zero

StrCmpNext          leau      1,U       advance first pointer
StrCmpLoop          ldb       ,U        load first character
                    sex                 sign-extend to word
                    pshs      D         push it
                    ldb       [<8,S]    load second character
                    sex                 sign-extend to word
                    cmpd      ,S++      compare the two characters
                    beq       StrCmpEqual equal, keep scanning
                    ldb       [<6,S]    load first character
                    sex                 sign-extend to word
                    pshs      D         push it
                    ldb       ,U        reload other character
                    sex                 sign-extend to word
                    subd      ,S++      compute the difference
                    puls      PC,U      return the difference

                    use       lib/memcpy.asm

Add32               ldd       4,S       load addend low word
                    addd      2,X       add operand low word
                    std       >Y059D,Y  store result low word
                    ldd       2,S       load addend high word
                    adcb      1,X       add operand with carry
                    adca      ,X        add high byte
                    std       >TempResult,Y store result high word
                    lbra      ReturnTempPtr return result

Sub32               ldd       4,S       load minuend low word
                    subd      2,X       subtract operand low word
                    std       >Y059D,Y  store result low word
                    ldd       2,S       load minuend high word
                    sbcb      1,X       subtract with borrow
                    sbca      ,X        subtract high byte
                    std       >TempResult,Y store result high word
                    lbra      ReturnTempPtr return result

Cmp32               ldd       2,S       load left high word
                    cmpd      ,X        compare high words
                    bne       Cmp32Done differ, result decided
                    ldd       4,S       load left low word
                    cmpd      2,X       compare low words
                    beq       Cmp32Done equal
                    bcs       Cmp32Less left is smaller
                    lda       #1        flag greater
                    andcc     #254      clear carry
                    bra       Cmp32Done join result point

Cmp32Less           clra                flag less
                    cmpa      #1        set carry via compare
Cmp32Done           pshs      CC        save condition codes
                    ldd       1,S       reload the result byte
                    std       5,S       store result on the stack frame
                    puls      CC        restore the condition codes
                    leas      4,S       clean up the stack frame
                    rts                 return to caller
Negate32            lbsr      CopyToTemp32 copy the operand into the temp
                    ldd       #0        load zero for the subtract
                    subd      2,X       subtract the low word
                    std       2,X       store the low word result
                    ldd       #0        load zero for the high word
                    sbcb      1,X       subtract low byte with borrow
                    sbca      ,X        subtract high byte with borrow
                    std       ,X        store the high word result
                    rts                 return to caller
                    ldd       ,X        load the high word
                    coma                complement the high byte
                    comb                complement the low byte
                    std       >TempResult,Y store into the temp
                    ldd       2,X       load the low word
                    coma                complement the high byte
                    comb                complement the low byte
                    leax      >TempResult,Y point at the temp
                    std       2,X       store the low word
                    rts                 return to caller
SignExtend32        leax      >TempResult,Y point at the temp
                    std       2,X       store the low word
                    tfr       A,B       copy the high byte
                    sex                 sign extend it
                    tfr       A,B       replicate the sign byte
                    std       ,X        store the sign-extended high word
                    rts                 return to caller
ZeroExtend32        leax      >TempResult,Y point at the temp
                    std       2,X       store the low word
                    clr       ,X        zero the high byte
                    clr       1,X       zero the other high byte
                    rts                 return to caller
StoreLong           pshs      Y         save Y
                    ldy       4,S       load the destination pointer
                    ldd       ,X        load the high word
                    std       ,Y        store to the destination
                    ldd       2,X       load the low word
                    std       U0002,Y   store the low word to destination
                    puls      X         restore X
                    exg       Y,X       swap the pointers
                    puls      D         pop the saved value
                    std       ,S        store it on the stack
                    rts                 return to caller
ReturnTempPtr       tfr       CC,A      save the condition codes
                    puls      X         pop the return address
                    stx       2,S       relocate the return address
                    leas      2,S       drop the stack slot
                    leax      >TempResult,Y point at the temp result
                    tfr       A,CC      restore the condition codes
                    rts                 return to caller
CopyToTemp32        ldd       ,X        load the high word
                    std       >TempResult,Y store into the temp
                    ldd       2,X       load the low word
                    leax      >TempResult,Y point at the temp
                    std       2,X       store the low word
                    rts                 return to caller
                    use       lib/imul.asm
Divide32            clr       >SignFlag,Y clear the sign flag
                    leax      >UDivEntry,PC point at the unsigned divide routine
                    stx       >RoutinePtr,Y store the routine pointer
                    bra       Div32Body go to the divide body

                    leax      >SDivEntry,PC point at the signed divide routine
                    stx       >RoutinePtr,Y store the routine pointer
                    clr       >SignFlag,Y clear the sign flag
                    tst       2,S       test the dividend sign
                    bpl       Div32Body skip if positive
                    inc       >SignFlag,Y set the sign flag
Div32Body           subd      #0        test the divisor for zero
                    bne       Div32Call divide if nonzero
                    puls      X         pop the return address
                    ldd       ,S++      pop the operand
                    jmp       ,X        return zero result

Div32Call           ldx       2,S       load the dividend
                    pshs      X         push it as argument
                    jsr       [>RoutinePtr,Y] call the divide routine
                    ldd       ,S        load the low result
                    std       2,S       store it back
                    tfr       X,D       move the high result to D
                    tst       >SignFlag,Y test the sign flag
                    beq       DivStoreResult skip negate if positive
                    nega                negate the result
                    negb                negate the low byte
                    sbca      #0        finish the negate with borrow
DivStoreResult      std       ,S++      store the result
                    rts                 return to caller
                    use       lib/divide.asm
                    use       lib/shift.asm

SendSignal          std       >errno,Y  save the signal number as errno
                    pshs      Y,B       save registers
                    os9       F$ID      get the current process id
                    puls      Y,B       restore registers
                    os9       F$Send    send the signal
                    rts                 return to caller
GetStatSys          lda       5,S       load the path number
                    ldb       3,S       load the function code
                    beq       GetSttSimple branch on function zero
                    cmpb      #1        compare function one
                    beq       GetSttCall branch to the getstat call
                    cmpb      #6        compare function six
                    beq       GetSttCall branch to the getstat call
                    cmpb      #2        compare function two
                    beq       GetSttOption branch to the option path
                    cmpb      #5        compare function five
                    beq       GetSttOption branch to the option path
                    ldb       #208      prepare bad mode error
                    lbra      SyscallErr return the error

GetSttOption        pshs      U         save U
                    os9       I$GetStt  get the file status
                    bcc       GetSttStore branch on success
                    puls      U         restore U
                    lbra      SyscallErr return the error

GetSttStore         stx       [<8,S]    store the result to the caller
                    ldx       8,S       load the result pointer
                    stu       2,X       store U there
                    puls      U         restore U
                    clra                clear the return high byte
                    clrb                clear the return low byte
                    rts                 return to caller
GetSttSimple        ldx       6,S       load the argument pointer
GetSttCall          os9       I$GetStt  get the file status
                    lbra      SyscallRet return via sysret

                    lda       5,S       load the path number
                    ldb       3,S       load the function code
                    beq       SetSttSimple branch on function zero
                    cmpb      #2        compare function two
                    beq       SetStatXU branch to the option path
                    ldb       #208      prepare bad mode error
                    lbra      SyscallErr return the error

SetSttSimple        ldx       6,S       load the argument
                    os9       I$SetStt  set the file status
                    lbra      SyscallRet return via sysret

                    use       lib/setstat.asm

                    use       lib/access.asm

                    use       lib/openpath.asm
                    use       lib/closepath.asm

mknod               ldx       2,S       load the directory name
                    ldb       5,S       load the attributes
                    os9       I$MakDir  make the directory
                    lbra      SyscallRet return via sysret

                    use       lib/createheada.asm
                    use       lib/createtail.asm

                    use       lib/deletepath.asm

dup                 lda       3,S       load the path number
                    os9       I$Dup     duplicate the path
                    lbcs      SyscallErr return error if it failed
                    tfr       A,B       return the new path number
                    clra                clear the high byte
                    rts                 return to caller
                    use       lib/readpath.asm

                    use       lib/writepath.asm

lseek               pshs      U         save U
                    ldd       10,S      load the whence argument
                    bne       LseekWhence branch if not SEEK_SET
                    ldu       #0        zero offset high
                    ldx       #0        zero offset high
                    bra       LseekDoSeek go do the seek

LseekWhence         cmpd      #1        compare SEEK_CUR
                    beq       LseekCur  branch to current-position path
                    cmpd      #2        compare SEEK_END
                    beq       LseekEnd  branch to end-of-file path
                    ldb       #247      prepare bad argument error
LseekErr            clra                clear the high byte
                    std       >errno,Y  record errno
                    ldd       #-1       return minus one
                    leax      >TempResult,Y point at the temp
                    std       ,X        store into it
                    std       2,X       store into it
                    puls      PC,U      return with error

LseekEnd            lda       5,S       load the path number
                    ldb       #2        file size getstat function
                    os9       I$GetStt  get the file size
                    bcs       LseekErr  branch on error
                    bra       LseekDoSeek go do the seek

LseekCur            lda       5,S       load the path number
                    ldb       #5        current position getstat function
                    os9       I$GetStt  get the current position
                    bcs       LseekErr  branch on error
LseekDoSeek         tfr       U,D       start from the base position
                    addd      8,S       add the offset low
                    std       >Y059D,Y  store the position low
                    tfr       D,U       move it back to U
                    tfr       X,D       load the position high
                    adcb      7,S       add offset high with carry
                    adca      6,S       add offset high byte
                    bmi       LseekErr  error if negative position
                    tfr       D,X       move the high half to X
                    std       >TempResult,Y store the position high
                    lda       5,S       load the path number
                    os9       I$Seek    seek to the position
                    bcs       LseekErr  branch on error
                    leax      >TempResult,Y point at the result
                    puls      PC,U      return with result

Sbrk                ldd       >memend,Y load the current heap end
                    pshs      D         save it
                    ldd       4,S       load the requested size
                    cmpd      >FreeSpace,Y compare with the free space
                    bcs       SbrkAdjust branch if enough already
                    addd      >memend,Y add to the heap end
                    pshs      Y         save Y
                    subd      ,S        compute the extra needed
                    os9       F$Mem     request more memory
                    tfr       Y,D       new memory size in D
                    puls      Y         restore Y
                    bcc       SbrkGrow  branch on success
                    ldd       #-1       return failure
                    leas      2,S       drop the saved value
                    rts                 return to caller
SbrkGrow            std       >memend,Y update the heap end
                    addd      >FreeSpace,Y add the free space
                    subd      ,S        subtract the old end
                    std       >FreeSpace,Y update the free space
SbrkAdjust          leas      2,S       drop the saved value
                    ldd       >FreeSpace,Y load the free space
                    pshs      D         save it
                    subd      4,S       subtract the requested size
                    std       >FreeSpace,Y deduct the allocation
                    ldd       >memend,Y load the heap end
                    subd      ,S++      subtract to find the block start
                    pshs      D         save the pointer
                    clra                zero fill byte
                    ldx       ,S        load the fill pointer
SbrkFillLoop        sta       ,X+       store the fill byte
                    cmpx      >memend,Y compare with the heap end
                    bcs       SbrkFillLoop loop until heap end
                    puls      PC,D      return the pointer

GrowMemTop          ldd       2,S       load the requested size
                    addd      >_mtop,Y  add requested size to current memory top
                    bcs       SbrkFail  overflow past end of memory fails
                    cmpd      >_stbot,Y compare new top against stack bottom
                    bcc       SbrkFail  would collide with stack so fail
                    pshs      D         save the new top on the stack
                    ldx       >_mtop,Y  load the old memory top
                    clra                zero as the fill byte
ClrMemLoop          cmpx      ,S        reached the new top yet
                    bcc       ClrMemDone done clearing when at new top
                    sta       ,X+       zero this byte of the new region
                    bra       ClrMemLoop continue clearing

ClrMemDone          ldd       >_mtop,Y  return the old top as result
                    puls      X         recover the new top
                    stx       >_mtop,Y  commit the updated memory top
                    rts                 return to caller
SbrkFail            ldd       #-1       return failure value -1
                    rts                 return to caller
                    ldx       2,S       load the time packet pointer
                    os9       F$STime   set the system time
                    lbra      SyscallRet return through the syscall epilogue

GetTime             ldx       2,S       load the time buffer pointer
                    os9       F$Time    read the system time
                    lbra      SyscallRet return through the syscall epilogue

                    use       lib/syscallerr.asm

exit                lbsr      _dumprof  dump profiling data before exit
                    lbsr      _tidyup   tidy up open resources
_exit               ldd       2,S       load the exit status code
                    os9       F$Exit    terminate the process

_dumprof            rts                 profiling stub does nothing

                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       WBIcount2-WBIblock1

                    * ---- block1: DP data image  ->  data base
WBIblock1           fcb       $00
                    fcb       $01
                    fcb       $01
                    fcb       $00
                    fcb       $42
                    fcb       $00
                    fcb       $50
WBIp_0007           fdb       CodeSection
WBIp_0009           fdb       DataSection
WBIp_000B           fdb       Y025E
WBIp_000D           fdb       BssSection
WBIp_000F           fdb       HashTable
WBIp_0011           fdb       BranchHashTbl
WBIp_0013           fdb       DispatchTbl

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
WBIcount2           fdb       WBIblk2End-WBIblock2

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fcb       $72
                    fcb       $6D
                    fcb       $61
                    fcb       $2E
                    fcb       $74
                    fcb       $6D
                    fcb       $70
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
WBIp_0106           fdb       Lt_08EE
                    fcb       $00
                    fcb       $00
WBIp_010A           fdb       Lt_08F4
                    fcb       $00
                    fcb       $01
WBIp_010E           fdb       Lt_08FA
                    fcb       $00
                    fcb       $02
WBIp_0112           fdb       Lt_0900
                    fcb       $06
                    fcb       $03
WBIp_0116           fdb       Lt_0904
                    fcb       $16
                    fcb       $00
WBIp_011A           fdb       Lt_0909
                    fcb       $17
                    fcb       $00
WBIp_011E           fdb       Lt_090E
                    fcb       $1A
                    fcb       $01
WBIp_0122           fdb       Lt_0913
                    fcb       $1C
                    fcb       $01
WBIp_0126           fdb       Lt_0919
                    fcb       $3C
                    fcb       $01
WBIp_012A           fdb       Lt_091E
                    fcb       $C3
                    fcb       $02
WBIp_012E           fdb       Lt_0923
                    fcb       $83
                    fcb       $02
WBIp_0132           fdb       Lt_0928
                    fcb       $CC
                    fcb       $02
WBIp_0136           fdb       Lt_092C
                    fcb       $8E
                    fcb       $02
WBIp_013A           fdb       Lt_0930
                    fcb       $CE
                    fcb       $02
WBIp_013E           fdb       Lt_0934
                    fcb       $8C
                    fcb       $02
WBIp_0142           fdb       Lt_0939
                    fcb       $8D
                    fcb       $42
WBIp_0146           fdb       Lt_093D
                    fcb       $CD
                    fcb       $42
WBIp_014A           fdb       Lt_0941
                    fcb       $8F
                    fcb       $42
WBIp_014E           fdb       Lt_0945
                    fcb       $CF
                    fcb       $42
WBIp_0152           fdb       Lt_0949
                    fcb       $83
                    fcb       $22
WBIp_0156           fdb       Lt_094E
                    fcb       $8C
                    fcb       $22
WBIp_015A           fdb       Lt_0953
                    fcb       $83
                    fcb       $12
WBIp_015E           fdb       Lt_0958
                    fcb       $8C
                    fcb       $12
WBIp_0162           fdb       Lt_095D
                    fcb       $8E
                    fcb       $12
WBIp_0166           fdb       Lt_0961
                    fcb       $CE
                    fcb       $12
WBIp_016A           fdb       Lt_0965
                    fcb       $8F
                    fcb       $52
WBIp_016E           fdb       Lt_0969
                    fcb       $CF
                    fcb       $52
WBIp_0172           fdb       Lt_096D
                    fcb       $8B
                    fcb       $03
WBIp_0176           fdb       Lt_0971
                    fcb       $81
                    fcb       $03
WBIp_017A           fdb       Lt_0975
                    fcb       $80
                    fcb       $03
WBIp_017E           fdb       Lt_0979
                    fcb       $82
                    fcb       $03
WBIp_0182           fdb       Lt_097D
                    fcb       $84
                    fcb       $03
WBIp_0186           fdb       Lt_0981
                    fcb       $85
                    fcb       $03
WBIp_018A           fdb       Lt_0985
                    fcb       $86
                    fcb       $03
WBIp_018E           fdb       Lt_0988
                    fcb       $87
                    fcb       $43
WBIp_0192           fdb       Lt_098B
                    fcb       $88
                    fcb       $03
WBIp_0196           fdb       Lt_098F
                    fcb       $89
                    fcb       $03
WBIp_019A           fdb       Lt_0993
                    fcb       $08
                    fcb       $0C
WBIp_019E           fdb       Lt_0997
                    fcb       $8A
                    fcb       $03
WBIp_01A2           fdb       Lt_099A
                    fcb       $00
                    fcb       $04
WBIp_01A6           fdb       Lt_099E
                    fcb       $03
                    fcb       $04
WBIp_01AA           fdb       Lt_09A2
                    fcb       $04
                    fcb       $04
WBIp_01AE           fdb       Lt_09A6
                    fcb       $06
                    fcb       $04
WBIp_01B2           fdb       Lt_09AA
                    fcb       $07
                    fcb       $04
WBIp_01B6           fdb       Lt_09AE
                    fcb       $08
                    fcb       $04
WBIp_01BA           fdb       Lt_09B2
                    fcb       $08
                    fcb       $04
WBIp_01BE           fdb       Lt_09B6
                    fcb       $09
                    fcb       $04
WBIp_01C2           fdb       Lt_09BA
                    fcb       $0A
                    fcb       $04
WBIp_01C6           fdb       Lt_09BE
                    fcb       $0C
                    fcb       $04
WBIp_01CA           fdb       Lt_09C2
                    fcb       $0D
                    fcb       $04
WBIp_01CE           fdb       Lt_09C6
                    fcb       $0E
                    fcb       $44
WBIp_01D2           fdb       Lt_09CA
                    fcb       $0F
                    fcb       $04
WBIp_01D6           fdb       Lt_09CE
                    fcb       $39
                    fcb       $05
WBIp_01DA           fdb       Lt_09D2
                    fcb       $3D
                    fcb       $05
WBIp_01DE           fdb       Lt_09D6
                    fcb       $12
                    fcb       $05
WBIp_01E2           fdb       Lt_09DA
                    fcb       $13
                    fcb       $05
WBIp_01E6           fdb       Lt_09DF
                    fcb       $19
                    fcb       $05
WBIp_01EA           fdb       Lt_09E3
                    fcb       $1D
                    fcb       $05
WBIp_01EE           fdb       Lt_09E7
                    fcb       $3A
                    fcb       $05
WBIp_01F2           fdb       Lt_09EB
                    fcb       $3B
                    fcb       $05
WBIp_01F6           fdb       Lt_09EF
                    fcb       $3F
                    fcb       $15
WBIp_01FA           fdb       Lt_09F4
                    fcb       $3F
                    fcb       $25
WBIp_01FE           fdb       Lt_09F9
                    fcb       $3F
                    fcb       $05
WBIp_0202           fdb       Lt_09FD
                    fcb       $30
                    fcb       $06
WBIp_0206           fdb       Lt_0A02
                    fcb       $31
                    fcb       $06
WBIp_020A           fdb       Lt_0A07
                    fcb       $32
                    fcb       $06
WBIp_020E           fdb       Lt_0A0C
                    fcb       $33
                    fcb       $06
WBIp_0212           fdb       Lt_0A11
                    fcb       $1F
                    fcb       $07
WBIp_0216           fdb       Lt_0A15
                    fcb       $1E
                    fcb       $07
WBIp_021A           fdb       Lt_0A19
                    fcb       $34
                    fcb       $08
WBIp_021E           fdb       Lt_0A1E
                    fcb       $35
                    fcb       $08
WBIp_0222           fdb       Lt_0A23
                    fcb       $36
                    fcb       $08
WBIp_0226           fdb       Lt_0A28
                    fcb       $37
                    fcb       $08
WBIp_022A           fdb       Lt_0A2D
                    fcb       $00
                    fcb       $19
WBIp_022E           fdb       Lt_0A30
                    fcb       $01
                    fcb       $0B
WBIp_0232           fdb       Lt_0A34
                    fcb       $02
                    fcb       $0B
WBIp_0236           fdb       Lt_0A38
                    fcb       $03
                    fcb       $0B
WBIp_023A           fdb       Lt_0A3C
                    fcb       $04
                    fcb       $0B
WBIp_023E           fdb       Lt_0A40
                    fcb       $0A
                    fcb       $0B
WBIp_0242           fdb       Lt_0A44
                    fcb       $06
                    fcb       $0B
WBIp_0246           fdb       Lt_0A4A
                    fcb       $00
                    fcb       $0D
WBIp_024A           fdb       Lt_0A50
                    fcb       $07
                    fcb       $0B
WBIp_024E           fdb       Lt_0A55
                    fcb       $07
                    fcb       $0C
WBIp_0252           fdb       Lt_0A5B
                    fcb       $09
                    fcb       $0B
WBIp_0256           fdb       Lt_0A5F
                    fcb       $00
                    fcb       $00
WBIp_025A           fdb       Lt_0A63
                    fcb       $00
                    fcb       $01
WBIp_025E           fdb       Lt_0A68
                    fcb       $00
                    fcb       $00
WBIp_0262           fdb       Lt_0A6C
                    fcb       $01
                    fcb       $00
WBIp_0266           fdb       Lt_0A70
                    fcb       $02
                    fcb       $00
WBIp_026A           fdb       Lt_0A74
                    fcb       $03
                    fcb       $00
WBIp_026E           fdb       Lt_0A78
                    fcb       $04
                    fcb       $00
WBIp_0272           fdb       Lt_0A7C
                    fcb       $0A
                    fcb       $00
WBIp_0276           fdb       Lt_0A80
                    fcb       $00
                    fcb       $01
WBIp_027A           fdb       Lt_0A85
                    fcb       $00
                    fcb       $00
WBIp_027E           fdb       Lt_0A89
                    fcb       $00
                    fcb       $01
WBIp_0282           fdb       Lt_0A8E
                    fcb       $00
                    fcb       $00
WBIp_0286           fdb       Lt_0A92
                    fcb       $01
                    fcb       $00
WBIp_028A           fdb       Lt_0A96
                    fcb       $02
                    fcb       $00
WBIp_028E           fdb       Lt_0A9A
                    fcb       $03
                    fcb       $00
WBIp_0292           fdb       Lt_0A9E
                    fcb       $04
                    fcb       $00
WBIp_0296           fdb       Lt_0AA2
                    fcb       $05
                    fcb       $00
WBIp_029A           fdb       Lt_0AA6
                    fcb       $09
                    fcb       $00
WBIp_029E           fdb       Lt_0AAB
                    fcb       $0A
                    fcb       $00
WBIp_02A2           fdb       Lt_0AB0
                    fcb       $0B
                    fcb       $00
WBIp_02A6           fdb       Lt_0AB5
                    fcb       $00
                    fcb       $01
WBIp_02AA           fdb       Lt_0ABA
                    fcb       $01
                    fcb       $01
WBIp_02AE           fdb       Lt_0ABF
                    fcb       $02
                    fcb       $01
WBIp_02B2           fdb       Lt_0AC4
                    fcb       $03
                    fcb       $01
WBIp_02B6           fdb       Lt_0AC9
                    fcb       $04
                    fcb       $01
WBIp_02BA           fdb       Lt_0ACE
                    fcb       $05
                    fcb       $01
WBIp_02BE           fdb       Lt_0AD3
                    fcb       $06
                    fcb       $01
WBIp_02C2           fdb       Lt_0AD8
                    fcb       $00
                    fcb       $02
WBIp_02C6           fdb       Lt_0ADD
                    fcb       $01
                    fcb       $02
WBIp_02CA           fdb       Lt_0AE2
                    fcb       $05
                    fcb       $03
WBIp_02CE           fdb       Lt_0AE6
                    fcb       $08
                    fcb       $03
WBIp_02D2           fdb       Lt_0AEA
                    fcb       $00
                    fcb       $04
WBIp_02D6           fdb       Lt_0AF0
                    fcb       $00
                    fcb       $05
WBIp_02DA           fdb       Lt_0AF5
                    fcb       $8D
                    fcb       $0A
WBIp_02DE           fdb       Lt_0AF9
                    fcb       $20
                    fcb       $0A
WBIp_02E2           fdb       Lt_0AFD
                    fcb       $21
                    fcb       $0A
WBIp_02E6           fdb       Lt_0B01
                    fcb       $22
                    fcb       $0A
WBIp_02EA           fdb       Lt_0B05
                    fcb       $23
                    fcb       $0A
WBIp_02EE           fdb       Lt_0B09
                    fcb       $24
                    fcb       $0A
WBIp_02F2           fdb       Lt_0B0D
                    fcb       $24
                    fcb       $0A
WBIp_02F6           fdb       Lt_0B11
                    fcb       $25
                    fcb       $0A
WBIp_02FA           fdb       Lt_0B15
                    fcb       $25
                    fcb       $0A
WBIp_02FE           fdb       Lt_0B19
                    fcb       $26
                    fcb       $0A
WBIp_0302           fdb       Lt_0B1D
                    fcb       $27
                    fcb       $0A
WBIp_0306           fdb       Lt_0B21
                    fcb       $28
                    fcb       $0A
WBIp_030A           fdb       Lt_0B25
                    fcb       $29
                    fcb       $0A
WBIp_030E           fdb       Lt_0B29
                    fcb       $2A
                    fcb       $0A
WBIp_0312           fdb       Lt_0B2D
                    fcb       $2B
                    fcb       $0A
WBIp_0316           fdb       Lt_0B31
                    fcb       $2C
                    fcb       $0A
WBIp_031A           fdb       Lt_0B35
                    fcb       $2D
                    fcb       $0A
WBIp_031E           fdb       Lt_0B39
                    fcb       $2E
                    fcb       $0A
WBIp_0322           fdb       Lt_0B3D
                    fcb       $2F
                    fcb       $0A
WBIp_0326           fdb       Lt_0D78
WBIp_0328           fdb       Lt_0D8D
WBIp_032A           fdb       Lt_0DF8
WBIp_032C           fdb       Lt_0D67
WBIp_032E           fdb       Lt_0F41
WBIp_0330           fdb       Lt_0F73
WBIp_0332           fdb       Lt_0E46
WBIp_0334           fdb       Lt_0E96
WBIp_0336           fdb       Lt_0EFD
WBIp_0338           fdb       Lt_0D78
WBIp_033A           fdb       Lt_0B41
WBIp_033C           fdb       Lt_0B4B
WBIp_033E           fdb       Lt_0B6C
WBIp_0340           fdb       Lt_0B85
WBIp_0342           fdb       Lt_0BC9
WBIp_0344           fdb       Lt_0C14
WBIp_0346           fdb       Lt_0C19
WBIp_0348           fdb       Lt_0C2C
WBIp_034A           fdb       Lt_0C92
WBIp_034C           fdb       Lt_0CCE
WBIp_034E           fdb       Lt_0D06
WBIp_0350           fdb       Lt_0D67
WBIp_0352           fdb       Lt_0D78
WBIp_0354           fdb       Lt_0E96
WBIp_0356           fdb       Lt_0D67
WBIp_0358           fdb       Lt_0F2A
WBIp_035A           fdb       Lt_0D67
WBIp_035C           fdb       SetCodeSection
WBIp_035E           fdb       Lt_0D67
WBIp_0360           fdb       InitSectionDefaults
                    fcb       $41
                    fcb       $00
                    fcb       $02
                    fcb       $42
                    fcb       $00
                    fcb       $04
                    fcb       $43
                    fcb       $43
                    fcb       $01
                    fcb       $44
                    fcb       $50
                    fcb       $08
                    fcb       $44
                    fcb       $00
                    fcb       $06
                    fcb       $58
                    fcb       $00
                    fcb       $10
                    fcb       $59
                    fcb       $00
                    fcb       $20
                    fcb       $55
                    fcb       $00
                    fcb       $40
                    fcb       $53
                    fcb       $00
                    fcb       $40
                    fcb       $50
                    fcb       $43
                    fcb       $80
                    fcb       $6C
WBIp_0381           fdb       OptionFlag
                    fcb       $6F
WBIp_0384           fdb       SectCount
                    fcb       $63
WBIp_0387           fdb       CondState
                    fcb       $66
WBIp_038A           fdb       U00C0
                    fcb       $67
WBIp_038D           fdb       U00C1
                    fcb       $65
WBIp_0390           fdb       U0001
                    fcb       $73
WBIp_0393           fdb       U00C7
                    fcb       $78
WBIp_0396           fdb       U0002
WBIp_0398           fdb       Lt_1734
WBIp_039A           fdb       Lt_1813
WBIp_039C           fdb       Lt_18D8
WBIp_039E           fdb       Lt_181E
WBIp_03A0           fdb       Lt_18C3
WBIp_03A2           fdb       Lt_17BF
WBIp_03A4           fdb       Lt_1BCD
WBIp_03A6           fdb       InitSectionDefaults
WBIp_03A8           fdb       Lt_17CA
WBIp_03AA           fdb       Lt_197F
WBIp_03AC           fdb       Lt_170E
WBIp_03AE           fdb       Lt_19CB
WBIp_03B0           fdb       ParseOptionList
WBIp_03B2           fdb       Lt_19FB
WBIp_03B4           fdb       Lt_1A07
WBIp_03B6           fdb       Lt_1A0E
WBIp_03B8           fdb       Lt_1B2F
WBIp_03BA           fdb       Lt_19C7
WBIp_03BC           fdb       Lt_1B0A
WBIp_03BE           fdb       Lt_19B6
WBIp_03C0           fdb       Lt_1CA5
WBIp_03C2           fdb       Lt_1CBC
WBIp_03C4           fdb       EndrDirective
WBIp_03C6           fdb       Lt_1B6B
WBIp_03C8           fdb       Lt_1B79
WBIp_03CA           fdb       Lt_1B87
WBIp_03CC           fdb       Lt_1B95
WBIp_03CE           fdb       Lt_1BA3
WBIp_03D0           fdb       Lt_1BB1
WBIp_03D2           fdb       IfPass2Handler
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $62
                    fcb       $CD
                    fcb       $23
                    fcb       $87
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
WBIp_03F4           fdb       IncludeStack
WBIp_03F6           fdb       ArgBuffer
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $01
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $02
                    fcb       $00
                    fcb       $38
                    fcb       $38
                    fcb       $28
                    fcb       $28
                    fcb       $28
                    fcb       $28
                    fcb       $28
                    fcb       $28
                    fcb       $28
                    fcb       $28
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $02
                    fcb       $22
                    fcb       $22
                    fcb       $22
                    fcb       $22
                    fcb       $22
                    fcb       $22
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $02
                    fcb       $00
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $04
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $27
                    fcb       $10
                    fcb       $03
                    fcb       $E8
                    fcb       $00
                    fcb       $64
                    fcb       $00
                    fcb       $0A
WBIp_0484           fdb       Y0484
                    fcb       $6C
                    fcb       $78
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $01
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $02
                    fcb       $00
                    fcb       $01
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $42
                    fcb       $00
                    fcb       $02
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00
                    fcb       $00

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
WBIblk2End          fdb       (reloc1End-reloc1Start)/2

                    * ---- reloc1: text relocation offsets
reloc1Start         fdb       HDRADV+WBIp_03A4-WBIblock2,HDRADV+WBIp_03A2-WBIblock2,HDRADV+WBIp_03A0-WBIblock2,HDRADV+WBIp_039E-WBIblock2,HDRADV+WBIp_039C-WBIblock2,HDRADV+WBIp_039A-WBIblock2,HDRADV+WBIp_0398-WBIblock2,HDRADV+WBIp_03B2-WBIblock2
                    fdb       HDRADV+WBIp_03B0-WBIblock2,HDRADV+WBIp_03AE-WBIblock2,HDRADV+WBIp_03AC-WBIblock2,HDRADV+WBIp_03AA-WBIblock2,HDRADV+WBIp_03A8-WBIblock2,HDRADV+WBIp_03A6-WBIblock2,HDRADV+WBIp_03C0-WBIblock2,HDRADV+WBIp_03BE-WBIblock2
                    fdb       HDRADV+WBIp_03BC-WBIblock2,HDRADV+WBIp_03BA-WBIblock2,HDRADV+WBIp_03B8-WBIblock2,HDRADV+WBIp_03B6-WBIblock2,HDRADV+WBIp_03B4-WBIblock2,HDRADV+WBIp_03CE-WBIblock2,HDRADV+WBIp_03CC-WBIblock2,HDRADV+WBIp_03CA-WBIblock2
                    fdb       HDRADV+WBIp_03C8-WBIblock2,HDRADV+WBIp_03C6-WBIblock2,HDRADV+WBIp_03C4-WBIblock2,HDRADV+WBIp_03C2-WBIblock2,HDRADV+WBIp_032E-WBIblock2,HDRADV+WBIp_032C-WBIblock2,HDRADV+WBIp_032A-WBIblock2,HDRADV+WBIp_0328-WBIblock2
                    fdb       HDRADV+WBIp_0326-WBIblock2,HDRADV+WBIp_03D2-WBIblock2,HDRADV+WBIp_03D0-WBIblock2,HDRADV+WBIp_033C-WBIblock2,HDRADV+WBIp_033A-WBIblock2,HDRADV+WBIp_0338-WBIblock2,HDRADV+WBIp_0336-WBIblock2,HDRADV+WBIp_0334-WBIblock2
                    fdb       HDRADV+WBIp_0332-WBIblock2,HDRADV+WBIp_0330-WBIblock2,HDRADV+WBIp_034A-WBIblock2,HDRADV+WBIp_0348-WBIblock2,HDRADV+WBIp_0346-WBIblock2,HDRADV+WBIp_0344-WBIblock2,HDRADV+WBIp_0342-WBIblock2,HDRADV+WBIp_0340-WBIblock2
                    fdb       HDRADV+WBIp_033E-WBIblock2,HDRADV+WBIp_0358-WBIblock2,HDRADV+WBIp_0356-WBIblock2,HDRADV+WBIp_0354-WBIblock2,HDRADV+WBIp_0352-WBIblock2,HDRADV+WBIp_0350-WBIblock2,HDRADV+WBIp_034E-WBIblock2,HDRADV+WBIp_034C-WBIblock2
                    fdb       HDRADV+WBIp_010E-WBIblock2,HDRADV+WBIp_010A-WBIblock2,HDRADV+WBIp_0106-WBIblock2,HDRADV+WBIp_0360-WBIblock2,HDRADV+WBIp_035E-WBIblock2,HDRADV+WBIp_035C-WBIblock2,HDRADV+WBIp_035A-WBIblock2,HDRADV+WBIp_012A-WBIblock2
                    fdb       HDRADV+WBIp_0126-WBIblock2,HDRADV+WBIp_0122-WBIblock2,HDRADV+WBIp_011E-WBIblock2,HDRADV+WBIp_011A-WBIblock2,HDRADV+WBIp_0116-WBIblock2,HDRADV+WBIp_0112-WBIblock2,HDRADV+WBIp_0146-WBIblock2,HDRADV+WBIp_0142-WBIblock2
                    fdb       HDRADV+WBIp_013E-WBIblock2,HDRADV+WBIp_013A-WBIblock2,HDRADV+WBIp_0136-WBIblock2,HDRADV+WBIp_0132-WBIblock2,HDRADV+WBIp_012E-WBIblock2,HDRADV+WBIp_0162-WBIblock2,HDRADV+WBIp_015E-WBIblock2,HDRADV+WBIp_015A-WBIblock2
                    fdb       HDRADV+WBIp_0156-WBIblock2,HDRADV+WBIp_0152-WBIblock2,HDRADV+WBIp_014E-WBIblock2,HDRADV+WBIp_014A-WBIblock2,HDRADV+WBIp_017E-WBIblock2,HDRADV+WBIp_017A-WBIblock2,HDRADV+WBIp_0176-WBIblock2,HDRADV+WBIp_0172-WBIblock2
                    fdb       HDRADV+WBIp_016E-WBIblock2,HDRADV+WBIp_016A-WBIblock2,HDRADV+WBIp_0166-WBIblock2,HDRADV+WBIp_019A-WBIblock2,HDRADV+WBIp_0196-WBIblock2,HDRADV+WBIp_0192-WBIblock2,HDRADV+WBIp_018E-WBIblock2,HDRADV+WBIp_018A-WBIblock2
                    fdb       HDRADV+WBIp_0186-WBIblock2,HDRADV+WBIp_0182-WBIblock2,HDRADV+WBIp_01B6-WBIblock2,HDRADV+WBIp_01B2-WBIblock2,HDRADV+WBIp_01AE-WBIblock2,HDRADV+WBIp_01AA-WBIblock2,HDRADV+WBIp_01A6-WBIblock2,HDRADV+WBIp_01A2-WBIblock2
                    fdb       HDRADV+WBIp_019E-WBIblock2,HDRADV+WBIp_01D2-WBIblock2,HDRADV+WBIp_01CE-WBIblock2,HDRADV+WBIp_01CA-WBIblock2,HDRADV+WBIp_01C6-WBIblock2,HDRADV+WBIp_01C2-WBIblock2,HDRADV+WBIp_01BE-WBIblock2,HDRADV+WBIp_01BA-WBIblock2
                    fdb       HDRADV+WBIp_01EE-WBIblock2,HDRADV+WBIp_01EA-WBIblock2,HDRADV+WBIp_01E6-WBIblock2,HDRADV+WBIp_01E2-WBIblock2,HDRADV+WBIp_01DE-WBIblock2,HDRADV+WBIp_01DA-WBIblock2,HDRADV+WBIp_01D6-WBIblock2,HDRADV+WBIp_020A-WBIblock2
                    fdb       HDRADV+WBIp_0206-WBIblock2,HDRADV+WBIp_0202-WBIblock2,HDRADV+WBIp_01FE-WBIblock2,HDRADV+WBIp_01FA-WBIblock2,HDRADV+WBIp_01F6-WBIblock2,HDRADV+WBIp_01F2-WBIblock2,HDRADV+WBIp_0226-WBIblock2,HDRADV+WBIp_0222-WBIblock2
                    fdb       HDRADV+WBIp_021E-WBIblock2,HDRADV+WBIp_021A-WBIblock2,HDRADV+WBIp_0216-WBIblock2,HDRADV+WBIp_0212-WBIblock2,HDRADV+WBIp_020E-WBIblock2,HDRADV+WBIp_0242-WBIblock2,HDRADV+WBIp_023E-WBIblock2,HDRADV+WBIp_023A-WBIblock2
                    fdb       HDRADV+WBIp_0236-WBIblock2,HDRADV+WBIp_0232-WBIblock2,HDRADV+WBIp_022E-WBIblock2,HDRADV+WBIp_022A-WBIblock2,HDRADV+WBIp_025E-WBIblock2,HDRADV+WBIp_025A-WBIblock2,HDRADV+WBIp_0256-WBIblock2,HDRADV+WBIp_0252-WBIblock2
                    fdb       HDRADV+WBIp_024E-WBIblock2,HDRADV+WBIp_024A-WBIblock2,HDRADV+WBIp_0246-WBIblock2,HDRADV+WBIp_027A-WBIblock2,HDRADV+WBIp_0276-WBIblock2,HDRADV+WBIp_0272-WBIblock2,HDRADV+WBIp_026E-WBIblock2,HDRADV+WBIp_026A-WBIblock2
                    fdb       HDRADV+WBIp_0266-WBIblock2,HDRADV+WBIp_0262-WBIblock2,HDRADV+WBIp_0296-WBIblock2,HDRADV+WBIp_0292-WBIblock2,HDRADV+WBIp_028E-WBIblock2,HDRADV+WBIp_028A-WBIblock2,HDRADV+WBIp_0286-WBIblock2,HDRADV+WBIp_0282-WBIblock2
                    fdb       HDRADV+WBIp_027E-WBIblock2,HDRADV+WBIp_02B2-WBIblock2,HDRADV+WBIp_02AE-WBIblock2,HDRADV+WBIp_02AA-WBIblock2,HDRADV+WBIp_02A6-WBIblock2,HDRADV+WBIp_02A2-WBIblock2,HDRADV+WBIp_029E-WBIblock2,HDRADV+WBIp_029A-WBIblock2
                    fdb       HDRADV+WBIp_02CE-WBIblock2,HDRADV+WBIp_02CA-WBIblock2,HDRADV+WBIp_02C6-WBIblock2,HDRADV+WBIp_02C2-WBIblock2,HDRADV+WBIp_02BE-WBIblock2,HDRADV+WBIp_02BA-WBIblock2,HDRADV+WBIp_02B6-WBIblock2,HDRADV+WBIp_02EA-WBIblock2
                    fdb       HDRADV+WBIp_02E6-WBIblock2,HDRADV+WBIp_02E2-WBIblock2,HDRADV+WBIp_02DE-WBIblock2,HDRADV+WBIp_02DA-WBIblock2,HDRADV+WBIp_02D6-WBIblock2,HDRADV+WBIp_02D2-WBIblock2,HDRADV+WBIp_0306-WBIblock2,HDRADV+WBIp_0302-WBIblock2
                    fdb       HDRADV+WBIp_02FE-WBIblock2,HDRADV+WBIp_02FA-WBIblock2,HDRADV+WBIp_02F6-WBIblock2,HDRADV+WBIp_02F2-WBIblock2,HDRADV+WBIp_02EE-WBIblock2,HDRADV+WBIp_0322-WBIblock2,HDRADV+WBIp_031E-WBIblock2,HDRADV+WBIp_031A-WBIblock2
                    fdb       HDRADV+WBIp_0316-WBIblock2,HDRADV+WBIp_0312-WBIblock2,HDRADV+WBIp_030E-WBIblock2,HDRADV+WBIp_030A-WBIblock2
reloc1End           equ       *

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       (reloc2End-reloc2Start)/2

                    * ---- reloc2: data relocation offsets
reloc2Start         fdb       HDRADV+WBIp_0381-WBIblock2,HDRADV+WBIp_03F6-WBIblock2,HDRADV+WBIp_03F4-WBIblock2,HDRADV+WBIp_0484-WBIblock2,HDRADV+WBIp_0384-WBIblock2,HDRADV+WBIp_0393-WBIblock2,HDRADV+WBIp_0396-WBIblock2,HDRADV+WBIp_0387-WBIblock2
                    fdb       HDRADV+WBIp_0390-WBIblock2,HDRADV+WBIp_038A-WBIblock2,HDRADV+WBIp_038D-WBIblock2,WBIp_0013-WBIblock1,WBIp_0011-WBIblock1,WBIp_000F-WBIblock1,WBIp_000D-WBIblock1,WBIp_000B-WBIblock1
                    fdb       WBIp_0009-WBIblock1,WBIp_0007-WBIblock1
reloc2End           equ       *

                    * ---- name: trailing module-name string
                    fcc       /c.asm/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end