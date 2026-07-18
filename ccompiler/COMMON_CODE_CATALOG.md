# ccompiler common-code catalog

Structurally-identical code shared across the disassembled compiler modules (labels, and both hex AND decimal addresses/constants, abstracted; os9 syscalls kept as anchors). Line numbers are 1-based, into the **pre-extraction** module sources.

> The `cstart-head` group is the C runtime startup, now factored out to `lib/cstart.asm` (and `lib/cstart_rev.asm` for make's reversing variant); the compiler modules `use` it instead of carrying a copy. c_asm now matches the others here: it is hand-disassembled (decimal literals, uppercase registers, explicit `>` size prefixes, `,pc` vs `,pcr`), so it only lined up once those representational differences were normalized away. The `clib-tail` groups (file I/O, malloc, math, printf) are the remaining shared runtime, not yet extracted.

- k-gram=12, min run=20 instrs, occ cap=40
- 261 groups; 36 in >=5 modules

## cstart-head (31 groups)

| id | label | #mod | len | modules: line-range |
|--|--|--|--|--|
| 2 | `ClrBssLoop` | 8 | 68 | c.comp:69-141 c.link:108-180 c.opt:82-154 c.pass1:119-191 c.pass2:84-156 c.prep:90-162 c_asm:269-365 cc1:81-153 |
| 9 | `copybytes` | 7 | 42 | c.link:81-124 c.opt:55-98 c.pass1:92-135 c.pass2:57-100 c_asm:235-289 cc1:54-97 make:58-101 |
| 14 | `copybytes` | 6 | 105 | c.link:81-191 c.opt:55-165 c.pass1:92-202 c.pass2:57-167 c_asm:235-381 cc1:54-164 |
| 19 | `stkcheck` | 6 | 34 | c.comp:154-191 c.link:193-230 c.opt:167-204 c.pass1:204-241 c_asm:385-450 cc1:166-203 |
| 22 | `ClrBssLoop` | 5 | 115 | c.comp:69-193 c.link:108-232 c.opt:82-206 c.pass1:119-243 cc1:81-205 |
| 23 | `copybytes` | 5 | 112 | c.link:81-198 c.opt:55-172 c.pass1:92-209 c.pass2:57-174 cc1:54-171 |
| 37 | `copybytes` | 4 | 141 | c.link:81-232 c.opt:55-206 c.pass1:92-243 cc1:54-205 |
| 45 | `StackOverflowErr` | 4 | 30 | c.link:203-234 c.pass2:179-210 c.prep:185-218 cc1:176-207 |
| 86 | `StackOverflowErr` | 3 | 31 | c.link:203-235 c.pass2:179-211 cc1:176-208 |
| 93 | `InternalErr` | 3 | 28 | c.comp:486-514 c.pass1:353-381 c.pass2:8011-8039 |
| 101 | `PutCharDone` | 3 | 22 | c.comp:620-643 c.pass1:487-510 c.pass2:8233-8256 |
| 103 | `ArgLoop2` | 2 | 1348 | c.comp:1359-2838 c.pass1:1226-2705 |
| 116 | `AllocZeroLoop` | 2 | 333 | c.comp:406-767 c.pass1:273-634 |
| 131 | `NameSearchLoop` | 2 | 187 | c.comp:769-984 c.pass1:636-851 |
| 133 | `copybytes` | 2 | 146 | c.link:81-237 cc1:54-210 |
| 159 | `BuildSizeofNode` | 2 | 79 | c.comp:1103-1185 c.pass1:970-1052 |
| 193 | `BuildMemberNode` | 2 | 46 | c.comp:1265-1314 c.pass1:1132-1181 |
| 208 | `ArgLoopNext` | 2 | 38 | c.comp:314-353 c.pass1:12090-12129 |
| 210 | `BuildPostIncDec` | 2 | 37 | c.comp:1317-1356 c.pass1:1184-1223 |
| 211 | `BuildSubscript` | 2 | 36 | c.comp:1222-1259 c.pass1:1089-1126 |
| 213 | `OptDispatch` | 2 | 34 | c.comp:277-313 c.pass1:12051-12087 |
| 217 | `OptCharLoad` | 2 | 34 | c.comp:227-265 c.pass1:11999-12037 |
| 225 | `main` | 2 | 30 | c.comp:193-224 c.pass1:11961-11992 |
| 231 | `ParsePrefixOp` | 2 | 28 | c.comp:1039-1068 c.pass1:906-935 |
| 232 | `OptUnknown` | 2 | 26 | c.link:369-395 cc1:411-437 |
| 235 | `AllocBlk` | 2 | 26 | c.comp:376-402 c.pass1:243-269 |
| 236 | `MakeErrNode` | 2 | 26 | c.comp:1010-1036 c.pass1:877-903 |
| 237 | `ParseSubscript` | 2 | 26 | c.comp:1194-1219 c.pass1:1061-1086 |
| 241 | `SizeofExpr` | 2 | 24 | c.comp:1072-1097 c.pass1:939-964 |
| 248 | `UnknownFlag` | 2 | 22 | c.comp:267-290 c.pass2:266-289 |
| 251 | `erexit` | 2 | 21 | c_asm:404-452 make:187-209 |

## clib-tail (47 groups)

| id | label | #mod | len | modules: line-range |
|--|--|--|--|--|
| 0 | `MulFull` | 9 | 29 | c.comp:19527-19555 c.link:5602-5630 c.opt:4370-4398 c.pass1:13309-13337 c.pass2:10660-10688 c.prep:4157-4185 c_asm:8512-8540 cc1:2934-2962 make:6397-6425 |
| 3 | `ResolveStorage` | 8 | 33 | c.comp:18299-18334 c.link:5107-5142 c.opt:4174-4209 c.pass1:12927-12962 c.pass2:9485-9520 c_asm:8219-8254 cc1:2749-2784 make:5473-5508 |
| 4 | `CreateOk` | 8 | 28 | c.comp:19780-19810 c.link:5855-5885 c.opt:4592-4622 c.pass1:13562-13592 c.pass2:10913-10943 c.prep:4296-4325 c_asm:8757-8786 cc1:3074-3104 |
| 7 | `WriteWhole` | 8 | 20 | c.comp:18095-18116 c.link:4900-4921 c.opt:3964-3985 c.pass1:12720-12741 c.pass2:9281-9302 c.prep:3698-3719 cc1:2705-2726 make:5249-5270 |
| 11 | `WriteWhole` | 7 | 24 | c.comp:18095-18120 c.link:4900-4925 c.opt:3964-3989 c.pass1:12720-12745 c.pass2:9281-9306 cc1:2705-2730 make:5249-5274 |
| 13 | `CreatePath` | 6 | 117 | c.comp:19776-19906 c.link:5851-5981 c.opt:4588-4718 c.pass1:13558-13688 c.pass2:10909-11039 cc1:3070-3199 |
| 17 | `SbrkGrow` | 6 | 36 | c.comp:19921-19959 c.link:6022-6060 c.opt:4733-4771 c.pass2:11054-11092 c_asm:8896-8933 cc1:3244-3282 |
| 18 | `RefillAndGet` | 6 | 36 | c.comp:18151-18189 c.link:4957-4995 c.opt:4024-4062 c.pass1:12779-12817 c.pass2:9337-9375 c.prep:3758-3796 |
| 20 | `WriteLoop` | 6 | 29 | c.comp:18075-18106 c.link:4880-4911 c.pass1:12700-12731 c.pass2:9261-9292 c_asm:7992-8023 cc1:2685-2716 |
| 25 | `SbrkGrow` | 5 | 51 | c.comp:19908-19962 c.link:6009-6063 c.opt:4720-4774 c.pass2:11041-11095 cc1:3231-3285 |
| 26 | `SeekErr` | 5 | 40 | c.comp:19877-19919 c.opt:4689-4731 c.pass1:13659-13701 c.pass2:11010-11052 c_asm:8852-8894 |
| 38 | `EvalDone` | 4 | 71 | c.comp:18283-18359 c.pass1:12911-12987 c.pass2:9469-9545 cc1:2733-2809 |
| 54 | `EvalInline` | 4 | 24 | c.comp:18255-18280 c.pass1:12883-12908 c.pass2:9441-9466 make:5431-5456 |
| 55 | `StrCat` | 4 | 22 | c.comp:18382-18404 c.pass1:13010-13032 c.pass2:9639-9661 make:5591-5613 |
| 57 | `MulInt32` | 3 | 401 | c.comp:19517-19958 c.pass1:13299-13740 c.pass2:10650-11091 |
| 59 | `ShiftRightDone` | 3 | 255 | c.comp:19492-19772 c.pass2:10625-10905 c_asm:8480-8751 |
| 60 | `EmitSeekDelta` | 3 | 251 | c.comp:17854-18122 c.pass1:12479-12747 c.pass2:9040-9308 |
| 62 | `FlushBuf` | 3 | 110 | c.comp:18024-18139 c.link:4829-4944 c.pass2:9210-9325 |
| 68 | `SetEndPtr` | 3 | 56 | c.comp:18357-18418 c.pass1:12985-13046 c.pass2:9614-9675 |
| 74 | `LongNeg` | 3 | 42 | c.link:5525-5569 c.pass1:13201-13245 make:6321-6364 |
| 84 | `ArenaAllocFail` | 3 | 33 | c.comp:19962-19999 c.pass1:13744-13781 cc1:3333-3370 |
| 85 | `StrNCmpDiff` | 3 | 32 | c.comp:18501-18533 c.link:5356-5388 c.pass1:13129-13161 |
| 87 | `StrNCat` | 3 | 31 | c.comp:18505-18535 c.pass1:13133-13163 make:5713-5743 |
| 90 | `StrCmpLoop` | 3 | 30 | c.comp:18430-18461 c.link:5284-5315 c.pass1:13058-13089 |
| 91 | `StrNCpy` | 3 | 29 | c.comp:18434-18464 c.pass1:13062-13092 make:5642-5672 |
| 92 | `StrCpyDone` | 3 | 28 | c.comp:18404-18434 c.pass1:13032-13062 c_asm:8359-8389 |
| 94 | `SetupIntercept` | 3 | 27 | c.comp:20001-20031 c.link:6065-6095 c.pass1:13783-13813 |
| 95 | `CopyDone` | 3 | 27 | c.comp:19379-19408 c.pass2:10513-10542 make:6281-6310 |
| 106 | `BuildByteType` | 2 | 776 | c.comp:18606-19429 c.pass2:9740-10562 |
| 108 | `SubstDone` | 2 | 675 | c.comp:17633-18359 c.pass2:8821-9545 |
| 111 | `SignExtendTo32` | 2 | 472 | c.comp:19444-19962 c.pass2:10577-11095 |
| 114 | `FlushExit` | 2 | 404 | c.comp:18120-18553 c.pass1:12748-13181 |
| 115 | `LongMulAccHigh` | 2 | 352 | c.opt:4398-4790 c.pass2:10718-11111 |
| 123 | `IntToLong` | 2 | 270 | c.link:5549-5847 c_asm:8464-8750 |
| 132 | `GetStatSys` | 2 | 155 | c_asm:8677-8850 cc1:2992-3168 |
| 142 | `CmpLess` | 2 | 106 | c.link:5517-5630 make:6313-6425 |
| 145 | `FlushBuffer` | 2 | 96 | c.pass1:12649-12751 cc1:2634-2736 |
| 153 | `CreateExisting` | 2 | 87 | c.prep:4327-4424 cc1:3106-3203 |
| 162 | `AddInt32` | 2 | 76 | c.comp:19381-19463 c_asm:8404-8482 |
| 164 | `LongNot` | 2 | 74 | c.pass1:13218-13297 c.pass2:10569-10648 |
| 176 | `ArenaAllocFail` | 2 | 61 | c.comp:19961-20031 c.pass1:13743-13813 |
| 177 | `ShlLoop` | 2 | 59 | c.prep:4210-4277 cc1:2987-3054 |
| 179 | `CopyByteTest3` | 2 | 58 | c.link:5484-5547 c_asm:8401-8462 |
| 197 | `LongMul` | 2 | 44 | c.opt:4354-4398 c.pass1:13293-13337 |
| 200 | `CopyHiBitLoop` | 2 | 41 | c.comp:18553-18604 c.pass2:9688-9738 |
| 203 | `FormatXDone` | 2 | 40 | c.pass1:12436-12481 c_asm:6901-6944 |
| 252 | `PoolAlloc` | 2 | 21 | c.link:6050-6074 c.prep:4493-4516 |

## compiler-mid (183 groups)

| id | label | #mod | len | modules: line-range |
|--|--|--|--|--|
| 1 | `AllocRegSlot` | 9 | 22 | c.comp:17498-17522 c.link:3646-3670 c.opt:2971-2995 c.pass1:12300-12324 c.pass2:8709-8733 c.prep:2766-2790 c_asm:6790-6814 cc1:1749-1773 make:4017-4041 |
| 5 | `AllocRegSlot` | 8 | 26 | c.comp:17497-17526 c.link:3645-3674 c.opt:2970-2999 c.pass1:12299-12328 c.pass2:8708-8737 c.prep:2765-2794 c_asm:6789-6818 cc1:1748-1777 |
| 6 | `UtoaDecimal` | 8 | 20 | c.comp:17136-17157 c.link:4187-4208 c.pass1:9286-9307 c.pass2:5331-5352 c.prep:3199-3220 c_asm:7296-7317 cc1:2209-2230 make:4564-4585 |
| 8 | `PutBuffered` | 7 | 51 | c.comp:17881-17934 c.link:4687-4740 c.opt:3753-3806 c.pass1:12506-12559 c.pass2:9067-9120 c.prep:3483-3537 cc1:2492-2545 |
| 10 | `PutByte` | 7 | 30 | c.comp:17862-17892 c.link:4668-4698 c.opt:3734-3764 c.pass1:12487-12517 c.pass2:9048-9078 c_asm:7780-7810 cc1:2473-2503 |
| 12 | `FlushBuf` | 7 | 22 | c.comp:18047-18069 c.link:4852-4874 c.pass1:12672-12694 c.pass2:9233-9255 c_asm:7964-7986 cc1:2657-2679 make:5203-5225 |
| 15 | `ClassifyBySize` | 6 | 61 | c.comp:17396-17467 c.link:3544-3615 c.opt:2867-2938 c.pass1:12198-12269 c.pass2:8607-8678 c.prep:2664-2735 |
| 16 | `AddressOperand` | 6 | 61 | c.comp:17474-17541 c.link:3622-3689 c.pass1:12276-12343 c.pass2:8685-8752 c_asm:6766-6833 cc1:1725-1792 |
| 21 | `WriteLoop` | 6 | 21 | c.comp:18071-18093 c.link:4876-4898 c.pass1:12696-12718 c.pass2:9257-9279 cc1:2681-2703 make:5226-5248 |
| 24 | `GetSizeLetter` | 5 | 107 | c.comp:17459-17577 c.link:3607-3725 c.pass1:12261-12379 c.pass2:8670-8788 cc1:1710-1828 |
| 27 | `RangeCompare2` | 5 | 37 | c.comp:17730-17768 c.link:4536-4574 c.pass2:8916-8954 c_asm:7646-7684 make:4900-4938 |
| 28 | `ConvOctal` | 5 | 33 | c.link:4241-4274 c.prep:3253-3286 c_asm:7350-7383 cc1:2263-2296 make:4618-4651 |
| 29 | `EmitOneChar` | 5 | 32 | c.link:4111-4144 c.opt:3392-3425 c.prep:3123-3156 c_asm:7220-7253 cc1:2133-2166 |
| 30 | `EmitOneChar` | 5 | 31 | c.link:4113-4146 c.opt:3394-3427 c_asm:7222-7255 cc1:2135-2168 make:4493-4526 |
| 31 | `StrLenLoop2` | 5 | 25 | c.link:5220-5246 c.opt:4287-4313 c.prep:4012-4038 c_asm:8321-8347 cc1:2851-2877 |
| 32 | `FormatScanLoop` | 5 | 24 | c.link:3889-3914 c.opt:3172-3197 c_asm:6998-7023 cc1:1911-1936 make:4279-4304 |
| 33 | `ConvSignedDec` | 5 | 23 | c.link:4147-4170 c.opt:3428-3451 c.prep:3159-3182 c_asm:7256-7279 cc1:2169-2192 |
| 34 | `CheckRegBit` | 5 | 22 | c.comp:17669-17692 c.link:4475-4498 c.pass2:8855-8878 c_asm:7584-7607 make:4842-4865 |
| 35 | `QueryFilePos` | 5 | 20 | c.comp:17834-17854 c.link:4640-4660 c.pass2:9020-9040 c_asm:7752-7772 make:5002-5022 |
| 36 | `PutCharDone2` | 4 | 200 | c.comp:17352-17579 c.link:3500-3727 c.pass1:12140-12381 c.pass2:8523-8790 |
| 39 | `PutCharFileDone` | 4 | 68 | c.comp:17351-17427 c.opt:2820-2898 c.pass1:12139-12229 cc1:1601-1678 |
| 40 | `CompareRanges` | 4 | 63 | c.comp:17711-17776 c.link:4517-4582 c.pass2:8897-8962 c_asm:7627-7692 |
| 41 | `ReturnNoOp` | 4 | 57 | c.comp:17649-17709 c.link:4455-4515 c.pass2:8835-8895 c_asm:7564-7624 |
| 42 | `ConvUnsignedDec` | 4 | 53 | c.link:4184-4238 c.prep:3196-3250 c_asm:7293-7347 cc1:2206-2260 |
| 43 | `ReportBufErr` | 4 | 46 | c.comp:17812-17860 c.link:4618-4666 c.pass2:8998-9046 c_asm:7730-7778 |
| 44 | `ConvOctal` | 4 | 34 | c.link:4241-4275 c.prep:3253-3287 c_asm:7350-7384 cc1:2263-2297 |
| 46 | `DecSubLoop` | 4 | 30 | c.link:4210-4240 c_asm:7319-7349 cc1:2232-2262 make:4586-4616 |
| 47 | `EmitBranch` | 4 | 29 | c.comp:16282-16311 c.pass1:978-1007 c.pass2:3669-3698 cc1:415-444 |
| 48 | `FloatConvert` | 4 | 29 | c.link:4038-4069 c.prep:3050-3081 cc1:2060-2091 make:4423-4454 |
| 49 | `CloseNull` | 4 | 29 | c.link:4782-4813 c.opt:3848-3879 c_asm:7894-7925 cc1:2587-2618 |
| 50 | `EmitIndexedRef2` | 4 | 28 | c.comp:17696-17725 c.link:4502-4531 c.pass2:8882-8911 make:4868-4897 |
| 51 | `PrecDigitTest` | 4 | 27 | c.link:3964-3993 c.opt:3245-3274 c.pass1:9148-9177 cc1:1986-2015 |
| 52 | `DecPowerTest` | 4 | 27 | c.link:4230-4257 c.opt:3513-3540 c_asm:7339-7366 cc1:2252-2279 |
| 53 | `CheckSeekResult` | 4 | 26 | c.comp:17782-17810 c.link:4588-4616 c.pass2:8968-8996 c_asm:7699-7727 |
| 56 | `StrCatScan` | 4 | 22 | c.link:5248-5272 c.prep:4040-4064 c_asm:8349-8373 cc1:2879-2903 |
| 58 | `SubstDone` | 3 | 307 | c.comp:17635-17965 c.link:4441-4771 c.pass2:8823-9151 |
| 61 | `OutputCharField` | 3 | 129 | c.comp:17077-17214 c.pass1:9227-9364 c.pass2:5272-5409 |
| 63 | `FlushNext` | 3 | 90 | c.link:4772-4867 c.opt:3838-3933 cc1:2577-2672 |
| 64 | `PutCallWrite` | 3 | 76 | c.link:4700-4780 c_asm:7812-7892 cc1:2505-2585 |
| 65 | `GetConvChar` | 3 | 64 | c.comp:17005-17075 c.pass1:9155-9225 c.pass2:5200-5270 |
| 66 | `RetNegOne` | 3 | 61 | c.link:4815-4878 c_asm:7927-7990 cc1:2620-2683 |
| 67 | `FillBuf` | 3 | 59 | c.link:5017-5079 c.opt:4084-4146 c_asm:8129-8191 |
| 69 | `HexDigitLoop` | 3 | 51 | c.link:4286-4341 c.prep:3298-3353 cc1:2308-2363 |
| 70 | `StoreHexChar` | 3 | 51 | c.comp:17216-17270 c.pass1:9366-9420 c.pass2:5411-5465 |
| 71 | `EmitInlineArgs` | 3 | 51 | c.comp:8847-8901 c.pass1:8915-8969 c.pass2:6915-6969 |
| 72 | `ConvHex` | 3 | 49 | c.link:4278-4329 cc1:2300-2351 make:4657-4708 |
| 73 | `HexAlphaAdj` | 3 | 46 | c.link:4296-4345 c_asm:7405-7454 cc1:2318-2367 |
| 75 | `FWriteDone` | 3 | 41 | c.link:3831-3875 c.opt:3114-3158 c_asm:6940-6984 |
| 76 | `OctCopyTest` | 3 | 40 | c.link:4270-4312 c.opt:3553-3595 cc1:2292-2334 |
| 77 | `OpenForMode` | 3 | 39 | c_asm:6714-6760 cc1:1673-1719 make:3942-3988 |
| 78 | `CntStrLoop` | 3 | 39 | c.comp:17311-17352 c.pass1:9461-9502 c.pass2:5506-5547 |
| 79 | `EmitLiteral` | 3 | 38 | c.link:3882-3922 c_asm:6991-7031 cc1:1904-1944 |
| 80 | `OutputLiteralChar` | 3 | 38 | c.comp:16918-16958 c.pass1:9068-9108 c.pass2:5111-5151 |
| 81 | `FloatConvert` | 3 | 36 | c.link:4038-4076 cc1:2060-2098 make:4423-4461 |
| 82 | `PadStrNext` | 3 | 34 | c.comp:17272-17309 c.pass1:9422-9459 c.pass2:5467-5504 |
| 83 | `EmitBranch` | 3 | 33 | c.comp:16284-16317 c.pass1:8648-8681 c.pass2:3671-3704 |
| 88 | `PutcStdout` | 3 | 30 | c.opt:3714-3747 c.prep:3443-3477 cc1:2453-2486 |
| 89 | `LongModifier` | 3 | 30 | c.prep:3971-4010 c_asm:8282-8319 cc1:2812-2849 |
| 96 | `StrCmp` | 3 | 26 | c.link:5258-5285 c.pass2:9661-9688 cc1:2889-2916 |
| 97 | `WidthDigitLoop` | 3 | 25 | c.link:3924-3949 cc1:1946-1971 make:4314-4339 |
| 98 | `OpDispatch2` | 3 | 25 | c.comp:12259-12283 c.pass2:1614-1638 make:443-467 |
| 99 | `WidthDigitTest` | 3 | 23 | c.link:3937-3960 c.pass1:9122-9145 make:4327-4350 |
| 100 | `PadRightTest` | 3 | 22 | c.link:4374-4397 c_asm:7483-7506 cc1:2396-2419 |
| 102 | `DigitCheckDone` | 2 | 2014 | c.comp:11854-14151 c.pass2:1275-3506 |
| 104 | `GenNode51Match` | 2 | 1251 | c.comp:3293-4701 c.pass1:3160-4568 |
| 105 | `TypesMatchOk` | 2 | 1101 | c.comp:14896-16121 c.pass1:6340-7565 |
| 107 | `LoadMemberNode` | 2 | 774 | c.comp:8264-9138 c.pass2:6332-7206 |
| 109 | `MinusOpTok` | 2 | 621 | c.comp:10569-11225 c.pass1:9905-10561 |
| 110 | `FloatTypeRet` | 2 | 489 | c.comp:14135-14675 c.pass1:5569-6119 |
| 112 | `RetPop2` | 2 | 425 | c.comp:16079-16573 c.pass2:3490-3960 |
| 113 | `GenTempSlot` | 2 | 411 | c.comp:7813-8261 c.pass2:5882-6330 |
| 117 | `PrecisionScan` | 2 | 327 | c.comp:16998-17352 c.pass2:5193-5547 |
| 118 | `EmitOneChar` | 2 | 311 | c.link:4110-4446 cc1:2132-2468 |
| 119 | `CheckRightConst` | 2 | 301 | c.comp:5984-6302 c.pass2:4382-4700 |
| 120 | `EmitExternRef` | 2 | 288 | c.comp:6705-7016 c.pass1:7619-7930 |
| 121 | `RetEmitValue` | 2 | 273 | c.comp:5479-5793 c.pass1:5281-5595 |
| 122 | `FillCaseNode` | 2 | 272 | c.comp:5102-5382 c.pass1:4969-5249 |
| 124 | `EmitConstResult` | 2 | 256 | c.comp:6375-6648 c.pass2:4790-5063 |
| 125 | `TellSubBuf` | 2 | 250 | c.link:4660-4927 cc1:2463-2732 |
| 126 | `PutCharDone2` | 2 | 229 | c.comp:17352-17610 c.link:3500-3758 |
| 127 | `PutCharFile` | 2 | 223 | c.comp:17349-17601 c.pass1:12137-12403 |
| 128 | `StrScanTest` | 2 | 212 | c_asm:7177-7403 cc1:2090-2316 |
| 129 | `EmitRegisterField` | 2 | 201 | c.comp:9342-9575 c.pass2:7409-7642 |
| 130 | `EmitCharDecimal` | 2 | 193 | c.comp:11645-11947 c.pass1:10867-11158 |
| 134 | `GetByte` | 2 | 134 | c.link:4945-5089 c.opt:4012-4156 |
| 135 | `GenRelOp` | 2 | 127 | c.comp:3033-3169 c.pass1:2900-3036 |
| 136 | `FillInitElements` | 2 | 121 | c.comp:7016-7147 c.pass1:7931-8062 |
| 137 | `FatalError` | 2 | 118 | c.opt:2814-2950 c.pass1:12133-12281 |
| 138 | `BuildEmptyAssign` | 2 | 118 | c.comp:14677-14801 c.pass1:6121-6245 |
| 139 | `EmitPaddedString` | 2 | 110 | c.link:4069-4187 c.opt:3350-3468 |
| 140 | `PutcRet` | 2 | 109 | c.opt:3707-3824 cc1:2446-2563 |
| 141 | `GenNode5ATest` | 2 | 108 | c.comp:3171-3283 c.pass1:3038-3150 |
| 143 | `DoAllocBuf` | 2 | 104 | c.prep:3945-4065 cc1:2786-2904 |
| 144 | `FindFreeStream` | 2 | 103 | c_asm:6648-6764 cc1:1607-1723 |
| 146 | `StmtDispatchLoop` | 2 | 95 | c.comp:10288-10395 c.pass1:9624-9731 |
| 147 | `SetupBuf` | 2 | 92 | c.link:5093-5193 cc1:2735-2835 |
| 148 | `EmitCmpImm` | 2 | 92 | c.comp:16678-16786 c.pass2:4064-4172 |
| 149 | `OperRegA` | 2 | 90 | c.opt:2953-3053 cc1:1731-1831 |
| 150 | `FormatScanLoop` | 2 | 89 | c.link:3885-3979 make:4275-4369 |
| 151 | `EmitStmtRet` | 2 | 89 | c.comp:5767-5887 c.pass2:4176-4274 |
| 152 | `PrintfToBuf` | 2 | 89 | c.comp:16870-16965 c.pass2:5063-5158 |
| 154 | `LoadConvChar` | 2 | 86 | c_asm:7080-7173 cc1:1993-2086 |
| 155 | `PrecDigitTest` | 2 | 85 | c.link:3964-4056 c.opt:3245-3337 |
| 156 | `FormatToScratch` | 2 | 82 | c_asm:6944-7032 cc1:1857-1945 |
| 157 | `HandleLineFile` | 2 | 82 | c.comp:7436-7521 c.pass1:11277-11362 |
| 158 | `GenNode65MakeConst` | 2 | 80 | c.comp:2943-3031 c.pass1:2810-2898 |
| 160 | `StrToFpDone` | 2 | 78 | c.comp:16790-16870 c.pass1:9502-9584 |
| 161 | `GenAddrRefOp` | 2 | 77 | c.comp:5888-5970 c.pass2:4280-4362 |
| 163 | `EmitLocalLabel` | 2 | 76 | c.comp:9580-9930 c.pass2:7643-7993 |
| 165 | `GotData` | 2 | 72 | c.link:5091-5168 c.opt:4158-4235 |
| 166 | `GenConstCompare` | 2 | 71 | c.comp:16588-16662 c.pass2:3974-4048 |
| 167 | `SelectFormat` | 2 | 70 | c.link:5170-5259 c.opt:4237-4326 |
| 168 | `StrLen` | 2 | 67 | c.link:5214-5285 cc1:2845-2916 |
| 169 | `EmitRefExpr` | 2 | 67 | c.comp:7176-7252 c.pass1:8087-8163 |
| 170 | `ReadLineExit` | 2 | 66 | c.comp:7644-7733 c.pass2:5738-5808 |
| 171 | `MulInt` | 2 | 65 | cc1:2924-2990 make:6387-6454 |
| 172 | `FWriteByteLoop` | 2 | 65 | c.link:3811-3880 c_asm:6920-6989 |
| 173 | `AddConstJoin` | 2 | 64 | c.comp:6303-6377 c.pass2:4710-4784 |
| 174 | `Fopen` | 2 | 62 | c.pass1:12345-12412 c_asm:6835-6902 |
| 175 | `GetcOrFlags` | 2 | 61 | c.opt:4148-4213 c_asm:8193-8258 |
| 178 | `FloatSetExp` | 2 | 59 | c.comp:11258-11319 c.pass1:10584-10645 |
| 180 | `GenReturnEmit` | 2 | 58 | c.comp:7738-7808 c.pass2:5810-5880 |
| 181 | `EmitOperand2` | 2 | 55 | c.comp:9200-9258 c.pass2:7264-7322 |
| 182 | `TestSkipTok` | 2 | 55 | c.comp:7310-7382 c.pass1:11076-11216 |
| 183 | `FloatConvert` | 2 | 54 | c.link:4037-4096 cc1:2059-2118 |
| 184 | `Pow10Copy` | 2 | 54 | c.comp:11471-11530 c.pass1:10715-10774 |
| 185 | `ApplyDecExp` | 2 | 53 | c.comp:11342-11401 c.pass1:10658-10717 |
| 186 | `IfCheckElse` | 2 | 52 | c.comp:4800-4852 c.pass1:4667-4719 |
| 187 | `TypeWalkDone` | 2 | 52 | c.comp:6643-6703 c.pass1:7522-7616 |
| 188 | `Op46Emit` | 2 | 51 | c.comp:2881-2934 c.pass1:2748-2801 |
| 189 | `FlushLoopAdvance` | 2 | 50 | c.opt:3956-4010 c.pass1:12712-12766 |
| 190 | `GenLongDefault` | 2 | 47 | c.comp:8572-8619 c.pass2:806-853 |
| 191 | `CompileSwitch` | 2 | 47 | c.comp:4936-4987 c.pass1:4803-4854 |
| 192 | `PushCompareArgs` | 2 | 47 | c.comp:14842-14894 c.pass1:6286-6338 |
| 194 | `EvalExprStmt` | 2 | 46 | c.comp:4704-4753 c.pass1:4571-4620 |
| 195 | `InitCopyLoop` | 2 | 45 | c.prep:2610-2662 cc1:1593-1645 |
| 196 | `AdvanceOffset` | 2 | 45 | c.pass1:9009-9066 c.pass2:5058-5109 |
| 198 | `PrecDigitLoop` | 2 | 43 | c.link:3951-3997 cc1:1973-2019 |
| 199 | `FlushError` | 2 | 43 | c.link:4913-4959 c_asm:8025-8071 |
| 201 | `CompileIf` | 2 | 41 | c.comp:4756-4797 c.pass1:4623-4664 |
| 202 | `FillBufAlloc` | 2 | 40 | c.opt:4215-4260 c_asm:8260-8305 |
| 204 | `PrecDigit` | 2 | 39 | c.pass2:5181-5222 c_asm:7061-7102 |
| 205 | `ReadLineEofRet` | 2 | 39 | c.comp:7603-7666 c.pass1:11438-11501 |
| 206 | `ErrCheckFatal` | 2 | 38 | c.comp:7526-7567 c.pass1:11364-11405 |
| 207 | `PipeOpTok` | 2 | 38 | c.comp:10444-10488 c.pass1:9780-9824 |
| 209 | `WriteStringLoop` | 2 | 37 | c.link:3757-3797 c.pass2:8787-8827 |
| 212 | `EmitVsectRmb` | 2 | 35 | c.comp:9943-9980 c.pass1:11511-11548 |
| 214 | `PadCheck` | 2 | 34 | c.link:5321-5357 make:5674-5710 |
| 215 | `WhileEmitTest` | 2 | 34 | c.comp:4877-4911 c.pass1:4744-4778 |
| 216 | `DispatchTypeSize` | 2 | 34 | c.comp:7271-7324 c.pass1:8185-8238 |
| 218 | `EmitInstrLine` | 2 | 33 | c.comp:9164-9197 c.pass2:7228-7261 |
| 219 | `TypeChkTest` | 2 | 33 | c.comp:2843-2876 c.pass1:2710-2743 |
| 220 | `HandlePostAssign` | 2 | 32 | c.comp:14803-14840 c.pass1:6247-6284 |
| 221 | `RetWidenInt` | 2 | 31 | c.comp:5443-5477 c.pass2:1211-1245 |
| 222 | `EmitSwitchDispatch` | 2 | 31 | c.comp:5005-5036 c.pass1:4872-4903 |
| 223 | `EmitStringBody` | 2 | 31 | c.comp:11542-11575 c.pass1:10795-10828 |
| 224 | `CaseEntryLoopTest` | 2 | 30 | c.comp:5039-5069 c.pass1:4906-4936 |
| 226 | `ReadInitVar` | 2 | 29 | c.prep:2579-2608 cc1:1562-1591 |
| 227 | `ParseStatement2` | 2 | 29 | c.comp:10248-10278 c.pass1:9584-9614 |
| 228 | `ParseDecimalBody` | 2 | 29 | c.comp:7569-7598 c.pass1:11407-11436 |
| 229 | `RetEmitLoad` | 2 | 28 | c.comp:5408-5438 c.pass2:1176-1206 |
| 230 | `EmitStringByte` | 2 | 28 | c.comp:11595-11623 c.pass2:8479-8507 |
| 233 | `SPadRightTest` | 2 | 26 | c.link:4423-4453 c_asm:7532-7562 |
| 234 | `EmitFuncPrologue` | 2 | 26 | c.comp:10031-10056 c.pass2:8387-8412 |
| 238 | `CompileCase` | 2 | 26 | c.comp:5072-5099 c.pass1:4939-4966 |
| 239 | `WidthScanLoop` | 2 | 25 | c.pass2:5160-5185 cc1:1953-1978 |
| 240 | `WidthDigit` | 2 | 25 | c.pass2:5154-5179 c_asm:7034-7059 |
| 242 | `AccumWidthDigit` | 2 | 24 | c.comp:16960-16984 c.pass1:9110-9134 |
| 243 | `AmpOpTok` | 2 | 24 | c.comp:10414-10442 c.pass1:9750-9778 |
| 244 | `GreaterOpTok` | 2 | 24 | c.comp:10519-10546 c.pass1:9855-9882 |
| 245 | `CopyByteStore` | 2 | 23 | c.pass1:12411-12435 cc1:1827-1851 |
| 246 | `WidthScan` | 2 | 23 | c.comp:16972-16995 cc1:1959-1982 |
| 247 | `GetcCheckRead` | 2 | 22 | c.opt:4138-4162 c.prep:3872-3896 |
| 249 | `EmitPopByte` | 2 | 22 | c.comp:9134-9157 c.pass2:7487-7510 |
| 250 | `GenReturnStmt` | 2 | 22 | c.comp:5384-5406 c.pass1:5251-5273 |
| 253 | `Getc` | 2 | 21 | c.opt:4000-4022 c.prep:3734-3756 |
| 254 | `ParseNumber` | 2 | 21 | c.link:2892-2913 c.pass1:11389-11410 |
| 255 | `FlagP` | 2 | 21 | c.pass1:12033-12055 c.pass2:260-282 |
| 256 | `EmitLocalOffset` | 2 | 21 | c.comp:9268-9290 c.pass2:7334-7356 |
| 257 | `ScanCharTest` | 2 | 20 | c.comp:17619-17641 c.pass1:12421-12443 |
| 258 | `FlagUnknown` | 2 | 20 | c.pass1:12039-12059 c.pass2:519-539 |
| 259 | `AccumFracDigit` | 2 | 20 | c.comp:11227-11247 c.pass1:10563-10583 |
| 260 | `DumpStrings` | 2 | 20 | c.comp:10128-10148 c.pass1:11716-11736 |

