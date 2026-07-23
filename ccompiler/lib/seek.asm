********************************************************************
* seek - lseek: reposition an open path by whence + 32-bit offset
*
* Shared C runtime lseek.  Whence 0/1/2 selects an absolute base, the
* current position (I$GetStt code 5) or the end of file (code 2); the
* signed 32-bit offset is added and the path seeked there.  The new
* position is staged in the module's long-value cells and a pointer to
* it is returned; a bad whence or any failure stores Errno and returns
* the -1 position.
*
* Each module maps its own long-value staging cells onto HighResultWord
* and LowResultWord (used module-wide by lseek/ftell/int-to-long), and
* supplies the Errno cell; both come in via equ aliases where the module
* names them differently.
*
* C prototype:  long  lseek(int path, long offset, int whence);   returns ptr to 32-bit result
********************************************************************

lseek               pshs      u         save u
                    ldd       $0a,s     load whence argument
                    bne       @SeekWhence nonzero whence
                    ldu       #$0000    absolute base high zero
                    ldx       #$0000    absolute base low zero
                    bra       @SeekCompute compute new position
@SeekWhence          cmpd      #$0001    whence from current
                    beq       @SeekCurPos get current position
                    cmpd      #$0002    whence from end
                    beq       @SeekEndSize get file size
                    ldb       #E$Seek   invalid whence error
@SeekErr             clra                clear high errno byte
                    std       Errno,y   store errno
                    ldd       #$FFFF    position minus one
                    leax      HighResultWord,y   point to saved position
                    std       ,x        store high word
                    std       $02,x     store low word
                    puls      pc,u      return seek error
@SeekEndSize         lda       $05,s     load path number
                    ldb       #$02      size status code
                    os9       I$GetStt  get file size
                    bcs       @SeekErr  seek error on failure
                    bra       @SeekCompute compute new position
@SeekCurPos          lda       $05,s     load path number
                    ldb       #$05      current position code
                    os9       I$GetStt  get current position
                    bcs       @SeekErr  seek error on failure
@SeekCompute         tfr       u,d       base low to d
                    addd      $08,s     add offset low word
                    std       LowResultWord,y   save new position low
                    tfr       d,u       keep low in u
                    tfr       x,d       base high to d
                    adcb      $07,s     add offset high with carry
                    adca      $06,s     propagate carry
                    bmi       @SeekErr  negative position error
                    tfr       d,x       keep high in x
                    std       HighResultWord,y   save new position high
                    lda       $05,s     load path number
                    os9       I$Seek    seek to new position
                    bcs       @SeekErr  seek error on failure
                    leax      HighResultWord,y   point to new position
                    puls      pc,u      return position pointer

