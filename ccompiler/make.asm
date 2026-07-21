                    nam       make
                    ttl       program module

* Annotated 2026-07-17 (Claude Code):
*   - renamed disassembled labels to meaningful names
*   - added an inline comment to every instruction
*   - re-disassembled the "**** STACK OVERFLOW ****" banner that had
*     been decoded as instructions
*   - separated the direct-page globals from the startup code they had
*     been mis-resolved onto (disassembler assumed DP=$00); they are now
*     a direct-page equate block with the references repointed
*   - verified byte-identical to the original assembly (module CRC $F9D781)

                    use       defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $12

                    mod       eom,name,tylg,atrv,_start,size

                    * ------------------------------------------------------------------
                    * Data area (named rmb fields).  rmb reserves RAM without emitting
                    * bytes; OS-9 allocates <size> at load, cstart inits from WorkBlockImage.
                    * Names for ,y-referenced fields are derived from the code comments.
                    * ------------------------------------------------------------------
                    rmb       $1
GlbVar0001          rmb       $1
AdvancePastPair     rmb       $1
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
GlbVar0027          rmb       $2
MsgTab              rmb       $1A
BlankPaddingString  rmb       $15
SpaceSeparator      rmb       $2
DontKnowFmt         rmb       $1E
WorkBuf             rmb       $15
Pow10               rmb       $8
LastDivisor         rmb       $2
FmtBuf              rmb       $3
DefaultInputHandle  rmb       $D
CommandEchoBuffer   rmb       $D
OutputBuffer        rmb       $B6
TableEndAddress     rmb       $1
CharacterTypeTable  rmb       $80
FreeListHead        rmb       $4
HeapTop             rmb       $2
LongResult3         rmb       $2
ResultLow           rmb       $6
SizePointer         rmb       $2
Limit               rmb       $2
StreamPointer       rmb       $2
DirectoryName       rmb       $2
TargetName          rmb       $2
SecondPrefixString  rmb       $2
ObjectFileName      rmb       $2
ExtraCFlags         rmb       $2
ExtraAssemblerFlags rmb       $2
Install             rmb       $2
Install2            rmb       $2
Install3            rmb       $2
QuietModeFlag       rmb       $2
DFlagCounter        rmb       $2
IFlagCounter        rmb       $2
NFlagCounter        rmb       $2
SFlagCounter        rmb       $2
NoExecuteMode       rmb       $2
ForceRebuildOption  rmb       $2
XFlagCounter        rmb       $2
ZFlagCounter        rmb       $2
ThirdSuffixOption   rmb       $2
SecondSuffixOption  rmb       $2
FirstSuffixOption   rmb       $2
AlreadyHaveCc       rmb       $2
ExplicitAssemblerFlag rmb       $2
AlreadyHaveLc       rmb       $2
AlreadyWarnedFlag   rmb       $2
PendingPushbackFlag rmb       $50
FileHandle          rmb       $2
LineBuffer          rmb       $50
InputBuffer         rmb       $400
OutputBuffer2       rmb       $1000
LineCounter         rmb       $2
OutputPointer       rmb       $2
ConversionBuffer    rmb       $A
StartScratchBuffer  rmb       $A
LeftJustifyFlag     rmb       $2
PadCharacter        rmb       $2
BaseBlock           rmb       $2
BaseBlockSize       rmb       $2
UpdateFreeCount     rmb       $2
UserHandlerAddress  rmb       $2
                    rmb       $380     remaining data, bss and heap
size                equ       .

name                equ       *
                    fcs       /make/
                    fcb       edition

* --- shared C runtime startup, reversing variant (see lib/cstart_rev.asm) ---
RTBASE              equ       $01AF     runtime-globals block base in the data area
DATAEND             equ       $16F7     end of static data / heap start / stack limit
HDRADV              equ       $0029     advance to where the non-DP data starts
                    use       lib/cstart_rev.asm

StorePtr17Cb        pshs      u,d       save the argument pointer
                    ldd       #$FFBE    load a negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldd       ,s        get the saved pointer
                    std       GlbVar0017 store the command pointer global
                    lbra      OptionsDone return through the epilogue

main                pshs      u         save the argument count copy
                    tfr       d,u       argument count into U
                    ldd       #$FFB2    load a negative frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -8,s       allocate the locals
                    clra                prepare a zero value
                    clrb                zero the macro counter
                    std       $02,s     clear the equals count
                    lbsr      InstallDefaults install the default rule strings
                    ldd       $0C,s     get the argv base pointer
                    std       GlbVar000D save the argv cursor global
                    leax      -$01,u    argc minus one
                    stx       GlbVar0013 store the remaining argument count
                    lbra      ArgLoopTop enter the argument loop

ArgParseLoop        ldx       $0C,s     get the argv cursor
                    leax      $02,x     advance to the next argument
                    stx       $0C,s     save the cursor
                    ldd       ,x        load the argument pointer
                    std       $04,s     save the argument pointer
                    tfr       d,x       pointer into X
                    ldb       ,x        first character of the argument
                    cmpb      #$2d      test for the dash option prefix
                    bne       CheckMacroArg not an option argument
                    ldd       $04,s     argument pointer
                    addd      #$0001    skip past the dash
                    std       $04,s     save the adjusted pointer
                    lbsr      ParseOptions parse the option string
                    ldd       GlbVar0013 remaining argument count
                    addd      #$FFFF    decrement it
                    std       GlbVar0013 store the count
                    clra                prepare a zero value
                    clrb                zero low byte
                    std       [$0C,s]   clear the consumed argv slot
                    bra       ArgLoopTop go to the next argument

CheckMacroArg       ldd       $04,s     argument pointer
                    std       $06,s     save the scan cursor
                    bra       ScanEqualsTest enter the equals scan

ScanEqualsLoop      ldx       $06,s     scan cursor
                    leax      $01,x     advance one character
                    stx       $06,s     save the cursor
                    ldb       -$01,x    look at the previous character
                    cmpb      #$3d      test for an equals sign
                    bne       ScanEqualsTest keep scanning if not equals
                    ldd       $06,s     pointer just past the equals
                    pshs      d         save it
                    ldd       $06,s     macro value pointer
                    lbsr      ParseMacroDef define the macro
                    leas      2,s        drop the argument
                    ldd       $02,s     equals-seen count
                    addd      #$0001    increment it
                    std       $02,s     store the count
                    ldd       GlbVar0013 remaining argument count
                    addd      #$FFFF    decrement it
                    std       GlbVar0013 store the count
                    clra                prepare a zero value
                    clrb                zero low byte
                    std       [$0C,s]   clear the consumed argv slot
                    bra       MacroDone done with this argument

ScanEqualsTest      ldb       [$06,s]   look at the next character
                    bne       ScanEqualsLoop keep scanning for equals
MacroDone           ldd       $02,s     equals-seen count
                    beq       CountTargetArg no macro was defined
                    clra                prepare a zero value
                    clrb                zero low byte
                    std       $02,s     reset the equals count
                    bra       ArgLoopTop go to the next argument

CountTargetArg      ldd       GlbVar0011 target count
                    addd      #$0001    increment it
                    std       GlbVar0011 record a target argument
ArgLoopTop          leau      -$01,u    decrement the argument index
                    stu       -$02,s    save the index
                    lbgt      ArgParseLoop process the next argument
                    lbsr      ParseMakefile read the makefile
                    ldd       DirectoryName,y   first default rule set
                    bne       SetDefaultRule2 already set
                    leax      DotStr1,pcr default rule string
                    stx       DirectoryName,y   install it
SetDefaultRule2     ldd       TargetName,y   second default rule set
                    lbne      NextTarget already set so build
                    leax      DotStr2,pcr default rule string
                    stx       TargetName,y   install it
                    bra       NextTarget go build the targets

ProcessTargetLoop   ldd       $04,s     target name pointer
                    lbsr      LookupMacro look up the target in the graph
                    std       ,s        save the target node
                    clra                prepare a zero value
                    clrb                zero low byte
                    lbsr      SetIntercept clear the visit flag
                    ldd       QuietModeFlag,y   quiet-mode flag
                    bne       BuildTarget skip the announcement
                    ldd       ,s        target node
                    lbsr      PrintDependencies announce the target
BuildTarget         ldd       ,s        target node
                    lbsr      ApplySuffixRules build the target
                    leax      StorePtr17Cb,pcr command handler address
                    tfr       x,d       into D
                    lbsr      SetIntercept register the handler
                    ldx       ,s        target node
                    ldd       $04,x     prerequisite list
                    beq       BuildLeaf no prerequisites present
                    tfr       x,d       target node into D
                    lbsr      CompareModTimes build with prerequisites
                    bra       CheckWarned continue past leaf build

BuildLeaf           tfr       x,d       target node into D
                    lbsr      RunCommands build the leaf target
CheckWarned         ldd       AlreadyWarnedFlag,y   already-warned flag
                    bne       NextTarget skip the warning
                    ldd       $04,s     target name
                    pshs      d         save it
                    leax      MsgUpToDate,pcr nothing-to-be-done message
                    tfr       x,d       into D
                    lbsr      FormatToInternal print the message
                    leas      2,s        drop the argument
                    clra                prepare a zero value
                    clrb                zero low byte
                    std       AlreadyWarnedFlag,y   mark the warning as shown
NextTarget          lbsr      NextTargetArg get the next target argument
                    std       $04,s     save it
                    bne       ProcessTargetLoop process the next target
                    leas      8,s        release the locals
                    puls      pc,u      return from the driver

InstallDefaults     pshs      u         save the caller register
                    ldd       #$FFC0    load a negative frame size
                    lbsr      stkcheck  check for stack overflow
                    leax      StrCc1,pcr default suffix list
                    stx       Install,y   install it
                    leax      StrCc2,pcr default rule pointer
                    stx       Install3,y   install it
                    leax      StrRma,pcr default rule pointer
                    stx       Install2,y   install it
                    puls      pc,u      return to caller

ParseOptions        pshs      u         save the option-string pointer
                    tfr       d,u       option string into U
                    ldd       #$FFBA    load a negative frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       allocate a local
                    clra                prepare a zero value
                    clrb                zero low byte
                    std       ,s        clear the local
                    lbra      OptionLoop enter the option loop

NextOptionChar      ldb       ,u+       get the next option character
                    sex                 sign-extend to a word
                    lbsr      ToLower   fold to lowercase
                    tfr       d,x       option character into X
                    lbra      OptionSwitch dispatch the option

OptFlagB            ldd       QuietModeFlag,y   b-flag counter
                    addd      #$0001    increment it
                    std       QuietModeFlag,y   set the brief flag
                    lbra      OptionLoop next option character

OptFlagD            ldd       DFlagCounter,y   d-flag counter
                    addd      #$0001    increment it
                    std       DFlagCounter,y   set the debug flag
                    lbra      OptionLoop next option character

OptFileName         ldb       ,u        next character after f
                    cmpb      #$3d      test for an equals sign
                    bne       NoEqualsFound no equals present
                    leau      $01,u     skip the equals
NoEqualsFound       tfr       u,d       remaining pointer
                    std       GlbVar0009 save the makefile name global
                    lbra      OptionsDone return from the options

OptFlagI            ldd       IFlagCounter,y   i-flag counter
                    addd      #$0001    increment it
                    std       IFlagCounter,y   set the ignore-errors flag
                    lbra      OptionLoop next option character

OptFlagN            ldd       NFlagCounter,y   n-flag counter
                    addd      #$0001    increment it
                    std       NFlagCounter,y   set the no-execute flag
                    lbra      OptionLoop next option character

OptFlagS            ldd       SFlagCounter,y   s-flag counter
                    addd      #$0001    increment it
                    std       SFlagCounter,y   set the silent flag
                    lbra      OptionLoop next option character

OptFlagT            ldd       NoExecuteMode,y   t-flag counter
                    addd      #$0001    increment it
                    std       NoExecuteMode,y   set the touch flag
                    lbra      OptionLoop next option character

OptFlagX            ldd       XFlagCounter,y   x-flag counter
                    addd      #$0001    increment it
                    std       XFlagCounter,y   set the exit-on-error flag
                    lbra      OptionLoop next option character

OptFlagU            ldd       ForceRebuildOption,y   u-flag counter
                    addd      #$0001    increment it
                    std       ForceRebuildOption,y   set the unconditional flag
                    lbra      OptionLoop next option character

OptFlagZ            ldd       ZFlagCounter,y   z-flag counter
                    addd      #$0001    increment it
                    std       ZFlagCounter,y   set the read-from-file flag
                    ldb       ,u        next character after z
                    cmpb      #$3d      test for an equals sign
                    lbne      OptionLoop no filename so next option
                    ldb       $01,u     character after the equals
                    lbeq      OptionLoop empty so next option
                    leax      $01,u     point past the equals
                    stx       GlbVar000F save the file-list name global
                    lbra      OptionsDone return from the options

                    bra       OptionLoop next option character

OptHelp             lbsr      FlushBuffers flush the output buffers
                    clra                clear the exit status high
                    clrb                clear the exit status low
                    lbsr      exit      terminate the program
OptUnknown          bsr       FlushBuffers flush the output buffers
                    ldd       #$00D7    bad-option error code
                    lbsr      exit      terminate with the error
                    bra       OptionLoop next option character

OptionSwitch        cmpx      #$0062    test for letter b
                    lbeq      OptFlagB  handle the b option
                    cmpx      #$0064    test for letter d
                    lbeq      OptFlagD  handle the d option
                    cmpx      #$0066    test for letter f
                    lbeq      OptFileName handle the f option
                    cmpx      #$0020    test for a space
                    beq       OptionsDone ignore and return
                    cmpx      #$000D    test for carriage return
                    beq       OptionsDone ignore and return
                    cmpx      #$0069    test for letter i
                    lbeq      OptFlagI  handle the i option
                    cmpx      #$006E    test for letter n
                    lbeq      OptFlagN  handle the n option
                    cmpx      #$0073    test for letter s
                    lbeq      OptFlagS  handle the s option
                    cmpx      #$0074    test for letter t
                    lbeq      OptFlagT  handle the t option
                    cmpx      #$0078    test for letter x
                    lbeq      OptFlagX  handle the x option
                    cmpx      #$0075    test for letter u
                    lbeq      OptFlagU  handle the u option
                    cmpx      #$007A    test for letter z
                    lbeq      OptFlagZ  handle the z option
                    cmpx      #$003F    test for a question mark
                    beq       OptHelp   show usage and exit
                    bra       OptUnknown unknown option error

OptionLoop          ldb       ,u        next option character
                    lbne      NextOptionChar process it
OptionsDone         leas      2,s        release the local
                    puls      pc,u      return to caller

FlushBuffers        pshs      u         save the caller register
                    ldd       #$FFBA    load a negative frame size
                    lbsr      stkcheck  check for stack overflow
                    leau      >MsgTab+$02,y point at the buffer table
                    bra       FlushLoopTest enter the flush loop

FlushLoop           leax      CommandEchoBuffer,y   output file descriptor
                    pshs      x         save it
                    ldd       ,u++      next buffer pointer
                    lbsr      PutString flush the buffer
                    leas      2,s        drop the argument
FlushLoopTest       cmpu      GlbVar0001 reached the table end
                    bcs       FlushLoop flush the next buffer
                    puls      pc,u      return to caller

NextTargetArg       pshs      u         save the caller register
                    ldd       #$FFB8    load a negative frame size
                    lbsr      stkcheck  check for stack overflow
                    ldb       PendingPushbackFlag,y   pending-pushback flag
                    beq       NextCmdTarget none pending
                    ldd       GlbVar0015 already-returned flag
                    lbne      ReturnNull done so return nothing
                    ldd       #$0001    prepare the returned marker
                    std       GlbVar0015 mark as already returned
                    leax      PendingPushbackFlag,y   pushed-back item
                    lbra      ReturnLinePtr return it

NextCmdTarget       ldd       GlbVar0013 remaining argument count
                    beq       OpenSourceFile none left so read the file
                    addd      #$FFFF    decrement the count
                    std       GlbVar0013 store the count
SkipEmptyArg        ldx       GlbVar000D argv cursor
                    leax      $02,x     advance to the next slot
                    stx       GlbVar000D save the cursor
                    ldd       ,x        load the argument pointer
                    beq       SkipEmptyArg skip empty slots
                    ldd       [GlbVar000D,y] load the target name
                    puls      pc,u      return from previous routine

OpenSourceFile      ldd       ZFlagCounter,y   load makefile-name flag
                    beq       ReturnNull none present, return null
                    ldd       FileHandle,y   load current file handle
                    bne       ReadFileLine already open, read a line
                    ldd       GlbVar000F explicit makefile name given
                    beq       UseDefaultInput no name, use default input
                    lbsr      OpenFile  open the named makefile
                    std       FileHandle,y   save the file handle
                    bra       ReadFileLine go read a line

UseDefaultInput     leax      DefaultInputHandle,y   point to default input handle
                    stx       FileHandle,y   use it as current stream
ReadFileLine        ldd       FileHandle,y   load the file stream
                    pshs      d         push stream argument
                    ldd       #$0050    buffer size eighty
                    pshs      d         push size argument
                    leax      LineBuffer,y   point to the line buffer
                    tfr       x,d       buffer as first argument
                    lbsr      ProcessEntry read a line with fgets
                    leas      4,s        drop the arguments
                    std       -$02,s    store and test result
                    beq       ReturnNull end of file, return null
                    ldb       LineBuffer,y   load first character
                    cmpb      #C$CR      is it a carriage return
                    beq       ReturnNull blank line, return null
                    leax      LineBuffer,y   point to the line buffer
                    tfr       x,d       buffer pointer as argument
                    lbsr      $33CF     measure the line length
                    addd      #$FFFF    index of last character
                    leax      LineBuffer,y   point to the line buffer
                    leax      d,x       point at trailing newline
                    clra                build null byte high
                    clrb                build null byte low
                    stb       ,x        strip the trailing newline
                    leax      LineBuffer,y   point to the line buffer
ReturnLinePtr       tfr       x,d       return the buffer pointer
                    puls      pc,u      return the line

ReturnNull          clra                return value zero high
                    clrb                return value zero low
                    puls      pc,u      return null

ParseMakefile       pshs      u         save frame pointer
                    ldd       #$FFA0    frame size for stack check
                    lbsr      stkcheck  check stack and set up frame
                    leas      -24,s      allocate twenty-four byte frame
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       GlbVar0019 clear the target list head
                    lbsr      OpenPrimaryFile open the primary makefile
                    std       GlbVar000B save the file handle
                    lbra      ReadLineLoop enter the read-line loop

ProcessLine         ldb       ,u        load first character of line
                    cmpb      #$20      is it a leading space
                    bne       ParseDefLine no, parse rule or macro
                    leau      $01,u     skip the leading space
                    tfr       u,d       line text as argument
                    lbsr      DupString duplicate the command string
                    std       $08,s     save the command copy
                    ldd       GlbVar0019 load target list head
                    std       $10,s     start target iteration
                    beq       NoTargetErr no current target, error
AppendCmdLoop       ldd       [$10,s]   load target node pointer
                    std       $16,s     save current target
                    ldx       [$16,s]   dereference the target
                    ldd       $04,x     load its command field
                    bne       NextCmdTarget2 already has command, skip
                    ldd       $08,s     load the command copy
                    std       $04,x     attach command to target
NextCmdTarget2      ldx       $10,s     load list link
                    ldd       $02,x     load next link
                    std       $10,s     advance to next target
                    bne       AppendCmdLoop loop over all targets
                    lbra      ReadLineLoop back to read-line loop

NoTargetErr         leax      MsgNoDepList,pcr point to error message
                    pshs      x         push message argument
                    ldd       #$0001    stderr stream number
                    lbsr      PrintError print the error message
                    leas      2,s        drop the argument
                    lbsr      exit      abort the program
                    lbra      ReadLineLoop back to read-line loop

ParseDefLine        ldd       GlbVar0019 load target list head
                    std       $10,s     start iteration
                    beq       ScanForDelim empty, skip freeing
FreeTargetsLoop     ldx       $10,s     load list node
                    ldd       $02,x     load next link
                    std       $0e,s     save next pointer
                    tfr       x,d       node as argument
                    lbsr      Free      free the list node
                    ldd       $0e,s     reload next pointer
                    std       $10,s     advance
                    bne       FreeTargetsLoop free the entire old list
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       GlbVar0019 clear the target list head
ScanForDelim        leax      >GlbVar0019,y  point to list head slot
                    stx       GlbVar001B save the list-append pointer
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       ,s        clear the macro-seen flag
                    ldu       $06,s     load the line pointer
                    tfr       u,d       line as scan cursor
                    std       $0C,s     save scan start
                    bra       NextNameChar begin the name scan

ScanNameLoop        ldb       ,u+       read next name character
                    sex                 sign-extend to word
                    tfr       d,x       character into X for compare
                    bra       CheckDelim check for a delimiter

DefineMacro         pshs      u         save cursor
                    ldd       $08,s     load the name pointer
                    lbsr      ParseMacroDef define the macro
                    leas      2,s        drop the argument
                    ldd       ,s        load macro-seen flag
                    addd      #$0001    increment it
                    std       ,s        mark a macro defined
                    bra       HandleColon finish this line

SyntaxErr           ldd       $0a,s     load offending token
                    pshs      d         push message argument
                    leax      MsgSyntaxError,pcr point to syntax error text
                    pshs      x         push format string
                    ldd       #$0001    stderr stream number
                    lbsr      PrintError print the error
                    leas      4,s        drop the arguments
                    lbsr      exit      abort the program
                    bra       NextNameChar continue scanning

CheckDelim          cmpx      #$003D    is character an equals
                    beq       DefineMacro yes, macro assignment
                    cmpx      #$003A    is character a colon
                    beq       HandleColon yes, rule definition
                    stx       -$02,s    test the character
                    beq       SyntaxErr unexpected end, error
                    bra       NextNameChar keep scanning

NextNameChar        ldb       ,u        peek next character
                    bne       ScanNameLoop not end, scan it
HandleColon         ldd       ,s        load macro-seen flag
                    beq       SkipWs    no macro, parse the rule
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       ,s        clear the flag
                    lbra      ReadLineLoop line done, read next

SkipWsLoop          leau      $01,u     skip whitespace character
SkipWs              ldb       ,u        peek next character
                    cmpb      #$20      is it a space
                    beq       SkipWsLoop yes, skip it
                    cmpb      #$09      is it a tab
                    lbeq      SkipWsLoop yes, skip it
                    std       -$02,s    test the character
                    beq       NoPrereqStr empty, no prerequisites
                    tfr       u,d       cursor as argument
                    lbsr      $33CF     measure remaining length
                    pshs      d         push the length
                    tfr       u,d       cursor as argument
                    lbsr      BuildWordList duplicate prerequisite text
                    leas      2,s        drop the length
                    bra       InitTargetScan continue

NoPrereqStr         clra                prepare zero high
                    clrb                prepare zero low
InitTargetScan      std       $14,s     save the prerequisite string
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       $02,s     clear the colon-seen flag
                    ldd       $0C,s     load scan cursor
                    std       $0a,s     mark token start
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       $04,s     clear the token length
                    lbra      TargetLoopCheck enter target scan loop

ScanTargetLoop      ldb       [$0C,s]   load current character
                    sex                 sign-extend to word
                    tfr       d,x       character into X
                    bra       ClassifyTargetChar classify the character

MarkColon           ldd       #$0001    set flag value
                    std       $02,s     mark colon seen
                    bra       EndTarget end the target token

AdvanceTarget       ldd       $04,s     load token length
                    addd      #$0001    increment
                    std       $04,s     extend the token
                    ldd       $0C,s     load the cursor
                    addd      #$0001    advance
                    std       $0C,s     next character
                    lbra      TargetLoopCheck loop for more characters

ClassifyTargetChar  cmpx      #$003A    is character a colon
                    beq       MarkColon yes, end of targets
                    cmpx      #$0020    is character a space
                    beq       EndTarget yes, end this target
                    cmpx      #$0009    is character a tab
                    beq       EndTarget yes, end this target
                    bra       AdvanceTarget part of name, continue

EndTarget           ldd       $04,s     load token length
                    lbeq      ReadLineLoop empty token, done
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       $04,s     reset token length
                    ldx       $0C,s     load cursor
                    leax      $01,x     advance past delimiter
                    stx       $0C,s     save cursor
                    stb       -$01,x    null-terminate the target name
                    ldd       $0a,s     load the target name pointer
                    lbsr      EnsureMacroValue find or create target node
                    std       $16,s     save the target node
LinkTargetLoop      ldx       $16,s     load target node
                    ldd       $04,x     load its prerequisite list
                    beq       FirstPrereq no prerequisites yet
                    ldd       $04,x     load prerequisite list head
                    bra       AdvancePrereq walk to list end

WalkPrereqEnd       ldx       $12,s     load prerequisite node
                    ldd       $02,x     load next link
AdvancePrereq       std       $12,s     advance pointer
                    ldx       $12,s     load prerequisite node
                    ldd       $02,x     load next link
                    bne       WalkPrereqEnd walk to end of list
                    ldd       $02,s     colon-seen flag
                    beq       ChkPrereqName no explicit prerequisite
                    ldx       $16,s     load target node
                    ldd       $06,x     load default prerequisite
                    beq       UsePrereqName none, use given name
ChkPrereqName       ldd       $14,s     load prerequisite string
                    bne       DupPrereq have string, duplicate it
UsePrereqName       ldd       $14,s     load prerequisite string
                    bra       StorePrereq store as prerequisite

DupPrereq           lbsr      CopyTree  create prerequisite node
StorePrereq         ldx       $12,s     load prerequisite slot
                    std       $02,x     link the prerequisite
                    bra       SetDefaultGoal record the dependency

FirstPrereq         ldd       $02,s     colon-seen flag
                    beq       ChkFirstName no explicit prerequisite
                    ldd       $06,x     load default prerequisite
                    beq       UseFirstName none, use given name
ChkFirstName        ldd       $14,s     load prerequisite string
                    bne       DupFirstPrereq have string, duplicate it
UseFirstName        ldd       $14,s     load prerequisite string
                    bra       StoreFirstPrereq store as prerequisite

DupFirstPrereq      lbsr      CopyTree  create prerequisite node
StoreFirstPrereq    ldx       $16,s     load target node
                    std       $04,x     set first prerequisite
SetDefaultGoal      ldd       GlbVar0011 already saw first rule
                    bne       AllocDepNode yes, skip default goal
                    ldd       ZFlagCounter,y   makefile flag set
                    bne       AllocDepNode yes, skip default goal
                    ldx       [$16,s]   dereference the target node
                    ldd       $02,x     load the target name
                    pshs      d         push the name
                    leax      PendingPushbackFlag,y   point to default-goal buffer
                    tfr       x,d       destination as argument
                    lbsr      StrCopy   copy name as default goal
                    leas      2,s        drop the argument
                    ldd       #$0001    flag value
                    std       GlbVar0011 mark default goal recorded
AllocDepNode        ldd       #$0004    node size four bytes
                    lbsr      Malloc    allocate a list node
                    std       $10,s     save the new node
                    std       [GlbVar001B,y] link into the append slot
                    beq       NextTargetNode allocation failed, skip
                    ldd       $10,s     load the new node
                    addd      #$0002    point to its link field
                    std       GlbVar001B update the append pointer
                    ldd       $16,s     load the target node
                    std       [$10,s]   store target in list node
                    clra                prepare zero high
                    clrb                prepare zero low
                    ldx       $10,s     load the list node
                    std       $02,x     null-terminate the link
NextTargetNode      ldx       $16,s     load target node
                    ldd       $06,x     load next linked target
                    std       $16,s     advance to next target
                    lbne      LinkTargetLoop process the next target
                    bra       SkipTrailWs skip trailing whitespace

SkipTrailWsLoop     ldd       $0C,s     load cursor
                    addd      #$0001    advance
                    std       $0C,s     next character
SkipTrailWs         ldb       [$0C,s]   peek next character
                    cmpb      #$20      is it a space
                    beq       SkipTrailWsLoop yes, skip it
                    cmpb      #$09      is it a tab
                    lbeq      SkipTrailWsLoop yes, skip it
                    ldd       $0C,s     load cursor
                    std       $0a,s     mark next token start
TargetLoopCheck     ldd       $02,s     colon-seen flag
                    lbeq      ScanTargetLoop more targets, scan them
ReadLineLoop        lbsr      ReadLine  read next makefile line
                    tfr       d,u       line pointer into U
                    tfr       u,d       copy back to D
                    std       $06,s     save the line pointer
                    lbne      ProcessLine got a line, process it
                    ldd       GlbVar000B load the file handle
                    lbsr      CloseStream close the makefile
                    leas      24,s       release the frame
                    puls      pc,u      return

OpenPrimaryFile     pshs      u         save frame pointer
                    ldd       #$FFBC    frame size for stack check
                    lbsr      stkcheck  check stack and set up frame
                    ldd       GlbVar0009 makefile name argument given
                    bne       CheckDashArg name given, examine it
                    leax      StrMakefile,pcr point to default name makefile
                    tfr       x,d       name as argument
                    bra       OpenAndStore open it

CheckDashArg        ldb       [GlbVar0009,y] load first char of name
                    cmpb      #$2d      is it a dash
                    bne       OpenArgFile no, open the named file
                    leax      DefaultInputHandle,y   point to standard input handle
                    stx       GlbVar000B use stdin as the source
                    bra       OpenPrimaryDone done

OpenArgFile         ldd       GlbVar0009 load the file name
OpenAndStore        bsr       OpenFile  open the file
                    std       GlbVar000B save the file handle
OpenPrimaryDone     puls      pc,u      return

OpenFile            pshs      u,d       save frame pointer and name
                    ldd       #$FFB4    frame size for stack check
                    lbsr      stkcheck  check stack and set up frame
                    leas      -2,s       reserve a local
                    leax      StrReadMode,pcr point to open mode read
                    pshs      x         push the mode argument
                    ldd       $04,s     load the file name
                    lbsr      ParseAndAdd open the file with fopen
                    leas      2,s        drop the argument
                    std       ,s        store and test the result
                    bne       OpenFileDone opened, return the handle
                    ldd       $02,s     load the file name
                    pshs      d         push name argument
                    ldd       >MsgTab,y load error format string
                    pshs      d         push it too
                    ldd       StreamPointer,y   load stderr stream
                    lbsr      PrintError report the open failure
                    leas      4,s        drop the arguments
                    lbsr      exit      abort the program
OpenFileDone        ldd       ,s        load the file handle
                    leas      4,s        release the frame
                    puls      pc,u      return the handle

AppendString        pshs      u         save frame pointer
                    tfr       d,u       first string into U
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  check stack and set up frame
                    leas      -2,s       reserve a local
                    tfr       u,d       first string as argument
                    lbsr      $33CF     measure its length
                    std       ,s        save first length
                    pshs      d         push the length
                    ldd       $08,s     load second string
                    lbsr      $33CF     measure its length
                    addd      ,s++      add the two lengths
                    cmpd      #$1000    exceeds four-kilobyte limit
                    ble       CopyCharLoop within limit, concatenate
                    leax      MsgBufferOverflow,pcr point to overflow message
                    pshs      x         push message argument
                    ldd       #$0001    stderr stream number
                    lbra      AbortPrint print error and abort

CopyCharLoop        ldd       ,s        load first length
                    addd      #$0001    include the terminator
                    std       ,s        save adjusted length
                    subd      #$0001    length again
                    leax      d,u       point past first string
                    pshs      x         save append position
                    ldx       $08,s     load second-string cursor
                    leax      $01,x     advance it
                    stx       $08,s     save cursor
                    ldb       -$01,x    load next character
                    stb       [,s++]    append it to the buffer
                    bne       CopyCharLoop copy until terminator
                    lbra      AbortExit return the concatenation

ReadLine            pshs      u         save frame pointer
                    ldd       #$FFB0    frame size for stack check
                    lbsr      stkcheck  check stack and set up frame
                    leas      -8,s       allocate an eight-byte frame
                    clra                prepare zero high
                    clrb                prepare zero low
                    std       $04,s     clear the continuation flag
                    std       ,s        clear the seen-word flag
                    leax      OutputBuffer2,y   point to the output buffer
                    stx       $06,s     save the output cursor
                    leau      InputBuffer,y   point to the input buffer
                    ldd       LineCounter,y   any pending line
                    lbne      ReturnNull2 yes, resume elsewhere
ExpandTokenLoop     clra                prepare zero high
                    clrb                prepare zero low
                    std       $02,s     clear the word pointer
                    ldb       ,u        load current character
                    cmpb      #$20      is it a space
                    beq       SkipBlankLoop yes, skip whitespace
                    cmpb      #$09      is it a tab
                    bne       HandleWord no, handle the word
SkipBlankLoop       leau      $01,u     skip whitespace character
                    ldb       ,u        peek next character
                    cmpb      #$20      is it a space
                    beq       SkipBlankLoop yes, keep skipping
                    cmpb      #$09      is it a tab
                    lbeq      SkipBlankLoop yes, keep skipping
                    tfr       u,d       cursor as argument
                    lbsr      IsCommentOrBlank look up macro at cursor
                    std       -$02,s    test the result
                    bne       MarkWordSet a macro, mark word seen
                    ldd       $04,s     continuation flag
                    beq       EmitSpace not continued, emit space
                    ldd       ,s        seen-word flag
                    beq       CheckSeenWord nothing yet, skip space
EmitSpace           ldd       #$0020    a space character
                    ldx       $06,s     load output cursor
                    leax      $01,x     advance it
                    stx       $06,s     save cursor
                    stb       -$01,x    emit the space
CheckSeenWord       ldd       ,s        seen-word flag
                    bne       TokenLoopCheck already have a word, continue
                    ldd       #$0001    flag value
                    std       $04,s     set the continuation flag
                    bra       TokenLoopCheck continue scanning

HandleWord          tfr       u,d       cursor as argument
                    lbsr      IsCommentOrBlank look up macro at cursor
                    std       -$02,s    test the result
                    bne       MarkWordSet a macro, mark word seen
                    ldb       ,u        load current character
                    cmpb      #$2d      is it a dash
                    bne       TokenLoopCheck no, continue scanning
                    ldd       ,s        seen-word flag
                    bne       TokenLoopCheck already saw a word, skip
                    pshs      u         save cursor
                    ldd       #$0001    skip one position
                    addd      ,s++      point past the dash
                    lbsr      ParseOptions handle a command-line option
MarkWordSet         ldd       #$0001    flag value
                    std       $02,s     mark word pointer set
TokenLoopCheck      ldd       $02,s     word pointer set
                    lbne      ExpandDone yes, process the word
                    lbra      NextChar  otherwise continue elsewhere

ScanCharLoop2       ldb       ,u        load current character
                    sex                 sign-extend to word
                    tfr       d,x       character into X
                    lbra      ClassifyChar jump to the character classifier

MacroDollar         ldb       $01,u     read char after the dollar
                    sex                 sign-extend to d
                    tfr       d,x       move to x for comparison
                    bra       IsSpecialMacro test for a special macro char

EmitSpecialMacro    ldd       $04,s     check the echo flag
                    beq       ExpandNamedMacro if zero expand a named macro
                    ldd       $06,s     load output position
                    addd      #$0001    advance one
                    std       $06,s     save position
                    leau      $01,u     skip the macro character
                    lbra      NextChar  continue scanning

IsSpecialMacro      cmpx      #$002A    is the char a star
                    beq       EmitSpecialMacro handle special macro
                    cmpx      #$0040    is the char an at sign
                    lbeq      EmitSpecialMacro handle special macro
                    cmpx      #$003F    is the char a question mark
                    lbeq      EmitSpecialMacro handle special macro
ExpandNamedMacro    tfr       u,d       macro name pointer to d
                    lbsr      $33CF     measure the macro name length
                    pshs      d         push the length
                    tfr       u,d       pointer again
                    lbsr      ExpandMacro look up the macro value
                    leas      2,s        drop length argument
                    tfr       d,u       use the expanded value
                    lbra      NextChar  continue scanning

HandleNewline       ldx       $06,s     load output position
                    ldb       -$01,x    read the previous character
                    cmpb      #$5C      is it a backslash
                    bne       NoContinuation no continuation
                    ldd       #$0001    flag continuation
                    bra       StoreContFlag store the flag

NoContinuation      clra                clear
                    clrb                clear the flag
StoreContFlag       std       ,s        store continuation flag
                    beq       KeepNewline not a continuation
                    tfr       x,d       position to d
                    addd      #$FFFF    back up over the backslash
                    std       $06,s     save position
                    lbra      ExpandDone finish this line

KeepNewline         ldd       $04,s     check the echo flag
                    beq       TerminateLine if zero terminate
                    tfr       x,d       position to d
                    addd      #$0001    advance
                    std       $06,s     save position
                    bra       TerminateLine terminate the line

HandleComment       ldb       $01,u     read char after the hash
                    sex                 sign-extend
                    leax      CharacterTypeTable,y   character class table base
                    leax      d,x       index by character
                    ldb       ,x        load the class byte
                    clra                clear high byte
                    andb      #$08      test class bit three
                    bne       CopyChar  if set treat as literal
StripTrailWsLoop    ldx       $06,s     load output position
                    leax      -$01,x    back up one
                    stx       $06,s     save position
                    ldb       ,x        read previous char
                    cmpb      #$20      is it a space
                    beq       StripTrailWsLoop keep stripping
                    ldb       [$06,s]   read the char again
                    cmpb      #$09      is it a tab
                    lbeq      StripTrailWsLoop keep stripping
                    ldd       $06,s     load position
                    addd      #$0001    advance
                    std       $06,s     save position
                    ldd       $04,s     check the echo flag
                    beq       TerminateLine if zero terminate
                    ldd       #$000D    carriage return
                    ldx       $06,s     output position
                    leax      $01,x     advance
                    stx       $06,s     save position
                    stb       -$01,x    store carriage return
TerminateLine       clra                clear
                    clrb                null terminator
                    stb       [$06,s]   terminate the output string
                    bra       ExpandDone finish the line

CopyChar            leau      $01,u     skip the character
                    ldd       $06,s     load position
                    addd      #$0001    advance
                    std       $06,s     save position
                    bra       NextChar  continue scanning

ClassifyChar        cmpx      #$0024    is the char a dollar
                    lbeq      MacroDollar handle a macro
                    cmpx      #$000D    is the char a carriage return
                    lbeq      HandleNewline handle the newline
                    cmpx      #$0023    is the char a hash
                    lbeq      HandleComment handle the comment
                    bra       CopyChar  otherwise copy the char

NextChar            ldb       ,u        read the source char
                    stb       [$06,s]   store into the output
                    lbne      ScanCharLoop2 loop until end of line
ExpandDone          ldd       GlbVar000B load buffer base global
                    pshs      d         push it
                    ldd       #$0400    buffer size 1024
                    pshs      d         push the size
                    leax      InputBuffer,y   expansion buffer
                    tfr       x,d       to d
                    lbsr      ProcessEntry copy the expanded line
                    leas      4,s        drop arguments
                    tfr       d,u       result pointer
                    stu       -$02,s    save it
                    bne       CheckLeadingWs if non-null continue
                    ldd       LineCounter,y   load line counter
                    addd      #$0001    increment
                    std       LineCounter,y   save the counter
                    bra       EvalResult evaluate the result

CheckLeadingWs      ldd       $04,s     check the echo flag
                    beq       EvalResult if zero evaluate
                    ldb       ,u        read the first char
                    cmpb      #$20      is it a space
                    beq       SetWsFlag mark leading whitespace
                    cmpb      #$09      is it a tab
                    bne       CheckContFlag not whitespace
SetWsFlag           ldd       #$0001    whitespace flag
                    std       $02,s     store the flag
                    bra       EvalResult evaluate the result

CheckContFlag       ldd       ,s        check continuation flag
                    bne       EvalResult if set evaluate
                    clra                clear
                    clrb                clear
                    std       $04,s     clear the echo flag
                    bra       ReturnBuffer return the buffer

EvalResult          ldd       ,s        check continuation flag
                    bne       CheckLineCount if set check line count
                    ldd       $02,s     check whitespace flag
                    beq       CheckContError if none maybe error
CheckLineCount      ldd       LineCounter,y   load line counter
                    lbeq      ExpandTokenLoop if zero return to caller
CheckContError      ldd       ,s        check continuation flag
                    beq       CheckWsResult if none skip
                    leax      MsgUnfinishedCont,pcr unfinished continuation line message
                    pshs      x         push the message
                    ldd       #$0001    stream id
                    lbsr      PrintError print the error
                    leas      2,s        drop argument
                    lbsr      exit      flush output
CheckWsResult       ldd       $02,s     check whitespace flag
                    bne       ReturnNull2 if set return null
ReturnBuffer        leax      OutputBuffer2,y   result buffer
                    tfr       x,d       to d
                    bra       ExpandExit return it

ReturnNull2         clra                clear
                    clrb                null result
ExpandExit          leas      8,s        release locals
                    puls      pc,u      return

IsCommentOrBlank    pshs      u         save u
                    tfr       d,u       u points to the string
                    ldd       #$FFC0    frame size
                    lbsr      stkcheck  stack overflow check
                    ldb       ,u        read the first char
                    sex                 sign-extend
                    tfr       d,x       to x for comparison
                    bra       TestFirstChar test the first char

RetTrue             ldd       #$0001    return true
                    puls      pc,u      return

TestFirstChar       cmpx      #$0023    is it a hash
                    beq       RetTrue   yes return true
                    cmpx      #$002A    is it a star
                    lbeq      RetTrue   yes return true
                    cmpx      #$000D    is it a carriage return
                    lbeq      RetTrue   yes return true
                    stx       -$02,s    store char and test for null
                    lbeq      RetTrue   if null return true
                    clra                clear
                    clrb                return false
                    puls      pc,u      return

AbortMake           pshs      u,d       save u and format argument
                    ldd       #$FFB8    frame size
                    lbsr      stkcheck  stack overflow check
                    leax      MsgMakeTerminated,pcr make terminated message
                    pshs      x         push the message
                    ldd       $02,s     load the format argument
AbortPrint          lbsr      PrintError print the message
                    leas      2,s        drop argument
                    lbsr      exit      flush output
AbortExit           leas      2,s        drop saved d
                    puls      pc,u      return

                    fcc       /can't open "%s". /
                    fcb       C$NULL
DotStr1             fcb       $2E
                    fcb       C$NULL
DotStr2             fcb       $2E
                    fcb       C$NULL
MsgUpToDate         fcc       /%s up to date/
                    fcb       C$CR,C$NULL
StrCc1              fcb       $63,$63
                    fcb       C$NULL
StrCc2              fcb       $63,$63
                    fcb       C$NULL
StrRma              fcb       $72,$6D,$61
                    fcb       C$NULL
                    fcc       /Syntax: make {[<-opts>] [< target file >] [< macros >]}/
                    fcb       C$CR,C$NULL
                    fcc       /Function: keep track of modules for a file/
                    fcb       C$CR,C$NULL
                    fcc       /Options:/
                    fcb       C$CR,C$NULL
                    fcc       /    -b        don't use built-in rules/
                    fcb       C$CR,C$NULL
                    fcc       /    -d        debug mode, print out the file dates in makefile/
                    fcb       C$CR,C$NULL
                    fcc       /    -f=<xxx>  use <xxx> as the makefile  (default: makefile)/
                    fcb       C$CR,C$NULL
                    fcc       /    -i        ignore errors on commands and keep going/
                    fcb       C$CR,C$NULL
                    fcc       /    -n        don't execute commands, just print them out/
                    fcb       C$CR,C$NULL
                    fcc       /    -s        silent mode, execute commands without echoing them/
                    fcb       C$CR,C$NULL
                    fcc       /    -t        update the dates without executing the commands/
                    fcb       C$CR,C$NULL
                    fcc       /    -u        do the make whether it needs it or not/
                    fcb       C$CR,C$NULL
                    fcc       /    -z[=<path>] get list of files to make from stdin or path/
                    fcb       C$CR,C$NULL
MsgNoDepList        fcc       /no dependency list for command line/
                    fcb       C$CR,C$NULL
MsgSyntaxError      fcc       /syntax error/
                    fcb       C$CR
                    fcc       /"%s"/
                    fcb       C$NULL
StrMakefile         fcc       /makefile/
                    fcb       C$NULL
StrReadMode         fcb       $72
                    fcb       C$NULL
MsgBufferOverflow   fcc       /buffer overflow -- line too long/
                    fcb       C$CR,C$NULL
MsgUnfinishedCont   fcc       /unfinished continuation line/
                    fcb       C$CR,C$NULL
MsgMakeTerminated   fcc       /make terminated/
                    fcb       C$CR,C$NULL
BuildWordList       pshs      u         save u
                    tfr       d,u       u points to the string
                    ldd       #$FFAE    frame size
                    lbsr      stkcheck  stack overflow check
                    leas      -12,s      allocate locals
                    leax      $02,s     list tail pointer
                    stx       ,s        save it
                    lbra      SplitLoop enter the split loop

ResetWord           clra                clear
                    clrb                clear
                    std       $08,s     reset skip count
                    std       $0a,s     reset word count
                    bra       SkipSpaceLoop skip whitespace

SkipSpace           leau      $01,u     advance past a space
                    ldd       $10,s     remaining length
                    addd      #$FFFF    decrement
                    std       $10,s     save it
SkipSpaceLoop       ldb       ,u        read char
                    cmpb      #$20      is it a space
                    beq       SkipSpace skip it
                    cmpb      #$09      is it a tab
                    lbeq      SkipSpace skip it
                    stu       $06,s     save word start
                    ldb       ,u        read char
                    lbeq      SplitDone if null we are done
                    bra       WordDone  process the word

ScanWord            ldb       ,u        read char
                    sex                 sign-extend
                    tfr       d,x       to x
                    bra       TestWordChar test the word char

EndWord             clra                clear
                    clrb                clear
                    stb       ,u+       null-terminate the word
WordEnded           ldd       $0a,s     word count
                    addd      #$0001    increment
                    std       $0a,s     save it
                    bra       WordDone  process the word

NextWordChar        leau      $01,u     advance
                    ldd       $08,s     char count
                    addd      #$0001    increment
                    std       $08,s     save it
                    bra       WordDone  continue scanning

TestWordChar        cmpx      #$0020    is it a space
                    beq       EndWord   end the word
                    cmpx      #$0009    is it a tab
                    lbeq      EndWord   end the word
                    stx       -$02,s    store char and test for null
                    beq       WordEnded if null the word ended
                    bra       NextWordChar continue the word

WordDone            ldd       $0a,s     word count
                    beq       ScanWord  none yet keep scanning
                    ldd       $10,s     remaining length
                    pshs      d         push it
                    ldd       $0a,s     word count
                    addd      #$0001    plus one
                    nega                negate
                    negb                negate
                    sbca      #$00      complete the negation
                    addd      ,s++      subtract from length
                    std       $10,s     save remaining
                    ldd       $06,s     word start pointer
                    lbsr      FindOrAddMacro duplicate the word
                    bsr       AllocWordNode allocate a list node
                    std       $04,s     save the node
                    std       [,s]      link into the list
                    ldd       $04,s     node again
                    addd      #$0002    point to next field
                    std       ,s        advance the tail pointer
SplitLoop           ldd       $10,s     remaining length
                    lbgt      ResetWord loop while more
SplitDone           ldd       $02,s     return the list head
                    leas      12,s       release locals
                    puls      pc,u      return

AllocWordNode       pshs      u         save u
                    tfr       d,u       u points to the node
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  stack overflow check
                    pshs      u         push node pointer
                    ldd       #$0008    node size eight
                    lbsr      AllocOrDie allocate the node
                    bsr       LinkNode  initialize and link the node
                    lbra      FrameRet2 restore u and return

LinkNode            pshs      u         save u
                    tfr       d,u       u points to the list slot
                    ldd       #$FFC0    frame size
                    lbsr      stkcheck  stack overflow check
                    clra                clear
                    clrb                clear
                    std       $04,u     clear a field
                    std       $02,u     clear a field
                    ldd       $04,s     new node pointer
                    std       ,u        store the data pointer
                    ldd       [$04,s]   current list head
                    std       $06,u     chain onto the node
                    stu       [$04,s]   make node the new head
                    tfr       u,d       return the node
                    puls      pc,u      return

DupString           pshs      u         save u
                    tfr       d,u       u points to the source string
                    ldd       #$FFB8    frame size
                    lbsr      stkcheck  stack overflow check
                    leas      -2,s       local slot
                    tfr       u,d       string to d
                    lbsr      $33CF     measure the length
                    addd      #$0001    room for the null
                    lbsr      AllocOrDie allocate the buffer
                    std       ,s        save the buffer
                    pshs      u         push the source
                    ldd       $02,s     load the buffer
                    lbsr      StrCopy   copy the string
                    leas      2,s        drop the source
                    ldd       ,s        buffer pointer
                    lbra      FrameRet2 restore u and return

PrintDependencies   pshs      u         save u
                    tfr       d,u       u holds the argument
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  stack overflow check
                    clra                clear
                    clrb                clear
                    std       GlbVar0021 clear the error flag
                    leax      >GlbVar001D,y  target list base
                    stx       GlbVar001F save the list pointer
                    leax      MsgCheckReloc,pcr format string
                    tfr       x,d       to d
                    lbsr      DebugTrace print the header
                    clra                clear
                    clrb                clear
                    pshs      d         push depth zero
                    tfr       u,d       argument to d
                    bsr       WalkTarget walk the target tree
                    leas      2,s        drop argument
                    leax      MsgCheckSource,pcr format string
                    tfr       x,d       to d
                    lbsr      DebugTrace print separator
                    clra                clear
                    clrb                clear
                    pshs      d         push zero
                    tfr       u,d       argument to d
                    lbsr      CheckImplicitSource process the target
                    leas      2,s        drop argument
                    ldd       GlbVar0021 error flag
                    beq       PrintDepsDone if none finish
                    ldd       #$0001    flag value
                    lbsr      ScanSourceDir report the error
PrintDepsDone       puls      pc,u      return

WalkTarget          pshs      u         save u
                    tfr       d,u       u points to the target
                    ldd       #$FFB0    frame size
                    lbsr      stkcheck  stack overflow check
                    leas      -8,s       allocate locals
                    clra                clear
                    clrb                clear
                    std       $02,s     clear counter
                    ldd       $0C,s     depth argument
                    aslb                shift left
                    rola                rotate in
                    aslb                shift left
                    rola                multiply depth by four
                    std       ,s        store indent offset
TargetLoop          ldx       ,u        target record pointer
                    ldd       $02,x     load the name pointer
                    std       $06,s     save it
                    pshs      d         push it
                    ldd       #$0014    column width twenty
                    subd      $02,s     minus the depth offset
                    leax      >BlankPaddingString,y  blank padding string
                    leax      d,x       index into padding
                    pshs      x         push padding pointer
                    leax      MsgFilePair,pcr format string
                    tfr       x,d       to d
                    lbsr      DebugTrace print the indented name
                    leas      4,s        drop arguments
                    ldd       $06,s     name pointer
                    lbsr      FindExtension get the file date
                    std       -$02,s    save the date
                    lbeq      RecurseRelocChild if none skip prerequisites
                    ldd       $06,s     name pointer
                    pshs      d         push it
                    ldd       $0e,s     depth argument
                    pshs      d         push the depth
                    leax      MsgFoundObject,pcr format string
                    tfr       x,d       to d
                    lbsr      DebugTrace print the date line
                    leas      4,s        drop arguments
                    ldd       $04,u     prerequisite list
                    beq       BuildImplicitR if none continue
                    ldd       $0C,s     depth argument
                    pshs      d         push the depth
                    leax      SuffixIsRel,pcr format string
                    pshs      x         push it
                    ldd       $04,u     prerequisite list
                    lbsr      FindDependent recurse over prerequisites
                    leas      4,s        drop arguments
                    std       $02,s     save the result
BuildImplicitR      ldd       $02,s     load the local found flag
                    bne       ClearFoundFlag skip building when an explicit file was found
                    leax      MsgNoExplicitR,pcr point at "no explicit .r file"
                    tfr       x,d       pass the message in d
                    lbsr      DebugTrace emit the debug trace
                    ldd       $06,s     load the target name
                    lbsr      $33CF     measure its length
                    addd      #$0003    room for ".r" and terminator
                    lbsr      Malloc    allocate the filename buffer
                    std       $04,s     save the new buffer
                    ble       NextRelocTarget skip if allocation failed
                    leax      SfxDotR,pcr point at the ".r" suffix
                    pshs      x         push the suffix argument
                    ldd       $08,s     load the base name
                    pshs      d         push it
                    ldd       $08,s     load the destination buffer
                    lbsr      StrCopy   copy the base name in
                    leas      2,s        drop the argument
                    lbsr      StrCat    append the ".r" suffix
                    leas      2,s        drop the argument
                    ldd       $04,s     load the built filename
                    pshs      d         push it as argument
                    tfr       u,d       pass the current node
                    lbsr      AppendRelocDep append the implicit reloc dependency
                    leas      2,s        drop the argument
                    ldd       $04,s     reload the filename buffer
                    lbsr      Free      free the temporary buffer
                    bra       NextRelocTarget continue to the next target

ClearFoundFlag      clra                zero
                    clrb                the result value
                    std       $02,s     clear the found flag
                    bra       NextRelocTarget continue

RecurseRelocChild   ldd       $04,u     load the child pointer
                    beq       NextRelocTarget no child to recurse
                    ldd       $0C,s     load the recursion level
                    addd      #$0001    increment the level
                    pshs      d         push the level argument
                    ldd       $04,u     load the child node
                    lbsr      WalkTarget recurse into the reloc check
                    leas      2,s        drop the argument
NextRelocTarget     ldd       $0C,s     load the level flag
                    beq       ScanRelocDone done at the top level
                    ldu       $02,u     advance to the next sibling
                    lbne      TargetLoop loop over the sibling list
ScanRelocDone       leas      8,s        release the locals
                    puls      pc,u      return

CheckImplicitSource pshs      u         save the caller frame
                    tfr       d,u       u points at the node
                    ldd       #$FFB4    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -4,s       reserve locals
                    clra                zero
                    clrb                the found flag
                    std       $02,s     clear the found flag
                    ldd       $08,s     load the level argument
                    aslb                multiply level by two
                    rola                propagate the carry
                    aslb                multiply by four total
                    rola                propagate the carry
                    std       ,s        save the indent width
SourceScanLoop      ldx       ,u        load the target record
                    ldd       $02,x     load its name pointer
                    pshs      d         push the name
                    ldd       #$0014    base column width
                    subd      $02,s     subtract the indent
                    leax      >BlankPaddingString,y  point at the blank padding
                    leax      d,x       index into the padding
                    pshs      x         push the prefix string
                    leax      MsgFilePair2,pcr point at "%sfile: %s"
                    tfr       x,d       pass the format
                    lbsr      DebugTrace emit the debug trace
                    leas      4,s        drop the arguments
                    ldx       ,u        reload the record
                    ldd       $02,x     load its name
                    lbsr      SuffixIsRel look up the source file
                    std       -$02,s    save the lookup result
                    beq       RecurseSourceChild not found, try the children
                    ldd       $04,u     load the child pointer
                    beq       NoSourceFound no child list present
                    ldd       $08,s     load the level
                    pshs      d         push it
                    leax      SuffixIsSrc,pcr point at the match predicate
                    pshs      x         push the callback
                    ldd       $04,u     load the child list
                    bsr       FindDependent search dependents for a match
                    leas      4,s        drop the arguments
                    std       $02,s     save the found flag
NoSourceFound       ldd       $02,s     load the found flag
                    bne       ClearSourceFlag matched, skip the notice
                    leax      MsgNoSource,pcr point at "no explicit source file listed"
                    tfr       x,d       pass the message
                    lbsr      DebugTrace emit the debug trace
                    tfr       u,d       pass the node
                    lbsr      AddUnresolvedSource record the unresolved source
                    bra       NextSourceTarget continue

ClearSourceFlag     clra                zero
                    clrb                the found flag
                    std       $02,s     clear the found flag
                    bra       NextSourceTarget continue

RecurseSourceChild  ldd       $04,u     load the child pointer
                    beq       NextSourceTarget no child to recurse
                    ldd       $08,s     load the level
                    addd      #$0001    increment it
                    pshs      d         push the level argument
                    ldd       $04,u     load the child node
                    lbsr      CheckImplicitSource recurse into the children
                    leas      2,s        drop the argument
NextSourceTarget    ldd       $08,s     load the level
                    lbeq      FrameRet4 done at the top level
                    ldu       $02,u     advance to the next sibling
                    lbne      SourceScanLoop loop over the siblings
                    lbra      FrameRet4 return

FindDependent       pshs      u,d       save the frame and node
                    ldd       #$FFB6    frame size
                    lbsr      stkcheck  establish the stack frame
DependentListLoop   ldu       ,s        load the current list head
DependentNodeLoop   ldx       ,u        load the record
                    ldd       $02,x     load its name
                    jsr       [$06,s]   call the match predicate
                    std       -$02,s    save the result
                    beq       NextDependent no match, keep scanning
                    ldx       ,u        reload the record
                    ldd       $02,x     load its name
                    pshs      d         push the name argument
                    ldd       $0a,s     load the level
                    pshs      d         push it
                    leax      MsgFoundDep,pcr point at "found dependent (level %d): %s"
                    tfr       x,d       pass the format
                    lbsr      DebugTrace emit the debug trace
                    leas      4,s        drop the arguments
                    ldd       #$0001    return found
                    lbra      FrameRet2 return

NextDependent       ldu       $02,u     advance to the next sibling
                    bne       DependentNodeLoop scan the sibling list
                    ldx       ,s        reload the list node
                    ldd       $04,x     load the child list
                    std       ,s        make it current
                    bne       DependentListLoop descend into the children
                    clra                zero
                    clrb                return not found
                    lbra      FrameRet2 return

AddUnresolvedSource pshs      u,d       save the frame and node
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  establish the stack frame
                    ldd       #$0004    node size four bytes
                    lbsr      AllocOrDie allocate the node
                    tfr       d,u       u points at the node
                    stu       [GlbVar001F,y] link it onto the list tail
                    ldd       ,s        load the source pointer
                    std       ,u        store it in the node
                    leax      $02,u     point past the link field
                    stx       GlbVar001F update the tail pointer
                    ldd       GlbVar0021 load the unresolved count
                    addd      #$0001    increment it
                    std       GlbVar0021 save the count
                    lbra      FrameRet2 return

ScanSourceDir       pshs      u         save the caller frame
                    ldd       #$FF94    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -34,s      reserve locals
                    leax      StrDFlag,pcr point at the "d" flag string
                    pshs      x         push the argument
                    ldd       DirectoryName,y   load the directory name
                    lbsr      ParseAndAdd find the flag character
                    leas      2,s        drop the argument
                    std       ,s        save the result
                    bne       OpenSourceDir found, skip the warning
                    ldd       DirectoryName,y   load the name
                    pshs      d         push it
                    ldd       >MsgTab,y load the second argument
                    pshs      d         push it
                    ldd       StreamPointer,y   load the stream pointer
                    lbsr      PrintError print the diagnostic
                    leas      4,s        drop the arguments
                    lbsr      exit      flush the error output
OpenSourceDir       clra                zero
                    clrb                the open flag high byte
                    pshs      d         push it
                    ldd       #$0040    read access mode
                    pshs      d         push it
                    clra                zero
                    clrb                the flag low word
                    pshs      d         push it
                    ldd       $06,s     load the file name
                    lbsr      $2DC1     open the directory file
                    leas      6,s        drop the arguments
                    cmpd      #$FFFF    check for open failure
                    bne       ReadDirLoop opened, start reading
                    ldd       DirectoryName,y   load the name
                    pshs      d         push it
                    leax      MsgCantRead,pcr point at "can't read %s"
                    pshs      x         push the format
                    ldd       StreamPointer,y   load the stream pointer
                    lbsr      PrintError print the diagnostic
                    leas      4,s        drop the arguments
                    lbsr      exit      flush the error output
                    bra       ReadDirLoop continue

MatchDirEntry       ldb       $02,s     load the entry length
                    beq       ReadDirLoop empty, read the next line
                    leax      $02,s     point at the entry text
                    tfr       x,d       pass it
                    bsr       ResolveSourceFile try to match a source file
                    std       -$02,s    save the result
                    beq       CheckUnresolved all resolved, stop
ReadDirLoop         ldd       ,s        load the file handle
                    pshs      d         push it
                    ldd       #$0020    read buffer size
                    pshs      d         push it
                    ldd       #$0001    one record
                    pshs      d         push it
                    leax      $08,s     point at the read buffer
                    tfr       x,d       pass it
                    lbsr      ReadBlock read the next directory line
                    leas      6,s        drop the arguments
                    std       -$02,s    save the byte count
                    bne       MatchDirEntry process the entry
CheckUnresolved     ldd       GlbVar0021 load the unresolved count
                    beq       CloseSourceDir all resolved, done
                    ldu       [GlbVar001D,y] load the unresolved list head
                    ldx       ,u        load the record
                    ldd       $02,x     load its name
                    pshs      d         push it
                    leax      MsgNoSourceFile,pcr point at "can't find source file to make %s"
                    pshs      x         push the format
                    ldd       #$0001    stderr stream
                    lbsr      PrintError print the diagnostic
                    leas      4,s        drop the arguments
                    lbsr      exit      flush the error output
CloseSourceDir      ldd       ,s        load the file handle
                    lbsr      CloseStream close the directory
                    leas      34,s       release the locals
                    puls      pc,u      return

ResolveSourceFile   pshs      u         save the caller frame
                    tfr       d,u       u points at the name
                    ldd       #$FF90    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -40,s      reserve locals
                    clra                zero
                    clrb                the previous pointer
                    std       $20,s     clear the previous pointer
                    ldd       GlbVar001D load the list head
                    std       $22,s     save the walk pointer
                    pshs      u         push the name argument
                    leax      $02,s     point at the name slot
                    tfr       x,d       pass it
                    lbsr      CopyOS9Name normalise the file name
                    leas      2,s        drop the argument
ResolveListLoop     ldd       [$22,s]   load the current record
                    std       $24,s     save it
                    ldx       [$24,s]   load the record pointer
                    ldd       $02,x     load its name
                    std       $26,s     save the name pointer
                    lbsr      $33CF     measure the name length
                    std       $1e,s     save the length
                    bra       SlashScanCond enter the scan loop

SlashScanLoop       ldd       $1e,s     load the scan index
                    addd      #$FFFF    decrement it
                    std       $1e,s     save the index
                    addd      $26,s     point into the name
                    tfr       d,x       address the character
                    ldb       ,x        load the character
                    cmpb      #$2f      is it a path separator
                    bne       SlashScanCond not a slash, keep scanning
                    ldd       $26,s     load the name base
                    pshs      d         save it
                    ldd       $20,s     load the offset
                    addd      #$0001    add one
                    addd      ,s++      add the saved base
                    std       $26,s     take the basename after the slash
                    bra       CompareEntryName basename located

SlashScanCond       ldd       $1e,s     load the scan index
                    bne       SlashScanLoop keep scanning the name
CompareEntryName    leax      ,s        point at the local result slot
                    pshs      x         push it
                    ldd       $28,s     load the search name
                    lbsr      StemMatchSrc compare against the entry
                    std       ,s++      save and pop the result
                    beq       AdvancePrev no match, advance
                    ldd       $20,s     load the previous pointer
                    beq       UnlinkAtHead matched at the list head
                    ldx       $22,s     load the current node
                    ldd       $02,x     load its next pointer
                    ldx       $20,s     load the previous node
                    std       $02,x     unlink the current node
                    bra       RecordMatch process the match

UnlinkAtHead        ldx       $22,s     load the current node
                    ldd       $02,x     load its next pointer
                    std       GlbVar001D update the list head
RecordMatch         ldx       [$24,s]   load the matched record
                    ldd       $02,x     load its name
                    pshs      d         push it
                    leax      $02,s     point at the source name
                    pshs      x         push it
                    leax      MsgFoundToMake,pcr point at "found %s to make %s"
                    tfr       x,d       pass the format
                    lbsr      DebugTrace emit the debug trace
                    leas      4,s        drop the arguments
                    leax      ,s        point at the source name
                    pshs      x         push it
                    ldd       $26,s     load the matched record
                    bsr       AttachSourceDep attach the resolved source
                    leas      2,s        drop the argument
                    ldd       GlbVar0021 load the unresolved count
                    addd      #$FFFF    decrement it
                    std       GlbVar0021 save the count
                    bra       NextResolveNode advance to the next node

AdvancePrev         ldd       $22,s     load the current node
                    std       $20,s     remember it as previous
NextResolveNode     ldx       $22,s     load the current node
                    ldd       $02,x     load its next pointer
                    std       $22,s     advance the walk pointer
                    lbne      ResolveListLoop loop over the list
                    ldd       GlbVar0021 return the remaining count
                    leas      40,s       release the locals
                    puls      pc,u      return

AppendRelocDep      pshs      u         save the caller frame
                    tfr       d,u       u points at the target
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -2,s       reserve a local
                    ldd       $06,s     load the file name
                    lbsr      EnsureMacroValue build a reloc record
                    lbsr      CopyTree  deep-copy the dependency tree
                    bra       RelocTailNext walk to the list tail

RelocTailLoop       ldx       ,s        load the current node
                    ldd       $02,x     load its next pointer
RelocTailNext       std       ,s        save the walk pointer
                    ldx       ,s        reload it
                    ldd       $02,x     load its next pointer
                    bne       RelocTailLoop walk to the end of the list
                    ldd       $04,u     load the child list
                    bra       LinkChildList link the new node

AttachSourceDep     pshs      u         save the caller frame
                    tfr       d,u       u points at the target
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -2,s       reserve a local
                    ldd       $06,s     load the source name
                    lbsr      FindOrAddMacro build a source record
                    lbsr      AllocWordNode create the dependency node
                    std       ,s        save it
                    ldd       $04,u     load the child list
                    ldx       ,s        load the new node
LinkChildList       std       $02,x     chain the old list after it
                    tfr       x,d       get the new node
                    std       $04,u     make it the child list head
                    lbra      FrameRet2 return

DupNode             pshs      u,d       save the frame and node
                    ldd       #$FFB8    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -2,s       reserve a local
                    ldd       #$0008    node size eight bytes
                    lbsr      AllocOrDie allocate the node
                    std       ,s        save the new node
                    ldd       [$02,s]   load the source name pointer
                    std       [,s]      copy it into the node
                    ldx       $02,s     load the source node
                    ldd       $06,x     load its data field
                    ldx       ,s        load the new node
                    std       $06,x     copy the data field
                    tfr       x,d       get the new node
                    ldx       $02,s     load the source node
                    std       $06,x     back-link the source to the copy
                    clra                zero
                    clrb                the child fields
                    ldx       ,s        load the new node
                    std       $04,x     clear the child pointer
                    std       $02,x     clear the next pointer
                    tfr       x,d       return the new node
FrameRet4           leas      4,s        release the frame
                    puls      pc,u      return

CopyTree            pshs      u,d       save the frame and node
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  establish the stack frame
                    ldd       ,s        load the node to copy
                    bsr       DupNode   duplicate the node
                    tfr       d,u       u points at the copy
                    ldx       ,s        load the source node
                    ldd       $04,x     load its child list
                    beq       CopySiblings no children
                    ldd       $04,x     load the child list
                    bsr       CopyTree  copy the child subtree
                    std       $04,u     attach it to the copy
CopySiblings        ldx       ,s        load the source node
                    ldd       $02,x     load its next pointer
                    beq       CopyTreeRet no siblings
                    ldd       $02,x     load the sibling list
                    lbsr      CopyTree  copy the sibling subtree
                    std       $02,u     attach it to the copy
CopyTreeRet         tfr       u,d       return the copied tree
FrameRet2           leas      2,s        release the frame
                    puls      pc,u      return

MsgCheckReloc       fcc       /checking for implicit relocatable files/
                    fcb       C$CR,C$NULL
MsgCheckSource      fcc       /checking for implicit source files/
                    fcb       C$CR,C$NULL
MsgFilePair         fcc       /%sfile: %s/
                    fcb       C$CR,C$NULL
MsgFoundObject      fcc       /found object file(level %d): %s/
                    fcb       C$CR,C$NULL
MsgNoExplicitR      fcc       /no explicit ".r" file/
                    fcb       C$CR,C$NULL
SfxDotR             fcb       $2E,$72
                    fcb       C$NULL
MsgFilePair2        fcc       /%sfile: %s/
                    fcb       C$CR,C$NULL
MsgNoSource         fcc       /no explicit source file listed/
                    fcb       C$CR,C$NULL
MsgFoundDep         fcc       /found dependent (level %d): %s/
                    fcb       C$CR,C$NULL
StrDFlag            fcb       $64
                    fcb       C$NULL
MsgCantRead         fcc       /can't read "%s".  /
                    fcb       C$NULL
MsgNoSourceFile     fcc       /can't find source file to make "%s"/
                    fcb       C$NULL
MsgFoundToMake      fcc       /found "%s" to make "%s"/
                    fcb       C$CR,C$NULL
CompareModTimes     pshs      u         save the caller frame
                    tfr       d,u       u points at the node
                    ldd       #$FFAE    frame size
                    lbsr      stkcheck  establish the stack frame
                    leas      -12,s      reserve locals
                    ldd       $04,u     load the second node
                    std       $0a,s     save it
                    ldd       [$0a,s]   load its record pointer
                    addd      #$0006    offset to the date field
                    std       $08,s     save the date pointer
                    ldd       ,u        load the first node
                    addd      #$0006    offset to the date field
                    std       $06,s     save the date pointer
                    clra                zero
                    clrb                the result value
                    std       $02,s     clear the result
                    leax      $02,s     compute address of local scan buffer
                    stx       ,s        store scan pointer
                    lbra      DepLoopTest jump to dependency loop test

DepLoop             ldd       GlbVar0017 load verbose-trace flag
                    beq       DepCheckDate skip trace if disabled
                    lbsr      AbortMake print dependency trace
DepCheckDate        ldd       $0a,s     load current dependency node
                    lbsr      ApplySuffixRules apply implicit suffix rules
                    ldb       [$06,s]   load dependency flag byte
                    cmpb      #$FF      check already-processed sentinel
                    beq       AllocDepNode2 skip if already marked
                    ldd       [$0a,s]   load node data pointer
                    addd      #$0006    point to name field
                    pshs      d         push name pointer argument
                    ldd       $08,s     load target name
                    lbsr      CompareDates compare modification dates
                    std       ,s++      save result and pop argument
                    bne       AllocDepNode2 branch if dependency newer
                    ldd       ForceRebuildOption,y   load force-rebuild option
                    beq       RecurseDep skip alloc if not forcing
AllocDepNode2       ldd       #$0004    request four bytes
                    lbsr      AllocOrDie allocate a new dependency node
                    std       $04,s     save new node pointer
                    std       [,s]      link node into the list
                    ldd       $04,s     reload node pointer
                    addd      #$0002    point past link field
                    std       ,s        store list tail pointer
                    ldx       [$0a,s]   load current node data
                    ldd       $02,x     load its next pointer
                    std       [$04,s]   copy into new node
                    clra                clear high byte
                    clrb                clear low byte
                    ldx       $04,s     reload new node
                    std       $02,x     clear its next pointer
RecurseDep          ldx       $0a,s     load current node
                    ldd       $04,x     load command/subdep field
                    beq       TrackNewest skip recursion if none
                    ldd       GlbVar0023 load recursion depth counter
                    addd      #$0001    increment depth
                    std       GlbVar0023 store depth back
                    ldd       $0a,s     load current node
                    lbsr      CompareModTimes recursively make this dependency
TrackNewest         ldd       [$0a,s]   load node data pointer
                    addd      #$0006    point to name field
                    cmpd      $08,s     compare against saved name
                    beq       NextDep   skip if same node
                    pshs      d         push name pointer
                    ldd       $0a,s     load current node
                    lbsr      CompareDates compare modification dates
                    std       ,s++      save result and pop
                    beq       NextDep   skip if not newer
                    ldd       [$0a,s]   reload node data pointer
                    addd      #$0006    point to name field
                    std       $08,s     remember newest prerequisite
NextDep             ldx       $0a,s     load current node
                    ldd       $02,x     load next pointer
                    std       $0a,s     advance to next dependency
DepLoopTest         ldd       $0a,s     load current node
                    lbne      DepLoop   loop while list non-empty
                    ldx       ,u        load target structure
                    ldb       $06,x     load target flag byte
                    cmpb      #$FF      check processed sentinel
                    beq       DoBuild   skip date test if marked
                    ldd       $08,s     load newest prerequisite
                    pshs      d         push as argument
                    tfr       x,d       target pointer to accumulator
                    addd      #$0006    point to name field
                    lbsr      CompareDates compare modification dates
                    std       ,s++      save result and pop
                    bne       MarkOutOfDate branch if target newer
                    ldd       ForceRebuildOption,y   load force-rebuild option
                    beq       MakeExit  skip build if up to date
MarkOutOfDate       ldd       #$00FF    set processed sentinel
                    ldx       ,u        load target structure
                    stb       $06,x     mark target as out of date
DoBuild             ldd       $02,s     load command list
                    pshs      d         push as argument
                    tfr       u,d       target pointer to accumulator
                    lbsr      RunCommands run the build commands
                    leas      2,s        drop argument
MakeExit            ldd       GlbVar0023 load recursion depth
                    addd      #$FFFF    decrement depth
                    std       GlbVar0023 store depth back
                    leas      12,s       release local frame
                    puls      pc,u      return

ApplySuffixRules    pshs      u         save caller frame
                    tfr       d,u       target argument to base pointer
                    ldd       #$FF4C    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    leas      -108,s     allocate local frame
                    ldx       ,u        load target structure
                    ldd       $02,x     load name pointer
                    std       $6a,s     save name pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       $04,s     clear slash count
                    std       $02,s     clear match count
                    ldd       $6a,s     reload name pointer
                    std       ,s        set scan pointer
                    bra       ScanLoopTest enter forward scan loop

SlashScanLoop2      ldx       ,s        load scan pointer
                    leax      $01,x     advance one character
                    stx       ,s        store scan pointer
                    ldb       -$01,x    load previous character
                    cmpb      #$2f      is it a slash
                    bne       ScanLoopTest continue if not slash
                    ldd       $04,s     load slash count
                    addd      #$0001    increment count
                    std       $04,s     store slash count
                    bra       CheckRule1 exit scan after slash

ScanLoopTest        ldb       [,s]      load current character
                    bne       SlashScanLoop2 loop until null terminator
CheckRule1          clra                clear high byte
                    clrb                clear low byte
                    stb       $06,s     clear match flag
                    ldd       $6a,s     load name pointer
                    lbsr      SuffixIsRel look up first suffix rule
                    std       -$02,s    save rule pointer
                    beq       CheckRule2 try next rule if none
                    ldd       $02,s     load match count
                    addd      #$0001    increment count
                    std       $02,s     store match count
                    ldd       $04,s     load slash count
                    lbne      BuildCandidate skip if path has a slash
                    ldd       FirstSuffixOption,y   load first suffix option
                    lbeq      BuildCandidate skip if disabled
                    ldd       TargetName,y   load prefix directory string
                    pshs      d         push as argument
                    leax      $08,s     address of candidate buffer
                    tfr       x,d       buffer pointer to accumulator
                    lbsr      StrCopy   copy prefix into buffer
                    leas      2,s        drop argument
                    leax      SlashConstA,pcr load first suffix literal
AppendSuffix        pshs      x         push suffix string
                    leax      $08,s     address of candidate buffer
                    tfr       x,d       buffer pointer to accumulator
                    lbsr      StrCat    append suffix to buffer
                    leas      2,s        drop argument
                    lbra      BuildCandidate continue to build candidate

CheckRule2          ldd       $6a,s     load name pointer
                    lbsr      FindExtension find filename extension
                    std       -$02,s    save extension pointer
                    beq       CheckRule3 try next rule if none
                    ldd       $02,s     load match count
                    addd      #$0001    increment count
                    std       $02,s     store match count
                    ldd       $04,s     skip if path has a slash
                    bne       BuildCandidate skip if path has a slash
                    ldd       SecondSuffixOption,y   load second suffix option
                    beq       BuildCandidate skip if disabled
                    ldd       SecondPrefixString,y   load second prefix string
                    pshs      d         push as argument
                    leax      $08,s     address of candidate buffer
                    tfr       x,d       buffer pointer to accumulator
                    lbsr      StrCopy   copy prefix into buffer
                    leas      2,s        drop argument
                    leax      SlashConstB,pcr load second suffix literal
                    bra       AppendSuffix append and continue

CheckRule3          ldd       $6a,s     load name pointer
                    lbsr      SuffixIsSrc look up third suffix rule
                    std       -$02,s    save rule pointer
                    beq       BumpMatch none found
                    ldd       $04,s     load slash count
                    bne       BuildCandidate skip if path has a slash
                    ldd       ThirdSuffixOption,y   load third suffix option
                    beq       BuildCandidate skip if disabled
                    ldd       DirectoryName,y   load third prefix string
                    pshs      d         push as argument
                    leax      $08,s     address of candidate buffer
                    tfr       x,d       buffer pointer to accumulator
                    lbsr      StrCopy   copy prefix into buffer
                    leas      2,s        drop argument
                    leax      SlashConstC,pcr load third suffix literal
                    lbra      AppendSuffix append and continue

BumpMatch           ldd       $02,s     load match count
                    addd      #$0001    increment count
                    std       $02,s     store match count
BuildCandidate      ldd       $6a,s     load name pointer
                    pshs      d         push as argument
                    leax      $08,s     address of candidate buffer
                    tfr       x,d       buffer pointer to accumulator
                    lbsr      StrCat    append name to buffer
                    leas      2,s        drop argument
                    ldx       ,u        load target structure
                    ldb       $06,x     load target flag
                    bne       RecordName skip stat if already marked
                    ldd       $02,s     load match count
                    pshs      d         push as argument
                    leax      $08,s     address of candidate buffer
                    pshs      x         push buffer pointer
                    tfr       u,d       target pointer to accumulator
                    bsr       StatCandidate stat this candidate file
                    leas      4,s        drop arguments
RecordName          ldd       DFlagCounter,y   load list/touch option
                    beq       SuffixRuleDone skip if disabled
                    ldd       ,u        load target data pointer
                    addd      #$0006    point to name field
                    pshs      d         push name pointer
                    leax      $08,s     address of candidate buffer
                    tfr       x,d       buffer pointer to accumulator
                    lbsr      PrintFileDate record the generated name
                    leas      2,s        drop argument
SuffixRuleDone      leas      108,s      release local frame
                    puls      pc,u      return

StatCandidate       pshs      u,d       save frame and argument
                    ldd       #$FFA2    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    ldu       $08,s     load target pointer
                    leas      -20,s      allocate local frame
                    ldd       [$14,s]   load candidate name pointer
                    addd      #$0006    point to name field
                    std       ,s        save name pointer
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero access mode
                    ldd       $1C,s     load candidate path pointer
                    lbsr      OpenFile2 open file read-only
                    leas      2,s        drop argument
                    std       $12,s     save path number
                    bge       ReadFileDate branch if opened
                    ldd       #$0080    directory access mode flag
                    pshs      d         push mode argument
                    ldd       $1C,s     load candidate path pointer
                    lbsr      OpenFile2 retry opening the file
                    leas      2,s        drop argument
                    std       $12,s     save path number
                    bge       ReadFileDate branch if opened
                    stu       -$02,s    save target pointer
                    bne       MarkFound branch if target exists
                    ldx       $14,s     load candidate node
                    ldd       $04,x     load command field
                    beq       ReportNoRule report missing if no rule
MarkFound           ldd       #$00FF    set found sentinel value
                    stb       [,s]      mark target found flag
                    bra       ReadFileDate continue

ReportNoRule        ldd       $1a,s     load candidate name
                    pshs      d         push as argument
                    ldd       >MsgTab,y load program name pointer
                    pshs      d         push as argument
                    ldd       StreamPointer,y   load no-rule error format
                    lbsr      PrintError format the error message
                    leas      4,s        drop arguments
                    lbsr      exit      abort with error
ReadFileDate        ldb       [,s]      load found flag
                    bne       StatDone  skip read if not found
                    ldd       #$0010    request sixteen bytes
                    pshs      d         push length argument
                    leax      $04,s     address of status buffer
                    pshs      x         push buffer pointer
                    ldd       $16,s     load path number
                    lbsr      GetFileDesc get file status descriptor
                    leas      4,s        drop arguments
                    cmpd      #$FFFF    check for error return
                    bne       SaveDate  continue if successful
                    ldd       $1a,s     load candidate name
                    pshs      d         push as argument
                    leax      MsgGetstatErr,pcr load stat-error format string
                    pshs      x         push format string
                    ldd       StreamPointer,y   load error format string
                    lbsr      PrintError format the error message
                    leas      4,s        drop arguments
                    lbsr      exit      abort with error
SaveDate            leax      $05,s     address of timestamp bytes
                    pshs      x         push source pointer
                    ldd       $02,s     load destination pointer
                    lbsr      CopyFiveBytes copy the modification date
                    leas      2,s        drop argument
                    ldd       $12,s     load path number
                    lbsr      CloseByPathB close the file
StatDone            leas      22,s       release local frame
                    puls      pc,u      return

FindExtension       pshs      u         save frame
                    tfr       d,u       string pointer to base pointer
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    leas      -2,s       allocate local frame
                    pshs      u         push string pointer
                    tfr       u,d       string pointer to accumulator
                    lbsr      $33CF     measure string length
                    addd      ,s++      add length to base pointer
                    std       ,s        save end-of-string pointer
                    bra       BackScanNext enter backward scan

BackScanLoop        ldb       [,s]      load current character
                    cmpb      #$2f      is it a slash
                    lbeq      DatesNewer stop at path separator
                    ldb       [,s]      reload current character
                    cmpb      #$2e      is it a dot
                    lbeq      DatesOlder found extension start
BackScanNext        ldd       ,s        load scan pointer
                    addd      #$FFFF    step back one character
                    std       ,s        store scan pointer
                    pshs      d         push pointer
                    cmpu      ,s++      compare against string start
                    bls       BackScanLoop loop while within string
                    lbra      DatesNewer none found, return end pointer

CompareDates        pshs      u         save frame
                    tfr       d,u       first date pointer to base
                    ldd       #$FFBC    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    leas      -2,s       allocate local frame
                    ldb       ,u        load first timestamp byte
                    cmpb      #$FF      check missing-file sentinel
                    beq       DatesOlder treat missing file as older
                    ldb       [$06,s]   load second timestamp byte
                    cmpb      #$FF      check missing-file sentinel
                    beq       DatesNewer treat missing file as newer
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear byte index
                    bra       CompareDateTest enter comparison loop

CompareDateLoop     ldb       ,u        load first timestamp byte
                    sex                 sign-extend to word
                    pshs      d         push first byte
                    ldb       [$08,s]   load second timestamp byte
                    sex                 sign-extend to word
                    cmpd      ,s++      compare the two bytes
                    beq       NextDateByte equal, check next byte
                    ldb       ,u        reload first byte
                    sex                 sign-extend
                    pshs      d         push first byte
                    ldb       [$08,s]   load second byte
                    sex                 sign-extend
                    cmpd      ,s++      compare again
                    bgt       DatesNewer first newer, return one
DatesOlder          clra                clear high byte
                    clrb                clear low byte
                    bra       CompareDatesRet return zero for older or equal

NextDateByte        ldd       ,s        load byte index
                    addd      #$0001    increment index
                    std       ,s        store index
                    leau      $01,u     advance first date pointer
                    ldd       $06,s     load second date pointer
                    addd      #$0001    advance second pointer
                    std       $06,s     store second pointer
CompareDateTest     ldd       ,s        load byte index
                    cmpd      #$0005    five bytes in a date stamp
                    blt       CompareDateLoop loop over timestamp bytes
DatesNewer          ldd       #$0001    return one meaning newer
CompareDatesRet     leas      2,s        release local frame
                    puls      pc,u      return

RunCommands         pshs      u,d       save frame and target
                    ldd       #$FFA8    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    leas      -12,s      allocate local frame
                    ldu       #$0000    clear command pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       $06,s     clear macro index
                    ldd       GlbVar0003 load output buffer pointer
                    std       ,s        save buffer pointer
                    ldx       [$0C,s]   load target structure
                    ldd       $04,x     load command list
                    beq       EchoDefault echo default if none
                    ldd       $04,x     reload command list
                    pshs      d         push as argument
                    leax      MsgCommand,pcr load command format string
                    tfr       x,d       format pointer to accumulator
                    lbsr      DebugTrace format the command line
                    leas      2,s        drop argument
                    bra       BeginExpand continue

EchoDefault         leax      MsgNoCommand,pcr load default format string
                    tfr       x,d       format pointer to accumulator
                    lbsr      DebugTrace format the default line
BeginExpand         ldd       #$0001    set build-started flag
                    std       AlreadyWarnedFlag,y   mark that a rebuild happened
                    ldx       [$0C,s]   load target structure
                    ldd       $04,x     load command list
                    std       $04,s     save command pointer
                    bne       CmdCharLoop use commands if present
                    ldd       $0C,s     load target pointer
                    lbsr      BuildTarget2 get default command list
                    std       $04,s     save command pointer
CmdCharLoop         ldb       [$04,s]   load current command character
                    cmpb      #C$CR      is it carriage return
                    lbeq      RunCommandRet end of command line
                    ldd       ,s        load output pointer
                    cmpd      $04,s     check if at command start
                    lbeq      MacRunToken branch if line empty
                    ldd       NoExecuteMode,y   load echo/silent option
                    lbne      MacRunToken skip echo if silent
                    lbra      MacStoreChar go expand the command

EmitPlainChar       ldx       $04,s     load command pointer
                    leax      $01,x     advance one character
                    stx       $04,s     store command pointer
                    ldb       -$01,x    load consumed character
                    sex                 sign-extend to word
                    tfr       d,x       character to index register
                    lbra      MacCharDispatch dispatch the character

ExpandTargetName    ldx       [$0C,s]   load target structure
                    ldd       $02,x     load target name pointer
                    std       $02,s     save name pointer
                    lbsr      $33CF     measure name length
                    std       $0a,s     save length
                    ldx       $04,s     load command pointer
                    leax      $01,x     advance one character
                    stx       $04,s     store command pointer
                    ldb       -$01,x    load consumed character
                    sex                 sign-extend
                    tfr       d,x       character to index register
                    lbra      DollarSubDispatch dispatch macro character

ResetMacroScan      clra                clear high byte
                    clrb                clear low byte
                    std       $06,s     clear macro index
                    ldd       $0a,s     load name length
                    bra       StemLoopDec enter copy loop

LoadNameChar        ldx       $02,s     load name pointer
                    ldd       $08,s     load current offset
                    leax      d,x       index into the name
                    ldb       ,x        load name character
                    sex                 sign-extend
                    tfr       d,x       character to index register
                    bra       StemCheckSep dispatch macro character

MarkMacroStart      ldd       $06,s     load macro index
                    bne       StemContinue skip if not first character
                    ldd       $08,s     load current offset
                    std       $0a,s     save macro start offset
                    ldd       $06,s     load macro index
                    addd      #$0001    increment index
                    std       $06,s     store macro index
                    bra       StemContinue continue

AdvanceMacroOffset  ldd       $02,s     load base pointer
                    pshs      d         push base pointer
                    ldd       $0a,s     load running offset
                    addd      #$0001    increment offset
                    std       $0a,s     store offset
                    addd      ,s++      add base to offset
                    std       $02,s     store computed pointer
                    ldd       $0a,s     load offset
                    subd      $08,s     subtract start offset
                    std       $0a,s     store adjusted length
                    bra       ExpandTarget continue

StemCheckSep        cmpx      #$002E    is the stem char a dot
                    beq       MarkMacroStart extension separator found
                    cmpx      #$002F    is the stem char a slash
                    beq       AdvanceMacroOffset path separator found
                    bra       StemContinue keep scanning backward

StemContinue        ldd       $08,s     reload the scan index
StemLoopDec         addd      #$FFFF    step the index back one
                    std       $08,s     save the updated index
                    ldd       $08,s     reload the index
                    bgt       LoadNameChar more characters to scan
ExpandTarget        ldd       $0a,s     target name pointer for '$@'
                    pshs      d         push it as an argument
                    ldd       $04,s     current output offset
                    pshs      d         push the destination
                    pshs      u         push the length so far
                    ldd       GlbVar0003 base of the output buffer
                    addd      ,s++      add the current offset
                    lbsr      StrNCpy   copy the target name into output
                    leas      4,s        drop the arguments
                    ldd       $0a,s     reload the copied length
                    bra       MacAppend go append and continue

ExpandOODList       ldd       $12,s     out-of-date list pointer
                    lbeq      MacStoreChar nothing to expand
                    pshs      d         push the list argument
                    pshs      u         push the output length
                    ldd       GlbVar0003 base of the output buffer
                    addd      ,s++      add the current offset
                    lbsr      JoinNameList expand the prerequisite list
                    leas      2,s        drop the argument
MacAppend           leau      d,u       advance output length by copied bytes
                    lbra      MacStoreChar go store terminator and continue

MacUnknownErr       ldd       $04,s     current position in the command
                    addd      #$FFFE    back up to the macro name
                    pshs      d         push the macro text
                    leax      MsgUnknownMacro,pcr unknown-macro format string
                    pshs      x         push the format
                    ldd       #$0001    one argument
                    lbsr      PrintError print to standard error
                    leas      4,s        drop the arguments
                    lbsr      exit      abort the build
                    bra       MacStoreChar unreachable continue

DollarSubDispatch   cmpx      #$002A    is it '$*' the stem
                    lbeq      ResetMacroScan expand the stem
                    cmpx      #$0040    is it '$@' the target
                    beq       ExpandTarget expand the target name
                    cmpx      #$003F    is it '$?' the out-of-date list
                    beq       ExpandOODList expand the prerequisite list
                    bra       MacUnknownErr otherwise unknown macro

MacCarriageReturn   pshs      u         push the current length
                    ldd       #$0001    reserve one byte
                    addd      ,s++      add to the length
                    addd      GlbVar0003 offset into the output buffer
                    tfr       d,x       form the output pointer
                    clra                clear high byte
                    clrb                clear low byte
                    stb       ,x        terminate the output string
                    ldd       $0C,s     command buffer pointer
                    pshs      d         push it
                    ldd       $02,s     load the command string
                    bsr       RunCommand run the assembled command
                    leas      2,s        drop the argument
                    ldd       NoExecuteMode,y   no-execute mode flag
                    lbne      RunCommandRet return without more lines
                    ldu       #$0000    reset the output length
                    bra       MacStoreChar continue scanning

MacPlainChar        leau      $01,u     count one output byte
                    bra       MacStoreChar store the character

MacCharDispatch     cmpx      #$0024    is the char a dollar sign
                    lbeq      ExpandTargetName begin macro expansion
                    cmpx      #$000D    is the char a carriage return
                    beq       MacCarriageReturn end of the command line
                    bra       MacPlainChar ordinary character

MacStoreChar        ldx       GlbVar0003 output buffer base
                    tfr       u,d       current output length
                    leax      d,x       form the write pointer
                    ldb       [$04,s]   fetch the current source byte
                    stb       ,x        store it into the output
                    lbne      EmitPlainChar loop while not end of string
                    bra       MacRetOne reached end, finish

MacRunToken         ldd       $0C,s     command buffer pointer
                    pshs      d         push it
                    ldd       $06,s     command string pointer
                    bsr       RunCommand run the command
                    leas      2,s        drop the argument
MacRetOne           ldd       #$0001    return success
                    lbra      RunCommandRet return from the function

RunCommand          pshs      u         save the frame pointer
                    tfr       d,u       command string pointer into u
                    ldd       #$FFA4    reserve the stack frame
                    lbsr      stkcheck  allocate locals and check stack
                    leas      -14,s      reserve more locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       $0C,s     clear the silent-prefix count
                    std       $0a,s     clear the ignore-error count
                    ldb       ,u        read the first command character
                    sex                 sign-extend to a word
                    tfr       d,x       into x for dispatch
                    bra       CmdScanPrefix scan the command prefixes

CmdCountSilent      ldd       $0C,s     silent-prefix count
                    addd      #$0001    increment it
                    std       $0C,s     save it
                    bra       CmdNextChar advance to the next char

CmdCountIgnore      ldd       $0a,s     ignore-error count
                    addd      #$0001    increment it
                    std       $0a,s     save it
CmdNextChar         leau      $01,u     advance the command pointer
                    bra       CmdAfterPrefix recheck the prefix

CmdScanPrefix       cmpx      #$0040    is the prefix '@' silent
                    beq       CmdCountSilent count the silent flag
                    cmpx      #$002D    is the prefix '-' ignore-error
                    beq       CmdCountIgnore count the ignore-error flag
CmdAfterPrefix      ldd       NFlagCounter,y   echo-suppress flag
                    beq       CmdCheckDryRun not suppressed, continue
                    leax      CommandEchoBuffer,y   command echo buffer
                    pshs      x         push it
                    tfr       u,d       command string
                    lbsr      PutString echo the command
                    leas      2,s        drop the argument
                    lbra      RunCommandRet done

CmdCheckDryRun      ldd       NoExecuteMode,y   no-execute mode flag
                    beq       CmdForkShell not dry-run, execute it
                    ldx       [$12,s]   the target record
                    ldd       $02,x     its name string
                    lbsr      ResolveFileDate record the target as built
                    lbra      RunCommandRet done

CmdForkShell        leax      StrShell,pcr the shell program name
                    stx       ,s        store as the first argument
                    stu       $02,s     command string as argument
                    clra                clear high byte
                    clrb                clear low byte
                    std       $04,s     clear the terminator
                    ldd       SFlagCounter,y   global silent flag
                    bne       CmdWaitChild skip echo when silent
                    ldd       $0C,s     per-command silent count
                    bne       CmdWaitChild skip echo when '@' present
                    leax      CommandEchoBuffer,y   command echo buffer
                    pshs      x         push it
                    tfr       u,d       command string
                    lbsr      PutString echo the command
                    leas      2,s        drop the argument
CmdWaitChild        clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push a null argument
                    ldd       #$0001    parameter value one
                    pshs      d         push it
                    pshs      d         push it again
                    pshs      u         push the command string
                    tfr       u,d       command as argument
                    lbsr      $33CF     get its length
                    pshs      d         push the length
                    ldd       $0a,s     shell argument vector
                    lbsr      ForkProcess fork the shell process
                    leas      10,s       drop the arguments
                    std       $06,s     save the child process id
                    cmpd      #$FFFF    did the fork fail
                    beq       CmdAbortMsg abort on fork failure
                    ldd       $06,s     the child id
                    bsr       WaitForChild wait for the child to finish
                    std       -$02,s    save its exit status
                    beq       RunCommandRet success, return
                    ldd       IFlagCounter,y   keep-going flag
                    bne       RunCommandRet ignore the error, continue
                    ldd       $0a,s     per-command ignore-error count
                    bne       RunCommandRet '-' prefix, ignore the error
                    leax      MsgAbortedA,pcr aborted-due-to-errors message
                    bra       CmdPrintAbort print and abort

CmdAbortMsg         leax      MsgAbortedB,pcr aborted-due-to-errors message
CmdPrintAbort       pshs      x         push the message
                    ldd       StreamPointer,y   error output path
                    lbsr      PrintError print the abort message
                    leas      2,s        drop the argument
                    lbsr      exit      abort the build
RunCommandRet       leas      14,s       release the locals
                    puls      pc,u      return

WaitForChild        pshs      u,d       save frame and child id
                    ldd       #$FFB4    reserve the stack frame
                    lbsr      stkcheck  allocate locals
                    leas      -4,s       reserve the status area
WaitLoop            leax      ,s        point at the status buffer
                    tfr       x,d       as the argument
                    lbsr      WaitChild wait for any child to exit
                    std       $02,s     save the returned child id
                    cmpd      #$FFFF    wait error
                    beq       WaitOk    return not found
                    ldd       $02,s     returned child id
                    bne       WaitMatch a child exited, check it
                    ldd       GlbVar0017 our process context
                    pshs      d         push it
                    ldd       $06,s     the awaited child id
                    lbsr      SendSignal sleep waiting for the child
                    leas      2,s        drop the argument
                    cmpd      #$FFFF    interrupted
                    beq       WaitFail  give up with failure
                    bra       WaitLoop  keep waiting

WaitMatch           cmpd      $04,s     is this the awaited child
                    lbne      WaitLoop  not ours, keep waiting
                    ldd       ,s        its exit status
                    beq       WaitOk    clean exit, return success
                    std       StreamPointer,y   record the failing status
WaitFail            ldd       #$FFFF    return failure
                    bra       WaitRet   go to the common return

WaitOk              clra                clear high byte
                    clrb                clear low byte for success
WaitRet             leas      6,s        release the locals
                    puls      pc,u      return

JoinNameList        pshs      u         save the frame pointer
                    tfr       d,u       list head pointer into u
                    ldd       #$FFBA    reserve the stack frame
                    lbsr      stkcheck  allocate locals
                    ldd       [$04,s]   the first list node
                    pshs      d         push it
                    tfr       u,d       output buffer
                    lbsr      StrCopy   copy the first name
                    bra       JoinNameNext advance to the next node

JoinNameLoop        leax      >SpaceSeparator,y  the space separator
                    pshs      x         push it
                    tfr       u,d       output buffer
                    lbsr      StrCat    append a separating space
                    leas      2,s        drop the argument
                    ldd       [$04,s]   current node name
                    pshs      d         push it
                    tfr       u,d       output buffer
                    lbsr      AppendString append the name
JoinNameNext        leas      2,s        drop the argument
                    ldx       $04,s     list node pointer
                    ldd       $02,x     next-node link
                    std       $04,s     advance the cursor
                    bne       JoinNameLoop more names to join
                    tfr       u,d       output buffer
                    lbsr      $33CF     measure the total length
                    puls      pc,u      return the length

BuildTarget2        pshs      u         save the frame pointer
                    tfr       d,u       target record into u
                    ldd       #$FF8A    reserve the large stack frame
                    lbsr      stkcheck  allocate locals
                    leas      -46,s      reserve local buffers
                    clra                clear high byte
                    clrb                clear low byte
                    std       $28,s     clear the C-compile count
                    std       $26,s     clear the assemble count
                    std       $24,s     clear the rel count
                    ldx       ,u        the target record
                    ldd       $02,x     its name string
                    std       $2C,s     save the target name
                    lbsr      SuffixIsRel look up an explicit rule
                    std       -$02,s    save the result
                    beq       BuildDeriveSrc none, derive a source name
                    ldd       #$0073    flag letter 's'
BuildProcessDep     pshs      d         push the flag letter
                    ldd       $04,u     the dependency string
                    lbsr      ScanDepList locate the source file
                    leas      2,s        drop the argument
                    std       $2a,s     save the prerequisite name
                    bne       BuildClassify got it, continue building
                    bra       BuildNoRuleErr otherwise report missing

BuildDeriveSrc      ldd       $2C,s     target name
                    lbsr      FindExtension derive a source file name
                    std       -$02,s    save it
                    beq       BuildNoRuleErr none found, error out
                    ldd       #$0072    flag letter 'r'
                    bra       BuildProcessDep process the derived source

BuildNoRuleErr      ldd       $2C,s     target name
                    pshs      d         push it
                    leax      >DontKnowFmt,y the '%s' format string
                    pshs      x         push the format
                    ldd       #$0001    one argument
                    lbsr      PrintError report don't-know-how error
                    leas      4,s        drop the arguments
                    lbsr      exit      abort the build
BuildClassify       ldd       $2C,s     target name
                    lbsr      HasSlash  measure the base name
                    std       $20,s     save it
                    ldd       $2a,s     source name
                    lbsr      HasSlash  measure the base name
                    std       $1e,s     save it
                    ldd       $2a,s     source name
                    lbsr      $33CF     its length
                    addd      #$FFFF    index of the last char
                    std       $22,s     save the index
                    ldx       $2a,s     source name
                    leax      d,x       point at the last char
                    ldb       ,x        read the suffix letter
                    sex                 sign-extend it
                    tfr       d,x       into x for dispatch
                    bra       SuffixDispatch classify the suffix

SuffixCountC        ldd       $28,s     the C-compile count
                    addd      #$0001    increment it
                    std       $28,s     save it
                    bra       BuildCStage done classifying

SuffixCountA        ldd       $26,s     the assemble count
                    addd      #$0001    increment it
                    std       $26,s     save it
                    bra       BuildCStage done classifying

SuffixCountR        ldd       $24,s     the rel count
                    addd      #$0001    increment it
                    std       $24,s     save it
                    bra       BuildCStage done classifying

SuffixFPErr         leax      MsgNoFPCompiler,pcr unsupported-compiler message
                    pshs      x         push the message
                    ldd       #$0001    print to standard error
                    lbsr      PrintError print the message
                    leas      2,s        drop the argument
                    lbsr      exit      abort the build
SuffixUnknownErr    ldd       $2C,s     target name
                    pshs      d         push it
                    leax      >DontKnowFmt,y the '%s' format string
                    pshs      x         push the format
                    ldd       #$0001    print to standard error
                    lbsr      PrintError report the unknown suffix
                    leas      4,s        drop the arguments
                    lbsr      exit      abort the build
                    bra       BuildCStage unreachable continue

SuffixDispatch      cmpx      #$0063    suffix 'c' for C source
                    beq       SuffixCountC count a C compile
                    cmpx      #$0061    suffix 'a' for assembly
                    beq       SuffixCountA count an assemble
                    cmpx      #$0072    suffix 'r' for relocatable
                    beq       SuffixCountR count a rel file
                    cmpx      #$0066    suffix 'f'
                    beq       SuffixFPErr unsupported compiler error
                    cmpx      #$0070    suffix 'p'
                    lbeq      SuffixFPErr unsupported compiler error
                    bra       SuffixUnknownErr otherwise unknown suffix

BuildCStage         ldd       $28,s     the C-compile count
                    lbeq      BuildAStage none, try the assemble stage
                    leax      >SpaceSeparator,y  the compile command buffer
                    pshs      x         push the destination
                    ldd       Install,y   the C compiler command
                    pshs      d         push it
                    ldd       GlbVar0003 the command build buffer
                    lbsr      StrCopy   start building the command
                    leas      2,s        drop the argument
                    lbsr      StrCat    append the compiler name
                    leas      2,s        drop the argument
                    ldd       ExtraCFlags,y   extra C flags
                    beq       BuildRelEq none to add
                    pshs      d         push the flags
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCat    append the flags
                    leas      2,s        drop the argument
BuildRelEq          ldd       FirstSuffixOption,y   rel-output option flag
                    beq       BuildRelPlain use the plain -r form
                    leax      OptREqual,pcr the ' -r=' option
                    pshs      x         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCat    append ' -r='
                    leas      2,s        drop the argument
                    ldd       GlbVar0003 the command buffer
                    lbsr      AppendTargetPath append the output directory
                    ldd       GlbVar0003 the command buffer
                    lbsr      $33CF     get the current length
                    tfr       d,x       as an index
                    ldd       GlbVar0003 the command buffer base
                    leax      d,x       point at the end
                    ldd       #$0020    a space character
                    stb       -$01,x    replace the last char with a space
                    bra       BuildCAppendSrc go append the source

BuildRelPlain       leax      OptRSpace,pcr the ' -r ' option
                    pshs      x         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCat    append ' -r '
                    leas      2,s        drop the argument
BuildCAppendSrc     ldd       $2a,s     source file name
                    pshs      d         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      AppendString append the source name
                    lbra      PopFinalArg run the compile command

BuildAStage         ldd       $26,s     the assemble count
                    lbeq      AppendObjOpt none, try the link stage
                    ldd       ExplicitAssemblerFlag,y   explicit-assembler flag
                    bne       BuildAExplicit use the explicit assembler
                    ldd       XFlagCounter,y   default-assembler flag
                    beq       BuildAExplicit none set, use default name
                    leax      StrR68,pcr the default assembler name
                    pshs      x         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCopy   start the assemble command
                    bra       BuildAFlags continue with options

BuildAExplicit      leax      >SpaceSeparator,y  the assemble command buffer
                    pshs      x         push the destination
                    ldd       Install2,y   the assembler command string
                    pshs      d         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCopy   start the assemble command
                    leas      2,s        drop the argument
                    lbsr      StrCat    append the assembler name
BuildAFlags         leas      2,s        drop the argument
                    ldd       ExtraAssemblerFlags,y   extra assembler flags
                    beq       BuildObjSuffix none to add
                    leax      >SpaceSeparator,y  the assembler flags buffer
                    pshs      x,d       push destination and flags
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCat    append the flags
                    leas      2,s        drop the argument
                    lbsr      StrCat    append the remaining flags
                    leas      2,s        drop the argument
BuildObjSuffix      leax      StrDot,pcr the suffix '.' string
                    pshs      x         push it
                    ldd       DirectoryName,y   object-suffix option flag
                    lbsr      StrCmp    check whether the option is set
                    std       ,s++      pop the argument
                    beq       BuildOutOption not set, skip
                    ldd       $1e,s     source base name length
                    bne       BuildOutOption nonzero, skip
                    leax      SlashConstD,pcr the '/' path separator
                    pshs      x         push it
                    ldd       DirectoryName,y   object-suffix option
                    pshs      d         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCat    append the path separator
                    leas      2,s        drop the argument
                    lbsr      StrCat    append the object suffix
                    leas      2,s        drop the argument
BuildOutOption      leax      OptOEqual,pcr the ' -o=' option
                    pshs      x         push it
                    ldd       $2C,s     target name
                    pshs      d         push it
                    ldd       GlbVar0003 the command buffer
                    lbsr      StrCat    append ' -o='
                    leas      2,s        pop the pushed argument
                    lbsr      StrCat    append string to the command buffer
                    leas      2,s        pop the argument
                    ldd       FirstSuffixOption,y   load the suffix directory field
                    lbeq      AppendFinalArg skip appending if none
                    ldd       $20,s     load a local mode flag
                    lbne      AppendFinalArg skip if the flag is set
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      AppendTargetPath append the target path component
                    lbra      AppendFinalArg go emit the remaining arguments

AppendObjOpt        ldd       $24,s     test the object-option local flag
                    lbeq      EmitCommandCR skip object option if unset
                    leax      >SpaceSeparator,y  point to the work-block name buffer
                    pshs      x         push the buffer pointer
                    ldd       Install3,y   load the object directory string
                    pshs      d         push the directory name
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCopy   copy the directory into the buffer
                    leas      2,s        pop the argument
                    lbsr      StrCat    append the remaining string
                    leas      2,s        pop the argument
                    ldd       ObjectFileName,y   load the object-file name field
                    beq       CheckTargetSlash skip if there is none
                    leax      >SpaceSeparator,y  point to the name buffer
                    pshs      x,d       push the buffer and name
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCat    append the object name
                    leas      2,s        pop the argument
                    lbsr      StrCat    append the buffered name
                    leas      2,s        pop the argument
CheckTargetSlash    ldd       $1e,s     test another local flag
                    bne       AppendFOpt skip if set
                    ldd       FirstSuffixOption,y   load the suffix field
                    beq       AppendFOpt skip if none
                    leax      SlashConstE,pcr point to the '/' literal
                    pshs      x         push it
                    ldd       TargetName,y   load the target name
                    pshs      d         push the target name
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCat    append the target name
                    leas      2,s        pop the argument
                    lbsr      StrCat    append the '/' separator
                    leas      2,s        pop the argument
AppendFOpt          leax      OptFEqual,pcr point to the ' -f=' option
                    pshs      x         push it
                    ldd       $2C,s     load the argument value
                    pshs      d         push the argument
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCat    append the ' -f=' option
                    leas      2,s        pop the argument
                    lbsr      StrCat    append the option value
                    leas      2,s        pop the argument
                    ldd       $20,s     test the mode flag local
                    bne       AppendFinalArg skip if set
                    ldd       SecondPrefixString,y   load the directory field
                    beq       AppendFinalArg skip if none
                    leax      SlashConstF,pcr point to the '/' literal
                    pshs      x,d       push the '/' and value
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCat    append the value
                    leas      2,s        pop the argument
                    lbsr      StrCat    append the '/' separator
                    leas      2,s        pop the argument
AppendFinalArg      ldd       $2C,s     load the final argument value
                    pshs      d         push the argument
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCat    append the final argument
PopFinalArg         leas      2,s        pop the argument
EmitCommandCR       leax      StrCR,pcr point to the carriage return string
                    pshs      x         push it
                    ldd       GlbVar0003 load the command buffer pointer
                    lbsr      StrCat    append the carriage return
                    leas      2,s        pop the argument
                    ldd       GlbVar0003 return the command buffer pointer
                    leas      46,s       release the local frame
                    puls      pc,u      restore frame and return

ResolveFileDate     pshs      u         save the caller frame
                    tfr       d,u       U holds the filename argument
                    ldd       #$FF4C    negative local frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -106,s     allocate the local frame
                    clra                clear high byte
                    clrb                clear low byte
                    std       $66,s     zero the slash counter
                    stu       ,s        save the filename pointer
                    bra       SlashScanTest enter the scan loop

SlashCountLoop      ldx       ,s        load the current pointer
                    leax      $01,x     advance one character
                    stx       ,s        store the pointer back
                    ldb       -$01,x    read the character just passed
                    cmpb      #$2f      is it a slash
                    bne       SlashScanTest no, keep scanning
                    ldd       $66,s     load the slash count
                    addd      #$0001    increment it
                    std       $66,s     store the slash count
                    bra       SlashCountDone stop scanning at the slash

SlashScanTest       ldb       [,s]      read the character at the pointer
                    bne       SlashCountLoop loop while not end of string
SlashCountDone      ldd       $66,s     load the slash count
                    lbne      CopyDirectName use path directly if it has slashes
                    ldd       FirstSuffixOption,y   load the first suffix directory list
                    beq       TrySuffixDir2 none, try the next list
                    tfr       u,d       pass the filename
                    lbsr      SuffixIsRel look up in the first suffix directory
                    std       -$02,s    save the match
                    beq       TrySuffixDir2 not found, try the next list
                    pshs      u         push the filename
                    ldd       TargetName,y   load the directory name
                    pshs      d         push it
                    leax      FmtPathA,pcr '%s/%s' path format
                    bra       FormatFullPath build the full path

TrySuffixDir2       ldd       SecondSuffixOption,y   load the second suffix list
                    beq       TrySuffixDir3 none, try the next
                    tfr       u,d       pass the filename
                    lbsr      FindExtension look up in the second table
                    std       -$02,s    save the match
                    beq       TrySuffixDir3 not found, try the next
                    pshs      u         push the filename
                    ldd       SecondPrefixString,y   load the directory name
                    pshs      d         push it
                    leax      FmtPathB,pcr '%s/%s' path format
                    bra       FormatFullPath build the full path

TrySuffixDir3       ldd       ThirdSuffixOption,y   load the third suffix list
                    beq       OpenAndStat none, use the name as is
                    tfr       u,d       pass the filename
                    lbsr      SuffixIsSrc look up in the third table
                    std       -$02,s    save the match
                    beq       OpenAndStat not found, use the name as is
                    pshs      u         push the filename
                    ldd       DirectoryName,y   load the directory name
                    pshs      d         push it
                    leax      FmtPathC,pcr '%s/%s' path format
FormatFullPath      pshs      x         push the format string
                    leax      $08,s     point to the path buffer
                    tfr       x,d       pass the buffer pointer
                    lbsr      SprintfFmtB sprintf the full path into the buffer
                    leas      6,s        pop the format arguments
                    bra       OpenAndStat open the resolved path

CopyDirectName      pshs      u         push the filename
                    leax      $04,s     point to the path buffer
                    tfr       x,d       pass the buffer pointer
                    lbsr      StrCopy   copy the filename into the buffer
                    leas      2,s        pop the argument
OpenAndStat         ldd       #$0002    read-access mode
                    pshs      d         push the mode
                    leax      $04,s     point to the path buffer
                    tfr       x,d       pass the buffer pointer
                    lbsr      OpenFile2 open the file
                    leas      2,s        pop the mode
                    std       $68,s     save the path number
                    bge       CheckVerboseFlag opened successfully
                    leax      $02,s     point to the filename
                    pshs      x         push it
                    ldd       >MsgTab,y load the error context field
                    pshs      d         push it
                    ldd       StreamPointer,y   load the message field
                    lbsr      PrintError report the open failure
                    leas      4,s        pop the arguments
                    lbsr      exit      flush the error output
CheckVerboseFlag    ldd       SFlagCounter,y   check the verbose flag
                    bne       CloseReturnDate skip listing if off
                    leax      $02,s     point to the path buffer
                    pshs      x         push it
                    leax      MsgUpdated,pcr 'updated: %s' message
                    pshs      x         push the format string
                    leax      OutputBuffer,y   point to the output buffer
                    tfr       x,d       pass the buffer pointer
                    lbsr      SprintfFmtA format the updated message
                    leas      4,s        pop the arguments
CloseReturnDate     ldd       $68,s     load the path number
                    lbsr      CloseByPathB close the file and read its date
                    leas      106,s      release the local frame
                    puls      pc,u      return the file date

PrintFileDate       pshs      u         save the caller frame
                    tfr       d,u       U holds the descriptor buffer
                    ldd       #$FFA2    negative local frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -12,s      allocate the local frame
                    ldb       [$10,s]   load the year byte
                    sex                 sign extend to a word
                    std       $08,s     store the year
                    ldx       $10,s     reload the descriptor pointer
                    ldb       $01,x     load the month byte
                    sex                 sign extend
                    std       $06,s     store the month
                    ldb       $02,x     load the day byte
                    sex                 sign extend
                    std       $04,s     store the day
                    ldb       $03,x     load the hour byte
                    sex                 sign extend
                    std       $02,s     store the hour
                    ldb       $04,x     load the minute byte
                    sex                 sign extend
                    std       ,s        store the minute
                    ldd       GlbVar0023 load the base-year global
                    aslb                shift left
                    rola                rotate the high byte
                    aslb                shift left again
                    rola                multiply the base year by four
                    std       $0a,s     store the adjusted value
                    ldd       ,s        load the minute
                    pshs      d         push the minute
                    ldd       $04,s     load the hour
                    pshs      d         push the hour
                    ldd       $08,s     load the day
                    pshs      d         push the day
                    ldd       $0C,s     load the month
                    pshs      d         push the month
                    ldd       $10,s     load the year
                    pshs      d         push the year
                    pshs      u         push the name string
                    ldd       #$0014    column offset constant
                    subd      $16,s     compute the column offset
                    leax      >WorkBuf,y point into the work buffer
                    leax      d,x       add the computed offset
                    pshs      x         push the name field pointer
                    leax      FmtDateLine,pcr date-line format string
                    tfr       x,d       pass the format pointer
                    lbsr      FormatToInternal printf the date line
                    leas      14,s       pop the printf arguments
                    leas      12,s       release the local frame
                    puls      pc,u      restore frame and return

ScanDepList         pshs      u         save the caller frame
                    tfr       d,u       U holds the list head
                    ldd       #$FFB2    negative local frame size
                    lbsr      stkcheck  check for stack overflow
                    leas      -10,s      allocate the local frame
OuterDepLoop        stu       $02,s     save the current outer node
MidDepLoop          ldd       $02,s     reload the node
                    std       ,s        set the inner pointer
InnerDepLoop        ldx       [,s]      dereference to the entry
                    ldd       $02,x     load the entry name pointer
                    std       $04,s     save it
                    ldb       $0f,s     load the search type byte
                    cmpb      #$72      is it 'r' prerequisite type
                    bne       LookupOtherType no, use the other lookup
                    ldd       $04,s     entry name
                    lbsr      SuffixIsRel look up as a prerequisite
                    std       -$02,s    save the result
                    bne       GotDepMatch found, return it
                    bra       NextDepEntry else advance

LookupOtherType     ldd       $04,s     entry name
                    lbsr      SuffixIsSrc look up as the other type
                    std       -$02,s    save the result
                    beq       NextDepEntry not found, advance
GotDepMatch         ldd       $04,s     matched entry name
                    bra       DepScanDone return it

NextDepEntry        ldx       ,s        load the inner pointer
                    ldd       $02,x     load the next inner link
                    std       ,s        store it
                    bne       InnerDepLoop loop over the inner list
                    ldx       $02,s     load the outer node
                    ldd       $04,x     load the next middle link
                    std       $02,s     store it
                    bne       MidDepLoop loop over the middle list
                    ldu       $02,u     load the next outer node
                    bne       OuterDepLoop loop over the outer list
                    clra                clear high byte
                    clrb                no match found
DepScanDone         leas      10,s       release the local frame
                    puls      pc,u      return the match or null

HasSlash            pshs      u         save the caller frame
                    tfr       d,u       U holds the string pointer
                    ldd       #$FFC0    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    bra       SlashScanPeek enter the scan loop

SlashScanNext       ldb       ,u+       read the character and advance
                    cmpb      #$2f      is it a slash
                    bne       SlashScanPeek no, keep scanning
                    ldd       #$0001    return true
                    puls      pc,u      string contains a slash

SlashScanPeek       ldb       ,u        peek the current character
                    bne       SlashScanNext loop while not end of string
                    clra                clear high byte
                    clrb                return false
                    puls      pc,u      no slash found

AppendTargetPath    pshs      u         save the caller frame
                    tfr       d,u       U holds the component string
                    ldd       #$FFBA    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    ldd       TargetName,y   load the target name
                    pshs      d         push it
                    tfr       u,d       command buffer pointer
                    lbsr      AppendString append the target name
                    leas      2,s        pop the argument
                    leax      SlashConstG,pcr '/' literal
                    pshs      x         push it
                    tfr       u,d       command buffer pointer
                    lbsr      StrCat    append the '/' separator
                    leas      2,s        pop the argument
                    puls      pc,u      return

SlashConstA         fcb       $2F
                    fcb       C$NULL
SlashConstB         fcb       $2F
                    fcb       C$NULL
SlashConstC         fcb       $2F
                    fcb       C$NULL
MsgGetstatErr       fcc       /getstat error - "%s".  /
                    fcb       C$NULL
MsgCommand          fcc       /command: %s/
                    fcb       C$CR,C$NULL
MsgNoCommand        fcc       /no explicit command/
                    fcb       C$CR,C$NULL
MsgUnknownMacro     fcc       /"%s" - unknown macro on command line/
                    fcb       C$CR,C$NULL
StrShell            fcc       /shell/
                    fcb       C$NULL
MsgAbortedA         fcc       /aborted due to errors/
                    fcb       C$CR,C$NULL
MsgAbortedB         fcc       /aborted due to errors/
                    fcb       C$CR,C$NULL
MsgNoFPCompiler     fcc       /don't know about 'f' or 'p' compilers./
                    fcb       C$CR,C$NULL
OptREqual           fcc       / -r=/
                    fcb       C$NULL
OptRSpace           fcc       / -r /
                    fcb       C$NULL
StrR68              fcb       $72,$36,$38
                    fcb       C$NULL
StrDot              fcb       $2E
                    fcb       C$NULL
SlashConstD         fcb       $2F
                    fcb       C$NULL
OptOEqual           fcc       / -o=/
                    fcb       C$NULL
SlashConstE         fcb       $2F
                    fcb       C$NULL
OptFEqual           fcc       / -f=/
                    fcb       C$NULL
SlashConstF         fcb       $2F
                    fcb       C$NULL
StrCR               fcb       C$CR,C$NULL
FmtPathA            fcc       |%s/%s|
                    fcb       C$NULL
FmtPathB            fcc       |%s/%s|
                    fcb       C$NULL
FmtPathC            fcc       |%s/%s|
                    fcb       C$NULL
MsgUpdated          fcc       /updated: "%s"/
                    fcb       C$CR,C$NULL
FmtDateLine         fcc       |%s%-32s date: %02d/%02d/%02d %02d:%02d|
                    fcb       C$CR,C$NULL
SlashConstG         fcb       $2F
                    fcb       C$NULL
AllocNamedNode      pshs      u         save the caller frame
                    tfr       d,u       U holds the name string
                    ldd       #$FFB8    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       allocate the local
                    tfr       u,d       name pointer
                    lbsr      $33CF     measure the name length
                    addd      #$000E    add the node header size
                    lbsr      AllocOrDie allocate the node memory
                    std       ,s        save the node pointer
                    pshs      u         push the name
                    ldd       $02,s     node pointer
                    lbsr      InitNamedNode initialize the node with the name
                    leas      2,s        pop the argument
                    ldd       ,s        node pointer
                    std       [GlbVar0005,y] link into the list head
                    addd      #$000B    advance to the value field
                    std       GlbVar0005 update the list tail global
                    bra       MacroReturn return the new node

FindOrAddMacro      pshs      u         save the caller frame
                    tfr       d,u       U holds the name string
                    ldd       #$FFB8    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       allocate the local
                    ldd       GlbVar0025 load the macro-list head global
                    std       ,s        save the current node
                    beq       MacroNodeFound empty list, create a node
SearchLoop          pshs      u         push the search name
                    ldx       $02,s     load the current node
                    ldd       $02,x     load the node name pointer
                    lbsr      StrCmp    compare the names
                    std       ,s++      save the result and pop
                    beq       MacroNodeFound match, node found
                    ldx       ,s        load the current node
                    ldd       $0b,x     load the next link
                    std       ,s        store it
                    bne       SearchLoop loop through the list
MacroNodeFound      ldd       ,s        load the found node
                    bne       MacroReturn return it if found
                    tfr       u,d       name pointer
                    lbsr      AllocNamedNode create a new node
                    std       ,s        save it
MacroReturn         ldd       ,s        load the node pointer
                    bra       NodeReturnTail return

EnsureMacroValue    pshs      u         save the caller frame
                    tfr       d,u       U holds the name string
                    ldd       #$FFBA    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       allocate the local
                    tfr       u,d       name pointer
                    bsr       FindOrAddMacro find or create the macro
                    std       ,s        save the node
                    ldd       [,s]      load its value pointer
                    bne       NodeReturnTail already defined, return
                    ldd       ,s        node pointer
                    lbsr      AllocWordNode assign the default value
                    bra       NodeReturnTail return

InitNamedNode       pshs      u         save the caller frame
                    tfr       d,u       U holds the node pointer
                    ldd       #$FFBA    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    clra                clear high byte
                    clrb                clear low byte
                    std       $04,u     zero the value field
                    std       $0b,u     zero the link field
                    std       ,u        zero the flag field
                    leax      $0d,u     point past the header
                    stx       $02,u     set the name field pointer
                    ldd       $04,s     load the name argument
                    pshs      d         push it
                    ldd       $02,u     name field pointer
                    lbsr      StrCopy   copy the name into the node
NodeReturnTail      leas      2,s        pop the argument
                    puls      pc,u      return

LookupMacro         pshs      u,d       save frame and name argument
                    ldd       #$FFB4    negative frame marker
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       allocate the local
                    ldd       GlbVar0025 load the macro-list head global
                    std       ,s        save the current node
                    ldd       $02,s     load the search name
                    beq       TargetNotFound no name given, done
MacroSearchLoop     ldd       $02,s     search name
                    pshs      d         push it
                    ldx       $02,s     load the current node
                    ldd       $02,x     load the node name pointer
                    lbsr      StrCmp    compare the names
                    std       ,s++      save the result and pop
                    bne       MacroNextLink no match, advance
                    ldd       [,s]      load the node value
                    bra       FindTargetDone return the value

MacroNextLink       ldx       ,s        load the current node
                    ldd       $0b,x     load the next link
                    std       ,s        store next node as current
                    bne       MacroSearchLoop keep walking the target list
TargetNotFound      ldd       $02,s     load the missing target name
                    pshs      d         pass it as printf argument
                    leax      >MsgCantFind,pcr point at can't-find-target message
                    pshs      x         pass the format string
                    ldd       #$0001    one argument follows
                    lbsr      PrintError print the error message
                    leas      4,s        drop the arguments
                    lbsr      exit      abort make
FindTargetDone      leas      4,s        discard locals
                    puls      pc,u      return

MsgCantFind         fcc       /can't find target file: %s./
                    fcb       C$CR,C$NULL
DebugTrace          pshs      u,d       save register
                    ldd       #$FFB4    frame size
                    lbsr      stkcheck  set up the stack frame
                    ldd       DFlagCounter,y   load the debug flag
                    lbeq      ReturnEpilogue skip trace when debugging off
                    ldd       $0a,s     fetch third variadic argument
                    pshs      d         push it
                    ldd       $0a,s     fetch second argument
                    pshs      d         push it
                    ldd       $0a,s     fetch first argument
                    pshs      d         push it
                    ldd       $06,s     load the format string
                    lbsr      FormatToInternal call printf
                    leas      6,s        drop the arguments
                    lbra      ReturnEpilogue return

SuffixIsSrc         pshs      u         save register
                    tfr       d,u       keep string pointer in u
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  set up frame
                    leas      -2,s       reserve a local
                    tfr       u,d       pass the string
                    lbsr      $33CF     measure its length
                    std       ,s        save the length
                    leax      d,u       point past end of string
                    ldb       -$02,x    load second-to-last char
                    cmpb      #$2e      is it a dot
                    bne       SuffixNoMatch no dot, not a source suffix
                    ldb       -$01,x    load the last char
                    sex                 extend to word
                    tfr       d,x       into x for compare
                    cmpx      #$0063    is it .c
                    beq       SuffixMatch matched, return true
                    cmpx      #$0061    is it .a
                    beq       SuffixMatch matched
                    cmpx      #$0066    is it .f
                    beq       SuffixMatch matched
                    cmpx      #$0070    is it .p
                    beq       SuffixMatch matched
                    bra       SuffixNoMatch none matched, return false

SuffixIsRel         pshs      u         save register
                    tfr       d,u       string pointer in u
                    ldd       #$FFBA    frame size
                    lbsr      stkcheck  set up frame
                    leas      -2,s       reserve a local
                    tfr       u,d       pass the string
                    lbsr      $33CF     measure its length
                    std       ,s        save the length
                    addd      #$FFFE    length minus two
                    leax      d,u       point at second-to-last char
                    ldb       ,x        load it
                    cmpb      #$2e      is it a dot
                    bne       SuffixNoMatch no, not .r
                    ldd       ,s        length again
                    addd      #$FFFF    length minus one
                    leax      d,u       point at last char
                    ldb       ,x        load it
                    cmpb      #$72      is it 'r'
                    bne       SuffixNoMatch no, not .r
SuffixMatch         ldd       #$0001    result true
                    lbra      ReturnEpilogue return

SuffixNoMatch       clra                result false
                    clrb                result false
                    lbra      ReturnEpilogue return

CopyFiveBytes       pshs      u         save register
                    tfr       d,u       destination pointer in u
                    ldd       #$FFBE    frame size
                    lbsr      stkcheck  set up frame
                    leas      -2,s       reserve the counter
                    clra                zero the counter
                    clrb                zero the counter
                    std       ,s        init loop counter
                    bra       CopyByteTest enter the copy loop

CopyByteLoop        ldx       $06,s     load source pointer
                    leax      $01,x     advance it
                    stx       $06,s     save it back
                    ldb       -$01,x    read source byte
                    stb       ,u+       copy to destination
CopyByteTest        ldd       ,s        load counter
                    addd      #$0001    increment
                    std       ,s        save it
                    subd      #$0001    restore value
                    cmpd      #$0005    copied five bytes yet
                    blt       CopyByteLoop no, keep copying
                    lbra      ReturnEpilogue return

                    pshs      u         save register
                    tfr       d,u       pattern pointer in u
                    ldd       #$FFBE    frame size
                    lbsr      stkcheck  set up frame
                    bra       PrefixCmpTop enter compare loop

PrefixCmpBody       ldb       ,u        load pattern byte
                    sex                 extend to word
                    pshs      d         save it
                    ldx       $06,s     load candidate pointer
                    leax      $01,x     advance it
                    stx       $06,s     save it back
                    ldb       -$01,x    read candidate byte
                    sex                 extend
                    cmpd      ,s++      compare the two bytes
                    bne       CheckRelSuffix mismatch, check suffix
                    leau      $01,u     advance pattern
                    bra       PrefixCmpTop continue

PrefixCmpTop        ldb       ,u        peek pattern byte
                    bne       PrefixCmpBody more to compare
CheckRelSuffix      ldb       ,u        pattern exhausted
                    lbne      RuleNoMatch no dot follows, no match
                    ldb       [$04,s]   candidate char after prefix
                    cmpb      #$2e      must be a dot
                    lbne      RuleNoMatch candidate pointer
                    ldx       $04,s     next char
                    ldb       $01,x     must be 'r'
                    cmpb      #$72      no, no match
                    lbne      RuleNoMatch char after .r
                    ldb       $02,x     end of string, matched
                    beq       RuleMatch otherwise no match
                    lbra      RuleNoMatch

StemMatchSrc        pshs      u         save register
                    tfr       d,u       pattern pointer in u
                    ldd       #$FFBE    frame size
                    lbsr      stkcheck  set up frame
                    bra       StemCmpNext enter compare loop

StemDotSeen         ldb       ,u+       read pattern byte
                    cmpb      #$2e      reached the dot
                    bne       StemCmpNext no, keep comparing
                    ldb       [$04,s]   candidate char at the dot
                    sex                 extend
                    tfr       d,x       into x
                    bra       TestSuffixChar test the suffix letter

CheckStemEnd        ldx       $04,s     candidate pointer
                    ldb       $01,x     char after suffix letter
                    bne       RuleNoMatch trailing junk, no match
RuleMatch           ldd       #$0001    result true
                    puls      pc,u      return

TestSuffixChar      cmpx      #$0063    is suffix .c
                    beq       CheckStemEnd check terminator
                    cmpx      #$0061    is suffix .a
                    lbeq      CheckStemEnd check terminator
                    cmpx      #$0070    is suffix .p
                    lbeq      CheckStemEnd check terminator
                    cmpx      #$0066    is suffix .f
                    lbeq      CheckStemEnd check terminator
                    bra       RuleNoMatch unknown suffix, no match

StemCmpNext         ldb       ,u        pattern byte
                    sex                 extend
                    pshs      d         save it
                    ldx       $06,s     candidate pointer
                    leax      $01,x     advance
                    stx       $06,s     save it back
                    ldb       -$01,x    candidate byte
                    sex                 extend
                    cmpd      ,s++      compare the bytes
                    beq       StemDotSeen match, continue
RuleNoMatch         clra                result false
                    clrb                result false
                    puls      pc,u      return

AllocOrDie          pshs      u         save register
                    tfr       d,u       size in u
                    ldd       #$FFB8    frame size
                    lbsr      stkcheck  set up frame
                    leas      -2,s       reserve a local
                    tfr       u,d       size argument
                    lbsr      GrowHeap2 allocate memory
                    std       ,s        save the pointer
                    cmpd      #$FFFF    allocation failed
                    bne       ReturnResult no, return the pointer
                    leax      >MsgNoMemory,pcr point at no-memory message
                    pshs      x         pass the message
                    ldd       StreamPointer,y   program name argument
                    bsr       PrintError print the error
                    leas      2,s        drop the argument
                    lbsr      exit      abort make
                    bra       ReturnResult return the pointer

PrintError          pshs      u,d       save registers
                    ldd       #$FFB8    frame size
                    lbsr      stkcheck  set up frame
                    leax      CommandEchoBuffer,y   message buffer
                    pshs      x         destination argument
                    leax      >MsgMakePrefix,pcr point at 'make: ' prefix
                    tfr       x,d       source argument
                    lbsr      PutString copy prefix into buffer
                    leas      2,s        drop the argument
                    ldd       $08,s     variadic arguments
                    pshs      d         push them
                    ldd       $08,s     format string
                    lbsr      FormatToInternal format the message
                    leas      2,s        drop the argument
                    leax      CommandEchoBuffer,y   message buffer
                    pshs      x         destination argument
                    leax      >MsgCrLf,pcr point at CR terminator
                    tfr       x,d       source argument
                    lbsr      PutString append newline
                    leas      2,s        drop the argument
ReturnResult        ldd       ,s        load the result value
ReturnEpilogue      leas      2,s        discard the local
                    puls      pc,u      return

MsgNoMemory         fcc       / - system memory request denied.  /
                    fcb       C$NULL
MsgMakePrefix       fcc       /make: /
                    fcb       C$NULL
MsgCrLf             fcb       C$CR,C$NULL
ParseMacroDef       pshs      u         save register
                    tfr       d,u       line pointer in u
                    ldd       #$FFB2    frame size
                    lbsr      stkcheck  set up frame
                    leas      -8,s       reserve locals
                    stu       $04,s     save the line pointer
                    ldd       DFlagCounter,y   debug flag
                    beq       NameScanLoop skip trace when off
                    tfr       u,d       pass the line
                    lbsr      PrintNameLine trace the line
                    bra       NameScanLoop proceed to scan name

NameScanNext        ldx       $04,s     advance the scan pointer
                    leax      $01,x     advance
                    stx       $04,s     save it back
                    ldb       -$01,x    read the character
                    sex                 extend
                    tfr       d,x       into x
                    bra       IsNameSep test for a separator

TerminateName       clra                nul terminator
                    clrb                nul terminator
                    ldx       $04,s     name pointer
                    stb       -$01,x    terminate the name
                    bra       SkipValueTop go parse the value

IsNameSep           cmpx      #$0020    is it a space
                    beq       TerminateName end of the name
                    cmpx      #$0009    is it a tab
                    lbeq      TerminateName end of the name
                    cmpx      #$003D    is it an equals
                    lbeq      TerminateName end of the name
                    bra       NameScanLoop keep scanning

NameScanLoop        ldb       [$04,s]   current character
                    bne       NameScanNext keep scanning the name
                    bra       SkipValueTop done, parse the value

SkipValueSpace      ldd       $0C,s     value pointer
                    addd      #$0001    advance
                    std       $0C,s     save it
SkipValueTop        ldb       [$0C,s]   current value character
                    cmpb      #$20      is it a space
                    beq       SkipValueSpace skip it
                    cmpb      #$09      is it a tab
                    lbeq      SkipValueSpace skip it
                    ldd       $0C,s     value pointer
                    lbsr      $33CF     measure value length
                    std       $02,s     save the length
                    ldx       $0C,s     value pointer
                    ldd       $02,s     length
                    leax      d,x       point past the end
                    ldb       -$01,x    last character
                    cmpb      #C$CR      trailing carriage return
                    bne       BuildVarNode no, keep it
                    ldd       $02,s     length
                    addd      #$FFFF    minus one
                    std       $02,s     save it
                    addd      $0C,s     address of the carriage return
                    tfr       d,x       into x
                    clra                nul
                    clrb                nul
                    stb       ,x        strip the carriage return
BuildVarNode        tfr       u,d       name pointer
                    lbsr      $33CF     measure the name length
                    std       ,s        save it
                    addd      #$0004    plus header size
                    addd      $02,s     plus value length
                    addd      #$0002    plus two nul bytes
                    lbsr      AllocOrDie allocate the node
                    std       $06,s     save the node pointer
                    pshs      u         push the name pointer
                    ldd       $08,s     node pointer
                    addd      #$0004    name field offset
                    lbsr      StrCopy   copy the name
                    leas      2,s        drop the argument
                    ldd       $0C,s     value pointer
                    pshs      d         push it
                    ldd       $08,s     node pointer
                    addd      #$0004    past the name field
                    addd      $02,s     plus the name length
                    addd      #$0001    value field offset
                    std       [$08,s]   store the value pointer
                    lbsr      StrCopy   copy the value
                    leas      2,s        drop the argument
                    leax      StrSDIR,pcr point at 'SDIR'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      drop argument, test result
                    bne       ChkRdir   not SDIR
                    ldd       DirectoryName,y   already have an SDIR
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       DirectoryName,y   record the SDIR value
                    ldd       ThirdSuffixOption,y   SDIR count
                    addd      #$0001    increment
                    std       ThirdSuffixOption,y   save it
                    lbra      LinkVarNode link the node

ChkRdir             leax      StrRDIR,pcr point at 'RDIR'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkOdir   not RDIR
                    ldd       TargetName,y   already have an RDIR
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       TargetName,y   record the RDIR value
                    ldd       FirstSuffixOption,y   RDIR count
                    addd      #$0001    increment
                    std       FirstSuffixOption,y   save it
                    lbra      LinkVarNode link the node

ChkOdir             leax      StrODIR,pcr point at 'ODIR'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkCflags not ODIR
                    ldd       SecondPrefixString,y   already have an ODIR
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       SecondPrefixString,y   record the ODIR value
                    ldd       SecondSuffixOption,y   ODIR count
                    addd      #$0001    increment
                    std       SecondSuffixOption,y   save it
                    lbra      LinkVarNode link the node

ChkCflags           leax      StrCFLAGS,pcr point at 'CFLAGS'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkRflags not CFLAGS
                    ldd       ExtraCFlags,y   already have CFLAGS
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       ExtraCFlags,y   record the CFLAGS value
                    lbra      LinkVarNode link the node

ChkRflags           leax      StrRFLAGS,pcr point at 'RFLAGS'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkLflags not RFLAGS
                    ldd       ExtraAssemblerFlags,y   already have RFLAGS
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       ExtraAssemblerFlags,y   record the RFLAGS value
                    lbra      LinkVarNode link the node

ChkLflags           leax      StrLFLAGS,pcr point at 'LFLAGS'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkCc     not LFLAGS
                    ldd       ObjectFileName,y   already have LFLAGS
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       ObjectFileName,y   record the LFLAGS value
                    lbra      LinkVarNode link the node

ChkCc               leax      StrCC,pcr point at 'CC'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkRc     not CC
                    ldd       AlreadyHaveCc,y   already have CC
                    lbne      MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       Install,y   record the CC value
                    ldd       AlreadyHaveCc,y   CC count
                    addd      #$0001    increment
                    std       AlreadyHaveCc,y   save it
                    bra       LinkVarNode link the node

ChkRc               leax      StrRC,pcr point at 'RC'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       ChkLc     not RC
                    ldd       ExplicitAssemblerFlag,y   already have RC
                    bne       MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       Install2,y   record the RC value
                    ldd       ExplicitAssemblerFlag,y   RC count
                    addd      #$0001    increment
                    std       ExplicitAssemblerFlag,y   save it
                    bra       LinkVarNode link the node

ChkLc               leax      StrLC,pcr point at 'LC'
                    pshs      x         compare argument
                    tfr       u,d       name pointer
                    lbsr      StrCmp    strcmp
                    std       ,s++      test result
                    bne       LinkVarNode not LC either
                    ldd       AlreadyHaveLc,y   already have LC
                    bne       MacroDefDone yes, done
                    ldd       [$06,s]   node name pointer
                    std       Install3,y   record the LC value
                    ldd       AlreadyHaveLc,y   LC count
                    addd      #$0001    increment
                    std       AlreadyHaveLc,y   save it
LinkVarNode         ldd       $06,s     node pointer
                    std       [GlbVar0007,y] link into the variable list
                    addd      #$0002    advance the list tail
                    std       GlbVar0007 update the list head
MacroDefDone        leas      8,s        discard locals
                    puls      pc,u      return

ExpandMacro         pshs      u,d       save registers
                    ldd       #$FFA6    frame size
                    lbsr      stkcheck  set up frame
                    leas      -16,s      reserve locals
                    ldu       #$0000    init output pointer
                    ldd       $10,s     first argument
                    addd      #$0001    bump it
                    std       $10,s     save it
                    subd      #$0001    restore value
                    std       $06,s     save local copy
                    std       $02,s     save the working pointer
                    ldd       #$0001    initialise nesting depth to one
                    std       $0a,s     store paren depth counter
                    ldx       $10,s     load the scan pointer
                    leax      $01,x     advance the scan pointer
                    stx       $10,s     save advanced pointer
                    ldb       -$01,x    fetch current character
                    cmpb      #$28      is it an open paren
                    bne       SkipMacroChar no, do not increase depth
                    ldd       $0a,s     load paren depth
                    addd      #$0001    increment nesting depth
                    std       $0a,s     store updated depth
                    bra       ScanParenTop continue scanning

ScanParenLoop       leau      $01,u     advance macro name pointer
ScanParenTop        ldx       $10,s     load the scan pointer
                    leax      $01,x     advance the scan pointer
                    stx       $10,s     save advanced pointer
                    ldb       -$01,x    fetch current character
                    cmpb      #$29      is it a close paren
                    bne       ScanParenLoop not yet, keep scanning name
                    bra       GotMacroName found closing paren

SkipMacroChar       leau      $01,u     advance macro name pointer
GotMacroName        pshs      u         save macro name end pointer
                    ldd       $08,s     load name start pointer
                    addd      $0C,s     compute name buffer offset
                    lbsr      LookupMacro2 look up the macro by name
                    leas      2,s        drop temporary argument
                    std       ,s        store the entry pointer
                    lbeq      UnknownMacroErr not found, unknown macro error
                    pshs      u         save name pointer
                    ldd       $0C,s     load offset value
                    addd      ,s++      add saved offset
                    addd      #$0001    add one for terminator
                    pshs      d         push computed length
                    ldd       [$02,s]   load expansion string pointer
                    lbsr      $33CF     measure expansion length
                    std       $0e,s     save expansion length
                    cmpd      ,s++      compare against remaining space
                    bge       ShiftBufferSetup too long, shift buffer to fit
                    ldd       $06,s     load replacement offset
                    addd      $0C,s     add name offset
                    std       $08,s     set destination pointer
                    std       $04,s     also set second copy
CopyExpandLoop      ldx       $10,s     load source pointer
                    leax      $01,x     advance source pointer
                    stx       $10,s     save source pointer
                    ldb       -$01,x    fetch source character
                    ldx       $08,s     load destination pointer
                    leax      $01,x     advance destination pointer
                    stx       $08,s     save destination pointer
                    stb       -$01,x    copy character into buffer
                    bne       CopyExpandLoop loop until terminator
                    bra       LoadExpansion copy finished

ShiftBufferSetup    ldd       $0a,s     load depth counter
                    addd      #$FFFF    decrement it
                    std       $0a,s     store updated depth
                    beq       SetShiftOne zero, use single shift
                    ldd       #$0003    three-byte shift amount
                    bra       ShiftPrep go store shift amount

SetShiftOne         ldd       #$0001    one-byte shift amount
ShiftPrep           pshs      d         push shift amount
                    pshs      u         push name pointer
                    ldd       $0a,s     load shift amount
                    addd      $1a,s     add buffer base
                    std       $0C,s     store shifted start
                    addd      $10,s     add pointer offset
                    subd      ,s++      subtract saved value
                    subd      ,s++      subtract another
                    std       $04,s     store destination pointer
                    bra       ShiftRightTop enter shift loop

ShiftRightLoop      ldx       $08,s     load source pointer
                    leax      -$01,x    move back one byte
                    stx       $08,s     save source pointer
                    ldb       $01,x     fetch byte
                    ldx       $04,s     load destination pointer
                    leax      -$01,x    move back one byte
                    stx       $04,s     save destination pointer
                    stb       $01,x     copy byte shifting buffer right
ShiftRightTop       ldd       $08,s     load source pointer
                    cmpd      $10,s     compare against limit
                    bcc       ShiftRightLoop loop while above limit
LoadExpansion       ldd       [,s]      load expansion string pointer
                    std       $08,s     set source to expansion
                    bra       InsertExpandTop enter insertion loop

InsertExpandLoop    ldx       $08,s     load expansion source pointer
                    leax      $01,x     advance source pointer
                    stx       $08,s     save source pointer
                    ldb       -$01,x    fetch expansion character
                    ldx       $06,s     load destination pointer
                    leax      $01,x     advance destination pointer
                    stx       $06,s     save destination pointer
                    stb       -$01,x    insert character into buffer
InsertExpandTop     ldb       [$08,s]   peek next expansion char
                    bne       InsertExpandLoop loop until terminator
                    bra       ExpandDone2 insertion finished

UnknownMacroErr     ldd       $06,s     load macro name pointer
                    pshs      d         push it as printf argument
                    leax      MsgUnknownMacro2,pcr point to unknown-macro format
                    pshs      x         push format string
                    ldd       #$0001    select stderr file number
                    lbsr      PrintError print the error message
                    leas      4,s        drop the arguments
                    lbsr      exit      abort the build
ExpandDone2         ldd       $02,s     load result pointer
                    leas      18,s       tear down the frame
                    puls      pc,u      return to caller

LookupMacro2        pshs      u         save u register
                    tfr       d,u       move name pointer into u
                    ldd       #$FFB6    load hash seed
                    lbsr      stkcheck  compute name hash
                    leas      -2,s       reserve a local
                    ldd       GlbVar0027 load macro list head
                    std       ,s        save current entry
                    beq       NotFound  empty list, not found
                    bra       SearchTop enter the search loop

CompareEntryLoop    ldd       $06,s     load target name length
                    pshs      d         push it
                    pshs      u         push name pointer
                    ldd       $04,s     load entry name pointer
                    addd      #$0004    skip to entry name field
                    lbsr      StrNCmp   compare the two names
                    leas      4,s        drop arguments
                    std       -$02,s    save compare result
                    bne       NextEntry mismatch, try next entry
                    ldd       ,s        load entry pointer
                    addd      #$0004    skip to name field
                    lbsr      $33CF     measure entry name length
                    cmpd      $06,s     lengths equal
                    bne       NextEntry differ, try next entry
                    ldd       ,s        return matching entry
                    bra       LookupReturn go return

NextEntry           ldx       ,s        load current entry
                    ldd       $02,x     load next-link pointer
                    std       ,s        advance to next entry
SearchTop           ldd       ,s        load current entry pointer
                    bne       CompareEntryLoop keep searching if non-null
NotFound            clra                not found, return null
                    clrb                clear low byte
LookupReturn        leas      2,s        release the local
                    puls      pc,u      return to caller

StrSDIR             fcc       /SDIR/
                    fcb       C$NULL
StrRDIR             fcc       /RDIR/
                    fcb       C$NULL
StrODIR             fcc       /ODIR/
                    fcb       C$NULL
StrCFLAGS           fcc       /CFLAGS/
                    fcb       C$NULL
StrRFLAGS           fcc       /RFLAGS/
                    fcb       C$NULL
StrLFLAGS           fcc       /LFLAGS/
                    fcb       C$NULL
StrCC               fcb       $43,$43
                    fcb       C$NULL
StrRC               fcb       $52,$43
                    fcb       C$NULL
StrLC               fcb       $4C,$43
                    fcb       C$NULL
MsgUnknownMacro2    fcc       /"%s" - unknown macro/
                    fcb       C$NULL
AllocMacroSlot      pshs      u         save u register
                    leau      DefaultInputHandle,y   point to macro table base
FindFreeLoop        ldd       $06,u     load entry flag word
                    clra                clear high byte
                    andb      #$03      test the in-use bits
                    bne       NextSlot  occupied, try next slot
                    tfr       u,d       return this free entry
                    puls      pc,u      return to caller

NextSlot            leau      $0d,u     advance to next entry
                    pshs      u         save pointer
                    leax      TableEndAddress,y   load table end address
                    cmpx      ,s++      past the end
                    bhi       FindFreeLoop still room, keep scanning
                    ldd       #$00C8    table full error code
                    std       StreamPointer,y   store error number
                    clra                return null
                    clrb                clear low byte
                    puls      pc,u      return to caller

                    puls      pc,u      unreachable tail return

AddMacroEntry       pshs      u,d       save arguments
                    ldu       $08,s     load existing entry pointer
                    bne       HaveEntry already have an entry
                    bsr       AllocMacroSlot allocate a new entry
                    tfr       d,u       move entry into u
HaveEntry           stu       -$02,s    save entry pointer
                    beq       AddEntryNull allocation failed, return null
                    ldd       ,s        load name pointer
                    std       $08,u     store name into entry
                    ldx       $06,s     load option string pointer
                    ldb       $01,x     load second character
                    cmpb      #$2b      is it a plus
                    beq       SetAppendFlag yes, append mode
                    ldb       $02,x     load third character
                    cmpb      #$2b      is it a plus
                    bne       CheckFirstChar no, plain assignment
SetAppendFlag       ldd       $06,u     load entry flags
                    orb       #$03      mark append and defined bits
                    bra       StoreEntryFlags go store flags

CheckFirstChar      ldd       $06,u     load entry flags
                    pshs      d         save them
                    ldb       ,x        load first option char
                    cmpb      #$72      is it r
                    beq       FlagOne   yes, flag one
                    cmpb      #$64      is it d
                    bne       FlagTwo   no, use flag two
FlagOne             ldd       #$0001    flag value one
                    bra       MergeFlags go merge

FlagTwo             ldd       #$0002    flag value two
MergeFlags          ora       ,s+       merge with saved flags
                    orb       ,s+       merge low byte
StoreEntryFlags     std       $06,u     store entry flags
                    ldd       $02,u     load entry value pointer
                    addd      $0b,u     add offset
                    std       $04,u     store computed pointer
                    std       ,u        also store at head
                    tfr       u,d       return entry pointer
                    lbra      ParseAddReturn return to caller

AddEntryNull        clra                return null
                    clrb                clear low byte
                    lbra      ParseAddReturn return to caller

ParseMacroOption    pshs      u         save u register
                    tfr       d,u       move option pointer into u
                    leas      -4,s       reserve locals
                    clra                clear flag accumulator
                    clrb                clear low byte
                    std       ,s        store zeroed flags
                    ldx       $08,s     load pointer argument
                    ldb       $01,x     load second character
                    sex                 sign-extend to word
                    tfr       d,x       move into x for compare
                    bra       FirstOptChar dispatch on character

CheckXPlus          ldx       $08,s     reload pointer argument
                    ldb       $02,x     load third character
                    cmpb      #$2b      is it a plus
                    bne       FlagX     no, x alone
                    ldd       #$0007    flags for x plus
                    bra       StoreOptFlags go store flags

FlagX               ldd       #$0004    flags for x alone
                    bra       StoreOptFlags go store flags

FlagPlus            ldd       #$0003    flags for plus alone
StoreOptFlags       std       ,s        save option flags
                    bra       DispatchOpt continue parsing

OptError            leax      $04,s     restore stack pointer
                    lbra      OptErrorReset go to error path

FirstOptChar        stx       -$02,s    test first character value
                    beq       DispatchOpt nul, proceed
                    cmpx      #$0078    is it x
                    beq       CheckXPlus handle x option
                    cmpx      #$002B    is it plus
                    beq       FlagPlus  handle plus option
                    bra       OptError  unknown, error path

DispatchOpt         ldb       [$08,s]   load first char indirect
                    sex                 sign-extend to word
                    tfr       d,x       move into x
                    lbra      DispatchChar dispatch on option letter

OptRead             ldd       ,s        load flags
                    orb       #$01      set read bit
                    bra       InstallVariant go install variant

OptAppend           ldd       ,s        load flags
                    orb       #$02      set append bit
                    pshs      d         save flags
                    tfr       u,d       move string pointer
                    lbsr      OpenFile2 install macro variant
                    leas      2,s        drop argument
                    std       $02,s     save result
                    cmpd      #$FFFF    was it an error
                    beq       OptWrite  yes, handle write path
                    ldd       #$0002    push count two
                    pshs      d         push it
                    clra                push null
                    clrb                clear low byte
                    pshs      d         push null
                    pshs      d         push null again
                    ldd       $08,s     load entry pointer
                    lbsr      SeekFile  build the entry
                    leas      6,s        drop arguments
                    bra       OptResult go finish

OptWrite            ldd       ,s        load flags
                    orb       #$02      set write bit
                    pshs      d         save flags
                    tfr       u,d       move string pointer
                    lbsr      CreateFile install macro variant
                    bra       VariantDone go save result

OptDelete           ldd       ,s        load flags
                    orb       #$81      set delete flags
InstallVariant      pshs      d         push flags
                    tfr       u,d       move string pointer
                    lbsr      OpenFile2 install macro variant
VariantDone         leas      2,s        drop argument
                    std       $02,s     save result
                    bra       OptResult go finish

OptErrorReset       leas      -$04,x    restore stack for error
BadOptionErr        ldd       #$00CB    bad option error code
                    std       StreamPointer,y   store error number
                    clra                return null
                    clrb                clear low byte
                    bra       OptReturn go return

DispatchChar        cmpx      #$0072    is it r
                    lbeq      OptRead   handle read option
                    cmpx      #$0061    is it a
                    lbeq      OptAppend handle append option
                    cmpx      #$0077    is it w
                    beq       OptWrite  handle write option
                    cmpx      #$0064    is it d
                    beq       OptDelete handle delete option
                    bra       BadOptionErr unknown option error

OptResult           ldd       $02,s     load result
OptReturn           leas      4,s        release locals
                    puls      pc,u      return to caller

                    pshs      u,d       save arguments
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push null flags
                    ldd       $08,s     load name pointer
                    pshs      d         push it
                    ldd       $04,s     load option pointer
                    bra       CallAddEntry call add-entry

ParseAndAdd         pshs      u,d       save arguments
                    ldd       $06,s     load option string pointer
                    pshs      d         push it
                    ldd       $02,s     load name pointer
                    lbsr      ParseMacroOption parse the macro option
                    leas      2,s        drop argument
                    tfr       d,u       result into u
                    cmpu      #$FFFF    was it an error
                    bne       AddWithEntry no, proceed
                    clra                return null
                    clrb                clear low byte
                    bra       ParseAddReturn go return

AddWithEntry        clra                clear high byte
                    clrb                clear low byte
                    bra       PushEntryArgs go push add-entry args

                    pshs      u,d       save arguments
                    ldd       $08,s     load pointer argument
                    lbsr      CloseStream call helper
                    ldd       $06,s     load option pointer
                    pshs      d         push it
                    ldd       $02,s     load name pointer
                    lbsr      ParseMacroOption parse the macro option
                    leas      2,s        drop argument
                    tfr       d,u       result into u
                    stu       -$02,s    save result
                    bge       UseEntryArg valid, use entry arg
                    clra                return null
                    clrb                clear low byte
                    bra       ParseAddReturn go return

UseEntryArg         ldd       $08,s     load entry argument
PushEntryArgs       pshs      d         push it
                    ldd       $08,s     load argument again
                    pshs      d         push it
                    tfr       u,d       move entry pointer
CallAddEntry        lbsr      AddMacroEntry add the macro entry
                    leas      4,s        drop the arguments
ParseAddReturn      leas      2,s        release local
                    puls      pc,u      return to caller

PrintNameLine       pshs      u,d       save arguments
                    leax      CommandEchoBuffer,y   point to name buffer
                    pshs      x         push buffer pointer
                    ldd       $02,s     load argument
                    bsr       PutString print the string
                    leas      2,s        drop argument
                    leax      CommandEchoBuffer,y   point to name buffer
                    pshs      x         push buffer pointer
                    ldd       #$000D    carriage return character
                    lbsr      EmitFloatField write the newline
                    leas      2,s        drop argument
                    leas      2,s        drop argument
                    puls      pc,u      return to caller

PutString           pshs      u         save u register
                    tfr       d,u       move string pointer into u
                    leas      -1,s       reserve char local
                    bra       PutStringTop enter output loop

PutCharLoop         ldd       $05,s     load file argument
                    pshs      d         push it
                    ldb       $02,s     load current character
                    sex                 sign-extend
                    lbsr      EmitFloatField output the character
                    leas      2,s        drop argument
PutStringTop        ldb       ,u+       fetch next character
                    stb       ,s        save it locally
                    bne       PutCharLoop loop until terminator
                    leas      1,s        release char local
                    puls      pc,u      return to caller

                    pshs      u,d       save arguments
                    leas      -2,s       reserve local
                    ldu       $02,s     load destination buffer pointer
                    bra       ReadCharTop enter read loop

ReadCharLoop        ldd       ,s        load read character
                    stb       ,u+       store into buffer
ReadCharTop         leax      DefaultInputHandle,y   point to input handle
                    tfr       x,d       move into d
                    lbsr      GetChar   read next character
                    std       ,s        save character
                    cmpd      #$000D    is it carriage return
                    beq       CheckEof  yes, end of line
                    ldd       ,s        reload character
                    cmpd      #$FFFF    is it end of file
                    bne       ReadCharLoop no, keep reading
CheckEof            ldd       ,s        load last character
                    cmpd      #$FFFF    was it end of file
                    bne       TerminateLine2 no, terminate line
                    clra                return null on eof
                    clrb                clear low byte
                    bra       ReadLineReturn go return

TerminateLine2      clra                clear high byte
                    clrb                clear low byte
                    stb       ,u        nul-terminate the buffer
                    ldd       $02,s     return buffer pointer
ReadLineReturn      leas      4,s        release locals
                    puls      pc,u      return to caller

ProcessEntry        pshs      u,d       save arguments
                    ldu       $06,s     load pointer argument
                    leas      -4,s       reserve locals
                    ldd       $04,s     load argument value
                    std       ,s        store into local
                    bra       ProcessLoop enter processing loop

ProcessEntryLoop    ldd       $02,s     load next argument
                    ldx       ,s        load output buffer pointer
                    leax      $01,x     advance the buffer pointer
                    stx       ,s        save advanced pointer
                    stb       -$01,x    store the read character
                    cmpb      #C$CR      check for carriage return
                    beq       FgetsTerminate stop at end of line
ProcessLoop         tfr       u,d       get remaining count
                    leau      -$01,u    decrement the count
                    std       -$02,s    save remaining count
                    ble       FgetsTerminate stop when buffer is full
                    ldd       $0C,s     load the input path
                    lbsr      GetChar   read the next character
                    std       $02,s     save the character
                    cmpd      #$FFFF    check for end of file
                    bne       ProcessEntryLoop keep reading until eof
FgetsTerminate      clra                clear high byte
                    clrb                clear low byte
                    stb       [,s]      null terminate the line
                    ldd       $02,s     reload last read result
                    cmpd      #$FFFF    was it end of file
                    bne       FgetsReturnCount return count if data read
                    clra                clear high byte
                    clrb                clear low byte
                    bra       FgetsExit return zero at eof

FgetsReturnCount    ldd       $04,s     return the byte count
FgetsExit           leas      6,s        drop locals
                    puls      pc,u      return to caller

ReadBlock           pshs      u         save the buffer pointer
                    tfr       d,u       set up destination pointer
                    ldd       #$FFB6    negative size argument
                    lbsr      stkcheck  call the block-read helper
                    leas      -6,s       reserve local frame
                    ldd       $0C,s     load element count
                    bra       ReadOuterDec enter the outer loop

ReadOuterLoop       ldd       $0a,s     reload inner byte count
                    bra       ReadInnerNext resume the inner loop

ReadByteLoop        ldd       $0e,s     load the input path
                    lbsr      GetChar   read the next byte
                    std       ,s        save the byte
                    cmpd      #$FFFF    check for end of file
                    beq       ReadInnerDone stop at eof
                    ldd       ,s        reload the byte
                    stb       ,u+       store into destination
                    ldd       $04,s     load remaining bytes
                    addd      #$FFFF    decrement the counter
ReadInnerNext       std       $04,s     save remaining bytes
                    ldd       $04,s     reload remaining bytes
                    bne       ReadByteLoop keep reading this element
ReadInnerDone       ldd       $04,s     check inner remainder
                    bne       ReadBlockDone bail out on short read
                    ldd       $02,s     load element counter
                    addd      #$FFFF    decrement element count
ReadOuterDec        std       $02,s     save element count
                    ldd       $02,s     reload element count
                    bne       ReadOuterLoop read the next element
ReadBlockDone       ldd       $0C,s     total requested bytes
                    subd      $02,s     subtract bytes remaining
                    leas      6,s        drop the frame
                    puls      pc,u      return bytes read

FormatToInternal    pshs      u,d       save registers and args
                    leax      CommandEchoBuffer,y   point to internal buffer
                    stx       OutputPointer,y   set the output pointer
                    leax      $06,s     address of the argument list
                    pshs      x         pass the argument pointer
                    ldd       $02,s     load the format string
                    bra       DoSprintfA call the format engine

SprintfFmtA         pshs      u,d       save registers and args
                    ldd       ,s        load destination pointer
                    std       OutputPointer,y   set the output pointer
                    leax      $08,s     address of the arguments
                    pshs      x         pass the argument pointer
                    ldd       $08,s     load the format string
DoSprintfA          pshs      d         push the format string
                    leax      FormatToBuffer,pcr default output callback
                    tfr       x,d       into d for the call
                    bsr       FormatEngine run the format engine
                    leas      4,s        drop pushed arguments
                    bra       SprintfRet return to caller

SprintfFmtB         pshs      u,d       save registers and args
                    ldd       ,s        load destination pointer
                    std       OutputPointer,y   set the output pointer
                    leax      $08,s     address of the arguments
                    pshs      x         pass the argument pointer
                    ldd       $08,s     load the format string
                    pshs      d         push the format string
                    leax      BufPutChar,pcr alternate output callback
                    tfr       x,d       into d for the call
                    bsr       FormatEngine run the format engine
                    leas      4,s        drop pushed arguments
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [OutputPointer,y] null terminate the buffer
                    ldd       ,s        load return value
SprintfRet          leas      2,s        drop local
                    puls      pc,u      return to caller

FormatEngine        pshs      u,d       save registers and format
                    ldu       $06,s     point at the format string
                    leas      -11,s      reserve local frame
                    bra       ScanLoop  start scanning the format

EmitLiteral         ldb       $08,s     load the current character
                    lbeq      FormatDone stop at end of string
                    sex                 extend char to word
                    jsr       [$0b,s]   emit the literal character
ScanLoop            ldb       ,u+       fetch next format character
                    stb       $08,s     save the character
                    cmpb      #$25      is it a percent sign
                    bne       EmitLiteral emit ordinary characters
                    ldb       ,u+       fetch char after percent
                    stb       $08,s     save the conversion char
                    clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     clear precision
                    std       $06,s     clear field width
                    ldb       $08,s     reload conversion char
                    cmpb      #$2d      is it a minus flag
                    bne       NoLeftFlag no left-justify requested
                    ldd       #$0001    set left-justify flag
                    std       LeftJustifyFlag,y   save the flag
                    ldb       ,u+       fetch next character
                    stb       $08,s     save the character
                    bra       CheckZeroPad continue parsing flags

NoLeftFlag          clra                clear high byte
                    clrb                clear low byte
                    std       LeftJustifyFlag,y   clear left-justify flag
CheckZeroPad        ldb       $08,s     load the character
                    cmpb      #$30      is it a zero flag
                    bne       SpacePad  use space padding
                    ldd       #$0030    zero pad character
                    bra       SetPadChar set the pad character

SpacePad            ldd       #$0020    space pad character
SetPadChar          std       PadCharacter,y   save the pad character
                    bra       WidthLoop parse the field width

WidthDigit          ldd       $06,s     current width accumulator
                    pshs      d         save it
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  do the multiply
                    pshs      d         save the product
                    ldb       $0a,s     load the current digit
                    sex                 extend to word
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add the scaled width
                    std       $06,s     save the new width
                    ldb       ,u+       fetch next character
                    stb       $08,s     save the character
WidthLoop           ldb       $08,s     load the character
                    sex                 extend to word
                    leax      CharacterTypeTable,y   character-type table
                    leax      d,x       index by character
                    ldb       ,x        load the type bits
                    clra                clear high byte
                    andb      #$08      test for a digit
                    bne       WidthDigit accumulate width digits
                    ldb       $08,s     load the character
                    cmpb      #$2e      is it a decimal point
                    bne       NoPrecision no precision given
                    ldd       #$0001    mark precision present
                    std       $04,s     save the flag
                    bra       PrecLoop  parse precision digits

PrecDigit           ldd       $02,s     current precision accumulator
                    pshs      d         save it
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  do the multiply
                    pshs      d         save the product
                    ldb       $0a,s     load the current digit
                    sex                 extend to word
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add the scaled precision
                    std       $02,s     save the new precision
PrecLoop            ldb       ,u+       fetch next character
                    stb       $08,s     save the character
                    ldb       $08,s     load the character
                    sex                 extend to word
                    leax      CharacterTypeTable,y   character-type table
                    leax      d,x       index by character
                    ldb       ,x        load the type bits
                    clra                clear high byte
                    andb      #$08      test for a digit
                    bne       PrecDigit accumulate precision digits
                    bra       DispatchConv precision parsed

NoPrecision         clra                clear high byte
                    clrb                clear low byte
                    std       $04,s     clear precision-present flag
DispatchConv        ldb       $08,s     load conversion char
                    sex                 extend to word
                    tfr       d,x       into x for dispatch
                    lbra      ConvDispatch dispatch on conversion

ConvDecimal         ldd       $06,s     pass the field width
                    pshs      d         save it
                    ldx       $15,s     va_list pointer
                    leax      $02,x     advance past argument
                    stx       $15,s     save the pointer
                    ldd       -$02,x    fetch the integer argument
                    lbsr      FormatSignedDec convert to signed decimal
                    lbra      EmitFormatted output the digits

ConvOctal           ldd       $06,s     pass the field width
                    pshs      d         save it
                    ldx       $15,s     va_list pointer
                    leax      $02,x     advance past argument
                    stx       $15,s     save the pointer
                    ldd       -$02,x    fetch the integer argument
                    lbsr      FormatOctal convert to octal
                    lbra      EmitFormatted output the digits

ConvHex             ldd       $06,s     pass the field width
                    pshs      d         save it
                    ldb       $0a,s     the conversion char
                    sex                 extend to word
                    leax      CharacterTypeTable,y   character-type table
                    leax      d,x       index by character
                    ldb       ,x        load the type bits
                    clra                clear high byte
                    andb      #$02      test the uppercase flag
                    pshs      d         pass the case flag
                    ldx       $17,s     va_list pointer
                    leax      $02,x     advance past argument
                    stx       $17,s     save the pointer
                    ldd       -$02,x    fetch the integer argument
                    lbsr      FormatHex convert to hex
                    lbra      LongResult output the digits

ConvUnsigned        ldd       $06,s     pass the field width
                    pshs      d         save it
                    ldx       $15,s     va_list pointer
                    leax      $02,x     advance past argument
                    stx       $15,s     save the pointer
                    ldd       -$02,x    fetch the integer argument
                    pshs      d         pass the value
                    leax      ConversionBuffer,y   conversion buffer
                    tfr       x,d       pass the buffer
                    lbsr      FormatUnsignedDec convert unsigned decimal
                    lbra      LongResult output the digits

ConvFloat           ldd       $04,s     precision present flag
                    bne       FloatHavePrec keep given precision
                    ldd       #$0006    default six digits
                    std       $02,s     set default precision
FloatHavePrec       ldd       $06,s     pass the field width
                    pshs      d         save it
                    leax      $15,s     address of the va_list
                    pshs      x         pass the va_list pointer
                    ldd       $06,s     reload the field width
                    pshs      d         save again
                    ldb       $0e,s     the conversion char
                    sex                 extend to word
                    lbsr      $33C4     format the floating value
                    leas      4,s        drop pushed arguments
                    lbra      EmitFormatted output the result

ConvChar            ldx       $13,s     va_list pointer
                    leax      $02,x     advance past argument
                    stx       $13,s     save the pointer
                    ldd       -$02,x    fetch the char argument
                    lbra      EmitOneChar emit the character

ConvString          ldx       $13,s     va_list pointer
                    leax      $02,x     advance past argument
                    stx       $13,s     save the pointer
                    ldd       -$02,x    fetch the string pointer
                    std       $09,s     save the string pointer
                    ldd       $04,s     precision present flag
                    beq       StringFull use full string length
                    ldd       $09,s     the string pointer
                    std       $04,s     start scanning here
                    bra       StrLenTest measure to precision

StrLenLoop          ldb       [$09,s]   load current character
                    beq       EmitStringLen stop at end of string
                    ldd       $09,s     the string pointer
                    addd      #$0001    advance the pointer
                    std       $09,s     save it
StrLenTest          ldd       $02,s     remaining precision
                    addd      #$FFFF    decrement the count
                    std       $02,s     save the count
                    subd      #$FFFF    test the count
                    bne       StrLenLoop scan up to precision chars
EmitStringLen       ldd       $06,s     pass the field width
                    pshs      d         save it
                    ldd       $0b,s     end of scanned range
                    subd      $06,s     compute the length
                    pshs      d         pass the length
                    ldd       $08,s     the string pointer
                    pshs      d         pass the string
                    ldd       $11,s     the output callback
                    lbsr      PutPaddedCount emit the string
                    leas      6,s        drop arguments
                    bra       FieldDone continue scanning

StringFull          ldd       $06,s     pass the field width
                    pshs      d         save it
                    ldd       $0b,s     the string pointer
EmitFormatted       pshs      d         pass the string
                    bra       OutputField output the string

ConvLong            ldb       ,u+       fetch the length modifier
                    stb       $08,s     save the character
                    bra       LongFormat handle the long conversion

                    leas      -$0d,x    unreachable filler after branch
LongFormat          ldd       $06,s     pass the field width
                    pshs      d         save it
                    leax      $15,s     address of the va_list
                    pshs      x         pass the va_list pointer
                    ldb       $0C,s     the conversion char
                    sex                 extend to word
                    lbsr      GetFormatArg format the long value
LongResult          std       ,s        save the result pointer
OutputField         ldd       $0f,s     the output callback
                    lbsr      PutPaddedStr emit with field width
                    leas      4,s        drop arguments
FieldDone           lbra      ScanLoop  continue scanning

ConvDefault         ldb       $08,s     load conversion char
                    sex                 extend to word
EmitOneChar         jsr       [$0b,s]   emit the character
                    lbra      ScanLoop  continue scanning

ConvDispatch        cmpx      #$0064    is it d
                    lbeq      ConvDecimal signed decimal
                    cmpx      #$006F    is it o
                    lbeq      ConvOctal octal
                    cmpx      #$0078    is it x
                    lbeq      ConvHex   lowercase hex
                    cmpx      #$0058    is it X
                    lbeq      ConvHex   uppercase hex
                    cmpx      #$0075    is it u
                    lbeq      ConvUnsigned unsigned decimal
                    cmpx      #$0066    is it f
                    lbeq      ConvFloat floating point
                    cmpx      #$0065    is it e
                    lbeq      ConvFloat floating point
                    cmpx      #$0067    is it g
                    lbeq      ConvFloat floating point
                    cmpx      #$0045    is it E
                    lbeq      ConvFloat floating point
                    cmpx      #$0047    is it G
                    lbeq      ConvFloat floating point
                    cmpx      #$0063    is it c
                    lbeq      ConvChar  single character
                    cmpx      #$0073    is it s
                    lbeq      ConvString string
                    cmpx      #$006C    is it l
                    lbeq      ConvLong  long modifier
                    bra       ConvDefault emit unknown as literal

FormatDone          leas      13,s       drop the local frame
                    puls      pc,u      return from format engine

FormatSignedDec     pshs      u,d       save registers and value
                    leas      -2,s       reserve local
                    leax      ConversionBuffer,y   conversion buffer
                    stx       ,s        save buffer pointer
                    ldd       $02,s     load the value
                    bge       ConvMagnitude positive, convert directly
                    nega                negate the value
                    negb                continue the negation
                    sbca      #$00      finish the negation
                    std       $02,s     save the magnitude
                    std       -$02,s    test for overflow
                    bge       WriteMinus normal negative value
                    leax      FormatFloatCore,pcr most-negative constant string
                    pshs      x         pass the string
                    leax      ConversionBuffer,y   conversion buffer
                    tfr       x,d       pass the buffer
                    lbsr      StrCopy   copy the constant
                    leas      2,s        drop the argument
                    lbra      OctalFmtExit return the buffer

WriteMinus          ldd       #$002D    minus sign character
                    ldx       ,s        buffer pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save the pointer
                    stb       -$01,x    store the minus sign
ConvMagnitude       ldd       $02,s     load the magnitude
                    pshs      d         pass the value
                    ldd       $02,s     reload the value
                    bsr       FormatUnsignedDec convert unsigned decimal
                    leas      2,s        drop the argument
                    lbra      OctalDone return the buffer

FormatUnsignedDec   pshs      u,d       save registers and value
                    leas      -6,s       reserve local frame
                    ldu       $06,s     output buffer pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     clear significant-digit flag
                    std       ,s        clear digit accumulator
                    bra       ScaleLoop find the top divisor

ScaleDivisor        ldd       ,s        digit accumulator
                    addd      #$0001    count another division
                    std       ,s        save the digit
                    ldd       $0C,s     remaining value
                    subd      Pow10,y   subtract the divisor
                    std       $0C,s     save the remainder
ScaleLoop           ldd       $0C,s     reload the value
                    blt       ScaleDivisor reduce until it goes negative
                    leax      Pow10,y   start at largest divisor
                    stx       $04,s     save the divisor pointer
                    bra       DivisorLoop begin digit extraction

DigitSubLoop        ldd       ,s        digit accumulator
                    addd      #$0001    count another subtraction
                    std       ,s        save the digit
DivideLoop          ldd       $0C,s     remaining value
                    subd      [$04,s]   subtract current divisor
                    std       $0C,s     save the remainder
                    bge       DigitSubLoop keep subtracting this divisor
                    addd      [$04,s]   restore last subtraction
                    std       $0C,s     save the remainder
                    ldd       ,s        the digit value
                    beq       CheckDigit suppress leading zeros
                    ldd       #$0001    mark first significant digit
                    std       $02,s     set the flag
CheckDigit          ldd       $02,s     significant-digit flag
                    beq       NextDivisor skip leading zero
                    ldd       ,s        the digit value
                    addd      #$0030    convert to ascii
                    stb       ,u+       emit the digit
NextDivisor         clra                clear high byte
                    clrb                clear low byte
                    std       ,s        reset digit accumulator
                    ldd       $04,s     divisor pointer
                    addd      #$0002    advance to next divisor
                    std       $04,s     save the pointer
DivisorLoop         ldd       $04,s     divisor pointer
                    cmpd      LastDivisor,y   reached the last divisor
                    bne       DivideLoop extract the next digit
                    ldd       $0C,s     the final remainder
                    addd      #$0030    convert to ascii
                    stb       ,u+       emit the last digit
                    clra                clear high byte
                    clrb                clear low byte
                    stb       ,u        null terminate the string
                    ldd       $06,s     return the buffer pointer
                    leas      8,s        drop the frame
                    puls      pc,u      return to caller

FormatOctal         pshs      u,d       save registers and value
                    leas      -2,s       reserve local
                    leax      ConversionBuffer,y   conversion buffer
                    stx       ,s        save pointer
                    leau      StartScratchBuffer,y   point to digit scratch buffer
OctalDigitLoop      ldd       $02,s     load current value
                    clra                clear high byte
                    andb      #$07      isolate low octal digit
                    addd      #$0030    convert to ascii digit
                    stb       ,u+       store octal digit
                    ldd       $02,s     reload value
                    lsra                shift value right three bits
                    rorb                shift value right three bits
                    lsra                shift value right three bits
                    rorb                shift value right three bits
                    lsra                shift value right three bits
                    rorb                shift value right three bits
                    std       $02,s     save shifted value
                    bne       OctalDigitLoop loop until value exhausted
                    bra       OctalReverseChk go reverse the digit string

OctalReverseCopy    ldb       ,u        read a digit to move
                    ldx       ,s        load destination pointer
                    leax      $01,x     advance destination
                    stx       ,s        save destination
                    stb       -$01,x    copy digit into reversed position
OctalReverseChk     leau      -$01,u    step back through digits
                    pshs      u         save digit pointer
                    leax      StartScratchBuffer,y   start of scratch buffer
                    cmpx      ,s++      compare against buffer start
                    bls       OctalReverseCopy copy until fully reversed
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [,s]      write string terminator
OctalDone           leax      ConversionBuffer,y   point to result string
                    tfr       x,d       return pointer in d
OctalFmtExit        leas      4,s        discard locals
                    puls      pc,u      return

FormatHex           pshs      u,d       save registers for hex format
                    leas      -4,s       allocate locals
                    leax      ConversionBuffer,y   point to result buffer
                    stx       $02,s     save buffer pointer
                    leau      StartScratchBuffer,y   point to digit scratch
HexDigitLoop        ldd       $04,s     load value
                    clra                clear high byte
                    andb      #$0f      isolate low nibble
                    std       ,s        save nibble
                    pshs      d         push nibble
                    ldd       $02,s     reload nibble
                    cmpd      #$0009    digit above nine
                    ble       HexDecimalBase if zero to nine use decimal base
                    ldd       $0C,s     check uppercase flag
                    beq       HexLowerBase if lowercase go lowercase base
                    ldd       #$0041    uppercase letter base
                    bra       HexAlphaAdjust skip lowercase base

HexLowerBase        ldd       #$0061    lowercase letter base
HexAlphaAdjust      addd      #$FFF6    adjust to map onto a-f
                    bra       HexStoreDigit go store the digit

HexDecimalBase      ldd       #$0030    ascii zero base
HexStoreDigit       addd      ,s++      add nibble to base
                    stb       ,u+       store hex digit
                    ldd       $04,s     reload value
                    lsra                shift value right four bits
                    rorb                shift value right four bits
                    lsra                shift value right four bits
                    rorb                shift value right four bits
                    lsra                shift value right four bits
                    rorb                shift value right four bits
                    lsra                shift value right four bits
                    rorb                shift value right four bits
                    anda      #$0f      clear top nibble
                    std       $04,s     save shifted value
                    bne       HexDigitLoop loop until value exhausted
                    bra       HexReverseChk go reverse the hex string

HexReverseCopy      ldb       ,u        read a digit to move
                    ldx       $02,s     load destination pointer
                    leax      $01,x     advance destination
                    stx       $02,s     save destination
                    stb       -$01,x    copy digit into reversed position
HexReverseChk       leau      -$01,u    step back through digits
                    pshs      u         save digit pointer
                    leax      StartScratchBuffer,y   start of scratch buffer
                    cmpx      ,s++      compare against buffer start
                    bls       HexReverseCopy copy until fully reversed
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [$02,s]   write string terminator
                    leax      ConversionBuffer,y   point to result string
                    tfr       x,d       return pointer in d
                    leas      6,s        discard locals
                    puls      pc,u      return

PutPaddedCount      pshs      u,d       save registers for padded output
                    ldu       $06,s     load string pointer
                    ldd       $0a,s     load field width
                    subd      $08,s     subtract string length
                    std       $0a,s     save pad count
                    ldd       LeftJustifyFlag,y   check left-justify flag
                    bne       StrCharChk skip leading pad when left justified
                    bra       LeadPadChk check leading pad count

LeadPadEmit         ldd       PadCharacter,y   load pad character
                    jsr       [,s]      emit pad via callback
LeadPadChk          ldd       $0a,s     load pad count
                    addd      #$FFFF    decrement pad count
                    std       $0a,s     save pad count
                    subd      #$FFFF    test remaining count
                    bgt       LeadPadEmit emit more leading pad
                    bra       StrCharChk go output the string

StrCharEmit         ldb       ,u+       load next string character
                    sex                 sign extend to word
                    jsr       [,s]      emit character via callback
StrCharChk          ldd       $08,s     load remaining length
                    addd      #$FFFF    decrement length
                    std       $08,s     save length
                    subd      #$FFFF    test remaining length
                    bne       StrCharEmit emit rest of string
                    ldd       LeftJustifyFlag,y   check left-justify flag
                    lbeq      PutRet    no trailing pad when right justified
                    bra       TrailPadChk go emit trailing pad

TrailPadEmit        ldd       PadCharacter,y   load pad character
                    jsr       [,s]      emit pad via callback
TrailPadChk         ldd       $0a,s     load pad count
                    addd      #$FFFF    decrement pad count
                    std       $0a,s     save pad count
                    subd      #$FFFF    test remaining count
                    bgt       TrailPadEmit emit more trailing pad
                    lbra      PutRet    done

PutPaddedStr        pshs      u,d       save registers for padded string output
                    ldu       $06,s     load string pointer
                    ldd       $08,s     load field width
                    pshs      d         save width
                    tfr       u,d       string pointer to d
                    lbsr      $33CF     measure string length
                    nega                negate length
                    negb                negate length
                    sbca      #$00      negate length
                    addd      ,s++      width minus length gives pad count
                    std       $08,s     save pad count
                    ldd       LeftJustifyFlag,y   check left-justify flag
                    bne       StrCharChk2 skip leading pad when left justified
                    bra       LeadPadChk2 check leading pad count

LeadPadEmit2        ldd       PadCharacter,y   load pad character
                    jsr       [,s]      emit pad via callback
LeadPadChk2         ldd       $08,s     load pad count
                    addd      #$FFFF    decrement pad count
                    std       $08,s     save pad count
                    subd      #$FFFF    test remaining count
                    bgt       LeadPadEmit2 emit more leading pad
                    bra       StrCharChk2 go output the string

StrCharEmit2        ldb       ,u+       load next string character
                    sex                 sign extend to word
                    jsr       [,s]      emit character via callback
StrCharChk2         ldb       ,u        peek next character
                    bne       StrCharEmit2 loop until null terminator
                    ldd       LeftJustifyFlag,y   check left-justify flag
                    beq       PutRet    no trailing pad when right justified
                    bra       TrailPadChk2 go emit trailing pad

TrailPadEmit2       ldd       PadCharacter,y   load pad character
                    jsr       [,s]      emit pad via callback
TrailPadChk2        ldd       $08,s     load pad count
                    addd      #$FFFF    decrement pad count
                    std       $08,s     save pad count
                    subd      #$FFFF    test remaining count
                    bgt       TrailPadEmit2 emit more trailing pad
                    bra       PutRet    done

FormatToBuffer      pshs      u,d       save registers
                    ldd       OutputPointer,y   load output buffer pointer
                    pshs      d         push buffer pointer
                    ldd       $02,s     load value
                    lbsr      EmitFloatField format number into buffer
                    leas      2,s        discard argument
                    bra       PutRet    return via shared exit

BufPutChar          pshs      u,d       save registers
                    ldd       ,s        load character
                    ldx       OutputPointer,y   load buffer pointer
                    leax      $01,x     advance buffer pointer
                    stx       OutputPointer,y   save buffer pointer
                    stb       -$01,x    store character in buffer
PutRet              leas      2,s        discard argument
                    puls      pc,u      return

FormatFloatCore     blt       FmtFloatCheckLow branch on sign of value
                    leas      -GlbVar0009,y    reserve frame on stack
                    pshu      y,x,dp    save registers on user stack
                    neg       $0034     negate working pointer value
                    nega                negate high byte
                    tfr       d,u       move pointer into u
                    leas      -6,s       allocate locals
                    cmpu      #$0000    null pointer check
                    beq       FmtFloatNull handle null value
                    ldd       $06,u     load flags field
                    clra                clear high byte
                    andb      #$03      isolate type bits
                    bne       FmtFloatSigned branch when not special
FmtFloatNull        ldd       #$FFFF    error result value
                    lbra      FmtFloatExit return

FmtFloatSigned      ldd       $06,u     load flags field
                    anda      #$80      isolate sign bit
                    clrb                clear low byte
                    std       -$02,s    save sign flag
                    bne       FmtFloatFlag branch when sign set
                    tfr       u,d       pointer to d
                    lbsr      InitBuffer normalize the value
                    lbra      FmtFloatEmit go emit the result

FmtFloatFlag        ldd       $06,u     load flags field
                    anda      #$01      isolate low bit
FmtFloatCheckLow    clrb                clear low byte
                    std       -$02,s    save flag
                    beq       FmtFloatRange branch when clear
                    tfr       u,d       pointer to d
                    lbsr      FlushWrite call scaling helper
                    ldd       $06,u     load flags
                    anda      #$FE      clear low bit
                    std       $06,u     save flags
                    ldd       $02,u     load mantissa low
                    addd      $0b,u     add exponent field
                    std       $04,u     store adjusted value
                    lbra      FmtFloatStore go store the value

FmtFloatRange       ldd       ,u        load value
                    cmpd      $04,u     compare against upper limit
                    lbcc      FmtFloatEmit branch when above limit
                    leax      $02,s     point to argument slot
                    pshs      x         push argument pointer
                    leax      $0C,s     point to argument slot
                    lbsr      CopyLong  compute digit value
                    ldx       $0e,s     load result selector
                    lbra      FmtFloatDispatch dispatch on selector

FmtFloatCaseA       leax      $02,s     point to argument slot
                    pshs      x         push argument pointer
                    ldd       $02,x     push argument high word
                    pshs      d         push argument high word
                    ldd       ,x        push argument low word
                    pshs      d         push argument low word
                    tfr       u,d       pointer to d
                    lbsr      FloatNormalize call normalize helper
                    lbsr      LongSub   call helper
                    lbsr      CopyLong  call helper
FmtFloatCaseB       ldd       $0b,u     load exponent field
                    lbsr      LongFromByte call helper
                    ldd       $02,x     push argument word
                    pshs      d         push argument word
                    ldd       ,x        push argument word
                    pshs      d         push argument word
                    leax      $06,s     point at pushed arguments
                    ldd       $02,x     push argument word
                    pshs      d         push argument word
                    ldd       ,x        push argument word
                    pshs      d         push argument word
                    bsr       FmtCmpThunkA call with inline constant following
                    fcb       $00,$00,$00,$00
FmtCmpThunkA        puls      x         recover inline constant pointer
                    lbsr      LongCompare compare the two values
                    bge       FmtFloatGe branch when greater or equal
                    leax      $06,s     point at pushed arguments
                    lbsr      LongNegate call helper
                    bra       FmtFloatCmp2 continue

FmtFloatGe          leax      $06,s     point at pushed arguments
FmtFloatCmp2        lbsr      LongCompare compare the two values
                    blt       FmtFloatMerge branch when less than
                    ldd       $04,s     load argument word
                    addd      ,u        add value
                    std       ,s        store sum
                    cmpd      $02,u     compare with lower field
                    bcs       FmtFloatMerge branch when below
                    cmpd      $04,u     compare with upper field
                    bcc       FmtFloatMerge branch when at or above
                    std       ,u        store the value
                    ldd       $06,u     load flags
                    andb      #$EF      clear a flag bit
                    std       $06,u     save flags
                    lbra      FmtFloatOk go return success

                    bra       FmtFloatMerge go merge

FmtFloatDispatch    stx       -$02,s    save selector
                    lbeq      FmtFloatCaseA dispatch case a on zero
                    cmpx      #$0001    compare selector with one
                    lbeq      FmtFloatCaseB dispatch case b on one
FmtFloatMerge       ldd       $0e,s     load selector
                    cmpd      #$0001    compare with one
                    bne       FmtFloatSetVal skip when not one
                    leax      $0a,s     point to argument slot
                    pshs      x         push argument pointer
                    ldd       $02,x     push argument word
                    pshs      d         push argument word
                    ldd       ,x        push argument word
                    pshs      d         push argument word
                    ldd       $04,u     upper field minus value
                    subd      ,u        upper field minus value
                    lbsr      LongFromByte call helper
                    lbsr      LongSub   call helper
                    lbsr      CopyLong  call helper
FmtFloatSetVal      ldd       $04,u     load upper field value
FmtFloatStore       std       ,u        store the value
FmtFloatEmit        ldd       $06,u     load flags
                    andb      #$EF      clear a flag bit
                    std       $06,u     save flags
                    ldd       $0e,s     load selector
                    pshs      d         push selector
                    leax      $0C,s     point to argument slot
                    ldd       $02,x     push argument word
                    pshs      d         push argument word
                    ldd       ,x        push argument word
                    pshs      d         push argument word
                    ldd       $08,u     load exponent field
                    lbsr      SeekFile  call formatter helper
                    leas      6,s        discard arguments
                    ldd       $02,x     push argument word
                    pshs      d         push argument word
                    ldd       ,x        push argument word
                    pshs      d         push argument word
                    bsr       FmtCmpThunkB call with inline constant following
                    fcb       $FF,$FF,$FF,$FF
FmtCmpThunkB        puls      x         recover inline constant pointer
                    lbsr      LongCompare compare the values
                    bne       FmtFloatOk branch when not equal
                    ldd       #$FFFF    error result value
                    bra       FmtFloatExit return

FmtFloatOk          clra                clear high byte
                    clrb                clear low byte
FmtFloatExit        leas      6,s        discard locals
                    puls      pc,u      return

                    pshs      u,d       save registers for helper
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    pshs      d         push zero argument
                    ldd       $06,s     load value argument
                    lbsr      $2DC1     call formatting helper
                    leas      6,s        discard arguments
                    leas      2,s        discard argument
                    puls      pc,u      return

FloatNormalize      pshs      u         save registers
                    tfr       d,u       pointer into u
                    cmpu      #$0000    null pointer check
                    beq       FloatNullConst handle null value
                    ldd       $06,u     load flags field
                    clra                clear high byte
                    andb      #$03      isolate type bits
                    bne       FloatNormSign branch when not special
FloatNullConst      bsr       FloatConstThunk call with inline constant following
                    fcb       $FF,$FF,$FF,$FF
FloatConstThunk     puls      x         recover inline constant pointer
                    leau      LongResult3,y   point at constant value
                    pshs      u         push pointer
                    lbsr      CopyLong  call helper
                    puls      pc,u      return

FloatNormSign       ldd       $06,u     load flags field
                    anda      #$80      isolate sign bit
                    clrb                clear low byte
                    std       -$02,s    save sign flag
                    bne       FloatNormScale branch when set
                    tfr       u,d       pointer to d
                    lbsr      InitBuffer convert the value
FloatNormScale      ldd       #$0001    constant one
                    pshs      d         push argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    pshs      d         push zero argument
                    ldd       $08,u     load exponent field
                    lbsr      SeekFile  call formatter helper
                    leas      6,s        discard arguments
                    ldd       $02,x     push argument word
                    pshs      d         push argument word
                    ldd       ,x        push argument word
                    pshs      d         push argument word
                    ldd       $06,u     load flags
                    anda      #$01      isolate low bit
                    clrb                clear low byte
                    std       -$02,s    save flag
                    beq       FloatNormNeg branch when clear
                    ldd       $02,u     use lower field
                    bra       FloatNormStore skip

FloatNormNeg        ldd       $04,u     use upper field
FloatNormStore      pshs      d         push chosen field
                    ldd       ,u        load value
                    subd      ,s++      subtract chosen field
                    lbsr      LongFromByte call helper
                    lbsr      LongAdd   call helper
                    puls      pc,u      return

EmitFloatField      pshs      u,d       save registers to emit float field
                    ldu       $06,s     load value pointer
                    ldd       $06,u     load flags field
                    anda      #$80      isolate sign bit
                    andb      #$22      mask relevant flag bits
                    cmpd      #$8002    test for signed special combination
                    beq       EmitFloatExp branch on match
                    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$22      mask relevant flag bits
                    cmpd      #$0002    test flag combination
                    lbne      StreamErr branch when not matched
                    tfr       u,d       pointer to d
                    lbsr      InitBuffer convert the value
EmitFloatExp        ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$04      isolate a flag bit
                    beq       EmitFloatRound branch when clear
                    ldd       #$0001    constant one
                    pshs      d         push argument
                    leax      $03,s     point to result slot
                    pshs      x         push result pointer
                    ldd       $06,u     load flags
                    clra                clear high byte
                    andb      #$40      isolate case flag bit
                    beq       EmitFloatLower branch when clear
                    leax      WriteLnFile,pcr uppercase formatter routine pointer
                    bra       EmitFloatCall skip

EmitFloatLower      leax      WriteFile,pcr lowercase formatter routine pointer
EmitFloatCall       tfr       x,d       routine pointer to d
                    tfr       d,x       back into x
                    ldd       $08,u     load value pointer
                    jsr       ,x        call the formatter routine
                    leas      4,s        discard arguments
                    cmpd      #$FFFF    check for error result
                    lbne      LoadRetVal branch on error
                    ldd       $06,u     load flags
                    orb       #$20      set a flag bit
                    std       $06,u     save flags
                    lbra      StreamErr go return

EmitFloatRound      ldd       $06,u     load flags
                    anda      #$01      isolate low bit
                    clrb                clear low byte
                    std       -$02,s    save flag
                    bne       LoadValue branch when set
                    tfr       u,d       pointer to d
                    lbsr      FlushBuffer call helper
LoadValue           ldd       ,u        load value
                    addd      #$0001    increment value
                    std       ,u        store value
                    subd      #$0001    restore value for comparison
                    tfr       d,x       point x at the write position
                    ldd       ,s        get the character argument
                    stb       ,x        store the byte into the buffer
                    ldd       ,u        load the current buffer pointer
                    cmpd      $04,u     compare against the buffer end
                    bcc       PutFlushFull buffer full so go flush
                    ldd       $06,u     load the stream flags
                    clra                clear high byte
                    andb      #$40      test the line-buffered bit
                    lbeq      LoadRetVal not line buffered so done
                    ldd       ,s        reload the character
                    cmpd      #$000D    is it a carriage return
                    lbne      LoadRetVal not a newline so done
PutFlushFull        tfr       u,d       stream pointer into d
                    lbsr      FlushBuffer flush the buffer to the file
                    std       -$02,s    save the flush result
                    lbne      StreamErr flush failed so bail out
                    lbra      LoadRetVal otherwise return

                    pshs      u         save the stream pointer
                    tfr       d,u       value into u
                    ldd       $04,s     fetch the argument
                    pshs      d         push it
                    pshs      u         push the stream
                    ldd       #$0008    element size eight
                    lbsr      LsrEntry  scale the index
                    lbsr      EmitFloatField call the write helper
                    leas      2,s        drop the argument
                    ldd       $04,s     reload the argument
                    pshs      d         push it
                    tfr       u,d       stream into d
                    lbsr      EmitFloatField call the write helper again
                    lbra      StreamRet return via shared epilogue

FlushAllStreams     pshs      u,d       save registers
                    leau      DefaultInputHandle,y   point at the FILE table base
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        initialise the loop counter
                    bra       FlushCountTest enter the loop test

FlushEntryLoop      tfr       u,d       current stream into the argument
                    leau      $0d,u     advance to the next FILE entry
                    bsr       CloseStream flush and close this stream
FlushCountTest      ldd       ,s        load the loop counter
                    addd      #$0001    increment it
                    std       ,s        store it back
                    subd      #$0001    recover the pre-increment value
                    cmpd      #$0010    done all sixteen files
                    blt       FlushEntryLoop loop for the next stream
                    bra       StreamRet return via shared epilogue

CloseStream         pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    leas      -2,s       reserve a local
                    cmpu      #$0000    is the stream null
                    beq       StreamErr yes so return error
                    ldd       $06,u     load the flags
                    bne       StreamActive in-use stream so process it
StreamErr           ldd       #$FFFF    error result FFFF
                    bra       StreamRet return

StreamActive        ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$02      test the dirty write bit
                    beq       NoFlush   clean so skip the flush
                    tfr       u,d       stream into the argument
                    bsr       FlushWrite flush the write buffer
                    bra       StoreFlushResult continue

NoFlush             clra                clear high byte
                    clrb                result zero
StoreFlushResult    std       ,s        save the flush result
                    ldd       $08,u     load the file descriptor
                    lbsr      CloseByPathB close the file
                    clra                clear high byte
                    clrb                clear low byte
                    std       $06,u     mark the stream closed
LoadRetVal          ldd       ,s        load the return value
StreamRet           leas      2,s        drop the local
                    puls      pc,u      restore and return

FlushWrite          pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    cmpu      #$0000    is the stream null
                    beq       FlushWriteErr yes so error
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$22      mask the write and dirty bits
                    cmpd      #$0002    writable and dirty
                    beq       DoFlushWrite yes so flush it
FlushWriteErr       ldd       #$FFFF    error result FFFF
                    puls      pc,u      return

DoFlushWrite        ldd       $06,u     load the flags
                    anda      #$80      test the buffer-initialized bit
                    clrb                clear low byte
                    std       -$02,s    save the flag test
                    bne       FlushWriteCall already set up
                    tfr       u,d       stream into the argument
                    lbsr      InitBuffer initialise the buffer first
FlushWriteCall      tfr       u,d       stream into the argument
                    bsr       FlushBuffer flush the buffer to the file
                    puls      pc,u      return

FlushBuffer         pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    leas      -4,s       reserve locals
                    ldd       $06,u     load the flags
                    anda      #$01      test the read-mode bit
                    clrb                clear low byte
                    std       -$02,s    save the flag test
                    bne       BufferUsed read mode so skip write-back
                    ldd       ,u        load the current pointer
                    cmpd      $04,u     equals the end pointer
                    beq       BufferUsed nothing buffered so skip
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero offset
                    tfr       u,d       stream into the argument
                    lbsr      FloatNormalize get the buffer bounds
                    ldd       $02,x     buffer end pointer
                    pshs      d         push it
                    ldd       ,x        buffer start pointer
                    pshs      d         push it
                    ldd       $08,u     load the file descriptor
                    lbsr      SeekFile  write the buffer to the file
                    leas      6,s        drop the arguments
BufferUsed          ldd       ,u        load the current pointer
                    subd      $02,u     minus base gives bytes used
                    std       $02,s     save the count
                    lbeq      ResetBuffer nothing there so reset
                    ldd       $06,u     load the flags
                    anda      #$01      test the read-mode bit
                    clrb                clear low byte
                    std       -$02,s    save the flag test
                    lbeq      ResetBuffer write mode so reset buffer
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the device bit
                    beq       WriteBuffer plain file so write it out
                    ldd       $02,u     buffer base pointer
                    bra       UpdatePtr go update the pointer

ReadFillLoop        ldd       $02,s     remaining byte count
                    pshs      d         push it
                    ldd       ,u        current pointer
                    pshs      d         push it
                    ldd       $08,u     file descriptor
                    lbsr      WriteLnFile read a partial fill from the fd
                    leas      4,s        drop the arguments
                    std       ,s        save bytes read
                    cmpd      #$FFFF    read error
                    bne       ReadAdvance no so continue
                    leax      $04,s     point at the error slot
                    bra       WriteErrAdj handle the error

ReadAdvance         ldd       $02,s     remaining count
                    subd      ,s        minus bytes read
                    std       $02,s     save the remainder
                    ldd       ,u        current pointer
                    addd      ,s        advance by bytes read
UpdatePtr           std       ,u        store the updated pointer
                    ldd       $02,s     remaining count
                    bne       ReadFillLoop more to read so loop
                    bra       ResetBuffer done so reset the buffer

WriteBuffer         ldd       $02,s     byte count
                    pshs      d         push it
                    ldd       $02,u     buffer base pointer
                    pshs      d         push it
                    ldd       $08,u     file descriptor
                    lbsr      WriteFile write the whole buffer out
                    leas      4,s        drop the arguments
                    cmpd      $02,s     all bytes written
                    beq       ResetBuffer yes so reset
                    bra       SetIoErr  short write so mark error

WriteErrAdj         leas      -$04,x    stack fixup on error
SetIoErr            ldd       $06,u     load the flags
                    orb       #$20      set the error flag
                    std       $06,u     store the flags
                    ldd       $04,u     end pointer
                    std       ,u        reset current to end
                    ldd       #$FFFF    return EOF
                    bra       FlushBufRet return from the flush

ResetBuffer         ldd       $06,u     load the flags
                    ora       #$01      set the read-mode bit
                    std       $06,u     store the flags
                    ldd       $02,u     buffer base pointer
                    std       ,u        reset current pointer to base
                    addd      $0b,u     plus the buffer size
                    std       $04,u     set the end pointer
                    clra                clear high byte
                    clrb                success result zero
FlushBufRet         leas      4,s        drop the locals
                    puls      pc,u      return

                    pshs      u,d       save registers
                    ldd       ,s        load the character
                    leax      CharacterTypeTable,y   point at the ctype table
                    leax      d,x       index by the character
                    ldb       ,x        load the ctype flags
                    clra                clear high byte
                    andb      #$04      test the lowercase bit
                    beq       CharUnchanged not lowercase so unchanged
                    ldd       ,s        load the character
                    clra                clear high byte
                    andb      #$DF      clear bit five for uppercase
                    bra       CharRet   return the converted char

ToLower             pshs      u,d       save registers
                    ldd       ,s        load the character
                    leax      CharacterTypeTable,y   point at the ctype table
                    leax      d,x       index by the character
                    ldb       ,x        load the ctype flags
                    clra                clear high byte
                    andb      #$02      test the uppercase bit
                    beq       CharUnchanged not uppercase so unchanged
                    ldd       ,s        load the character
                    orb       #$20      set bit five for lowercase
                    bra       CharRet   return the converted char

CharUnchanged       ldd       ,s        return the character unchanged
CharRet             leas      2,s        drop the local
                    puls      pc,u      restore and return

GetChar             pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    cmpu      #$0000    is the stream null
                    beq       GetCharEof yes so return EOF
                    ldd       $06,u     load the flags
                    anda      #$01      isolate the eof/error bit
                    clrb                clear low byte
                    std       -$02,s    save the flag test
                    beq       GetCharRead stream usable so fetch a byte
GetCharEof          ldd       #$FFFF    return EOF
                    puls      pc,u      restore and return

GetCharRead         ldd       ,u        load the current pointer
                    cmpd      $04,u     at the buffer end
                    bcc       GetCharRefill yes so refill the buffer
                    addd      #$0001    advance the pointer
                    std       ,u        store it
                    subd      #$0001    back to the byte address
                    tfr       d,x       pointer into x
                    ldb       ,x        fetch the byte
                    clra                clear high byte
                    bra       GetCharRet return the character

GetCharRefill       tfr       u,d       stream into the argument
                    lbsr      FillBuffer refill the buffer and get a byte
GetCharRet          puls      pc,u      restore and return

                    pshs      u,d       save registers
                    ldu       $06,s     load the FILE pointer argument
                    lbeq      FillEof   null stream so error
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$01      test the readable bit
                    lbeq      FillEof   not readable so fail
                    ldd       ,s        load the pushback character
                    cmpd      #$FFFF    is it EOF
                    lbeq      FillEof   cannot push EOF so fail
                    ldd       ,u        current pointer
                    cmpd      $02,u     at the buffer base
                    lbls      FillEof   no room to push back
                    ldd       ,u        current pointer
                    addd      #$FFFF    decrement it
                    std       ,u        store it
                    tfr       d,x       pointer into x
                    ldd       ,s        the pushback character
                    stb       ,x        store the pushed-back byte
                    lbra      FillRet   return the character

                    pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    leas      -4,s       reserve locals
                    tfr       u,d       stream into the argument
                    lbsr      GetChar   read the first byte
                    std       $02,s     save it
                    cmpd      #$FFFF    end of file
                    beq       GetWordEof yes so return EOF
                    tfr       u,d       stream into the argument
                    lbsr      GetChar   read the second byte
                    std       ,s        save it
                    cmpd      #$FFFF    end of file
                    bne       CombineBytes no so combine the bytes
GetWordEof          ldd       #$FFFF    return EOF
                    bra       GetWordRet return

CombineBytes        ldd       $02,s     first byte
                    pshs      d         push it
                    ldd       #$0008    shift count eight
                    lbsr      AslEntry  shift it left one byte
                    addd      ,s        add the second byte
GetWordRet          leas      4,s        drop the locals
                    puls      pc,u      return the word

FillBuffer          pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    leas      -2,s       reserve a local
                    ldd       $06,u     load the flags
                    anda      #$80      test the initialized bit
                    andb      #$31      mask the state bits
                    cmpd      #$8001    initialized and readable
                    beq       FillCheckStdin yes so read
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$31      mask the state bits
                    cmpd      #$0001    readable but not set up
                    lbne      FillEof   invalid state so error
                    tfr       u,d       stream into the argument
                    lbsr      InitBuffer initialise the buffer
FillCheckStdin      leax      DefaultInputHandle,y   point at the stdin table entry
                    pshs      x         push it
                    cmpu      ,s++      is this stdin
                    bne       FillDoRead no so just read
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the device bit
                    beq       FillDoRead not a tty so just read
                    leax      CommandEchoBuffer,y   point at the stdout entry
                    tfr       x,d       stdout into the argument
                    lbsr      FlushWrite flush stdout before reading tty
FillDoRead          ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$08      test the buffered bit
                    beq       FillUnbuffered unbuffered so read one byte
                    ldd       $0b,u     buffer size
                    pshs      d         push it
                    ldd       $02,u     buffer base pointer
                    pshs      d         push it
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the device bit
                    beq       PickFileRead plain file read
                    leax      ReadLnFile,pcr select the tty read routine
                    bra       CallReadFn go call it

PickFileRead        leax      ReadFile,pcr select the file read routine
CallReadFn          tfr       x,d       routine into d
                    tfr       d,x       routine into x
                    ldd       $08,u     load the file descriptor
                    jsr       ,x        call the read routine
                    bra       FillCheckResult check the result

FillUnbuffered      ldd       #$0001    one byte for unbuffered read
                    pshs      d         push it
                    leax      $0a,u     point at the inline byte buffer
                    stx       $02,u     set buffer base to it
                    pshs      x         push the buffer pointer
                    ldd       $08,u     load the file descriptor
                    lbsr      ReadFile  read a single byte
FillCheckResult     leas      4,s        drop the arguments
                    std       ,s        save bytes read
                    ldd       ,s        load bytes read
                    bgt       FillGotData got data so proceed
                    ldd       $06,u     load the flags
                    pshs      d         push them
                    ldd       $02,s     the bytes-read result
                    beq       SetEofFlag zero bytes means eof
                    ldd       #$0020    otherwise an error flag
                    bra       MergeIoFlag merge it

SetEofFlag          ldd       #$0010    eof flag
MergeIoFlag         ora       ,s+       merge into the flags high byte
                    orb       ,s+       merge into the flags low byte
                    std       $06,u     store the updated flags
FillEof             ldd       #$FFFF    return EOF
                    bra       FillRet   return

FillGotData         ldd       $02,u     buffer base pointer
                    addd      #$0001    advance past the first byte
                    std       ,u        set the current pointer
                    ldd       $02,u     buffer base pointer
                    addd      ,s        plus bytes read
                    std       $04,u     set the end pointer
                    ldb       [$02,u]   fetch the first byte
                    clra                clear high byte
FillRet             leas      2,s        drop the local
                    puls      pc,u      restore and return

InitBuffer          pshs      u         save the stream pointer
                    tfr       d,u       FILE pointer into u
                    ldd       #$FF98    status request code
                    lbsr      stkcheck  query the file descriptor status
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$C0      buffer type already known
                    bne       SetInitFlag yes so skip the stat
                    leas      -34,s      reserve the fd data block
                    leax      ,s        point at the block
                    pshs      x         push the pointer
                    ldd       $08,u     load the file descriptor
                    lbsr      GetStatOpt get the file descriptor sector
                    leas      2,s        drop the pointer
                    ldd       $06,u     load the flags
                    pshs      d         push them
                    ldb       $02,s     the device type byte
                    bne       MarkDevice nonzero so it is a device
                    ldd       #$0040    mark as a regular file
                    bra       StoreTypeFlag merge the flag

MarkDevice          ldd       #$0080    mark as a device
StoreTypeFlag       ora       ,s+       merge into the flags high byte
                    orb       ,s+       merge into the flags low byte
                    std       $06,u     store the flags
                    leas      34,s       drop the fd data block
SetInitFlag         ldd       $06,u     load the flags
                    ora       #$80      set the buffer-initialized bit
                    std       $06,u     store the flags
                    clra                clear high byte
                    andb      #$0C      buffer already allocated
                    beq       SizeBuffer no so allocate one
                    puls      pc,u      already done so return

SizeBuffer          ldd       $0b,u     buffer size field
                    bne       AllocBuffer already sized
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      test the device bit
                    beq       FileBufSize file so use larger size
                    ldd       #$0080    device buffer size 128
                    bra       StoreBufSize store it

FileBufSize         ldd       #$0100    file buffer size 256
StoreBufSize        std       $0b,u     store the buffer size
AllocBuffer         ldd       $02,u     buffer base pointer
                    bne       SetBuffered already allocated
                    ldd       $0b,u     buffer size
                    lbsr      ClearToLimit allocate the buffer
                    std       $02,u     store the buffer base
                    cmpd      #$FFFF    allocation failed
                    beq       UseInlineBuf yes so use inline buffer
SetBuffered         ldd       $06,u     load the flags
                    orb       #$08      set the buffered flag
                    std       $06,u     store the flags
                    bra       SetEndPtr go set the pointers

UseInlineBuf        ldd       $06,u     load the flags
                    orb       #$04      set the unbuffered flag
                    std       $06,u     store the flags
                    leax      $0a,u     point at the inline byte buffer
                    stx       $02,u     set buffer base to it
                    ldd       #$0001    size one
                    std       $0b,u     store it
SetEndPtr           ldd       $02,u     buffer base pointer
                    addd      $0b,u     plus the buffer size
                    std       $04,u     set the end pointer
                    std       ,u        set the current pointer
                    puls      pc,u      restore and return

GetFormatArg        pshs      u,d       save registers
                    ldb       $01,s     high byte of the first argument
                    sex                 sign extend it
                    tfr       d,x       value into x
                    bra       CheckConvSpec enter the conversion

AdvanceArgPtr       ldd       [$06,s]   dereference the argument pointer
                    addd      #$0004    advance by four bytes
                    std       [$06,s]   store the stepped pointer back
                    leax      >StrLenThunk,pcr load pointer to the strlen thunk
                    bra       ConvReturn join the conversion return path

SetDefaultBase      ldb       $01,s     get the default base byte
                    stb       FmtBuf+$01,y store it into the format buffer
                    leax      FmtBuf,y  point at the format buffer
ConvReturn          tfr       x,d       move buffer pointer to return register
                    bra       ConvExit  go return from conversion

CheckConvSpec       cmpx      #$0064    is the conversion specifier 'd'
                    beq       AdvanceArgPtr handle decimal conversion
                    cmpx      #$006F    is the conversion specifier 'o'
                    lbeq      AdvanceArgPtr handle octal conversion
                    cmpx      #$0078    is the conversion specifier 'x'
                    lbeq      AdvanceArgPtr handle hex conversion
                    bra       SetDefaultBase fall back to the default base

ConvExit            leas      2,s        drop the locals
                    puls      pc,u      return from conversion

StrLenThunk         neg       $0034     pointer thunk fragment byte
                    nega                pointer thunk fragment byte
                    leax      >StrLen,pcr point at the strlen routine
                    tfr       x,d       return that pointer
                    puls      pc,u      return to caller

StrLen              neg       $0034     entry fragment byte
                    rora                entry fragment byte
                    ldu       ,s        load the string pointer
StrLenLoop2         ldb       ,u+       read the next byte
                    bne       StrLenLoop2 loop until the nul
                    tfr       u,d       take the end pointer
                    subd      ,s        subtract the start pointer
                    addd      #$FFFF    minus one for the nul
                    leas      2,s        drop the locals
                    puls      pc,u      return the length

StrCopy             pshs      u,d       save args for strcpy
                    ldu       $06,s     load the source pointer
                    leas      -2,s       make a local for the cursor
                    ldd       $02,s     load the destination pointer
                    std       ,s        save the running cursor
StrCopyLoop         ldb       ,u+       read a source byte
                    ldx       ,s        fetch the dest cursor
                    leax      $01,x     advance the cursor
                    stx       ,s        save the cursor
                    stb       -$01,x    store the byte to dest
                    bne       StrCopyLoop loop until the nul is copied
                    bra       StrCopyDone return the destination

StrCat              pshs      u,d       save args for strcat
                    ldu       $06,s     load the source pointer
                    leas      -2,s       make a local for the cursor
                    ldd       $02,s     load the destination pointer
                    std       ,s        save the running cursor
StrCatEndLoop       ldx       ,s        fetch the dest cursor
                    leax      $01,x     advance the cursor
                    stx       ,s        save the cursor
                    ldb       -$01,x    read a dest byte
                    bne       StrCatEndLoop find the end of the destination
                    ldd       ,s        take the end pointer
                    addd      #$FFFF    back up over the nul
                    std       ,s        save the append point
StrCatCopyLoop      ldb       ,u+       read a source byte
                    ldx       ,s        fetch the append cursor
                    leax      $01,x     advance the cursor
                    stx       ,s        save the cursor
                    stb       -$01,x    store the byte
                    bne       StrCatCopyLoop loop until the nul is copied
StrCopyDone         ldd       $02,s     return the destination pointer
                    leas      4,s        drop the locals
                    puls      pc,u      return to caller

StrCmp              pshs      u         save u for strcmp
                    tfr       d,u       set u to the first string
                    bra       StrCmpLoop enter the compare loop

StrCmpNext          ldx       $04,s     advance the cursor
                    leax      $01,x     save the cursor
                    stx       $04,s     read a second-string byte
                    ldb       -$01,x    continue if not nul
                    bne       StrCmpAdv strings matched
                    clra                return zero
                    clrb                return to caller
                    puls      pc,u      advance the first string pointer

StrCmpAdv           leau      $01,u     read a first-string byte
StrCmpLoop          ldb       ,u        sign extend to a word
                    sex                 save the first byte
                    pshs      d         read the second-string byte
                    ldb       [$06,s]   sign extend to a word
                    sex                 compare the two bytes
                    cmpd      ,s++      equal so keep comparing
                    beq       StrCmpNext sign extend the second byte
                    sex                 save the second value
                    pshs      d         reload the first byte
                    ldb       ,u        sign extend to a word
                    sex                 compute first minus second
                    subd      ,s++      return the difference
                    puls      pc,u

StrNCpy             pshs      u,d       save args for strncpy
                    ldu       $06,s     load the source pointer
                    leas      -2,s       make a local for the cursor
                    ldd       $02,s     load the destination pointer
                    std       ,s        save the running cursor
StrNCpyLoop         ldd       $0a,s     load the remaining count
                    addd      #$FFFF    decrement the count
                    std       $0a,s     save the count
                    subd      #$FFFF    test the original count
                    ble       StrNCpyPadLoop done if the count is exhausted
                    ldb       ,u+       read a source byte
                    ldx       ,s        fetch the dest cursor
                    leax      $01,x     advance the cursor
                    stx       ,s        save the cursor
                    stb       -$01,x    store the byte
                    bne       StrNCpyLoop loop while not the nul
                    bra       StrNCpyPadLoop go pad the remainder

StrNCpyPad          clra                pad byte
                    clrb                fetch the dest cursor
                    ldx       ,s        advance the cursor
                    leax      $01,x     save the cursor
                    stx       ,s        store the nul pad
                    stb       -$01,x    load the remaining count
StrNCpyPadLoop      ldd       $0a,s     decrement the count
                    addd      #$FFFF    save the count
                    std       $0a,s     test the count
                    subd      #$FFFF    keep padding while count remains
                    bgt       StrNCpyPad return the destination
                    lbra      StrNCatDone

StrNCmp             pshs      u         save u for strncmp
                    tfr       d,u       set u to the first string
                    bra       StrNCmpLoop enter the compare loop

StrNCmpNext         ldx       $04,s     advance the cursor
                    leax      $01,x     save the cursor
                    stx       $04,s     read a second-string byte
                    ldb       -$01,x    continue if not nul
                    bne       StrNCmpAdv strings matched
                    clra                return zero
                    clrb                return to caller
                    puls      pc,u      advance the first string pointer

StrNCmpAdv          leau      $01,u     load the remaining count
StrNCmpLoop         ldd       $06,s     decrement the count
                    addd      #$FFFF    save the count
                    std       $06,s     test the count
                    subd      #$FFFF    stop when the count is exhausted
                    ble       StrNCmpDiff read a first-string byte
                    ldb       ,u        sign extend to a word
                    sex                 save the first byte
                    pshs      d         read the second-string byte
                    ldb       [$06,s]   sign extend to a word
                    sex                 compare the two bytes
                    cmpd      ,s++      equal so keep comparing
                    beq       StrNCmpNext reload the count
StrNCmpDiff         ldd       $06,s     if count remains compute difference
                    bge       StrNCmpCalc count exhausted
                    clra                return zero
                    clrb                go return
                    bra       StrNCmpDone read the second-string byte

StrNCmpCalc         ldb       [$04,s]   save the second value
                    sex                 read the first-string byte
                    pshs      d         sign extend to a word
                    ldb       ,u        compute first minus second
                    sex                 return the result
                    subd      ,s++
StrNCmpDone         puls      pc,u      save args for strncat

                    pshs      u,d       load the source pointer
                    ldu       $06,s     make a local for the cursor
                    leas      -2,s       load the destination pointer
                    ldd       $02,s     save the running cursor
                    std       ,s        fetch the dest cursor
StrNCatEndLoop      ldx       ,s        advance the cursor
                    leax      $01,x     save the cursor
                    stx       ,s        read a dest byte
                    ldb       -$01,x    find the end of the destination
                    bne       StrNCatEndLoop take the end pointer
                    ldd       ,s        back up over the nul
                    addd      #$FFFF    save the append point
                    std       ,s        load the remaining count
StrNCatCopyLoop     ldd       $0a,s     decrement the count
                    addd      #$FFFF    save the count
                    std       $0a,s     test the count
                    subd      #$FFFF    stop when count is exhausted
                    ble       StrNCatTerm read a source byte
                    ldb       ,u+       fetch the append cursor
                    ldx       ,s        advance the cursor
                    leax      $01,x     save the cursor
                    stx       ,s        store the byte
                    stb       -$01,x    loop while not the nul
                    bne       StrNCatCopyLoop reload the count
StrNCatTerm         ldd       $0a,s     skip terminator if count exhausted
                    bge       StrNCatDone zero half
                    clra                nul terminator
                    clrb                write the nul at the cursor
                    stb       [,s]      return the destination
StrNCatDone         ldd       $02,s     drop the locals
                    leas      4,s        return to caller
                    puls      pc,u

CopyOS9Name         pshs      u,d       save args for the os9 name copy
                    ldu       ,s        load the destination pointer
CopyOS9NameLoop     ldx       $06,s     fetch the source cursor
                    leax      $01,x     advance the cursor
                    stx       $06,s     save the cursor
                    ldb       -$01,x    read a source byte
                    stb       ,u+       store it to the destination
                    bgt       CopyOS9NameLoop loop while the high bit is clear
                    ldb       -$01,u    get the last stored byte
                    clra                clear the high half
                    andb      #$7f      strip the high bit terminator
                    stb       -$01,u    store the cleaned byte
                    clra                zero half
                    clrb                nul byte
                    stb       ,u        terminate the c string
                    ldd       ,s        return the destination
                    leas      2,s        drop the local
                    puls      pc,u      return to caller

GrowHeap            pshs      u,d       save args for the heap grow
                    leas      -4,s       make locals
                    ldd       $04,s     load the requested size
                    addd      #$00FF    round up to a page boundary
                    pshs      d         save the rounded size
                    ldd       #$0008    shift count of eight
                    lbsr      LsrEntry  shift right into page units
                    pshs      d         save the page count
                    ldd       #$0008    shift count of eight
                    lbsr      AslEntry  mask the low bits
                    std       ,s        save the value
                    aslb                multiply by four
                    rola                carry into high half
                    aslb                multiply again
                    rola                carry into high half
                    lbsr      GrowHeap2 request memory from the system
                    tfr       d,u       pointer to the new block
                    cmpu      #$FFFF    did the allocation fail
                    bne       GrowHeapOk got the memory
                    clra                return null
                    clrb                return null
                    bra       GrowHeapDone go finish

GrowHeapOk          stu       $02,s     save the block pointer
                    ldd       ,s        load the block size
                    ldx       $02,s     reload the block pointer
                    std       $02,x     store size in the block header
                    tfr       x,d       copy the pointer
                    addd      #$0004    skip past the header
                    lbsr      Free      add the block to the free list
                    ldd       FreeListHead,y   return the heap head
GrowHeapDone        leas      6,s        drop the locals
                    puls      pc,u      return to caller

Malloc              pshs      u,d       save args for malloc
                    leas      -6,s       make locals
                    ldd       $06,s     load the requested size
                    addd      #$0003    round the size up
                    lsra                divide by four
                    rorb                rotate low half
                    lsra                divide again
                    rorb                rotate low half
                    addd      #$0001    add the header unit
                    std       ,s        save the unit count
                    ldd       FreeListHead,y   load the free list head
                    std       $04,s     save as the current pointer
                    bne       MallocScanStart list not empty so search it
                    leax      BaseBlock,y   point at the base block
                    stx       $04,s     set it as current
                    tfr       x,d       copy the pointer
                    std       FreeListHead,y   initialise the free list head
                    std       BaseBlock,y   self-link the base block
                    clra                zero half
                    clrb                zero half
                    std       BaseBlockSize,y   clear the base block size
MallocScanStart     ldu       [$04,s]   load the first free block
MallocScanLoop      ldd       $02,u     load the block size
                    cmpd      ,s        compare it to the request
                    bcs       MallocCheckWrap too small so try next
                    cmpd      ,s        compare it to the request
                    bne       MallocSplit bigger so split it
                    ldd       ,u        exact fit so take next link
                    std       [$04,s]   unlink the block
                    bra       MallocReturn go return it

MallocSplit         subd      ,s        shrink the remaining size
                    std       $02,u     store it back
                    aslb                size to bytes
                    rola                carry into high half
                    aslb                size to bytes
                    rola                carry into high half
                    leau      d,u       advance to the tail chunk
                    ldd       ,s        load the request size
                    std       $02,u     set the allocated size
MallocReturn        ldd       $04,s     take the current pointer
                    std       FreeListHead,y   update the roving pointer
                    pshs      u         save the block
                    ldd       #$0004    header offset
                    addd      ,s++      point past the header
                    bra       MallocDone go return the pointer

MallocCheckWrap     cmpu      FreeListHead,y   wrapped around the free list
                    bne       MallocNext no so try the next block
                    ldd       ,s        load the request size
                    lbsr      GrowHeap  grow the heap from the system
                    tfr       d,u       pointer to the new block
                    stu       -$02,s    save it
                    bne       MallocNext retry the search
                    clra                out of memory
                    clrb                return null
                    bra       MallocDone go finish

MallocNext          stu       $04,s     advance the current pointer
                    ldu       ,u        load the next block
                    bra       MallocScanLoop continue the search

MallocDone          leas      8,s        drop the locals
                    puls      pc,u      return to caller

Free                pshs      u,d       save args for free
                    leas      -2,s       make a local
                    ldd       $02,s     load the pointer to free
                    addd      #$FFFC    back up to the block header
                    tfr       d,u       set u to the block header
                    ldd       FreeListHead,y   load the free list head
                    bra       FreeScanTest enter the scan

FreeScanLoop        ldd       ,s        load the current block
                    cmpd      [,s]      compare it with the next
                    bcs       FreeScanNext insertion point found
                    pshs      d         save the current block
                    cmpu      ,s++      is the freed block above current
                    bhi       FreeMergeNext insert here
                    cmpu      [,s]      is the freed block below next
                    bcs       FreeMergeNext insert here
FreeScanNext        ldd       [,s]      advance to the next block
FreeScanTest        std       ,s        save the current pointer
                    cmpu      ,s        freed block past current
                    bls       FreeScanLoop keep scanning
                    cmpu      [,s]      freed block below next
                    lbcc      FreeScanLoop keep scanning
FreeMergeNext       pshs      u         save the current block
                    ldd       $02,u     load the block size
                    aslb                size to bytes
                    rola                carry into high half
                    aslb                size to bytes
                    rola                carry into high half
                    addd      ,s++      compute the block end
                    cmpd      [,s]      adjacent to the next block
                    bne       FreeLinkNext not adjacent
                    ldd       $02,u     get the next block link
                    pshs      d         save it
                    ldx       [$02,s]   load the next block
                    ldd       $02,x     its size
                    addd      ,s++      merge the sizes
                    std       $02,u     store the merged size
                    ldd       ,x        take the next block link
                    bra       FreeSetLink go set the link

FreeLinkNext        ldd       [,s]      take the next block link
FreeSetLink         std       ,u        link the freed block in
                    ldx       ,s        take the current block
                    ldd       $02,x     its size
                    aslb                size to bytes
                    rola                carry into high half
                    aslb                size to bytes
                    rola                carry into high half
                    addd      ,s        compute the current block end
                    pshs      d         save it
                    cmpu      ,s++      freed block adjacent below
                    bne       FreeLinkPrev not adjacent
                    ldd       $02,x     current block size
                    addd      $02,u     merge with the freed size
                    std       $02,x     store the merged size
                    ldd       ,u        take the freed block link
                    std       ,x        relink it
                    bra       FreeUpdateHead go update the head

FreeLinkPrev        stu       ,x        link the freed block
FreeUpdateHead      tfr       x,d       copy the pointer
                    std       FreeListHead,y   update the free list head
                    bra       CallocDone return to caller

                    pshs      u,d       save args for calloc
                    leas      -2,s       make a local
                    ldd       $02,s     load the element size
                    pshs      d         save it
                    ldd       $0a,s     load the element count
                    lbsr      MulEntry  multiply size by count
                    std       ,s        total byte size
                    lbsr      Malloc    allocate the block
                    tfr       d,u       take the pointer
                    stu       -$02,s    save the pointer
                    beq       CallocRet allocation failed
                    ldd       ,s        load the total size
                    pshs      d         save it
                    tfr       u,d       pointer as an argument
                    bsr       ZeroFill  zero the block
                    leas      2,s        drop the argument
CallocRet           tfr       u,d       return the pointer
CallocDone          leas      4,s        drop the locals
                    puls      pc,u      return to caller

ZeroFill            pshs      u         save u for the zero fill
                    tfr       d,u       set u to the buffer
                    bra       ZeroFillTest enter the loop

ZeroFillLoop        clra                zero half
                    clrb                store a zero byte
                    stb       ,u+       load the remaining count
ZeroFillTest        ldd       $04,s     decrement the count
                    addd      #$FFFF    save the count
                    std       $04,s     test the count
                    subd      #$FFFF    loop until done
                    bne       ZeroFillLoop return to caller
                    puls      pc,u

                    tfr       d,x       path name pointer for the open
                    lda       $03,s     load the access mode
                    os9       I$Open    try to open the file
                    bcc       CloseByPath opened so close it
                    bra       IoReturn  return the status

OpenFile2           tfr       d,x       path name pointer
                    lda       $03,s     load the access mode
                    os9       I$Open    open the file
                    bcs       FailReturn error exit
                    tfr       a,b       path number to b
                    clra                clear the error half
                    rts                 return the path

CloseByPathB        tfr       b,a       path number to a for close
CloseByPath         os9       I$Close   close the file
IoReturn            lbra      CheckStatus jump to the shared io return

                    tfr       d,x       path name pointer for mkdir
                    ldb       $03,s     load the access mode
                    os9       I$MakDir  make the directory
                    bra       IoReturn  return the status

CreateFile          pshs      d         save the name pointer
                    ldx       ,s        path name pointer
                    lda       $05,s     load the mode byte
                    tfr       a,b       copy the mode
                    andb      #$24      mask the access bits
                    orb       #$0b      add the create attributes
                    os9       I$Create  create the file
                    bcs       CreateExists error so maybe it exists
CreateOk            leas      2,s        drop the local
                    tfr       a,b       path number to b
                    clra                clear the error half
                    rts                 return the path

CreateExists        cmpb      #$DA      was it already existing
                    bne       SetSizeCleanup other error so fail
                    lda       $05,s     reload the mode
                    bita      #$80      exclusive create requested
                    bne       SetSizeCleanup fail if exclusive
                    anda      #$07      mask to the access mode
                    ldx       ,s        path name pointer
                    os9       I$Open    open the existing file
                    bcs       SetSizeCleanup open failed
                    pshs      u,a       save registers before setstt
                    ldx       #$0000    size high word is zero
                    leau      ,x        size low word is zero
                    ldb       #$02      SS.Size setstt code
                    os9       I$SetStt  truncate the file to zero
                    puls      u,a       restore registers
                    bcc       CreateOk  branch if truncate succeeded
                    pshs      b         save the error code
                    os9       I$Close   close the file on failure
                    puls      b         restore the error code
SetSizeCleanup      leas      2,s        drop the local slot
FailReturn          lbra      SetErrnoFail return failure

                    tfr       d,x       pathname pointer into x
                    lda       $03,s     access mode argument
                    ldb       $05,s     file attributes argument
                    os9       I$Create  create the file
                    lbcs      SetErrnoFail error out on failure
                    tfr       a,b       path number into b
                    clra                clear the high byte
                    rts                 return the path number
                    tfr       d,x       pathname pointer into x
                    os9       I$Delete  delete the named file
                    bra       IoReturn  return via shared status check

                    tfr       b,a       path number into a
                    os9       I$Dup     duplicate the path
                    bcs       FailReturn error out on failure
                    tfr       a,b       new path number into b
                    clra                clear the high byte
                    rts                 return the new path number

ReadFile            pshs      y         save y
                    tfr       b,a       path number into a
                    ldx       $04,s     buffer pointer argument
                    ldy       $06,s     byte count argument
                    os9       I$Read    read from the file
                    bra       ReadResult join the read result handler

ReadLnFile          pshs      y         save y
                    tfr       b,a       path number into a
                    ldx       $04,s     buffer pointer argument
                    ldy       $06,s     byte count argument
                    os9       I$ReadLn  read a line from the file
ReadResult          bcc       IOReturnCount branch if the read succeeded
                    cmpb      #$D3      check for end-of-file error
                    bne       IOError   other error goes to failure
                    clra                return zero count at eof
                    clrb                clear the low byte
                    puls      pc,y      return zero bytes read

WriteFile           pshs      y         save y
                    ldy       $06,s     byte count argument
                    beq       IOReturnCount nothing to write
                    tfr       b,a       path number into a
                    ldx       $04,s     buffer pointer argument
                    os9       I$Write   write to the file
                    bra       WriteCheck join the write check

WriteLnFile         pshs      y         save y
                    ldy       $06,s     byte count argument
                    beq       IOReturnCount nothing to write
                    tfr       b,a       path number into a
                    ldx       $04,s     buffer pointer argument
                    os9       I$WritLn  write a line to the file
WriteCheck          bcs       IOError   error out on failure
IOReturnCount       tfr       y,d       return the actual byte count
                    puls      pc,y      return to caller

IOError             puls      y         restore y
                    lbra      SetErrnoFail return failure

SeekFile            pshs      u,d       save registers
                    ldd       $0a,s     load the whence argument
                    bne       SeekWhence nonzero whence
                    ldu       #$0000    base offset high is zero for seek-set
                    ldx       #$0000    base offset low is zero
                    bra       SeekCompute go compute the new position

SeekWhence          cmpd      #$0001    whence equals seek-cur
                    beq       SeekCur   take the current-position path
                    cmpd      #$0002    whence equals seek-end
                    beq       SeekEnd   take the file-size path
                    ldb       #$F7      bad whence error code
SeekErr             clra                clear the high byte
                    std       StreamPointer,y   store the errno
                    ldd       #$FFFF    return value is -1
                    leax      LongResult3,y   point at the long result temp
                    std       ,x        store -1 high word
                    std       $02,x     store -1 low word
                    leas      2,s        drop the local slot
                    puls      pc,u      return failure

SeekEnd             lda       $01,s     path number argument
                    ldb       #$02      SS.Size getstt code
                    os9       I$GetStt  get the file size for seek-end
                    bcs       SeekErr   error out on failure
                    bra       SeekCompute go compute the new position

SeekCur             lda       $01,s     path number argument
                    ldb       #$05      SS.Pos getstt code
                    os9       I$GetStt  get the current position for seek-cur
                    bcs       SeekErr   error out on failure
SeekCompute         tfr       u,d       base offset low word
                    addd      $08,s     add the requested offset low
                    tfr       d,u       new position low into u
                    tfr       x,d       base offset high word
                    adcb      $07,s     add the offset high with carry
                    adca      $06,s     propagate the carry
                    bmi       SeekErr   negative position is an error
                    tfr       d,x       new position high into x
                    stx       LongResult3,y   store the new position high
                    stu       ResultLow,y   store the new position low
                    lda       $01,s     path number argument
                    os9       I$Seek    seek to the new position
                    bcs       SeekErr   error out on failure
                    leax      LongResult3,y   point at the long result
                    leas      2,s        drop the local slot
                    puls      pc,u      return the new position

GrowHeap2           pshs      y,d       save registers
                    cmpd      UpdateFreeCount,y   compare requested size to free
                    bls       ClearBlock enough room already available
                    subd      UpdateFreeCount,y   extra bytes needed
                    addd      HeapTop,y   add to the current heap top
                    subd      $02,s     adjust by the base offset
                    os9       F$Mem     request more memory from the system
                    tfr       y,d       new memory size into d
                    ldy       $02,s     restore y
                    bcc       HeapGrown allocation succeeded
                    ldd       #$FFFF    return -1 on failure
                    leas      4,s        drop the locals
                    rts                 return failure

HeapGrown           ldx       HeapTop,y   old heap top pointer
                    std       HeapTop,y   store the new heap top
                    pshs      x         save old top on stack
                    subd      ,s++      growth is new minus old
                    addd      UpdateFreeCount,y   add growth to the free count
                    std       UpdateFreeCount,y   update the free count
ClearBlock          ldd       HeapTop,y   heap top pointer
                    subd      UpdateFreeCount,y   minus free gives the block base
                    tfr       d,x       block pointer into x
                    ldd       UpdateFreeCount,y   current free count
                    subd      ,s        minus the requested size
                    std       UpdateFreeCount,y   update the free count
                    ldd       ,s        requested size back into d
                    stx       ,s        save the block pointer
                    bitb      #$01      test for an odd byte count
                    beq       ClearEven even count skips the odd byte
                    clr       ,x+       zero the odd leading byte
                    decb                one fewer byte to clear
ClearEven           tfr       d,y       remaining byte count into y
                    leay      ,y        test the remaining count
                    beq       ClearDone nothing left to clear
                    clra                clear the high byte
                    clrb                zero fill value
ClearLoop           std       ,x++      clear two bytes at a time
                    leay      -AdvancePastPair,y    advance past the pair
                    bne       ClearLoop loop until the block is cleared
ClearDone           puls      pc,y,d    return the block pointer

ClearToLimit        addd      SizePointer,y   add size to the current pointer
                    bcs       ClearLimitErr overflow is an error
                    cmpd      Limit,y   compare against the limit
                    bcc       ClearLimitErr past the limit is an error
                    pshs      d         save the end pointer
                    ldx       SizePointer,y   current start pointer
                    clra                zero fill value
                    bra       ClearLimitTest enter the clear loop

ClearLimitLoop      sta       ,x+
ClearLimitTest      cmpx      ,s        reached the end pointer
                    bcs       ClearLimitLoop loop while below the end
                    ldd       SizePointer,y   reload the start pointer
                    puls      x         recover the end pointer
                    stx       SizePointer,y   update the stored pointer
                    rts                 return success

ClearLimitErr       ldd       #$FFFF    return -1 on failure
                    rts                 return failure

SendSignal          tfr       b,a       process id into a
                    ldb       $03,s     signal code argument
                    os9       F$Send    send a signal to the process
                    lbra      CheckStatus return the status

WaitChild           tfr       d,x       status buffer pointer into x
                    clra                clear the high byte
                    clrb                clear the low byte
                    os9       F$Wait    wait for a child to die
                    lbcs      SetErrnoFail error out on failure
                    stx       -$02,s    save status pointer and test for null
                    beq       WaitReturn no status buffer supplied
                    stb       $01,x     store the exit status low
                    clr       ,x        clear the status high byte
WaitReturn          tfr       a,b       child process id into b
                    clra                clear the high byte
                    rts                 return the child id
                    tfr       b,a       process id into a
                    ldb       $03,s     new priority argument
                    os9       F$SPrior  set the process priority
                    lbra      CheckStatus return the status

                    leau      $02,s     point at the argument block
                    leas      $00FF,y   reset the stack for chain
                    tfr       d,x       module name pointer into x
                    ldy       ,u        module name length
                    lda       $05,u     memory size field
                    asla                shift into the high nibble
                    asla                shift into the high nibble
                    asla                shift into the high nibble
                    asla                shift into the high nibble
                    ora       $07,u     combine the data size
                    ldb       $09,u     priority argument
                    ldu       $02,u     parameter pointer
                    os9       F$Chain   chain to the new program
                    os9       F$Exit    exit if chain returns
ForkProcess         pshs      u,y       save registers
                    tfr       d,x       module name pointer into x
                    ldy       $06,s     module name length
                    ldu       $08,s     parameter pointer
                    lda       $0b,s     language and type byte
                    ora       $0d,s     combine the data size
                    ldb       $0f,s     priority argument
                    os9       F$Fork    fork a new process
                    puls      u,y       restore registers
                    lbcs      SetErrnoFail error out on failure
                    tfr       a,b       child process id into b
                    clra                clear the high byte
                    rts                 return the child id

SetIntercept        pshs      u         save u
                    tfr       y,u       keep globals pointer in u
                    std       UserHandlerAddress,y   save the user handler address
                    leax      >InterceptEntry,pcr address of the intercept trampoline
                    os9       F$Icpt    install the signal intercept
                    puls      u         restore u
                    lbra      CheckStatus return the status

InterceptEntry      tfr       u,y       recover the globals pointer
                    clra                clear the high byte
                    jsr       [UserHandlerAddress,y] call the user signal handler
                    rti                 return from the intercept

GetStatOpt          tfr       b,a       path number into a
                    ldb       #$00      SS.Opt getstt code
                    ldx       $02,s     option buffer pointer
                    os9       I$GetStt  get the file status options
                    lbra      CheckStatus return the status

GetFileDesc         tfr       b,a       path number into a
                    ldb       #$0f      SS.FD getstt code
                    ldx       $02,s     descriptor buffer pointer
                    pshs      y         save y
                    ldy       $06,s     buffer size argument
                    os9       I$GetStt  read the file descriptor sector
                    puls      y         restore y
                    lbra      CheckStatus return the status

SetErrnoFail        clra                clear the high byte
                    std       StreamPointer,y   store the errno
                    ldd       #$FFFF    return value is -1
                    rts                 return failure

CheckStatus         bcs       SetErrnoFail carry means an error occurred
                    clra                clear the high byte
                    clrb                clear the low byte
                    rts                 return success

exit                pshs      d         save the exit code
                    lbsr      NullReturn call the empty flush stub
                    lbsr      FlushAllStreams flush buffers and clean up
                    puls      d         restore the exit code
_exit               os9       F$Exit    terminate the process
NullReturn          rts                 empty stub returns

LongAdd             ldd       $04,s     augend low word
                    addd      $02,x     add the addend low
                    std       ResultLow,y   store the result low
                    ldd       $02,s     augend high word
                    adcb      $01,x     add the addend high with carry
                    adca      ,x        propagate the carry
                    std       LongResult3,y   store the result high
                    lbra      LongResult2 return the long result pointer

LongSub             ldd       $04,s     minuend low word
                    subd      $02,x     subtract the subtrahend low
                    std       ResultLow,y   store the result low
                    ldd       $02,s     minuend high word
                    sbcb      $01,x     subtract the high with borrow
                    sbca      ,x        propagate the borrow
                    std       LongResult3,y   store the result high
                    lbra      LongResult2 return the long result pointer

LongCompare         ldd       $02,s     left high word
                    cmpd      ,x        compare to right high
                    bne       LongCmpDone high words differ
                    ldd       $04,s     left low word
                    cmpd      $02,x     compare to right low
                    beq       LongCmpDone the longs are equal
                    bcs       LongCmpLess left is less than right
                    lda       #$01      greater result value
                    andcc     #$FE      clear carry for greater
                    bra       LongCmpDone join the compare finish

LongCmpLess         clra
                    cmpa      #$01      set carry for less than
LongCmpDone         pshs      cc        save the comparison flags
                    ldd       $01,s     shuffle the return value
                    std       $05,s     store the return value
                    puls      cc        restore the comparison flags
                    leas      4,s        drop the compare args
                    rts                 return with flags set

LongNegate          lbsr      LoadLongTemp load the long into the temp
                    ldd       #$0000    zero for the negation
                    subd      $02,x     negate the low word
                    std       $02,x     store the negated low
                    ldd       #$0000    zero for the negation
                    sbcb      $01,x     negate the high with borrow
                    sbca      ,x        propagate the borrow
                    std       ,x        store the negated high
                    rts                 return to caller
                    ldd       ,x        long high word
                    coma                complement the high byte
                    comb                complement the low byte
                    std       LongResult3,y   store the complemented high
                    ldd       $02,x     long low word
                    coma                complement the high byte
                    comb                complement the low byte
                    leax      LongResult3,y   point at the long result
                    std       $02,x     store the complemented low
                    rts                 return to caller

LongFromByte        leax      LongResult3,y   point at the long result
                    std       $02,x     store the low word
                    tfr       a,b       value byte into b
                    sex                 sign-extend the byte
                    tfr       a,b       replicate the sign byte
                    std       ,x        store the sign-extended high
                    rts                 return to caller
                    leax      LongResult3,y   point at the long result
                    std       $02,x     store the low word
                    clr       ,x        clear the high byte
                    clr       $01,x     clear the high word
                    rts                 return to caller

CopyLong            pshs      y         save y
                    ldy       $04,s     destination pointer
                    ldd       ,x        source high word
                    std       ,y        store to the destination
                    ldd       $02,x     source low word
                    std       AdvancePastPair,y     store to the destination
                    puls      x         recover the source pointer
                    exg       y,x       swap the pointers back
                    puls      d         recover the return value
                    std       ,s        restore the stack slot
                    rts                 return to caller

LongResult2         tfr       cc,a      save the flags
                    puls      x         recover the saved pointer
                    stx       $02,s     store into the stack slot
                    leas      2,s        drop the local slot
                    leax      LongResult3,y   point at the long result
                    tfr       a,cc      restore the flags
                    rts                 return to caller

LoadLongTemp        ldd       ,x        long high word
                    std       LongResult3,y   store into the temp
                    ldd       $02,x     long low word
                    leax      LongResult3,y   point at the temp
                    std       $02,x     store the low word
                    rts                 return to caller

                    use       lib/imul.asm
                    use       lib/shift.asm

* ------------------------------------------------------------------
* WorkBlockImage - cc1-style init image for the work block (see $001B):
* rts stub + count/block table + relocation dirs + module-name string.
* ------------------------------------------------------------------
                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       $0009

                    * ---- block1: DP data image  ->  data base
                    fcb       $00,$00
                    fcb       $43
                    fcb       $06,$D3,$00
                    fcb       $25
                    fcb       $00
                    fcb       $27

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
                    fdb       $01C4

                    * ---- block2: non-DP data image  ->  data base + HDRADV
                    * block2 opens with MsgTab: 13 relocated pointers (+module
                    * base) to the program's message strings, reached as >MsgTab,y
WBIblock2           fcb       $09,$C4,$09,$F3,$0A
                    fcb       $2C
                    fcb       $0A
                    fcb       $58
                    fcb       $0A
                    fcb       $62
                    fcb       $0A,$8A,$0A,$CA,$0B,$08,$0B
                    fcb       $40
                    fcb       $0B
                    fcb       $7B
                    fcb       $0B,$BD,$0B,$FC,$0C
                    fcc       /2                    /
                    fcb       C$NULL
                    fcb       $20
                    fcb       C$NULL
DontKnowImg         fcc       /don't know how to mak/
                    fcc       /e /
                    fcb       $22
                    fcc       /%s/
                    fcb       $22,$2E
                    fcb       C$CR,C$NULL
WorkBufImg          fcc       /                    /
                    fcb       C$NULL
Pow10Img            fdb       10000,1000,100,10 powers of ten
                    fcb       $00,$95
FmtBufImg           fcc       /lx/
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
                    fcb       $00,$00,$00,$00,$00,$00,$00,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01
                    fcb       $11,$11,$01,$11,$11,$01,$01,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01
                    fcc       /0               HHHHH/
                    fcc       /HHHHH       BBBBBB/
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02
                    fcc       /      DDDDDD/
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04
                    fcc       /    /
                    fcb       $01,C$NULL,C$NULL

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
                    fdb       $000D

                    * ---- reloc1: text relocation offsets
                    fdb       $0033,$0031,$002F,$002D,$002B,$0029,$0041,$003F
                    fdb       $003D,$003B,$0039,$0037,$0035

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       $0005

                    * ---- reloc2: data relocation offsets
                    fdb       $0001,$0003,$0005,$0007,$0095

                    * ---- name: trailing module-name string
                    fcc       /make/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end
