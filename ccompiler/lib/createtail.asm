********************************************************************
* createtail - shared tail of the create-file wrapper
*
* Every module's create wrapper differs only in the few instructions
* that build the create attributes; from the create call onwards they
* are identical.  This include holds that shared remainder: the success
* return (CreateOk) and the "file already exists" fallback, which reopens
* the file and truncates it to zero length.  Any hard error drops into
* SyscallErr (from lib/syscallerr.asm).
*
* Each module keeps its own create prologue ending in "bcs CreateExists"
* (aliasing that label where it uses a different name) and falls through
* into CreateOk here.
*
* Role:         shared tail of creat(): success return + "already exists" reopen/truncate
********************************************************************

@CreateOk            tfr       a,b       path number to result
                    clra                clear high byte
                    rts                 return path number
CreateExists        cmpb      #E$CEF    file already exists error
                    lbne      SyscallErr other error returns
                    lda       5,s       reload create mode
                    bita      #$80      test exclusive flag
                    lbne      SyscallErr exclusive create fails
                    anda      #$07      keep permission bits
                    ldx       2,s       load pathname pointer
                    os9       I$Open    open existing file
                    lbcs      SyscallErr return error
                    pshs      u,a       save path and u
                    ldx       #0        zero length
                    leau      ,x        clear u pointer
                    ldb       #2        setstt size code
                    os9       I$SetStt  truncate to zero length
                    puls      u,a       restore path and u
                    bcc       @CreateOk return path on success
                    pshs      b         save error code
                    os9       I$Close   close on failure
                    puls      b         restore error code
                    lbra      SyscallErr return error

