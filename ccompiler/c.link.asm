                    nam       c.link
                    ttl       program module

* Annotated 2026-07-14 (Claude Code):
*   - renamed disassembled labels to meaningful names
*   - added an inline comment to every instruction
*   - re-disassembled the "**** STACK OVERFLOW ****" banner that had
*     been decoded as instructions
*   - separated the direct-page globals from the startup code they had
*     been mis-resolved onto (disassembler assumed DP=$00); they are now
*     a direct-page equate block with the references repointed
*   - verified byte-identical to the original assembly (module CRC $DBED5C)

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
GlbVar0001          rmb       $1
LowWord             rmb       $1
GlbVar0003          rmb       $2
Buffer              rmb       $3
GlbVar0008          rmb       $2
GlbVar000A          rmb       $2
GlbVar000C          rmb       $2
GlbVar000E          rmb       $2
GlbVar0010          rmb       $4
GlbVar0014          rmb       $2
GlbTFlag            rmb       $2
GlbVar0018          rmb       $2
GlbOutPath          rmb       $2
GlbVar001C          rmb       $2
GlbVar001E          rmb       $2
GlbVar0020          rmb       $2
GlbDpDataSize       rmb       $2
GlbVar0024          rmb       $2
GlbInitDataSize     rmb       $2
GlbVar0028          rmb       $2
GlbVar002A          rmb       $2
GlbVar002C          rmb       $2
GlbVar002E          rmb       $2
GlbVar0030          rmb       $2
GlbMemSize          rmb       $2
GlbVar0034          rmb       $2
GlbVar0036          rmb       $2
GlbVar0038          rmb       $2
GlbVar003A          rmb       $2
GlbVar003C          rmb       $2
GlbListHead         rmb       $2
GlbVar0040          rmb       $2
GlbVar0042          rmb       $2
GlbVar0044          rmb       $2
GlbVar0046          rmb       $2
GlbVar0048          rmb       $2
GlbVar004A          rmb       $2
GlbVar004C          rmb       $2
GlbVar004E          rmb       $2
GlbVar0050          rmb       $2
GlbVar0052          rmb       $2
GlbVar0054          rmb       $6
GlbVar005A          rmb       $2
GlbVar005C          rmb       $2
GlbVar005E          rmb       $2
ListHeadAddress     rmb       $10
SectNameTab         rmb       $2
SectionListField    rmb       $2
SectionListField2   rmb       $2
SectionListField3   rmb       $2
OutputNameField     rmb       $2
OutputPointer       rmb       $2
Pow10               rmb       $8
OnesPlace           rmb       $2
AddressBuffer       rmb       $1
ScratchBuffer       rmb       $2
SegmentTableStart   rmb       $D
MessageWorkBuffer   rmb       $D
NameBuf             rmb       $B6
TableEnd            rmb       $1
CtypeTab            rmb       $C0
HeapBreak           rmb       $2
HighResultWord      rmb       $2
LowResultWord       rmb       $6
PoolPointer         rmb       $2
PoolLimit           rmb       $2
OutputPathHandle    rmb       $2
Errno               equ       OutputPathHandle the fatal-error path reuses this cell for errno
SourceFileTable     rmb       $3C
LibraryDirectoryTable rmb       $A
EditionNumber       rmb       $1
NamePointer         rmb       $2
OutputFileName      rmb       $2
EntryName           rmb       $2
OutputBuffer        rmb       $100
OutputNameField2    rmb       $4
SecondNameField     rmb       $4
LongVariable        rmb       $4
LongVariable2       rmb       $4
HashTableBase       rmb       $2E6
OutputPointer2      rmb       $2
NumberBuffer        rmb       $A
DigitScratchBuffer  rmb       $A
LeftJustifyFlag     rmb       $2
PadCharacter        rmb       $2
ResultSignFlag      rmb       $1
DivideRoutinePointer rmb       $2
FreeSpace           rmb       $2
UserHandlerPointer  rmb       $2
HeapStart           rmb       $F80     start of heap/bss (end of static data)
size                equ       .

name                equ       *
                    fcs       /c.link/
                    fcb       edition

* --- shared C runtime startup (see cstart.i) ---
RTBASE              equ       CtypeTab+$80 runtime-globals block base (after the 128-byte ctype table)
DATAEND             equ       HeapStart end of static data / heap start / stack limit
HDRADV              equ       ListHeadAddress initialized-data header advance (non-DP data start)

* ---- shared node-record header fields (symbol/section/module linked records)
NdNext              equ       $0e       list/sibling link (next in a node list)
NdLink              equ       $11       module / free-list chain link
NdMFlags            equ       $13       module flags
NdExec              equ       $23       module exec offset
NdHead              equ       $2d       head of a node child list
NdName              equ       $2f       name / section id
                    use       lib/cstart.asm

main                pshs      u         save the data base
                    ldd       #$FFB0    stack space needed
                    lbsr      stkcheck  check stack space
                    leas      -6,s       allocate local variables
                    leax      FinishOutput,pcr point to the link pass handler
                    pshs      x         push the handler pointer
                    lbsr      SetIntercept register the cleanup handler
                    leas      2,s        drop the pushed pointer
                    lbra      ArgLoop   enter the argument loop

ParseArg            ldx       $0C,s     get the current argv pointer
                    leax      $02,x     advance to next argument
                    stx       $0C,s     save the argv pointer
                    ldu       ,x        get the argument string
                    ldb       ,u        get its first character
                    cmpb      #$2d      is it an option dash
                    lbne      SourceFile treat as a source file
                    lbra      NextOptChar parse the option

DispatchOpt         ldb       ,u        get the option character
                    sex                 sign extend to a word
                    tfr       d,x       index by option character
                    lbra      OptDispatch dispatch the option

OptOutFile          leau      $01,u     skip the option letter
                    ldb       ,u        get the next character
                    cmpb      #$3d      is an equals sign
                    bne       SetModName no filename supplied
                    leau      $01,u     skip the equals sign
                    tfr       u,d       output filename pointer
                    std       OutputFileName,y   save the output file name
SetModName          ldd       NamePointer,y   module name already set
                    lbne      OptCleanup option complete
                    pshs      u         push the argument pointer
                    lbsr      BaseName  duplicate the name string
                    leas      2,s        drop the argument
                    std       NamePointer,y   save the module name
                    lbra      OptCleanup option complete

OptLibDir           leau      $01,u     skip the option letter
                    ldb       ,u        get the next character
                    cmpb      #$3d      is an equals sign
                    bne       OptLibErr malformed library option
                    ldd       GlbVar000C get library directory count
                    cmpd      #$0005    reached the maximum
                    bge       OptLibErr too many library dirs
                    ldd       GlbVar000C get the count
                    addd      #$0001    increment it
                    std       GlbVar000C save the count
                    subd      #$0001    back to the index
                    aslb                multiply index by two
                    rola                for a word index
                    leax      LibraryDirectoryTable,y   library directory table
                    leax      d,x       index into the table
                    pshs      x         push the slot pointer
                    pshs      u         push the string pointer
                    ldd       #$0001    skip past equals offset
                    addd      ,s++      point past the equals
                    std       [,s++]    store library dir pointer
                    lbra      OptCleanup option complete

OptLibErr           pshs      u         push the option string
                    leax      MsgLibSpecErr,pcr library error format
                    pshs      x         push the format string
                    lbsr      PrintErrMsg print the error message
                    leas      4,s        drop the arguments
                    lbra      OptCleanup option complete

OptFlagM            ldd       #$0001    set flag value
                    std       GlbVar000E enable the m option
                    lbra      NextOptChar next option character

OptFlagS            ldd       #$0001    set flag value
                    std       GlbVar0010 enable the s option
                    lbra      NextOptChar next option character

OptName             leau      $01,u     skip the option letter
                    ldb       ,u        get the next character
                    cmpb      #$3d      is an equals sign
                    lbne      OptCleanup no name supplied
                    leax      $01,u     point past the equals
                    stx       NamePointer,y   save the module name
                    lbra      OptCleanup option complete

OptEdition          leau      $01,u     skip the option letter
                    ldb       ,u        get the next character
                    cmpb      #$3d      is an equals sign
                    lbne      OptCleanup no value supplied
                    pshs      u         push the argument pointer
                    ldd       #$0001    skip past equals offset
                    addd      ,s++      point past the equals
                    pshs      d         push the number string
                    lbsr      Atoi      convert edition to number
                    leas      2,s        drop the argument
                    stb       EditionNumber,y   save the edition number
                    bra       OptCleanup option complete

OptMemSize          leau      $01,u     skip the option letter
                    ldb       ,u        get the next character
                    cmpb      #$3d      is an equals sign
                    bne       OptMemErr malformed memory option
                    pshs      u         push the argument pointer
                    ldd       #$0001    skip past equals offset
                    addd      ,s++      point past the equals
                    pshs      d         push the number string
                    lbsr      ParseNumber convert hex to number
                    leas      2,s        drop the argument
                    std       ,s        save the parsed value
                    cmpd      #$0100    exceeds one page limit
                    bcs       OptCleanup value is acceptable
                    ldd       ,s        reload the value
                    std       GlbMemSize save the memory size
                    bra       OptCleanup option complete

OptMemErr           pshs      u         push the option string
                    leax      MsgMemSize,pcr memory size label string
                    pshs      x         push the argument
                    leax      MsgModSpecErr,pcr memory error format
                    pshs      x         push the format string
                    lbsr      PrintErrMsg print the error message
                    leas      6,s        drop the arguments
OptDataMod          ldd       #$0001    set flag value
                    std       GlbVar0014 enable the b option flag
                    leau      $01,u     skip the option letter
                    ldb       ,u        get the next character
                    cmpb      #$3d      is an equals sign
                    bne       OptCleanup no name supplied
                    leax      $01,u     point past the equals
                    stx       EntryName,y   save the b option name
OptCleanup          leax      $06,s     restore the stack frame
                    lbra      OptReturn return to the argument loop

OptFlagT            ldd       #$0001    set flag value
                    std       GlbTFlag  enable the t option flag
                    bra       NextOptChar next option character

OptUnknown          ldb       ,u        get the unknown option char
                    sex                 sign extend to a word
                    pshs      d         push the option character
                    leax      MsgUnknownOpt,pcr unknown option format
                    pshs      x         push the format string
                    lbsr      PrintErrMsg print the error message
                    leas      4,s        drop the arguments
                    bra       NextOptChar next option character

OptDispatch         cmpx      #$006F    option o
                    lbeq      OptOutFile handle the output file
                    cmpx      #$006C    option l
                    lbeq      OptLibDir handle the library dir
                    cmpx      #$006D    option m
                    lbeq      OptFlagM  handle the m flag
                    cmpx      #$0073    option s
                    lbeq      OptFlagS  handle the s flag
                    cmpx      #$006E    option n
                    lbeq      OptName   handle the module name
                    cmpx      #$0045    option E
                    lbeq      OptEdition handle the edition
                    cmpx      #$0065    option e
                    lbeq      OptEdition handle the edition
                    cmpx      #$004D    option M
                    lbeq      OptMemSize handle the memory size
                    cmpx      #$0062    option b
                    lbeq      OptDataMod handle the b option
                    cmpx      #$0074    option t
                    beq       OptFlagT  handle the t flag
                    bra       OptUnknown unknown option

NextOptChar         leau      $01,u     advance to next character
                    ldb       ,u        get the option character
                    lbne      DispatchOpt dispatch the next option
                    bra       ArgLoop   end of this argument

OptReturn           leas      -$06,x    restore the stack frame
                    bra       ArgLoop   back to the argument loop

SourceFile          ldd       GlbVar000A get the source file count
                    cmpd      #$001E    reached the maximum
                    bne       StoreSourceFile room for another file
                    leax      MsgTooManySrc,pcr too many files message
                    pshs      x         push the format string
                    lbsr      PrintErrMsg print the error message
                    leas      2,s        drop the argument
StoreSourceFile     ldd       GlbVar000A get the file count
                    addd      #$0001    increment it
                    std       GlbVar000A save the count
                    subd      #$0001    back to the index
                    aslb                multiply index by two
                    rola                for a word index
                    leax      SourceFileTable,y   source file table
                    leax      d,x       index into the table
                    ldd       [$0C,s]   get the argument pointer
                    std       ,x        store the source file name
ArgLoop             ldd       $0a,s     get remaining argument count
                    addd      #$FFFF    decrement it
                    std       $0a,s     save the count
                    lbgt      ParseArg  process the next argument
                    lbsr      EmitModules run the link pass
                    lbsr      ReportUnresolved resolve external references
                    std       -$02,s    save the unresolved count
                    beq       RefsResolved all references resolved
                    leax      MsgUnresolved,pcr unresolved references message
                    pshs      x         push the message
                    lbsr      PrintErrMsg print the error message
                    leas      2,s        drop the argument
RefsResolved        ldd       NamePointer,y   get the module name
                    pshs      d         push the name pointer
                    lbsr      strlen+1  create the output module
                    leas      2,s        drop the argument
                    std       GlbOutPath save the output path
                    lbsr      ComputeSectionSizes write the module header
                    lbsr      ApplySectionBase write the module body
                    ldd       GlbVar0014 b option was set
                    beq       ChkDpAlloc skip the data checks
                    ldd       GlbInitDataSize init data present
                    bne       WarnInitData report the init data
                    ldd       GlbVar002A second init data present
                    beq       WarnDpData no init data warning needed
WarnInitData        leax      MsgNoInitData,pcr no init data message
                    pshs      x         push the message
                    lbsr      EmitNameRec print a warning
                    leas      2,s        drop the argument
WarnDpData          ldd       GlbDpDataSize dp data present
                    beq       WarnStaticData no dp data warning needed
                    leax      MsgNoDpData,pcr no dp data message
                    pshs      x         push the message
                    lbsr      EmitNameRec print a warning
                    leas      2,s        drop the argument
WarnStaticData      ldd       GlbTFlag  t flag was set
                    bne       ChkDpAlloc static data is allowed
                    ldd       GlbVar001E static data present
                    beq       ChkDpAlloc no static data warning needed
                    leax      MsgNoStaticData,pcr no static data message
                    pshs      x         push the message
                    lbsr      EmitNameRec print a warning
                    leas      2,s        drop the argument
ChkDpAlloc          ldd       GlbDpDataSize load direct page base size
                    addd      GlbVar002A add direct page data size
                    cmpd      #$0100    exceeds a single page
                    bls       ChkNameClash within a page so skip warning
                    ldd       GlbDpDataSize reload direct page base size
                    addd      GlbVar002A total direct page bytes
                    pshs      d         push size for message
                    leax      MsgDpAlloc,pcr point to dp overflow message
                    pshs      x         push format string
                    lbsr      PrintErrMsg print dp allocation warning
                    leas      4,s        drop message arguments
ChkNameClash        ldd       GlbVar0044 any pending name clash
                    beq       ChkOutFile no clash so skip
                    leax      MsgNameClash,pcr point to name clash message
                    pshs      x         push format string
                    lbsr      PrintErrMsg report name clash
                    leas      2,s        drop message argument
ChkOutFile          ldd       OutputFileName,y   output file specified
                    bne       ResolveEntry have an output file
                    leax      MsgNoOutFile,pcr point to no output file message
                    pshs      x         push format string
                    lbsr      PrintErrMsg report missing output file
                    leas      2,s        drop message argument
ResolveEntry        ldd       GlbVar0014 copy-only mode
                    lbeq      FinishModule skip entry resolution when copying
                    ldd       EntryName,y   entry point name given
                    bne       LookupEntry have an entry name
                    leax      MsgNoEntryName,pcr point to no entry point message
                    pshs      x         push format string
                    lbsr      EmitNameRec report missing entry point
                    bra       SetModFlag go finish module

LookupEntry         leas      -2,s       make a local slot
                    ldd       EntryName,y   entry point name
                    pshs      d         push name argument
                    ldd       EntryName,y   entry point name again
                    pshs      d         push lookup argument
                    lbsr      HashName  hash the entry symbol name
                    std       ,s        save symbol pointer
                    lbsr      LookupSym find the symbol entry
                    leas      4,s        drop lookup arguments
                    std       ,s        save found symbol pointer
                    beq       EntryNotFound symbol not found
                    ldx       ,s        symbol pointer
                    ldd       $0a,x     load symbol type field
                    clra                clear high byte
                    andb      #$07      mask to type bits
                    cmpd      #$0004    is it a code symbol
                    bne       EntryNotFound wrong type treated as not found
                    ldx       ,s        symbol pointer
                    ldd       $0C,x     load entry offset
                    std       GlbVar0030 save resolved entry offset
                    bra       SetModFlag go finish module

EntryNotFound       ldd       EntryName,y   entry point name
                    pshs      d         push name argument
                    leax      MsgEntryNotFound,pcr point to entry not found message
                    pshs      x         push format string
                    lbsr      EmitNameRec report entry not found
                    leas      4,s        drop message arguments
SetModFlag          leas      2,s        drop the local slot
                    ldd       #$2181    output module type constant
                    std       GlbVar0018 store output module flag
FinishModule        lbsr      WriteOutModule write out the module
                    leas      6,s        restore caller frame
                    puls      pc,u      return to caller

EmitModules         pshs      u         save caller frame pointer
                    ldd       #$FF96    negative local frame size
                    lbsr      stkcheck  allocate the stack frame
                    leas      -30,s      reserve extra locals
                    ldd       GlbVar000A section count
                    lbeq      EmitDone  nothing to emit so finish
                    clra                init index high byte
                    clrb                init index low byte
                    lbra      SectionTest enter first loop test

SectionLoop         ldd       ,s        loop index
                    aslb                index times two
                    rola                extend to word
                    leax      SourceFileTable,y   first section table base
                    leax      d,x       index into table
                    ldd       ,x        load section entry pointer
                    std       GlbVar0042 save current section pointer
                    ldd       GlbVar0038 current module handle
                    pshs      d         push module argument
                    leax      MsgReadMode,pcr open mode read string
                    pshs      x         push mode string
                    ldd       GlbVar0042 section pointer
                    pshs      d         push section argument
                    lbsr      WalkExprLoop open the section
                    leas      6,s        drop open arguments
                    std       GlbVar0038 save module handle
                    bne       SectionOpened opened successfully
                    lbsr      ErrCantOpen report open failure
SectionOpened       ldd       GlbVar0003 copy global into module field
                    ldx       GlbVar0038 module handle
                    std       $0b,x     store field into module block
                    ldd       GlbVar0038 module handle
                    pshs      d         push module argument
                    ldd       #$0001    read one record
                    pshs      d         push count argument
                    ldd       #$001C    record byte size
                    pshs      d         push size argument
                    leax      $08,s     record buffer pointer
                    pshs      x         push buffer argument
                    lbsr      FRead     read a record
                    leas      8,s        drop read arguments
                    std       -$02,s    save read result
                    bne       RecordRead read succeeded
                    lbsr      ErrReadInput report read error
RecordRead          leax      $02,s     record buffer pointer
                    ldd       $02,x     second word of record
                    pshs      d         push argument
                    ldd       ,x        first word of record
                    pshs      d         push argument
                    bsr       CmpRecType1 fetch inline constant pointer
                    fcb       $62
                    fcb       $CD
                    fcb       $23
                    fcb       $87
CmpRecType1         puls      x         pointer to inline constant
                    lbsr      LongCmp   compare record type
                    beq       RecTypeOk types match
                    lbsr      ErrNotReloc report type mismatch
                    bra       SectionTail go to section tail

RecTypeOk           ldb       $08,s     read flag byte
                    beq       ChkCopyDup flag not set
                    lbsr      ErrAsmErrors report duplicate record
                    bra       SectionTail go to section tail

ChkCopyDup          ldd       GlbVar0014 copy-only mode
                    beq       ChkSymDup not copy mode
                    ldd       $06,s     existing entry present
                    beq       SectionTail none so skip
                    lbsr      ErrNoMainline report already defined
                    bra       SectionTail go to section tail

ChkSymDup           ldd       ,s        current symbol present
                    beq       NoMainline none present
                    ldd       $06,s     existing entry present
                    beq       SectionTail none so skip
                    lbsr      ErrDualMainline report redefinition
                    bra       SectionTail go to section tail

NoMainline          ldd       $06,s     existing mainline entry
                    bne       HaveMainline already have mainline
                    ldd       GlbVar0042 section name
                    pshs      d         push name argument
                    leax      MsgNoMainline,pcr point to no mainline message
                    pshs      x         push format string
                    lbsr      PrintErrMsg report no mainline
                    leas      4,s        drop message arguments
                    bra       SetSectFlag skip storing mainline

HaveMainline        ldd       $06,s     mainline entry pointer
                    std       GlbVar0018 record mainline entry
SetSectFlag         ldb       EditionNumber,y   current section flag byte
                    bne       SectionTail flag already set
                    ldb       $0e,s     new flag value
                    stb       EditionNumber,y   store section flag
SectionTail         clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    leax      $04,s     local buffer pointer
                    pshs      x         push buffer argument
                    lbsr      BuildSymNode build symbol node
                    leas      4,s        drop arguments
                    ldd       ,s        load result
                    lbne      SectionNext nonzero so advance index
                    leas      -2,s       make a local slot
                    ldd       GlbListHead output list head
                    std       ,s        save iterate pointer
                    ldd       #$0104    list type code
                    pshs      d         push type code
                    ldd       >SectNameTab,y load section list field
                    pshs      d         push list argument
                    ldd       $04,s     iterate pointer
                    pshs      d         push list pointer
                    lbsr      AddSymbol merge into output list
                    leas      6,s        drop arguments
                    ldd       #$0104    list type code
                    pshs      d         push type code
                    ldd       >OutputNameField,y  load section list field
                    pshs      d         push list argument
                    ldd       $04,s     iterate pointer
                    pshs      d         push list pointer
                    lbsr      AddSymbol merge into output list
                    leas      6,s        drop arguments
                    ldd       #$0101    list type code
                    pshs      d         push type code
                    ldd       >SectionListField,y  load section list field
                    pshs      d         push list argument
                    ldd       $04,s     iterate pointer
                    pshs      d         push list pointer
                    lbsr      AddSymbol merge into output list
                    leas      6,s        drop arguments
                    ldd       #$0100    list type code
                    pshs      d         push type code
                    ldd       >SectionListField2,y  load section list field
                    pshs      d         push list argument
                    ldd       $04,s     iterate pointer
                    pshs      d         push list pointer
                    lbsr      AddSymbol merge into output list
                    leas      6,s        drop arguments
                    ldd       #$0102    list type code
                    pshs      d         push type code
                    ldd       >SectionListField3,y  load section list field
                    pshs      d         push list argument
                    ldd       $04,s     iterate pointer
                    pshs      d         push list pointer
                    lbsr      AddSymbol merge into output list
                    leas      6,s        drop arguments
                    leas      2,s        drop the local slot
SectionNext         ldd       ,s        loop index
                    addd      #$0001    increment index
SectionTest         std       ,s        store loop index
                    ldd       ,s        reload index
                    cmpd      GlbVar000A compare against section count
                    lblt      SectionLoop loop for more sections
                    clra                clear high byte
                    clrb                clear low byte
                    lbra      RefTest   enter second loop test

RefLoop             ldd       ,s        loop index
                    aslb                index times two
                    rola                extend to word
                    leax      LibraryDirectoryTable,y   second table base
                    leax      d,x       index into table
                    ldd       ,x        load table entry
                    std       GlbVar0042 save current section pointer
                    ldd       GlbVar0038 current module handle
                    pshs      d         push module argument
                    lbsr      fclose    close previous module
                    leas      2,s        drop argument
                    leax      MsgReadMode2,pcr open mode read string
                    pshs      x         push mode string
                    ldd       GlbVar0042 section pointer
                    pshs      d         push section argument
                    lbsr      WalkExprNode open the section
                    leas      4,s        drop open arguments
                    std       GlbVar0038 save module handle
                    lbne      RefReadNext opened successfully
                    lbsr      ErrCantOpen report open failure
                    bra       RefReadNext continue to read loop

RefRecord           leax      $02,s     record buffer pointer
                    ldd       $02,x     second word of record
                    pshs      d         push argument
                    ldd       ,x        first word of record
                    pshs      d         push argument
                    bsr       CmpRecType2 fetch inline constant pointer
                    fcb       $62
                    fcb       $CD
                    fcb       $23
                    fcb       $87
CmpRecType2         puls      x         pointer to inline constant
                    lbsr      LongCmp   compare record type
                    beq       RefTypeOk types match
                    lbsr      ErrNotReloc report type mismatch
                    bra       ChkListEnd go check list end

RefTypeOk           ldb       $08,s     read flag byte
                    beq       ChkRefEntry flag not set
                    lbsr      ErrAsmErrors report duplicate record
                    bra       ChkListEnd go check list end

ChkRefEntry         ldd       $06,s     existing entry present
                    beq       ProcessRef none present
                    ldd       GlbVar0014 copy-only mode
                    beq       RefRedefine not copy mode
                    lbsr      ErrNoMainline report already defined
                    bra       ChkListEnd go check list end

RefRedefine         lbsr      ErrDualMainline report redefinition
                    bra       ChkListEnd go check list end

ProcessRef          ldd       #$0001    flag value one
                    pshs      d         push flag argument
                    leax      $04,s     local buffer pointer
                    pshs      x         push buffer argument
                    bsr       BuildSymNode build symbol node
                    leas      4,s        drop arguments
ChkListEnd          leax      >ListHeadAddress,y  list end pointer
                    cmpx      >ListHeadAddress,y  reached end of list
                    bne       RefReadNext not at end yet
                    leax      $1e,s     adjust stack for exit
                    bra       EarlyExit take early exit

RefReadNext         ldd       GlbVar0038 module handle
                    pshs      d         push module argument
                    ldd       #$0001    read one record
                    pshs      d         push count argument
                    ldd       #$001C    record byte size
                    pshs      d         push size argument
                    leax      $08,s     record buffer pointer
                    pshs      x         push buffer argument
                    lbsr      FRead     read next record
                    leas      8,s        drop read arguments
                    std       -$02,s    save read result
                    lbne      RefRecord got a record
                    ldd       ,s        loop index
                    addd      #$0001    increment index
RefTest             std       ,s        store loop index
                    ldd       ,s        reload index
                    cmpd      GlbVar000C compare against second count
                    lblt      RefLoop   loop for more references
                    bra       EmitDone  finished emitting

EarlyExit           leas      -$1e,x    restore stack from pointer
EmitDone            leas      30,s       drop the locals
                    puls      pc,u      return to caller

BuildSymNode        pshs      u         save caller frame pointer
                    ldd       #$FF8B    negative local frame size
                    lbsr      stkcheck  allocate the stack frame
                    leas      -41,s      reserve extra locals
                    ldd       GlbVar003C free node list head
                    bne       ReuseFreeNode reuse an existing node
                    ldd       #$0031    node size in bytes
                    pshs      d         push size argument
                    lbsr      AllocMem  allocate a new node
                    leas      2,s        drop argument
                    std       $27,s     save node pointer
                    bra       NodeAcquired skip free-list path

ReuseFreeNode       ldd       GlbVar003C free node list head
                    std       $27,s     use it as the node
                    ldx       $27,s     node pointer
                    ldd       NdLink,x     load next free node
                    std       GlbVar003C advance the free list
NodeAcquired        clra                clear high byte
                    clrb                clear low byte
                    ldx       $27,s     node pointer
                    std       NdHead,x     clear node symbol field
                    clra                clear high byte
                    clrb                clear low byte
                    ldx       $27,s     node pointer
                    std       $27,x     clear node link field
                    ldd       $27,s     node pointer
                    std       $1b,s     init buffer write pointer
                    ldd       #$0010    header byte count
                    bra       CopyByteTest enter copy test

CopyByteLoop        ldd       $23,s     next source byte
                    ldx       $1b,s     buffer write pointer
                    leax      $01,x     advance write pointer
                    stx       $1b,s     store write pointer
                    stb       -$01,x    write the byte
                    ldd       $21,s     remaining byte count
                    addd      #$FFFF    decrement count
CopyByteTest        std       $21,s     store remaining count
                    ldd       $21,s     reload count
                    ble       CopyDone  done copying header
                    ldd       GlbVar0038 current module handle
                    pshs      d         push module argument
                    lbsr      GetByte   read next byte
                    leas      2,s        drop argument
                    std       $23,s     save the byte
                    bne       CopyByteLoop loop to copy more
CopyDone            ldx       GlbVar0038 module handle
                    ldd       $06,x     load module attributes
                    clra                clear high byte
                    andb      #$20      test attribute bit
                    beq       StoreNodeName bit clear so skip
                    lbsr      ErrReadInput report attribute error
StoreNodeName       clra                clear high byte
                    clrb                clear low byte
                    stb       [$1b,s]   null terminate buffer
                    ldd       GlbVar0042 current section pointer
                    ldx       $27,s     node pointer
                    std       NdName,x     store section into node
                    ldd       #$0010    push length argument
                    pshs      d         node section name field
                    ldd       $2f,s     offset into name
                    addd      #$000C    push source argument
                    pshs      d         buffer destination address
                    ldd       $2b,s     offset into buffer
                    addd      #$0015    push destination argument
                    pshs      d         copy the section name
                    lbsr      BlockCopy copy or compare name
                    leas      6,s        drop arguments
                    ldd       GlbVar0038 current module handle
                    pshs      d         push module argument
                    lbsr      ReadWord  read symbol count word
                    leas      2,s        drop argument
                    std       $1f,s     save symbol count
                    bra       ReadRelLoop enter symbol loop test

SymbolLoop          lbsr      AllocNode read next symbol
                    std       $25,s     save new symbol node
                    ldx       $27,s     parent node pointer
                    ldd       NdHead,x     current child list head
                    ldx       $25,s     new symbol pointer
                    std       NdNext,x     link old head after new
                    ldd       $25,s     new symbol pointer
                    ldx       $27,s     parent node pointer
                    std       NdHead,x     update child list head
                    ldd       $25,s     new symbol pointer
                    pshs      d         push symbol argument
                    lbsr      ReadSymName insert into hash table
                    leas      2,s        drop pushed argument
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      GetByte   read relocation word
                    leas      2,s        drop argument
                    ldx       $25,s     point to current entry
                    std       $0a,x     store first reloc field
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      ReadWord  read next word
                    leas      2,s        drop argument
                    ldx       $25,s     point to current entry
                    std       $0C,x     store second reloc field
ReadRelLoop         ldd       $1f,s     load loop counter
                    addd      #$FFFF    decrement counter
                    std       $1f,s     save counter
                    subd      #$FFFF    test for zero
                    bne       SymbolLoop loop while entries remain
                    ldd       $2f,s     load flag argument
                    lbeq      MergeSection skip merge when zero
                    ldx       $27,s     point to module record
                    ldd       NdHead,x     load symbol list head
                    bra       FindSymNext enter search loop

FindSymLoop         ldd       #$0001    push mode flag one
                    pshs      d         pass flag
                    ldd       $27,s     load module record
                    pshs      d         pass module record
                    lbsr      FindSym   look up symbol
                    leas      4,s        drop two arguments
                    std       -$02,s    save match result
                    bne       FindSymDone stop when match found
                    ldx       $25,s     point to current entry
                    ldd       NdNext,x     load next entry link
FindSymNext         std       $25,s     set current entry
                    ldd       $25,s     reload current entry
                    bne       FindSymLoop continue while entries remain
FindSymDone         ldd       $25,s     load found entry
                    bne       MergeSection merge into existing entry
                    leas      -2,s       reserve local
                    ldx       $29,s     point to source record
                    ldd       NdHead,x     load symbol name pointer
                    pshs      d         pass name pointer
                    lbsr      FindListTail allocate new entry
                    leas      2,s        drop argument
                    std       ,s        save new entry pointer
                    ldd       GlbVar0001 load list head at $0001
                    ldx       ,s        point to new entry
                    std       NdNext,x     link previous head
                    ldx       $29,s     point to source record
                    ldd       NdNext,x     load source next link
                    std       GlbVar0001 update list head
                    ldd       $29,s     load source record
                    pshs      d         pass source record
                    lbsr      WriteModBlock copy record fields
                    leas      2,s        drop argument
                    lbsr      WriteDataSections finalize copy
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      ReadWord  read next word
                    std       ,s        save word
                    lbsr      WriteDataBlock process word
                    leas      2,s        drop argument
                    ldd       GlbVar003C load previous tail link
                    ldx       $29,s     point to source record
                    std       NdLink,x     store link field
                    ldd       $29,s     load source record
                    std       GlbVar003C update list tail
                    leas      43,s       release frame
                    puls      pc,u      return

MergeSection        ldx       $27,s     point to module record
                    ldd       NdHead,x     load symbol list head
                    bra       DupSymJoin enter duplicate scan

DupSymLoop          ldd       $25,s     load current symbol
                    pshs      d         pass symbol
                    lbsr      InsertSym look up global symbol
                    std       ,s++      save result and drop
                    beq       DupSymNext skip when not duplicate
                    ldd       $27,s     load module record
                    pshs      d         pass module record
                    ldd       $27,s     load module record
                    pshs      d         pass again
                    leax      MsgSymRedefined,pcr point to duplicate message
                    pshs      x         pass message
                    leax      NameBuf,y point to name buffer
                    pshs      x         pass buffer
                    lbsr      Sprintf   print error message
                    leas      8,s        drop four arguments
                    ldd       GlbVar0044 load error count
                    addd      #$0001    bump error count
                    std       GlbVar0044 save error count
DupSymNext          ldx       $25,s     point to current symbol
                    ldd       NdNext,x     load next symbol link
DupSymJoin          std       $25,s     set current symbol
                    ldd       $25,s     reload current symbol
                    bne       DupSymLoop continue scanning symbols
                    ldd       GlbVar0040 load list tail pointer
                    bne       AppendRecord append when list nonempty
                    ldd       $27,s     load module record
                    std       GlbVar0040 set list head
                    std       GlbListHead set list root
                    bra       LinkDone  continue

AppendRecord        ldd       $27,s     load module record
                    ldx       GlbVar0040 point to list tail
                    std       NdLink,x     link new record
                    std       GlbVar0040 update list tail
LinkDone            ldx       $27,s     point to module record
                    leax      $29,x     point to symbol subfield
                    pshs      x         pass pointer
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      FileTell  read symbol block
                    leas      2,s        drop argument
                    lbsr      LongStore process symbols
                    ldd       $27,s     load module record
                    pshs      d         pass module record
                    lbsr      WriteModBlock copy record fields
                    leas      2,s        drop argument
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      ReadWord  read next word
                    leas      2,s        drop argument
                    std       $1f,s     save relocation count
                    lbra      RelocLoopNext enter relocation loop

RelocLoop2          leax      $01,s     point to local buffer
                    pshs      x         pass buffer
                    lbsr      ReadSymName read relocation entry
                    leas      2,s        drop argument
                    leax      $01,s     point to first field
                    pshs      x         pass field pointer
                    leax      $03,s     point to second field
                    pshs      x         pass field pointer
                    lbsr      HashName  build symbol key
                    std       ,s        save key
                    lbsr      LookupSym look up symbol
                    leas      4,s        drop two arguments
                    std       $25,s     save symbol pointer
                    beq       NewSymEntry create entry when absent
                    ldx       $25,s     point to symbol
                    ldd       $0a,x     load flag word
                    ora       #$01      mark referenced
                    std       $0a,x     save flags
                    bra       ApplyReloc2 apply relocation

NewSymEntry         leas      -2,s       reserve local
                    leax      $03,s     point to key field
                    pshs      x         pass key
                    lbsr      InternSym hash symbol name
                    leas      2,s        drop argument
                    std       ,s        save hash
                    leax      $03,s     point to key field
                    pshs      x         pass key
                    ldd       $02,s     load hash value
                    addd      #$0004    offset to bucket
                    pshs      d         pass bucket
                    lbsr      strcpy    insert symbol entry
                    leas      4,s        drop two arguments
                    ldd       $29,s     load new entry
                    ldx       ,s        point to previous head
                    std       NdNext,x     link entry
                    leas      2,s        release local
ApplyReloc2         ldx       $27,s     point to module record
                    ldd       $27,x     load section base
                    leax      $27,x     point to base field
                    pshs      x,d       pass base and pointer
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      ReadWord  read reloc offset
                    std       ,s        save offset
                    lbsr      CountRecords resolve address
                    leas      2,s        drop argument
                    addd      ,s++      add section base
                    std       [,s++]    store into target
RelocLoopNext       ldd       $1f,s     load loop counter
                    addd      #$FFFF    decrement counter
                    std       $1f,s     save counter
                    subd      #$FFFF    test for zero
                    lbne      RelocLoop2 loop while entries remain
                    ldd       GlbVar0038 load module handle
                    pshs      d         pass module handle
                    lbsr      ReadWord  read next word
                    leas      2,s        drop argument
                    std       $1f,s     save second reloc count
                    ldx       GlbVar0038 point to module handle
                    ldd       $06,x     load module attributes
                    clra                keep low byte
                    andb      #$20      test data flag
                    beq       ClearRelocNext skip when clear
                    lbsr      ErrReadInput process data section
                    bra       ClearRelocNext continue

ClearRelocLoop      ldx       $27,s     point to module record
                    ldd       $27,x     load section base
                    leax      $27,x     point to base field
                    pshs      x,d       pass base and pointer
                    ldd       #$0001    push mode flag
                    pshs      d         pass flag
                    lbsr      CountRecords resolve address
                    leas      2,s        drop argument
                    addd      ,s++      add section base
                    std       [,s++]    store into target
ClearRelocNext      ldd       $1f,s     load loop counter
                    addd      #$FFFF    decrement counter
                    std       $1f,s     save counter
                    subd      #$FFFF    test for zero
                    bne       ClearRelocLoop loop while entries remain
                    leas      41,s       release frame
                    puls      pc,u      return

ComputeSectionSizes pshs      u         save frame pointer
                    ldd       #$FFB6    frame size seventy four bytes
                    lbsr      stkcheck  allocate stack frame
                    leas      -2,s       reserve local
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0034 reset max size
                    ldd       GlbListHead load module list head
                    lbra      SumModLoop enter module loop

SumModEnter         ldx       ,s        point to current module
                    ldu       NdHead,x     load section list head
                    lbra      SumSectTest enter section loop

SumSectLoop         ldd       $0a,u     load section flags
                    anda      #$01      test included flag
                    clrb                clear low byte
                    std       -$02,s    save flag
                    lbeq      SumSectNext skip excluded section
                    ldx       ,s        point to current module
                    ldd       NdMFlags,x     load module flags
                    ora       #$01      mark module used
                    std       NdMFlags,x     save module flags
                    ldd       GlbVar001E load text accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $17,x     load section text size
                    addd      ,s++      add accumulator
                    std       GlbVar001E update text total
                    ldd       GlbDpDataSize load data accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $19,x     load section data size
                    addd      ,s++      add accumulator
                    std       GlbDpDataSize update data total
                    ldd       GlbInitDataSize load bss accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $1b,x     load section bss size
                    addd      ,s++      add accumulator
                    std       GlbInitDataSize update bss total
                    ldd       GlbVar002A load size accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $1d,x     load section size field
                    addd      ,s++      add accumulator
                    std       GlbVar002A update total
                    ldd       GlbMemSize load size accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $21,x     load section size field
                    addd      ,s++      add accumulator
                    std       GlbMemSize update total
                    ldd       GlbVar002E load size accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $1f,x     load section size field
                    addd      ,s++      add accumulator
                    std       GlbVar002E update total
                    ldd       GlbVar0036 load size accumulator
                    pshs      d         save accumulator
                    ldx       $02,s     point to section
                    ldd       $27,x     load section size field
                    addd      ,s++      add accumulator
                    std       GlbVar0036 update total
                    ldx       ,s        point to current module
                    ldd       $1f,x     load section start
                    ldx       ,s        point to current module
                    addd      $1b,x     add section length
                    cmpd      GlbVar0034 compare against max
                    bls       SumModNext keep existing max
                    ldx       ,s        point to current module
                    ldd       $1f,x     load section start
                    ldx       ,s        point to current module
                    addd      $1b,x     add section length
                    std       GlbVar0034 update max size
                    bra       SumModNext advance module

SumSectNext         ldu       NdNext,u     load next section
SumSectTest         stu       -$02,s    save section pointer
                    lbne      SumSectLoop loop while sections remain
SumModNext          ldx       ,s        point to current module
                    ldd       NdLink,x     load next module link
SumModLoop          std       ,s        set current module
                    ldd       ,s        reload current module
                    lbne      SumModEnter loop while modules remain
                    ldd       >SectNameTab,y load text symbol name
                    pshs      d         pass name
                    ldd       >SectNameTab,y load name again
                    pshs      d         pass name
                    lbsr      HashName  build symbol key
                    std       ,s        save key
                    lbsr      LookupSym look up symbol
                    leas      4,s        drop two arguments
                    tfr       d,u       move symbol to u
                    stu       -$02,s    save symbol pointer
                    beq       SetDataSym skip when absent
                    ldd       GlbVar002E load computed size
                    std       $0C,u     set symbol value
SetDataSym          ldd       >SectionListField,y  load data symbol name
                    pshs      d         pass name
                    ldd       >SectionListField,y  load name again
                    pshs      d         pass name
                    lbsr      HashName  build symbol key
                    std       ,s        save key
                    lbsr      LookupSym look up symbol
                    leas      4,s        drop two arguments
                    tfr       d,u       move symbol to u
                    stu       -$02,s    save symbol pointer
                    beq       SetBssSym skip when absent
                    ldd       GlbInitDataSize load computed size
                    std       $0C,u     set symbol value
SetBssSym           ldd       >SectionListField2,y  load bss symbol name
                    pshs      d         pass name
                    ldd       >SectionListField2,y  load name again
                    pshs      d         pass name
                    lbsr      HashName  build symbol key
                    std       ,s        save key
                    lbsr      LookupSym look up symbol
                    leas      4,s        drop two arguments
                    tfr       d,u       move symbol to u
                    stu       -$02,s    save symbol pointer
                    beq       SetLastSym skip when absent
                    ldd       GlbVar001E load computed size
                    std       $0C,u     set symbol value
SetLastSym          ldd       >SectionListField3,y  load fourth symbol name
                    pshs      d         pass name
                    ldd       >SectionListField3,y  load name again
                    pshs      d         pass name
                    lbsr      HashName  build symbol key
                    std       ,s        save key
                    lbsr      LookupSym look up symbol
                    leas      4,s        drop two arguments
                    tfr       d,u       move symbol to u
                    stu       -$02,s    save symbol pointer
                    beq       SizesDone skip when absent
                    ldd       GlbDpDataSize load computed size
                    std       $0C,u     set symbol value
SizesDone           puls      pc,u,x    return

ApplySectionBase    pshs      u         save frame pointer
                    ldd       #$FFB1    frame size seventy nine bytes
                    lbsr      stkcheck  allocate stack frame
                    leas      -5,s       reserve locals
                    lbsr      ComputeSectionAddrs initialize section bases
                    ldd       GlbListHead load module list head
                    lbra      ModuleLoop enter module loop

RelocModLoop        ldx       $03,s     point to current module
                    ldd       NdMFlags,x     load module flags
                    anda      #$01      test used flag
                    clrb                clear low byte
                    std       -$02,s    save flag
                    lbeq      NextModule skip unused module
                    ldx       $03,s     point to current module
                    ldu       NdHead,x     load section list head
                    lbra      EntryLoop enter section loop

SelectSectionBase   ldd       $0a,u     load section flags
                    clra                keep low byte
                    andb      #$07      mask section type
                    tfr       d,x       index by type
                    bra       TypeSwitch dispatch on type

AddBaseText         ldd       $0C,u     load section offset
                    addd      GlbVar001C add text base
                    bra       StoreBase store adjusted offset

AddBaseData         ldd       $0C,u     load section offset
                    addd      GlbVar0024 add data base
                    bra       StoreBase store adjusted offset

AddBaseBss          ldd       $0C,u     load section offset
                    addd      GlbVar0020 add bss base
                    bra       StoreBase store adjusted offset

AddBaseFour         ldd       $0C,u     load section offset
                    addd      GlbVar0028 add fourth base
                    bra       StoreBase store adjusted offset

AddBaseFive         ldd       $0C,u     load section offset
                    addd      GlbVar002C add fifth base
StoreBase           std       $0C,u     store adjusted offset
                    bra       NextEntry advance section

RelocEntryLoop      ldx       $03,s     point to current module
                    ldd       NdName,x     load relocation list
                    pshs      d         pass relocation list
                    ldd       $05,s     load argument
                    pshs      d         pass argument
                    leax      MsgUnknownEntryType,pcr point to unknown entry type message
                    pshs      x         push format pointer
                    lbsr      PrintErrMsg print the error message
                    leas      6,s        drop the printf arguments
                    bra       NextEntry continue to next entry

TypeSwitch          stx       -$02,s    save entry type for testing
                    beq       AddBaseText type zero handler
                    cmpx      #$0001    type one
                    beq       AddBaseData type one handler
                    cmpx      #$0002    type two
                    beq       AddBaseBss type two handler
                    cmpx      #$0003    type three
                    beq       AddBaseFour type three handler
                    cmpx      #$0004    type four
                    beq       AddBaseFive type four handler
                    bra       RelocEntryLoop unknown entry type

NextEntry           ldu       NdNext,u     follow link to next entry
EntryLoop           stu       -$02,s    test the entry pointer
                    lbne      SelectSectionBase loop while entries remain
                    ldd       GlbVar001C accumulate text size total
                    pshs      d         push running total
                    ldx       $05,s     module pointer
                    ldd       $17,x     module text size
                    addd      ,s++      add and pop
                    std       GlbVar001C update total text size
                    ldd       GlbVar0024 accumulate data size total
                    pshs      d         push running total
                    ldx       $05,s     module pointer
                    ldd       $1b,x     module data size
                    addd      ,s++      add and pop
                    std       GlbVar0024 update total data size
                    ldd       GlbVar0020 accumulate section size total
                    pshs      d         push running total
                    ldx       $05,s     module pointer
                    ldd       $19,x     module section size
                    addd      ,s++      add and pop
                    std       GlbVar0020 update total section size
                    ldd       GlbVar0028 accumulate bss size total
                    pshs      d         push running total
                    ldx       $05,s     module pointer
                    ldd       $1d,x     module bss size
                    addd      ,s++      add and pop
                    std       GlbVar0028 update total bss size
                    ldd       GlbVar002C accumulate dp size total
                    pshs      d         push running total
                    ldx       $05,s     module pointer
                    ldd       $1f,x     module dp size
                    addd      ,s++      add and pop
                    std       GlbVar002C update total dp size
NextModule          ldx       $03,s     current module pointer
                    ldd       NdLink,x     next module link
ModuleLoop          std       $03,s     advance the module pointer
                    ldd       $03,s     test the module pointer
                    lbne      RelocModLoop loop while modules remain
                    ldd       >OutputNameField,y  get output name field
                    pshs      d         push argument
                    ldd       >OutputNameField,y  get output name field
                    pshs      d         push argument
                    lbsr      HashName  read helper
                    std       ,s        store result argument
                    lbsr      LookupSym lookup helper
                    leas      4,s        drop arguments
                    tfr       d,u       result pointer
                    stu       -$02,s    test the result
                    beq       DoLayout  skip clear if null
                    clra                clear high byte
                    clrb                clear low byte
                    std       $0C,u     zero the field
DoLayout            bsr       ComputeSectionAddrs compute section addresses
                    lbra      ScanDone  return through scan exit

ComputeSectionAddrs pshs      u         save frame pointer
                    ldd       #$FFC0
                    lbsr      stkcheck  reserve stack frame
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0028 zero the bss origin
                    ldd       GlbVar0028 load bss origin
                    addd      GlbVar002A add bss size
                    std       GlbVar0020 data origin
                    ldd       GlbVar0020 load data origin
                    addd      GlbDpDataSize add data size
                    std       GlbVar0024 text origin
                    ldd       GlbVar0024 load text origin
                    addd      GlbInitDataSize add text size
                    std       GlbVar001C overall end address
                    ldd       GlbOutPath load module base
                    addd      #$000E    add header size
                    std       GlbVar002C dp origin
                    puls      pc,u      return

AddSymbol           pshs      u         save frame pointer
                    ldd       #$FFB4
                    lbsr      stkcheck  reserve stack frame
                    leas      -2,s       local node slot
                    bsr       AllocNode allocate a node
                    std       ,s        save the new node
                    ldx       $06,s     parent record
                    ldd       NdHead,x     current list head
                    ldx       ,s        new node
                    std       NdNext,x     link old head into node
                    ldd       ,s        new node pointer
                    ldx       $06,s     parent record
                    std       NdHead,x     set node as new head
                    ldd       #$0009    copy nine bytes
                    pshs      d         push length
                    ldd       $0a,s     source pointer
                    pshs      d         push source
                    ldd       $04,s     destination node
                    pshs      d         push destination
                    lbsr      strncpy   copy the bytes
                    leas      6,s        drop arguments
                    ldd       $0a,s     value argument
                    ldx       ,s        node pointer
                    std       $0a,x     store value in node
                    ldd       ,s        name pointer
                    pshs      d         push name
                    lbsr      InsertSym register the name
                    leas      2,s        drop argument
                    puls      pc,u,x    return the node

AllocNode           pshs      u         save frame pointer
                    ldd       #$FFBA
                    lbsr      stkcheck  reserve stack frame
                    ldd       GlbVar0001 free list head
                    bne       ReuseFreed reuse a freed node
                    ldd       #$0012    node size
                    pshs      d         push size
                    lbsr      AllocMem  allocate eighteen bytes
                    leas      2,s        drop argument
                    tfr       d,u       new node
                    bra       ReturnNode return the node

ReuseFreed          ldu       GlbVar0001 pop the free list
                    ldd       NdNext,u     next free node
                    std       GlbVar0001 update free head
ReturnNode          tfr       u,d       return node pointer
                    puls      pc,u      return

WriteModBlock       pshs      u         save frame pointer
                    ldd       #$FFB4
                    lbsr      stkcheck  reserve stack frame
                    ldd       #$0001    write count one
                    pshs      d         push count
                    ldx       $06,s     module record
                    ldd       $1f,x     dp size
                    ldx       $06,s     module record
                    addd      $1d,x     plus bss size
                    ldx       $06,s     module record
                    addd      $1b,x     plus data size
                    bra       WriteBuffer write the block

WriteDataBlock      pshs      u         save frame pointer
                    ldd       #$FFB4
                    lbsr      stkcheck  reserve stack frame
                    ldd       #$0001    write count one
                    pshs      d         push count
                    ldd       $06,s     byte value
                    pshs      d         push value
                    ldd       #$0003    pattern size
                    lbsr      MulEntry  build fill buffer
WriteBuffer         lbsr      UIntToLong get buffer descriptor
                    ldd       $02,x     buffer length
                    pshs      d         push length
                    ldd       ,x        buffer address
                    pshs      d         push address
                    ldd       GlbVar0038 output file path
                    pshs      d         push path
                    lbsr      Fseek     write to output file
                    leas      8,s        drop arguments
                    puls      pc,u      return

WriteDataSections   pshs      u         save frame pointer
                    ldd       #$FFAE
                    lbsr      stkcheck  reserve stack frame
                    leas      -12,s      local buffer
                    ldd       GlbVar0038 output file path
                    pshs      d         push path
                    lbsr      ReadWord  read block count
                    leas      2,s        drop argument
                    std       ,s        save remaining count
                    bra       WriteSectionTest enter loop test

WriteSectionLoop    leax      $02,s     record buffer
                    pshs      x         push buffer
                    lbsr      ReadSymName read one record
                    leas      2,s        drop argument
                    ldd       GlbVar0038 output file path
                    pshs      d         push path
                    lbsr      ReadWord  read block length
                    std       ,s        save length
                    lbsr      WriteDataBlock write the block
                    leas      2,s        drop argument
WriteSectionTest    ldd       ,s        remaining block count
                    addd      #$FFFF    decrement
                    std       ,s        store count
                    subd      #$FFFF    restore for test
                    bne       WriteSectionLoop loop while blocks remain
                    leas      12,s       drop local buffer
                    puls      pc,u      return

CountRecords        pshs      u         save frame pointer
                    ldd       #$FFAF
                    lbsr      stkcheck  reserve stack frame
                    ldu       $04,s     record count
                    leas      -5,s       local record buffer
                    clra                clear high byte
                    clrb                clear low byte
                    bra       StoreCount init count to zero

CountLoop           ldd       GlbVar0038 output file path
                    pshs      d         push path
                    ldd       #$0001    element size one
                    pshs      d         push size
                    ldd       #$0003    count three
                    pshs      d         push count
                    leax      $06,s     record buffer
                    pshs      x         push buffer
                    lbsr      FRead     read a record
                    leas      8,s        drop arguments
                    std       -$02,s    test read result
                    bne       ReadByteOk read succeeded
                    lbsr      ErrReadInput report read error
ReadByteOk          ldb       ,s        record flag byte
                    clra                clear high byte
                    andb      #$30      isolate type bits
                    cmpd      #$0020    check type value
                    beq       NextRecord skip counting common type
                    ldd       $03,s     current count
                    addd      #$0001    increment count
StoreCount          std       $03,s     store the count
NextRecord          tfr       u,d       remaining records
                    leau      -$01,u    decrement
                    std       -$02,s    test remaining
                    bne       CountLoop loop over records
                    ldd       $03,s     return the count
ScanDone            leas      5,s        unwind local frame
                    puls      pc,u      return

FindListTail        pshs      u         save frame pointer
                    ldd       #$FFBE
                    lbsr      stkcheck  reserve stack frame
                    ldu       $04,s     list head
                    leas      -2,s       local slot
                    stu       ,s        save current node
                    stu       ,s        seed result pointer
                    bra       TailTest  enter loop test

TailAdvance         stu       ,s        remember non-null node
                    ldu       NdNext,u     follow link
TailTest            stu       -$02,s    test node pointer
                    bne       TailAdvance loop to end of list
                    ldd       ,s        return last node
                    puls      pc,u,x    return

EmitNameRec         pshs      u         save frame pointer
                    ldd       #$FFB6
                    lbsr      stkcheck  reserve stack frame
                    ldd       $06,s     format argument
                    pshs      d         push argument
                    ldd       $06,s     format argument
                    pshs      d         push argument
                    leax      NameBuf,y scratch buffer
                    pshs      x         push buffer
                    lbsr      Sprintf   format the message
                    leas      6,s        drop arguments
                    leax      NameBuf,y formatted string
                    pshs      x         push string
                    ldd       #$000D    line length
                    pshs      d         push length
                    lbsr      PutByte   write formatted line
                    leas      4,s        drop arguments
                    leax      MsgBasic09Conflict,pcr point to conflict message
                    pshs      x         push message
                    lbsr      PrintErrMsg print the message
                    puls      pc,u,x    return

ErrNoMainline       pshs      u         save frame pointer
                    ldd       #$FFBA
                    lbsr      stkcheck  reserve stack frame
                    leax      MsgNoMainlineAllowed,pcr no mainline allowed message
                    pshs      x         push message
                    bsr       EmitNameRec emit the message
                    puls      pc,u,x    return

ErrCantOpen         pshs      u         save frame pointer
                    ldd       #$FFB8
                    lbsr      stkcheck  reserve stack frame
                    ldd       GlbVar0042 module name pointer
                    pshs      d         push name
                    leax      MsgCantOpen,pcr cannot open message
                    lbra      PrintErrExit print and return

ErrNotReloc         pshs      u         save frame pointer
                    ldd       #$FFB8
                    lbsr      stkcheck  reserve stack frame
                    ldd       GlbVar0042 module name pointer
                    pshs      d         push name
                    leax      MsgNotReloc,pcr not relocatable message
                    bra       PrintErrExit print and return

ErrAsmErrors        pshs      u         save frame pointer
                    ldd       #$FFB8
                    lbsr      stkcheck  reserve stack frame
                    ldd       GlbVar0042 module name pointer
                    pshs      d         push name
                    leax      MsgAsmErrors,pcr assembly errors message
                    bra       PrintErrExit print and return

ErrDualMainline     pshs      u         save frame pointer
                    ldd       #$FFB6
                    lbsr      stkcheck  reserve stack frame
                    ldd       GlbVar0042 module name pointer
                    pshs      d         push name
                    ldx       GlbListHead current module
                    ldd       NdName,x     module name field
                    pshs      d         push name
                    leax      MsgMainlineDup,pcr mainline in both message
                    pshs      x         push message
                    lbsr      PrintErrMsg print the error
                    leas      6,s        drop arguments
                    puls      pc,u      return

ErrReadInput        pshs      u         save frame pointer
                    ldd       #$FFB8
                    lbsr      stkcheck  reserve stack frame
                    ldd       GlbVar0042 module name pointer
                    pshs      d         push name
                    leax      MsgErrReadInput,pcr error reading input message
PrintErrExit        pshs      x         push message pointer
                    lbsr      PrintErrMsg print the error
                    leas      4,s        drop arguments
                    puls      pc,u      return

BaseName            pshs      u         save frame pointer
                    ldd       #$FFBE
                    lbsr      stkcheck  reserve stack frame
                    ldu       $04,s     path string pointer
                    leas      -2,s       local slot
                    stu       ,s        default to string start
                    bra       BaseNameLoop enter scan loop

BaseNameCheck       ldb       ,u        current character
                    cmpb      #$2f      is it a slash
                    bne       BaseNameNext not a slash
                    leax      $01,u     point past the slash
                    stx       ,s        remember basename start
BaseNameNext        leau      $01,u     advance the pointer
BaseNameLoop        ldb       ,u        next character
                    bne       BaseNameCheck loop until end of string
                    ldd       ,s        return basename pointer
                    puls      pc,u,x    return

SymEtext            fcc       /etext/
                    fcb       C$NULL
SymEdata            fcc       /edata/
                    fcb       C$NULL
SymEnd              fcb       $65,$6E,$64
                    fcb       C$NULL
SymDpsiz            fcc       /dpsiz/
                    fcb       C$NULL
SymBtext            fcc       /btext/
                    fcb       C$NULL
MsgLibSpecErr       fcc       /error specifying library: -l%s/
                    fcb       C$CR,C$NULL
MsgModSpecErr       fcc       /error specifying %s -M%s/
                    fcb       C$CR,C$NULL
MsgMemSize          fcc       /memory size:/
                    fcb       C$NULL
MsgUnknownOpt       fcc       /unknown option -%c/
                    fcb       C$NULL
MsgTooManySrc       fcc       /too many source files/
                    fcb       C$NULL
MsgUnresolved       fcc       /unresolved references/
                    fcb       C$NULL
MsgNoInitData       fcc       /no init data allowed/
                    fcb       C$NULL
MsgNoDpData         fcc       /no dp data allowed/
                    fcb       C$NULL
MsgNoStaticData     fcc       /no static data/
                    fcb       C$NULL
MsgDpAlloc          fcc       /direct page allocation is %u bytes/
                    fcb       C$NULL
MsgNameClash        fcc       /name clash/
                    fcb       C$NULL
MsgNoOutFile        fcc       /no output file/
                    fcb       C$NULL
MsgNoEntryName      fcc       /no entry point name/
                    fcb       C$NULL
MsgEntryNotFound    fcc       /entry point '%s' not found/
                    fcb       C$NULL
MsgReadMode         fcb       $72
                    fcb       C$NULL
MsgNoMainline       fcc       /'%s' contains no mainline/
                    fcb       C$NULL
MsgReadMode2        fcb       $72
                    fcb       C$NULL
MsgSymRedefined     fcc       /symbol already defined: %-8s in %s/
                    fcb       C$CR,C$NULL
MsgUnknownEntryType fcc       /unknown entry type in %s:%s/
                    fcb       C$NULL
MsgBasic09Conflict  fcc       /BASIC09 conflict/
                    fcb       C$NULL
MsgNoMainlineAllowed fcc       /no mainline allowed/
                    fcb       C$NULL
MsgCantOpen         fcc       /can't open '%s'/
                    fcb       C$NULL
MsgNotReloc         fcc       /'%s' is not a relocatable module/
                    fcb       C$NULL
MsgAsmErrors        fcc       /'%s' contains assembly errors/
                    fcb       C$NULL
MsgMainlineDup      fcc       /mainline found in both %s and %s/
                    fcb       C$NULL
MsgErrReadInput     fcc       /error reading input file %s/
                    fcb       C$NULL
WriteOutModule      pshs      u         save u across module write
                    ldd       #$FFA5    buffer size to allocate
                    lbsr      stkcheck  allocate work buffer
                    leas      -15,s      reserve local header frame
                    ldd       GlbVar0034 load current pointer global
                    std       GlbVar0046 save it
                    pshs      d         pass as argument
                    lbsr      AllocMem  call helper
                    leas      2,s        drop argument
                    std       GlbVar0048 save returned pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar0046 clear pointer global
                    ldd       #$87CD    OS-9 module sync bytes
                    std       $02,s     store header sync word
                    ldd       GlbOutPath load code size
                    addd      GlbVar0036 add relocation size
                    aslb                shift low byte
                    rola                shift into high byte to double
                    addd      #$000D    add header length
                    addd      GlbVar002E add exec section size
                    addd      GlbInitDataSize add data size
                    addd      GlbVar002A add symbol area size
                    addd      #$000D    add name and trailer length
                    std       $04,s     store total module size
                    ldd       #$000D    header/name offset
                    std       $06,s     store name offset field
                    ldd       GlbVar0018 load module type and language
                    pshs      d         pass argument
                    ldd       #$0008    field width argument
                    lbsr      AsrEntry  compute type/language byte
                    stb       $08,s     store type/language field
                    ldd       GlbVar0018 reload module type
                    clra                clear high byte
                    stb       $09,s     store attribute/revision field
                    ldd       #$0008    length argument
                    pshs      d         pass argument
                    leax      $04,s     point at header for parity
                    pshs      x         pass header pointer
                    lbsr      XorChecksum compute header parity
                    leas      4,s        drop arguments
                    stb       $0a,s     store header parity byte
                    ldd       GlbVar0014 check copy-data flag
                    beq       NoCopyExecOff branch if not copying bytes
                    ldd       GlbVar0030 use data-section size
                    bra       StoreExecOff join header store

NoCopyExecOff       ldx       GlbListHead point at module record
                    ldd       NdExec,x     load exec offset field
                    addd      GlbVar002C add relocation offset
StoreExecOff        std       $0b,s     store exec offset in header
                    ldd       GlbVar002A load data size
                    addd      GlbDpDataSize add symbol size
                    addd      GlbInitDataSize add data size
                    addd      GlbVar001E add bss size
                    addd      GlbMemSize add stack size
                    std       $0d,s     store storage/data-size field
                    leax      MsgModeWxp,pcr point at file mode string
                    pshs      x         pass mode
                    ldd       OutputFileName,y   output filename pointer
                    pshs      d         pass filename
                    lbsr      WalkExprNode open/create output file
                    leas      4,s        drop arguments
                    std       GlbVar003A save output file handle
                    bne       OpenedOk  branch if opened ok
                    bra       ReportOpenErr go report open failure

WriteErr            leas      -$0f,x    adjust frame on write error
ReportOpenErr       leax      MsgCantCreateOut,pcr point at error message
                    pshs      x         pass message
                    lbsr      PrintErrMsg print fatal error and exit
                    leas      2,s        drop argument
OpenedOk            ldd       #$0200    stream buffer size flag
                    ldx       GlbVar003A load file handle
                    std       $0b,x     set stream buffering
                    ldd       $04,s     load module size
                    pshs      d         pass size
                    ldx       GlbVar003A reload file handle
                    ldd       $08,x     load stream buffer pointer
                    pshs      d         pass buffer pointer
                    lbsr      SetFileSize write header bytes
                    leas      4,s        drop arguments
                    std       -$02,s    save write result
                    beq       WriteModHeader branch if write ok
                    leax      $0f,s     point at frame for error
                    bra       WriteErr  report write error

WriteModHeader      leax      >Buffer,y  point at module name buffer
                    pshs      x         pass destination
                    ldd       #$000D    copy length
                    pshs      d         pass length
                    leax      $06,s     point at header source
                    pshs      x         pass source
                    lbsr      CalcCrc   copy header into buffer
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       #$0001    record count
                    pshs      d         pass count
                    ldd       #$000D    header length
                    pshs      d         pass length
                    leax      $08,s     point at buffer
                    pshs      x         pass buffer
                    lbsr      FWrite    write header to file
                    leas      8,s        drop arguments
                    lbsr      ErrWriteFile check for write error
                    ldd       NamePointer,y   load module name pointer
                    std       ,s        save pointer
NameEndLoop         ldx       ,s        load name pointer
                    leax      $01,x     advance one character
                    stx       ,s        store back
                    ldb       -$01,x    read current character
                    bne       NameEndLoop loop until null terminator
                    ldd       ,s        get end pointer
                    subd      #$0002    back up to last character
                    std       ,s        store pointer
                    ldb       [,s]      load last name character
                    sex                 sign extend
                    orb       #$80      set high bit end marker
                    stb       [,s]      store terminated character
                    leax      >Buffer,y  point at name buffer
                    pshs      x         pass destination
                    ldd       GlbOutPath load code size offset
                    pshs      d         pass length
                    ldd       NamePointer,y   load name pointer
                    pshs      d         pass source
                    lbsr      CalcCrc   copy name into buffer
                    leas      6,s        drop arguments
                    ldd       NamePointer,y   load name pointer
                    pshs      d         pass length
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    lbsr      Sprintf   write name to file
                    leas      4,s        drop arguments
                    lbsr      ErrWriteFile check for write error
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       #$0001    single byte length
                    pshs      d         pass length
                    leax      EditionNumber,y   point at trailer byte
                    pshs      x         pass source
                    lbsr      CalcCrc   copy one byte
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldb       EditionNumber,y   load trailer byte
                    sex                 sign extend
                    pshs      d         pass byte
                    lbsr      PutByte   write byte to file
                    leas      4,s        drop arguments
                    ldb       [,s]      reload written byte
                    clra                clear high byte
                    andb      #$7f      clear high bit
                    stb       [,s]      store cleaned byte
                    ldd       GlbVar0036 load relocation size
                    pshs      d         pass size
                    lbsr      SeekChunk call helper
                    leas      2,s        drop argument
                    leax      OutputNameField2,y   point at offset record
                    pshs      x         pass record
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    lbsr      FileTell  write offset record
                    leas      2,s        drop argument
                    lbsr      LongStore call helper
                    leax      LongVariable,y   point at long variable
                    pshs      x         pass destination
                    leax      OutputNameField2,y   point at source long
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    ldd       GlbVar002E load exec section size
                    lbsr      UIntToLong compute 32-bit value
                    lbsr      LongAdd   call helper
                    lbsr      LongStore call helper
                    leax      SecondNameField,y   point at long variable
                    pshs      x         pass destination
                    leax      LongVariable,y   point at source long
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    bsr       AfterLongLitA call past inline long constant
                    fcb       $00,$00,$00,$02
AfterLongLitA       puls      x         get pointer to inline constant
                    lbsr      LongAdd   call helper
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    ldd       GlbVar002A load data size
                    lbsr      UIntToLong compute 32-bit value
                    lbsr      LongAdd   call helper
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    bsr       AfterLongLitB call past inline long constant
                    fcb       $00,$00,$00,$02
AfterLongLitB       puls      x         get pointer to inline constant
                    lbsr      LongAdd   call helper
                    lbsr      LongStore call helper
                    leax      LongVariable2,y   point at long variable
                    pshs      x         pass destination
                    leax      SecondNameField,y   point at source long
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    ldd       GlbInitDataSize load data size
                    lbsr      UIntToLong compute 32-bit value
                    lbsr      LongAdd   call helper
                    lbsr      LongStore call helper
                    ldd       GlbListHead load symbol list head
                    bra       StoreSymPtr enter symbol loop test

SymFixupLoop        ldx       GlbVar0050 load current symbol
                    ldd       NdMFlags,x     load symbol flags
                    anda      #$01      test emit bit
                    clrb                clear low byte
                    std       -$02,s    save flag result
                    beq       NextSym   skip if not flagged
                    lbsr      ProcessObjModule emit this symbol
                    lbsr      ErrWriteFile check for write error
NextSym             ldx       GlbVar0050 load current symbol
                    ldd       NdLink,x     load next-symbol pointer
StoreSymPtr         std       GlbVar0050 store current symbol pointer
                    ldd       GlbVar0050 test for end of list
                    bne       SymFixupLoop loop while entries remain
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         pass zero position
                    leax      LongVariable,y   point at long variable
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    lbsr      Fseek     seek and patch file
                    leas      8,s        drop arguments
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       #$0002    two byte length
                    pshs      d         pass length
                    leax      >GlbVar002A,y  point at value source
                    pshs      x         pass source
                    lbsr      CalcCrc   copy two bytes
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       GlbVar002A load data value
                    pshs      d         pass value
                    lbsr      PutWord   write word to file
                    leas      4,s        drop arguments
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       GlbVar002A load data value
                    pshs      d         pass value
                    leax      OutputBuffer,y   point at source
                    pshs      x         pass source
                    lbsr      CalcCrc   copy bytes
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       GlbVar002A load data value
                    pshs      d         pass value
                    ldd       #$0001    record count
                    pshs      d         pass count
                    leax      OutputBuffer,y   point at buffer
                    pshs      x         pass buffer
                    lbsr      FWrite    write block to file
                    leas      8,s        drop arguments
                    lbsr      ErrWriteFile check for write error
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       #$0002    two byte length
                    pshs      d         pass length
                    leax      >GlbInitDataSize,y  point at source
                    pshs      x         pass source
                    lbsr      CalcCrc   copy two bytes
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       GlbInitDataSize load data size
                    pshs      d         pass size
                    lbsr      PutWord   write word to file
                    leas      4,s        drop arguments
                    ldd       GlbInitDataSize test data size
                    beq       DataSizeDone skip if no data section
                    ldd       GlbInitDataSize load data size
                    pshs      d         pass size
                    lbsr      CopyInputData write data section
                    leas      2,s        drop argument
DataSizeDone        clra                clear high byte
                    clrb                clear low byte
                    pshs      d         pass zero position
                    leax      LongVariable2,y   point at long variable
                    ldd       $02,x     load low word
                    pshs      d         pass low word
                    ldd       ,x        load high word
                    pshs      d         pass high word
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    lbsr      Fseek     seek and patch file
                    leas      8,s        drop arguments
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       #$0002    two byte length
                    pshs      d         pass length
                    leax      >GlbVar004E,y  point at source
                    pshs      x         pass source
                    lbsr      CalcCrc   copy two bytes
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       GlbVar004E load value
                    pshs      d         pass value
                    lbsr      PutWord   write word to file
                    leas      4,s        drop arguments
                    ldd       GlbVar0052 load value
                    pshs      d         pass value
                    lbsr      WalkDrefNodes call helper
                    leas      2,s        drop argument
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       #$0002    two byte length
                    pshs      d         pass length
                    leax      >GlbVar004C,y  point at source
                    pshs      x         pass source
                    lbsr      CalcCrc   copy two bytes
                    leas      6,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       GlbVar004C load value
                    pshs      d         pass value
                    lbsr      PutWord   write word to file
                    leas      4,s        drop arguments
                    ldd       GlbVar0054 load value
                    pshs      d         pass value
                    lbsr      WalkDrefNodes call helper
                    leas      2,s        drop argument
                    leax      >Buffer,y  point at buffer
                    pshs      x         pass destination
                    ldd       GlbOutPath load code size
                    addd      #$0001    add one
                    pshs      d         pass length
                    ldd       NamePointer,y   load name pointer
                    pshs      d         pass source
                    lbsr      CalcCrc   copy name into buffer
                    leas      6,s        drop arguments
                    ldd       NamePointer,y   load name pointer
                    pshs      d         pass length
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    lbsr      Sprintf   write name to file
                    leas      4,s        drop arguments
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         pass zero byte
                    lbsr      PutByte   write byte to file
                    leas      4,s        drop arguments
                    ldu       #$0000    init byte counter
                    bra       ComplementCond enter complement loop test

ComplementLoop      tfr       u,d       counter to index
                    leax      >Buffer,y  point at buffer base
                    leax      d,x       index element
                    pshs      x         pass destination
                    tfr       u,d       counter to index
                    leax      >Buffer,y  point at buffer base
                    leax      d,x       index element
                    ldb       ,x        load byte
                    sex                 sign extend
                    coma                complement high byte
                    comb                complement low byte
                    stb       [,s++]    store complemented byte
                    leau      $01,u     advance counter
ComplementCond      cmpu      #$0003    compare against three
                    blt       ComplementLoop loop for three bytes
                    ldd       GlbVar003A load file handle
                    pshs      d         pass handle
                    ldd       #$0001    record count
                    pshs      d         pass count
                    ldd       #$0003    three byte length
                    pshs      d         pass length
                    leax      >Buffer,y  point at CRC buffer
                    pshs      x         pass buffer
                    lbsr      FWrite    write CRC bytes to file
                    leas      8,s        drop arguments
                    lbsr      ErrWriteFile check for write error
                    ldd       GlbVar003A load file handle
                    pshs      d         push file pointer argument
                    lbsr      fclose    call helper
                    leas      2,s        drop argument
                    ldd       GlbVar000E load global flag
                    beq       ReportCopyBytes skip if zero
                    lbsr      PrintLinkMap call externs helper
ReportCopyBytes     ldd       GlbVar0014 load copied byte count
                    beq       CopyDoneExit skip if nothing copied
                    ldd       GlbTFlag  load verbose flag
                    beq       CopyDoneExit skip if not verbose
                    ldd       GlbVar001E load value to report
                    pshs      d         push argument
                    leax      MsgStaticSize,pcr point to format string
                    pshs      x         push format pointer
                    leax      NameBuf,y point to output buffer
                    pshs      x         push buffer pointer
                    lbsr      Sprintf   call sprintf
                    leas      6,s        drop arguments
CopyDoneExit        leas      15,s       release locals
                    puls      pc,u      restore and return

CopyInputData       pshs      u         save frame register (entry)
                    ldd       #$FF32    frame size argument
                    lbsr      stkcheck  allocate stack frame
                    leas      -130,s     reserve local copy buffer
                    clra                prepare zero value
                    clrb                complete zero value
                    pshs      d         push zero seek offset
                    ldd       GlbVar003A load input file pointer
                    pshs      d         push file pointer
                    lbsr      FileTell  call position helper
                    leas      2,s        drop argument
                    ldd       $02,x     load record offset field
                    pshs      d         push argument
                    ldd       ,x        load record offset field
                    pshs      d         push argument
                    ldd       GlbVar003A load input file pointer
                    pshs      d         push file pointer
                    lbsr      Fseek     call fseek
                    leas      8,s        drop arguments
                    bra       CopyBlockTest enter copy loop test

CopyBlockLoop       lbsr      ErrWriteFile refill input buffer
                    ldd       ,s        load remaining count
                    cmpd      $0086,s   compare with total remaining
                    ble       ClampBlockSize keep smaller value
                    ldd       $0086,s   clamp to total remaining
                    std       ,s        store block size
ClampBlockSize      leax      >Buffer,y  point to output stream
                    pshs      x         push stream pointer
                    ldd       $02,s     load block size
                    pshs      d         push byte count
                    leax      $06,s     point to copy buffer
                    pshs      x         push buffer pointer
                    lbsr      CalcCrc   call fwrite
                    leas      6,s        drop arguments
                    ldd       $0086,s   load remaining total
                    subd      ,s        subtract block written
                    std       $0086,s   update remaining total
CopyBlockTest       ldd       $0086,s   load remaining count
                    ble       CopyInputDone done when none left
                    ldd       GlbVar003A load input file pointer
                    pshs      d         push file pointer
                    ldd       #$0080    block size 128
                    pshs      d         push element size
                    ldd       #$0001    count one
                    pshs      d         push count
                    leax      $08,s     point to copy buffer
                    pshs      x         push buffer pointer
                    lbsr      FRead     call fread
                    leas      8,s        drop arguments
                    std       ,s        store bytes read
                    bne       CopyBlockLoop loop while bytes read
CopyInputDone       leas      130,s      release local buffer
                    puls      pc,u      restore and return

ProcessObjModule    pshs      u         save frame register (entry)
                    ldd       #$FFA3    frame size argument
                    lbsr      stkcheck  allocate stack frame
                    leas      -7,s       reserve locals
                    ldd       GlbVar004A load last name id
                    ldx       GlbVar0050 load module record pointer
                    cmpd      NdName,x     compare with current name id
                    beq       OutFileReady skip reopen if unchanged
                    ldd       GlbVar0038 load current output file
                    pshs      d         push file pointer
                    leax      MsgModeRead,pcr point to open mode string
                    pshs      x         push mode pointer
                    ldx       GlbVar0050 reload record pointer
                    ldd       NdName,x     load new name id
                    std       GlbVar004A remember name id
                    pshs      d         push name id
                    lbsr      WalkExprLoop call open helper
                    leas      6,s        drop arguments
                    std       GlbVar0038 store new file pointer
                    bne       OutFileReady continue if open succeeded
                    ldx       GlbVar0050 reload record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    leax      MsgCantReopen,pcr point to error string
                    pshs      x         push message pointer
                    lbsr      PrintErrMsg print error and exit
                    leas      4,s        drop arguments
OutFileReady        clra                prepare zero value
                    clrb                complete zero value
                    pshs      d         push zero seek offset
                    ldx       GlbVar0050 load record pointer
                    leax      $29,x     point to section address field
                    ldd       $02,x     load offset low word
                    pshs      d         push argument
                    ldd       ,x        load offset high word
                    pshs      d         push argument
                    ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    lbsr      Fseek     call fseek
                    leas      8,s        drop arguments
                    ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    ldd       #$0001    count one
                    pshs      d         push count
                    ldx       GlbVar0050 load record pointer
                    ldd       $1f,x     load text size
                    ldx       GlbVar0050 reload record pointer
                    addd      $1d,x     add data size
                    ldx       GlbVar0050 reload record pointer
                    addd      $1b,x     add extra size
                    pshs      d         push total size
                    ldd       GlbVar0048 load buffer pointer
                    pshs      d         push buffer pointer
                    lbsr      FRead     call fread
                    leas      8,s        drop arguments
                    std       -$02,s    store bytes read
                    bne       SegCountRead continue if read succeeded
                    ldx       GlbVar0050 load record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    lbsr      ErrReadFile report file error
                    leas      2,s        drop argument
SegCountRead        ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    lbsr      ReadWord  call getc
                    leas      2,s        drop argument
                    std       ,s        store segment count
                    ldx       GlbVar0038 load file structure
                    ldd       $06,x     load status flags
                    clra                isolate low byte
                    andb      #$20      test error flag
                    lbeq      SegLoopTest skip if no error
                    ldx       GlbVar0050 load record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    lbsr      ErrReadFile report file error
                    leas      2,s        drop argument
                    lbra      SegLoopTest jump to segment loop test

SegLoopBody         leas      -10,s      reserve loop locals
                    leax      ,s        point to local record
                    pshs      x         push record pointer
                    lbsr      ReadSymName read segment header
                    leas      2,s        drop argument
                    ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    lbsr      ReadWord  call getc
                    leas      2,s        drop argument
                    tfr       d,u       save record count in u
                    ldx       GlbVar0038 load file structure
                    ldd       $06,x     load status flags
                    clra                isolate low byte
                    andb      #$20      test error flag
                    beq       ReadRelocValue skip if no error
                    ldx       GlbVar0050 load record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    lbsr      ErrReadFile report file error
                    leas      2,s        drop argument
ReadRelocValue      leax      ,s        point to first local
                    pshs      x         push pointer
                    leax      $02,s     point to second local
                    pshs      x         push pointer
                    lbsr      HashName  read relocation value
                    std       ,s        store value
                    lbsr      LookupSym resolve symbol value
                    leas      4,s        drop arguments
                    std       $0f,s     store resolved value
                    bne       RelocLoopTest skip error if valid
                    leax      ,s        point to local
                    pshs      x         push pointer
                    leax      MsgSymNotFound,pcr point to error string
                    pshs      x         push message pointer
                    lbsr      PrintErrMsg print error and exit
                    bra       RelocLoopEnd continue loop

RelocLoop3          ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    ldd       #$0001    count one
                    pshs      d         push count
                    ldd       #$0003    read three bytes
                    pshs      d         push size
                    leax      $12,s     point to record buffer
                    pshs      x         push buffer pointer
                    lbsr      FRead     call fread
                    leas      8,s        drop arguments
                    ldx       GlbVar0038 load file structure
                    ldd       $06,x     load status flags
                    clra                isolate low byte
                    andb      #$20      test error flag
                    beq       EmitRelocEntry skip if no error
                    ldx       GlbVar0050 load record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    lbsr      ErrReadFile report file error
                    leas      2,s        drop argument
EmitRelocEntry      ldd       $0f,s     load resolved value
                    pshs      d         push value
                    leax      $0e,s     point to record buffer
                    pshs      x         push record pointer
                    lbsr      ApplyReloc3 emit relocation entry
RelocLoopEnd        leas      4,s        drop arguments
RelocLoopTest       tfr       u,d       copy loop counter
                    leau      -$01,u    decrement counter
                    std       -$02,s    store counter
                    bne       RelocLoop3 loop while more records
                    leas      10,s       release loop locals
SegLoopTest         ldd       ,s        load segment count
                    addd      #$FFFF    decrement count
                    std       ,s        store count
                    subd      #$FFFF    restore for test
                    lbne      SegLoopBody loop while segments remain
                    ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    lbsr      ReadWord  call getc
                    leas      2,s        drop argument
                    std       ,s        store data record count
                    ldx       GlbVar0038 load file structure
                    ldd       $06,x     load status flags
                    clra                isolate low byte
                    andb      #$20      test error flag
                    beq       DataRelocTest2 skip if no error
                    ldx       GlbVar0050 load record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    lbsr      ErrReadFile report file error
                    leas      2,s        drop argument
                    bra       DataRelocTest2 enter data loop test

DataRelocLoop       ldd       GlbVar0038 load output file
                    pshs      d         push file pointer
                    ldd       #$0001    count one
                    pshs      d         push count
                    ldd       #$0003    read three bytes
                    pshs      d         push size
                    leax      $08,s     point to record buffer
                    pshs      x         push buffer pointer
                    lbsr      FRead     call fread
                    leas      8,s        drop arguments
                    ldx       GlbVar0038 load file structure
                    ldd       $06,x     load status flags
                    clra                isolate low byte
                    andb      #$20      test error flag
                    beq       DataRelocEmit skip if no error
                    ldx       GlbVar0050 load record pointer
                    ldd       NdName,x     load name id
                    pshs      d         push name id
                    lbsr      ErrReadFile report file error
                    leas      2,s        drop argument
DataRelocEmit       clra                prepare zero value
                    clrb                complete zero value
                    pshs      d         push zero argument
                    leax      $04,s     point to record buffer
                    pshs      x         push record pointer
                    lbsr      ApplyReloc3 emit relocation entry
                    leas      4,s        drop arguments
DataRelocTest2      ldd       ,s        load remaining count
                    addd      #$FFFF    decrement count
                    std       ,s        store count
                    subd      #$FFFF    restore for test
                    bne       DataRelocLoop loop while records remain
                    leax      >Buffer,y  point to output stream
                    pshs      x         push stream pointer
                    ldx       GlbVar0050 load record pointer
                    ldd       $1f,x     load text size
                    pshs      d         push size
                    ldd       GlbVar0048 load buffer pointer
                    pshs      d         push buffer pointer
                    lbsr      CalcCrc   call fwrite
                    leas      6,s        drop arguments
                    ldd       GlbVar005A load header-written flag
                    bne       WriteCodeSection skip header if already written
                    clra                prepare zero value
                    clrb                complete zero value
                    pshs      d         push zero seek offset
                    leax      OutputNameField2,y   point to output name field
                    ldd       $02,x     load offset low
                    pshs      d         push argument
                    ldd       ,x        load offset high
                    pshs      d         push argument
                    ldd       GlbVar003A load file pointer
                    pshs      d         push file pointer
                    lbsr      Fseek     call fseek
                    leas      8,s        drop arguments
WriteCodeSection    ldd       GlbVar003A load file pointer
                    pshs      d         push file pointer
                    ldd       #$0001    count one
                    pshs      d         push count
                    ldx       GlbVar0050 load record pointer
                    ldd       $1f,x     load text size
                    pshs      d         push size
                    ldd       GlbVar0048 load buffer pointer
                    pshs      d         push buffer pointer
                    lbsr      FWrite    write code section
                    leas      8,s        drop arguments
                    leax      OutputNameField2,y   point to output name field
                    pshs      x         push pointer
                    ldd       $02,x     load offset low
                    pshs      d         push argument
                    ldd       ,x        load offset high
                    pshs      d         push argument
                    ldx       GlbVar0050 load record pointer
                    ldd       $1f,x     load text size
                    lbsr      UIntToLong update output position
                    lbsr      LongAdd   flush output record
                    lbsr      LongStore finalize output position
                    ldd       #$0001    set flag value
                    std       GlbVar005A mark header written
                    lbsr      ErrWriteFile refill input buffer
                    clra                prepare zero value
                    clrb                complete zero value
                    std       ,s        initialize byte index
                    ldd       GlbVar0048 load buffer base
                    ldx       GlbVar0050 load record pointer
                    addd      $1f,x     add text size offset
                    tfr       d,u       set source pointer
                    bra       CopyByteTest2 enter byte copy test

CopyByteLoop2       ldb       ,u+       read next data byte
                    ldx       >OutputPointer,y  load output pointer
                    leax      $01,x     advance pointer
                    stx       >OutputPointer,y  save output pointer
                    stb       -$01,x    store byte to output
                    ldd       ,s        load byte index
                    addd      #$0001    increment index
                    std       ,s        store index
CopyByteTest2       ldd       ,s        load byte index
                    ldx       GlbVar0050 load record pointer
                    cmpd      $1d,x     compare with data size
                    bcs       CopyByteLoop2 loop while bytes remain
                    ldx       GlbVar0050 load record pointer
                    ldd       $1b,x     load extra size
                    lbeq      AccumSectionSizes skip if none
                    clra                prepare zero value
                    clrb                complete zero value
                    pshs      d         push zero seek offset
                    leax      SecondNameField,y   point to second name field
                    ldd       $02,x     load offset low
                    pshs      d         push argument
                    ldd       ,x        load offset high
                    pshs      d         push argument
                    ldd       GlbVar003A load file pointer
                    pshs      d         push file pointer
                    lbsr      Fseek     call fseek
                    leas      8,s        drop arguments
                    ldd       GlbVar003A load file pointer
                    pshs      d         push file pointer
                    ldd       #$0001    count one
                    pshs      d         push count
                    ldx       GlbVar0050 load record pointer
                    ldd       $1b,x     load extra size
                    pshs      d         push size
                    ldd       GlbVar0048 load buffer base
                    ldx       GlbVar0050 load record pointer
                    addd      $1f,x     add text size offset
                    ldx       GlbVar0050 reload record pointer
                    addd      $1d,x     add data size offset
                    pshs      d         push source pointer
                    lbsr      FWrite    write extra section
                    leas      8,s        drop arguments
                    leax      SecondNameField,y   point to second name field
                    pshs      x         push pointer
                    ldd       $02,x     load offset low
                    pshs      d         push argument
                    ldd       ,x        load offset high
                    pshs      d         push argument
                    ldx       GlbVar0050 load record pointer
                    ldd       $1b,x     load extra size
                    lbsr      UIntToLong update output position
                    lbsr      LongAdd   flush output record
                    lbsr      LongStore finalize output position
                    lbsr      ErrWriteFile refill input buffer
                    clra                prepare zero value
                    clrb                complete zero value
                    std       GlbVar005A reset header flag
AccumSectionSizes   ldd       GlbVar001C load text total
                    pshs      d         push accumulator
                    ldx       GlbVar0050 load record pointer
                    ldd       $17,x     load section text size
                    addd      ,s++      add running total
                    std       GlbVar001C store updated total
                    ldd       GlbVar0020 load data total
                    pshs      d         push accumulator
                    ldx       GlbVar0050 load record pointer
                    ldd       $19,x     load section data size
                    addd      ,s++      add running total
                    std       GlbVar0020 save updated segment base
                    ldd       GlbVar0024 load next segment base
                    pshs      d         stash it for adding
                    ldx       GlbVar0050 point to module reloc record
                    ldd       $1b,x     read this segment size
                    addd      ,s++      accumulate running base
                    std       GlbVar0024 save updated segment base
                    ldd       GlbVar0028 load next segment base
                    pshs      d         stash it for adding
                    ldx       GlbVar0050 point to module reloc record
                    ldd       $1d,x     read this segment size
                    addd      ,s++      accumulate running base
                    std       GlbVar0028 save updated segment base
                    ldd       GlbVar002C load next segment base
                    pshs      d         stash it for adding
                    ldx       GlbVar0050 point to module reloc record
                    ldd       $1f,x     read this segment size
                    addd      ,s++      accumulate running base
                    std       GlbVar002C save updated segment base
                    ldd       GlbVar001C reload first segment base
                    ldx       GlbVar0050 point to module reloc record
                    subd      $17,x     subtract original segment offset
                    ldx       GlbVar0050 point to module reloc record
                    std       $17,x     store relocation delta back
                    ldd       GlbVar0020 reload segment base
                    ldx       GlbVar0050 point to module reloc record
                    subd      $19,x     subtract original segment offset
                    ldx       GlbVar0050 point to module reloc record
                    std       $19,x     store relocation delta back
                    ldd       GlbVar0024 reload segment base
                    ldx       GlbVar0050 point to module reloc record
                    subd      $1b,x     subtract original segment offset
                    ldx       GlbVar0050 point to module reloc record
                    std       $1b,x     store relocation delta back
                    ldd       GlbVar0028 reload segment base
                    ldx       GlbVar0050 point to module reloc record
                    subd      $1d,x     subtract original segment offset
                    ldx       GlbVar0050 point to module reloc record
                    std       $1d,x     store relocation delta back
                    ldd       GlbVar002C reload segment base
                    ldx       GlbVar0050 point to module reloc record
                    subd      $1f,x     subtract original segment offset
                    ldx       GlbVar0050 point to module reloc record
                    std       $1f,x     store relocation delta back
                    lbra      RelocDone done, return from routine

ApplyReloc3         pshs      u         save frame pointer
                    ldd       #$FFB1    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    leas      -7,s       allocate local frame
                    ldx       $0b,s     get reloc entry pointer arg
                    ldd       $01,x     load target offset field
                    addd      GlbVar0048 add segment load base
                    std       $05,s     save patch address
                    ldb       [$0b,s]   load flags byte from entry
                    stb       $02,s     save flags
                    ldd       $0d,s     get symbol pointer arg
                    beq       RelocSegRel none, relocate segment relative
                    ldx       $0d,s     point to symbol record
                    ldd       $0C,x     read symbol value
                    std       $03,s     save as relocation value
                    ldx       $0d,s     point to symbol record
                    ldd       $0a,x     read symbol type byte
                    stb       $01,s     save segment/type selector
                    ldb       $02,s     reload flags byte
                    clra                clear high half
                    andb      #$80      test negate-value bit
                    lbeq      RelocApply not set, apply as is
                    ldd       $03,s     load relocation value
                    subd      GlbVar002C subtract bss base
                    std       $03,s     save adjusted value
                    bra       RelocApply go apply relocation

RelocSegRel         ldb       $02,s     take flags byte
                    stb       $01,s     save as segment selector
                    clra                clear high half
                    andb      #$07      isolate segment number
                    tfr       d,x       index for segment switch
                    bra       RelocSegSwitch dispatch on segment

RelocSeg0           ldd       GlbVar001C segment 0 base
                    bra       RelocSegSet store as reloc value

RelocSeg1           ldd       GlbVar0024 segment 1 base
                    bra       RelocSegSet store as reloc value

RelocSeg2           ldd       GlbVar0020 segment 2 base
                    bra       RelocSegSet store as reloc value

RelocSeg3           ldd       GlbVar0028 segment 3 base
                    bra       RelocSegSet store as reloc value

RelocSeg4           ldd       GlbVar002C segment 4 bss base
RelocSegSet         std       $03,s     save selected base as reloc value
                    bra       RelocApply go apply relocation

RelocBadType        leax      MsgRefTypeErr,pcr point to ref type error message
                    pshs      x         push message pointer
                    lbsr      PrintErrMsg print the error
                    leas      2,s        drop argument
                    bra       RelocApply continue applying

RelocSegSwitch      stx       -$02,s    save segment index
                    beq       RelocSeg0 segment 0
                    cmpx      #$0001    segment 1?
                    beq       RelocSeg1 segment 1
                    cmpx      #$0002    segment 2?
                    beq       RelocSeg2 segment 2
                    cmpx      #$0003    segment 3?
                    beq       RelocSeg3 segment 3
                    cmpx      #$0004    segment 4?
                    beq       RelocSeg4 segment 4
                    bra       RelocBadType bad segment, error

RelocApply          ldb       $02,s     take flags byte
                    clra                clear high half
                    andb      #$40      test negate bit
                    beq       RelocSizeBits not negated
                    ldd       $03,s     load relocation value
                    nega                negate low
                    negb                negate high
                    sbca      #$00      propagate borrow
                    std       $03,s     save negated value
RelocSizeBits       ldb       $02,s     take flags byte
                    clra                clear high half
                    andb      #$30      isolate reference size bits
                    stb       ,s        save size class
                    cmpb      #$20      high-only reference?
                    beq       RelocPatch skip base adjustment
                    ldd       $05,s     patch address
                    pshs      d         save for adding
                    ldx       GlbVar0050 point to reloc record
                    ldd       $1f,x     bss segment delta
                    addd      ,s++      add to address
                    std       $05,s     adjust patch address
                    ldb       ,s        take size class
                    clra                clear high half
                    andb      #$10      test data-segment bit
                    bne       RelocPatch skip second adjustment
                    ldd       $05,s     patch address
                    pshs      d         save for adding
                    ldx       GlbVar0050 point to reloc record
                    ldd       $1d,x     data segment delta
                    addd      ,s++      add to address
                    std       $05,s     adjust patch address
RelocPatch          ldb       $02,s     take flags byte
                    clra                clear high half
                    andb      #$08      test byte-size bit
                    beq       RelocWord word relocation
                    ldb       [$05,s]   load target byte
                    sex                 sign extend
                    addd      $03,s     add relocation value
                    stb       [$05,s]   store patched byte
                    bra       RelocRecord go record fixup

RelocWord           ldd       [$05,s]   load target word
                    addd      $03,s     add relocation value
                    std       [$05,s]   store patched word
RelocRecord         ldb       ,s        take size class
                    cmpb      #$20      high-only reference?
                    beq       RelocDone nothing to record
                    ldb       ,s        take size class
                    clra                clear high half
                    andb      #$10      use segment 1 base
                    beq       RelocSeg1Base use segment 1 base
                    ldd       GlbVar0028 segment 3 base
                    bra       RelocMakeAddr go build address

RelocSeg1Base       ldd       GlbVar0024 segment 1 base
RelocMakeAddr       ldx       $0b,s     reloc entry pointer
                    addd      $01,x     add entry offset
                    tfr       d,u       final relocation address
                    ldb       $01,s     segment selector
                    clra                clear high half
                    andb      #$07      isolate segment number
                    cmpd      #$0004    segment 4 bss?
                    bne       RelocRecordData no, data reloc list
                    pshs      u         push address
                    leax      >GlbVar0052,y  bss reloc list head
                    pshs      x         push list pointer
                    lbsr      AllocDref append to bss list
                    leas      4,s        drop arguments
                    ldd       GlbVar004E bss reloc count
                    addd      #$0001    increment
                    std       GlbVar004E save count
                    bra       RelocDone done

RelocRecordData     pshs      u         push address
                    leax      >GlbVar0054,y  data reloc list head
                    pshs      x         push list pointer
                    lbsr      AllocDref append to data list
                    leas      4,s        drop arguments
                    ldd       GlbVar004C data reloc count
                    addd      #$0001    increment
                    std       GlbVar004C save count
RelocDone           leas      7,s        release local frame
                    puls      pc,u      return from routine

XorChecksum         pshs      u         save frame pointer
                    ldd       #$FFBC    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    ldu       $04,s     buffer pointer arg
                    leas      -2,s       allocate accumulator
                    ldd       #$FFFF    seed checksum value
                    bra       XorNext   enter loop test

XorLoop             ldd       ,s        running checksum
                    pshs      d         save for xor
                    ldb       ,u+       next buffer byte
                    sex                 sign extend
                    eora      ,s+       xor into high
                    eorb      ,s+       xor into low
XorNext             std       ,s        save checksum
                    ldd       $08,s     remaining byte count
                    addd      #$FFFF    decrement count
                    std       $08,s     save count
                    subd      #$FFFF    test for zero
                    bne       XorLoop   more bytes to hash
                    ldd       ,s        result checksum
                    puls      pc,u,x    return checksum

ErrReadFile         pshs      u         save frame pointer
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    ldd       $04,s     filename argument
                    pshs      d         push filename
                    leax      MsgErrReadFile,pcr error reading file message
                    bra       PrintFileErr print and return

ErrWriteFile        pshs      u         save frame pointer
                    ldd       #$FFB8    frame size for stack check
                    lbsr      stkcheck  stack overflow check
                    ldx       GlbVar003A point to file structure
                    ldd       $06,x     read status flags
                    clra                clear high half
                    andb      #$20      test write-error bit
                    beq       ErrWriteDone none, just return
                    ldd       OutputFileName,y   filename pointer
                    pshs      d         push filename
                    leax      MsgErrWriteFile,pcr error writing file message
PrintFileErr        pshs      x         push message pointer
                    lbsr      PrintErrMsg print the error
                    leas      4,s        drop arguments
ErrWriteDone        puls      pc,u      return from routine

SetFileSize         pshs      u,x,d     save registers and args
                    lda       $09,s     path number
                    ldb       #$02      SS.Size status code
                    ldx       #$0000    high size word zero
                    ldu       $0a,s     low size word
                    os9       I$SetStt  set file size
                    puls      u,x,d     restore registers
                    lbra      SyscallRet check for os9 error and return

MsgModeWxp          fcb       $77,$78,$2B
                    fcb       C$NULL
MsgCantCreateOut    fcc       /can't create output file/
                    fcb       C$NULL
MsgStaticSize       fcc       /BASIC09 static data size is %d bytes/
                    fcb       C$CR,C$NULL
MsgModeRead         fcb       $72
                    fcb       C$NULL
MsgCantReopen       fcc       /can't reopen input file %s/
                    fcb       C$NULL
MsgSymNotFound      fcc       /symbol %s not found in codgen/
                    fcb       C$NULL
MsgRefTypeErr       fcc       /ref type error/
                    fcb       C$NULL
MsgErrReadFile      fcc       /error reading file %s/
                    fcb       C$NULL
MsgErrWriteFile     fcc       /error writing file %s/
                    fcb       C$NULL
HashName            pshs      u         save frame pointer
                    ldu       $04,s     string pointer arg
                    leas      -2,s       allocate sum accumulator
                    clra                clear sum high
                    clrb                clear sum low
                    bra       HashNext  enter loop test

HashLoop            ldd       ,s        running sum
                    pshs      d         save for adding
                    ldb       ,u+       next character
                    sex                 sign extend
                    addd      ,s++      add to sum
HashNext            std       ,s        save sum
                    ldb       ,u        peek next character
                    bne       HashLoop  until null terminator
                    ldd       ,s        total sum
                    pshs      d         push sum
                    ldd       #$0173    table size for modulo
                    lbsr      UDivSetup modulo to hash index
                    puls      pc,u,x    return hash index

LookupSym           pshs      u         save frame pointer
                    ldd       $04,s     hash index argument
                    aslb                index times two low
                    rola                index times two high
                    leax      HashTableBase,y   hash table base
                    leax      d,x       point to bucket
                    ldu       ,x        first symbol in bucket
                    bra       LookupTest enter search loop

LookupLoop          ldb       [$06,s]   first char of search key
                    sex                 sign extend
                    pshs      d         save for compare
                    ldb       ,u        first char of this symbol
                    sex                 sign extend
                    cmpd      ,s++      compare first characters
                    bne       LookupNext mismatch, try next
                    pshs      u         push symbol pointer
                    ldd       $08,s     key string pointer
                    pshs      d         push key pointer
                    lbsr      strcmp    full string compare
                    leas      4,s        drop arguments
                    std       -$02,s    save result
                    lbeq      InternDone equal, symbol found
LookupNext          ldu       $10,u     next symbol in chain
LookupTest          stu       -$02,s    save current node
                    bne       LookupLoop keep searching if not null
                    clra                clear result high
                    clrb                clear result low
                    puls      pc,u      return null, not found

InsertSym           pshs      u,d       save frame pointer and args
                    ldd       $06,s     symbol pointer
                    pshs      d         push symbol
                    ldd       $08,s     name pointer
                    pshs      d         push name
                    lbsr      HashName  hash the name
                    leas      2,s        drop name arg
                    std       $02,s     save hash index
                    pshs      d         push hash index
                    lbsr      LookupSym look up existing symbol
                    leas      4,s        drop arguments
                    std       -$02,s    save result
                    bne       SymExists already present
                    ldd       ,s        hash index
                    aslb                index times two low
                    rola                index times two high
                    leax      HashTableBase,y   hash table base
                    leax      d,x       bucket address
                    ldd       ,x        current bucket head
                    ldx       $06,s     new symbol pointer
                    std       $10,x     link old head as next
                    ldd       ,s        hash index
                    aslb                index times two low
                    rola                index times two high
                    leax      HashTableBase,y   hash table base
                    leax      d,x       bucket address
                    ldd       $06,s     new symbol pointer
                    std       ,x        make it bucket head
                    clra                clear high
                    clrb                clear low
                    pshs      d         push placeholder
                    ldd       $08,s     name pointer
                    pshs      d         push name
                    lbsr      FindSym   check for reserved name
                    leas      4,s        drop arguments
                    std       -$02,s    save result
                    beq       InsertDone not a special name
                    ldx       $06,s     symbol pointer
                    ldd       $0a,x     read flags word
                    ora       #$01      set special-name flag
                    std       $0a,x     save flags
InsertDone          clra                clear result high
                    clrb                clear result low
                    bra       InsertRet go return

SymExists           ldd       #$0001    return one, already existed
InsertRet           puls      pc,u,x    return from routine

                    puls      pc,u,x    unreachable duplicate return

PrintErrMsg         pshs      u,d       save frame pointer and args
                    ldd       OutputPathHandle,y   program name prefix
                    std       ,s        save into buffer
                    leax      MsgLinkerFatal,pcr format prefix string
                    pshs      x         push format pointer
                    leax      NameBuf,y output buffer
                    pshs      x         push buffer pointer
                    lbsr      Sprintf   format into buffer
                    leas      4,s        drop arguments
                    ldd       $0C,s     caller format argument
                    pshs      d         push argument
                    ldd       $0C,s     caller format argument
                    pshs      d         push argument
                    ldd       $0C,s     caller format argument
                    pshs      d         push argument
                    ldd       $0C,s     caller format argument
                    pshs      d         push argument
                    leax      NameBuf,y output buffer
                    pshs      x         push buffer pointer
                    lbsr      Sprintf   format message with args
                    leas      10,s       drop arguments
                    leax      MsgCrNul,pcr newline suffix string
                    pshs      x         push suffix pointer
                    leax      NameBuf,y output buffer
                    pshs      x         push buffer pointer
                    lbsr      Sprintf   append newline
                    leas      4,s        drop arguments
                    ldd       ,s        formatted buffer pointer
                    pshs      d         push string
                    lbsr      exit      write to error output
                    leas      2,s        drop argument
                    puls      pc,u,x    return from routine

ParseNumber         pshs      u         save frame pointer
                    ldu       $04,s     string pointer arg
                    leas      -4,s       allocate local frame
                    clra                start number value at zero
                    clrb                clear low byte
                    bra       NumScanLoop enter digit scan loop

NumAddDigit         ldd       ,s        load running value
                    pshs      d         save it as multiplicand
                    ldd       #$000A    multiplier ten
                    lbsr      MulEntry  multiply value by ten
                    pshs      d         save the product
                    ldd       $04,s     reload current digit char
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add digit to value times ten
NumScanLoop         std       ,s        store running value
                    ldb       ,u+       fetch next input char
                    sex                 extend to word
                    std       $02,s     save current char
                    leax      CtypeTab,y point to character class table
                    leax      d,x       index table by char
                    ldb       ,x        load class flags
                    clra                clear high byte
                    andb      #$08      test digit flag bit
                    bne       NumAddDigit keep scanning while digit
                    ldd       $02,s     reload terminating char
                    cmpd      #$006B    is it lowercase k
                    beq       NumKiloScale apply kilo scaling
                    ldd       $02,s     reload char
                    cmpd      #$004B    is it uppercase K
                    bne       NumFinalScale no suffix keep value
NumKiloScale        ldd       ,s        load parsed value
                    pshs      d         pass as multiplicand
                    ldd       #$0004    kilo scale factor
                    lbsr      MulEntry  scale value for suffix
                    std       ,s        store scaled value
NumFinalScale       ldd       ,s        load value to finalize
                    pshs      d         pass it
                    ldd       #$0008    final scale factor
                    lbsr      AslEntry  apply final scaling
                    leas      4,s        drop locals
                    puls      pc,u      return parsed value

FreeListNode        pshs      u         save u
                    ldu       $04,s     load node pointer argument
                    ldd       ,u        get node next link
                    std       [$02,u]   patch predecessor forward link
                    ldd       $02,u     get node prev link
                    ldx       ,u        get node next link
                    std       $02,x     patch successor back link
                    leax      >ListHeadAddress,y  point to list head
                    pshs      x         save head address
                    cmpu      ,s++      is node the list head
                    beq       FreeNodeDone skip free-list push
                    ldd       GlbVar005C current free list head
                    std       ,u        link node onto free list
                    stu       GlbVar005C node becomes free head
FreeNodeDone        puls      pc,u      return

FindSym             pshs      u,d       save regs and make locals
                    clra                clear found result
                    clrb                clear low byte
                    std       ,s        store none found
                    ldu       >ListHeadAddress,y  load bucket head node
                    bra       FindSymTest enter search loop

FindSymLoop2        ldb       $04,u     node key length
                    sex                 extend to word
                    pshs      d         save it
                    ldb       [$08,s]   target key length
                    sex                 extend to word
                    cmpd      ,s++      do the lengths match
                    bne       NextSymNode no advance to next
                    ldd       $06,s     target name pointer
                    pshs      d         push as argument
                    pshs      u         push node pointer
                    ldd       #$0004    name field offset
                    addd      ,s++      node name pointer
                    pshs      d         push as argument
                    lbsr      strcmp    compare the two names
                    leas      4,s        drop arguments
                    std       -$02,s    save compare result
                    bne       NextSymNode mismatch advance
                    ldd       $08,s     load keep flag
                    beq       UnlinkMatch remove node and continue
                    tfr       u,d       return matched node
                    puls      pc,u,x    return

UnlinkMatch         ldd       ,u        save node next link
                    std       ,s        stash next pointer
                    pshs      u         push node pointer
                    lbsr      FreeListNode unlink and free node
                    leas      2,s        drop argument
                    ldu       ,s        reload saved next
NextSymNode         ldu       ,u        advance to next node
FindSymTest         leax      >ListHeadAddress,y  list head address
                    pshs      x         save head
                    cmpu      ,s++      reached head again
                    bne       FindSymLoop2 keep searching
                    ldd       ,s        load found result
                    puls      pc,u,x    return

InternSym           pshs      u         save u
                    ldd       #$0001    keep flag true
                    pshs      d         push flag
                    ldd       $06,s     target key pointer
                    pshs      d         push key
                    lbsr      FindSym   search for symbol
                    leas      4,s        drop arguments
                    tfr       d,u       result node
                    stu       -$02,s    save it
                    bne       InternDone found so return it
                    ldd       GlbVar005C free list head
                    beq       AllocNewSym empty so allocate new
                    ldu       GlbVar005C take node from free list
                    ldd       ,u        its next link
                    std       GlbVar005C pop the free list
                    bra       LinkSymHead link the node

AllocNewSym         ldd       #$0010    node size sixteen
                    pshs      d         push size
                    bsr       AllocMem  allocate a node
                    leas      2,s        drop argument
                    tfr       d,u       new node pointer
LinkSymHead         leax      >ListHeadAddress,y  list head address
                    stx       $02,u     set node prev to head
                    ldd       >ListHeadAddress,y  head next node
                    std       ,u        set node next link
                    ldx       >ListHeadAddress,y  head next node
                    stu       $02,x     its prev is new node
                    stu       >ListHeadAddress,y  head next is new node
InternDone          tfr       u,d       return node pointer
                    puls      pc,u      return

AllocMem            pshs      u,d       save regs and locals
                    ldd       $06,s     requested size
                    pshs      d         push size
                    lbsr      GrowHeap  allocate memory
                    leas      2,s        drop argument
                    std       ,s        save pointer
                    cmpd      #$FFFF    allocation failed
                    bne       AllocOk   success return pointer
                    ldd       GlbVar0046 size report flag
                    beq       AllocFail skip size message
                    ldd       GlbVar0046 requested amount
                    pshs      d         push value
                    leax      MsgNeedBytes,pcr need bytes message
                    pshs      x         push format
                    leax      NameBuf,y output buffer
                    pshs      x         push destination
                    lbsr      Sprintf   format the message
                    leas      6,s        drop arguments
AllocFail           leax      MsgOutOfMem,pcr out of memory message
                    pshs      x         push string
                    lbsr      PrintErrMsg print fatal error
                    leas      2,s        drop argument
                    bra       AllocRet  return

AllocOk             ldd       ,s        load pointer
                    puls      pc,u,x    return

AllocRet            puls      pc,u,x    return

SectTypeName        pshs      u         save u
                    ldd       $04,s     section type argument
                    clra                clear high byte
                    andb      #$07      mask type bits
                    tfr       d,x       into index register
                    bra       SectTypeSwitch dispatch on type

NameCode            leax      StrCode,pcr point to code string
                    bra       SectNameRet return it

NameUdat            leax      StrUdat,pcr point to udat string
                    bra       SectNameRet return it

NameIdat            leax      StrIdat,pcr point to idat string
                    bra       SectNameRet return it

NameUdpd            leax      StrUdpd,pcr point to udpd string
                    bra       SectNameRet return it

NameIdpd            leax      StrIdpd,pcr point to idpd string
                    bra       SectNameRet return it

NameUnknown         leax      StrUnknown,pcr point to unknown marker
SectNameRet         tfr       x,d       string pointer into d
                    puls      pc,u      return

SectTypeSwitch      cmpx      #$0004    type value four
                    beq       NameCode  return code name
                    stx       -$02,s    save type value
                    beq       NameUdat  zero is udat
                    cmpx      #$0001    type value one
                    beq       NameIdat  return idat name
                    cmpx      #$0002    type value two
                    beq       NameUdpd  return udpd name
                    cmpx      #$0003    type value three
                    beq       NameIdpd  return idpd name
                    bra       NameUnknown return unknown name

                    puls      pc,u      return

PrintLinkMap        pshs      u,d       save regs
                    ldd       OutputFileName,y   output file name
                    pshs      d         push argument
                    ldd       NamePointer,y   module name
                    pshs      d         push argument
                    leax      MsgMapHeader,pcr map header format
                    pshs      x         push format
                    lbsr      Printf    print header line
                    leas      6,s        drop arguments
                    leax      MsgSectColumns,pcr section column header
                    pshs      x         push string
                    lbsr      PutMsgLine print header
                    leas      2,s        drop argument
                    ldd       GlbListHead module list head
                    lbra      PrintModTest enter module loop

PrintModLoop        ldx       ,s        current module
                    ldd       NdMFlags,x     module flags
                    anda      #$01      test print flag
                    clrb                clear low byte
                    std       -$02,s    save flag
                    lbeq      NextModule2 skip module if not flagged
                    ldx       ,s        current module
                    ldd       NdName,x     file name pointer
                    pshs      d         push argument
                    ldx       $02,s     module pointer
                    ldd       $19,x     udpd size
                    pshs      d         push argument
                    ldx       $04,s     module pointer
                    ldd       $1d,x     idpd size
                    pshs      d         push argument
                    ldx       $06,s     module pointer
                    ldd       $17,x     udat size
                    pshs      d         push argument
                    ldx       $08,s     module pointer
                    ldd       $1b,x     idat size
                    pshs      d         push argument
                    ldx       $0a,s     module pointer
                    ldd       $1f,x     code size
                    pshs      d         push argument
                    ldd       $0C,s     module name
                    pshs      d         push argument
                    leax      MsgModLine,pcr module line format
                    pshs      x         push format
                    lbsr      Printf    print module line
                    leas      16,s       drop arguments
                    ldd       GlbVar0010 section detail flag
                    beq       NextModule2 skip section list
                    ldx       ,s        current module
                    ldu       NdHead,x     first section
                    bra       PrintSectTest enter section loop

PrintSectLoop       ldd       $0C,u     section address
                    pshs      d         push argument
                    ldd       $0a,u     section type
                    pshs      d         push argument
                    lbsr      SectTypeName get section name
                    std       ,s        replace type with name
                    pshs      u         push section pointer
                    leax      MsgSectLine,pcr section line format
                    pshs      x         push format
                    lbsr      Printf    print section line
                    leas      8,s        drop arguments
                    ldu       NdNext,u     next section
PrintSectTest       stu       -$02,s    save section pointer
                    bne       PrintSectLoop more sections to print
NextModule2         ldx       ,s        current module
                    ldd       NdLink,x     next module link
PrintModTest        std       ,s        store module pointer
                    ldd       ,s        reload it
                    lbne      PrintModLoop more modules to print
                    leax      MsgMapDashes,pcr totals separator dashes
                    pshs      x         push string
                    lbsr      PutMsgLine print dashes
                    leas      2,s        drop argument
                    ldd       GlbDpDataSize total udpd
                    pshs      d         push argument
                    ldd       GlbVar002A total idpd
                    pshs      d         push argument
                    ldd       GlbVar001E total udat
                    pshs      d         push argument
                    ldd       GlbInitDataSize total idat
                    pshs      d         push argument
                    ldd       GlbVar002E total code
                    pshs      d         push argument
                    leax      MsgMapTotals,pcr totals line format
                    pshs      x         push format
                    lbsr      Printf    print totals line
                    leas      12,s       drop arguments
                    puls      pc,u,x    return

ReportUnresolved    pshs      u         save u
                    leax      >ListHeadAddress,y  unresolved list head
                    cmpx      >ListHeadAddress,y  is list empty
                    beq       NoUnresolved none so report done
                    leax      MsgUnresHeader,pcr unresolved header format
                    pshs      x         push format
                    leax      NameBuf,y output buffer
                    pshs      x         push destination
                    lbsr      Sprintf   print header
                    leas      4,s        drop arguments
                    ldu       >ListHeadAddress,y  first entry
                    bra       UnresTest enter loop

UnresLoop           ldx       NdNext,u     referencing module
                    ldd       NdName,x     module file name
                    pshs      d         push argument
                    ldd       NdNext,u     module pointer
                    pshs      d         push argument
                    pshs      u         push entry pointer
                    ldd       #$0004    name field offset
                    addd      ,s++      entry name pointer
                    pshs      d         push argument
                    leax      MsgUnresLine,pcr unresolved line format
                    pshs      x         push format
                    leax      NameBuf,y output buffer
                    pshs      x         push destination
                    lbsr      Sprintf   print reference line
                    leas      10,s       drop arguments
                    ldu       ,u        next entry
UnresTest           leax      >ListHeadAddress,y  list head address
                    pshs      x         save head
                    cmpu      ,s++      reached head again
                    bne       UnresLoop more entries
                    ldd       #$0001    unresolved references found
                    puls      pc,u      return

NoUnresolved        clra                result zero
                    clrb                clear low byte
                    puls      pc,u      return

                    puls      pc,u      return

ReadSymName         pshs      u         save u
                    ldu       $04,s     destination buffer
                    leas      -2,s       make local
                    bra       ReadNameTest enter loop

ReadNameLoop        ldd       ,s        current byte
                    stb       ,u+       store into buffer
ReadNameTest        ldd       GlbVar0038 input stream state
                    pshs      d         push argument
                    lbsr      GetByte   read next byte
                    leas      2,s        drop argument
                    std       ,s        save byte
                    bne       ReadNameLoop store until null
                    clra                null terminator
                    clrb                clear low byte
                    stb       ,u        terminate string
                    puls      pc,u,x    return

FinishOutput        pshs      u,d       save regs
                    ldd       OutputPathHandle,y   output path handle
                    std       ,s        save it
                    ldd       GlbVar003A temp file handle
                    beq       SkipTempFile none so skip
                    ldd       GlbVar003A temp file handle
                    pshs      d         push argument
                    lbsr      fclose    close temp file
                    leas      2,s        drop argument
                    ldd       OutputFileName,y   temp file name
                    pshs      d         push argument
                    lbsr      unlink    delete temp file
                    leas      2,s        drop argument
SkipTempFile        ldd       OutputPathHandle,y   output path handle
                    pshs      d         push argument
                    lbsr      exit      close output file
                    leas      2,s        drop argument
                    puls      pc,u,x    return

MsgLinkerFatal      fcc       /linker fatal: /
                    fcb       C$NULL
MsgCrNul            fcb       C$CR,C$NULL
MsgNeedBytes        fcc       /need %d bytes for linkbuf/
                    fcb       C$CR,C$NULL
MsgOutOfMem         fcc       /out of memory/
                    fcb       C$NULL
StrCode             fcc       /code/
                    fcb       C$NULL
StrUdat             fcc       /udat/
                    fcb       C$NULL
StrIdat             fcc       /idat/
                    fcb       C$NULL
StrUdpd             fcc       /udpd/
                    fcb       C$NULL
StrIdpd             fcc       /idpd/
                    fcb       C$NULL
StrUnknown          fcb       $3F,$3F,$3F
                    fcb       C$NULL
MsgMapHeader        fcc       /Linkage map for %s  File - %s/
                    fcb       C$NULL
MsgSectColumns      fcb       C$CR,C$CR
                    fcc       /Section          Code IDat UDat IDpD UDpD File/
                    fcb       C$CR,C$NULL
MsgModLine          fcc       /%-16s %04x %04x %04x %02x   %02x %s/
                    fcb       C$CR,C$NULL
MsgSectLine         fcc       /     %-9s %s %04x/
                    fcb       C$CR,C$NULL
MsgMapDashes        fcc       /                 ---- ---- ---- --/
                    fcb       C$NULL
MsgMapTotals        fcc       /                 %04x %04x %04x %02x  %02x/
                    fcb       C$CR,C$NULL
MsgUnresHeader      fcc       /Unresolved references:/
                    fcb       C$CR,C$NULL
MsgUnresLine        fcc       / %-16s %-16s in %-16s/
                    fcb       C$CR,C$NULL
SeekChunk           pshs      u         save u
                    ldu       >GlbVar005C,y  chunk list head
                    bra       SeekChunkTest enter loop

SeekChunkLoop       ldu       ,u        next chunk
                    ldd       $04,s     remaining count
                    subd      #$0007    decrement by seven
                    std       $04,s     save count
SeekChunkTest       ldd       $04,s     load count
                    ble       DrefCountCheck count exhausted done
                    stu       -$02,s    store node pointer into local temp
                    bne       SeekChunkLoop loop while node still non-null
DrefCountCheck      ldd       $04,s     load remaining node count
                    beq       DrefAllocDone done if none still needed
                    bra       DrefAllocTest enter block allocation loop test

DrefAllocLoop       ldd       #$0010    node block size of 16 bytes
                    pshs      d         pass size to allocator
                    lbsr      AllocMem  allocate a memory block
                    leas      2,s        drop the size argument
                    tfr       d,u       new block pointer into u
                    ldd       >GlbVar005C,y  current free list head
                    std       ,u        link old head into new block
                    stu       >GlbVar005C,y  new block becomes list head
                    ldd       $04,s     load remaining count
                    subd      #$0007    one block supplies seven nodes
                    std       $04,s     save decremented count
DrefAllocTest       ldd       $04,s     reload the count
                    bgt       DrefAllocLoop allocate again while more needed
DrefAllocDone       puls      pc,u      return to caller

FillWordsFFFF       pshs      u         save frame register
                    ldu       $04,s     load array pointer argument
                    bra       FillWordTest enter fill loop test

FillWordLoop        ldd       #$FFFF    free-slot marker value
                    std       ,u++      mark slot free, advance pointer
FillWordTest        ldd       $06,s     load remaining word count
                    addd      #$FFFF    decrement count by one
                    std       $06,s     save the count
                    subd      #$FFFF    test whether count was positive
                    bgt       FillWordLoop fill while slots remain
                    puls      pc,u      return to caller

FindFreeSlot        pshs      u         save frame register
                    ldu       $04,s     load array pointer argument
                    leas      -2,s       reserve local index slot
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        initialise index to zero
                    bra       FindFreeTest enter search loop test

FindFreeLoop        ldd       ,u        load current slot value
                    bge       FindFreeNext skip slot if in use
                    tfr       u,d       return pointer to free slot
                    puls      pc,u,x    return to caller

FindFreeNext        ldd       ,s        load loop index
                    addd      #$0001    increment index
                    std       ,s        save index
                    leau      $02,u     advance to next slot
FindFreeTest        ldd       ,s        load loop index
                    cmpd      #$0007    seven slots per node
                    blt       FindFreeLoop continue while slots remain
                    clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u,x    return zero, no free slot

AllocDref           pshs      u,d       save frame and value argument
                    ldd       [$06,s]   dereference node pointer
                    bne       AllocDrefSlot node already allocated
                    ldd       >GlbVar005C,y  take head of free list
                    std       [$06,s]   store node into caller slot
                    ldx       $06,s     pointer to node slot
                    ldd       [,x]      node link field
                    std       >GlbVar005C,y  advance free list head
                    clra                clear high byte
                    clrb                clear low byte
                    ldx       $06,s     node pointer
                    std       [,x]      clear node link field
                    ldd       #$0007    seven slots to initialise
                    pshs      d         pass slot count
                    ldd       [$08,s]   node data pointer
                    addd      #$0002    skip past link field
                    pshs      d         pass slot array pointer
                    lbsr      FillWordsFFFF initialise slots to $FFFF
                    leas      4,s        drop the arguments
AllocDrefSlot       ldd       [$06,s]   node pointer
                    addd      #$0002    skip past link field
                    pshs      d         pass slot array
                    lbsr      FindFreeSlot find a free slot
                    leas      2,s        drop the argument
                    std       ,s        save found slot pointer
                    bne       AllocDrefStore got a free slot
                    ldd       >GlbVar005C,y  free list head
                    bne       AllocDrefRelink nodes still available
                    leax      MsgOutOfDrefNodes,pcr point to out of dref nodes message
                    pshs      x         pass message pointer
                    lbsr      PrintErrMsg report fatal error
                    bra       AllocDrefUnstack branch to teardown

AllocDrefRelink     leas      -2,s       reserve local temp
                    ldd       >GlbVar005C,y  free list head
                    std       ,s        save it locally
                    ldd       [,s]      head node link
                    std       >GlbVar005C,y  advance free list head
                    ldd       [$08,s]   current node pointer
                    std       [,s]      chain node onto grabbed block
                    ldd       ,s        grabbed block pointer
                    std       [$08,s]   make it the current node
                    ldd       #$0007    seven slots to initialise
                    pshs      d         pass count
                    ldd       [$0a,s]   node data pointer
                    addd      #$0002    skip link field
                    std       $04,s     save array pointer
                    pshs      d         pass array pointer
                    lbsr      FillWordsFFFF initialise new node slots
                    leas      4,s        drop the arguments
AllocDrefUnstack    leas      2,s        drop the temp
AllocDrefStore      ldd       $08,s     value to store
                    std       [,s]      store value into free slot
                    puls      pc,u,x    return to caller

WalkDrefNodes       pshs      u         save frame register
                    ldu       $04,s     load node list head argument
                    leas      -4,s       reserve two locals
                    bra       WalkDrefNodeTest enter node walk test

WalkDrefStart       clra                clear high byte
                    clrb                clear low byte
                    std       $02,s     slot index zero
                    leax      $02,u     point at first slot
                    stx       ,s        save slot pointer
                    bra       WalkDrefSlotTest enter slot loop test

WalkDrefSlotLoop    ldd       [,s]      load slot value
                    cmpd      #$FFFF    empty slot marker
                    beq       WalkDrefNextNode skip empty slots
                    ldx       ,s        slot pointer
                    leax      $02,x     advance to next slot
                    stx       ,s        save slot pointer
                    ldd       -$02,x    value from current slot
                    pshs      d         pass value
                    bsr       EmitDrefWord emit word to output buffer
                    leas      2,s        drop the argument
                    bra       WalkDrefSlotNext continue to slot increment

WalkDrefSlotNext    ldd       $02,s     slot index
                    addd      #$0001    increment index
                    std       $02,s     save index
WalkDrefSlotTest    ldd       $02,s     slot index
                    cmpd      #$0007    seven slots per node
                    blt       WalkDrefSlotLoop process next slot
WalkDrefNextNode    ldu       ,u        follow link to next node
WalkDrefNodeTest    stu       -$02,s    save node pointer
                    bne       WalkDrefStart process next node
                    bsr       FlushDrefBuf flush the output buffer
                    leas      4,s        drop the locals
                    puls      pc,u      return to caller

EmitDrefWord        pshs      u         save frame register
                    ldd       $04,s     value to emit
                    ldx       GlbVar0008 output buffer pointer
                    leax      $02,x     advance buffer pointer
                    stx       GlbVar0008 save buffer pointer
                    std       -$02,x    store value into buffer
                    ldd       GlbVar005E buffer byte count
                    addd      #$0002    add one word
                    std       GlbVar005E save byte count
                    cmpd      #$0100    buffer full at 256 bytes
                    blt       EmitDrefDone not full yet
                    bsr       FlushDrefBuf flush the full buffer
EmitDrefDone        puls      pc,u      return to caller

FlushDrefBuf        pshs      u         save frame register
                    leax      >Buffer,y  point at output file path
                    pshs      x         pass path pointer
                    ldd       GlbVar005E buffer byte count
                    pshs      d         pass byte count
                    leax      OutputBuffer,y   point at output buffer
                    pshs      x         pass buffer pointer
                    lbsr      CalcCrc   accumulate into checksum
                    leas      6,s        drop the arguments
                    ldd       GlbVar003A output file path number
                    pshs      d         pass path number
                    ldd       #$0001    write-mode argument
                    pshs      d         pass mode
                    ldd       GlbVar005E buffer byte count
                    pshs      d         pass byte count
                    leax      OutputBuffer,y   point at output buffer
                    pshs      x         pass buffer pointer
                    lbsr      FWrite    write buffer to file
                    leas      8,s        drop the arguments
                    lbsr      ErrWriteFile check for write error
                    leax      OutputBuffer,y   reset buffer to start
                    stx       GlbVar0008 save buffer pointer
                    clra                clear high byte
                    clrb                clear low byte
                    std       GlbVar005E reset byte count
                    puls      pc,u      return to caller

MsgOutOfDrefNodes   fcc       /out of dref nodes/
                    fcb       C$NULL
FindFreeSeg         pshs      u         save frame register
                    leau      SegmentTableStart,y   point at segment table start
FindFreeSegLoop     ldd       $06,u     entry flag word
                    clra                clear high byte
                    andb      #$03      mask the type bits
                    lbeq      SegReturnEntry free entry found
                    leau      $0d,u     advance one 13-byte entry
                    pshs      u         save entry pointer
                    leax      TableEnd,y   point at table end
                    cmpx      ,s++      compare against entry pointer
                    bhi       FindFreeSegLoop scan next entry if within table
                    ldd       #$00C8    table full error 200
                    std       OutputPathHandle,y   set error code
                    lbra      SegReturnNull return null

                    puls      pc,u      unreachable return

AddSegEntry         pshs      u         save frame register
                    ldu       $08,s     existing entry argument
                    bne       GotSegEntry already have an entry
                    bsr       FindFreeSeg find a free entry
                    tfr       d,u       entry pointer into u
GotSegEntry         stu       -$02,s    save entry pointer
                    beq       SegReturnNull none available, return zero
                    ldd       $04,s     value argument
                    std       $08,u     store value into entry
                    ldx       $06,s     name pointer
                    ldb       $01,x     second name character
                    cmpb      #$2b      compare against plus
                    beq       SegSetTypeBits plus flags both type bits
                    ldx       $06,s     name pointer
                    ldb       $02,x     third name character
                    cmpb      #$2b      compare against plus
                    bne       SegCheckName no plus, derive type from name
SegSetTypeBits      ldd       $06,u     entry flag word
                    orb       #$03      set both type bits
                    bra       SegStoreFlags store the flags

SegCheckName        ldd       $06,u     entry flag word
                    pshs      d         save flags
                    ldb       [$08,s]   first name character
                    cmpb      #'r       compare against r
                    beq       SegTypeOne read section, type 1
                    ldb       [$08,s]   first name character
                    cmpb      #'d       compare against d
                    bne       SegTypeTwo neither, use type 2
SegTypeOne          ldd       #$0001    read or data section type
                    bra       SegTypeMerge merge into flags

SegTypeTwo          ldd       #$0002    other section type
SegTypeMerge        ora       ,s+       merge high byte with saved flags
                    orb       ,s+       merge low byte with saved flags
SegStoreFlags       std       $06,u     store entry flags
                    ldd       $02,u     entry base address
                    addd      $0b,u     add section size
                    std       $04,u     set entry end address
                    std       ,u        set entry current address
SegReturnEntry      tfr       u,d       return entry pointer
                    puls      pc,u      return to caller

SegReturnNull       clra                clear high byte
                    clrb                clear low byte
                    puls      pc,u      return zero

ParseSectAttr       pshs      u         save frame register
                    ldu       $04,s     load spec argument
                    leas      -4,s       reserve two locals
                    clra                clear high byte
                    clrb                clear low byte
                    std       ,s        clear section type local
                    ldx       $0a,s     spec string pointer
                    ldb       $01,x     second character
                    sex                 sign extend to word
                    tfr       d,x       move into index register
                    bra       SpecDispatch dispatch on prefix character

SpecXPlus           ldx       $0a,s     spec string pointer
                    ldb       $02,x     third character
                    cmpb      #$2b      compare against plus
                    bne       SpecXPlain no trailing plus
                    ldd       #$0007    x-plus section type 7
                    bra       SpecSetType store the type

SpecXPlain          ldd       #$0004    plain x section type 4
                    bra       SpecSetType store the type

SpecPlus            ldd       #$0003    plus prefix section type 3
SpecSetType         std       ,s        save the section type
                    bra       SpecAttrChar parse the attribute letter

SpecBadPrefix       leax      $04,s     compute stack restore pointer
                    lbra      SpecErrExit report bad spec error

SpecDispatch        stx       -$02,s    save the prefix character
                    beq       SpecAttrChar no prefix, parse attribute
                    cmpx      #$0078    compare against x
                    beq       SpecXPlus handle x prefix
                    cmpx      #$002B    compare against plus
                    beq       SpecPlus  handle plus prefix
                    bra       SpecBadPrefix invalid prefix, error

SpecAttrChar        ldb       [$0a,s]   attribute letter
                    sex                 sign extend to word
                    tfr       d,x       move into index register
                    lbra      AttrDispatch dispatch on attribute letter

AttrRead            ldd       ,s        section type flags
                    orb       #$01      mark section readable
                    bra       AttrLookup install via common lookup

AttrAlloc           ldd       ,s        section type flags
                    orb       #$02      mark section allocatable
                    pshs      d         save flags
                    pshs      u         save spec argument
                    lbsr      open      look up the section
                    leas      4,s        drop the arguments
                    std       $02,s     save lookup result
                    cmpd      #$FFFF    section not found
                    beq       AttrWrite create writable section instead
                    ldd       #$0002    registration flag two
                    pshs      d         pass flag
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         pass zero argument
                    pshs      d         pass zero argument
                    ldd       $08,s     section pointer argument
                    pshs      d         pass section pointer
                    lbsr      lseek     register the section
                    leas      8,s        drop the arguments
                    bra       SpecReturnVal return result

AttrWrite           ldd       ,s        section type flags
                    orb       #$0b      mark write and bss
                    pshs      d         save flags
                    pshs      u         save spec argument
                    lbsr      CreatePath create the section
                    bra       AttrStoreResult finish install

AttrData            ldd       ,s        section type flags
                    orb       #$81      mark data section
AttrLookup          pshs      d         save flags
                    pshs      u         save spec argument
                    lbsr      open      look up the section
AttrStoreResult     leas      4,s        drop the arguments
                    std       $02,s     save lookup result
                    bra       SpecReturnVal return result

SpecErrExit         leas      -$04,x    restore the stack pointer
SpecError           ldd       #$00CB    bad attribute error 203
                    std       OutputPathHandle,y   set error code
                    clra                clear high byte
                    clrb                clear low byte
                    bra       SpecReturn return zero

AttrDispatch        cmpx      #$0072    compare against r
                    lbeq      AttrRead  read attribute
                    cmpx      #$0061    compare against a
                    lbeq      AttrAlloc alloc attribute
                    cmpx      #$0077    compare against w
                    beq       AttrWrite write attribute
                    cmpx      #$0064    compare against d
                    beq       AttrData  data attribute
                    bra       SpecError unknown attribute error

SpecReturnVal       ldd       $02,s     load result value
SpecReturn          leas      4,s        drop the locals
                    puls      pc,u      return to caller

                    pshs      u         save frame register
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push zero argument
                    ldd       $08,s     spec argument
                    pshs      d         pass spec
                    ldd       $08,s     spec argument
                    pshs      d         pass spec
                    lbra      WalkExprAddSeg jump into shared body

WalkExprNode        pshs      u         save frame register
                    ldd       $06,s     spec argument
                    pshs      d         pass spec
                    ldd       $06,s     spec argument
                    pshs      d         pass spec
                    lbsr      ParseSectAttr parse section attribute spec
                    leas      4,s        drop the arguments
                    tfr       d,u       result pointer into u
                    cmpu      #$FFFF    compare against error marker
                    bne       WalkExprInit parse succeeded
                    clra                clear high byte
                    clrb                clear low byte
                    bra       ProcDone  return zero

WalkExprInit        clra                clear high byte
                    clrb                clear low byte
                    bra       WalkExprEmitBody enter shared emit body

WalkExprLoop        pshs      u         save frame register
                    ldd       $08,s     token argument
                    pshs      d         pass token
                    lbsr      fclose    process the token
                    leas      2,s        drop the argument
                    ldd       $06,s     spec argument
                    pshs      d         pass spec
                    ldd       $06,s     spec argument
                    pshs      d         pass spec
                    lbsr      ParseSectAttr parse section attribute spec
                    leas      4,s        drop the arguments
                    tfr       d,u       result pointer
                    stu       -$02,s    save result pointer
                    bge       WalkExprEmit valid section entry
                    clra                clear high byte
                    clrb                clear low byte
                    bra       ProcDone  return zero

WalkExprEmit        ldd       $08,s     value argument
WalkExprEmitBody    pshs      d         pass value
                    ldd       $08,s     value argument
                    pshs      d         pass value
                    pshs      u         pass frame register
WalkExprAddSeg      lbsr      AddSegEntry add the segment entry
                    leas      6,s        drop the three call arguments
ProcDone            puls      pc,u      return from the message routine

PutMsgLine          pshs      u         save frame pointer
                    leax      MessageWorkBuffer,y   point to message work buffer
                    pshs      x         pass buffer as the stream
                    ldd       $06,s     get the string argument
                    pshs      d         pass the string
                    bsr       WriteString write string into the buffer
                    leas      4,s        drop the two arguments
                    leax      MessageWorkBuffer,y   point to message buffer again
                    pshs      x         pass buffer as the stream
                    ldd       #$000D    carriage return character
                    pshs      d         pass the newline char
                    lbsr      PutByte   append the newline
                    leas      4,s        drop the two arguments
                    puls      pc,u      return

WriteString         pshs      u         save frame pointer
                    ldu       $04,s     point at the source string
                    leas      -1,s       reserve one local byte
                    bra       WriteStringLoop enter the copy loop

PutNextChar         ldd       $07,s     get the destination stream
                    pshs      d         pass the stream
                    ldb       $02,s     get the current char
                    sex                 widen char to sixteen bits
                    pshs      d         pass the char
                    lbsr      PutByte   emit char to the stream
                    leas      4,s        drop the two arguments
WriteStringLoop     ldb       ,u+       fetch next source byte
                    stb       ,s        stash it in the local
                    bne       PutNextChar emit until null terminator
                    leas      1,s        release the local byte
                    puls      pc,u      return

FRead               pshs      u         save frame pointer
                    ldu       $04,s     point at the destination buffer
                    leas      -6,s       reserve locals
                    clra                clear items-read high byte
                    clrb                clear items-read low byte
                    bra       FReadCountTop enter the item count loop

FReadItemLoop       ldd       $0C,s     load the item size
                    std       $04,s     set the inner byte counter
                    bra       FReadByteTop enter the byte read loop

FReadByteLoop       ldd       $10,s     get the stream
                    pshs      d         pass the stream
                    lbsr      GetByte   read one byte from the stream
                    leas      2,s        drop the stream argument
                    std       ,s        save the byte read
                    cmpd      #$FFFF    check for end of file
                    beq       ReadLoopDone stop on eof
                    ldd       ,s        reload the byte
                    stb       ,u+       store it into the buffer
FReadByteTop        ldd       $04,s     reload inner byte counter
                    addd      #$FFFF    decrement it
                    std       $04,s     save the counter
                    subd      #$FFFF    test remaining bytes
                    bgt       FReadByteLoop read next byte of item
                    ldd       $02,s     reload item counter
                    addd      #$0001    count this completed item
FReadCountTop       std       $02,s     save the item counter
                    ldd       $02,s     reload the item count
                    cmpd      $0e,s     compare against requested items
                    blt       FReadItemLoop read the next item
ReadLoopDone        ldd       $02,s     return items actually read
                    leas      6,s        release locals
                    puls      pc,u      return

FWrite              pshs      u         save frame pointer
                    ldu       $04,s     point at the source buffer
                    leas      -4,s       reserve locals
                    clra                clear items-written high byte
                    clrb                clear items-written low byte
                    bra       FWriteCountTop enter the item count loop

FWriteItemLoop      clra                clear inner byte index high
                    clrb                clear inner byte index low
                    std       ,s        reset the byte index
                    bra       FWriteByteTop enter the byte write loop

FWriteByteLoop      ldd       $0e,s     get the stream
                    pshs      d         pass the stream
                    ldb       ,u+       fetch next source byte
                    sex                 widen to sixteen bits
                    pshs      d         pass the byte
                    lbsr      PutByte   emit byte to the stream
                    leas      4,s        drop the two arguments
                    ldx       $0e,s     reload the stream pointer
                    ldd       $06,x     get the stream flags
                    clra                isolate the flag low byte
                    andb      #$20      test the error flag
                    bne       FWriteDone stop on write error
FWriteByteTop       ldd       ,s        reload inner byte index
                    addd      #$0001    advance it
                    std       ,s        save the index
                    subd      #$0001    restore the index value
                    cmpd      $0a,s     compare to item size
                    blt       FWriteByteLoop write next byte of item
                    ldd       $02,s     reload item counter
                    addd      #$0001    count this completed item
FWriteCountTop      std       $02,s     save the item counter
                    ldd       $02,s     reload the item count
                    cmpd      $0C,s     compare against requested items
                    blt       FWriteItemLoop write the next item
FWriteDone          ldd       $02,s     return items written
                    leas      4,s        release locals
                    puls      pc,u      return

Printf              pshs      u         save frame pointer
                    leax      MessageWorkBuffer,y   point at message work buffer
                    stx       OutputPointer2,y   set output pointer to it
                    leax      $06,s     point past the format argument
                    pshs      x         pass the vararg pointer
                    ldd       $06,s     get the format string
                    bra       FormatBufBody go format

Sprintf             pshs      u         save frame pointer
                    ldd       $04,s     get the caller buffer
                    std       OutputPointer2,y   set output pointer to it
                    leax      $08,s     point past the format argument
                    pshs      x         pass the vararg pointer
                    ldd       $08,s     get the format string
FormatBufBody       pshs      d         pass the format string
                    leax      PutCharStream,pcr buffer-store output callback
                    pshs      x         pass the callback
                    bsr       DoFormat  run the formatter
                    leas      6,s        drop the three arguments
                    puls      pc,u      return

                    pshs      u         save frame pointer
                    ldd       $04,s     get the caller buffer
                    std       OutputPointer2,y   set output pointer to it
                    leax      $08,s     point past the format argument
                    pshs      x         pass the vararg pointer
                    ldd       $08,s     get the format string
                    pshs      d         pass the format string
                    leax      PutCharBuf,pcr terminating-store callback
                    pshs      x         pass the callback
                    bsr       DoFormat  run the formatter
                    leas      6,s        drop the three arguments
                    clra                null high byte
                    clrb                null low byte
                    stb       [OutputPointer2,y] null terminate the string
                    ldd       $04,s     return the buffer pointer
                    puls      pc,u      return

DoFormat            pshs      u         save frame pointer
                    ldu       $06,s     point at the format string
                    leas      -11,s      reserve format state locals
                    bra       FormatScanLoop enter the scan loop

EmitLiteral         ldb       $08,s     get the current char
                    lbeq      FmtDispatchRet done at end of string
                    ldb       $08,s     reload the char
                    sex                 widen to sixteen bits
                    pshs      d         pass the char
                    jsr       [$11,s]   emit literal char via callback
                    leas      2,s        drop the argument
FormatScanLoop      ldb       ,u+       fetch next format byte
                    stb       $08,s     save the current char
                    cmpb      #'%       is it a percent sign
                    bne       EmitLiteral emit literal if not
                    ldb       ,u+       get the conversion char
                    stb       $08,s     save it
                    clra                clear precision high
                    clrb                clear precision low
                    std       $02,s     reset the precision
                    std       $06,s     reset the width
                    ldb       $08,s     reload the conversion char
                    cmpb      #$2d      is it a minus flag
                    bne       NoLeftJust skip if no left-justify
                    ldd       #$0001    true value
                    std       LeftJustifyFlag,y   set the left-justify flag
                    ldb       ,u+       advance past the flag char
                    stb       $08,s     save the next char
                    bra       CheckZeroPad go check the pad char

NoLeftJust          clra                false value high
                    clrb                false value low
                    std       LeftJustifyFlag,y   clear the left-justify flag
CheckZeroPad        ldb       $08,s     reload the current char
                    cmpb      #'0       is it a zero
                    bne       UseSpacePad use space padding otherwise
                    ldd       #$0030    zero pad character
                    bra       StorePadChar go store the pad char

UseSpacePad         ldd       #$0020    space pad character
StorePadChar        std       PadCharacter,y   set the pad character
                    bra       WidthDigitTest go parse width digits

WidthDigitLoop      ldd       $06,s     reload the current width
                    pshs      d         pass the width
                    ldd       #$000A    base ten
                    lbsr      MulEntry  multiply width by ten
                    pshs      d         pass the product
                    ldb       $0a,s     reload the digit char
                    sex                 widen it
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add to width times ten
                    std       $06,s     save the new width
                    ldb       ,u+       fetch next format char
                    stb       $08,s     save it
WidthDigitTest      ldb       $08,s     reload the current char
                    sex                 widen for indexing
                    leax      CtypeTab,y character class table
                    leax      d,x       index by the char
                    ldb       ,x        get the class bits
                    clra                isolate the low byte
                    andb      #$08      test the digit class
                    bne       WidthDigitLoop accumulate another width digit
                    ldb       $08,s     reload the current char
                    cmpb      #$2e      is it a period
                    bne       NoPrecision no precision given
                    ldd       #$0001    mark precision present
                    std       $04,s     save the flag
                    bra       PrecDigitTest go parse precision digits

PrecDigitLoop       ldd       $02,s     reload the current precision
                    pshs      d         pass the precision
                    ldd       #$000A    base ten
                    lbsr      MulEntry  multiply precision by ten
                    pshs      d         pass the product
                    ldb       $0a,s     reload the digit char
                    sex                 widen it
                    addd      #$FFD0    subtract ascii zero
                    addd      ,s++      add to precision times ten
                    std       $02,s     save the new precision
PrecDigitTest       ldb       ,u+       fetch next format char
                    stb       $08,s     save it
                    ldb       $08,s     reload the char
                    sex                 widen for indexing
                    leax      CtypeTab,y character class table
                    leax      d,x       index by the char
                    ldb       ,x        get the class bits
                    clra                isolate the low byte
                    andb      #$08      test the digit class
                    bne       PrecDigitLoop accumulate another precision digit
                    bra       GetConvChar done parsing precision

NoPrecision         clra                no precision high
                    clrb                no precision low
                    std       $04,s     clear the precision flag
GetConvChar         ldb       $08,s     reload the conversion char
                    sex                 widen to sixteen bits
                    tfr       d,x       conversion char into X
                    lbra      DispatchConv dispatch on the conversion

FmtDecimal          ldd       $06,s     reload the width
                    pshs      d         save width for output
                    ldx       $15,s     load vararg pointer
                    leax      $02,x     advance past this arg
                    stx       $15,s     save updated vararg pointer
                    ldd       -$02,x    fetch the integer argument
                    pshs      d         pass the value
                    lbsr      ConvSignedDec convert to signed decimal
                    bra       ConvDone  go output the result

FmtOctal            ldd       $06,s     reload the width
                    pshs      d         save width for output
                    ldx       $15,s     load vararg pointer
                    leax      $02,x     advance past this arg
                    stx       $15,s     save updated vararg pointer
                    ldd       -$02,x    fetch the integer argument
                    pshs      d         pass the value
                    lbsr      ConvOctal convert to octal
ConvDone            std       ,s        save converted string pointer
                    lbra      OutputField go output the field

FmtHex              ldd       $06,s     reload the width
                    pshs      d         save width for output
                    ldb       $0a,s     reload the conversion char
                    sex                 widen for indexing
                    leax      CtypeTab,y character class table
                    leax      d,x       index by the char
                    ldb       ,x        get the class bits
                    clra                isolate the low byte
                    andb      #$02      test the uppercase class
                    pshs      d         pass the case flag
                    ldx       $17,s     load vararg pointer
                    leax      $02,x     advance past this arg
                    stx       $17,s     save updated vararg pointer
                    ldd       -$02,x    fetch the integer argument
                    pshs      d         pass the value
                    lbsr      ConvHex   convert to hexadecimal
                    lbra      PopConvArgs go output the field

FmtUnsigned         ldd       $06,s     reload the width
                    pshs      d         save width for output
                    ldx       $15,s     load vararg pointer
                    leax      $02,x     advance past this arg
                    stx       $15,s     save updated vararg pointer
                    ldd       -$02,x    fetch the integer argument
                    pshs      d         pass the value
                    leax      NumberBuffer,y   conversion output buffer
                    pshs      x         pass the output buffer
                    lbsr      ConvUnsignedDec convert to unsigned decimal
                    lbra      PopConvArgs go output the field

FmtFloat            ldd       $04,s     test precision-present flag
                    bne       FloatConvert keep the given precision
                    ldd       #$0006    default precision of six
                    std       $02,s     set the precision
FloatConvert        ldd       $06,s     reload the width
                    pshs      d         pass the width
                    leax      $15,s     point at the vararg pointer
                    pshs      x         pass its address
                    ldd       $06,s     reload the precision
                    pshs      d         pass the precision
                    ldb       $0e,s     reload the conversion char
                    sex                 widen it
                    pshs      d         pass the conversion letter
                    lbsr      StrlenThunk+1 convert the floating point value
                    leas      6,s        drop the arguments
                    lbra      PushConvResult go output the field

FmtChar             ldx       $13,s     load vararg pointer
                    leax      $02,x     advance past this arg
                    stx       $13,s     save updated vararg pointer
                    ldd       -$02,x    fetch the char argument
                    lbra      EmitOneChar emit it directly

FmtString           ldx       $13,s     load vararg pointer
                    leax      $02,x     advance past this arg
                    stx       $13,s     save updated vararg pointer
                    ldd       -$02,x    fetch the string pointer arg
                    std       $09,s     save the string pointer
                    ldd       $04,s     test precision-present flag
                    beq       EmitStringNoPrec no length limit
                    ldd       $09,s     reload the string pointer
                    std       $04,s     use it as the scan pointer
                    bra       StrLenTop go measure the length

StrLenLoop          ldb       [$09,s]   current string byte
                    beq       EmitPaddedString stop at the null
                    ldd       $09,s     reload the scan pointer
                    addd      #$0001    advance it
                    std       $09,s     save the pointer
StrLenTop           ldd       $02,s     remaining precision count
                    addd      #$FFFF    decrement it
                    std       $02,s     save the count
                    subd      #$FFFF    test remaining
                    bne       StrLenLoop keep scanning characters
EmitPaddedString    ldd       $06,s     reload the field width
                    pshs      d         pass the width
                    ldd       $0b,s     end scan pointer
                    subd      $06,s     compute the string length
                    pshs      d         pass the length
                    ldd       $08,s     reload the string pointer
                    pshs      d         pass the string
                    ldd       $15,s     reload vararg pointer
                    pshs      d         pass it
                    lbsr      EmitFieldCb output the padded string
                    leas      8,s        drop the arguments
                    bra       BackToScan back to the scan loop

EmitStringNoPrec    ldd       $06,s     reload the field width
                    pshs      d         pass the width
                    ldd       $0b,s     reload the string pointer
                    bra       PushConvResult go output the field

FmtLong             ldb       ,u+       get the long conversion char
                    stb       $08,s     save it
                    bra       LongConvert handle the long value

                    leas      -$0b,x    unreachable stray instruction
LongConvert         ldd       $06,s     reload the width
                    pshs      d         pass the width
                    leax      $15,s     point at the vararg pointer
                    pshs      x         pass its address
                    ldb       $0C,s     reload the conversion char
                    sex                 widen it
                    pshs      d         pass the conversion letter
                    lbsr      SelectFormat convert the long value
PopConvArgs         leas      4,s        drop the extra arguments
PushConvResult      pshs      d         pass the converted string
OutputField         ldd       $13,s     reload the field width
                    pshs      d         pass the width
                    lbsr      EmitStrField output the padded field
                    leas      6,s        drop the arguments
BackToScan          lbra      FormatScanLoop back to the scan loop

FmtUnknown          ldb       $08,s     reload the format char
                    sex                 widen to sixteen bits
EmitOneChar         pshs      d         pass the char
                    jsr       [$11,s]   emit it via the callback
                    leas      2,s        drop the argument
                    lbra      FormatScanLoop back to the scan loop

DispatchConv        cmpx      #$0064    is the conversion d
                    lbeq      FmtDecimal do signed decimal
                    cmpx      #$006F    is the conversion o
                    lbeq      FmtOctal  do octal
                    cmpx      #$0078    is the conversion x
                    lbeq      FmtHex    do hexadecimal
                    cmpx      #$0058    is the conversion X
                    lbeq      FmtHex    do hexadecimal
                    cmpx      #$0075    is the conversion u
                    lbeq      FmtUnsigned do unsigned decimal
                    cmpx      #$0066    is the conversion f
                    lbeq      FmtFloat  do floating point
                    cmpx      #$0065    is the conversion e
                    lbeq      FmtFloat  do floating point
                    cmpx      #$0067    is the conversion g
                    lbeq      FmtFloat  do floating point
                    cmpx      #$0045    is the conversion E
                    lbeq      FmtFloat  dispatch matched format specifier
                    cmpx      #$0047    compare specifier with capital G
                    lbeq      FmtFloat  dispatch capital-G conversion
                    cmpx      #$0063    compare specifier with c
                    lbeq      FmtChar   dispatch character conversion
                    cmpx      #$0073    compare specifier with s
                    lbeq      FmtString dispatch string conversion
                    cmpx      #$006C    compare specifier with l modifier
                    lbeq      FmtLong   dispatch long modifier
                    bra       FmtUnknown fall through on unknown specifier

FmtDispatchRet      leas      11,s       drop the local frame
                    puls      pc,u      return from the dispatcher

ConvSignedDec       pshs      u,d       save registers and reserve a local
                    leax      NumberBuffer,y   point to the number buffer
                    stx       ,s        save the buffer pointer
                    ldd       $06,s     load the signed value
                    bge       ConvDecBody non-negative skips sign handling
                    ldd       $06,s     reload the negative value
                    nega                negate the value
                    negb                negate the value
                    sbca      #$00      complete the two-byte negation
                    std       $06,s     store the absolute value
                    bge       StoreMinusSign still negative means it was the minimum
                    leax      MsgIntMin,pcr point to the -32768 literal
                    pshs      x         push source string
                    leax      NumberBuffer,y   push destination buffer
                    pshs      x         push destination buffer
                    lbsr      strcpy    copy the literal into the buffer
                    leas      4,s        drop the call arguments
                    puls      pc,u,x    return the buffer

StoreMinusSign      ldd       #$002D    load the minus sign character
                    ldx       ,s        load the buffer pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save the pointer
                    stb       -$01,x    write the minus sign
ConvDecBody         ldd       $06,s     load the absolute value
                    pshs      d         push the value argument
                    ldd       $02,s     load the buffer pointer
                    pshs      d         push the buffer argument
                    bsr       ConvUnsignedDec convert the magnitude to decimal
                    leas      4,s        drop the arguments
                    leax      NumberBuffer,y   point to the number buffer
                    tfr       x,d       return the buffer pointer
                    puls      pc,u,x    return

ConvUnsignedDec     pshs      u,y,x,d   save registers and reserve locals
                    ldu       $0a,s     load the output buffer pointer
                    clra                clear the significant-digit flag
                    clrb                clear the significant-digit flag
                    std       $02,s     store the cleared flag
                    clra                clear the digit counter
                    clrb                clear the digit counter
                    std       ,s        store the cleared counter
                    bra       DecPrimeTest enter the priming test

DecPrimeLoop        ldd       ,s        count another priming subtraction
                    addd      #$0001    increment the counter
                    std       ,s        save the counter
                    ldd       $0C,s     load the running value
                    subd      >Pow10,y  subtract the leading power of ten
                    std       $0C,s     save the running value
DecPrimeTest        ldd       $0C,s     reload the running value
                    blt       DecPrimeLoop keep priming while negative
                    leax      >Pow10,y  point to the powers-of-ten table
                    stx       $04,s     save the table pointer
                    bra       DecPowerTest enter the division loop

DecDigitCount       ldd       ,s        advance the current digit
                    addd      #$0001    increment the digit
                    std       ,s        save the digit
DecSubLoop          ldd       $0C,s     load the remaining value
                    subd      [$04,s]   subtract the current power of ten
                    std       $0C,s     save the remainder
                    bge       DecDigitCount repeat while still non-negative
                    ldd       $0C,s     overshot the last subtraction
                    addd      [$04,s]   add the power back
                    std       $0C,s     restore the remainder
                    ldd       ,s        check the digit count
                    beq       DecMarkDigit leading zero stays suppressed
                    ldd       #$0001    mark a significant digit seen
                    std       $02,s     store the significant flag
DecMarkDigit        ldd       $02,s     load the significant flag
                    beq       DecNextPower suppress leading zeros
                    ldd       ,s        load the digit value
                    addd      #$0030    convert digit to ascii
                    stb       ,u+       store the digit character
DecNextPower        clra                reset the digit count
                    clrb                reset the digit count
                    std       ,s        store the cleared count
                    ldd       $04,s     load the table pointer
                    addd      #$0002    advance to the next power
                    std       $04,s     save the table pointer
DecPowerTest        ldd       $04,s     load the table pointer
                    cmpd      OnesPlace,y   reached the ones place
                    bne       DecSubLoop continue with the next power
                    ldd       $0C,s     load the final remainder
                    addd      #$0030    convert to ascii
                    stb       ,u+       store the last digit
                    clra                prepare the terminator
                    clrb                prepare the terminator
                    stb       ,u        null-terminate the buffer
                    ldd       $0a,s     return the buffer pointer
                    leas      6,s        drop the locals
                    puls      pc,u      return

ConvOctal           pshs      u,d       save registers and reserve a local
                    leax      NumberBuffer,y   point to the number buffer
                    stx       ,s        save the buffer pointer
                    leau      DigitScratchBuffer,y   point to the digit scratch buffer
OctDigitLoop        ldd       $06,s     load the value
                    clra                clear high byte
                    andb      #$07      isolate the low octal digit
                    addd      #$0030    convert to ascii
                    stb       ,u+       store digit into scratch reversed
                    ldd       $06,s     reload the value
                    lsra                shift right one bit
                    rorb                shift right one bit
                    lsra                shift right one bit
                    rorb                shift right one bit
                    lsra                shift right one bit
                    rorb                shift right three bits total
                    std       $06,s     save the shifted value
                    bne       OctDigitLoop more octal digits remain
                    bra       OctCopyTest enter the reverse-copy test

OctCopyLoop         ldb       ,u        read a scratch digit
                    ldx       ,s        load the buffer pointer
                    leax      $01,x     advance the pointer
                    stx       ,s        save the pointer
                    stb       -$01,x    copy the digit into the buffer
OctCopyTest         leau      -$01,u    back up the scratch pointer
                    pshs      u         push it for comparison
                    leax      DigitScratchBuffer,y   point to the scratch start
                    cmpx      ,s++      reached the start
                    bls       OctCopyLoop copy digits in reverse order
                    clra                prepare the terminator
                    clrb                prepare the terminator
                    stb       [,s]      null-terminate the buffer
                    leax      NumberBuffer,y   point to the number buffer
                    tfr       x,d       return the pointer
                    puls      pc,u,x    return

ConvHex             pshs      u,x,d     save registers and reserve locals
                    leax      NumberBuffer,y   point to the number buffer
                    stx       $02,s     save the buffer pointer
                    leau      DigitScratchBuffer,y   point to the digit scratch buffer
HexDigitLoop        ldd       $08,s     load the value
                    clra                clear high byte
                    andb      #$0f      isolate the low hex nibble
                    std       ,s        save the nibble
                    pshs      d         push the nibble
                    ldd       $02,s     load the nibble value
                    cmpd      #$0009    digit or letter range
                    ble       HexDigitBase take the digit path for 0-9
                    ldd       $0C,s     load the case flag
                    beq       HexLowerBase zero flag selects lowercase
                    ldd       #$0041    uppercase letter base
                    bra       HexAlphaAdj apply the letter adjustment

HexLowerBase        ldd       #$0061    lowercase letter base
HexAlphaAdj         addd      #$FFF6    adjust the letter base down by ten
                    bra       HexStoreDigit add the nibble

HexDigitBase        ldd       #$0030    ascii zero base for a digit
HexStoreDigit       addd      ,s++      add the nibble and pop
                    stb       ,u+       store the hex character reversed
                    ldd       $08,s     reload the value
                    lsra                shift right one bit
                    rorb                shift right one bit
                    lsra                shift right one bit
                    rorb                shift right one bit
                    lsra                shift right one bit
                    rorb                shift right one bit
                    lsra                shift right one bit
                    rorb                shift right four bits total
                    anda      #$0f      mask off the shifted-in high bits
                    std       $08,s     save the shifted value
                    bne       HexDigitLoop more hex nibbles remain
                    bra       HexCopyTest enter the reverse-copy test

HexCopyLoop         ldb       ,u        read a scratch nibble
                    ldx       $02,s     load the buffer pointer
                    leax      $01,x     advance the pointer
                    stx       $02,s     save the pointer
                    stb       -$01,x    copy the nibble into the buffer
HexCopyTest         leau      -$01,u    back up the scratch pointer
                    pshs      u         push it for comparison
                    leax      DigitScratchBuffer,y   point to the scratch start
                    cmpx      ,s++      reached the start
                    bls       HexCopyLoop copy nibbles in reverse order
                    clra                prepare the terminator
                    clrb                prepare the terminator
                    stb       [$02,s]   null-terminate the buffer
                    leax      NumberBuffer,y   point to the number buffer
                    tfr       x,d       return the pointer
                    lbra      FmtStrRet return via the shared exit

EmitFieldCb         pshs      u         save the callback register
                    ldu       $06,s     load the source string pointer
                    ldd       $0a,s     load the field width
                    subd      $08,s     subtract the string length
                    std       $0a,s     save the pad count
                    ldd       LeftJustifyFlag,y   load the left-justify flag
                    bne       EmitCharTest left-justified skips leading pad
                    bra       PadLeftTest enter the leading-pad test

PadLeftLoop         ldd       PadCharacter,y   load the pad character
                    pshs      d         push it as the argument
                    jsr       [$06,s]   output the pad character
                    leas      2,s        drop the argument
PadLeftTest         ldd       $0a,s     load the pad count
                    addd      #$FFFF    decrement the count
                    std       $0a,s     save the count
                    subd      #$FFFF    test for remaining padding
                    bgt       PadLeftLoop more leading padding
                    bra       EmitCharTest proceed to character emission

EmitCharLoop        ldb       ,u+       load the next string character
                    sex                 sign-extend to a word
                    pshs      d         push it as the argument
                    jsr       [$06,s]   output the character
                    leas      2,s        drop the argument
EmitCharTest        ldd       $08,s     load the length counter
                    addd      #$FFFF    decrement the count
                    std       $08,s     save the count
                    subd      #$FFFF    test for remaining characters
                    bne       EmitCharLoop more characters to emit
                    ldd       LeftJustifyFlag,y   load the left-justify flag
                    beq       EmitFieldDone right-justified needs no trailing pad
                    bra       PadRightTest enter the trailing-pad test

PadRightLoop        ldd       PadCharacter,y   load the pad character
                    pshs      d         push it as the argument
                    jsr       [$06,s]   output the trailing pad
                    leas      2,s        drop the argument
PadRightTest        ldd       $0a,s     load the pad count
                    addd      #$FFFF    decrement the count
                    std       $0a,s     save the count
                    subd      #$FFFF    test for remaining padding
                    bgt       PadRightLoop more trailing padding
EmitFieldDone       puls      pc,u      return

EmitStrField        pshs      u         save the callback register
                    ldu       $06,s     load the string pointer
                    ldd       $08,s     load the field width
                    pshs      d         push the width
                    pshs      u         push the string pointer
                    lbsr      strlen+1  measure the string length
                    leas      2,s        drop the argument
                    nega                negate the length
                    negb                negate the length
                    sbca      #$00      complete the negation
                    addd      ,s++      width minus length gives pad count
                    std       $08,s     save the pad count
                    ldd       LeftJustifyFlag,y   load the left-justify flag
                    bne       SEmitCharTest left-justified skips leading pad
                    bra       SPadLeftTest enter the leading-pad test

SPadLeftLoop        ldd       PadCharacter,y   load the pad character
                    pshs      d         push it as the argument
                    jsr       [$06,s]   output the pad character
                    leas      2,s        drop the argument
SPadLeftTest        ldd       $08,s     load the pad count
                    addd      #$FFFF    decrement the count
                    std       $08,s     save the count
                    subd      #$FFFF    test for remaining padding
                    bgt       SPadLeftLoop more leading padding
                    bra       SEmitCharTest proceed to character emission

SEmitCharLoop       ldb       ,u+       load the next character
                    sex                 sign-extend to a word
                    pshs      d         push it as the argument
                    jsr       [$06,s]   output the character
                    leas      2,s        drop the argument
SEmitCharTest       ldb       ,u        peek the next character
                    bne       SEmitCharLoop continue until the terminator
                    ldd       LeftJustifyFlag,y   load the left-justify flag
                    beq       SEmitFieldDone right-justified needs no trailing pad
                    bra       SPadRightTest enter the trailing-pad test

SPadRightLoop       ldd       PadCharacter,y   load the pad character
                    pshs      d         push it as the argument
                    jsr       [$06,s]   output the trailing pad
                    leas      2,s        drop the argument
SPadRightTest       ldd       $08,s     load the pad count
                    addd      #$FFFF    decrement the count
                    std       $08,s     save the count
                    subd      #$FFFF    test for remaining padding
                    bgt       SPadRightLoop more trailing padding
SEmitFieldDone      puls      pc,u      return

PutCharStream       pshs      u         save the register
                    ldd       OutputPointer2,y   load the stream handle
                    pshs      d         push the stream handle
                    ldd       $06,s     load the character argument
                    pshs      d         push the character
                    lbsr      PutByte   write the character to the stream
FmtStrRet           leas      4,s        drop the arguments
                    puls      pc,u      return

PutCharBuf          pshs      u         save the register
                    ldd       $04,s     load the character argument
                    ldx       OutputPointer2,y   load the output pointer
                    leax      $01,x     advance the pointer
                    stx       OutputPointer2,y   save the pointer
                    stb       -$01,x    store the character
                    puls      pc,u      return

MsgIntMin           fcc       /-32768/
                    fcb       C$NULL
Fseek               pshs      u         save the register
                    ldu       $04,s     load the node pointer argument
                    leas      -6,s       reserve the local frame
                    cmpu      #$0000    test for a null node
                    beq       NodeNullRet null node returns failure
                    ldd       $06,u     load the node flags
                    clra                clear high byte
                    andb      #$03      isolate the type bits
                    bne       NodeCheckResolved typed node proceeds
NodeNullRet         ldd       #$FFFF    return failure
                    lbra      SeekDone  exit

NodeCheckResolved   ldd       $06,u     load the node flags
                    anda      #$80      isolate the resolved bit
                    clrb                clear low byte
                    std       -$02,s    save the test result
                    bne       NodeLoadFlags already resolved skips lookup
                    pshs      u         push the node pointer
                    lbsr      SetupBuf  resolve the node
                    leas      2,s        drop the argument
                    lbra      SeekClearFlag continue past resolution

NodeLoadFlags       ldd       $06,u     reload the node flags
                    anda      #$01      isolate the dirty bit
                    clrb                clear low byte
                    std       -$02,s    save the test result
                    beq       NodeCompareEnd clean node skips recompute
                    pshs      u         push the node pointer
                    lbsr      FlushWrite recompute the node value
                    leas      2,s        drop the argument
                    ldd       $06,u     reload the node flags
                    anda      #$FE      clear the dirty bit
                    std       $06,u     save the flags
                    ldd       $02,u     load the base value
                    addd      $0b,u     add the node size
                    std       $04,u     store the computed end
                    lbra      SeekSetCur done with this node

NodeCompareEnd      ldd       ,u        load the current position
                    cmpd      $04,u     compare against the node end
                    lbcc      SeekClearFlag past the end so skip
                    leax      $02,s     point to the local buffer
                    pshs      x         push the buffer pointer
                    leax      $0e,s     point to the result slot
                    lbsr      LongStore scan the node range
                    ldx       $10,s     load the returned pointer
                    lbra      WhenceDispatch proceed with the result

NodeSplit           leax      $02,s     point to the local buffer
                    pshs      x         push the buffer pointer
                    ldd       $02,x     push the range end
                    pshs      d         push the range end
                    ldd       ,x        push the range start
                    pshs      d         push the range start
                    pshs      u         push the node pointer
                    lbsr      FileTell  allocate a working node
                    leas      2,s        drop the argument
                    lbsr      LongSub   link the new node
                    lbsr      LongStore rescan the range
NodeMergeStep       ldd       $0b,u     load the node size
                    lbsr      IntToLong apply the size to the node
                    ldd       $02,x     push the range end
                    pshs      d         push the range end
                    ldd       ,x        push the range start
                    pshs      d         push the range start
                    leax      $06,s     point to the second range
                    ldd       $02,x     push the second range end
                    pshs      d         push the second range end
                    ldd       ,x        push the second range start
                    pshs      d         push the second range start
                    bsr       NodeInlineArgs call with inline argument block
                    fcb       $00,$00,$00,$00
NodeInlineArgs      puls      x         retrieve the inline argument pointer
                    lbsr      LongCmp   compare the two ranges
                    bge       NodeRangeA first range is greater or equal
                    leax      $06,s     point to the second range
                    lbsr      LongNeg   swap in the smaller range
                    bra       NodeRangeCheck proceed to the range check

NodeRangeA          leax      $06,s     point to the second range
NodeRangeCheck      lbsr      LongCmp   compare the selected ranges
                    blt       SeekAdjust out-of-order range is rejected
                    ldd       $04,s     load the offset
                    addd      ,u        add the node position
                    std       ,s        save the computed value
                    cmpd      $02,u     below the node base is rejected
                    bcs       SeekAdjust below the node base is rejected
                    ldd       ,s        reload the computed value
                    cmpd      $04,u     compare against the node end
                    bcc       SeekAdjust beyond the node end is rejected
                    ldd       ,s        reload the computed value
                    std       ,u        store it as the node position
                    ldd       $06,u     load the node flags
                    andb      #$EF      clear the pending bit
                    std       $06,u     save the flags
                    lbra      SeekOk    done with this node

                    bra       SeekAdjust jump to common seek path

WhenceDispatch      stx       -$02,s    save and test computed offset
                    lbeq      NodeSplit branch if seek to start
                    cmpx      #$0001    check whence value one
                    lbeq      NodeMergeStep branch if whence is current
SeekAdjust          ldd       $10,s     load whence argument
                    cmpd      #$0001    is whence SEEK_CUR
                    bne       SeekResetEnd skip relative adjust if not
                    leax      $0C,s     point to offset local
                    pshs      x         pass offset pointer
                    ldd       $02,x     low word of offset
                    pshs      d         push low word
                    ldd       ,x        high word of offset
                    pshs      d         push high word
                    ldd       $04,u     buffer end pointer
                    subd      ,u        minus current position
                    lbsr      IntToLong build buffered byte count
                    lbsr      LongSub   adjust offset by buffered bytes
                    lbsr      LongStore store adjusted offset back
SeekResetEnd        ldd       $04,u     load buffer end
SeekSetCur          std       ,u        reset current to buffer end
SeekClearFlag       ldd       $06,u     load stream flags
                    andb      #$EF      clear pushback flag bit
                    std       $06,u     store flags
                    ldd       $10,s     whence argument
                    pshs      d         push whence
                    leax      $0e,s     point to offset local
                    ldd       $02,x     low word offset
                    pshs      d         push low word
                    ldd       ,x        high word offset
                    pshs      d         push high word
                    ldd       $08,u     path number
                    pshs      d         push path number
                    lbsr      lseek     call lseek
                    leas      8,s        drop lseek arguments
                    ldd       $02,x     low word of result
                    pshs      d         push low word
                    ldd       ,x        high word of result
                    pshs      d         push high word
                    bsr       SeekCheckResult fetch inline -1 constant address
                    fcb       $FF,$FF,$FF,$FF
SeekCheckResult     puls      x         x points to inline -1 long
                    lbsr      LongCmp   compare result against -1
                    bne       SeekOk    branch if seek succeeded
                    ldd       #$FFFF    return failure code
                    bra       SeekDone  go to exit

SeekOk              clra                return success zero
                    clrb                clear low byte
SeekDone            leas      6,s        drop pushed longs
                    puls      pc,u      return from fseek

                    pshs      u         save frame register
                    clra                zero offset high
                    clrb                clear low byte
                    pshs      d         push offset high
                    clra                zero offset low
                    clrb                clear low byte
                    pshs      d         push offset low
                    pshs      d         push whence SEEK_SET
                    ldd       $0a,s     stream argument
                    pshs      d         push stream
                    lbsr      Fseek     call fseek to rewind
                    leas      8,s        drop arguments
                    puls      pc,u      return from rewind

FileTell            pshs      u         save frame register
                    ldu       $04,s     load stream argument
                    beq       TellNull  error if null stream
                    ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$03      test read/write mode bits
                    bne       TellCompute proceed if stream active
TellNull            bsr       StoreTellError fetch inline -1 address
                    fcb       $FF,$FF,$FF,$FF
StoreTellError      puls      x         x points to inline -1 long
                    leau      HighResultWord,y   point to ftell value global
                    pshs      u         push destination
                    lbsr      LongStore store -1 as position
                    puls      pc,u      return -1

TellCompute         ldd       $06,u     stream flags
                    anda      #$80      test buffer-allocated flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    bne       TellSeekCur skip init if buffered
                    pshs      u         push stream
                    lbsr      SetupBuf  allocate stream buffer
                    leas      2,s        drop argument
TellSeekCur         ldd       #$0001    whence SEEK_CUR
                    pshs      d         push whence
                    clra                zero offset high
                    clrb                clear low byte
                    pshs      d         push offset high
                    pshs      d         push offset low
                    ldd       $08,u     path number
                    pshs      d         push path number
                    lbsr      lseek     lseek to get current position
                    leas      8,s        drop arguments
                    ldd       $02,x     low word of position
                    pshs      d         push low word
                    ldd       ,x        high word of position
                    pshs      d         push high word
                    ldd       $06,u     stream flags
                    anda      #$01      test read-direction flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    beq       TellUseEnd use buffer end if writing
                    ldd       $02,u     buffer base for reading
                    bra       TellSubBuf skip to boundary push

TellUseEnd          ldd       $04,u     buffer end for writing
TellSubBuf          pshs      d         push buffer boundary
                    ldd       ,u        current position
                    subd      ,s++      minus boundary for buffered count
                    lbsr      IntToLong extend to long
                    lbsr      LongAdd   subtract buffered from file position
                    puls      pc,u      return true position

PutByte             pshs      u         save frame register
                    ldu       $06,s     load stream argument
                    ldd       $06,u     stream flags
                    anda      #$80      test buffer-allocated bit
                    andb      #$22      test write-active bits
                    cmpd      #$8002    buffered and writing already
                    beq       PutActive already set up
                    ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$22      mask mode bits
                    cmpd      #$0002    is stream in write mode
                    lbne      RetNegOne error if not writable
                    pshs      u         push stream
                    lbsr      SetupBuf  allocate stream buffer
                    leas      2,s        drop argument
PutActive           ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$04      test unbuffered flag
                    beq       PutBuffered buffered path if not
                    ldd       #$0001    write one byte
                    pshs      d         push count
                    leax      $07,s     point to the character
                    pshs      x         push buffer pointer
                    ldd       $08,u     path number
                    pshs      d         push path number
                    ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$40      test text-translation flag
                    beq       PutRawFn  use raw write if binary
                    leax      writeln,pcr text-write routine
                    bra       PutCallWrite skip to call

PutRawFn            leax      write,pcr raw-write routine
PutCallWrite        tfr       x,d       move routine pointer
                    tfr       d,x       back into index register
                    jsr       ,x        call selected write routine
                    leas      6,s        drop arguments
                    cmpd      #$FFFF    write failed
                    bne       PutDone   done if written
                    ldd       $06,u     stream flags
                    orb       #$20      set error flag
                    std       $06,u     store flags
                    lbra      RetNegOne return -1

PutBuffered         ldd       $06,u     stream flags
                    anda      #$01      test read-direction flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    bne       PutStore  skip flush if writing
                    pshs      u         push stream
                    lbsr      FlushBuffer flush pending read buffer
                    leas      2,s        drop argument
PutStore            ldd       ,u        current buffer pointer
                    addd      #$0001    advance one byte
                    std       ,u        store new pointer
                    subd      #$0001    recover write address
                    tfr       d,x       into index register
                    ldd       $04,s     the character argument
                    stb       ,x        store byte into buffer
                    ldd       ,u        updated pointer
                    cmpd      $04,u     reached buffer end
                    bcc       PutFlush  flush if buffer full
                    ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$40      test line-buffered flag
                    beq       PutDone   done if fully buffered
                    ldd       $04,s     the character
                    cmpd      #$000D    is it a newline
                    bne       PutDone   done if not newline
PutFlush            pshs      u         push stream
                    lbsr      FlushBuffer flush the buffer
                    std       ,s++      check flush result
                    lbne      RetNegOne return -1 on error
PutDone             ldd       $04,s     return written character
                    puls      pc,u      return from putc

PutWord             pshs      u         save frame register
                    ldu       $04,s     load stream argument
                    ldd       $06,s     load word value
                    pshs      d         save value
                    pshs      u         save stream
                    ldd       #$0008    shift amount eight
                    lbsr      LsrEntry  shift value right eight
                    pshs      d         push high byte
                    lbsr      PutByte   putc the high byte
                    leas      4,s        drop arguments
                    ldd       $06,s     reload word value
                    pshs      d         push value
                    pshs      u         push stream
                    lbsr      PutByte   putc the low byte
                    lbra      FlushRet  return

FlushAllStreams     pshs      u,d       save frame and value
                    leau      SegmentTableStart,y   stream table base
                    clra                zero index
                    clrb                clear low byte
                    std       ,s        initialise index
                    bra       FlushNext skip to loop test

FlushEntry          tfr       u,d       current stream pointer
                    leau      $0d,u     advance to next stream entry
                    pshs      d         push stream pointer
                    bsr       fclose    flush and close this stream
                    leas      2,s        drop argument
FlushNext           ldd       ,s        load index
                    addd      #$0001    increment index
                    std       ,s        store index
                    subd      #$0001    recover index
                    cmpd      #$0010    done all sixteen
                    blt       FlushEntry loop over next stream
                    puls      pc,u,x    return

                    use       lib/fclose.asm
FlushStream         equ       FlushWrite this module's helper name

FlushWrite          pshs      u         save frame register
                    ldu       $04,s     load stream argument
                    beq       RetNegOne error if null
                    ldd       $06,u     stream flags
                    clra                keep low byte
                    andb      #$22      mask mode bits
                    cmpd      #$0002    is stream writing
                    beq       FlushWriteGo flush if writable
RetNegOne           ldd       #$FFFF    return -1
                    puls      pc,u      return

FlushWriteGo        ldd       $06,u     stream flags
                    anda      #$80      test buffer-allocated flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    bne       FlushWriteCall skip init if buffered
                    pshs      u         push stream
                    lbsr      SetupBuf  allocate stream buffer
                    leas      2,s        drop argument
FlushWriteCall      pshs      u         push stream
                    bsr       FlushBuffer flush the buffer
                    puls      pc,u,x    return flush result

                    use       lib/flushbuffer.asm

GetByte             pshs      u         save frame register
                    ldu       $04,s     load stream argument
                    beq       RetEof    eof if null stream
                    ldd       $06,u     stream flags
                    anda      #$01      test read-direction flag
                    clrb                clear low byte
                    std       -$02,s    save flag test
                    bne       RetEof    eof if not readable
                    ldd       ,u        current position
                    cmpd      $04,u     buffer exhausted
                    bcc       GetRefill refill if empty
                    ldd       ,u        current position
                    addd      #$0001    advance one byte
                    std       ,u        store pointer
                    subd      #$0001    recover read address
                    tfr       d,x       into index register
                    ldb       ,x        read byte from buffer
                    clra                zero-extend to word
                    bra       GetReturn return the character

GetRefill           pshs      u         push stream
                    lbsr      FillBuf   refill buffer and read byte
                    leas      2,s        drop argument
GetReturn           puls      pc,u      return the character

                    pshs      u         save frame register
                    ldu       $06,s     load stream argument
                    beq       RetEof    null stream returns eof
                    ldd       $06,u     load stream flags
                    clra                clear high byte
                    andb      #$01      test writable bit
                    beq       RetEof    not writable returns eof
                    ldd       $04,s     load char argument
                    cmpd      #$FFFF    is it eof
                    beq       RetEof    eof char cannot be pushed back
                    ldd       ,u        current buffer pointer
                    cmpd      $02,u     compare against buffer start
                    bhi       UngetChar room to push back
RetEof              ldd       #$FFFF    return eof
                    puls      pc,u      return to caller

UngetChar           ldd       ,u        current pointer
                    addd      #$FFFF    back up one byte
                    std       ,u        store new pointer
                    tfr       d,x       pointer into x
                    ldd       $04,s     load char
                    stb       ,x        store char back
                    ldd       $04,s     return the char
                    puls      pc,u      return to caller

ReadWord            pshs      u         save frame pointer
                    ldu       $04,s     stream argument
                    leas      -4,s       two word locals
                    pshs      u         pass stream
                    lbsr      GetByte   read a byte
                    leas      2,s        drop argument
                    std       $02,s     save high byte
                    cmpd      #$FFFF    is it eof
                    beq       ReadWordEof abort word on eof
                    pshs      u         pass stream
                    lbsr      GetByte   read a byte
                    leas      2,s        drop argument
                    std       ,s        save low byte
                    cmpd      #$FFFF    is it eof
                    bne       CombineWord got a full word
ReadWordEof         ldd       #$FFFF    return eof
                    bra       ReadWordDone jump to exit

CombineWord         ldd       $02,s     high byte
                    pshs      d         save it
                    ldd       #$0008    shift count eight
                    lbsr      AslEntry  shift high byte left
                    addd      ,s        add low byte
ReadWordDone        leas      4,s        drop locals
                    puls      pc,u      return the word

FillBuf             pshs      u         save frame pointer
                    ldu       $04,s     stream argument
                    leas      -2,s       one word local
                    ldd       $06,u     stream flags
                    anda      #$80      isolate open bit
                    andb      #$31      isolate mode bits
                    cmpd      #$8001    open and readable
                    beq       BufOpened buffer already open
                    ldd       $06,u     flags
                    clra                clear high byte
                    andb      #$31      isolate mode bits
                    cmpd      #$0001    readable but not open
                    beq       InitStream open it first
                    ldd       #$FFFF    return eof
                    puls      pc,u,x    return to caller

InitStream          pshs      u         pass stream
                    lbsr      SetupBuf  open and allocate buffer
                    leas      2,s        drop argument
BufOpened           leax      SegmentTableStart,y   address of stdin stream
                    pshs      x         save it
                    cmpu      ,s++      is this stdin
                    bne       DoRead    not stdin skip flush
                    ldd       $06,u     flags
                    clra                clear high byte
                    andb      #$40      isolate interactive bit
                    beq       DoRead    not a tty skip flush
                    leax      MessageWorkBuffer,y   address of stdout stream
                    pshs      x         pass stdout
                    lbsr      FlushWrite flush stdout before reading
                    leas      2,s        drop argument
DoRead              ldd       $06,u     flags
                    clra                clear high byte
                    andb      #$08      isolate buffered bit
                    beq       ReadUnbuffered unbuffered path
                    ldd       $0b,u     buffer size
                    pshs      d         push as read length
                    ldd       $02,u     buffer pointer
                    pshs      d         push as read address
                    ldd       $08,u     file descriptor
                    pshs      d         push as read path
                    ldd       $06,u     flags
                    clra                clear high byte
                    andb      #$40      isolate interactive bit
                    beq       UseBlockRead use plain block read
                    leax      readln,pcr line-input read routine
                    bra       CallRead  call it

UseBlockRead        leax      read,pcr  block read routine
CallRead            tfr       x,d       move routine to d
                    tfr       d,x       and back to x
                    jsr       ,x        call read routine
                    bra       AfterRead handle the result

ReadUnbuffered      ldd       #$0001    read a single byte
                    pshs      d         as read length
                    leax      $0a,u     internal one-char buffer
                    stx       $02,u     set buffer pointer
                    pshs      x         as read address
                    ldd       $08,u     file descriptor
                    pshs      d         as read path
                    lbsr      read      block read
AfterRead           leas      6,s        drop arguments
                    std       ,s        save byte count
                    ldd       ,s        count
                    bgt       GotData   got data
                    ldd       $06,u     flags
                    pshs      d         save flags
                    ldd       $02,s     count
                    beq       SetEofFlag zero means eof
                    ldd       #$0020    read error flag
                    bra       StoreReadFlags merge it in

SetEofFlag          ldd       #$0010    eof flag
StoreReadFlags      ora       ,s+       or into flags
                    orb       ,s+       or low byte
                    std       $06,u     store flags
                    ldd       #$FFFF    return eof
                    puls      pc,u,x    return to caller

GotData             ldd       $02,u     buffer pointer
                    addd      #$0001    skip first byte
                    std       ,u        new read pointer
                    ldd       $02,u     buffer start
                    addd      ,s        add byte count
                    std       $04,u     set end pointer
                    ldb       [$02,u]   first byte read
                    clra                clear high byte
                    puls      pc,u,x    return the byte

SetupBuf            pshs      u         save frame pointer
                    ldu       $04,s     stream argument
                    ldd       $06,u     flags
                    clra                clear high byte
                    andb      #$C0      device-type bits
                    bne       MarkOpen  type already known
                    leas      -32,s      local status buffer
                    leax      ,s        point to it
                    pshs      x         push status buffer
                    ldd       $08,u     file descriptor
                    pshs      d         push it
                    clra                clear high byte
                    clrb                clear low byte
                    pshs      d         push status code zero
                    lbsr      MathDispatch get file status
                    leas      6,s        drop arguments
                    ldd       $06,u     flags
                    pshs      d         save flags
                    ldb       $02,s     status result
                    bne       SetTtyFlag device is a tty
                    ldd       #$0040    regular file flag
                    bra       StoreMode merge it in

SetTtyFlag          ldd       #$0080    tty flag
StoreMode           ora       ,s+       or into flags
                    orb       ,s+       or low byte
                    std       $06,u     store flags
                    leas      32,s       drop status buffer
MarkOpen            ldd       $06,u     flags
                    ora       #$80      set open bit
                    std       $06,u     store flags
                    clra                clear high byte
                    andb      #$0C      buffering-decided bits
                    beq       NeedBuffer need to set up buffer
                    puls      pc,u      already set up return

NeedBuffer          ldd       $0b,u     buffer size
                    bne       CheckBuffer size already set
                    ldd       $06,u     flags
                    clra                clear high byte
                    andb      #$40      isolate interactive bit
                    beq       FileBufSize use large buffer
                    ldd       #$0080    tty buffer size 128
                    bra       StoreBufSize store it

FileBufSize         ldd       #$0100    file buffer size 256
StoreBufSize        std       $0b,u     store buffer size
CheckBuffer         ldd       $02,u     buffer pointer
                    bne       BufAllocated buffer already allocated
                    ldd       $0b,u     buffer size
                    pshs      d         pass size
                    lbsr      PoolAlloc allocate buffer memory
                    leas      2,s        drop argument
                    std       $02,u     store buffer pointer
                    cmpd      #$FFFF    allocation failed
                    beq       MallocFailed fall back unbuffered
BufAllocated        ldd       $06,u     flags
                    orb       #$08      set buffered bit
                    std       $06,u     store flags
                    bra       InitPointers finish setup

MallocFailed        ldd       $06,u     flags
                    orb       #$04      set unbuffered bit
                    std       $06,u     store flags
                    leax      $0a,u     internal one-char buffer
                    stx       $02,u     use it as buffer
                    ldd       #$0001    size one byte
                    std       $0b,u     store size
InitPointers        ldd       $02,u     buffer pointer
                    addd      $0b,u     add size
                    std       $04,u     set end pointer
                    std       ,u        set read pointer empty
                    puls      pc,u      return to caller

SelectFormat        pshs      u         save frame pointer
                    ldb       $05,s     conversion character
                    sex                 sign extend to word
                    tfr       d,x       into x
                    bra       CheckConv test the character

NumFormat           ldd       [$06,s]   argument list pointer
                    addd      #$0004    advance past word arg
                    std       [$06,s]   store updated pointer
                    leax      >StrlenThunk,pcr numeric formatter thunk
                    bra       FormatRet return it

CharFormat          ldb       $05,s     conversion character
                    stb       ScratchBuffer,y   store into scratch buffer
                    leax      AddressBuffer,y   address of that buffer
FormatRet           tfr       x,d       return formatter pointer
                    puls      pc,u      return to caller

CheckConv           cmpx      #$0064    is it d
                    beq       NumFormat numeric conversion
                    cmpx      #$006F    is it o
                    lbeq      NumFormat numeric conversion
                    cmpx      #$0078    is it x
                    lbeq      NumFormat numeric conversion
                    bra       CharFormat default character formatter

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
StrlenThunk         neg       $0034     misframed thunk prologue
                    nega                misframed thunk prologue
                    leax      >strlen,pcr address of strlen routine
                    tfr       x,d       return that pointer
                    puls      pc,u      return to caller

* StrLen - strlen routine (entered via the &StrLen pointer returned above):
                    use       lib/strlen.asm

                    use       lib/strcpy.asm

                    use       lib/strcat.asm

                    use       lib/strcmp.asm

                    use       lib/strncpy.asm

                    use       lib/strncmp.asm

                    use       lib/strncat.asm

                    pshs      u         save u register
                    ldu       $04,s     load destination pointer
CopyStrLoop         ldx       $06,s     load source pointer
                    leax      $01,x     advance source pointer
                    stx       $06,s     save source pointer
                    ldb       -$01,x    fetch source byte
                    stb       ,u+       store to destination
                    bgt       CopyStrLoop loop while byte positive
                    ldb       -$01,u    get last stored byte
                    clra                clear high half
                    andb      #$7f      strip high bit
                    stb       -$01,u    store cleaned byte
                    clra                prepare zero byte
                    clrb                prepare zero byte
                    stb       ,u        null-terminate destination
                    ldd       $04,s     return destination pointer
                    puls      pc,u      return to caller

Atoi                pshs      u         save u register
                    ldu       $04,s     load string pointer
                    leas      -5,s       allocate local scratch
                    clra                clear accumulator high
                    clrb                clear accumulator low
                    std       $01,s     clear running accumulator
SkipSpaceLoop       ldb       ,u+       read next character
                    stb       ,s        save current character
                    cmpb      #$20      is it a space
                    beq       SkipSpaceLoop skip leading spaces
                    ldb       ,s        reload character
                    cmpb      #$09      is it a tab
                    lbeq      SkipSpaceLoop skip leading tabs
                    ldb       ,s        reload character
                    cmpb      #$2d      is it a minus sign
                    bne       NotNeg    no leading sign
                    ldd       #$0001    set negative flag
                    bra       StoreSign store sign flag

NotNeg              clra                clear sign flag high
                    clrb                clear sign flag low
StoreSign           std       $03,s     store sign flag
                    ldb       ,s        reload character
                    cmpb      #$2d      is it a minus
                    beq       NextChar  consume leading sign
                    ldb       ,s        reload character
                    cmpb      #$2b      is it a plus
                    bne       CheckDigit no sign to consume
                    bra       NextChar  consume leading sign

DigitLoop           ldd       $01,s     load current accumulator
                    pshs      d         push multiplicand
                    ldd       #$000A    multiply by ten
                    lbsr      MulEntry  perform the multiply
                    pshs      d         push scaled value
                    ldb       $02,s     get digit character
                    sex                 sign-extend digit
                    addd      ,s++      add to scaled accumulator
                    addd      #$FFD0    subtract ascii zero
                    std       $01,s     store updated accumulator
NextChar            ldb       ,u+       read next character
                    stb       ,s        save current character
CheckDigit          ldb       ,s        load character
                    sex                 sign-extend to index
                    leax      CtypeTab,y point to ctype table
                    leax      d,x       index table by character
                    ldb       ,x        get character attributes
                    clra                clear high half
                    andb      #$08      test digit attribute
                    bne       DigitLoop accumulate if digit
                    ldd       $03,s     load sign flag
                    beq       PosResult result stays positive
                    ldd       $01,s     load accumulator
                    nega                negate result
                    negb                negate result
                    sbca      #$00      negate result
                    bra       AtoiDone  return negated value

PosResult           ldd       $01,s     load positive result
AtoiDone            leas      5,s        release local scratch
                    puls      pc,u      return parsed value

BlockCopy           pshs      u         save u register
                    ldu       $04,s     load destination pointer
                    bra       CopyByteTest3 enter count test

CopyByteLoop3       ldx       $06,s     load source pointer
                    leax      $01,x     advance source pointer
                    stx       $06,s     save source pointer
                    ldb       -$01,x    fetch source byte
                    stb       ,u+       store to destination
CopyByteTest3       ldd       $08,s     load remaining count
                    addd      #$FFFF    decrement count
                    std       $08,s     save count
                    subd      #$FFFF    test if bytes remain
                    bgt       CopyByteLoop3 loop while bytes remain
                    puls      pc,u      return to caller

LongAdd             ldd       $04,s     low word of first operand
                    addd      $02,x     add low word of second
                    std       LowResultWord,y   store low result word
                    ldd       $02,s     high word of first operand
                    adcb      $01,x     add high with carry
                    adca      ,x        add high with carry
                    std       HighResultWord,y   store high result word
                    lbra      LongRetPtr return result pointer

LongSub             ldd       $04,s     low word of first operand
                    subd      $02,x     subtract low word
                    std       LowResultWord,y   store low result word
                    ldd       $02,s     high word of first operand
                    sbcb      $01,x     subtract high with borrow
                    sbca      ,x        subtract high with borrow
                    std       HighResultWord,y   store high result word
                    lbra      LongRetPtr return result pointer

LongCmp             ldd       $02,s     high word of first operand
                    cmpd      ,x        compare high words
                    bne       CmpDone   differ so result decided
                    ldd       $04,s     low word of first operand
                    cmpd      $02,x     compare low words
                    beq       CmpDone   operands equal
                    bcs       CmpLess   first operand is smaller
                    lda       #$01      mark greater
                    andcc     #$FE      clear carry for greater
                    bra       CmpDone   result decided

CmpLess             clra                mark less
                    cmpa      #$01      set carry for less
CmpDone             pshs      cc        save comparison flags
                    ldd       $01,s     reload return address
                    std       $05,s     reposition return address
                    puls      cc        restore comparison flags
                    leas      4,s        clean local stack
                    rts                 return with flags

LongNeg             lbsr      LongToTmp copy operand to temp
                    ldd       #$0000    prepare zero
                    subd      $02,x     negate low word
                    std       $02,x     store negated low word
                    ldd       #$0000    prepare zero
                    sbcb      $01,x     negate high word with borrow
                    sbca      ,x        negate high word with borrow
                    std       ,x        store negated high word
                    rts                 return to caller
                    ldd       ,x        load high word
                    coma                complement high word
                    comb                complement high word
                    std       HighResultWord,y   store to temp result
                    ldd       $02,x     load low word
                    coma                complement low word
                    comb                complement low word
                    leax      HighResultWord,y   point to temp result
                    std       $02,x     store complemented low word
                    rts                 return to caller

IntToLong           leax      HighResultWord,y   point to temp long
                    std       $02,x     store low word
                    tfr       a,b       copy sign byte
                    sex                 sign-extend high byte
                    tfr       a,b       copy sign byte
                    std       ,x        store sign-extended high word
                    rts                 return to caller

UIntToLong          leax      HighResultWord,y   point to temp long
                    std       $02,x     store low word
                    clr       ,x        zero high byte
                    clr       $01,x     zero high byte
                    rts                 return to caller

LongStore           pshs      y         save y register
                    ldy       $04,s     load destination pointer
                    ldd       ,x        copy high word
                    std       ,y        store high word
                    ldd       $02,x     copy low word
                    std       LowWord,y     store low word
                    puls      x         restore saved pointer
                    exg       y,x       swap registers
                    puls      d         restore original value
                    std       ,s        place return value
                    rts                 return to caller

LongRetPtr          tfr       cc,a      preserve flags
                    puls      x         pop return address
                    stx       $02,s     reposition return address
                    leas      2,s        clean local stack
                    leax      HighResultWord,y   point to result long
                    tfr       a,cc      restore flags
                    rts                 return to caller

LongToTmp           ldd       ,x        load high word
                    std       HighResultWord,y   store to temp
                    ldd       $02,x     load low word
                    leax      HighResultWord,y   point x to temp
                    std       $02,x     store low word to temp
                    rts                 return to caller

                    use       lib/imul.asm

UDivSetup           clr       ResultSignFlag,y   clear result sign flag
                    leax      >UDivEntry,pcr point to unsigned divide
                    stx       DivideRoutinePointer,y   store divide routine pointer
                    bra       CheckDivisor go check divisor

                    leax      >SDivEntry,pcr point to signed divide
                    stx       DivideRoutinePointer,y   store divide routine pointer
                    clr       ResultSignFlag,y   clear result sign flag
                    tst       $02,s     test dividend sign
                    bpl       CheckDivisor skip if positive
                    inc       ResultSignFlag,y   mark negative result
CheckDivisor        subd      #$0000    test divisor value
                    bne       DoDivide  divisor nonzero
                    puls      x         pop return address
                    ldd       ,s++      discard divisor
                    jmp       ,x        return early

DoDivide            ldx       $02,s     load divisor
                    pshs      x         push divisor argument
                    jsr       [DivideRoutinePointer,y] call selected divide routine
                    ldd       ,s        fetch quotient result
                    std       $02,s     reposition quotient
                    tfr       x,d       move quotient to d
                    tst       ResultSignFlag,y   test result sign flag
                    beq       QuotStore quotient stays positive
                    nega                negate quotient
                    negb                negate quotient
                    sbca      #$00      negate quotient
QuotStore           std       ,s++      store final quotient
                    rts                 return to caller

                    use       lib/divide.asm
SendSignal          equ       RaiseError module signal raiser for divide by zero

                    use       lib/shift.asm

RaiseError          std       OutputPathHandle,y   save signal code
                    pshs      y,b       preserve registers
                    os9       F$ID      get own process id
                    puls      y,b       restore registers
                    os9       F$Send    send signal to own process
                    rts                 return to caller

MathDispatch        lda       $05,s     load operand byte
                    ldb       $03,s     load operation code
                    beq       GetSttCode0 handle case zero
                    cmpb      #$01      is operation one
                    beq       DoGetStt  handle case one
                    cmpb      #$06      is operation six
                    beq       DoGetStt  handle case six
                    cmpb      #$02      is operation two
                    beq       GetStatXU branch for status code two
                    cmpb      #$05      check status code five
                    beq       GetStatXU same handler for code five
                    ldb       #E$UnkSvc unknown status code error
                    lbra      SyscallErr return with error

                    use       lib/getstat.asm

GetSttCode0         ldx       $06,s     load status parameter x
DoGetStt            os9       I$GetStt  get file status
                    lbra      SyscallRet return status result

                    lda       $05,s     load path number
                    ldb       $03,s     load status code
                    beq       SetSttCode0 code zero setstt
                    cmpb      #$02      check status code two
                    beq       SetStatXU code two setstt with u
                    ldb       #E$UnkSvc unknown status code error
                    lbra      SyscallErr return error

SetSttCode0         ldx       $06,s     load status parameter
                    os9       I$SetStt  set file status
                    lbra      SyscallRet return result

                    use       lib/setstat.asm

                    use       lib/access.asm

                    use       lib/openpath.asm

                    use       lib/closepath.asm

                    ldx       $02,s     load pathname pointer
                    ldb       $05,s     load access mode
                    os9       I$MakDir  make directory
                    lbra      SyscallRet return result

CreatePath          ldx       $02,s     load pathname pointer
                    ldb       $05,s     load create mode
                    tfr       b,a       copy mode to a
                    anda      #$07      keep permission bits
                    os9       I$Create  create the file
                    bcs       CreateExists handle create failure
                    use       lib/createtail.asm

                    use       lib/deletepath.asm

                    lda       $03,s     load path number
                    os9       I$Dup     duplicate path number
                    lbcs      SyscallErr return error
                    tfr       a,b       new path to result
                    clra                clear high byte
                    rts                 return new path number

                    use       lib/readpath.asm

                    use       lib/writepath.asm

                    use       lib/seek.asm

                    rts                 return
                    ldx       #$0000    sleep indefinitely
                    clrb                clear tick count high
                    os9       F$Sleep   sleep
                    lbra      SyscallErr return via error path

                    rts                 return

CalcCrc             pshs      u,y       save registers
                    ldx       $06,s     load data start pointer
                    ldy       $08,s     load control parameter
                    ldu       $0a,s     load byte count
                    os9       F$CRC     load crc accumulator pointer
                    puls      pc,u,y    compute crc

                    lda       $03,s     return from crc
                    ldb       $05,s     load path number
                    os9       F$Perr    load error code
                    lbcs      SyscallErr print error message
                    rts                 return error
                    ldx       $02,s     return
                    os9       F$Sleep   load tick count
                    lbcs      SyscallErr sleep for ticks
                    tfr       x,d       return error
                    rts                 remaining ticks to result

GrowHeap            ldd       HeapBreak,y   load current heap break
                    pshs      d         save heap break
                    ldd       $04,s     load requested size
                    cmpd      FreeSpace,y   compare against free space
                    bcs       HeapAlloc enough free space already
                    addd      HeapBreak,y   new heap top needed
                    pshs      y         save data base
                    subd      ,s        convert to memory size
                    os9       F$Mem     request more memory
                    tfr       y,d       returned top of memory
                    puls      y         restore data base
                    bcc       GrowHeapOk allocation succeeded
                    ldd       #$FFFF    allocation failed result
                    leas      2,s        drop saved value
                    rts                 return failure

GrowHeapOk          std       HeapBreak,y   store new heap break
                    addd      FreeSpace,y   recompute free space
                    subd      ,s        minus old break
                    std       FreeSpace,y   store new free space
HeapAlloc           leas      2,s        drop saved break
                    ldd       FreeSpace,y   load free space
                    pshs      d         save free space
                    subd      $04,s     subtract request
                    std       FreeSpace,y   reduce free space
                    ldd       HeapBreak,y   load heap break
                    subd      ,s++      compute block start
                    pshs      d         save block pointer
                    clra                zero fill byte
                    ldx       ,s        load block start
HeapZeroLoop        sta       ,x+       zero the byte
                    cmpx      HeapBreak,y   reached heap break
                    bcs       HeapZeroLoop continue zero fill
                    puls      pc,d      return block pointer

PoolAlloc           ldd       $02,s     load requested size
                    addd      PoolPointer,y   add to pool pointer
                    bcs       PoolAllocFail overflow fails
                    cmpd      PoolLimit,y   compare pool limit
                    bcc       PoolAllocFail exceeds pool fails
                    pshs      d         save new pool pointer
                    ldx       PoolPointer,y   load current pool pointer
                    clra                zero fill byte
PoolZeroLoop        cmpx      ,s        reached new pointer
                    bcc       PoolAllocOk done filling
                    sta       ,x+       zero the byte
                    bra       PoolZeroLoop continue filling

PoolAllocOk         ldd       PoolPointer,y   old pool pointer as result
                    puls      x         load new pool pointer
                    stx       PoolPointer,y   advance pool pointer
                    rts                 return allocated block

PoolAllocFail       ldd       #$FFFF    allocation failed result
                    rts                 return failure

SetIntercept        pshs      u         save u
                    tfr       y,u       data base to u
                    ldx       $04,s     load handler address
                    stx       UserHandlerPointer,y   store user handler pointer
                    leax      >InterceptEntry,pcr point to intercept trampoline
                    os9       F$Icpt    install signal intercept
                    puls      u         restore u
                    lbra      SyscallRet return result

InterceptEntry      tfr       u,y       restore data base
                    clra                zero high signal code
                    pshs      d         push signal code argument
                    jsr       [UserHandlerPointer,y] call user signal handler
                    leas      2,s        drop argument
                    rti                 return from intercept

                    use       lib/syscallerr.asm

exit                lbsr      RtsStub   call rts stub
                    lbsr      FlushAllStreams run exit cleanup
_exit               ldd       $02,s     load exit status
                    os9       F$Exit    terminate process
RtsStub             rts                 empty rts stub
* ------------------------------------------------------------------
* WorkBlockImage - cc1-style init image for the work block (see _start):
* rts stub + count/block table + relocation dirs + module-name string.
* ------------------------------------------------------------------
                    * ============ WorkBlockImage: cstart init/relocation tables ============

                    * ---- count1: DP-data length (bytes copied to the DP base)
WorkBlockImage      fdb       WBIcount2-WBIblock1

                    * ---- block1: DP data image  ->  data base
WBIblock1           fcb       $00,$00,$00,$04,$00,$FF,$FF,$FF
WBIptrOutBuf2       fdb       OutputBuffer

                    * ---- count2: non-DP-data length (bytes copied to base+HDRADV)
WBIcount2           fdb       WBIblk2End-WBIblock2

                    * ---- block2: non-DP data image  ->  data base + HDRADV
WBIblock2           fdb       ListHeadAddress
WBIptrListHead2     fdb       ListHeadAddress
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
SectNameTabImg      fdb       SymEtext
WBIptrEdata         fdb       SymEdata
WBIptrEnd           fdb       SymEnd
WBIptrDpsiz         fdb       SymDpsiz
WBIptrBtext         fdb       SymBtext
WBIptrOutBuf1       fdb       OutputBuffer
Pow10Img            fdb       10000,1000,100,10 powers of ten
WBIptrOnes          fdb       OnesPlace
                    fcc       /lx/
                    fcb       $00,$00,$00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02,$00,$01,$00,$00,$00
NameBufImg          fcb       $00,$00,$00,$00,$00,$00,$00
                    fcb       $42
                    fcb       $00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
CtypeTabImg         fcb       $01,$01,$01,$01,$01,$01,$01,$01,$01,$11,$11,$01,$11,$11,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01
                    fcc       /0               HHHHH/
                    fcc       /HHHHH       BBBBBB/
                    fcb       $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
                    fcc       /      DDDDDD/
                    fcb       $04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
                    fcc       /    /
                    fcb       $01

                    * ---- nreloc1: text-relocation count  (each offset patched by +module base)
WBIblk2End          fdb       (reloc1End-reloc1Start)/2

                    * ---- reloc1: text relocation offsets
reloc1Start         fdb       HDRADV+WBIptrBtext-WBIblock2,HDRADV+WBIptrDpsiz-WBIblock2,HDRADV+WBIptrEnd-WBIblock2,HDRADV+WBIptrEdata-WBIblock2,HDRADV+SectNameTabImg-WBIblock2
reloc1End           equ       *

                    * ---- nreloc2: data-relocation count  (each offset patched by +work base)
                    fdb       (reloc2End-reloc2Start)/2

                    * ---- reloc2: data relocation offsets
reloc2Start         fdb       HDRADV+WBIptrListHead2-WBIblock2,HDRADV+WBIblock2-WBIblock2,HDRADV+WBIptrOutBuf1-WBIblock2,WBIptrOutBuf2-WBIblock1,HDRADV+WBIptrOnes-WBIblock2
reloc2End           equ       *

                    * ---- name: trailing module-name string
                    fcc       /c.link/
                    fcb       C$NULL
                    emod
eom                 equ       *
                    end