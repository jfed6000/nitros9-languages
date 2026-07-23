                    nam       cc1
                    ttl       program module

* Annotated 2026-07-17 (Claude Code):
*   - renamed disassembled labels to meaningful names
*   - added an inline comment to every instruction
*   - separated the direct-page globals from the startup code they had
*     been mis-resolved onto (disassembler assumed DP=$00); they are now
*     a direct-page equate block with the references repointed
*   - verified byte-identical to the original assembly (module CRC $2124D4)

                    use       defsfile

tylg                set       Prgrm+Objct
atrv                set       ReEnt+rev
rev                 set       $01
edition             set       $04

                    mod       eom,name,tylg,atrv,_start,size

                    * ------------------------------------------------------------------
                    * Data area (named rmb fields).  rmb reserves RAM without emitting
                    * bytes; OS-9 allocates <size> at load and cstart inits it from
                    * WorkBlockImage.  Fields the code references by ,y are named here.
                    * ------------------------------------------------------------------
                    rmb       $1
GlbVar0001          rmb       $2
GlbVar0003          rmb       $4
GlbVar0007          rmb       $2
UserId              rmb       $2
GlbVar000B          rmb       $2
GlbVar000D          rmb       $4
GlbVar0011          rmb       $2
GlbFlag13           rmb       $2
GlbOptP             rmb       $2
GlbLibCount         rmb       $2
GlbOptX             rmb       $4
GlbVar001D          rmb       $2
GlbFlag1F           rmb       $2
GlbVar0021          rmb       $2
GlbOptNamePtr       rmb       $2
GlbFileCount        rmb       $2
GlbDefineCount      rmb       $2
GlbRelFileFlag      rmb       $2
GlbVar002B          rmb       $2
WorkBuf             rmb       $14
NameBuf             rmb       $1E
VersionPtr          rmb       $2
Pow10               rmb       $8
Pow10End            rmb       $2
OneCharStr          rmb       $1
ScratchChar         rmb       $2
FileTable           rmb       $D
StdoutPtr           rmb       $D
OutBuf              rmb       $B7
CtypeTab            rmb       $C0
BreakPtr            rmb       $2
PosField            rmb       $2
PosLow              rmb       $6
ArenaBase           rmb       $2
HeapLimit           rmb       $2
Errno             rmb       $2
LibPtrArray         rmb       $8
FilePtrArray        rmb       $C8
FileTypeArray       rmb       $64
DefinePtrArray      rmb       $C8
CmdBuf              rmb       $3C
TmpMBuf             rmb       $3C
TmpRBuf             rmb       $3C
PrepOutBuf          rmb       $3C
Pass1InBuf          rmb       $3C
FValBuf             rmb       $3C
SavedNameBuf        rmb       $32
TmpPathBuf          rmb       $14
NameCopyBuf         rmb       $C
OutStream           rmb       $2
ConvBuf             rmb       $A
DigitBuf            rmb       $A
LeftJustFlag        rmb       $2
PadChar             rmb       $2
FreeCount           rmb       $2
                    rmb       $380     remaining data, bss and heap
size                equ       .

name                equ       *
                    ifne       CC2
                    fcs        /cc2/
                    else
                    fcs        /cc1/
                    endc
                    fcb       edition

* --- shared C runtime startup (see cstart.i) ---
RTBASE              equ       $01BF     runtime-globals block base in the data area
DATAEND             equ       $05E1     end of static data / heap start / stack limit
HDRADV              equ       $002D     initialized-data header advance
                    use       lib/cstart.asm

main                pshs      u         save the frame pointer
                    ldd       #$FFA1    stack space needed for main
                    lbsr      stkcheck  check stack for main
                    leas      -15,s      allocate the local frame
                    leax      MsgVersion,pcr point at the banner format
                    pshs      x         push the format string
                    ldd       >VersionPtr,y  load the version global
                    pshs      d         push the version argument
                    leax      OutBuf,y   point at the output buffer
                    pshs      x         push the destination buffer
                    lbsr      fprintf   format the startup banner
                    leas      6,s        clean up printf arguments
                    clra                zero the high byte
                    clrb                zero the low byte
                    std       $08,s     clear the local counter
                    leax      >WorkBuf,y  point at the working buffer
                    pshs      x         push the buffer argument
                    lbsr      SubstTempId initialize the working buffer
                    leas      2,s        clean up the argument
                    leax      StrModeW,pcr point at the name template
                    pshs      x         push the template
                    leax      >NameBuf,y  point at the name buffer
                    pshs      x         push the destination
                    lbsr      OpenAndAddFile build the working file name
                    leas      4,s        clean up the arguments
                    std       GlbVar002B save the returned status
                    lbne      NextFileLoop bail out on error
                    leax      MsgShellOpen,pcr point at the usage message
                    pshs      x         push the message
                    lbsr      FatalError print the usage message
                    leas      2,s        clean up the argument
                    lbra      NextFileLoop jump to cleanup

NextArgLoop         ldx       $15,s     load the current argv pointer
                    leax      $02,x     advance to the next argument
                    stx       $15,s     save the updated argv pointer
                    ldd       ,x        load the argument string pointer
                    std       $0C,s     save the current argument
                    tfr       d,x       point x at the argument
                    ldb       ,x        get the first character
                    cmpb      #'-       is it an option dash?
                    lbne      ProcessFile treat as file if not a dash
                    lbra      NextOptChar process option characters

ParseOptChar        ldb       [$0C,s]   load the option letter
                    clra                clear the high byte
                    andb      #$DF      convert letter to uppercase
                    tfr       d,x       index by the option letter
                    lbra      DispatchOption dispatch on the option

OptDefine           ldx       $0C,s     point at the option argument
                    ldb       $01,x     get char after the D
                    lbeq      OptHandled done if a bare -D
                    ldd       #$002D    prepare a dash character
                    ldx       $0C,s     point at the argument
                    leax      -$01,x    back up one byte
                    stx       $0C,s     save the adjusted pointer
                    stb       ,x        write the leading dash
                    ldd       #$0044    prepare the letter D
                    ldx       $0C,s     point at the argument
                    stb       $01,x     write D after the dash
                    ldd       GlbDefineCount load the define count
                    addd      #$0001    increment the count
                    std       GlbDefineCount store the new define count
                    subd      #$0001    recover the index
                    aslb                scale index by two
                    rola                propagate the carry
                    leax      DefinePtrArray,y   point at the define pointer array
                    lbra      StoreOptPtr store the define argument pointer

OptName             ldd       #$002D    prepare a dash character
                    ldx       $0C,s     point at the argument
                    leax      -$01,x    back up one byte
                    stx       $0C,s     save the adjusted pointer
                    stb       ,x        write the leading dash
                    ldd       $0C,s     load the argument pointer
                    std       GlbOptNamePtr save the name option pointer
                    lbra      OptHandled option handled

OptX                ldd       #$0001    prepare true flag
                    std       GlbOptX   set the X option flag
                    lbra      NextOptChar continue with the next char

OptS                ldd       #$0001    prepare true flag
                    std       GlbVar0007 set the S option flag
                    lbra      NextOptChar continue with the next char

OptC                ldd       #$0001    prepare true flag
                    std       GlbVar0001 set the C option flag
                    lbra      NextOptChar continue with the next char

OptP                ldd       #$0001    prepare true flag
                    std       GlbOptP   set the P option flag
                    lbra      NextOptChar continue with the next char

OptOptimize         ldd       #$0001    prepare true flag
                    std       GlbVar0011 set the O optimize flag
                    lbra      NextOptChar continue with the next char

OptR                ldd       #$0001    prepare true flag
                    std       GlbVar000B set the R option flag
                    lbra      NextOptChar continue with the next char

OptA                ldd       #$0001    prepare true flag
                    std       GlbVar000D set the A option flag
                    lbra      NextOptChar continue with the next char

OptE                leax      >GlbVar0021,y  point at the E option buffer
                    stx       $0a,s     save the target buffer
                    leax      $0f,s     compute the frame restore
                    bra       OptEMRestore join the common option code

OptM                leax      >GlbFlag1F,y  point at the M option buffer
                    stx       $0a,s     save the target buffer
                    bra       OptEMStore join the common option code

OptEMRestore        leas      -$0f,x    restore frame for the E option
OptEMStore          ldb       [$0C,s]   load the option letter
                    clra                clear the high byte
                    andb      #$5f      uppercase the letter
                    stb       [$0C,s]   store the uppercased letter
                    ldx       $0C,s     point at the argument
                    ldb       $01,x     get char after the letter
                    lbeq      OptHandled done if a bare option
                    ldd       #$002D    prepare a dash character
                    ldx       $0C,s     point at the argument
                    leax      -$01,x    back up one byte
                    stx       $0C,s     save the adjusted pointer
                    stb       ,x        write the leading dash
                    ldd       $0C,s     load the argument pointer
                    std       [$0a,s]   save the option pointer
                    lbra      OptHandled option handled

OptF                ldx       $0C,s     point at the F option argument
                    leax      $01,x     advance past the F
                    stx       $0C,s     save the pointer
                    ldb       ,x        get the next char
                    cmpb      #'=       is it an equals sign?
                    lbne      OptHandled done if no value follows
                    ldd       $0C,s     load the argument pointer
                    addd      #$0001    skip past the equals
                    pshs      d         push the value pointer
                    leax      FValBuf,y   point at the F value buffer
                    pshs      x         push the destination
                    lbsr      strcpy    copy the option value
                    leas      4,s        clean up the arguments
                    ldb       FValBuf,y   get the first value char
                    lbeq      OptHandled done if the value is empty
                    ldd       GlbVar0003 load the F option count
                    addd      #$0001    increment the count
                    std       GlbVar0003 store the new count
                    leax      FValBuf,y   point at the value buffer
                    pshs      x         push the value
                    lbsr      GetFileSuffix get the value type character
                    leas      2,s        clean up the argument
                    stb       $0e,s     save the type character
                    cmpb      #'c       is it lowercase c?
                    beq       OptFTypeOk accept the c type
                    ldb       $0e,s     reload the type char
                    cmpb      #'r       is it lowercase r?
                    beq       OptFTypeOk accept the r type
                    ldb       $0e,s     reload the type char
                    cmpb      #'C       is it uppercase C?
                    beq       OptFTypeOk accept the C type
                    ldb       $0e,s     reload the type char
                    cmpb      #'R       is it uppercase R?
                    bne       OptHandled reject an unknown type
OptFTypeOk          ldb       $0e,s     reload the accepted type
                    sex                 sign extend to a word
                    pshs      d         push the type argument
                    leax      MsgBadSuffix,pcr point at the message string
                    pshs      x         push the format
                    lbsr      FatalError report the F option type
                    leas      4,s        clean up the arguments
                    bra       OptHandled option handled

OptLibrary          ldx       $0C,s     point at the L option argument
                    ldb       $01,x     get char after the L
                    cmpb      #'=       is it an equals sign?
                    bne       OptHandled done if no value follows
                    ldd       GlbLibCount load the library count
                    cmpd      #$0004    reached maximum libraries?
                    bne       OptLibStore store if room remains
                    leax      MsgTooManyLibs,pcr point at the too-many message
                    pshs      x         push the message
                    lbsr      FatalError report too many libraries
                    leas      2,s        clean up the argument
OptLibStore         ldd       #$002D    prepare a dash character
                    ldx       $0C,s     point at the argument
                    leax      -$01,x    back up one byte
                    stx       $0C,s     save the adjusted pointer
                    stb       ,x        write the leading dash
                    ldd       GlbLibCount load the library count
                    addd      #$0001    increment the count
                    std       GlbLibCount store the new library count
                    subd      #$0001    recover the index
                    aslb                scale index by two
                    rola                propagate the carry
                    leax      LibPtrArray,y   point at the library pointer array
StoreOptPtr         leax      d,x       index into the pointer array
                    ldd       $0C,s     load the argument pointer
                    std       ,x        store the option argument pointer
OptHandled          leax      $0f,s     restore the local frame
                    lbra      OptArgDone finish option handling

OptUnknown          ldb       [$0C,s]   load the unknown option char
                    sex                 sign extend to a word
                    pshs      d         push the option char
                    leax      MsgUnknownFlag,pcr point at the unknown option message
                    pshs      x         push the format
                    lbsr      FatalError report the unknown option
                    leas      4,s        clean up the arguments
                    bra       NextOptChar continue with the next char

DispatchOption      cmpx      #$0044    option D?
                    lbeq      OptDefine handle the define option
                    cmpx      #$004E    option N?
                    lbeq      OptName   handle the name option
                    cmpx      #$0058    option X?
                    lbeq      OptX      handle the X option
                    cmpx      #$0053    option S?
                    lbeq      OptS      handle the S option
                    cmpx      #$0043    option C?
                    lbeq      OptC      handle the C option
                    cmpx      #$0050    option P?
                    lbeq      OptP      handle the P option
                    cmpx      #$004F    option O?
                    lbeq      OptOptimize handle the optimize option
                    cmpx      #$0052    option R?
                    lbeq      OptR      handle the R option
                    cmpx      #$0041    option A?
                    lbeq      OptA      handle the A option
                    cmpx      #$0045    option E?
                    lbeq      OptE      handle the E option
                    cmpx      #$004D    option M?
                    lbeq      OptM      handle the M option
                    cmpx      #$0046    option F?
                    lbeq      OptF      handle the F option
                    cmpx      #$004C    option L?
                    lbeq      OptLibrary handle the library option
                    bra       OptUnknown unknown option letter

NextOptChar         ldx       $0C,s     point at the option argument
                    leax      $01,x     advance to the next char
                    stx       $0C,s     save the pointer
                    ldb       ,x        get the next option char
                    lbne      ParseOptChar process another option letter
                    lbra      NextFileLoop done with this argument

OptArgDone          leas      -$0f,x    restore the stack frame
                    lbra      NextFileLoop continue the argument loop

ProcessFile         ldd       [$15,s]   load the file argument pointer
                    pshs      d         push the file name
                    lbsr      GetFileSuffix get the file extension char
                    leas      2,s        clean up the argument
                    stb       $0e,s     save the extension character
                    sex                 sign extend to a word
                    tfr       d,x       index by the extension
                    bra       DispatchFileType dispatch on the file type

FileTypeRel         ldd       #$0001    prepare true flag
                    std       GlbRelFileFlag mark a relocatable file present
StoreInputFile      ldd       GlbFileCount load the file count
                    leax      FileTypeArray,y   point at the file type array
                    leax      d,x       index by the file number
                    ldb       $0e,s     get the file type char
                    stb       ,x        store the file type
                    ldd       GlbFileCount load the file count
                    aslb                scale index by two
                    rola                propagate the carry
                    leax      FilePtrArray,y   point at the file pointer array
                    leax      d,x       index by the file number
                    ldd       [$15,s]   load the file name pointer
                    std       ,x        store the file name pointer
                    ldd       GlbFileCount load the file count
                    addd      #$0001    increment the file count
                    std       GlbFileCount store the new file count
                    bra       NextFileLoop continue the argument loop

FileTypeError       ldd       [$15,s]   load the bad file name
                    pshs      d         push the file name
                    leax      MsgNoSuffix,pcr point at the bad type message
                    pshs      x         push the format
                    lbsr      FatalError report the bad file type
                    leas      4,s        clean up the arguments
                    bra       NextFileLoop continue the argument loop

DispatchFileType    cmpx      #$0052    extension R?
                    beq       FileTypeRel handle a relocatable file
                    cmpx      #$0072    extension r?
                    lbeq      FileTypeRel handle a relocatable file
                    cmpx      #$0041    extension A?
                    beq       StoreInputFile store an assembly file
                    cmpx      #$0043    extension C?
                    lbeq      StoreInputFile store a C source file
                    cmpx      #$0061    extension a?
                    lbeq      StoreInputFile store an assembly file
                    cmpx      #$0063    extension c?
                    lbeq      StoreInputFile store a C source file
                    bra       FileTypeError branch back to option-scan loop

NextFileLoop        ldd       $13,s     load remaining file counter
                    addd      #$FFFF    decrement the counter
                    std       $13,s     store updated counter
                    ble       NoFilesCheck done when no files remain
                    ldd       $08,s     load current file index
                    addd      #$0001    advance to next file
                    std       $08,s     store file index
                    cmpd      #$0064    cap at one hundred files
                    lblt      NextArgLoop loop back to scan next file
NoFilesCheck        ldd       GlbFileCount load count of input files
                    bne       IncompatFlagCheck proceed if any files given
                    leax      MsgNoFiles,pcr point at no-files message
                    pshs      x         push message argument
                    leax      OutBuf,y   point at stderr stream
                    pshs      x         push stream argument
                    lbsr      fprintf   print the no-files error
                    leas      4,s        clean up call arguments
                    clra                zero exit status high
                    clrb                zero exit status low
                    pshs      d         push exit code
                    lbsr      exit      terminate the driver
                    leas      2,s        drop argument after exit
IncompatFlagCheck   ldd       GlbVar000D load one intermediate flag
                    addd      GlbVar000B combine with the other flag
                    cmpd      #$0001    check for conflicting flags
                    ble       OutNameCheck ok if at most one set
                    clra                zero severity high
                    clrb                zero severity low
                    pshs      d         push severity argument
                    leax      MsgIncompatFlags,pcr point at incompatible flags message
                    pshs      x         push message
                    lbsr      FatalError report incompatible flags
                    leas      4,s        clean up arguments
OutNameCheck        ldd       GlbVar0003 load output-name-given flag
                    beq       SetDefaultOut skip check if no output name
                    ldd       GlbFileCount load input file count
                    cmpd      #$0001    more than one input file
                    ble       SetDefaultOut ok if single file
                    ldd       GlbVar000D load assemble-only flag
                    bne       OutNameErr warn if set
                    ldd       GlbVar000B load compile-only flag
                    beq       SetDefaultOut ok when neither is set
OutNameErr          leax      FValBuf,y   point at output name
                    pshs      x         push name argument
                    leax      MsgOutputNA,pcr point at output-not-applicable message
                    pshs      x         push message
                    lbsr      FatalError report inapplicable output name
                    leas      4,s        clean up arguments
SetDefaultOut       ldd       GlbVar0003 load output-name-given flag
                    bne       BuildTempNames skip default when name given
                    ldd       GlbFileCount load input file count
                    cmpd      #$0001    exactly one input file
                    bne       UseGenericName use generic name for many files
                    ldd       FilePtrArray,y   load single input name pointer
                    pshs      d         push it as default base
                    bra       StoreOutName go store output name

UseGenericName      leax      NameOutput,pcr point at generic "output" name
                    pshs      x         push default name
StoreOutName        leax      FValBuf,y   point at output buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy default output name
                    leas      4,s        clean up arguments
BuildTempNames      leax      >WorkBuf,y  point at base name
                    pshs      x         push source
                    leax      TmpMBuf,y   point at .m temp buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy base into temp name
                    leas      4,s        clean up arguments
                    leax      SufDotM,pcr point at ".m" suffix
                    pshs      x         push suffix
                    leax      TmpMBuf,y   point at temp buffer
                    pshs      x         push destination
                    lbsr      strcat    append .m suffix to temp name
                    leas      4,s        clean up arguments
                    leax      >WorkBuf,y  point at base name
                    pshs      x         push source
                    leax      TmpRBuf,y   point at .r temp buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy base into temp name
                    leas      4,s        clean up arguments
                    leax      SufDotR,pcr point at ".r" suffix
                    pshs      x         push suffix
                    leax      TmpRBuf,y   point at temp buffer
                    pshs      x         push destination
                    lbsr      strcat    append .r suffix to temp name
                    leas      4,s        clean up arguments
                    clra                reset file index high
                    clrb                reset file index low
                    std       $08,s     store index
                    lbra      FileLoopTest enter phase command emit loop

EmitFileCmds        leax      StrEchoQuote,pcr point at "echo '" prefix
                    pshs      x         push string
                    lbsr      PrintTrace append echo prefix to script
                    leas      2,s        clean up argument
                    ldd       $08,s     load current file index
                    aslb                scale index high
                    rola                scale index to word offset
                    leax      FilePtrArray,y   point at filename pointer array
                    leax      d,x       index the entry
                    ldd       ,x        load source filename pointer
                    pshs      d         push it
                    lbsr      PrintTrace append source name to script
                    leas      2,s        clean up argument
                    leax      StrQuote,pcr point at closing quote newline
                    pshs      x         push string
                    lbsr      PrintTrace close the echo line
                    leas      2,s        clean up argument
                    ldd       $08,s     load file index
                    leax      FileTypeArray,y   point at file-type array
                    leax      d,x       index the entry
                    ldb       ,x        load this file's type char
                    cmpb      #'C       is it uppercase C
                    beq       EmitCPrepCmd compile as C source
                    ldd       $08,s     reload file index
                    leax      FileTypeArray,y   file-type array
                    leax      d,x       index entry
                    ldb       ,x        load type char
                    cmpb      #'c       is it lowercase c
                    lbne      NotCFile  not C, handle other file type
EmitCPrepCmd        ldd       #$0001    mark this as a C file
                    std       ,s        store is-C flag
                    leax      TmpMBuf,y   point at .m temp name
                    pshs      x         push source
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy temp name to scratch
                    leas      4,s        clean up arguments
                    ldd       #$006D    character 'm'
                    pshs      d         push suffix char
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push buffer
                    lbsr      SetFileSuffix append 'm' suffix
                    leas      4,s        clean up arguments
                    leax      StrDashX,pcr point at "-x" line
                    pshs      x         push string
                    lbsr      PrintTrace append shell abort option
                    leas      2,s        clean up argument
                    leax      PhasePrep,pcr point at "C.PREP "
                    pshs      x         push string
                    lbsr      PrintTrace append preprocessor command
                    leas      2,s        clean up argument
                    ldd       GlbVar0001 load list flag
                    beq       AppendPrepOpt skip if not set
                    leax      OptDashL,pcr point at "-l " option
                    pshs      x         push option
                    lbsr      PrintTrace append list option
                    leas      2,s        clean up argument
AppendPrepOpt       ldd       GlbVar0021 load extra option pointer
                    beq       DefsLoopInit skip if none
                    ldd       GlbVar0021 reload option string pointer
                    pshs      d         push it
                    lbsr      PrintTrace append extra preprocessor option
                    leas      2,s        clean up argument
                    leax      StrSpace1,pcr point at space separator
                    pshs      x         push separator
                    lbsr      PrintTrace append separating space
                    leas      2,s        clean up argument
DefsLoopInit        clra                clear define index high
                    clrb                clear define index low
                    std       $04,s     store loop index
                    bra       DefsLoopTest test loop condition

DefsAppendLoop      ldd       $04,s     load define index
                    addd      #$0001    advance index
                    std       $04,s     store updated index
                    subd      #$0001    recover current index
                    aslb                scale index high
                    rola                scale to word offset
                    leax      DefinePtrArray,y   point at defines pointer array
                    leax      d,x       index the entry
                    ldd       ,x        load define string pointer
                    pshs      d         push it
                    lbsr      PrintTrace append -D define to command
                    leas      2,s        clean up argument
                    leax      StrSpace2,pcr point at space separator
                    pshs      x         push separator
                    lbsr      PrintTrace append separating space
                    leas      2,s        clean up argument
DefsLoopTest        ldd       $04,s     load define index
                    cmpd      GlbDefineCount compare with define count
                    blt       DefsAppendLoop loop over remaining defines
                    ldd       $08,s     load file index
                    aslb                scale index high
                    rola                scale to word offset
                    leax      FilePtrArray,y   point at filename array
                    leax      d,x       index entry
                    ldd       ,x        load source filename pointer
                    pshs      d         push it
                    lbsr      PrintTrace append source name to command
                    leas      2,s        clean up argument
                    leax      StrRedirect,pcr point at " >" redirect
                    pshs      x         push redirect
                    lbsr      PrintTrace append output redirect
                    leas      2,s        clean up argument
                    leax      PrepOutBuf,y   point at prep output name
                    pshs      x         push name
                    lbsr      PrintTrace append preprocessor output file
                    leas      2,s        clean up argument
                    leax      PrepOutBuf,y   point at prep output name
                    pshs      x         push source
                    leax      Pass1InBuf,y   point at pass1 input buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy prep output to pass1 input
                    leas      4,s        clean up arguments
                    ifne       CC2
                    * ------------------------------------------------------------------
                    * cc2: compile in a single pass with c.comp, which reads the
                    * preprocessor output and emits the .a assembler source directly
                    * (the combined job of c.pass1 then c.pass2).  c.comp accepts only
                    * -s, -p and -o=, so no -e is passed.
                    * ------------------------------------------------------------------
                    leax       EchoComp,pcr point at c.comp echo header
                    pshs       x         push string
                    lbsr       PrintTrace append c.comp echo line
                    leas       2,s       clean up argument
                    leax       PhaseComp,pcr point at "C.COMP "
                    pshs       x         push command
                    lbsr       PrintTrace append c.comp command
                    leas       2,s       clean up argument
                    leax       Pass1InBuf,y point at prep output name
                    pshs       x         push name
                    lbsr       PrintTrace append c.comp input file
                    leas       2,s       clean up argument
                    ldd        GlbVar0007 load strip flag
                    beq        CompCheckProf skip if not set
                    leax       OptPass1S,pcr point at " -s " option
                    pshs       x         push option
                    lbsr       PrintTrace append strip option
                    leas       2,s       clean up argument
CompCheckProf       ldd        GlbOptP   load profile flag
                    beq        CompSelectOut skip if not set
                    leax       OptPass1P,pcr point at " -p " option
                    pshs       x         push option
                    lbsr       PrintTrace append profile option
                    leas       2,s       clean up argument
CompSelectOut       ldd        GlbVar000D load assemble-only flag
                    beq        CompAppendA use default output base
                    ldd        GlbVar0003 load output-name-given flag
                    beq        CompUseInput use input name if none given
                    leax       FValBuf,y point at output name
                    pshs       x         push source
                    leax       PrepOutBuf,y point at scratch buffer
                    pshs       x         push destination
                    lbsr       strcpy   copy output name to scratch
                    bra        CompEmitOut continue with output
CompUseInput        ldd        $08,s     load file index
                    aslb                 scale index high
                    rola                 scale to word offset
                    leax       FilePtrArray,y point at filename array
                    leax       d,x       index entry
                    ldd        ,x        load source filename pointer
                    pshs       d         push source
                    leax       PrepOutBuf,y point at scratch buffer
                    pshs       x         push destination
                    lbsr       strcpy   copy input name to scratch
                    leas       4,s       clean up arguments
CompAppendA         ldd        #$0061    character 'a'
                    pshs       d         push suffix char
                    leax       PrepOutBuf,y point at scratch buffer
                    pshs       x         push buffer
                    lbsr       SetFileSuffix append 'a' suffix
CompEmitOut         leas       4,s       clean up arguments
                    leax       OptPass2Out,pcr point at " -o=" option
                    pshs       x         push option
                    lbsr       PrintTrace append output option
                    leas       2,s       clean up argument
                    leax       PrepOutBuf,y point at output name
                    pshs       x         push name
                    lbsr       PrintTrace append output file
                    leas       2,s       clean up argument
                    ldd        GlbFlag13 load keep-intermediate flag
                    bne        CompFinish keep the prep output
                    leax       CmdDelPass1,pcr point at "del " command
                    pshs       x         push command
                    lbsr       PrintTrace append delete of prep output
                    leas       2,s       clean up argument
                    leax       Pass1InBuf,y point at prep output name
                    pshs       x         push name
                    lbsr       PrintTrace append name to delete
                    leas       2,s       clean up argument
CompFinish          leax       CrNulPass2,pcr point at newline terminator
                    pshs       x         push terminator
                    lbsr       PrintTrace finish the compile chain line
                    leas       2,s       clean up argument
                    bra        EmitAsmStep continue to assembler step
                    else
                    leax      EchoPass1,pcr point at pass1 echo header
                    pshs      x         push string
                    lbsr      PrintTrace append pass1 echo line
                    leas      2,s        clean up argument
                    leax      PhasePass1,pcr point at "C.PASS1 "
                    pshs      x         push command
                    lbsr      PrintTrace append pass1 command
                    leas      2,s        clean up argument
                    leax      Pass1InBuf,y   point at pass1 input name
                    pshs      x         push name
                    lbsr      PrintTrace append pass1 input file
                    leas      2,s        clean up argument
                    ldd       GlbFlag13 load keep-intermediate flag
                    beq       Pass1CheckStrip skip if not set
                    leax      OptPass1E,pcr point at "-e " option
                    pshs      x         push option
                    lbsr      PrintTrace append error-stop option
                    leas      2,s        clean up argument
Pass1CheckStrip     ldd       GlbVar0007 load strip flag
                    beq       Pass1CheckProf skip if not set
                    leax      OptPass1S,pcr point at " -s " option
                    pshs      x         push option
                    lbsr      PrintTrace append strip option
                    leas      2,s        clean up argument
Pass1CheckProf      ldd       GlbOptP   load profile flag
                    beq       EmitPass1Out skip if not set
                    leax      OptPass1P,pcr point at " -p " option
                    pshs      x         push option
                    lbsr      PrintTrace append profile option
                    leas      2,s        clean up argument
EmitPass1Out        leax      TmpMBuf,y   point at base name
                    pshs      x         push source
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy base name to scratch
                    leas      4,s        clean up arguments
                    ldd       #$0069    character 'i'
                    pshs      d         push suffix char
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push buffer
                    lbsr      SetFileSuffix append 'i' suffix
                    leas      4,s        clean up arguments
                    leax      OptPass1Out,pcr point at " -o=" option
                    pshs      x         push option
                    lbsr      PrintTrace append pass1 output option
                    leas      2,s        clean up argument
                    leax      PrepOutBuf,y   point at pass1 output name
                    pshs      x         push name
                    lbsr      PrintTrace append pass1 output file
                    leas      2,s        clean up argument
                    ldd       GlbFlag13 load keep-intermediate flag
                    bne       SaveIntermedName keep the intermediate name
                    leax      CmdDelPass1,pcr point at "del " command
                    pshs      x         push command
                    lbsr      PrintTrace append delete of prep output
                    leas      2,s        clean up argument
                    leax      Pass1InBuf,y   point at prep output name
                    pshs      x         push name
                    lbsr      PrintTrace append name to delete
                    leas      2,s        clean up argument
                    leax      CrNulPass1,pcr point at newline terminator
                    pshs      x         push terminator
                    lbsr      PrintTrace finish delete command
                    leas      2,s        clean up argument
                    bra       EmitPass2Cmd continue to pass2 command

SaveIntermedName    leax      Pass1InBuf,y   point at prep output name
                    pshs      x         push source
                    leax      SavedNameBuf,y   point at saved-name buffer
                    pshs      x         push destination
                    lbsr      strcpy    save intermediate name for later
                    leas      4,s        clean up arguments
EmitPass2Cmd        leax      EchoPass2,pcr point at pass2 echo header
                    pshs      x         push string
                    lbsr      PrintTrace append pass2 echo line
                    leas      2,s        clean up argument
                    leax      PhasePass2,pcr point at "C.PASS2 "
                    pshs      x         push command
                    lbsr      PrintTrace append pass2 command
                    leas      2,s        clean up argument
                    leax      PrepOutBuf,y   point at pass1 output name
                    pshs      x         push source
                    leax      Pass1InBuf,y   point at pass2 input buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy pass1 output to pass2 input
                    leas      4,s        clean up arguments
                    leax      Pass1InBuf,y   point at pass2 input name
                    pshs      x         push name
                    lbsr      PrintTrace append pass2 input file
                    leas      2,s        clean up argument
                    ldd       GlbVar0007 load strip flag
                    beq       Pass2CheckProf skip if not set
                    leax      OptPass2S,pcr point at " -s " option
                    pshs      x         push option
                    lbsr      PrintTrace append strip option
                    leas      2,s        clean up argument
Pass2CheckProf      ldd       GlbOptP   load profile flag
                    beq       Pass2CheckKeep skip if not set
                    leax      OptPass2P,pcr point at " -p " option
                    pshs      x         push option
                    lbsr      PrintTrace append profile option
                    leas      2,s        clean up argument
Pass2CheckKeep      ldd       GlbFlag13 load keep-intermediate flag
                    beq       SelectAsmOutName skip if not set
                    leax      StrSpace3,pcr point at space separator
                    pshs      x         push separator
                    lbsr      PrintTrace append separating space
                    leas      2,s        clean up argument
                    leax      SavedNameBuf,y   point at saved name
                    pshs      x         push name
                    lbsr      PrintTrace append saved intermediate name
                    leas      2,s        clean up argument
SelectAsmOutName    ldd       GlbVar000D load assemble-only flag
                    beq       AppendCharA use default output base
                    ldd       GlbVar0003 load output-name-given flag
                    beq       UseInputName use input name if none given
                    leax      FValBuf,y   point at output name
                    pshs      x         push source
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy output name to scratch
                    bra       EmitPass2Out continue with pass2 output

UseInputName        ldd       $08,s     load file index
                    aslb                scale index high
                    rola                scale to word offset
                    leax      FilePtrArray,y   point at filename array
                    leax      d,x       index entry
                    ldd       ,x        load source filename pointer
                    pshs      d         push source
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy input name to scratch
                    leas      4,s        clean up arguments
AppendCharA         ldd       #$0061    character 'a'
                    pshs      d         push suffix char
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push buffer
                    lbsr      SetFileSuffix append 'a' suffix
EmitPass2Out        leas      4,s        clean up arguments
                    leax      OptPass2Out,pcr point at " -o=" option
                    pshs      x         push option
                    lbsr      PrintTrace append pass2 output option
                    leas      2,s        clean up argument
                    leax      PrepOutBuf,y   point at pass2 output name
                    pshs      x         push name
                    lbsr      PrintTrace append pass2 output file
                    leas      2,s        clean up argument
                    leax      CmdDelPass2,pcr point at delete command
                    pshs      x         push command
                    lbsr      PrintTrace append delete command
                    leas      2,s        clean up argument
                    leax      Pass1InBuf,y   point at pass2 output name
                    pshs      x         push name
                    lbsr      PrintTrace append output to delete
                    leas      2,s        clean up argument
                    ldd       GlbFlag13 load keep-intermediate flag
                    beq       FinishCChain skip second delete if keeping
                    leax      StrDelSpc,pcr point at second delete command
                    pshs      x         push command
                    lbsr      PrintTrace append delete command
                    leas      2,s        clean up argument
                    leax      SavedNameBuf,y   point at saved name
                    pshs      x         push name
                    lbsr      PrintTrace append name to delete
                    leas      2,s        clean up argument
FinishCChain        leax      CrNulPass2,pcr point at newline terminator
                    pshs      x         push terminator
                    lbsr      PrintTrace finish the compile chain line
                    leas      2,s        clean up argument
                    bra       EmitAsmStep continue to assembler step
                    endc

NotCFile            clra                clear is-C flag high
                    clrb                clear is-C flag low
                    std       ,s        store not-a-C-file
EmitAsmStep         ldd       GlbVar000D load assemble-only flag
                    lbne      AfterOutEcho skip assembly if set
                    ldd       $08,s     load file index
                    leax      FileTypeArray,y   point at file-type array
                    leax      d,x       index entry
                    ldb       ,x        load type char
                    cmpb      #'R       is it uppercase R
                    lbeq      AfterOutEcho relocatable, skip assembly
                    ldd       $08,s     reload file index
                    leax      FileTypeArray,y   file-type array
                    leax      d,x       index entry
                    ldb       ,x        load type char
                    cmpb      #'r       is it lowercase r
                    lbeq      AfterOutEcho relocatable, skip assembly
                    ldd       $08,s     reload file index
                    leax      FileTypeArray,y   file-type array
                    leax      d,x       index entry
                    ldb       ,x        load type char
                    cmpb      #'A       is it uppercase A
                    beq       AsmUseInput assembly source, use input
                    ldd       $08,s     reload file index
                    leax      FileTypeArray,y   file-type array
                    leax      d,x       index entry
                    ldb       ,x        load type char
                    cmpb      #'a       is it lowercase a
                    bne       AsmUseTemp otherwise use temp name
AsmUseInput         ldd       $08,s     load file index
                    aslb                scale index high
                    rola                scale to word offset
                    leax      FilePtrArray,y   point at filename array
                    leax      d,x       index entry
                    ldd       ,x        load source filename pointer
                    pshs      d         push input as assembler source
                    bra       BuildOptCmd go copy the name

AsmUseTemp          leax      PrepOutBuf,y   point at scratch name
                    pshs      x         push scratch as source
BuildOptCmd         leax      Pass1InBuf,y   point at assembler input buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy assembler input name
                    leas      4,s        clean up arguments
                    ldd       GlbVar0011 load copy-only flag
                    lbne      EchoCompileCmd skip assembly if copying
                    leax      EchoOpt,pcr point at optimizer echo header
                    pshs      x         push string
                    lbsr      PrintTrace append optimizer echo line
                    leas      2,s        clean up argument
                    leax      PhaseOpt,pcr point at "C.OPT " command
                    pshs      x         push command
                    lbsr      PrintTrace append optimizer command
                    leas      2,s        clean up argument
                    leax      Pass1InBuf,y   point at optimizer input name
                    pshs      x         push name
                    lbsr      PrintTrace append optimizer input file
                    leas      2,s        clean up argument
                    leax      TmpMBuf,y   point at base name
                    pshs      x         push source
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push destination
                    lbsr      strcpy    copy base name to scratch
                    leas      4,s        clean up arguments
                    ldd       #$006F    character 'o'
                    pshs      d         push suffix char
                    leax      PrepOutBuf,y   point at scratch buffer
                    pshs      x         push buffer
                    lbsr      SetFileSuffix append 'o' suffix
                    leas      4,s        clean up arguments
                    leax      StrSpace4,pcr load intro format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string to trace
                    leas      2,s        drop the argument
                    leax      PrepOutBuf,y   load the command buffer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the command buffer
                    leas      2,s        drop the argument
                    leax      StrCrNul,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       ,s        load output-name flag
                    beq       AppendSrcName skip output echo if unset
                    leax      CmdDel,pcr load -o label string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      Pass1InBuf,y   load output-name buffer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the output name
                    leas      2,s        drop the argument
                    leax      CrNulOpt,pcr load trailing string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
AppendSrcName       leax      PrepOutBuf,y   load destination command buffer
                    pshs      x         push destination pointer
                    leax      Pass1InBuf,y   load output-name buffer
                    pshs      x         push source pointer
                    lbsr      strcpy    append name into command buffer
                    leas      4,s        drop the two arguments
EchoCompileCmd      leax      EchoAsm,pcr load compile format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      PhaseAsm,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      Pass1InBuf,y   load output-name buffer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the output name
                    leas      2,s        drop the argument
                    ldd       GlbFileCount load source file count
                    cmpd      #$0001    is it a single file
                    bne       CheckStopAfter branch if more than one
                    ldd       GlbVar000B check compile-only flag
                    bne       CheckStopAfter branch if set
                    leax      TmpRBuf,y   load default name buffer
PushOutName         pshs      x         push the name pointer
                    bra       EchoCmdArg go echo the name

CheckStopAfter      ldd       GlbVar0003 check output flag
                    beq       StripSrcSuffix branch if clear
                    ldd       GlbVar000B check compile-only flag
                    beq       StripSrcSuffix branch if clear
                    leax      FValBuf,y   load alternate name buffer
                    bra       PushOutName push it as the name

StripSrcSuffix      ldd       #$0072    load suffix char code
                    pshs      d         push suffix argument
                    ldd       $0a,s     load loop index
                    aslb                index times two low
                    rola                index times two high
                    leax      FilePtrArray,y   load name pointer table
                    leax      d,x       index into the table
                    ldd       ,x        load the name pointer
                    pshs      d         push name pointer
                    lbsr      SetFileSuffix strip its file suffix
                    leas      4,s        drop the arguments
                    ldd       $08,s     load loop index
                    aslb                index times two low
                    rola                index times two high
                    leax      FilePtrArray,y   load name pointer table
                    leax      d,x       index into the table
                    ldd       ,x        load the name pointer
                    pshs      d         push it for echo
EchoCmdArg          leax      PrepOutBuf,y   load destination command buffer
                    pshs      x         push destination pointer
                    lbsr      strcpy    append name into command buffer
                    leas      4,s        drop the two arguments
                    leax      OptAsmOut,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      PrepOutBuf,y   load command buffer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the command buffer
                    leas      2,s        drop the argument
                    leax      CrNulAsmOut,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       ,s        load output flag
                    beq       AfterOutEcho skip output echo if unset
                    leax      CmdDelAsm,pcr load -o label string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      Pass1InBuf,y   load output-name buffer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the output name
                    leas      2,s        drop the argument
                    leax      CrNulAsmDel,pcr load trailing string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
AfterOutEcho        ldd       $08,s     load file loop index
                    addd      #$0001    advance to next file
                    std       $08,s     store loop index
FileLoopTest        ldd       $08,s     load file loop index
                    cmpd      GlbFileCount compare against file count
                    lblt      EmitFileCmds loop over remaining files
                    ldd       GlbVar000D check assemble-only flag
                    lbne      FinishAndRun skip link if set
                    ldd       GlbVar000B check compile-only flag
                    lbne      FinishAndRun skip link if set
                    ldd       GlbVar0003 check output flag
                    bne       EchoLinkCmd skip default name block
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push null suffix argument
                    leax      FValBuf,y   load default name buffer
                    pshs      x         push name pointer
                    lbsr      SetFileSuffix strip the file suffix
                    leas      4,s        drop the arguments
EchoLinkCmd         leax      EchoLink,pcr load link format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      PhaseLink,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      StrDdDir,pcr load object list string
                    stx       $0C,s     save pointer in local
                    ldd       $0C,s     load the saved pointer
                    pshs      d         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      LibCstart,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       GlbFileCount load source file count
                    cmpd      #$0001    is it a single file
                    bne       NoRelocOut branch if not one
                    ldb       FileTypeArray,y   load output suffix char
                    cmpb      #$52      is it uppercase relocatable
                    beq       NoRelocOut skip redirect if so
                    ldb       FileTypeArray,y   reload suffix char
                    cmpb      #$72      is it lowercase relocatable
                    beq       NoRelocOut skip redirect if so
                    leax      StrLinkSpace,pcr load -o redirect string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      PrepOutBuf,y   load command buffer
                    stx       GlbVar001D save as final output pointer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the output name
                    leas      2,s        drop the argument
                    bra       EchoLibSetup skip the object loop

NoRelocOut          clra                zero high byte
                    clrb                zero low byte
                    bra       ObjLoopNext enter object echo loop

EchoObjLoop         leax      StrObjPrefix,pcr load object prefix string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       $08,s     load object index
                    aslb                index times two low
                    rola                index times two high
                    leax      FilePtrArray,y   load name pointer table
                    leax      d,x       index into the table
                    ldd       ,x        load object name pointer
                    pshs      d         push name pointer
                    lbsr      PrintTrace echo the object name
                    leas      2,s        drop the argument
                    ldd       $08,s     load object index
                    addd      #$0001    advance to next object
ObjLoopNext         std       $08,s     store object index
                    ldd       $08,s     load object index
                    cmpd      GlbFileCount compare against file count
                    blt       EchoObjLoop loop over objects
                    clra                zero high byte
                    clrb                zero low byte
                    std       GlbVar001D clear final output pointer
EchoLibSetup        leax      OptLinkO,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      FValBuf,y   load library name buffer
                    pshs      x         push buffer pointer
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    clra                zero high byte
                    clrb                zero low byte
                    bra       LibLoopNext enter library echo loop

EchoLibLoop         leax      StrLibPrefix,pcr load library prefix string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       $06,s     load library index
                    aslb                index times two low
                    rola                index times two high
                    leax      LibPtrArray,y   load library pointer table
                    leax      d,x       index into the table
                    ldd       ,x        load library name pointer
                    pshs      d         push name pointer
                    lbsr      PrintTrace echo the library name
                    leas      2,s        drop the argument
                    ldd       $06,s     load library index
                    addd      #$0001    advance to next library
LibLoopNext         std       $06,s     store library index
                    ldd       $06,s     load library index
                    cmpd      GlbLibCount compare against library count
                    blt       EchoLibLoop loop over libraries
                    leax      OptLinkL,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       $0C,s     load saved object list pointer
                    pshs      d         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    leax      LibClib,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       GlbOptNamePtr load first option value
                    pshs      d         push option argument
                    lbsr      PrintOptArg print option arg if set
                    leas      2,s        drop the argument
                    ldd       GlbVar0021 load second option value
                    pshs      d         push option argument
                    lbsr      PrintOptArg print option arg if set
                    leas      2,s        drop the argument
                    ldd       GlbFlag1F load third option value
                    pshs      d         push option argument
                    lbsr      PrintOptArg print option arg if set
                    leas      2,s        drop the argument
                    leax      StrCrNul2,pcr load format string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       GlbVar001D load final output pointer
                    beq       FinishAndRun skip if no output name
                    leax      CmdDel2,pcr load -o label string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
                    ldd       GlbVar001D load final output pointer
                    pshs      d         push output pointer
                    lbsr      PrintTrace echo the output name
                    leas      2,s        drop the argument
                    leax      CrNulClib,pcr load trailing string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the string
                    leas      2,s        drop the argument
FinishAndRun        ldd       GlbVar002B load trace file handle
                    pshs      d         push file handle
                    lbsr      fclose    close the trace file
                    leas      2,s        drop the argument
                    ldd       GlbOptX   check verbose-only flag
                    lbne      EchoRunDone skip running if set
                    leax      OptAsmTP,pcr load command tail string
                    pshs      x         push string argument
                    leax      CmdBuf,y   load command buffer
                    pshs      x         push destination pointer
                    lbsr      strcpy    append tail to command
                    leas      4,s        drop the two arguments
                    leax      >FileTable,y  load working buffer
                    pshs      x         push destination pointer
                    leax      StrModeR,pcr load format string
                    pshs      x         push string argument
                    leax      >NameBuf,y  load result buffer
                    pshs      x         push buffer pointer
                    lbsr      OpenNamedAddFile format the command string
                    leas      6,s        drop the arguments
                    std       -$02,s    save format result
                    bne       CmdBuilt  branch if formatting ok
                    leax      >NameBuf,y  load result buffer
                    pshs      x         push message argument
                    leax      MsgCantReopen,pcr load error format string
                    pshs      x         push format string
                    lbsr      FatalError report fatal error
                    leas      4,s        drop the arguments
CmdBuilt            clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push null environment
                    ldd       #$0001    load memory size
                    pshs      d         push memory argument
                    ldd       #$0001    load one path flag
                    pshs      d         push path argument
                    leax      CmdBuf,y   load command buffer
                    pshs      x         push command pointer
                    leax      CmdBuf,y   load command buffer
                    pshs      x         push command pointer
                    lbsr      strlen    fork the phase command
                    std       ,s        save child process id
                    leax      StrShell,pcr load phase name string
                    pshs      x         push string argument
                    lbsr      SysChain  wait for the child phase
                    leas      12,s       drop the arguments
EchoRunDone         leas      15,s       tear down the stack frame
                    puls      pc,u      return to caller

                    pshs      u         save caller frame pointer
                    ldd       #$FFB4    load stack limit
                    lbsr      stkcheck  check for stack overflow
                    leas      -2,s       reserve local word
                    clra                zero high byte
                    clrb                zero low byte
                    pshs      d         push null terminator
                    ldd       #$0004    load name length four
                    pshs      d         push length argument
                    leax      EnvCcDevice,pcr load environment variable name
                    pshs      x         push name pointer
                    lbsr      LinkModule look up the environment variable
                    leas      6,s        drop the arguments
                    tfr       d,u       move result to pointer
                    cmpu      #$FFFF    was it not found
                    bne       EnvVarFound branch if found
                    lbsr      FindInitName get default temp directory
                    bra       TmpDirDone return the result

EnvVarFound         pshs      u         push the value pointer
                    ldd       $09,u     load its length field
                    addd      ,s++      add the accumulated length
                    std       ,s        store combined length
                    pshs      d         push length argument
                    leax      TmpPathBuf,y   load temp path buffer
                    pshs      x         push destination pointer
                    lbsr      strcpy    copy env value into buffer
                    leas      4,s        drop the two arguments
                    pshs      u         push value pointer
                    lbsr      UnLinkModule free the environment value
                    leas      2,s        drop the argument
                    leax      TmpPathBuf,y   load temp path buffer
                    tfr       x,d       return the buffer pointer
TmpDirDone          puls      pc,u,x    return to caller

                    puls      pc,u,x    dead trailing return

PrintOptArg         pshs      u         save caller frame pointer
                    ldd       #$FFBA    load stack limit
                    lbsr      stkcheck  check for stack overflow
                    ldd       $04,s     load option arg pointer
                    beq       PrintOptDone skip if null
                    ldd       $04,s     reload option arg pointer
                    pshs      d         push arg pointer
                    lbsr      PrintTrace echo the option arg
                    leas      2,s        drop the argument
                    leax      StrArgSep,pcr load separator string
                    pshs      x         push string argument
                    lbsr      PrintTrace echo the separator
                    leas      2,s        drop the argument
PrintOptDone        puls      pc,u      return to caller

FatalError          pshs      u         save caller frame pointer
                    ldd       #$FFB6    load stack limit
                    lbsr      stkcheck  check for stack overflow
                    ldd       $06,s     load message argument
                    pshs      d         push message argument
                    ldd       $06,s     load format string
                    pshs      d         push format string
                    leax      OutBuf,y   load stderr handle
                    pshs      x         push file handle
                    lbsr      fprintf   print the error message
                    leas      6,s        drop the arguments
                    leax      OutBuf,y   load stderr handle
                    pshs      x         push file handle
                    ldd       #$000D    load carriage return
                    pshs      d         push newline argument
                    lbsr      fputc     print the newline
                    leas      4,s        drop the arguments
                    ldd       #$0001    load exit code one
                    pshs      d         push exit code
                    lbsr      exit      terminate the program
                    puls      pc,u,x    dead trailing return

SetFileSuffix       pshs      u         save caller frame pointer
                    ldd       #$FFC0    load stack limit
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load file name pointer
SuffixScanLoop      ldb       ,u+       read next character
                    bne       SuffixScanLoop loop to end of string
                    ldb       -$03,u    load third-from-last char
                    cmpb      #'.       is it a dot
                    beq       SuffixDotFound branch if suffix present
                    puls      pc,u      return with no change

SuffixDotFound      ldb       $07,s     load new suffix char arg
                    bne       SetSuffixChar branch if replacing suffix
                    clra                zero high byte
                    clrb                zero low byte
                    stb       -$03,u    truncate name at the dot
                    bra       SetSuffixDone done

SetSuffixChar       ldb       $07,s     load new suffix char
                    stb       -$02,u    replace the suffix char
SetSuffixDone       puls      pc,u      return to caller

GetFileSuffix       pshs      u         save caller frame pointer
                    ldd       #$FFBD    load stack limit
                    lbsr      stkcheck  check for stack overflow
                    ldu       $04,s     load file name pointer
                    leas      -3,s       reserve char and counter locals
ResetNameLen        clra                zero high byte
                    clrb                zero low byte
                    bra       CountNameStore reset the length counter

CountNameLoop       ldb       ,s        load current character
                    cmpb      #'/       is it a slash
                    beq       ResetNameLen reset counter on slash
                    ldd       $01,s     load length counter
                    addd      #$0001    increment the counter
CountNameStore      std       $01,s     store the length counter
                    ldb       ,u+       read next character
                    stb       ,s        save current character
                    bne       CountNameLoop loop until end of string
                    ldd       $01,s     load final name length
                    cmpd      #$001D    compare against maximum
                    bgt       NoValidSuffix reject if too long
                    ldd       $01,s     reload name length
                    cmpd      #$0002    compare against minimum
                    ble       NoValidSuffix reject if too short
                    ldb       -$03,u    load third-from-last char
                    cmpb      #'.       is it a dot
                    bne       NoValidSuffix reject if no dot
                    ldb       -$02,u    load the suffix character
                    sex                 sign extend to word
                    orb       #$40      set found flag bit
                    bra       GetSuffixReturn return the suffix char

NoValidSuffix       clra                zero high byte
                    clrb                zero low byte
GetSuffixReturn     leas      3,s        drop the locals
                    puls      pc,u      return to caller

PrintTrace          pshs      u         save caller frame pointer
                    ldd       #$FFB8    load stack limit
                    lbsr      stkcheck  check for stack overflow
                    ldd       $04,s     load string argument
                    pshs      d         push string argument
                    ldd       GlbVar002B load trace file handle
                    pshs      d         push file handle
                    lbsr      fprintf   print string to trace file
                    leas      4,s        drop the arguments
                    puls      pc,u      return to caller

* ------------------------------------------------------------------
* String pool for the cc1 compiler driver: the sign-on banner, error
* messages, and the shell command-line fragments used to build the
* pass invocations (c.prep, c.pass1, ... c.link).  Referenced by the
* driver code via leax <label>,pcr; the banner (MsgBanner) is reached
* indirectly through the relocated work-block pointer at base+$5f.
* ------------------------------------------------------------------
MsgBanner           fcc       /CC1 VERSION %s/    sign-on banner, %s = version string
                    fcb       C$CR
                    fcc       /COPYRIGHT 1983 MICROWARE/
                    fcb       C$CR
                    fcc       /REPRODUCED UNDER LICENSE/
                    fcb       C$CR
                    fcc       /TO TANDY/
                    fcb       C$CR,C$NULL
MsgVersion          fcc       /RS 01.00.00/
                    fcb       C$NULL
StrModeW            fcc       /w/
                    fcb       C$NULL
MsgShellOpen        fcc       /can't open shell command file/
                    fcb       C$NULL
MsgBadSuffix        fcc       /Suffix '.%c' not allowed for output/
                    fcb       C$NULL
MsgTooManyLibs      fcc       /Too many libraries/
                    fcb       C$NULL
MsgUnknownFlag      fcc       /unknown flag : -%c/
                    fcb       C$CR,C$NULL
MsgNoSuffix         fcc       /%s : no recognized suffix/
                    fcb       C$NULL
MsgNoFiles          fcc       /no files!/
                    fcb       C$CR,C$NULL
MsgIncompatFlags    fcc       /incompatible flags/
                    fcb       C$NULL
MsgOutputNA         fcc       /%s : output name not applicable/
                    fcb       C$NULL
NameOutput          fcc       /output/
                    fcb       C$NULL
SufDotM             fcc       /.m/
                    fcb       C$NULL
SufDotR             fcc       /.r/
                    fcb       C$NULL
StrEchoQuote        fcc       /echo '/
                    fcb       C$NULL
StrQuote            fcc       /'/
                    fcb       C$CR,C$NULL
StrDashX            fcc       /-x/
                    fcb       C$CR
                    fcc       /echo c.prep:/
                    fcb       C$CR,C$NULL
PhasePrep           fcc       /C.PREP /
                    fcb       C$NULL
OptDashL            fcc       /-l /
                    fcb       C$NULL
StrSpace1           fcc       / /
                    fcb       C$NULL
StrSpace2           fcc       / /
                    fcb       C$NULL
StrRedirect         fcc       / >/
                    fcb       C$NULL
EchoPass1           fcb       C$CR
                    fcc       /x/
                    fcb       C$CR
                    fcc       /echo c.pass1:/
                    fcb       C$CR,C$NULL
PhasePass1          fcc       /C.PASS1 /
                    fcb       C$NULL
OptPass1E           fcc       /-e /
                    fcb       C$NULL
OptPass1S           fcc       / -s /
                    fcb       C$NULL
OptPass1P           fcc       / -p /
                    fcb       C$NULL
OptPass1Out         fcc       / -o=/
                    fcb       C$NULL
CmdDelPass1         fcb       C$CR
                    fcc       /del /
                    fcb       C$NULL
CrNulPass1          fcb       C$CR,C$NULL
EchoPass2           fcc       /echo c.pass2:/
                    fcb       C$CR,C$NULL
PhasePass2          fcc       /C.PASS2 /
                    fcb       C$NULL
OptPass2S           fcc       / -s /
                    fcb       C$NULL
OptPass2P           fcc       / -p /
                    fcb       C$NULL
StrSpace3           fcc       / /
                    fcb       C$NULL
OptPass2Out         fcc       / -o=/
                    fcb       C$NULL
CmdDelPass2         fcb       C$CR
                    fcc       /del /
                    fcb       C$NULL
StrDelSpc           fcc       / /
                    fcb       C$NULL
CrNulPass2          fcb       C$CR,C$NULL
                    ifne       CC2
EchoComp            fcb        C$CR
                    fcc        /x/
                    fcb        C$CR
                    fcc        /echo c.comp:/
                    fcb        C$CR,C$NULL
PhaseComp           fcc        /C.COMP /
                    fcb        C$NULL
                    endc
EchoOpt             fcc       /echo c.opt:/
                    fcb       C$CR,C$NULL
PhaseOpt            fcc       /C.OPT /
                    fcb       C$NULL
StrSpace4           fcc       / /
                    fcb       C$NULL
StrCrNul            fcb       C$CR,C$NULL
CmdDel              fcc       /del /
                    fcb       C$NULL
CrNulOpt            fcb       C$CR,C$NULL
EchoAsm             fcc       /echo c.asm:/
                    fcb       C$CR,C$NULL
PhaseAsm            fcc       /C.ASM /
                    fcb       C$NULL
OptAsmOut           fcc       / -o=/
                    fcb       C$NULL
CrNulAsmOut         fcb       C$CR,C$NULL
CmdDelAsm           fcc       /del /
                    fcb       C$NULL
CrNulAsmDel         fcb       C$CR,C$NULL
EchoLink            fcc       /echo c.link:/
                    fcb       C$CR,C$NULL
PhaseLink           fcc       /C.LINK /
                    fcb       C$NULL
StrDdDir            fcc       |/dd|
                    fcb       C$NULL
LibCstart           fcc       |/lib/cstart.r|
                    fcb       C$NULL
StrLinkSpace        fcc       / /
                    fcb       C$NULL
StrObjPrefix        fcc       / /
                    fcb       C$NULL
OptLinkO            fcc       / -o=/
                    fcb       C$NULL
StrLibPrefix        fcc       / /
                    fcb       C$NULL
OptLinkL            fcc       / -l=/
                    fcb       C$NULL
LibClib             fcc       |/lib/clib.l |
                    fcb       C$NULL
StrCrNul2           fcb       C$CR,C$NULL
CmdDel2             fcc       /del /
                    fcb       C$NULL
CrNulClib           fcb       C$CR,C$NULL
OptAsmTP            fcc       /-t -p/
                    fcb       C$CR,C$NULL
StrModeR            fcc       /r/
                    fcb       C$NULL
MsgCantReopen       fcc       /can't reopen '%s'/
                    fcb       C$NULL
StrShell            fcc       /shell/
                    fcb       C$NULL
EnvCcDevice         fcc       /ccdevice/
                    fcb       C$NULL
StrArgSep           fcc       / /
                    fcb       C$NULL

FindInitName        pshs      u         save u, enter FindInitName
                    leas      -7,s       reserve local scratch
                    clra                clear high byte of zero argument
                    clrb                clear low byte of zero argument
                    pshs      d         push zero argument
                    ldd       #$000C    length argument value
                    pshs      d         push length argument
                    leax      >StrInit,pcr point to "Init" module name
                    pshs      x         push name pointer argument
                    lbsr      LinkModule search for the Init module
                    leas      6,s        drop the call arguments
                    std       ,s        save returned record pointer
                    cmpd      #$FFFF    check for not-found result
                    beq       FindInitNull bail out if module not found
                    ldd       ,s        reload record pointer
                    ldx       ,s        record pointer into x
                    addd      $10,x     add name-field offset
                    std       $05,s     save source name pointer
                    leau      NameCopyBuf,y   point to name copy buffer
                    bra       FindInitCopyLoop enter the copy loop

FindInitStore       ldb       $04,s     fetch current name character
                    stb       ,u+       store character into buffer
FindInitCopyLoop    ldx       $05,s     reload source pointer
                    leax      $01,x     advance source pointer
                    stx       $05,s     save advanced source pointer
                    ldb       -$01,x    read the character
                    stb       $04,s     stash the character
                    bgt       FindInitStore loop while character positive
                    ldb       $04,s     get terminating character
                    clra                clear high byte
                    andb      #$7f      strip name high bit
                    stb       ,u+       store final character
                    clra                clear high byte
                    clrb                clear low byte
                    stb       ,u        null-terminate the name
                    ldd       ,s        reload record pointer
                    pshs      d         push record argument
                    lbsr      UnLinkModule release the found module
                    leas      2,s        drop the argument
                    leax      NameCopyBuf,y   point to copied name
                    tfr       x,d       return name pointer
                    bra       FindInitDone go to common exit

FindInitNull        clra                clear high byte
                    clrb                return null on failure
FindInitDone        leas      7,s        release local scratch
                    puls      pc,u      restore u and return

StrInit             fcc       /Init/    "Init" string constant
                    fcb       C$NULL

FindFreeFileEntry   pshs      u         save u, enter FindFreeFileEntry
                    leau      >FileTable,y  point to first file entry
FindFreeLoop        ldd       $06,u     load entry flag bits
                    clra                clear high byte
                    andb      #$03      isolate in-use bits
                    lbeq      AddFileRet free slot found, return it
                    leau      $0d,u     advance to next entry
                    pshs      u         save entry pointer
                    leax      $013e,y   point at end of table
                    cmpx      ,s++      compare against table limit
                    bhi       FindFreeLoop keep scanning if within table
                    ldd       #$00C8    no free entry error code
                    std       Errno,y   store the error code
                    lbra      RetNull   return null

                    puls      pc,u      restore u and return

AddFileEntry        pshs      u         save u, enter AddFileEntry
                    ldu       $08,s     load caller-supplied entry
                    bne       AddFileHaveSlot use it when non-null
                    bsr       FindFreeFileEntry otherwise allocate a free entry
                    tfr       d,u       entry pointer into u
AddFileHaveSlot     stu       -$02,s    save the entry pointer
                    beq       RetNull   bail if allocation failed
                    ldd       $04,s     get file type argument
                    std       $08,u     store type into entry
                    ldx       $06,s     get name pointer
                    ldb       $01,x     read second name character
                    cmpb      #'+       is it a '+'
                    beq       AddFileSetBoth handle the '+' flag
                    ldx       $06,s     reload name pointer
                    ldb       $02,x     read third name character
                    cmpb      #'+       is it a '+'
                    bne       AddFileParseMode no plus, parse mode character
AddFileSetBoth      ldd       $06,u     load entry flags
                    orb       #$03      set both in-use bits
                    bra       AddFileStore store the flags

AddFileParseMode    ldd       $06,u     load entry flags
                    pshs      d         save flags on stack
                    ldb       [$08,s]   read first name character indirectly
                    cmpb      #'r       is it 'r'
                    beq       AddFileFlag1 read/delete flag value
                    ldb       [$08,s]   read the character again
                    cmpb      #'d       is it 'd'
                    bne       AddFileFlag2 default flag value
AddFileFlag1        ldd       #$0001    set flag bit 0
                    bra       AddFileMergeFlags merge with saved flags

AddFileFlag2        ldd       #$0002    set flag bit 1
AddFileMergeFlags   ora       ,s+       merge saved flags high byte
                    orb       ,s+       merge saved flags low byte
AddFileStore        std       $06,u     store combined entry flags
                    ldd       $02,u     load entry base offset
                    addd      $0b,u     add the size field
                    std       $04,u     store as current pointer
                    std       ,u        and as start pointer
AddFileRet          tfr       u,d       return entry pointer
                    puls      pc,u      restore u and return

RetNull             clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u      return null

OpenFileByMode      pshs      u         save u, enter OpenFileByMode
                    ldu       $04,s     load entry pointer
                    leas      -4,s       reserve local scratch
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear the open flags
                    ldx       $0a,s     get mode string pointer
                    ldb       $01,x     read second mode character
                    sex                 sign-extend to d
                    tfr       d,x       prefix character into x
                    bra       OpenModeDispatch dispatch on prefix

OpenModeExecPlus    ldx       $0a,s     reload mode string
                    ldb       $02,x     read third mode character
                    cmpb      #'+       is it a '+'
                    bne       OpenModeExec no plus, plain exec flags
                    ldd       #$0007    update and create flags
                    bra       OpenModeSaveFlags save the open flags

OpenModeExec        ldd       #$0004    exec-only flags
                    bra       OpenModeSaveFlags save the open flags

OpenModePlus        ldd       #$0003    read/write flags
OpenModeSaveFlags   std       ,s        save the open flags
                    bra       OpenModeReadChar go parse the mode character

OpenModeBad         leax      $04,s     point to locals
                    lbra      OpenModeRestoreStk invalid mode

OpenModeDispatch    stx       -$02,s    save the prefix character
                    beq       OpenModeReadChar empty, parse mode character
                    cmpx      #$0078    is prefix 'x'
                    beq       OpenModeExecPlus handle exec prefix
                    cmpx      #$002B    is prefix '+'
                    beq       OpenModePlus handle update prefix
                    bra       OpenModeBad invalid mode prefix

OpenModeReadChar    ldb       [$0a,s]   read first mode character
                    sex                 sign-extend to d
                    tfr       d,x       mode character into x
                    lbra      OpenModeSelect dispatch on mode character

OpenModeRead        ldd       ,s        load open flags
                    orb       #$01      set read bit
                    bra       OpenModeDoOpen go open the file

OpenModeAppend      ldd       ,s        load open flags
                    orb       #$02      set write bit
                    pshs      d         push flags argument
                    pshs      u         push entry argument
                    lbsr      open      open existing file
                    leas      4,s        drop the arguments
                    std       $02,s     save the path number
                    cmpd      #$FFFF    did the open fail
                    beq       OpenModeCreate retry by creating
                    ldd       #$0002    seek/write count
                    pshs      d         push count argument
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    pshs      d         push zero argument
                    ldd       $08,s     get path number
                    pshs      d         push path argument
                    lbsr      lseek     position at end of file
                    leas      8,s        drop the arguments
                    bra       OpenModeRetPath return the path number

OpenModeCreate      ldd       ,s        load open flags
                    orb       #$02      set write bit
                    pshs      d         push flags argument
                    pshs      u         push entry argument
                    lbsr      creat     create the file
                    bra       OpenModeSavePath save the result

OpenModeDir         ldd       ,s        load open flags
                    orb       #$81      set directory/exec bits
OpenModeDoOpen      pshs      d         push flags argument
                    pshs      u         push entry argument
                    lbsr      open      open the file
OpenModeSavePath    leas      4,s        drop the arguments
                    std       $02,s     save the path number
                    bra       OpenModeRetPath return the path number

OpenModeRestoreStk  leas      -$04,x    restore the stack pointer
OpenModeErr         ldd       #$00CB    invalid-mode error code
                    std       Errno,y   store the error code
                    clra                clear high byte
                    clrb                clear low byte
                    bra       OpenModeExit return null

OpenModeSelect      cmpx      #$0072    is mode 'r'
                    lbeq      OpenModeRead open for read
                    cmpx      #$0061    is mode 'a'
                    lbeq      OpenModeAppend open for append
                    cmpx      #$0077    is mode 'w'
                    beq       OpenModeCreate open for write
                    cmpx      #$0064    is mode 'd'
                    beq       OpenModeDir open a directory
                    bra       OpenModeErr invalid mode

OpenModeRetPath     ldd       $02,s     load path number for return
OpenModeExit        leas      4,s        release local scratch
                    puls      pc,u      restore u and return

                    pshs      u         save u, open-and-add helper
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push null entry argument
                    ldd       $08,s     get mode argument
                    pshs      d         push mode argument
                    ldd       $08,s     get name argument
                    pshs      d         push name argument
                    lbra      OpenAddDoAdd go add the file entry

OpenAndAddFile      pshs      u         save u, enter OpenAndAddFile
                    ldd       $06,s     get mode argument
                    pshs      d         push mode argument
                    ldd       $06,s     get name argument
                    pshs      d         push name argument
                    lbsr      OpenFileByMode open the file by mode
                    leas      4,s        drop the arguments
                    tfr       d,u       open result into u
                    cmpu      #$FFFF    did the open fail
                    bne       OpenAddNoResult proceed if open succeeded
                    clra                clear high byte
                    clrb                clear low byte
                    bra       OpenAddDone return null

OpenAddNoResult     clra                clear high byte
                    clrb                clear low byte
                    bra       OpenAddPushArgs add entry with null path

OpenNamedAddFile    pshs      u         save u, enter OpenNamedAddFile
                    ldd       $08,s     get name argument
                    pshs      d         push name argument
                    lbsr      fclose    prepare/resolve the name
                    leas      2,s        drop the argument
                    ldd       $06,s     get mode argument
                    pshs      d         push mode argument
                    ldd       $06,s     get name argument
                    pshs      d         push name argument
                    lbsr      OpenFileByMode open the file by mode
                    leas      4,s        drop the arguments
                    tfr       d,u       open result into u
                    stu       -$02,s    save the open result
                    bge       OpenAddHaveName proceed if opened
                    clra                clear high byte
                    clrb                clear low byte
                    bra       OpenAddDone return null

OpenAddHaveName     ldd       $08,s     get name argument
OpenAddPushArgs     pshs      d         push name argument
                    ldd       $08,s     get mode argument
                    pshs      d         push mode argument
                    pshs      u         push open result argument
OpenAddDoAdd        lbsr      AddFileEntry add the file entry
                    leas      6,s        drop the arguments
OpenAddDone         puls      pc,u      restore u and return

SubstTempId         pshs      u,d       save regs, enter SubstTempId
                    ldu       $06,s     get string pointer
                    bra       SubstScanLoop enter the scan loop

SubstScanNext       leau      $01,u     advance to next character
SubstScanLoop       ldb       ,u        read the character
                    sex                 sign-extend to d
                    std       ,s        save the character
                    beq       SubstCheck stop at end of string
                    ldd       ,s        reload the character
                    cmpd      #$0058    is it 'X'
                    bne       SubstScanNext keep scanning otherwise
SubstCheck          ldd       ,s        reload the character
                    beq       SubstDone no 'X' found, done
                    lbsr      SysGetProcId get a unique id number
                    pshs      d         push the number argument
                    leax      >FmtDecimal,pcr point to "%d" format
                    pshs      x         push format argument
                    pshs      u         push the 'X' position
                    lbsr      sprintf   format the id into the string
                    leas      6,s        drop the arguments
SubstDone           ldd       $06,s     return the string pointer
                    puls      pc,u,x    restore regs and return

FmtDecimal          fcc       /%d/                integer format string
                    fcb       C$NULL

printf              pshs      u         save u, enter printf
                    leax      >StdoutPtr,y  point to standard output
                    stx       OutStream,y   set current output stream
                    leax      $06,s     point to format arguments
                    pshs      x         push argument pointer
                    ldd       $06,s     get format string
                    bra       PrintfCommon do the formatted print

fprintf             pshs      u         save u, enter fprintf
                    ldd       $04,s     get output stream argument
                    std       OutStream,y   set current output stream
                    leax      $08,s     point to format arguments
                    pshs      x         push argument pointer
                    ldd       $08,s     get format string
PrintfCommon        pshs      d         push format string
                    leax      PutcToStream,pcr point to character-output routine
                    pshs      x         push output routine
                    bsr       doprnt    run the formatter
                    leas      6,s        drop the pushed arguments
                    puls      pc,u      restore frame pointer and return

sprintf             pshs      u         save the frame pointer
                    ldd       $04,s     load the output buffer pointer argument
                    std       OutStream,y   set the string output destination global
                    leax      $08,s     point to the variadic argument list
                    pshs      x         push args pointer for doprnt
                    ldd       $08,s     load the format string pointer
                    pshs      d         push the format string
                    leax      PutcToBuffer,pcr address of the string-output helper
                    pshs      x         push the output function pointer
                    bsr       doprnt    run the core formatter
                    leas      6,s        drop the pushed arguments
                    clra                zero for the terminator
                    clrb                zero for the terminator
                    stb       [>OutStream,y] write null terminator to the string
                    ldd       $04,s     return the buffer pointer
                    puls      pc,u      restore and return

doprnt              pshs      u         save the frame pointer
                    ldu       $06,s     load format string pointer into u
                    leas      -11,s      reserve the local frame
                    bra       FormatLoop enter the format scan loop

PutLiteral          ldb       $08,s     reload current format char
                    lbeq      DoprntDone end of format string, finish
                    ldb       $08,s     load the literal char
                    sex                 sign-extend char to d
                    pshs      d         push the char argument
                    jsr       [$11,s]   call the output function
                    leas      2,s        drop the char argument
FormatLoop          ldb       ,u+       fetch next format char
                    stb       $08,s     save the current char
                    cmpb      #'%       is it a percent sign
                    bne       PutLiteral no, output it literally
                    ldb       ,u+       fetch the char after percent
                    stb       $08,s     save the conversion char
                    clra                zero the precision
                    clrb                zero the precision
                    std       $02,s     clear the precision field
                    std       $06,s     clear the width field
                    ldb       $08,s     reload the conversion char
                    cmpb      #'-       is it the dash flag
                    bne       NoLeftJustify no, default justification
                    ldd       #$0001    left-justify flag value
                    std       LeftJustFlag,y   set the left-justify flag
                    ldb       ,u+       consume dash, fetch next char
                    stb       $08,s     save the char
                    bra       CheckZeroPad go check the pad char

NoLeftJustify       clra                clear the left-justify flag
                    clrb                clear the left-justify flag
                    std       LeftJustFlag,y   store cleared left-justify flag
CheckZeroPad        ldb       $08,s     load the current char
                    cmpb      #'0       is it the zero pad flag
                    bne       PadSpace  no, use space padding
                    ldd       #$0030    pad character is zero
                    bra       SetPadChar store the pad character

PadSpace            ldd       #$0020
SetPadChar          std       PadChar,y   store the pad character global
                    bra       WidthTestDigit begin width parsing

WidthDigitLoop      ldd       $06,s     current accumulated width
                    pshs      d         save width on stack
                    ldd       #$000A    multiplier of ten
                    lbsr      MulEntry  multiply width by ten
                    pshs      d         save product
                    ldb       $0a,s     load the digit char
                    sex                 sign-extend the digit
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add the width times ten
                    std       $06,s     store the accumulated width
                    ldb       ,u+       fetch the next char
                    stb       $08,s     save the char
WidthTestDigit      ldb       $08,s     load the current char
                    sex                 extend char to index
                    leax      CtypeTab,y   base of the ctype table
                    leax      d,x       index by the char
                    ldb       ,x        load the char class flags
                    clra                clear high byte
                    andb      #$08      test the digit class bit
                    bne       WidthDigitLoop is a digit, accumulate width
                    ldb       $08,s     load the current char
                    cmpb      #'.       is it the dot precision
                    bne       NoPrecision no precision given
                    ldd       #$0001    precision-present flag
                    std       $04,s     mark precision present
                    bra       PrecTestDigit parse the precision digits

PrecDigitLoop       ldd       $02,s     current accumulated precision
                    pshs      d         save precision on stack
                    ldd       #$000A    multiplier of ten
                    lbsr      MulEntry  multiply precision by ten
                    pshs      d         save product
                    ldb       $0a,s     load the digit char
                    sex                 sign-extend the digit
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add the precision times ten
                    std       $02,s     store the accumulated precision
PrecTestDigit       ldb       ,u+       fetch the next char
                    stb       $08,s     save the char
                    ldb       $08,s     reload the char
                    sex                 extend char to index
                    leax      CtypeTab,y   base of the ctype table
                    leax      d,x       index by the char
                    ldb       ,x        load the char class flags
                    clra                clear high byte
                    andb      #$08      test the digit class bit
                    bne       PrecDigitLoop is a digit, accumulate precision
                    bra       DispatchConv done, dispatch the conversion

NoPrecision         clra                clear precision-present flag
                    clrb                clear precision-present flag
                    std       $04,s     clear the precision-present flag
DispatchConv        ldb       $08,s     load the conversion char
                    sex                 extend to full word
                    tfr       d,x       move into x for dispatch
                    lbra      DispatchTable jump to the conversion dispatch

ConvSignedDec       ldd       $06,s     push the field width
                    pshs      d         push the field width
                    ldx       $15,s     load the variadic arg pointer
                    leax      $02,x     advance past the int argument
                    stx       $15,s     save the arg pointer
                    ldd       -$02,x    fetch the int argument
                    pshs      d         push the value
                    lbsr      IntToDecStr convert to signed decimal string
                    bra       StoreStrResult go store the result

ConvOctal           ldd       $06,s     push the field width
                    pshs      d         push the field width
                    ldx       $15,s     load the variadic arg pointer
                    leax      $02,x     advance past the argument
                    stx       $15,s     save the arg pointer
                    ldd       -$02,x    fetch the argument
                    pshs      d         push the value
                    lbsr      UintToOctStr convert to octal string
StoreStrResult      std       ,s        store the result pointer
                    lbra      EmitField emit the formatted field

ConvHex             ldd       $06,s     push the field width
                    pshs      d         push the field width
                    ldb       $0a,s     load the conversion char
                    sex                 sign-extend the char
                    leax      CtypeTab,y   base of the ctype table
                    leax      d,x       index by the char
                    ldb       ,x        load the char class flags
                    clra                clear high byte
                    andb      #$02      test uppercase class bit for X
                    pshs      d         push the uppercase flag
                    ldx       $17,s     load the variadic arg pointer
                    leax      $02,x     advance past the argument
                    stx       $17,s     save the arg pointer
                    ldd       -$02,x    fetch the argument
                    pshs      d         push the value
                    lbsr      UintToHexStr convert to hex string
                    lbra      DropTwoArgs emit the formatted field

ConvUnsigned        ldd       $06,s     push the field width
                    pshs      d         push the field width
                    ldx       $15,s     load the variadic arg pointer
                    leax      $02,x     advance past the argument
                    stx       $15,s     save the arg pointer
                    ldd       -$02,x    fetch the argument
                    pshs      d         push the value
                    leax      ConvBuf,y   conversion buffer address
                    pshs      x         push the buffer pointer
                    lbsr      UintToDecStr convert to unsigned decimal string
                    lbra      DropTwoArgs emit the formatted field

ConvFloat           ldd       $04,s     was precision specified
                    bne       FloatConvert yes, keep it
                    ldd       #$0006    default precision of six
                    std       $02,s     set the precision
FloatConvert        ldd       $06,s     push the field width
                    pshs      d         push the field width
                    leax      $15,s     address of the arg pointer
                    pshs      x         push it
                    ldd       $06,s     push the precision value
                    pshs      d         push the precision value
                    ldb       $0e,s     load the conversion char
                    sex                 sign-extend the char
                    pshs      d         push the char
                    lbsr      GetEmptyStr convert the floating-point value
                    leas      6,s        drop the pushed arguments
                    lbra      PushFieldPtr push result and emit field

ConvChar            ldx       $13,s     load the variadic arg pointer
                    leax      $02,x     advance past the char argument
                    stx       $13,s     save the arg pointer
                    ldd       -$02,x    fetch the char argument
                    lbra      OutputChar output the single char

ConvString          ldx       $13,s     load the variadic arg pointer
                    leax      $02,x     advance past the string argument
                    stx       $13,s     save the arg pointer
                    ldd       -$02,x    fetch the string pointer
                    std       $09,s     save the string pointer
                    ldd       $04,s     was precision specified
                    beq       NullString no, print the whole string
                    ldd       $09,s     load the string pointer
                    std       $04,s     set the scan pointer
                    bra       StrCountNext count the precision-limited length

StrCountLoop        ldb       [$09,s]   load the current string char
                    beq       EmitString null, stop counting
                    ldd       $09,s     advance the string pointer
                    addd      #$0001    advance the string pointer
                    std       $09,s     save the pointer
StrCountNext        ldd       $02,s     load the remaining precision
                    addd      #$FFFF    decrement the counter
                    std       $02,s     save the counter
                    subd      #$FFFF    restore original for test
                    bne       StrCountLoop still counting, loop
EmitString          ldd       $06,s     push the field width
                    pshs      d         push the field width
                    ldd       $0b,s     load the string end pointer
                    subd      $06,s     subtract start to get length
                    pshs      d         push the string length
                    ldd       $08,s     push the precision
                    pshs      d         push the precision
                    ldd       $15,s     load the string pointer
                    pshs      d         push the string pointer
                    lbsr      PrintPadField output the padded string
                    leas      8,s        drop the pushed arguments
                    bra       NextFormat back to the format loop

NullString          ldd       $06,s     push the field width
                    pshs      d         push the field width
                    ldd       $0b,s     load the string pointer
                    bra       PushFieldPtr push result and emit field

ConvLong            ldb       ,u+       consume the l modifier char
                    stb       $08,s     save the next char
                    bra       LongConvert proceed to long conversion

                    leas      -$0b,x    unreachable padding after branch
LongConvert         ldd       $06,s     push the field width
                    pshs      d         push the field width
                    leax      $15,s     address of the arg pointer
                    pshs      x         push it
                    ldb       $0C,s     load the conversion char
                    sex                 sign-extend the char
                    pshs      d         push the char
                    lbsr      ConvSpec  convert the long integer
DropTwoArgs         leas      4,s        drop two pushed arguments
PushFieldPtr        pshs      d         push the converted string pointer
EmitField           ldd       $13,s     load the output function pointer
                    pshs      d         push it
                    lbsr      PrintStrField emit the padded formatted field
                    leas      6,s        drop the pushed arguments
NextFormat          lbra      FormatLoop continue the format loop

PutConvChar         ldb       $08,s     load the unknown conversion char
                    sex                 sign-extend the char
OutputChar          pshs      d         push the char
                    jsr       [$11,s]   call the output function
                    leas      2,s        drop the char
                    lbra      FormatLoop continue the format loop

DispatchTable       cmpx      #$0064    is it d
                    lbeq      ConvSignedDec signed decimal conversion
                    cmpx      #$006F    is it o
                    lbeq      ConvOctal octal conversion
                    cmpx      #$0078    is it x
                    lbeq      ConvHex   hexadecimal conversion
                    cmpx      #$0058    is it X
                    lbeq      ConvHex   uppercase hex conversion
                    cmpx      #$0075    is it u
                    lbeq      ConvUnsigned unsigned decimal conversion
                    cmpx      #$0066    is it f
                    lbeq      ConvFloat floating-point conversion
                    cmpx      #$0065    is it e
                    lbeq      ConvFloat floating-point conversion
                    cmpx      #$0067    is it g
                    lbeq      ConvFloat floating-point conversion
                    cmpx      #$0045    is it E
                    lbeq      ConvFloat floating-point conversion
                    cmpx      #$0047    is it G
                    lbeq      ConvFloat floating-point conversion
                    cmpx      #$0063    is it c
                    lbeq      ConvChar  character conversion
                    cmpx      #$0073    is it s
                    lbeq      ConvString string conversion
                    cmpx      #$006C    is it l
                    lbeq      ConvLong  long modifier
                    bra       PutConvChar unknown, output literally

DoprntDone          leas      11,s       release the local frame
                    puls      pc,u      return from doprnt

IntToDecStr         pshs      u,d       save regs and the value
                    leax      ConvBuf,y   conversion buffer address
                    stx       ,s        initialise the buffer pointer
                    ldd       $06,s     load the value
                    bge       ConvertMagnitude non-negative, no sign needed
                    ldd       $06,s     load the value
                    nega                negate the value
                    negb                negate the value
                    sbca      #$00      negate the value
                    std       $06,s     store the magnitude
                    bge       StoreMinusSign not INT_MIN, add the sign
                    leax      MsgIntMin,pcr address of the INT_MIN literal
                    pshs      x         push the source
                    leax      ConvBuf,y   destination buffer
                    pshs      x         push the destination
                    lbsr      strcpy    copy the literal string
                    leas      4,s        drop the arguments
                    puls      pc,u,x    return the buffer pointer

StoreMinusSign      ldd       #$002D    the minus sign character
                    ldx       ,s        load the buffer pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save the pointer
                    stb       -$01,x    write the minus sign
ConvertMagnitude    ldd       $06,s     load the magnitude
                    pshs      d         push the magnitude
                    ldd       $02,s     load the buffer pointer
                    pshs      d         push the buffer pointer
                    bsr       UintToDecStr convert the unsigned digits
                    leas      4,s        drop the arguments
                    leax      ConvBuf,y   buffer start address
                    tfr       x,d       return the pointer
                    puls      pc,u,x    restore and return

UintToDecStr        pshs      u,y,x,d   save regs, output pointer and value
                    ldu       $0a,s     load the output buffer pointer
                    clra                clear the leading-zero flag
                    clrb                clear the leading-zero flag
                    std       $02,s     clear the leading-zero flag
                    clra                clear the digit accumulator
                    clrb                clear the digit accumulator
                    std       ,s        clear the digit accumulator
                    bra       DecPreAdjustCheck check whether adjustment needed

DecPreAdjustLoop    ldd       ,s        increment the digit count
                    addd      #$0001    increment the digit count
                    std       ,s        store the count
                    ldd       $0C,s     load the value
                    subd      >Pow10,y  subtract a power of ten
                    std       $0C,s     store the remainder
DecPreAdjustCheck   ldd       $0C,s     load the value
                    blt       DecPreAdjustLoop still negative, keep adjusting
                    leax      >Pow10,y  powers-of-ten table base
                    stx       $04,s     initialise the table pointer
                    bra       DecNextPower begin digit extraction

DecDigitInc         ldd       ,s        load the digit value
                    addd      #$0001    increment the digit value
                    std       ,s        store the digit value
DecSubtractLoop     ldd       $0C,s     load the remaining value
                    subd      [$04,s]   subtract the current power
                    std       $0C,s     store the value
                    bge       DecDigitInc still fits, increment digit
                    ldd       $0C,s     went negative, load value
                    addd      [$04,s]   add the power back
                    std       $0C,s     restore the remainder
                    ldd       ,s        load the digit value
                    beq       DecCheckLeading zero digit, maybe suppress
                    ldd       #$0001    nonzero digit seen
                    std       $02,s     set the leading flag
DecCheckLeading     ldd       $02,s     load the leading flag
                    beq       DecStoreDigit still leading zero, skip output
                    ldd       ,s        load the digit value
                    addd      #$0030    convert to ascii
                    stb       ,u+       store the digit char
DecStoreDigit       clra                reset the digit
                    clrb                reset the digit
                    std       ,s        reset the digit accumulator
                    ldd       $04,s     load the table pointer
                    addd      #$0002    advance to the next power
                    std       $04,s     save the table pointer
DecNextPower        ldd       $04,s     load the table pointer
                    cmpd      >Pow10End,y  reached the table end
                    bne       DecSubtractLoop no, process the next digit
                    ldd       $0C,s     load the final remainder
                    addd      #$0030    convert to ascii
                    stb       ,u+       store the last digit
                    clra                zero for terminator
                    clrb                zero for terminator
                    stb       ,u        null terminate the string
                    ldd       $0a,s     return the buffer pointer
                    leas      6,s        drop the locals
                    puls      pc,u      restore and return

UintToOctStr        pshs      u,d       save regs and the value
                    leax      ConvBuf,y   conversion buffer address
                    stx       ,s        initialise the buffer pointer
                    leau      DigitBuf,y   point to the scratch digit buffer
OctDigitLoop        ldd       $06,s     load the value
                    clra                clear high byte
                    andb      #$07      low octal digit
                    addd      #$0030    convert to ascii
                    stb       ,u+       store the digit in scratch
                    ldd       $06,s     load the value
                    lsra                shift right by three bits
                    rorb                shift right by three bits
                    lsra                shift right by three bits
                    rorb                shift right by three bits
                    lsra                shift right by three bits
                    rorb                shift right by three bits
                    std       $06,s     store the shifted value
                    bne       OctDigitLoop more digits remain
                    bra       OctReverseCheck begin reversing digits

OctReverseLoop      ldb       ,u        load a digit from scratch
                    ldx       ,s        load the destination pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save the pointer
                    stb       -$01,x    copy the digit reversed
OctReverseCheck     leau      -$01,u    back up the scratch pointer
                    pshs      u         push the scratch pointer
                    leax      DigitBuf,y   scratch buffer start
                    cmpx      ,s++      reached the start
                    bls       OctReverseLoop copy the next digit
                    clra                zero for terminator
                    clrb                zero for terminator
                    stb       [,s]      null terminate the result
                    leax      ConvBuf,y   buffer start address
                    tfr       x,d       return the pointer
                    puls      pc,u,x    restore and return

UintToHexStr        pshs      u,x,d     save regs and the value
                    leax      ConvBuf,y   conversion buffer address
                    stx       $02,s     initialise the buffer pointer
                    leau      DigitBuf,y   point to the scratch digit buffer
HexDigitLoop        ldd       $08,s     load the value
                    clra                clear high byte
                    andb      #$0f      low hex nibble
                    std       ,s        save the nibble
                    pshs      d         push the nibble
                    ldd       $02,s     load the nibble value
                    cmpd      #$0009    digit or letter
                    ble       HexDecimalBase is zero to nine, numeric
                    ldd       $0C,s     load the uppercase flag
                    beq       HexLowerBase lowercase letters
                    ldd       #$0041    uppercase A base
                    bra       HexAlphaAdjust apply the letter offset

HexLowerBase        ldd       #$0061    lowercase a base
HexAlphaAdjust      addd      #$FFF6    adjust for a-f range
                    bra       HexStoreDigit store the hex digit

HexDecimalBase      ldd       #$0030    ascii zero base
HexStoreDigit       addd      ,s++      add the nibble value
                    stb       ,u+       store the hex digit char
                    ldd       $08,s     load the value
                    lsra                shift right by four bits
                    rorb                shift right by four bits
                    lsra                shift right by four bits
                    rorb                shift right by four bits
                    lsra                shift right by four bits
                    rorb                shift right by four bits
                    lsra                shift right by four bits
                    rorb                shift right by four bits
                    anda      #$0f      mask the shifted value
                    std       $08,s     store shifted value back into local
                    bne       HexDigitLoop loop while digits remain
                    bra       RevDigitTest enter the reversal test

RevDigitLoop        ldb       ,u        read a digit from the high end
                    ldx       $02,s     load the destination pointer
                    leax      $01,x     advance the destination pointer
                    stx       $02,s     save the destination pointer
                    stb       -$01,x    write the digit in reversed order
RevDigitTest        leau      -$01,u    step the source pointer down
                    pshs      u         save the source pointer
                    leax      DigitBuf,y   buffer start address
                    cmpx      ,s++      compare source against buffer start
                    bls       RevDigitLoop loop until fully reversed
                    clra                clear high byte
                    clrb                clear low byte for terminator
                    stb       [$02,s]   null-terminate the string
                    leax      ConvBuf,y   result string address
                    tfr       x,d       return pointer in d
                    lbra      PutcCallbackDone tear down frame and return

PrintPadField       pshs      u         save frame pointer
                    ldu       $06,s     load the string pointer argument
                    ldd       $0a,s     load the field width
                    subd      $08,s     subtract the string length
                    std       $0a,s     save the pad count
                    ldd       LeftJustFlag,y   load the left-justify flag
                    bne       FieldCharTest skip leading pad if left justified
                    bra       PadLeadTest enter the leading pad loop

PadLeadLoop         ldd       PadChar,y   load the pad character
                    pshs      d         push pad char argument
                    jsr       [$06,s]   call the output function
                    leas      2,s        drop the argument
PadLeadTest         ldd       $0a,s     load remaining pad count
                    addd      #$FFFF    decrement the counter
                    std       $0a,s     save the pad count
                    subd      #$FFFF    restore value for the test
                    bgt       PadLeadLoop loop while pad remains
                    bra       FieldCharTest go output the field characters

FieldCharLoop       ldb       ,u+       load next field character
                    sex                 sign-extend to d
                    pshs      d         push char argument
                    jsr       [$06,s]   call the output function
                    leas      2,s        drop the argument
FieldCharTest       ldd       $08,s     load remaining length
                    addd      #$FFFF    decrement the length
                    std       $08,s     save the length
                    subd      #$FFFF    restore value for the test
                    bne       FieldCharLoop loop over field characters
                    ldd       LeftJustFlag,y   load the left-justify flag
                    beq       PrintPadDone done if right justified
                    bra       PadTrailTest enter the trailing pad loop

PadTrailLoop        ldd       PadChar,y   load the pad character
                    pshs      d         push pad char
                    jsr       [$06,s]   call the output function
                    leas      2,s        drop the argument
PadTrailTest        ldd       $0a,s     load remaining pad count
                    addd      #$FFFF    decrement the counter
                    std       $0a,s     save the pad count
                    subd      #$FFFF    restore value for the test
                    bgt       PadTrailLoop loop trailing pad
PrintPadDone        puls      pc,u      return from field output

PrintStrField       pshs      u         save frame pointer
                    ldu       $06,s     load the string pointer
                    ldd       $08,s     load the field width
                    pshs      d         push the width
                    pshs      u         push the string pointer
                    lbsr      strlen    measure the string length
                    leas      2,s        drop the pointer argument
                    nega                negate length high byte
                    negb                negate length low byte
                    sbca      #$00      complete the negation
                    addd      ,s++      width minus length gives pad count
                    std       $08,s     save the pad count
                    ldd       LeftJustFlag,y   load the left-justify flag
                    bne       StrCharTest skip leading pad if left justified
                    bra       StrPadLeadTest enter the leading pad loop

StrPadLeadLoop      ldd       PadChar,y   load the pad character
                    pshs      d         push pad char
                    jsr       [$06,s]   call the output function
                    leas      2,s        drop the argument
StrPadLeadTest      ldd       $08,s     load remaining pad count
                    addd      #$FFFF    decrement the counter
                    std       $08,s     save the pad count
                    subd      #$FFFF    restore value for the test
                    bgt       StrPadLeadLoop loop leading pad
                    bra       StrCharTest go output the string characters

StrCharLoop         ldb       ,u+       load next string character
                    sex                 sign-extend to d
                    pshs      d         push char argument
                    jsr       [$06,s]   call the output function
                    leas      2,s        drop the argument
StrCharTest         ldb       ,u        peek the next character
                    bne       StrCharLoop loop until the null terminator
                    ldd       LeftJustFlag,y   load the left-justify flag
                    beq       PrintStrDone done if right justified
                    bra       StrPadTrailTest enter the trailing pad loop

StrPadTrailLoop     ldd       PadChar,y   load the pad character
                    pshs      d         push pad char
                    jsr       [$06,s]   call the output function
                    leas      2,s        drop the argument
StrPadTrailTest     ldd       $08,s     load remaining pad count
                    addd      #$FFFF    decrement the counter
                    std       $08,s     save the pad count
                    subd      #$FFFF    restore value for the test
                    bgt       StrPadTrailLoop loop trailing pad
PrintStrDone        puls      pc,u      return from string output

PutcToStream        pshs      u         save frame pointer
                    ldd       OutStream,y   load the current stream pointer
                    pshs      d         push stream argument
                    ldd       $06,s     load the char argument
                    pshs      d         push the char
                    lbsr      fputc     write the char to the stream
PutcCallbackDone    leas      4,s        drop the arguments
                    puls      pc,u      return

PutcToBuffer        pshs      u         save frame pointer
                    ldd       $04,s     load the char argument
                    ldx       OutStream,y   load the buffer write pointer
                    leax      $01,x     advance the write pointer
                    stx       OutStream,y   save the write pointer
                    stb       -$01,x    store the char into the buffer
                    puls      pc,u      return

MsgIntMin           fcc       /-32768/            INT_MIN literal, special-cased by itoa
                    fcb       C$NULL
fputc               pshs      u         stream putc: write char to FILE at work+$5c5
                    ldu       $06,s     load the FILE pointer
                    ldd       $06,u     load the stream flags
                    anda      #$80      mask the buffer-known bit
                    andb      #$22      mask the mode bits
                    cmpd      #$8002    buffered and open for writing
                    beq       PutcCheckBuf take fast path if ready
                    ldd       $06,u     reload the flags
                    clra                clear high byte
                    andb      #$22      mask the mode bits
                    cmpd      #$0002    open for writing
                    lbne      ReturnEofError error if not writable
                    pshs      u         push the FILE pointer
                    lbsr      SetupBuffer set up buffering
                    leas      2,s        drop the argument
PutcCheckBuf        ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$04      mask the unbuffered bit
                    beq       PutcBuffered take buffered path if not unbuffered
                    ldd       #$0001    write length of one
                    pshs      d         push the write count
                    leax      $07,s     point at the char to write
                    pshs      x         push the char address
                    ldd       $08,u     load the path number
                    pshs      d         push the path number
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      mask the line-buffered bit
                    beq       UseRawWrite choose the write routine
                    leax      writeln,pcr select text write routine
                    bra       DoRawWrite go invoke it

UseRawWrite         leax      write,pcr select raw write routine
DoRawWrite          tfr       x,d       copy pointer via d
                    tfr       d,x       move function pointer to x
                    jsr       ,x        call the write routine
                    leas      6,s        drop the arguments
                    cmpd      #$FFFF    check for a write error
                    bne       PutcReturn return the char on success
                    ldd       $06,u     load the flags
                    orb       #$20      set the stream error flag
                    std       $06,u     save the flags
                    lbra      ReturnEofError return eof on error

PutcBuffered        ldd       $06,u     load the flags
                    anda      #$01      mask the buffer-allocated bit
                    clrb                clear low byte
                    std       -$02,s    save the test value
                    bne       StoreInBuffer buffer already allocated
                    pshs      u         push the FILE pointer
                    lbsr      FlushBuffer flush to allocate the buffer
                    leas      2,s        drop the argument
StoreInBuffer       ldd       ,u        load the buffer position
                    addd      #$0001    advance the position
                    std       ,u        save the position
                    subd      #$0001    restore the prior pointer
                    tfr       d,x       move it into x
                    ldd       $04,s     load the char argument
                    stb       ,x        store the char in the buffer
                    ldd       ,u        load the buffer position
                    cmpd      $04,u     compare against buffer end
                    bcc       FlushFullBuffer flush if the buffer is full
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      mask the line-buffered bit
                    beq       PutcReturn return if not line buffered
                    ldd       $04,s     load the char
                    cmpd      #$000D    was it a newline
                    bne       PutcReturn return if not a newline
FlushFullBuffer     pshs      u         push the FILE pointer
                    lbsr      FlushBuffer flush the buffer to the path
                    std       ,s++      save the flush result
                    lbne      ReturnEofError return eof on flush error
PutcReturn          ldd       $04,s     load the written char
                    puls      pc,u      return the char

                    pshs      u         save frame pointer
                    ldu       $04,s     load the FILE pointer
                    ldd       $06,s     load the value to write
                    pshs      d         push it
                    pshs      u         push the FILE pointer
                    ldd       #$0008    divisor of eight
                    lbsr      LsrEntry  divide the value
                    pshs      d         push the quotient
                    lbsr      fputc     write the high character
                    leas      4,s        drop the arguments
                    ldd       $06,s     load the value again
                    pshs      d         push it
                    pshs      u         push the FILE pointer
                    lbsr      fputc     write the low character
                    lbra      FlushRet  tear down and return

CloseAllStreams     pshs      u,d       save frame and counter
                    leau      >FileTable,y  point at the first FILE table entry
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        initialise the index
                    bra       CloseAllTest enter the loop test

CloseNextStream     tfr       u,d       copy the stream pointer
                    leau      $0d,u     advance to the next FILE entry
                    pshs      d         push the stream pointer
                    bsr       fclose    close this stream
                    leas      2,s        drop the argument
CloseAllTest        ldd       ,s        load the index
                    addd      #$0001    increment the index
                    std       ,s        save the index
                    subd      #$0001    restore value for the test
                    cmpd      #$0010    done all sixteen streams
                    blt       CloseNextStream loop over the FILE table
                    puls      pc,u,x    return

                    use       lib/fclose.asm

FlushStream         pshs      u         save frame pointer
                    ldu       $04,s     load the FILE pointer
                    beq       ReturnEofError error if the pointer is null
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$22      mask the mode bits
                    cmpd      #$0002    open for writing
                    beq       DoFlushBuffer flush if writable
ReturnEofError      ldd       #$FFFF    return eof error
                    puls      pc,u      return

DoFlushBuffer       ldd       $06,u     load the flags
                    anda      #$80      mask the buffer-known bit
                    clrb                clear low byte
                    std       -$02,s    save the test value
                    bne       CallFlushBuffer buffer already set up
                    pshs      u         push the FILE pointer
                    lbsr      SetupBuffer set up buffering
                    leas      2,s        drop the argument
CallFlushBuffer     pshs      u         push the FILE pointer
                    bsr       FlushBuffer flush the buffer
                    puls      pc,u,x    return

                    use       lib/flushbuffer.asm
FileTell            equ       GetBufInfo file position helper in this module

GetBufInfo          pshs      u         save frame pointer
                    puls      pc,u      return the caller pointer

SetupBuffer         pshs      u         save frame pointer
                    ldu       $04,s     load the FILE pointer
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$C0      mask the buffering-set bits
                    bne       MarkBufChecked buffering already determined
                    leas      -32,s      reserve a stat buffer
                    leax      ,s        point at the stat buffer
                    pshs      x         push the buffer address
                    ldd       $08,u     load the path number
                    pshs      d         push the path number
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push the status code
                    lbsr      GetStat   get the path status
                    leas      6,s        drop the arguments
                    ldd       $06,u     load the flags
                    pshs      d         save the flags
                    ldb       $02,s     load the device type
                    bne       SetFullBuffer full buffer if not a device
                    ldd       #$0040    line-buffered flag
                    bra       ApplyBufFlags go apply the flags

SetFullBuffer       ldd       #$0080    full-buffered flag
ApplyBufFlags       ora       ,s+       merge into flags high byte
                    orb       ,s+       merge into flags low byte
                    std       $06,u     save the updated flags
                    leas      32,s       release the stat buffer
MarkBufChecked      ldd       $06,u     load the flags
                    ora       #$80      mark buffering known
                    std       $06,u     save the flags
                    clra                clear high byte
                    andb      #$0C      mask the user-buffer bits
                    beq       ChooseBufSize allocate buffer if none set
                    puls      pc,u      return with the user buffer

ChooseBufSize       ldd       $0b,u     load the buffer size
                    bne       AllocBuffer size already set
                    ldd       $06,u     load the flags
                    clra                clear high byte
                    andb      #$40      mask the line-buffered bit
                    beq       FullBufSize full buffer size if block buffered
                    ldd       #$0080    line buffer size
                    bra       StoreBufSize go store the size

FullBufSize         ldd       #$0100    full buffer size
StoreBufSize        std       $0b,u     store the buffer size
AllocBuffer         ldd       $02,u     load the buffer pointer
                    bne       MarkBufAlloc already allocated
                    ldd       $0b,u     load the buffer size
                    pshs      d         push the size
                    lbsr      FreeMem   allocate the buffer memory
                    leas      2,s        drop the argument
                    std       $02,u     save the buffer pointer
                    cmpd      #$FFFF    allocation failed
                    beq       MarkBuffered handle the allocation failure
MarkBufAlloc        ldd       $06,u     load the flags
                    orb       #$08      mark the buffer allocated
                    std       $06,u     save the flags
                    bra       SetBufEnd continue the setup

MarkBuffered        ldd       $06,u     load the file status flags
                    orb       #$04      set the buffered flag bit
                    std       $06,u     store the flags back
                    leax      $0a,u     point past the header to the buffer
                    stx       $02,u     save the buffer pointer
                    ldd       #$0001    one byte buffer size
                    std       $0b,u     store the buffer size
SetBufEnd           ldd       $02,u     load the buffer base
                    addd      $0b,u     add the buffer size
                    std       $04,u     set the buffer end pointer
                    std       ,u        set the current pointer
                    puls      pc,u      return

ConvSpec            pshs      u         save frame register
                    ldb       $05,s     load the conversion char argument
                    sex                 sign extend to sixteen bits
                    tfr       d,x       move the char into x
                    bra       CheckConvChar go test the conversion letter

ConvNumeric         ldd       [$06,s]   load the pointer through the argument
                    addd      #$0004    advance by four bytes
                    std       [$06,s]   store the advanced pointer
                    leax      >EmptyStrA,pcr point to the empty result string
                    bra       ConvReturn go return the result

ConvDefault         ldb       $05,s     load the conversion char
                    stb       >ScratchChar,y  store the char into the scratch buffer
                    leax      >OneCharStr,y  point to the one-char result string
ConvReturn          tfr       x,d       move the result pointer to d
                    puls      pc,u      return

CheckConvChar       cmpx      #$0064    is it a 'd' conversion
                    beq       ConvNumeric handle it as numeric
                    cmpx      #$006F    is it an 'o' conversion
                    lbeq      ConvNumeric handle it as numeric
                    cmpx      #$0078    is it an 'x' conversion
                    lbeq      ConvNumeric handle it as numeric
                    bra       ConvDefault otherwise use the default path

                    puls      pc,u      return

EmptyStrA           fcb       $00       empty string
GetEmptyStr         pshs      u         save frame register
                    leax      >EmptyStrB,pcr point to the empty string
                    tfr       x,d       move pointer to d
                    puls      pc,u      return the empty string pointer

EmptyStrB           fcb       $00       empty string
strlen              pshs      u         save frame register
                    ldu       $04,s     load the string pointer
StrLenLoop          ldb       ,u+       scan bytes to the terminator
                    bne       StrLenLoop keep scanning until zero
                    tfr       u,d       end pointer to d
                    subd      $04,s     subtract the start pointer
                    addd      #$FFFF    discount the terminator byte
                    puls      pc,u      return the length

                    use       lib/strcpy.asm

                    use       lib/strcat.asm

                    use       lib/strcmp.asm

                    use       lib/imul.asm
                    use       lib/shift.asm

GetStat             lda       $05,s     load the path number
                    ldb       $03,s     load the getstat function code
                    beq       GetStatDefault code zero uses the default
                    cmpb      #$01      is it code one
                    beq       GetStatCall use the default call
                    cmpb      #$06      is it code six
                    beq       GetStatCall use the default call
                    cmpb      #$02      is it code two
                    beq       GetStatXU use the x/u variant
                    cmpb      #$05      is it code five
                    beq       GetStatXU use the x/u variant
                    ldb       #E$UnkSvc unknown service error
                    lbra      SyscallErr report the error

                    use       lib/getstat.asm

GetStatDefault      ldx       $06,s     load x from the argument
GetStatCall         os9       I$GetStt  get file status
                    lbra      SyscallRet return the status

                    lda       $05,s     load the path number
                    ldb       $03,s     load the setstat function code
                    beq       SetStatCall code zero uses the default
                    cmpb      #$02      is it code two
                    beq       SetStatXU use the x/u variant
                    ldb       #E$UnkSvc unknown service error
                    lbra      SyscallErr report the error

SetStatCall         ldx       $06,s     load x from the argument
                    os9       I$SetStt  set file status
                    lbra      SyscallRet return the status

                    use       lib/setstat.asm

                    use       lib/access.asm

                    use       lib/openpath.asm

                    use       lib/closepath.asm

                    ldx       $02,s     load the pathname
                    ldb       $05,s     load the attributes
                    os9       I$MakDir  make the directory
                    lbra      SyscallRet return the status

                    use       lib/createheada.asm
                    use       lib/createtail.asm

                    use       lib/deletepath.asm

                    lda       $03,s     load the path number
                    os9       I$Dup     duplicate the path
                    lbcs      SyscallErr report the error
                    tfr       a,b       new path number to b
                    clra                clear high byte
                    rts                 return the path number
                    use       lib/readpath.asm

                    use       lib/writepath.asm

                    use       lib/seek.asm
HighResultWord      equ       PosField this module's long-value high cell
LowResultWord       equ       PosLow this module's long-value low cell

LinkModule          pshs      u,y       save registers
                    ldx       $06,s     load the module name
                    lda       $09,s     load the type/language byte
                    asla                shift into the high nibble
                    asla                shift
                    asla                shift
                    asla                shift
                    ora       $0b,s     combine with the low nibble
                    os9       F$Link    link the module
LinkReturn          tfr       u,d       module entry to d
                    puls      u,y       restore registers
                    lbcs      SyscallErr report the error
                    rts                 return the module entry
                    pshs      u,y       save registers
                    ldx       $06,s     load the pathname
                    lda       $09,s     load the type/language byte
                    asla                shift into the high nibble
                    asla                shift
                    asla                shift
                    asla                shift
                    ora       $0b,s     combine with the low nibble
                    os9       F$Load    load the module
                    bra       LinkReturn return the module entry

UnLinkModule        pshs      u         save frame register
                    ldu       $04,s     load the module pointer
                    os9       F$UnLink  unlink the module
                    puls      u         restore frame register
                    lbra      SyscallRet return the status

                    ldd       BreakPtr,y   load the current break pointer
                    pshs      d         save it
                    ldd       $04,s     load the requested size
                    cmpd      FreeCount,y   compare against the free count
                    bcs       SbrkAlloc enough already free
                    addd      BreakPtr,y   compute the new break
                    pshs      y         save the data base
                    subd      ,s        compute total data size from base
                    os9       F$Mem     request a larger data area
                    tfr       y,d       new memory size to d
                    puls      y         restore the data base
                    bcc       SbrkUpdate allocation succeeded
                    ldd       #$FFFF    return the failure value
                    leas      2,s        drop the temporary
                    rts                 return

SbrkUpdate          std       BreakPtr,y   update the break pointer
                    addd      FreeCount,y   add to the free count
                    subd      ,s        subtract the old break
                    std       FreeCount,y   store the new free count
SbrkAlloc           leas      2,s        drop the temporary
                    ldd       FreeCount,y   load the free count
                    pshs      d         save it
                    subd      $04,s     reduce by the request size
                    std       FreeCount,y   store the new free count
                    ldd       BreakPtr,y   load the break pointer
                    subd      ,s++      compute the block start
                    pshs      d         save it
                    clra                zero fill value
                    ldx       ,s        load the block pointer
SbrkZeroLoop        sta       ,x+       zero-fill the block
                    cmpx      BreakPtr,y   until the break pointer
                    bcs       SbrkZeroLoop loop
                    puls      pc,d      return the block pointer

FreeMem             ldd       $02,s     load the block size
                    addd      ArenaBase,y   add the arena base
                    bcs       BrkFail   out-of-range, error
                    cmpd      HeapLimit,y   compare requested break against heap limit
                    bcc       BrkFail   fail if it exceeds the limit
                    pshs      d         save the new break pointer
                    ldx       ArenaBase,y   load the current break pointer
                    clra                zero fill value
BrkZeroLoop         cmpx      ,s        loop until reaching the new break
                    bcc       BrkSetBreak stop when the new break is reached
                    sta       ,x+       zero the newly allocated byte
                    bra       BrkZeroLoop continue the zero fill loop

BrkSetBreak         ldd       ArenaBase,y   load old break to return to caller
                    puls      x         retrieve the new break pointer
                    stx       ArenaBase,y   store the updated break
                    rts                 return the old break value

BrkFail             ldd       #$FFFF    return the failure value
                    rts                 return
                    lda       $03,s     load the signal code argument
                    ldb       $05,s     load the target process id
                    os9       F$Send    send the signal to the process
                    lbra      SyscallRet check for error and return

                    clra                clear a
                    clrb                clear b to wait for any child
                    os9       F$Wait    wait for a child to terminate
                    lbcs      SyscallErr return error if the wait failed
                    ldx       $02,s     load the status pointer argument
                    beq       WaitNoStatus skip if no status wanted
                    stb       $01,x     store the child exit status
                    clr       ,x        clear the high status byte
WaitNoStatus        tfr       a,b       move child id into the return value
                    clra                clear the high byte
                    rts                 return the child id
                    lda       $03,s     load the priority argument
                    ldb       $05,s     load the target process id
                    os9       F$SPrior  set the process priority
                    lbra      SyscallRet check for error and return

SysChain            leau      ,s        point u at the argument block
                    leas      $00FF,y   reserve local stack space
                    ldx       $02,u     load the module name pointer
                    ldy       $04,u     load the parameter area size
                    lda       $09,u     load the type code
                    asla                shift type into the high nibble
                    asla                shift type into the high nibble
                    asla                shift type into the high nibble
                    asla                shift type into the high nibble
                    ora       $0b,u     combine with the language code
                    ldb       $0d,u     load the data area size
                    ldu       $06,u     load the parameter area pointer
                    os9       F$Chain   chain to the new module
                    os9       F$Exit    exit if chain returns
                    pshs      u,y       save u and y across the call
                    ldx       $06,s     load the module name pointer
                    ldy       $08,s     load the parameter area size
                    ldu       $0a,s     load the parameter area pointer
                    lda       $0d,s     load the type code
                    ora       $0f,s     combine with the language code
                    ldb       $11,s     load the data area size
                    os9       F$Fork    fork the child process
                    puls      u,y       restore u and y
                    lbcs      SyscallErr return error if the fork failed
                    tfr       a,b       move child id into the return value
                    clra                clear the high byte
                    rts                 return the child id

SysGetProcId        pshs      y         save y across the call
                    os9       F$ID      get the current process id
                    puls      y         restore y
                    bcc       GetProcIdOk branch on success
                    lbcs      SyscallErr return error on failure
GetProcIdOk         tfr       a,b       move the id into the return value
                    clra                clear the high byte
                    rts                 return the process id

SysGetIds           pshs      y         save y across the call
                    os9       F$ID      get the process and user id
                    bcc       GetIdsRet branch on success
IdErr               puls      y         restore y
                    lbra      SyscallErr jump to the error exit

GetIdsRet           tfr       y,d       return the user id in d
                    puls      pc,y      return with y restored

                    pshs      y         save y across the call
                    bsr       SysGetIds fetch the current user id
                    std       -$02,s    save the current user id
                    beq       DoSetUser allowed if super user
                    ldb       #E$FNA    prepare permission error
                    bra       IdErr     jump to the error exit

DoSetUser           ldy       $04,s     load the new user id argument
                    os9       F$SUser   change the user id
                    bcc       SetUserOk branch on success
                    cmpb      #E$UnkSvc check for unknown-service error
                    bne       IdErr     fail on any other error
                    tfr       y,d       move the requested id into d
                    ldy       >$004B    point y at the global work block (data-area address, overlaps cstart)
                    std       UserId,y     record the user id in the work block
SetUserOk           clra                clear a
                    clrb                clear b
                    puls      pc,y      return success with y restored

                    use       lib/syscallerr.asm

exit                lbsr      RunAtexit run the atexit handlers
                    lbsr      CloseAllStreams flush open output files
_exit               ldd       $02,s     load the exit status argument
                    os9       F$Exit    terminate the process
RunAtexit           rts                 return

* ------------------------------------------------------------------
* WorkBlockImage - initialisation image for the cc1 work block, walked once by
* the _start routine: count1 word + count1 bytes copied to base, then
* count2 word + count2 bytes copied to base+$2d, then two relocation
* directories that fix up embedded pointers (see _start at $001A).
* ------------------------------------------------------------------
WorkBlockImage      fdb       $0001     count1 - bytes copied to base
                    fcb       $00       block1 image (-> base+$00)
                    fdb       $0192     count2 - bytes copied to base+$2d

* block2 - work block template ($192 bytes) copied to base+$2d
                    fcc       /ctmp.XXXXXX/       base+$2d temporary file name template
                    zmb       9         pad
                    fcc       /c.com/             base+$41 compiler command name
                    zmb       25        pad
                    fdb       MsgBanner base+$5f reloc ptr (+module base) -> banner
                    fdb       10000,1000,100,10 powers of ten
                    fdb       $0069     base+$69 relocatable pointer, +work base
                    fcb       $6C,$78,$00 base+$6b
                    zmb       7         work block default fields
                    fcb       $01
                    zmb       12
                    fcb       $02,$00,$01
                    zmb       10
                    fcb       $42,$00,$02
                    zmb       173
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01 character classification table
                    fcb       $01,$11,$11,$01,$11,$11,$01,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01
                    fcb       $01,$01,$01,$01,$01,$01,$01,$01
                    fcb       $30,$20,$20,$20,$20,$20,$20,$20
                    fcb       $20,$20,$20,$20,$20,$20,$20,$20
                    fcb       $48,$48,$48,$48,$48,$48,$48,$48
                    fcb       $48,$48,$20,$20,$20,$20,$20,$20
                    fcb       $20,$42,$42,$42,$42,$42,$42,$02
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02
                    fcb       $02,$02,$02,$20,$20,$20,$20,$20
                    fcb       $20,$44,$44,$44,$44,$44,$44,$04
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04
                    fcb       $04,$04,$04,$20,$20,$20,$20,$01

* relocation directory
                    fdb       $0001     nreloc1
                    fdb       $005F     relocate word at work+$5f by module base
                    fdb       $0001     nreloc2
                    fdb       $0069     relocate word at work+$69 by work base

* trailing module name string
                    fcc       /cc1/
                    fcb       C$NULL

                    emod
eom                 equ       *
                    end