                    nam       c.prep
                    ttl       C-compiler preprocessor

* Disassembled 02/08/25 13:23:49 by Disasm v1.6 (C) 1988 by RML
*
* Annotated 2026-07-11 (Claude Code):
*   - renamed disassembled labels (Lxxxx code, u00xx variables) to meaningful names
*   - added inline comments describing the preprocessor's flow
*   - verified byte-identical to the original assembly (module CRC $4B70BB)

                  IFP1
                    use       defsfile
                  ENDC
tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       1
edition             set       4
                    mod       eom,name,tylg,atrv,_start,size

                    * ------------------------------------------------------------------
                    * Data area (named rmb fields).  rmb reserves RAM without emitting
                    * bytes; OS-9 allocates <size> at load, cstart inits from WorkBlockImage.
                    * Names for ,y-referenced fields are derived from the code comments.
                    * ------------------------------------------------------------------
BuiltinArgBuf       rmb       1
PoolPtr             rmb       1
FileBufBase         rmb       1
CurChar             rmb       1
TokenStart          rmb       2
ExpandPtr           rmb       2
InPtr               rmb       1
FilePath            rmb       1
CurFile             rmb       1
FileBufSize         rmb       1
LineNum             rmb       1
FileEntStride       rmb       4
WorkField11         rmb       3
IncludeStack        rmb       2
LineSyncFlag        rmb       2
PoolEnd             rmb       2
PoolGuard           rmb       2
OptEqPtr            rmb       2
OutputEnabled       rmb       2
WorkField20         rmb       5
WorkField25         rmb       2
WorkField27         rmb       1
FileTable           rmb       2
OneCharFormat       rmb       1
StashOneChar        rmb       2
UStartFile          rmb       2
FileTableCont2F     rmb       5
FileTableBody       rmb       6
XInternalScratch    rmb       40
WorkField62         rmb       2
WorkField64         rmb       1
WorkField65         rmb       4
WorkField69         rmb       3
WorkField6C         rmb       1
WorkField6D         rmb       1
WorkField6E         rmb       5
FileTableTail       rmb       117
CharClassTable      rmb       21
XEndTable           rmb       1
XCharacterClass     rmb       128
SavedArgv           rmb       2
ArgPtrTable         rmb       58
NestDepth           rmb       1
ArgCount            rmb       3
WorkArea            rmb       2
XLongResult         rmb       2
LowResult           rmb       6
WorkAreaLimit       rmb       2
PastStackLow        rmb       2
Errno               rmb       2
MacroHashTable      rmb       256
BaseLineBuffer      rmb       256
XBackupBuffer       rmb       256
XSourceName         rmb       30
XOutputName         rmb       15
AsmPassthroughFlag  rmb       2
SystemIncludePath   rmb       20
UIdentifierBuffer   rmb       15
EnclosingActiveState rmb       20
Depth               rmb       2
SavedElseFlag       rmb       20
SeenElseFlag        rmb       2
XY54c               rmb       20
UY560               rmb       12
OutputPointerBuffer rmb       2
XConversionBuffer   rmb       10
ScratchDigitBuffer  rmb       10
LeftJustified       rmb       2
PadCharacter        rmb       2
FitsFreePool        rmb       2
HandlerPointer      rmb       2
HeapStart           rmb       4480      remaining data, bss and heap
size                equ       .

name                equ       *
                    fcs       /c.prep/
                    fcb       edition

* --- shared C runtime startup (see lib/cstart.asm) ---
RTBASE              equ       SavedArgv runtime-globals block base in the data area
DATAEND             equ       HeapStart end of static data / heap start / stack limit
HDRADV              equ       OptEqPtr  advance to where the non-DP data starts
                    use       lib/cstart.asm

ErrorCleanup        pshs      u         save U
                    ldd       #$FFBA    D = -70 stack margin
                    lbsr      stkcheck  check stack
                    ldd       #2        D = output stream code 2
                    pshs      b,a       pass it
                    lbsr      exit      flush that output stream
                    puls      pc,u,x    return

main                pshs      u         save U
                    ldd       #$FFB0    D = -80 stack margin
                    lbsr      stkcheck  check stack
                    leas      -4,s       make room for locals
                    ldd       #2048     D = $0800 work-buffer size
                    pshs      b,a       pass the size
                    lbsr      InitHeap  allocate the work buffer
                    leas      2,s        drop the arg
                    leax      >ErrorCleanup,pcr X -> error-cleanup handler
                    pshs      x         push the handler
                    lbsr      SetIntercept install the exception handler
                    lbra      NextArgDrop enter the per-argument loop

ProcessArg          ldx       10,s      X = argv cursor
                    leax      2,x       advance to next argv entry
                    stx       10,s      save updated cursor
                    ldb       [,x]      B = first char of the argument
                    cmpb      #'+       leading '+'?
                    beq       OptionLetter yes -> option
                    ldx       10,s      reload argv cursor
                    ldb       [,x]      B = first char again
                    cmpb      #'-       leading '-'?
                    lbne      ProcessFileArg no -> treat as a filename
OptionLetter        ldu       [<10,s]   U -> the option argument
                    leau      PoolPtr,u skip the +/- sign
                    ldb       ,u        B = the option letter
                    sex                 sign-extend to D
                    tfr       d,x       move letter into X
                    lbra      DispatchOption dispatch on the option letter

SetLineFlag         ldd       #1        D = 1
                    std       <LineSyncFlag set the line-directive flag
                    lbra      NextArgLoop back to the arg loop

SetErrPath          leau      PoolPtr,u skip the 'E'/'e' letter
                    ldb       ,u        B = next char
                    cmpb      #'=       is it '='?
                    lbne      NextArgLoop no -> back to arg loop
                    leax      PoolPtr,u X -> value after '='
                    stx       >OptEqPtr,y  save the error-output path
                    lbra      NextArgLoop back to the arg loop

ParseDefine         leau      PoolPtr,u skip the 'D' letter
                    ldb       ,u        B = next char
                    sex                 sign-extend
                    leax      >XCharacterClass,y  X -> character-class table
                    leax      d,x       index by the char
                    ldb       ,x        B = class bits
                    clra                clear A
                    andb      #$06      is it a letter?
                    bne       DefNameStart yes -> valid name _start
                    ldb       ,u        B = char again
                    cmpb      #'_       underscore?
                    lbne      BadDefineErr no -> bad define name
DefNameStart        stu       2,s       save name _start pointer
                    bra       DefNameTest begin scanning the name

DefNameLoop         ldd       2,s       advance the scan pointer
                    addd      #1        step forward
                    std       2,s       save updated pointer
DefNameTest         ldb       [<2,s]    B = char at scan point
                    sex                 sign-extend
                    leax      >XCharacterClass,y  X -> class table
                    leax      d,x       index by the char
                    ldb       ,x        B = class bits
                    clra                clear A
                    andb      #$0E      identifier char?
                    bne       DefNameLoop yes -> keep scanning
                    ldb       [<2,s]    B = char at scan point
                    cmpb      #'_       underscore?
                    lbeq      DefNameLoop yes -> keep scanning
                    ldb       [<2,s]    B = terminating char
                    sex                 sign-extend
                    std       ,s        save the terminator
                    clra                A = 0
                    clrb                B = 0
                    stb       [<2,s]    NUL-terminate the name
                    ldd       ,s        D = the terminator char
                    cmpd      #61       was it '='?
                    bne       DefValueOne no -> no explicit value
                    ldd       2,s       advance past the '='
                    addd      #1        step forward
                    std       2,s       value starts here
                    bra       AddDefine use that value

DefValueOne         leax      >StrOne,pcr X -> default value "1"
                    stx       2,s       value pointer = "1"
AddDefine           ldd       2,s       D = value pointer
                    pshs      b,a       push the value
                    pshs      u         push the name
                    lbsr      AddMacro  add the macro to the table
                    leas      4,s        drop the args
                    lbra      NextArgLoop back to the arg loop

BadDefineErr        ldd       [<10,s]   D = the whole -D argument
                    pshs      b,a       push it
                    ldd       #49       D = message format index
                    pshs      b,a       push the format
                    lbsr      EmitDirective print the error
                    leas      4,s        drop the args
                    leax      >FmtZeroNL,pcr X -> "0" trailer
                    lbra      EmitErrTail print and exit

DispatchOption      cmpx      #108      option 'l'?
                    lbeq      SetLineFlag yes -> line-directive flag
                    cmpx      #69       option 'E'?
                    lbeq      SetErrPath yes -> error-output path
                    cmpx      #101      option 'e'?
                    lbeq      SetErrPath yes -> error-output path
                    cmpx      #68       option 'D'?
                    lbeq      ParseDefine yes -> define
                    lbra      NextArgLoop unknown option -> arg loop

ProcessFileArg      leax      >ModeRead,pcr X -> open mode "r"
                    pshs      x         push the mode
                    ldd       [<12,s]   D = filename pointer
                    pshs      b,a       push the filename
                    lbsr      Fopen     open the input file
                    leas      4,s        drop the args
                    std       <CurFile  save the file handle
                    lbeq      CantOpenFile open failed?
                    leas      -2,s       make room for a local
                    ldd       #1        D = 1
                    std       ,s        mark first line pending
                    ldd       [<12,s]   D = filename pointer
                    pshs      b,a       push it
                    leax      >XSourceName,y  X -> source-name buffer
                    pshs      x         push the destination
                    lbsr      strcpy    copy filename into the buffer
                    leas      4,s        drop the args
                    leax      >XSourceName,y  X -> source-name buffer
                    pshs      x         push it
                    lbsr      DeriveBaseName strip path to the basename
                    std       ,s        save the basename pointer
                    leax      >XOutputName,y  X -> output-name buffer
                    pshs      x         push the destination
                    lbsr      strcpy    copy basename into the buffer
                    leas      4,s        drop the args
                    leax      >XOutputName,y  X -> output-name buffer
                    pshs      x         push it
                    leax      >XSourceName,y  X -> source-name buffer
                    pshs      x         push it
                    ldd       #55       D = header format index
                    pshs      b,a       push the format
                    lbsr      EmitDirective emit the file header
                    leas      6,s        drop the args
                    ldd       >OptEqPtr,y  D = error-output path
                    pshs      b,a       push it
                    leax      >XOutputName,y  X -> output-name buffer
                    pshs      x         push it
                    ldd       #80       D = format index
                    pshs      b,a       push the format
                    lbsr      EmitDirective emit it
                    leas      6,s        drop the args
                    lbsr      ResetLineBuf init the line-buffer state
                    bra       NextLineLoop read the first line

EmitLine            ldd       <LineNum  D = current source line
                    addd      #$FFFF    minus one
                    cmpd      ,s        same as last emitted line?
                    beq       EmitLineText yes -> emit text only
                    ldd       <LineNum  D = current source line
                    addd      #$FFFF    minus one
                    std       ,s        save as last emitted
                    pshs      b,a       push the line number
                    ldd       #53       D = #line format index
                    pshs      b,a       push the format
                    lbsr      EmitDirective emit the #line directive
                    leas      4,s        drop the args
EmitLineText        leax      >BaseLineBuffer,y  X -> output line buffer
                    pshs      x         push it
                    leax      >FmtStrCR,pcr X -> "%s" format
                    pshs      x         push the format
                    lbsr      Printf    write the line text
                    leas      4,s        drop the args
                    ldd       ,s        D = last-emitted line
                    addd      #1        advance it
                    std       ,s        save it
NextLineLoop        lbsr      GetNextLine read/expand the next line
                    cmpd      #$FFFF    end of file?
                    bne       EmitLine  no -> emit it
                    bra       NextArgDrop yes -> file done

CantOpenFile        ldd       [<10,s]   D = filename pointer
                    pshs      b,a       push it
                    ldd       #49       D = message format index
                    pshs      b,a       push the format
                    lbsr      EmitDirective print can't-open message
                    leas      4,s        drop the args
                    leax      >FmtZeroZeroCR,pcr X -> "0" trailer
EmitErrTail         pshs      x         X -> secondary message format
                    lbsr      Printf    print the error message
                    leas      2,s        drop format arg
                    ldd       #1        write flag = 1
                    pshs      b,a       push flush flag
                    lbsr      exit      flush output stream
NextArgDrop         leas      2,s        drop saved word
NextArgLoop         ldd       8,s       D = remaining arg count
                    addd      #$FFFF    decrement the count
                    std       8,s       save updated count
                    lbne      ProcessArg more args -> process next
                    leas      4,s        drop locals
                    puls      pc,u      return to caller

StrZero             fcb       $30
                    fcb       C$NULL

StrOne              fcb       $31
                    fcb       C$NULL
FmtZeroNL           fcb       $30
                    fcb       C$CR
FmtZeroNL2          fcb       $30
                    fcb       C$CR

MsgBadDefine        fcc       "bad define"
                    fcb       C$CR
                    fcb       C$NULL
ModeRead            fcc       "r"
                    fcb       C$NULL
FmtStrCR            fcc       "%s"
                    fcb       C$CR
                    fcb       C$NULL
FmtZeroZeroCR       fcb       $30
                    fcb       C$CR
                    fcb       $30
                    fcb       C$CR

MsgCantOpen         fcc       "can't open file"
                    fcb       C$CR
                    fcb       C$NULL

ResetLineBuf        pshs      u         save U
                    ldd       #$FFC0    stack margin to check
                    lbsr      stkcheck  stack overflow guard
                    leax      >BaseLineBuffer,y  X -> line buffer
                    stx       <InPtr    input pointer = buffer _start
                    clra                clear A
                    clrb                D = 0
                    stb       >BaseLineBuffer,y  empty the line buffer
                    ldd       #'        space character
                    stb       <CurChar  prime current char with a space
                    puls      pc,u      return

GetNextLine         pshs      u         save U
                    ldd       #$FEAD    stack margin
                    lbsr      stkcheck  stack overflow guard
                    leas      >-267,s   reserve line work buffer
                    leax      >BaseLineBuffer,y  X -> current line buffer
                    pshs      x         push source ptr
                    leax      >XBackupBuffer,y  X -> backup buffer
                    pshs      x         push dest ptr
                    lbsr      strcpy    save current line (strcpy)
                    leas      4,s        drop args
                    bra       ReadRawLine enter the read loop

NextLineLoop2       leas      >-267,x   reset stack to work base
ReadRawLine         lbsr      ReadLine  read next raw source line
                    std       -2,s      save line result
                    lbeq      LineEof   end of input -> return EOF
                    lbra      ProcessLine process the line

HandleDirective     ldd       <InPtr    D = input pointer
                    std       <TokenStart remember line _start
SkipDirWsLoop       clra                clear A
                    clrb                D = 0 no-skip flag
                    pshs      b,a       push flag
                    lbsr      NextChar  advance to next char
                    leas      2,s        drop flag
                    ldb       <CurChar  B = current char
                    cmpb      #'        space?
                    beq       SkipDirWsLoop skip leading spaces
                    ldb       <CurChar  B = current char
                    cmpb      #9        tab?
SkipDirTab          lbeq      SkipDirWsLoop skip leading tabs
                    ldd       <InPtr    D = input pointer
                    std       <TokenStart mark keyword _start
                    ldb       <CurChar  B = current char
                    sex                 sign-extend to D
                    leax      >XCharacterClass,y  X -> character-class table
                    leax      d,x       index by char
                    ldb       ,x        B = class flags
                    clra                clear A
                    andb      #$06      letter class?
                    lbeq      IllegalHashErr not a name -> illegal '#'
                    leax      >256,s    X -> keyword scratch
                    pshs      x         push buffer
                    lbsr      ReadIdent read directive keyword
                    leas      2,s        drop arg
                    leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >DefineStr,pcr "define"
                    pshs      x         push literal
                    lbsr      strcmp    compare (strcmp)
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkInclude not define -> try include
                    ldd       #1        define mode = 1
CallDefine          pshs      b,a       push mode
                    lbsr      HandleDefUndef handle #define
                    lbra      DirDrop   directive done

ChkInclude          leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >IncludeStr,pcr "include"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkIfdef  not include -> try ifdef
                    lbsr      DoInclude handle #include
                    lbra      DirNextLine next line

ChkIfdef            leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >IfdefStr,pcr "ifdef"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkIfndef not ifdef -> try ifndef
                    ldd       #1        ifdef mode = 1
                    pshs      b,a       push mode
                    lbsr      DoIfdef   handle #ifdef
                    lbra      DirDrop   directive done

ChkIfndef           leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >IfndefStr,pcr "ifndef"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkEndif  not ifndef -> try endif
                    clra                clear A
                    clrb                ifndef mode = 0
                    pshs      b,a       push mode
                    lbsr      DoIfdef   handle #ifndef
                    lbra      DirDrop   directive done

ChkEndif            leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >EndifStr,pcr "endif"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkElse   not endif -> try else
                    lbsr      DoEndif   handle #endif
                    lbra      DirNextLine next line

ChkElse             leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >ElseStr,pcr "else"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkUndef  not else -> try undef
                    lbsr      DoElse    handle #else
                    lbra      DirNextLine next line

ChkUndef            leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >UndefStr,pcr "undef"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkAsm    not undef -> try asm
                    clra                clear A
                    clrb                undef mode = 0
                    lbra      CallDefine reuse define handler

ChkAsm              leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >AsmStr,pcr "asm"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkEndAsm not asm -> try endasm
                    ldd       >OutputEnabled,y  output enabled?
                    beq       DirNextLine in false branch -> ignore
                    ldd       #1        asm flag = 1
SetAsmFlag          std       >AsmPassthroughFlag,y  set asm-passthrough flag
                    bra       DirNextLine next line

ChkEndAsm           leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >EndasmStr,pcr "endasm"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       ChkLineDir not endasm -> try line
                    ldd       >OutputEnabled,y  output enabled?
                    beq       DirNextLine in false branch -> ignore
                    clra                clear A
                    clrb                asm flag = 0
                    bra       SetAsmFlag clear asm flag

ChkLineDir          leax      >256,s    X -> keyword
                    pshs      x         push keyword
                    leax      >LineStr,pcr "line"
                    pshs      x         push literal
                    lbsr      strcmp    compare
                    leas      4,s        drop args
                    std       -2,s      save result
                    bne       BadDirFixup unknown directive
                    lbsr      DoLineDir handle #line
                    bra       DirNextLine next line

BadDirFixup         leax      >267,s    X = saved stack base
                    bra       BadDirRestore restore the stack

BadDirRestore       leas      >-267,x   reset work-buffer stack
IllegalHashErr      leax      >IllegalHashMsg,pcr "illegal '#'" message
                    pshs      x         push message
                    lbsr      ReportWarnAtMark report the error
DirDrop             leas      2,s        drop word
DirNextLine         lbsr      ReadLine  read next raw line
                    std       -2,s      save result
                    bne       ProcessLine got a line -> process
LineEof             ldd       #$FFFF    EOF marker
                    lbra      GetLineDone return EOF

ProcessLine         clra                clear A
                    clrb                no-skip flag
                    pshs      b,a       push flag
                    lbsr      NextChar  advance to first char
                    leas      2,s        drop flag
                    ldb       <CurChar  B = current char
                    cmpb      #'#       '#' directive?
                    lbeq      HandleDirective handle the directive
                    ldd       >OutputEnabled,y  output enabled?
                    beq       SkipLine  disabled -> skip line
                    ldd       >AsmPassthroughFlag,y  in #asm block?
                    beq       ExpandAndEmit no -> expand macros
                    leax      >BaseLineBuffer,y  X -> raw line
                    pshs      x         push line ptr
                    ldd       #50       verbatim-line format
                    pshs      b,a       push format id
                    lbsr      EmitDirective emit asm line unchanged
                    leas      4,s        drop args
                    bra       SkipLine  next line

ExpandAndEmit       leax      ,s        X -> output buffer
                    stx       <ExpandPtr set output write pointer
                    leax      >BaseLineBuffer,y  X -> input line
                    stx       <InPtr    set input read pointer
                    pshs      x         push input ptr
                    bsr       ExpandMacros expand macros in line
                    leas      2,s        drop arg
                    leax      ,s        X -> expanded text
                    pshs      x         push text ptr
                    lbsr      StripHighBits mask to 7-bit chars
                    leas      2,s        drop arg
                    leax      ,s        X -> expanded text
                    pshs      x         push source
                    leax      >BaseLineBuffer,y  X -> line buffer
                    pshs      x         push dest
                    lbsr      strcpy    copy expansion back (strcpy)
                    leas      4,s        drop args
                    ldd       #'        return space (non-EOF)
                    bra       GetLineDone return the line

                    bra       GetLineDone unreachable

SkipLine            leax      >267,s    X = saved stack base
                    lbra      NextLineLoop2 loop for next line

GetLineDone         leas      >267,s    release the work buffer
                    puls      pc,u      return

ExpandMacros        pshs      u         save U
                    ldd       #$FE72    stack margin
                    lbsr      stkcheck  stack overflow guard
                    leas      <-56,s    reserve locals
                    ldd       <InPtr    D = input pointer
                    std       <33,s     save caller input pointer
                    ldd       <60,s     D = input pointer argument
                    std       <InPtr    set input pointer to expand
                    ldd       #1        flag = 1
                    pshs      b,a       push flag
                    lbsr      NextChar  prime first char
                    leas      2,s        drop flag
                    lbra      NextToken enter the scan loop

ClassifyToken       ldb       <CurChar  B = current char
                    cmpb      #''       single quote?
                    beq       CopyStringLit copy char literal
                    ldb       <CurChar  B = current char
                    cmpb      #'"       double quote?
                    bne       ChkIdentChar not a string -> check ident
CopyStringLit       leax      >ExpandPtr,y  X -> string scratch
                    pshs      x         push scratch
                    lbsr      CopyStringLit2 copy quoted string literally
                    leas      2,s        drop arg
                    ldb       <CurChar  B = closing quote
                    ldx       <ExpandPtr X = output pointer
                    leax      1,x       advance output pointer
                    stx       <ExpandPtr save output pointer
                    stb       -1,x      store the closing quote
                    ldd       #1        advance flag = 1
                    pshs      b,a       push flag
                    lbsr      NextChar  advance past quote
                    leas      2,s        drop flag
                    lbra      NextToken continue scanning

ChkIdentChar        ldb       <CurChar  B = current char
                    sex                 sign-extend
                    leax      >XCharacterClass,y  X -> char-class table
                    leax      d,x       index by char
                    ldb       ,x        B = class flags
                    clra                clear A
                    andb      #$06      letter?
                    bne       MacroExpand identifier -> macro lookup
                    ldb       <CurChar  B = current char
                    cmpb      #'_       underscore?
                    lbne      CopyNumber not a name -> number/other
MacroExpand         leax      <24,s     X -> identifier scratch
                    pshs      x         push scratch
                    lbsr      ReadIdent read identifier
                    leas      2,s        drop arg
                    leax      <24,s     X -> identifier
                    pshs      x         push identifier
                    lbsr      LookupMacro look up macro
                    leas      2,s        drop arg
                    std       ,s        save macro entry pointer
                    lbeq      CopyIdent not a macro -> emit name
                    leas      >-268,s   reserve arg buffer
                    ldb       <CurChar  B = char after name
                    cmpb      #'        space before '('?
                    bne       NoLeadSpace no space present
                    ldd       #1        space present
                    bra       SetSpaceFlag store the flag

NoLeadSpace         clra                clear A
                    clrb                no space
SetSpaceFlag        std       ,s        record space-before-paren flag
                    ldx       >268,s    reload macro entry pointer
                    ldu       2,x       U = macro replacement text
                    lbsr      SkipSpaces skip spaces after the name
                    ldb       <CurChar  B = current input char
                    cmpb      #'(       is it an open paren
                    lbne      ExpandAndEmit2 no paren means emit body plain
                    ldx       >268,s    X = macro table entry
                    ldd       4,x       function-like flag
                    lbeq      ExpandAndEmit2 object-like macro emits body
                    clra                clear arg count
                    clrb                clear arg count
                    std       >290,s    arg count = 0
                    ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  consume the open paren
                    leas      2,s        drop the flag
                    lbra      ArgListLoop enter the argument-list loop

CollectArg          leas      -4,s       reserve scratch for this arg
                    ldd       >294,s    current argument index
                    lslb                index times two
                    rola                index times two
                    leax      >307,s    argument pointer table
                    leax      d,x       point at this arg slot
                    pshs      x         hold the slot pointer
                    ldd       <InPtr    input read pointer
                    addd      #$FFFF    back up one char
                    std       [,s++]    record this arg's _start
                    clra                clear length
                    clrb                clear length
                    std       10,s      argument length = 0
                    std       2,s       paren depth = 0
                    lbra      ArgScanLoop scan chars of the argument

ArgClassify         ldb       <CurChar  current char
                    sex                 sign extend to word
                    tfr       d,x       X = the char
                    lbra      ArgCharSwitch classify the char

ArgComma            ldd       2,s       paren depth
                    lbne      ArgAccumChar nested comma is ordinary text
                    ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  consume the comma separator
                    leas      2,s        drop the flag
                    bra       EndArg    this argument is complete

ArgCloseParen       ldd       2,s       paren depth
                    beq       EndArg    top level ends the arg list
                    ldd       2,s       paren depth
                    addd      #$FFFF    decrement nesting depth
                    bra       SetArgDepth save depth and keep scanning

EndArg              leax      >328,s    compute stack fixup pointer
                    lbra      FinishArg store the arg length

ArgOpenParen        ldd       2,s       paren depth
                    addd      #1        increment nesting depth
SetArgDepth         std       2,s       save the new depth
                    lbra      ArgAccumChar keep scanning the argument

ArgQuote            ldb       <CurChar  quote char
                    sex                 sign extend to word
                    std       ,s        remember the opening quote
ArgStrLoop          ldb       <CurChar  current char
                    cmpb      #'\       is it a backslash escape
                    bne       ArgStrNext not escaped
                    clra                clear get-char flag
                    clrb                clear get-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  consume the escaped char
                    leas      2,s        drop the flag
                    ldd       10,s      arg length
                    addd      #1        count the escaped char
                    std       10,s      save length
ArgStrNext          clra                clear get-char flag
                    clrb                clear get-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  get next string char
                    leas      2,s        drop the flag
                    ldd       10,s      arg length
                    addd      #1        count this char
                    std       10,s      save length
                    ldb       <CurChar  current char
                    beq       ArgAccumChar end of input stops the string
                    ldb       <CurChar  current char
                    sex                 sign extend to word
                    cmpd      ,s        reached the closing quote
                    bne       ArgStrLoop no keep scanning the string
                    bra       ArgAccumChar string done resume arg

ArgCharSwitch       cmpx      #',       is it a comma
                    lbeq      ArgComma  handle argument separator
                    cmpx      #')       is it a close paren
                    lbeq      ArgCloseParen handle end of arg list
                    cmpx      #'(       is it an open paren
                    lbeq      ArgOpenParen handle nested paren
                    cmpx      #''       is it a single quote
                    beq       ArgQuote  scan a quoted string
                    cmpx      #'"       is it a double quote
                    lbeq      ArgQuote  scan a quoted string
ArgAccumChar        ldd       10,s      arg length
                    addd      #1        count this char
                    std       10,s      save length
                    ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  advance the input
                    leas      2,s        drop the flag
ArgScanLoop         ldb       <CurChar  current char
                    lbne      ArgClassify more chars keep scanning
                    bra       StoreArgLen end so store the length

FinishArg           leas      >-328,x   restore the scan stack frame
StoreArgLen         ldd       >294,s    argument index
                    lslb                index times two
                    rola                index times two
                    leax      >274,s    argument length table
                    leax      d,x       point at this slot
                    ldd       10,s      the measured length
                    std       ,x        store the arg length
                    ldd       >294,s    argument index
                    addd      #1        bump the argument count
                    std       >294,s    save the new count
                    leas      4,s        drop the arg scratch
ArgListLoop         ldb       <CurChar  current char
                    beq       SetGetNext end means do substitution
                    ldb       <CurChar  current char
                    cmpb      #')       is it the close paren
                    lbne      CollectArg no so collect another arg
SetGetNext          ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  consume the close paren
                    leas      2,s        drop the flag
                    leax      8,s       expansion output pointer
                    stx       >264,s    save the write pointer
                    ldb       ,u+       fetch first macro-body char
                    sex                 sign extend to word
                    std       2,s       hold the char
SubstBodyLoop       ldd       2,s       current body char
                    cmpd      #64       is it a parameter marker
                    lbne      BodyQuoteChk not a parameter
                    ldb       ,u+       fetch the parameter digit
                    sex                 sign extend to word
                    std       2,s       hold the digit
                    addd      #$FFD0    convert digit from ascii
                    std       4,s       parameter index
                    blt       EmitLiteralAt negative means literal at-sign
                    ldd       4,s       parameter index
                    cmpd      >290,s    index past the arg count
                    bge       EmitLiteralAt out of range means literal
                    ldd       4,s       parameter index
                    lslb                index times two
                    rola                index times two
                    leax      >270,s    argument length table
                    leax      d,x       point at that arg
                    ldd       ,x        its stored length
                    std       6,s       chars left to copy
                    ldd       4,s       parameter index
                    lslb                index times two
                    rola                index times two
                    leax      >303,s    argument pointer table
                    leax      d,x       point at that arg
                    ldd       ,x        its _start pointer
                    std       >266,s    arg text source pointer
                    bra       CopyArgLoop _start copying the arg text

CopyArgText         ldx       >266,s    arg source pointer
                    leax      1,x       advance source
                    stx       >266,s    save source pointer
                    ldb       -1,x      fetch one arg char
                    ldx       >264,s    output pointer
                    leax      1,x       advance output
                    stx       >264,s    save output pointer
                    stb       -1,x      write char to expansion
CopyArgLoop         ldd       6,s       chars remaining
                    addd      #$FFFF    decrement the count
                    std       6,s       save the count
                    subd      #$FFFF    test for zero
                    bne       CopyArgText copy more arg chars
                    lbra      NextBodyChar continue scanning body

EmitLiteralAt       ldd       #'@       literal at-sign byte
                    ldx       >264,s    output pointer
                    leax      1,x       advance output
                    stx       >264,s    save output pointer
                    stb       -1,x      write the literal at-sign
                    bra       CopyBodyChar continue scanning body

BodyQuoteChk        ldd       2,s       current body char
                    cmpd      #''       single quote in body
                    beq       CopyBodyStr copy the string verbatim
                    ldd       2,s       current body char
                    cmpd      #'"       double quote in body
                    bne       CopyBodyChar otherwise copy one char
CopyBodyStr         leas      -1,s       reserve byte for quote
                    ldd       3,s       the quote char
                    stb       ,s        remember the opening quote
BodyStrLoop         ldd       3,s       the quote char
                    ldx       >265,s    output pointer
                    leax      1,x       advance output
                    stx       >265,s    save output pointer
                    stb       -1,x      copy the string char
                    ldb       ,u+       fetch next body char
                    sex                 sign extend to word
                    std       3,s       hold the char
                    ldd       3,s       the current char
                    beq       BodyStrClose end of body closes string
                    ldb       ,s        the opening quote
                    sex                 sign extend to word
                    cmpd      3,s       reached the closing quote
                    bne       BodyStrLoop no keep copying the string
BodyStrClose        ldd       3,s       the closing quote
                    ldx       >265,s    output pointer
                    leax      1,x       advance output
                    stx       >265,s    save output pointer
                    stb       -1,x      copy the closing quote
                    leas      1,s        drop the saved quote byte
                    bra       NextBodyChar continue scanning body

CopyBodyChar        ldd       2,s       the literal char
                    ldx       >264,s    output pointer
                    leax      1,x       advance output
                    stx       >264,s    save output pointer
                    stb       -1,x      copy the literal char
NextBodyChar        ldd       2,s       current body char
                    beq       EndExpand zero ends the body
                    ldb       ,u+       fetch next body char
                    sex                 sign extend to word
                    std       2,s       hold the char
                    lbne      SubstBodyLoop loop over the body
EndExpand           clra                clear terminator
                    clrb                clear terminator
                    stb       [>264,s]   nul-terminate the expansion
                    leau      8,s       U points at expanded text
ExpandAndEmit2      ldb       <CurChar  current char
                    stb       >323,s    save current char across recursion
                    pshs      u         pass expansion pointer
                    lbsr      ExpandMacros recursively expand the result
                    leas      2,s        drop the pointer
                    ldb       >323,s    reload saved char
                    stb       <CurChar  restore current char
                    ldd       ,s        trailing-space flag
                    beq       FreeArgBuf no space needed
                    ldd       #'        emit a separating space
                    ldx       <ExpandPtr output pointer
                    leax      1,x       advance output
                    stx       <ExpandPtr save output pointer
                    stb       -1,x      write the space
FreeArgBuf          leas      >268,s    free the argument buffer
                    lbra      NextToken back to the token loop

CopyIdent           leau      <24,s     U points at identifier buffer
                    bra       CopyIdentLoop test-first copy loop

CopyIdentChar       ldb       ,u+       fetch one identifier char
                    ldx       <ExpandPtr output pointer
                    leax      1,x       advance output
                    stx       <ExpandPtr save output pointer
                    stb       -1,x      copy char to output
CopyIdentLoop       ldb       ,u        peek next identifier char
                    bne       CopyIdentChar more chars keep copying
                    lbra      NextToken back to the token loop

CopyNumber          ldb       <CurChar  current char
                    cmpb      #'0       leading zero of a constant
                    bne       CopyOneChar not zero copy one char
                    ldb       <CurChar  the zero digit
                    ldx       <ExpandPtr output pointer
                    leax      1,x       advance output
                    stx       <ExpandPtr save output pointer
                    stb       -1,x      copy the zero
                    ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  advance the input
                    leas      2,s        drop the flag
                    ldb       <CurChar  current char
                    cmpb      #'x       lowercase hex prefix
                    beq       CopyHexLoop copy hex constant
                    ldb       <CurChar  current char
                    cmpb      #'X       uppercase hex prefix
                    bne       NextToken plain zero back to token loop
CopyHexLoop         ldb       <CurChar  current hex char
                    ldx       <ExpandPtr output pointer
                    leax      1,x       advance output
                    stx       <ExpandPtr save output pointer
                    stb       -1,x      copy the hex digit
                    ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  advance the input
                    leas      2,s        drop the flag
                    ldb       <CurChar  current char
                    sex                 sign extend to word
                    leax      >XCharacterClass,y  char-class lookup table
                    leax      d,x       index by char
                    ldb       ,x        its class bits
                    clra                clear high byte
                    andb      #$40      test hex-digit class bit
                    bne       CopyHexLoop keep copying hex digits
                    bra       NextToken back to the token loop

CopyOneChar         ldb       <CurChar  current char
                    ldx       <ExpandPtr output pointer
                    leax      1,x       advance output
                    stx       <ExpandPtr save output pointer
                    stb       -1,x      copy the single char
                    ldd       #1        one for get-next-char flag
                    pshs      b,a       push the flag
                    lbsr      NextChar  advance the input
                    leas      2,s        drop the flag
NextToken           ldb       <CurChar  current char
                    lbne      ClassifyToken more input means next token
                    clra                clear terminator
                    clrb                clear terminator
                    stb       [>ExpandPtr,y] nul-terminate the output line
                    ldd       <33,s     saved input pointer
                    std       <InPtr    restore input pointer
                    leas      <56,s     release the local frame
                    puls      pc,u      return

LookupMacro         pshs      u         save caller U
                    ldd       #$FFB6    stack margin to check
                    lbsr      stkcheck  guard against stack overflow
                    leas      -2,s       reserve a local word
                    ldd       6,s       name string to look up
                    pshs      b,a       pass the name
                    lbsr      HashName  hash the macro name
                    leas      2,s        drop the argument
                    lslb                hash times two
                    rola                hash times two
                    leax      >MacroHashTable,y  macro hash table base
                    leax      d,x       index into the buckets
                    ldu       ,x        U = bucket head entry
                    bra       MacroBucketLoop enter the bucket walk

MacroCmpLoop        ldd       ,s        this entry pointer
                    addd      #6        entry name field offset
                    pshs      b,a       pass the entry name
                    ldd       8,s       the search name
                    pshs      b,a       pass the search name
                    lbsr      strcmp    compare the two names
                    leas      4,s        drop the arguments
                    std       -2,s      save compare result
                    beq       MacroFound zero means match found
                    ldu       ,u        follow chain to next entry
                    bra       MacroBucketLoop loop back to bucket walk

MacroFound          tfr       u,d       return the matching entry
                    puls      pc,u,x    restore and return

MacroBucketLoop     stu       ,s        hold the entry pointer
                    bne       MacroCmpLoop keep walking while nonzero
                    clra                return null - macro not found
                    clrb                d = 0
                    puls      pc,u,x    return to caller

HandleDefUndef      pshs      u         save caller u
                    ldd       #$FFAF    frame size for stack check
                    lbsr      stkcheck  guard against stack overflow
                    leas      -9,s       make room for locals
                    ldd       >OutputEnabled,y  in a false #if block?
                    lbeq      DefExit   yes, ignore this directive
                    lbsr      SkipWsComment skip whitespace and comments
                    ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  get next input char
                    leas      2,s        drop arg
                    ldb       <CurChar  b = current char
                    sex                 sign extend to d
                    leax      >XCharacterClass,y  point at char-class table
                    leax      d,x       index by char
                    ldb       ,x        b = class bits
                    clra                clear high byte
                    andb      #$06      is it a letter?
                    bne       GotDefName yes, read the name
                    ldb       <CurChar  b = current char
                    cmpb      #'_       underscore?
                    bne       BadDefName no, not an identifier - error
GotDefName          leax      ,s        x -> name buffer
                    pshs      x         push buffer pointer
                    lbsr      ReadIdent read identifier token
                    leas      2,s        drop pointer
                    ldd       13,s      d = mode (1=define, 0=undef)
                    cmpd      #1        define?
                    bne       DoUndef   no, undefine it
                    clra                null body arg high
                    clrb                null body arg low
                    pshs      b,a       push null body
                    leax      2,s       x -> name
                    pshs      x         push name pointer
                    bsr       AddMacro  add macro to table
                    leas      4,s        drop args
                    bra       DefExit   done

DoUndef             leax      ,s        x -> name
                    pshs      x         push name pointer
                    bsr       UndefMacro remove macro from table
                    bra       DefCleanup done

BadDefName          leax      >IllegalMacroMsg,pcr point at 'illegal macro name'
                    pshs      x         push message
                    lbsr      ReportWarn report the error
DefCleanup          leas      2,s        drop pointer
DefExit             leas      9,s        release locals
                    puls      pc,u      return

UndefMacro          pshs      u         save caller u
                    ldd       #$FFBA    frame size for stack check
                    lbsr      stkcheck  guard against stack overflow
                    bra       UndefLoop _start the lookup

ClearMacroEntry     clra                clear defined flag
                    clrb                d = 0
                    stb       ExpandPtr,u mark this macro undefined
UndefLoop           ldd       4,s       d = name pointer
                    pshs      b,a       push name
                    lbsr      LookupMacro look up macro entry
                    leas      2,s        drop arg
                    tfr       d,u       u = entry, 0 if none
                    stu       -2,s      test result
                    bne       ClearMacroEntry found - clear and keep scanning
                    puls      pc,u      return

AddMacro            pshs      u         save caller u
                    ldd       #$FE91    large frame for parse buffers
                    lbsr      stkcheck  guard against stack overflow
                    leas      >-295,s   allocate parse buffers
                    ldd       #6        size of a macro entry
                    pshs      b,a       push size
                    lbsr      AllocBytes allocate the entry
                    leas      2,s        drop size
                    std       >293,s    save entry pointer
                    tfr       d,u       u = entry
                    ldd       >299,s    d = macro name
                    pshs      b,a       push name
                    lbsr      HashName  hash name to bucket
                    leas      2,s        drop name
                    std       >291,s    save bucket index
                    lslb                word offset = index*2
                    rola                carry into high byte
                    leax      >MacroHashTable,y  x -> macro hash table
                    leax      d,x       x -> bucket slot
                    ldd       ,x        d = old chain head
                    std       >287,s    save old head
                    ldd       >291,s    reload bucket index
                    lslb                word offset = index*2
                    rola                carry into high byte
                    leax      >MacroHashTable,y  x -> hash table
                    leax      d,x       x -> bucket slot
                    ldd       >293,s    d = new entry
                    std       ,x        insert at head of chain
                    ldd       >287,s    d = old head
                    std       [>293,s]   link old chain into new entry
                    ldd       >299,s    d = macro name
                    pshs      b,a       push name
                    lbsr      StoreString copy name into string arena
                    leas      2,s        drop arg
                    ldd       <PoolPtr  d = interned name pointer
                    ldx       >293,s    x = entry
                    std       2,x       store name pointer in entry
                    ldd       >301,s    predefined body supplied?
                    beq       ParseMacroDef no, parse from input
                    ldd       >301,s    d = body string
                    pshs      b,a       push body
                    lbsr      StoreString copy body into arena
                    leas      2,s        drop arg
                    lbsr      EnsureHeap ensure arena space
                    lbra      AddMacroDone done

ParseMacroDef       clra                clear param count high
                    clrb                clear param count low
                    std       ,s        param count = 0
                    ldb       <CurChar  b = current char
                    cmpb      #'(       '(' function-like macro?
                    lbne      BodyStart no, object-like body
                    ldd       #1        flag value
                    ldx       >293,s    x = entry
                    std       4,x       mark macro as function-like
                    ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  consume the '('
                    leas      2,s        drop arg
                    leau      <31,s     u -> param name buffer
                    bra       ParamLoop scan parameters

ParamLoop           lbsr      SkipSpaces skip spaces
                    ldb       <CurChar  b = current char
                    lbeq      ParamsDone end of input - done
                    ldb       <CurChar  b = current char
                    cmpb      #')       ')' end of params?
                    lbeq      ParamsDone yes, done
                    ldd       ,s        d = param count
                    lslb                word offset = count*2
                    rola                carry into high byte
                    leax      2,s       x -> param pointer array
                    leax      d,x       x -> this slot
                    stu       ,x        save this param's name pointer
                    ldb       <CurChar  b = current char
                    sex                 sign extend
                    leax      >XCharacterClass,y  x -> char-class table
                    leax      d,x       index by char
                    ldb       ,x        b = class bits
                    clra                clear high
                    andb      #$06      is it a letter?
                    bne       ReadParam yes, read the param name
                    ldb       <CurChar  b = current char
                    cmpb      #'_       underscore?
                    bne       BadParamErr no, bad parameter
ReadParam           leax      <22,s     x -> token buffer
                    pshs      x         push buffer
                    lbsr      ReadIdent read parameter name
                    leas      2,s        drop buffer
                    leax      <22,s     x -> name
                    stx       >287,s    save read pointer
CopyParamLoop       ldx       >287,s    x = read pointer
                    leax      1,x       advance
                    stx       >287,s    save pointer
                    ldb       -1,x      b = name char
                    stb       ,u+       copy into param table
                    bne       CopyParamLoop loop until nul
                    ldd       ,s        d = param count
                    addd      #1        increment
                    std       ,s        store new count
                    lbsr      SkipSpaces skip spaces
                    ldb       <CurChar  b = current char
                    cmpb      #',       comma between params?
                    bne       NextParam no, jump to loop
                    ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  consume the comma
                    bra       ParamAfterComma continue

BadParamErr         leax      >MacroDefErrMsg,pcr point at 'macro definition error'
                    pshs      x         push message
                    lbsr      ReportWarn report bad parameter
ParamAfterComma     leas      2,s        drop arg
NextParam           lbra      ParamLoop next parameter

ParamsDone          ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  consume the ')'
                    leas      2,s        drop arg
BodyStart           lbsr      SkipSpaces skip spaces before body
                    lbra      BodyNext  _start body scan

BodyLoop            ldb       <CurChar  b = current char
                    cmpb      #''       single quote?
                    beq       MarkQuoted yes, mark it quoted
                    ldb       <CurChar  b = current char
                    cmpb      #'"       double quote?
                    bne       BodyIdent no, check for identifier
MarkQuoted          ldb       <CurChar  b = current char
                    sex                 sign extend
                    orb       #$80      flag char as quoted
                    stb       <CurChar  store back
                    lbra      BodyNext  next body char

BodyIdent           ldb       <CurChar  b = current char
                    sex                 sign extend
                    leax      >XCharacterClass,y  x -> char-class table
                    leax      d,x       index by char
                    ldb       ,x        b = class bits
                    clra                clear high
                    andb      #$06      is it a letter?
                    bne       ReadBodyWord yes, read the word
                    ldb       <CurChar  b = current char
                    cmpb      #'_       underscore?
                    lbne      BodyNumber no, check for a number
ReadBodyWord        leax      <22,s     x -> word buffer
                    pshs      x         push buffer
                    lbsr      ReadIdent read identifier word
                    leas      2,s        drop buffer
                    clra                _start at param 0
                    clrb                index low = 0
                    bra       ParamMatchTest begin param match

MatchParamLoop      ldd       >291,s    d = param index
                    lslb                word offset = index*2
                    rola                carry into high byte
                    leax      2,s       x -> param pointer array
                    leax      d,x       index
                    ldd       ,x        d = param name pointer
                    pshs      b,a       push param name
                    leax      <24,s     x -> word buffer
                    pshs      x         push word
                    lbsr      strcmp    compare word to param
                    leas      4,s        drop args
                    std       -2,s      matched?
                    bne       ParamNoMatch no, try next param
                    ldd       #64       '@' marks a parameter ref
                    stb       <22,s     emit the marker byte
                    ldd       >291,s    d = param index
                    addd      #48       param index to ascii digit
                    stb       <23,s     store digit after marker
                    clra                terminator high
                    clrb                terminator low
                    stb       <24,s     nul-terminate the marker
                    bra       EmitWord  emit the marker

ParamNoMatch        ldd       >291,s    d = param index
                    addd      #1        advance to next param
ParamMatchTest      std       >291,s    save index
                    ldd       >291,s    d = index
                    cmpd      ,s        checked all params?
                    blt       MatchParamLoop no, keep comparing
EmitWord            leax      <22,s     x -> word or marker
                    stx       >287,s    save read pointer
                    bra       EmitWordLoop emit it

AppendBodyChar      ldd       >289,s    d = char to emit
                    pshs      b,a       push char
                    lbsr      AppendOutByte append char to body
                    leas      2,s        drop char
EmitWordLoop        ldx       >287,s    x = read pointer
                    leax      1,x       advance
                    stx       >287,s    save pointer
                    ldb       -1,x      b = word char
                    sex                 sign extend
                    std       >289,s    save char
                    bne       AppendBodyChar loop until nul
                    lbsr      EnsureHeap ensure arena space
                    lbra      BodyNext  next body char

BodyNumber          ldb       <CurChar  b = current char
                    cmpb      #'0       leading '0' of a number?
                    bne       BodyLiteral no, literal char
                    ldb       <CurChar  b = current char
                    sex                 sign extend
                    pshs      b,a       push char
                    lbsr      AppendOutByte append '0' to body
                    leas      2,s        drop char
                    ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  get next char
                    leas      2,s        drop arg
                    ldb       <CurChar  b = current char
                    cmpb      #'x       'x' hex prefix?
                    beq       CopyHexLoop2 yes, copy hex digits
                    ldb       <CurChar  b = current char
                    cmpb      #'X       'X' hex prefix?
                    bne       BodyNext  no, resume body
CopyHexLoop2        ldb       <CurChar  b = current char
                    sex                 sign extend
                    pshs      b,a       push char
                    lbsr      AppendOutByte append hex digit
                    leas      2,s        drop char
                    ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  get next char
                    leas      2,s        drop arg
                    ldb       <CurChar  b = current char
                    sex                 sign extend
                    leax      >XCharacterClass,y  x -> char-class table
                    leax      d,x       index by char
                    ldb       ,x        b = class bits
                    clra                clear high
                    andb      #$40      still a hex digit?
                    bne       CopyHexLoop2 yes, keep copying
                    bra       BodyNext  resume body

BodyLiteral         ldb       <CurChar  b = literal char
                    sex                 sign extend
                    pshs      b,a       push char
                    lbsr      AppendOutByte append char to body
                    leas      2,s        drop char
                    ldd       #1        request a char read
                    pshs      b,a       push arg
                    lbsr      NextChar  get next char
                    leas      2,s        drop arg
BodyNext            ldb       <CurChar  b = current char
                    lbne      BodyLoop  more body, loop
                    clra                terminator high
                    clrb                terminator low
                    pshs      b,a       push nul
                    lbsr      AppendOutByte terminate macro body
                    leas      2,s        drop arg
AddMacroDone        leas      >295,s    release buffers
                    puls      pc,u      return

StripHighBits       pshs      u         save caller u
                    ldd       #$FFC0    frame size for stack check
                    lbsr      stkcheck  guard against stack overflow
                    ldu       4,s       u -> string argument
                    bra       StripTest test first char

StripLoop           ldb       ,u+       b = char, advance
                    clra                clear high
                    andb      #$7F      strip quoted-marker high bit
                    stb       -PoolPtr,u store cleaned char back
StripTest           ldb       ,u        b = current char
                    bne       StripLoop loop until nul
                    puls      pc,u      return

DoInclude           pshs      u         save caller u
                    ldd       #$FF90    frame size for stack check
                    lbsr      stkcheck  guard against stack overflow
                    leas      <-38,s    allocate include-name buffer
                    ldd       >OutputEnabled,y  active-output flag set?
                    lbeq      IncDone   inactive region, skip include
                    lbsr      SkipWsComment advance to next input line
                    ldd       <InPtr    current input pointer
                    std       <TokenStart remember line _start
                    leau      4,s       U points at filename buffer
                    ldd       #1        request skip leading whitespace
                    pshs      b,a       pass the flag
                    lbsr      NextChar  read next char
                    leas      2,s        drop arg
                    ldb       <CurChar  B = current char
                    sex                 sign-extend to D
                    std       ,s        save delimiter char
                    cmpd      #'"       opening double quote?
                    beq       IncDelimOk yes, read the filename
                    ldd       ,s        reload the char
                    cmpd      #'<       opening angle bracket?
                    lbne      IncSyntaxErr neither, bad include syntax
IncDelimOk          clra                no-skip mode
                    clrb                D = 0
                    pshs      b,a       pass the flag
                    lbsr      NextChar  read next char
                    leas      2,s        drop arg
                    ldd       ,s        recover delimiter
                    cmpd      #'<       was it an angle bracket?
                    bne       IncNameLoop no, quoted form copies directly
                    ldd       #'>       closing bracket terminator
                    std       ,s        use as terminator
                    ldb       >SystemIncludePath,y  system include path already built?
                    bne       SysPathBuf yes, skip building it
                    leax      >DdPathStr,pcr default path prefix string
                    pshs      x         push source
                    leax      >SystemIncludePath,y  destination buffer
                    pshs      x         push dest
                    lbsr      strcpy    copy prefix into buffer
                    leas      4,s        drop args
                    leax      >DefsPathStr,pcr path suffix string
                    pshs      x         push source
                    leax      >SystemIncludePath,y  same buffer
                    pshs      x         push dest
                    lbsr      strcat    append the suffix
                    leas      4,s        drop args
SysPathBuf          leax      >SystemIncludePath,y  system path buffer
                    pshs      x         push it
                    pshs      u         filename buffer pointer
                    lbsr      CopyStrEnd point just past the path prefix
                    leas      4,s        drop args
                    tfr       d,u       U = write cursor after prefix
                    bra       IncNameLoop go copy the filename

StoreIncChar        ldb       <CurChar  current char
                    stb       ,u+       store into filename buffer
                    clra                no-skip mode
                    clrb                D = 0
                    pshs      b,a       pass flag
                    lbsr      NextChar  read next char
                    leas      2,s        drop arg
IncNameLoop         ldb       <CurChar  current char
                    beq       IncNameDone end of line, stop copying
                    ldb       <CurChar  current char
                    sex                 sign-extend
                    cmpd      ,s        reached the terminator?
                    bne       StoreIncChar no, keep copying
IncNameDone         clra                D = 0
                    clrb                clear B
                    stb       ,u        NUL-terminate the filename
                    leax      >ReadModeStr,pcr "r" open mode string
                    pshs      x         push mode
                    leax      6,s       filename buffer
                    pshs      x         push name
                    lbsr      Fopen     open the include file
                    leas      4,s        drop args
                    std       <34,s     save the file handle
                    lbeq      IncOpenErr open failed, report it
                    ldd       #23       23 bytes for include record
                    pshs      b,a       pass size
                    lbsr      AllocBytes allocate include-stack record
                    leas      2,s        drop arg
                    std       2,s       save record pointer
                    ldd       <IncludeStack current include-stack head
                    std       [<2,s]    link previous entry
                    ldd       <LineNum  current line number
                    ldx       2,s       record pointer
                    std       2,x       save line number in record
                    ldd       <CurFile  current file struct
                    ldx       2,s       record pointer
                    std       4,x       save file pointer in record
                    leax      >XSourceName,y  current file name buffer
                    pshs      x         push it
                    lbsr      StoreString duplicate the name string
                    leas      2,s        drop arg
                    ldx       2,s       record pointer
                    std       6,x       save saved-name pointer
                    leax      >XOutputName,y  secondary name buffer
                    pshs      x         push dest
                    ldd       4,s       record pointer
                    addd      #8        offset to name field
                    pshs      b,a       push source
                    lbsr      strcpy    copy the saved name
                    leas      4,s        drop args
                    leax      4,s       new filename buffer
                    pshs      x         push source
                    leax      >XSourceName,y  main name buffer
                    pshs      x         push dest
                    lbsr      strcpy    install new current filename
                    leas      4,s        drop args
                    leax      4,s       new filename
                    pshs      x         push it
                    lbsr      DeriveBaseName derive a base identifier
                    std       ,s        save the pointer
                    leax      >XOutputName,y  base-name dest buffer
                    pshs      x         push dest
                    lbsr      strcpy    copy base name
                    leas      4,s        drop args
                    leax      >XOutputName,y  base name
                    pshs      x         push arg
                    leax      >XSourceName,y  full name
                    pshs      x         push arg
                    ldd       #55       #line marker format
                    pshs      b,a       push format
                    lbsr      EmitDirective emit the line marker
                    leas      6,s        drop args
                    ldd       2,s       record pointer
                    std       <IncludeStack make it the new stack head
                    clra                line number 0
                    clrb                clear B
                    pshs      b,a       push it
                    ldd       #53       line-number reset format
                    pshs      b,a       push format
                    lbsr      EmitDirective emit line-number reset
                    leas      4,s        drop args
                    clra                reset value 0
                    clrb                clear B
                    std       <LineNum  reset line number
                    ldd       <34,s     new file handle
                    std       <CurFile  make it the current file
                    bra       IncDone   done with include

IncOpenErr          leax      >CantOpenMsg,pcr "can't open" message
                    bra       IncPrintErr print it

IncSyntaxErr        leax      >BadIncludeMsg,pcr "bad include" message
IncPrintErr         pshs      x         push message pointer
                    lbsr      ReportError print the error
                    leas      2,s        drop arg
IncDone             leas      <38,s     drop locals
                    puls      pc,u      return

DoLineDir           pshs      u         save caller U
                    ldd       #$FFAB    stack margin to check
                    lbsr      stkcheck  verify stack headroom
                    leas      -11,s      reserve locals
                    ldd       >OutputEnabled,y  active-output flag set?
                    lbeq      LineDone  inactive region, skip
                    lbsr      SkipWsComment advance to next line
                    ldd       #1        skip whitespace
                    pshs      b,a       pass flag
                    lbsr      NextChar  read next char
                    leas      2,s        drop arg
                    leax      ,s        number token buffer
                    pshs      x         push dest
                    lbsr      ReadIdent copy the number token
                    leas      2,s        drop arg
                    leax      ,s        token buffer
                    pshs      x         push it
                    lbsr      ParseInt  convert to integer
                    leas      2,s        drop arg
                    std       9,s       save line number
                    beq       LineReadName zero, keep current number
                    ldd       9,s       new line number
                    std       <LineNum  set current line number
LineReadName        lbsr      SkipWsComment advance to next line
                    ldd       #1        skip whitespace
                    pshs      b,a       pass flag
                    lbsr      NextChar  read next char
                    leas      2,s        drop arg
                    leax      ,s        name token buffer
                    pshs      x         push dest
                    lbsr      ReadIdent copy the filename token
                    leas      2,s        drop arg
                    ldb       ,s        first char of name
                    beq       LineEmitDir empty, no filename given
                    leax      ,s        new name
                    pshs      x         push source
                    leax      >XSourceName,y  current name buffer
                    pshs      x         push dest
                    lbsr      strcpy    install new filename
                    leas      4,s        drop args
                    leax      >XSourceName,y  name buffer
                    pshs      x         push it
                    bsr       DeriveBaseName derive a base identifier
                    std       ,s        save the pointer
                    leax      >XOutputName,y  base-name dest buffer
                    pshs      x         push dest
                    lbsr      strcpy    copy base name
                    leas      4,s        drop args
LineEmitDir         leax      >XOutputName,y  base name
                    pshs      x         push arg
                    leax      >XSourceName,y  full name
                    pshs      x         push arg
                    ldd       #55       #line marker format
                    pshs      b,a       push format
                    lbsr      EmitDirective emit the line marker
                    leas      6,s        drop args
LineDone            leas      11,s       drop locals
                    puls      pc,u      return

DeriveBaseName      pshs      u         save caller U
                    ldd       #$FFBA    stack margin to check
                    lbsr      stkcheck  verify stack headroom
                    ldu       4,s       U = source path
                    leas      -4,s       reserve locals
                    bra       MarkAfterSlash enter the scan loop

ChkSlash            ldd       ,s        current char
                    cmpd      #47       path separator '/'?
                    bne       SlashScanLoop no, keep scanning
MarkAfterSlash      stu       2,s       record _start just past slash
SlashScanLoop       ldb       ,u+       next path char
                    sex                 sign-extend
                    std       ,s        save char
                    bne       ChkSlash  not end, continue scanning
                    leau      >UIdentifierBuffer,y  U = identifier buffer
                    ldb       [<2,s]    first base-name char
                    sex                 sign-extend
                    leax      >XCharacterClass,y  char-class table
                    leax      d,x       index by char
                    ldb       ,x        class bits
                    clra                clear high byte
                    andb      #$08      leading char is a digit?
                    beq       NextIdentChar no, copy it as-is
                    ldd       #95       leading digit becomes '_'
                    bra       StoreIdentChar store the underscore

CopyIdentLoop2      ldd       ,s        current char
                    leax      >XCharacterClass,y  char-class table
                    leax      d,x       index by char
                    ldb       ,x        class bits
                    clra                clear high byte
                    andb      #$0E      valid identifier char?
                    bne       IdentCharOk yes, keep it
                    ldd       #95       invalid becomes '_'
                    std       ,s        replace the char
IdentCharOk         ldd       ,s        char to store
StoreIdentChar      stb       ,u+       store into identifier buffer
NextIdentChar       ldx       2,s       source pointer
                    leax      1,x       advance it
                    stx       2,s       save it back
                    ldb       -1,x      next source char
                    sex                 sign-extend
                    std       ,s        save char
                    beq       IdentDone end of string, stop
                    leax      >UIdentifierBuffer,y  identifier buffer base
                    pshs      x         push it
                    tfr       u,d       current write cursor
                    subd      ,s++      bytes written so far
                    cmpd      #14       still under 14 chars?
                    ble       CopyIdentLoop2 yes, copy another
IdentDone           clra                D = 0
                    clrb                clear B
                    stb       ,u        NUL-terminate identifier
                    leax      >UIdentifierBuffer,y  return identifier buffer
                    tfr       x,d       D = pointer
                    leas      4,s        drop locals
                    puls      pc,u      return

DoIfdef             pshs      u         save caller U
                    ldd       #$FFB1    stack margin to check
                    lbsr      stkcheck  verify stack headroom
                    leas      -9,s       reserve locals
                    ldd       >Depth,y  current if-nesting depth
                    cmpd      #10       nesting limit (10) reached?
                    bne       IfChkIdent no, proceed
                    leax      >IfNestDeepMsg,pcr "too many nests" error
                    bra       IfErr     report it

IfChkIdent          lbsr      SkipWsComment advance to next line
                    ldd       #1        skip whitespace
                    pshs      b,a       pass flag
                    lbsr      NextChar  read next char
                    leas      2,s        drop arg
                    ldd       <InPtr    input pointer
                    std       <TokenStart remember line _start
                    ldb       <CurChar  current char
                    sex                 sign-extend
                    leax      >XCharacterClass,y  char-class table
                    leax      d,x       index by char
                    ldb       ,x        class bits
                    clra                clear high byte
                    andb      #$06      is it a letter?
                    bne       IfEvalName yes, valid macro name
                    ldb       <CurChar  current char
                    cmpb      #'_       underscore?
                    beq       IfEvalName yes, valid macro name
                    leax      >IllegalIfMacroMsg,pcr "missing name" error
IfErr               pshs      x         push message pointer
                    lbsr      ReportWarn print the error
                    leas      2,s        drop arg
                    lbra      IfDefDone done

IfEvalName          leax      ,s        name buffer
                    pshs      x         push dest
                    lbsr      ReadIdent copy the macro name token
                    leas      2,s        drop arg
                    ldd       >Depth,y  current depth
                    lslb                shift low byte
                    rola                depth*2 = word index
                    leax      >SavedElseFlag,y  saved-else-flag stack
                    leax      d,x       index by depth
                    ldd       >SeenElseFlag,y  current seen-else flag
                    std       ,x        push it onto the stack
                    ldd       #1        reset value
                    std       >SeenElseFlag,y  clear seen-else flag
                    ldd       >Depth,y  current depth
                    addd      #1        increment it
                    std       >Depth,y  save new depth
                    subd      #1        recover old depth
                    lslb                shift low byte
                    rola                old depth*2 = word index
                    leax      >EnclosingActiveState,y  active-flag stack
                    leax      d,x       index by depth
                    ldd       >OutputEnabled,y  current active flag
                    std       ,x        push it onto the stack
                    std       -2,s      test the outer active flag
                    beq       IfDefDone outer region off, stay inactive
                    leax      ,s        name buffer
                    pshs      x         push it
                    lbsr      LookupMacro look up the macro
                    std       ,s++      save the lookup result
                    bne       MacroFound2 macro found
                    ldd       #1        not defined -> 1
                    bra       ApplySense combine with sense

MacroFound2         clra                defined -> 0
                    clrb                clear B
ApplySense          eora      13,s      XOR with ifdef/ifndef sense
                    eorb      14,s      XOR low byte
                    std       >OutputEnabled,y  set new active flag
IfDefDone           leas      9,s        drop local scratch bytes
                    puls      pc,u      return from #ifdef/#ifndef

DoElse              pshs      u         save U for #else handler
                    ldd       #$FFBA    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    ldd       >SeenElseFlag,y  any open #if group?
                    bne       ElseHasIf yes, evaluate the else
                    leax      >NoIfForElseMsg,pcr point at 'no #if for #else'
                    pshs      x         push message pointer
                    lbsr      ReportWarn report the error
                    puls      pc,u,x    return

ElseHasIf           ldd       >Depth,y  B = current #if nesting depth
                    addd      #$FFFF    index the enclosing #if (depth-1)
                    lslb                word-scale the index
                    rola                high byte of scaled index
                    leax      >EnclosingActiveState,y  enclosing active-state stack
                    leax      d,x       index into the stack
                    ldd       ,x        load enclosing active flag
                    beq       ElseInactive enclosing off -> else stays off
                    ldd       >OutputEnabled,y  this group already had a true branch?
                    bne       ElseInactive yes -> else branch off
                    ldd       #1        else branch becomes active
                    bra       ElseStoreActive store the new flag

ElseInactive        clra                else branch inactive
                    clrb                D = 0
ElseStoreActive     std       >OutputEnabled,y  set current output-active flag
                    clra                clear branch-seen flag
                    clrb                D = 0
                    bra       StoreIfBranchState store state and return

DoEndif             pshs      u         save U for #endif handler
                    ldd       #$FFBA    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    ldd       >Depth,y  any open #if to close?
                    bne       EndifPop  yes -> pop it
                    leax      >TooManyEndifMsg,pcr point at 'too many #endifs'
                    pshs      x         push message pointer
                    lbsr      ReportWarn report the error
                    puls      pc,u,x    return

EndifPop            ldd       >Depth,y  B = nesting depth
                    addd      #$FFFF    decrement the depth
                    std       >Depth,y  pop one #if level
                    lslb                word-scale the index
                    rola                high byte of scaled index
                    leax      >EnclosingActiveState,y  enclosing active-state stack
                    leax      d,x       index into the stack
                    ldd       ,x        load saved enclosing active flag
                    std       >OutputEnabled,y  restore outer output state
                    ldd       >Depth,y  nesting depth again
                    lslb                word-scale the index
                    rola                high byte of scaled index
                    leax      >SavedElseFlag,y  branch-seen stack
                    leax      d,x       index into the stack
                    ldd       ,x        restore saved branch-seen flag
StoreIfBranchState  std       >SeenElseFlag,y  store branch-seen state
                    puls      pc,u      return

CopyStringLit2      pshs      u         save U for literal copy
                    ldd       #$FFB9    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    leas      -1,s       reserve local for quote char
                    ldu       [<5,s]    U = destination buffer
                    ldb       <CurChar  current char is the opening quote
                    stb       ,s        remember the quote delimiter
CopyStrLoop         ldb       <CurChar  copy the current char
                    stb       ,u+       into the buffer
                    ldb       <CurChar  reload current char
                    cmpb      #'\       backslash escape?
                    bne       CopyStrNext no -> normal handling
                    clra                yes, take next char verbatim
                    clrb                D = 0
                    pshs      b,a       push flag argument
                    lbsr      NextChar  get the escaped char
                    leas      2,s        drop argument
                    ldb       <CurChar  copy the escaped char
                    stb       ,u+       into the buffer
CopyStrNext         clra                request next char
                    clrb                D = 0
                    pshs      b,a       push argument
                    lbsr      NextChar  advance to the next char
                    leas      2,s        drop argument
                    ldb       <CurChar  current char
                    beq       CopyStrDone end of line -> done
                    ldb       <CurChar  current char
                    sex                 sign-extend to D
                    pshs      b,a       push it
                    ldb       2,s       compare with stored quote
                    sex                 sign-extend to D
                    cmpd      ,s++      matches closing quote?
                    bne       CopyStrLoop no -> keep copying
CopyStrDone         stu       [<5,s]    save updated buffer pointer
                    leas      1,s        drop quote local
                    puls      pc,u      return

ReadIdent           pshs      u         save U for identifier read
                    ldd       #$FFB8    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    ldu       4,s       U = identifier buffer
                    leas      -2,s       reserve length counter
                    ldd       #1        _start length at 1
                    bra       IdentCheck enter the length check

IdentLoop           ldb       <CurChar  store the identifier char
                    stb       ,u+       into the buffer
                    ldd       #1        request one char
                    pshs      b,a       push argument
                    lbsr      NextChar  get next char
                    leas      2,s        drop argument
                    ldd       ,s        bump the length
                    addd      #1        add one
IdentCheck          std       ,s        save the length
                    ldd       ,s        reload length
                    cmpd      #9        reached max identifier length?
                    bge       IdentTerminate yes -> terminate
                    ldb       <CurChar  classify current char
                    sex                 sign-extend to D
                    leax      >XCharacterClass,y  char-class table
                    leax      d,x       index into the table
                    ldb       ,x        load class byte
                    clra                clear high byte
                    andb      #$0E      alphanumeric?
                    bne       IdentLoop yes -> keep collecting
                    ldb       <CurChar  current char
                    cmpb      #'_       underscore?
                    lbeq      IdentLoop also an identifier char
IdentTerminate      clra                terminate identifier
                    clrb                D = 0
                    stb       ,u        NUL-terminate the buffer
                    bra       IdentSkipCheck check for trailing chars

IdentSkipLoop       ldd       #1        request a char to skip
                    pshs      b,a       push argument
                    lbsr      NextChar  get next char
                    leas      2,s        drop argument
IdentSkipCheck      ldb       <CurChar  classify current char
                    sex                 sign-extend to D
                    leax      >XCharacterClass,y  char-class table
                    leax      d,x       index into the table
                    ldb       ,x        load class byte
                    clra                clear high byte
                    andb      #$0E      alphanumeric?
                    bne       IdentSkipLoop keep skipping
                    ldb       <CurChar  current char
                    cmpb      #'_       underscore?
                    lbeq      IdentSkipLoop skip it too
                    puls      pc,u,x    return

ReadLine            pshs      u         save U for line read
                    ldd       #$FFB6    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
ReadLineLoop        lbsr      ReadSourceLine read one source line
                    std       -2,s      got a line?
                    beq       PopInclude no -> input exhausted
                    ldd       <LineSyncFlag line-suppression flag set?
                    beq       LineReady no -> line ready
                    leax      >BaseLineBuffer,y  line buffer
                    pshs      x         push buffer pointer
                    ldd       #54       output opcode $36
                    pshs      b,a       push it
                    lbsr      EmitDirective emit directive to pass2
                    leas      4,s        drop arguments
LineReady           ldd       #1        return line-available
                    puls      pc,u      return

PopInclude          ldd       <CurFile  current file handle
                    pshs      b,a       push it
                    lbsr      FileClose close finished input file
                    leas      2,s        drop argument
                    ldd       <IncludeStack any saved include context?
                    lbeq      ReadLineEOF none -> real EOF
                    ldx       <IncludeStack pop include-stack node
                    ldd       4,x       restore saved char
                    std       <CurFile  into current char
                    ldx       <IncludeStack node pointer again
                    ldd       2,x       restore saved line number
                    std       <LineNum  into line counter
                    ldx       <IncludeStack node pointer again
                    ldd       6,x       restore saved filename
                    pshs      b,a       push it
                    leax      >XSourceName,y  filename scratch
                    pshs      x         push pointer
                    lbsr      strcpy    copy filename string
                    leas      4,s        drop arguments
                    ldd       <IncludeStack node pointer
                    addd      #8        node's stored name field
                    pshs      b,a       push it
                    leax      >XOutputName,y  second name scratch
                    pshs      x         push pointer
                    lbsr      strcpy    copy it
                    leas      4,s        drop arguments
                    ldd       [>IncludeStack,y] unlink the popped node
                    std       <IncludeStack update include head
                    leax      >XOutputName,y  name scratch pointer
                    pshs      x         push it
                    leax      >XSourceName,y  filename scratch pointer
                    pshs      x         push it
                    ldd       #55       output opcode $37
                    pshs      b,a       push it
                    lbsr      EmitDirective emit resumed-file directive
                    leas      6,s        drop arguments
                    ldd       <LineNum  restored line number
                    pshs      b,a       push it
                    ldd       #53       output opcode $35
                    pshs      b,a       push it
                    lbsr      EmitDirective emit line-number directive
                    leas      4,s        drop arguments
                    lbra      ReadLineLoop resume reading outer file

ReadLineEOF         clra                no more input
                    clrb                D = 0
                    puls      pc,u      return EOF

                    puls      pc,u      unreachable tail

SkipSpaces          pshs      u         save U for space skip
                    ldd       #$FFBA    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    bra       SkipSpTest enter the space test

SkipSpLoop          ldd       #1        request next char
                    pshs      b,a       push argument
                    bsr       NextChar  get next char
                    leas      2,s        drop argument
SkipSpTest          ldb       <CurChar  current char
                    cmpb      #'        space?
                    beq       SkipSpLoop skip it
                    puls      pc,u      return at first non-space

NextChar            pshs      u         save U for char fetch
                    ldd       #$FFBC    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    ldb       [>InPtr,y] read char at input pointer
                    stb       <CurChar  store as current char
                    bne       NextCharNonNul non-NUL -> process
                    puls      pc,u      end of buffer -> return

NextCharNonNul      ldd       4,s       caller wants line refill?
                    beq       AdvanceInput no -> just advance
                    bsr       SkipWsComment skip whitespace and comments
                    std       -2,s      anything consumed?
                    beq       AdvanceInput no -> advance normally
                    ldd       #'        collapse to a single space
                    stb       <CurChar  as the current char
                    bra       NextCharDone skip the plain advance

AdvanceInput        ldd       <InPtr    advance input pointer
                    addd      #1        by one
                    std       <InPtr    store it back
NextCharDone        puls      pc,u      return

SkipWsComment       pshs      u         save U for ws/comment skip
                    ldd       #$FFB9    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    leas      -3,s       reserve flag and char locals
                    clra                clear A
                    clrb                clear B
SkipWsSetFlag       std       ,s        clear whitespace-seen flag
SkipWsLoop          ldb       [>InPtr,y] peek current char
                    stb       2,s       save it
                    sex                 sign-extend to D
                    tfr       d,x       char into X for dispatch
                    lbra      SkipWsDispatch dispatch on char class

TabToSpace          ldd       #'        turn tab/formfeed into a space
                    stb       [>InPtr,y] in the input buffer
SkipWsSpace         ldd       <InPtr    advance input pointer
                    addd      #1        by one
                    std       <InPtr    store it back
                    ldd       #1        mark whitespace seen
                    bra       SkipWsSetFlag loop with flag set

MaybeComment        ldx       <InPtr    peek char after '/'
                    ldb       1,x       next char
                    cmpb      #42       _start of a comment?
                    bne       SkipWsDone no -> stop skipping
                    ldd       #1        remember whitespace seen
                    std       ,s        save flag
                    ldd       <InPtr    skip past the '/*'
                    addd      #2        two chars
                    bra       CommentStorePtr store input pointer

CommentScan         ldb       2,s       at end of buffer?
                    bne       CommentAdvance no -> advance
                    bsr       ReadSourceLine refill line inside comment
                    std       -2,s      line available?
                    bne       CommentReadChar yes -> keep scanning
                    bra       SkipWsDone EOF ends the comment

                    bra       CommentReadChar unreachable

CommentAdvance      ldd       <InPtr    advance past comment char
                    addd      #1        by one
CommentStorePtr     std       <InPtr    store input pointer
CommentReadChar     ldb       [>InPtr,y] read next comment char
                    stb       2,s       save it
                    cmpb      #'*       possible comment end '*'?
                    bne       CommentScan no -> keep scanning
                    ldx       <InPtr    peek char after '*'
                    ldb       1,x       next char
                    cmpb      #'/       closing '/'?
                    lbne      CommentScan no -> keep scanning
                    ldd       <InPtr    skip past the '*/'
                    addd      #2        two chars
                    std       <InPtr    store input pointer
                    lbra      SkipWsLoop resume outer skip loop

SkipWsDone          ldd       ,s        return whitespace-seen flag
                    bra       SkipWsExit exit

SkipWsDispatch      cmpx      #12       formfeed?
                    lbeq      TabToSpace treat as space
                    cmpx      #9        tab?
                    lbeq      TabToSpace treat as space
                    cmpx      #'        space?
                    lbeq      SkipWsSpace skip it
                    cmpx      #'/       slash (comment)?
                    lbeq      MaybeComment check for comment
                    bra       SkipWsDone other char -> stop

SkipWsExit          leas      3,s        drop locals
                    puls      pc,u      return

ReadSourceLine      pshs      u         save U for source-line read
                    ldd       #$FFB6    stack margin to reserve
                    lbsr      stkcheck  check for stack overflow
                    leas      -4,s       reserve char and count locals
                    ldd       #256      max line length 256
                    std       2,s       save the count
                    leax      >BaseLineBuffer,y  line buffer
                    stx       <InPtr    reset input pointer to buffer
                    leau      ,x        U = buffer write pointer
                    ldd       <CurFile  current file handle
                    pshs      b,a       push it
                    lbsr      GetChar   read next char from source
                    leas      2,s        drop argument
                    std       ,s        save the char
                    cmpd      #$FFFF    read error or EOF?
                    bne       LineCharCheck no -> store the char
                    ldx       <CurFile  inspect file status block
                    ldd       6,x       status flags
                    clra                clear high byte
                    andb      #$20      real read-error bit?
                    beq       EmptyLine no -> plain EOF
                    leax      >ReadErrMsg,pcr point at 'source file read error'
                    pshs      x         push message pointer
                    lbsr      ReportError report the source read error
                    leas      2,s        drop the message pointer
EmptyLine           clra                prepare an empty line
                    clrb                D = 0
                    stb       ,u        NUL-terminate the empty line
                    sex                 sign-extend the char
                    bra       ReadLineExit return with no line read

                    bra       LineCharCheck (unreachable) resume reading

StoreLineChar       ldd       ,s        B = char just read
                    stb       ,u+       store it into the line buffer
                    ldd       <CurFile  D = current input file
                    pshs      b,a       pass the file to the reader
                    lbsr      GetChar   read the next char
                    leas      2,s        drop the argument
                    std       ,s        save the returned char
LineCharCheck       ldd       ,s        get the current char
                    cmpd      #13       carriage return ends the line?
                    beq       LineComplete yes, line complete
                    ldd       ,s        reload the char
                    cmpd      #$FFFF    end of file?
                    beq       LineComplete yes, line complete
                    ldd       2,s       remaining room in the buffer
                    addd      #$FFFF    decrement the count
                    std       2,s       save it back
                    subd      #$FFFF    undo for the flag test
                    bgt       StoreLineChar room left, keep reading
LineComplete        ldd       2,s       remaining count
                    bge       TerminateLine line fit in the buffer?
                    leax      >LineTooLongMsg,pcr point at "source file line too long"
                    pshs      x         push the message
                    lbsr      ReportError report the error
                    leas      2,s        drop the message pointer
TerminateLine       clra                prepare the terminator
                    clrb                D = 0
                    stb       ,u        NUL-terminate the line
                    ldd       <LineNum  current line number
                    addd      #1        advance to the next line
                    std       <LineNum  save the line number
                    ldd       #1        return the line-read flag
ReadLineExit        leas      4,s        drop the locals
                    puls      pc,u      restore U and return

DefineStr           fcc       "define"
                    fcb       C$NULL
IncludeStr          fcc       "include"
                    fcb       C$NULL
IfdefStr            fcc       "ifdef"
                    fcb       C$NULL
IfndefStr           fcc       "ifndef"
                    fcb       C$NULL
EndifStr            fcc       "endif"
                    fcb       C$NULL
ElseStr             fcc       "else"
                    fcb       C$NULL
UndefStr            fcc       "undef"
                    fcb       C$NULL
AsmStr              fcc       "asm"
                    fcb       C$NULL
EndasmStr           fcc       "endasm"
                    fcb       C$NULL
LineStr             fcc       "line"
                    fcb       C$NULL
IllegalHashMsg      fcc       "illegal '#'"
                    fcb       C$NULL
IllegalMacroMsg     fcc       "illegal macro name"
                    fcb       C$NULL
MacroDefErrMsg      fcc       "macro definition error"
                    fcb       C$NULL
DdPathStr           fcc       "/dd"
                    fcb       C$NULL
DefsPathStr         fcc       "/defs/"
                    fcb       C$NULL
ReadModeStr         fcc       "r"
                    fcb       C$NULL
CantOpenMsg         fcc       "can't open"
                    fcb       C$NULL
BadIncludeMsg       fcc       "bad include file"
                    fcb       C$NULL
IfNestDeepMsg       fcc       "'#if' nesting too deep"
                    fcb       C$NULL
IllegalIfMacroMsg   fcc       "illegal '#if' macro name"
                    fcb       C$NULL
NoIfForElseMsg      fcc       "no '#if' for '#else'"
                    fcb       C$NULL
TooManyEndifMsg     fcc       "too many #endifs"
                    fcb       C$NULL
ReadErrMsg          fcc       "source file read error"
                    fcb       C$NULL
LineTooLongMsg      fcc       "source file line too long"
                    fcb       C$NULL

ReportError         pshs      u         save the caller U
                    ldd       #49       severity '1' marks a fatal error
                    pshs      b,a       push the severity
                    ldd       <LineNum  current line number
                    pshs      b,a       push it
                    ldd       8,s       the diagnostic line number
                    pshs      b,a       push it
                    leax      >BaseLineBuffer,y  base of the line buffer
                    pshs      x         push it
                    ldd       <TokenStart position of the error
                    subd      ,s++      column = position minus buffer _start
                    pshs      b,a       push the column
                    bsr       FormatDiag format the diagnostic
                    leas      8,s        drop the arguments
                    ldd       #1        exit status 1
                    pshs      b,a       push it
                    lbsr      exit      flush output and exit
                    puls      pc,u,x    (never reached) restore and return

ReportWarnAtMark    pshs      u         save the caller U
                    ldd       #48       severity '0' marks a warning
                    pshs      b,a       push the severity
WarnEmitBody        ldd       <LineNum  current line number
                    pshs      b,a       push it
                    ldd       8,s       the diagnostic line number
                    pshs      b,a       push it
                    leax      >BaseLineBuffer,y  base of the line buffer
                    pshs      x         push it
                    ldd       <TokenStart position of the warning
                    bra       DiagColumn compute column and format

ReportWarn          pshs      u         save the caller U
                    ldd       #48       severity '0' marks a warning
                    pshs      b,a       push the severity
                    ldd       <LineNum  current line number
                    pshs      b,a       push it
                    ldd       8,s       the diagnostic line number
                    pshs      b,a       push it
                    leax      >BaseLineBuffer,y  base of the line buffer
                    pshs      x         push it
                    ldd       <InPtr    current scan position
DiagColumn          subd      ,s++      column = position minus buffer _start
                    pshs      b,a       push the column
                    bsr       FormatDiag format the diagnostic
WarnReturn          leas      8,s        drop the arguments
                    puls      pc,u      restore U and return

FormatDiag          pshs      u         save the caller U
                    ldd       8,s       the requested line number
                    cmpd      <LineNum  same as the current line?
                    bne       ChkPrevLine no, check the previous line
                    leau      >BaseLineBuffer,y  use the current line buffer
                    bra       EmitDiagLine go emit it

ChkPrevLine         ldd       <LineNum  current line number
                    addd      #$FFFF    current line minus one
                    cmpd      8,s       matches the previous line?
                    bne       NoDiagLine no, use empty text
                    leau      >XBackupBuffer,y  use the previous line buffer
                    bra       EmitDiagLine go emit it

NoDiagLine          leau      >EmptyStr,pcr no source line available

EmitDiagLine        pshs      u         push the source line pointer
                    ldd       12,s      the severity character
                    pshs      b,a       push it
                    bsr       EmitDirective emit the severity marker
                    leas      4,s        drop the argument
                    ldd       8,s       the line number
                    pshs      b,a       push it
                    leax      >FmtDecLine,pcr "%d" format
                    pshs      x         push the format
                    lbsr      Printf    print the line number
                    leas      4,s        drop the arguments
                    ldd       6,s       the column
                    pshs      b,a       push it
                    ldd       6,s       the column again
                    pshs      b,a       push it
                    leax      >FmtLineFile,pcr "%d %s" format
                    pshs      x         push the format
                    lbsr      Printf    print column and source text
                    leas      6,s        drop the arguments
                    puls      pc,u      restore U and return

CopyStrEnd          pshs      u         save the caller U
                    ldu       4,s       destination buffer
CopyStrLoop2        ldx       6,s       source pointer
                    leax      1,x       advance the source
                    stx       6,s       save it back
                    ldb       -1,x      fetch the source byte
                    stb       ,u+       copy it to the destination
                    bne       CopyStrLoop2 loop until the NUL
                    pshs      u         push the end pointer
                    ldd       #$FFFF    back up over the NUL
                    addd      ,s++      adjust the pointer
                    puls      pc,u      return the terminator position

EmitDirective       pshs      u         save the caller U
                    ldx       4,s       the directive opcode
                    bra       EmitOpDispatch dispatch on it

EmitOpTwoStr        ldd       8,s       operand string
                    pshs      b,a       push it
                    ldd       8,s       operand string again
                    pshs      b,a       push it
                    ldd       8,s       operand string again
                    pshs      b,a       push it
                    ldd       #35       '#' record marker
                    pshs      b,a       push it
                    leax      >FmtErrCharStr,pcr "%c%c %s %s" format
                    pshs      x         push the format
                    lbsr      Printf    emit the two-string directive
                    leas      10,s       drop the arguments
                    bra       EmitOpDone done

EmitOpNum           ldd       6,s       numeric operand
                    pshs      b,a       push it
                    ldd       6,s       numeric operand again
                    pshs      b,a       push it
                    ldd       #35       '#' record marker
                    pshs      b,a       push it
                    leax      >FmtErrCharDec,pcr "%c%c %d" format
                    bra       EmitOpTail go emit

EmitOpStr           ldd       6,s       string operand
                    pshs      b,a       push it
                    ldd       6,s       string operand again
                    pshs      b,a       push it
                    ldd       #35       '#' record marker
                    pshs      b,a       push it
                    leax      >FmtErrCharOneStr,pcr "%c%c %s" format
EmitOpTail          pshs      x         push the format
                    lbsr      Printf    emit the directive
                    leas      8,s        drop the arguments
                    bra       EmitOpDone done

EmitOpDispatch      cmpx      #55       opcode $37?
                    beq       EmitOpTwoStr two-string form
                    cmpx      #80       opcode $50?
                    lbeq      EmitOpTwoStr two-string form
                    cmpx      #53       opcode $35?
                    beq       EmitOpNum numeric form
                    bra       EmitOpStr otherwise single-string form

EmitOpDone          puls      pc,u      restore U and return

HashName            pshs      u         save the caller U
                    ldu       4,s       the name to hash
                    leas      -4,s       make room for locals
                    clra                clear the accumulator
                    clrb                D = 0
                    bra       HashNext  enter the hash loop

HashAdd             ldd       2,s       running sum
                    addd      ,s        add the current byte
HashNext            std       2,s       save the accumulator
                    ldb       ,u+       next name byte
                    sex                 sign-extend it
                    std       ,s        save the byte
                    bne       HashAdd   loop until the NUL
                    ldd       2,s       final sum
                    clra                keep the low byte
                    andb      #$7F      mask to 0-127
                    leas      4,s        drop the locals
                    puls      pc,u      return the hash

EnsureHeap          pshs      u         save the caller U
                    ldd       <PoolPtr  heap pointer
                    cmpd      <PoolGuard still below the refill threshold?
                    bcs       EnsureHeapDone yes, nothing to do
                    ldd       #256      grow by 256 bytes
                    pshs      b,a       push the size
                    bsr       AllocBytes extend the heap
                    leas      2,s        drop the argument
                    std       <PoolPtr  adopt the new pointer
EnsureHeapDone      puls      pc,u      restore U and return

AllocBytes          pshs      u         save the caller U
                    ldu       4,s       requested size
                    leas      -2,s       make room for a local
                    ldd       <PoolPtr  current heap pointer
                    std       ,s        save the _start pointer
                    ldd       <PoolPtr  heap pointer again
                    cmpd      <PoolEnd  past the heap top?
                    bls       CheckHeapRoom no, check for room
                    leax      >ErrGrabOverlap,pcr point at "grab overlap"
                    pshs      x         push the message
                    lbsr      ReportError fatal error
                    leas      2,s        recheck for room
                    bra       CheckHeapRoom

GrowHeap            ldd       #256      request 256 more bytes
                    pshs      b,a       push the size
                    lbsr      AllocMem  allocate from the system
                    leas      2,s        drop the argument
                    cmpd      #$FFFF    allocation failed?
                    bne       HeapGrown no, record the growth
                    leax      >ErrOutOfMem,pcr point at "out of memory"
                    pshs      x         push the message
                    lbsr      ReportError fatal error
                    leas      2,s        drop the argument
HeapGrown           ldd       <PoolEnd  current heap top
                    addd      #256      extend the top by 256
                    std       <PoolEnd  save it
CheckHeapRoom       ldd       <PoolEnd  heap top
                    subd      <PoolPtr  bytes free in the heap
                    pshs      b,a       push the free count
                    pshs      u         push the request
                    ldd       #32       add a 32-byte margin
                    addd      ,s++      combine
                    cmpd      ,s++      enough for the request?
                    bhi       GrowHeap  no, grow the heap more
                    ldd       <PoolEnd  heap top
                    addd      #$FFE0    top minus 32
                    std       <PoolGuard set the refill threshold
                    ldd       <PoolPtr  current heap pointer
                    pshs      b,a       push it
                    tfr       u,d       the requested size
                    addd      ,s++      add the size
                    std       <PoolPtr  advance the heap pointer
                    ldd       ,s        return the old pointer
                    puls      pc,u,x    restore and return

InitHeap            pshs      u         save the caller U
                    ldd       4,s       initial heap size
                    pshs      b,a       push the size
                    lbsr      AllocMem  allocate from the system
                    leas      2,s        drop the argument
                    std       <PoolPtr  set the heap pointer
                    ldd       <PoolPtr  heap pointer
                    addd      4,s       plus the size
                    std       <PoolEnd  set the heap top
                    ldd       <PoolEnd  heap top
                    addd      #$FFE0    top minus 32
                    std       <PoolGuard set the refill threshold
                    puls      pc,u      restore U and return

StoreString         pshs      u         save the caller U
                    ldu       4,s       the source string
                    leas      -2,s       make room for a local
                    ldd       <PoolPtr  heap pointer
                    std       ,s        save the copy _start
StoreStringLoop     ldb       ,u+       next source byte
                    ldx       <PoolPtr  heap pointer
                    leax      1,x       advance it
                    stx       <PoolPtr  save it back
                    stb       -1,x      store the byte in the heap
                    bne       StoreStringLoop loop until the NUL
                    lbsr      EnsureHeap grow output buffer if near limit
                    ldd       ,s        D = _start of appended string
                    puls      pc,u,x    return the string pointer

AppendOutByte       pshs      u         save caller U
                    ldb       5,s       B = char argument
                    ldx       <PoolPtr  X = output write pointer
                    leax      1,x       advance write pointer
                    stx       <PoolPtr  save advanced pointer
                    stb       -1,x      store the char in buffer
                    lbsr      EnsureHeap grow buffer if near limit
                    ldd       <PoolPtr  D = new write pointer
                    addd      #$FFFF    back up to the stored char
                    puls      pc,u      return pointer to stored char

                    pshs      u,b,a     save registers
                    clra                clear A
                    clrb                clear B
                    pshs      b,a       push null terminator arg
                    ldd       #4        length of 'ccdevice'
                    pshs      b,a       push length
                    leax      >StrCcDevice,pcr X = 'ccdevice' name
                    pshs      x         push name pointer
                    lbsr      LinkModule look up the ccdevice env var
                    leas      6,s        drop lookup args
                    tfr       d,u       U = env handle
                    cmpu      #$FFFF    lookup failed?
                    bne       CcDevEnvFound got a handle
                    lbsr      ReadInitVar fall back to Init path
                    bra       CcDevDone return that result

CcDevEnvFound       pshs      u         save handle
                    ldd       FilePath,u D = value offset field
                    addd      ,s++      add the base pointer
                    std       ,s        save value pointer
                    pshs      b,a       push source pointer
                    leax      >XY54c,y  X = Y+$54C dest buffer
                    pshs      x         push dest pointer
                    lbsr      strcpy    copy the string
                    leas      4,s        drop copy args
                    pshs      u         push env handle
                    lbsr      UnlinkModule release the env handle
                    leas      2,s        drop arg
                    leax      >XY54c,y  X = result buffer
                    tfr       x,d       D = result buffer pointer
CcDevDone           puls      pc,u,x    return the buffer

                    puls      pc,u,x    dead alternate return

EmptyStr            fcb       C$NULL
FmtDecLine          fcc       "%d"
                    fcb       C$CR
                    fcb       C$NULL
FmtLineFile         fcc       "%d"
                    fcb       C$CR
                    fcc       "%s"
                    fcb       C$CR
                    fcb       C$NULL
FmtErrCharStr       fcc       "%c%c"
                    fcb       C$CR
                    fcc       "%s"
                    fcb       C$CR
                    fcc       "%s"
                    fcb       C$CR
                    fcb       C$NULL
FmtErrCharDec       fcc       "%c%c"
                    fcb       C$CR
                    fcc       "%d"
                    fcb       C$CR
                    fcb       C$NULL
FmtErrCharOneStr    fcc       "%c%c"
                    fcb       C$CR
                    fcc       "%s"
                    fcb       C$CR
                    fcb       C$NULL

ErrGrabOverlap      fcc       "grab overlap"
                    fcb       C$NULL

ErrOutOfMem         fcc       "out of memory"
                    fcb       C$NULL
StrCcDevice         fcc       "ccdevice"
                    fcb       C$NULL

ReadInitVar         pshs      u         save caller U
                    leas      -7,s       reserve seven local bytes
                    clra                clear A
                    clrb                clear B
                    pshs      b,a       push null terminator arg
                    ldd       #12       length of 'Init'
                    pshs      b,a       push length
                    leax      >StrInitVar,pcr X = 'Init' name
                    pshs      x         push name pointer
                    lbsr      LinkModule look up the Init env var
                    leas      6,s        drop lookup args
                    std       ,s        save the handle
                    cmpd      #$FFFF    not found?
                    beq       ReadInitNull give up if absent
                    ldd       ,s        reload handle
                    ldx       ,s        X = handle
                    addd      <16,x     point at the value text
                    std       5,s       save source pointer
                    leau      >UY560,y  U = Y+$560 dest buffer
                    bra       InitCopyLoop enter copy loop

InitCopyChar        ldb       4,s       reload current char
InitStoreChar       stb       ,u+       store char into buffer
InitCopyLoop        ldx       5,s       X = source pointer
                    leax      1,x       advance source
                    stx       5,s       save source pointer
                    ldb       -1,x      B = source char
                    stb       4,s       stash the char
                    bgt       InitCopyChar loop while high bit clear
                    ldb       4,s       reload final char
                    clra                clear A
                    andb      #$7F      strip the terminator bit
                    stb       ,u+       store final char
                    clra                clear A
                    clrb                clear B
                    stb       ,u        null terminate the buffer
                    ldd       ,s        reload handle
                    pshs      b,a       push handle
                    lbsr      UnlinkModule release the env handle
                    leas      2,s        drop arg
                    leax      >UY560,y  X = result buffer
                    tfr       x,d       D = result buffer pointer
                    bra       ReadInitDone return the buffer

ReadInitNull        clra                clear A
                    clrb                clear B for null return
ReadInitDone        leas      7,s        drop locals
                    puls      pc,u      return

StrInitVar          fcc       "Init"
                    fcb       C$NULL

FindFreeStream      pshs      u         save caller U
                    leau      >UStartFile,y  U = _start of FILE table
StreamSlotLoop      ldd       ExpandPtr,u D = stream flags
                    clra                clear A
                    andb      #$03      slot in use?
                    lbeq      StreamRetOk free slot found
                    leau      FileEntStride,u advance to next FILE entry
                    pshs      u         push current entry
                    leax      >XEndTable,y  X = end of table
                    cmpx      ,s++      past the last entry?
                    bhi       StreamSlotLoop loop while entries remain
                    ldd       #200      errno 200 too many files
                    std       >Errno,y  store errno
                    lbra      StreamRetNull return null

                    puls      pc,u      dead return

InitStream          pshs      u         save caller U
                    ldu       8,s       U = caller FILE pointer
                    bne       StreamGotSlot use it if supplied
                    bsr       FindFreeStream else find a free slot
                    tfr       d,u       U = the slot
StreamGotSlot       stu       -2,s      remember slot
                    beq       StreamRetNull no slot so fail
                    ldd       4,s       D = file descriptor
                    std       InPtr,u   store fd in stream
                    ldx       6,s       X = mode string
                    ldb       1,x       second char
                    cmpb      #'+       '+' update mode?
                    beq       SetRdWrMode set read and write
                    ldx       6,s       X = mode string
                    ldb       2,x       third char
                    cmpb      #'+       '+' update mode?
                    bne       ChkModeFirst no plus so pick one mode
SetRdWrMode         ldd       ExpandPtr,u load flags
                    orb       #$03      set read and write flags
                    bra       StreamSetBuffer store the flags

ChkModeFirst        ldd       ExpandPtr,u load flags
                    pshs      b,a       save flags
                    ldb       [<8,s]    first mode char
                    cmpb      #'r       'r' read?
                    beq       SetReadMode select read
                    ldb       [<8,s]    first mode char
                    cmpb      #'d       'd' device?
                    bne       SetWriteMode not read so select write
SetReadMode         ldd       #1        read flag
                    bra       MergeModeFlags merge it in

SetWriteMode        ldd       #2        write flag
MergeModeFlags      ora       ,s+       merge chosen bit high byte
                    orb       ,s+       merge chosen bit low byte
StreamSetBuffer     std       ExpandPtr,u store the stream flags
                    ldd       FileBufBase,u buffer base pointer
                    addd      FileBufSize,u plus buffer size
                    std       TokenStart,u set buffer end
                    std       ,u        current pointer at end (empty)
StreamRetOk         tfr       u,d       return the stream pointer
                    puls      pc,u      return

StreamRetNull       clra                clear A
                    clrb                clear B for null return
                    puls      pc,u      return null

OpenFileByMode      pshs      u         save caller U
                    ldu       4,s       U = filename
                    leas      -4,s       reserve four local bytes
                    clra                clear A
                    clrb                clear B
                    std       ,s        clear access mode local
                    ldx       10,s      X = mode string
                    ldb       1,x       second char
                    sex                 sign extend
                    tfr       d,x       X = second char
                    bra       ModeScanSecond dispatch on second char

ChkThirdPlus        ldx       10,s      X = mode string
                    ldb       2,x       third char
                    cmpb      #'+       '+' update?
                    bne       SetAccessWrite no plus after x
                    ldd       #7        access mode 7
                    bra       StoreAccessMode store it

SetAccessWrite      ldd       #4        access mode 4
                    bra       StoreAccessMode store it

SetAccessRdWr       ldd       #3        access mode 3
StoreAccessMode     std       ,s        save access mode
                    bra       ModeDispatchFirst go dispatch first char

ModeInvalid         leax      4,s       restore stack pointer
                    lbra      ModeBadFixup invalid mode string

ModeScanSecond      stx       -2,s      remember second char
                    beq       ModeDispatchFirst none so dispatch first char
                    cmpx      #120      'x' char?
                    beq       ChkThirdPlus check third char
                    cmpx      #43       '+' char?
                    beq       SetAccessRdWr set update mode
                    bra       ModeInvalid otherwise invalid

ModeDispatchFirst   ldb       [<10,s]   first mode char
                    sex                 sign extend
                    tfr       d,x       X = first char
                    lbra      MatchModeChar dispatch on it

ModeRead2           ldd       ,s        read access base
                    orb       #$01      set read bit
                    bra       OpenPath  open the path

ModeAppend          ldd       ,s        append access base
                    orb       #$02      set write bit
                    pshs      b,a       push access mode
                    pshs      u         push filename
                    lbsr      open      try open existing file
                    leas      4,s        drop args
                    std       2,s       save the fd
                    cmpd      #$FFFF    does not exist?
                    beq       ModeCreate create it instead
                    ldd       #2        seek whence = end
                    pshs      b,a       push whence
                    clra                clear A
                    clrb                clear B
                    pshs      b,a       push offset high
                    pshs      b,a       push offset low
                    ldd       8,s       fd argument
                    pshs      b,a       push fd
                    lbsr      SeekFile  seek to end of file
                    leas      8,s        drop seek args
                    bra       OpenRetFd return the fd

ModeCreate          ldd       ,s        create access base
                    orb       #$02      set write bit
                    pshs      b,a       push access mode
                    pshs      u         push filename
                    lbsr      creat     create the file
                    bra       OpenStoreFd store the new fd

ModeDevice          ldd       ,s        device access base
                    orb       #$81      set device flag $81
OpenPath            pshs      b,a       push access mode
                    pshs      u         push filename
                    lbsr      open      open the file
OpenStoreFd         leas      4,s        drop args
                    std       2,s       save the fd
                    bra       OpenRetFd return the fd

ModeBadFixup        leas      -4,x      restore stack pointer
BadModeErr          ldd       #203      errno 203 bad mode
                    std       >Errno,y  store errno
                    clra                clear A
                    clrb                clear B for failure
                    bra       OpenRetDone go to exit

MatchModeChar       cmpx      #114      'r' read?
                    lbeq      ModeRead2 handle read mode
                    cmpx      #97       'a' append?
                    lbeq      ModeAppend handle append mode
                    cmpx      #119      'w' write?
                    beq       ModeCreate handle create mode
                    cmpx      #100      'd' device?
                    beq       ModeDevice handle device mode
                    bra       BadModeErr unknown mode error

OpenRetFd           ldd       2,s       D = returned fd
OpenRetDone         leas      4,s        drop locals
                    puls      pc,u      return

                    pshs      u         save U (dead code)
                    clra                clear A
                    clrb                clear B
                    pshs      b,a       push null slot pointer
                    ldd       8,s       fd argument
                    pshs      b,a       push fd
                    ldd       8,s       mode argument
                    pshs      b,a       push mode
                    lbra      FopenCallInit init the stream

Fopen               pshs      u         save caller U
                    ldd       6,s       filename argument
                    pshs      b,a       push filename
                    ldd       6,s       mode string argument
                    pshs      b,a       push mode
                    lbsr      OpenFileByMode open or create the file
                    leas      4,s        drop args
                    tfr       d,u       U = fd
                    cmpu      #$FFFF    open failed?
                    bne       FopenGotFd got a valid fd
                    clra                clear A
                    clrb                clear B for null return
                    bra       MacroLookupDone return null stream

FopenGotFd          clra                clear A
                    clrb                clear B
                    bra       FopenInitArgs go bind fd to a slot

                    pshs      u         save U (dead code)
                    ldd       8,s       stream argument
                    pshs      b,a       push stream
                    lbsr      FileClose close the old stream
                    leas      2,s        drop arg
                    ldd       6,s       filename argument
                    pshs      b,a       push filename
                    ldd       6,s       mode argument
                    pshs      b,a       push mode
                    lbsr      OpenFileByMode reopen with the mode
                    leas      4,s        drop args
                    tfr       d,u       U = fd
                    stu       -2,s      remember fd
                    bge       FreopenGotFd got a valid fd
                    clra                clear A
                    clrb                clear B for null return
                    bra       MacroLookupDone return null stream

FreopenGotFd        ldd       8,s       fd argument
FopenInitArgs       pshs      b,a       push fd
                    ldd       8,s       stream slot argument
                    pshs      b,a       push slot
                    pshs      u         push null buffer
FopenCallInit       lbsr      InitStream init the stream
                    leas      6,s        drop the three call arguments
MacroLookupDone     puls      pc,u      return, macro lookup done

Printf              pshs      u         save caller U
                    leax      >XInternalScratch,y  X -> internal scratch output buffer
                    stx       >OutputPointerBuffer,y  set current output pointer
                    leax      6,s       X -> varargs following the format
                    pshs      x         pass the argument pointer
                    ldd       6,s       D = format string pointer
                    bra       RunFormat go run the format engine

                    pshs      u         save caller U
                    ldd       4,s       D = destination buffer
                    std       >OutputPointerBuffer,y  set output pointer to the buffer
                    leax      8,s       X -> varargs
                    pshs      x         pass the argument pointer
                    ldd       8,s       D = format string pointer
RunFormat           pshs      b,a       push the format string
                    leax      >FilePutcCB,pcr X -> console char-output callback
                    pshs      x         pass the output callback
                    bsr       Doprnt    run the format engine
                    leas      6,s        drop callback, format, args pointer
                    puls      pc,u      return

                    pshs      u         save caller U
                    ldd       4,s       D = destination buffer
                    std       >OutputPointerBuffer,y  set output pointer to the buffer
                    leax      8,s       X -> varargs
                    pshs      x         pass the argument pointer
                    ldd       8,s       D = format string pointer
                    pshs      b,a       push the format string
                    leax      >BufPutcCB,pcr X -> buffer char-store callback
                    pshs      x         pass the output callback
                    bsr       Doprnt    run the format engine
                    leas      6,s        drop callback, format, args pointer
                    clra                A = 0
                    clrb                D = 0 for the terminator
                    stb       [>OutputPointerBuffer,y] NUL-terminate the output buffer
                    ldd       4,s       return the destination buffer pointer
                    puls      pc,u      return

Doprnt              pshs      u         save caller U
                    ldu       6,s       U -> format string
                    leas      -11,s      reserve local workspace
                    bra       FormatLoop _start scanning the format

EmitLiteral         ldb       8,s       B = current literal char
                    lbeq      DoprntDone NUL -> whole format done
                    ldb       8,s       reload the char
                    sex                 extend to D
                    pshs      b,a       pass char to the callback
                    jsr       [<17,s]   call the char-output callback
                    leas      2,s        drop the char argument
FormatLoop          ldb       ,u+       fetch the next format character
                    stb       8,s       save the current char
                    cmpb      #'%       '%' conversion introducer?
                    bne       EmitLiteral no, emit it literally
                    ldb       ,u+       fetch the char after '%'
                    stb       8,s       save it
                    clra                A = 0
                    clrb                D = 0
                    std       2,s       clear the precision
                    std       6,s       clear the width
                    ldb       8,s       B = char after '%'
                    cmpb      #'-       '-' left-justify flag?
                    bne       NoLeftFlag no, skip the flag
                    ldd       #1        flag value = 1
                    std       >LeftJustified,y  set the left-justify flag
                    ldb       ,u+       consume flag, fetch next char
                    stb       8,s       save it
                    bra       ChkZeroFlag go check the zero-pad flag

NoLeftFlag          clra                A = 0
                    clrb                D = 0
                    std       >LeftJustified,y  clear the left-justify flag
ChkZeroFlag         ldb       8,s       B = current char
                    cmpb      #'0       '0' zero-pad flag?
                    bne       FillSpace no, use space fill
                    ldd       #'0       fill character = '0'
                    bra       SetFill   store the pad character

FillSpace           ldd       #'        fill character = space
SetFill             std       >PadCharacter,y  store the chosen pad character
                    bra       WidthLoop scan the width digits

WidthDigit          ldd       6,s       D = accumulated width
                    pshs      b,a       save it
                    ldd       #10       base-10 multiplier
                    lbsr      MulEntry  width times ten
                    pshs      b,a       save the product
                    ldb       10,s      B = current digit char
                    sex                 extend to D
                    addd      #$FFD0    subtract '0' to get digit value
                    addd      ,s++      add to width times ten
                    std       6,s       store the new width
                    ldb       ,u+       fetch next format char
                    stb       8,s       save it
WidthLoop           ldb       8,s       B = current char
                    sex                 extend to D
                    leax      >XCharacterClass,y  X -> character-class table
                    leax      d,x       index by the character
                    ldb       ,x        B = class bits
                    clra                A = 0
                    andb      #$08      is-digit bit set?
                    bne       WidthDigit yes, keep accumulating width
                    ldb       8,s       B = current char
                    cmpb      #'.       '.' precision separator?
                    bne       NoPrec    no, precision stays unset
                    ldd       #1        mark precision present
                    std       4,s       set the precision flag
                    bra       PrecLoop  scan the precision digits

PrecDigit           ldd       2,s       D = accumulated precision
                    pshs      b,a       save it
                    ldd       #10       base-10 multiplier
                    lbsr      MulEntry  precision times ten
                    pshs      b,a       save the product
                    ldb       10,s      B = current digit char
                    sex                 extend to D
                    addd      #$FFD0    subtract '0' to get digit value
                    addd      ,s++      add to precision times ten
                    std       2,s       store the new precision
PrecLoop            ldb       ,u+       fetch next format char
                    stb       8,s       save it
                    ldb       8,s       B = current char
                    sex                 extend to D
                    leax      >XCharacterClass,y  X -> character-class table
                    leax      d,x       index by the character
                    ldb       ,x        B = class bits
                    clra                A = 0
                    andb      #$08      is-digit bit set?
                    bne       PrecDigit yes, keep accumulating precision
                    bra       ConvDispatch done, go dispatch the conversion

NoPrec              clra                A = 0
                    clrb                D = 0
                    std       4,s       clear the precision flag
ConvDispatch        ldb       8,s       B = conversion character
                    sex                 extend to D
                    tfr       d,x       X = conversion char for dispatch
                    lbra      ConvTable jump to the conversion table

ConvDecimal         ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    ldx       <21,s     X -> vararg pointer
                    leax      2,x       advance past this argument
                    stx       <21,s     save the updated pointer
                    ldd       -2,x      D = the int argument
                    pshs      b,a       pass the value
                    lbsr      IntToDec  convert signed decimal
                    bra       SetConvStr go store the result string

ConvOctal           ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    ldx       <21,s     X -> vararg pointer
                    leax      2,x       advance past the argument
                    stx       <21,s     save the updated pointer
                    ldd       -2,x      D = the argument value
                    pshs      b,a       pass the value
                    lbsr      FormatOctal convert to octal
SetConvStr          std       ,s        save the converted-string pointer
                    lbra      EmitConv  go emit the field

ConvHex             ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    ldb       10,s      B = conversion char
                    sex                 extend to D
                    leax      >XCharacterClass,y  X -> character-class table
                    leax      d,x       index by the character
                    ldb       ,x        B = class bits
                    clra                A = 0
                    andb      #$02      uppercase bit ('X' vs 'x')?
                    pshs      b,a       pass the uppercase flag
                    ldx       <23,s     X -> vararg pointer
                    leax      2,x       advance past the argument
                    stx       <23,s     save the updated pointer
                    ldd       -2,x      D = the argument value
                    pshs      b,a       pass the value
                    lbsr      FormatHex convert to hex
                    lbra      ConvCleanup go clean up and emit

ConvUnsigned        ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    ldx       <21,s     X -> vararg pointer
                    leax      2,x       advance past the argument
                    stx       <21,s     save the updated pointer
                    ldd       -2,x      D = the argument value
                    pshs      b,a       pass the value
                    leax      >XConversionBuffer,y  X -> conversion buffer
                    pshs      x         pass the buffer
                    lbsr      UnsignedToDec convert unsigned decimal
                    lbra      ConvCleanup go clean up and emit

ConvFloat           ldd       4,s       precision specified?
                    bne       FloatConv yes, keep it
                    ldd       #6        default float precision = 6
                    std       2,s       set it
FloatConv           ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    leax      <21,s     X -> vararg pointer slot
                    pshs      x         pass the args pointer
                    ldd       6,s       D = precision
                    pshs      b,a       pass the precision
                    ldb       14,s      B = conversion char (f/e/g)
                    sex                 extend to D
                    pshs      b,a       pass the format char
                    lbsr      FloatFmtStub convert floating point
                    leas      6,s        drop the arguments
                    lbra      PushConv  go emit the field

ConvChar            ldx       <19,s     X -> char vararg pointer
                    leax      2,x       advance past the argument
                    stx       <19,s     save the updated pointer
                    ldd       -2,x      D = the char argument
                    lbra      EmitDispatch emit the single char

ConvString          ldx       <19,s     X -> string vararg pointer
                    leax      2,x       advance past the argument
                    stx       <19,s     save the updated pointer
                    ldd       -2,x      D = string pointer
                    std       9,s       save the string pointer
                    ldd       4,s       precision specified?
                    beq       EmitStrFull no, print the whole string
                    ldd       9,s       D = string _start
                    std       4,s       set the scan pointer
                    bra       StrLenNext count up to the precision

StrLenLoop          ldb       [<9,s]    B = char at string position
                    beq       EmitStr   NUL -> stop counting
                    ldd       9,s       advance the string pointer
                    addd      #1        increment
                    std       9,s       save it
StrLenNext          ldd       2,s       D = remaining precision
                    addd      #$FFFF    decrement
                    std       2,s       save it
                    subd      #$FFFF    test for zero
                    bne       StrLenLoop keep counting
EmitStr             ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    ldd       11,s      D = end pointer
                    subd      6,s       length = end minus _start
                    pshs      b,a       pass the length
                    ldd       8,s       D = string _start
                    pshs      b,a       pass the string pointer
                    ldd       <21,s     D = left-justify flag
                    pshs      b,a       pass the flag
                    lbsr      OutputPadNum emit the padded substring
                    leas      8,s        drop the arguments
                    bra       NextFormat next format char

EmitStrFull         ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    ldd       11,s      D = string pointer
                    bra       PushConv  emit the whole string

LongMod             ldb       ,u+       fetch the char after 'l'
                    stb       8,s       save it (long conversion)
                    bra       PadField  go build the field

                    leas      -11,x     unreachable stack adjust
PadField            ldd       6,s       D = field width
                    pshs      b,a       pass the width
                    leax      <21,s     X -> vararg pointer slot
                    pshs      x         pass the args pointer
                    ldb       12,s      B = conversion char
                    sex                 extend to D
                    pshs      b,a       pass the format char
                    lbsr      LongModifier handle the long conversion
ConvCleanup         leas      4,s        drop two arguments
PushConv            pshs      b,a       push the converted result
EmitConv            ldd       <19,s     D = field width
                    pshs      b,a       pass the width
                    lbsr      OutputPadStr emit the padded field
                    leas      6,s        drop the arguments
NextFormat          lbra      FormatLoop next format char

EmitUnknown         ldb       8,s       B = unknown conversion char
                    sex                 extend to D
EmitDispatch        pshs      b,a       pass the char
                    jsr       [<17,s]   call the char-output callback
                    leas      2,s        drop the char
                    lbra      FormatLoop next format char

ConvTable           cmpx      #100      'd' signed decimal?
                    lbeq      ConvDecimal handle it
                    cmpx      #111      'o' octal?
                    lbeq      ConvOctal handle it
                    cmpx      #120      'x' hex?
                    lbeq      ConvHex   handle it
                    cmpx      #'X       'X' uppercase hex?
                    lbeq      ConvHex   handle it
                    cmpx      #117      'u' unsigned?
                    lbeq      ConvUnsigned handle it
                    cmpx      #102      'f' float?
                    lbeq      ConvFloat handle it
                    cmpx      #101      'e' float?
                    lbeq      ConvFloat handle it
                    cmpx      #103      'g' float?
                    lbeq      ConvFloat handle it
                    cmpx      #69       'E' float?
                    lbeq      ConvFloat handle it
                    cmpx      #71       'G' float?
                    lbeq      ConvFloat handle it
                    cmpx      #99       'c' char?
                    lbeq      ConvChar  handle it
                    cmpx      #115      's' string?
                    lbeq      ConvString handle it
                    cmpx      #108      'l' long modifier?
                    lbeq      LongMod   handle it
                    bra       EmitUnknown unknown, emit literally

DoprntDone          leas      11,s       release the local workspace
                    puls      pc,u      return

IntToDec            pshs      u,b,a     save U and the int value
                    leax      >XConversionBuffer,y  X -> conversion buffer
                    stx       ,s        save the buffer pointer
                    ldd       6,s       D = signed int argument
                    bge       DecMagnitude non-negative, convert directly
                    ldd       6,s       D = the value
                    nega                negate high byte
                    negb                negate low byte
                    sbca      #0        finish negation with borrow
                    std       6,s       store the magnitude
                    bge       PutMinus  negation valid, prepend '-'
                    leax      >MinIntStr,pcr X -> INT_MIN literal string
                    pshs      x         pass the source string
                    leax      >XConversionBuffer,y  X -> conversion buffer
                    pshs      x         pass the destination
                    lbsr      strcpy    copy the literal
                    leas      4,s        drop the arguments
                    puls      pc,u,x    return the buffer pointer

PutMinus            ldd       #'-       D = '-' character
                    ldx       ,s        X -> buffer position
                    leax      1,x       advance
                    stx       ,s        save the position
                    stb       -1,x      store the minus sign
DecMagnitude        ldd       6,s       D = the magnitude
                    pshs      b,a       pass the value
                    ldd       2,s       D = buffer position
                    pshs      b,a       pass the buffer
                    bsr       UnsignedToDec convert the unsigned digits
                    leas      4,s        drop the arguments
                    leax      >XConversionBuffer,y  X -> conversion buffer
                    tfr       x,d       return the buffer pointer
                    puls      pc,u,x    return

UnsignedToDec       pshs      u,y,x,b,a save registers
                    ldu       10,s      U -> output buffer
                    clra                A = 0
                    clrb                D = 0
                    std       2,s       clear the leading-zero suppression flag
                    clra                clear high byte of counter
                    clrb                clear low byte
                    std       ,s        reset digit count
                    bra       DecTopCountTest test highest place first

DecTopCountLoop     ldd       ,s        count another subtraction
                    addd      #1        increment count
                    std       ,s        save count
                    ldd       12,s      value minus top power
                    subd      >WorkField20,y  subtract ten thousand
                    std       12,s      save remaining value
DecTopCountTest     ldd       12,s      value still negative?
                    blt       DecTopCountLoop keep subtracting top power
                    leax      >WorkField20,y  point at powers-of-ten table
                    stx       4,s       save divisor pointer
                    bra       DecPowerTest enter per-place loop

DecCountLoop        ldd       ,s        count this subtraction
                    addd      #1        increment count
                    std       ,s        save count
DecSubLoop          ldd       12,s      subtract current power
                    subd      [<4,s]    from remaining value
                    std       12,s      save remainder
                    bge       DecCountLoop repeat while non-negative
                    ldd       12,s      overshot so add power back
                    addd      [<4,s]    restore value
                    std       12,s      save restored value
                    ldd       ,s        did this place produce a digit?
                    beq       DecEmitDigit if none keep suppressing zeros
                    ldd       #1        mark significant digit seen
                    std       2,s       save flag
DecEmitDigit        ldd       2,s       past the leading zeros?
                    beq       DecNextPower skip storing leading zero
                    ldd       ,s        get digit value
                    addd      #48       convert to ascii
                    stb       ,u+       store digit char
DecNextPower        clra                clear high byte
                    clrb                clear low byte
                    std       ,s        reset digit count
                    ldd       4,s       advance divisor pointer
                    addd      #2        next table entry
                    std       4,s       save pointer
DecPowerTest        ldd       4,s       reached end of table?
                    cmpd      >FileTable,y  compare against table end
                    bne       DecSubLoop process next place
                    ldd       12,s      final units digit
                    addd      #48       convert to ascii
                    stb       ,u+       store units digit
                    clra                clear high byte
                    clrb                clear low byte
                    stb       ,u        null terminate string
                    ldd       10,s      return buffer pointer
                    leas      6,s        drop locals
                    puls      pc,u      return

FormatOctal         pshs      u,b,a     save U reserve locals
                    leax      >XConversionBuffer,y  point at output buffer
                    stx       ,s        save output pointer
                    leau      >ScratchDigitBuffer,y  point at scratch digit buffer
OctExtractLoop      ldd       6,s       current value
                    clra                clear high byte
                    andb      #$07      isolate low octal digit
                    addd      #48       convert to ascii
                    stb       ,u+       store digit reversed
                    ldd       6,s       reload value
                    lsra                divide value by eight
                    rorb                rotate into low byte
                    lsra                shift again
                    rorb                rotate again
                    lsra                third shift
                    rorb                rotate low byte
                    std       6,s       save shifted value
                    bne       OctExtractLoop more octal digits?
                    bra       OctCopyTest begin reverse copy

OctCopyLoop         ldb       ,u        grab reversed digit
                    ldx       ,s        output pointer
                    leax      1,x       bump pointer
                    stx       ,s        advance output pointer
                    stb       -1,x      copy digit out
OctCopyTest         leau      -PoolPtr,u step back through scratch
                    pshs      u         save scratch pointer
                    leax      >ScratchDigitBuffer,y  scratch buffer _start
                    cmpx      ,s++      reached _start?
                    bls       OctCopyLoop copy next reversed digit
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [,s]      null terminate output
                    leax      >XConversionBuffer,y  return buffer pointer
                    tfr       x,d       return pointer in D
                    puls      pc,u,x    return

FormatHex           pshs      u,x,b,a   save regs reserve locals
                    leax      >XConversionBuffer,y  point at output buffer
                    stx       2,s       save output pointer
                    leau      >ScratchDigitBuffer,y  point at scratch digit buffer
HexExtractLoop      ldd       8,s       current value
                    clra                clear high byte
                    andb      #$0F      isolate low nibble
                    std       ,s        save nibble
                    pshs      b,a       keep a copy
                    ldd       2,s       nibble value
                    cmpd      #9        digit or letter?
                    ble       HexDigitBase 0-9 uses digit base
                    ldd       12,s      uppercase requested?
                    beq       HexLowerBase lowercase if not
                    ldd       #'A       letter base uppercase A
                    bra       HexAlphaAdjust apply letter adjust

HexLowerBase        ldd       #'a       letter base lowercase a
HexAlphaAdjust      addd      #$FFF6    adjust for a-f offset
                    bra       HexEmitDigit form the character

HexDigitBase        ldd       #48       digit base ascii zero
HexEmitDigit        addd      ,s++      add nibble form char
                    stb       ,u+       store hex digit reversed
                    ldd       8,s       reload value
                    lsra                shift right one nibble
                    rorb                rotate into low byte
                    lsra                shift again
                    rorb                rotate again
                    lsra                shift again
                    rorb                rotate again
                    lsra                fourth shift
                    rorb                rotate low byte
                    anda      #$0F      clear high nibble
                    std       8,s       save shifted value
                    bne       HexExtractLoop more nibbles?
                    bra       HexCopyTest begin reverse copy

HexCopyLoop         ldb       ,u        grab reversed digit
                    ldx       2,s       output pointer
                    leax      1,x       bump pointer
                    stx       2,s       advance output pointer
                    stb       -1,x      copy digit out
HexCopyTest         leau      -PoolPtr,u step back through scratch
                    pshs      u         save scratch pointer
                    leax      >ScratchDigitBuffer,y  scratch buffer _start
                    cmpx      ,s++      reached _start?
                    bls       HexCopyLoop copy next reversed digit
                    clra                clear high byte
                    clrb                clear low byte
                    stb       [<2,s]    null terminate output
                    leax      >XConversionBuffer,y  return buffer pointer
                    tfr       x,d       return pointer in D
                    lbra      FmtCleanupRet shared cleanup return

OutputPadNum        pshs      u         save U
                    ldu       6,s       U -> formatted digits
                    ldd       10,s      field width
                    subd      8,s       minus length
                    std       10,s      equals pad count
                    ldd       >LeftJustified,y  left justified?
                    bne       NumEmitTest yes skip leading pad
                    bra       NumLeadPadTest enter leading pad loop

NumLeadPadLoop      ldd       >PadCharacter,y  pad character
                    pshs      b,a       pass pad char
                    jsr       [<6,s]    output one pad char
                    leas      2,s        drop arg
NumLeadPadTest      ldd       10,s      decrement pad count
                    addd      #$FFFF    minus one
                    std       10,s      save count
                    subd      #$FFFF    test the result
                    bgt       NumLeadPadLoop more leading pad?
                    bra       NumEmitTest

NumEmitLoop         ldb       ,u+       next digit char
                    sex                 sign extend
                    pshs      b,a       pass char
                    jsr       [<6,s]    output the digit
                    leas      2,s        drop arg
NumEmitTest         ldd       8,s       decrement length
                    addd      #$FFFF    minus one
                    std       8,s       save length
                    subd      #$FFFF    test the result
                    bne       NumEmitLoop more digits?
                    ldd       >LeftJustified,y  left justified?
                    beq       NumPadDone no trailing pad needed
                    bra       NumTailPadTest enter trailing pad loop

NumTailPadLoop      ldd       >PadCharacter,y  pad character
                    pshs      b,a       pass pad char
                    jsr       [<6,s]    output trailing pad
                    leas      2,s        drop arg
NumTailPadTest      ldd       10,s      decrement pad count
                    addd      #$FFFF    minus one
                    std       10,s      save count
                    subd      #$FFFF    test the result
                    bgt       NumTailPadLoop more trailing pad?
NumPadDone          puls      pc,u      return

OutputPadStr        pshs      u         save U
                    ldu       6,s       U -> string argument
                    ldd       8,s       field width
                    pshs      b,a       save width
                    pshs      u         pass string
                    lbsr      strlen    measure string length
                    leas      2,s        drop arg
                    nega                negate the length
                    negb                negate low byte
                    sbca      #0        propagate borrow
                    addd      ,s++      width minus length equals pad
                    std       8,s       save pad count
                    ldd       >LeftJustified,y  left justified?
                    bne       StrEmitTest yes skip leading pad
                    bra       StrLeadPadTest enter leading pad loop

StrLeadPadLoop      ldd       >PadCharacter,y  pad character
                    pshs      b,a       pass pad char
                    jsr       [<6,s]    output one pad char
                    leas      2,s        drop arg
StrLeadPadTest      ldd       8,s       decrement pad count
                    addd      #$FFFF    minus one
                    std       8,s       save count
                    subd      #$FFFF    test the result
                    bgt       StrLeadPadLoop more leading pad?
                    bra       StrEmitTest

StrEmitLoop         ldb       ,u+       next string char
                    sex                 sign extend
                    pshs      b,a       pass char
                    jsr       [<6,s]    output the char
                    leas      2,s        drop arg
StrEmitTest         ldb       ,u        end of string?
                    bne       StrEmitLoop no keep emitting
                    ldd       >LeftJustified,y  left justified?
                    beq       StrPadDone no trailing pad
                    bra       StrTailPadTest enter trailing pad loop

StrTailPadLoop      ldd       >PadCharacter,y  pad character
                    pshs      b,a       pass pad char
                    jsr       [<6,s]    output trailing pad
                    leas      2,s        drop arg
StrTailPadTest      ldd       8,s       decrement pad count
                    addd      #$FFFF    minus one
                    std       8,s       save count
                    subd      #$FFFF    test the result
                    bgt       StrTailPadLoop more trailing pad?
StrPadDone          puls      pc,u      return

FilePutcCB          pshs      u         save U
                    ldd       >OutputPointerBuffer,y  current stream pointer
                    pshs      b,a       push stream pointer
                    ldd       6,s       char to output
                    pshs      b,a       push char
                    lbsr      FilePutc  write char to file
FmtCleanupRet       leas      4,s        drop args
                    puls      pc,u      return

BufPutcCB           pshs      u         save U
                    ldd       4,s       char to store
                    ldx       >OutputPointerBuffer,y  buffer write pointer
                    leax      1,x       bump pointer
                    stx       >OutputPointerBuffer,y  advance stored pointer
                    stb       -1,x      store char in buffer
                    puls      pc,u      return

MinIntStr           fcc       "-32768"
                    fcb       C$NULL

FilePutc            pshs      u         save U
                    ldu       6,s       U -> file structure
                    ldd       ExpandPtr,u file flags
                    anda      #$80      keep eof flag bit
                    andb      #$22      and the write-mode bits
                    cmpd      #$8002    at eof but writable?
                    beq       PutcModeOk already writable proceed
                    ldd       ExpandPtr,u reload file flags
                    clra                clear high byte
                    andb      #$22      mask write-mode bits
                    cmpd      #2        open for writing?
                    lbne      FlushErr  no return error
                    pshs      u         pass file
                    lbsr      InitStreamBuf switch stream to write mode
                    leas      2,s        drop arg
PutcModeOk          ldd       ExpandPtr,u file flags
                    clra                clear high byte
                    andb      #$04      unbuffered stream?
                    beq       PutcBuffered no take buffered path
                    ldd       #1        write a single byte
PutcUnbufWrite      pshs      b,a       push length
                    leax      7,s       point at the char
                    pshs      x         pass buffer pointer
                    ldd       InPtr,u   file descriptor
                    pshs      b,a       pass descriptor
                    ldd       ExpandPtr,u file flags
                    clra                clear high byte
                    andb      #$40      translation enabled?
                    beq       PutcRawWrite no use raw write
                    leax      >writeln,pcr cooked write routine
                    bra       PutcCallWrite call it

PutcRawWrite        leax      >write,pcr raw write routine
PutcCallWrite       tfr       x,d       move routine address
                    tfr       d,x       into X for call
                    jsr       ,x        perform the write
                    leas      6,s        drop args
                    cmpd      #$FFFF    write failed?
                    bne       PutcReturn no return the char
                    ldd       ExpandPtr,u file flags
                    orb       #$20      set error flag
                    std       ExpandPtr,u save flags
                    lbra      FlushErr  return error

PutcBuffered        ldd       ExpandPtr,u file flags
                    anda      #$01      buffer allocated?
                    clrb                clear low byte
                    std       -2,s      save test result
                    bne       PutcStore yes store the char
                    pshs      u         pass file
                    lbsr      WriteBuffer set up the buffer
                    leas      2,s        drop arg
PutcStore           ldd       ,u        buffer write pointer
                    addd      #1        plus one
                    std       ,u        advance it
                    subd      #1        restore pointer value
                    tfr       d,x       X = store address
                    ldd       4,s       char to store
                    stb       ,x        put char in buffer
                    ldd       ,u        new pointer
                    cmpd      TokenStart,u buffer full?
                    bcc       PutcFlush yes flush now
                    ldd       ExpandPtr,u file flags
                    clra                clear high byte
                    andb      #$40      line buffered?
                    beq       PutcReturn no done
                    ldd       4,s       char written
                    cmpd      #13       was it newline?
                    bne       PutcReturn no done

PutcFlush           pshs      u         pass file
                    lbsr      WriteBuffer flush the buffer
                    std       ,s++      check flush result
                    lbne      FlushErr  flush failed return error
PutcReturn          ldd       4,s       return char written
                    puls      pc,u      return

                    pshs      u         save U
                    ldu       4,s       U -> file structure
                    ldd       6,s       word to write
                    pshs      b,a       push word
                    pshs      u         push file
                    ldd       #8        shift count eight
                    lbsr      LsrEntry  extract high byte
                    pshs      b,a       push high byte
                    lbsr      FilePutc  write high byte
                    leas      4,s        drop the two pushed arguments
                    ldd       6,s       reload the 16-bit value
                    pshs      b,a       push low half as argument
                    pshs      u         push file pointer
                    lbsr      FilePutc  output the low part
                    lbra      WriteBufDone return through common exit

CloseAllFiles       pshs      u,b,a     save registers and index
                    leau      >UStartFile,y  U -> first FILE struct
                    clra                clear index counter
                    clrb
                    std       ,s        index = 0
                    bra       CloseFileTest jump to loop test

CloseFileLoop       tfr       u,d       D = current FILE pointer
                    leau      FileEntStride,u advance to next FILE (13 bytes)
                    pshs      b,a       push FILE pointer as argument
                    bsr       FileClose flush and close this file
                    leas      2,s        drop argument
CloseFileTest       ldd       ,s        load loop index
                    addd      #1        bump index
                    std       ,s        store it back
                    subd      #1
                    cmpd      #16       processed all 16 files?
                    blt       CloseFileLoop no, close next file
                    puls      pc,u,x    return

FileClose           pshs      u         save FILE pointer register
                    ldu       4,s       U = FILE argument
                    leas      -2,s       make room for result
                    cmpu      #0        null FILE pointer?
                    beq       FcloseNull yes, return -1
                    ldd       ExpandPtr,u load status flags
                    bne       FcloseOpen open file, proceed
FcloseNull          ldd       #$FFFF    return -1
                    puls      pc,u,x

FcloseOpen          ldd       ExpandPtr,u load flags
                    clra
                    andb      #$02      output buffer dirty?
                    beq       FcloseNoFlush no, skip flush
                    pshs      u         push FILE pointer
                    bsr       FlushWrite flush pending output
                    leas      2,s        drop argument
                    bra       FcloseDoClose join close path

FcloseNoFlush       clra                no flush needed
                    clrb
FcloseDoClose       std       ,s        save flush result
                    ldd       InPtr,u   load file descriptor
                    pshs      b,a       push it
                    lbsr      close     close the path
                    leas      2,s        drop argument
                    clra
                    clrb
                    std       ExpandPtr,u clear flags, mark closed
                    ldd       ,s        return flush result
                    puls      pc,u,x

FlushWrite          pshs      u         save FILE pointer register
                    ldu       4,s       U = FILE argument
                    beq       FlushErr  null pointer -> -1
                    ldd       ExpandPtr,u load flags
                    clra
                    andb      #$22      mask write-mode bits
                    cmpd      #2        open for writing?
                    beq       FlushSetup yes, flush it
FlushErr            ldd       #$FFFF    return -1
                    puls      pc,u

FlushSetup          ldd       ExpandPtr,u load flags
                    anda      #$80      buffer already set up?
                    clrb
                    std       -2,s      save test result
                    bne       FlushWriteBuf yes, skip setup
                    pshs      u         push FILE pointer
                    lbsr      InitStreamBuf allocate buffer
                    leas      2,s        drop argument

FlushWriteBuf       pshs      u         push FILE pointer
                    bsr       WriteBuffer write out the buffer
                    puls      pc,u,x    return result

WriteBuffer         pshs      u         save FILE pointer register
                    ldu       4,s       U = FILE argument
                    leas      -4,s       reserve local slots
                    ldd       ExpandPtr,u load flags
                    anda      #$01      currently reading?
                    clrb
                    std       -2,s      save test result
                    bne       WriteBufCount yes, nothing to write
                    ldd       ,u        current buffer pointer
                    cmpd      TokenStart,u at end of buffer?
                    beq       WriteBufCount yes, nothing pending
                    clra
                    clrb
                    pshs      b,a       push zero count
                    pshs      u         push FILE pointer
                    lbsr      WriteBufStub helper call
                    leas      2,s        drop argument
                    ldd       2,x       second write parameter
                    pshs      b,a       push it
                    ldd       ,x        first write parameter
                    pshs      b,a       push it
                    ldd       InPtr,u   file descriptor
                    pshs      b,a       push it
                    lbsr      SeekFile  write bytes to file
                    leas      8,s        drop arguments
WriteBufCount       ldd       ,u        current buffer pointer
                    subd      FileBufBase,u bytes queued in buffer
                    std       2,s       save the count
                    lbeq      WriteBufReset empty, reset buffer
                    ldd       ExpandPtr,u load flags
                    anda      #$01      read mode active?
                    clrb
                    std       -2,s      save test result
                    lbeq      WriteBufReset not writing, reset only
                    ldd       ExpandPtr,u load flags
                    clra
                    andb      #$40      text (line) mode?
                    beq       WriteBlock no, binary block write
                    ldd       FileBufBase,u buffer base pointer
                    bra       WriteLineAdvance enter line-write loop

WriteLineLoop       ldd       2,s       remaining byte count
                    pshs      b,a       push it
                    ldd       ,u        current write position
                    pshs      b,a       push it
                    ldd       InPtr,u   file descriptor
                    pshs      b,a       push it
                    lbsr      writeln   write one line to file
                    leas      6,s        drop arguments
                    std       ,s        save bytes written
                    cmpd      #$FFFF    write error?
                    bne       WriteLineOk no, continue
                    leax      4,s       point at saved result
                    bra       WriteBufErr go set error flag

WriteLineOk         ldd       2,s       remaining count
                    subd      ,s        subtract bytes written
                    std       2,s       store remaining
                    ldd       ,u        buffer pointer
                    addd      ,s        advance past written bytes
WriteLineAdvance    std       ,u        store new pointer
                    ldd       2,s       remaining count
                    bne       WriteLineLoop more to write, loop
                    bra       WriteBufReset done, reset buffer

WriteBlock          ldd       2,s       byte count
                    pshs      b,a       push it
                    ldd       FileBufBase,u buffer base
                    pshs      b,a       push it
                    ldd       InPtr,u   file descriptor
                    pshs      b,a       push it
                    lbsr      write     write whole block to file
                    leas      6,s        drop arguments
                    cmpd      2,s       all bytes written?
                    beq       WriteBufReset yes, reset buffer
                    bra       WriteBufSetErr short write -> error

WriteBufErr         leas      -4,x      restore stack after error
WriteBufSetErr      ldd       ExpandPtr,u load flags
                    orb       #$20      set error flag
                    std       ExpandPtr,u store flags
                    ldd       TokenStart,u buffer end pointer
                    std       ,u        reset pointer to end
                    ldd       #$FFFF    return -1
                    bra       WriteBufDone join common exit

WriteBufReset       ldd       ExpandPtr,u load flags
                    ora       #$01      mark read mode
                    std       ExpandPtr,u store flags
                    ldd       FileBufBase,u buffer base
                    std       ,u        reset pointer to base
                    addd      FileBufSize,u base plus buffer size
                    std       TokenStart,u set buffer end
                    clra
                    clrb                success result zero
WriteBufDone        leas      4,s        drop locals
                    puls      pc,u      return

WriteBufStub        pshs      u         save and restore U only
                    puls      pc,u      return

GetChar             pshs      u         save FILE pointer register
                    ldu       4,s       U = FILE argument
                    beq       GetCharEof null pointer -> -1
                    ldd       ExpandPtr,u load flags
                    anda      #$01      in write mode?
                    clrb
                    std       -2,s      save test result
                    bne       GetCharEof yes, cannot read
                    ldd       ,u        current buffer pointer
                    cmpd      TokenStart,u buffer exhausted?
                    bcc       GetCharFill yes, refill from file
                    ldd       ,u        current pointer
                    addd      #1        advance pointer
                    std       ,u        store it
                    subd      #1
                    tfr       d,x
                    ldb       ,x        fetch next byte
                    clra                clear high byte
                    bra       GetCharDone return the byte

GetCharFill         pshs      u         push FILE pointer
                    lbsr      FillBuffer refill buffer on underflow
                    leas      2,s        drop argument
GetCharDone         puls      pc,u      return character

                    pshs      u         save FILE pointer register
                    ldu       6,s       U = FILE argument
                    beq       GetCharEof null pointer -> -1
                    ldd       ExpandPtr,u load flags
                    clra
                    andb      #$01      in read mode?
                    beq       GetCharEof no, cannot push back
                    ldd       4,s       char to push back
                    cmpd      #$FFFF    was it EOF?
                    beq       GetCharEof yes, cannot push
                    ldd       ,u        current buffer pointer
                    cmpd      FileBufBase,u already at buffer _start?
                    bhi       UnGetStore room to back up
GetCharEof          ldd       #$FFFF    return -1
                    puls      pc,u

UnGetStore          ldd       ,u        current pointer
                    addd      #$FFFF    back pointer up one
                    std       ,u        store it
                    tfr       d,x
                    ldd       4,s       char to push back
                    stb       ,x        store pushed-back char
                    ldd       4,s       return the char
                    puls      pc,u

                    pshs      u         save FILE pointer register
                    ldu       4,s       U = FILE argument
                    leas      -4,s       reserve local slots
                    pshs      u         push FILE pointer
                    lbsr      GetChar   read high byte
                    leas      2,s        drop argument
                    std       2,s       save high byte
                    cmpd      #$FFFF    EOF?
                    beq       GetWordEof yes, fail
                    pshs      u         push FILE pointer
                    lbsr      GetChar   read low byte
                    leas      2,s        drop argument
                    std       ,s        save low byte
                    cmpd      #$FFFF    EOF?
                    bne       GetWordCombine no, combine bytes
GetWordEof          ldd       #$FFFF    return -1
                    bra       GetWordDone go to exit

GetWordCombine      ldd       2,s       high byte
                    pshs      b,a       push it
                    ldd       #8        shift amount 8
                    lbsr      AslEntry  shift high byte up
                    addd      ,s        combine with low byte
GetWordDone         leas      4,s        drop locals
                    puls      pc,u      return the word

FillBuffer          pshs      u         save FILE pointer register
                    ldu       4,s       U = FILE argument
                    leas      -2,s       make room for result
                    ldd       ExpandPtr,u load flags
                    anda      #$80      buffer set up bit
                    andb      #$31      mask read/status bits
                    cmpd      #$8001    set up and readable?
                    beq       FillBufRead yes, do the read
                    ldd       ExpandPtr,u load flags
                    clra
                    andb      #$31      mask read/status bits
                    cmpd      #1        readable but not set up?
                    beq       FillBufSetup yes, allocate first
                    ldd       #$FFFF    not readable -> -1
                    puls      pc,u,x

FillBufSetup        pshs      u         push FILE pointer
                    lbsr      InitStreamBuf allocate the buffer
                    leas      2,s        drop argument
FillBufRead         leax      >UStartFile,y  X -> stdin FILE
                    pshs      x         push it
                    cmpu      ,s++      is this stdin?
                    bne       FillBufSelect no, skip stdout flush
                    ldd       ExpandPtr,u load flags
                    clra
                    andb      #$40      line-buffered?
                    beq       FillBufSelect no, skip flush
                    leax      >XInternalScratch,y  X -> stdout FILE
                    pshs      x         push it
                    lbsr      FlushWrite flush stdout before reading
                    leas      2,s        drop argument
FillBufSelect       ldd       ExpandPtr,u load flags
                    clra
                    andb      #$08      buffer allocated?
                    beq       FillBufOne no, read single byte
                    ldd       FileBufSize,u buffer size
                    pshs      b,a       push it
                    ldd       FileBufBase,u buffer base
                    pshs      b,a       push it
                    ldd       InPtr,u   file descriptor
                    pshs      b,a       push it
                    ldd       ExpandPtr,u load flags
                    clra
                    andb      #$40      text mode?
                    beq       FillBufBlock no, use block read
                    leax      >readln,pcr X -> line-read routine
                    bra       FillBufCall call it

FillBufBlock        leax      >read,pcr X -> block-read routine
FillBufCall         tfr       x,d
                    tfr       d,x
                    jsr       ,x        read into buffer
                    bra       FillBufResult check the result

FillBufOne          ldd       #1        read count of one
                    pshs      b,a       push it
                    leax      CurFile,u point at inline one-byte slot
                    stx       FileBufBase,u make it the buffer base
                    pshs      x         push it
                    ldd       InPtr,u   file descriptor
                    pshs      b,a       push it
                    lbsr      read      read one byte
FillBufResult       leas      6,s        drop arguments
                    std       ,s        save byte count
                    ldd       ,s        reload count
                    bgt       FillBufData got some data?
                    ldd       ExpandPtr,u load flags
                    pshs      b,a       push them
                    ldd       2,s       read result
                    beq       FillBufEof zero bytes -> EOF
                    ldd       #32       otherwise error flag
                    bra       OrFlags   merge it in

FillBufEof          ldd       #16       EOF flag
OrFlags             ora       ,s+       or into flags
                    orb       ,s+
                    std       ExpandPtr,u set EOF or error flag
                    ldd       #$FFFF    return -1
                    puls      pc,u,x

FillBufData         ldd       FileBufBase,u buffer base
                    addd      #1        skip first byte
                    std       ,u        set current pointer
                    ldd       FileBufBase,u buffer base
                    addd      ,s        base plus bytes read
                    std       TokenStart,u set buffer end
                    ldb       [<FileBufBase,u] return first byte
                    clra                zero-extend the buffer byte just read
                    puls      pc,u,x    return the character in D

InitStreamBuf       pshs      u         save caller U
                    ldu       4,s       U = stream structure pointer
                    ldd       ExpandPtr,u D = stream flags
                    clra
                    andb      #$C0      buffering mode already resolved?
                    bne       AllocStreamBuf yes, skip the device probe
                    leas      <-32,s    reserve 32-byte status scratch
                    leax      ,s        point at the scratch area
                    pshs      x         push status buffer pointer
                    ldd       InPtr,u   path number for the stream
                    pshs      b,a
                    clra                function code 0 = query device type
                    clrb
                    pshs      b,a
                    lbsr      GetDevStat probe the device status
                    leas      6,s        drop the call arguments
                    ldd       ExpandPtr,u D = current stream flags
                    pshs      b,a
                    ldb       2,s       B = device-type result
                    bne       BlockBufFlag nonzero means not interactive
                    ldd       #64       interactive: line-buffered flag
                    bra       StoreBufMode store the mode

BlockBufFlag        ldd       #128      device: block-buffered flag
StoreBufMode        ora       ,s+       merge flag into stream flags
                    orb       ,s+
                    std       ExpandPtr,u save updated flags
                    leas      <32,s     release the status scratch
AllocStreamBuf      ldd       ExpandPtr,u D = stream flags
                    ora       #$80      mark buffering mode resolved
                    std       ExpandPtr,u save the flags
                    clra
                    andb      #$0C      buffer already present?
                    beq       ChooseBufSize no, choose a size
                    puls      pc,u      yes, nothing more to do

ChooseBufSize       ldd       FileBufSize,u current buffer size field
                    bne       DoAllocBuf size already set
                    ldd       ExpandPtr,u D = stream flags
                    clra
                    andb      #$40      interactive stream?
                    beq       BlockBufSize no, use block size
                    ldd       #128      interactive default size 128
                    bra       StoreBufSize store the size

BlockBufSize        ldd       #256      block default size 256
StoreBufSize        std       FileBufSize,u save the chosen buffer size
DoAllocBuf          ldd       FileBufBase,u existing buffer pointer
                    bne       BufAllocOk already allocated
                    ldd       FileBufSize,u request buffer of this size
                    pshs      b,a
                    lbsr      AllocWork allocate buffer from heap
                    leas      2,s
                    std       FileBufBase,u save the buffer pointer
                    cmpd      #$FFFF    allocation failed?
                    beq       BufAllocFail fall back to inline buffer
BufAllocOk          ldd       ExpandPtr,u D = stream flags
                    orb       #$08      mark buffer heap-allocated
                    std       ExpandPtr,u save flags
                    bra       FinishBufInit finish buffer setup

BufAllocFail        ldd       ExpandPtr,u D = stream flags
                    orb       #$04      mark unbuffered fallback
                    std       ExpandPtr,u save flags
                    leax      CurFile,u use the inline one-byte buffer
                    stx       FileBufBase,u store buffer pointer
                    ldd       #1
                    std       FileBufSize,u buffer size = 1
FinishBufInit       ldd       FileBufBase,u buffer base pointer
                    addd      FileBufSize,u plus its size
                    std       TokenStart,u set the buffer end pointer
                    std       ,u        reset the current pointer
                    puls      pc,u      return

LongModifier        pshs      u         save caller U
                    ldb       5,s       B = conversion char after %l
                    sex                 widen to 16 bits
                    tfr       d,x       into X for the dispatch
                    bra       LongSpecDispatch dispatch on the char

SkipLongArg         ldd       [<6,s]    vararg pointer for the long
                    addd      #4        skip a 4-byte long argument
                    std       [<6,s]    store advanced pointer
                    leax      >EmptyFmtStr,pcr return empty format string
                    bra       RetSpecPtr go return the pointer

DefaultSpec         ldb       5,s       B = the conversion char
                    stb       >StashOneChar,y  stash it in the one-char format
                    leax      >OneCharFormat,y  point at the one-char format
RetSpecPtr          tfr       x,d       return format pointer in D
                    puls      pc,u

LongSpecDispatch    cmpx      #100      was the char 'd'?
                    beq       SkipLongArg yes, skip a long
                    cmpx      #111      was it 'o'?
                    lbeq      SkipLongArg yes, skip a long
                    cmpx      #120      was it 'x'?
                    lbeq      SkipLongArg yes, skip a long
                    bra       DefaultSpec otherwise treat as one-char spec

                    puls      pc,u      unreachable

EmptyFmtStr         fcb       $00

FloatFmtStub        pshs      u         save caller U
                    leax      >EmptyFloatStr,pcr float output not supported
                    tfr       x,d       return empty string in D
                    puls      pc,u      return

EmptyFloatStr       fcb       $00

strlen              pshs      u         save caller U
                    ldu       4,s       U = _start of the string
StrLenLoop2         ldb       ,u+       scan forward one byte
                    bne       StrLenLoop2 until the terminator
                    tfr       u,d       D = pointer past terminator
                    subd      4,s       minus the _start gives length+1
                    addd      #$FFFF    drop the NUL from the count
                    puls      pc,u      return the length

                    use       lib/strcpy.asm

                    use       lib/strcat.asm

strcmp              pshs      u         save caller U
                    ldu       4,s       U = first string
                    bra       StrCmpLoop enter the compare loop

StrCmpNext          ldx       6,s       advance second-string pointer
                    leax      1,x
                    stx       6,s
                    ldb       -1,x      B = second-string char
                    bne       StrCmpAdv not the terminator, keep going
                    clra                reached both ends together
                    clrb                strings equal, return 0
                    puls      pc,u

StrCmpAdv           leau      PoolPtr,u advance first-string pointer
StrCmpLoop          ldb       ,u        B = first-string char
                    sex                 widen to 16 bits
                    pshs      b,a
                    ldb       [<8,s]    second-string char
                    sex                 widen to 16 bits
                    cmpd      ,s++      characters equal?
                    beq       StrCmpNext yes, keep comparing
                    ldb       [<6,s]    differ: second-string char
                    sex                 widen
                    pshs      b,a
                    ldb       ,u        first-string char
                    sex                 widen
                    subd      ,s++      D = char difference
                    puls      pc,u      return the difference

ParseInt            pshs      u         save caller U
                    ldu       4,s       U = string to parse
                    leas      -5,s       reserve local frame
                    clra
                    clrb
                    std       1,s       accumulated value = 0
SkipBlanks          ldb       ,u+       fetch a character
                    stb       ,s        save it
                    cmpb      #'        a space?
                    beq       SkipBlanks skip it
                    ldb       ,s        reload the char
                    cmpb      #9        a tab?
                    lbeq      SkipBlanks skip it
                    ldb       ,s        reload the char
                    cmpb      #'-       leading minus?
                    bne       SignPositive no
                    ldd       #1        remember negative
                    bra       StoreSign store the sign flag

SignPositive        clra                positive
                    clrb
StoreSign           std       3,s       save the sign flag
                    ldb       ,s        reload the char
                    cmpb      #'-       leading minus?
                    beq       NextParseChar consume it
                    ldb       ,s        reload the char
                    cmpb      #'+       leading plus?
                    bne       DigitTest no, _start scanning digits
                    bra       NextParseChar consume the plus

AccumDigit          ldd       1,s       D = current value
                    pshs      b,a
                    ldd       #10       multiply by ten
                    lbsr      MulEntry  call the multiply helper
                    pshs      b,a
                    ldb       2,s       B = the digit character
                    sex                 widen
                    addd      ,s++      add value*10 back
                    addd      #$FFD0    subtract ASCII '0'
                    std       1,s       store the new value
NextParseChar       ldb       ,u+       fetch the next character
                    stb       ,s        save it
DigitTest           ldb       ,s        B = current char
                    sex                 widen
                    leax      >XCharacterClass,y  index the character-class table
                    leax      d,x
                    ldb       ,x        read its class byte
                    clra
                    andb      #$08      is it a digit?
                    bne       AccumDigit yes, accumulate it
                    ldd       3,s       was the number negative?
                    beq       PositiveResult no, return as is
                    ldd       1,s       D = value
                    nega                negate it
                    negb
                    sbca      #0
                    bra       ApplySign take the negated result

PositiveResult      ldd       1,s       positive result
ApplySign           leas      5,s        drop the local frame
                    puls      pc,u      return the value

                    use       lib/imul.asm
                    use       lib/shift.asm

GetDevStat          lda       5,s       A = path number
                    ldb       3,s       B = status function code
                    beq       GetSttCode0 code 0 = simple GetStt
                    cmpb      #1        code 1?
                    beq       DoGetStt  plain GetStt
                    cmpb      #6        code 6?
                    beq       DoGetStt  plain GetStt
                    cmpb      #2        code 2?
                    beq       GetStatXU GetStt returning X and U
                    cmpb      #5        code 5?
                    beq       GetStatXU GetStt returning X and U
                    ldb       #E$UnkSvc unknown code error
                    lbra      SyscallErr report the error

GetStatXU           pshs      u         save caller U
                    os9       I$GetStt
                    bcc       GetStatOk call succeeded
                    puls      u         restore U
                    lbra      SyscallErr propagate the error

GetStatOk           stx       [<8,s]    return the X result word
                    ldx       8,s       caller result pointer
                    stu       2,x       return the U result word
                    puls      u         restore U
                    clra                return no error
                    clrb                getstt succeeded, clear low byte
                    rts                 return success (D=0)

GetSttCode0         ldx       6,s       code 0: X = getstt parameter
DoGetStt            os9       I$GetStt
                    lbra      SyscallRet return getstt status

                    lda       5,s       setstt entry: A = path number
                    ldb       3,s       B = setstt function code
                    beq       DoSetStt  code 0 -> plain setstt
                    cmpb      #2        code 2?
                    beq       SetStatXU code 2 -> setstt with U param
                    ldb       #E$UnkSvc bad code -> error $D0
                    lbra      SyscallErr return error

DoSetStt            ldx       6,s       X = status parameter
                    os9       I$SetStt
                    lbra      SyscallRet return setstt status

                    use       lib/setstat.asm

                    use       lib/access.asm

                    use       lib/openpath.asm
                    use       lib/closepath.asm

                    ldx       2,s       makdir: X = pathname
                    ldb       5,s       B = directory attributes
                    os9       I$MakDir
                    lbra      SyscallRet return makdir status

                    use       lib/createheada.asm
                    use       lib/createtail.asm

                    use       lib/deletepath.asm

                    lda       3,s       dup: A = path number
                    os9       I$Dup
                    lbcs      SyscallErr dup failed -> errno
                    tfr       a,b       B = new path number
                    clra                D = new path number
                    rts                 return new path number
                    use       lib/readpath.asm

                    use       lib/writepath.asm

SeekFile            pshs      u         save U
                    ldd       10,s      D = whence
                    bne       ChkWhence not SEEK_SET -> check others
                    ldu       #0        SEEK_SET: base high = 0
                    ldx       #0        base low = 0
                    bra       DoSeek    compute target position

ChkWhence           cmpd      #1        SEEK_CUR?
                    beq       SeekCur   go fetch current position
                    cmpd      #2        SEEK_END?
                    beq       SeekEnd   go fetch file size
                    ldb       #E$Seek   invalid whence -> error $F7
SeekErr             clra                seek error: A=0 so D=errno
                    std       >Errno,y  save errno
                    ldd       #$FFFF    result = -1
                    leax      >XLongResult,y  X -> long result buffer
                    std       ,x        store -1 high word
                    std       2,x       store -1 low word
                    puls      pc,u      return -1

SeekEnd             lda       5,s       SEEK_END: A = path number
                    ldb       #2        SS.Size getstt code
                    os9       I$GetStt
                    bcs       SeekErr   getstt failed -> error
                    bra       DoSeek    base = file size

SeekCur             lda       5,s       SEEK_CUR: A = path number
                    ldb       #5        SS.Pos getstt code
                    os9       I$GetStt
                    bcs       SeekErr   getstt failed -> error
DoSeek              tfr       u,d       D = base position low
                    addd      8,s       add offset low word
                    std       >LowResult,y  save low result
                    tfr       d,u       stash new low in U
                    tfr       x,d       D = base position high
                    adcb      7,s       add offset high with carry
                    adca      6,s       propagate carry into high byte
                    bmi       SeekErr   negative position -> error
                    tfr       d,x       X = new high word
                    std       >XLongResult,y  save high result
                    lda       5,s       A = path number
                    os9       I$Seek
                    bcs       SeekErr   seek failed -> error
                    leax      >XLongResult,y  X -> new position long
                    puls      pc,u      return new position

LinkModule          pshs      u,y       save U and Y
                    ldx       6,s       X = module name
                    lda       9,s       A = type/language byte
                    lsla                shift type into high nibble
                    lsla                continue nibble shift
                    lsla                continue nibble shift
                    lsla                continue nibble shift
                    ora       11,s      combine with attr/rev
                    os9       F$Link
LinkResult          tfr       u,d       D = module entry point
                    puls      u,y       restore registers
                    lbcs      SyscallErr link failed -> errno
                    rts                 return entry point

                    pshs      u,y       load: save U and Y
                    ldx       6,s       X = file name
                    lda       9,s       A = type/language byte
                    lsla                shift type into high nibble
                    lsla                continue nibble shift
                    lsla                continue nibble shift
                    lsla                continue nibble shift
                    ora       11,s      combine with attr/rev
                    os9       F$Load
                    bra       LinkResult share link result handling

UnlinkModule        pshs      u         save U
                    ldu       4,s       U = module pointer
                    os9       F$UnLink
                    puls      u         restore U
                    lbra      SyscallRet return unlink status

AllocMem            ldd       >WorkArea,y  D = current heap top
                    pshs      b,a       save heap top
                    ldd       4,s       D = requested size
                    cmpd      >FitsFreePool,y  fits in free pool?
                    bcs       CarveBlock yes -> carve from pool
                    addd      >WorkArea,y  compute new heap top
                    pshs      y         save Y for byte count
                    subd      ,s        compute F$Mem byte count
                    os9       F$Mem
                    tfr       y,d       D = granted memory top
                    puls      y         restore Y
                    bcc       MemGranted got memory -> update top
                    ldd       #$FFFF    F$Mem failed -> -1
                    leas      2,s        drop saved top
                    rts                 return -1
MemGranted          std       >WorkArea,y  save new heap top
                    addd      >FitsFreePool,y  add old free pool
                    subd      ,s        minus previous top
                    std       >FitsFreePool,y  update free pool size
CarveBlock          leas      2,s        drop saved top
                    ldd       >FitsFreePool,y  D = free pool size
                    pshs      b,a       save free pool
                    subd      4,s       subtract requested size
                    std       >FitsFreePool,y  shrink free pool
                    ldd       >WorkArea,y  D = heap top
                    subd      ,s++      block = top minus free pool
                    pshs      b,a       save block pointer
                    clra                fill byte = 0
                    ldx       ,s        X = block _start
ZeroBlockLoop       sta       ,x+       zero the block
                    cmpx      >WorkArea,y  reached heap top?
                    bcs       ZeroBlockLoop loop until filled
                    puls      pc,b,a    return block pointer

AllocWork           ldd       2,s       D = requested size
                    addd      >WorkAreaLimit,y  add to work-area limit
                    bcs       WorkAllocOvf wraparound -> fail
                    cmpd      >PastStackLow,y  past stack low-water?
                    bcc       WorkAllocOvf yes -> fail
                    pshs      b,a       save new limit
                    ldx       >WorkAreaLimit,y  X = old limit
                    clra                fill byte = 0
ZeroWorkLoop        cmpx      ,s        reached new limit?
                    bcc       WorkAllocOk done zeroing
                    sta       ,x+       zero the block
                    bra       ZeroWorkLoop loop

WorkAllocOk         ldd       >WorkAreaLimit,y  D = old limit (block _start)
                    puls      x         X = new limit
                    stx       >WorkAreaLimit,y  advance work-area limit
                    rts                 return block pointer
WorkAllocOvf        ldd       #$FFFF    out of work space -> -1
                    rts                 return failure

SetIntercept        pshs      u         save U
                    tfr       y,u       U = static base
                    ldx       4,s       X = user handler
                    stx       >HandlerPointer,y  save handler pointer
                    leax      >InterceptHandler,pcr X -> intercept trampoline
                    os9       F$Icpt
                    puls      u         restore U
                    lbra      SyscallRet return status

InterceptHandler    tfr       u,y       Y = static base
                    clra                A = 0
                    pshs      b,a       push signal code
                    jsr       [>HandlerPointer,y] call saved user handler
                    leas      2,s        drop signal code
                    rti                 return from intercept

                    use       lib/syscallerr.asm

exit                lbsr      ReturnStub no-op stub call
                    lbsr      CloseAllFiles flush all open files

_exit               ldd       2,s       D = exit status
                    os9       F$Exit
ReturnStub          rts                 return (stub)

                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       WBIcount2-WBIblock1

                    * ---- block1: DP data image  ->  data base
WBIblock1           fcb       $00

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
WBIcount2           fdb       WBIblk2End-WBIblock2

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fdb       StrZero   reloc1 data-to-text pointer to the zero string
                    fcb       $00
                    fcb       $01
                    fdb       10000,1000,100,10 powers of ten
WBIptr2             fdb       HDRADV+WBIptr2-WBIblock2 reloc2 data-to-data self pointer
                    fcb       $6C       l
                    fcb       $78       x
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
                    fcb       $42       B
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
                    fcb       $00
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $11
                    fcb       $11
                    fcb       $01
                    fcb       $11
                    fcb       $11
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $01
                    fcb       $30       0
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $48       H
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $42       B
                    fcb       $42       B
                    fcb       $42       B
CharClassLetterD    fcb       $42       B
                    fcb       $42       B
CharClassLetterF    fcb       $42       B
                    fcb       $02
                    fcb       $02
                    fcb       $02
CharClassLetterJ    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
                    fcb       $02
CharClassLetterP    fcb       $02
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
                    fcb       $20
CharClassBackslash  fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $44       D
                    fcb       $44       D
                    fcb       $44       D
                    fcb       $44       D
                    fcb       $44       D
                    fcb       $44       D
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
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $20
                    fcb       $01

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
WBIblk2End          fdb       (reloc1End-reloc1Start)/2

                    * ---- reloc1: text relocation offsets
reloc1Start         fdb       HDRADV    work offset of the block2-start text pointer
reloc1End           equ       *

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       (reloc2End-reloc2Start)/2

                    * ---- reloc2: data relocation offsets
reloc2Start         fdb       HDRADV+WBIptr2-WBIblock2 work offset of the data pointer
reloc2End           equ       *

                    * ---- name: trailing module-name string
                    fcc       /c.prep/
                    fcb       C$NULL
                    emod
eom                 equ       *