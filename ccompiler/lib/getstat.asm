********************************************************************
* getstat - I$GetStt wrapper returning X and U through a caller pointer
*
* Shared C runtime getstat helper.  Called with the status code and
* path already set up; on success it stores the returned X and U back
* through the caller's pointer, otherwise it drops into SyscallErr
* (from lib/syscallerr.asm).
*
* Each module pulls this in with "use lib/getstat.asm".
*
* Convention:   getstat helper: A=path, B=status code, returns X,U through caller pointer
********************************************************************

GetStatXU           pshs      u         save the caller u register
                    os9       I$GetStt  get file status
                    bcc       @GetStatStore success
                    puls      u         restore the caller u register
                    lbra      SyscallErr report the error
@GetStatStore        stx       [8,s]     store the returned x through caller
                    ldx       8,s       reload caller pointer
                    stu       2,x       store the returned u
                    puls      u         restore the caller u register
                    clra                clear high result
                    clrb                clear low result
                    rts                 return success

