                    nam       c.opt
                    ttl       program module

* Annotated 2026-07-14 (Claude Code):
*   - renamed disassembled labels to meaningful names
*   - added an inline comment to every instruction
*   - re-disassembled the "**** STACK OVERFLOW ****" banner that had
*     been decoded as instructions
*   - separated the direct-page globals from the startup code they had
*     been mis-resolved onto (disassembler assumed DP=$00); they are now
*     a direct-page equate block with the references repointed
*   - verified byte-identical to the original assembly (module CRC $D5C6D2)

                    use       defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $04

                    mod       eom,name,tylg,atrv,_start,size

                    * ------------------------------------------------------------------
                    * Data area (named rmb fields).  rmb reserves RAM without emitting
                    * bytes; OS-9 allocates <size> at load, cstart inits from WorkBlockImage.
                    * Names for ,y-referenced fields are derived from the code comments.
                    * ------------------------------------------------------------------
                    rmb       $1
GlbVar0001          rmb       $2
GlbVar0003          rmb       $2
GlbVar0005          rmb       $2
GlbVar0007          rmb       $2
GlbVar0009          rmb       $2
GlbVar000B          rmb       $2
GlbVar000D          rmb       $2
GlbVar000F          rmb       $2
GlbVar0011          rmb       $2
GlbVar0013          rmb       $2
GlbPtr0015          rmb       $2
GlbWord0017         rmb       $2
GlbWord0019         rmb       $2
GlbWord001B         rmb       $2
GlbVar001D          rmb       $2
GlbVar001F          rmb       $2
GlbWord0021         rmb       $2
LabelCtr            rmb       $2
NumericOptionValue  rmb       $2
StringArgument      rmb       $24
StringArgument2     rmb       $FB
OpcodeTable         rmb       $272
CtypeTab            rmb       $80
Pow10               rmb       $8
TableEnd            rmb       $2
WorkArea            rmb       $1
WorkArea2           rmb       $2
InputPathBuffer     rmb       $D
OutputPathBuffer    rmb       $D
OutputStream        rmb       $B6
PastTableEnd        rmb       $40
BreakPointer        rmb       $2
SeekBuffer          rmb       $2
ResultLowWord       rmb       $6
OldRegionPointer    rmb       $2
RegionLimit         rmb       $2
ErrorFlag           rmb       $2
InputFilePointer    rmb       $2
OutputFilePointer   rmb       $2
InputStream         rmb       $2
TableBase           rmb       $200
HashTable           rmb       $100
OutputPointer       rmb       $2
OutputBuffer        rmb       $A
ScratchBuffer       rmb       $A
LeftJustifyFlag     rmb       $2
PadCharacter        rmb       $2
UpdateFreeCount     rmb       $2
                    rmb       $B80     remaining data, bss and heap
size                equ       .

name                equ       *
                    fcs       /c.opt/
                    fcb       edition

* --- shared C runtime startup (see lib/cstart.asm) ---
RTBASE              equ       $0515     runtime-globals block base in the data area
DATAEND             equ       $0887     end of static data / heap start / stack limit
HDRADV              equ       $0023     advance to where the non-DP data starts
                    use       lib/cstart.asm

main                pshs      u         save frame pointer
                    leas      -8,s       reserve locals
                    leax      InputPathBuffer,y   point to input path buffer
                    stx       InputFilePointer,y   save input file pointer
                    leax      OutputPathBuffer,y   point to output path buffer
                    stx       OutputFilePointer,y   save output file pointer
                    clra                zero high byte
                    clrb                zero low byte
                    std       ,s        clear input file slot
SaveOutFileArg      std       $02,s     clear output file slot
                    lbra      MainArgLoop enter argument loop

ProcessArg          ldd       [$0e,s]   load current argv pointer
                    std       $04,s     save arg pointer local
                    tfr       d,x       arg pointer into X
                    ldb       ,x        get first character
                    cmpb      #$2d      leading dash
                    lbne      HandleFileArg not an option
                    ldx       $04,s     reload arg pointer
                    leax      $01,x     skip the dash
                    stx       $04,s     save advanced pointer
                    ldb       ,x        get option letter
                    sex                 sign-extend to D
                    tfr       d,x       option letter into X
                    lbra      DispatchOpt dispatch on option

SetFlag0007         ldd       #$0001    flag value one
                    std       GlbVar0007 set statistics option flag
                    lbra      MainArgLoop back to argument loop

HandleOptI          clra                zero high byte
                    clrb                zero low byte
                    std       >NumericOptionValue,y  clear numeric option value
                    ldx       $04,s     reload arg pointer
                    leax      $01,x     skip option letter
                    stx       $04,s     save pointer
                    ldb       ,x        get next character
                    cmpb      #$3d      equals sign
                    beq       NextOptChar parse number after equals
                    ldd       $04,s     reload pointer
                    addd      #$FFFF    back up one character
                    std       $04,s     save pointer
                    bra       NextOptChar parse digits

AccumDigitLoop      ldd       >NumericOptionValue,y  load running value
                    pshs      d         save it
                    ldd       #$000A    multiplier ten
                    lbsr      MulEntry  multiply value by ten
                    pshs      d         save product
                    ldd       $08,s     reload digit character
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add to scaled value
                    std       >NumericOptionValue,y  store accumulated number
NextOptChar         ldx       $04,s     reload pointer
                    leax      $01,x     advance pointer
                    stx       $04,s     save pointer
                    ldb       ,x        get next digit character
                    sex                 sign-extend
                    std       $06,s     save character
                    bne       AccumDigitLoop accumulate if nonzero
                    bra       MainArgLoop back to argument loop

UnknownOpt          ldd       $04,s     reload arg pointer
                    addd      #$FFFF    back up one character
                    std       $04,s     save pointer
                    pshs      d         push bad option pointer
                    leax      MsgUnknownOption,pcr point to error format
                    pshs      x         push format string
                    lbsr      FatalError report unknown option
                    leas      4,s        clean up arguments
                    bra       MainArgLoop back to argument loop

DispatchOpt         stx       -$02,s    save option letter
                    lbeq      SetFlag0007 empty option sets flag
                    cmpx      #$0069    letter i
                    lbeq      HandleOptI handle i option
                    bra       UnknownOpt unknown option

HandleFileArg       ldd       $02,s     output file already set
                    bne       SetInFile try input slot
                    ldd       $04,s     load arg pointer
                    lbra      SaveOutFileArg save as output file

SetInFile           ldd       ,s        input file already set
                    bne       TooManyFiles too many files
                    ldd       $04,s     load arg pointer
                    std       ,s        save as input file
                    bra       MainArgLoop back to argument loop

TooManyFiles        leax      MsgTooManyFiles,pcr point to error format
                    pshs      x         push format string
                    lbsr      FatalError report extra file error
                    leas      2,s        clean up argument
MainArgLoop         ldd       $0e,s     load argv pointer
                    addd      #$0002    advance to next argv
                    std       $0e,s     save argv pointer
                    ldd       $0C,s     load remaining count
                    addd      #$FFFF    decrement count
                    std       $0C,s     save count
                    lbne      ProcessArg process next argument
                    ldd       $02,s     output file specified
                    beq       CheckInFile skip if none
                    leax      InputPathBuffer,y   point to output path buffer
                    pshs      x         push buffer pointer
                    leax      StrModeR,pcr point to open mode string
                    pshs      x         push mode
                    ldd       $06,s     load output filename
                    pshs      d         push filename
                    lbsr      AssembleOperandAlloc open output file
                    leas      6,s        clean up arguments
                    std       InputFilePointer,y   save output file handle
                    bne       CheckInFile continue if opened
                    ldd       $02,s     reload output filename
                    pshs      d         push filename
                    leax      MsgCantOpenIn,pcr point to error format
                    pshs      x         push format
                    lbsr      FatalError report open failure
                    leas      4,s        clean up arguments
CheckInFile         ldd       ,s        input file specified
                    beq       RunPasses skip if none
                    leax      StrModeW,pcr point to open mode string
                    pshs      x         push mode
                    ldd       $02,s     load input filename
                    pshs      d         push filename
                    lbsr      AssembleOperand open input file
                    leas      4,s        clean up arguments
                    std       OutputFilePointer,y   save input file handle
                    bne       RunPasses continue if opened
                    ldd       ,s        reload input filename
                    pshs      d         push filename
                    leax      MsgCantOpenOut,pcr point to error format
                    pshs      x         push format
                    lbsr      FatalError report open failure
                    leas      4,s        clean up arguments
RunPasses           ldd       OutputFilePointer,y   load input file handle
                    std       InputStream,y   set current input stream
                    lbsr      InitHashTable run pass one
                    lbsr      InitLineState run pass two
                    lbsr      BuildOpcodeHash run pass three
                    lbsr      OptMain   finalize output
                    ldd       GlbVar0007 statistics flag set
                    lbeq      MainDone  skip stats if clear
                    leas      -4,s       reserve print args
                    leax      MsgStatistics,pcr point to format string
                    pshs      x         push format
                    leax      OutputStream,y   point to output stream
                    pshs      x         push stream
                    lbsr      fprintf   print statistics header
                    leas      4,s        clean up arguments
                    ldd       GlbVar0009 load a counter
                    pshs      d         push value
                    leax      MsgTotalInsns,pcr point to format string
                    pshs      x         push format
                    leax      OutputStream,y   point to output stream
                    pshs      x         push stream
                    lbsr      fprintf   print statistic line
                    leas      6,s        clean up arguments
                    ldd       GlbWord0019 load byte count
                    pshs      d         push value
                    ldd       GlbWord001B load second count
                    pshs      d         push value
                    lbsr      ComputeRatio compute ratio
                    leas      4,s        clean up arguments
                    pshs      d         push computed ratio
                    ldd       GlbWord001B load count
                    pshs      d         push value
                    ldd       GlbWord0019 load count
                    pshs      d         push value
                    leax      MsgLongBranches,pcr point to format string
                    pshs      x         push format
                    leax      OutputStream,y   point to output stream
                    pshs      x         push stream
                    lbsr      fprintf   print statistic line
                    leas      10,s       clean up arguments
                    ldd       GlbVar0009 load counter
                    pshs      d         push value
                    ldd       GlbWord0021 load count
                    pshs      d         push value
                    lbsr      ComputeRatio compute ratio
                    leas      4,s        clean up arguments
                    pshs      d         push ratio
                    ldd       GlbWord0021 load count
                    pshs      d         push value
                    leax      MsgRemoved,pcr point to format string
                    pshs      x         push format
                    leax      OutputStream,y   point to output stream
                    pshs      x         push stream
                    lbsr      fprintf   print statistic line
                    leas      8,s        clean up arguments
                    ldd       GlbWord001B load count
                    aslb                shift low byte left
                    rola                rotate into high byte
                    std       ,s        save doubled value
                    pshs      d         push value
                    ldd       GlbWord0021 load count
                    pshs      d         push value
                    bsr       ScalePercent scale to percentage
                    leas      2,s        clean up argument
                    addd      ,s++      add doubled count
                    std       ,s        save total
                    ldd       GlbVar0009 load counter
                    pshs      d         push value
                    bsr       ScalePercent scale to percentage
                    leas      2,s        clean up argument
                    std       $02,s     save result
                    pshs      d         push value
                    ldd       $02,s     reload result
                    pshs      d         push value
                    bsr       ComputeRatio compute ratio
                    leas      4,s        clean up arguments
                    pshs      d         push ratio
                    ldd       $02,s     reload value
                    pshs      d         push value
                    ldd       $06,s     load counter
                    pshs      d         push value
                    leax      MsgTotalBytes,pcr point to format string
                    pshs      x         push format
                    leax      OutputStream,y   point to output stream
                    pshs      x         push stream
                    lbsr      fprintf   print statistic line
                    leas      10,s       clean up arguments
                    leas      4,s        clean up locals
MainDone            leas      8,s        release locals
                    puls      pc,u      restore frame and return

ScalePercent        pshs      u         save frame pointer
                    ldd       $04,s     load argument
                    addd      $04,s     double it
                    pshs      d         save doubled value
                    ldd       $06,s     load second argument
                    pshs      d         push it
                    ldd       #$0003    scale factor three
                    lbsr      MulEntry  multiply
                    pshs      d         save product
                    ldd       #$0005    divisor five
                    lbsr      SDivMod   divide
                    addd      ,s++      add saved offset
                    puls      pc,u      restore frame and return

ComputeRatio        pshs      u         save frame pointer
                    ldd       $06,s     load divisor argument
                    beq       RetZero   avoid divide by zero
                    ldd       $04,s     load dividend
                    pshs      d         push value
                    ldd       $08,s     load scaled numerator
                    addd      #$0032    add rounding half
                    pshs      d         push value
                    ldd       #$0064    hundred
                    lbsr      UDivMod   scale by hundred
                    lbsr      UDivMod   continue scaling
                    bra       RetExit   return computed ratio

RetZero             clra                clear high byte of zero return
                    clrb                clear low byte of zero return
RetExit             puls      pc,u      restore frame and return

OptMain             pshs      u         save caller frame pointer
                    leas      -228,s     allocate local stack frame
                    clra                clear high byte
                    clrb                clear low byte
                    std       $0C,s     clear local list head
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000F clear section-open flag
                    std       GlbVar000D clear current section type
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000B clear line counter
                    lbra      ReadLineLoop enter main read-line loop

ProcessLine         leau      $0080,s   point at start of line buffer
                    bra       EolScanLoop begin end-of-line scan

EolNext             leau      $01,u     advance scan pointer
EolScanLoop         ldb       ,u        read line character
                    cmpb      #C$CR      test for carriage return
                    bne       EolNext   keep scanning until carriage return
                    clra                clear high byte of terminator
                    clrb                clear low byte of terminator
                    stb       ,u        null-terminate the line
                    ldd       GlbVar000B load line counter
                    addd      #$0001    increment it
                    std       GlbVar000B store updated line count
                    leax      $0080,s   point at line buffer
                    stx       $06,s     save line pointer local
                    ldb       [$06,s]   read first character
                    lbeq      ReadLineLoop skip empty line
                    ldb       [$06,s]   reload first character
                    cmpb      #$2a      test for comment star
                    lbeq      ReadLineLoop skip comment line
                    leax      ,s        point at output field buffer
                    pshs      x         push destination arg
                    ldd       $08,s     load line pointer
                    pshs      d         push source arg
                    leax      $78,s     point at label buffer
                    pshs      x         push buffer arg
                    ldd       #$0001    field index one
                    pshs      d         push index arg
                    lbsr      CopyField copy the label field
                    leas      8,s        drop call arguments
                    std       $06,s     save updated line pointer
                    pshs      d         push line pointer arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    ldd       #$0002    field index two
                    pshs      d         push index arg
                    lbsr      CopyField copy the opcode field
                    leas      6,s        drop call arguments
                    bra       SkipWsLoop skip leading whitespace

SkipWsNext          ldd       $06,s     load line pointer
                    addd      #$0001    advance one character
SkipWsLoop          std       $06,s     store advanced pointer
                    ldb       [$06,s]   read current character
                    cmpb      #$20      test for space
                    beq       SkipWsNext skip spaces
                    ldb       [$06,s]   reload character
                    cmpb      #$09      test for tab
                    lbeq      SkipWsNext skip tabs
                    ldb       $69,s     load first opcode character
                    sex                 sign-extend to word
                    tfr       d,x       move into X for dispatch
                    lbra      DispatchDirective dispatch on opcode letter

MatchEndsect        leax      OpEndsect,pcr point at endsect keyword
                    pshs      x         push keyword arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    lbsr      StrCmp    compare the two strings
                    leas      4,s        drop call arguments
                    std       -$02,s    save compare result
                    lbne      DefaultLine not endsect, handle as instruction
                    lbsr      EmitEndsect flush current section
                    ldd       #$0001    flag value one means open
StoreSectFlag       std       GlbVar000F mark section open
                    lbra      ReadLineLoop next line

MatchInfo           leax      OpInfo,pcr point at info keyword
                    pshs      x         push keyword arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    lbsr      StrCmp    compare the two strings
                    leas      4,s        drop call arguments
                    std       -$02,s    save compare result
                    lbeq      SectPassThru matched info, handle section
                    lbra      DefaultLine not info, handle as instruction

MatchNam            leax      OpNam,pcr point at nam keyword
                    pshs      x         push keyword arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    lbsr      StrCmp    compare the two strings
                    leas      4,s        drop call arguments
                    std       -$02,s    save compare result
                    lbne      DefaultLine not nam, handle as instruction
                    bra       EmitPassLine pass line through unchanged

ResetFrame          leas      $FF1C,x   reset stack to entry frame
EmitPassLine        leax      $0080,s   point at line buffer
                    pshs      x         push string arg
                    leax      FmtPctSCr,pcr point at %s format
                    pshs      x         push format arg
                    ldd       OutputFilePointer,y   load output file pointer
EmitFmtLine         pshs      d         push file arg
                    lbsr      fprintf   print the line verbatim
                    leas      6,s        drop call arguments
                    lbra      ReadLineLoop next line

MatchPsect          leax      OpPsect,pcr point at psect keyword
                    pshs      x         push keyword arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    lbsr      StrCmp    compare the two strings
                    leas      4,s        drop call arguments
                    std       -$02,s    save compare result
                    lbne      DefaultLine not psect, handle as instruction
                    lbsr      EmitEndsect flush current section
                    lbra      SectPassThru handle the new section

MatchTtl            leax      OpTtl,pcr point at ttl keyword
                    pshs      x         push keyword arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    lbsr      StrCmp    compare the two strings
                    leas      4,s        drop call arguments
                    std       -$02,s    save compare result
                    beq       SectPassThru matched ttl, handle section
                    lbra      DefaultLine not ttl, handle as instruction

MatchVsect          leax      OpVsect,pcr point at vsect keyword
                    pshs      x         push keyword arg
                    leax      $6b,s     point at opcode buffer
                    pshs      x         push buffer arg
                    lbsr      StrCmp    compare the two strings
                    leas      4,s        drop call arguments
                    std       -$02,s    save compare result
                    lbne      DefaultLine not vsect, handle as instruction
                    ldb       [$06,s]   read next character
                    cmpb      #$64      test for letter d
                    bne       SectNumOne default section number
                    ldx       $06,s     load line pointer
                    ldb       $01,x     read following character
                    cmpb      #$70      test for letter p
                    bne       SectNumOne default section number
                    ldd       #$0002    section number two for dp
                    bra       StoreSectNum store the section number

SectNumOne          ldd       #$0001    section number one
StoreSectNum        std       $02,s     save the section number
                    ldd       GlbVar000D load current section type
                    cmpd      $02,s     compare with the new one
                    bne       SwitchSect different, switch section
                    ldd       GlbVar000F load section-open flag
                    beq       SwitchSect not open, switch section
                    clra                clear high byte
                    clrb                clear low byte
                    lbra      StoreSectFlag clear open flag and continue

SwitchSect          lbsr      EmitEndsect flush current section
                    ldd       $02,s     load new section number
                    std       GlbVar000D set current section type
SectPassThru        leax      $00E4,s   point at frame base
                    lbra      ResetFrame reset stack and pass through

DispatchDirective   cmpx      #$0065    test opcode letter e
                    lbeq      MatchEndsect dispatch to endsect handler
                    cmpx      #$0069    test opcode letter i
                    lbeq      MatchInfo dispatch to info handler
                    cmpx      #$006E    test opcode letter n
                    lbeq      MatchNam  dispatch to nam handler
                    cmpx      #$0070    test opcode letter p
                    lbeq      MatchPsect dispatch to psect handler
                    cmpx      #$0074    test opcode letter t
                    lbeq      MatchTtl  dispatch to ttl handler
                    cmpx      #$0076    test opcode letter v
                    lbeq      MatchVsect dispatch to vsect handler
DefaultLine         lbsr      EmitEndsect flush current section
                    ldd       GlbVar000D load current section type
                    beq       HandleLabelField no section, handle label field
                    leax      $0080,s   point at line buffer
                    pshs      x         push string arg
                    leax      FmtPctSCr2,pcr point at %s format
                    pshs      x         push format arg
                    ldd       InputStream,y   load output file pointer
                    lbra      EmitFmtLine print the line

HandleLabelField    ldb       $74,s     load label field first char
                    beq       HandleOpcodeField no label, handle opcode
                    leax      $74,s     point at label field
                    pshs      x         push arg
                    lbsr      HashLookup look up label in table
                    leas      2,s        drop arg
                    std       $0a,s     save symbol pointer
                    bne       MarkLabelUsed found, mark it used
                    leax      $74,s     point at label field
                    pshs      x         push arg
                    lbsr      HashInsert insert label into table
                    leas      2,s        drop arg
                    std       $0a,s     save symbol pointer
MarkLabelUsed       ldd       ,s        load flag
                    beq       ListAppendInit skip mark if zero
                    ldx       $0a,s     load symbol pointer
                    ldd       $0a,x     load symbol flags
                    orb       #$01      set the defined bit
                    std       $0a,x     store flags back
ListAppendInit      ldd       $0a,s     load symbol pointer
                    bra       ListWalkTest enter list walk

ListWalkLoop        ldx       $08,s     load list node
                    ldd       $08,x     load its next link
ListWalkTest        std       $08,s     save current node
                    ldx       $08,s     reload node
                    ldd       $08,x     load its next link
                    bne       ListWalkLoop walk to end of list
                    ldd       $0C,s     load pending list head
                    ldx       $08,s     load last node
                    std       $08,x     link head onto tail
                    ldd       $0a,s     load new symbol
                    std       $0C,s     make it the new head
HandleOpcodeField   ldb       $69,s     load opcode field char
                    beq       ReadLineLoop no opcode, next line
                    ldd       $06,s     load line pointer
                    pshs      d         push source arg
                    leax      $10,s     point at operand buffer
                    pshs      x         push buffer arg
                    ldd       #$0003    field index three
                    pshs      d         push index arg
                    lbsr      CopyField copy the operand field
                    leas      6,s        drop call arguments
                    leax      $0C,s     point at list head arg
                    pshs      x         push arg
                    leax      $10,s     point at operand buffer
                    pshs      x         push arg
                    leax      $6d,s     point at opcode buffer
                    pshs      x         push arg
                    leax      >GlbPtr0015,y  point at opcode pattern table
                    pshs      x         push arg
                    lbsr      AddLineNode match opcode and operand pattern
                    leas      8,s        drop call arguments
                    std       -$02,s    save match result
                    beq       CountInsn no match, just count it
                    ldd       GlbWord0017 load matched instruction
                    pshs      d         push arg
                    lbsr      OptBranchPass apply peephole transform
                    leas      2,s        drop arg
                    ldd       GlbWord0017 reload instruction
                    pshs      d         push arg
                    lbsr      OptimizeInsnList emit optimized instruction
                    leas      2,s        drop arg
CountInsn           ldd       GlbVar0009 load instruction count
                    addd      #$0001    increment it
                    std       GlbVar0009 store updated count
                    ldd       GlbVar0013 load buffered byte count
                    cmpd      >NumericOptionValue,y  compare against flush threshold
                    blt       ReadLineLoop below limit, read next line
                    lbsr      PrintInsn flush output buffer
ReadLineLoop        ldd       InputFilePointer,y   load input file pointer
                    pshs      d         push file arg
                    ldd       #$0064    max line length one hundred
                    pshs      d         push arg
                    leax      $0084,s   point at line buffer
                    pshs      x         push buffer arg
                    lbsr      ReadCountedChars read next input line
                    leas      6,s        drop call arguments
                    std       -$02,s    save read result
                    lbne      ProcessLine got a line, process it
                    ldd       $0C,s     load pending list head
                    beq       FinishFlush none pending, finish
                    leax      $0C,s     point at list head arg
                    pshs      x         push arg
                    leax      StrEmpty,pcr point at empty string
                    pshs      x         push arg
                    leax      OpNop,pcr point at nop mnemonic
                    pshs      x         push arg
                    leax      >GlbPtr0015,y  point at opcode table
                    pshs      x         push arg
                    lbsr      AddLineNode emit dangling labels as nop
                    leas      8,s        drop call arguments
FinishFlush         bsr       EmitEndsect flush current section
                    bra       DrainTest drain the output

DrainLoop           lbsr      PrintInsn flush output buffer
DrainTest           ldd       GlbVar0013 load buffered count
                    bne       DrainLoop drain until empty
                    leas      228,s      release local frame
                    puls      pc,u      return to caller

EmitEndsect         pshs      u         save caller frame pointer
                    ldd       GlbVar000F load section-open flag
                    beq       EmitEndsectRet nothing open, return
                    ldd       GlbVar000D load section type
                    beq       EndsectDrainTest data section, just drain
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000D clear section type
                    bra       EmitEndsectStr emit the endsect line

EndsectDrainLoop    lbsr      PrintInsn flush output buffer
EndsectDrainTest    ldd       GlbVar0013 load buffered count
                    bne       EndsectDrainLoop drain until empty
EmitEndsectStr      leax      StrEndsect,pcr point at endsect string
                    pshs      x         push string arg
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push file arg
                    lbsr      fprintf   print the endsect line
                    leas      4,s        drop call arguments
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar000F clear section-open flag
EmitEndsectRet      puls      pc,u      return to caller

MsgUnknownOption    fcc       /unknown option '%s'/
                    fcb       C$CR,C$NULL
MsgTooManyFiles     fcc       /too many files/
                    fcb       C$NULL
StrModeR            fcb       $72
                    fcb       C$NULL
MsgCantOpenIn       fcc       /can't open %s/
                    fcb       C$NULL
StrModeW            fcb       $77
                    fcb       C$NULL
MsgCantOpenOut      fcc       /can't open %s/
                    fcb       C$NULL
MsgStatistics       fcc       /statistics:/
                    fcb       C$CR,C$NULL
MsgTotalInsns       rol       $0074     total-instructions message data
                    fcc       /otal instructions : %d/
                    fcb       C$CR,C$NULL
MsgLongBranches     rol       $006C     long-branches message data
                    fcc       /ong branches :  %5d, %5d, %3d%%/
                    fcb       C$CR,C$NULL
MsgRemoved          rol       $0072     removed message data
                    fcc       /emoved       :         %5d, %3d%%/
                    fcb       C$CR,C$NULL
MsgTotalBytes       rol       $0074     total-bytes message data
                    fcc       /otal bytes   :  %5d, %5d, %3d%%/
                    fcb       C$CR,C$NULL
OpEndsect           fcc       /endsect/
                    fcb       C$NULL
OpInfo              fcc       /info/
                    fcb       C$NULL
OpNam               fcb       $6E,$61,$6D
                    fcb       C$NULL
FmtPctSCr           fcb       $25,$73
                    fcb       C$CR,C$NULL
OpPsect             fcc       /psect/
                    fcb       C$NULL
OpTtl               fcb       $74,$74,$6C
                    fcb       C$NULL
OpVsect             fcc       /vsect/
                    fcb       C$NULL
FmtPctSCr2          fcb       $25,$73
                    fcb       C$CR,C$NULL
OpNop               fcb       $6E,$6F,$70
                    fcb       C$NULL
StrEmpty            fcb       C$NULL
StrEndsect          fcc       / endsect/
                    fcb       C$CR,C$NULL
CopyField           pshs      u         save caller frame pointer
                    ldu       $06,s     load destination pointer
                    leas      -2,s       allocate local counter
                    ldx       $06,s     load source pointer
                    lbra      ParseTypeDispatch enter the copy loop

CopyFieldInit       ldd       #$000B    maximum field width eleven
                    std       ,s        save remaining count
                    ldb       [$0a,s]   read source character
                    cmpb      #$20      test for space
                    lbeq      ParseDone stop on space
                    ldb       [$0a,s]   reload character
                    cmpb      #$09      test for tab
                    lbeq      ParseDone stop on tab
CopyFieldLoop       ldx       $0a,s     load source pointer
                    leax      $01,x     advance it
                    stx       $0a,s     save advanced pointer
                    ldb       -$01,x    read the character
                    stb       ,u+       store into destination
                    ldd       ,s        load remaining count
                    addd      #$FFFF    decrement it
                    std       ,s        save the count
                    beq       CopyCheckWs width exhausted, stop
                    ldb       [$0a,s]   read next character
                    sex                 sign-extend for index
                    leax      CtypeTab,y point at character-class table
                    leax      d,x       index by character value
                    ldb       ,x        load class byte
                    clra                clear high byte
                    andb      #$0f      mask the class bits
                    bne       CopyFieldLoop still in field, keep copying
                    bra       CopyCheckWs delimiter reached, stop

CopySkipWs          ldd       $0a,s     load source pointer
                    addd      #$0001    advance one character
                    std       $0a,s     store advanced pointer
CopyCheckWs         ldb       [$0a,s]   read character
                    sex                 sign-extend char value as class index
                    leax      CtypeTab,y point to the character class table
                    leax      d,x       index the table by character
                    ldb       ,x        load the character class byte
                    clra                clear high byte
                    andb      #$0f      extract the class low nibble
                    bne       CopySkipWs keep scanning identifier characters
                    ldb       [$0a,s]   read the current source char
                    cmpb      #$3a      test for a colon
                    bne       NoColon   no colon so clear the flag
                    ldd       #$0001    set the colon-seen flag
                    bra       StoreColonFlag go store the flag

NoColon             clra                clear high byte of flag
                    clrb                clear the colon flag
StoreColonFlag      std       [$0C,s]   store colon flag to caller
                    lbeq      ParseDone no colon so parse is done
                    ldd       $0a,s     load the source pointer
                    addd      #$0001    advance past the colon
                    std       $0a,s     save the pointer
                    lbra      ParseDone parse is done

ParseType2          ldd       #$000A    set field width of ten
                    std       ,s        init the copy counter
                    bra       SkipSpace2 skip leading whitespace

SkipSpace2Loop      ldd       $0a,s     load the source pointer
                    addd      #$0001    advance the pointer
                    std       $0a,s     save the pointer
SkipSpace2          ldb       [$0a,s]   read the current char
                    cmpb      #$20      test for a space
                    beq       SkipSpace2Loop skip the space
                    ldb       [$0a,s]   read the current char
                    cmpb      #$09      test for a tab
                    lbeq      SkipSpace2Loop skip the tab
                    bra       CopyChar2Test begin the copy test

CopyChar2Loop       ldx       $0a,s     load the source pointer
                    leax      $01,x     advance the pointer
                    stx       $0a,s     save the pointer
                    ldb       -$01,x    read the char
                    stb       ,u+       copy char to output buffer
CopyChar2Test       ldd       ,s        load remaining count
                    addd      #$FFFF    decrement the count
                    std       ,s        save the count
                    subd      #$FFFF    test if count exhausted
                    beq       SkipTail2 count done so skip the rest
                    ldb       [$0a,s]   read the current char
                    sex                 sign-extend as class index
                    leax      CtypeTab,y point to class table
                    leax      d,x       index by character
                    ldb       ,x        load the class byte
                    clra                clear high byte
                    andb      #$0f      extract the class nibble
                    bne       CopyChar2Loop copy while identifier char
                    bra       SkipTail2 skip trailing chars

SkipTail2Loop       ldd       $0a,s     load the pointer
                    addd      #$0001    advance the pointer
                    std       $0a,s     save the pointer
SkipTail2           ldb       [$0a,s]   read the current char
                    sex                 sign-extend as class index
                    leax      CtypeTab,y point to class table
                    leax      d,x       index by character
                    ldb       ,x        load the class byte
                    clra                clear high byte
                    andb      #$0f      extract the class nibble
                    bne       SkipTail2Loop skip remaining identifier chars
                    lbra      ParseDone parse is done

ParseType3          ldd       #$005A    set field width of ninety
                    std       ,s        init the copy counter
                    bra       SkipSpace3 skip leading whitespace

SkipSpace3Loop      ldd       $0a,s     load the pointer
                    addd      #$0001    advance the pointer
                    std       $0a,s     save the pointer
SkipSpace3          ldb       [$0a,s]   read the current char
                    cmpb      #$20      test for a space
                    beq       SkipSpace3Loop skip the space
                    ldb       [$0a,s]   read the current char
                    cmpb      #$09      test for a tab
                    lbeq      SkipSpace3Loop skip the tab
                    bra       CopyChar3Test begin the copy test

CopyChar3Loop       ldx       $0a,s     load the pointer
                    leax      $01,x     advance the pointer
                    stx       $0a,s     save the pointer
                    ldb       -$01,x    read the char
                    stb       ,u+       copy char to output buffer
CopyChar3Test       ldd       ,s        load remaining count
                    addd      #$FFFF    decrement the count
                    std       ,s        save the count
                    subd      #$FFFF    test if count exhausted
                    beq       ParseDone count done so finish
                    ldb       [$0a,s]   read the current char
                    bne       CopyChar3Loop copy until the null terminator
                    bra       ParseDone parse is done

ParseBadType        ldd       $06,s     load the bad type value
                    pshs      d         push it for the message
                    leax      >MsgBadType,pcr point to the error format
                    pshs      x         push the format
                    lbsr      FatalError print the error message
                    leas      4,s        clean up the arguments
                    bra       ParseDone parse is done

ParseTypeDispatch   cmpx      #$0001    is it type one
                    lbeq      CopyFieldInit parse type one
                    cmpx      #$0002    is it type two
                    lbeq      ParseType2 parse type two
                    cmpx      #$0003    is it type three
                    lbeq      ParseType3 parse type three
                    bra       ParseBadType otherwise report a bad type

ParseDone           clra                clear high byte
                    clrb                clear the terminator
                    stb       ,u        null-terminate the output
                    ldd       $0a,s     return the source pointer
                    leas      2,s        drop the local
                    puls      pc,u      restore and return

MsgBadType          fcc       /parse called with bad type : %d/
                    fcb       C$NULL
InitHashTable       pshs      u,d       save regs and reserve a local
                    leax      TableBase,y   point to the hash table base
                    stx       ,s        save the table pointer
                    ldu       #$0000    init the bucket index
                    bra       InitBucketTest enter the init loop

InitBucketLoop      ldd       ,s        load the current entry pointer
                    ldx       ,s        load the entry pointer
                    std       $02,x     set forward link to itself
                    std       [,s]      set back link to itself
                    ldd       ,s        load the entry pointer
                    addd      #$0004    advance to the next entry
                    std       ,s        save the pointer
                    leau      $01,u     next bucket index
InitBucketTest      cmpu      #$0080    done all 128 buckets
                    blt       InitBucketLoop loop over the buckets
                    lbra      PopUReturn return

HashInsert          pshs      u,d       save regs and reserve a local
                    lbsr      AllocNode allocate a node
                    std       ,s        save the node pointer
                    ldd       $06,s     load the key string
                    pshs      d         push the string
                    lbsr      HashString compute the hash
                    leas      2,s        clean up the argument
                    aslb                multiply the hash by four
                    rola                multiply the hash by four
                    aslb                multiply the hash by four
                    rola                multiply the hash by four
                    leax      TableBase,y   point to the table base
                    leax      d,x       index to the bucket
                    leau      ,x        set u to the bucket head
                    ldd       $06,s     load the key string
                    pshs      d         push the string
                    ldd       $02,s     load the node pointer
                    addd      #$000C    offset to the node key field
                    pshs      d         push the destination
                    lbsr      StrCopy   copy the key string in
                    leas      4,s        clean up the arguments
                    stu       [,s]      store node into bucket slot
                    ldd       $02,u     load the bucket forward link
                    ldx       ,s        load the bucket pointer
                    std       $02,x     link node into the bucket
                    ldd       ,s        load the node pointer
                    std       [$02,u]   finish linking the node
                    ldd       ,s        load the node pointer
                    std       $02,u     finish linking the node
                    ldd       ,s        return the node pointer
                    lbra      PopUReturn return

HashLookup          pshs      u,x,d     save the registers
                    ldd       $08,s     load the key string
                    pshs      d         push the string
                    bsr       HashString compute the hash
                    leas      2,s        clean up the argument
                    aslb                multiply the hash by four
                    rola                multiply the hash by four
                    aslb                multiply the hash by four
                    rola                multiply the hash by four
                    leax      TableBase,y   point to the table base
                    leax      d,x       index to the bucket
                    stx       ,s        save the bucket pointer
                    ldd       [,s]      load the first node
                    bra       LookupTest enter the lookup loop

LookupLoop          ldd       $02,s     load the node pointer
                    addd      #$000C    offset to the node key
                    pshs      d         push the key pointer
                    ldd       $0a,s     load the search key
                    pshs      d         push the search key
                    lbsr      StrCmp    compare the strings
                    leas      4,s        clean up the arguments
                    std       -$02,s    save the compare result
                    bne       LoadNextNode no match so advance
                    ldd       $02,s     return the matching node
                    bra       LookupDone lookup is done

LoadNextNode        ldd       [$02,s]   load the next node
LookupTest          std       $02,s     save the current node
                    ldd       $02,s     load the current node
                    cmpd      ,s        reached the bucket head
                    bne       LookupLoop continue the lookup
                    clra                clear high byte for not found
                    clrb                clear result for not found
LookupDone          leas      4,s        clean up the stack
                    puls      pc,u      restore and return

HashString          pshs      u         save u
                    ldu       $04,s     load the string pointer
                    leas      -2,s       reserve a local
                    clra                clear high byte of hash
                    clrb                clear the hash accumulator
                    bra       HashTest  enter the hash loop

HashLoop            ldd       ,s        load the accumulator
                    pshs      d         push it
                    ldb       ,u+       load the next character
                    sex                 sign-extend the character
                    addd      ,s++      add character to the hash
HashTest            std       ,s        save the hash
                    ldb       ,u        peek the next character
                    bne       HashLoop  loop until the null terminator
                    ldd       ,s        load the final hash
                    clra                clear high byte
                    andb      #$7f      mask hash to 0-127
PopUReturn          leas      2,s        clean up the local
                    puls      pc,u      restore and return

AllocNode           pshs      u         save u
                    ldu       GlbVar0011 load the free list head
                    beq       AllocFromHeap empty so allocate from heap
                    ldd       ,u        unlink the node
                    std       GlbVar0011 update the free list head
                    clra                clear high byte
                    clrb                clear low byte
                    std       $0a,u     clear a node field
                    std       $08,u     clear a node field
                    std       $06,u     clear a node field
                    std       $04,u     clear a node field
                    bra       AllocReturn return the node

AllocFromHeap       ldd       #$0018    node size is 24 bytes
                    pshs      d         push the size
                    lbsr      LookupOpcode allocate memory
                    leas      2,s        clean up the argument
                    tfr       d,u       set u to the new node
AllocReturn         tfr       u,d       return the node pointer
                    puls      pc,u      restore and return

FreeNode            pshs      u         save u
                    ldu       $04,s     load the node pointer
                    ldd       $04,u     check reference field four
                    bne       FreeDone  still referenced so keep it
                    ldd       $06,u     check reference field six
                    bne       FreeDone  still referenced so keep it
                    ldd       ,u        unlink the node
                    std       [$02,u]   relink the neighbor
                    ldd       $02,u     load the forward link
                    ldx       ,u        load the back link
                    std       $02,x     relink the neighbors
                    ldd       GlbVar0011 load the free list head
                    std       ,u        chain node onto the free list
                    stu       GlbVar0011 update the free list head
FreeDone            puls      pc,u      restore and return

GenLabel            pshs      u         save u
                    ldd       >LabelCtr,y load the label counter
                    addd      #$0001    increment the counter
                    std       >LabelCtr,y save the counter
                    pshs      d         push the counter
                    leax      >MsgLabelFmt,pcr point to the label format
                    pshs      x         push the format
                    ldd       $08,s     load the destination buffer
                    pshs      d         push the destination
                    lbsr      Sprintf   format the label string
                    leas      6,s        clean up the arguments
                    puls      pc,u      restore and return

MsgLabelFmt         clrb                label format string data
                    bcc       $0A7B     label format string data
                    lsr       0,x       label format string data
SearchStrings       pshs      u         save u
                    ldu       $06,s     load the array start
                    bra       SearchTest enter the search loop

SearchLoop          ldd       ,u        load the array string
                    pshs      d         push it
                    ldd       $06,s     load the target string
                    pshs      d         push it
                    lbsr      StrCmp    compare the strings
                    leas      4,s        clean up the arguments
                    std       -$02,s    save the compare result
                    lbeq      AllocDone match found
                    leau      $02,u     advance to the next entry
SearchTest          cmpu      $08,s     reached the array end
                    bcs       SearchLoop continue the search
                    clra                clear high byte for not found
                    clrb                clear result for not found
                    puls      pc,u      restore and return

InitLineState       pshs      u         save u
                    leax      >GlbPtr0015,y  point to the line buffer
                    stx       GlbWord0017 set the buffer end pointer
                    tfr       x,d       copy pointer to d
                    std       GlbPtr0015 set the buffer start pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar001D clear a global
                    std       GlbVar001F clear a global
                    std       GlbVar0013 reset the byte counter
                    puls      pc,u      restore and return

AddLineNode         pshs      u         save u
                    leas      -10,s      reserve local variables
                    lbsr      AllocInsnNode allocate a line node
                    tfr       d,u       set u to the node
                    ldd       $14,s     load the list head
                    beq       NoTailNode list is empty
                    ldd       [$14,s]   load the tail node
                    bra       SetNodeBack go set the back link

NoTailNode          clra                clear high byte for null tail
                    clrb                clear low byte for null tail
SetNodeBack         std       $04,u     set the node back link
                    beq       CopyLineText list empty so skip linking
                    ldd       [$14,s]   load the current tail
                    bra       FindTailTest enter the link loop

FindTailLoop        ldx       $08,s     load the tail node
                    stu       $04,x     link the node
                    ldx       $08,s     load the node
                    ldd       $08,x     advance to the next
FindTailTest        std       $08,s     save the pointer
                    ldd       $08,s     load the pointer
                    bne       FindTailLoop walk to the tail
                    clra                clear high byte
                    clrb                clear low byte
                    std       [$14,s]   update the list head
CopyLineText        ldd       $10,s     load the source string
                    pshs      d         push it
                    pshs      u         push the node
                    ldd       #$0008    offset to the node text
                    addd      ,s++      add the node base
                    pshs      d         push the destination
                    lbsr      StrCopy   copy text into the node
                    leas      4,s        clean up the arguments
                    ldd       $12,s     load the text pointer
                    std       $04,s     save the working pointer
                    tfr       d,x       copy pointer to x
                    ldb       ,x        read the first char
                    beq       StrlenDone empty string
StrlenLoop          ldx       $04,s     load the pointer
                    leax      $01,x     advance the pointer
                    stx       $04,s     save the pointer
                    ldb       ,x        read the char
                    bne       StrlenLoop scan to end of the string
StrlenDone          ldd       $04,s     load the end pointer
                    subd      $12,s     compute the string length
                    std       ,s        save the length
                    ldd       $0e,s     load the list tail
                    std       ,u        set node forward link
                    ldx       $0e,s     load the list tail
                    ldd       $02,x     load its back link
                    std       $02,u     copy the back link
                    ldx       $0e,s     load the list tail
                    stu       [$02,x]   link node into the list
                    ldx       $0e,s     load the list tail
                    stu       $02,x     finish linking the node
                    ldd       GlbVar0013 load the line count
                    addd      #$0001    increment the count
                    std       GlbVar0013 save the count
                    leax      $08,u     point to the node text
                    stx       $06,s     save the text pointer
                    ldb       ,x        read the first opcode char
                    sex                 sign-extend the char
                    tfr       d,x       copy to x
                    lbra      DispatchOperand dispatch on the opcode

CheckBranchOp       ldx       $06,s     load the text pointer
                    leax      $01,x     advance the pointer
                    stx       $06,s     save the pointer
                    ldb       ,x        read the next char
                    cmpb      #$62      test for letter b
                    lbne      EmitInsnTail not a branch so handle elsewhere
MatchBranchOp       leax      >StringArgument2,y  point to a string argument
                    pshs      x         push it
                    leax      >StringArgument,y  point to a string argument
                    pshs      x         push it
                    ldd       $0a,s     load the pointer
                    addd      #$0001    advance the pointer
                    pshs      d         push it
                    lbsr      SearchStrings search the string list
                    leas      6,s        clean up the arguments
                    std       $02,s     save the result
                    lbeq      EmitInsnTail not found
                    ldd       $06,u     load a node field
                    pshs      d         push it
                    leax      >StringArgument,y  point to a string argument
                    pshs      x         push it
                    ldd       $06,s     load a value
                    subd      ,s++      compute the difference
                    pshs      d         push the difference
                    ldd       #$0002    set the argument count
                    lbsr      SDivMod   call the helper routine
                    orb       #$60      set operand-mode bits in low byte
                    ora       ,s+       merge high flag byte from stack
                    orb       ,s+       merge low flag byte from stack
                    std       $06,u     store combined flags into node
                    ldd       [$02,s]   load field indirectly through arg
                    pshs      d         push the value
                    pshs      u         push node pointer
                    ldd       #$0008    offset eight
                    addd      ,s++      compute node plus eight address
                    pshs      d         push that address
                    lbsr      StrCopy   call copy helper
                    leas      4,s        drop the arguments
                    leax      ,s        point at local buffer
                    pshs      x         push buffer pointer
                    ldd       $14,s     load argument
                    pshs      d         push it
                    ldd       $16,s     load next argument
                    pshs      d         push it
                    ldd       #$0001    flag value one
                    pshs      d         push it
                    lbsr      CopyField call insert helper
                    leas      8,s        drop the arguments
                    ldd       $12,s     load operand argument
                    pshs      d         push it
                    lbsr      HashLookup look up matching node
                    leas      2,s        drop argument
                    std       $08,s     save matched node
                    leax      >StringArgument,y  load sentinel address
                    cmpx      $02,s     compare against sentinel
                    bne       BumpReplaceCount branch when not sentinel
                    ldd       $08,s     load matched node
                    beq       ChkNodeRef skip if none matched
                    ldx       $08,s     load matched node
                    ldd       $04,x     load its next field
                    beq       ChkNodeRef skip if next empty
                    ldx       $08,s     reload matched node
                    ldd       $04,x     load next field
                    pshs      d         push it
                    pshs      u         push current node
                    lbsr      UnlinkInsn unlink the duplicate instruction
                    leas      4,s        drop the arguments
ChkNodeRef          ldd       $04,u     load node reference field
                    bne       SetKeepFlag branch if already referenced
                    leax      >GlbPtr0015,y  load other sentinel address
                    cmpx      $02,u     compare node source
                    beq       SetKeepFlag branch if from sentinel
                    ldx       $02,u     load node source
                    ldd       $06,x     load its flags
                    anda      #$01      isolate bit zero
                    clrb                clear low byte
                    std       -$02,s    save the test flag
                    beq       SetKeepFlag branch if bit clear
                    pshs      u         push current node
                    lbsr      FreeOperand remove the instruction
                    leas      2,s        drop argument
                    ldd       GlbWord0021 load delete counter
                    addd      #$0001    add one
                    std       GlbWord0021 bump the delete counter
                    clra                clear result high
                    clrb                clear result low
                    lbra      OptExit   return null via exit

SetKeepFlag         ldd       $06,u     load node flags
                    ora       #$01      set keep bit zero
                    std       $06,u     store flags
BumpReplaceCount    ldd       GlbWord0019 load replace counter
                    addd      #$0001    add one
                    std       GlbWord0019 bump the replace counter
                    ldd       $08,s     load matched node
                    bne       SetEmitFlag branch if already found
                    ldd       $12,s     load operand argument
                    pshs      d         push it
                    lbsr      HashInsert create a new node
                    leas      2,s        drop argument
                    std       $08,s     save the new node
SetEmitFlag         ldd       $06,u     load node flags
                    ora       #$02      set emitted bit one
                    std       $06,u     store flags
                    ldd       $08,s     load result node
                    std       $13,u     store operand pointer in node
                    pshs      d         push node value
                    pshs      u         push current node
                    lbsr      LinkRefNode link the new reference node
                    leas      4,s        drop the arguments
                    bra       EmitInsnTail jump to emit tail

MatchPuls           leax      StrPuls,pcr load 'puls' string
                    pshs      x         push string pointer
                    ldd       $08,s     load mnemonic pointer
                    pshs      d         push it
                    lbsr      StrCmp    compare the strings
                    leas      4,s        drop the arguments
                    std       -$02,s    save comparison result
                    bne       EmitInsnTail not puls, go to tail
                    leax      StrPcSuffix,pcr load ',pc' string
                    pshs      x         push string pointer
                    ldd       $14,s     load base address
                    addd      $02,s     add offset
                    addd      #$FFFD    back up three bytes
                    bra       CmpMnemonic join the compare path

MatchRts            leax      StrRts,pcr load 'rts' string
                    pshs      x         push string pointer
                    ldd       $08,s     load mnemonic pointer
CmpMnemonic         pshs      d         push it
                    lbsr      StrCmp    compare the strings
                    leas      4,s        drop the arguments
                    std       -$02,s    save comparison result
                    bne       EmitInsnTail no match, go to tail
                    ldd       $06,u     load node flags
                    ora       #$01      set keep bit zero
                    std       $06,u     store flags
                    bra       EmitInsnTail branch to emit tail

DispatchOperand     cmpx      #$006C    is operand type l
                    lbeq      CheckBranchOp handle the l case
                    cmpx      #$0062    is operand type b
                    lbeq      MatchBranchOp handle the b case
                    cmpx      #$0070    is operand type p
                    beq       MatchPuls handle the puls case
                    cmpx      #$0072    is operand type r
                    beq       MatchRts  handle the rts case
EmitInsnTail        ldd       $06,u     load node flags
                    clra                clear high byte
                    andb      #$20      test emitted bit five
                    bne       ReturnNode skip emit if already set
                    ldd       $12,s     load operand argument
                    pshs      d         push it
                    ldd       $02,s     load matched node
                    pshs      d         push it
                    lbsr      AllocStrBuf emit the output instruction
                    leas      2,s        drop argument
                    std       $13,u     store operand pointer in node
                    pshs      d         push returned value
                    lbsr      StrCopy   free the temporary
                    leas      4,s        drop the arguments
ReturnNode          tfr       u,d       return the node pointer
OptExit             leas      10,s       drop local frame
                    puls      pc,u      restore and return

AllocInsnNode       pshs      u         save caller register
                    ldu       GlbVar001D load free-list head
                    bne       ReuseFreeNode reuse if a free node exists
                    ldd       GlbVar001F load allocation counter
                    addd      #$0001    add one
                    std       GlbVar001F bump the allocation counter
                    pshs      d         push it
                    ldd       >NumericOptionValue,y  load current instruction count
                    addd      #$0003    add margin of three
                    cmpd      ,s++      compare against limit
                    bge       AllocFresh within limit, continue
                    leax      MsgRunOut,pcr load out-of-instructions message
                    pshs      x         push message pointer
                    lbsr      FatalError report the error
                    leas      2,s        drop argument
AllocFresh          ldd       #$0015    node size twenty-one
                    pshs      d         push it
                    lbsr      LookupOpcode allocate the memory
                    leas      2,s        drop argument
                    tfr       d,u       new node into u
                    bra       AllocDone go to return

ReuseFreeNode       ldd       ,u        load next free pointer
                    std       GlbVar001D unlink from free list
                    clra                clear high
                    clrb                clear low
                    std       $13,u     clear operand field
                    std       $06,u     clear the flags
AllocDone           tfr       u,d       return the node pointer
                    puls      pc,u      restore and return

LinkRefNode         pshs      u         save caller register
                    lbsr      AllocRefCell allocate a reference node
                    tfr       d,u       new node into u
                    ldd       $04,s     load value argument
                    std       $02,u     store into node
                    ldx       $06,s     load target node argument
                    ldd       $06,x     load its chain head
                    std       ,u        chain existing into new node
                    ldx       $06,s     reload target node
                    stu       $06,x     store new node as chain head
                    puls      pc,u      restore and return

UnlinkInsn          pshs      u,d       save registers and locals
                    ldd       $06,s     load first node
                    cmpd      $08,s     compare to target
                    lbeq      FreeOperandDone done if it is the target
                    ldx       $06,s     load first node
                    ldu       $04,x     load head of the chain
                    lbeq      FreeOperandDone done if chain empty
UnlinkLoop          stu       ,s        remember current node
                    ldd       $08,s     load the target
                    std       $04,u     relink current past target
                    ldu       $08,u     advance to next node
                    bne       UnlinkLoop loop until end of chain
                    ldx       $08,s     load target node
                    ldd       $04,x     load its reference field
                    ldx       ,s        load current node
                    std       $08,x     append it to current
                    ldx       $06,s     load first node
                    ldd       $04,x     load its reference field
                    ldx       $08,s     load target node
                    std       $04,x     move head ref onto target
                    clra                clear high
                    clrb                clear low
                    ldx       $06,s     load first node
                    std       $04,x     clear its reference field
                    lbra      FreeOperandDone return

PrintInsn           pshs      u,d       save registers and locals
                    ldu       GlbPtr0015 load global reference node
                    pshs      u         push it
                    leax      >GlbPtr0015,y  load sentinel address
                    cmpx      ,s++      compare against sentinel
                    bne       ChkRefChain branch if not sentinel
                    leax      MsgTooManyRemoved,pcr load too-many-instructions message
                    pshs      x         push message pointer
                    lbsr      FatalError report the error
                    leas      2,s        drop argument
ChkRefChain         ldd       $06,u     load node flags
                    clra                clear high byte
                    andb      #$60      isolate bits five and six
                    cmpd      #$0060    both bits set
                    bne       PrintLabels skip if not both set
                    ldd       #$0004    scan type four
                    pshs      d         push it
                    pshs      u         push node
                    lbsr      AdjustRefs scan back references
                    leas      4,s        drop the arguments
PrintLabels         ldd       $04,u     load reference chain head
                    std       ,s        save the iterator
                    beq       RefLoopCond skip if no references
                    ldd       #$0005    scan type five
                    pshs      d         push it
                    pshs      u         push node
                    lbsr      AdjustRefs scan references
                    bra       DropScanArgs drop scan arguments

PrintRefLoop        ldd       ,s        load current reference node
                    addd      #$000C    offset to operand text
                    pshs      d         push it
                    leax      FmtStr,pcr load '%s' format
                    pshs      x         push format pointer
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    lbsr      fprintf   print the label operand
                    leas      6,s        drop the arguments
                    ldx       ,s        reload iterator
                    ldd       $0a,x     load node flags
                    clra                clear high byte
                    andb      #$01      test bit zero
                    beq       NextRefLabel skip separator if clear
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    ldd       #$003A    colon character
                    pshs      d         push it
                    lbsr      $1FB2     output the colon
                    leas      4,s        drop the arguments
NextRefLabel        ldx       ,s        reload iterator
                    ldd       $08,x     load next reference
                    std       ,s        advance the iterator
                    beq       RefLoopCond stop if end of chain
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    ldd       #$000D    separator character
                    pshs      d         push it
                    lbsr      $1FB2     output the separator
DropScanArgs        leas      4,s        drop scan arguments
RefLoopCond         ldd       ,s        load iterator
                    bne       PrintRefLoop loop while references remain
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    ldd       #$0020    space character
                    pshs      d         push it
                    lbsr      $1FB2     output the space
                    leas      4,s        drop the arguments
                    ldd       $06,u     load node flags
                    clra                clear high byte
                    andb      #$20      test bit five
                    beq       EmitMnemonic branch if clear
                    ldd       $06,u     load node flags
                    anda      #$02      test bit one
                    clrb                clear low byte
                    std       -$02,s    save the test flag
                    beq       UseOperand branch if clear
                    ldd       $13,u     load operand pointer
                    addd      #$000C    offset to operand text
                    bra       EmitBranch merge with emit path

UseOperand          ldd       $13,u     load operand pointer
EmitBranch          pshs      d         push it
                    pshs      u         push node
                    ldd       #$0008    offset eight
                    addd      ,s++      compute node plus eight
                    pshs      d         push mnemonic address
                    ldd       $06,u     load node flags
                    clra                clear high byte
                    andb      #$40      test bit six
                    beq       NoSuffix  branch if clear
                    leax      StrLongPrefix,pcr load 'l' suffix string
                    bra       FmtBranch go set suffix

NoSuffix            leax      StrEmpty2,pcr load empty suffix string
FmtBranch           tfr       x,d       suffix pointer into d
                    pshs      d         push it
                    leax      FmtBranchInsn,pcr load branch format string
                    pshs      x         push format pointer
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    lbsr      fprintf   print the branch instruction
                    leas      10,s       drop the arguments
                    bra       EmitNewline go to newline

EmitMnemonic        pshs      u         push node
                    ldd       #$0008    offset eight
                    addd      ,s++      compute node plus eight
                    pshs      d         push mnemonic address
                    leax      FmtStrB,pcr load '%s' format
                    pshs      x         push format pointer
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    lbsr      fprintf   print the mnemonic
                    leas      6,s        drop the arguments
                    ldb       [$13,u]   load first operand char
                    beq       EmitNewline skip if no operand
                    ldd       $13,u     load operand pointer
                    pshs      d         push it
                    leax      FmtSpaceStr,pcr load ' %s' format
                    pshs      x         push format pointer
                    ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    lbsr      fprintf   print the operand text
                    leas      6,s        drop the arguments
EmitNewline         ldd       OutputFilePointer,y   load output file pointer
                    pshs      d         push it
                    ldd       #$000D    carriage return character
                    pshs      d         push it
                    lbsr      $1FB2     output the newline
                    leas      4,s        drop the arguments
                    pshs      u         push node
                    lbsr      FreeOperand release the instruction node
                    leas      2,s        drop argument
                    lbra      FreeOperandDone return

AdjustRefs          pshs      u,y,x,d   save registers and locals
                    ldu       $0a,s     load node argument
                    ldd       $0C,s     load type argument
                    cmpd      #$0004    is type four
                    lbne      ScanOtherType handle other types
                    ldd       $06,u     load node flags
                    anda      #$02      test bit one
                    clrb                clear low byte
                    std       -$02,s    save the test flag
                    beq       ResolveOperand branch if clear
                    ldd       $13,u     use operand pointer directly
                    bra       HaveTarget go to merge point

ResolveOperand      ldd       $13,u     load operand pointer
                    pshs      d         push it
                    lbsr      HashLookup resolve to operand node
                    leas      2,s        drop argument
HaveTarget          std       $02,s     save resolved node
                    lbeq      ScanDone  done if null
                    ldx       $02,s     load resolved node
                    ldd       $04,x     load its reference field
                    std       $04,s     save it
                    lbeq      ScanDone  done if null
                    ldd       #$0024    loop limit thirty-six
                    bra       ScanFwdCond enter the scan loop

ScanFwdLoop         cmpu      $04,s     current equals target
                    bne       DecCounter no, decrement and continue
                    ldd       $06,u     load node flags
                    orb       #$80      set found bit seven
                    std       $06,u     store flags
                    ldx       $0a,s     load node argument
                    ldd       $06,x     load its flags
                    andb      #$BF      clear bit six
                    std       $06,x     store flags
                    lbra      BumpMatchCount count it and finish

DecCounter          ldd       ,s        load counter
                    addd      #$FFFF    decrement it
ScanFwdCond         std       ,s        store the counter
                    ldd       ,s        reload counter
                    lbeq      ScanDone  done if exhausted
                    ldu       ,u        follow to next node
                    pshs      u         push it
                    leax      >GlbPtr0015,y  load sentinel address
                    cmpx      ,s++      reached sentinel
                    bne       ScanFwdLoop loop if not
                    lbra      ScanDone  done

ScanOtherType       ldd       #$0024    loop limit thirty-six
                    bra       ChainCountStore enter second scan loop

ScanRefLoop2        ldd       $06,u     load node flags
                    clra                clear high byte
                    andb      #$60      isolate bits five and six
                    cmpd      #$0060    both bits set
                    bne       NextChainNode skip if not both set
                    ldd       $06,u     load node flags
                    anda      #$02      test bit one
                    clrb                zero the low byte to build result
                    std       -$02,s    store result to local temp
                    beq       MapOperand branch when operand is zero
                    ldd       $13,u     load the operand field
                    bra       OperandReady join the common operand path

MapOperand          ldd       $13,u     load the operand field
                    pshs      d         pass operand as argument
                    lbsr      HashLookup call helper to map operand
                    leas      2,s        drop the argument
OperandReady        std       $02,s     save the mapped operand value
                    beq       NextChainNode branch if operand is null
                    ldd       $0a,s     load the saved node
                    ldx       $02,s     load the mapped result pointer
                    cmpd      $04,x     compare against its target field
                    bne       NextChainNode branch if the targets differ
                    ldd       $06,u     load the instruction flags
                    andb      #$BF      clear the $40 flag bit
                    std       $06,u     store the updated flags
BumpMatchCount      ldd       GlbWord001B load the global match counter
                    addd      #$0001    increment the counter
                    std       GlbWord001B store the counter back
                    bra       ScanDone  done with this node

NextChainNode       ldd       ,s        load the loop counter
                    addd      #$FFFF    decrement the counter
ChainCountStore     std       ,s        store the updated counter
                    ldd       ,s        reload the counter
                    beq       ScanDone  exit loop when it reaches zero
                    ldu       ,u        follow the link to the next node
                    pshs      u         save the node pointer
                    leax      >GlbPtr0015,y  address the list-head sentinel
                    cmpx      ,s++      compare node against the sentinel
                    lbne      ScanRefLoop2 loop while not at the list head
ScanDone            leas      6,s        release the locals
                    puls      pc,u      restore register and return

FreeOperand         pshs      u         save the register
                    ldu       $04,s     load the node argument
                    leas      -2,s       reserve a local word
                    ldd       $06,u     load the node flags
                    clra                keep only the low byte
                    andb      #$20      test the $20 flag bit
                    beq       FreeOperandStr branch when the flag is clear
                    ldd       $13,u     load the operand reference pointer
                    pshs      d         pass operand as argument
                    pshs      u         pass the node as argument
                    bsr       RemoveRef unlink the operand reference
                    leas      4,s        drop the arguments
                    bra       OperandFreed continue past the else branch

FreeOperandStr      ldd       $13,u     load the operand string pointer
                    pshs      d         pass it as argument
                    lbsr      FreeStrBuf free the operand string buffer
                    leas      2,s        drop the argument
OperandFreed        ldd       $04,u     load the node's list-head field
                    bra       ClearFieldTest enter the field-clearing loop test

ClearFieldLoop      clra                clear high byte
                    clrb                clear low byte for zero
                    ldx       ,s        load the current node
                    std       $04,x     clear its field $04
                    ldd       ,s        load the node
                    pshs      d         pass it as argument
                    lbsr      FreeNode  call the helper
                    leas      2,s        drop the argument
                    ldx       ,s        reload the node
                    ldd       $08,x     load its next link
ClearFieldTest      std       ,s        store as current node
                    ldd       ,s        reload the node
                    bne       ClearFieldLoop loop while node is non-null
                    ldd       ,u        load the node's forward link
                    std       [$02,u]   patch the predecessor link
                    ldd       $02,u     load the back link
                    ldx       ,u        load the forward link
                    std       $02,x     patch the successor back link
                    ldd       GlbVar001D load the free-list head
                    std       ,u        link the node into the free list
                    stu       GlbVar001D update the free-list head
                    ldd       GlbVar0013 load the live allocation count
                    addd      #$FFFF    decrement the count
                    std       GlbVar0013 store the count back
FreeOperandDone     leas      2,s        release the local
                    puls      pc,u      restore register and return

RemoveRef           pshs      u,x,d     save the working registers
                    ldd       $0a,s     load the list argument
                    beq       RemoveRefDone exit if the list is empty
                    ldd       $0a,s     reload the list pointer
                    addd      #$0006    point at its link field
                    bra       RemoveRefAdvance enter the search loop

RemoveRefLoop       ldx       $02,s     load the current entry
                    ldd       $02,x     load its key
                    cmpd      $08,s     compare with the target key
                    bne       RemoveRefNext branch when it does not match
                    ldd       [$02,s]   load the matched node's link
                    std       [,s]      unlink the matched node
                    ldd       $0a,s     load the list argument
                    pshs      d         pass it as argument
                    lbsr      FreeNode  call the helper
                    leas      2,s        drop the argument
                    ldd       $02,s     load the matched node
                    pshs      d         pass it as argument
                    bsr       FreeRefCell free the reference cell
                    leas      2,s        drop the argument
                    bra       RemoveRefDone done after removal

RemoveRefNext       ldd       $02,s     load the current entry
RemoveRefAdvance    std       ,s        store it as cursor
                    ldd       [,s]      load the next link
                    std       $02,s     save the next entry
                    bne       RemoveRefLoop loop while entry is non-null
RemoveRefDone       leas      4,s        release the locals
                    puls      pc,u      restore register and return

AllocRefCell        pshs      u         save the register
                    ldu       GlbVar0001 load the free-list head
                    beq       AllocRefNew allocate when the list is empty
                    ldd       ,u        load the next free cell
                    std       GlbVar0001 pop it from the free list
                    bra       AllocRefInit use the popped cell

AllocRefNew         ldd       #$0004    request four bytes
                    pshs      d         pass the size
                    lbsr      LookupOpcode call the raw allocator
                    leas      2,s        drop the argument
                    tfr       d,u       move pointer into u
AllocRefInit        clra                clear high byte
                    clrb                clear low byte for zero
                    std       $02,u     clear the cell field
                    bra       ClearAndReturn finish and return the cell

FreeRefCell         pshs      u         save the register
                    ldu       $04,s     load the cell argument
                    ldd       GlbVar0001 load the free-list head
                    std       ,u        link the cell in front
                    stu       GlbVar0001 update the free-list head
                    puls      pc,u      restore register and return

AllocStrBuf         pshs      u         save the register
                    ldd       $04,s     load the size argument
                    cmpd      #$0010    compare against sixteen
                    bge       AllocLargePool use the large pool when big
                    ldu       GlbVar0003 load the small free list
                    beq       AllocSmallNew allocate when it is empty
                    ldd       ,u        load the next free cell
                    std       GlbVar0003 pop it from the small list
                    bra       AllocBufInit use the popped cell

AllocSmallNew       ldd       #$0010    request sixteen bytes
                    bra       AllocBufMalloc allocate the buffer

AllocLargePool      ldu       GlbVar0005 load the large free list
                    beq       AllocLargeNew allocate when it is empty
                    ldd       ,u        load the next free cell
                    std       GlbVar0005 pop it from the large list
                    bra       AllocBufInit use the popped cell

AllocLargeNew       ldd       #$005B    request ninety-one bytes
AllocBufMalloc      pshs      d         pass the size
                    lbsr      LookupOpcode call the raw allocator
                    leas      2,s        drop the argument
                    tfr       d,u       move pointer into u
AllocBufInit        clra                clear high byte
                    clrb                clear low byte for zero
ClearAndReturn      std       ,u        clear the cell header
                    tfr       u,d       return the pointer in d
                    puls      pc,u      restore register and return

FreeStrBuf          pshs      u         save the register
                    ldu       $04,s     load the string argument
                    beq       FreeBufDone skip when the pointer is null
                    bra       StrLenTest enter the length loop

StrLenLoop2         leau      $01,u     advance the pointer
StrLenTest          ldb       ,u        load the current character
                    bne       StrLenLoop2 loop until the terminator
                    tfr       u,d       copy the end pointer
                    subd      $04,s     compute the string length
                    cmpd      #$0010    compare against sixteen
                    bge       FreeLargeBuf use large list when long
                    ldd       GlbVar0003 load the small free-list head
                    std       [$04,s]   link the buffer in
                    ldd       $04,s     load the buffer pointer
                    std       GlbVar0003 push onto the small free list
                    bra       FreeBufDone done

FreeLargeBuf        ldd       GlbVar0005 load the large free-list head
                    std       [$04,s]   link the buffer in
                    ldd       $04,s     load the buffer pointer
                    std       GlbVar0005 push onto the large free list
FreeBufDone         puls      pc,u      restore register and return

                    fcb       $72,$61
                    fcb       C$NULL
                    fcb       $73,$72
                    fcb       C$NULL
                    fcb       $65,$71
                    fcb       C$NULL
                    fcb       $6E,$65
                    fcb       C$NULL
                    fcb       $6C,$74
                    fcb       C$NULL
                    fcb       $67,$65
                    fcb       C$NULL
                    fcb       $6C,$65
                    fcb       C$NULL
                    fcb       $67,$74
                    fcb       C$NULL
                    fcb       $6C,$6F
                    fcb       C$NULL
                    fcb       $68,$73
                    fcb       C$NULL
                    fcb       $6C,$73
                    fcb       C$NULL
BraCondHi           fcb       $68,$69
                    fcb       C$NULL
                    fcb       $70,$6C
                    fcb       C$NULL
BraCondMi           fcb       $6D,$69
                    fcb       C$NULL
                    fcb       $63,$63
                    fcb       C$NULL
BraCondCs           fcb       $63,$73
                    fcb       C$NULL
                    fcb       $76,$63
                    fcb       C$NULL
                    fcb       $76,$73
                    fcb       C$NULL
StrPuls             fcc       /puls/
                    fcb       C$NULL
StrPcSuffix         fcb       $2C,$70,$63
                    fcb       C$NULL
StrRts              fcb       $72,$74,$73
                    fcb       C$NULL
MsgRunOut           fcc       /run out of instructions/
                    fcb       C$NULL
MsgTooManyRemoved   fcc       /removing too many instructions/
                    fcb       C$NULL
FmtStr              fcb       $25,$73
                    fcb       C$NULL
FmtBranchInsn       fcc       /%sb%s %s/
                    fcb       C$NULL
StrLongPrefix       fcb       $6C
                    fcb       C$NULL
StrEmpty2           fcb       C$NULL
FmtStrB             fcb       $25,$73
                    fcb       C$NULL
FmtSpaceStr         fcb       $20,$25,$73
                    fcb       C$NULL
BuildOpcodeHash     pshs      u,d       save the working registers
                    leau      OpcodeTable,y   point at the opcode table
                    bra       BuildHashTest enter the build loop test

BuildHashLoop       ldd       $02,u     load the opcode key
                    pshs      d         pass it as argument
                    lbsr      HashString hash the opcode
                    leas      2,s        drop the argument
                    aslb                shift index left
                    rola                scale the index by two
                    leax      HashTable,y   point at the hash table
                    leax      d,x       index into the bucket
                    stx       ,s        save the bucket pointer
                    ldd       [,s]      load the current bucket head
                    std       $0e,u     chain the existing entry
                    stu       [,s]      insert entry at bucket head
                    leau      $10,u     advance to the next entry
BuildHashTest       ldd       ,u        load the entry opcode
                    bne       BuildHashLoop loop while opcode is non-zero
                    leas      2,s        release the local
                    puls      pc,u      restore register and return

OptBranchPass       pshs      u         save the register
                    ldu       $04,s     load the node argument
                    leas      -12,s      reserve the local frame
                    ldu       $02,u     load the first instruction
                    bra       OptLoopTest enter the scan loop test

OptLoopReset        leas      -$0C,x    reset the stack to the frame base
OptLoopTest         leax      >GlbPtr0015,y  address the list-head sentinel
                    pshs      x         save the sentinel
                    cmpu      ,s++      compare node against the head
                    lbeq      WalkExit  exit when the list is exhausted
                    ldd       ,u        load the next instruction link
                    std       $0a,s     save the next instruction
                    pshs      d         pass it as argument
                    leax      >GlbPtr0015,y  address the list head
                    cmpx      ,s++      check for the end sentinel
                    lbeq      WalkExit  exit if at the list head
                    ldx       $0a,s     load the next instruction
                    ldd       $04,x     load its target field
                    lbeq      OptTableLookup branch when the field is zero
                    ldd       $06,u     load the current flags
                    clra                keep only the low byte
                    andb      #$20      test the $20 flag bit
                    lbeq      WalkExit  skip when the flag is clear
                    ldd       $06,u     reload the flags
                    clra                keep only the low byte
                    andb      #$3f      mask the opcode bits
                    cmpd      #$0021    compare with opcode $21
                    lbeq      WalkExit  skip when it matches
                    ldx       $13,u     load the operand pointer
                    ldd       $04,x     load its target field
                    cmpd      $0a,s     compare with the next instruction
                    bne       OptCheckPredecessor branch when they differ
                    ldd       $0a,s     load the next instruction
                    pshs      d         pass it as argument
                    pshs      u         pass the current node
                    lbsr      UnlinkInsn call the fold helper
                    leas      4,s        drop the arguments
                    pshs      u         pass the node
                    lbsr      FreeOperand free the operand node
                    leas      2,s        drop the argument
                    ldx       $0a,s     load the next instruction
                    ldu       $02,x     advance to the following instruction
                    ldd       GlbWord0021 load the optimization counter
                    addd      #$0001    increment the counter
                    std       GlbWord0021 store the counter back
                    leax      $0C,s     point at the frame base
                    lbra      OptLoopReset loop for the next instruction

OptCheckPredecessor ldd       $06,u     load the flags
                    anda      #$01      test the $0100 flag bit
                    clrb                clear the low byte
                    std       -$02,s    store the test result
                    lbeq      WalkExit  skip when the flag is clear
                    ldd       $04,u     load the field
                    lbne      WalkExit  skip when it is non-zero
                    ldu       $02,u     advance to the next node
                    pshs      u         save the node
                    leax      >GlbPtr0015,y  address the list head
                    cmpx      ,s++      check for the end sentinel
                    lbeq      WalkExit  skip if at the list head
                    ldd       $06,u     load the flags
                    clra                keep only the low byte
                    andb      #$3f      mask the opcode bits
                    cmpd      #$0021    compare with opcode $21
                    lble      WalkExit  skip when at or below $21
                    ldx       $13,u     load the operand pointer
                    ldd       $04,x     load its target field
                    cmpd      $0a,s     compare with the next instruction
                    lbne      WalkExit  skip when they differ
                    pshs      u         pass the node
                    lbsr      InvertBranchNode call the fold helper
                    leas      2,s        drop the argument
                    lbra      WalkExit  done with this instruction

OptTableLookup      pshs      u         save the node
                    ldd       #$0008    offset of eight
                    addd      ,s++      compute the operand field address
                    pshs      d         pass it as argument
                    lbsr      HashString hash the opcode
                    leas      2,s        drop the argument
                    aslb                shift index left
                    rola                scale the index by two
                    leax      HashTable,y   point at the pattern hash table
                    leax      d,x       index into the bucket
                    ldd       ,x        load the bucket head
                    std       $08,s     save the table entry
                    clra                clear high byte
                    clrb                clear low byte for zero
                    std       $04,s     clear the match local
                    lbra      ScanNodeLoop enter the pattern-match loop

OptMatchLoop        ldx       $08,s     load the table entry
                    ldd       $02,x     load its first operand
                    pshs      d         pass it as argument
                    pshs      u         pass the node
                    ldd       #$0008    offset of eight
                    addd      ,s++      compute the operand field address
                    pshs      d         pass it as argument
                    lbsr      MatchPattern compare the operands
                    leas      4,s        drop the arguments
                    std       -$02,s    save the comparison result
                    lbeq      AdvanceNextNode skip when no match
                    ldx       $08,s     load the table entry
                    ldd       $04,x     load its second operand
                    pshs      d         pass it as argument
                    ldd       $13,u     load the operand pointer
                    pshs      d         pass it as argument
                    lbsr      MatchPattern compare the operands
                    leas      4,s        drop the arguments
                    std       -$02,s    save the comparison result
                    beq       AdvanceNextNode skip when no match
                    ldx       $08,s     load the table entry
                    ldd       $06,x     load its third operand
                    pshs      d         pass it as argument
                    ldd       $0C,s     load the node field
                    addd      #$0008    compute the operand field address
                    pshs      d         pass it as argument
                    lbsr      MatchPattern compare the operands
                    leas      4,s        drop the arguments
                    std       -$02,s    save the comparison result
                    beq       AdvanceNextNode skip when no match
                    ldx       $08,s     load the table entry
                    ldd       $08,x     load its action code
                    cmpd      #$0001    compare with action one
                    bne       OptActionOther branch when not action one
                    ldd       $13,u     load the operand pointer
                    bra       OptActionEmit use the operand for the action

OptActionOther      ldx       $08,s     load the table entry
                    ldd       $08,x     load its action code
OptActionEmit       pshs      d         pass it as argument
                    ldx       $0C,s     load the node pointer
                    ldd       $13,x     load its operand pointer
                    pshs      d         push argument for the pattern match
                    lbsr      MatchPattern test whether the pattern matches
                    leas      4,s        drop the call arguments
                    std       -$02,s    save the match result
                    beq       AdvanceNextNode no match, advance to next node
                    ldd       #$0001    set the matched flag
                    std       $04,s     store the matched flag
                    bra       CheckMatchFlag proceed with the matched node

AdvanceNextNode     ldx       $08,s     load current node
                    ldd       $0e,x     fetch its next-node link
                    std       $08,s     advance to the next node
ScanNodeLoop        ldd       $08,s     reload the node pointer
                    lbne      OptMatchLoop keep scanning while nodes remain
CheckMatchFlag      ldd       $04,s     check the matched flag
                    lbeq      WalkExit  nothing matched, finish the walk
                    ldx       $08,s     load the matched node
                    ldx       $0a,x     load its first operand link
                    bra       OperandDispatch dispatch on operand kind

OperandKind2        ldd       $0a,s     take frame operand base
                    addd      #$0008    offset to the operand field
                    bra       EmitOperand emit this operand

OperandDefault      ldx       $08,s     load node pointer
                    ldd       $0a,x     load the operand pointer
EmitOperand         pshs      d         push operand argument
                    pshs      u         push node context
                    ldd       #$0008    offset constant
                    addd      ,s++      compute the operand address
                    pshs      d         push computed address
                    lbsr      StrCopy   emit or copy the operand
                    leas      4,s        drop the call arguments
                    bra       HandleDest go handle the destination

OperandDispatch     cmpx      #$0001    operand kind 1
                    beq       HandleDest skip, handle destination
                    cmpx      #$0002    operand kind 2
                    beq       OperandKind2 use the frame operand
                    bra       OperandDefault default operand handling

HandleDest          ldx       $08,s     load the matched node
                    ldx       $0C,x     load its destination link
                    bra       DestDispatch dispatch on destination kind

ZeroDest            clra                zero value high
                    clrb                zero value low
                    stb       [$13,u]   clear the destination field
                    bra       DisposeAndCount finish the emit

DestKind2           ldx       $0a,s     take frame base
                    ldd       $13,x     load destination operand value
                    bra       EmitDest  emit the destination

DestDefault         ldx       $08,s     load the node
                    ldd       $0C,x     load the destination pointer
EmitDest            pshs      d         push destination argument
                    ldd       $13,u     push the node's field
                    pshs      d         push it
                    lbsr      StrCopy   emit or copy the destination
                    leas      4,s        drop the arguments
                    bra       DisposeAndCount finish the emit

DestDispatch        stx       -$02,s    save the destination kind
                    beq       ZeroDest  zero destination
                    cmpx      #$0001    kind 1
                    beq       DisposeAndCount no destination work
                    cmpx      #$0002    kind 2
                    beq       DestKind2 frame destination
                    bra       DestDefault default destination

DisposeAndCount     ldd       $0a,s     pass the node
                    pshs      d         push it
                    lbsr      FreeOperand dispose of the node
                    leas      2,s        drop the argument
                    ldd       GlbWord0021 load the optimization counter
                    addd      #$0001    increment it
                    std       GlbWord0021 record another change made
                    ldx       [$08,s]   follow the node link
                    bra       NextDispatch dispatch on next step

FollowContext       ldu       $02,u     follow the context link
                    bra       ResumeOuter continue the outer loop

NextDispatch        cmpx      #$0001    kind 1
                    beq       FollowContext follow the context
                    cmpx      #$0002    kind 2
                    beq       WalkExit  done
ResumeOuter         lbra      OptLoopTest resume the outer scan

WalkExit            leas      12,s       release the locals
                    puls      pc,u      return

InvertBranchNode    pshs      u         save the frame register
                    ldu       $04,s     load the node argument
                    ldd       $06,u     read the attribute word
                    clra                keep only the low byte
                    andb      #$3f      isolate the condition bits
                    eorb      #$01      invert the branch sense
                    pshs      d         save the inverted condition
                    ldx       ,u        load the first linked node
                    ldd       $06,x     read its attribute word
                    anda      #$FE      clear the low flag bit
                    andb      #$C0      keep the top two bits
                    ora       ,s+       merge the inverted condition high
                    orb       ,s+       merge the inverted condition low
                    std       $06,u     write back the rewritten attribute
                    clra                zero high byte
                    andb      #$1f      isolate the opcode index
                    aslb                scale to a word index
                    rola                carry into high byte
                    leax      >StringArgument,y  opcode replacement table base
                    leax      d,x       index into the table
                    ldd       ,x        fetch the replacement opcode
                    pshs      d         push it
                    pshs      u         push the node
                    ldd       #$0008    field offset
                    addd      ,s++      compute the target address
                    pshs      d         push it
                    lbsr      StrCopy   emit the rewritten operand
                    leas      4,s        drop the arguments
                    ldd       $13,u     take the node field
                    pshs      d         push it
                    pshs      u         push the node
                    lbsr      RemoveRef process the linked list
                    leas      4,s        drop the arguments
                    ldx       ,u        load the first child
                    ldd       $13,x     take its field
                    std       $13,u     promote the field up
                    pshs      d         push it
                    pshs      u         push the node
                    lbsr      LinkRefNode relink the node
                    leas      4,s        drop the arguments
                    ldd       ,u        take the child pointer
                    pshs      d         push it
                    lbsr      FreeOperand free the child node
                    leas      2,s        drop the argument
                    ldd       GlbWord0021 load the change counter
                    addd      #$0001    increment it
                    std       GlbWord0021 record the optimization
                    puls      pc,u      return

MatchPattern        pshs      u         save the frame register
                    ldu       $04,s     load the pattern argument
                    ldd       $06,s     check the input pointer
                    lbne      MatchNextChar start matching if input present
                    ldd       #$0001    default the match to true
                    puls      pc,u      return the match result

                    lbra      MatchNextChar resume the match loop

MatchPlaceholder    ldb       [$06,s]   load the current pattern char
                    cmpb      #$3C      is it the < placeholder
                    lbne      MatchLiteral no, do a literal compare
                    ldb       ,u        load the input class byte
                    sex                 extend to a word
                    leax      CtypeTab,y character class table base
                    leax      d,x       index into the table
                    ldb       ,x        fetch the class flags
                    clra                zero high byte
                    andb      #$08      test the is-digit flag
                    lbeq      MatchFail not a digit, fail the match
                    leas      -2,s       make room for the accumulator
                    clra                zero accumulator high
                    clrb                zero accumulator low
                    std       ,s        initialise the number to zero
ParseDigitLoop      ldd       ,s        load the running accumulator
                    pshs      d         push it for the multiply
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  accumulator times ten
                    pshs      d         push the result
                    ldb       ,u+       load the next input digit
                    sex                 extend to a word
                    addd      ,s++      add the digit in
                    addd      #$FFD0    subtract ascii zero
                    std       ,s        store the new accumulator
                    ldb       ,u        peek the next input char
                    sex                 extend to a word
                    leax      CtypeTab,y character class table base
                    leax      d,x       index into the table
                    ldb       ,x        fetch the class flags
                    clra                zero high byte
                    andb      #$08      test the is-digit flag
                    bne       ParseDigitLoop keep consuming digits
                    ldd       ,s        load the parsed number
                    cmpd      #$00FF    does it exceed one byte
                    bls       PlaceholderOk within range, accept
                    clra                too big, fail high
                    clrb                too big, fail low
                    leas      2,s        drop the accumulator
                    puls      pc,u      return no match

PlaceholderOk       leas      2,s        drop the accumulator
                    ldd       $06,s     load the pattern pointer
                    addd      #$0001    advance past the placeholder
                    std       $06,s     update the pattern pointer
                    bra       MatchNextChar continue matching

MatchLiteral        ldb       ,u+       load input char and advance
                    sex                 extend to a word
                    pshs      d         save the input char
                    ldx       $08,s     load the pattern pointer
                    leax      $01,x     advance the pattern
                    stx       $08,s     update the pattern pointer
                    ldb       -$01,x    load the pattern char
                    sex                 extend to a word
                    cmpd      ,s++      compare to the input char
                    bne       MatchFail mismatch, fail the match
MatchNextChar       ldb       [$06,s]   peek the next pattern char
                    lbne      MatchPlaceholder more pattern, keep matching
                    ldb       ,u        input at its end
                    bne       MatchFail leftover input, fail
                    ldd       #$0001    full match succeeded
                    bra       MatchReturn return true

MatchFail           clra                match failed high
                    clrb                match failed low
MatchReturn         puls      pc,u      return the result

OptimizeInsnList    pshs      u         save the frame register
                    ldu       $04,s     load the list argument
                    leas      -10,s      allocate the locals
                    leax      >GlbPtr0015,y  sentinel node address
                    cmpx      $02,u     is the list head the sentinel
                    lbeq      ScanDone2 empty list, skip to end
                    clra                zero high
                    clrb                zero low
                    std       ,s        clear the chain head
                    ldd       $04,u     load the list start
                    bra       BlockLoop enter the block loop

NextBlock           ldx       $06,s     load the block pointer
                    ldd       $06,x     fetch the next block link
                    bra       AdvanceInstr advance the block

InstrLoop           ldx       $04,s     load the instruction pointer
                    ldd       $02,x     load the operand link
                    std       $08,s     save the operand node
                    ldx       $08,s     reload the operand node
                    ldd       $04,x     load its value field
                    beq       InstrNext none, skip this instruction
                    ldx       $08,s     reload the operand node
                    ldd       $06,x     load its attributes
                    anda      #$01      test the low flag bit
                    clrb                clear low byte
                    std       -$02,s    save the flag
                    beq       InstrNext flag clear, skip
                    ldx       $08,s     reload the operand node
                    ldd       $06,x     load its attributes
                    clra                zero high byte
                    andb      #$80      test the high flag bit
                    bne       InstrNext set, skip this instruction
                    lbsr      AllocRefCell allocate a new chain cell
                    std       $02,s     save the new cell
                    ldd       ,s        load the current chain head
                    std       [$02,s]   link it into the new cell
                    ldd       $02,s     load the new cell
                    std       ,s        make it the chain head
                    ldd       $08,s     load the operand node
                    ldx       ,s        load the new cell
                    std       $02,x     record the operand in the cell
InstrNext           ldd       [$04,s]   follow the instruction link
AdvanceInstr        std       $04,s     advance the instruction
                    ldd       $04,s     reload the instruction pointer
                    bne       InstrLoop loop over instructions
                    ldx       $06,s     load the block pointer
                    ldd       $08,x     load the block's other link
BlockLoop           std       $06,s     set the current block
                    ldd       $06,s     reload the current block
                    lbne      NextBlock loop over blocks
                    lbra      ChainDone done collecting, process chain

ChainLoop           pshs      u         save the frame register
                    ldx       $02,s     load the chain head
                    ldd       $02,x     load its operand node
                    std       $0a,s     save the operand node
                    pshs      d         push it
                    lbsr      UnlinkInsn look up or process the node
                    leas      4,s        drop the arguments
                    ldx       $08,s     load the result pointer
                    ldd       $02,x     load its link
                    std       $08,s     save it
                    pshs      d         push it
                    leax      >GlbPtr0015,y  sentinel node address
                    cmpx      ,s++      is it the sentinel
                    beq       ChainAdvance yes, skip
                    ldx       $08,s     reload the node
                    ldd       $06,x     load its attributes
                    clra                zero high byte
                    andb      #$20      test the flag bit
                    beq       ChainAdvance clear, skip
                    ldx       $08,s     reload the node
                    ldd       $06,x     load its attributes
                    anda      #$01      test the low flag
                    clrb                clear low byte
                    std       -$02,s    save the flag
                    beq       DestOpcodeCheck clear, take the other branch
                    ldd       [$08,s]   load the operand value
                    pshs      d         push it
                    lbsr      FreeOperand free the node
                    bra       ChainStep continue

DestOpcodeCheck     ldx       $08,s     reload the node
                    ldd       $06,x     load its attributes
                    clra                zero high byte
                    andb      #$3f      isolate the low bits
                    cmpd      #$0021    compare to the opcode threshold
                    ble       ChainAdvance below threshold, skip
                    ldx       $08,s     reload the node
                    ldx       $13,x     load its child node
                    ldd       $04,x     load the child value
                    ldx       $08,s     reload the node
                    cmpd      [,x]      does it match the operand
                    bne       ChainAdvance no, skip
                    ldd       $08,s     load the node
                    pshs      d         push it
                    lbsr      InvertBranchNode rewrite the branch node
ChainStep           leas      2,s        drop the argument
ChainAdvance        ldd       [,s]      load the next chain entry
                    std       $02,s     advance the chain
                    ldd       ,s        load the chain cell
                    pshs      d         push it
                    lbsr      FreeRefCell free the chain cell
                    leas      2,s        drop the argument
                    ldd       $02,s     load the next cell
                    std       ,s        update the chain head
ChainDone           ldd       ,s        load the chain head
                    lbne      ChainLoop loop over the chain
                    ldx       $02,u     load the list head
                    ldd       $06,x     load its attributes
                    anda      #$01      test the flag bit
                    clrb                clear low byte
                    std       -$02,s    save the flag
                    bne       CheckListFlag set, skip the block loop
                    ldd       $04,u     load the list start
                    bra       SecondBlockSet enter the second block loop

SecondBlockLoop     ldx       $06,s     load the block pointer
                    ldd       $06,x     load its next link
                    bra       AdvanceInstr2 advance

SecondInstrLoop     ldx       $04,s     load the instruction pointer
                    ldd       $02,x     load the operand link
                    std       $08,s     save it
                    tfr       d,x       copy to index register
                    ldd       $06,x     load operand attributes
                    anda      #$01      test the flag bit
                    clrb                clear low byte
                    std       -$02,s    save the flag
                    beq       SecondInstrNext clear, skip
                    ldd       $08,s     load the node
                    pshs      d         push it
                    ldx       $08,s     reload the node
                    ldd       $08,x     load its field
                    pshs      d         push it
                    lbsr      UpdateUseChain process or emit the node
                    leas      4,s        drop the arguments
SecondInstrNext     ldd       [$04,s]   follow the instruction link
AdvanceInstr2       std       $04,s     advance the instruction
                    ldd       $04,s     reload the instruction pointer
                    bne       SecondInstrLoop loop over instructions
                    ldx       $06,s     load the block pointer
                    ldd       $08,x     load its block link
SecondBlockSet      std       $06,s     set the current block
                    ldd       $06,s     reload the current block
                    bne       SecondBlockLoop loop over blocks
                    pshs      u         push the list
                    ldd       $04,u     load the list start
                    pshs      d         push it
                    lbsr      UpdateUseChain process the list
                    leas      4,s        drop the arguments
CheckListFlag       ldd       $06,u     load the list attributes
                    anda      #$01      test the flag bit
                    clrb                clear low byte
                    std       -$02,s    save the flag
                    lbeq      ScanDone2 clear, finish
                    ldd       $06,u     load the attributes again
                    clra                zero high byte
                    andb      #$20      test the flag bit
                    beq       AdvanceFromU clear, take the other path
                    ldx       $13,u     load the child node
                    ldd       $04,x     load its value field
                    std       $08,s     save it
                    beq       UseChildField none, use the child field
                    ldx       $08,s     reload the node
                    ldd       $02,x     load its operand
                    pshs      d         push it
                    ldd       $02,u     load the list operand
                    pshs      d         push it
                    lbsr      MatchBlockPair compare the operands
                    leas      4,s        drop the arguments
                    std       -$02,s    save the compare result
                    lbne      ScanDone2 differ, finish
                    pshs      u         push the list
                    ldx       $0a,s     reload the node
                    ldd       $04,x     load its value field
                    bra       EmitListNode emit it

UseChildField       pshs      u         push the list
                    ldd       $13,u     load the child field
EmitListNode        pshs      d         push the argument
                    lbsr      UpdateUseChain process the node
                    leas      4,s        drop the arguments
                    lbra      ScanDone2 finish

AdvanceFromU        ldd       $02,u     load next-instruction pointer from u
                    lbra      SetCurrent jump to set it as current

ScanPairLoop        ldx       $08,s     load current instruction pointer
                    ldd       $06,x     load its flags field
                    anda      #$01      isolate the low operand flag bit
                    clrb                clear low byte of masked flag
                    std       -$02,s    save masked flag locally
                    beq       AdvanceInsn skip if flag bit clear
                    ldx       $08,s     reload current instruction
                    ldd       $06,x     reload flags field
                    clra                clear high byte
                    andb      #$A0      mask the a0 flag bits
                    bne       AdvanceInsn skip if any of those bits set
                    ldd       $08,s     take current pointer
                    addd      #$0008    offset to operand text field
                    pshs      d         push first strcmp argument
                    pshs      u         push u pointer
                    ldd       #$0008    prepare operand field offset
                    addd      ,s++      compute u plus offset
                    pshs      d         push second strcmp argument
                    lbsr      StrCmp    compare the two operand strings
                    leas      4,s        pop the arguments
                    std       -$02,s    save comparison result
                    bne       AdvanceInsn skip if operands differ
                    ldx       $08,s     reload current instruction
                    ldd       $13,x     load secondary field
                    pshs      d         push first argument
                    ldd       $13,u     load u secondary field
                    pshs      d         push second argument
                    lbsr      StrCmp    compare the secondary fields
                    leas      4,s        pop arguments
                    std       -$02,s    save result
                    bne       AdvanceInsn skip if fields differ
                    ldd       $02,u     load u operand pointer
                    pshs      d         push argument
                    ldx       $0a,s     load other operand base
                    ldd       $02,x     load its operand pointer
                    pshs      d         push argument
                    bsr       MatchBlockPair deep-compare the operand chains
                    leas      4,s        pop arguments
                    std       -$02,s    save result
                    bne       ScanDone2 exit if a match was made
AdvanceInsn         ldx       $08,s     load current instruction
                    ldd       $02,x     load next-instruction link
SetCurrent          std       $08,s     set it as the current instruction
                    leax      >GlbPtr0015,y  load the list sentinel address
                    cmpx      $08,s     reached end of list
                    lbne      ScanPairLoop loop while more instructions remain
ScanDone2           leas      10,s       tear down the scan frame
                    puls      pc,u      return

MatchBlockPair      pshs      u         save u register
                    ldu       $04,s     load first operand argument
                    leas      -20,s      allocate local workspace
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        init depth counter to zero
                    stu       $06,s     save operand pointer local
                    pshs      u         push u for comparison
                    ldd       $1C,s     load second operand argument
                    std       $06,s     store it locally
                    cmpd      ,s++      compare the two operand pointers
                    bne       MatchLoop continue if they differ
                    lbra      ReturnZero identical operands return zero

                    bra       MatchLoop fall into the match loop

MatchNextLoop       ldu       $02,u     follow u to next operand
                    ldx       $1a,s     load other chain pointer
                    ldd       $02,x     load its next link
                    std       $1a,s     advance the other pointer
                    ldd       ,s        load depth counter
                    addd      #$0001    increment matched depth
                    std       ,s        store depth back
MatchLoop           leax      >GlbPtr0015,y  load the list sentinel
                    pshs      x         push sentinel
                    cmpu      ,s++      reached end of u chain
                    lbeq      MatchEnd  stop at chain end
                    leax      >GlbPtr0015,y  load sentinel again
                    cmpx      $1a,s     other pointer at end
                    lbeq      MatchEnd  stop at chain end
                    cmpu      $04,s     u back at original start
                    lbeq      MatchEnd  stop on wrap
                    ldd       $1a,s     load other pointer
                    cmpd      $06,s     other back at original
                    lbeq      MatchEnd  stop on wrap
                    ldd       $06,u     load u flags
                    clra                clear high byte
                    andb      #$3f      mask opcode class bits
                    pshs      d         push opcode class
                    ldx       $1C,s     load other operand base
                    ldd       $06,x     load its flags
                    clra                clear high byte
                    andb      #$3f      mask opcode class bits
                    cmpd      ,s++      same opcode class
                    lbne      MatchEnd  differ so no match
                    ldd       $06,u     load u flags
                    clra                clear high byte
                    andb      #$80      test the high flag bit
                    lbne      MatchEnd  set means no match
                    ldd       $06,u     load u flags again
                    clra                clear high byte
                    andb      #$20      test bit five
                    beq       CompareOperandText branch to text compare if clear
                    ldx       $13,u     load u symbol pointer
                    ldd       $04,x     load symbol reference
                    beq       CompareSymbol branch if no symbol
                    ldx       $13,u     reload symbol pointer
                    ldd       $04,x     load symbol reference
                    ldx       $1a,s     load other operand base
                    ldx       $13,x     load its symbol pointer
                    cmpd      $04,x     compare symbol references
                    bne       MarkNotEqual differ so not equal
MarkEqual           ldd       #$0001    mark operands equal
                    bra       MatchResult branch with equal result

CompareSymbol       ldd       $13,u     load u field
                    ldx       $1a,s     load other operand base
                    cmpd      $13,x     compare the fields
                    bra       CheckEqual branch on comparison

CompareOperandText  ldd       $1a,s     load other operand pointer
                    addd      #$0008    offset to operand text
                    pshs      d         push first argument
                    pshs      u         push u pointer
                    ldd       #$0008    prepare operand offset
                    addd      ,s++      compute u operand address
                    pshs      d         push second argument
                    lbsr      StrCmp    compare operand text
                    leas      4,s        pop arguments
                    std       -$02,s    save result
                    bne       MarkNotEqual differ so not equal
                    ldx       $1a,s     load other operand base
                    ldd       $13,x     load secondary field
                    pshs      d         push argument
                    ldd       $13,u     load u secondary field
                    pshs      d         push argument
                    lbsr      StrCmp    compare secondary fields
                    leas      4,s        pop arguments
                    std       -$02,s    save result
CheckEqual          beq       MarkEqual equal marks a match
MarkNotEqual        clra                clear high byte for zero result
                    clrb                clear low byte
MatchResult         lbne      MatchNextLoop continue loop if operands matched
MatchEnd            ldu       ,u        follow u to parent pointer
                    ldd       ,s        load depth counter
                    lbeq      ReturnZero no matches so return zero
                    ldd       [$1a,s]   dereference other chain
                    std       $1a,s     store dereferenced pointer
                    std       $04,s     save as work pointer
                    ldd       $04,u     load u forward link
                    std       $02,s     store it locally
                    bne       MergeLoopTest branch if link present
                    ldx       $1a,s     load other pointer
                    ldd       $04,x     load its forward link
                    std       $02,s     store locally
                    bne       MergeLoopTest branch if link present
                    leax      $08,s     point at local pair
                    pshs      x         push pointer argument
                    lbsr      GenLabel  allocate a new node
                    std       ,s        save allocated node
                    lbsr      HashInsert link the node
                    leas      2,s        pop argument
                    std       $02,s     store node pointer
                    ldd       $1a,s     load other pointer
                    ldx       $02,s     load node pointer
                    std       $04,x     link node forward
                    ldd       $02,s     load node pointer
                    ldx       $1a,s     load other pointer
                    std       $04,x     link node backward
                    bra       MergeLoopTest proceed to merge loop

MergeLoop           ldd       $1a,s     load other pointer
                    pshs      d         push argument
                    pshs      u         push u
                    lbsr      UnlinkInsn merge the matched operands
                    leas      4,s        pop arguments
                    ldu       ,u        follow u parent link
                    ldd       $02,u     load u operand pointer
                    pshs      d         push argument
                    lbsr      FreeOperand remove the redundant instruction
                    leas      2,s        pop argument
                    ldd       GlbWord0021 load optimisation counter
                    addd      #$0001    increment it
                    std       GlbWord0021 store counter back
                    ldd       [$1a,s]   dereference other chain
                    std       $1a,s     advance other pointer
MergeLoopTest       ldd       ,s        load depth counter
                    addd      #$FFFF    decrement by one
                    std       ,s        store counter
                    subd      #$FFFF    test for remaining depth
                    bge       MergeLoop loop while depth left
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       $04,s     load work pointer
                    addd      #$000C    offset to target field
                    pshs      d         push argument
                    leax      OpLbra,pcr point at lbra mnemonic
                    pshs      x         push mnemonic argument
                    pshs      u         push u
                    lbsr      AddLineNode emit the branch instruction
                    leas      8,s        pop arguments
                    pshs      u         push u
                    lbsr      OptBranchPass finalize the emitted block
                    leas      2,s        pop argument
                    ldd       $04,s     load work pointer
                    pshs      d         push argument
                    ldx       $06,s     load operand base
                    ldd       $04,x     load its forward link
                    pshs      d         push argument
                    bsr       UpdateUseChain update the use chain
                    leas      4,s        pop arguments
                    ldd       #$0001    return success
                    bra       ReturnValue branch to common exit

ReturnZero          clra                clear high byte for zero
                    clrb                clear low byte
ReturnValue         leas      20,s       tear down local frame
                    puls      pc,u      return with result

UpdateUseChain      pshs      u,d       save registers and result slot
                    bra       UseLoopTest enter the use loop test

UseNextLoop         ldx       $06,s     load operand base
                    ldd       $06,x     load next use pointer
                    bra       UseStore  store advanced pointer

UseCheckLoop        ldx       ,s        load use list head
                    ldu       $02,x     load use record pointer
                    ldd       $06,u     load its flags
                    anda      #$01      isolate low flag bit
                    clrb                clear low byte
                    std       -$02,s    save masked flag
                    beq       UseFollow skip if flag clear
                    ldd       $06,u     load flags again
                    clra                clear high byte
                    andb      #$80      test high flag bit
                    bne       UseFollow skip if set
                    ldx       $08,s     load current operand
                    ldd       $02,x     load its operand pointer
                    pshs      d         push argument
                    ldd       $02,u     load use operand pointer
                    pshs      d         push argument
                    lbsr      MatchBlockPair compare the operands
                    leas      4,s        pop arguments
                    std       -$02,s    save result
                    bne       UseNextBlock exit block on match
UseFollow           ldd       [,s]      follow the use link
UseStore            std       ,s        store advanced pointer
                    ldd       ,s        load pointer
                    bne       UseCheckLoop loop while entries remain
UseNextBlock        ldx       $06,s     load operand base
                    ldd       $08,x     load next block link
                    std       $06,s     store block pointer
UseLoopTest         ldd       $06,s     load block pointer
                    bne       UseNextLoop loop while blocks remain
                    leas      2,s        pop result slot
                    puls      pc,u      return

                    fcb       $2C,$78,$2B
                    fcb       C$NULL
                    fcb       $2C,$79,$2B
                    fcb       C$NULL
                    fcb       $2C,$75,$2B
                    fcb       C$NULL
                    fcb       $2C,$2D,$78
                    fcb       C$NULL
                    fcb       $2C,$2D,$79
                    fcb       C$NULL
                    fcb       $2C,$2D,$75
                    fcb       C$NULL
                    fcc       /,x++/
                    fcb       C$NULL
                    fcc       /,y++/
                    fcb       C$NULL
                    fcc       /,u++/
                    fcb       C$NULL
                    fcc       /,--x/
                    fcb       C$NULL
                    fcc       /,--y/
                    fcb       C$NULL
                    fcc       /,--u/
                    fcb       C$NULL
                    fcc       /,s++/
                    fcb       C$NULL
                    fcc       /-4,s/
                    fcb       C$NULL
                    fcc       /-6,s/
                    fcb       C$NULL
OpLbra              fcc       /lbra/
                    fcb       C$NULL
LookupOpcode        pshs      u,d       save registers
                    ldd       $06,s     load mnemonic argument
                    pshs      d         push argument
                    lbsr      Sbrk      look up the mnemonic index
                    leas      2,s        pop argument
                    std       ,s        save index
                    cmpd      #$FFFF    lookup failed
                    bne       LookupDone2 skip error on success
                    leax      >MsgMemoryOverflow,pcr point at memory overflow message
                    pshs      x         push message argument
                    bsr       FatalError report the fatal error
                    leas      2,s        pop argument
LookupDone2         ldd       ,s        load lookup result
                    bra       ErrorReturn branch to return

FatalError          pshs      u         save u
                    leax      >MsgOptimiserError,pcr point at error prefix string
                    pshs      x         push argument
                    leax      OutputStream,y   load stderr stream pointer
                    pshs      x         push stream argument
                    lbsr      fprintf   print the error prefix
                    leas      4,s        pop arguments
                    ldd       $0a,s     load message argument
                    pshs      d         push it
                    ldd       $0a,s     load message argument
                    pshs      d         push it
                    ldd       $0a,s     load message argument
                    pshs      d         push it
                    ldd       $0a,s     load message argument
                    pshs      d         push it
                    leax      OutputStream,y   load stderr stream pointer
                    pshs      x         push stream argument
                    lbsr      fprintf   print the formatted message
                    leas      10,s       pop arguments
                    leax      OutputStream,y   load stderr stream pointer
                    pshs      x         push stream argument
                    ldd       #$000D    prepare carriage return
                    pshs      d         push it
                    lbsr      $1FB2     write the newline
                    leas      4,s        pop arguments
                    ldd       #$0001    prepare exit status one
                    pshs      d         push status
                    lbsr      exit      terminate the program
ErrorReturn         leas      2,s        pop argument
                    puls      pc,u      return

MsgMemoryOverflow   fcc       /memory overflow/
                    fcb       C$NULL
MsgOptimiserError   fcc       /C optimiser error: /
                    fcb       C$NULL
AllocOperand        pshs      u         save u
                    leau      InputPathBuffer,y   point at the operand table base
AllocScanLoop       ldd       $06,u     load entry flags
                    clra                clear high byte
                    andb      #$03      mask the in-use bits
                    lbeq      ReturnSlot free slot found
                    leau      $0d,u     advance to next table entry
                    pshs      u         push entry pointer
                    leax      PastTableEnd,y   point past table end
                    cmpx      ,s++      compare against end
                    bhi       AllocScanLoop loop while within table
                    ldd       #$00C8    prepare overflow error code
                    std       ErrorFlag,y   set the error flag
                    lbra      ReturnNull return null on overflow

                    puls      pc,u      return

MakeOperand         pshs      u         save u
                    ldu       $08,s     load caller-provided slot
                    bne       FillOperand branch if slot supplied
                    bsr       AllocOperand allocate a new operand slot
                    tfr       d,u       move result into u
FillOperand         stu       -$02,s    save the slot pointer
                    beq       ReturnNull return null if allocation failed
                    ldd       $04,s     load field argument
                    std       $08,u     store into operand record
                    ldx       $06,s     load text pointer
                    ldb       $01,x     load first character
                    cmpb      #$2b      is it a plus sign
                    beq       SetIncFlags branch to set increment flags
                    ldx       $06,s     load text pointer
                    ldb       $02,x     load second character
                    cmpb      #$2b      is it a plus sign
                    bne       CheckRegType branch if no increment
SetIncFlags         ldd       $06,u     load operand flags
                    orb       #$03      set auto-increment flag bits
                    bra       StoreOperandFlags go store the flags

CheckRegType        ldd       $06,u     load operand flags
                    pshs      d         push them
                    ldb       [$08,s]   load indirect text character
                    cmpb      #$72      is it register r
                    beq       RegTypeOne branch if r
                    ldb       [$08,s]   reload character
                    cmpb      #$64      is it register d
                    bne       RegTypeTwo branch if not d
RegTypeOne          ldd       #$0001    select flag value one
                    bra       MergeRegFlags go merge flags

RegTypeTwo          ldd       #$0002    select flag value two
MergeRegFlags       ora       ,s+       merge into flag high byte
                    orb       ,s+       merge into flag low byte
StoreOperandFlags   std       $06,u     store the operand flags
                    ldd       $02,u     load operand base value
                    addd      $0b,u     add operand length
                    std       $04,u     store end pointer
                    std       ,u        store current pointer
ReturnSlot          tfr       u,d       return the slot pointer
                    puls      pc,u      return

ReturnNull          clra                clear high byte for null
                    clrb                clear low byte
                    puls      pc,u      return

OperandEntry        pshs      u         save u
                    ldu       $04,s     load operand argument pointer
                    leas      -4,s       reserve local scratch for mode flags
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        initialize addressing-mode flags to zero
                    ldx       $0a,s     load operand token pointer
                    ldb       $01,x     read second char of token
                    sex                 widen char to word
                    tfr       d,x       move char into x for compare
                    bra       OperDispatchChar dispatch on first char

OperIndexX          ldx       $0a,s     reload operand token pointer
                    ldb       $02,x     read third char of token
                    cmpb      #$2b      is it a plus
                    bne       OperIndexXPlain no plus, use plain index flag
                    ldd       #$0007    x index with post-increment flag
                    bra       OperStoreMode store mode flag

OperIndexXPlain     ldd       #$0004    plain x index flag
                    bra       OperStoreMode store mode flag

OperIndexPlus       ldd       #$0003    plus auto-increment flag
OperStoreMode       std       ,s        save computed addressing-mode flag
                    bra       OperReadRegChar read register letter next

OperModeErr         leax      $04,s     point past local frame for unwind
                    lbra      OperUnwindErr take error path

OperDispatchChar    stx       -$02,s    save first char
                    beq       OperReadRegChar empty falls through to register read
                    cmpx      #$0078    is char 'x'
                    beq       OperIndexX handle x index mode
                    cmpx      #$002B    is char '+'
                    beq       OperIndexPlus handle plus index mode
                    bra       OperModeErr unknown mode, error

OperReadRegChar     ldb       [$0a,s]   read register letter via token pointer
                    sex                 widen to word
                    tfr       d,x       move into x for compare
                    lbra      OperRegDispatch dispatch register letter

OperRegR            ldd       ,s        load mode flags
                    orb       #$01      set 'r' register bit
                    bra       OperEmitReg emit register operand

OperRegA            ldd       ,s        load mode flags
                    orb       #$02      set 'a' register bit
                    pshs      d         push flags argument
                    pshs      u         push node argument
                    lbsr      OpenFile  build operand entry
                    leas      4,s        drop call arguments
                    std       $02,s     save result pointer
                    cmpd      #$FFFF    allocation failed
                    beq       OperRegW  fall back on failure
                    ldd       #$0002    push size two argument
                    pshs      d         push it
                    clra                clear
                    clrb                clear
                    pshs      d         push zero field
                    clra                clear
                    clrb                clear
                    pshs      d         push zero field
                    ldd       $08,s     reload operand pointer
                    pshs      d         push it
                    lbsr      LseekFile append operand fields
                    leas      8,s        drop arguments
                    bra       OperReturnEntry return built entry

OperRegW            ldd       ,s        load mode flags
                    orb       #$02      set 'a' register bit
                    pshs      d         push flags argument
                    pshs      u         push node argument
                    lbsr      CreateFile build alternate operand entry
                    bra       OperStoreEntry store result

OperRegD            ldd       ,s        load mode flags
                    orb       #$81      set 'd' double register bits
OperEmitReg         pshs      d         push flags argument
                    pshs      u         push node argument
                    lbsr      OpenFile  build operand entry
OperStoreEntry      leas      4,s        drop arguments
                    std       $02,s     save result pointer
                    bra       OperReturnEntry return built entry

OperUnwindErr       leas      -$04,x    restore stack pointer for error
OperSetError        ldd       #$00CB    error code 203
                    std       ErrorFlag,y   set compiler error
                    clra                clear
                    clrb                clear
                    bra       OperExit  return null

OperRegDispatch     cmpx      #$0072    is register 'r'
                    lbeq      OperRegR  register operand
                    cmpx      #$0061    is register 'a'
                    lbeq      OperRegA  accumulator operand
                    cmpx      #$0077    is register 'w'
                    beq       OperRegW  word operand
                    cmpx      #$0064    is register 'd'
                    beq       OperRegD  double operand
                    bra       OperSetError unknown register, error

OperReturnEntry     ldd       $02,s     load built operand pointer
OperExit            leas      4,s        drop local frame
                    puls      pc,u      return

                    pshs      u         save frame pointer
                    clra                clear
                    clrb                clear
                    pshs      d         push zero destination
                    ldd       $08,s     load operand argument
                    pshs      d         push it
                    ldd       $08,s     load token argument
                    pshs      d         push it
                    lbra      OperandBuild tail into operand builder

AssembleOperand     pshs      u         save frame pointer
                    ldd       $06,s     load token argument
                    pshs      d         push it
                    ldd       $06,s     load context argument
                    pshs      d         push it
                    lbsr      OperandEntry parse operand token
                    leas      4,s        drop arguments
                    tfr       d,u       keep parsed node
                    cmpu      #$FFFF    parse failed
                    bne       OperandNoDest parse succeeded
                    clra                clear
                    clrb                clear
                    bra       OperandRet return null

OperandNoDest       clra                clear
                    clrb                clear
                    bra       OperandEmit emit with zero destination

AssembleOperandAlloc pshs      u         save frame pointer
                    ldd       $08,s     load size argument
                    pshs      d         push it
                    lbsr      FcloseOne allocate result buffer
                    leas      2,s        drop argument
                    ldd       $06,s     load token argument
                    pshs      d         push it
                    ldd       $06,s     load context argument
                    pshs      d         push it
                    lbsr      OperandEntry parse operand token
                    leas      4,s        drop arguments
                    tfr       d,u       keep parsed node
                    stu       -$02,s    save node
                    bge       OperandWithDest valid node, continue
                    clra                clear
                    clrb                clear
                    bra       OperandRet return null

OperandWithDest     ldd       $08,s     load destination argument
OperandEmit         pshs      d         push destination
                    ldd       $08,s     load node argument
                    pshs      d         push it
                    pshs      u         push parsed node
OperandBuild        lbsr      MakeOperand build instruction from operand
                    leas      6,s        drop arguments
OperandRet          puls      pc,u      return result

                    pshs      u,d       save frame and destination arg
                    ldu       $06,s     load destination buffer pointer
ReadLineLoop2       leax      InputPathBuffer,y   source line buffer address
                    pshs      x         push it
                    lbsr      Getc      read next char
                    leas      2,s        drop argument
                    std       ,s        save char
                    cmpd      #$000D    is carriage return
                    beq       ReadLineEnd end of line
                    ldd       ,s        reload char
                    cmpd      #$FFFF    read error
                    beq       ReadLineEnd stop on error
                    ldd       ,s        reload char
                    stb       ,u+       store into destination buffer
                    bra       ReadLineLoop2 next char

ReadLineEnd         ldd       ,s        load last char
                    cmpd      #$FFFF    was it a read error
                    bne       ReadLineTerm no, terminate normally
                    clra                clear
                    clrb                clear
                    puls      pc,u,x    return null

ReadLineTerm        clra                clear
                    clrb                clear
                    stb       ,u        null-terminate buffer
                    ldd       $06,s     load destination buffer pointer
                    puls      pc,u,x    return buffer

ReadCountedChars    pshs      u         save frame pointer
                    ldu       $06,s     load remaining count
                    leas      -4,s       reserve local cursor
                    ldd       $08,s     load destination pointer
                    std       ,s        initialize cursor
ReadCharsLoop       tfr       u,d       copy remaining count
                    leau      -$01,u    decrement count
                    std       -$02,s    save updated count
                    ble       ReadCharsDone done when count exhausted
                    ldd       $0C,s     load source argument
                    pshs      d         push it
                    lbsr      Getc      read next char
                    leas      2,s        drop argument
                    std       $02,s     save char
                    cmpd      #$FFFF    read error
                    beq       ReadCharsDone stop on error
                    ldd       $02,s     reload char
                    ldx       ,s        load cursor
                    leax      $01,x     advance cursor
                    stx       ,s        save cursor
                    stb       -$01,x    store char at cursor
                    cmpb      #C$CR      is carriage return
                    bne       ReadCharsLoop continue reading
ReadCharsDone       clra                clear
                    clrb                clear
                    stb       [,s]      null-terminate at cursor
                    ldd       $02,s     load last char
                    cmpd      #$FFFF    was it read error
                    bne       ReadCharsOk no, return buffer
                    clra                clear
                    clrb                clear
                    bra       ReadCharsExit return null

ReadCharsOk         ldd       $08,s     load destination pointer
ReadCharsExit       leas      4,s        drop locals
                    puls      pc,u      return

                    pshs      u         save frame pointer
                    leax      OutputPathBuffer,y   internal output buffer address
                    stx       OutputPointer,y   set output pointer
                    leax      $06,s     address of variadic arguments
                    pshs      x         push it
                    ldd       $06,s     load format string
                    bra       PrintfTail into formatter tail

fprintf             pshs      u         save frame pointer
                    ldd       $04,s     load output stream argument
                    std       OutputPointer,y   set output pointer
                    leax      $08,s     address of variadic arguments
                    pshs      x         push it
                    ldd       $08,s     load format string
PrintfTail          pshs      d         push format string
                    leax      PutcStdout,pcr buffered putc routine
                    pshs      x         push it
                    bsr       doprnt    run formatter
                    leas      6,s        drop arguments
                    puls      pc,u      return

Sprintf             pshs      u         save frame pointer
                    ldd       $04,s     load destination string pointer
                    std       OutputPointer,y   set output pointer
                    leax      $08,s     address of variadic arguments
                    pshs      x         push it
                    ldd       $08,s     load format string
                    pshs      d         push it
                    leax      BufAppendByte,pcr string putc routine
                    pshs      x         push it
                    bsr       doprnt    run formatter
                    leas      6,s        drop arguments
                    clra                clear
                    clrb                clear
                    stb       [OutputPointer,y] null-terminate output string
                    ldd       $04,s     return destination pointer
                    puls      pc,u      return

doprnt              pshs      u         save frame pointer
                    ldu       $06,s     load format string pointer
                    leas      -11,s      reserve formatter locals
DoprntLoop          ldb       ,u+       fetch next format char
                    stb       $08,s     save char
                    cmpb      #$25      is it a percent
                    beq       DoprntConv handle conversion
                    ldb       $08,s     reload char
                    lbeq      FmtReturn null terminates format
                    ldb       $08,s     reload char
                    sex                 widen to word
                    pshs      d         push char argument
                    jsr       [$11,s]   call output routine
                    leas      2,s        drop argument
                    bra       DoprntLoop next char

DoprntConv          ldb       ,u+       char after percent
                    stb       $08,s     save it
                    clra                clear
                    clrb                clear
                    std       $02,s     clear precision accumulator
                    std       $06,s     clear width accumulator
                    ldb       $08,s     reload char
                    cmpb      #$2d      is left-justify flag
                    bne       NoLeftFlag no flag present
                    ldd       #$0001    mark left-justify
                    std       LeftJustifyFlag,y   store flag
                    ldb       ,u+       advance past flag
                    stb       $08,s     save char
                    bra       AfterFlags continue after flag

NoLeftFlag          clra                clear
                    clrb                clear
                    std       LeftJustifyFlag,y   clear left-justify flag
AfterFlags          ldb       $08,s     reload char
                    cmpb      #$30      is zero-pad flag
                    bne       PadSpace  no zero pad
                    ldd       #$0030    pad character is zero
                    bra       StorePadChar store pad char

PadSpace            ldd       #$0020    pad character is space
StorePadChar        std       PadCharacter,y   save chosen pad char
WidthLoop           ldb       $08,s     load current char
                    sex                 widen to word
                    leax      CtypeTab,y character class table base
                    leax      d,x       index by char
                    ldb       ,x        load class flags
                    clra                clear high byte
                    andb      #$08      is it a digit
                    beq       CheckPrecision no more width digits
                    ldd       $06,s     load current width
                    pshs      d         push it
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  width times ten
                    pshs      d         push product
                    ldb       $0a,s     load digit char
                    sex                 widen
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add to width times ten
                    std       $06,s     save width
                    ldb       ,u+       fetch next char
                    stb       $08,s     save it
                    bra       WidthLoop continue width digits

CheckPrecision      ldb       $08,s     load current char
                    cmpb      #$2e      is precision dot
                    bne       NoPrecision no precision field
                    ldd       #$0001    mark precision present
                    std       $04,s     store flag
PrecisionLoop       ldb       ,u+       fetch next char
                    stb       $08,s     save it
                    ldb       $08,s     reload char
                    sex                 widen
                    leax      CtypeTab,y character class table base
                    leax      d,x       index by char
                    ldb       ,x        load class flags
                    clra                clear high byte
                    andb      #$08      is it a digit
                    beq       GetConvChar precision digits done
                    ldd       $02,s     load current precision
                    pshs      d         push it
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  precision times ten
                    pshs      d         push product
                    ldb       $0a,s     load digit char
                    sex                 widen
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add digit
                    std       $02,s     save precision
                    bra       PrecisionLoop continue precision digits

NoPrecision         clra                clear
                    clrb                clear
                    std       $04,s     clear precision-present flag
GetConvChar         ldb       $08,s     load conversion specifier char
                    sex                 widen to word
                    tfr       d,x       move into x for dispatch
                    lbra      ConvDispatch dispatch on conversion char

ConvSignedDec       ldd       $06,s     push field width
                    pshs      d         push it
                    ldx       $15,s     load variadic argument pointer
                    leax      $02,x     advance past this argument
                    stx       $15,s     save argument pointer
                    ldd       -$02,x    fetch integer argument
                    pshs      d         push it
                    lbsr      SignedToStr format signed decimal
                    bra       ConvIntEmit emit formatted integer

ConvOctal           ldd       $06,s     push field width
                    pshs      d         push it
                    ldx       $15,s     load variadic argument pointer
                    leax      $02,x     advance past this argument
                    stx       $15,s     save argument pointer
                    ldd       -$02,x    fetch integer argument
                    pshs      d         push it
                    lbsr      UnsToOctStr format octal
ConvIntEmit         std       ,s        save formatted string
                    lbra      EmitConvStr emit and continue

ConvHex             ldd       $06,s     push field width
                    pshs      d         push it
                    ldb       $0a,s     load conversion char
                    sex                 widen
                    leax      CtypeTab,y character class table base
                    leax      d,x       index by char
                    ldb       ,x        load class flags
                    clra                clear high byte
                    andb      #$02      test uppercase-hex flag
                    pshs      d         push case flag
                    ldx       $17,s     load variadic argument pointer
                    leax      $02,x     advance past this argument
                    stx       $17,s     save argument pointer
                    ldd       -$02,x    fetch integer argument
                    pshs      d         push it
                    lbsr      UnsToHexStr format hexadecimal
                    lbra      DropArgs4 emit and continue

ConvUnsigned        ldd       $06,s     push field width
                    pshs      d         push it
                    ldx       $15,s     load variadic argument pointer
                    leax      $02,x     advance past this argument
                    stx       $15,s     save argument pointer
                    ldd       -$02,x    fetch unsigned integer argument
                    pshs      d         push value argument
                    leax      OutputBuffer,y   point to output buffer
                    pshs      x         push buffer pointer
                    lbsr      UnsToDecStr convert number to decimal string
                    lbra      DropArgs4 go emit the result

FloatConv           ldd       $04,s     precision flag set
                    bne       FloatConvGo skip default if precision given
                    ldd       #$0006    default float precision 6
                    std       $02,s     store precision
FloatConvGo         ldd       $06,s     load float value
                    pshs      d         push value
                    leax      $15,s     point to work area
                    pshs      x         push work pointer
                    ldd       $06,s     push value again
                    pshs      d         push value
                    ldb       $0e,s     load conversion char
                    sex                 sign extend char
                    pshs      d         push conversion char
                    lbsr      $23EC     call float format routine
                    leas      6,s        clean call arguments
                    lbra      PushConvStr go emit result

CharConv            ldx       $13,s     load va_arg pointer
                    leax      $02,x     advance past argument
                    stx       $13,s     store advanced pointer
                    ldd       -$02,x    fetch char argument
                    lbra      EmitChar  emit single character

StrConv             ldx       $13,s     load va_arg pointer
                    leax      $02,x     advance past argument
                    stx       $13,s     store advanced pointer
                    ldd       -$02,x    fetch string pointer argument
                    std       $09,s     save string pointer
                    ldd       $04,s     precision specified
                    beq       StrNoPrec branch if no precision
                    ldd       $09,s     reload string pointer
                    std       $04,s     set scan start
StrPrecLoop         ldd       $02,s     remaining precision count
                    addd      #$FFFF    decrement count
                    std       $02,s     store count
                    subd      #$FFFF    test original count
                    beq       StrEmitField stop when count exhausted
                    ldb       [$09,s]   fetch string char
                    beq       StrEmitField stop at null terminator
                    ldd       $09,s     load string pointer
                    addd      #$0001    advance one char
                    std       $09,s     store pointer
                    bra       StrPrecLoop continue scanning

StrEmitField        ldd       $06,s     load pointer
                    pshs      d         push it
                    ldd       $0b,s     load end pointer
                    subd      $06,s     compute measured length
                    pshs      d         push length
                    ldd       $08,s     push field width
                    pshs      d         push field width
                    ldd       $15,s     push output routine pointer
                    pshs      d         push pointer
                    lbsr      EmitPaddedField emit padded field
                    leas      8,s        clean arguments
                    bra       ConvDone  loop back to format loop

StrNoPrec           ldd       $06,s     load pointer
                    pshs      d         push it
                    ldd       $0b,s     load string pointer
                    bra       PushConvStr emit string

LongModifier        ldb       ,u+       fetch next format char for l flag
                    stb       $08,s     store size flag
                    bra       IntFormat go format integer

                    leas      -$0b,x    unreachable filler after branch
IntFormat           ldd       $06,s     load value
                    pshs      d         push value
                    leax      $15,s     point to work area
                    pshs      x         push work pointer
                    ldb       $0C,s     load conversion char
                    sex                 sign extend
                    pshs      d         push char
                    lbsr      FormatConv call integer format routine
DropArgs4           leas      4,s        drop call arguments
PushConvStr         pshs      d         push converted string pointer
EmitConvStr         ldd       $13,s     load output pointer
                    pshs      d         push it
                    lbsr      EmitStrField emit string field
                    leas      6,s        clean arguments
ConvDone            lbra      DoprntLoop back to main format loop

LiteralChar         ldb       $08,s     default: fetch char
                    sex                 sign extend
EmitChar            pshs      d         push char
                    jsr       [$11,s]   call output routine
                    leas      2,s        clean argument
                    lbra      DoprntLoop back to format loop

ConvDispatch        cmpx      #$0064    is specifier 'd'
                    lbeq      ConvSignedDec handle signed decimal
                    cmpx      #$006F    is specifier 'o'
                    lbeq      ConvOctal handle octal
                    cmpx      #$0078    is specifier 'x'
                    lbeq      ConvHex   handle lowercase hex
                    cmpx      #$0058    is specifier 'X'
                    lbeq      ConvHex   handle uppercase hex
                    cmpx      #$0075    is specifier 'u'
                    lbeq      ConvUnsigned handle unsigned decimal
                    cmpx      #$0066    is specifier 'f'
                    lbeq      FloatConv handle float
                    cmpx      #$0065    is specifier 'e'
                    lbeq      FloatConv handle float
                    cmpx      #$0067    is specifier 'g'
                    lbeq      FloatConv handle float
                    cmpx      #$0045    is specifier 'E'
                    lbeq      FloatConv handle float
                    cmpx      #$0047    is specifier 'G'
                    lbeq      FloatConv handle float
                    cmpx      #$0063    is specifier 'c'
                    lbeq      CharConv  handle char
                    cmpx      #$0073    is specifier 's'
                    lbeq      StrConv   handle string
                    cmpx      #$006C    is specifier 'l'
                    lbeq      LongModifier handle long modifier
                    bra       LiteralChar unknown specifier emitted literally

FmtReturn           leas      11,s       discard locals
                    puls      pc,u      return to caller

SignedToStr         pshs      u,d       save regs on entry
                    leax      OutputBuffer,y   point to output buffer
                    stx       ,s        store buffer pointer local
                    ldd       $06,s     load value
                    bge       IntAbsToStr positive: skip negation
                    ldd       $06,s     load value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      complete 16-bit negate
                    std       $06,s     store absolute value
                    bge       EmitSign  emit sign if now positive
                    leax      MsgIntMin,pcr point to most-negative-int string
                    pshs      x         push string pointer
                    leax      OutputBuffer,y   point to output buffer
                    pshs      x         push destination
                    lbsr      StrCopy   copy literal string
                    leas      4,s        clean arguments
                    puls      pc,u,x    return

EmitSign            ldd       #$002D    minus sign character
                    ldx       ,s        load buffer pointer
                    leax      $01,x     advance
                    stx       ,s        store pointer
                    stb       -$01,x    store minus sign
IntAbsToStr         ldd       $06,s     load absolute value
                    pshs      d         push value
                    ldd       $02,s     load buffer pointer
                    pshs      d         push it
                    bsr       UnsToDecStr convert unsigned to decimal
                    leas      4,s        clean arguments
                    leax      OutputBuffer,y   return buffer pointer
                    tfr       x,d       into d
                    puls      pc,u,x    return

UnsToDecStr         pshs      u,y,x,d   entry: convert to decimal digits
                    ldu       $0a,s     load output pointer
                    clra                clear
                    clrb                clear
                    std       $02,s     zero nonzero-seen flag
                    clra                clear
                    clrb                clear
                    std       ,s        zero digit accumulator
DecNormLoop         ldd       $0C,s     load value
                    bge       DecDigitInit non-negative: proceed
                    ldd       ,s        load overflow count
                    addd      #$0001    increment for overflow
                    std       ,s        store count
                    ldd       $0C,s     load value
                    subd      Pow10,y   subtract table base power
                    std       $0C,s     store value
                    bra       DecNormLoop repeat normalization

DecDigitInit        leax      Pow10,y   point to power-of-ten table
                    stx       $04,s     store table pointer
DecDigitLoop        ldd       $04,s     load table pointer
                    cmpd      TableEnd,y   reached table end
                    beq       DecFinalDigit done: emit final digit
DecSubLoop          ldd       $0C,s     load remaining value
                    subd      [$04,s]   subtract current power of ten
                    std       $0C,s     store value
                    blt       DecRestore went negative: digit done
                    ldd       ,s        load digit count
                    addd      #$0001    increment digit
                    std       ,s        store count
                    bra       DecSubLoop keep subtracting

DecRestore          ldd       $0C,s     load value
                    addd      [$04,s]   restore last subtraction
                    std       $0C,s     store value
                    ldd       ,s        load digit value
                    beq       DecStoreDigit zero digit: maybe suppress
                    ldd       #$0001    nonzero found
                    std       $02,s     mark nonzero seen
DecStoreDigit       ldd       $02,s     any nonzero digit yet
                    beq       DecNextPow skip leading zero
                    ldd       ,s        load digit
                    addd      #$0030    convert to ascii
                    stb       ,u+       store digit
DecNextPow          clra                clear
                    clrb                clear
                    std       ,s        reset digit count
                    ldd       $04,s     load table pointer
                    addd      #$0002    advance to next power
                    std       $04,s     store pointer
                    bra       DecDigitLoop next digit position

DecFinalDigit       ldd       $0C,s     load final units digit
                    addd      #$0030    convert to ascii
                    stb       ,u+       store digit
                    clra                clear
                    clrb                clear
                    stb       ,u        null terminate string
                    ldd       $0a,s     return output pointer
                    leas      6,s        discard locals
                    puls      pc,u      return

UnsToOctStr         pshs      u,d       entry: convert to octal
                    leax      OutputBuffer,y   point to output buffer
                    stx       ,s        store buffer pointer
                    leau      ScratchBuffer,y   point to scratch buffer
OctDivLoop          ldd       $06,s     load value
                    clra                clear high byte
                    andb      #$07      low three bits octal digit
                    addd      #$0030    convert to ascii
                    stb       ,u+       store into scratch
                    ldd       $06,s     load value
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                divide value by eight
                    std       $06,s     store value
                    bne       OctDivLoop repeat until zero
OctReverseLoop      leau      -$01,u    back up scratch pointer
                    pshs      u         push it
                    leax      ScratchBuffer,y   scratch start
                    cmpx      ,s++      reached start of scratch
                    bhi       OctDone   done reversing
                    ldb       ,u        fetch digit
                    ldx       ,s        load output pointer
                    leax      $01,x     advance
                    stx       ,s        store pointer
                    stb       -$01,x    copy digit to output
                    bra       OctReverseLoop continue reverse copy

OctDone             clra                clear
                    clrb                clear
                    stb       [,s]      null terminate output
                    leax      OutputBuffer,y   return buffer pointer
                    tfr       x,d       into d
                    puls      pc,u,x    return

UnsToHexStr         pshs      u,x,d     entry: convert to hex
                    leax      OutputBuffer,y   point to output buffer
                    stx       $02,s     store buffer pointer
                    leau      ScratchBuffer,y   point to scratch buffer
HexDivLoop          ldd       $08,s     load value
                    clra                clear high byte
                    andb      #$0f      low nibble
                    std       ,s        store nibble
                    pshs      d         push nibble
                    ldd       $02,s     reload nibble
                    cmpd      #$0009    digit greater than nine
                    ble       HexDigitBase no: numeric digit
                    ldd       $0C,s     uppercase flag
                    beq       HexLowerBase lowercase letters
                    ldd       #$0041    uppercase A base
                    bra       HexLetterAdj go adjust

HexLowerBase        ldd       #$0061    lowercase a base
HexLetterAdj        addd      #$FFF6    adjust for a-f offset
                    bra       HexStoreDigit go store

HexDigitBase        ldd       #$0030    numeric zero base
HexStoreDigit       addd      ,s++      add nibble value
                    stb       ,u+       store hex digit
                    ldd       $08,s     load value
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                rotate
                    lsra                shift right
                    rorb                divide value by sixteen
                    anda      #$0f      mask high nibble
                    std       $08,s     store value
                    bne       HexDivLoop repeat until zero
HexReverseLoop      leau      -$01,u    back up scratch pointer
                    pshs      u         push it
                    leax      ScratchBuffer,y   scratch start
                    cmpx      ,s++      reached start of scratch
                    bhi       HexDone   done reversing
                    ldb       ,u        fetch digit
                    ldx       $02,s     load output pointer
                    leax      $01,x     advance
                    stx       $02,s     store pointer
                    stb       -$01,x    copy digit to output
                    bra       HexReverseLoop continue reverse copy

HexDone             clra                clear
                    clrb                clear
                    stb       [$02,s]   null terminate output
                    leax      OutputBuffer,y   return buffer pointer
                    tfr       x,d       into d
                    lbra      PutcStdoutDone return

EmitPaddedField     pshs      u         entry: emit padded field
                    ldu       $06,s     load source pointer
                    ldd       $0a,s     load field width
                    subd      $08,s     subtract string length
                    std       $0a,s     store pad count
                    ldd       LeftJustifyFlag,y   left-justify flag
                    bne       EmitCharsLoop left: skip leading pad
PadLeadLoop         ldd       $0a,s     load pad count
                    addd      #$FFFF    decrement
                    std       $0a,s     store count
                    subd      #$FFFF    test count
                    ble       EmitCharsLoop done padding
                    ldd       PadCharacter,y   load pad character
                    pshs      d         push it
                    jsr       [$06,s]   output pad char
                    leas      2,s        clean argument
                    bra       PadLeadLoop continue padding

EmitCharsLoop       ldd       $08,s     load string length
                    addd      #$FFFF    decrement
                    std       $08,s     store count
                    subd      #$FFFF    test count
                    beq       PadTrailCheck done emitting chars
                    ldb       ,u+       next string char
                    sex                 sign extend
                    pshs      d         push char
                    jsr       [$06,s]   output char
                    leas      2,s        clean argument
                    bra       EmitCharsLoop continue emitting

PadTrailCheck       ldd       LeftJustifyFlag,y   left-justify flag
                    beq       EmitFieldRet no trailing pad
PadTrailLoop        ldd       $0a,s     load remaining pad count
                    addd      #$FFFF    decrement
                    std       $0a,s     store count
                    subd      #$FFFF    test count
                    ble       EmitFieldRet done padding
                    ldd       PadCharacter,y   load pad character
                    pshs      d         push it
                    jsr       [$06,s]   output pad char
                    leas      2,s        clean argument
                    bra       PadTrailLoop continue padding

EmitFieldRet        puls      pc,u      return

EmitStrField        pshs      u         entry: emit string field
                    ldu       $06,s     load string pointer
                    ldd       $08,s     load field width
                    pshs      d         push width
                    pshs      u         push string pointer
                    lbsr      $23F7     compute string length
                    leas      2,s        clean argument
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #$00      complete negate of length
                    addd      ,s++      width minus length equals pad
                    std       $08,s     store pad count
                    ldd       LeftJustifyFlag,y   left-justify flag
                    bne       StrCharLoop left: skip leading pad
StrPadLeadLoop      ldd       $08,s     load pad count
                    addd      #$FFFF    decrement
                    std       $08,s     store count
                    subd      #$FFFF    test count
                    ble       StrCharLoop done padding
                    ldd       PadCharacter,y   load pad character
                    pshs      d         push it
                    jsr       [$06,s]   output pad char
                    leas      2,s        clean argument
                    bra       StrPadLeadLoop continue padding

StrCharLoop         ldb       ,u        peek next char
                    beq       StrPadTrailCheck end of string
                    ldb       ,u+       fetch and advance
                    sex                 sign extend
                    pshs      d         push char
                    jsr       [$06,s]   output char
                    leas      2,s        clean argument
                    bra       StrCharLoop continue emitting

StrPadTrailCheck    ldd       LeftJustifyFlag,y   left-justify flag
                    beq       PutcRet   no trailing pad
StrPadTrailLoop     ldd       $08,s     load remaining pad count
                    addd      #$FFFF    decrement
                    std       $08,s     store count
                    subd      #$FFFF    test count
                    ble       PutcRet   done padding
                    ldd       PadCharacter,y   load pad character
                    pshs      d         push it
                    jsr       [$06,s]   output pad char
                    leas      2,s        clean argument
                    bra       StrPadTrailLoop continue padding

PutcRet             puls      pc,u      restore and return to caller

PutcStdout          pshs      u         save frame register
                    ldd       OutputPointer,y   load the default output stream pointer
                    pshs      d         pass stream as first argument
                    ldd       $06,s     fetch the byte to write
                    pshs      d         pass byte as second argument
                    lbsr      $1FB2     call putc on the default stream
PutcStdoutDone      leas      4,s        drop the two arguments
                    puls      pc,u      restore and return

BufAppendByte       pshs      u         save frame register
                    ldd       $04,s     load the byte to store
                    ldx       OutputPointer,y   load the current buffer cursor
                    leax      $01,x     advance cursor one byte
                    stx       OutputPointer,y   save the updated cursor
                    stb       -$01,x    store byte at the old cursor
                    puls      pc,u      restore and return

MsgIntMin           fcc       /-32768/
                    fcb       C$NULL
                    pshs      u         save frame register
                    ldu       $06,s     load the FILE stream pointer
                    ldd       $06,u     load the stream flags
                    anda      #$80      isolate the high flag bit
                    andb      #$22      isolate write and error bits
                    cmpd      #$8002    test the special error-write state
                    beq       PutcModeCheck skip buffer setup if already flagged
                    ldd       $06,u     reload the flags
                    clra                keep only the low flag byte
                    andb      #$22      isolate the write-mode bits
                    cmpd      #$0002    check the stream is open for writing
                    lbne      IoErr     fail if not writable
                    pshs      u         pass the stream to the allocator
                    lbsr      FillBuf   allocate the stream buffer
                    leas      2,s        drop the argument
PutcModeCheck       ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$04      test the unbuffered bit
                    beq       PutcBuffered branch to the buffered path
                    ldd       #$0001    count of one byte
                    pshs      d         push the byte count
                    leax      $07,s     point at the byte argument
                    pshs      x         push the buffer address
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the descriptor
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$40      test the text-translation bit
                    beq       PutcSelectBin choose the binary writer
                    leax      WriteLnBytes,pcr select the text-mode write routine
                    bra       PutcInvokeWrite go invoke it

PutcSelectBin       leax      WriteBytes,pcr select the binary write routine
PutcInvokeWrite     tfr       x,d       move the routine address
                    tfr       d,x       back into the pointer register
                    jsr       ,x        call the write routine
                    leas      6,s        drop the three arguments
                    cmpd      #$FFFF    check for a write error
                    bne       PutcReturn return the byte if written
                    ldd       $06,u     load the flags
                    orb       #$20      mark the stream in error
                    std       $06,u     store the updated flags
                    lbra      IoErr     return the error

PutcBuffered        ldd       $06,u     load the flags
                    anda      #$01      isolate the read-active bit
                    clrb                clear the low byte
                    std       -$02,s    save the test result
                    bne       PutcStore skip init if already writing
                    pshs      u         pass the stream
                    lbsr      FlushBuf  flush to initialize the buffer
                    leas      2,s        drop the argument
PutcStore           ldd       ,u        load the buffer write pointer
                    addd      #$0001    advance the pointer
                    std       ,u        store the new pointer
                    subd      #$0001    recover the old pointer
                    tfr       d,x       into the index register
                    ldd       $04,s     load the byte
                    stb       ,x        store byte into the buffer
                    ldd       ,u        reload the write pointer
                    cmpd      $04,u     compare against the buffer end
                    bcc       PutcFlush flush when the buffer is full
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$40      test the line-buffer bit
                    beq       PutcReturn done if not line buffered
                    ldd       $04,s     load the byte
                    cmpd      #$000D    check for a carriage return
                    bne       PutcReturn done unless newline
PutcFlush           pshs      u         pass the stream
                    lbsr      FlushBuf  flush the buffer
                    std       ,s++      test the flush result
                    lbne      IoErr     return error on flush failure
PutcReturn          ldd       $04,s     return the written byte
                    puls      pc,u      restore and return

                    pshs      u         save frame register for putw
                    ldu       $04,s     load the stream pointer
                    ldd       $06,s     load the word to write
                    pshs      d         save the word for later
                    pshs      u         push the stream argument
                    ldd       #$0008    prepare a shift of eight bits
                    lbsr      LsrEntry  extract the high byte
                    pshs      d         push the high byte argument
                    lbsr      $1FB2     write the high byte first
                    leas      4,s        drop the arguments
                    ldd       $06,s     reload the word
                    pshs      d         push the low byte argument
                    pshs      u         push the stream argument
                    lbsr      $1FB2     write the low byte
                    lbra      FlushBufDone return through the common exit

FlushAll            pshs      u,d       save registers for flush-all
                    leau      InputPathBuffer,y   point at the stream table
                    clra                zero the index
                    clrb                zero the index
                    std       ,s        initialize the loop counter
FlushAllLoop        ldd       ,s        load the loop index
                    addd      #$0001    increment the index
                    std       ,s        store the index
                    subd      #$0001    recover the index value
                    cmpd      #$0010    compare against the stream count
                    bge       FlushAllDone exit when all streams done
                    tfr       u,d       copy the current stream pointer
                    leau      $0d,u     advance to the next stream entry
                    pshs      d         pass this stream
                    bsr       FcloseOne close and flush the stream
                    leas      2,s        drop the argument
                    bra       FlushAllLoop loop to the next stream

FlushAllDone        puls      pc,u,x    restore and return

FcloseOne           pshs      u         save frame register for fclose
                    ldu       $04,s     load the stream pointer
                    leas      -2,s       reserve a local
                    cmpu      #$0000    check for a null stream
                    beq       FcloseNull fail if null
                    ldd       $06,u     load the flags
                    bne       FcloseFlush proceed if the stream is in use
FcloseNull          ldd       #$FFFF    return failure
                    puls      pc,u,x    restore and return

FcloseFlush         ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$02      test the write-mode bit
                    beq       FcloseNoFlush skip flush if not writing
                    pshs      u         pass the stream
                    bsr       Fflush    flush pending output
                    leas      2,s        drop the argument
                    bra       FcloseCallClose continue to the close

FcloseNoFlush       clra                no flush result
                    clrb                no flush result
FcloseCallClose     std       ,s        save the flush result
                    ldd       $08,u     load the file descriptor
                    pshs      d         pass the descriptor
                    lbsr      CloseFile close the file
                    leas      2,s        drop the argument
                    clra                clear the flags
                    clrb                clear the flags
                    std       $06,u     mark the stream free
                    ldd       ,s        return the flush result
                    puls      pc,u,x    restore and return

Fflush              pshs      u         save frame register for fflush
                    ldu       $04,s     load the stream pointer
                    beq       IoErr     fail if null stream
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$22      isolate write and error bits
                    cmpd      #$0002    check the stream is writable
                    beq       FflushWrite flush if writable
IoErr               ldd       #$FFFF    return the error code
                    puls      pc,u      restore and return

FflushWrite         ldd       $06,u     load the flags
                    anda      #$80      isolate the high flag bit
                    clrb                clear the low byte
                    std       -$02,s    save the test result
                    bne       FflushTail skip alloc if already set
                    pshs      u         pass the stream
                    lbsr      FillBuf   allocate the buffer if needed
                    leas      2,s        drop the argument
FflushTail          pshs      u         pass the stream
                    bsr       FlushBuf  perform the buffer flush
                    puls      pc,u,x    restore and return

FlushBuf            pshs      u         save frame register for flush
                    ldu       $04,s     load the stream pointer
                    leas      -4,s       reserve locals
                    ldd       $06,u     load the flags
                    anda      #$01      isolate the read bit
                    clrb                clear the low byte
                    std       -$02,s    save the test result
                    bne       FlushBufCount skip if a read stream
                    ldd       ,u        load the write pointer
                    cmpd      $04,u     compare with the buffer base
                    beq       FlushBufCount skip if the buffer is empty
                    clra                zero the value
                    clrb                zero the value
                    pshs      d         push a null argument
                    pshs      u         push the stream
                    lbsr      TellPos   compute the buffer position
                    leas      2,s        drop the argument
                    ldd       $02,x     load the end pointer from result
                    pshs      d         push the end pointer
                    ldd       ,x        load the start pointer
                    pshs      d         push the start pointer
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the descriptor
                    lbsr      LseekFile seek to the file position
                    leas      8,s        drop the arguments
FlushBufCount       ldd       ,u        load the write pointer
                    subd      $02,u     compute the bytes buffered
                    std       $02,s     save the byte count
                    lbeq      FlushResetPtr reset if nothing to write
                    ldd       $06,u     load the flags
                    anda      #$01      isolate the read bit
                    clrb                clear the low byte
                    std       -$02,s    save the test result
                    lbeq      FlushResetPtr reset if a read stream
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$40      test the text-mode bit
                    beq       FlushWriteBlock block write if binary
                    ldd       $02,u     load the buffer base pointer
FlushWriteLoop      std       ,u        reset write pointer to base
                    ldd       $02,s     load the remaining count
                    lbeq      FlushResetPtr done when all written
                    ldd       $02,s     load the remaining count
                    pshs      d         push the count
                    ldd       ,u        load the current pointer
                    pshs      d         push the buffer pointer
                    ldd       $08,u     load the descriptor
                    pshs      d         push the descriptor
                    lbsr      WriteLnBytes write chunk in text mode
                    leas      6,s        drop the arguments
                    std       ,s        save the bytes written
                    cmpd      #$FFFF    check for a write error
                    bne       FlushLoopAdvance continue if written
                    leax      $04,s     point at the error result
                    bra       FlushErrAdjust handle the write error

FlushLoopAdvance    ldd       $02,s     load the remaining count
                    subd      ,s        subtract the bytes written
                    std       $02,s     update the remaining count
                    ldd       ,u        load the current pointer
                    addd      ,s        advance by the bytes written
                    bra       FlushWriteLoop loop for the remaining bytes

FlushWriteBlock     ldd       $02,s     load the byte count
                    pshs      d         push the count
                    ldd       $02,u     load the buffer base
                    pshs      d         push the buffer pointer
                    ldd       $08,u     load the descriptor
                    pshs      d         push the descriptor
                    lbsr      WriteBytes write the whole buffer binary
                    leas      6,s        drop the arguments
                    cmpd      $02,s     check all bytes written
                    beq       FlushResetPtr reset on a full write
                    bra       FlushSetErr otherwise flag an error

FlushErrAdjust      leas      -$04,x    restore stack after the error
FlushSetErr         ldd       $06,u     load the flags
                    orb       #$20      mark the stream in error
                    std       $06,u     store the flags
                    ldd       $04,u     load the buffer limit
                    std       ,u        reset the write pointer
                    ldd       #$FFFF    return the error
                    bra       FlushBufDone exit through the common tail

FlushResetPtr       ldd       $06,u     load the flags
                    ora       #$01      mark the empty/read state
                    std       $06,u     store the flags
                    ldd       $02,u     load the buffer base
                    std       ,u        reset the current pointer
                    addd      $0b,u     add the buffer size
                    std       $04,u     set the buffer end pointer
                    clra                return success zero
                    clrb                return success zero
FlushBufDone        leas      4,s        drop the locals
                    puls      pc,u      restore and return

TellPos             pshs      u         save frame register
                    puls      pc,u      return the position pointer

Getc                pshs      u         save frame register for getc
                    ldu       $04,s     load the stream pointer
                    beq       GetcEof   eof if null stream
                    ldd       $06,u     load the flags
                    anda      #$01      isolate the error bit
                    clrb                clear the low byte
                    std       -$02,s    save the test result
                    bne       GetcEof   eof if flagged
                    ldd       ,u        load the read pointer
                    cmpd      $04,u     compare with the buffer end
                    bcc       GetcFill  refill when the buffer is empty
                    ldd       ,u        load the read pointer
                    addd      #$0001    advance the pointer
                    std       ,u        store the new pointer
                    subd      #$0001    recover the old pointer
                    tfr       d,x       into the index register
                    ldb       ,x        read the byte from the buffer
                    clra                widen to a word
                    bra       GetcRet   return the byte

GetcFill            pshs      u         pass the stream
                    lbsr      Filbuf    refill from the file
                    leas      2,s        drop the argument
GetcRet             puls      pc,u      restore and return

                    pshs      u         save frame register for ungetc
                    ldu       $06,s     load the stream pointer
                    beq       GetcEof   fail if null stream
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$01      test the read-mode bit
                    beq       GetcEof   fail if not reading
                    ldd       $04,s     load the pushback byte
                    cmpd      #$FFFF    reject an eof pushback
                    beq       GetcEof   fail on eof
                    ldd       ,u        load the read pointer
                    cmpd      $02,u     check room before buffer start
                    bhi       UngetcStore store if space is available
GetcEof             ldd       #$FFFF    return eof
                    puls      pc,u      restore and return

UngetcStore         ldd       ,u        load the read pointer
                    addd      #$FFFF    back up one byte
                    std       ,u        store the new pointer
                    tfr       d,x       into the index register
                    ldd       $04,s     load the pushback byte
                    stb       ,x        store byte back in the buffer
                    ldd       $04,s     return the byte
                    puls      pc,u      restore and return

                    pshs      u         save frame register for getw
                    ldu       $04,s     load the stream pointer
                    leas      -4,s       reserve locals
                    pshs      u         push the stream
                    lbsr      Getc      read the high byte
                    leas      2,s        drop the argument
                    std       $02,s     save the high byte
                    cmpd      #$FFFF    check for eof
                    beq       GetwEof   fail on eof
                    pshs      u         push the stream
                    lbsr      Getc      read the low byte
                    leas      2,s        drop the argument
                    std       ,s        save the low byte
                    cmpd      #$FFFF    check for eof
                    bne       GetwCombine combine if valid
GetwEof             ldd       #$FFFF    return eof
                    bra       GetwDone  exit

GetwCombine         ldd       $02,s     load the high byte
                    pshs      d         push the high byte
                    ldd       #$0008    shift amount of eight
                    lbsr      AslEntry  shift high byte into place
                    addd      ,s        combine with the low byte
GetwDone            leas      4,s        drop the locals
                    puls      pc,u      restore and return

Filbuf              pshs      u         save frame register for fill
                    ldu       $04,s     load the stream pointer
                    leas      -2,s       reserve a local
                    ldd       $06,u     load the flags
                    anda      #$80      isolate the high flag bit
                    andb      #$31      isolate read and mode bits
                    cmpd      #$8001    test an uninitialized read stream
                    beq       FilbufSyncStdin initialize the buffer if so
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$31      isolate the read-mode bits
                    cmpd      #$0001    check open for reading
                    beq       FilbufRead proceed if readable
                    ldd       #$FFFF    return eof
                    puls      pc,u,x    restore and return

FilbufRead          pshs      u         pass the stream
                    lbsr      FillBuf   allocate the read buffer
                    leas      2,s        drop the argument
FilbufSyncStdin     leax      InputPathBuffer,y   point at the standard input entry
                    pshs      x         push it for comparison
                    cmpu      ,s++      is this the console input
                    bne       FilbufSeek skip sync if not stdin
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$40      test the line-buffer bit
                    beq       FilbufSeek skip if not line buffered
                    leax      OutputPathBuffer,y   point at the standard output entry
                    pshs      x         push stdout
                    lbsr      Fflush    flush stdout before reading
                    leas      2,s        drop the argument
FilbufSeek          ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$08      test the seek-required bit
                    beq       GetcReadOne skip seek if not needed
                    ldd       $0b,u     load the buffer size
                    pshs      d         push the size
                    ldd       $02,u     load the buffer base
                    pshs      d         push the base pointer
                    ldd       $08,u     load the descriptor
                    pshs      d         push the descriptor
                    ldd       $06,u     load the flags
                    clra                keep the low byte
                    andb      #$40      test the text-mode bit
                    beq       FilbufSelectBin choose the binary reader
                    leax      ReadLnBytes,pcr select the text-mode read routine
                    bra       FilbufInvokeRead go invoke it

FilbufSelectBin     leax      ReadBytes,pcr select the binary read routine
FilbufInvokeRead    tfr       x,d       move the routine address
                    tfr       d,x       into the pointer register
                    jsr       ,x        call the read routine
                    bra       GetcCheckRead continue after the read

GetcReadOne         ldd       #$0001    request a single byte
                    pshs      d         push the length argument
                    leax      $0a,u     point at the inline one-byte buffer
                    stx       $02,u     set current pointer to that buffer
                    pshs      x         push the buffer argument
                    ldd       $08,u     load the file descriptor
                    pshs      d         push the path argument
                    lbsr      ReadBytes call the low-level read helper
GetcCheckRead       leas      6,s        drop the three arguments
                    std       ,s        save the bytes-read count
                    ldd       ,s        reload the count
                    bgt       GetcReturnByte branch if a byte was read
                    ldd       $06,u     load the stream flags
                    pshs      d         save the flags
                    ldd       $02,s     test the returned count
                    beq       GetcSetEof zero means end of file
                    ldd       #$0020    error flag bit
                    bra       GetcOrFlags go merge the flag

GetcSetEof          ldd       #$0010    end-of-file flag bit
GetcOrFlags         ora       ,s+       merge the flag into the stream flags
                    orb       ,s+       low byte too
                    std       $06,u     store the updated flags
                    ldd       #$FFFF    return -1 for eof
                    puls      pc,u,x    return

GetcReturnByte      ldd       $02,u     load the current buffer pointer
                    addd      #$0001    advance past the byte
                    std       ,u        store the new base pointer
                    ldd       $02,u     reload the pointer
                    addd      ,s        add the count to get the end
                    std       $04,u     store the end pointer
                    ldb       [$02,u]   fetch the byte just read
                    clra                zero-extend to a word
                    puls      pc,u,x    return the byte

FillBuf             pshs      u         save the frame
                    ldu       $04,s     load the stream pointer argument
                    ldd       $06,u     load the stream flags
                    clra                isolate the low byte
                    andb      #$C0      test the buffering bits
                    bne       FillBufMarkActive already set up, skip allocation
                    leas      -32,s      reserve a local scratch buffer
                    leax      ,s        point at it
                    pshs      x         push its address
                    ldd       $08,u     load the file descriptor
                    pshs      d         push it
                    clra                clear the high byte
                    clrb                clear the low byte
                    pshs      d         push a zero argument
                    lbsr      QueryOperand query the device information
                    leas      6,s        drop the arguments
                    ldd       $06,u     reload the flags
                    pshs      d         save them
                    ldb       $02,s     test the device-type result
                    bne       FillBufFully nonzero selects block buffering
                    ldd       #$0040    line-buffered flag
                    bra       FillBufOrMode go merge it

FillBufFully        ldd       #$0080    fully-buffered flag
FillBufOrMode       ora       ,s+       merge the buffering-mode flag
                    orb       ,s+       low byte too
                    std       $06,u     store the flags
                    leas      32,s       release the local buffer
FillBufMarkActive   ldd       $06,u     load the flags
                    ora       #$80      mark the stream active
                    std       $06,u     store back
                    clra                isolate the low byte
                    andb      #$0C      test the eof/error bits
                    beq       FillBufSize none set, continue
                    puls      pc,u      abort on eof or error

FillBufSize         ldd       $0b,u     load the buffer size
                    bne       FillBufAlloc already sized, skip default
                    ldd       $06,u     load the flags
                    clra                isolate the low byte
                    andb      #$40      test line-buffered
                    beq       FillBufDefSize not line-buffered
                    ldd       #$0080    small buffer size
                    bra       FillBufStoreSize go store it

FillBufDefSize      ldd       #$0100    default buffer size
FillBufStoreSize    std       $0b,u     store the buffer size
FillBufAlloc        ldd       $02,u     load the current pointer
                    bne       FillBufAllocOk buffer already allocated
                    ldd       $0b,u     load the buffer size
                    pshs      d         push it
                    lbsr      MemExtend allocate the buffer
                    leas      2,s        drop the argument
                    std       $02,u     store the buffer pointer
                    cmpd      #$FFFF    check the allocation result
                    beq       FillBufAllocFail allocation failed
FillBufAllocOk      ldd       $06,u     load the flags
                    orb       #$08      mark heap-allocated buffer
                    std       $06,u     store back
                    bra       FillBufSetPtrs go finish setup

FillBufAllocFail    ldd       $06,u     load the flags
                    orb       #$04      mark use of the inline buffer
                    std       $06,u     store back
                    leax      $0a,u     point at the inline buffer
                    stx       $02,u     use it as the buffer
                    ldd       #$0001    size of one byte
                    std       $0b,u     store the size
FillBufSetPtrs      ldd       $02,u     load the buffer base
                    addd      $0b,u     add the size
                    std       $04,u     set the end pointer
                    std       ,u        set the current pointer
                    puls      pc,u      return

FormatConv          pshs      u         save the frame
                    ldb       $05,s     load the format character
                    sex                 sign-extend it
                    tfr       d,x       move into X for dispatch
                    bra       ConvSwitch jump to the switch

ConvNumeric         ldd       [$06,s]   load the varargs pointer
                    addd      #$0004    advance by one argument
                    std       [$06,s]   store it back
                    leax      >StrlenThunk,pcr point at the numeric handler
                    bra       ConvReturn return that pointer

ConvChar            ldb       $05,s     reload the character
                    stb       WorkArea2,y   store it in the work area
                    leax      WorkArea,y   point at the work area
ConvReturn          tfr       x,d       move the result pointer to D
                    puls      pc,u      return

ConvSwitch          cmpx      #$0064    is it the d conversion
                    beq       ConvNumeric handle it as numeric
                    cmpx      #$006F    is it the o conversion
                    lbeq      ConvNumeric handle it as numeric
                    cmpx      #$0078    is it the x conversion
                    lbeq      ConvNumeric handle it as numeric
                    bra       ConvChar  default character copy

                    puls      pc,u      unreachable return

* ------------------------------------------------------------------
* StrlenThunk/StrLen - reached ONLY via leax,pcr data pointers (never
* branched or called), so the linear sweep decoded them as code.  They
* read as a pair of function-pointer thunks: StrlenThunk returns &StrLen
* in D; StrLen is strlen(4,s) - scan ldb,u+/bne for the NUL, length =
* (end - start - 1).  But the leading "neg $34 / nega" ($00 $34 $40)
* prologue would clobber DP $34 and A, which makes no sense as code, so
* these may instead be data the sweep mis-framed.  Left as code: byte-
* exact either way and the body reads as a genuine strlen.
* ------------------------------------------------------------------
StrlenThunk         neg       $0034     thunk prologue decoded from data
                    nega                thunk prologue continued
                    leax      >StrLen,pcr point at the strlen routine
                    tfr       x,d       return its address
                    puls      pc,u      return

* StrLen - strlen routine (entered via the &StrLen pointer returned above):
StrLen              neg       $0034     thunk prologue decoded from data
                    nega                thunk prologue continued
                    ldu       $04,s     load the string pointer
StrLenLoop3         ldb       ,u+       scan the bytes
                    bne       StrLenLoop3 until the NUL
                    tfr       u,d       end pointer
                    subd      $04,s     minus the start
                    addd      #$FFFF    minus one for the NUL
                    puls      pc,u      return the length

StrCopy             pshs      u         save the frame
                    ldu       $06,s     load the source pointer
                    leas      -2,s       local for the dest cursor
                    ldd       $06,s     load the dest pointer
                    std       ,s        initialise the cursor
StrCopyLoop         ldb       ,u+       read a source byte
                    ldx       ,s        load the dest cursor
                    leax      $01,x     advance the cursor
                    stx       ,s        store the cursor
                    stb       -$01,x    write the byte
                    bne       StrCopyLoop loop until NUL copied
                    ldd       $06,s     return the dest pointer
                    puls      pc,u,x    return

                    pshs      u         save the frame
                    ldu       $06,s     load the source pointer
                    leas      -2,s       local for the cursor
                    ldd       $06,s     load the dest pointer
                    std       ,s        initialise the cursor
StrCatScanLoop      ldx       ,s        load the cursor
                    leax      $01,x     advance it
                    stx       ,s        store it
                    ldb       -$01,x    read a dest byte
                    bne       StrCatScanLoop scan to the terminator
                    ldd       ,s        cursor at the terminator
                    addd      #$FFFF    back up onto the NUL
                    std       ,s        store the cursor
StrCatCopyLoop      ldb       ,u+       read a source byte
                    ldx       ,s        load the cursor
                    leax      $01,x     advance it
                    stx       ,s        store it
                    stb       -$01,x    append the byte
                    bne       StrCatCopyLoop loop until NUL copied
                    ldd       $06,s     return the dest pointer
                    puls      pc,u,x    return

StrCmp              pshs      u         save the frame
                    ldu       $04,s     load the first string pointer
StrCmpLoop          ldb       ,u        byte of the first string
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       [$08,s]   byte of the second string
                    sex                 sign-extend
                    cmpd      ,s++      compare the two bytes
                    bne       StrCmpDiff they differ, compute the result
                    ldx       $06,s     load the second pointer
                    leax      $01,x     advance it
                    stx       $06,s     store it
                    ldb       -$01,x    the compared byte
                    bne       StrCmpNext not NUL, keep comparing
                    clra                strings are equal
                    clrb                return zero
                    puls      pc,u      return

StrCmpNext          leau      $01,u     advance the first pointer
                    bra       StrCmpLoop loop

StrCmpDiff          ldb       [$06,s]   second byte
                    sex                 sign-extend
                    pshs      d         save it
                    ldb       ,u        first byte
                    sex                 sign-extend
                    subd      ,s++      compute the difference
                    puls      pc,u      return the signed difference

                    use       lib/imul.asm

UDivMod             subd      #$0000    test the divisor
                    beq       DivZeroErr zero divisor, raise the trap
                    pshs      d         save the divisor
                    leas      -2,s       local for the sign flags
                    clr       ,s        no sign fixup needed
                    clr       $01,s     clear the other sign flag
                    bra       DivNormalize do the division

DivZeroErr          puls      d         restore the divisor
                    std       ,s        store it
                    ldd       #$002D    arithmetic-trap signal code
                    lbra      RaiseSignal raise the signal

SDivMod             subd      #$0000    test the divisor
                    beq       DivZeroErr zero divisor, raise the trap
                    pshs      d         save the divisor
                    leas      -2,s       local for the sign flags
                    clr       ,s        clear a sign flag
                    clr       $01,s     clear the other sign flag
                    tsta                is the dividend negative
                    bpl       DivChkDivisorSign no, leave it
                    nega                negate the dividend
                    negb                negate the low byte
                    sbca      #$00      propagate the borrow
                    inc       $01,s     record the sign
                    std       $02,s     store the negated dividend
DivChkDivisorSign   ldd       $06,s     load the divisor
                    bpl       DivNormalize positive, proceed
                    nega                negate the divisor
                    negb                negate the low byte
                    sbca      #$00      propagate the borrow
                    com       $01,s     flip the result sign
                    std       $06,s     store the negated divisor
DivNormalize        lda       #$01      start the shift count
DivNormLoop         inca                count a leading bit
                    asl       $03,s     shift the divisor left
                    rol       $02,s     through the high half
                    bpl       DivNormLoop until aligned
                    sta       ,s        save the shift count
                    ldd       $06,s     load the dividend
                    clr       $06,s     clear the remainder
                    clr       $07,s     clear the remainder high
DivLoop             subd      $02,s     trial subtract the divisor
                    bcc       DivQuotBit it fits, set the bit
                    addd      $02,s     restore the dividend
                    andcc     #$FE      clear the quotient bit
                    bra       DivShiftStep go shift

DivQuotBit          orcc      #$01      set the quotient bit
DivShiftStep        rol       $07,s     shift the bit into the quotient
                    rol       $06,s     through the high half
                    lsr       $02,s     shift the divisor down
                    ror       $03,s     through the low half
                    dec       ,s        decrement the counter
                    bne       DivLoop   loop
                    std       $02,s     store the remainder
                    tst       $01,s     is a sign fixup needed
                    beq       DivFinish no, done
                    ldd       $06,s     load the quotient
                    nega                negate it
                    negb                negate the low byte
                    sbca      #$00      propagate the borrow
                    std       $06,s     store the negated quotient
DivFinish           ldx       $04,s     grab the saved return slot
                    ldd       $06,s     load the quotient
                    std       $04,s     store it
                    stx       $06,s     restore the slot
                    ldx       $02,s     take the remainder
                    ldd       $04,s     result into D
                    leas      6,s        drop the locals
                    rts                 return the quotient
                    use       lib/shift.asm

RaiseSignal         std       ErrorFlag,y   save the signal code
                    pshs      y,b       preserve registers
                    os9       F$ID      get our process id
                    puls      y,b       restore registers
                    os9       F$Send    send the signal to ourself
                    rts                 return

QueryOperand        lda       $05,s     load the path number
                    ldb       $03,s     load the operand type
                    beq       QueryCaseZero type 0 case
                    cmpb      #$01      type 1
                    beq       SsGetStt  handle it
                    cmpb      #$06      type 6
                    beq       SsGetStt  handle it
                    cmpb      #$02      type 2
                    beq       QueryViaGetStt handle it
                    cmpb      #$05      type 5
                    beq       QueryViaGetStt handle it
                    ldb       #$D0      bad-type error code
                    lbra      SetErrnoRet report the error

QueryViaGetStt      pshs      u         save the frame
                    os9       I$GetStt  query the file status
                    bcc       QueryGetSttOk succeeded
                    puls      u         restore the frame
                    lbra      SetErrnoRet report the error

QueryGetSttOk       stx       [$08,s]   store the status result
                    ldx       $08,s     reload the result slot
                    stu       $02,x     store the pointer
                    puls      u         restore the frame
                    clra                success
                    clrb                return zero
                    rts                 return

QueryCaseZero       ldx       $06,s     load the type-0 operand pointer
SsGetStt            os9       I$GetStt  get file status
                    lbra      RetZeroOrErr return status

                    lda       $05,s     load status code argument
                    ldb       $03,s     select set-status function
                    beq       SsSetStt  function 0 does plain setstat
                    cmpb      #$02      check for function 2
                    beq       SsSetSttU function 2 setstat with parameters
                    ldb       #$D0      unknown function error
                    lbra      SetErrnoRet return error

SsSetStt            ldx       $06,s     load parameter pointer
                    os9       I$SetStt  set file status
                    lbra      RetZeroOrErr return status

SsSetSttU           pshs      u         save u
                    ldx       $08,s     load x parameter
                    ldu       $0a,s     load u parameter
                    os9       I$SetStt  set file status
                    puls      u         restore u
                    lbra      RetZeroOrErr return status

                    ldx       $02,s     load path name pointer
                    lda       $05,s     load access mode
                    os9       I$Open    open the file
                    bcs       AccessDone skip close on error
                    os9       I$Close   close immediately for access test
AccessDone          lbra      RetZeroOrErr return status

OpenFile            ldx       $02,s     load path name pointer
                    lda       $05,s     load access mode
                    os9       I$Open    open the file
                    lbcs      SetErrnoRet error returns -1
                    tfr       a,b       move path number to b
                    clra                clear high byte
                    rts                 return path number

CloseFile           lda       $03,s     load path number
                    os9       I$Close   close the path
                    lbra      RetZeroOrErr return status

                    ldx       $02,s     load directory name pointer
                    ldb       $05,s     load access mode
                    os9       I$MakDir  make the directory
                    lbra      RetZeroOrErr return status

CreateFile          ldx       $02,s     load path name pointer
                    lda       $05,s     load mode
                    tfr       a,b       copy mode
                    andb      #$24      mask permission bits
                    orb       #$0b      force create attributes
                    os9       I$Create  create the file
                    bcs       CreateExisting handle create error
RetPathNum          tfr       a,b       move path number to b
                    clra                clear high byte
                    rts                 return path number

CreateExisting      cmpb      #$DA      file-already-exists error
                    lbne      SetErrnoRet other errors return -1
                    lda       $05,s     reload mode
                    bita      #$80      test exclusive-create bit
                    lbne      SetErrnoRet fail if exclusive requested
                    anda      #$07      keep access bits only
                    ldx       $02,s     load path name pointer
                    os9       I$Open    open the existing file
                    lbcs      SetErrnoRet error returns -1
                    pshs      u,a       save path number
                    ldx       #$0000    new size is zero
                    leau      ,x        clear u
                    ldb       #$02      setstat size code
                    os9       I$SetStt  truncate file to zero
                    puls      u,a       restore path number
                    bcc       RetPathNum success returns path number
                    pshs      b         save error code
                    os9       I$Close   close on failure
                    puls      b         restore error code
                    lbra      SetErrnoRet return error

                    ldx       $02,s     load path name pointer
                    os9       I$Delete  delete the file
                    lbra      RetZeroOrErr return status

                    lda       $03,s     load path number
                    os9       I$Dup     duplicate the path
                    lbcs      SetErrnoRet error returns -1
                    tfr       a,b       move new path number
                    clra                clear high byte
                    rts                 return new path number

ReadBytes           pshs      y         save y
                    ldx       $06,s     load buffer pointer
                    lda       $05,s     load path number
                    ldy       $08,s     load byte count
                    pshs      y         save count for return
                    os9       I$Read    read the bytes
IoDone              bcc       IoRetCount success handles count
                    cmpb      #$D3      end-of-file error
                    bne       IoErr2    other error path
                    clra                zero count at eof
                    clrb                zero count at eof
                    puls      pc,y,x    return zero at eof

IoErr2              puls      y,x       clean stack
                    lbra      SetErrnoRet return error

IoRetCount          tfr       y,d       actual count returned
                    puls      pc,y,x    return count

ReadLnBytes         pshs      y         save y
                    lda       $05,s     load path number
                    ldx       $06,s     load buffer pointer
                    ldy       $08,s     load byte count
                    pshs      y         save count for return
                    os9       I$ReadLn  read a line
                    bra       IoDone    share read completion

WriteBytes          pshs      y         save y
                    ldy       $08,s     load byte count
                    beq       WriteRetCount zero count returns zero
                    lda       $05,s     load path number
                    ldx       $06,s     load buffer pointer
                    os9       I$Write   write the bytes
WriteDone           bcc       WriteRetCount success returns count
                    puls      y         clean stack
                    lbra      SetErrnoRet return error

WriteRetCount       tfr       y,d       count written
                    puls      pc,y      return count

WriteLnBytes        pshs      y         save y
                    ldy       $08,s     load byte count
                    beq       WriteRetCount zero count returns zero
                    lda       $05,s     load path number
                    ldx       $06,s     load buffer pointer
                    os9       I$WritLn  write a line
                    bra       WriteDone share write completion

LseekFile           pshs      u         save u
                    ldd       $0a,s     load whence argument
                    bne       SeekWhence nonzero whence
                    ldu       #$0000    base zero for seek-set
                    ldx       #$0000    base zero for seek-set
                    bra       SeekCompute compute seek position

SeekWhence          cmpd      #$0001    whence 1 is seek-current
                    beq       SeekCur   seek from current position
                    cmpd      #$0002    whence 2 is seek-end
                    beq       SeekEnd   seek from end
                    ldb       #$F7      bad-whence error
SeekErr             clra                clear high byte
                    std       ErrorFlag,y   store errno
                    ldd       #$FFFF    return -1
                    leax      SeekBuffer,y   point at seek buffer
                    std       ,x        clear seek buffer
                    std       $02,x     clear seek buffer
                    puls      pc,u      return error

SeekEnd             lda       $05,s     load path number
                    ldb       #$02      get file size code
                    os9       I$GetStt  query end position
                    bcs       SeekErr   error path
                    bra       SeekCompute compute seek position

SeekCur             lda       $05,s     load path number
                    ldb       #$05      get current position code
                    os9       I$GetStt  query current position
                    bcs       SeekErr   error path
SeekCompute         tfr       u,d       base low word
                    addd      $08,s     add offset low word
                    std       ResultLowWord,y   store result low word
                    tfr       d,u       keep low word in u
                    tfr       x,d       base high word
                    adcb      $07,s     add offset high with carry
                    adca      $06,s     add offset high byte
                    bmi       SeekErr   negative position is error
                    tfr       d,x       keep high word in x
                    std       SeekBuffer,y   store result high word
                    lda       $05,s     load path number
                    os9       I$Seek    seek to new position
                    bcs       SeekErr   error path
                    leax      SeekBuffer,y   point at new position
                    puls      pc,u      return position

Sbrk                ldd       BreakPointer,y   load current break pointer
                    pshs      d         save current break
                    ldd       $04,s     requested block size
                    cmpd      UpdateFreeCount,y   compare with free space
                    bcs       AllocBlock enough free skips grow
                    addd      BreakPointer,y   new break needed
                    pshs      y         save y
                    subd      ,s        bytes to request
                    os9       F$Mem     request more memory
                    tfr       y,d       new memory size
                    puls      y         restore y
                    bcc       SbrkOk    allocation succeeded
                    ldd       #$FFFF    return failure
                    leas      2,s        clean stack
                    rts                 return failure

SbrkOk              std       BreakPointer,y   store new break
                    addd      UpdateFreeCount,y   add old free space
                    subd      ,s        less old break
                    std       UpdateFreeCount,y   update free count
AllocBlock          leas      2,s        drop saved break
                    ldd       UpdateFreeCount,y   free byte count
                    pshs      d         save it
                    subd      $04,s     subtract request
                    std       UpdateFreeCount,y   update free count
                    ldd       BreakPointer,y   current break
                    subd      ,s++      compute block start
                    pshs      d         save block pointer
                    clra                zero fill value
                    ldx       ,s        block start pointer
AllocFillLoop       sta       ,x+       zero-fill a byte
                    cmpx      BreakPointer,y   reached break yet
                    bcs       AllocFillLoop continue filling
                    puls      pc,d      return block pointer

MemExtend           ldd       $02,s     requested size
                    addd      OldRegionPointer,y   add to region pointer
                    bcs       ExtendFail overflow fails
                    cmpd      RegionLimit,y   compare region limit
                    bcc       ExtendFail beyond limit fails
                    pshs      d         save new pointer
                    ldx       OldRegionPointer,y   old region pointer
                    clra                zero fill value
ExtendFillLoop      cmpx      ,s        reached new pointer
                    bcc       ExtendOk  done filling
                    sta       ,x+       zero-fill a byte
                    bra       ExtendFillLoop continue filling

ExtendOk            ldd       OldRegionPointer,y   old region pointer
                    puls      x         new region pointer
                    stx       OldRegionPointer,y   update region pointer
                    rts                 return old pointer

ExtendFail          ldd       #$FFFF    return failure
                    rts                 return failure

SetErrnoRet         clra                clear high byte
                    std       ErrorFlag,y   store error in errno
                    ldd       #$FFFF    return -1
                    rts                 return -1

RetZeroOrErr        bcs       SetErrnoRet error sets errno
                    clra                return zero
                    clrb                return zero
                    rts                 return success

exit                lbsr      RtsStub   call termination stub
                    lbsr      FlushAll  flush and clean up
_exit               ldd       $02,s     load exit code
                    os9       F$Exit    terminate process
RtsStub             rts                 return stub

* ------------------------------------------------------------------
* WorkBlockImage - cc1-style init image for the work block (see _start):
* rts stub + count/block table + relocation dirs + module-name string.
* ------------------------------------------------------------------
                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       $0007

                    * ---- block1: DP data image  ->  data base
                    fcb       $00,$00,$00,$00,$00,$00
                    fcb       $00

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
                    fdb       $04F2

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fcb       $00,$00,$01
                    fcb       $2C
                    fcb       $10
                    fcb       $52
                    fcb       $10
                    fcb       $55
                    fcb       $10
                    fcb       $58
                    fcb       $10
                    fcb       $5B
                    fcb       $10
                    fcb       $5E
                    fcb       $10
                    fcb       $61
                    fcb       $10
                    fcb       $64
                    fcb       $10
                    fcb       $67
                    fcb       $10
                    fcb       $6A
                    fcb       $10
                    fcb       $6D
                    fcb       $10
                    fcb       $70
                    fcb       $10
                    fcb       $73
                    fcb       $10
                    fcb       $76
                    fcb       $10
                    fcb       $79
                    fcb       $10
                    fcb       $7C
                    fcb       $10,$7F,$10,$82,$10,$85
                    fcb       $64
                    fcb       C$NULL
                    fcb       $78
                    fcb       C$NULL
                    fcb       $79
                    fcb       C$NULL
                    fcb       $75
                    fcb       C$NULL
                    fcb       $64,$2C,$78
                    fcb       C$NULL
                    fcb       $64,$2C,$79
                    fcb       C$NULL
                    fcb       $64,$2C,$75
                    fcb       C$NULL
                    fcc       /d,x,u/
                    fcb       C$NULL
                    fcc       /d,x,y,u/
                    fcb       C$NULL
                    fcc       /x,u,pc/
                    fcb       C$NULL
                    fcb       $79,$2C,$64
                    fcb       C$NULL
                    fcb       $79,$2C,$75
                    fcb       C$NULL
                    fcb       $75,$2C,$64
                    fcb       C$NULL
                    fcc       /u,pc/
                    fcb       C$NULL
                    fcc       /clra/
                    fcb       C$NULL
                    fcc       /cmpb/
                    fcb       C$NULL
                    fcc       /cmpd/
                    fcb       C$NULL
                    fcc       /cmpx/
                    fcb       C$NULL
                    fcc       /cmpy/
                    fcb       C$NULL
                    fcc       /cmpu/
                    fcb       C$NULL
                    fcb       $6C,$64,$62
                    fcb       C$NULL
                    fcb       $6C,$64,$64
                    fcb       C$NULL
                    fcb       $6C,$64,$78
                    fcb       C$NULL
                    fcb       $6C,$64,$79
                    fcb       C$NULL
                    fcb       $6C,$64,$75
                    fcb       C$NULL
                    fcb       $73,$74,$62
                    fcb       C$NULL
                    fcb       $73,$74,$64
                    fcb       C$NULL
                    fcb       $73,$74,$78
                    fcb       C$NULL
                    fcb       $73,$74,$79
                    fcb       C$NULL
                    fcb       $73,$74,$75
                    fcb       C$NULL
                    fcc       /pshs/
                    fcb       C$NULL
                    fcc       /puls/
                    fcb       C$NULL
                    fcc       /leax/
                    fcb       C$NULL
                    fcc       /leay/
                    fcb       C$NULL
                    fcc       /leau/
                    fcb       C$NULL
                    fcc       /leas/
                    fcb       C$NULL
                    fcb       $73,$65,$78
                    fcb       C$NULL
                    fcb       $74,$66,$72
                    fcb       C$NULL
                    fcb       $23,$30
                    fcb       C$NULL
                    fcb       $32,$2C,$78
                    fcb       C$NULL
                    fcb       $31,$2C,$78
                    fcb       C$NULL
                    fcb       $30,$2C,$78
                    fcb       C$NULL
                    fcc       /-1,x/
                    fcb       C$NULL
                    fcc       /-2,x/
                    fcb       C$NULL
                    fcb       $32,$2C,$79
                    fcb       C$NULL
                    fcb       $31,$2C,$79
                    fcb       C$NULL
                    fcb       $30,$2C,$79
                    fcb       C$NULL
                    fcc       /-1,y/
                    fcb       C$NULL
                    fcc       /-2,y/
                    fcb       C$NULL
                    fcb       $32,$2C,$75
                    fcb       C$NULL
                    fcb       $31,$2C,$75
                    fcb       C$NULL
                    fcb       $30,$2C,$75
                    fcb       C$NULL
                    fcc       /-1,u/
                    fcb       C$NULL
                    fcc       /-2,u/
                    fcb       C$NULL
                    fcb       $32,$2C,$73
                    fcb       C$NULL
                    fcb       $30,$2C,$73
                    fcb       C$NULL
                    fcc       /-2,s/
                    fcb       C$NULL
                    fcb       $23,$3C
                    fcb       $00,$00,$02,$00,$BB,$00,$00,$00
                    fcb       $A7,$00,$01,$00,$01,$00,$01,$00
                    fcb       $00,$00,$02,$00,$BF,$00,$00,$00
                    fcb       $AB,$00,$01,$00,$01,$00,$01,$00
                    fcb       $00,$00,$02,$00,$B7,$00,$00,$00
                    fcb       $A3,$00,$01,$00,$01,$00,$01,$00
                    fcb       $00,$00,$02,$00,$A7,$00,$00,$00
                    fcb       $BB,$00,$01,$00,$01,$00,$01,$00
                    fcb       $00,$00,$02,$00,$AB,$00,$00,$00
                    fcb       $BF,$00,$01,$00,$01,$00,$01,$00
                    fcb       $00,$00,$01,$00,$ED,$00
                    fcb       $74
                    fcb       $00,$CB,$00
                    fcb       $4B
                    fcb       $00,$02,$00
                    fcb       $4F
                    fcb       $00,$00,$00,$01,$00,$ED,$00
                    fcb       $7C
                    fcb       $00,$CB,$00
                    fcb       $4B
                    fcb       $00,$02,$00
                    fcb       $51
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $4D
                    fcb       $00,$CB,$00
                    fcb       $4B
                    fcb       $00,$01,$00
                    fcb       $53
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $51
                    fcb       $00,$CB,$00
                    fcb       $4B
                    fcb       $00,$01,$00
                    fcb       $5B
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $4F
                    fcb       $00,$CB,$00
                    fcb       $4B
                    fcb       $00,$01,$00
                    fcb       $57
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $51
                    fcb       $00,$CB,$00
                    fcb       $4F
                    fcb       $00,$01,$00
                    fcb       $78
                    fcb       $00,$00,$00,$02,$00,$A7,$00,$00
                    fcb       $00,$8F,$00,$F1,$00,$01,$00,$01
                    fcb       $00,$00,$00,$02,$00,$AB,$00,$00
                    fcb       $00,$94,$00,$F1,$00,$01,$00,$01
                    fcb       $00,$00,$00,$02,$00,$AF,$00,$00
                    fcb       $00,$99,$00,$F1,$00,$01,$00,$01
                    fcb       $00,$00,$00,$02,$00,$B3,$00,$00
                    fcb       $00,$9E,$00,$F1,$00,$01,$00,$01
                    fcb       $00,$00,$00,$02,$00,$C3,$00,$00
                    fcb       $00,$99,$00,$F1,$00,$01,$00,$01
                    fcb       $00,$00,$00,$02,$00,$C7,$00,$00
                    fcb       $00,$9E,$00,$F1,$00,$01,$00,$01
                    fcb       $00,$00,$00,$02,$00,$A3,$00,$00
                    fcb       $00,$B7,$00,$01,$00,$01,$00,$01
                    fcb       $00,$00,$00,$01,$00,$E9,$00,$00
                    fcb       $00,$85,$00,$00,$00,$02,$00,$00
                    fcb       $00,$00,$00,$02,$00,$D5,$00,$F8
                    fcb       $00,$00,$01,$00,$00,$02,$17,$A9
                    fcb       $00,$00,$00,$02,$00,$DA,$01,$0E
                    fcb       $00,$00,$01,$16,$00,$02,$17,$AD
                    fcb       $00,$00,$00,$02,$00,$DF,$01
                    fcb       $24
                    fcb       $00,$00,$01
                    fcb       $2C
                    fcb       $00,$02,$17,$B1,$00,$00,$00,$02
                    fcb       $00,$D5,$01,$00,$00,$00,$00,$FC
                    fcb       $00,$02,$17,$B5,$00,$00,$00,$02
                    fcb       $00,$DA,$01,$16,$00,$00,$01,$12
                    fcb       $00,$02,$17,$B9,$00,$00,$00,$02
                    fcb       $00,$DF,$01
                    fcb       $2C
                    fcb       $00,$00,$01
                    fcb       $28
                    fcb       $00,$02,$17,$BD,$00,$00,$00,$02
                    fcb       $00,$D5,$00,$F4,$00,$00,$01,$05
                    fcb       $00,$02,$17,$C1,$00,$00,$00,$02
                    fcb       $00,$DA,$01,$0A,$00,$00,$01,$1B
                    fcb       $00,$02,$17,$C6,$00,$00,$00,$02
                    fcb       $00,$DF,$01
                    fcb       $20
                    fcb       $00,$00,$01
                    fcb       $31
                    fcb       $00,$02,$17,$CB,$00,$00,$00,$02
                    fcb       $00,$D5,$01,$05,$00,$00,$00,$FC
                    fcb       $00,$02,$17,$D0,$00,$00,$00,$02
                    fcb       $00,$DA,$01,$1B,$00,$00,$01,$12
                    fcb       $00,$02,$17,$D5,$00,$00,$00,$02
                    fcb       $00,$DF,$01
                    fcb       $31
                    fcb       $00,$00,$01
                    fcb       $28
                    fcb       $00,$02,$17,$DA,$00,$00,$00,$02
                    fcb       $00,$E9,$00,$00,$00,$8F,$01
                    fcb       $43
                    fcb       $00,$8A,$00,$02,$00,$00,$00,$02
                    fcb       $00,$85,$00,$00,$00,$8F,$01
                    fcb       $43
                    fcb       $00,$8A,$00,$02,$00,$00,$00,$02
                    fcb       $00,$E4,$01
                    fcb       $36
                    fcb       $00,$BB,$01
                    fcb       $3E
                    fcb       $00,$02,$17,$DF,$00,$00,$00,$02
                    fcb       $00,$E4,$01
                    fcb       $36
                    fcb       $00,$CB,$00
                    fcb       $4B
                    fcb       $00,$BB,$01
                    fcb       $3A
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $51
                    fcb       $00,$E4,$01
                    fcb       $3E
                    fcb       $00,$01,$00
                    fcb       $5B
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $51
                    fcb       $00,$E4,$17,$E4,$00,$01,$00
                    fcb       $5F
                    fcb       $00,$00,$00,$02,$00,$CB,$00
                    fcb       $51
                    fcb       $00,$E4,$17,$E9,$00,$01,$00
                    fcb       $65
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00
CtypeTabImg         fcb       $00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
                    fcb       $01,$00,$00,$00,$00,$00,$00,$00
                    fcb       C$NULL,C$NULL,$02,C$NULL
                    fcc       /88((((((((/
                    fcb       $00,$00,$00,$00,$00,$00,$02
                    fcc       /""""""/
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02,$00,$00,$00,$00
                    fcb       $02,$00,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04,$00,$00,$00,$00
                    fcb       $00
Pow10Img            fdb       10000,1000,100,10 powers of ten
                    fcb       $04
                    fcb       $40,$6C,$78
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00
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
                    fdb       $0021

                    * ---- reloc1: text relocation offsets
                    fdb       $02C2,$02B2,$02A2,$0292,$0282,$0332,$0322,$0312
                    fdb       $0302,$02F2,$02E2,$02D2,$002D,$002B,$0029,$0027
                    fdb       $039E,$038E,$0362,$003B,$0039,$0037,$0035,$0033
                    fdb       $0031,$002F,$0049,$0047,$0045,$0043,$0041,$003F
                    fdb       $003D

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       $0082

                    * ---- reloc2: data relocation offsets
                    fdb       $0158,$014C,$0148,$0440,$018C,$0188,$017C,$0178
                    fdb       $016C,$0168,$015C,$01AA,$01A8,$01A2,$019E,$019C
                    fdb       $019A,$0198,$01BE,$01BC,$01BA,$01B8,$01B2,$01AE
                    fdb       $01AC,$01D8,$01D2,$01CE,$01CC,$01CA,$01C8,$01C2
                    fdb       $01EC,$01EA,$01E8,$01E2,$01DE,$01DC,$01DA,$020C
                    fdb       $0208,$01FE,$01FC,$01F8,$01F2,$01EE,$022E,$022C
                    fdb       $0228,$021E,$021C,$0218,$020E,$0258,$024E,$024C
                    fdb       $0248,$023E,$023C,$0238,$0288,$027E,$027A,$0278
                    fdb       $026C,$0268,$025C,$02AA,$02A8,$029E,$029A,$0298
                    fdb       $028E,$028A,$02CE,$02CA,$02C8,$02BE,$02BA,$02B8
                    fdb       $02AE,$02F8,$02EE,$02EA,$02E8,$02DE,$02DA,$02D8
                    fdb       $031A,$0318,$030E,$030A,$0308,$02FE,$02FA,$033E
                    fdb       $033C,$0338,$032E,$032A,$0328,$031E,$035A,$0358
                    fdb       $0350,$034E,$034C,$0348,$0340,$0370,$036E,$036C
                    fdb       $036A,$0368,$035E,$035C,$0388,$0382,$037E,$037C
                    fdb       $037A,$0378,$0372,$03A2,$039C,$039A,$0398,$0392
                    fdb       $038C,$038A

                    * ---- name: trailing module-name string
                    fcc       /c.opt/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end
